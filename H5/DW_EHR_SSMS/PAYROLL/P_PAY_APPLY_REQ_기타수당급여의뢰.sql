SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER   PROCEDURE [dbo].[P_PAY_APPLY_REQ] (
    @av_company_cd     NVARCHAR(10),           -- 회사코드
    @av_pay_upload_mst_ids    NVARCHAR(MAX),      -- 급여의뢰신청ID(문자열 ',' 연결)
    --@an_pay_ymd_id     NUMERIC(18,0),          -- 급여일자ID
    --@av_close_type_cd  NVARCHAR(10),           -- 마감업무유형
    @an_mod_user_id    NUMERIC(18,0),          -- 작업자
    @av_ret_code       NVARCHAR(300)  OUTPUT,  -- 결과코드
    @av_ret_message    NVARCHAR(4000) OUTPUT   -- 결과메시지
) AS

--<DOCLINE> ***************************************************************************
--<DOCLINE>   TITLE       : 기타수당급여의뢰
--<DOCLINE>   PROJECT     : 신인사정보시스템
--<DOCLINE>   AUTHOR      : 성정엽
--<DOCLINE>   PROGRAM_ID  : P_PAY_APPLY_REQ
--<DOCLINE>   ARGUMENT    : 
--<DOCLINE>   RETURN      : 결과코드 SUCCESS! / FAILURE! 
--<DOCLINE>               : 결과메시지
--<DOCLINE>   COMMENT     : 
--<DOCLINE>   HISTORY     : 
--<DOCLINE> ***************************************************************************

BEGIN
    DECLARE
        @v_program_id NVARCHAR(30),
        @v_program_nm NVARCHAR(100),
		
        @c_pay_close_yn CHAR(1),         -- 급여마감여부
        @c_req_close_yn CHAR(1),         -- 기초작업마감여부
        @n_close_type_id NUMERIC(18,0),   -- 업무담당자관리ID
		@n_pay_upload_mst_id NUMERIC(18,0),
		@n_pay_ymd_id NUMERIC(18,0),
		@v_close_type_cd NVARCHAR(10),
		@cnt_dup_emp	NUMERIC


    /*기본변수 초기값 세팅*/
    SET @v_program_id   = 'P_PAY_APPLY_REQ'
    SET @v_program_nm   = '기타수당급여의뢰'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('프로시저 실행 시작..[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
	
--<DOCLINE> ***************************************************************************
--<DOCLINE> 급여마감여부, 해당업무 기초작업 마감여부체크
--<DOCLINE> ***************************************************************************
    BEGIN
	
        DECLARE CUR_MST CURSOR LOCAL FOR
            SELECT PAY_UPLOAD_MST_ID
			     , PAY_YMD_ID
				 , CLOSE_TYPE_CD
              FROM PAY_UPLOAD_MST A
                   INNER JOIN DBO.FN_SPLIT_ARRAY(@av_pay_upload_mst_ids, ',') B
                           ON A.PAY_UPLOAD_MST_ID = CAST(B.ITEMS AS NUMERIC(18,0))
        OPEN CUR_MST
        WHILE 1=1
        BEGIN TRY
			FETCH NEXT FROM CUR_MST INTO @n_pay_upload_mst_id, @n_pay_ymd_id, @v_close_type_cd
			IF @@FETCH_STATUS <> 0 BREAK

			SELECT @c_pay_close_yn  = YMD.CLOSE_YN
				 , @c_req_close_yn  = PC.CLOSE_YN
				 , @n_close_type_id = PCT.PAY_CLOSE_TYPE_ID
			  FROM PAY_PAY_YMD YMD
				   LEFT OUTER JOIN PAY_CLOSE PC
						   ON YMD.PAY_YMD_ID = PC.PAY_YMD_ID
						  AND PC.CLOSE_TYPE_CD = @v_close_type_cd
				   LEFT OUTER JOIN PAY_CLOSE_TYPE PCT
						   ON YMD.PAY_YMD BETWEEN PCT.STA_YMD AND PCT.END_YMD
						  AND PCT.PAY_CLOSE_TYPE_CD = @v_close_type_cd
						  AND PCT.EMP_ID = @an_mod_user_id
			 WHERE YMD.COMPANY_CD = @av_company_cd
			   AND YMD.PAY_YMD_ID = @n_pay_ymd_id

			IF @@ROWCOUNT < 1
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('급여일자가 정보가 없습니다.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END

			IF @@ERROR <> 0
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('급여일자 정보 조회 중 에러발생[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END

			IF @c_pay_close_yn = 'Y'
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('급여가 마감되었습니다.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END

			IF @c_req_close_yn = 'Y'
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('해당업무 급여의뢰가 마감되었습니다.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END
			ELSE IF @c_req_close_yn IS NULL
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('해당급여의 급여의뢰가 가능한 업무가 아닙니다.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END
			ELSE IF @n_close_type_id IS NULL
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('해당업무 급여의뢰 권한이 없습니다.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END
--<DOCLINE> ***************************************************************************
--<DOCLINE> 의뢰조건체크
--<DOCLINE> ***************************************************************************
			SELECT @cnt_dup_emp = COUNT(*)
			  FROM (
							SELECT DTL.EMP_ID
								FROM PAY_UPLOAD_MST MST
								JOIN PAY_KIND_UPLOAD DTL
									ON MST.PAY_UPLOAD_MST_ID = DTL.PAY_UPLOAD_MST_ID
								LEFT OUTER JOIN PAY_REQUEST REQ
									ON MST.PAY_UPLOAD_MST_ID = REQ.PAY_UPLOAD_MST_ID
								 AND ISNULL(CONF_YN, 'Y') = 'Y'
								 AND ISNULL(TEAM_YN, 'Y') = 'Y'
							 WHERE MST.PAY_YMD_ID = @n_pay_ymd_id
								 AND (REQ.PAY_UPLOAD_MST_ID IS NOT NULL OR MST.PAY_UPLOAD_MST_ID = @n_pay_upload_mst_id)
							 GROUP BY DTL.EMP_ID, DTL.PAY_ITEM_CD
							 HAVING COUNT(*) > 1
			 ) A
			IF @cnt_dup_emp > 0 
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('의뢰한 내역중 중복 사원이 있습니다.[ERR]', @v_program_id, 0123, NULL, @an_mod_user_id)
					RETURN
				END
			-- 
			INSERT INTO PAY_REQUEST(
					PAY_REQUEST_ID,
					PAY_UPLOAD_MST_ID,
					MOD_USER_ID,
					MOD_DATE,
					TZ_CD,
					TZ_DATE
			)
			SELECT NEXT VALUE FOR S_PAY_SEQUENCE AS PAY_REQUSET_ID
					, @n_pay_upload_mst_id
					, @an_mod_user_id                 -- MOD_USER_ID
					, GETDATE()                       -- MOD_DATE
					, 'KST'                           -- TZ_CD
					, GETDATE()                       -- TZ_DATE
			UPDATE PAY_UPLOAD_MST
			   set REQ_DATE = dbo.XF_TRUNC_D(dbo.XF_SYSDATE(0))
			 WHERE PAY_UPLOAD_MST_ID = @n_pay_upload_mst_id
		END TRY
		BEGIN CATCH
			SET @av_ret_code = 'FAILUERE!'
			SET @av_ret_message = DBO.F_FRM_ERRMSG('처리중 에러가 발생했습니다.[ERR]', @v_program_id, 0000, ERROR_MESSAGE(), @an_mod_user_id)
			RETURN
		END CATCH

		CLOSE CUR_MST
		DEALLOCATE CUR_MST
--<DOCLINE> ***************************************************************************
--<DOCLINE> 작업완료
--<DOCLINE> ***************************************************************************
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('급여의뢰 실행 완료..[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
	END
END
GO

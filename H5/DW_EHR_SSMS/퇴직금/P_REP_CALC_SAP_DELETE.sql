USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_CALC_SAP_DELETE]    Script Date: 2021-02-23 오전 11:09:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_CALC_SAP_DELETE] (
    @av_company_cd         NVARCHAR(10),           -- 회사코드
    @av_locale_cd          NVARCHAR(50),           -- 지역코드
    @an_rep_calc_list_id         NUMERIC(18,0),          -- 퇴직금ID
    @an_mod_user_id        NUMERIC(18,0),          -- 작업자
    @av_ret_code           NVARCHAR(300)  OUTPUT,  -- 결과코드
    @av_ret_message        NVARCHAR(4000) OUTPUT   -- 결과메시지
) AS

--<DOCLINE> ***************************************************************************
--<DOCLINE>   TITLE       : 급여전표삭제
--<DOCLINE>   PROJECT     : 신인사정보시스템
--<DOCLINE>   AUTHOR      : 성정엽
--<DOCLINE>   PROGRAM_ID  : P_PAY_SAP_DELETE
--<DOCLINE>   ARGUMENT    :
--<DOCLINE>   RETURN      : 결과코드 SUCCESS! / FAILURE!
--<DOCLINE>               : 결과메시지
--<DOCLINE>   COMMENT     :
--<DOCLINE>   HISTORY     :
--<DOCLINE> ***************************************************************************

BEGIN
    DECLARE
        @v_program_id          NVARCHAR(30),
        @v_program_nm          NVARCHAR(100),

        -- 퇴직금정보 --
		@n_rep_calc_list_id         NUMERIC(38,0),			-- 퇴직금ID
		@v_filldt					NVARCHAR(8),
		@n_fillno					NUMERIC(18),
		@n_auto_yn					NVARCHAR(10),
		@d_auto_ymd					DATE,
		@n_auto_no					NUMERIC(18)


    /*기본변수 초기값 세팅*/
    SET @v_program_id   = OBJECT_NAME(@@PROCID) --'P_REP_CALC_SAP_DELETE'
    SET @v_program_nm   = '퇴직금전표삭제'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('프로시저 실행 시작..[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)

--===========================================================
-- 퇴직금정보 조회
--===========================================================
    BEGIN
		SELECT @v_filldt = FILLDT
			 , @n_fillno = FILLNO
			 , @n_auto_yn = AUTO_YN
			 , @d_auto_ymd = AUTO_YMD
			 , @n_auto_no = AUTO_NO
		  FROM REP_CALC_LIST
		 WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id
		

        IF @@ROWCOUNT < 1
            BEGIN
                SET @av_ret_code = 'FAILUERE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('퇴직금정보가 정보가 없습니다.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
                RETURN
            END

        IF @@ERROR <> 0
            BEGIN
                SET @av_ret_code = 'FAILUERE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('퇴직금 정보 조회 중 에러발생[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
                RETURN
            END
    END

--===========================================================
-- 전표내역삭제
--===========================================================
    BEGIN TRY
        DELETE FROM H_IF_SAPINTERFACE
         WHERE COMPANY_CD = @av_company_cd
           AND DRAW_DATE = @v_filldt
		   AND SEQ = @n_fillno
		   AND ACCT_TYPE = 'E017'
		   AND FLAG = 'N'
		UPDATE A
		   SET FILLDT = NULL
			 , FILLNO = NULL
			 , AUTO_YN = NULL
			 , AUTO_YMD = NULL
			 , AUTO_NO = NULL
		  FROM REP_CALC_LIST A
		 WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id
    END TRY
	BEGIN CATCH
		SET @av_ret_code = 'FAILURE!'
		SET @av_ret_message = DBO.F_FRM_ERRMSG('전표금전표 내역삭제 중 에러발생[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
		IF @@TRANCOUNT > 0
			ROLLBACK
		RETURN
	END CATCH

--=========================================================
-- 작업완료
--=========================================================
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('전표내역이 삭제되었습니다.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
END


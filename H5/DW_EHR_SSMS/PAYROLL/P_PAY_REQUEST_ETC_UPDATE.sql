SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PAY_REQUEST_ETC_UPDATE] (
    @av_company_cd         NVARCHAR(10),           -- 회사코드
    @av_pay_request_ids    NVARCHAR(MAX),          -- 급여의뢰ID(문자열 ',' 연결)
    @an_mod_user_id        NUMERIC(18,0),          -- 작업자
    @av_ret_code           NVARCHAR(300)  OUTPUT,  -- 결과코드
    @av_ret_message        NVARCHAR(4000) OUTPUT   -- 결과메시지
) AS

--<DOCLINE> ***************************************************************************
--<DOCLINE>   TITLE       : 급여의뢰팀장승인 후처리
--<DOCLINE>   PROJECT     : 신인사정보시스템
--<DOCLINE>   AUTHOR      : 성정엽
--<DOCLINE>   PROGRAM_ID  : P_PAY_REQUEST_ETC_UPDATE
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
		
        @req$pay_request_id    NUMERIC(18,0),     -- 급여의뢰ID
        @req$pay_kind_upload_id    NUMERIC(18,0),     -- 각종수당업로드ID
        @req$pay_ymd_id        NUMERIC(18,0),     -- 급여일자ID
        @req$emp_id            NUMERIC(18,0),     -- 사원ID
        @req$pay_item_cd       NVARCHAR(10),      -- 급여항목코드
        @req$team_yn           CHAR(1)            -- 팀장승인여부

    /*기본변수 초기값 세팅*/
    SET @v_program_id   = 'P_PAY_REQUEST_ETC_UPDATE'
    SET @v_program_nm   = '급여의뢰팀장승인 후처리'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('프로시저 실행 시작..[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
	
--<DOCLINE> ***************************************************************************
--<DOCLINE> 급여의뢰내역 중 승인된 내역은 수시지급테이블에 INSERT, 승인취소 내역은 DELETE
--<DOCLINE> ***************************************************************************
    BEGIN
        DECLARE CUR_REQ CURSOR LOCAL FOR
            SELECT PAY_REQUEST_ID
                 , PAY_KIND_UPLOAD_ID
                 , PAY_YMD_ID
                 , EMP_ID
                 , ITEM_CD
                 , TEAM_YN
              FROM PAY_REQUEST A
              INNER JOIN DBO.FN_SPLIT_ARRAY(@av_pay_request_ids, ',') B
                           ON A.PAY_REQUEST_ID = CAST(B.ITEMS AS NUMERIC(18,0))
			  INNER JOIN PAY_UPLOAD_MST M
			          ON A.PAY_UPLOAD_MST_ID = M.PAY_UPLOAD_MST_ID
			  INNER JOIN PAY_KIND_UPLOAD C
			          ON A.PAY_UPLOAD_MST_ID = M.PAY_UPLOAD_MST_ID
        OPEN CUR_REQ
        WHILE 1=1
        BEGIN
        FETCH NEXT FROM CUR_REQ INTO @req$pay_request_id, @req$pay_kind_upload_id, @req$pay_ymd_id, @req$emp_id, @req$pay_item_cd, @req$team_yn
        IF @@FETCH_STATUS <> 0 BREAK
            IF @req$team_yn = 'Y'
                BEGIN TRY
                    INSERT INTO PAY_ETC_PAY( PAY_ETC_PAY_ID    -- 급여기타지급ID
                                           , PAY_YMD_ID		   -- 급여일자ID
                                           , EMP_ID			   -- 사원ID
                                           , CLOSE_TYPE_CD	   -- 마감업무유형코드
                                           , PAY_ITEM_CD	   -- 급여항목코드
                                           , ALLW_AMT		   -- 수시지급금액
                                           , TAX_YN			   -- 세금여부
                                           , PAY_YN			   -- 급여적용여부
                                           , CRE_FLAG		   -- 생성구분
                                           , REQ_ID			   -- 급여의뢰ID
                                           , LOCATION_CD	   -- 사업장코드
                                           , NOTE			   -- 비고
                                           , MOD_USER_ID	   -- 변경자
                                           , MOD_DATE		   -- 변경일시
                                           , TZ_CD			   -- 타임존코드
                                           , TZ_DATE		   -- 타임존일시
                                           )
                                      SELECT NEXT VALUE FOR S_PAY_SEQUENCE  -- PAY_ETC_PAY_ID
                                           , PAY_YMD_ID                     -- PAY_YMD_ID
                                           , EMP_ID                         -- EMP_ID
                                           , M.CLOSE_TYPE_CD                -- CLOSE_TYPE_CD
                                           , ITEM_CD                        -- PAY_ITEM_CD
                                           , PAY_MON                        -- ALLW_AMT
                                           , 'N'                            -- TAX_YN
                                           , 'N'                            -- PAY_YN
                                           , 'REQ'                          -- CRE_FLAG
                                           , PAY_REQUEST_ID                 -- REQ_ID
                                           , NULL                           -- LOCATION_CD
                                           , NULL                           -- NOTE
                                           , @an_mod_user_id                -- MOD_USER_ID
                                           , GETDATE()                      -- MOD_DATE
                                           , 'KST'                          -- TZ_CD
                                           , GETDATE()                      -- TZ_DATE
                                        FROM PAY_REQUEST A
										JOIN PAY_KIND_UPLOAD B
										  ON A.PAY_UPLOAD_MST_ID = B.PAY_UPLOAD_MST_ID
										JOIN PAY_UPLOAD_MST M
										  ON A.PAY_UPLOAD_MST_ID = M.PAY_UPLOAD_MST_ID
                                       WHERE PAY_REQUEST_ID = @req$pay_request_id
										 AND PAY_KIND_UPLOAD_ID = @req$pay_kind_upload_id
                END TRY
                BEGIN CATCH
                    SET @av_ret_code = 'FAILURE!' 
                    SET @av_ret_message = DBO.F_FRM_ERRMSG('승인내역 반영중 에러발생[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
                    IF @@TRANCOUNT > 0
                        ROLLBACK
                    RETURN
                END CATCH
            ELSE
                BEGIN TRY
                    DELETE FROM PAY_ETC_PAY
                     WHERE REQ_ID = @req$pay_request_id
                       AND PAY_YMD_ID = @req$pay_ymd_id
                       AND EMP_ID = @req$emp_id
                       AND PAY_ITEM_CD = @req$pay_item_cd
                END TRY
                BEGIN CATCH
                    SET @av_ret_code = 'FAILURE!' 
                    SET @av_ret_message = DBO.F_FRM_ERRMSG('승인취소내역 반영중 에러발생[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
                    IF @@TRANCOUNT > 0
                        ROLLBACK
                    RETURN
                END CATCH
        END
        CLOSE CUR_REQ
        DEALLOCATE CUR_REQ
    END
--<DOCLINE> ***************************************************************************
--<DOCLINE> 작업완료
--<DOCLINE> ***************************************************************************
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('자료가 저장되었습니다[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
END

GO



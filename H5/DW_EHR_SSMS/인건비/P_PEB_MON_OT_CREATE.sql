SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_MON_OT_CREATE]
		@an_peb_base_id			NUMERIC,
		@av_company_cd      NVARCHAR(10),
		@ad_base_ymd				DATE,
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- 타임존코드
    @an_mod_user_id     NUMERIC(18,0)  ,    -- 변경자 ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 인건비계획 월별OT생성
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_PEB_MON_OT_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획 월별OT 생성
    --<DOCLINE>   HISTORY     : 작성 임택구 2020.09.08
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @PEB_MON_OT_UPLOAD_ID	NUMERIC

    SET @v_program_id   = 'P_PEB_PHM_MST_CREATE'
    SET @v_program_nm   = '인건비계획 월별OT 생성'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
  -- 기존자료 삭제
	DELETE FROM PEB_MON_OT
		FROM PEB_MON_OT A
		JOIN PEB_PAYROLL PAY
		  ON PAY.PEB_PAYROLL_ID = A.PEB_PAYROLL_ID
		JOIN PEB_PHM_MST MST
		  ON PAY.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id
	/** 인건비계획 대상명단 **/
	DECLARE CUR_UPLOAD CURSOR LOCAL FOR
		SELECT PEB_MON_OT_UPLOAD_ID
			FROM PEB_MON_OT_UPLOAD A
			JOIN PEB_PHM_MST MST
			  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
	OPEN CUR_UPLOAD
	FETCH NEXT FROM CUR_UPLOAD INTO @PEB_MON_OT_UPLOAD_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> 인건비 월별OT 생성
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				--PRINT 'UPLOAD_ID ' + CONVERT(VARCHAR(100), @PEB_MON_OT_UPLOAD_ID)
				INSERT INTO PEB_MON_OT(
						PEB_MON_OT_ID, --	인건비월별OT관리ID
						PEB_PAYROLL_ID, --	월별계획인원ID
						OT, --	OT시간
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
						A.PEB_PAYROLL_ID,
						OT.OT_TIME,
						NULL	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
				  FROM (SELECT *
									FROM (SELECT MST.PEB_BASE_ID, T.*
													FROM PEB_PHM_MST MST
													JOIN PEB_MON_OT_UPLOAD T
								  					ON MST.PEB_PHM_MST_ID = T.PEB_PHM_MST_ID
												 WHERE T.PEB_MON_OT_UPLOAD_ID = @PEB_MON_OT_UPLOAD_ID
											 ) A
											 UNPIVOT ( OT_TIME FOR MON_COL IN (MON_01, MON_02, MON_03, MON_04, MON_05, MON_06, MON_07, MON_08, MON_09, MON_10, MON_11, MON_12) )  UNPVT1
										) OT
					JOIN PEB_PAYROLL A
						ON A.PEB_PHM_MST_ID = OT.PEB_PHM_MST_ID
					 AND RIGHT(A.PEB_YM,2) = RIGHT(MON_COL,2)
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 인상율 INSERT 에러[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_UPLOAD INTO @PEB_MON_OT_UPLOAD_ID
		END
	CLOSE CUR_UPLOAD
	DEALLOCATE CUR_UPLOAD
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END

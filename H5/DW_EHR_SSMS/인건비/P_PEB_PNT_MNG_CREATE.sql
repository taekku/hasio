SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_PNT_MNG_CREATE]
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
    --<DOCLINE>   TITLE       : 인건비계획 복지포인트 생성
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PNT_MNG_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획 복지포인트 생성
    --<DOCLINE>   HISTORY     : 작성 임택구 2020.09.14
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @PEB_PHM_MST_ID	NUMERIC
		, @STA_YMD DATE
		, @END_YMD DATE
		, @COMPANY_CD NVARCHAR(10)
		, @BASE_YYYY NVARCHAR(10)
		, @CAT_PAY_MGR_ID	NUMERIC

    SET @v_program_id   = 'P_PEB_SCH_MNG_CREATE'
    SET @v_program_nm   = '인건비계획 복지포인트 생성'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
  -- 기존자료 삭제
	DELETE FROM PEB_PNT_MNG
		FROM PEB_PNT_MNG A
		JOIN PEB_PHM_MST MST
		  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id
	SELECT @BASE_YYYY = BASE_YYYY
	     , @COMPANY_CD = COMPANY_CD
			 , @STA_YMD = STA_YMD
			 , @END_YMD = END_YMD
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id
	/** 인건비계획 대상명단 **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID, CAT_PAY_MGR_ID
			FROM PEB_PHM_MST MST
			JOIN PHM_EMP EMP
			  ON EMP.COMPANY_CD = @COMPANY_CD
			 AND MST.EMP_NO = EMP.EMP_NO
			 AND MST.PEB_BASE_ID = @an_peb_base_id
			JOIN CAT_PAY_MGR CAT
			  ON EMP.EMP_ID = CAT.EMP_ID
			 --AND CAT.PAY_YMD BETWEEN @STA_YMD AND @END_YMD
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
		   AND DATEPART(YEAR, CAT.GIVE_YMD) = (@BASE_YYYY - 1)
		   AND CAT.CONF_CD = 'Y' -- 지급된자
	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @CAT_PAY_MGR_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> 인건비 복지포인트 생성
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				INSERT INTO PEB_PNT_MNG(
						PEB_PNT_MNG_ID, --	인건비복지포인트ID
						PEB_PHM_MST_ID, --	인건비계획대상자ID
						PAY_YMD, --	지급일자
						PAY_AMT, --	포인트금액
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
						@PEB_PHM_MST_ID	PEB_PHM_MST_ID, --	인건비계획대상자ID
						dbo.XF_ADD_MONTH(A.GIVE_YMD, 12)	PAY_YMD, --	지급일자
						A.POINT + A.BIRTH_POINT	PAY_AMT, --	포인트금액
						NULL	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
				  FROM CAT_PAY_MGR A
				 WHERE CAT_PAY_MGR_ID = @CAT_PAY_MGR_ID
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 복지포인트 INSERT 에러[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @CAT_PAY_MGR_ID
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END

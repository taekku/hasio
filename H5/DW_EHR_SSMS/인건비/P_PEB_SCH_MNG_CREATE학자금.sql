SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_SCH_MNG_CREATE]
	@an_peb_base_id		NUMERIC(38),
	@av_company_cd      NVARCHAR(10),
	@ad_base_ymd		DATE,
	@an_org_id			NUMERIC(38),
	@av_emp_no			NVARCHAR(10),
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- 타임존코드
    @an_mod_user_id     NUMERIC(38)  ,    -- 변경자 ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 인건비계획 학자금 생성
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_PEB_SCH_MNG_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획 학자금 생성
    --<DOCLINE>   HISTORY     : 작성 임택구 2020.09.08
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @PEB_PHM_MST_ID	NUMERIC(38)
		, @STA_YMD DATE
		, @END_YMD DATE
		, @COMPANY_CD NVARCHAR(10)
		, @BASE_YYYY NVARCHAR(10)
		, @SEC_EDU_ID	NUMERIC(38)

    SET @v_program_id   = 'P_PEB_SCH_MNG_CREATE'
    SET @v_program_nm   = '인건비계획 학자금자료 생성'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
	SELECT @BASE_YYYY = BASE_YYYY
	     , @COMPANY_CD = COMPANY_CD
			 , @STA_YMD = STA_YMD
			 , @END_YMD = END_YMD
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id

  -- 기존자료 삭제
	DELETE FROM A
		FROM PEB_SCH_MNG A
		JOIN PEB_PHM_MST MST
		  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id
	/** 인건비계획 대상명단 **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID, SEC_EDU_ID
			FROM PEB_PHM_MST MST
			JOIN PHM_EMP EMP
			  ON EMP.COMPANY_CD = @COMPANY_CD
			 AND MST.EMP_NO = EMP.EMP_NO
			 AND MST.PEB_BASE_ID = @an_peb_base_id
			JOIN SEC_EDU SEC
			  ON EMP.EMP_ID = SEC.EMP_ID
			 AND DATEPART(YEAR, SEC.PAY_YMD) = (dbo.XF_TO_NUMBER( @BASE_YYYY ) - 1)
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @SEC_EDU_ID

 --   --<DOCLINE> ********************************************************
 --   --<DOCLINE> 인건비 학자금 생성
 --   --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			print @SEC_EDU_ID
			BEGIN Try
				INSERT INTO PEB_SCH_MNG(
						PEB_SCH_MNG_ID, --	인건비학자금ID
						PEB_PHM_MST_ID, --	인건비계획대상자ID
						REQ_YMD, --	신청일자
						FAM_NM, --	자녀성명
						SCH_GRD_CD, --	학력구분
						SCH_NM, --	학교명
						SCH_GRADE, --	학년
						SCH_TERM, --	학기
						ENT_AMT, --	입학금
						TUI_AMT, --	수업료
						OPE_SUP_AMT, --	운영지원비
						PRAT_AMT, --	실습비
						STD_UNI_AMT, --	학생회비
						BOOK_AMT, --	교과서비
						ENT_CON_AMT, --	입학축하금
						FOOD_AMT, --	급식비
						REQ_AMT, --	신청금액
						CNF_AMT, --	확정금액
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
						@PEB_PHM_MST_ID	PEB_PHM_MST_ID, --	인건비계획대상자ID
						dbo.XF_ADD_MONTH(PAY_YMD, 12)	REQ_YMD, --	신청일자
						A.FAM_NM	FAM_NM, --	자녀성명
						A.SCH_GRD_CD	SCH_GRD_CD, --	학력구분
						A.SCH_NM	SCH_NM, --	학교명
						A.EDU_POS	SCH_GRADE, --	학년
						A.SCE_EDU_TERM	SCH_TERM, --	학기
						0	ENT_AMT, --	입학금
						0	TUI_AMT, --	수업료
						0	OPE_SUP_AMT, --	운영지원비
						0	PRAT_AMT, --	실습비
						0	STD_UNI_AMT, --	학생회비
						0	BOOK_AMT, --	교과서비
						0	ENT_CON_AMT, --	입학축하금
						0	FOOD_AMT, --	급식비
						A.APPL_AMT	REQ_AMT, --	신청금액
						A.CONFIRM_AMT	CNF_AMT, --	확정금액
						NULL	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
				  FROM SEC_EDU A
				 WHERE SEC_EDU_ID = @SEC_EDU_ID
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 학자금 INSERT 에러[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @SEC_EDU_ID
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END

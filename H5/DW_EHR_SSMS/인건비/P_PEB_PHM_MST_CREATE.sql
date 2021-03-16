SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER     PROCEDURE [dbo].[P_PEB_PHM_MST_CREATE]
		@an_peb_base_id			NUMERIC,
		@av_company_cd      NVARCHAR(10),
		@ad_base_ymd				DATE,
		@an_org_id				NUMERIC,
		@av_emp_no				NVARCHAR(50),
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- 타임존코드
    @an_mod_user_id     NUMERIC(18,0)  ,    -- 변경자 ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 인건비계획 대상명단생성
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PHM_MST_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획 대상명단을 생성
    --<DOCLINE>   HISTORY     : 작성 임택구 2020.09.08
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @CD				NVARCHAR(50)
	  , @EMP_ID		NUMERIC
	  , @EMP_NO		NVARCHAR(50)
	  , @PEB_PHM_MST_ID	NUMERIC(38,0)

    SET @v_program_id   = 'P_PEB_PHM_MST_CREATE'
    SET @v_program_nm   = '인건비계획 대상명단 생성'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
	-- 기존ID백업
	SELECT A.PEB_PHM_MST_ID, A.EMP_NO
	  INTO #phm_mst_back
	  FROM PEB_PHM_MST A
		JOIN PHM_EMP EMP
		  ON EMP.COMPANY_CD = @av_company_cd
		 AND A.EMP_NO = EMP.EMP_NO
	   WHERE A.PEB_BASE_ID = @an_peb_base_id
	     AND (@an_org_id IS NULL OR EMP.ORG_ID = @an_org_id)
		 AND (@av_emp_no IS NULL OR EMP.EMP_NO = @av_emp_no)
	-- 기존자료삭제
	DELETE FROM PEB_PHM_MST
	  FROM PEB_PHM_MST A
		JOIN PHM_EMP EMP
		  ON EMP.COMPANY_CD = @av_company_cd
		 AND A.EMP_NO = EMP.EMP_NO
	   WHERE A.PEB_BASE_ID = @an_peb_base_id
	     AND (@an_org_id IS NULL OR EMP.ORG_ID = @an_org_id)
		 AND (@av_emp_no IS NULL OR EMP.EMP_NO = @av_emp_no)
--RETURN
	/** 인건비계획 대상명단 **/
	DECLARE CUR_PHM_EMP CURSOR LOCAL FOR
		SELECT EMP.EMP_ID, EMP.EMP_NO, B.PEB_PHM_MST_ID
			FROM PHM_EMP EMP
			LEFT OUTER JOIN #phm_mst_back B
			             ON EMP.EMP_NO = B.EMP_NO
		 WHERE EMP.COMPANY_CD = @av_company_cd
		   --AND @ad_base_ymd BETWEEN EMP.HIRE_YMD AND ISNULL(EMP.RETIRE_YMD, '2999-12-31')
			 AND @ad_base_ymd >= EMP.HIRE_YMD
			 AND @ad_base_ymd > ISNULL(EMP.RETIRE_YMD, '1900-01-01')
			 AND IN_OFFI_YN = 'Y'
			 AND (@an_org_id IS NULL OR EMP.ORG_ID = @an_org_id)
			 AND (@av_emp_no IS NULL OR EMP.EMP_NO = @av_emp_no)
	OPEN CUR_PHM_EMP
	FETCH NEXT FROM CUR_PHM_EMP INTO @EMP_ID, @EMP_NO, @PEB_PHM_MST_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> 인건비 대상명단 생성
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				IF @PEB_PHM_MST_ID IS NULL
					SET @PEB_PHM_MST_ID = NEXT VALUE FOR S_PEB_SEQUENCE
				INSERT INTO PEB_PHM_MST(
						PEB_PHM_MST_ID, --	인건비계획대상자ID
						PEB_BASE_ID, --	인건비계획기준ID
						EMP_NO, --	사번
						EMP_NM, --	성명
						HIRE_YMD, --	입사일자
						ANNUAL_CAL_YMD, --	연차기산일
						BIRTH_YMD, -- 생년월일
						WK_TYPE_CD, --	근무형태코드
						MGR_TYPE_CD, --	관리구분
						JOB_POSITION_CD, -- 직종코드
						SALARY_TYPE_CD, --	급여형태코드
						PAY_ORG_ID, --	급여부서ID
						PHM_BIZ_CD, --	소속사업장
						PAY_BIZ_CD, --	급여사업장
						PAY_GROUP_CD, -- 급여그룹코드
						POS_CD, --	직위코드 [PHM_POS_CD]
						POS_YMD, --	직위임용일자
						DUTY_CD, --	직책코드 [PHM_DUTY_CD]
						POS_GRD_CD, --	직급코드 [PHM_POS_GRD_CD]
						POS_GRD_YMD, --	직급승진일자
						YEARNUM_CD, --	호봉코드 [PHM_YEARNUM_CD]
						YEARNUM_YMD, --	호봉승급일자
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				)
				SELECT @PEB_PHM_MST_ID,
						   @an_peb_base_id, --	인건비계획기준ID
						EMP.EMP_NO, --	사번
						EMP.EMP_NM, --	성명
						EMP.HIRE_YMD, --	입사일자
						(SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=EMP.EMP_ID AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD AND BASE_TYPE_CD='ANNUAL_CAL_YMD'), -- 연차기산일
						EMP.BIRTH_YMD, -- 생년월일
						CAM.EMP_KIND_CD WK_TYPE_CD, --	근무형태코드
						CAM.MGR_TYPE_CD, --	관리구분
						CAM.JOB_POSITION_CD, -- 직종코드
						(select salary_type_cd from CNM_CNT where EMP_ID=EMP.EMP_ID and @ad_base_ymd between STA_YMD AND END_YMD) SALARY_TYPE_CD, --	급여형태코드
						CAM.ORG_ID PAY_ORG_ID, --	급여부서ID
						dbo.F_ORM_ORG_BIZ(CAM.ORG_ID, GETDATE(), 'PAY') PHM_BIZ_CD, --	소속사업장
						dbo.F_ORM_ORG_BIZ(CAM.ORG_ID, GETDATE(), 'PAY') PAY_BIZ_CD, --	급여사업장
						dbo.F_PAY_GROUP_CD(EMP.EMP_ID), -- 급여그룹코드
						CAM.POS_CD	POS_CD, --	직위코드 [PHM_POS_CD]
						--EMP.POS_YMD	POS_YMD, --	직위임용일자
						(SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=EMP.EMP_ID AND BASE_TYPE_CD='POS_YMD' AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD) AS POS_YMD,
						CAM.DUTY_CD	DUTY_CD, --	직책코드 [PHM_DUTY_CD]
						CAM.POS_GRD_CD	POS_GRD_CD, --	직급코드 [PHM_POS_GRD_CD]
						-- 직급승진일자
						CASE WHEN @av_company_cd in ('E') THEN -- 엔터인 경우 직위승진을 직급승진일로 Setting
						          (SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=EMP.EMP_ID AND BASE_TYPE_CD='POS_YMD' AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD)
						     ELSE (SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=EMP.EMP_ID AND BASE_TYPE_CD='POS_GRD_YMD' AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD)
						     END AS POS_GRD_YMD,
						EMP.YEARNUM_CD	YEARNUM_CD, --	호봉코드 [PHM_YEARNUM_CD]
						(SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=EMP.EMP_ID AND BASE_TYPE_CD='YEARNUM_YMD' AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD) AS YEARNUM_YMD,
						NULL	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
				  FROM VI_FRM_CAM_HISTORY CAM
				  JOIN VI_FRM_PHM_EMP EMP
				    ON CAM.EMP_ID = EMP.EMP_ID
				   AND @ad_base_ymd BETWEEN CAM.STA_YMD AND CAM.END_YMD
				 WHERE EMP.EMP_ID = @EMP_ID
				   AND EMP.LOCALE_CD = @av_locale_cd
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 인상율 INSERT 에러[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_EMP INTO @EMP_ID, @EMP_NO, @PEB_PHM_MST_ID
		END
	CLOSE CUR_PHM_EMP
	DEALLOCATE CUR_PHM_EMP
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END

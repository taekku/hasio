USE [dwehrdev_H5]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_PEB_PAYROLL_CREATE]
		@an_peb_base_id			NUMERIC,
		@av_company_cd			NVARCHAR(10),
		@ad_base_ymd			DATE,
		@an_pay_org_id			NUMERIC,
		@av_emp_no				NVARCHAR(10),
		@av_locale_cd			NVARCHAR(10),
		@av_tz_cd				NVARCHAR(10),    -- 타임존코드
		@an_mod_user_id			NUMERIC(18,0)  ,    -- 변경자 ID
		@av_ret_code			NVARCHAR(100)    OUTPUT,
		@av_ret_message			NVARCHAR(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 인건비계획 월별대상명단생성
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PAYROLL_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획 월별대상명단을 생성
    --<DOCLINE>   HISTORY     : 작성 임택구 2020.09.10
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
			, @PEB_PHM_MST_ID	 NUMERIC
			, @v_base_yyyy			NVARCHAR(04) -- 기준년도
			, @d_peb_sta_ymd		DATE
			, @d_peb_end_ymd		DATE
			, @d_std_ymd			DATE
			, @v_company_cd			NVARCHAR(10)
			, @v_pay_group			NVARCHAR(50) -- 급여그룹
			, @v_next_pos_grd_mm	NVARCHAR(06) -- 차기 직급 승진일자
			, @v_next_pos_mm		NVARCHAR(06) -- 차기 직위 승진일자
			, @v_next_pos_grd_cd	NVARCHAR(50) -- 차기 직급
			, @v_next_pos_cd		NVARCHAR(50) -- 차기 직위

    SET @v_program_id   = 'P_PEB_PAYROLL_CREATE'
    SET @v_program_nm   = '인건비계획 월별대상명단 생성'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);

	SELECT @d_peb_sta_ymd = STA_YMD
	     , @d_peb_end_ymd = END_YMD
		 , @d_std_ymd     = STD_YMD
		 , @v_company_cd  = COMPANY_CD
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id
	IF @@ROWCOUNT < 1
		BEGIN
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 계획이 없습니다.[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0100,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
		END
	/** 인건비계획 월별대상명단 **/
	DECLARE CUR_PHM_EMP CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID
			FROM PEB_PHM_MST MST
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
		   AND (@an_pay_org_id IS NULL OR MST.PAY_ORG_ID = @an_pay_org_id)
		   AND (ISNULL(@av_emp_no,'') = '' OR MST.EMP_NO = @av_emp_no)
	OPEN CUR_PHM_EMP
	FETCH NEXT FROM CUR_PHM_EMP INTO @PEB_PHM_MST_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> 인건비 월별대상명단 생성
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				DELETE FROM PEB_PAYROLL
				 WHERE PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				-- 급여그룹
				set @v_pay_group = dbo.F_PEB_GET_PAY_GROUP(@PEB_PHM_MST_ID)
				-- 승진년월체크 ( 직급, 직위 )
				select @v_next_pos_grd_mm = dbo.XF_TO_CHAR_D( DATEADD(YEAR, dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_POS_GRD_BASE',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, A.POS_GRD_CD, NULL, NULL, NULL,
									@d_peb_sta_ymd, 'H1' -- 'H1' : 코드1,  'E1' : 기타코드1
									)), A.POS_GRD_YMD), 'yyyy' + 
									-- 반영월
										dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_MONTH',
										NULL, NULL, NULL, NULL, NULL,
										@v_pay_group, 'POS_GRD', NULL, NULL, NULL,
										@d_peb_sta_ymd, 'H1' -- 'H1' : 코드1,  'E1' : 기타코드1
										)
									)
					 , @v_next_pos_grd_cd = dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_POS_GRD_BASE',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, A.POS_GRD_CD, NULL, NULL, NULL,
									@d_peb_sta_ymd, 'H2' -- 'H1' : 코드1,  'E1' : 기타코드1
									)
					 , @v_next_pos_mm = dbo.XF_TO_CHAR_D( DATEADD(YEAR, dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_POS_BASE',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, A.POS_GRD_CD, NULL, NULL, NULL,
									@d_peb_sta_ymd, 'H1' -- 'H1' : 코드1,  'E1' : 기타코드1
									)), A.POS_GRD_YMD), 'yyyy' + 
									-- 반영월
										dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_MONTH',
										NULL, NULL, NULL, NULL, NULL,
										@v_pay_group, 'POS', NULL, NULL, NULL,
										@d_peb_sta_ymd, 'H1' -- 'H1' : 코드1,  'E1' : 기타코드1
										)
									)
					 , @v_next_pos_cd = dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_POS_BASE',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, A.POS_CD, NULL, NULL, NULL,
									@d_peb_sta_ymd, 'H2' -- 'H1' : 코드1,  'E1' : 기타코드1
									)
				  FROM PEB_PHM_MST A
				 WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID

				INSERT INTO PEB_PAYROLL(
						PEB_PAYROLL_ID, --	월별계획인원ID
						PEB_PHM_MST_ID, --	인건비계획대상자ID
						PEB_YM, --	년월
						JOB_POSITION_CD, -- 직종코드
						POS_GRD_CD, --	직급코드 [PHM_POS_GRD_CD]
						POS_CD, --	직위코드 [PHM_POS_CD]
						DUTY_CD, --	직책코드 [PHM_DUTY_CD]
						YEARNUM_CD, --	호봉코드 [PHM_YEARNUM_CD]
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_ID,
						MST.PEB_PHM_MST_ID, --	인건비계획대상자ID
						CALENDAR.MONTH_ID PEB_YM, --	년월
						MST.JOB_POSITION_CD, -- 직종코드
						--MST.POS_GRD_CD, --	직급코드 [PHM_POS_GRD_CD]
						CASE WHEN @v_next_pos_grd_mm <= MONTH_ID AND SUBSTRING(@v_next_pos_grd_mm,5,2) <= MM THEN @v_next_pos_grd_cd
						     ELSE MST.POS_GRD_CD END,
						--MST.POS_CD, --	직위코드 [PHM_POS_CD]
						CASE WHEN @v_next_pos_mm <= MONTH_ID AND SUBSTRING(@v_next_pos_mm,5,2) <= MM THEN @v_next_pos_cd
						     ELSE MST.POS_CD END, -- 차기 직위코드
						MST.DUTY_CD, --	직책코드 [PHM_DUTY_CD]
						CASE WHEN (SELECT SYS_CD FROM FRM_CODE WHERE COMPANY_CD=@v_company_cd AND CD_KIND='PAY_SALARY_TYPE_CD' AND CD=MST.SALARY_TYPE_CD AND @d_std_ymd BETWEEN STA_YMD AND END_YMD)
						          = '002' THEN -- 호봉제이면
								  CASE WHEN dbo.XF_TO_CHAR_D( MST.YEARNUM_YMD, 'MM') <= CALENDAR.MM THEN
								  RIGHT( dbo.XF_TO_CHAR_N( dbo.XF_TO_NUMBER( MST.YEARNUM_CD ) - 2, '0000') , LEN(MST.YEARNUM_CD))
								       ELSE MST.YEARNUM_CD END
							 ELSE MST.YEARNUM_CD END AS NEW_YEARNUM_CD, --	호봉코드 [PHM_YEARNUM_CD]
						NULL	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
				  FROM PEB_PHM_MST MST
				  INNER JOIN (SELECT DISTINCT SUBSTRING(YMD,1,6) MONTH_ID, SUBSTRING(YMD, 5, 2) MM
									FROM FRM_CALENDAR C
									WHERE YMD BETWEEN @d_peb_sta_ymd and @d_peb_end_ymd) CALENDAR
				   ON dbo.XF_TO_CHAR_D( MST.HIRE_YMD, 'YYYYMM') <= MONTH_ID
				 WHERE MST.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 월별대상명단생성중 에러 발생했습니다.[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_EMP INTO @PEB_PHM_MST_ID
		END
	CLOSE CUR_PHM_EMP
	DEALLOCATE CUR_PHM_EMP
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END

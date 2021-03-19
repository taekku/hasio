SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_PEB_CNM_CNT_CREATE]
	@av_company_cd      nVARCHAR(10),       -- 인사영역
    @av_locale_cd       nVARCHAR(10),       -- 지역코드
    @an_peb_base_id     NUMERIC(38,0),      -- 인건비기준id
	@ad_base_ymd		DATE,
	@av_emp_no			NVARCHAR(10),		-- 대상자
    @av_tz_cd           NVARCHAR(10),		-- 타임존코드
    @an_mod_user_id     NUMERIC(38,0)  ,    -- 변경자 ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 인건비계획 연봉관리 생성
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PHM_MST_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획 연봉관리를 생성
    --<DOCLINE>   HISTORY     : 작성 임택구 2020.09.08
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id		NVARCHAR(30)
      , @v_program_nm		NVARCHAR(100)
      , @v_ret_code			NVARCHAR(100)
      , @v_ret_message		NVARCHAR(500)
	  , @PEB_PHM_MST_ID		NUMERIC(38)
	  , @EMP_NO				NVARCHAR(50)
	  , @POS_GRD_CD			NVARCHAR(50)
	  , @POS_GRD_YMD		DATE
	  , @PEB_CNM_CNT_ID		NUMERIC(38)
	  , @n_peb_cnm_cnt_id	NUMERIC(38)
	  , @v_base_yyyy		NVARCHAR(04) -- 인건비 년도
	  , @n_up_rate			NUMERIC(8,4) -- 인상율
	  , @v_peb_mm			NVARCHAR(02) -- 인상반영월
	  , @d_first_sta_ymd	DATE -- 최초시작일
	  , @d_sta_ymd			DATE -- 시작일
	  , @d_end_ymd			DATE -- 종료일
	  , @d_cnm_sta_ymd		DATE -- 시작일
	  , @d_cnm_end_ymd		DATE -- 종료일
	  , @v_pay_group		NVARCHAR(50) -- 급여그룹
	  , @n_year_limit		NUMERIC(02) -- 승진년한
	  , @v_next_pos_grd_cd	NVARCHAR(50) -- 승진직급
	  , @n_pos_grd_base_amt	NUMERIC(18) -- 승진기본연봉
	  , @v_prm_appl_ym		NVARCHAR(50) -- 직급승진반영월

	SET NOCOUNT ON;

    SET @v_program_id   = 'P_PEB_CNM_CNT_CREATE'
    SET @v_program_nm   = '인건비계획 연봉관리 복사'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);

	/** 인건비계획 연봉삭제 **/
	DELETE
	  FROM A
			FROM PEB_CNM_CNT A
			JOIN PEB_PHM_MST MST
				ON A.PEB_BASE_ID = MST.PEB_BASE_ID
				AND A.EMP_NO = MST.EMP_NO
			JOIN VI_FRM_PHM_EMP EMP
				ON MST.PEB_BASE_ID = @an_peb_base_id
				AND MST.EMP_NO = EMP.EMP_NO
				AND EMP.COMPANY_CD = @av_company_cd
				AND EMP.LOCALE_CD = @av_locale_cd
			JOIN CNM_CNT CNM
				ON CNM.EMP_ID = EMP.EMP_ID
				AND @ad_base_ymd BETWEEN CNM.STA_YMD AND CNM.END_YMD
			WHERE A.PEB_BASE_ID = @an_peb_base_id
			  AND (@av_emp_no IS NULL OR MST.EMP_NO = @av_emp_no)
	/** 인건비계획 대상명단 **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID, EMP_NO, POS_GRD_CD, POS_YMD-- POS_GRD_YMD
		  FROM PEB_PHM_MST MST
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
		   AND (@av_emp_no IS NULL OR MST.EMP_NO = @av_emp_no)

	-- 인건비기준
	SELECT @v_base_yyyy = BASE_YYYY
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id
	IF @@ROWCOUNT < 1
		BEGIN
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = dbo.F_FRM_ERRMSG('인건비기준 읽어오기 에러[ERR]',
																					@v_program_id,  120,  NULL, NULL);
				RETURN
		END
	-- 연봉인상율
	SELECT @n_up_rate = (PEB_RATE / 100.0) + 1 -- 연봉인상율
		    , @v_peb_mm = A.PEB_YM -- 연봉인상월
		FROM PEB_RATE A
		WHERE PEB_BASE_ID = @an_peb_base_id
		AND A.PEB_TYPE_CD = '110' -- 110:연봉인상율, 120:호봉인상율
	IF @@ROWCOUNT < 1
		BEGIN
			SELECT @n_up_rate = NULL, @v_peb_mm = NULL
		END
		
    --<DOCLINE> ********************************************************
    --<DOCLINE> 인건비 계약 생성
    --<DOCLINE> ********************************************************
	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST
				INTO @PEB_PHM_MST_ID, @EMP_NO, @POS_GRD_CD, @POS_GRD_YMD
	WHILE @@FETCH_STATUS = 0
		BEGIN
			-- 급여그룹
			set @v_pay_group = dbo.F_PEB_GET_PAY_GROUP(@PEB_PHM_MST_ID)
			BEGIN Try
				-- 계약복사
				INSERT INTO PEB_CNM_CNT(
						PEB_CNM_CNT_ID, --	인건비계획연봉ID
						PEB_BASE_ID, --	인건비계획기준ID
						COMPANY_CD, --	인사영역코드
						EMP_NO, --	사번
						SALARY_TYPE_CD, --	급여유형
						STA_YMD, --	계약시작일자
						END_YMD, --	계약종료일자
						PRE_END_YMD, --	계약종료일
						PAY_POS_GRD_CD, --	급여직급코드[PAY_POS_GRD_CD]
						PAY_GRADE, --	급여호봉[PAY_GRADE]
						PAY_JOP_CD, --	급여직군[PAY_JOP_CD]
						OLD_CNT_SALARY, --	이전고정급
						CNT_SALARY, --	연간고정급
						BASE_SALARY, --	기본급
						BP01, --	보전금액
						BP02, --	고정(연장)
						BP03, --	고정(야간)
						BP04, --	고정(휴일)
						BP05, --	소정근로시간
						BP06, --	수습시작일자
						BP07, --	수습종료일자
						BP08, --	월상여미지급여부
						BP09, --	보전수당지급율
						BP10, --	BP10
						BP12, --	기본급산정유형[PAY_BAS_TYPE_CD]
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE AS PEB_CNM_CNT_ID,
						   @an_peb_base_id PEB_BASE_ID, --	인건비계획기준ID
						@av_company_cd COMPANY_CD, --	인사영역코드
						MST.EMP_NO, --	사번
						CNM.SALARY_TYPE_CD SALARY_TYPE_CD, --	급여유형
						CNM.STA_YMD	STA_YMD, --	계약시작일자
						--ISNULL(@d_end_ymd, CNM.END_YMD)	END_YMD, --	계약종료일자
						'29991231'	as END_YMD, --	계약종료일자
						CNM.PRE_END_YMD	PRE_END_YMD, --	계약종료일
						MST.POS_GRD_CD	PAY_POS_GRD_CD, --	급여직급코드[PAY_POS_GRD_CD]
						CNM.PAY_GRADE	PAY_GRADE, --	급여호봉[PAY_GRADE]
						CNM.PAY_JOP_CD	PAY_JOP_CD, --	급여직군[PAY_JOP_CD]
						CNM.CNT_SALARY	OLD_CNT_SALARY, --	이전고정급
						CNM.CNT_SALARY	AS CNT_SALARY, --	연간고정급
						CNM.BASE_SALARY	AS BASE_SALARY, --	기본급
						CNM.BP01	BP01, --	보전금액
						CNM.BP02	BP02, --	고정(연장)
						CNM.BP03	BP03, --	고정(야간)
						CNM.BP04	BP04, --	고정(휴일)
						CNM.BP05	BP05, --	소정근로시간
						CNM.BP06	BP06, --	수습시작일자
						CNM.BP07	BP07, --	수습종료일자
						CNM.BP08	BP08, --	월상여미지급여부
						CNM.BP09	BP09, --	보전수당지급율
						CNM.BP10	BP10, --	BP10
						CNM.BP12	BP12, --	기본급산정유형[PAY_BAS_TYPE_CD]
						CNM.NOTE	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
				  FROM PEB_PHM_MST MST
				  INNER JOIN VI_FRM_PHM_EMP EMP
					  ON MST.PEB_BASE_ID = @an_peb_base_id
					 AND MST.EMP_NO = EMP.EMP_NO
					 AND EMP.COMPANY_CD = @av_company_cd
					 AND EMP.LOCALE_CD = @av_locale_cd
				  INNER JOIN CNM_CNT CNM
					  ON CNM.EMP_ID = EMP.EMP_ID
					 AND @ad_base_ymd BETWEEN CNM.STA_YMD AND CNM.END_YMD
				 WHERE MST.EMP_NO = @EMP_NO
				-- 연봉인상율 반영
				IF @@ROWCOUNT > 0
					IF @n_up_rate IS NOT NULL
						BEGIN
							--PRINT '연봉인상율 반영'
							SELECT @d_sta_ymd = dbo.XF_TO_DATE( @v_base_yyyy + @v_peb_mm + '01', 'yyyymmdd')
								 , @d_end_ymd = dbo.XF_DATEADD( dbo.XF_TO_DATE( @v_base_yyyy + @v_peb_mm + '01', 'yyyymmdd'), - 1)
							DECLARE CUR_PEB_CNM_CNT CURSOR LOCAL FOR
								SELECT PEB_CNM_CNT_ID, STA_YMD, END_YMD
								  FROM PEB_CNM_CNT
								 WHERE PEB_BASE_ID = @an_peb_base_id
								   AND EMP_NO = @EMP_NO
								   AND @d_sta_ymd BETWEEN STA_YMD AND END_YMD
							OPEN CUR_PEB_CNM_CNT
							FETCH NEXT FROM CUR_PEB_CNM_CNT
										INTO @PEB_CNM_CNT_ID, @d_cnm_sta_ymd, @d_cnm_end_ymd
							WHILE @@FETCH_STATUS = 0
								BEGIN
									IF @d_cnm_sta_ymd < @d_sta_ymd
										BEGIN
											--PRINT '쪼개기-인상'
											UPDATE PEB_CNM_CNT
											   SET END_YMD = @d_end_ymd
											 WHERE PEB_CNM_CNT_ID = @PEB_CNM_CNT_ID
											select @n_peb_cnm_cnt_id = NEXT VALUE FOR S_PEB_SEQUENCE
											INSERT INTO PEB_CNM_CNT(
												PEB_CNM_CNT_ID, --	인건비계획연봉ID
												PEB_BASE_ID, --	인건비계획기준ID
												COMPANY_CD, --	인사영역코드
												EMP_NO, --	사번
												SALARY_TYPE_CD, --	급여유형
												STA_YMD, --	계약시작일자
												END_YMD, --	계약종료일자
												PRE_END_YMD, --	계약종료일
												PAY_POS_GRD_CD, --	급여직급코드[PAY_POS_GRD_CD]
												PAY_GRADE, --	급여호봉[PAY_GRADE]
												PAY_JOP_CD, --	급여직군[PAY_JOP_CD]
												OLD_CNT_SALARY, --	이전고정급
												CNT_SALARY, --	연간고정급
												BASE_SALARY, --	기본급
												BP01, --	보전금액
												BP02, --	고정(연장)
												BP03, --	고정(야간)
												BP04, --	고정(휴일)
												BP05, --	소정근로시간
												BP06, --	수습시작일자
												BP07, --	수습종료일자
												BP08, --	월상여미지급여부
												BP09, --	보전수당지급율
												BP10, --	BP10
												BP12, --	기본급산정유형[PAY_BAS_TYPE_CD]
												NOTE, --	비고
												MOD_USER_ID, --	변경자
												MOD_DATE, --	변경일
												TZ_CD, --	타임존코드
												TZ_DATE --	타임존일시
										)
										SELECT @n_peb_cnm_cnt_id AS PEB_CNM_CNT_ID, --	인건비계획연봉ID
												PEB_BASE_ID, --	인건비계획기준ID
												COMPANY_CD, --	인사영역코드
												EMP_NO, --	사번
												SALARY_TYPE_CD, --	급여유형
												@d_sta_ymd STA_YMD, --	계약시작일자
												@d_cnm_end_ymd END_YMD, --	계약종료일자
												PRE_END_YMD, --	계약종료일
												PAY_POS_GRD_CD, --	급여직급코드[PAY_POS_GRD_CD]
												PAY_GRADE, --	급여호봉[PAY_GRADE]
												PAY_JOP_CD, --	급여직군[PAY_JOP_CD]
												OLD_CNT_SALARY, --	이전고정급
												dbo.XF_CEIL(CNT_SALARY * @n_up_rate, -1) AS CNT_SALARY, --	연간고정급
												dbo.XF_CEIL(BASE_SALARY * @n_up_rate, -1) AS BASE_SALARY, --	기본급
												BP01, --	보전금액
												BP02, --	고정(연장)
												BP03, --	고정(야간)
												BP04, --	고정(휴일)
												BP05, --	소정근로시간
												BP06, --	수습시작일자
												BP07, --	수습종료일자
												BP08, --	월상여미지급여부
												BP09, --	보전수당지급율
												BP10, --	BP10
												BP12, --	기본급산정유형[PAY_BAS_TYPE_CD]
												NOTE, --	비고
												MOD_USER_ID, --	변경자
												MOD_DATE, --	변경일
												TZ_CD, --	타임존코드
												TZ_DATE --	타임존일시
										  FROM PEB_CNM_CNT
										 WHERE PEB_CNM_CNT_ID = @PEB_CNM_CNT_ID
										END
									FETCH NEXT FROM CUR_PEB_CNM_CNT
												INTO @PEB_CNM_CNT_ID, @d_cnm_sta_ymd, @d_cnm_end_ymd
								END
							
							CLOSE CUR_PEB_CNM_CNT
							DEALLOCATE CUR_PEB_CNM_CNT
						END
				-- 승진처리
				SET @n_peb_cnm_cnt_id = 0
				--PRINT '승진처리'
				--DECLARE CUR_PAYROLL CURSOR LOCAL FOR
				IF OBJECT_ID('tempdb..#TEMP_PAYROLL') IS NOT NULL
					DROP TABLE #TEMP_PAYROLL
					SELECT MST.EMP_NO, CNM.PEB_CNM_CNT_ID, CNM.STA_YMD, CNM.END_YMD, PAY.PEB_YM, CNM.PAY_POS_GRD_CD, PAY.POS_GRD_CD
					  INTO #TEMP_PAYROLL
					  FROM PEB_PHM_MST MST
					  JOIN PEB_CNM_CNT CNM
					    ON MST.PEB_BASE_ID = CNM.PEB_BASE_ID
					   AND MST.EMP_NO = CNM.EMP_NO
					  JOIN PEB_PAYROLL PAY
					    ON MST.PEB_PHM_MST_ID = PAY.PEB_PHM_MST_ID
					   AND PAY.PEB_YM BETWEEN FORMAT(CNM.STA_YMD,'yyyyMM') AND FORMAT(CNM.END_YMD, 'yyyyMM')
					 WHERE MST.PEB_BASE_ID = @an_peb_base_id
					   AND MST.EMP_NO = @EMP_NO
					   --AND 1 = 2
					   --AND CNM.PAY_POS_GRD_CD != PAY.POS_GRD_CD -- 직급코드가 틀린경우
					 ORDER BY MST.EMP_NO, PAY.PEB_YM
				DECLARE CUR_PAYROLL CURSOR LOCAL FOR
				  SELECT PEB_CNM_CNT_ID, STA_YMD, END_YMD, PEB_YM, PAY_POS_GRD_CD, POS_GRD_CD
				    FROM #TEMP_PAYROLL
				   ORDER BY EMP_NO, PEB_YM
				DECLARE @pay_n_peb_cnm_cnt_id numeric(38)
				      , @pay_d_sta_ymd date
					  , @pay_end_ymd date
					  , @pay_peb_ym nvarchar(6)
					  , @pay_pay_pos_grd_cd nvarchar(10)
					  , @pay_pos_grd_cd nvarchar(10)
					  , @work_pos_grd_cd nvarchar(10) = ''
					  , @work_pay_peb_ym nvarchar(10) = ''
					  , @work_sta_ymd date
					  , @work_end_ymd date
					  , @work_cnm_cnt_id numeric(38,0) = 0
				OPEN CUR_PAYROLL
				FETCH NEXT FROM CUR_PAYROLL
							INTO @pay_n_peb_cnm_cnt_id, @pay_d_sta_ymd
							  , @pay_end_ymd, @pay_peb_ym
							  , @pay_pay_pos_grd_cd, @pay_pos_grd_cd
				WHILE @@FETCH_STATUS = 0
					BEGIN
										--print ',pay_peb_ym='           + ISNULL(@pay_peb_ym , '')
										--    + ',pay_n_peb_cnm_cnt_id=' + ISNULL(format(@pay_n_peb_cnm_cnt_id,'')   , '')
										--    + ',pay_d_sta_ymd='        + ISNULL(format(@pay_d_sta_ymd, 'yyyyMMdd') , '')
										--    + ',pay_end_ymd='          + ISNULL(format(@pay_end_ymd, 'yyyyMMdd')   , '')
										--    + ',work_cnm_cnt_id='      + ISNULL(format(@work_cnm_cnt_id,'')		   , '')
										--    + ',work_sta_ymd='         + ISNULL(format(@work_sta_ymd, 'yyyyMMdd')  , '')
										--    + ',work_end_ymd='         + ISNULL(format(@work_end_ymd, 'yyyyMMdd')  , '')

						IF @work_pos_grd_cd != @pay_pay_pos_grd_cd
						OR @work_pos_grd_cd != @pay_pos_grd_cd
							BEGIN
								IF @pay_pay_pos_grd_cd != @pay_pos_grd_cd AND @work_pos_grd_cd != @pay_pos_grd_cd
									BEGIN	-- 틀린면 쪼갠다.
										select @work_pos_grd_cd = @pay_pos_grd_cd
										-- 기본연봉
					select @n_pos_grd_base_amt = dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_POS_GRD_BASE_AMT',
										NULL, NULL, NULL, NULL, NULL,
										@v_pay_group, @work_pos_grd_cd, NULL, NULL, NULL,
										@v_base_yyyy + '1231',
										'H1' -- 'H1' : 코드1,  'E1' : 기타코드1
										))
					set @n_pos_grd_base_amt = dbo.XF_CEIL(@n_pos_grd_base_amt / 12, -1);
					if @n_pos_grd_base_amt <= 0
						set @n_pos_grd_base_amt = NULL
										IF @work_cnm_cnt_id = 0
											set @work_cnm_cnt_id = @pay_n_peb_cnm_cnt_id
										set @work_sta_ymd = dbo.XF_TO_DATE(@pay_peb_ym + '01', 'yyyyMMdd')
										set @work_end_ymd = dbo.XF_DATEADD(@work_sta_ymd, -1)
										IF @pay_peb_ym > FORMAT(@pay_d_sta_ymd, 'yyyyMM')
											BEGIN
												--PRINT '쪼개기1:' + @pay_peb_ym
												UPDATE PEB_CNM_CNT
												   SET END_YMD = @work_end_ymd
												 WHERE PEB_CNM_CNT_ID = @work_cnm_cnt_id
												--
												select @n_peb_cnm_cnt_id = NEXT VALUE FOR S_PEB_SEQUENCE
											END
										ELSE
											BEGIN
												--PRINT '유지:' + @pay_peb_ym
												UPDATE PEB_CNM_CNT
												   SET BASE_SALARY = ISNULL(@n_pos_grd_base_amt, BASE_SALARY)
												     , PAY_POS_GRD_CD = @work_pos_grd_cd
													-- , END_YMD = @work_end_ymd
												 WHERE PEB_CNM_CNT_ID = @work_cnm_cnt_id
											END
										IF @pay_peb_ym > FORMAT(@pay_d_sta_ymd, 'yyyyMM')
										BEGIN
											INSERT INTO PEB_CNM_CNT(
												PEB_CNM_CNT_ID, --	인건비계획연봉ID
												PEB_BASE_ID, --	인건비계획기준ID
												COMPANY_CD, --	인사영역코드
												EMP_NO, --	사번
												SALARY_TYPE_CD, --	급여유형
												STA_YMD, --	계약시작일자
												END_YMD, --	계약종료일자
												PRE_END_YMD, --	계약종료일
												PAY_POS_GRD_CD, --	급여직급코드[PAY_POS_GRD_CD]
												PAY_GRADE, --	급여호봉[PAY_GRADE]
												PAY_JOP_CD, --	급여직군[PAY_JOP_CD]
												OLD_CNT_SALARY, --	이전고정급
												CNT_SALARY, --	연간고정급
												BASE_SALARY, --	기본급
												BP01, --	보전금액
												BP02, --	고정(연장)
												BP03, --	고정(야간)
												BP04, --	고정(휴일)
												BP05, --	소정근로시간
												BP06, --	수습시작일자
												BP07, --	수습종료일자
												BP08, --	월상여미지급여부
												BP09, --	보전수당지급율
												BP10, --	BP10
												BP12, --	기본급산정유형[PAY_BAS_TYPE_CD]
												NOTE, --	비고
												MOD_USER_ID, --	변경자
												MOD_DATE, --	변경일
												TZ_CD, --	타임존코드
												TZ_DATE --	타임존일시
										)
										SELECT @n_peb_cnm_cnt_id AS PEB_CNM_CNT_ID, --	인건비계획연봉ID
												PEB_BASE_ID, --	인건비계획기준ID
												COMPANY_CD, --	인사영역코드
												EMP_NO, --	사번
												SALARY_TYPE_CD, --	급여유형
												@work_sta_ymd STA_YMD, --	계약시작일자
												@pay_end_ymd END_YMD, --	계약종료일자
												PRE_END_YMD, --	계약종료일
												@work_pos_grd_cd PAY_POS_GRD_CD, --	급여직급코드[PAY_POS_GRD_CD]
												PAY_GRADE, --	급여호봉[PAY_GRADE]
												PAY_JOP_CD, --	급여직군[PAY_JOP_CD]
												OLD_CNT_SALARY, --	이전고정급
												CNT_SALARY, --	연간고정급
												ISNULL(@n_pos_grd_base_amt, BASE_SALARY) AS BASE_SALARY, --	기본급
												BP01, --	보전금액
												BP02, --	고정(연장)
												BP03, --	고정(야간)
												BP04, --	고정(휴일)
												BP05, --	소정근로시간
												BP06, --	수습시작일자
												BP07, --	수습종료일자
												BP08, --	월상여미지급여부
												BP09, --	보전수당지급율
												BP10, --	BP10
												BP12, --	기본급산정유형[PAY_BAS_TYPE_CD]
												NOTE, --	비고
												MOD_USER_ID, --	변경자
												MOD_DATE, --	변경일
												TZ_CD, --	타임존코드
												TZ_DATE --	타임존일시
										  FROM PEB_CNM_CNT
										 WHERE PEB_CNM_CNT_ID = @work_cnm_cnt_id
											set @work_cnm_cnt_id = @n_peb_cnm_cnt_id
										END
										--print 'work_cnm_cnt_id=' + format(@work_cnm_cnt_id,'')
										--    + ',pay_peb_ym=' + @pay_peb_ym
										--    + ',work_sta_ymd=' + format(@work_sta_ymd, 'yyyyMMdd')
										--    + ',pay_end_ymd=' + format(@pay_end_ymd, 'yyyyMMdd')
									END
							END
							
						IF FORMAT(@pay_end_ymd, 'yyyyMM') = @pay_peb_ym
							set @work_cnm_cnt_id = 0
						set @work_pos_grd_cd = @pay_pos_grd_cd
						FETCH NEXT FROM CUR_PAYROLL
									INTO @pay_n_peb_cnm_cnt_id, @pay_d_sta_ymd
									  , @pay_end_ymd, @pay_peb_ym
									  , @pay_pay_pos_grd_cd, @pay_pos_grd_cd
					END
				CLOSE CUR_PAYROLL
				DEALLOCATE CUR_PAYROLL
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 연봉관리 INSERT 에러[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_MST
						INTO @PEB_PHM_MST_ID, @EMP_NO, @POS_GRD_CD, @POS_GRD_YMD
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END

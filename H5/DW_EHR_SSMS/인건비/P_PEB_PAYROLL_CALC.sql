SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER     PROCEDURE [dbo].[P_PEB_PAYROLL_CALC]
	@an_peb_base_id		NUMERIC,
	@av_company_cd      NVARCHAR(10),
	@ad_base_ymd		DATE,
	@av_cal_emp_no		NVARCHAR(MAX),
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- 타임존코드
    @an_mod_user_id     NUMERIC(18,0)  ,    -- 변경자 ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 인건비계획 인건비계산
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PAYROLL_CALC
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획 인건비계산
    --<DOCLINE>   HISTORY     : 작성 임택구 2020.09.15
    --<DOCLINE> ***************************************************************************
BEGIN
	SET NOCOUNT ON;
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id		NVARCHAR(30)
      , @v_program_nm		NVARCHAR(100)
      , @v_ret_code			NVARCHAR(100)
      , @v_ret_message		NVARCHAR(500)

	  , @PEB_PHM_MST_ID		NUMERIC
	  , @EMP_NO				NVARCHAR(20)
	  , @d_peb_sta_ymd		DATE
	  , @d_peb_end_ymd		DATE
	  , @v_company_cd		NVARCHAR(10)
	  , @v_pay_item_cd		NVARCHAR(10)
	  , @v_salary_sys_cd	NVARCHAR(10)

	  , @n_base_salary		NUMERIC -- 기본급
	  , @n_base_hour		NUMERIC -- 소정근로시간
	  , @n_ordwage_hour		NUMERIC(18) -- 통상임금
	  , @n_ordwage_amt		NUMERIC(18) -- 통상임금
	  , @n_dtm_year_amt		NUMERIC(18) -- 연차금액
	  , @n_insur_rate		NUMERIC(5,3) -- 보험요율
	  , @n_peb_rate			NUMERIC(18,2) -- 인상율/금액

	DECLARE @tmp_emp_no TABLE (
		EMP_NO NVARCHAR(20),
		PRIMARY KEY (EMP_NO)
	)

	SET @v_program_id   = 'P_PEB_PAYROLL_CALC'
	SET @v_program_nm   = '인건비계획 인건비계산'
	SET @av_ret_code    = 'SUCCESS!'
	SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
										@v_program_id,  0000,  NULL, NULL);

	SELECT @d_peb_sta_ymd = STA_YMD
	     , @d_peb_end_ymd = END_YMD
		 , @v_company_cd = COMPANY_CD
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
	-- 대상자를 선택
	INSERT INTO @tmp_emp_no(EMP_NO)
	SELECT ITEMS
	  FROM dbo.fn_split_array(@av_cal_emp_no, ',')
	IF @av_cal_emp_no IS NULL
		INSERT INTO @tmp_emp_no(EMP_NO)
		SELECT EMP_NO
		  FROM PEB_PHM_MST
		 WHERE PEB_BASE_ID = @an_peb_base_id
	-- 작업전 자료 삭제
	DELETE FROM A
	  FROM PEB_PAYROLL_DETAIL A
	  JOIN PEB_PAYROLL B
	    ON A.PEB_PAYROLL_ID = B.PEB_PAYROLL_ID
	  JOIN PEB_PHM_MST MST
	    ON B.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	  JOIN @tmp_emp_no EMP
	    ON MST.EMP_NO = EMP.EMP_NO

	/** 인건비계획 월별대상명단 **/
	DECLARE CUR_PHM_EMP CURSOR LOCAL FOR
		SELECT MST.PEB_PHM_MST_ID
		     , MST.EMP_NO
			 , (SELECT SYS_CD FROM FRM_CODE WHERE COMPANY_CD = @v_company_cd
											  AND CD_KIND='PAY_SALARY_TYPE_CD' AND CD = MST.SALARY_TYPE_CD)
				AS SALARY_SYS_CD --급여유형 type 구분 (001(연봉제),002(호봉제),003(일급제),004(시급제))
			FROM PEB_PHM_MST MST
			JOIN @tmp_emp_no EMP
			  ON MST.PEB_BASE_ID = @an_peb_base_id
			 AND MST.EMP_NO = EMP.EMP_NO
		 WHERE (1=1)
		   AND MST.PEB_BASE_ID = @an_peb_base_id
		 ORDER BY MST.PEB_PHM_MST_ID

	OPEN CUR_PHM_EMP
	FETCH NEXT FROM CUR_PHM_EMP INTO @PEB_PHM_MST_ID, @EMP_NO, @v_salary_sys_cd

    --<DOCLINE> ********************************************************
    --<DOCLINE> 인건비 월별대상명단 생성
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT 'START:' + @EMP_NO
			BEGIN TRY
				-- 기본금
				SET @v_pay_item_cd = 'P001'
				-- @v_salary_sys_cd : 001(연봉제),002(호봉제),003(일급제),004(시급제)
			PRINT '@v_salary_sys_cd:' + @v_salary_sys_cd
				IF @v_salary_sys_cd = '001' -- 연봉제
					BEGIN
						-- 기본금
						SET @v_pay_item_cd = 'P001'
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								A.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd	PAY_ITEM_CD, --	급여항목코드 -- 기본금
								C.BASE_SALARY AS	CAM_AMT, --	계산금액
								'연봉-기본급'	NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL A
						  JOIN PEB_CNM_CNT C
							ON A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						   AND C.PEB_BASE_ID = @an_peb_base_id
						   AND C.EMP_NO = @EMP_NO
						   AND A.PEB_YM BETWEEN dbo.XF_TO_CHAR_D(STA_YMD, 'yyyymm') AND dbo.XF_TO_CHAR_D( END_YMD, 'yyyymm')
						-- 보전금액
						SET @v_pay_item_cd = 'P003'
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								A.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd	PAY_ITEM_CD, --	급여항목코드 -- 보전금액
								C.BP01 AS	CAM_AMT, --	계산금액
								'연봉-보전금액'	NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL A
						  JOIN PEB_CNM_CNT C
							ON A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						   AND C.PEB_BASE_ID = @an_peb_base_id
						   AND C.EMP_NO = @EMP_NO
						   AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN STA_YMD AND END_YMD
						   AND ISNULL(C.BP01,0) <> 0
					END
				ELSE IF @v_salary_sys_cd = '002' -- 호봉제
					BEGIN
						-- 기본금
						SET @v_pay_item_cd = 'P001'
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								A.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd	PAY_ITEM_CD, --	급여항목코드 -- 기본금
								B.PAY_AMT AS	CAM_AMT, --	계산금액
								'호봉-기본급'	NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL A
						  JOIN PEB_PHM_MST M
						    ON A.PEB_PHM_MST_ID = M.PEB_PHM_MST_ID
						  LEFT OUTER JOIN PAY_SHIP_RATE S
						               ON M.PAY_ORG_ID = S.PAY_ORG_ID
									  AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN S.STA_YMD AND S.END_YMD
						  JOIN PEB_PAY_HOBONG B
							ON B.PEB_BASE_ID = @an_peb_base_id
						   AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN B.STA_YMD AND B.END_YMD
						   AND M.PAY_BIZ_CD = B.BIZ_CD
						   AND A.POS_GRD_CD = B.PAY_POS_GRD_CD
						   AND A.YEARNUM_CD = B.PAY_GRADE
						   AND M.PAY_BIZ_CD = B.BIZ_CD
						   AND (A.POS_GRD_CD != '600'
						         OR     A.POS_CD = B.POS_CD
						            AND S.SHIP_CD = B.SHIP_CD -- 선박분류
						            AND S.SHIP_CD_D = B.SHIP_CD_D -- 선박상세분류
						       )
						 WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						   --AND 
						IF @@ROWCOUNT < 1
							BEGIN
								SET @av_ret_message = dbo.F_FRM_ERRMSG( '사번[' + @EMP_NO + ']에 대한 기본급을 알 수 없습니다.[ERR]' ,
														@v_program_id,  1009,  null, null
													)
								SET @av_ret_code    = 'FAILURE!'
								RETURN
							END
					END
				--ELSE IF @v_salary_sys_cd = '003' -- 일급제
				--	BEGIN
				--	END
				--ELSE IF @v_salary_sys_cd = '002' -- 시급제
				--	BEGIN
				--	END
				ELSE
					BEGIN
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '사번[' + @EMP_NO + ']에 대한 급여유형[' +ISNULL(@v_salary_sys_cd,'NULL')+ ']의 기본급을 알 수 없습니다.[ERR]' ,
												@v_program_id,  1009,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
					END
					
				---------------------------
				-- 정기상여금
				---------------------------
				set @v_pay_item_cd = 'P300' -- 상여금
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	인건비계산결과ID
					PEB_PAYROLL_ID, --	월별계획인원ID
					PAY_ITEM_CD, --	급여항목코드
					CAM_AMT, --	계산금액
					NOTE, --	비고
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	월별계획인원ID
						@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
						CASE WHEN B.PEB_APP_BASE_CD='20' THEN
							B.PEB_RATE / 100 * (SELECT ISNULL(SUM(CAM_AMT),0) FROM PEB_PAYROLL_DETAIL
							                           WHERE PEB_PAYROLL_ID=A.PEB_PAYROLL_ID
													     AND PAY_ITEM_CD IN ('P001','P003'))
							ELSE 0 END AS	CAM_AMT, --	계산금액
						'기준' NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
					FROM PEB_PAYROLL A
					JOIN PEB_RATE B
					  ON B.PEB_BASE_ID = @an_peb_base_id
					 AND B.PEB_TYPE_CD = '130' -- 상여금
					WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				---------------------------
				-- 성과급
				---------------------------
				set @v_pay_item_cd = 'P303' -- 성과급
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	인건비계산결과ID
					PEB_PAYROLL_ID, --	월별계획인원ID
					PAY_ITEM_CD, --	급여항목코드
					CAM_AMT, --	계산금액
					NOTE, --	비고
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	월별계획인원ID
						@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
						CASE WHEN B.PEB_APP_BASE_CD='20' THEN
							B.PEB_RATE / 100 * (SELECT ISNULL(SUM(CAM_AMT),0) FROM PEB_PAYROLL_DETAIL
							                           WHERE PEB_PAYROLL_ID=A.PEB_PAYROLL_ID
													     AND PAY_ITEM_CD IN ('P001','P003'))
							ELSE 0 END AS	CAM_AMT, --	계산금액
						'기준' NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
					FROM PEB_PAYROLL A
					JOIN PEB_RATE B
					  ON B.PEB_BASE_ID = @an_peb_base_id
					 AND B.PEB_TYPE_CD = '131' -- 타결금
					 AND SUBSTRING(A.PEB_YM,5,2) = B.PEB_YM
					WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				---------------------------
				-- 타결비
				---------------------------
				/*
				140	설상여	P302	명절상여금
				141	설귀성비	P550	귀성비
				150	추석상여	P302	명절상여금
				151	추석귀성비	P550	귀성비
				160	휴가비	P530	휴가비
				220	타결금	P111	타결금
				 */
				set @v_pay_item_cd = 'P111' -- 타결금
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	인건비계산결과ID
					PEB_PAYROLL_ID, --	월별계획인원ID
					PAY_ITEM_CD, --	급여항목코드
					CAM_AMT, --	계산금액
					NOTE, --	비고
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	월별계획인원ID
						--@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
						CASE
						WHEN B.PEB_TYPE_CD IN ('140','150') THEN 'P302'
						WHEN B.PEB_TYPE_CD IN ('141','151') THEN 'P550'
						WHEN B.PEB_TYPE_CD IN ('160') THEN 'P530'
						WHEN B.PEB_TYPE_CD IN ('220') THEN 'P111'
						ELSE B.PEB_TYPE_CD END AS PAY_ITEM_CD, -- 급여항목코드
						B.PEB_RATE AS	CAM_AMT, --	계산금액
						'기준' NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
					FROM PEB_PAYROLL A
					JOIN PEB_RATE B
					  ON B.PEB_BASE_ID = @an_peb_base_id
					 --AND B.PEB_TYPE_CD = '220' -- 타결금
					 AND B.PEB_TYPE_CD in ('140','141','150','151','160','220')
					 AND SUBSTRING(A.PEB_YM,5,2) = B.PEB_YM
					WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				
				---------------------------
				-- 인건비 - 직책수당
				---------------------------
				set @v_pay_item_cd = 'P004' -- 직책수당
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	인건비계산결과ID
					PEB_PAYROLL_ID, --	월별계획인원ID
					PAY_ITEM_CD, --	급여항목코드
					CAM_AMT, --	계산금액
					NOTE, --	비고
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	월별계획인원ID
						@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
						dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_BASE_DUTY',
								NULL, NULL, NULL, NULL, NULL,
								A.DUTY_CD, NULL, NULL, NULL, NULL,
								getDate(),
								'H1' -- 'H1' : 코드1,     'H2' : 코드2,     'H3' :  코드3,     'H4' : 코드4,     'H5' : 코드5
																		-- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
								) AS	CAM_AMT, --	계산금액
						'기준' NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
					FROM PEB_PAYROLL A
					WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
					AND dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_BASE_DUTY',
								NULL, NULL, NULL, NULL, NULL,
								A.DUTY_CD, NULL, NULL, NULL, NULL,
								getDate(),
								'H1' -- 'H1' : 코드1,     'H2' : 코드2,     'H3' :  코드3,     'H4' : 코드4,     'H5' : 코드5
																		-- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
								) IS NOT NULL -- 직책에 대한 기준금액이 있는 경우
				
				
				---------------------------
				-- 인건비 - 제수당
				---------------------------
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	인건비계산결과ID
					PEB_PAYROLL_ID, --	월별계획인원ID
					PAY_ITEM_CD, --	급여항목코드
					CAM_AMT, --	계산금액
					NOTE, --	비고
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	월별계획인원ID
						I.PAY_ITEM_CD PAY_ITEM_CD, --	급여항목코드
						I.BASE_AMT AS	CAM_AMT, --	계산금액
						I.NOTE NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
					FROM PEB_PAYROLL A
					JOIN PEB_PHM_ITEM I
					  ON A.PEB_PHM_MST_ID = I.PEB_PHM_MST_ID
				   WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				     AND NOT EXISTS (SELECT * FROM PEB_PAYROLL_DETAIL WHERE PEB_PAYROLL_ID = A.PEB_PAYROLL_ID AND PAY_ITEM_CD = I.PAY_ITEM_CD)
					 
				---------------------------
				-- 인건비 - 복지포인트
				---------------------------
				set @v_pay_item_cd = 'P152' -- 기타수당
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	인건비계산결과ID
					PEB_PAYROLL_ID, --	월별계획인원ID
					PAY_ITEM_CD, --	급여항목코드
					CAM_AMT, --	계산금액
					NOTE, --	비고
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	월별계획인원ID
						@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
						PNT.PAY_AMT AS	CAM_AMT, --	계산금액
						PNT.NOTE NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
					FROM PEB_PAYROLL A
					JOIN PEB_PNT_MNG PNT
					  ON A.PEB_PHM_MST_ID = PNT.PEB_PHM_MST_ID
					 AND A.PEB_YM = dbo.XF_TO_CHAR_D( PNT.PAY_YMD, 'YYYYMM')
				   WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				---------------------------
				-- 인건비 - 학자금
				---------------------------
				set @v_pay_item_cd = 'P500' -- 학자금
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	인건비계산결과ID
					PEB_PAYROLL_ID, --	월별계획인원ID
					PAY_ITEM_CD, --	급여항목코드
					CAM_AMT, --	계산금액
					NOTE, --	비고
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	월별계획인원ID
						@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
						SUM(ISNULL(SCH.CNF_AMT,0)) AS	CAM_AMT, --	계산금액
						'' NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
					FROM PEB_PAYROLL A
					JOIN PEB_SCH_MNG SCH
					  ON A.PEB_PHM_MST_ID = SCH.PEB_PHM_MST_ID
					 --AND A.PEB_YM = dbo.XF_TO_CHAR_D( SCH.REQ_YMD, 'YYYYMM')
					 AND A.PEB_YM = FORMAT( SCH.REQ_YMD, 'yyyyMM')
				   WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				   GROUP BY A.PEB_PAYROLL_ID
					 
				---------------------------
				-- 인건비 - 고정OT
				---------------------------
				set @v_pay_item_cd = 'P002' -- 고정OT
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	인건비계산결과ID
					PEB_PAYROLL_ID, --	월별계획인원ID
					PAY_ITEM_CD, --	급여항목코드
					CAM_AMT, --	계산금액
					NOTE, --	비고
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	월별계획인원ID
						@v_pay_item_cd	PAY_ITEM_CD, --	급여항목코드 -- 고정OT
						CONVERT(NUMERIC,C.BP02) * CONVERT(NUMERIC(5,1), 1.5) * (SELECT ISNULL(SUM(CAM_AMT) / CONVERT(NUMERIC(5), C.BP05), 0)
											  FROM PEB_PAYROLL_DETAIL
											 WHERE PEB_PAYROLL_ID = A.PEB_PAYROLL_ID
										   AND PAY_ITEM_CD IN (SELECT HIS.KEY_CD2 AS CD
																  FROM FRM_UNIT_STD_MGR MGR
																	   INNER JOIN FRM_UNIT_STD_HIS HIS
																			   ON MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
																			  AND MGR.UNIT_CD = 'PEB'
																			  AND MGR.STD_KIND = 'PEB_ORDWAGE_ITEM'
																 WHERE MGR.COMPANY_CD = 'E'
																   AND MGR.LOCALE_CD = 'KO'
																   AND GETDATE() BETWEEN HIS.STA_YMD AND HIS.END_YMD
																   AND HIS.KEY_CD1 = 'EA01'))
							AS	CAM_AMT, --	계산금액
						'연봉-고정OT'	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
					FROM PEB_PAYROLL A
					JOIN PEB_CNM_CNT C
					ON A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
					AND C.PEB_BASE_ID = @an_peb_base_id
					AND C.EMP_NO = @EMP_NO
					AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN  C.STA_YMD AND C.END_YMD
					AND ISNULL(C.BP02,0) <> 0
				---------------------------
				-- 인건비 - 추가OT
				---------------------------
				set @v_pay_item_cd = 'P021' -- 추가OT
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								A.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
								OT.OT * 1.5 * (SELECT ISNULL(SUM(CAM_AMT) / CONVERT(NUMERIC, C.BP05) , 0)
											  FROM PEB_PAYROLL_DETAIL
											 WHERE PEB_PAYROLL_ID = A.PEB_PAYROLL_ID
										   AND PAY_ITEM_CD IN (SELECT HIS.KEY_CD2 AS CD
																  FROM FRM_UNIT_STD_MGR MGR
																	   INNER JOIN FRM_UNIT_STD_HIS HIS
																			   ON MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
																			  AND MGR.UNIT_CD = 'PEB'
																			  AND MGR.STD_KIND = 'PEB_ORDWAGE_ITEM'
																 WHERE MGR.COMPANY_CD = 'E'
																   AND MGR.LOCALE_CD = 'KO'
																   AND GETDATE() BETWEEN HIS.STA_YMD AND HIS.END_YMD
																   AND HIS.KEY_CD1 = 'EA01'))
									AS	CAM_AMT, --	계산금액
								NULL NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL A
						  JOIN PEB_PHM_MST M
						    ON A.PEB_PHM_MST_ID = M.PEB_PHM_MST_ID
						  JOIN PEB_CNM_CNT C
						    ON A.PEB_PHM_MST_ID = M.PEB_PHM_MST_ID
						   AND C.PEB_BASE_ID = M.PEB_BASE_ID
						   AND C.EMP_NO = M.EMP_NO
						   AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN  C.STA_YMD AND C.END_YMD
						  JOIN PEB_MON_OT OT
						    ON A.PEB_PAYROLL_ID = OT.PEB_PAYROLL_ID
						WHERE M.PEB_BASE_ID = @an_peb_base_id
						  AND M.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						  AND ISNULL(OT.OT, 0) <> 0
				---------------------------
				-- 인건비 - 연차
				---------------------------
				set @v_pay_item_cd = 'P050' -- 연차
				select @n_dtm_year_amt = DTM.UN_USE_CNT * CASE WHEN M.MGR_TYPE_CD='O' THEN 1 -- 관리
													  WHEN M.MGR_TYPE_CD='9' THEN 1.5
								                      ELSE 1 END --1.5
								            * (SELECT ISNULL(SUM(CAM_AMT) / CONVERT(NUMERIC, C.BP05) , 0) * 8
											  FROM PEB_PAYROLL_DETAIL
											 WHERE PEB_PAYROLL_ID = A.PEB_PAYROLL_ID
										   AND PAY_ITEM_CD IN (SELECT HIS.KEY_CD2 AS CD
																  FROM FRM_UNIT_STD_MGR MGR
																	   INNER JOIN FRM_UNIT_STD_HIS HIS
																			   ON MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
																			  AND MGR.UNIT_CD = 'PEB'
																			  AND MGR.STD_KIND = 'PEB_ORDWAGE_ITEM'
																 WHERE MGR.COMPANY_CD = 'E'
																   AND MGR.LOCALE_CD = 'KO'
																   AND GETDATE() BETWEEN HIS.STA_YMD AND HIS.END_YMD
																   AND HIS.KEY_CD1 = 'EA01'))
									--	연차금액
						  FROM PEB_PAYROLL A
						  JOIN PEB_PHM_MST M
						    ON A.PEB_PHM_MST_ID = M.PEB_PHM_MST_ID
						  JOIN PEB_CNM_CNT C
						    ON A.PEB_PHM_MST_ID = M.PEB_PHM_MST_ID
						   AND C.PEB_BASE_ID = M.PEB_BASE_ID
						   AND C.EMP_NO = M.EMP_NO
						   AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN  C.STA_YMD AND C.END_YMD
						  JOIN PEB_DTM_MNG DTM
						    ON M.PEB_PHM_MST_ID = DTM.PEB_PHM_MST_ID
						WHERE M.PEB_BASE_ID = @an_peb_base_id
						  AND M.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						  AND ISNULL(DTM.UN_USE_CNT, 0) <> 0
						  AND A.PEB_YM = (SELECT MAX(PEB_YM) FROM PEB_PAYROLL WHERE PEB_PHM_MST_ID = @PEB_PHM_MST_ID)
					IF @@ROWCOUNT > 0 
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								A.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
								@n_dtm_year_amt / (select COUNT(*) FROM PEB_PAYROLL WHERE PEB_PHM_MST_ID = @PEB_PHM_MST_ID)
									AS	CAM_AMT, --	계산금액
								NULL NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL A
						WHERE PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						  AND @n_dtm_year_amt > 0
				-- 4대보험
				set @v_pay_item_cd = 'D910' -- 국민연금회사부담금
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * (SELECT COMP_RATE FROM PEB_STP_RATE WHERE COMPANY_CD=@av_company_cd AND PEB_YM + '01' BETWEEN STA_YMD AND END_YMD) / 100, -1)
									AS	CAM_AMT, --	계산금액
								NULL NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD NOT IN ('D910','D920','D925','D930','D940','D950')
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
				set @v_pay_item_cd = 'D920' -- 건강보험회사부담금
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * (SELECT COMP_RATE FROM PEB_NHS_RATE WHERE COMPANY_CD=@av_company_cd AND INSURE_CD='01' AND PEB_YM + '01' BETWEEN STA_YMD AND END_YMD) / 100, -1)
									AS	CAM_AMT, --	계산금액
								NULL NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD NOT IN ('D910','D920','D925','D930','D940','D950')
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
				set @v_pay_item_cd = 'D925' -- 장기요양보험회사부담금
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * (SELECT COMP_RATE FROM PEB_NHS_RATE WHERE COMPANY_CD=@av_company_cd AND INSURE_CD='02' AND PEB_YM + '01' BETWEEN STA_YMD AND END_YMD) / 100, -1)
									AS	CAM_AMT, --	계산금액
								NULL NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD = 'D920'
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
				set @v_pay_item_cd = 'D930' -- 고용보험회사부담금
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * (SELECT ISNULL(UNEMP_RATE_O,0) + ISNULL(EMP_RATE_O,0) + ISNULL(ABLILTY_RATE_O,0) FROM PEB_EMI_RATE WHERE COMPANY_CD=@av_company_cd AND PEB_YM + '01' BETWEEN STA_YMD AND END_YMD) / 100 , -1)
									AS	CAM_AMT, --	계산금액
								NULL NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD NOT IN ('D910','D920','D925','D930','D940','D950')
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
				set @v_pay_item_cd = 'D940' -- 산재보험회사부담금
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * ISNULL(dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_IAI_RATE',
										NULL, NULL, NULL, NULL, NULL,
										MST.PHM_BIZ_CD, NULL, NULL, NULL, NULL,
										getDate(),
										'H1'),0 ) / 100 , -1)
									AS	CAM_AMT, --	계산금액
								NULL NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD NOT IN ('D910','D920','D925','D930','D940','D950')
						  JOIN PEB_PHM_MST MST
						    ON ROLL.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY MST.PHM_BIZ_CD, ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
				set @v_pay_item_cd = 'D950' -- 퇴직연금
				SELECT @n_peb_rate = PEB_RATE
				  FROM PEB_RATE
				 WHERE PEB_BASE_ID = @an_peb_base_id
				   AND PEB_TYPE_CD = '300'
				IF @@ROWCOUNT > 0 AND @n_peb_rate > 0
					BEGIN
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	인건비계산결과ID
							PEB_PAYROLL_ID, --	월별계획인원ID
							PAY_ITEM_CD, --	급여항목코드
							CAM_AMT, --	계산금액
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	월별계획인원ID
								@v_pay_item_cd PAY_ITEM_CD, --	급여항목코드
								--dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) / 12 * ISNULL(@n_peb_rate, 0) / 100 , -1)
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * ISNULL(@n_peb_rate, 0) / 100 , -1)
									AS	CAM_AMT, --	계산금액
								NULL NOTE, --	비고
								@an_mod_user_id	MOD_USER_ID, --	변경자
								SYSDATETIME()	MOD_DATE, --	변경일
								@av_tz_cd	TZ_CD, --	타임존코드
								SYSDATETIME()	TZ_DATE --	타임존일시
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD NOT IN ('D910','D920','D925','D930','D940','D950')
						  JOIN PEB_PHM_MST MST
						    ON ROLL.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY MST.PHM_BIZ_CD, ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
					END
			END TRY
			BEGIN Catch
					print 'Err' + error_message()
					SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비계획 인건비계산중 오류가 발생했습니다.[ERR]' + ERROR_MESSAGE() + CONVERT(NVARCHAR(100), ERROR_LINE()),
											@v_program_id,  0150,  null, null
										)
					SET @av_ret_code    = 'FAILURE!'
					RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_EMP INTO @PEB_PHM_MST_ID, @EMP_NO, @v_salary_sys_cd
		END
	CLOSE CUR_PHM_EMP
	DEALLOCATE CUR_PHM_EMP
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END

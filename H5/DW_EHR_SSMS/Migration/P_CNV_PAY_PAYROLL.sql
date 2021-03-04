SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 급여내역(대상자)
-- 
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_PAYROLL
      @an_try_no		NUMERIC(4)      -- 시도회차
    , @av_company_cd	NVARCHAR(10)    -- 회사코드
	, @av_fr_month		NVARCHAR(6)		-- 시작년월
	, @av_to_month		NVARCHAR(6)		-- 종료년월
	, @av_fg_supp		NVARCHAR(2)		-- 급여구분
	, @av_dt_prov		NVARCHAR(08)	-- 급여지급일
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @s_company_cd nvarchar(10)
	      , @t_company_cd nvarchar(10)
		  -- 변환작업결과
		  , @v_proc_nm   nvarchar(50) -- 프로그램ID
		  , @v_pgm_title nvarchar(100) -- 프로그램Title
		  , @v_params       nvarchar(4000) -- 파라미터
		  , @n_total_record numeric
		  , @n_cnt_success  numeric
		  , @n_cnt_failure  numeric
		  , @v_s_table      nvarchar(50) -- source table
		  , @v_t_table      nvarchar(50) -- target table
		  , @n_log_h_id		  numeric
		  , @v_keys			nvarchar(2000)
		  , @n_err_cod		numeric
		  , @v_err_msg		nvarchar(4000)
		  -- AS-IS Table Key
		  , @cd_company		nvarchar(20) -- 회사코드
		  , @ym_pay			nvarchar(10)
		  , @fg_supp		nvarchar(10)
		  , @dt_prov		nvarchar(10)
		  , @no_person		nvarchar(10)
		  -- 참조변수
		  , @cd_paygp		nvarchar(10)
		  , @dt_update		datetime
		  , @pay_ymd_id		numeric
		  , @emp_id			numeric -- 사원ID
		  , @person_id		numeric -- 개인ID
		  , @pay_payroll_id	numeric -- PAYROLL_ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '급여내역(대상자)'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@av_fr_month=' + ISNULL(CONVERT(nvarchar(100), @av_fr_month),'NULL')
				+ ',@av_to_month=' + ISNULL(CONVERT(nvarchar(100), @av_to_month),'NULL')
				+ ',@av_fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
				+ ',@av_dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
	set @v_s_table = 'H_MONTH_PAY_BONUS'   -- As-Is Table
	set @v_t_table = 'PAY_PAYROLL' -- To-Be Table
	-- =============================================
	-- 전환프로그램설명
	-- =============================================

	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	
	-- Conversion로그정보 Header
	EXEC @n_log_h_id = dbo.P_CNV_PAY_LOG_H 0, 'S', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table
	
	-- =============================================
	--   As-Is Key Column Select
	--   Source Table Key
	-- =============================================
    DECLARE CNV_CUR CURSOR READ_ONLY FOR
		SELECT CD_COMPANY
				 , YM_PAY
				 , FG_SUPP
				 , DT_PROV
				 , NO_PERSON
				 , CD_PAYGP
				 , DT_UPDATE
			  FROM dwehrdev.dbo.H_MONTH_PAY_BONUS
			 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
			   AND YM_PAY BETWEEN @av_fr_month AND @av_to_month
			   AND FG_SUPP LIKE ISNULL(@av_fg_supp, '') + '%'
			   AND DT_PROV LIKE ISNULL(@av_dt_prov, '') + '%'
			ORDER BY CD_COMPANY, YM_PAY, FG_SUPP, DT_PROV
	-- =============================================
	--   As-Is Key Column Select
	-- =============================================
	OPEN CNV_CUR

	WHILE 1 = 1
		BEGIN
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			FETCH NEXT FROM CNV_CUR
			      INTO @cd_company
				     , @ym_pay
					 , @fg_supp
					 , @dt_prov
					 , @no_person
					 , @cd_paygp
					 , @dt_update
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- 총 건수확인
				set @s_company_cd = @cd_company -- AS-IS 회사코드
				set @t_company_cd = @cd_company -- TO-BE 회사코드
				
				-- =======================================================
				-- 급여일자얻기
				-- =======================================================
				EXECUTE @pay_ymd_id = dbo.P_CNV_PAY_PAY_YMD
								   @n_log_h_id
								 , @s_company_cd
								 , @ym_pay
								 , @fg_supp
								 , @dt_prov
								 , @cd_paygp
								 , @dt_update
				IF ISNULL(@pay_ymd_id,0) = 0
					BEGIN
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = '급여일자를 구할 수 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE
					END
				-- =======================================================
				--  EMP_ID 찾기
				-- =======================================================
				SELECT @emp_id = EMP_ID, @person_id = PERSON_ID
				  FROM PHM_EMP_NO_HIS (NOLOCK)
				 WHERE COMPANY_CD = @cd_company
				   AND EMP_NO = @no_person
				IF @@ROWCOUNT < 1
					BEGIN
						-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS에서 사번을 찾을 수 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				select @pay_payroll_id = NEXT VALUE FOR S_PAY_SEQUENCE
				BEGIN TRY
				INSERT INTO dwehrdev_H5.dbo.PAY_PAYROLL(
							PAY_PAYROLL_ID,--	급여내역ID
							PAY_YMD_ID,--	급여일자ID
							EMP_ID,--	사원ID
							SALARY_TYPE_CD,--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
							SUB_COMPANY_CD,--	서브회사코드
							PAY_GROUP_CD,--	급여그룹
							PAY_BIZ_CD,--	급여사업장코드
							RES_BIZ_CD,--	지방세사업장코드
							ORG_ID,--	발령부서ID
							PAY_ORG_ID,--	급여부서ID
							MGR_TYPE_CD,-- 관리구분코드
							POS_CD,--	직위코드[PHM_POS_CD]
							JOB_POSITION_CD,--	직종코드
							DUTY_CD, -- 직책코드[PHM_DUTY_CD]
							ACC_CD,--	코스트센터(ORM_COST_ORG_CD)
							PSUM,--	지급집계(모든기지급포함)
							PSUM1,--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
							PSUM2,--	지급집계(모든기지급포함안함)
							DSUM,--	공제집계
							TSUM,--	세금집계
							REAL_AMT,--	실지급액
							BANK_CD,--	은행코드[PAY_BANK_CD]
							ACCOUNT_NO,--	계좌번호
							FILLDT,--	기표일
							POS_GRD_CD,--	직급[PHM_POS_GRD_CD]
							PAY_GRADE,-- 호봉코드 [PHM_YEARNUM_CD]
							DTM_TYPE,--	근태유형
							FILLNO,--	전표번호
							NOTICE,--	급여명세공지
							TAX_YMD,--	원천징수신고일자
							FOREIGN_PSUM,--	외화지급집계(모든기지급포함)
							FOREIGN_PSUM1,--	외화지급집계(PSUM에서 급여성기지급 포함 안함)
							FOREIGN_PSUM2,--	외화지급집계(모든기지급포함안함)
							FOREIGN_DSUM,--	외화공제집계
							FOREIGN_TSUM,--	외화세금집계
							FOREIGN_REAL_AMT,--	외화실지급액
							CURRENCY_CD,--	통화코드[PAY_CURRENCY_CD]
							TAX_SUBSIDY_YN,--	세금보조여부
							TAX_FAMILY_CNT,--	부양가족수
							FAM20_CNT,--	20세이하자녀수
							FOREIGN_YN,--	외국인여부
							PEAK_YN	,--임금피크대상여부
							PEAK_DATE,--	임금피크적용일자
							PAY_METH_CD,--	급여지급방식코드[PAY_METH_CD]
							PAY_EMP_CLS_CD,--	고용유형코드[PAY_EMP_CLS_CD]
							CONT_TIME,--	소정근로시간
							UNION_YN,--	노조회비공제대상여부
							UNION_FULL_YN,--	노조전임여부
							PAY_UNION_CD,--	노조사업장코드[PAY_UNION_CD]
							FOREJOB_YN,--	국외근로여부
							TRBNK_YN,--	신협공제대상여부
							PROD_YN,--	생산직여부
							ADV_YN,--	선망가불금공제여부
							SMS_YN,--	SMS발송여부
							EMAIL_YN,--	E_MAIL발송여부
							WORK_YN,--	근속수당지급여부
							WORK_YMD,--	근속기산일자
							RETR_YMD,--	퇴직금기산일자
							NOTE, --	비고
							JOB_CD, -- 직무
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일시
							TZ_CD, --	타임존코드
							TZ_DATE  --	타임존일시
				       )
					SELECT @pay_payroll_id,
							@pay_ymd_id PAY_YMD_ID, --	급여일자ID
							@emp_id	EMP_ID, --	사원ID
							CASE WHEN A.TP_CALC_INS = 'A' THEN '005' -- 호봉제
								WHEN A.TP_CALC_INS = 'B' THEN '001' -- 임원
								WHEN A.TP_CALC_INS = 'C' THEN '010' -- 계약제
								WHEN A.TP_CALC_INS = 'D' THEN '100' -- 일급제
								WHEN A.TP_CALC_INS = 'F' THEN '010' -- 판매
								WHEN A.TP_CALC_INS = 'M' THEN '005' -- 월급제
								WHEN A.TP_CALC_INS = 'S' THEN '005' -- 선원
								WHEN A.TP_CALC_INS = 'T' THEN '010' -- 시급제
								WHEN A.TP_CALC_INS = 'U' THEN '002' -- 성과급제
								WHEN A.TP_CALC_INS = 'W' THEN '002' -- 생산연봉제
								WHEN A.TP_CALC_INS = 'Y' THEN '002' -- 연봉제
								ELSE '002' END AS SALARY_TYPE_CD, --	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
							@t_company_cd	SUB_COMPANY_CD,--	서브회사코드
							A.CD_PAYGP PAY_GROUP_CD, -- 급여그룹
							A.CD_BIZ_AREA	PAY_BIZ_CD,--	급여사업장코드
							A.CD_REG_BIZ_AREA	RES_BIZ_CD,--	지방세사업장코드
							ISNULL((select org_id from ORM_ORG where COMPANY_CD = @t_company_cd AND ORG_CD = A.CD_DEPT),0)	ORG_ID, --	발령부서ID
							(select org_id from ORM_ORG where COMPANY_CD = @t_company_cd AND ORG_CD = A.CD_DEPT) PAY_ORG_ID, --	급여부서ID
							A.TP_DUTY	MGR_TYPE_CD,-- 관리구분코드
							ISNULL(B.POS_CD, A.CD_POSITION)	POS_CD, --	직위코드[PHM_POS_CD]
							ISNULL(B.JOB_POSITION_CD, A.CD_OCPT)	JOB_POSITION_CD, --	직종코드
							ISNULL(B.DUTY_CD, A.CD_ABIL)	DUTY_CD, -- 직책코드[PHM_DUTY_CD]
							A.CD_COST	ACC_CD, --	코스트센터(ORM_COST_ORG_CD)
							A.AMT_SUPPLY_TOTAL	PSUM, --	지급집계(모든기지급포함)
							A.AMT_SUPPLY_TOTAL	PSUM1, --	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
							A.AMT_SUPPLY_TOTAL	PSUM2, --	지급집계(모든기지급포함안함)
							A.AMT_DEDUCT_TOTAL	DSUM, --	공제집계 (**AS는 세금까지 포함된 금액**)
							0	TSUM, --	세금집계
							A.AMT_REAL_SUPPLY	REAL_AMT, --	실지급액
							A.CD_BANK1	BANK_CD, --	은행코드[PAY_BANK_CD]
							A.NO_BANK_ACCNT1	ACCOUNT_NO, --	계좌번호
							A.DT_AUTO	FILLDT, --	기표일
							A.LVL_PAY1	POS_GRD_CD, --	직급[PHM_POS_GRD_CD]
							A.LVL_PAY2	PAY_GRADE,-- 호봉코드 [PHM_YEARNUM_CD]
							NULL	DTM_TYPE, --	근태유형
							A.NO_AUTO	FILLNO, --	전표번호
							NULL	NOTICE, --	급여명세공지
							NULL	TAX_YMD, --	원천징수신고일자
							0	FOREIGN_PSUM, --	외화지급집계(모든기지급포함)
							0	FOREIGN_PSUM1, --	외화지급집계(PSUM에서 급여성기지급 포함 안함)
							0	FOREIGN_PSUM2, --	외화지급집계(모든기지급포함안함)
							0	FOREIGN_DSUM, --	외화공제집계
							0	FOREIGN_TSUM, --	외화세금집계
							0	FOREIGN_REAL_AMT, --	외화실지급액
							'KRW'	CURRENCY_CD, --	통화코드[PAY_CURRENCY_CD]
							NULL	TAX_SUBSIDY_YN, --	세금보조여부
							A.CNT_FAMILY	TAX_FAMILY_CNT, --	부양가족수
							A.CNT_CHILD		FAM20_CNT,--	20세이하자녀수
							A.YN_FOREIGN	FOREIGN_YN, --	외국인여부
							'N'		PEAK_YN, --	임금피크대상여부
							NULL	PEAK_DATE, --	임금피크적용일자
							A.TP_CALC_PAY	PAY_METH_CD, --	급여지급방식코드[PAY_METH_CD]
							A.TP_CALC_INS	PAY_EMP_CLS_CD,--	고용유형코드[PAY_EMP_CLS_CD]
							NULL	CONT_TIME,--	소정근로시간
							A.YN_LABOR_OBJ	UNION_YN,--	노조회비공제대상여부
							NULL	UNION_FULL_YN,--	노조전임여부
							NULL	PAY_UNION_CD,--	노조사업장코드[PAY_UNION_CD]
							A.YN_FOREJOB	FOREJOB_YN, --	국외근로여부
							A.YN_CRE	TRBNK_YN, --	신협공제대상여부
							A.YN_PROD_LABOR	PROD_YN, --	생산직여부
							NULL	ADV_YN,--	선망가불금공제여부
							NULL	SMS_YN,--	SMS발송여부
							NULL	EMAIL_YN,--	E_MAIL발송여부
							NULL	WORK_YN,--	근속수당지급여부
							NULL	WORK_YMD,--	근속기산일자
							NULL	RETR_YMD,--	퇴직금기산일자
							A.REM_COMMENT	NOTE, --	비고
							A.CD_JOB, -- 직무
						 0 AS MOD_USER_ID
						, ISNULL(DT_UPDATE,'1900-01-01')
						, 'KST'
						, ISNULL(DT_UPDATE,'1900-01-01')
				  FROM dwehrdev.dbo.H_MONTH_PAY_BONUS A (NOLOCK)
				  LEFT OUTER JOIN CAM_HISTORY B (NOLOCK)
				    ON B.EMP_ID = @emp_id
				   AND B.COMPANY_CD = @t_company_cd
				   AND B.SEQ = 0
				   AND A.DT_PROV BETWEEN B.STA_YMD AND B.END_YMD
				 WHERE CD_COMPANY = @s_company_cd
				   AND YM_PAY = @ym_pay
				   AND FG_SUPP = @fg_supp
				   AND DT_PROV = @dt_prov
				   AND NO_PERSON = @no_person
				END TRY
				BEGIN CATCH
					set @n_err_cod = ERROR_NUMBER()
					IF @n_err_cod = 2627 -- 중복키
						BEGIN
						PRINT '중복키:'
							UPDATE A
							   SET 
								PSUM = PSUM + B.AMT_SUPPLY_TOTAL,--	지급집계(모든기지급포함)
								PSUM1 = PSUM1 + B.AMT_SUPPLY_TOTAL,--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
								PSUM2 = PSUM2 + B.AMT_SUPPLY_TOTAL,--	지급집계(모든기지급포함안함)
								DSUM = DSUM + B.AMT_DEDUCT_TOTAL,--	공제집계
								--TSUM,--	세금집계
								REAL_AMT = REAL_AMT + B.AMT_REAL_SUPPLY--	실지급액
							  FROM PAY_PAYROLL A
							  JOIN (SELECT AMT_SUPPLY_TOTAL, AMT_DEDUCT_TOTAL, AMT_REAL_SUPPLY
									  FROM dwehrdev.dbo.H_MONTH_PAY_BONUS A (NOLOCK)
									 WHERE CD_COMPANY = @s_company_cd
									   AND YM_PAY = @ym_pay
									   AND FG_SUPP = @fg_supp
									   AND DT_PROV = @dt_prov
									   AND NO_PERSON = @no_person) B
								ON 1=1
							 WHERE @pay_ymd_id = PAY_YMD_ID --	급여일자ID
								AND @emp_id	= EMP_ID --	사원ID
								--AND '002' = SALARY_TYPE_CD
							IF @@ROWCOUNT < 1
							begin
								-- *** 로그에 실패 메시지 저장 ***
								set @v_keys = '@cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
									  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
									  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
									  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
									  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
								set @v_err_msg = '선택된 Record가 없습니다.!!!' -- ERROR_MESSAGE()
								EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
								-- *** 로그에 실패 메시지 저장 ***
								set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
							end
							set @v_keys = '@cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
								  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
								  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
								  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
								  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							print @v_keys
						END
					ELSE
						THROW;
				END CATCH
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================

				--if @@ROWCOUNT > 0 
					begin
						-- *** 성공메시지 로그에 저장 ***
						--set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
						--      + ',' + ISNULL(CONVERT(nvarchar(100), @cd_accnt),'NULL')
						--set @v_err_msg = '선택된 Record가 없습니다.!'
						--EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 성공메시지 로그에 저장 ***
						set @n_cnt_success = @n_cnt_success + 1 -- 성공건수
					end
				--else
				--	begin
				--		-- *** 로그에 실패 메시지 저장 ***
				--		set @v_keys = '@cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
				--			  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
				--			  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
				--			  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
				--			  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
				--		set @v_err_msg = '선택된 Record가 없습니다.!!!' -- ERROR_MESSAGE()
				--		EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
				--		-- *** 로그에 실패 메시지 저장 ***
				--		set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
				--	end
			END TRY
			BEGIN CATCH
				-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = '@cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = CONVERT(NVARCHAR(100), ERROR_LINE()) + ':' + ERROR_MESSAGE()
						
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
				-- *** 로그에 실패 메시지 저장 ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
			END CATCH
		END
	--print '종료 총건수 : ' + dbo.xf_to_char_n(@n_total_record, default)
	--print '성공 : ' + dbo.xf_to_char_n(@n_cnt_success, default)
	--print '실패 : ' + dbo.xf_to_char_n(@n_cnt_failure, default)
	-- Conversion 로그정보 - 전환건수저장
	EXEC [dbo].[P_CNV_PAY_LOG_H] @n_log_h_id, 'E', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table, @n_total_record, @n_cnt_success, @n_cnt_failure

	CLOSE CNV_CUR
	DEALLOCATE CNV_CUR
	PRINT @v_proc_nm + ' 완료!'
	PRINT 'CNT_PAY_WORK_ID = ' + CONVERT(varchar(100), @n_log_h_id)
	RETURN @n_log_h_id
END
GO
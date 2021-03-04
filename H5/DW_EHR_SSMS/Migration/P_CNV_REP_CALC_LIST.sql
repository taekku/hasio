SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 퇴직금계산대상자(내역)
-- 
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_REP_CALC_LIST
      @an_try_no		NUMERIC(4)       -- 시도회차
    , @av_company_cd	NVARCHAR(10)     -- 회사코드
	, @av_fr_month		NVARCHAR(6)		-- 시작년월
	, @av_to_month		NVARCHAR(6)		-- 종료년월
AS
BEGIN
	SET NOCOUNT ON;
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
		  , @dt_base		nvarchar(20) -- 기준일자
		  , @fg_retr		nvarchar(20) -- 퇴직구분(1.퇴직, 2.퇴직추계, 3.중간정산, B.연금(DB형), C.연금(DC형))
		  , @no_person		nvarchar(20) -- 사번
		  , @dt_retr		nvarchar(20) -- 퇴사일자
		  -- 참조변수
		  , @emp_id			numeric -- 사원ID
		  , @person_id		numeric -- 개인ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '퇴직금계산대상자(내역)'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',fr_month=' + ISNULL(CONVERT(nvarchar(100), @av_fr_month),'NULL')
				+ ',to_month=' + ISNULL(CONVERT(nvarchar(100), @av_to_month),'NULL')
	set @v_s_table = 'H_RETIRE_DETAIL'   -- As-Is Table
	set @v_t_table = 'REP_CALC_LIST' -- To-Be Table
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
				 , DT_BASE
				 , FG_RETR
				 , NO_PERSON
				 , DT_RETR
			  FROM dwehrdev.dbo.H_RETIRE_DETAIL A
			 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
			   AND DT_BASE >= ISNULL(@av_fr_month,'')
			   AND DT_BASE <= ISNULL(@av_to_month,'999999') + '99'
			   --AND (ISNULL(A.DT_RETR, '') <> '')
			   --AND A.DT_BASE = A.DT_RETR
			   --AND A.DT_BASE NOT IN ('2011231', '20091232')
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
				     , @dt_base, @fg_retr, @no_person, @dt_retr
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- 총 건수확인
				set @s_company_cd = @cd_company -- AS-IS 회사코드
				set @t_company_cd = @cd_company -- TO-BE 회사코드
				
				-- =======================================================
				--  EMP_ID 찾기
				-- =======================================================
				SELECT @emp_id = EMP_ID, @person_id = PERSON_ID
				  FROM PHM_EMP_NO_HIS
				 WHERE COMPANY_CD = @cd_company
				   AND EMP_NO = @no_person
				IF @@ROWCOUNT < 1
					BEGIN
						-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',dt_base=' + ISNULL(CONVERT(nvarchar(100), @dt_base),'NULL')
							  + ',fg_retr=' + ISNULL(CONVERT(nvarchar(100), @fg_retr),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',dt_retr=' + ISNULL(CONVERT(nvarchar(100), @dt_retr),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS에서 사번을 찾을 수 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				INSERT INTO REP_CALC_LIST (
				REP_CALC_LIST_ID,	-- 퇴직금대상ID
				EMP_ID,				-- 사원ID 
				CALC_TYPE_CD,		-- 정산구분[REP_CALC_TYPE_CD]
				RETIRE_YMD,			-- 퇴직일
				INS_TYPE_CD,		-- 퇴직연금구분
				INS_TYPE_YN,		-- 퇴직연금가입구분
				ADD_MM_2012,		-- 2012년까지 가산월수(계산) 
				ADD_MM_2013,		-- 2013년부터  가산월수(계산) 
				ADD_WORK_YY,		-- 추가근속년수(지급율) 
				AGENT_CD,			-- 징수의무자구분 
				APPL_CAUSE_CD,		-- 신청사유 
				--APPL_GUBUN,			-- 중간전산(전후반)구분 
				APPL_ID,			-- 신청서ID 
				APPL_YMD,			-- 신청일자 
				ARMY_HIRE_YMD,		-- 군경력감안(인정)입사일 
				ATTACH_AMT,			-- 압류금 
				AVG_BONUS,			-- 평균상여 
				AVG_DAY,			-- 평균연월차 
				AVG_PAY,			-- 평균급여 
				AVG_PAY_AMT,		-- 평균임금 
				B1_CORP_NM,			-- 종(전)지급처명 
				B1_END_YMD,			-- 종(전)정산일 
				B1_EXCEPT_MM,		-- 종(전)제외월수 
				B1_RETIRE_AMT,		-- 종(전)퇴직급여
				B1_RETIRE_REP_AMT,	-- 종(전)명예/희망퇴직금 
				B1_STA_YMD,			-- 종(전)기산일 
				B1_TAX_NO,			-- 종(전)사업자번호 
				B1_WORK_MM,			-- 종(전)근속월수 
				B1_RETIRE_TOT,		-- 종(전)퇴직금
				B2_END_YMD,			-- 법정이외종(전)정산일 
				B2_EXCEPT_MM,		-- 법정이외종(전)제외월수 
				B2_STA_YMD,			-- 법정이외종(전)기산일 
				B2_WORK_MM,			-- 법정이외종(전)근속월수 
				BC1_DUP_MM,			-- 중복월수(법정) 
				BC1_WORK_YY,		-- 근속년수(법정)(현+종전 근속년수) 
				BC2_DUP_MM,			-- 법정이외중복월수 
				BC2_WORK_YY,		-- 법정이외근속년수 
				BONUS_MON,			-- 상여총액 
				BT01,				-- 종(전)소득세 
				BT02,				-- 종(전)주민세 
				BT03,				-- 종(전)농특세 
				BT_SUM,				-- 종(전)세액계 
				B_RETIRE_TAX_YN,	-- 종(전)퇴직소득세액공제여부 
				C1_ADD_MM,			-- 최종 가산월수 
				C1_ADD_MM_2012,		-- 최종 2012년까지 가산월수(입력) 
				C1_ADD_MM_2013,		-- 최종 2013년부터  가산월수(입력) 
				C1_END_YMD,			-- 주(현)정산일 
				C1_END_YMD_2012,	-- 2012년까지 종료일 
				C1_END_YMD_2013,	-- 2013년부터 종료일 
				C1_EXCEPT_MM,		-- 주(현)제외월수 
				C1_EXCEPT_MM_2012,	-- 최종 2012년까지 제외월수(입력) 
				C1_EXCEPT_MM_2013,	-- 최종 2013년부터 제외월수(입력) 
				C1_STA_YMD,			-- 법정주(현)기산일 
				C1_STA_YMD_2012,	-- 2012년까지 시작일 
				C1_STA_YMD_2013,	-- 2013년부터 시작일 
				C1_TAX_RATE_2012,	-- 2012년까지 세율(법정) 
				C1_TAX_RATE_2013,	-- 2013년부터 세율(법정) 
				C1_WORK_MM,			-- 주(현)근속월수 
				C1_WORK_MM_2012,	-- 2012년까지 근속월 
				C1_WORK_MM_2013,	-- 2012년부터 근속월 
				C1_WORK_YY,			-- 최종 근속년수 
				C1_WORK_YY_2012,	-- 2012년까지 근속년수(법정) 
				C1_WORK_YY_2013,	-- 2013년부터 근속년수(법정) 
				C2_END_YMD,			-- 법정이외주(현)정산일 
				C2_EXCEPT_MM,		-- 법정이외주(현)제외월수 
				C2_STA_YMD,			-- 법정이외주(현)기산일 
				C2_TAX_RATE_2012,	-- 2012년까지 세율(법정이외) 
				C2_TAX_RATE_2013,	-- 2013년부터 세율(법정이외) 
				C2_WORK_MM,			-- 법정이외주(현)근속월수 
				C2_WORK_YY_2012,	-- 2012년까지 근속년수(법정이외) 
				C2_WORK_YY_2013,	-- 2013년부터 근속년수(법정이외) 
				CALC_RETIRE_CD,		-- 퇴직(정산)유형(해외파견,대외파견,군입댜,회사이동) 
				CAM_TYPE_CD,		-- 발령유형 
				CHAIN_AMT,			-- 차인지급액(퇴직금) 
				CT01,				-- 퇴직소득세 
				CT02,				-- 퇴직주민세 
				CT03,				-- 퇴직농특세 
				CT_SUM,				-- 퇴직세액계 
				C_01,				-- 주(현)법정퇴직급여 =>  주(현)법정퇴직금 + 주(현)퇴직보험금 
				C_01_1,				-- 주(현)법정퇴직금 
				C_01_2,				-- 주(현)퇴직보험금 
				C_02,				-- 주(현)명예퇴직수당등 (추가퇴직금)  => 명예 + 추가퇴직금 
				C_02_1,				-- 주(현)명예퇴직금 
				C_02_1_BASE,		-- 주(현)명예퇴직금기준금액 
				C_02_1_RATE,		-- 주(현)명예퇴직금지급율 
				C_02_2,				-- 주(현)추가퇴직금 
				C_02_2_RATE,		-- 주(현)추가퇴직금지급율 
				C_02_3,				-- 퇴직위로금 
				C_RETIRE_TAX_YN,	-- 주(현)퇴직소득세액공제여부 
				C_SUM,				-- 주(현)계 
				DUMMY_YN,			-- DUMMY여부 
				DUP_MM,				-- 정산 중복월 
				EMP_KIND_CD,		-- 근로구분코드 [PHM_EMP_KIND_CD]
				END_YN,				-- 완료여부 
				ETC_DEDUCT,			-- 기타공제 
				EXCEPT_MM_2012,		-- 2012년까지 제외월수(계산) 
				EXCEPT_MM_2013,		-- 2013년부터 제외월수(계산) 
				EXCE_END_YMD,		-- 퇴직금제외종료일 
				EXCE_STA_YMD,		-- 퇴직금제외시작일 
				FILLDT,				-- 기표일 
				FILLNO,				-- 전표번호 
				FIRST_HIRE_YMD,		-- 최초입사일 
				FLAG,				-- 1년미만여부 
				FLAG2,				-- 중간정산(임금피크Y보통N) 
				--JSOFCD1,			-- JSOFCD1 
				--JSOFCD2,			-- JSOFCD2 
				LAST_YN,			-- 마지막여부 
				MID_ADD_MM,			-- 중간지급  가산월 
				MID_END_YMD,		-- 중간지급 퇴직일 
				MID_EXCEPT_MM,		-- 중간지급 제외월 
				MID_HIRE_YMD,		-- 중간지급 입사일 
				MID_PAY_YMD,		-- 중간지급 지급일 
				MID_STA_YMD,		-- 중간지급 기산일 
				MID_WORK_MM,		-- 중간지급 근속월 
				MID_WORK_YY,		-- 중간지급 근속년수 
				MOD_DATE,			-- 변경일시 
				MOD_USER_ID,		-- 변경자 
				MONTH_DAY3,			-- 3개월근무일수 
				NON_RETIRE_AMT,		-- 비과세퇴직금 
				NON_RETIRE_MID_AMT,	-- 비과세중간정산퇴직금 
				NOTE,				-- 비고 
				OFFICERS_YN,		-- 임원여부 
				ORG_ID,				-- 발령부서ID 
				ORIGIN_REP_CALC_LIST_ID,	-- 재정산전 퇴직금대상ID 
				PAY_ORG_ID,			-- 급여부서ID 
				PAY_YMD,			-- 지급일 
				POS_CD,				-- 직위코드 [PHM_POS_CD]
				POS_GRD_CD,			-- 직급코드 [PHM_POS_GRD_CD]
				R01,				-- 법정퇴직급여액 
				R01_A,				-- 법정이외퇴직급여액 
				R01_S,				-- 퇴직급여액 
				R02,				-- 법정퇴직소득공제(01+02) 
				R02_01,				-- 법정퇴직소득공제(50%) 
				R02_02,				-- 법정퇴직소득공제(근속) 
				R02_B,				-- 법정이외퇴직소득공제(01+02) 
				R02_B_01,			-- 법정이외퇴직소득공제(50%) 
				R02_B_02,			-- 법정이외퇴직소득공제(근속) 
				R02_S,				-- 퇴직소득공제 
				R03,				-- 법정퇴직소득과표 
				R03_2012,			-- 2012년까지 과세표준 
				R03_2013,			-- 2013년부터 과세표준 
				R03_C,				-- 법정이외퇴직소득과표 
				R03_S,				-- 퇴직소득과표 
				R04,				-- 법정연평균과세표준 
				R04_12,				-- 퇴직소득과세표준(2016년 개정) 
				R04_2012,			-- 2012년까지 연평균 과세표준(법정) 
				R04_2013,			-- 2013년부터 연평균 과세표준(법정) 
				R04_D,				-- 법정이외연평균과세표준 
				R04_DEDUCT,			-- 환산급여별공제(2016년 개정) 
				R04_D_2012,			-- 2012년까지 연평균 과세표준(법정이외) 
				R04_D_2013,			-- 2013년부터 연평균 과세표준(법정이외) 
				R04_N_12,			-- 환산급여(2016년 개정) 
				R04_S,				-- 연평균과세표준 
				R05,				-- 법정연평균산출세액 
				R05_12,				-- 환산산출세액(2016년 개정) 
				R05_2012,			-- 2012년까지 연평균 산출세액(법정) 
				R05_2013,			-- 2013년부터 연평균 산출세액(법정) 
				R05_E,				-- 법정이외연평균산출세액 
				R05_E_2012,			-- 2012년까지 연평균 산출세액(법정이외) 
				R05_E_2013,			-- 2013년부터 연평균 산출세액(법정이외) 
				R05_S,				-- 연평균산출세액 
				R06,				-- 법정산출세액 
				R06_2012,			-- 2012년까지 산출세액(법정) 
				R06_2013,			-- 2013년부터 산출세액(법정) 
				R06_F,				-- 법정이외산출세액 
				R06_F_2012,			-- 2012년까지 산출세액(법정이외) 
				R06_F_2013,			-- 2013년부터 산출세액(법정이외) 
				R06_N,				-- 산출세액(2016년 개정) 
				R06_S,				-- 산출세액 
				R07,				-- 법정세액공제 
				R07_G,				-- 법정이외세액공제 
				R07_S,				-- 세액공제 
				R08,				-- 법정결정세액 
				R08_H,				-- 법정이외결정세액 
				R08_S,				-- 결정세액 
				R09,				-- 법정퇴직소득세액공제 
				R09_I,				-- 법정이외퇴직소득세액공제 
				R09_S,				-- 퇴직소득세액공제 
				RC_C01_TAX_AMT,		-- 예상퇴직금법정퇴직금세금 
				REAL_AMT,			-- 실지급액 
				REP_ACCOUNT_NO,		-- 퇴직연금계좌번호 
				REP_ANNUITY_BIZ_NM,	-- 퇴직연금사업자명 
				REP_ANNUITY_BIZ_NO,	-- 퇴직연금사업장등록번호 
				REP_MID_YN,			-- 중간정산포함여부 
				RESIDENT_CD,		-- 거주자구분 
				RETIRE_FUND_MON,	-- 퇴직보험금(한국) 
				RETIRE_MID_AMT,		-- 중간정산퇴직금 
				RETIRE_MID_INCOME_AMT,	-- 중간정산퇴직소득세 
				RETIRE_MID_JTAX_AMT,							-- 중간정산퇴직주민세
				RETIRE_MID_NTAX_AMT,							-- 중간정산퇴직농특세
				RETIRE_TURN,		-- 국민연금퇴직전환금 
				RETIRE_TURN_INCOME_AMT,	-- 국민연금퇴직전환금소득세
				RETIRE_TURN_RESIDENCE_AMT,	-- 국민연금퇴직전환금주민세
				RETIRE_TYPE_CD,		-- 퇴직사유  
				SEND_YMD,			-- 제출일자 
				COMPANY_CD,			-- 회사코드 
				SUM_ADD_MM,			-- 정산 가산월 
				SUM_END_YMD,		-- 정산 퇴직일 
				SUM_EXCEPT_MM,		-- 정산 제외월 
				SUM_STA_YMD,		-- 정산 기산일 
				SUM_WORK_MM,		-- 정산 근속월 
				SUM_WORK_YY,		-- 정산 근속년수 
				T01,				-- 차감소득세 
				T02,				-- 차감주민세 
				T03,				-- 차감농특세 
				TAX_RATE,			-- 세율 
				TAX_TYPE,			-- 세금방식[REP_TAX_TYPE_CD] 
				TRANS_AMT,			-- 과세이연금액 
				TRANS_INCOME_AMT,	-- 과세이연소득세 
				TRANS_OTHER_AMT,	-- 법정이외과세이연금액 
				TRANS_RESIDENCE_AMT,-- 과세이연주민세 
				TRANS_YMD,			-- 퇴직연금 입금일
				TZ_CD,				-- 타임존코드 
				TZ_DATE,			-- 타임존일시 
				T_SUM,				-- 차감세액계 
				WORK_DAY,			-- 실근속총일수 
				WORK_DD,			-- 실근속일수 
				WORK_MM,			-- 실근속월수 
				WORK_YY,			-- 실근속년수(년만) 
				WORK_YY_PT,			-- 실근속년수(지급율) 
				ETC_PAY_AMT,		-- 기타수당
				ORG_NM,				-- 조직명
				ORG_LINE,			-- 조직순차
				BIZ_CD,				-- 사업장
				REG_BIZ_CD,			-- 신고사업장
				DUTY_CD,			-- 직책코드 [PHM_DUTY_CD]
				YEARNUM_CD,			-- 호봉코드 [PHM_YEARNUM_CD]
				MGR_TYPE_CD,		-- 관리구분코드[PHM_MGR_TYPE_CD]
				JOB_POSITION_CD,	-- 직종코드[PHM_JOB_POSTION_CD]
				JOB_CD,				-- 직무코드
				PAY_METH_CD,		-- 급여지급방식[PAY_METH_CD]
				EMP_CLS_CD,			-- 고용유형[PAY_EMP_CLS_CD]
				WORK_MM_PT,			-- 산정월수
				WORK_DD_PT,			-- 산정일수
				SUM_MONTH_DAY3,		-- 근속일수
				COMM_AMT,			-- 통상임금
				DAY_AMT,			-- 일당
				PAY01_YM,			-- 급여년월_01
				PAY02_YM,			-- 급여년월_02
				PAY03_YM,			-- 급여년월_03
				PAY04_YM,			-- 급여년월_04
				PAY05_YM,			-- 급여년월_05
				PAY06_YM,			-- 급여년월_06
				PAY07_YM,			-- 급여년월_07
				PAY08_YM,			-- 급여년월_08
				PAY09_YM,			-- 급여년월_09
				PAY10_YM,			-- 급여년월_10
				PAY11_YM,			-- 급여년월_11
				PAY12_YM,			-- 급여년월_12
				PAY01_AMT,			-- 급여금액_01
				PAY02_AMT,			-- 급여금액_02
				PAY03_AMT,			-- 급여금액_03
				PAY04_AMT,			-- 급여금액_04
				PAY05_AMT,			-- 급여금액_05
				PAY06_AMT,			-- 급여금액_06
				PAY07_AMT,			-- 급여금액_07
				PAY08_AMT,			-- 급여금액_08
				PAY09_AMT,			-- 급여금액_09
				PAY10_AMT,			-- 급여금액_10
				PAY11_AMT,			-- 급여금액_11
				PAY12_AMT,			-- 급여금액_12
				PAY_MON,			-- 급여합계
				PAY_TOT_AMT,		-- 3개월급여합계
				BONUS01_YM,			-- 상여년월_01
				BONUS02_YM,			-- 상여년월_02
				BONUS03_YM,			-- 상여년월_03
				BONUS04_YM,			-- 상여년월_04
				BONUS05_YM,			-- 상여년월_05
				BONUS06_YM,			-- 상여년월_06
				BONUS07_YM,			-- 상여년월_07
				BONUS08_YM,			-- 상여년월_08
				BONUS09_YM,			-- 상여년월_09
				BONUS10_YM,			-- 상여년월_10
				BONUS11_YM,			-- 상여년월_11
				BONUS12_YM,			-- 상여년월_12
				BONUS01_AMT,		-- 상여금액_01
				BONUS02_AMT,		-- 상여금액_02
				BONUS03_AMT,		-- 상여금액_03
				BONUS04_AMT,		-- 상여금액_04
				BONUS05_AMT,		-- 상여금액_05
				BONUS06_AMT,		-- 상여금액_06
				BONUS07_AMT,		-- 상여금액_07
				BONUS08_AMT,		-- 상여금액_08
				BONUS09_AMT,		-- 상여금액_09
				BONUS10_AMT,		-- 상여금액_10
				BONUS11_AMT,		-- 상여금액_11
				BONUS12_AMT,		-- 상여금액_12
				BONUS_TOT_AMT,		-- 3개월급여합계
				CNT_YEAR_REQ,		-- 연차발생일수
				CNT_YEAR_USE,		-- 연차사용일수
				CNT_YEAR,			-- 연차산정일수
				DAY_TOT_AMT,		-- 3개월 연월차수당
				PAY_SUM_AMT,		-- 3개월 총임금
				PAY_COMM_AMT,		-- 3개월 평균임금
				AVG_PAY_AMT_M,		-- 월 평균임금(년평균임금 / 12)
				AVG_PAY_AMT_D,		-- 일 평균임금
				AMT_RETR_PAY_Y,		-- 년 퇴직금
				AMT_RETR_PAY_M,		-- 월 퇴직금
				AMT_RETR_PAY_D,		-- 일 퇴직금
				AMT_RATE_ADD,		-- 누진율(임원배수)
				C_02_SUM,			-- 주(현)퇴직금
				B1_RERIRE_INSU_AMT,	-- 종(전)퇴직보험금
				BC_WORK_MM,			-- 근속개월수
				BC_WORK_ADD_MM,		-- 누진월수
				BC_WORK_TOT_MM,		-- 산정월수(근속개월수+누진월수)
				MID_DUP_MM,			-- 중간지급 중복월수
				R04_ADD,			-- 누진공제
				R06_SUM,			-- 산출세액 합계
				R06_2009,			-- 산출세액_2009년 한시적용
				ETC01_SUB_NM,		-- 기타공제01 제목
				ETC02_SUB_NM,		-- 기타공제02 제목
				ETC03_SUB_NM,		-- 기타공제03 제목
				ETC04_SUB_NM,		-- 기타공제04 제목
				ETC05_SUB_NM,		-- 기타공제05 제목
				ETC06_SUB_NM,		-- 기타공제06 제목
				ETC07_SUB_NM,		-- 기타공제07 제목
				ETC08_SUB_NM,		-- 기타공제08 제목
				ETC09_SUB_NM,		-- 기타공제09 제목
				ETC10_SUB_NM,		-- 기타공제10 제목
				ETC11_SUB_NM,		-- 기타공제11 제목
				ETC12_SUB_NM,		-- 기타공제12 제목
				ETC13_SUB_NM,		-- 기타공제13 제목
				ETC01_SUB_AMT,		-- 기타공제01 금액
				ETC02_SUB_AMT,		-- 기타공제02 금액
				ETC03_SUB_AMT,		-- 기타공제03 금액
				ETC04_SUB_AMT,		-- 기타공제04 금액
				ETC05_SUB_AMT,		-- 기타공제05 금액
				ETC06_SUB_AMT,		-- 기타공제06 금액
				ETC07_SUB_AMT,		-- 기타공제07 금액
				ETC08_SUB_AMT,		-- 기타공제08 금액
				ETC09_SUB_AMT,		-- 기타공제09 금액
				ETC10_SUB_AMT,		-- 기타공제10 금액
				ETC11_SUB_AMT,		-- 기타공제11 금액
				ETC12_SUB_AMT,		-- 기타공제12 금액
				ETC13_SUB_AMT,		-- 기타공제13 금액
				ETC01_PAY_NM,		-- 기타지급01 제목
				ETC02_PAY_NM,		-- 기타지급02 제목
				ETC03_PAY_NM,		-- 기타지급03 제목
				ETC04_PAY_NM,		-- 기타지급04 제목
				ETC05_PAY_NM,		-- 기타지급05 제목
				ETC06_PAY_NM,		-- 기타지급06 제목
				ETC07_PAY_NM,		-- 기타지급07 제목
				ETC08_PAY_NM,		-- 기타지급08 제목
				ETC09_PAY_NM,		-- 기타지급09 제목
				ETC10_PAY_NM,		-- 기타지급10 제목
				ETC01_PAY_AMT,		-- 기타지급01 금액
				ETC02_PAY_AMT,		-- 기타지급02 금액
				ETC03_PAY_AMT,		-- 기타지급03 금액
				ETC04_PAY_AMT,		-- 기타지급04 금액
				ETC05_PAY_AMT,		-- 기타지급05 금액
				ETC06_PAY_AMT,		-- 기타지급06 금액
				ETC07_PAY_AMT,		-- 기타지급07 금액
				ETC08_PAY_AMT,		-- 기타지급08 금액
				ETC09_PAY_AMT,		-- 기타지급09 금액
				ETC10_PAY_AMT,		-- 기타지급10 금액
				COMM_REAL_AMT,		-- 당사지급액
				PENSION_TOT,		-- 주(현)총수령액
				PENSION_WONRI,		-- 주(현)원리금합계액
				PENSION_RESERVE,	-- 주(현)연금적립액(소득자불입액)
				PENSION_GONGJE,		-- 주(현)퇴직연금소득공제액
				PENSION_CASH,		-- 주(현)퇴직연금일시금
				PENSION_REAL,		-- 주(현)21)퇴직연금일시금지급예산액
				SEND_YM,			-- 신고귀속년월
				SEND_YN,			-- 신고여부
				AUTO_YN,			-- 자동분개 여부
				AUTO_YMD,			-- 자동분개 이관일자
				AUTO_NO,			-- 자동분개 일련번호
				REC_YMD,			-- 영수일자
				CALCU_TPYE,			-- 계산구분
				PAY_GROUP,			-- 급여그룹
				B_PENSION_TOT,		-- 종(전)총수령액
				B_PENSION_WONRI,	-- 종(전)원리금합계액
				B_PENSION_RESERVE,	-- 종(전)연금적립액(소득자불입액)
				B_PENSION_GONGJE,	-- 종(전)퇴직연금소득공제액
				B_PENSION_CASH,		-- 종(전)퇴직연금일시금
				B_PENSION_REAL,		-- 종(전)21)퇴직연금일시금지급예산액
				TRANS_TOT_AMT,		-- 총일시금
				TRANS_NOW_AMT,		-- 수령가능퇴직급여액
				TRANS_SUDK_AMT,		-- 환산퇴직소득공제
				TRANS_RETR_AMT,		-- 환산퇴직소득과세표준
				TRANS_AVG_PAY,		-- 환산연평균과세표준
				TRANS_AVG_TAX,		-- 환산연평균산출세액
				R04_2013_5,			-- 2013년 이후 5년환산과세표준
				R05_2013_5,			-- 연평균산출세액
				RETPENSION_YMD      -- 납입금해당시간(시작일)
				)
				SELECT NEXT VALUE FOR dbo.S_REP_SEQUENCE AS REP_CALC_LIST_ID,			-- 퇴직금대상ID 
					   @emp_id,												-- 사원ID 	
					   CASE WHEN A.FG_RETR = '1' THEN '01'
							WHEN A.FG_RETR = '2' THEN '03'
							WHEN A.FG_RETR = '3' THEN '02'
							WHEN A.FG_RETR = '4' THEN '04'
							ELSE '01' END AS CALC_TYPE_CD,								-- 정산구분[REP_CALC_TYPE_CD]
					   dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') AS RETIRE_YMD,				-- 퇴직일 	   
					   CASE WHEN TRIM(A.FG_RETPENSION_KIND) = 'DB' THEN '10' 
							WHEN TRIM(A.FG_RETPENSION_KIND) = 'DC' THEN '20'
							WHEN TRIM(A.FG_RETPENSION_KIND) = 'TR' THEN '30'
							ELSE '00' 
					   END AS INS_TYPE_CD,												-- 퇴직연금구분
					   ISNULL(TRIM(A.YN_RETPENSION), 'N') AS INS_TYPE_YN,				-- 퇴직연금가입구분
					   NULL AS ADD_MM_2012,												-- 2012년까지 가산월수(계산) 
					   NULL AS ADD_MM_2013,												-- 2013년부터  가산월수(계산) 
					   NULL AS ADD_WORK_YY,												-- 추가근속년수(지급율) 
					   NULL AS AGENT_CD,												-- 징수의무자구분 
					   NULL AS APPL_CAUSE_CD,											-- 신청사유 
				--	   NULL AS APPL_GUBUN,												-- 중간전산(전후반)구분 
					   NULL AS APPL_ID,													-- 신청서ID 
					   NULL AS APPL_YMD,												-- 신청일자 
					   NULL AS ARMY_HIRE_YMD,											-- 군경력감안(인정)입사일 
					   NULL AS ATTACH_AMT,												-- 압류금 
					   A.AMT_BONUS_AVG3 AS AVG_BONUS,									-- 평균상여 
					   A.AMT_YEARMONTH_AVG3 AS AVG_DAY,									-- 평균연월차 
					   A.AMT_PAY_AVG AS AVG_PAY,										-- 평균급여 
					   A.AMT_DAY_PAY AS AVG_PAY_AMT,									-- 평균임금 
					   A.NM_O_PAY2 AS B1_CORP_NM,										-- 종(전)지급처명 
					   dbo.XF_TO_DATE(A.DT_O_RETIRE, 'YYYYMMDD') AS B1_END_YMD,			-- 종(전)정산일 
					   --A.CNT_BFR_EXCEPT_MONTH AS B1_EXCEPT_MM,						-- 종(전)제외월수 
					   NULL AS B1_EXCEPT_MM,											-- 종(전)제외월수
					   --A.AMT_O_PAY2_1 AS B1_RETIRE_AMT,								-- 종(전)퇴직급여
					   0 AS B1_RETIRE_AMT,												-- 종(전)퇴직급여
					   A.AMT_O_PAY2_2 AS B1_RETIRE_REP_AMT,								-- 종(전)명예/희망퇴직금 
					   dbo.XF_TO_DATE(A.DT_O_ENTER, 'YYYYMMDD') AS B1_STA_YMD,			-- 종(전)기산일 
					   A.NO_O_PAY2 AS B1_TAX_NO,										-- 종(전)사업자번호 
					   --A.CNT_O_DUTYMONTH AS B1_WORK_MM,								-- 종(전)근속월수 
					   NULL AS B1_WORK_MM,												-- 종(전)근속월수
					   A.AMT_O_PAY2_TOT AS B1_RETIRE_TOT,								-- 종(전)퇴직금
					   NULL AS B2_END_YMD,												-- 법정이외종(전)정산일 
					   NULL AS B2_EXCEPT_MM,											-- 법정이외종(전)제외월수 
					   NULL AS B2_STA_YMD,												-- 법정이외종(전)기산일 
					   NULL AS B2_WORK_MM,												-- 법정이외종(전)근속월수 
					   NULL AS BC1_DUP_MM,												-- 중복월수(법정) 
					   A.CNT_TAX_YEAR AS BC1_WORK_YY,									-- 근속년수(법정)(현+종전 근속년수) 
					   NULL AS BC2_DUP_MM,												-- 법정이외중복월수 
					   NULL AS BC2_WORK_YY,												-- 법정이외근속년수 
					   A.AMT_BONUS_TOT AS BONUS_MON,									-- 상여총액 
					   --A.AMT_OLD_STAX AS BT01,										-- 종(전)소득세 
					   0 AS BT01,														-- 종(전)소득세
					   --A.AMT_OLD_JTAX AS BT02,										-- 종(전)주민세 
					   0 AS BT02,														-- 종(전)주민세
					   --A.AMT_OLD_NTAX AS BT03,											-- 종(전)농특세 
					   0 AS BT03,														-- 종(전)농특세
					   ISNULL(A.AMT_OLD_STAX,0) + ISNULL(A.AMT_OLD_NTAX,0) + ISNULL(A.AMT_OLD_JTAX,0) AS BT_SUM,				-- 종(전)세액계 
					   NULL AS B_RETIRE_TAX_YN,											-- 종(전)퇴직소득세액공제여부 
					   NULL AS C1_ADD_MM,												-- 최종 가산월수 
					   NULL AS C1_ADD_MM_2012,											-- 최종 2012년까지 가산월수(입력) 
					   NULL AS C1_ADD_MM_2013,											-- 최종 2013년부터  가산월수(입력) 
					   dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') AS C1_END_YMD,				-- 주(현)정산일 
					   CASE WHEN A.DT_JOIN <= '20120101' THEN dbo.XF_TO_DATE('20121231', 'YYYYMMDD') ELSE NULL END AS C1_END_YMD_2012,		-- 2012년까지 종료일 
					   dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') AS C1_END_YMD_2013,		-- 2013년부터 종료일 
					   A.CNT_EXCEPT_MONTH AS C1_EXCEPT_MM,								-- 주(현)제외월수 
					   NULL AS C1_EXCEPT_MM_2012,										-- 최종 2012년까지 제외월수(입력) 
					   NULL AS C1_EXCEPT_MM_2013,										-- 최종 2013년부터 제외월수(입력) 
					   dbo.XF_TO_DATE(A.DT_JOIN, 'YYYYMMDD') AS C1_STA_YMD,				-- 법정주(현)기산일 
					   CASE WHEN A.DT_JOIN <= '20120101' THEN dbo.XF_TO_DATE(A.DT_JOIN, 'YYYYMMDD') ELSE NULL END AS C1_STA_YMD_2012,		-- 2012년까지 시작일 
					   CASE WHEN A.DT_JOIN < '20130101' THEN dbo.XF_TO_DATE('20130101', 'YYYYMMDD') ELSE dbo.XF_TO_DATE(A.DT_JOIN, 'YYYYMMDD') END AS C1_STA_YMD_2013,		-- 2013년부터 시작일 
					   NULL AS C1_TAX_RATE_2012,										-- 2012년까지 세율(법정) 
					   NULL AS C1_TAX_RATE_2013,										-- 2013년부터 세율(법정) 
					   (ISNULL(A.CNT_CAL_YEAR,0) * 12) + ISNULL(A.CNT_CAL_MONTH,0) AS C1_WORK_MM,			-- 주(현)근속월수 
					   A.CNT_CAL_MONTH_2012 AS C1_WORK_MM_2012,							-- 2012년까지 근속월 
					   A.CNT_CAL_MONTH_2013 AS C1_WORK_MM_2013,							-- 2012년부터 근속월 
					   A.CNT_TAX_YEAR AS C1_WORK_YY,									-- 최종 근속년수 
					   A.CNT_TAX_YEAR_2012 AS C1_WORK_YY_2012,							-- 2012년까지 근속년수(법정) 
					   A.CNT_TAX_YEAR_2013 AS C1_WORK_YY_2013,							-- 2013년부터 근속년수(법정) 
					   NULL AS C2_END_YMD,												-- 법정이외주(현)정산일 
					   NULL AS C2_EXCEPT_MM,											-- 법정이외주(현)제외월수 
					   NULL AS C2_STA_YMD,												-- 법정이외주(현)기산일 
					   NULL AS C2_TAX_RATE_2012,										-- 2012년까지 세율(법정이외) 
					   NULL AS C2_TAX_RATE_2013,										-- 2013년부터 세율(법정이외) 
					   NULL AS C2_WORK_MM,												-- 법정이외주(현)근속월수 
					   A.CNT_TAX_YEAR_2012 AS C2_WORK_YY_2012,							-- 2012년까지 근속년수(법정이외) 
					   A.CNT_TAX_YEAR_2013 AS C2_WORK_YY_2013,							-- 2013년부터 근속년수(법정이외) 
					   '04' AS CALC_RETIRE_CD,											-- 퇴직(정산)유형(해외파견,대외파견,군입댜,회사이동) 	    
					   A.RSN_RETIRE AS CAM_TYPE_CD,										-- 발령유형 
					   ISNULL(AMT_RETR_PAY,0) - (ISNULL(A.AMT_FIX_STAX,0) + ISNULL(A.AMT_FIX_NTAX,0) + ISNULL(A.AMT_FIX_JTAX,0)) AS CHAIN_AMT,	-- 차인지급액(퇴직금) 
					   A.AMT_FIX_STAX AS CT01,											-- 퇴직소득세 
					   A.AMT_FIX_JTAX AS CT02,											-- 퇴직주민세 
					   A.AMT_FIX_NTAX AS CT03,											-- 퇴직농특세 
					   ISNULL(A.AMT_FIX_STAX,0) + ISNULL(A.AMT_FIX_NTAX,0) + ISNULL(A.AMT_FIX_JTAX,0) AS CT_SUM,				-- 퇴직세액계 
					   A.AMT_RETR_PAY AS C_01,											-- 주(현)법정퇴직급여 =>  주(현)법정퇴직금 + 주(현)퇴직보험금 
					   A.AMT_RETR_PAY AS C_01_1,										-- 주(현)법정퇴직금 
					   A.AMT_N_PAY_3 AS C_01_2,											-- 주(현)퇴직보험금 
					   A.AMT_N_PAY_1 AS C_02,										-- 주(현)명예퇴직수당등 (추가퇴직금)  => 명예 + 추가퇴직금 
					   A.AMT_N_PAY_2 AS C_02_1,											-- 주(현)명예퇴직금 
					   NULL AS C_02_1_BASE,												-- 주(현)명예퇴직금기준금액 
					   NULL AS C_02_1_RATE,												-- 주(현)명예퇴직금지급율 
					   A.AMT_RETR_TOT AS C_02_2,										-- 주(현)추가퇴직금 
					   NULL AS C_02_2_RATE,												-- 주(현)추가퇴직금지급율 
					   NULL AS C_02_3,													-- 퇴직위로금 
					   A.YN_TAX_TRANS AS C_RETIRE_TAX_YN,								-- 주(현)퇴직소득세액공제여부 
					   A.AMT_RETR_PAY AS C_SUM,											-- 주(현)계 
					   NULL AS DUMMY_YN,												-- DUMMY여부 
					   NULL AS DUP_MM,													-- 정산 중복월 
					   ISNULL(A.FG_PERSON, B.EMP_KIND_CD) AS EMP_KIND_CD,										-- 근로구분코드 [PHM_EMP_KIND_CD]
					   NULL AS END_YN,													-- 완료여부 
					   ISNULL(A.AMT_ETC01_SUB,0) + ISNULL(A.AMT_ETC02_SUB,0) + ISNULL(A.AMT_ETC03_SUB,0) + ISNULL(A.AMT_ETC04_SUB,0) + ISNULL(A.AMT_ETC05_SUB,0) + 
					   ISNULL(A.AMT_ETC06_SUB,0) + ISNULL(A.AMT_ETC07_SUB,0) + ISNULL(A.AMT_ETC08_SUB,0) + ISNULL(A.AMT_ETC09_SUB,0) + ISNULL(A.AMT_ETC10_SUB,0) AS ETC_DEDUCT,	-- 기타공제 
					   NULL AS EXCEPT_MM_2012,											-- 2012년까지 제외월수(계산) 
					   NULL AS EXCEPT_MM_2013,											-- 2013년부터 제외월수(계산) 
					   NULL AS EXCE_END_YMD,											-- 퇴직금제외종료일 
					   NULL AS EXCE_STA_YMD,											-- 퇴직금제외시작일 
					   NULL AS FILLDT,													-- 기표일 
					   NULL AS FILLNO,													-- 전표번호 
					   dbo.XF_TO_DATE(B.FIRST_JOIN_YMD,'yyyymmdd') AS FIRST_HIRE_YMD,								-- 최초입사일 
					   NULL AS FLAG,													-- 1년미만여부 
					   NULL AS FLAG2,													-- 중간정산(임금피크Y보통N) 
					   --NULL AS JSOFCD1,													-- JSOFCD1 
					   --NULL AS JSOFCD2,													-- JSOFCD2 
					   NULL AS LAST_YN,													-- 마지막여부 
					   NULL AS MID_ADD_MM,												-- 중간지급  가산월 
					   dbo.XF_TO_DATE(A.DT_O_RETIRE,'yyyymmdd') AS MID_END_YMD,									-- 중간지급 퇴직일 
					   A.CNT_BFR_EXCEPT_MONTH AS MID_EXCEPT_MM,							-- 중간지급 제외월 
					   NULL AS MID_HIRE_YMD,											-- 중간지급 입사일
					   NULL AS MID_PAY_YMD,												-- 중간지급 지급일 
					   dbo.XF_TO_DATE(A.DT_O_ENTER,'yyyymmdd') AS MID_STA_YMD,										-- 중간지급 기산일 
					   A.CNT_O_DUTYMONTH AS MID_WORK_MM,								-- 중간지급 근속월 
					   A.CNT_BFR_DUTY_YEAR AS MID_WORK_YY,								-- 중간지급 근속년수 
					   ISNULL(A.DT_UPDATE,GETDATE()) AS MOD_DATE,											-- 변경일시 
					   0 AS MOD_USER_ID,												-- 변경자 
					   A.CNT_AVG_DAY AS MONTH_DAY3,										-- 3개월근무일수 
					   A.AMT_TAX_EXEMPTION_I AS NON_RETIRE_AMT,							-- 비과세퇴직금 
					   A.AMT_BFR_TAX_EXEMPTION_I AS NON_RETIRE_MID_AMT,					-- 비과세중간정산퇴직금 
					   A.REM_COMMENT AS NOTE,											-- 비고 
					   NULL AS OFFICERS_YN,												-- 임원여부 
					   ISNULL((SELECT ORG_ID 
						  FROM ORM_ORG (NOLOCK)
						 WHERE ORG_CD = A.CD_DEPT 
						   AND COMPANY_CD = A.CD_COMPANY
						   /* AND dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') BETWEEN STA_YMD AND END_YMD */ ), B.ORG_ID) AS ORG_ID,		-- 발령부서ID 
					   NULL AS ORIGIN_REP_CALC_LIST_ID,									-- 재정산전 퇴직금대상ID 
					   ISNULL((SELECT ORG_ID 
						  FROM ORM_ORG (NOLOCK)
						 WHERE ORG_CD = A.CD_DEPT 
						   AND COMPANY_CD = A.CD_COMPANY
						   /* AND dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') BETWEEN STA_YMD AND END_YMD */ ), B.ORG_ID) AS PAY_ORG_ID,	-- 급여부서ID 
					   dbo.XF_TO_DATE(A.DT_BASE, 'YYYYMMDD') AS PAY_YMD,				-- 지급일 
					   ISNULL(A.CD_POSITION, B.POS_CD) AS POS_CD,											-- 직위코드 [PHM_POS_CD]
					   ISNULL(A.LVL_PAY1, B.POS_GRD_CD) AS POS_GRD_CD,										-- 직급코드 [PHM_POS_GRD_CD]
					   A.AMT_RETR_PAY AS R01,											-- 법정퇴직급여액 
					   NULL AS R01_A,													-- 법정이외퇴직급여액 
					   A.AMT_RETR_TOT AS R01_S,											-- 퇴직급여액 
					   A.AMT_RETR_SUDK_GONG AS R02,										-- 법정퇴직소득공제(01+02) 
					   A.AMT_RETR_SUDK_GONG2 AS R02_01,									-- 법정퇴직소득공제(50%) 
					   A.AMT_RETR_SUDK_GONG3 AS R02_02,									-- 법정퇴직소득공제(근속) 
					   NULL AS R02_B,													-- 법정이외퇴직소득공제(01+02) 
					   A.AMT_RETR_SUDK_GONG1 AS R02_B_01,								-- 법정이외퇴직소득공제(50%) 
					   NULL AS R02_B_02,												-- 법정이외퇴직소득공제(근속) 
					   A.AMT_RETR_SUDK_GONG AS R02_S,									-- 퇴직소득공제 
					   A.AMT_BASE_TAX AS R03,											-- 법정퇴직소득과표 
					   A.AMT_BASE_TAX_2012 AS R03_2012,									-- 2012년까지 과세표준 
					   A.AMT_BASE_TAX_2013 AS R03_2013,									-- 2013년부터 과세표준 
					   NULL AS R03_C,													-- 법정이외퇴직소득과표 
					   A.AMT_BASE_TAX AS R03_S,											-- 퇴직소득과표 
					   A.AMT_Y_BASE_TAX AS R04,											-- 법정연평균과세표준 
					   A.AMT_BASE_TAX_2016 AS R04_12,									-- 퇴직소득과세표준(2016년 개정) 
					   A.AMT_Y_BASE_TAX_2012 AS R04_2012,								-- 2012년까지 연평균 과세표준(법정) 
					   A.AMT_BASE_TAX_2013_DIV AS R04_2013,								-- 2013년부터 연평균 과세표준(법정) 
					   NULL AS R04_D,													-- 법정이외연평균과세표준 
					   A.AMT_RETR_SUDK_GONG4 AS R04_DEDUCT,								-- 환산급여별공제(2016년 개정) 
					   A.AMT_Y_BASE_TAX_2012 AS R04_D_2012,								-- 2012년까지 연평균 과세표준(법정이외) 
					   A.AMT_BASE_TAX_2013_DIV AS R04_D_2013,							-- 2013년부터 연평균 과세표준(법정이외) 
					   A.AMT_TRNS_PAY AS R04_N_12,										-- 환산급여(2016년 개정) 
					   A.AMT_BASE_TAX_2013_DIV AS R04_S,								-- 연평균과세표준 
					   NULL AS R05,														-- 법정연평균산출세액 
					   A.AMT_CAL_TAX_2016 AS R05_12,									-- 환산산출세액(2016년 개정) 
					   A.AMT_Y_CAL_TAX AS R05_2012,										-- 2012년까지 연평균 산출세액(법정) 
					   A.AMT_Y_CAL_TAX_2013 AS R05_2013,								-- 2013년부터 연평균 산출세액(법정) 
					   NULL AS R05_E,													-- 법정이외연평균산출세액 
					   A.AMT_Y_CAL_TAX AS R05_E_2012,									-- 2012년까지 연평균 산출세액(법정이외) 
					   A.AMT_Y_CAL_TAX_2013 AS R05_E_2013,								-- 2013년부터 연평균 산출세액(법정이외) 
					   NULL AS R05_S,													-- 연평균산출세액 
					   A.AMT_CAL_TAX3 AS R06,											-- 법정산출세액 
					   A.AMT_CAL_TAX_2012 AS R06_2012,									-- 2012년까지 산출세액(법정) 
					   A.AMT_CAL_TAX_2013 AS R06_2013,									-- 2013년부터 산출세액(법정) 
					   NULL AS R06_F,													-- 법정이외산출세액 
					   A.AMT_CAL_TAX_2012 AS R06_F_2012,								-- 2012년까지 산출세액(법정이외) 
					   A.AMT_CAL_TAX_2013 AS R06_F_2013,								-- 2013년부터 산출세액(법정이외) 
					   A.AMT_CAL_TAX2 AS R06_N,											-- 산출세액(2016년 개정) 
					   A.AMT_FIX_STAX AS R06_S,											-- 산출세액 
					   NULL AS R07,														-- 법정세액공제 
					   NULL AS R07_G,													-- 법정이외세액공제 
					   NULL AS R07_S,													-- 세액공제 
					   A.AMT_FIX_STAX AS R08,											-- 법정결정세액 
					   NULL AS R08_H,													-- 법정이외결정세액 
					   A.AMT_FIX_STAX AS R08_S,											-- 결정세액 
					   NULL AS R09,														-- 법정퇴직소득세액공제 
					   NULL AS R09_I,													-- 법정이외퇴직소득세액공제 
					   NULL AS R09_S,													-- 퇴직소득세액공제 
					   NULL AS RC_C01_TAX_AMT,											-- 예상퇴직금법정퇴직금세금 
					   A.AMT_REAL_PAY AS REAL_AMT,										-- 실지급액 
					   A.POSTPONE_ACCNT AS REP_ACCOUNT_NO,								-- 퇴직연금계좌번호 
					   A.POSTPONE_BIZ_NAME AS REP_ANNUITY_BIZ_NM,						-- 퇴직연금사업자명 
					   A.POSTPONE_BIZ_NO AS REP_ANNUITY_BIZ_NO,							-- 퇴직연금사업장등록번호
					   YN_MID AS REP_MID_YN,											-- 중간정산포함여부 
					   NULL AS RESIDENT_CD,												-- 거주자구분 
					   NULL AS RETIRE_FUND_MON,											-- 퇴직보험금(한국) 
					   A.AMT_O_PAY2_1 AS RETIRE_MID_AMT,								-- 중간정산퇴직금 
					   A.AMT_OLD_STAX AS RETIRE_MID_INCOME_AMT,							-- 중간정산퇴직소득세 
					   A.AMT_OLD_JTAX AS RETIRE_MID_JTAX_AMT,							-- 중간정산퇴직주민세
					   A.AMT_OLD_NTAX AS RETIRE_MID_NTAX_AMT,							-- 중간정산퇴직농특세
					   A.AMT_ANU_RET_AMT AS RETIRE_TURN,								-- 국민연금퇴직전환금 
					   A.AMT_ANU_RET_INC AS RETIRE_TURN_INCOME_AMT,						-- 국민연금 퇴직전환금 소득세
					   A.AMT_ANU_RET_LOC AS RETIRE_TURN_RESIDENCE_AMT,					-- 국민연금 퇴직전환금 주민세
					   A.RSN_RETIRE AS RETIRE_TYPE_CD,									-- 퇴직사유 
					   dbo.XF_TO_DATE(A.DT_REGISTER, 'YYYYMMDD') AS SEND_YMD,			-- 신고(제출)일자 
					   A.CD_COMPANY AS COMPANY_CD,										-- 서브회사코드 
					   NULL AS SUM_ADD_MM,												-- 정산 가산월 
					   dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') AS SUM_END_YMD,			-- 정산 퇴직일 
					   A.CNT_EXCEPT_MONTH AS SUM_EXCEPT_MM,								-- 정산 제외월 
					   dbo.XF_TO_DATE(A.DT_JOIN, 'YYYYMMDD') AS SUM_STA_YMD,			-- 정산 기산일 
					   (ISNULL(A.CNT_CAL_YEAR,0) * 12) + ISNULL(CNT_CAL_MONTH,0) AS SUM_WORK_MM,	-- 정산 근속월 
					   A.CNT_TAX_YEAR AS SUM_WORK_YY,									-- 정산 근속년수 
					   A.AMT_NEW_STAX AS T01,											-- 차감소득세 
					   A.AMT_NEW_JTAX AS T02,											-- 차감주민세 
					   A.AMT_NEW_NTAX AS T03,											-- 차감농특세 
					   A.RATE_BASE AS TAX_RATE,											-- 세율 
					   NULL AS TAX_TYPE,												-- 세금방식[REP_TAX_TYPE_CD] 
					   A.POSTPONE_DEPOSIT AS TRANS_AMT,									-- 과세이연금액 
					   A.POSTPONE_TAX AS TRANS_INCOME_AMT,								-- 과세이연소득세 
					   NULL AS TRANS_OTHER_AMT,											-- 법정이외과세이연금액 
					   dbo.XF_TRUNC_N(A.POSTPONE_TAX / 10,0) AS TRANS_RESIDENCE_AMT,	-- 과세이연주민세
					   dbo.XF_TO_DATE(A.POSTPONE_DEPOSIT_DATE,'yyyymmdd') AS TRANS_YMD,							-- 퇴직연금 입금일
					   'KST' AS TZ_CD,											-- 타임존코드 
					   ISNULL(A.DT_INSERT, '19000101') AS TZ_DATE,				-- 타임존일시 
					   ISNULL(A.AMT_NEW_STAX,0) + ISNULL(A.AMT_NEW_NTAX,0) + ISNULL(A.AMT_NEW_JTAX,0) AS T_SUM,		-- 차감세액계 
					   dbo.XF_DATEDIFF(dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD'), dbo.XF_TO_DATE(A.DT_JOIN, 'YYYYMMDD')) + 1 AS WORK_DAY,			-- 실근속총일수 
					   A.CNT_DUTY_DAY AS WORK_DD,										-- 실근속일수 
					   A.CNT_DUTY_MONTH AS WORK_MM,										-- 실근속월수 
					   A.CNT_DUTY_YEAR AS WORK_YY,										-- 실근속년수(년만) 
					   A.CNT_CAL_YEAR AS WORK_YY_PT,									-- 실근속년수(지급율) 
					   ISNULL(A.AMT_ETC01_PROV,0) + ISNULL(A.AMT_ETC02_PROV,0) + ISNULL(A.AMT_ETC03_PROV,0) + ISNULL(A.AMT_ETC04_PROV,0) + ISNULL(A.AMT_ETC05_PROV,0) + 
					   ISNULL(A.AMT_ETC06_PROV,0) + ISNULL(A.AMT_ETC07_PROV,0) + ISNULL(A.AMT_ETC08_PROV,0) + ISNULL(A.AMT_ETC09_PROV,0) + ISNULL(A.AMT_ETC10_PROV,0) AS ETC_PAY_AMT,			-- 기타수당
					   ISNULL((SELECT ORG_NM 
						  FROM ORM_ORG (NOLOCK)
						 WHERE ORG_CD = A.CD_DEPT 
						   AND COMPANY_CD = @t_company_cd
						  /* AND dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') BETWEEN STA_YMD AND END_YMD */), A.NM_DEPT) AS ORG_NM,	-- 조직명
					   ISNULL(dbo.F_FRM_ORM_ORG_NM((select org_id from orm_org (NOLOCK) where company_cd=@t_company_cd and org_cd = A.CD_DEPT), 'KO', A.DT_BASE, 'LL'), A.CD_SEQ) AS ORG_LINE,	-- 조직순차
					   A.CD_BIZ_AREA AS BIZ_CD,											-- 사업장
					   A.CD_REG_BIZ_AREA AS REG_BIZ_CD,									-- 신고사업장
					   ISNULL(A.CD_ABIL, B.DUTY_CD) AS DUTY_CD,											-- 직책코드 [PHM_DUTY_CD]
					   ISNULL(A.LVL_PAY2, B.YEARNUM_CD) AS YEARNUM_CD,										-- 호봉코드 [PHM_YEARNUM_CD]
					   ISNULL(A.TP_DUTY, B.MGR_TYPE_CD) AS MGR_TYPE_CD,										-- 관리구분코드[PHM_MGR_TYPE_CD]
					   ISNULL(A.CD_OCPT, B.JOB_POSITION_CD) AS JOB_POSITION_CD,									-- 직종코드[PHM_JOB_POSTION_CD]
					   ISNULL(A.CD_JOB, B.JOB_CD) AS JOB_CD,												-- 직무코드
					   A.TP_CALC_PAY AS PAY_METH_CD,									-- 급여지급방식[PAY_METH_CD]
					   A.TP_CALC_INS AS EMP_CLS_CD,										-- 고용유형[PAY_EMP_CLS_CD]
					   A.CNT_CAL_MONTH AS WORK_MM_PT,									-- 산정월수
					   A.CNT_CAL_DAY AS WORK_DD_PT,										-- 산정일수
					   A.CNT_WORK_DAY AS SUM_MONTH_DAY3,								-- 근속일수
					   A.AMT_COMM AS COMM_AMT,											-- 통상임금
					   A.AMT_DAY AS DAY_AMT,											-- 일당
					   A.DT_PAY01 AS PAY01_YM,											-- 급여년월_01
					   A.DT_PAY02 AS PAY02_YM,											-- 급여년월_02
					   A.DT_PAY03 AS PAY03_YM,											-- 급여년월_03
					   A.DT_PAY04 AS PAY04_YM,											-- 급여년월_04
					   A.DT_PAY05 AS PAY05_YM,											-- 급여년월_05
					   A.DT_PAY06 AS PAY06_YM,											-- 급여년월_06
					   A.DT_PAY07 AS PAY07_YM,											-- 급여년월_07
					   A.DT_PAY08 AS PAY08_YM,											-- 급여년월_08
					   A.DT_PAY09 AS PAY09_YM,											-- 급여년월_09
					   A.DT_PAY10 AS PAY10_YM,											-- 급여년월_10
					   A.DT_PAY11 AS PAY11_YM,											-- 급여년월_11
					   A.DT_PAY12 AS PAY12_YM,											-- 급여년월_12
					   A.AMT_PAY01 AS PAY01_AMT,										-- 급여금액_01
					   A.AMT_PAY02 AS PAY02_AMT,										-- 급여금액_02
					   A.AMT_PAY03 AS PAY03_AMT,										-- 급여금액_03
					   A.AMT_PAY04 AS PAY04_AMT,										-- 급여금액_04
					   A.AMT_PAY05 AS PAY05_AMT,										-- 급여금액_05
					   A.AMT_PAY06 AS PAY06_AMT,										-- 급여금액_06
					   A.AMT_PAY07 AS PAY07_AMT,										-- 급여금액_07
					   A.AMT_PAY08 AS PAY08_AMT,										-- 급여금액_08
					   A.AMT_PAY09 AS PAY09_AMT,										-- 급여금액_09
					   A.AMT_PAY10 AS PAY10_AMT,										-- 급여금액_10
					   A.AMT_PAY11 AS PAY11_AMT,										-- 급여금액_11
					   A.AMT_PAY12 AS PAY12_AMT,										-- 급여금액_12
					   A.AMT_PAY_SUM_YEAR AS PAY_MON,									-- 급여합계
					   A.AMT_PAY_TOT AS PAY_TOT_AMT,									-- 3개월급여합계
					   A.DT_BONUS01 AS BONUS01_YM,										-- 상여년월_01
					   A.DT_BONUS02 AS BONUS02_YM,										-- 상여년월_02
					   A.DT_BONUS03 AS BONUS03_YM,										-- 상여년월_03
					   A.DT_BONUS04 AS BONUS04_YM,										-- 상여년월_04
					   A.DT_BONUS05 AS BONUS05_YM,										-- 상여년월_05
					   A.DT_BONUS06 AS BONUS06_YM,										-- 상여년월_06
					   A.DT_BONUS07 AS BONUS07_YM,										-- 상여년월_07
					   A.DT_BONUS08 AS BONUS08_YM,										-- 상여년월_08
					   A.DT_BONUS09 AS BONUS09_YM,										-- 상여년월_09
					   A.DT_BONUS10 AS BONUS10_YM,										-- 상여년월_10
					   A.DT_BONUS11 AS BONUS11_YM,										-- 상여년월_11
					   A.DT_BONUS12 AS BONUS12_YM,										-- 상여년월_12
					   A.AMT_BONUS01 AS BONUS01_AMT,									-- 상여금액_01
					   A.AMT_BONUS02 AS BONUS02_AMT,									-- 상여금액_02
					   A.AMT_BONUS03 AS BONUS03_AMT,									-- 상여금액_03
					   A.AMT_BONUS04 AS BONUS04_AMT,									-- 상여금액_04
					   A.AMT_BONUS05 AS BONUS05_AMT,									-- 상여금액_05
					   A.AMT_BONUS06 AS BONUS06_AMT,									-- 상여금액_06
					   A.AMT_BONUS07 AS BONUS07_AMT,									-- 상여금액_07
					   A.AMT_BONUS08 AS BONUS08_AMT,									-- 상여금액_08
					   A.AMT_BONUS09 AS BONUS09_AMT,									-- 상여금액_09
					   A.AMT_BONUS10 AS BONUS10_AMT,									-- 상여금액_10
					   A.AMT_BONUS11 AS BONUS11_AMT,									-- 상여금액_11
					   A.AMT_BONUS12 AS BONUS12_AMT,									-- 상여금액_12
					   A.AMT_BONUS_MONTH3 AS BONUS_TOT_AMT,								-- 3개월급여합계
					   A.CNT_YEAR_REQ AS CNT_YEAR_REQ,									-- 연차발생일수
					   A.CNT_YEAR_USE AS CNT_YEAR_USE,									-- 연차사용일수
					   A.CNT_YEAR AS CNT_YEAR,											-- 연차산정일수
					   A.AMT_YEARMONTH_TOT3 AS DAY_TOT_AMT,								-- 3개월 연월차수당
					   A.AMT_MONTH_PAY3 AS PAY_SUM_AMT,									-- 3개월 총임금
					   A.AMT_COMM_PAY3 AS PAY_COMM_AMT,									-- 3개월 평균임금
					   A.AMT_DAY_PAY_M AS AVG_PAY_AMT_M,								-- 월 평균임금(년평균임금 / 12)
					   A.AMT_DAY_PAY_D AS AVG_PAY_AMT_D,								-- 일 평균임금
					   A.AMT_RETR_PAY_Y AS AMT_RETR_PAY_Y,								-- 년 퇴직금
					   A.AMT_RETR_PAY_M AS AMT_RETR_PAY_M,								-- 월 퇴직금
					   A.AMT_RETR_PAY_D AS AMT_RETR_PAY_D,								-- 일 퇴직금
					   A.RATE_ADD AS TAX_RATE_ADD,										-- 누진율(임원배수)
					   A.AMT_N_PAY_TOT AS C_02_SUM,										-- 주(현)퇴직금
					   A.AMT_O_PAY2_3 AS B1_RERIRE_INSU_AMT,							-- 종(전)퇴직보험금
					   A.CNT_N_DUTYMONTH AS BC_WORK_MM,									-- 근속개월수
					   A.CNT_N_ADDMONTH AS BC_WORK_ADD_MM,								-- 누진월수
					   A.CNT_N_MONTH AS BC_WORK_TOT_MM,									-- 산정월수(근속개월수+누진월수)
					   A.CNT_O_DOUBMONTH AS MID_DUP_MM,									-- 중간지급 중복월수
					   A.AMT_ADD_GONGJE AS R04_ADD,										-- 누진공제
					   A.AMT_CAL_TAX AS R06_SUM,										-- 산출세액 합계
					   A.AMT_TAX_GONG AS R06_2009,										-- 산출세액_2009년 한시적용
					   A.NM_ETC01_SUB_TIT AS ETC01_SUB_NM,								-- 기타공제01 제목
					   A.NM_ETC02_SUB_TIT AS ETC02_SUB_NM,								-- 기타공제02 제목
					   A.NM_ETC03_SUB_TIT AS ETC03_SUB_NM,								-- 기타공제03 제목
					   A.NM_ETC04_SUB_TIT AS ETC04_SUB_NM,								-- 기타공제04 제목
					   A.NM_ETC05_SUB_TIT AS ETC05_SUB_NM,								-- 기타공제05 제목
					   A.NM_ETC06_SUB_TIT AS ETC06_SUB_NM,								-- 기타공제06 제목
					   A.NM_ETC07_SUB_TIT AS ETC07_SUB_NM,								-- 기타공제07 제목
					   A.NM_ETC08_SUB_TIT AS ETC08_SUB_NM,								-- 기타공제08 제목
					   A.NM_ETC09_SUB_TIT AS ETC09_SUB_NM,								-- 기타공제09 제목
					   A.NM_ETC10_SUB_TIT AS ETC10_SUB_NM,								-- 기타공제10 제목
					   A.NM_ETC11_SUB_TIT AS ETC11_SUB_NM,								-- 기타공제11 제목
					   A.NM_ETC12_SUB_TIT AS ETC12_SUB_NM,								-- 기타공제12 제목
					   A.NM_ETC13_SUB_TIT AS ETC13_SUB_NM,								-- 기타공제13 제목
					   A.AMT_ETC01_SUB AS ETC01_SUB_AMT,								-- 기타공제01 금액
					   A.AMT_ETC02_SUB AS ETC02_SUB_AMT,								-- 기타공제02 금액
					   A.AMT_ETC03_SUB AS ETC03_SUB_AMT,								-- 기타공제03 금액
					   A.AMT_ETC04_SUB AS ETC04_SUB_AMT,								-- 기타공제04 금액
					   A.AMT_ETC05_SUB AS ETC05_SUB_AMT,								-- 기타공제05 금액
					   A.AMT_ETC06_SUB AS ETC06_SUB_AMT,								-- 기타공제06 금액
					   A.AMT_ETC07_SUB AS ETC07_SUB_AMT,								-- 기타공제07 금액
					   A.AMT_ETC08_SUB AS ETC08_SUB_AMT,								-- 기타공제08 금액
					   A.AMT_ETC09_SUB AS ETC09_SUB_AMT,								-- 기타공제09 금액
					   A.AMT_ETC10_SUB AS ETC10_SUB_AMT,								-- 기타공제10 금액
					   A.AMT_ETC11_SUB AS ETC11_SUB_AMT,								-- 기타공제11 금액
					   A.AMT_ETC12_SUB AS ETC12_SUB_AMT,								-- 기타공제12 금액
					   A.AMT_ETC13_SUB AS ETC13_SUB_AMT,								-- 기타공제13 금액
					   A.NM_ETC01_PROV_TIT AS ETC01_PAY_NM,								-- 기타지급01 제목
					   A.NM_ETC02_PROV_TIT AS ETC02_PAY_NM,								-- 기타지급02 제목
					   A.NM_ETC03_PROV_TIT AS ETC03_PAY_NM,								-- 기타지급03 제목
					   A.NM_ETC04_PROV_TIT AS ETC04_PAY_NM,								-- 기타지급04 제목
					   A.NM_ETC05_PROV_TIT AS ETC05_PAY_NM,								-- 기타지급05 제목
					   A.NM_ETC06_PROV_TIT AS ETC06_PAY_NM,								-- 기타지급06 제목
					   A.NM_ETC07_PROV_TIT AS ETC07_PAY_NM,								-- 기타지급07 제목
					   A.NM_ETC08_PROV_TIT AS ETC08_PAY_NM,								-- 기타지급08 제목
					   A.NM_ETC09_PROV_TIT AS ETC09_PAY_NM,								-- 기타지급09 제목
					   A.NM_ETC10_PROV_TIT AS ETC10_PAY_NM,								-- 기타지급10 제목
					   A.AMT_ETC01_PROV AS ETC01_PAY_AMT,								-- 기타지급01 금액
					   A.AMT_ETC02_PROV AS ETC02_PAY_AMT,								-- 기타지급02 금액
					   A.AMT_ETC03_PROV AS ETC03_PAY_AMT,								-- 기타지급03 금액
					   A.AMT_ETC04_PROV AS ETC04_PAY_AMT,								-- 기타지급04 금액
					   A.AMT_ETC05_PROV AS ETC05_PAY_AMT,								-- 기타지급05 금액
					   A.AMT_ETC06_PROV AS ETC06_PAY_AMT,								-- 기타지급06 금액
					   A.AMT_ETC07_PROV AS ETC07_PAY_AMT,								-- 기타지급07 금액
					   A.AMT_ETC08_PROV AS ETC08_PAY_AMT,								-- 기타지급08 금액
					   A.AMT_ETC09_PROV AS ETC09_PAY_AMT,								-- 기타지급09 금액
					   A.AMT_ETC10_PROV AS ETC10_PAY_AMT,								-- 기타지급10 금액
					   A.AMT_REAL_PAY_1 AS COMM_REAL_AMT,								-- 당사지급액
					   A.AMT_PENSION_TOT AS PENSION_TOT,								-- 주(현)총수령액
					   A.AMT_PENSION_WONRI AS PENSION_WONRI,							-- 주(현)원리금합계액
					   A.AMT_PENSION_RESERVE AS PENSION_RESERVE,						-- 주(현)연금적립액(소득자불입액)
					   A.AMT_PENSION_GONGJE AS PENSION_GONGJE,							-- 주(현)퇴직연금소득공제액
					   A.AMT_PENSION_CASH AS PENSION_CASH,								-- 주(현)퇴직연금일시금
					   A.AMT_PENSION_REAL AS PENSION_REAL,								-- 주(현)21)퇴직연금일시금지급예산액
					   A.YM_REGISTER AS SEND_YM,										-- 신고귀속년월
					   A.YN_REGISTER AS SEND_YN,										-- 신고여부
					   A.YN_AUTO AS AUTO_YN,											-- 자동분개 여부
					   dbo.XF_TO_DATE(A.DT_AUTO, 'YYYYMMDD') AS AUTO_YMD,				-- 자동분개 이관일자
					   A.NO_AUTO AS AUTO_NO,											-- 자동분개 일련번호
					   dbo.XF_TO_DATE(A.DT_REC, 'YYYYMMDD') AS REC_YMD,					-- 영수일자
					   A.FG_CALCU AS CALCU_TPYE,										-- 계산구분
					   A.CD_PAYGP AS PAY_GROUP,											-- 급여그룹
					   A.AMT_O_PENSION_TOT AS B_PENSION_TOT,							-- 종(전)총수령액
					   A.AMT_O_PENSION_WONRI AS B_PENSION_WONRI,						-- 종(전)원리금합계액
					   A.AMT_O_PENSION_RESERVE AS B_PENSION_RESERVE,					-- 종(전)연금적립액(소득자불입액)
					   A.AMT_O_PENSION_GONGJE AS B_PENSION_GONGJE,						-- 종(전)퇴직연금소득공제액
					   A.AMT_O_PENSION_CASH AS B_PENSION_CASH,							-- 종(전)퇴직연금일시금
					   A.AMT_O_PENSION_REAL AS B_PENSION_REAL,							-- 종(전)21)퇴직연금일시금지급예산액
					   A.ONE_AMT_TOT AS TRANS_TOT_AMT,									-- 총일시금
					   A.AMT_NOW_PENSION_TOT AS TRANS_NOW_AMT,							-- 수령가능퇴직급여액
					   A.AMT_TRANS_SUDK_GONG AS TRANS_SUDK_AMT,							-- 환산퇴직소득공제
					   A.AMT_RETIRE_PAY AS TRANS_RETR_AMT,								-- 환산퇴직소득과세표준
					   A.AMT_TRANS_AVG_PAY_BASE AS TRANS_AVG_PAY,						-- 환산연평균과세표준
					   A.AMT_TRANS_AVG_PAY_TAX AS TRANS_AVG_TAX,						-- 환산연평균산출세액
					   A.AMT_Y_BASE_TAX_2013 AS R04_2013_5,								-- 2013년 이후 5년환산과세표준
					   A.AMT_Y_CAL_TAX_2013_DIV AS R05_2013_5,							-- 연평균산출세액
					   A.DT_RETPENSION_F AS RETPESION_YMD							-- 납입금해당기간(시작일)
				  FROM [DWEHRDEV].DBO.H_RETIRE_DETAIL A
				INNER JOIN PHM_EMP B (NOLOCK)
					ON @t_company_cd = B.COMPANY_CD
				   AND A.NO_PERSON = B.EMP_NO
				WHERE A.CD_COMPANY = @s_company_cd
				  AND A.DT_BASE = @dt_base
				  AND A.FG_RETR = @fg_retr
				  AND A.NO_PERSON = @no_person
				  AND A.DT_RETR = @dt_retr
				  -- Data 오류
			   AND (ISNULL(A.DT_RETR, '') <> '')
			   AND A.DT_BASE = A.DT_RETR
			   AND A.DT_BASE NOT IN ('2011231', '20091232')
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================

				if @@ROWCOUNT > 0 
					begin
						-- *** 성공메시지 로그에 저장 ***
						-- *** 성공메시지 로그에 저장 ***
						set @n_cnt_success = @n_cnt_success + 1 -- 성공건수
					end
				else
					begin
						-- *** 로그에 실패 메시지 저장 ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',dt_base=' + ISNULL(CONVERT(nvarchar(100), @dt_base),'NULL')
							  + ',fg_retr=' + ISNULL(CONVERT(nvarchar(100), @fg_retr),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',dt_retr=' + ISNULL(CONVERT(nvarchar(100), @dt_retr),'NULL')
							  + ',emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
						set @v_err_msg = '선택된 Record가 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
					end
			END TRY
			BEGIN CATCH
				-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',dt_base=' + ISNULL(CONVERT(nvarchar(100), @dt_base),'NULL')
							  + ',fg_retr=' + ISNULL(CONVERT(nvarchar(100), @fg_retr),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',dt_retr=' + ISNULL(CONVERT(nvarchar(100), @dt_retr),'NULL')
							  + ',emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')

						set @v_err_msg = ERROR_MESSAGE()
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 급여내역(대상자)
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PAY_PAYROLL_FnB]
      @an_try_no		NUMERIC(4)      -- 시도회차
    , @av_company_cd	NVARCHAR(10)    -- 회사코드
	, @av_fr_month		NVARCHAR(10)	-- 시작월
	, @av_to_month		NVARCHAR(10)	-- 종료월
	, @av_cd_paygp		NVARCHAR(10)	-- 급여그룹
	, @av_sap_kind1		NVARCHAR(10)	-- 유형1
	, @av_sap_kind2		NVARCHAR(10)	-- 유형1
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
		  , @cd_paygp		nvarchar(10)
		  , @sap_kind1		nvarchar(10)
		  , @sap_kind2		nvarchar(10)
		  , @dt_prov		date
		  -- 참조변수
		  --, @no_person		nvarchar(10)
		  , @dt_update		datetime
		  , @pay_ymd_id		numeric
		  , @emp_id			numeric -- 사원ID
		  --, @person_id		numeric -- 개인ID
		  , @pay_payroll_id	numeric -- PAYROLL_ID
		  , @org_id			numeric -- 조직ID
		  , @salary_type_cd nvarchar(10) -- 
		  , @cd_cost		nvarchar(10) -- 코스트센터
		  , @es_grp			nvarchar(10) -- ES_GRP
		  , @tp_calc_ins	nvarchar(10)
		  , @psum			numeric
		  , @dsum			numeric
		  , @pay_type_cd	nvarchar(10)
		  , @sys_cd			nvarchar(10)

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '급여내역(대상자)'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',@company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@av_fr_month=' + ISNULL(CONVERT(nvarchar(100), @av_fr_month),'NULL')
				+ ',@av_to_month' + ISNULL(CONVERT(nvarchar(100), @av_to_month),'NULL')
				+ ',@av_cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @av_cd_paygp),'NULL')
				+ ',@av_sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind1),'NULL')
				+ ',@av_sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind2),'NULL')
				+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
	set @v_s_table = 'CNV_PAY_DTL_SAP'   -- As-Is Table
	set @v_t_table = 'PAY_PAYROLL' -- To-Be Table
	-- =============================================
	-- 전환프로그램설명
	-- =============================================

	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	select @s_company_cd = @av_company_cd, @t_company_cd = @av_company_cd
	
	-- Conversion로그정보 Header
	EXEC @n_log_h_id = dbo.P_CNV_PAY_LOG_H 0, 'S', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table

	-- 급여일자생성
	DECLARE YMD_CUR CURSOR READ_ONLY FOR
		SELECT CD_PAYGP, SAP_KIND1, SAP_KIND2, DT_PROV
		     , PAY_TYPE_CD, SYS_CD
		  FROM CNV_PAY_TYPE_SAP
		 WHERE FORMAT(DT_PROV, 'yyyyMM') BETWEEN @av_fr_month AND @av_to_month
		   AND CD_PAYGP LIKE ISNULL(@av_cd_paygp,'') + '%'
		   AND SAP_KIND1 LIKE ISNULL(@av_sap_kind1,'') + '%'
		   AND SAP_KIND2 LIKE ISNULL(@av_sap_kind2,'') + '%'
		   AND (@av_dt_prov IS NULL OR @av_dt_prov = '' OR DT_PROV = @av_dt_prov)
	OPEN YMD_CUR
	WHILE 1=1
		BEGIN
			FETCH NEXT FROM YMD_CUR
			      INTO @cd_paygp, @sap_kind1, @sap_kind2, @dt_prov
						, @pay_type_cd, @sys_cd
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				-- =============================================
				-- 급여일자생성
				-- =============================================
				SET @dt_update = GETDATE()
				EXEC @pay_ymd_id = P_CNV_PAY_PAY_YMD_SAP @an_log_h_id=@n_log_h_id, @av_company_cd=@av_company_cd,
											@av_sap_kind1=@sap_kind1, @av_sap_kind2=@sap_kind2, @ad_dt_prov=@dt_prov,
											@cd_paygp=@cd_paygp, @ad_dt_update=@dt_update
				IF @pay_ymd_id IS NULL
					BEGIN
						PRINT '급여일자생성오류(CNV_PAY_TYPE_SAP)'
				+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
				+ ',@sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @sap_kind1),'NULL')
				+ ',@sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @sap_kind2),'NULL')
				+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
						CONTINUE
					END
				-- =============================================
				-- 대상자생성
				-- =============================================
				DECLARE EMP_CUR CURSOR READ_ONLY FOR
					SELECT EMP_ID, MAX(CD_COST) AS CD_COST, ES_GRP,
							CASE
								WHEN ES_GRP IN ('11') THEN '001' -- 임원
								WHEN ES_GRP IN ('21') THEN '010' -- 시급제
								WHEN ES_GRP IN ('41') THEN '005' -- 월급제
								WHEN ES_GRP IN ('51') THEN '002' -- 연봉제
								WHEN ES_GRP IN ('61') THEN '010' -- 계약제
								WHEN ES_GRP IN ('71') THEN '002' -- 전문제
								ELSE '002' END,
							CASE
								WHEN ES_GRP IN ('11') THEN 'B' -- 임원
								WHEN ES_GRP IN ('21') THEN 'T' -- 시급제
								WHEN ES_GRP IN ('41') THEN 'M' -- 월급제
								WHEN ES_GRP IN ('51') THEN 'Y' -- 연봉제
								WHEN ES_GRP IN ('61') THEN 'C' -- 계약제
								WHEN ES_GRP IN ('71') THEN 'Y' -- 전문제
								ELSE 'Y' END,
							SUM(CASE WHEN TP_CODE = '1' THEN AMT ELSE 0 END) AS PSUM,
							SUM(CASE WHEN TP_CODE = '2' THEN AMT ELSE 0 END) AS DSUM
					  FROM CNV_PAY_DTL_SAP A
					  JOIN CNV_PAY_ITEM B
					    ON B.COMPANY_CD = @av_company_cd
					   AND A.CD_ITEM = B.CD_ITEM
					 WHERE CD_PAYGP = @cd_paygp
					   AND SAP_KIND1 = @sap_kind1
					   AND SAP_KIND2 = @sap_kind2
					   AND DT_PROV = @dt_prov
					 GROUP BY EMP_ID/*, CD_COST*/, ES_GRP
				OPEN EMP_CUR
				WHILE 1=1
					BEGIN
						FETCH NEXT FROM EMP_CUR
							  INTO @emp_id, @cd_cost, @es_grp, @salary_type_cd, @tp_calc_ins
									, @psum, @dsum
						IF @@FETCH_STATUS <> 0 BREAK
						set @n_total_record = @n_total_record + 1 -- 전체건수
						BEGIN TRY
							SELECT @pay_payroll_id = NEXT VALUE FOR S_PAY_SEQUENCE
							INSERT INTO PAY_PAYROLL(
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
									EMP_KIND_CD, -- 근로구분코드[PHM_EMP_KIND_CD]
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
									OPEN_YN, -- 오픈여부
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
							SELECT TOP 1 @pay_payroll_id,
									@pay_ymd_id PAY_YMD_ID, --	급여일자ID
									@emp_id	EMP_ID, --	사원ID
									@salary_type_cd AS SALARY_TYPE_CD, --	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
									@t_company_cd	SUB_COMPANY_CD,--	서브회사코드
									@cd_paygp PAY_GROUP_CD, -- 급여그룹
									dbo.F_ORM_ORG_BIZ(A.ORG_ID, @dt_prov, 'PAY')	PAY_BIZ_CD,--	급여사업장코드
									dbo.F_ORM_ORG_BIZ(A.ORG_ID, @dt_prov, 'PAY')	RES_BIZ_CD,--	지방세사업장코드
									A.ORG_ID	ORG_ID, --	발령부서ID
									A.ORG_ID PAY_ORG_ID, --	급여부서ID
									A.MGR_TYPE_CD	MGR_TYPE_CD,-- 관리구분코드
									A.POS_CD	POS_CD, --	직위코드[PHM_POS_CD]
									A.JOB_POSITION_CD	JOB_POSITION_CD, --	직종코드
									A.DUTY_CD	DUTY_CD, -- 직책코드[PHM_DUTY_CD]
									A.EMP_KIND_CD	EMP_KIND_CD, -- 근로구분코드[PHM_EMP_KIND_CD]
									@cd_cost	ACC_CD, --	코스트센터(ORM_COST_ORG_CD)
									@psum	PSUM, --	지급집계(모든기지급포함)
									@psum	PSUM1, --	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
									@psum	PSUM2, --	지급집계(모든기지급포함안함)
									@dsum	DSUM, --	공제집계 (**AS는 세금까지 포함된 금액**)
									0	TSUM, --	세금집계
									@psum - @dsum	REAL_AMT, --	실지급액
									NULL	BANK_CD, --	은행코드[PAY_BANK_CD]
									NULL	ACCOUNT_NO, --	계좌번호
									NULL	FILLDT, --	기표일
									A.POS_GRD_CD	POS_GRD_CD, --	직급[PHM_POS_GRD_CD]
									A.YEARNUM_CD	PAY_GRADE,-- 호봉코드 [PHM_YEARNUM_CD]
									NULL	DTM_TYPE, --	근태유형
									NULL	FILLNO, --	전표번호
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
									NULL	TAX_FAMILY_CNT, --	부양가족수
									NULL		FAM20_CNT,--	20세이하자녀수
									NULL	FOREIGN_YN, --	외국인여부
									'N'		PEAK_YN, --	임금피크대상여부
									NULL	PEAK_DATE, --	임금피크적용일자
									''	PAY_METH_CD, --	급여지급방식코드[PAY_METH_CD]
									@tp_calc_ins	PAY_EMP_CLS_CD,--	고용유형코드[PAY_EMP_CLS_CD]
									NULL	CONT_TIME,--	소정근로시간
									NULL	UNION_YN,--	노조회비공제대상여부
									NULL	UNION_FULL_YN,--	노조전임여부
									NULL	PAY_UNION_CD,--	노조사업장코드[PAY_UNION_CD]
									NULL	FOREJOB_YN, --	국외근로여부
									NULL	TRBNK_YN, --	신협공제대상여부
									NULL	PROD_YN, --	생산직여부
									NULL	ADV_YN,--	선망가불금공제여부
									'Y'		OPEN_YN, -- 오픈여부
									NULL	SMS_YN,--	SMS발송여부
									NULL	EMAIL_YN,--	E_MAIL발송여부
									NULL	WORK_YN,--	근속수당지급여부
									NULL	WORK_YMD,--	근속기산일자
									NULL	RETR_YMD,--	퇴직금기산일자
									'FnB(SAP)'	NOTE, --	비고
									A.JOB_CD , -- 직무
								0 AS MOD_USER_ID
								, @dt_update
								, 'KST'
								, @dt_update
								--FROM VI_FRM_CAM_HISTORY A
								FROM CAM_HISTORY A
								-- LEFT OUTER JOIN CAM_HISTORY B (NOLOCK)
								--ON B.EMP_ID = @emp_id
								--  AND B.COMPANY_CD = @t_company_cd
								--  AND B.SEQ = 0
								--  AND A.DT_PROV BETWEEN B.STA_YMD AND B.END_YMD
								WHERE COMPANY_CD = @t_company_cd
								AND EMP_ID = @emp_id
								AND @dt_prov BETWEEN STA_YMD AND END_YMD
								ORDER BY SEQ
							IF @@ROWCOUNT > 0 
								BEGIN
								set @n_cnt_success = @n_cnt_success + 1 -- 성공건수:대상자별로 성공카운트
								INSERT INTO PAY_PAYROLL_DETAIL(
											PAY_PAYROLL_DETAIL_ID, --	급여상세내역ID
											PAY_PAYROLL_ID, --	급여내역ID
											BEL_PAY_TYPE_CD, --	급여지급유형코드-귀속월[PAY_TYPE_CD]
											BEL_PAY_YM, --	귀속월
											BEL_PAY_YMD_ID, --	귀속급여일자ID
											SALARY_TYPE_CD, --	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
											PAY_ITEM_CD, --	급여항목코드
											BASE_MON, --	기준금액
											CAL_MON, --	계산금액
											FOREIGN_BASE_MON, --	외화기준금액
											FOREIGN_CAL_MON, --	외화계산금액
											PAY_ITEM_TYPE_CD, --	급여항목유형
											BEL_ORG_ID, --	귀속부서ID
											NOTE, --	비고
											MOD_USER_ID, --	변경자
											MOD_DATE, --	변경일시
											TZ_CD, --	타임존코드
											TZ_DATE  --	타임존일시
										)
									SELECT  NEXT VALUE FOR S_PAY_SEQUENCE AS PAY_PAYROLL_DETAIL_ID, --	급여상세내역ID
											@pay_payroll_id	PAY_PAYROLL_ID, --	급여내역ID
											@pay_type_cd	BEL_PAY_TYPE_CD, --	급여지급유형코드-귀속월[PAY_TYPE_CD]
											FORMAT(@dt_prov, 'yyyyMM')	BEL_PAY_YM, --	귀속월
											@pay_ymd_id	BEL_PAY_YMD_ID, --	귀속급여일자ID
											@salary_type_cd	SALARY_TYPE_CD, --	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
											case when @av_company_cd='F' and @cd_paygp='F21' and A.CD_ITEM='1001' then 'P132' else B.ITEM_CD end	PAY_ITEM_CD, --	급여항목코드
											SUM(A.AMT)	BASE_MON, --	기준금액
											SUM(A.AMT)	CAL_MON, --	계산금액
											0	FOREIGN_BASE_MON, --	외화기준금액
											0	FOREIGN_CAL_MON, --	외화계산금액
											dbo.F_FRM_UNIT_STD_VALUE (@t_company_cd, 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
												NULL, NULL, NULL, NULL, NULL,
												case when @av_company_cd='F' and @cd_paygp='F21' and A.CD_ITEM='1001' then 'P132' else B.ITEM_CD end, NULL, NULL, NULL, NULL,
												getdATE(),
												'H1' -- 'H1' : 코드1,     'H2' : 코드2,     'H3' :  코드3,     'H4' : 코드4,     'H5' : 코드5
													-- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
												)	PAY_ITEM_TYPE_CD, --	급여항목유형
											(select ORG_ID from PAY_PAYROLL WHERE PAY_PAYROLL_ID=@pay_payroll_id)	BEL_ORG_ID, --	귀속부서ID
											'FnB(SAP)'	NOTE, --	비고
											0 AS MOD_USER_ID
										, @dt_update
										, 'KST'
										, @dt_update
										FROM CNV_PAY_DTL_SAP A
										JOIN CNV_PAY_ITEM B
										ON B.COMPANY_CD = @av_company_cd
										AND A.CD_ITEM = B.CD_ITEM
										WHERE CD_PAYGP = @cd_paygp
										AND SAP_KIND1 = @sap_kind1
										AND SAP_KIND2 = @sap_kind2
										AND DT_PROV = @dt_prov
										AND EMP_ID = @emp_id
										GROUP BY case when @av_company_cd='F' and @cd_paygp='F21' and A.CD_ITEM='1001' then 'P132' else B.ITEM_CD end
								END
							ELSE
								BEGIN
							print 'Error' + Error_message()
							-- *** 로그에 실패 메시지 저장 ***
									set @n_err_cod = ERROR_NUMBER()
									set @v_keys = 'EMP_CUR,EMP_ID없음(VI_FRM_CAM_HISTORY)'
											+ ',@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
											+ ',@sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @sap_kind1),'NULL')
											+ ',@sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @sap_kind2),'NULL')
											+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
											+ ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
											+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
											+ ',@emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
									set @v_err_msg = @v_proc_nm + ' ' + ERROR_MESSAGE()
						
									EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
									--set @pay_ymd_id = 0
							-- *** 로그에 실패 메시지 저장 ***
							set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
								END
						END TRY
						BEGIN CATCH
							print 'Error' + Error_message()
							-- *** 로그에 실패 메시지 저장 ***
									set @n_err_cod = ERROR_NUMBER()
									set @v_keys = 'EMP_CUR,@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
											+ ',@sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @sap_kind1),'NULL')
											+ ',@sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @sap_kind2),'NULL')
											+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
											+ ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
											+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
									set @v_err_msg = @v_proc_nm + ' ' + ERROR_MESSAGE()
						
									EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
									--set @pay_ymd_id = 0
							-- *** 로그에 실패 메시지 저장 ***
							set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
						END CATCH
					END
				CLOSE EMP_CUR
				DEALLOCATE EMP_CUR
			END TRY
			BEGIN CATCH
							print 'Error' + Error_message()
							-- *** 로그에 실패 메시지 저장 ***
									set @n_err_cod = ERROR_NUMBER()
									set @v_keys = 'YMD_CUR,@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
											+ ',@sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @sap_kind1),'NULL')
											+ ',@sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @sap_kind2),'NULL')
											+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
											+ ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
											+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
									set @v_err_msg = @v_proc_nm + ' ' + ERROR_MESSAGE()
						
									EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
									set @pay_ymd_id = 0
							-- *** 로그에 실패 메시지 저장 ***
							set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
			END CATCH
		END

	--print '종료 총건수 : ' + dbo.xf_to_char_n(@n_total_record, default)
	--print '성공 : ' + dbo.xf_to_char_n(@n_cnt_success, default)
	--print '실패 : ' + dbo.xf_to_char_n(@n_cnt_failure, default)
	-- Conversion 로그정보 - 전환건수저장
	EXEC [dbo].[P_CNV_PAY_LOG_H] @n_log_h_id, 'E', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table, @n_total_record, @n_cnt_success, @n_cnt_failure

	CLOSE YMD_CUR
	DEALLOCATE YMD_CUR
	PRINT @v_proc_nm + ' 완료!'
	PRINT 'CNV_PAY_WORK_ID = ' + CONVERT(varchar(100), @n_log_h_id)
	RETURN @n_log_h_id
END

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �޿�����(�����)
-- For ���ؿ���
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_PAYROLL_HRD
      @an_try_no		NUMERIC(4)      -- �õ�ȸ��
    , @av_company_cd	NVARCHAR(10)    -- ȸ���ڵ�
	, @av_fr_month		NVARCHAR(6)		-- ���۳��
	, @av_to_month		NVARCHAR(6)		-- ������
	, @av_fg_supp		NVARCHAR(2)		-- �޿�����
	, @av_dt_prov		NVARCHAR(08)	-- �޿�������
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @s_company_cd nvarchar(10)
	      , @t_company_cd nvarchar(10)
		  -- ��ȯ�۾����
		  , @v_proc_nm   nvarchar(50) -- ���α׷�ID
		  , @v_pgm_title nvarchar(100) -- ���α׷�Title
		  , @v_params       nvarchar(4000) -- �Ķ����
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
		  , @cd_company		nvarchar(20) -- ȸ���ڵ�
		  , @ym_pay			nvarchar(10)
		  , @fg_supp		nvarchar(10)
		  , @dt_prov		nvarchar(10)
		  , @no_person		nvarchar(10)
		  -- ��������
		  , @cd_paygp		nvarchar(10)
		  , @dt_update		datetime
		  , @pay_ymd_id		numeric
		  , @emp_id			numeric -- ���ID
		  , @person_id		numeric -- ����ID
		  , @pay_payroll_id	numeric -- PAYROLL_ID
		  , @org_id			numeric -- ����ID
		  , @salary_type_cd nvarchar(10) -- 

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�޿�����(�����)'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',@company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@fr_month=' + ISNULL(CONVERT(nvarchar(100), @av_fr_month),'NULL')
				+ ',@to_month=' + ISNULL(CONVERT(nvarchar(100), @av_to_month),'NULL')
			--	+ ',@av_fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
			--	+ ',@av_dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
	set @v_s_table = 'H_MONTH_PAY_BONUS'   -- As-Is Table
	set @v_t_table = 'PAY_PAYROLL' -- To-Be Table
	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================

	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	
	-- Conversion�α����� Header
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
				 , ISNULL((select org_id from ORM_ORG where COMPANY_CD = A.CD_COMPANY AND ORG_CD = A.CD_DEPT),0) ORG_ID
				, CASE WHEN A.TP_CALC_INS = 'A' THEN '005' -- ȣ����
						WHEN A.TP_CALC_INS = 'B' THEN '001' -- �ӿ�
						WHEN A.TP_CALC_INS = 'C' THEN '010' -- �����
						WHEN A.TP_CALC_INS = 'D' THEN '100' -- �ϱ���
						WHEN A.TP_CALC_INS = 'F' THEN '010' -- �Ǹ�
						WHEN A.TP_CALC_INS = 'M' THEN '005' -- ������
						WHEN A.TP_CALC_INS = 'S' THEN '005' -- ����
						WHEN A.TP_CALC_INS = 'T' THEN '010' -- �ñ���
						WHEN A.TP_CALC_INS = 'U' THEN '002' -- ��������
						WHEN A.TP_CALC_INS = 'W' THEN '002' -- ���꿬����
						WHEN A.TP_CALC_INS = 'Y' THEN '002' -- ������
						ELSE '002' END AS SALARY_TYPE_CD -- �޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
				 , DT_UPDATE
			  FROM dwehr_hrd.dbo.H_MONTH_PAY_BONUS A
			 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
			   AND YM_PAY BETWEEN @av_fr_month AND @av_to_month
			   AND FG_SUPP LIKE ISNULL(@av_fg_supp, '') + '%'
			   AND DT_PROV LIKE ISNULL(@av_dt_prov, '') + '%'
			   AND NO_PERSON != '20141005' -- ����ö����
			ORDER BY CD_COMPANY, YM_PAY, FG_SUPP, DT_PROV, CD_PAYGP
	-- =============================================
	--   As-Is Key Column Select
	-- =============================================
	OPEN CNV_CUR

	WHILE 1 = 1
		BEGIN
			-- =============================================
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			FETCH NEXT FROM CNV_CUR
			      INTO @cd_company
				     , @ym_pay
					 , @fg_supp
					 , @dt_prov
					 , @no_person
					 , @cd_paygp
					 , @org_id
					 , @salary_type_cd
					 , @dt_update
			-- =============================================
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- �� �Ǽ�Ȯ��
				set @s_company_cd = @cd_company -- AS-IS ȸ���ڵ�
				set @t_company_cd = @cd_company -- TO-BE ȸ���ڵ�
				
				-- =======================================================
				-- �޿����ھ��
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
						set @v_err_msg = '�޿����ڸ� ���� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE
					END
				-- =======================================================
				--  EMP_ID ã��
				-- =======================================================
				SELECT @emp_id = EMP_ID, @person_id = PERSON_ID
				  FROM PHM_EMP_NO_HIS (NOLOCK)
				 WHERE COMPANY_CD = @cd_company
				   AND EMP_NO = @no_person
				IF @@ROWCOUNT < 1
					BEGIN
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS���� ����� ã�� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				select @pay_payroll_id = NEXT VALUE FOR S_PAY_SEQUENCE
				BEGIN TRY
					INSERT INTO PAY_PAYROLL(-----------------------------------------------------------------------
								PAY_PAYROLL_ID,--	�޿�����ID
								PAY_YMD_ID,--	�޿�����ID
								EMP_ID,--	���ID
								SALARY_TYPE_CD,--	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
								SUB_COMPANY_CD,--	����ȸ���ڵ�
								PAY_GROUP_CD,--	�޿��׷�
								PAY_BIZ_CD,--	�޿�������ڵ�
								RES_BIZ_CD,--	���漼������ڵ�
								ORG_ID,--	�߷ɺμ�ID
								PAY_ORG_ID,--	�޿��μ�ID
								MGR_TYPE_CD,-- ���������ڵ�
								POS_CD,--	�����ڵ�[PHM_POS_CD]
								JOB_POSITION_CD,--	�����ڵ�
								DUTY_CD, -- ��å�ڵ�[PHM_DUTY_CD]
								ACC_CD,--	�ڽ�Ʈ����(ORM_COST_ORG_CD)
								PSUM,--	��������(������������)
								PSUM1,--	��������(PSUM���� �޿��������� ���� ����, �������꿡�� ���)
								PSUM2,--	��������(�����������Ծ���)
								DSUM,--	��������
								TSUM,--	��������
								REAL_AMT,--	�����޾�
								BANK_CD,--	�����ڵ�[PAY_BANK_CD]
								ACCOUNT_NO,--	���¹�ȣ
								FILLDT,--	��ǥ��
								POS_GRD_CD,--	����[PHM_POS_GRD_CD]
								PAY_GRADE,-- ȣ���ڵ� [PHM_YEARNUM_CD]
								DTM_TYPE,--	��������
								FILLNO,--	��ǥ��ȣ
								NOTICE,--	�޿�������
								TAX_YMD,--	��õ¡���Ű�����
								FOREIGN_PSUM,--	��ȭ��������(������������)
								FOREIGN_PSUM1,--	��ȭ��������(PSUM���� �޿��������� ���� ����)
								FOREIGN_PSUM2,--	��ȭ��������(�����������Ծ���)
								FOREIGN_DSUM,--	��ȭ��������
								FOREIGN_TSUM,--	��ȭ��������
								FOREIGN_REAL_AMT,--	��ȭ�����޾�
								CURRENCY_CD,--	��ȭ�ڵ�[PAY_CURRENCY_CD]
								TAX_SUBSIDY_YN,--	���ݺ�������
								TAX_FAMILY_CNT,--	�ξ簡����
								FAM20_CNT,--	20�������ڳ��
								FOREIGN_YN,--	�ܱ��ο���
								PEAK_YN	,--�ӱ���ũ��󿩺�
								PEAK_DATE,--	�ӱ���ũ��������
								PAY_METH_CD,--	�޿����޹���ڵ�[PAY_METH_CD]
								PAY_EMP_CLS_CD,--	��������ڵ�[PAY_EMP_CLS_CD]
								CONT_TIME,--	�����ٷνð�
								UNION_YN,--	����ȸ�������󿩺�
								UNION_FULL_YN,--	�������ӿ���
								PAY_UNION_CD,--	����������ڵ�[PAY_UNION_CD]
								FOREJOB_YN,--	���ܱٷο���
								TRBNK_YN,--	����������󿩺�
								PROD_YN,--	����������
								ADV_YN,--	�������ұݰ�������
								SMS_YN,--	SMS�߼ۿ���
								EMAIL_YN,--	E_MAIL�߼ۿ���
								WORK_YN,--	�ټӼ������޿���
								WORK_YMD,--	�ټӱ������
								RETR_YMD,--	�����ݱ������
								NOTE, --	���
								MOD_USER_ID, --	������
								MOD_DATE, --	�����Ͻ�
								TZ_CD, --	Ÿ�����ڵ�
								TZ_DATE  --	Ÿ�����Ͻ�
						   )
						SELECT @pay_payroll_id,
								@pay_ymd_id PAY_YMD_ID, --	�޿�����ID
								@emp_id	EMP_ID, --	���ID
								@salary_type_cd AS SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
								@t_company_cd	SUB_COMPANY_CD,--	����ȸ���ڵ�
								A.CD_PAYGP PAY_GROUP_CD, -- �޿��׷�
								A.CD_BIZ_AREA	PAY_BIZ_CD,--	�޿�������ڵ�
								A.CD_REG_BIZ_AREA	RES_BIZ_CD,--	���漼������ڵ�
								@org_id	ORG_ID, --	�߷ɺμ�ID
								@org_id PAY_ORG_ID, --	�޿��μ�ID
								A.TP_DUTY	MGR_TYPE_CD,-- ���������ڵ�
								--ISNULL(B.POS_CD, A.CD_POSITION)	POS_CD, --	�����ڵ�[PHM_POS_CD]
								--ISNULL(B.JOB_POSITION_CD, A.CD_OCPT)	JOB_POSITION_CD, --	�����ڵ�
								--ISNULL(B.DUTY_CD, A.CD_ABIL)	DUTY_CD, -- ��å�ڵ�[PHM_DUTY_CD]
								A.CD_POSITION	POS_CD, --	�����ڵ�[PHM_POS_CD]
								A.CD_OCPT	JOB_POSITION_CD, --	�����ڵ�
								A.CD_ABIL	DUTY_CD, -- ��å�ڵ�[PHM_DUTY_CD]
								A.CD_COST	ACC_CD, --	�ڽ�Ʈ����(ORM_COST_ORG_CD)
								A.AMT_SUPPLY_TOTAL	PSUM, --	��������(������������)
								A.AMT_SUPPLY_TOTAL	PSUM1, --	��������(PSUM���� �޿��������� ���� ����, �������꿡�� ���)
								A.AMT_SUPPLY_TOTAL	PSUM2, --	��������(�����������Ծ���)
								A.AMT_DEDUCT_TOTAL	DSUM, --	�������� (**AS�� ���ݱ��� ���Ե� �ݾ�**)
								0	TSUM, --	��������
								A.AMT_REAL_SUPPLY	REAL_AMT, --	�����޾�
								A.CD_BANK1	BANK_CD, --	�����ڵ�[PAY_BANK_CD]
								A.NO_BANK_ACCNT1	ACCOUNT_NO, --	���¹�ȣ
								A.DT_AUTO	FILLDT, --	��ǥ��
								A.LVL_PAY1	POS_GRD_CD, --	����[PHM_POS_GRD_CD]
								A.LVL_PAY2	PAY_GRADE,-- ȣ���ڵ� [PHM_YEARNUM_CD]
								NULL	DTM_TYPE, --	��������
								A.NO_AUTO	FILLNO, --	��ǥ��ȣ
								NULL	NOTICE, --	�޿�������
								NULL	TAX_YMD, --	��õ¡���Ű�����
								0	FOREIGN_PSUM, --	��ȭ��������(������������)
								0	FOREIGN_PSUM1, --	��ȭ��������(PSUM���� �޿��������� ���� ����)
								0	FOREIGN_PSUM2, --	��ȭ��������(�����������Ծ���)
								0	FOREIGN_DSUM, --	��ȭ��������
								0	FOREIGN_TSUM, --	��ȭ��������
								0	FOREIGN_REAL_AMT, --	��ȭ�����޾�
								'KRW'	CURRENCY_CD, --	��ȭ�ڵ�[PAY_CURRENCY_CD]
								NULL	TAX_SUBSIDY_YN, --	���ݺ�������
								A.CNT_FAMILY	TAX_FAMILY_CNT, --	�ξ簡����
								A.CNT_CHILD		FAM20_CNT,--	20�������ڳ��
								A.YN_FOREIGN	FOREIGN_YN, --	�ܱ��ο���
								'N'		PEAK_YN, --	�ӱ���ũ��󿩺�
								NULL	PEAK_DATE, --	�ӱ���ũ��������
								A.TP_CALC_PAY	PAY_METH_CD, --	�޿����޹���ڵ�[PAY_METH_CD]
								A.TP_CALC_INS	PAY_EMP_CLS_CD,--	��������ڵ�[PAY_EMP_CLS_CD]
								NULL	CONT_TIME,--	�����ٷνð�
								A.YN_LABOR_OBJ	UNION_YN,--	����ȸ�������󿩺�
								NULL	UNION_FULL_YN,--	�������ӿ���
								NULL	PAY_UNION_CD,--	����������ڵ�[PAY_UNION_CD]
								A.YN_FOREJOB	FOREJOB_YN, --	���ܱٷο���
								A.YN_CRE	TRBNK_YN, --	����������󿩺�
								A.YN_PROD_LABOR	PROD_YN, --	����������
								NULL	ADV_YN,--	�������ұݰ�������
								NULL	SMS_YN,--	SMS�߼ۿ���
								NULL	EMAIL_YN,--	E_MAIL�߼ۿ���
								NULL	WORK_YN,--	�ټӼ������޿���
								NULL	WORK_YMD,--	�ټӱ������
								NULL	RETR_YMD,--	�����ݱ������
								A.REM_COMMENT	NOTE, --	���
							dbo.F_CNV_GET_EMP_ID_FROM_ASIS_LOGINID(A.ID_UPDATE) AS MOD_USER_ID
							, ISNULL(DT_UPDATE,'1900-01-01')
							, 'KST'
							, ISNULL(DT_UPDATE,'1900-01-01')
					  FROM dwehr_hrd.dbo.H_MONTH_PAY_BONUS A (NOLOCK)
					 -- LEFT OUTER JOIN CAM_HISTORY B (NOLOCK)
						--ON B.EMP_ID = @emp_id
					 --  AND B.COMPANY_CD = @t_company_cd
					 --  AND B.SEQ = 0
					 --  AND A.DT_PROV BETWEEN B.STA_YMD AND B.END_YMD
					 WHERE CD_COMPANY = @s_company_cd
					   AND YM_PAY = @ym_pay
					   AND FG_SUPP = @fg_supp
					   AND DT_PROV = @dt_prov
					   AND NO_PERSON = @no_person
					
					set @n_cnt_success = @n_cnt_success + 1 -- �����Ǽ�: �޿�����ڷ� ����Ƚ��
					------------
					-- �޿�����
					------------
						INSERT INTO PAY_PAYROLL_DETAIL(
									PAY_PAYROLL_DETAIL_ID, --	�޿��󼼳���ID
									PAY_PAYROLL_ID, --	�޿�����ID
									BEL_PAY_TYPE_CD, --	�޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
									BEL_PAY_YM, --	�ͼӿ�
									BEL_PAY_YMD_ID, --	�ͼӱ޿�����ID
									SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
									PAY_ITEM_CD, --	�޿��׸��ڵ�
									BASE_MON, --	���رݾ�
									CAL_MON, --	���ݾ�
									FOREIGN_BASE_MON, --	��ȭ���رݾ�
									FOREIGN_CAL_MON, --	��ȭ���ݾ�
									PAY_ITEM_TYPE_CD, --	�޿��׸�����
									BEL_ORG_ID, --	�ͼӺμ�ID
									NOTE, --	���
									MOD_USER_ID, --	������
									MOD_DATE, --	�����Ͻ�
									TZ_CD, --	Ÿ�����ڵ�
									TZ_DATE  --	Ÿ�����Ͻ�
							   )
							SELECT  NEXT VALUE FOR S_PAY_SEQUENCE AS PAY_PAYROLL_DETAIL_ID, --	�޿��󼼳���ID
									@pay_payroll_id	PAY_PAYROLL_ID, --	�޿�����ID
									YMD.PAY_TYPE_CD	BEL_PAY_TYPE_CD, --	�޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
									@ym_pay	BEL_PAY_YM, --	�ͼӿ�
									@pay_ymd_id	BEL_PAY_YMD_ID, --	�ͼӱ޿�����ID
									@salary_type_cd	SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
									B.ITEM_CD	PAY_ITEM_CD, --	�޿��׸��ڵ�
									A.AMT_ALLOW_2	BASE_MON, --	���رݾ�
									A.AMT_ALLOW	CAL_MON, --	���ݾ�
									0	FOREIGN_BASE_MON, --	��ȭ���رݾ�
									0	FOREIGN_CAL_MON, --	��ȭ���ݾ�
									dbo.F_FRM_UNIT_STD_VALUE (@t_company_cd, 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
									  NULL, NULL, NULL, NULL, NULL,
									  B.ITEM_CD, NULL, NULL, NULL, NULL,
									  getdATE(),
									  'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
										   -- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
									  )	PAY_ITEM_TYPE_CD, --	�޿��׸�����
									@org_id	BEL_ORG_ID, --	�ͼӺμ�ID
									A.REM_COMMENT	NOTE, --	���
								 dbo.F_CNV_GET_EMP_ID_FROM_ASIS_LOGINID(A.ID_UPDATE) AS MOD_USER_ID
								, ISNULL(A.DT_UPDATE,'1900-01-01')
								, 'KST'
								, ISNULL(A.DT_UPDATE,'1900-01-01')
						  FROM dwehr_hrd.dbo.H_MONTH_SUPPLY A WITH (NOLOCK)
						  JOIN PAY_PAY_YMD YMD WITH(NOLOCK)
						    ON YMD.PAY_YMD_ID = @pay_ymd_id
						  JOIN CNV_PAY_ITEM B WITH (NOLOCK)
						  --  ON A.CD_COMPANY = B.COMPANY_CD
						    ON 'HRD' = B.COMPANY_CD
						   AND A.CD_ALLOW = B.CD_ITEM
						   AND B.TP_CODE = '1'
						 WHERE A.CD_COMPANY = @s_company_cd
						   AND A.YM_PAY = @ym_pay
						   AND A.FG_SUPP = @fg_supp
						   AND A.DT_PROV = @dt_prov
						   AND A.NO_PERSON = @no_person
						   --AND A.CD_ALLOW = @cd_allow
					------------
					-- ��������
					------------
						INSERT INTO PAY_PAYROLL_DETAIL(
									PAY_PAYROLL_DETAIL_ID, --	�޿��󼼳���ID
									PAY_PAYROLL_ID, --	�޿�����ID
									BEL_PAY_TYPE_CD, --	�޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
									BEL_PAY_YM, --	�ͼӿ�
									BEL_PAY_YMD_ID, --	�ͼӱ޿�����ID
									SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
									PAY_ITEM_CD, --	�޿��׸��ڵ�
									BASE_MON, --	���رݾ�
									CAL_MON, --	���ݾ�
									FOREIGN_BASE_MON, --	��ȭ���رݾ�
									FOREIGN_CAL_MON, --	��ȭ���ݾ�
									PAY_ITEM_TYPE_CD, --	�޿��׸�����
									BEL_ORG_ID, --	�ͼӺμ�ID
									NOTE, --	���
									MOD_USER_ID, --	������
									MOD_DATE, --	�����Ͻ�
									TZ_CD, --	Ÿ�����ڵ�
									TZ_DATE  --	Ÿ�����Ͻ�
							   )
							SELECT  NEXT VALUE FOR S_PAY_SEQUENCE AS PAY_PAYROLL_DETAIL_ID, --	�޿��󼼳���ID
									@pay_payroll_id	PAY_PAYROLL_ID, --	�޿�����ID
									YMD.PAY_TYPE_CD	BEL_PAY_TYPE_CD, --	�޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
									@ym_pay	BEL_PAY_YM, --	�ͼӿ�
									@pay_ymd_id	BEL_PAY_YMD_ID, --	�ͼӱ޿�����ID
									@salary_type_cd	SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
									B.ITEM_CD	PAY_ITEM_CD, --	�޿��׸��ڵ�
									A.AMT_DEDUCT	BASE_MON, --	���رݾ�
									A.AMT_DEDUCT	CAL_MON, --	���ݾ�
									0	FOREIGN_BASE_MON, --	��ȭ���رݾ�
									0	FOREIGN_CAL_MON, --	��ȭ���ݾ�
									dbo.F_FRM_UNIT_STD_VALUE (@t_company_cd, 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
										  NULL, NULL, NULL, NULL, NULL,
										  ITEM_CD, NULL, NULL, NULL, NULL,
										  getdATE(),
										  'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
											   -- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
										  )	PAY_ITEM_TYPE_CD, --	�޿��׸�����
									@org_id	BEL_ORG_ID, --	�ͼӺμ�ID
									A.REM_COMMENT	NOTE, --	���
								 dbo.F_CNV_GET_EMP_ID_FROM_ASIS_LOGINID(A.ID_UPDATE) AS MOD_USER_ID
								, ISNULL(A.DT_UPDATE,'1900-01-01')
								, 'KST'
								, ISNULL(A.DT_UPDATE,'1900-01-01')
						  FROM dwehr_hrd.dbo.H_MONTH_DEDUCT A WITH (NOLOCK)
						  JOIN PAY_PAY_YMD YMD WITH(NOLOCK)
						    ON YMD.PAY_YMD_ID = @pay_ymd_id
						  JOIN CNV_PAY_ITEM B WITH (NOLOCK)
						  --  ON A.CD_COMPANY = B.COMPANY_CD
						    ON 'HRD' = B.COMPANY_CD
						   AND A.CD_DEDUCT = B.CD_ITEM
						   AND B.TP_CODE = '2'
						 WHERE A.CD_COMPANY = @s_company_cd
						   AND A.YM_PAY = @ym_pay
						   AND A.FG_SUPP = @fg_supp
						   AND A.DT_PROV = @dt_prov
						   AND A.NO_PERSON = @no_person
						   --AND A.CD_DEDUCT = @cd_deduct
					------------
					-- C001	�Ĵ�����	AMT_TAX_EXEMPTION2	������ݾ�(�Ĵ�)
					-- C002	��������	AMT_TAX_EXEMPTION1	������ݾ�(����)
					-- C003	���������	AMT_TAX_EXEMPTION3	������ݾ�(��Ÿ)
					-- C004	���ܱٷκ����	AMT_TAX_EXEMPTION4	������ݾ�(���ܱٷ�)
					-- C100	�������ݾ�	AMT_TOT_TAX	�����Ѱ����ݾ�
					-- C101	����ӱ�	AMT_CM_PAY	����ӱ�
					-- C102	���ñ�	AMT_CT_PAY	���ñ�
					-- C110	�ñ�		AMT_T_PAY	�ñ�
					-- C111	�ϱ�		AMT_D_PAY	�ϱ�
					-- C112	����ϱ�	AMT_CD_PAY	����ϱ�
					------------
						INSERT INTO PAY_PAYROLL_DETAIL(
									PAY_PAYROLL_DETAIL_ID, --	�޿��󼼳���ID
									PAY_PAYROLL_ID, --	�޿�����ID
									BEL_PAY_TYPE_CD, --	�޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
									BEL_PAY_YM, --	�ͼӿ�
									BEL_PAY_YMD_ID, --	�ͼӱ޿�����ID
									SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
									PAY_ITEM_CD, --	�޿��׸��ڵ�
									BASE_MON, --	���رݾ�
									CAL_MON, --	���ݾ�
									FOREIGN_BASE_MON, --	��ȭ���رݾ�
									FOREIGN_CAL_MON, --	��ȭ���ݾ�
									PAY_ITEM_TYPE_CD, --	�޿��׸�����
									BEL_ORG_ID, --	�ͼӺμ�ID
									NOTE, --	���
									MOD_USER_ID, --	������
									MOD_DATE, --	�����Ͻ�
									TZ_CD, --	Ÿ�����ڵ�
									TZ_DATE  --	Ÿ�����Ͻ�
							   )
							SELECT  NEXT VALUE FOR S_PAY_SEQUENCE AS PAY_PAYROLL_DETAIL_ID, --	�޿��󼼳���ID
									@pay_payroll_id	PAY_PAYROLL_ID, --	�޿�����ID
									YMD.PAY_TYPE_CD	BEL_PAY_TYPE_CD, --	�޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
									@ym_pay	BEL_PAY_YM, --	�ͼӿ�
									@pay_ymd_id	BEL_PAY_YMD_ID, --	�ͼӱ޿�����ID
									@salary_type_cd	SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
									CASE ITEM_VALS_COL
									 WHEN 'AMT_TAX_EXEMPTION2' THEN 'C001'
									 WHEN 'AMT_TAX_EXEMPTION1' THEN 'C002'
									 WHEN 'AMT_TAX_EXEMPTION3' THEN 'C003'
									 WHEN 'AMT_TAX_EXEMPTION4' THEN 'C004'
									 WHEN 'AMT_TOT_TAX' THEN 'C100'
									 WHEN 'AMT_CM_PAY' THEN 'C101'
									 WHEN 'AMT_CT_PAY' THEN 'C102'
									 WHEN 'AMT_T_PAY' THEN 'C110' -- C110	�ñ�		AMT_T_PAY	�ñ�
									 WHEN 'AMT_D_PAY' THEN 'C111' -- C111	�ϱ�		AMT_D_PAY	�ϱ�
									 WHEN 'AMT_CD_PAY' THEN 'C112' -- C112	����ϱ�	AMT_CD_PAY	����ϱ�
									 ELSE '' END PAY_ITEM_CD, --	�޿��׸��ڵ�
									ITEM_VALS	BASE_MON, --	���رݾ�
									ITEM_VALS	CAL_MON, --	���ݾ�
									0	FOREIGN_BASE_MON, --	��ȭ���رݾ�
									0	FOREIGN_CAL_MON, --	��ȭ���ݾ�
									dbo.F_FRM_UNIT_STD_VALUE (@t_company_cd, 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
										  NULL, NULL, NULL, NULL, NULL,
										  CASE ITEM_VALS_COL
											 WHEN 'AMT_TAX_EXEMPTION2' THEN 'C001'
											 WHEN 'AMT_TAX_EXEMPTION1' THEN 'C002'
											 WHEN 'AMT_TAX_EXEMPTION3' THEN 'C003'
											 WHEN 'AMT_TAX_EXEMPTION4' THEN 'C004'
											 WHEN 'AMT_TOT_TAX' THEN 'C100'
											 WHEN 'AMT_CM_PAY' THEN 'C101'
											 WHEN 'AMT_CT_PAY' THEN 'C102'
											 WHEN 'AMT_T_PAY' THEN 'C110' -- C110	�ñ�		AMT_T_PAY	�ñ�
											 WHEN 'AMT_D_PAY' THEN 'C111' -- C111	�ϱ�		AMT_D_PAY	�ϱ�
											 WHEN 'AMT_CD_PAY' THEN 'C112' -- C112	����ϱ�	AMT_CD_PAY	����ϱ�
											 ELSE '' END, NULL, NULL, NULL, NULL,
										  getdATE(),
										  'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
											   -- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
										  )	PAY_ITEM_TYPE_CD, --	�޿��׸�����
									@org_id	BEL_ORG_ID, --	�ͼӺμ�ID
									''	NOTE, --	���
								 dbo.F_CNV_GET_EMP_ID_FROM_ASIS_LOGINID(ID_UPDATE) AS MOD_USER_ID
								, ISNULL(DT_UPDATE,'1900-01-01')
								, 'KST'
								, ISNULL(DT_UPDATE,'1900-01-01')
						     FROM (SELECT CD_COMPANY, YM_PAY, FG_SUPP, DT_PROV, NO_PERSON, DT_UPDATE, ID_UPDATE
										, AMT_TAX_EXEMPTION2, AMT_TAX_EXEMPTION1, AMT_TAX_EXEMPTION3, AMT_TAX_EXEMPTION4 , AMT_TOT_TAX
										, CONVERT(NUMERIC(18,0), AMT_CM_PAY) AMT_CM_PAY
										, CONVERT(NUMERIC(18,0), AMT_CT_PAY) AMT_CT_PAY
										, CONVERT(NUMERIC(18,0), AMT_T_PAY) AMT_T_PAY
										, CONVERT(NUMERIC(18,0), AMT_D_PAY) AMT_D_PAY
										, CONVERT(NUMERIC(18,0), AMT_CD_PAY) AMT_CD_PAY
									FROM dwehr_hrd.dbo.H_MONTH_PAY_BONUS WITH(NOLOCK) ) A
									UNPIVOT ( ITEM_VALS FOR ITEM_VALS_COL IN (AMT_TAX_EXEMPTION2, AMT_TAX_EXEMPTION1, AMT_TAX_EXEMPTION3, AMT_TAX_EXEMPTION4, AMT_TOT_TAX,
																				AMT_CM_PAY, AMT_CT_PAY, AMT_T_PAY, AMT_D_PAY, AMT_CD_PAY )) UNPVT1
									JOIN PAY_PAY_YMD YMD WITH(NOLOCK)
									  ON YMD.PAY_YMD_ID = @pay_ymd_id
							 WHERE CD_COMPANY = @s_company_cd
							   AND YM_PAY = @ym_pay
							   AND FG_SUPP = @fg_supp
							   AND DT_PROV = @dt_prov
							   AND NO_PERSON = @no_person
							   AND ITEM_VALS <> 0
				END TRY
				BEGIN CATCH
					set @n_err_cod = ERROR_NUMBER()
					IF @n_err_cod = 2627 -- �ߺ�Ű
						BEGIN
						PRINT '�ߺ�Ű:'
							begin
								-- *** �α׿� ���� �޽��� ���� ***
								set @v_keys = '@cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
									  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
									  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
									  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
									  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
								set @v_err_msg = ERROR_MESSAGE()
								EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
								-- *** �α׿� ���� �޽��� ���� ***
								set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
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
					--begin
						-- *** �����޽��� �α׿� ���� ***
						--set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
						--      + ',' + ISNULL(CONVERT(nvarchar(100), @cd_accnt),'NULL')
						--set @v_err_msg = '���õ� Record�� �����ϴ�.!'
						--EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �����޽��� �α׿� ���� ***
						--set @n_cnt_success = @n_cnt_success + 1 -- �����Ǽ�
					--end
				--else
				--	begin
				--		-- *** �α׿� ���� �޽��� ���� ***
				--		set @v_keys = '@cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
				--			  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
				--			  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
				--			  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
				--			  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
				--		set @v_err_msg = '���õ� Record�� �����ϴ�.!!!' -- ERROR_MESSAGE()
				--		EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
				--		-- *** �α׿� ���� �޽��� ���� ***
				--		set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
				--	end
			END TRY
			BEGIN CATCH
				-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = '@cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = CONVERT(NVARCHAR(100), ERROR_LINE()) + ':' + ERROR_MESSAGE()
						
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
				-- *** �α׿� ���� �޽��� ���� ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- ���аǼ�
			END CATCH
		END
	--print '���� �ѰǼ� : ' + dbo.xf_to_char_n(@n_total_record, default)
	--print '���� : ' + dbo.xf_to_char_n(@n_cnt_success, default)
	--print '���� : ' + dbo.xf_to_char_n(@n_cnt_failure, default)
	-- Conversion �α����� - ��ȯ�Ǽ�����
	EXEC [dbo].[P_CNV_PAY_LOG_H] @n_log_h_id, 'E', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table, @n_total_record, @n_cnt_success, @n_cnt_failure

	CLOSE CNV_CUR
	DEALLOCATE CNV_CUR
	PRINT @v_proc_nm + ' �Ϸ�!'
	PRINT 'CNV_PAY_WORK_ID = ' + CONVERT(varchar(100), @n_log_h_id)
	RETURN @n_log_h_id
END
GO
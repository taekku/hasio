SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �޿�����(�����)
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PAY_PAYROLL_FnB]
      @an_try_no		NUMERIC(4)      -- �õ�ȸ��
    , @av_company_cd	NVARCHAR(10)    -- ȸ���ڵ�
	, @av_fr_month		NVARCHAR(10)	-- ���ۿ�
	, @av_to_month		NVARCHAR(10)	-- �����
	, @av_cd_paygp		NVARCHAR(10)	-- �޿��׷�
	, @av_sap_kind1		NVARCHAR(10)	-- ����1
	, @av_sap_kind2		NVARCHAR(10)	-- ����1
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
		  , @cd_paygp		nvarchar(10)
		  , @sap_kind1		nvarchar(10)
		  , @sap_kind2		nvarchar(10)
		  , @dt_prov		date
		  -- ��������
		  --, @no_person		nvarchar(10)
		  , @dt_update		datetime
		  , @pay_ymd_id		numeric
		  , @emp_id			numeric -- ���ID
		  --, @person_id		numeric -- ����ID
		  , @pay_payroll_id	numeric -- PAYROLL_ID
		  , @org_id			numeric -- ����ID
		  , @salary_type_cd nvarchar(10) -- 
		  , @cd_cost		nvarchar(10) -- �ڽ�Ʈ����
		  , @es_grp			nvarchar(10) -- ES_GRP
		  , @tp_calc_ins	nvarchar(10)
		  , @psum			numeric
		  , @dsum			numeric
		  , @pay_type_cd	nvarchar(10)
		  , @sys_cd			nvarchar(10)

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�޿�����(�����)'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
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
	-- ��ȯ���α׷�����
	-- =============================================

	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	select @s_company_cd = @av_company_cd, @t_company_cd = @av_company_cd
	
	-- Conversion�α����� Header
	EXEC @n_log_h_id = dbo.P_CNV_PAY_LOG_H 0, 'S', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table

	-- �޿����ڻ���
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
				-- �޿����ڻ���
				-- =============================================
				SET @dt_update = GETDATE()
				EXEC @pay_ymd_id = P_CNV_PAY_PAY_YMD_SAP @an_log_h_id=@n_log_h_id, @av_company_cd=@av_company_cd,
											@av_sap_kind1=@sap_kind1, @av_sap_kind2=@sap_kind2, @ad_dt_prov=@dt_prov,
											@cd_paygp=@cd_paygp, @ad_dt_update=@dt_update
				IF @pay_ymd_id IS NULL
					BEGIN
						PRINT '�޿����ڻ�������(CNV_PAY_TYPE_SAP)'
				+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
				+ ',@sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @sap_kind1),'NULL')
				+ ',@sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @sap_kind2),'NULL')
				+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
						CONTINUE
					END
				-- =============================================
				-- ����ڻ���
				-- =============================================
				DECLARE EMP_CUR CURSOR READ_ONLY FOR
					SELECT EMP_ID, MAX(CD_COST) AS CD_COST, ES_GRP,
							CASE
								WHEN ES_GRP IN ('11') THEN '001' -- �ӿ�
								WHEN ES_GRP IN ('21') THEN '010' -- �ñ���
								WHEN ES_GRP IN ('41') THEN '005' -- ������
								WHEN ES_GRP IN ('51') THEN '002' -- ������
								WHEN ES_GRP IN ('61') THEN '010' -- �����
								WHEN ES_GRP IN ('71') THEN '002' -- ������
								ELSE '002' END,
							CASE
								WHEN ES_GRP IN ('11') THEN 'B' -- �ӿ�
								WHEN ES_GRP IN ('21') THEN 'T' -- �ñ���
								WHEN ES_GRP IN ('41') THEN 'M' -- ������
								WHEN ES_GRP IN ('51') THEN 'Y' -- ������
								WHEN ES_GRP IN ('61') THEN 'C' -- �����
								WHEN ES_GRP IN ('71') THEN 'Y' -- ������
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
						set @n_total_record = @n_total_record + 1 -- ��ü�Ǽ�
						BEGIN TRY
							SELECT @pay_payroll_id = NEXT VALUE FOR S_PAY_SEQUENCE
							INSERT INTO PAY_PAYROLL(
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
									EMP_KIND_CD, -- �ٷα����ڵ�[PHM_EMP_KIND_CD]
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
									OPEN_YN, -- ���¿���
									SMS_YN,--	SMS�߼ۿ���
									EMAIL_YN,--	E_MAIL�߼ۿ���
									WORK_YN,--	�ټӼ������޿���
									WORK_YMD,--	�ټӱ������
									RETR_YMD,--	�����ݱ������
									NOTE, --	���
									JOB_CD, -- ����
									MOD_USER_ID, --	������
									MOD_DATE, --	�����Ͻ�
									TZ_CD, --	Ÿ�����ڵ�
									TZ_DATE  --	Ÿ�����Ͻ�
								)
							SELECT TOP 1 @pay_payroll_id,
									@pay_ymd_id PAY_YMD_ID, --	�޿�����ID
									@emp_id	EMP_ID, --	���ID
									@salary_type_cd AS SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
									@t_company_cd	SUB_COMPANY_CD,--	����ȸ���ڵ�
									@cd_paygp PAY_GROUP_CD, -- �޿��׷�
									dbo.F_ORM_ORG_BIZ(A.ORG_ID, @dt_prov, 'PAY')	PAY_BIZ_CD,--	�޿�������ڵ�
									dbo.F_ORM_ORG_BIZ(A.ORG_ID, @dt_prov, 'PAY')	RES_BIZ_CD,--	���漼������ڵ�
									A.ORG_ID	ORG_ID, --	�߷ɺμ�ID
									A.ORG_ID PAY_ORG_ID, --	�޿��μ�ID
									A.MGR_TYPE_CD	MGR_TYPE_CD,-- ���������ڵ�
									A.POS_CD	POS_CD, --	�����ڵ�[PHM_POS_CD]
									A.JOB_POSITION_CD	JOB_POSITION_CD, --	�����ڵ�
									A.DUTY_CD	DUTY_CD, -- ��å�ڵ�[PHM_DUTY_CD]
									A.EMP_KIND_CD	EMP_KIND_CD, -- �ٷα����ڵ�[PHM_EMP_KIND_CD]
									@cd_cost	ACC_CD, --	�ڽ�Ʈ����(ORM_COST_ORG_CD)
									@psum	PSUM, --	��������(������������)
									@psum	PSUM1, --	��������(PSUM���� �޿��������� ���� ����, �������꿡�� ���)
									@psum	PSUM2, --	��������(�����������Ծ���)
									@dsum	DSUM, --	�������� (**AS�� ���ݱ��� ���Ե� �ݾ�**)
									0	TSUM, --	��������
									@psum - @dsum	REAL_AMT, --	�����޾�
									NULL	BANK_CD, --	�����ڵ�[PAY_BANK_CD]
									NULL	ACCOUNT_NO, --	���¹�ȣ
									NULL	FILLDT, --	��ǥ��
									A.POS_GRD_CD	POS_GRD_CD, --	����[PHM_POS_GRD_CD]
									A.YEARNUM_CD	PAY_GRADE,-- ȣ���ڵ� [PHM_YEARNUM_CD]
									NULL	DTM_TYPE, --	��������
									NULL	FILLNO, --	��ǥ��ȣ
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
									NULL	TAX_FAMILY_CNT, --	�ξ簡����
									NULL		FAM20_CNT,--	20�������ڳ��
									NULL	FOREIGN_YN, --	�ܱ��ο���
									'N'		PEAK_YN, --	�ӱ���ũ��󿩺�
									NULL	PEAK_DATE, --	�ӱ���ũ��������
									''	PAY_METH_CD, --	�޿����޹���ڵ�[PAY_METH_CD]
									@tp_calc_ins	PAY_EMP_CLS_CD,--	��������ڵ�[PAY_EMP_CLS_CD]
									NULL	CONT_TIME,--	�����ٷνð�
									NULL	UNION_YN,--	����ȸ�������󿩺�
									NULL	UNION_FULL_YN,--	�������ӿ���
									NULL	PAY_UNION_CD,--	����������ڵ�[PAY_UNION_CD]
									NULL	FOREJOB_YN, --	���ܱٷο���
									NULL	TRBNK_YN, --	����������󿩺�
									NULL	PROD_YN, --	����������
									NULL	ADV_YN,--	�������ұݰ�������
									'Y'		OPEN_YN, -- ���¿���
									NULL	SMS_YN,--	SMS�߼ۿ���
									NULL	EMAIL_YN,--	E_MAIL�߼ۿ���
									NULL	WORK_YN,--	�ټӼ������޿���
									NULL	WORK_YMD,--	�ټӱ������
									NULL	RETR_YMD,--	�����ݱ������
									'FnB(SAP)'	NOTE, --	���
									A.JOB_CD , -- ����
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
								set @n_cnt_success = @n_cnt_success + 1 -- �����Ǽ�:����ں��� ����ī��Ʈ
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
											@pay_type_cd	BEL_PAY_TYPE_CD, --	�޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
											FORMAT(@dt_prov, 'yyyyMM')	BEL_PAY_YM, --	�ͼӿ�
											@pay_ymd_id	BEL_PAY_YMD_ID, --	�ͼӱ޿�����ID
											@salary_type_cd	SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
											case when @av_company_cd='F' and @cd_paygp='F21' and A.CD_ITEM='1001' then 'P132' else B.ITEM_CD end	PAY_ITEM_CD, --	�޿��׸��ڵ�
											SUM(A.AMT)	BASE_MON, --	���رݾ�
											SUM(A.AMT)	CAL_MON, --	���ݾ�
											0	FOREIGN_BASE_MON, --	��ȭ���رݾ�
											0	FOREIGN_CAL_MON, --	��ȭ���ݾ�
											dbo.F_FRM_UNIT_STD_VALUE (@t_company_cd, 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
												NULL, NULL, NULL, NULL, NULL,
												case when @av_company_cd='F' and @cd_paygp='F21' and A.CD_ITEM='1001' then 'P132' else B.ITEM_CD end, NULL, NULL, NULL, NULL,
												getdATE(),
												'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
													-- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
												)	PAY_ITEM_TYPE_CD, --	�޿��׸�����
											(select ORG_ID from PAY_PAYROLL WHERE PAY_PAYROLL_ID=@pay_payroll_id)	BEL_ORG_ID, --	�ͼӺμ�ID
											'FnB(SAP)'	NOTE, --	���
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
							-- *** �α׿� ���� �޽��� ���� ***
									set @n_err_cod = ERROR_NUMBER()
									set @v_keys = 'EMP_CUR,EMP_ID����(VI_FRM_CAM_HISTORY)'
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
							-- *** �α׿� ���� �޽��� ���� ***
							set @n_cnt_failure =  @n_cnt_failure + 1 -- ���аǼ�
								END
						END TRY
						BEGIN CATCH
							print 'Error' + Error_message()
							-- *** �α׿� ���� �޽��� ���� ***
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
							-- *** �α׿� ���� �޽��� ���� ***
							set @n_cnt_failure =  @n_cnt_failure + 1 -- ���аǼ�
						END CATCH
					END
				CLOSE EMP_CUR
				DEALLOCATE EMP_CUR
			END TRY
			BEGIN CATCH
							print 'Error' + Error_message()
							-- *** �α׿� ���� �޽��� ���� ***
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
							-- *** �α׿� ���� �޽��� ���� ***
							set @n_cnt_failure =  @n_cnt_failure + 1 -- ���аǼ�
			END CATCH
		END

	--print '���� �ѰǼ� : ' + dbo.xf_to_char_n(@n_total_record, default)
	--print '���� : ' + dbo.xf_to_char_n(@n_cnt_success, default)
	--print '���� : ' + dbo.xf_to_char_n(@n_cnt_failure, default)
	-- Conversion �α����� - ��ȯ�Ǽ�����
	EXEC [dbo].[P_CNV_PAY_LOG_H] @n_log_h_id, 'E', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table, @n_total_record, @n_cnt_success, @n_cnt_failure

	CLOSE YMD_CUR
	DEALLOCATE YMD_CUR
	PRINT @v_proc_nm + ' �Ϸ�!'
	PRINT 'CNV_PAY_WORK_ID = ' + CONVERT(varchar(100), @n_log_h_id)
	RETURN @n_log_h_id
END

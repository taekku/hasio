SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �����ݰ������(����)
-- 
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_REP_CALC_LIST
      @an_try_no		NUMERIC(4)       -- �õ�ȸ��
    , @av_company_cd	NVARCHAR(10)     -- ȸ���ڵ�
	, @av_fr_month		NVARCHAR(6)		-- ���۳��
	, @av_to_month		NVARCHAR(6)		-- ������
AS
BEGIN
	SET NOCOUNT ON;
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
		  , @dt_base		nvarchar(20) -- ��������
		  , @fg_retr		nvarchar(20) -- ��������(1.����, 2.�����߰�, 3.�߰�����, B.����(DB��), C.����(DC��))
		  , @no_person		nvarchar(20) -- ���
		  , @dt_retr		nvarchar(20) -- �������
		  -- ��������
		  , @emp_id			numeric -- ���ID
		  , @person_id		numeric -- ����ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�����ݰ������(����)'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',fr_month=' + ISNULL(CONVERT(nvarchar(100), @av_fr_month),'NULL')
				+ ',to_month=' + ISNULL(CONVERT(nvarchar(100), @av_to_month),'NULL')
	set @v_s_table = 'H_RETIRE_DETAIL'   -- As-Is Table
	set @v_t_table = 'REP_CALC_LIST' -- To-Be Table
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
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			FETCH NEXT FROM CNV_CUR
			      INTO @cd_company
				     , @dt_base, @fg_retr, @no_person, @dt_retr
			-- =============================================
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- �� �Ǽ�Ȯ��
				set @s_company_cd = @cd_company -- AS-IS ȸ���ڵ�
				set @t_company_cd = @cd_company -- TO-BE ȸ���ڵ�
				
				-- =======================================================
				--  EMP_ID ã��
				-- =======================================================
				SELECT @emp_id = EMP_ID, @person_id = PERSON_ID
				  FROM PHM_EMP_NO_HIS
				 WHERE COMPANY_CD = @cd_company
				   AND EMP_NO = @no_person
				IF @@ROWCOUNT < 1
					BEGIN
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',dt_base=' + ISNULL(CONVERT(nvarchar(100), @dt_base),'NULL')
							  + ',fg_retr=' + ISNULL(CONVERT(nvarchar(100), @fg_retr),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',dt_retr=' + ISNULL(CONVERT(nvarchar(100), @dt_retr),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS���� ����� ã�� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				INSERT INTO REP_CALC_LIST (
				REP_CALC_LIST_ID,	-- �����ݴ��ID
				EMP_ID,				-- ���ID 
				CALC_TYPE_CD,		-- ���걸��[REP_CALC_TYPE_CD]
				RETIRE_YMD,			-- ������
				INS_TYPE_CD,		-- �������ݱ���
				INS_TYPE_YN,		-- �������ݰ��Ա���
				ADD_MM_2012,		-- 2012����� �������(���) 
				ADD_MM_2013,		-- 2013�����  �������(���) 
				ADD_WORK_YY,		-- �߰��ټӳ��(������) 
				AGENT_CD,			-- ¡���ǹ��ڱ��� 
				APPL_CAUSE_CD,		-- ��û���� 
				--APPL_GUBUN,			-- �߰�����(���Ĺ�)���� 
				APPL_ID,			-- ��û��ID 
				APPL_YMD,			-- ��û���� 
				ARMY_HIRE_YMD,		-- ����°���(����)�Ի��� 
				ATTACH_AMT,			-- �з��� 
				AVG_BONUS,			-- ��ջ� 
				AVG_DAY,			-- ��տ����� 
				AVG_PAY,			-- ��ձ޿� 
				AVG_PAY_AMT,		-- ����ӱ� 
				B1_CORP_NM,			-- ��(��)����ó�� 
				B1_END_YMD,			-- ��(��)������ 
				B1_EXCEPT_MM,		-- ��(��)���ܿ��� 
				B1_RETIRE_AMT,		-- ��(��)�����޿�
				B1_RETIRE_REP_AMT,	-- ��(��)��/��������� 
				B1_STA_YMD,			-- ��(��)����� 
				B1_TAX_NO,			-- ��(��)����ڹ�ȣ 
				B1_WORK_MM,			-- ��(��)�ټӿ��� 
				B1_RETIRE_TOT,		-- ��(��)������
				B2_END_YMD,			-- �����̿���(��)������ 
				B2_EXCEPT_MM,		-- �����̿���(��)���ܿ��� 
				B2_STA_YMD,			-- �����̿���(��)����� 
				B2_WORK_MM,			-- �����̿���(��)�ټӿ��� 
				BC1_DUP_MM,			-- �ߺ�����(����) 
				BC1_WORK_YY,		-- �ټӳ��(����)(��+���� �ټӳ��) 
				BC2_DUP_MM,			-- �����̿��ߺ����� 
				BC2_WORK_YY,		-- �����ܱ̿ټӳ�� 
				BONUS_MON,			-- ���Ѿ� 
				BT01,				-- ��(��)�ҵ漼 
				BT02,				-- ��(��)�ֹμ� 
				BT03,				-- ��(��)��Ư�� 
				BT_SUM,				-- ��(��)���װ� 
				B_RETIRE_TAX_YN,	-- ��(��)�����ҵ漼�װ������� 
				C1_ADD_MM,			-- ���� ������� 
				C1_ADD_MM_2012,		-- ���� 2012����� �������(�Է�) 
				C1_ADD_MM_2013,		-- ���� 2013�����  �������(�Է�) 
				C1_END_YMD,			-- ��(��)������ 
				C1_END_YMD_2012,	-- 2012����� ������ 
				C1_END_YMD_2013,	-- 2013����� ������ 
				C1_EXCEPT_MM,		-- ��(��)���ܿ��� 
				C1_EXCEPT_MM_2012,	-- ���� 2012����� ���ܿ���(�Է�) 
				C1_EXCEPT_MM_2013,	-- ���� 2013����� ���ܿ���(�Է�) 
				C1_STA_YMD,			-- ������(��)����� 
				C1_STA_YMD_2012,	-- 2012����� ������ 
				C1_STA_YMD_2013,	-- 2013����� ������ 
				C1_TAX_RATE_2012,	-- 2012����� ����(����) 
				C1_TAX_RATE_2013,	-- 2013����� ����(����) 
				C1_WORK_MM,			-- ��(��)�ټӿ��� 
				C1_WORK_MM_2012,	-- 2012����� �ټӿ� 
				C1_WORK_MM_2013,	-- 2012����� �ټӿ� 
				C1_WORK_YY,			-- ���� �ټӳ�� 
				C1_WORK_YY_2012,	-- 2012����� �ټӳ��(����) 
				C1_WORK_YY_2013,	-- 2013����� �ټӳ��(����) 
				C2_END_YMD,			-- �����̿���(��)������ 
				C2_EXCEPT_MM,		-- �����̿���(��)���ܿ��� 
				C2_STA_YMD,			-- �����̿���(��)����� 
				C2_TAX_RATE_2012,	-- 2012����� ����(�����̿�) 
				C2_TAX_RATE_2013,	-- 2013����� ����(�����̿�) 
				C2_WORK_MM,			-- �����̿���(��)�ټӿ��� 
				C2_WORK_YY_2012,	-- 2012����� �ټӳ��(�����̿�) 
				C2_WORK_YY_2013,	-- 2013����� �ټӳ��(�����̿�) 
				CALC_RETIRE_CD,		-- ����(����)����(�ؿ��İ�,����İ�,���Դ�,ȸ���̵�) 
				CAM_TYPE_CD,		-- �߷����� 
				CHAIN_AMT,			-- �������޾�(������) 
				CT01,				-- �����ҵ漼 
				CT02,				-- �����ֹμ� 
				CT03,				-- ������Ư�� 
				CT_SUM,				-- �������װ� 
				C_01,				-- ��(��)���������޿� =>  ��(��)���������� + ��(��)��������� 
				C_01_1,				-- ��(��)���������� 
				C_01_2,				-- ��(��)��������� 
				C_02,				-- ��(��)����������� (�߰�������)  => �� + �߰������� 
				C_02_1,				-- ��(��)�������� 
				C_02_1_BASE,		-- ��(��)�������ݱ��رݾ� 
				C_02_1_RATE,		-- ��(��)�������������� 
				C_02_2,				-- ��(��)�߰������� 
				C_02_2_RATE,		-- ��(��)�߰������������� 
				C_02_3,				-- �������α� 
				C_RETIRE_TAX_YN,	-- ��(��)�����ҵ漼�װ������� 
				C_SUM,				-- ��(��)�� 
				DUMMY_YN,			-- DUMMY���� 
				DUP_MM,				-- ���� �ߺ��� 
				EMP_KIND_CD,		-- �ٷα����ڵ� [PHM_EMP_KIND_CD]
				END_YN,				-- �ϷῩ�� 
				ETC_DEDUCT,			-- ��Ÿ���� 
				EXCEPT_MM_2012,		-- 2012����� ���ܿ���(���) 
				EXCEPT_MM_2013,		-- 2013����� ���ܿ���(���) 
				EXCE_END_YMD,		-- ���������������� 
				EXCE_STA_YMD,		-- ���������ܽ����� 
				FILLDT,				-- ��ǥ�� 
				FILLNO,				-- ��ǥ��ȣ 
				FIRST_HIRE_YMD,		-- �����Ի��� 
				FLAG,				-- 1��̸����� 
				FLAG2,				-- �߰�����(�ӱ���ũY����N) 
				--JSOFCD1,			-- JSOFCD1 
				--JSOFCD2,			-- JSOFCD2 
				LAST_YN,			-- ���������� 
				MID_ADD_MM,			-- �߰�����  ����� 
				MID_END_YMD,		-- �߰����� ������ 
				MID_EXCEPT_MM,		-- �߰����� ���ܿ� 
				MID_HIRE_YMD,		-- �߰����� �Ի��� 
				MID_PAY_YMD,		-- �߰����� ������ 
				MID_STA_YMD,		-- �߰����� ����� 
				MID_WORK_MM,		-- �߰����� �ټӿ� 
				MID_WORK_YY,		-- �߰����� �ټӳ�� 
				MOD_DATE,			-- �����Ͻ� 
				MOD_USER_ID,		-- ������ 
				MONTH_DAY3,			-- 3�����ٹ��ϼ� 
				NON_RETIRE_AMT,		-- ����������� 
				NON_RETIRE_MID_AMT,	-- ������߰����������� 
				NOTE,				-- ��� 
				OFFICERS_YN,		-- �ӿ����� 
				ORG_ID,				-- �߷ɺμ�ID 
				ORIGIN_REP_CALC_LIST_ID,	-- �������� �����ݴ��ID 
				PAY_ORG_ID,			-- �޿��μ�ID 
				PAY_YMD,			-- ������ 
				POS_CD,				-- �����ڵ� [PHM_POS_CD]
				POS_GRD_CD,			-- �����ڵ� [PHM_POS_GRD_CD]
				R01,				-- ���������޿��� 
				R01_A,				-- �����̿������޿��� 
				R01_S,				-- �����޿��� 
				R02,				-- ���������ҵ����(01+02) 
				R02_01,				-- ���������ҵ����(50%) 
				R02_02,				-- ���������ҵ����(�ټ�) 
				R02_B,				-- �����̿������ҵ����(01+02) 
				R02_B_01,			-- �����̿������ҵ����(50%) 
				R02_B_02,			-- �����̿������ҵ����(�ټ�) 
				R02_S,				-- �����ҵ���� 
				R03,				-- ���������ҵ��ǥ 
				R03_2012,			-- 2012����� ����ǥ�� 
				R03_2013,			-- 2013����� ����ǥ�� 
				R03_C,				-- �����̿������ҵ��ǥ 
				R03_S,				-- �����ҵ��ǥ 
				R04,				-- ��������հ���ǥ�� 
				R04_12,				-- �����ҵ����ǥ��(2016�� ����) 
				R04_2012,			-- 2012����� ����� ����ǥ��(����) 
				R04_2013,			-- 2013����� ����� ����ǥ��(����) 
				R04_D,				-- �����̿ܿ���հ���ǥ�� 
				R04_DEDUCT,			-- ȯ��޿�������(2016�� ����) 
				R04_D_2012,			-- 2012����� ����� ����ǥ��(�����̿�) 
				R04_D_2013,			-- 2013����� ����� ����ǥ��(�����̿�) 
				R04_N_12,			-- ȯ��޿�(2016�� ����) 
				R04_S,				-- ����հ���ǥ�� 
				R05,				-- ��������ջ��⼼�� 
				R05_12,				-- ȯ����⼼��(2016�� ����) 
				R05_2012,			-- 2012����� ����� ���⼼��(����) 
				R05_2013,			-- 2013����� ����� ���⼼��(����) 
				R05_E,				-- �����̿ܿ���ջ��⼼�� 
				R05_E_2012,			-- 2012����� ����� ���⼼��(�����̿�) 
				R05_E_2013,			-- 2013����� ����� ���⼼��(�����̿�) 
				R05_S,				-- ����ջ��⼼�� 
				R06,				-- �������⼼�� 
				R06_2012,			-- 2012����� ���⼼��(����) 
				R06_2013,			-- 2013����� ���⼼��(����) 
				R06_F,				-- �����ܻ̿��⼼�� 
				R06_F_2012,			-- 2012����� ���⼼��(�����̿�) 
				R06_F_2013,			-- 2013����� ���⼼��(�����̿�) 
				R06_N,				-- ���⼼��(2016�� ����) 
				R06_S,				-- ���⼼�� 
				R07,				-- �������װ��� 
				R07_G,				-- �����ܼ̿��װ��� 
				R07_S,				-- ���װ��� 
				R08,				-- ������������ 
				R08_H,				-- �����̿ܰ������� 
				R08_S,				-- �������� 
				R09,				-- ���������ҵ漼�װ��� 
				R09_I,				-- �����̿������ҵ漼�װ��� 
				R09_S,				-- �����ҵ漼�װ��� 
				RC_C01_TAX_AMT,		-- ���������ݹ��������ݼ��� 
				REAL_AMT,			-- �����޾� 
				REP_ACCOUNT_NO,		-- �������ݰ��¹�ȣ 
				REP_ANNUITY_BIZ_NM,	-- �������ݻ���ڸ� 
				REP_ANNUITY_BIZ_NO,	-- �������ݻ�����Ϲ�ȣ 
				REP_MID_YN,			-- �߰��������Կ��� 
				RESIDENT_CD,		-- �����ڱ��� 
				RETIRE_FUND_MON,	-- ���������(�ѱ�) 
				RETIRE_MID_AMT,		-- �߰����������� 
				RETIRE_MID_INCOME_AMT,	-- �߰����������ҵ漼 
				RETIRE_MID_JTAX_AMT,							-- �߰����������ֹμ�
				RETIRE_MID_NTAX_AMT,							-- �߰�����������Ư��
				RETIRE_TURN,		-- ���ο���������ȯ�� 
				RETIRE_TURN_INCOME_AMT,	-- ���ο���������ȯ�ݼҵ漼
				RETIRE_TURN_RESIDENCE_AMT,	-- ���ο���������ȯ���ֹμ�
				RETIRE_TYPE_CD,		-- ��������  
				SEND_YMD,			-- �������� 
				COMPANY_CD,			-- ȸ���ڵ� 
				SUM_ADD_MM,			-- ���� ����� 
				SUM_END_YMD,		-- ���� ������ 
				SUM_EXCEPT_MM,		-- ���� ���ܿ� 
				SUM_STA_YMD,		-- ���� ����� 
				SUM_WORK_MM,		-- ���� �ټӿ� 
				SUM_WORK_YY,		-- ���� �ټӳ�� 
				T01,				-- �����ҵ漼 
				T02,				-- �����ֹμ� 
				T03,				-- ������Ư�� 
				TAX_RATE,			-- ���� 
				TAX_TYPE,			-- ���ݹ��[REP_TAX_TYPE_CD] 
				TRANS_AMT,			-- �����̿��ݾ� 
				TRANS_INCOME_AMT,	-- �����̿��ҵ漼 
				TRANS_OTHER_AMT,	-- �����̿ܰ����̿��ݾ� 
				TRANS_RESIDENCE_AMT,-- �����̿��ֹμ� 
				TRANS_YMD,			-- �������� �Ա���
				TZ_CD,				-- Ÿ�����ڵ� 
				TZ_DATE,			-- Ÿ�����Ͻ� 
				T_SUM,				-- �������װ� 
				WORK_DAY,			-- �Ǳټ����ϼ� 
				WORK_DD,			-- �Ǳټ��ϼ� 
				WORK_MM,			-- �Ǳټӿ��� 
				WORK_YY,			-- �Ǳټӳ��(�⸸) 
				WORK_YY_PT,			-- �Ǳټӳ��(������) 
				ETC_PAY_AMT,		-- ��Ÿ����
				ORG_NM,				-- ������
				ORG_LINE,			-- ��������
				BIZ_CD,				-- �����
				REG_BIZ_CD,			-- �Ű�����
				DUTY_CD,			-- ��å�ڵ� [PHM_DUTY_CD]
				YEARNUM_CD,			-- ȣ���ڵ� [PHM_YEARNUM_CD]
				MGR_TYPE_CD,		-- ���������ڵ�[PHM_MGR_TYPE_CD]
				JOB_POSITION_CD,	-- �����ڵ�[PHM_JOB_POSTION_CD]
				JOB_CD,				-- �����ڵ�
				PAY_METH_CD,		-- �޿����޹��[PAY_METH_CD]
				EMP_CLS_CD,			-- �������[PAY_EMP_CLS_CD]
				WORK_MM_PT,			-- ��������
				WORK_DD_PT,			-- �����ϼ�
				SUM_MONTH_DAY3,		-- �ټ��ϼ�
				COMM_AMT,			-- ����ӱ�
				DAY_AMT,			-- �ϴ�
				PAY01_YM,			-- �޿����_01
				PAY02_YM,			-- �޿����_02
				PAY03_YM,			-- �޿����_03
				PAY04_YM,			-- �޿����_04
				PAY05_YM,			-- �޿����_05
				PAY06_YM,			-- �޿����_06
				PAY07_YM,			-- �޿����_07
				PAY08_YM,			-- �޿����_08
				PAY09_YM,			-- �޿����_09
				PAY10_YM,			-- �޿����_10
				PAY11_YM,			-- �޿����_11
				PAY12_YM,			-- �޿����_12
				PAY01_AMT,			-- �޿��ݾ�_01
				PAY02_AMT,			-- �޿��ݾ�_02
				PAY03_AMT,			-- �޿��ݾ�_03
				PAY04_AMT,			-- �޿��ݾ�_04
				PAY05_AMT,			-- �޿��ݾ�_05
				PAY06_AMT,			-- �޿��ݾ�_06
				PAY07_AMT,			-- �޿��ݾ�_07
				PAY08_AMT,			-- �޿��ݾ�_08
				PAY09_AMT,			-- �޿��ݾ�_09
				PAY10_AMT,			-- �޿��ݾ�_10
				PAY11_AMT,			-- �޿��ݾ�_11
				PAY12_AMT,			-- �޿��ݾ�_12
				PAY_MON,			-- �޿��հ�
				PAY_TOT_AMT,		-- 3�����޿��հ�
				BONUS01_YM,			-- �󿩳��_01
				BONUS02_YM,			-- �󿩳��_02
				BONUS03_YM,			-- �󿩳��_03
				BONUS04_YM,			-- �󿩳��_04
				BONUS05_YM,			-- �󿩳��_05
				BONUS06_YM,			-- �󿩳��_06
				BONUS07_YM,			-- �󿩳��_07
				BONUS08_YM,			-- �󿩳��_08
				BONUS09_YM,			-- �󿩳��_09
				BONUS10_YM,			-- �󿩳��_10
				BONUS11_YM,			-- �󿩳��_11
				BONUS12_YM,			-- �󿩳��_12
				BONUS01_AMT,		-- �󿩱ݾ�_01
				BONUS02_AMT,		-- �󿩱ݾ�_02
				BONUS03_AMT,		-- �󿩱ݾ�_03
				BONUS04_AMT,		-- �󿩱ݾ�_04
				BONUS05_AMT,		-- �󿩱ݾ�_05
				BONUS06_AMT,		-- �󿩱ݾ�_06
				BONUS07_AMT,		-- �󿩱ݾ�_07
				BONUS08_AMT,		-- �󿩱ݾ�_08
				BONUS09_AMT,		-- �󿩱ݾ�_09
				BONUS10_AMT,		-- �󿩱ݾ�_10
				BONUS11_AMT,		-- �󿩱ݾ�_11
				BONUS12_AMT,		-- �󿩱ݾ�_12
				BONUS_TOT_AMT,		-- 3�����޿��հ�
				CNT_YEAR_REQ,		-- �����߻��ϼ�
				CNT_YEAR_USE,		-- ��������ϼ�
				CNT_YEAR,			-- ���������ϼ�
				DAY_TOT_AMT,		-- 3���� ����������
				PAY_SUM_AMT,		-- 3���� ���ӱ�
				PAY_COMM_AMT,		-- 3���� ����ӱ�
				AVG_PAY_AMT_M,		-- �� ����ӱ�(������ӱ� / 12)
				AVG_PAY_AMT_D,		-- �� ����ӱ�
				AMT_RETR_PAY_Y,		-- �� ������
				AMT_RETR_PAY_M,		-- �� ������
				AMT_RETR_PAY_D,		-- �� ������
				AMT_RATE_ADD,		-- ������(�ӿ����)
				C_02_SUM,			-- ��(��)������
				B1_RERIRE_INSU_AMT,	-- ��(��)���������
				BC_WORK_MM,			-- �ټӰ�����
				BC_WORK_ADD_MM,		-- ��������
				BC_WORK_TOT_MM,		-- ��������(�ټӰ�����+��������)
				MID_DUP_MM,			-- �߰����� �ߺ�����
				R04_ADD,			-- ��������
				R06_SUM,			-- ���⼼�� �հ�
				R06_2009,			-- ���⼼��_2009�� �ѽ�����
				ETC01_SUB_NM,		-- ��Ÿ����01 ����
				ETC02_SUB_NM,		-- ��Ÿ����02 ����
				ETC03_SUB_NM,		-- ��Ÿ����03 ����
				ETC04_SUB_NM,		-- ��Ÿ����04 ����
				ETC05_SUB_NM,		-- ��Ÿ����05 ����
				ETC06_SUB_NM,		-- ��Ÿ����06 ����
				ETC07_SUB_NM,		-- ��Ÿ����07 ����
				ETC08_SUB_NM,		-- ��Ÿ����08 ����
				ETC09_SUB_NM,		-- ��Ÿ����09 ����
				ETC10_SUB_NM,		-- ��Ÿ����10 ����
				ETC11_SUB_NM,		-- ��Ÿ����11 ����
				ETC12_SUB_NM,		-- ��Ÿ����12 ����
				ETC13_SUB_NM,		-- ��Ÿ����13 ����
				ETC01_SUB_AMT,		-- ��Ÿ����01 �ݾ�
				ETC02_SUB_AMT,		-- ��Ÿ����02 �ݾ�
				ETC03_SUB_AMT,		-- ��Ÿ����03 �ݾ�
				ETC04_SUB_AMT,		-- ��Ÿ����04 �ݾ�
				ETC05_SUB_AMT,		-- ��Ÿ����05 �ݾ�
				ETC06_SUB_AMT,		-- ��Ÿ����06 �ݾ�
				ETC07_SUB_AMT,		-- ��Ÿ����07 �ݾ�
				ETC08_SUB_AMT,		-- ��Ÿ����08 �ݾ�
				ETC09_SUB_AMT,		-- ��Ÿ����09 �ݾ�
				ETC10_SUB_AMT,		-- ��Ÿ����10 �ݾ�
				ETC11_SUB_AMT,		-- ��Ÿ����11 �ݾ�
				ETC12_SUB_AMT,		-- ��Ÿ����12 �ݾ�
				ETC13_SUB_AMT,		-- ��Ÿ����13 �ݾ�
				ETC01_PAY_NM,		-- ��Ÿ����01 ����
				ETC02_PAY_NM,		-- ��Ÿ����02 ����
				ETC03_PAY_NM,		-- ��Ÿ����03 ����
				ETC04_PAY_NM,		-- ��Ÿ����04 ����
				ETC05_PAY_NM,		-- ��Ÿ����05 ����
				ETC06_PAY_NM,		-- ��Ÿ����06 ����
				ETC07_PAY_NM,		-- ��Ÿ����07 ����
				ETC08_PAY_NM,		-- ��Ÿ����08 ����
				ETC09_PAY_NM,		-- ��Ÿ����09 ����
				ETC10_PAY_NM,		-- ��Ÿ����10 ����
				ETC01_PAY_AMT,		-- ��Ÿ����01 �ݾ�
				ETC02_PAY_AMT,		-- ��Ÿ����02 �ݾ�
				ETC03_PAY_AMT,		-- ��Ÿ����03 �ݾ�
				ETC04_PAY_AMT,		-- ��Ÿ����04 �ݾ�
				ETC05_PAY_AMT,		-- ��Ÿ����05 �ݾ�
				ETC06_PAY_AMT,		-- ��Ÿ����06 �ݾ�
				ETC07_PAY_AMT,		-- ��Ÿ����07 �ݾ�
				ETC08_PAY_AMT,		-- ��Ÿ����08 �ݾ�
				ETC09_PAY_AMT,		-- ��Ÿ����09 �ݾ�
				ETC10_PAY_AMT,		-- ��Ÿ����10 �ݾ�
				COMM_REAL_AMT,		-- ������޾�
				PENSION_TOT,		-- ��(��)�Ѽ��ɾ�
				PENSION_WONRI,		-- ��(��)�������հ��
				PENSION_RESERVE,	-- ��(��)����������(�ҵ��ں��Ծ�)
				PENSION_GONGJE,		-- ��(��)�������ݼҵ������
				PENSION_CASH,		-- ��(��)���������Ͻñ�
				PENSION_REAL,		-- ��(��)21)���������Ͻñ����޿����
				SEND_YM,			-- �Ű�ͼӳ��
				SEND_YN,			-- �Ű���
				AUTO_YN,			-- �ڵ��а� ����
				AUTO_YMD,			-- �ڵ��а� �̰�����
				AUTO_NO,			-- �ڵ��а� �Ϸù�ȣ
				REC_YMD,			-- ��������
				CALCU_TPYE,			-- ��걸��
				PAY_GROUP,			-- �޿��׷�
				B_PENSION_TOT,		-- ��(��)�Ѽ��ɾ�
				B_PENSION_WONRI,	-- ��(��)�������հ��
				B_PENSION_RESERVE,	-- ��(��)����������(�ҵ��ں��Ծ�)
				B_PENSION_GONGJE,	-- ��(��)�������ݼҵ������
				B_PENSION_CASH,		-- ��(��)���������Ͻñ�
				B_PENSION_REAL,		-- ��(��)21)���������Ͻñ����޿����
				TRANS_TOT_AMT,		-- ���Ͻñ�
				TRANS_NOW_AMT,		-- ���ɰ��������޿���
				TRANS_SUDK_AMT,		-- ȯ�������ҵ����
				TRANS_RETR_AMT,		-- ȯ�������ҵ����ǥ��
				TRANS_AVG_PAY,		-- ȯ�꿬��հ���ǥ��
				TRANS_AVG_TAX,		-- ȯ�꿬��ջ��⼼��
				R04_2013_5,			-- 2013�� ���� 5��ȯ�����ǥ��
				R05_2013_5,			-- ����ջ��⼼��
				RETPENSION_YMD      -- ���Ա��ش�ð�(������)
				)
				SELECT NEXT VALUE FOR dbo.S_REP_SEQUENCE AS REP_CALC_LIST_ID,			-- �����ݴ��ID 
					   @emp_id,												-- ���ID 	
					   CASE WHEN A.FG_RETR = '1' THEN '01'
							WHEN A.FG_RETR = '2' THEN '03'
							WHEN A.FG_RETR = '3' THEN '02'
							WHEN A.FG_RETR = '4' THEN '04'
							ELSE '01' END AS CALC_TYPE_CD,								-- ���걸��[REP_CALC_TYPE_CD]
					   dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') AS RETIRE_YMD,				-- ������ 	   
					   CASE WHEN TRIM(A.FG_RETPENSION_KIND) = 'DB' THEN '10' 
							WHEN TRIM(A.FG_RETPENSION_KIND) = 'DC' THEN '20'
							WHEN TRIM(A.FG_RETPENSION_KIND) = 'TR' THEN '30'
							ELSE '00' 
					   END AS INS_TYPE_CD,												-- �������ݱ���
					   ISNULL(TRIM(A.YN_RETPENSION), 'N') AS INS_TYPE_YN,				-- �������ݰ��Ա���
					   NULL AS ADD_MM_2012,												-- 2012����� �������(���) 
					   NULL AS ADD_MM_2013,												-- 2013�����  �������(���) 
					   NULL AS ADD_WORK_YY,												-- �߰��ټӳ��(������) 
					   NULL AS AGENT_CD,												-- ¡���ǹ��ڱ��� 
					   NULL AS APPL_CAUSE_CD,											-- ��û���� 
				--	   NULL AS APPL_GUBUN,												-- �߰�����(���Ĺ�)���� 
					   NULL AS APPL_ID,													-- ��û��ID 
					   NULL AS APPL_YMD,												-- ��û���� 
					   NULL AS ARMY_HIRE_YMD,											-- ����°���(����)�Ի��� 
					   NULL AS ATTACH_AMT,												-- �з��� 
					   A.AMT_BONUS_AVG3 AS AVG_BONUS,									-- ��ջ� 
					   A.AMT_YEARMONTH_AVG3 AS AVG_DAY,									-- ��տ����� 
					   A.AMT_PAY_AVG AS AVG_PAY,										-- ��ձ޿� 
					   A.AMT_DAY_PAY AS AVG_PAY_AMT,									-- ����ӱ� 
					   A.NM_O_PAY2 AS B1_CORP_NM,										-- ��(��)����ó�� 
					   dbo.XF_TO_DATE(A.DT_O_RETIRE, 'YYYYMMDD') AS B1_END_YMD,			-- ��(��)������ 
					   --A.CNT_BFR_EXCEPT_MONTH AS B1_EXCEPT_MM,						-- ��(��)���ܿ��� 
					   NULL AS B1_EXCEPT_MM,											-- ��(��)���ܿ���
					   --A.AMT_O_PAY2_1 AS B1_RETIRE_AMT,								-- ��(��)�����޿�
					   0 AS B1_RETIRE_AMT,												-- ��(��)�����޿�
					   A.AMT_O_PAY2_2 AS B1_RETIRE_REP_AMT,								-- ��(��)��/��������� 
					   dbo.XF_TO_DATE(A.DT_O_ENTER, 'YYYYMMDD') AS B1_STA_YMD,			-- ��(��)����� 
					   A.NO_O_PAY2 AS B1_TAX_NO,										-- ��(��)����ڹ�ȣ 
					   --A.CNT_O_DUTYMONTH AS B1_WORK_MM,								-- ��(��)�ټӿ��� 
					   NULL AS B1_WORK_MM,												-- ��(��)�ټӿ���
					   A.AMT_O_PAY2_TOT AS B1_RETIRE_TOT,								-- ��(��)������
					   NULL AS B2_END_YMD,												-- �����̿���(��)������ 
					   NULL AS B2_EXCEPT_MM,											-- �����̿���(��)���ܿ��� 
					   NULL AS B2_STA_YMD,												-- �����̿���(��)����� 
					   NULL AS B2_WORK_MM,												-- �����̿���(��)�ټӿ��� 
					   NULL AS BC1_DUP_MM,												-- �ߺ�����(����) 
					   A.CNT_TAX_YEAR AS BC1_WORK_YY,									-- �ټӳ��(����)(��+���� �ټӳ��) 
					   NULL AS BC2_DUP_MM,												-- �����̿��ߺ����� 
					   NULL AS BC2_WORK_YY,												-- �����ܱ̿ټӳ�� 
					   A.AMT_BONUS_TOT AS BONUS_MON,									-- ���Ѿ� 
					   --A.AMT_OLD_STAX AS BT01,										-- ��(��)�ҵ漼 
					   0 AS BT01,														-- ��(��)�ҵ漼
					   --A.AMT_OLD_JTAX AS BT02,										-- ��(��)�ֹμ� 
					   0 AS BT02,														-- ��(��)�ֹμ�
					   --A.AMT_OLD_NTAX AS BT03,											-- ��(��)��Ư�� 
					   0 AS BT03,														-- ��(��)��Ư��
					   ISNULL(A.AMT_OLD_STAX,0) + ISNULL(A.AMT_OLD_NTAX,0) + ISNULL(A.AMT_OLD_JTAX,0) AS BT_SUM,				-- ��(��)���װ� 
					   NULL AS B_RETIRE_TAX_YN,											-- ��(��)�����ҵ漼�װ������� 
					   NULL AS C1_ADD_MM,												-- ���� ������� 
					   NULL AS C1_ADD_MM_2012,											-- ���� 2012����� �������(�Է�) 
					   NULL AS C1_ADD_MM_2013,											-- ���� 2013�����  �������(�Է�) 
					   dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') AS C1_END_YMD,				-- ��(��)������ 
					   CASE WHEN A.DT_JOIN <= '20120101' THEN dbo.XF_TO_DATE('20121231', 'YYYYMMDD') ELSE NULL END AS C1_END_YMD_2012,		-- 2012����� ������ 
					   dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') AS C1_END_YMD_2013,		-- 2013����� ������ 
					   A.CNT_EXCEPT_MONTH AS C1_EXCEPT_MM,								-- ��(��)���ܿ��� 
					   NULL AS C1_EXCEPT_MM_2012,										-- ���� 2012����� ���ܿ���(�Է�) 
					   NULL AS C1_EXCEPT_MM_2013,										-- ���� 2013����� ���ܿ���(�Է�) 
					   dbo.XF_TO_DATE(A.DT_JOIN, 'YYYYMMDD') AS C1_STA_YMD,				-- ������(��)����� 
					   CASE WHEN A.DT_JOIN <= '20120101' THEN dbo.XF_TO_DATE(A.DT_JOIN, 'YYYYMMDD') ELSE NULL END AS C1_STA_YMD_2012,		-- 2012����� ������ 
					   CASE WHEN A.DT_JOIN < '20130101' THEN dbo.XF_TO_DATE('20130101', 'YYYYMMDD') ELSE dbo.XF_TO_DATE(A.DT_JOIN, 'YYYYMMDD') END AS C1_STA_YMD_2013,		-- 2013����� ������ 
					   NULL AS C1_TAX_RATE_2012,										-- 2012����� ����(����) 
					   NULL AS C1_TAX_RATE_2013,										-- 2013����� ����(����) 
					   (ISNULL(A.CNT_CAL_YEAR,0) * 12) + ISNULL(A.CNT_CAL_MONTH,0) AS C1_WORK_MM,			-- ��(��)�ټӿ��� 
					   A.CNT_CAL_MONTH_2012 AS C1_WORK_MM_2012,							-- 2012����� �ټӿ� 
					   A.CNT_CAL_MONTH_2013 AS C1_WORK_MM_2013,							-- 2012����� �ټӿ� 
					   A.CNT_TAX_YEAR AS C1_WORK_YY,									-- ���� �ټӳ�� 
					   A.CNT_TAX_YEAR_2012 AS C1_WORK_YY_2012,							-- 2012����� �ټӳ��(����) 
					   A.CNT_TAX_YEAR_2013 AS C1_WORK_YY_2013,							-- 2013����� �ټӳ��(����) 
					   NULL AS C2_END_YMD,												-- �����̿���(��)������ 
					   NULL AS C2_EXCEPT_MM,											-- �����̿���(��)���ܿ��� 
					   NULL AS C2_STA_YMD,												-- �����̿���(��)����� 
					   NULL AS C2_TAX_RATE_2012,										-- 2012����� ����(�����̿�) 
					   NULL AS C2_TAX_RATE_2013,										-- 2013����� ����(�����̿�) 
					   NULL AS C2_WORK_MM,												-- �����̿���(��)�ټӿ��� 
					   A.CNT_TAX_YEAR_2012 AS C2_WORK_YY_2012,							-- 2012����� �ټӳ��(�����̿�) 
					   A.CNT_TAX_YEAR_2013 AS C2_WORK_YY_2013,							-- 2013����� �ټӳ��(�����̿�) 
					   '04' AS CALC_RETIRE_CD,											-- ����(����)����(�ؿ��İ�,����İ�,���Դ�,ȸ���̵�) 	    
					   A.RSN_RETIRE AS CAM_TYPE_CD,										-- �߷����� 
					   ISNULL(AMT_RETR_PAY,0) - (ISNULL(A.AMT_FIX_STAX,0) + ISNULL(A.AMT_FIX_NTAX,0) + ISNULL(A.AMT_FIX_JTAX,0)) AS CHAIN_AMT,	-- �������޾�(������) 
					   A.AMT_FIX_STAX AS CT01,											-- �����ҵ漼 
					   A.AMT_FIX_JTAX AS CT02,											-- �����ֹμ� 
					   A.AMT_FIX_NTAX AS CT03,											-- ������Ư�� 
					   ISNULL(A.AMT_FIX_STAX,0) + ISNULL(A.AMT_FIX_NTAX,0) + ISNULL(A.AMT_FIX_JTAX,0) AS CT_SUM,				-- �������װ� 
					   A.AMT_RETR_PAY AS C_01,											-- ��(��)���������޿� =>  ��(��)���������� + ��(��)��������� 
					   A.AMT_RETR_PAY AS C_01_1,										-- ��(��)���������� 
					   A.AMT_N_PAY_3 AS C_01_2,											-- ��(��)��������� 
					   A.AMT_N_PAY_1 AS C_02,										-- ��(��)����������� (�߰�������)  => �� + �߰������� 
					   A.AMT_N_PAY_2 AS C_02_1,											-- ��(��)�������� 
					   NULL AS C_02_1_BASE,												-- ��(��)�������ݱ��رݾ� 
					   NULL AS C_02_1_RATE,												-- ��(��)�������������� 
					   A.AMT_RETR_TOT AS C_02_2,										-- ��(��)�߰������� 
					   NULL AS C_02_2_RATE,												-- ��(��)�߰������������� 
					   NULL AS C_02_3,													-- �������α� 
					   A.YN_TAX_TRANS AS C_RETIRE_TAX_YN,								-- ��(��)�����ҵ漼�װ������� 
					   A.AMT_RETR_PAY AS C_SUM,											-- ��(��)�� 
					   NULL AS DUMMY_YN,												-- DUMMY���� 
					   NULL AS DUP_MM,													-- ���� �ߺ��� 
					   ISNULL(A.FG_PERSON, B.EMP_KIND_CD) AS EMP_KIND_CD,										-- �ٷα����ڵ� [PHM_EMP_KIND_CD]
					   NULL AS END_YN,													-- �ϷῩ�� 
					   ISNULL(A.AMT_ETC01_SUB,0) + ISNULL(A.AMT_ETC02_SUB,0) + ISNULL(A.AMT_ETC03_SUB,0) + ISNULL(A.AMT_ETC04_SUB,0) + ISNULL(A.AMT_ETC05_SUB,0) + 
					   ISNULL(A.AMT_ETC06_SUB,0) + ISNULL(A.AMT_ETC07_SUB,0) + ISNULL(A.AMT_ETC08_SUB,0) + ISNULL(A.AMT_ETC09_SUB,0) + ISNULL(A.AMT_ETC10_SUB,0) AS ETC_DEDUCT,	-- ��Ÿ���� 
					   NULL AS EXCEPT_MM_2012,											-- 2012����� ���ܿ���(���) 
					   NULL AS EXCEPT_MM_2013,											-- 2013����� ���ܿ���(���) 
					   NULL AS EXCE_END_YMD,											-- ���������������� 
					   NULL AS EXCE_STA_YMD,											-- ���������ܽ����� 
					   NULL AS FILLDT,													-- ��ǥ�� 
					   NULL AS FILLNO,													-- ��ǥ��ȣ 
					   dbo.XF_TO_DATE(B.FIRST_JOIN_YMD,'yyyymmdd') AS FIRST_HIRE_YMD,								-- �����Ի��� 
					   NULL AS FLAG,													-- 1��̸����� 
					   NULL AS FLAG2,													-- �߰�����(�ӱ���ũY����N) 
					   --NULL AS JSOFCD1,													-- JSOFCD1 
					   --NULL AS JSOFCD2,													-- JSOFCD2 
					   NULL AS LAST_YN,													-- ���������� 
					   NULL AS MID_ADD_MM,												-- �߰�����  ����� 
					   dbo.XF_TO_DATE(A.DT_O_RETIRE,'yyyymmdd') AS MID_END_YMD,									-- �߰����� ������ 
					   A.CNT_BFR_EXCEPT_MONTH AS MID_EXCEPT_MM,							-- �߰����� ���ܿ� 
					   NULL AS MID_HIRE_YMD,											-- �߰����� �Ի���
					   NULL AS MID_PAY_YMD,												-- �߰����� ������ 
					   dbo.XF_TO_DATE(A.DT_O_ENTER,'yyyymmdd') AS MID_STA_YMD,										-- �߰����� ����� 
					   A.CNT_O_DUTYMONTH AS MID_WORK_MM,								-- �߰����� �ټӿ� 
					   A.CNT_BFR_DUTY_YEAR AS MID_WORK_YY,								-- �߰����� �ټӳ�� 
					   ISNULL(A.DT_UPDATE,GETDATE()) AS MOD_DATE,											-- �����Ͻ� 
					   0 AS MOD_USER_ID,												-- ������ 
					   A.CNT_AVG_DAY AS MONTH_DAY3,										-- 3�����ٹ��ϼ� 
					   A.AMT_TAX_EXEMPTION_I AS NON_RETIRE_AMT,							-- ����������� 
					   A.AMT_BFR_TAX_EXEMPTION_I AS NON_RETIRE_MID_AMT,					-- ������߰����������� 
					   A.REM_COMMENT AS NOTE,											-- ��� 
					   NULL AS OFFICERS_YN,												-- �ӿ����� 
					   ISNULL((SELECT ORG_ID 
						  FROM ORM_ORG (NOLOCK)
						 WHERE ORG_CD = A.CD_DEPT 
						   AND COMPANY_CD = A.CD_COMPANY
						   /* AND dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') BETWEEN STA_YMD AND END_YMD */ ), B.ORG_ID) AS ORG_ID,		-- �߷ɺμ�ID 
					   NULL AS ORIGIN_REP_CALC_LIST_ID,									-- �������� �����ݴ��ID 
					   ISNULL((SELECT ORG_ID 
						  FROM ORM_ORG (NOLOCK)
						 WHERE ORG_CD = A.CD_DEPT 
						   AND COMPANY_CD = A.CD_COMPANY
						   /* AND dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') BETWEEN STA_YMD AND END_YMD */ ), B.ORG_ID) AS PAY_ORG_ID,	-- �޿��μ�ID 
					   dbo.XF_TO_DATE(A.DT_BASE, 'YYYYMMDD') AS PAY_YMD,				-- ������ 
					   ISNULL(A.CD_POSITION, B.POS_CD) AS POS_CD,											-- �����ڵ� [PHM_POS_CD]
					   ISNULL(A.LVL_PAY1, B.POS_GRD_CD) AS POS_GRD_CD,										-- �����ڵ� [PHM_POS_GRD_CD]
					   A.AMT_RETR_PAY AS R01,											-- ���������޿��� 
					   NULL AS R01_A,													-- �����̿������޿��� 
					   A.AMT_RETR_TOT AS R01_S,											-- �����޿��� 
					   A.AMT_RETR_SUDK_GONG AS R02,										-- ���������ҵ����(01+02) 
					   A.AMT_RETR_SUDK_GONG2 AS R02_01,									-- ���������ҵ����(50%) 
					   A.AMT_RETR_SUDK_GONG3 AS R02_02,									-- ���������ҵ����(�ټ�) 
					   NULL AS R02_B,													-- �����̿������ҵ����(01+02) 
					   A.AMT_RETR_SUDK_GONG1 AS R02_B_01,								-- �����̿������ҵ����(50%) 
					   NULL AS R02_B_02,												-- �����̿������ҵ����(�ټ�) 
					   A.AMT_RETR_SUDK_GONG AS R02_S,									-- �����ҵ���� 
					   A.AMT_BASE_TAX AS R03,											-- ���������ҵ��ǥ 
					   A.AMT_BASE_TAX_2012 AS R03_2012,									-- 2012����� ����ǥ�� 
					   A.AMT_BASE_TAX_2013 AS R03_2013,									-- 2013����� ����ǥ�� 
					   NULL AS R03_C,													-- �����̿������ҵ��ǥ 
					   A.AMT_BASE_TAX AS R03_S,											-- �����ҵ��ǥ 
					   A.AMT_Y_BASE_TAX AS R04,											-- ��������հ���ǥ�� 
					   A.AMT_BASE_TAX_2016 AS R04_12,									-- �����ҵ����ǥ��(2016�� ����) 
					   A.AMT_Y_BASE_TAX_2012 AS R04_2012,								-- 2012����� ����� ����ǥ��(����) 
					   A.AMT_BASE_TAX_2013_DIV AS R04_2013,								-- 2013����� ����� ����ǥ��(����) 
					   NULL AS R04_D,													-- �����̿ܿ���հ���ǥ�� 
					   A.AMT_RETR_SUDK_GONG4 AS R04_DEDUCT,								-- ȯ��޿�������(2016�� ����) 
					   A.AMT_Y_BASE_TAX_2012 AS R04_D_2012,								-- 2012����� ����� ����ǥ��(�����̿�) 
					   A.AMT_BASE_TAX_2013_DIV AS R04_D_2013,							-- 2013����� ����� ����ǥ��(�����̿�) 
					   A.AMT_TRNS_PAY AS R04_N_12,										-- ȯ��޿�(2016�� ����) 
					   A.AMT_BASE_TAX_2013_DIV AS R04_S,								-- ����հ���ǥ�� 
					   NULL AS R05,														-- ��������ջ��⼼�� 
					   A.AMT_CAL_TAX_2016 AS R05_12,									-- ȯ����⼼��(2016�� ����) 
					   A.AMT_Y_CAL_TAX AS R05_2012,										-- 2012����� ����� ���⼼��(����) 
					   A.AMT_Y_CAL_TAX_2013 AS R05_2013,								-- 2013����� ����� ���⼼��(����) 
					   NULL AS R05_E,													-- �����̿ܿ���ջ��⼼�� 
					   A.AMT_Y_CAL_TAX AS R05_E_2012,									-- 2012����� ����� ���⼼��(�����̿�) 
					   A.AMT_Y_CAL_TAX_2013 AS R05_E_2013,								-- 2013����� ����� ���⼼��(�����̿�) 
					   NULL AS R05_S,													-- ����ջ��⼼�� 
					   A.AMT_CAL_TAX3 AS R06,											-- �������⼼�� 
					   A.AMT_CAL_TAX_2012 AS R06_2012,									-- 2012����� ���⼼��(����) 
					   A.AMT_CAL_TAX_2013 AS R06_2013,									-- 2013����� ���⼼��(����) 
					   NULL AS R06_F,													-- �����ܻ̿��⼼�� 
					   A.AMT_CAL_TAX_2012 AS R06_F_2012,								-- 2012����� ���⼼��(�����̿�) 
					   A.AMT_CAL_TAX_2013 AS R06_F_2013,								-- 2013����� ���⼼��(�����̿�) 
					   A.AMT_CAL_TAX2 AS R06_N,											-- ���⼼��(2016�� ����) 
					   A.AMT_FIX_STAX AS R06_S,											-- ���⼼�� 
					   NULL AS R07,														-- �������װ��� 
					   NULL AS R07_G,													-- �����ܼ̿��װ��� 
					   NULL AS R07_S,													-- ���װ��� 
					   A.AMT_FIX_STAX AS R08,											-- ������������ 
					   NULL AS R08_H,													-- �����̿ܰ������� 
					   A.AMT_FIX_STAX AS R08_S,											-- �������� 
					   NULL AS R09,														-- ���������ҵ漼�װ��� 
					   NULL AS R09_I,													-- �����̿������ҵ漼�װ��� 
					   NULL AS R09_S,													-- �����ҵ漼�װ��� 
					   NULL AS RC_C01_TAX_AMT,											-- ���������ݹ��������ݼ��� 
					   A.AMT_REAL_PAY AS REAL_AMT,										-- �����޾� 
					   A.POSTPONE_ACCNT AS REP_ACCOUNT_NO,								-- �������ݰ��¹�ȣ 
					   A.POSTPONE_BIZ_NAME AS REP_ANNUITY_BIZ_NM,						-- �������ݻ���ڸ� 
					   A.POSTPONE_BIZ_NO AS REP_ANNUITY_BIZ_NO,							-- �������ݻ�����Ϲ�ȣ
					   YN_MID AS REP_MID_YN,											-- �߰��������Կ��� 
					   NULL AS RESIDENT_CD,												-- �����ڱ��� 
					   NULL AS RETIRE_FUND_MON,											-- ���������(�ѱ�) 
					   A.AMT_O_PAY2_1 AS RETIRE_MID_AMT,								-- �߰����������� 
					   A.AMT_OLD_STAX AS RETIRE_MID_INCOME_AMT,							-- �߰����������ҵ漼 
					   A.AMT_OLD_JTAX AS RETIRE_MID_JTAX_AMT,							-- �߰����������ֹμ�
					   A.AMT_OLD_NTAX AS RETIRE_MID_NTAX_AMT,							-- �߰�����������Ư��
					   A.AMT_ANU_RET_AMT AS RETIRE_TURN,								-- ���ο���������ȯ�� 
					   A.AMT_ANU_RET_INC AS RETIRE_TURN_INCOME_AMT,						-- ���ο��� ������ȯ�� �ҵ漼
					   A.AMT_ANU_RET_LOC AS RETIRE_TURN_RESIDENCE_AMT,					-- ���ο��� ������ȯ�� �ֹμ�
					   A.RSN_RETIRE AS RETIRE_TYPE_CD,									-- �������� 
					   dbo.XF_TO_DATE(A.DT_REGISTER, 'YYYYMMDD') AS SEND_YMD,			-- �Ű�(����)���� 
					   A.CD_COMPANY AS COMPANY_CD,										-- ����ȸ���ڵ� 
					   NULL AS SUM_ADD_MM,												-- ���� ����� 
					   dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') AS SUM_END_YMD,			-- ���� ������ 
					   A.CNT_EXCEPT_MONTH AS SUM_EXCEPT_MM,								-- ���� ���ܿ� 
					   dbo.XF_TO_DATE(A.DT_JOIN, 'YYYYMMDD') AS SUM_STA_YMD,			-- ���� ����� 
					   (ISNULL(A.CNT_CAL_YEAR,0) * 12) + ISNULL(CNT_CAL_MONTH,0) AS SUM_WORK_MM,	-- ���� �ټӿ� 
					   A.CNT_TAX_YEAR AS SUM_WORK_YY,									-- ���� �ټӳ�� 
					   A.AMT_NEW_STAX AS T01,											-- �����ҵ漼 
					   A.AMT_NEW_JTAX AS T02,											-- �����ֹμ� 
					   A.AMT_NEW_NTAX AS T03,											-- ������Ư�� 
					   A.RATE_BASE AS TAX_RATE,											-- ���� 
					   NULL AS TAX_TYPE,												-- ���ݹ��[REP_TAX_TYPE_CD] 
					   A.POSTPONE_DEPOSIT AS TRANS_AMT,									-- �����̿��ݾ� 
					   A.POSTPONE_TAX AS TRANS_INCOME_AMT,								-- �����̿��ҵ漼 
					   NULL AS TRANS_OTHER_AMT,											-- �����̿ܰ����̿��ݾ� 
					   dbo.XF_TRUNC_N(A.POSTPONE_TAX / 10,0) AS TRANS_RESIDENCE_AMT,	-- �����̿��ֹμ�
					   dbo.XF_TO_DATE(A.POSTPONE_DEPOSIT_DATE,'yyyymmdd') AS TRANS_YMD,							-- �������� �Ա���
					   'KST' AS TZ_CD,											-- Ÿ�����ڵ� 
					   ISNULL(A.DT_INSERT, '19000101') AS TZ_DATE,				-- Ÿ�����Ͻ� 
					   ISNULL(A.AMT_NEW_STAX,0) + ISNULL(A.AMT_NEW_NTAX,0) + ISNULL(A.AMT_NEW_JTAX,0) AS T_SUM,		-- �������װ� 
					   dbo.XF_DATEDIFF(dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD'), dbo.XF_TO_DATE(A.DT_JOIN, 'YYYYMMDD')) + 1 AS WORK_DAY,			-- �Ǳټ����ϼ� 
					   A.CNT_DUTY_DAY AS WORK_DD,										-- �Ǳټ��ϼ� 
					   A.CNT_DUTY_MONTH AS WORK_MM,										-- �Ǳټӿ��� 
					   A.CNT_DUTY_YEAR AS WORK_YY,										-- �Ǳټӳ��(�⸸) 
					   A.CNT_CAL_YEAR AS WORK_YY_PT,									-- �Ǳټӳ��(������) 
					   ISNULL(A.AMT_ETC01_PROV,0) + ISNULL(A.AMT_ETC02_PROV,0) + ISNULL(A.AMT_ETC03_PROV,0) + ISNULL(A.AMT_ETC04_PROV,0) + ISNULL(A.AMT_ETC05_PROV,0) + 
					   ISNULL(A.AMT_ETC06_PROV,0) + ISNULL(A.AMT_ETC07_PROV,0) + ISNULL(A.AMT_ETC08_PROV,0) + ISNULL(A.AMT_ETC09_PROV,0) + ISNULL(A.AMT_ETC10_PROV,0) AS ETC_PAY_AMT,			-- ��Ÿ����
					   ISNULL((SELECT ORG_NM 
						  FROM ORM_ORG (NOLOCK)
						 WHERE ORG_CD = A.CD_DEPT 
						   AND COMPANY_CD = @t_company_cd
						  /* AND dbo.XF_TO_DATE(A.DT_RETR, 'YYYYMMDD') BETWEEN STA_YMD AND END_YMD */), A.NM_DEPT) AS ORG_NM,	-- ������
					   ISNULL(dbo.F_FRM_ORM_ORG_NM((select org_id from orm_org (NOLOCK) where company_cd=@t_company_cd and org_cd = A.CD_DEPT), 'KO', A.DT_BASE, 'LL'), A.CD_SEQ) AS ORG_LINE,	-- ��������
					   A.CD_BIZ_AREA AS BIZ_CD,											-- �����
					   A.CD_REG_BIZ_AREA AS REG_BIZ_CD,									-- �Ű�����
					   ISNULL(A.CD_ABIL, B.DUTY_CD) AS DUTY_CD,											-- ��å�ڵ� [PHM_DUTY_CD]
					   ISNULL(A.LVL_PAY2, B.YEARNUM_CD) AS YEARNUM_CD,										-- ȣ���ڵ� [PHM_YEARNUM_CD]
					   ISNULL(A.TP_DUTY, B.MGR_TYPE_CD) AS MGR_TYPE_CD,										-- ���������ڵ�[PHM_MGR_TYPE_CD]
					   ISNULL(A.CD_OCPT, B.JOB_POSITION_CD) AS JOB_POSITION_CD,									-- �����ڵ�[PHM_JOB_POSTION_CD]
					   ISNULL(A.CD_JOB, B.JOB_CD) AS JOB_CD,												-- �����ڵ�
					   A.TP_CALC_PAY AS PAY_METH_CD,									-- �޿����޹��[PAY_METH_CD]
					   A.TP_CALC_INS AS EMP_CLS_CD,										-- �������[PAY_EMP_CLS_CD]
					   A.CNT_CAL_MONTH AS WORK_MM_PT,									-- ��������
					   A.CNT_CAL_DAY AS WORK_DD_PT,										-- �����ϼ�
					   A.CNT_WORK_DAY AS SUM_MONTH_DAY3,								-- �ټ��ϼ�
					   A.AMT_COMM AS COMM_AMT,											-- ����ӱ�
					   A.AMT_DAY AS DAY_AMT,											-- �ϴ�
					   A.DT_PAY01 AS PAY01_YM,											-- �޿����_01
					   A.DT_PAY02 AS PAY02_YM,											-- �޿����_02
					   A.DT_PAY03 AS PAY03_YM,											-- �޿����_03
					   A.DT_PAY04 AS PAY04_YM,											-- �޿����_04
					   A.DT_PAY05 AS PAY05_YM,											-- �޿����_05
					   A.DT_PAY06 AS PAY06_YM,											-- �޿����_06
					   A.DT_PAY07 AS PAY07_YM,											-- �޿����_07
					   A.DT_PAY08 AS PAY08_YM,											-- �޿����_08
					   A.DT_PAY09 AS PAY09_YM,											-- �޿����_09
					   A.DT_PAY10 AS PAY10_YM,											-- �޿����_10
					   A.DT_PAY11 AS PAY11_YM,											-- �޿����_11
					   A.DT_PAY12 AS PAY12_YM,											-- �޿����_12
					   A.AMT_PAY01 AS PAY01_AMT,										-- �޿��ݾ�_01
					   A.AMT_PAY02 AS PAY02_AMT,										-- �޿��ݾ�_02
					   A.AMT_PAY03 AS PAY03_AMT,										-- �޿��ݾ�_03
					   A.AMT_PAY04 AS PAY04_AMT,										-- �޿��ݾ�_04
					   A.AMT_PAY05 AS PAY05_AMT,										-- �޿��ݾ�_05
					   A.AMT_PAY06 AS PAY06_AMT,										-- �޿��ݾ�_06
					   A.AMT_PAY07 AS PAY07_AMT,										-- �޿��ݾ�_07
					   A.AMT_PAY08 AS PAY08_AMT,										-- �޿��ݾ�_08
					   A.AMT_PAY09 AS PAY09_AMT,										-- �޿��ݾ�_09
					   A.AMT_PAY10 AS PAY10_AMT,										-- �޿��ݾ�_10
					   A.AMT_PAY11 AS PAY11_AMT,										-- �޿��ݾ�_11
					   A.AMT_PAY12 AS PAY12_AMT,										-- �޿��ݾ�_12
					   A.AMT_PAY_SUM_YEAR AS PAY_MON,									-- �޿��հ�
					   A.AMT_PAY_TOT AS PAY_TOT_AMT,									-- 3�����޿��հ�
					   A.DT_BONUS01 AS BONUS01_YM,										-- �󿩳��_01
					   A.DT_BONUS02 AS BONUS02_YM,										-- �󿩳��_02
					   A.DT_BONUS03 AS BONUS03_YM,										-- �󿩳��_03
					   A.DT_BONUS04 AS BONUS04_YM,										-- �󿩳��_04
					   A.DT_BONUS05 AS BONUS05_YM,										-- �󿩳��_05
					   A.DT_BONUS06 AS BONUS06_YM,										-- �󿩳��_06
					   A.DT_BONUS07 AS BONUS07_YM,										-- �󿩳��_07
					   A.DT_BONUS08 AS BONUS08_YM,										-- �󿩳��_08
					   A.DT_BONUS09 AS BONUS09_YM,										-- �󿩳��_09
					   A.DT_BONUS10 AS BONUS10_YM,										-- �󿩳��_10
					   A.DT_BONUS11 AS BONUS11_YM,										-- �󿩳��_11
					   A.DT_BONUS12 AS BONUS12_YM,										-- �󿩳��_12
					   A.AMT_BONUS01 AS BONUS01_AMT,									-- �󿩱ݾ�_01
					   A.AMT_BONUS02 AS BONUS02_AMT,									-- �󿩱ݾ�_02
					   A.AMT_BONUS03 AS BONUS03_AMT,									-- �󿩱ݾ�_03
					   A.AMT_BONUS04 AS BONUS04_AMT,									-- �󿩱ݾ�_04
					   A.AMT_BONUS05 AS BONUS05_AMT,									-- �󿩱ݾ�_05
					   A.AMT_BONUS06 AS BONUS06_AMT,									-- �󿩱ݾ�_06
					   A.AMT_BONUS07 AS BONUS07_AMT,									-- �󿩱ݾ�_07
					   A.AMT_BONUS08 AS BONUS08_AMT,									-- �󿩱ݾ�_08
					   A.AMT_BONUS09 AS BONUS09_AMT,									-- �󿩱ݾ�_09
					   A.AMT_BONUS10 AS BONUS10_AMT,									-- �󿩱ݾ�_10
					   A.AMT_BONUS11 AS BONUS11_AMT,									-- �󿩱ݾ�_11
					   A.AMT_BONUS12 AS BONUS12_AMT,									-- �󿩱ݾ�_12
					   A.AMT_BONUS_MONTH3 AS BONUS_TOT_AMT,								-- 3�����޿��հ�
					   A.CNT_YEAR_REQ AS CNT_YEAR_REQ,									-- �����߻��ϼ�
					   A.CNT_YEAR_USE AS CNT_YEAR_USE,									-- ��������ϼ�
					   A.CNT_YEAR AS CNT_YEAR,											-- ���������ϼ�
					   A.AMT_YEARMONTH_TOT3 AS DAY_TOT_AMT,								-- 3���� ����������
					   A.AMT_MONTH_PAY3 AS PAY_SUM_AMT,									-- 3���� ���ӱ�
					   A.AMT_COMM_PAY3 AS PAY_COMM_AMT,									-- 3���� ����ӱ�
					   A.AMT_DAY_PAY_M AS AVG_PAY_AMT_M,								-- �� ����ӱ�(������ӱ� / 12)
					   A.AMT_DAY_PAY_D AS AVG_PAY_AMT_D,								-- �� ����ӱ�
					   A.AMT_RETR_PAY_Y AS AMT_RETR_PAY_Y,								-- �� ������
					   A.AMT_RETR_PAY_M AS AMT_RETR_PAY_M,								-- �� ������
					   A.AMT_RETR_PAY_D AS AMT_RETR_PAY_D,								-- �� ������
					   A.RATE_ADD AS TAX_RATE_ADD,										-- ������(�ӿ����)
					   A.AMT_N_PAY_TOT AS C_02_SUM,										-- ��(��)������
					   A.AMT_O_PAY2_3 AS B1_RERIRE_INSU_AMT,							-- ��(��)���������
					   A.CNT_N_DUTYMONTH AS BC_WORK_MM,									-- �ټӰ�����
					   A.CNT_N_ADDMONTH AS BC_WORK_ADD_MM,								-- ��������
					   A.CNT_N_MONTH AS BC_WORK_TOT_MM,									-- ��������(�ټӰ�����+��������)
					   A.CNT_O_DOUBMONTH AS MID_DUP_MM,									-- �߰����� �ߺ�����
					   A.AMT_ADD_GONGJE AS R04_ADD,										-- ��������
					   A.AMT_CAL_TAX AS R06_SUM,										-- ���⼼�� �հ�
					   A.AMT_TAX_GONG AS R06_2009,										-- ���⼼��_2009�� �ѽ�����
					   A.NM_ETC01_SUB_TIT AS ETC01_SUB_NM,								-- ��Ÿ����01 ����
					   A.NM_ETC02_SUB_TIT AS ETC02_SUB_NM,								-- ��Ÿ����02 ����
					   A.NM_ETC03_SUB_TIT AS ETC03_SUB_NM,								-- ��Ÿ����03 ����
					   A.NM_ETC04_SUB_TIT AS ETC04_SUB_NM,								-- ��Ÿ����04 ����
					   A.NM_ETC05_SUB_TIT AS ETC05_SUB_NM,								-- ��Ÿ����05 ����
					   A.NM_ETC06_SUB_TIT AS ETC06_SUB_NM,								-- ��Ÿ����06 ����
					   A.NM_ETC07_SUB_TIT AS ETC07_SUB_NM,								-- ��Ÿ����07 ����
					   A.NM_ETC08_SUB_TIT AS ETC08_SUB_NM,								-- ��Ÿ����08 ����
					   A.NM_ETC09_SUB_TIT AS ETC09_SUB_NM,								-- ��Ÿ����09 ����
					   A.NM_ETC10_SUB_TIT AS ETC10_SUB_NM,								-- ��Ÿ����10 ����
					   A.NM_ETC11_SUB_TIT AS ETC11_SUB_NM,								-- ��Ÿ����11 ����
					   A.NM_ETC12_SUB_TIT AS ETC12_SUB_NM,								-- ��Ÿ����12 ����
					   A.NM_ETC13_SUB_TIT AS ETC13_SUB_NM,								-- ��Ÿ����13 ����
					   A.AMT_ETC01_SUB AS ETC01_SUB_AMT,								-- ��Ÿ����01 �ݾ�
					   A.AMT_ETC02_SUB AS ETC02_SUB_AMT,								-- ��Ÿ����02 �ݾ�
					   A.AMT_ETC03_SUB AS ETC03_SUB_AMT,								-- ��Ÿ����03 �ݾ�
					   A.AMT_ETC04_SUB AS ETC04_SUB_AMT,								-- ��Ÿ����04 �ݾ�
					   A.AMT_ETC05_SUB AS ETC05_SUB_AMT,								-- ��Ÿ����05 �ݾ�
					   A.AMT_ETC06_SUB AS ETC06_SUB_AMT,								-- ��Ÿ����06 �ݾ�
					   A.AMT_ETC07_SUB AS ETC07_SUB_AMT,								-- ��Ÿ����07 �ݾ�
					   A.AMT_ETC08_SUB AS ETC08_SUB_AMT,								-- ��Ÿ����08 �ݾ�
					   A.AMT_ETC09_SUB AS ETC09_SUB_AMT,								-- ��Ÿ����09 �ݾ�
					   A.AMT_ETC10_SUB AS ETC10_SUB_AMT,								-- ��Ÿ����10 �ݾ�
					   A.AMT_ETC11_SUB AS ETC11_SUB_AMT,								-- ��Ÿ����11 �ݾ�
					   A.AMT_ETC12_SUB AS ETC12_SUB_AMT,								-- ��Ÿ����12 �ݾ�
					   A.AMT_ETC13_SUB AS ETC13_SUB_AMT,								-- ��Ÿ����13 �ݾ�
					   A.NM_ETC01_PROV_TIT AS ETC01_PAY_NM,								-- ��Ÿ����01 ����
					   A.NM_ETC02_PROV_TIT AS ETC02_PAY_NM,								-- ��Ÿ����02 ����
					   A.NM_ETC03_PROV_TIT AS ETC03_PAY_NM,								-- ��Ÿ����03 ����
					   A.NM_ETC04_PROV_TIT AS ETC04_PAY_NM,								-- ��Ÿ����04 ����
					   A.NM_ETC05_PROV_TIT AS ETC05_PAY_NM,								-- ��Ÿ����05 ����
					   A.NM_ETC06_PROV_TIT AS ETC06_PAY_NM,								-- ��Ÿ����06 ����
					   A.NM_ETC07_PROV_TIT AS ETC07_PAY_NM,								-- ��Ÿ����07 ����
					   A.NM_ETC08_PROV_TIT AS ETC08_PAY_NM,								-- ��Ÿ����08 ����
					   A.NM_ETC09_PROV_TIT AS ETC09_PAY_NM,								-- ��Ÿ����09 ����
					   A.NM_ETC10_PROV_TIT AS ETC10_PAY_NM,								-- ��Ÿ����10 ����
					   A.AMT_ETC01_PROV AS ETC01_PAY_AMT,								-- ��Ÿ����01 �ݾ�
					   A.AMT_ETC02_PROV AS ETC02_PAY_AMT,								-- ��Ÿ����02 �ݾ�
					   A.AMT_ETC03_PROV AS ETC03_PAY_AMT,								-- ��Ÿ����03 �ݾ�
					   A.AMT_ETC04_PROV AS ETC04_PAY_AMT,								-- ��Ÿ����04 �ݾ�
					   A.AMT_ETC05_PROV AS ETC05_PAY_AMT,								-- ��Ÿ����05 �ݾ�
					   A.AMT_ETC06_PROV AS ETC06_PAY_AMT,								-- ��Ÿ����06 �ݾ�
					   A.AMT_ETC07_PROV AS ETC07_PAY_AMT,								-- ��Ÿ����07 �ݾ�
					   A.AMT_ETC08_PROV AS ETC08_PAY_AMT,								-- ��Ÿ����08 �ݾ�
					   A.AMT_ETC09_PROV AS ETC09_PAY_AMT,								-- ��Ÿ����09 �ݾ�
					   A.AMT_ETC10_PROV AS ETC10_PAY_AMT,								-- ��Ÿ����10 �ݾ�
					   A.AMT_REAL_PAY_1 AS COMM_REAL_AMT,								-- ������޾�
					   A.AMT_PENSION_TOT AS PENSION_TOT,								-- ��(��)�Ѽ��ɾ�
					   A.AMT_PENSION_WONRI AS PENSION_WONRI,							-- ��(��)�������հ��
					   A.AMT_PENSION_RESERVE AS PENSION_RESERVE,						-- ��(��)����������(�ҵ��ں��Ծ�)
					   A.AMT_PENSION_GONGJE AS PENSION_GONGJE,							-- ��(��)�������ݼҵ������
					   A.AMT_PENSION_CASH AS PENSION_CASH,								-- ��(��)���������Ͻñ�
					   A.AMT_PENSION_REAL AS PENSION_REAL,								-- ��(��)21)���������Ͻñ����޿����
					   A.YM_REGISTER AS SEND_YM,										-- �Ű�ͼӳ��
					   A.YN_REGISTER AS SEND_YN,										-- �Ű���
					   A.YN_AUTO AS AUTO_YN,											-- �ڵ��а� ����
					   dbo.XF_TO_DATE(A.DT_AUTO, 'YYYYMMDD') AS AUTO_YMD,				-- �ڵ��а� �̰�����
					   A.NO_AUTO AS AUTO_NO,											-- �ڵ��а� �Ϸù�ȣ
					   dbo.XF_TO_DATE(A.DT_REC, 'YYYYMMDD') AS REC_YMD,					-- ��������
					   A.FG_CALCU AS CALCU_TPYE,										-- ��걸��
					   A.CD_PAYGP AS PAY_GROUP,											-- �޿��׷�
					   A.AMT_O_PENSION_TOT AS B_PENSION_TOT,							-- ��(��)�Ѽ��ɾ�
					   A.AMT_O_PENSION_WONRI AS B_PENSION_WONRI,						-- ��(��)�������հ��
					   A.AMT_O_PENSION_RESERVE AS B_PENSION_RESERVE,					-- ��(��)����������(�ҵ��ں��Ծ�)
					   A.AMT_O_PENSION_GONGJE AS B_PENSION_GONGJE,						-- ��(��)�������ݼҵ������
					   A.AMT_O_PENSION_CASH AS B_PENSION_CASH,							-- ��(��)���������Ͻñ�
					   A.AMT_O_PENSION_REAL AS B_PENSION_REAL,							-- ��(��)21)���������Ͻñ����޿����
					   A.ONE_AMT_TOT AS TRANS_TOT_AMT,									-- ���Ͻñ�
					   A.AMT_NOW_PENSION_TOT AS TRANS_NOW_AMT,							-- ���ɰ��������޿���
					   A.AMT_TRANS_SUDK_GONG AS TRANS_SUDK_AMT,							-- ȯ�������ҵ����
					   A.AMT_RETIRE_PAY AS TRANS_RETR_AMT,								-- ȯ�������ҵ����ǥ��
					   A.AMT_TRANS_AVG_PAY_BASE AS TRANS_AVG_PAY,						-- ȯ�꿬��հ���ǥ��
					   A.AMT_TRANS_AVG_PAY_TAX AS TRANS_AVG_TAX,						-- ȯ�꿬��ջ��⼼��
					   A.AMT_Y_BASE_TAX_2013 AS R04_2013_5,								-- 2013�� ���� 5��ȯ�����ǥ��
					   A.AMT_Y_CAL_TAX_2013_DIV AS R05_2013_5,							-- ����ջ��⼼��
					   A.DT_RETPENSION_F AS RETPESION_YMD							-- ���Ա��ش�Ⱓ(������)
				  FROM [DWEHRDEV].DBO.H_RETIRE_DETAIL A
				INNER JOIN PHM_EMP B (NOLOCK)
					ON @t_company_cd = B.COMPANY_CD
				   AND A.NO_PERSON = B.EMP_NO
				WHERE A.CD_COMPANY = @s_company_cd
				  AND A.DT_BASE = @dt_base
				  AND A.FG_RETR = @fg_retr
				  AND A.NO_PERSON = @no_person
				  AND A.DT_RETR = @dt_retr
				  -- Data ����
			   AND (ISNULL(A.DT_RETR, '') <> '')
			   AND A.DT_BASE = A.DT_RETR
			   AND A.DT_BASE NOT IN ('2011231', '20091232')
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================

				if @@ROWCOUNT > 0 
					begin
						-- *** �����޽��� �α׿� ���� ***
						-- *** �����޽��� �α׿� ���� ***
						set @n_cnt_success = @n_cnt_success + 1 -- �����Ǽ�
					end
				else
					begin
						-- *** �α׿� ���� �޽��� ���� ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',dt_base=' + ISNULL(CONVERT(nvarchar(100), @dt_base),'NULL')
							  + ',fg_retr=' + ISNULL(CONVERT(nvarchar(100), @fg_retr),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',dt_retr=' + ISNULL(CONVERT(nvarchar(100), @dt_retr),'NULL')
							  + ',emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
						set @v_err_msg = '���õ� Record�� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
					end
			END TRY
			BEGIN CATCH
				-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',dt_base=' + ISNULL(CONVERT(nvarchar(100), @dt_base),'NULL')
							  + ',fg_retr=' + ISNULL(CONVERT(nvarchar(100), @fg_retr),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',dt_retr=' + ISNULL(CONVERT(nvarchar(100), @dt_retr),'NULL')
							  + ',emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')

						set @v_err_msg = ERROR_MESSAGE()
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
	PRINT 'CNT_PAY_WORK_ID = ' + CONVERT(varchar(100), @n_log_h_id)
	RETURN @n_log_h_id
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �޿����ڰ���
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_PAY_YMD_SAP_PAY
      @an_log_h_id		NUMERIC(20)      -- �α�H�ڵ�
    , @av_company_cd	NVARCHAR(10)    -- ȸ���ڵ�
	, @av_sap_kind1		nvarchar(10)	-- ����1
	, @av_sap_kind2		nvarchar(10)	-- ����2
	, @ad_dt_prov		date			-- �޿�������
	, @cd_paygp			nvarchar(10)	-- �޿��׷�
	, @ad_dt_update		datetime	-- ������
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
		  -- ��Ÿ
		  , @pay_ymd_id numeric -- �޿�����ID
		  , @pay_type_cd	nvarchar(10) -- �޿���������
		  , @pay_type_sys_cd nvarchar(10) -- �޿���������(�ý���)
		  , @v_err_message	nvarchar(100)

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�޿����ڰ���'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@av_sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind1),'NULL')
				+ ',@av_sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind2),'NULL')
				+ ',@av_dt_prov=' + ISNULL(CONVERT(nvarchar(100), @ad_dt_prov),'NULL')
				+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
	set @v_s_table = 'CNV_PAY_TYPE_SAP'   -- As-Is Table
	set @v_t_table = 'PAY_PAY_YMD' -- To-Be Table
	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @n_log_h_id = @an_log_h_id
	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	-- =============================================
	--   ȸ�纰�� �޿������������ϱ� 222222222
	-- =============================================
	--CREATE INDEX CNV_PAY_TYPE_SAP_01_IX01 ON CNV_PAY_TYPE_SAP_01 (DT_PROV, CD_PAYGP, SAP_KIND1, SAP_KIND2)
	SELECT @pay_type_cd = CASE WHEN PAY_TYPE_CD = '' THEN NULL ELSE PAY_TYPE_CD END
	     , @pay_type_sys_cd = SYS_CD
	  FROM CNV_PAY_TYPE_SAP_01 A (NOLOCK)
	 WHERE CD_PAYGP = @cd_paygp
	   AND SAP_KIND1 = @av_sap_kind1
	   AND SAP_KIND2 = @av_sap_kind2
	   AND DT_PROV = @ad_dt_prov

	IF @@ROWCOUNT < 1
		BEGIN
				BEGIN
					set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
							+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
							+ ',@av_sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind1),'NULL')
							+ ',@av_sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind2),'NULL')
							+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @ad_dt_prov),'NULL')
					set @v_err_msg = @v_proc_nm + ' ' + '�޿����������� ���� �� �����ϴ�.(CNV_PAY_TYPE_SAP)'
			
					EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
					RETURN
				END
		END
	-------------------------
	-- �޿����ڰ� �ִ���
	-------------------------
	SELECT @pay_ymd_id = PAY_YMD_ID
	  FROM PAY_PAY_YMD WITH (NOLOCK)
	 WHERE COMPANY_CD = @av_company_cd
	   AND PAY_YMD =  @ad_dt_prov
	   AND PAY_TYPE_CD = @pay_type_cd
	   AND NOTE = 'FnB(SAP-PAY)'
	IF @@ROWCOUNT < 1
		SET @pay_ymd_id = 0
	--PRINT 'DHK:' + ISNULL(@alter_pay_type_cd,'') + ':' + ISNULL(@pay_type_cd,'')
	IF @pay_type_cd is not NULL AND @pay_ymd_id = 0
		BEGIN
			select @pay_ymd_id = NEXT VALUE FOR S_PAY_SEQUENCE
			begin try
				INSERT INTO PAY_PAY_YMD(
					PAY_YMD_ID, --	�޿�����ID
					COMPANY_CD, --	�λ翵��
					PAY_YMD, --	�޿�����
					GIVE_YMD, --	��������
					PAY_TYPE_CD, --	�޿���������[PAY_TYPE_CD]
					PAY_YM, --	�޿�������
					TAX_YM, -- �����Ű����
					STD_YMD, --	���������
					STA_YMD, --	�����Ⱓ(From)
					END_YMD, --	�����Ⱓ(to)
					RETRO_YN, --	�ұ޴�󿩺�
					TAX_YN, --	���ݰ�꿩��
					EMI_YN, --	���뺸���꿩��
					ACCOUNT_TYPE_CD, --	��������[PAY_ACCOUNT_TYPE_CD]
					PRINT_TITLE, --	��¸�Ī
					CLOSE_YN, --	��������
					NOTICE, --	�޿���������
					SLIP_DATE, --	��ǥ��������
					RETRO_PAY_YMD_ID, --	�ӱ��λ���޿�ID
					PAY_YN, --	���޿���
					NOTE, --	���
					MOD_USER_ID, --	������
					MOD_DATE, --	�����Ͻ�
					TZ_CD, --	Ÿ�����ڵ�
					TZ_DATE --	Ÿ�����Ͻ�
					)
				SELECT 
					@pay_ymd_id	PAY_YMD_ID, --	�޿�����ID
					@av_company_cd	COMPANY_CD, --	�λ翵��
					@ad_dt_prov	PAY_YMD, --	�޿�����
					@ad_dt_prov	GIVE_YMD, --	��������
					@pay_type_cd	PAY_TYPE_CD, --	�޿���������[PAY_TYPE_CD]
					FORMAT(@ad_dt_prov,'yyyyMM')	PAY_YM, --	�޿�������
					FORMAT(@ad_dt_prov,'yyyyMM')  TAX_YM, -- ���ݽŰ����
					@ad_dt_prov	STD_YMD, --	���������
					FORMAT(@aD_dt_prov, 'yyyyMM') + '01'	STA_YMD, --	�����Ⱓ(From)
					dbo.XF_LAST_DAY(@ad_dt_prov)	END_YMD, --	�����Ⱓ(to)
					case when @pay_type_sys_cd in ('001') then 'Y' else 'N' end	RETRO_YN, --	�ұ޴�󿩺�
					'Y'	TAX_YN, --	���ݰ�꿩��
					'Y'	EMI_YN, --	���뺸���꿩��
					'01'	ACCOUNT_TYPE_CD, --	��������[PAY_ACCOUNT_TYPE_CD] �޿�����
					FORMAT(@ad_dt_prov,'yyyyMM') + dbo.F_FRM_CODE_NM( @av_company_cd, 'KO', 'PAY_TYPE_CD', @pay_type_cd, dbo.XF_SYSDATE(0), '1')	PRINT_TITLE, --	��¸�Ī
					'Y'	CLOSE_YN, --	��������
					--'N'	CLOSE_YN, --	�������� [�ӽ÷� ����]
					NULL	NOTICE, --	�޿���������
					NULL	SLIP_DATE, --	��ǥ��������
					NULL	RETRO_PAY_YMD_ID, --	�ӱ��λ���޿�ID
					'Y'	PAY_YN, --	���޿���
					'FnB(SAP-PAY)'	NOTE, --	���
						0 AS MOD_USER_ID
					, ISNULL(@ad_dt_update, '1900-01-01')
					, 'KST'
					, ISNULL(@ad_dt_update, '1900-01-01')
				exec dbo.P_PAY_CLOSE_CREATE @pay_ymd_id, 0, '', '' -- ������ �����Ⱓ����
			end Try
				
			BEGIN CATCH
				print 'Error' + Error_message()
				-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
								+ ',@av_sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind1),'NULL')
								+ ',@av_sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind2),'NULL')
								+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @ad_dt_prov),'NULL')
								+ ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
								+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
						set @v_err_msg = @v_proc_nm + ' ' + ERROR_MESSAGE()
						
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
						set @pay_ymd_id = 0
				-- *** �α׿� ���� �޽��� ���� ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- ���аǼ�
			END CATCH
		END
	RETURN @pay_ymd_id
END
GO
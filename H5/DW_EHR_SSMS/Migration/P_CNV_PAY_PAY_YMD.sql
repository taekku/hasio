SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �޿����ڰ���
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_PAY_YMD
      @an_log_h_id		NUMERIC(20)      -- �α�H�ڵ�
    , @av_company_cd	NVARCHAR(10)    -- ȸ���ڵ�
	, @av_ym_pay		nvarchar(10)	-- �޿����
	, @av_fg_supp		nvarchar(10)	-- �޿�����
	, @av_dt_prov		nvarchar(10)	-- �޿�������
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
		  , @cd_company		nvarchar(20) -- ȸ���ڵ�
		  , @ym_pay			nvarchar(10)
		  , @fg_supp		nvarchar(10)
		  , @dt_prov		nvarchar(10)
		  , @no_person		nvarchar(10)
		  -- ��Ÿ
		  , @pay_ymd_id numeric -- �޿�����ID
		  , @pay_type_cd	nvarchar(10) -- �޿���������
		  , @alter_pay_type_cd	nvarchar(10) -- ��ü�޿���������
		  , @pay_type_sys_cd nvarchar(10) -- �޿���������(�ý���)
		  , @v_err_message	nvarchar(100)

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�޿����ڰ���'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@av_ym_pay=' + ISNULL(CONVERT(nvarchar(100), @av_ym_pay),'NULL')
				+ ',@av_fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
				+ ',@av_dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
				+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
	set @v_s_table = 'H_MONTH_PAY_BONUS'   -- As-Is Table
	set @v_t_table = 'PAY_PAY_YMD' -- To-Be Table
	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	
	set @fg_supp = @av_fg_supp
	set @n_log_h_id = @an_log_h_id
	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	-- =============================================
	--   ȸ�纰�� �޿������������ϱ�
	-- =============================================
	SELECT @pay_type_cd = CASE WHEN PAY_TYPE_CD = '' THEN NULL ELSE PAY_TYPE_CD END
	     , @pay_type_sys_cd = (SELECT SYS_CD FROM FRM_CODE (NOLOCK) WHERE COMPANY_CD=A.COMPANY_CD AND CD = A.PAY_TYPE_CD AND CD_KIND='PAY_TYPE_CD' AND GETDATE() BETWEEN STA_YMD AND END_YMD)
	  FROM CNV_PAY_TYPE A (NOLOCK)
	 WHERE COMPANY_CD = @av_company_cd
	   AND CD_PAYGP = @cd_paygp
	   AND FG_SUPP = @fg_supp
	--PRINT ISNULL(@pay_type_cd,'NULL') + ':' + ISNULL(@pay_type_sys_cd,'NULL') + ':' + ISNULL(@av_company_cd,'NULL') + ':' + ISNULL(@cd_paygp,'NULL') + ':' + ISNULL(@fg_supp,'NULL')
	IF @@ROWCOUNT < 1
		BEGIN
			set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
					+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
					+ ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
					+ ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
					+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
					+ ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
			set @v_err_msg = @v_proc_nm + ' ' + '�޿����������� ���� �� �����ϴ�.(CNV_PAY_TYPE)'
			
			EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
			RETURN
		END
	-------------------------
	-- ��ü���������ڵ尡 �ִ���
	-------------------------
	SELECT @alter_pay_type_cd = CASE WHEN ALTER_PAY_TYPE_CD > '' THEN ALTER_PAY_TYPE_CD ELSE NULL END
	  FROM CNV_PAY_YMD
	 WHERE CD_COMPANY = @av_company_cd
	   AND YM_PAY = @av_ym_pay
	   AND FG_SUPP = @av_fg_supp
	   AND DT_PROV = @av_dt_prov
	   AND PAY_TYPE_CD = @pay_type_cd
	IF @@ROWCOUNT < 1
		SET @alter_pay_type_cd = NULL
	IF @alter_pay_type_cd > ''
	BEGIN
						set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
							  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @av_ym_pay),'NULL')
							  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
							  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
							  + ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
							  + ',@alter_pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @alter_pay_type_cd),'NULL')
							  + ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
		set @v_err_message = '��ü�����ڵ���:' + @alter_pay_type_cd
		EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, '999', @v_err_message
	END
	-------------------------
	-- �޿����ڰ� �ִ���
	-------------------------
	SELECT @pay_ymd_id = PAY_YMD_ID
	  FROM PAY_PAY_YMD WITH (NOLOCK)
	 WHERE COMPANY_CD = @av_company_cd
	   AND PAY_YM = @av_ym_pay
	   AND PAY_YMD =  @av_dt_prov
	   AND PAY_TYPE_CD = ISNULL(@alter_pay_type_cd, @pay_type_cd)
	IF @@ROWCOUNT < 1
		SET @pay_ymd_id = 0

	IF ISNULL(@alter_pay_type_cd, @pay_type_cd) is not NULL AND @pay_ymd_id = 0
		BEGIN
			--print 'insert:' + @av_company_cd + @av_ym_pay + @av_dt_prov + @pay_type_cd
			select @pay_ymd_id = NEXT VALUE FOR S_PAY_SEQUENCE
			begin try
				INSERT INTO PAY_PAY_YMD(
					PAY_YMD_ID, --	�޿�����ID
					COMPANY_CD, --	�λ翵��
					PAY_YMD, --	�޿�����
					GIVE_YMD, --	��������
					PAY_TYPE_CD, --	�޿���������[PAY_TYPE_CD]
					PAY_YM, --	�޿�������
					TAX_YM, -- �����Ű���
					STD_YMD, --	���������
					STA_YMD, --	�����Ⱓ(From)
					END_YMD, --	�����Ⱓ(to)
					RETRO_YN, --	�ұ޴�󿩺�
					TAX_YN, --	���ݰ�꿩��
					EMI_YN, --	��뺸���꿩��
					ACCOUNT_TYPE_CD, --	��������[PAY_ACCOUNT_TYPE_CD]
					PRINT_TITLE, --	��¸�Ī
					CLOSE_YN, --	��������
					NOTICE, --	�޿�������
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
					@av_dt_prov	PAY_YMD, --	�޿�����
					@av_dt_prov	GIVE_YMD, --	��������
					ISNULL(@alter_pay_type_cd, @pay_type_cd)	PAY_TYPE_CD, --	�޿���������[PAY_TYPE_CD]
					@av_ym_pay	PAY_YM, --	�޿�������
					@av_ym_pay  TAX_YM, -- ���ݽŰ���
					@av_dt_prov	STD_YMD, --	���������
					SUBSTRING(@av_dt_prov, 1, 6) + '01'	STA_YMD, --	�����Ⱓ(From)
					dbo.XF_LAST_DAY(@av_dt_prov)	END_YMD, --	�����Ⱓ(to)
					case when @pay_type_sys_cd = '009' then 'Y' else 'N' end	RETRO_YN, --	�ұ޴�󿩺�
					'Y'	TAX_YN, --	���ݰ�꿩��
					'Y'	EMI_YN, --	��뺸���꿩��
					'01'	ACCOUNT_TYPE_CD, --	��������[PAY_ACCOUNT_TYPE_CD] �޿�����
					@av_ym_pay + dbo.F_FRM_CODE_NM( @av_company_cd, 'KO', 'PAY_TYPE_CD', @pay_type_cd, dbo.XF_SYSDATE(0), '1')	PRINT_TITLE, --	��¸�Ī
					'Y'	CLOSE_YN, --	��������
					--'N'	CLOSE_YN, --	�������� [�ӽ÷� ����]
					NULL	NOTICE, --	�޿�������
					NULL	SLIP_DATE, --	��ǥ��������
					NULL	RETRO_PAY_YMD_ID, --	�ӱ��λ���޿�ID
					'Y'	PAY_YN, --	���޿���
					NULL	NOTE, --	���
						0 AS MOD_USER_ID
					, ISNULL(@ad_dt_update, '1900-01-01')
					, 'KST'
					, ISNULL(@ad_dt_update, '1900-01-01')
				--IF @@ROWCOUNT < 1
				--	BEGIN
				--		set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				--			  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
				--			  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
				--			  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
				--			  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
				--		set @v_err_msg = @v_proc_nm + ' ' + ERROR_MESSAGE()
						
				--		EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
				--	END
				exec dbo.P_PAY_CLOSE_CREATE @pay_ymd_id, 0, '', '' -- ������ �����Ⱓ����
			end Try
				
			BEGIN CATCH
				print 'Error' + Error_message()
				-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
							  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @av_ym_pay),'NULL')
							  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
							  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
							  + ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
							  + ',@alter_pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @alter_pay_type_cd),'NULL')
							  + ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
						set @v_err_msg = @v_proc_nm + ' ' + ERROR_MESSAGE()
						
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
						set @pay_ymd_id = 0
				-- *** �α׿� ���� �޽��� ���� ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- ���аǼ�
			END CATCH
		END
	--ELSE
	--	BEGIN
	--		IF @pay_ymd_id = 0
	--		BEGIN
	--					set @n_err_cod = 999
	--					set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	--						  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @av_ym_pay),'NULL')
	--						  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
	--						  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
	--						  + ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
	--						  + ',@alter_pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @alter_pay_type_cd),'NULL')
	--						  + ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
	--					set @v_err_msg = @v_proc_nm + ' ' + '�޿����ڸ� �˼�����.'
						
	--					EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
	--		END
	--	END
	RETURN @pay_ymd_id
END
GO

USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_CNV_PAY_PAY_YMD]    Script Date: 2020-10-16 ���� 3:03:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �޿����ڰ���
-- =============================================
ALTER   PROCEDURE [dbo].[P_CNV_PAY_PAY_YMD]
      @an_log_h_id		NUMERIC(4)      -- �α�H�ڵ�
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

		  , @pay_ymd_id numeric -- �޿�����ID
		  , @pay_type_cd	nvarchar( 10) -- �޿���������

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�޿����ڰ���'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_log_h_id)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_ym_pay),'NULL')
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
	set @v_s_table = 'H_MONTH_PAY_BONUS'   -- As-Is Table
	set @v_t_table = 'PAY_PAY_YMD' -- To-Be Table
	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	
	set @fg_supp = @av_fg_supp
	set @v_params = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@av_ym_pay=' + ISNULL(CONVERT(nvarchar(100), @av_ym_pay),'NULL')
				+ ',@av_fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
				+ ',@av_dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
				+ ',@@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')

	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	
	-- =============================================
	--   ȸ�纰�� �޿������������ϱ�
	-- =============================================
	IF @av_company_cd in ('I', 'E','C' )
		BEGIN
			-- @cd_paygp[�޿��׷�] �� ��� �������޿�
			select @pay_type_cd = CASE
					when @fg_supp IN ('001','002') then '001' -- ������_����޿�
					when @fg_supp = '004' then '002' -- ������_������
					when @fg_supp = '101' then '003' -- ������_��
					--when @fg_supp = '001' then '004' -- ������_������
					--when @fg_supp = '001' then '005' -- ������_�ӿ�������
					--when @fg_supp = '001' then '006' -- ������_����������
					--when @fg_supp = '001' then '007' -- ������_�������޿�
					--when @fg_supp = '001' then '008' -- ������_��������
					when @fg_supp IN ('S001','S002','S101','SSSS') then '009' -- ������_�ұޱ޿�
					ELSE '002' END -- ��Ÿ�� ��� ������_������??

			select @pay_ymd_id = PAY_YMD_ID
			  from PAY_PAY_YMD
			 WHERE COMPANY_CD = @av_company_cd
			   AND PAY_YM = @av_ym_pay
			   AND PAY_YMD =  @av_dt_prov
			   AND PAY_TYPE_CD = @pay_type_cd
			IF @@ROWCOUNT < 1
				SET @pay_ymd_id = 0

		END
	ELSE IF @av_company_cd = 'F'
		BEGIN
			SELECT @pay_type_cd = NULL
		END
	ELSE
		BEGIN
			SET @pay_type_cd = NULL
		END

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
					@pay_type_cd	PAY_TYPE_CD, --	�޿���������[PAY_TYPE_CD]
					@av_ym_pay	PAY_YM, --	�޿�������
					@av_dt_prov	STD_YMD, --	���������
					SUBSTRING(@av_dt_prov, 1, 6) + '01'	STA_YMD, --	�����Ⱓ(From)
					dbo.XF_LAST_DAY(@av_dt_prov)	END_YMD, --	�����Ⱓ(to)
					case when @pay_type_cd = '009' then 'Y' else 'N' end	RETRO_YN, --	�ұ޴�󿩺�
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
				exec dbo.P_PAY_CLOSE_CREATE @pay_ymd_id, 0, '', '' -- ������ �����Ⱓ����
			end Try
				
			BEGIN CATCH
				print 'Error' + Error_message()
				-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = '@cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = @v_proc_nm + ' ' + ERROR_MESSAGE()
						
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
				-- *** �α׿� ���� �޽��� ���� ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- ���аǼ�
			END CATCH
		END

	RETURN @pay_ymd_id
END

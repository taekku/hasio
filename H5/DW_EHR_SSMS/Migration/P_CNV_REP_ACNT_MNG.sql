SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �����ݰ����з�����
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_REP_ACNT_MNG]
      @an_try_no         NUMERIC(4)       -- �õ�ȸ��
    , @av_company_cd     NVARCHAR(10)     -- ȸ���ڵ�
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
		  , @cd_company   nvarchar(20) -- ȸ���ڵ�
		  , @tp_code			nvarchar(40) -- ����/��������
		  , @cd_item			nvarchar(40) -- �׸񱸺�
		  , @fg_accnt			nvarchar(40) -- ��������
		  -- ��������
		  , @salary_type_cd nvarchar(10) -- �޿������ڵ�
		  , @pay_item_cd	nvarchar(10) -- �޿��׸��ڵ�
		  , @pay_item_type_cd nvarchar(10) -- �޿��׸������ڵ�
			, @cnt_dup      numeric

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�����ݰ����з�����'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_ACCNT_MATRIX_2'   -- As-Is Table
	set @v_t_table = 'REP_ACNT_MNG' -- To-Be Table
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
				 , TP_CODE
				 , CD_ITEM
				 , FG_ACCNT
			  FROM dwehrdev.dbo.H_ACCNT_MATRIX_2
			 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
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
			      INTO @cd_company, @tp_code, @cd_item, @fg_accnt
			-- =============================================
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- �� �Ǽ�Ȯ��
				set @s_company_cd = @cd_company -- AS-IS ȸ���ڵ�
				set @t_company_cd = @cd_company -- TO-BE ȸ���ڵ�
				
				INSERT INTO REP_ACNT_MNG (
						REP_ACNT_MNG_ID, --	�����ݰ�������ID
						COMPANY_CD, --	ȸ���ڵ�
						REP_BILL_TYPE_CD, --	��ǥ����[REP_BILL_TYPE_CD]
						PAY_ACNT_TYPE_CD, --	��������[PAY_ACNT_TYPE_CD]
						DBCR_CD, --	���뱸��[PAY_DBCR_SAP_CD]
						INS_NO_ACNT_CD, --	�����ݰ���(�̰�����)
						INS_NO_REL_CD, --	������(�̰�����)
						INS_DB_ACNT_CD, --	�����ݰ���(DB��)
						INS_DB_REL_CD, --	������(DB��)
						INS_DC_ACNT_CD, --	�����ݰ���(DC��)
						INS_DC_REL_CD, --	���°���(DC��)
						STAX_ACNT_CD, --	�ҵ漼����
						JTAX_ACNT_CD, --	�ֹμ�����
						STA_YMD, --	��������
						END_YMD, --	��������
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	�����Ͻ�
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE  --	Ÿ�����Ͻ�
				       )
				SELECT NEXT VALUE FOR S_REP_SEQUENCE as REP_ACNT_MNG_ID,
						@t_company_cd AS COMPANY_CD,
						A.CD_ITEM AS REP_BILL_TYPE_CD, --	��ǥ����[REP_BILL_TYPE_CD]
						A.FG_ACCNT	PAY_ACNT_TYPE_CD, --	��������[PAY_ACNT_TYPE_CD]
						A.FG_DRCR	DBCR_CD, --	���뱸��[PAY_DBCR_SAP_CD]
						A.CD_ACCNT1	INS_NO_ACNT_CD, --	�����ݰ���(�̰�����)
						A.CD_ACCNT2	INS_NO_REL_CD, --	������(�̰�����)
						A.CD_ACCNT3	INS_DB_ACNT_CD, --	�����ݰ���(DB��)
						A.CD_ACCNT4	INS_DB_REL_CD, --	������(DB��)
						A.CD_ACCNT5	INS_DC_ACNT_CD, --	�����ݰ���(DC��)
						A.CD_ACCNT6	INS_DC_REL_CD, --	���°���(DC��)
						A.CD_ACCNT8	STAX_ACNT_CD, --	�ҵ漼����
						A.CD_ACCNT9	JTAX_ACNT_CD, --	�ֹμ�����
						'19000101' STA_YMD, --	��������
						CASE WHEN YN_USE = 'Y' THEN '29991231' ELSE '19000101' END END_YMD, --	��������
						  REM_COMMENT NOTE -- ���
						, 0 AS MOD_USER_ID
						, ISNULL(DT_UPDATE,'1900-01-01')
						, 'KST'
						, ISNULL(DT_UPDATE,'1900-01-01')
				  FROM dwehrdev.dbo.H_ACCNT_MATRIX_2 A
				 WHERE CD_COMPANY = @s_company_cd
				   AND TP_CODE = @tp_code
					 AND CD_ITEM = @cd_item
					 AND FG_ACCNT = @fg_accnt
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================
				if @@ROWCOUNT > 0 
					begin
						-- *** �����޽��� �α׿� ���� ***
						--set @v_keys = ISNULL(CONVERT(nvarchar(100), @@cd_company),'NULL')
						--      + ',' + ISNULL(CONVERT(nvarchar(100), @cd_accnt),'NULL')
						--set @v_err_msg = '���õ� Record�� �����ϴ�.!'
						--EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �����޽��� �α׿� ���� ***
						set @n_cnt_success = @n_cnt_success + 1 -- �����Ǽ�
					end
				else
					begin
						-- *** �α׿� ���� �޽��� ���� ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',tp_code=' + ISNULL(CONVERT(nvarchar(100), @tp_code),'NULL')
							  + ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
							  + ',fg_accnt=' + ISNULL(CONVERT(nvarchar(100), @fg_accnt),'NULL')
						set @v_err_msg = '���õ� Record�� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
					end
			END TRY
			BEGIN CATCH
				-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						IF @n_err_cod = 2627
							BEGIN
									set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
											+ ',tp_code=' + ISNULL(CONVERT(nvarchar(100), @tp_code),'NULL')
											+ ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
											+ ',fg_accnt=' + ISNULL(CONVERT(nvarchar(100), @fg_accnt),'NULL')
											+ ',pay_item_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_cd),'NULL')
											+ ',pay_item_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_type_cd),'NULL')
									set @v_err_msg = 'pay_item_cd[' + @pay_item_cd + ']�� �����ڵ尡 �ߺ��Դϴ�.'
									EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
									-- *** �α׿� ���� �޽��� ���� ***
									set @n_cnt_failure =  @n_cnt_failure + 1 -- ���аǼ�
							END
						ELSE
							BEGIN
								set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
										+ ',tp_code=' + ISNULL(CONVERT(nvarchar(100), @tp_code),'NULL')
										+ ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
										+ ',fg_accnt=' + ISNULL(CONVERT(nvarchar(100), @fg_accnt),'NULL')
										+ ',pay_item_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_cd),'NULL')
										+ ',pay_item_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_type_cd),'NULL')
								set @v_err_msg = ERROR_MESSAGE()
								EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
								-- *** �α׿� ���� �޽��� ���� ***
								set @n_cnt_failure =  @n_cnt_failure + 1 -- ���аǼ�
							END
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion ���κ���õ¡���������
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PAY_EXP_TAX]
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
			, @no_person		nvarchar(10) -- �����ȣ
		  , @yy_year      nvarchar(10) -- �⵵
			, @ym_pay_fr		nvarchar(10)
		  -- ��������
		  , @emp_id			numeric -- ���ID
		  , @person_id		numeric -- ����ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '���κ���õ¡����'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_INCOME_TAX_PERSON_TABLE'   -- As-Is Table
	set @v_t_table = 'PAY_EXP_TAX' -- To-Be Table
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
				 , NO_PERSON
				 , YY_YEAR
				 , YM_PAY_FR
			  FROM dwehrdev.dbo.H_INCOME_TAX_PERSON_TABLE
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
			      INTO @cd_company, @no_person, @yy_year, @ym_pay_fr
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
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS���� ����� ã�� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE
					END
				
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				INSERT INTO dwehrdev_H5.dbo.PAY_EXP_TAX(
						PAY_EXP_TAX_ID, --	���κ���õ¡����ID
						COMPANY_CD, --	�λ翵��
						EMP_ID, --	���ID
						TAX_RATE, --	¡����
						STA_YM, --	���۳��
						END_YM, --	������
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	�����Ͻ�
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE  --	Ÿ�����Ͻ�
				       )
				SELECT NEXT VALUE FOR S_PAY_SEQUENCE as PAY_EXP_TAX_ID,
						@t_company_cd COMPANY_CD, -- �λ翵��
						@emp_id	EMP_ID, --	���ID
						A.RATE_TAX TAX_RATE, -- ¡����
						A.YM_PAY_FR STA_YM, --	���۳��
						A.YM_PAY_TO END_YM, --	������
						A.REMARK NOTE, --	���
						  0 AS MOD_USER_ID
						, ISNULL(DT_UPDATE,'1900-01-01')
						, 'KST'
						, ISNULL(DT_UPDATE,'1900-01-01')
				  FROM dwehrdev.dbo.H_INCOME_TAX_PERSON_TABLE A
				 WHERE CD_COMPANY = @s_company_cd
				   AND NO_PERSON = @no_person
					 AND YY_YEAR = @yy_year
					 AND YM_PAY_FR = @ym_pay_fr
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
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',yy_year=' + ISNULL(CONVERT(nvarchar(100), @yy_year),'NULL')
							  + ',ym_pay_fr=' + ISNULL(CONVERT(nvarchar(100), @ym_pay_fr),'NULL')
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
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',yy_year=' + ISNULL(CONVERT(nvarchar(100), @yy_year),'NULL')
							  + ',ym_pay_fr=' + ISNULL(CONVERT(nvarchar(100), @ym_pay_fr),'NULL')
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �ڽ�Ʈ�����ڵ�
-- 
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_ORM_COST
      @an_try_no         NUMERIC(4)       -- �õ�ȸ��
    , @av_company_cd     NVARCHAR(10)     -- ȸ���ڵ�
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @s_company_cd nvarchar(10)
	      , @t_company_cd nvarchar(10)
		  -- ��ȯ�۾����
		  , @v_proc_nm		nvarchar(50) -- ���α׷�ID
		  , @v_pgm_title	nvarchar(100) -- ���α׷�Title
		  , @v_params       nvarchar(4000) -- �Ķ����
		  , @n_total_record numeric
		  , @n_cnt_success  numeric
		  , @n_cnt_failure  numeric
		  , @v_s_table      nvarchar(50) -- source table
		  , @v_t_table      nvarchar(50) -- target table
		  , @n_log_h_id		numeric
		  , @v_keys			nvarchar(2000)
		  , @n_err_cod		numeric
		  , @v_err_msg		nvarchar(4000)
		  -- AS-IS Table Key
		  , @cd_company		nvarchar(20) -- ȸ���ڵ�
		  , @cd_cc		nvarchar(40) -- �ڽ�Ʈ�����ڵ�
		  -- ��������
		  , @emp_id			numeric -- ���ID
		  , @person_id		numeric -- ����ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = 'COST���Ͱ���'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'B_COST_CENTER'   -- As-Is Table
	set @v_t_table = 'ORM_COST' -- To-Be Table
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
				 , CD_CC
			  FROM dwehrdev.dbo.B_COST_CENTER
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
			      INTO @cd_company, @cd_cc
			-- =============================================
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- �� �Ǽ�Ȯ��
				set @s_company_cd = @cd_company -- AS-IS ȸ���ڵ�
				set @t_company_cd = @cd_company -- TO-BE ȸ���ڵ�
				
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				INSERT INTO dwehrdev_H5.dbo.ORM_COST(
							  ORM_COST_ID, --	�ڽ�Ʈ���Ͱ���ID
								COMPANY_CD, --	ȸ���ڵ�
								COST_CD, --	�ڽ�Ʈ����
								COST_NM, --	�ڽ�Ʈ���͸�
								COST_ENG_NM, --	�ڽ�Ʈ���Ϳ�����
								PROD_TYPE_CD, --	��������[ORM_PROD_TYPE_CD]
								PROFIT_TYPE_CD, --	���ͱ���[ORM_PROFIT_TYPE_CD]
								PAY_TYPE_CD, --	�޿�����[ORM_PAY_TYPE_CD]
								COST_TYPE, --	����ι�
								ACCT_CD, --	��������
								SUB_COMP_CD, --	����ȸ��
								STA_YMD, --	������
								END_YMD, --	������
								NOTE --	���
							,MOD_USER_ID	-- ������
							,MOD_DATE	-- �����Ͻ�
							,TZ_CD	-- Ÿ�����ڵ�
							,TZ_DATE	-- Ÿ�����Ͻ�
				       )
				SELECT NEXT VALUE FOR S_ORM_SEQUENCE ORM_COST_ID,
							A.CD_COMPANY	COMPANY_CD, --	ȸ���ڵ�
							A.CD_CC	COST_CD, --	�ڽ�Ʈ����
							A.NM_CC	COST_NM, --	�ڽ�Ʈ���͸�
							A.NM_CC	COST_ENG_NM, --	�ڽ�Ʈ���Ϳ�����
							A.FG_COST_CC	PROD_TYPE_CD, --	��������[ORM_PROD_TYPE_CD]
							A.FG_PROFIT_CC	PROFIT_TYPE_CD, --	���ͱ���[ORM_PROFIT_TYPE_CD]
							A.FG_HUMAN_CC	PAY_TYPE_CD, --	�޿�����[ORM_PAY_TYPE_CD]
							A.BIZ_ACCT	COST_TYPE, --	����ι�
							A.FG_ACCT	ACCT_CD, --	��������
							NULL	SUB_COMP_CD, --	����ȸ��
							'19000101'	STA_YMD, --	������
							CASE WHEN A.YN_USE='Y' THEN '29991231' ELSE ISNULL(A.DT_UPDATE,'2019-12-31') END AS END_YMD, --	������
								A.TXT_REMARK	NOTE --	���
					, 0 --MOD_USER_ID	--������
					, ISNULL(A.DT_UPDATE,'1900-01-01') --MOD_DATE	--�����Ͻ�
					, 'KST' TZ_CD	--Ÿ�����ڵ�
					, ISNULL(A.DT_UPDATE,'1900-01-01') -- TZ_DATE	--Ÿ�����Ͻ�
				  FROM dwehrdev.dbo.B_COST_CENTER A
				 WHERE A.CD_COMPANY = @s_company_cd
				   AND A.CD_CC = @cd_cc
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
							  + ',cd_cc=' + ISNULL(CONVERT(nvarchar(100), @cd_cc),'NULL')
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
							  + ',cd_cc=' + ISNULL(CONVERT(nvarchar(100), @cd_cc),'NULL')
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion ���ڱݽ���
-- 
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_SEC_EDU
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
		  , @family_repre		nvarchar(100) -- �ֹι�ȣ
		  , @tp_school		nvarchar(40) -- �б�����
		  , @seq		numeric -- �Ϸù�ȣ
			-- Etc Field
		  , @cd_company		nvarchar(40) -- ȸ��
		  , @no_person		nvarchar(40) -- ���
		  -- ��������
		  , @emp_id			numeric -- ���ID
		  , @person_id		numeric -- ����ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '���ڱ�'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_SCHOOL_EXPENSES_LIST'   -- As-Is Table
	set @v_t_table = 'SEC_EDU' -- To-Be Table
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
		SELECT FAMILY_REPRE
		     , TP_SCHOOL
				 , SEQ
				 , CD_COMPANY
				 , NO_PERSON
			  FROM dwehrdev.dbo.H_SCHOOL_EXPENSES_LIST
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
			      INTO	@family_repre, @tp_school, @seq, @cd_company, @no_person
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
				INSERT INTO dwehrdev_H5.dbo.SEC_EDU(
							 SEC_EDU_ID, --	���ڱݽ�ûID
							 EMP_ID, --	���ID
							 APPL_YMD, --	��û����
							 RECEIPT_YMD, --	��������
							 FAM_REL_CD, --	�����ڰ���
							 FAM_NAME, --	�����ڸ�
							 APPL_AMT, --	��û�ݾ�
							 CONFIRM_AMT, --	�����ݾ�
							 BANK_CD, --	�����ڵ�
							 MEE_ACCOUNT_NO, --	���¹�ȣ
							 SCH_GRD_CD, --	�б�
							 EDU_POS, --	�г�
							 EDU_TERM, --	�б�[SCE_EDU_TERM]
							 MAJOR_NM, --	�а�
							 SCH_NM, --	�б���
							 REGEDU_MON, --	������
							 FEES_MON, --	����ȸ��
							 APPL_ID, --	��û��ID
							 STAT_CD, --	��û�������ڵ�
							 FINAL_APPR_YMD, --	������������
							 APPR_EMP_ID, --	������
							 POS_YN, --	�ӿ�����
							 REQ_NOTE, --	��û����
							 REMARK, --	�ݷ�����
							 ACCOUNT_YMD, --	��ǥ����
							 ACCOUNT_NO, --	��ǥ��ȣ
							 NOTE --	���
							,MOD_USER_ID	-- ������
							,MOD_DATE	-- �����Ͻ�
							,TZ_CD	-- Ÿ�����ڵ�
							,TZ_DATE	-- Ÿ�����Ͻ�
				       )
				SELECT NEXT VALUE FOR S_SEC_SEQUENCE SEC_EDU_ID, --	���ڱݽ�ûID
							@emp_id EMP_ID, --	���ID
							A.DT_INSERT APPL_YMD, --	��û����
							NULL RECEIPT_YMD, --	��������
							'004' FAM_REL_CD, --	�����ڰ���
							A.NM_FAMLY FAM_NAME, --	�����ڸ�
							A.AMT_PAYMENT APPL_AMT, --	��û�ݾ�
							A.AMT_CONFIRM CONFIRM_AMT, --	�����ݾ�
							NULL BANK_CD, --	�����ڵ�
							NULL MEE_ACCOUNT_NO, --	���¹�ȣ
							A.TP_SCHOOL SCH_GRD_CD, --	�б�
							A.TP_YEAR EDU_POS, --	�г�
							A.TP_TERM EDU_TERM, --	�б�[SCE_EDU_TERM]
							A.NM_MAJOR MAJOR_NM, --	�а�
							A.NM_SCHOOL SCH_NM, --	�б���
							0 REGEDU_MON, --	������
							0 FEES_MON, --	����ȸ��
							0 APPL_ID, --	��û��ID
							CASE WHEN A.YN_PAYMENT='Y' THEN '132' ELSE '131' END STAT_CD, --	��û�������ڵ� 132:����Ϸ�, 131:�ݷ�
							A.DT_PAYMENT  FINAL_APPR_YMD, --	������������
							NULL APPR_EMP_ID, --	������
							NULL POS_YN, --	�ӿ�����
							NULL REQ_NOTE, --	��û����
							NULL REMARK, --	�ݷ�����
							NULL ACCOUNT_YMD, --	��ǥ����
							NULL ACCOUNT_NO, --	��ǥ��ȣ
							NULL NOTE --	���
					, 0 --MOD_USER_ID	--������
					, ISNULL(A.DT_UPDATE,'1900-01-01') --MOD_DATE	--�����Ͻ�
					, 'KST' TZ_CD	--Ÿ�����ڵ�
					, ISNULL(A.DT_UPDATE,'1900-01-01') -- TZ_DATE	--Ÿ�����Ͻ�
				  FROM dwehrdev.dbo.H_SCHOOL_EXPENSES_LIST A
				 WHERE A.FAMILY_REPRE = @family_repre
				   AND A.TP_SCHOOL = @tp_school
					 AND A.SEQ = @seq
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
							  + ',' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
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
							  + ',' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
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

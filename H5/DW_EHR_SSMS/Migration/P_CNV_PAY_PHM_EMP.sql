SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �޿�������
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PAY_PHM_EMP]
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
		  , @no_person		nvarchar(40) -- ���
		  -- ��������
		  , @emp_id			numeric -- ���ID
		  , @person_id		numeric -- ����ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�޿�������'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_PAY_MASTER'   -- As-Is Table
	set @v_t_table = 'PAY_PHM_EMP' -- To-Be Table
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
			  FROM dwehrdev.dbo.H_PAY_MASTER
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
			      INTO @cd_company, @no_person
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
				INSERT INTO PAY_PHM_EMP (
							 EMP_ID, -- ���ID
							PERSON_ID, -- ����ID
							COMPANY_CD, -- �λ翵���ڵ�
							EMP_NO, -- ���
							TAX_FAMILY_CNT, -- �ξ簡����
							FAM20_CNT, -- 20�������ڳ��
							FOREIGN_YN, -- �ܱ��ο���
							PEAK_YMD, -- ������������
							FOREJOB_YN, -- ���ܱٷο���
							PROD_YN, -- ����������
							PEAK_YN, -- �ӱ���ũ��󿩺�
							TRBNK_YN, -- ����������󿩺�
							WORK_YN, -- �ټӼ������޿���
							UNION_CD, -- ����������ڵ�[PAY_UNION_CD]
							UNION_FULL_YN, -- �������ӿ���
							UNION_YN, -- ����ȸ�������󿩺�
							PAY_METH_CD, -- �޿����޹���ڵ�[PAY_METH_CD]
							EMP_CLS_CD, -- ��������ڵ�[PAY_EMP_CLS_CD]
							EMAIL_YN, -- E_MAIL�߼ۿ���
							SMS_YN, -- SMS�߼ۿ���
							YEAR_YMD, -- �����������
							RETR_YMD, -- �����ݱ������
							WORK_YMD, -- �ټӱ������
							ADV_YN, -- �������ұݰ�������
							CONT_TIME, -- �����ٷνð�
							PEN_ACCU_AMT, -- ����������
							RET_PROC_YN, -- ��������ϷῩ��
							ULSAN_YN, -- ��꿩��
							INS_TRANS_YN, -- ����������Կ���
							GLS_WORK_CD, -- �����ٹ�����[PAY_GLS_WORK_CD]
							MOD_USER_ID, -- ������
							MOD_DATE, -- �����Ͻ�
							TZ_CD, -- Ÿ�����ڵ�
							TZ_DATE -- Ÿ�����Ͻ�
				       )
				SELECT @emp_id, @person_id, @t_company_cd , @no_person
					 , A.CNT_FAMILY -- �ξ簡����
					 , A.CNT_CHILD FAM20_CNT -- 20�������ڳ��
					 , A.YN_FOREIGN -- �ܱ��ο���
					 , NULL PEAK_YMD -- ������������
					 , A.YN_FOREJOB -- ���ܱٷο���
					 , A.YN_PROD_LABOR -- ����������
					 , 'N' PEAK_YN -- �ӱ���ũ��󿩺�
					 , A.YN_CRE -- ����������󿩺�	
					, 'N' --WORK_YN	--�ټӼ������޿���
					, '' -- TODO -- UNION_CD	--����������ڵ�
					, '' -- UNION_FULL_YN - �������ӿ���
					, A.YN_LABOR_OBJ --UNION_YN	--����ȸ�������󿩺�
					, A.TP_CALC_PAY --PAY_METH_CD	--�޿����޹���ڵ�[PAY_METH_CD]
					, A.TP_CALC_INS --EMP_CLS_CD	--��������ڵ�[PAY_EMP_CLS_CD]
					, A.YN_EMAIL -- EMAIL_YN	--E_MAIL�߼ۿ���
					, A.YN_SMS -- SMS_YN	--SMS�߼ۿ���
					, dbo.XF_TO_DATE(A.DT_YEAR_RECK,'yyyyMMdd') --YEAR_YMD	--�����������
					, dbo.XF_TO_DATE(A.DT_RETR_RECK,'yyyyMMdd') RETR_YMD	--�����ݱ������
					, dbo.XF_TO_DATE(B.DT_LONG_BASE,'yyyyMMdd') -- TODO -- WORK_YMD	--�ټӱ������
					, A.YN_ADVANCE -- ADV_YN	--�������ұݰ�������
					, NULL -- TODO -- CONT_TIME	--�����ٷνð�
					, A.AMT_RETR_ANNU -- PEN_ACCU_AMT	--����������
					, A.YN_RETR_SUPPLY RET_PROC_YN -- ��������ϷῩ��
					, A.YN_ULSAN ULSAN_YN -- ��꿩��
					, NULL INS_TRANS_YN -- ����������Կ���
					, A.CD_DUTY_TYPE GLS_WORK_CD -- �����ٹ�����[PAY_GLS_WORK_CD]
					, 0 --MOD_USER_ID	--������
					, ISNULL(A.DT_INS_UPDATE,'1900-01-01') --MOD_DATE	--�����Ͻ�
					, 'KST' TZ_CD	--Ÿ�����ڵ�
					, ISNULL(A.DT_INS_UPDATE,'1900-01-01') -- TZ_DATE	--Ÿ�����Ͻ�
				  FROM dwehrdev.dbo.H_PAY_MASTER A
				  JOIN dwehrdev.dbo.H_HUMAN B
				    ON A.CD_COMPANY = B.CD_COMPANY
				   AND A.NO_PERSON = B.NO_PERSON
				 WHERE A.CD_COMPANY = @s_company_cd
				   AND A.NO_PERSON = @no_person
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

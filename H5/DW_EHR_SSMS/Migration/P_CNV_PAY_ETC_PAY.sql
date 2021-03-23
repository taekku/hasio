SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �޿���������
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PAY_ETC_PAY]
      @an_try_no         NUMERIC(4)       -- �õ�ȸ��
    , @av_company_cd     NVARCHAR(10)     -- ȸ���ڵ�
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
			, @fg_supp			nvarchar(20)
			, @dt_prov			nvarchar(20)
		  , @no_person		nvarchar(20) -- 
		  , @cd_item		nvarchar(20)
		  -- ��������
		  , @emp_id			numeric -- ���ID
		  , @person_id		numeric -- ����ID
		  , @pay_ymd_id		numeric -- �޿�����
		  , @pay_item_cd	nvarchar(10) -- �޿��׸��ڵ�
		  , @pay_item_type_cd nvarchar(10) -- �޿��׸������ڵ�
			, @ym_pay				nvarchar(10)
			, @cd_paygp			nvarchar(10)
			, @dt_update		nvarchar(10)
	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '���ü�������'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_CHA_SUDANG'   -- As-Is Table
	set @v_t_table = 'PAY_ETC_PAY' -- To-Be Table
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
    DECLARE CNV_CUR CURSOR READ_ONLY
	    FOR SELECT A.CD_COMPANY
				 , A.FG_SUPP
				 , A.DT_PROV
				 , A.NO_PERSON
				 , A.CD_ITEM
			  FROM dwehrdev.dbo.H_CHA_SUDANG A
				JOIN dwehrdev.dbo.H_PAY_ITEM B
				  ON A.CD_COMPANY = B.CD_COMPANY
				 AND A.CD_ITEM = B.CD_ITEM
				 AND B.TP_CODE = '1' -- 1:����, 2:����
			 WHERE A.CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
			   AND SUBSTRING(DT_PROV, 1, 6) BETWEEN @av_fr_month AND @av_to_month
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
				   , @fg_supp
				   , @dt_prov
				   , @no_person
					 , @cd_item
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
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS���� ����� ã�� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE
					END
				-- =======================================================
				--  �޿��׸��ڵ� �����ڵ� ã��
				-- =======================================================
				SELECT @pay_item_cd = BASE_ITEM_CD
				     , @pay_item_type_cd = dbo.F_FRM_UNIT_STD_VALUE ('E', 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
                              NULL, NULL, NULL, NULL, NULL,
                              BASE_ITEM_CD, NULL, NULL, NULL, NULL,
                              getdATE(),
                              'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
							       -- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
                              ) --AS PAY_ITEM_TYPE_CD
				  FROM CNV_PAY_ITEM A
				 WHERE COMPANY_CD = @s_company_cd
				   AND CD_ITEM = @cd_item
				   AND TP_CODE = '1' -- �����׸��ڵ�
				IF @@ROWCOUNT < 1 --OR ISNULL(@pay_item_cd,'') = ''
					BEGIN
						-- *** �α׿� ���� �޽��� ���� ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
							  + ',pay_item_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_cd),'NULL')
							  + ',pay_item_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_type_cd),'NULL')
						set @v_err_msg = 'CNV_PAY_ITEM���� �����ڵ带 ã�� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE;
					END
				IF ISNULL(@pay_item_cd,'') = ''
					BEGIN
						-- *** �α׿� ���� �޽��� ���� ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
							  + ',pay_item_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_cd),'NULL')
							  + ',pay_item_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_type_cd),'NULL')
						set @v_err_msg = 'CNV_PAY_ITEM�� ���ǵ��� ���� �ڵ��Դϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						-- set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ� ( ���аǼ��ΰ�?�н� )
						CONTINUE;
					END
				-- =======================================================
				-- �޿����ھ��
				-- =======================================================
				SELECT @ym_pay = YM_PAY
				     , @cd_paygp = CD_PAYGP
						 , @dt_update = DT_UPDATE
				  FROM dwehrdev.dbo.H_MONTH_PAY_BONUS
				 WHERE CD_COMPANY = @cd_company
				   AND FG_SUPP = @fg_supp
					 --AND YM_PAY = @ym_pay
					 AND DT_PROV = @dt_prov
					 AND NO_PERSON = @no_person
				IF @@ROWCOUNT < 0
					BEGIN
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = '�޿����ڸ� ���� �� �����ϴ�(H_MONTH_PAY_BONUS).!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE;
					END
				EXECUTE @pay_ymd_id = dbo.P_CNV_PAY_PAY_YMD
								   @n_log_h_id
								 , @cd_company
								 , @ym_pay
								 , @fg_supp
								 , @dt_prov
								 , @cd_paygp
								 , @dt_update
				IF ISNULL(@pay_ymd_id,0) = 0
					BEGIN
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = '�޿����ڸ� ���� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE;
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				INSERT INTO PAY_ETC_PAY(
							PAY_ETC_PAY_ID, --	�޿���Ÿ����ID
							PAY_YMD_ID, --	�޿�����ID
							EMP_ID, --	���ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							ALLW_AMT, --	�������ޱݾ�
							TAX_YN, --	���ݿ���
							PAY_YN, --	�޿����뿩��
							CRE_FLAG, --	��������
							REQ_ID, --	�޿��Ƿ�ID
							LOCATION_CD, --	������ڵ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	�����Ͻ�
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE  --	Ÿ�����Ͻ�
				       )
				SELECT NEXT VALUE FOR S_PAY_SEQUENCE as PAY_ETC_PAY_ID,
						  @pay_ymd_id PAY_YMD_ID,
							@emp_id as EMP_ID,
							@pay_item_cd	PAY_ITEM_CD, --	�����׸�
							AMT_ITEM ALLW_AMT, -- �������ޱݾ�
							NULL TAX_YN, --	���ݿ���
							NULL PAY_YN, --	�޿����뿩��
							'INS' CRE_FLAG, --	��������( REQ:�޿��Ƿ�, INS:������ )
							NULL REQ_ID, --	�޿��Ƿ�ID
							NULL LOCATION_CD, --	������ڵ�
					   REM_COMMENT NOTE, -- ���
						 0 AS MOD_USER_ID -- ������
						, ISNULL(DT_UPDATE,'1900-01-01')
						, 'KST'
						, ISNULL(DT_UPDATE,'1900-01-01')
				  FROM dwehrdev.dbo.H_CHA_SUDANG A
				 WHERE CD_COMPANY = @s_company_cd
				   AND FG_SUPP = @fg_supp
				   AND DT_PROV = @dt_prov
				   AND NO_PERSON = @no_person
				   AND CD_ITEM = @cd_item
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
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
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
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
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

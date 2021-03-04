SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �޿����޳���
-- H_MONTH_SUPPLY => PAY_PAYROLL_DETAIL(�����׸�)
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_PAYROLL_DETAIL_SUPPLY
      @an_try_no		NUMERIC(4)      -- �õ�ȸ��
    , @av_company_cd	NVARCHAR(10)    -- ȸ���ڵ�
	, @av_fr_month		NVARCHAR(6)		-- ���۳��
	, @av_to_month		NVARCHAR(6)		-- ������
	, @av_fg_supp		NVARCHAR(2)		-- �޿�����
	, @av_dt_prov		NVARCHAR(08)	-- �޿�������
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
		  , @cd_allow		nvarchar(10)
		  -- ��������
		  , @nm_item		nvarchar(100)
		  , @cd_paygp		nvarchar(10)
		  , @dt_update		datetime
		  , @pay_ymd_id		numeric
		  , @emp_id			numeric -- ���ID
		  , @person_id		numeric -- ����ID
		  , @pay_payroll_id	numeric -- PAYROLL_ID
		  , @bel_pay_type_cd nvarchar(10) -- �޿����������ڵ� - �ͼӿ�[PAY_TYPE_CD]
		  , @bel_pay_ym		nvarchar(06) -- �ͼӿ�
		  , @bel_pay_ymd_id numeric(18) -- �ͼӱ޿�����ID
		  , @salary_type_cd nvarchar(10) -- �޿������ڵ�
		  , @pay_item_cd	nvarchar(10) -- �޿��׸��ڵ�
		  , @pay_item_type_cd nvarchar(10) -- �޿��׸������ڵ�
		  , @bel_org_id		numeric(18) -- �ͼӺμ�ID
		  , @pay_payroll_detail_id	numeric(18) -- �޿����󼼳���ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�޿����޳���'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@av_fr_month=' + ISNULL(CONVERT(nvarchar(100), @av_fr_month),'NULL')
				+ ',@av_to_month=' + ISNULL(CONVERT(nvarchar(100), @av_to_month),'NULL')
				+ ',@av_fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
				+ ',@av_dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
	set @v_s_table = 'H_MONTH_SUPPLY'   -- As-Is Table
	set @v_t_table = 'PAY_PAYROLL_DETAIL' -- To-Be Table
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
				 , YM_PAY
				 , FG_SUPP
				 , DT_PROV
				 , NO_PERSON
				 , CD_ALLOW
				 , DT_UPDATE
			  FROM dwehrdev.dbo.H_MONTH_SUPPLY
			 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
			   AND YM_PAY BETWEEN @av_fr_month AND @av_to_month
			   AND FG_SUPP LIKE ISNULL(@av_fg_supp, '') + '%'
			   AND DT_PROV LIKE ISNULL(@av_dt_prov, '') + '%'
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
				     , @ym_pay
					 , @fg_supp
					 , @dt_prov
					 , @no_person
					 , @cd_allow
					 , @dt_update
			-- =============================================
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- �� �Ǽ�Ȯ��
				set @s_company_cd = @cd_company -- AS-IS ȸ���ڵ�
				set @t_company_cd = @cd_company -- TO-BE ȸ���ڵ�
				SELECT @cd_paygp = CD_PAYGP
				  FROM dwehrdev.dbo.H_MONTH_PAY_BONUS WITH (NOLOCK)
				 WHERE CD_COMPANY = @cd_company
				   AND YM_PAY = @ym_pay
				   AND FG_SUPP = @fg_supp
				   AND DT_PROV = @dt_prov
				   AND NO_PERSON = @no_person
				IF @@ROWCOUNT < 1
					BEGIN
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = 'H_MONTH_PAY_BONUS���� ã���������ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE;
					END
				-- =======================================================
				-- �޿����ھ��
				-- =======================================================
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
						-- EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE;
					END
				-- =======================================================
				--  EMP_ID ã��
				-- =======================================================
				SELECT @emp_id = EMP_ID, @person_id = PERSON_ID
				  FROM PHM_EMP_NO_HIS WITH (NOLOCK)
				 WHERE COMPANY_CD = @cd_company
				   AND EMP_NO = @no_person
				IF @@ROWCOUNT < 1
					BEGIN
						-- *** �α׿� ���� �޽��� ���� ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS���� ����� ã�� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE;
					END
				-- =======================================================
				--  PAY_PAYROLL_IDã��
				-- =======================================================
				select @pay_payroll_id = A.PAY_PAYROLL_ID
				     , @bel_pay_ym = B.PAY_YM
				     , @bel_pay_ymd_id = A.PAY_YMD_ID -- �ͼӱ޿�����
					 , @bel_org_id = A.ORG_ID -- �ͼӺμ�ID
					 , @bel_pay_type_cd = B.PAY_TYPE_CD
					 , @salary_type_cd = A.SALARY_TYPE_CD -- 002	������(���)
				  from PAY_PAYROLL A WITH (NOLOCK)
				  JOIN PAY_PAY_YMD B WITH (NOLOCK)
				    ON A.PAY_YMD_ID = B.PAY_YMD_ID
				 where A.PAY_YMD_ID = @pay_ymd_id
				   AND A.EMP_ID = @emp_id
				IF @@ROWCOUNT < 1
					BEGIN
						-- *** �α׿� ���� �޽��� ���� ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',pay_ymd_id=' + ISNULL(CONVERT(nvarchar(100), @pay_ymd_id),'NULL')
							  + ',emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
						set @v_err_msg = 'PAY_PAYROLL�� ã�� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE;
					END
				-- =======================================================
				--  �޿��׸��ڵ� �����ڵ� ã��
				-- =======================================================
				SELECT @pay_item_cd = ITEM_CD, @nm_item = NM_ITEM
				     , @pay_item_type_cd = dbo.F_FRM_UNIT_STD_VALUE (@t_company_cd, 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
                              NULL, NULL, NULL, NULL, NULL,
                              ITEM_CD, NULL, NULL, NULL, NULL,
                              getdATE(),
                              'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
							       -- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
                              ) --AS PAY_ITEM_TYPE_CD
				  FROM CNV_PAY_ITEM A WITH (NOLOCK)
				 WHERE COMPANY_CD = @s_company_cd
				   AND CD_ITEM = @cd_allow
				   AND TP_CODE = '1' -- �����׸��ڵ�
				IF @@ROWCOUNT < 1 OR ISNULL(@pay_item_cd,'') = '' --OR ISNULL(@pay_item_type_cd, '') = ''
					BEGIN
						-- *** �α׿� ���� �޽��� ���� ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',cd_allow=' + ISNULL(CONVERT(nvarchar(100), @cd_allow),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',pay_ymd_id=' + ISNULL(CONVERT(nvarchar(100), @pay_ymd_id),'NULL')
							  + ',emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
							  + ',cd_allow=' + ISNULL(CONVERT(nvarchar(100), @cd_allow),'NULL')
							  + ',nm_item=' + ISNULL(CONVERT(nvarchar(100), @nm_item),'NULL')
							  + ',pay_item_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_cd),'NULL')
							  + ',pay_item_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_type_cd),'NULL')
						set @v_err_msg = 'CNV_PAY_ITEM���� �����ڵ带 ã�� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE;
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				SELECT @pay_payroll_detail_id = NEXT VALUE FOR S_PAY_SEQUENCE
				BEGIN TRY
				INSERT INTO PAY_PAYROLL_DETAIL(
							PAY_PAYROLL_DETAIL_ID, --	�޿��󼼳���ID
							PAY_PAYROLL_ID, --	�޿�����ID
							BEL_PAY_TYPE_CD, --	�޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
							BEL_PAY_YM, --	�ͼӿ�
							BEL_PAY_YMD_ID, --	�ͼӱ޿�����ID
							SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							BASE_MON, --	���رݾ�
							CAL_MON, --	���ݾ�
							FOREIGN_BASE_MON, --	��ȭ���رݾ�
							FOREIGN_CAL_MON, --	��ȭ���ݾ�
							PAY_ITEM_TYPE_CD, --	�޿��׸�����
							BEL_ORG_ID, --	�ͼӺμ�ID
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	�����Ͻ�
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE  --	Ÿ�����Ͻ�
				       )
					SELECT  @pay_payroll_detail_id	PAY_PAYROLL_DETAIL_ID, --	�޿��󼼳���ID
							@pay_payroll_id	PAY_PAYROLL_ID, --	�޿�����ID
							@bel_pay_type_cd	BEL_PAY_TYPE_CD, --	�޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
							@bel_pay_ym	BEL_PAY_YM, --	�ͼӿ�
							@bel_pay_ymd_id	BEL_PAY_YMD_ID, --	�ͼӱ޿�����ID
							@salary_type_cd	SALARY_TYPE_CD, --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
							@pay_item_cd	PAY_ITEM_CD, --	�޿��׸��ڵ�
							A.AMT_ALLOW_2	BASE_MON, --	���رݾ�
							A.AMT_ALLOW	CAL_MON, --	���ݾ�
							0	FOREIGN_BASE_MON, --	��ȭ���رݾ�
							0	FOREIGN_CAL_MON, --	��ȭ���ݾ�
							@pay_item_type_cd	PAY_ITEM_TYPE_CD, --	�޿��׸�����
							@bel_org_id	BEL_ORG_ID, --	�ͼӺμ�ID
							A.REM_COMMENT	NOTE, --	���
						 0 AS MOD_USER_ID
						, ISNULL(A.DT_UPDATE,'1900-01-01')
						, 'KST'
						, ISNULL(A.DT_UPDATE,'1900-01-01')
				  FROM dwehrdev.dbo.H_MONTH_SUPPLY A WITH (NOLOCK)
				  --JOIN dwehrdev.dbo.H_MONTH_PAY_BONUS B
				  --  ON A.CD_COMPANY = B.CD_COMPANY
				  -- AND A.YM_PAY = B.YM_PAY
				  -- AND A.FG_SUPP = B.FG_SUPP
				  -- AND A.DT_PROV = B.DT_PROV
				  -- AND A.NO_PERSON = B.NO_PERSON
				 WHERE A.CD_COMPANY = @s_company_cd
				   AND A.YM_PAY = @ym_pay
				   AND A.FG_SUPP = @fg_supp
				   AND A.DT_PROV = @dt_prov
				   AND A.NO_PERSON = @no_person
				   AND A.CD_ALLOW = @cd_allow
				END TRY
				BEGIN CATCH
					set @n_err_cod = ERROR_NUMBER()
					IF @n_err_cod = 2627 -- �ߺ�Ű
						BEGIN
							UPDATE A
							   SET BASE_MON = BASE_MON + B.AMT_ALLOW_2
								 , CAL_MON = CAL_MON + B.AMT_ALLOW
							  FROM PAY_PAYROLL_DETAIL A
							  JOIN (SELECT AMT_ALLOW_2, AMT_ALLOW FROM dwehrdev.dbo.H_MONTH_SUPPLY A WITH (NOLOCK)
									 WHERE A.CD_COMPANY = @s_company_cd
									   AND A.YM_PAY = @ym_pay
									   AND A.FG_SUPP = @fg_supp
									   AND A.DT_PROV = @dt_prov
									   AND A.NO_PERSON = @no_person
									   AND A.CD_ALLOW = @cd_allow) B
								ON 1=1
							 WHERE @pay_payroll_id	= PAY_PAYROLL_ID --	�޿�����ID
								AND	@bel_pay_type_cd	= BEL_PAY_TYPE_CD --	�޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
								AND	@bel_pay_ym	= BEL_PAY_YM --	�ͼӿ�
								AND	@bel_pay_ymd_id	= BEL_PAY_YMD_ID --	�ͼӱ޿�����ID
								AND	@salary_type_cd	= SALARY_TYPE_CD --	�޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
								AND	@pay_item_cd	= PAY_ITEM_CD --	�޿��׸��ڵ�
							IF @@ROWCOUNT < 1
								begin
									-- *** �α׿� ���� �޽��� ���� ***
									set @v_keys = 'cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
										  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
										  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
										  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
										  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
										  + ',cd_allow=' + ISNULL(CONVERT(nvarchar(100), @cd_allow),'NULL')
									set @v_err_msg = '���õ� Record�� �����ϴ�.!' -- ERROR_MESSAGE()
									EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
									-- *** �α׿� ���� �޽��� ���� ***
									set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
								end
						END
					ELSE
						THROW;
				END CATCH;
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================

				--if @@ROWCOUNT > 0 
					begin
						-- *** �����޽��� �α׿� ���� ***
						--set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
						--      + ',' + ISNULL(CONVERT(nvarchar(100), @cd_accnt),'NULL')
						--set @v_err_msg = '���õ� Record�� �����ϴ�.!'
						--EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �����޽��� �α׿� ���� ***
						set @n_cnt_success = @n_cnt_success + 1 -- �����Ǽ�
					end
				--else
				--	begin
				--		-- *** �α׿� ���� �޽��� ���� ***
				--		set @v_keys = 'cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
				--			  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
				--			  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
				--			  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
				--			  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
				--			  + ',cd_allow=' + ISNULL(CONVERT(nvarchar(100), @cd_allow),'NULL')
				--		set @v_err_msg = '���õ� Record�� �����ϴ�.!' -- ERROR_MESSAGE()
				--		EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
				--		-- *** �α׿� ���� �޽��� ���� ***
				--		set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
				--	end
			END TRY
			BEGIN CATCH
				-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = 'cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',cd_allow=' + ISNULL(CONVERT(nvarchar(100), @cd_allow),'NULL')
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

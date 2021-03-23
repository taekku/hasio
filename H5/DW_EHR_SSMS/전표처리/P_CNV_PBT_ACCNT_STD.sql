SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �����ڵ����(�ο���_����������)
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PBT_ACCNT_STD]
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
		  , @HRTYPE_GBN		nvarchar(20)
		  , @WRTDPT_CD		nvarchar(20)
		  , @TRDTYP_CD		nvarchar(20)
		  , @BILL_GBN		nvarchar(20)
		  , @ACCNT_CD		nvarchar(20)
		  , @PBT_ACCNT_STD_ID	NUMERIC(38,0)

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�ο���_����������'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'PBT_ACCNT_STD'   -- As-Is Table
	set @v_t_table = 'PBT_ACCNT_STD' -- To-Be Table
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
		SELECT COMPANY
				 , HRTYPE_GBN, WRTDPT_CD, TRDTYP_CD, BILL_GBN, ACCNT_CD
			  FROM dwehrdev.dbo.PBT_ACCNT_STD
			 WHERE COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
			   AND BILL_GBN != 'P5110' -- ��ǥ����(�ڵ忡 ���� ��)
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
			      INTO @cd_company, @HRTYPE_GBN, @WRTDPT_CD, @TRDTYP_CD, @BILL_GBN, @ACCNT_CD
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
				SET @PBT_ACCNT_STD_ID = NEXT VALUE FOR S_PBT_SEQUENCE
				INSERT INTO PBT_ACCNT_STD (
						PBT_ACCNT_STD_ID, --	����������ID
						COMPANY_CD, --	�λ翵��
						HRTYPE_GBN, --	��������
						WRTDPT_CD, --	�ۼ��μ�
						TRDTYP_CD, --	�ŷ�����
						BILL_GBN, --	��ǥ����
						ACCNT_CD, --	�����ڵ�
						COST_ACCTCD, --	�������ڵ�
						MGNT_ACCTCD, --	���������ڵ�
						TRDTYP_NM, --	�ŷ�������Ī
						CUST_CD, --	�ŷ�ó�ڵ�
						DEBSER_GBN, --	���뱸��
						SUMMARY, --	�������
						CSTDPAT_CD, --	CSTDPAT_CD
						AGGR_GBN, --	AGGR_GBN
						USE_YN, --	��뿩��
						MOD_USER_ID, --	������
						MOD_DATE, --	�����Ͻ�
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE  --	Ÿ�����Ͻ�
				       )
				SELECT @PBT_ACCNT_STD_ID as PBT_ACCNT_STD_ID
						, @t_company_cd AS COMPANY_CD
						, HRTYPE_GBN, --	��������
						WRTDPT_CD, --	�ۼ��μ�
						TRDTYP_CD, --	�ŷ�����
						BILL_GBN, --	��ǥ����
						ACCNT_CD, --	�����ڵ�
						COST_ACCTCD, --	�������ڵ�
						MGNT_ACCTCD, --	���������ڵ�
						TRDTYP_NM, --	�ŷ�������Ī
						CUST_CD, --	�ŷ�ó�ڵ�
						CASE WHEN DEBSER_GBN = '1' THEN '40' ELSE '50' END, --	���뱸��
						SUMMARY, --	�������
						CSTDPAT_CD, --	CSTDPAT_CD
						AGGR_GBN, --	AGGR_GBN
						USE_YN --	��뿩��
						, 0 AS MOD_USER_ID
						, ISNULL(UPDATE_DT,'1900-01-01')
						, 'KST'
						, ISNULL(UPDATE_DT,'1900-01-01')
				  FROM dwehrdev.dbo.PBT_ACCNT_STD
				 WHERE COMPANY = @s_company_cd
				   AND HRTYPE_GBN = @HRTYPE_GBN --	��������
				   AND WRTDPT_CD = @WRTDPT_CD --	�ۼ��μ�
				   AND TRDTYP_CD = @TRDTYP_CD --	�ŷ�����
				   AND BILL_GBN = @BILL_GBN --	��ǥ����
				   AND ACCNT_CD = @ACCNT_CD --	�����ڵ�
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
							  + ',HRTYPE_GBN=' + ISNULL(CONVERT(nvarchar(100), @HRTYPE_GBN),'NULL')
							  + ',WRTDPT_CD=' + ISNULL(CONVERT(nvarchar(100), @WRTDPT_CD),'NULL')
							  + ',TRDTYP_CD=' + ISNULL(CONVERT(nvarchar(100), @TRDTYP_CD),'NULL')
							  + ',BILL_GBN=' + ISNULL(CONVERT(nvarchar(100), @BILL_GBN),'NULL')
							  + ',ACCNT_CD=' + ISNULL(CONVERT(nvarchar(100), @ACCNT_CD),'NULL')
						set @v_err_msg = '���õ� Record�� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
					end
				-- �ο���_�����׸�
				INSERT INTO PBT_INCITEM(
						PBT_INCITEM_ID, --	�����׸�ID
						PBT_ACCNT_STD_ID, --	����������ID
						ITEM_CD, --	�����׸������ڵ�
						SEQ, --	����
						INCITEM_FR, --	�����׸�����ڵ�
						INCITEM_TO, --	�����׸������ڵ�
						INCITEM, --	�����׸��ڵ�
						MOD_USER_ID, --	������
						MOD_DATE, --	�����Ͻ�
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE  --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PBT_SEQUENCE as PBT_INCITEM_ID,
				        @PBT_ACCNT_STD_ID as PBT_ACCNT_STD_ID,
						ITEM_CD, --	�����׸������ڵ�
						SEQ, --	����
						INCITEM_FR, --	�����׸�����ڵ�
						--CASE WHEN ITEM_CD IN ('G','H') THEN -- �޿��׸� ����(G)/����(H) == ���
						--	INCITEM
						--	ELSE INCITEM_TO END
						INCITEM_TO, --	�����׸������ڵ�
						CASE WHEN ITEM_CD = 'B' THEN
									CASE WHEN INCITEM='H2201' THEN '1'
										 WHEN INCITEM='H2203' THEN '2'
										 WHEN INCITEM='H2202' THEN '4'
										 ELSE INCITEM END
							 WHEN ITEM_CD = 'E' THEN -- ���
									CASE WHEN LEFT(INCITEM,1) > 1 THEN '19' ELSE '20' END + INCITEM
							 WHEN ITEM_CD IN ('G','H') THEN -- �޿��׸� ����(G)/����(H)
									ISNULL((SELECT ITEM_CD
									   FROM CNV_PAY_ITEM
									  WHERE TP_CODE = CASE WHEN A.ITEM_CD='G' THEN '1' ELSE '2' END
									    AND CD_ITEM = A.INCITEM AND COMPANY_CD=@s_company_cd) , A.INCITEM)
							ELSE INCITEM END   --	�����׸��ڵ�
						, 0 AS MOD_USER_ID
						, ISNULL(UPDATE_DT,'1900-01-01')
						, 'KST'
						, ISNULL(UPDATE_DT,'1900-01-01')
				  FROM dwehrdev.dbo.PBT_INCITEM A
				 WHERE COMPANY = @s_company_cd
				   AND HRTYPE_GBN = @HRTYPE_GBN --	��������
				   AND WRTDPT_CD = @WRTDPT_CD --	�ۼ��μ�
				   AND TRDTYP_CD = @TRDTYP_CD --	�ŷ�����
				   AND BILL_GBN = @BILL_GBN --	��ǥ����
				   AND ACCNT_CD = @ACCNT_CD --	�����ڵ�
				   
				-- �ο���_�����׸�
				INSERT INTO PBT_EXCITEM(
						PBT_EXCITEM_ID,--	�����׸�ID
						PBT_ACCNT_STD_ID, --	����������ID
						ITEM_CD, --	�����׸������ڵ�
						SEQ, --	����
						EXCITEM_FR, --	�����׸�����ڵ�
						EXCITEM_TO, --	�����׸������ڵ�
						EXCITEM, --	�����׸��ڵ�
						MOD_USER_ID, --	������
						MOD_DATE, --	�����Ͻ�
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE  --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PBT_SEQUENCE as PBT_INCITEM_ID,
				        @PBT_ACCNT_STD_ID as PBT_ACCNT_STD_ID,
						ITEM_CD, --	�����׸������ڵ�
						SEQ, --	����
						EXCITEM_FR, --	�����׸�����ڵ�
						EXCITEM_TO, --	�����׸������ڵ�
						CASE WHEN ITEM_CD = 'B' THEN -- �������(�ٷ�����)
									CASE WHEN EXCITEM='H2201' THEN '1' -- ������
										 WHEN EXCITEM='H2203' THEN '2' -- ��������
										 WHEN EXCITEM='H2202' THEN '4' -- �İ���
										 ELSE EXCITEM END
							 WHEN ITEM_CD = 'E' THEN -- ���
									CASE WHEN LEFT(EXCITEM,1) > 1 THEN '19' ELSE '20' END + EXCITEM
							 WHEN ITEM_CD IN ('G','H') THEN -- �޿��׸� ����(G)/����(H)
									ISNULL((SELECT ITEM_CD
									   FROM CNV_PAY_ITEM
									  WHERE TP_CODE = CASE WHEN A.ITEM_CD='G' THEN '1' ELSE '2' END
									    AND CD_ITEM = A.EXCITEM AND COMPANY_CD=@s_company_cd) , A.EXCITEM)
							ELSE EXCITEM END EXCITEM --	�����׸��ڵ�
						, 0 AS MOD_USER_ID
						, ISNULL(UPDATE_DT,'1900-01-01')
						, 'KST'
						, ISNULL(UPDATE_DT,'1900-01-01')
				  FROM dwehrdev.dbo.PBT_EXCITEM A
				 WHERE COMPANY = @s_company_cd
				   AND HRTYPE_GBN = @HRTYPE_GBN --	��������
				   AND WRTDPT_CD = @WRTDPT_CD --	�ۼ��μ�
				   AND TRDTYP_CD = @TRDTYP_CD --	�ŷ�����
				   AND BILL_GBN = @BILL_GBN --	��ǥ����
				   AND ACCNT_CD = @ACCNT_CD --	�����ڵ�
			END TRY
			BEGIN CATCH
				-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',HRTYPE_GBN=' + ISNULL(CONVERT(nvarchar(100), @HRTYPE_GBN),'NULL')
							  + ',WRTDPT_CD=' + ISNULL(CONVERT(nvarchar(100), @WRTDPT_CD),'NULL')
							  + ',TRDTYP_CD=' + ISNULL(CONVERT(nvarchar(100), @TRDTYP_CD),'NULL')
							  + ',BILL_GBN=' + ISNULL(CONVERT(nvarchar(100), @BILL_GBN),'NULL')
							  + ',ACCNT_CD=' + ISNULL(CONVERT(nvarchar(100), @ACCNT_CD),'NULL')
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

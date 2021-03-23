SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �޿�����
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PAY_ACCOUNT]
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
		  , @dt_tran      nvarchar(40) -- ����
		  -- ��������
		  , @emp_id			numeric -- ���ID
		  , @person_id		numeric -- ����ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�����ڵ����'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_PAY_BANK_HISTORY'   -- As-Is Table
	set @v_t_table = 'PAY_ACCOUNT' -- To-Be Table
	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================

	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	
	-- Conversion�α����� Header
	EXEC @n_log_h_id = dbo.P_CNV_PAY_LOG_H 0, 'S', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table
	
	
	-- =============================================
	-- �̰��� ���� ������ ����
	-- =============================================
	DELETE FROM PAY_ACCOUNT WHERE EMP_ID IN (SELECT EMP_ID FROM PHM_EMP WHERE COMPANY_CD = @av_company_cd)


	-- =============================================
	--   As-Is Key Column Select
	--   Source Table Key
	-- =============================================
    DECLARE CNV_CUR CURSOR READ_ONLY FOR
		--SELECT CD_COMPANY
		--		 , NO_PERSON
		--		 , DT_TRAN
		--	  FROM dwehrdev.dbo.H_PAY_BANK_HISTORY
		--	 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'

		SELECT A.CD_COMPANY
		     , A.NO_PERSON
		  FROM dwehrdev.dbo.H_HUMAN A
		       LEFT OUTER JOIN dwehrdev.dbo.H_PAY_MASTER B
			           ON A.CD_COMPANY = B.CD_COMPANY
					  AND A.NO_PERSON = B.NO_PERSON
		       LEFT OUTER JOIN dwehrdev.dbo.H_PAY_BANK_HISTORY C
			           ON A.CD_COMPANY = C.CD_COMPANY
					  AND A.NO_PERSON = C.NO_PERSON
		 WHERE A.CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
		   AND (NULLIF(B.NO_BANK_ACCNT1, '') IS NOT NULL OR NULLIF(C.NO_BANK_ACCNT, '') IS NOT NULL)
		 GROUP BY A.CD_COMPANY, A.NO_PERSON

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
			      INTO @cd_company, @no_person  --, @dt_tran
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
				--INSERT INTO PAY_ACCOUNT(
				--		PAY_ACCOUNT_ID, --	�޿�����ID
				--		EMP_ID, --	���ID
				--		ACCOUNT_TYPE_CD, --	��������(PAY_ACCOUNT_TYPE_CD)
				--		BANK_CD, --	�����ڵ�(PAY_BANK_CD)
				--		ACCOUNT_NO, --	���¹�ȣ
				--		HOLDER_NM, --	������
				--		STA_YMD, --	��������
				--		END_YMD, --	��������
				--		NOTE, --	���
				--		MOD_USER_ID, --	������
				--		MOD_DATE, --	�����Ͻ�
				--		TZ_CD, --	Ÿ�����ڵ�
				--		TZ_DATE  --	Ÿ�����Ͻ�
				--       )
				--SELECT NEXT VALUE FOR S_PAY_SEQUENCE as PAY_ACCOUNT_ID,
				--		@emp_id	EMP_ID, --	���ID
				--		'01'	ACCOUNT_TYPE_CD, --	��������(PAY_ACCOUNT_TYPE_CD)
				--		CD_BANK	BANK_CD, --	�����ڵ�(PAY_BANK_CD)
				--		NO_BANK_ACCNT	ACCOUNT_NO, --	���¹�ȣ
				--		NM_DEPOSITOR	HOLDER_NM, --	������
				--		CONVERT(DATETIME, DT_TRAN) as STA_YMD, -- ��������
				--		ISNULL( CONVERT(DATETIME, (SELECT MIN(X.DT_TRAN) FROM dwehrdev.dbo.H_PAY_BANK_HISTORY X
				--		                              WHERE X.CD_COMPANY = A.CD_COMPANY
				--										  AND X.NO_PERSON = A.NO_PERSON
				--									    AND X.DT_TRAN > A.DT_TRAN)) - 1, CONVERT(DATETIME, '29991231')) as END_YMD, -- ��������
				--		  REM_COMMENT
				--		, 0 AS MOD_USER_ID
				--		, ISNULL(DT_UPDATE,'1900-01-01')
				--		, 'KST'
				--		, ISNULL(DT_UPDATE,'1900-01-01')
				--  FROM dwehrdev.dbo.H_PAY_BANK_HISTORY A
				-- WHERE CD_COMPANY = @s_company_cd
				--   AND NO_PERSON = @no_person
				--	 AND DT_TRAN = @dt_tran


				

				-- �޿��⺻�� �ִ� ���������� , ������ �����̷¿� �ִ� ���������� �ֽŰ��·� ���
				INSERT INTO PAY_ACCOUNT(
						PAY_ACCOUNT_ID, --	�޿�����ID
						EMP_ID, --	���ID
						ACCOUNT_TYPE_CD, --	��������(PAY_ACCOUNT_TYPE_CD)
						BANK_CD, --	�����ڵ�(PAY_BANK_CD)
						ACCOUNT_NO, --	���¹�ȣ
						HOLDER_NM, --	������
						STA_YMD, --	��������
						END_YMD, --	��������
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	�����Ͻ�
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE  --	Ÿ�����Ͻ�
				       )
						SELECT NEXT VALUE FOR S_PAY_SEQUENCE  AS PAY_ACCOUNT_ID
						     , @emp_id                        AS EMP_ID
							 , '01'                           AS ACCOUNT_TYPE_CD
							 , MAX(CD_BANK_LAST)              AS BANK_CD
							 , NO_BANK_ACCNT_H                AS ACCOUNT_NO
							 , MAX(NM_DEPOSITOR_LAST)         AS HOLDER_NM
							 , MIN(STA_YMD_LAST)              AS STA_YMD
							 , MAX(END_YMD_LAST)              AS END_YMD
							 , MAX(REM_COMMENT)               AS NOTE
                             , 0                              AS MOD_USER_ID
                             , GETDATE()                      AS MOD_DATE
                             , 'KST'                          AS TZ_CD
                             , GETDATE()                      AS TZ_DATE
						  FROM (
								SELECT A.GBN
									 , A.ORD
									 , A.CD_COMPANY
									 , A.NO_PERSON
									 , A.CD_BANK          AS CD_BANK_H
									 , B.CD_BANK1         AS CD_BANK_M
									 , A.NO_BANK_ACCNT    AS NO_BANK_ACCNT_H
									 , B.NO_BANK_ACCNT1   AS NO_BANK_ACCNT_M
									 , A.NM_DEPOSITOR     AS NM_DEPOSITOR_H
									 , B.NM_DEPOSITOR1    AS NM_DEPOSITOR_M
									 , A.STA_YMD
									 , A.END_YMD

									 /*�޿��⺻�� �����̷��ֽ������� �ٸ� ��찡 �־� CASE�� ó��*/
									 , CASE WHEN ORD = '1' AND A.NO_BANK_ACCNT = B.NO_BANK_ACCNT1 AND GBN = 'HIS' THEN ISNULL(B.CD_BANK1, A.CD_BANK)
											ELSE A.CD_BANK
									   END AS CD_BANK_LAST
									 , CASE WHEN ORD = '1' AND A.NO_BANK_ACCNT = B.NO_BANK_ACCNT1 AND GBN = 'HIS' THEN ISNULL(B.NM_DEPOSITOR1, A.NM_DEPOSITOR)
											ELSE A.NM_DEPOSITOR
									   END AS NM_DEPOSITOR_LAST
									 , CASE WHEN ORD = '1' AND GBN = 'MST' THEN DATEADD(DD, 1, STA_YMD)
											ELSE STA_YMD
									   END AS STA_YMD_LAST
									 , CASE WHEN ORD = '1' AND A.NO_BANK_ACCNT <> B.NO_BANK_ACCNT1 AND GBN = 'HIS' THEN STA_YMD
											ELSE END_YMD
									   END AS END_YMD_LAST
									 , A.REM_COMMENT
								  FROM (
										SELECT 'MST'                  AS GBN
											 , '1'                    AS ORD
											 , MST.CD_COMPANY         AS CD_COMPANY
											 , MST.NO_PERSON          AS NO_PERSON
											 , MST.CD_BANK1           AS CD_BANK
											 , MST.NO_BANK_ACCNT1     AS NO_BANK_ACCNT
											 , MST.NM_DEPOSITOR1      AS NM_DEPOSITOR
											 , ISNULL( (SELECT CONVERT( DATETIME, MAX(X.DT_TRAN) )
														  FROM dwehrdev.dbo.H_PAY_BANK_HISTORY X
														 WHERE X.CD_COMPANY = MST.CD_COMPANY AND X.NO_PERSON = MST.NO_PERSON
														)
													 , CONVERT(DATETIME, '19000101')) AS STA_YMD
											 , CONVERT(DATETIME, '29991231')          AS END_YMD
											 , ''                     AS REM_COMMENT
										  FROM DWEHRDEV.DBO.H_PAY_MASTER MST
										 WHERE MST.CD_COMPANY = @s_company_cd
										   AND MST.NO_PERSON = @no_person

										UNION ALL

										SELECT 'HIS' AS GBN
											 , ROW_NUMBER() OVER(PARTITION BY HIS.CD_COMPANY, HIS.NO_PERSON ORDER BY HIS.DT_TRAN DESC) AS ORD
											 , HIS.CD_COMPANY
											 , HIS.NO_PERSON
											 , HIS.CD_BANK
											 , HIS.NO_BANK_ACCNT
											 , HIS.NM_DEPOSITOR
											 , CONVERT(DATETIME, HIS.DT_TRAN) AS STA_YMD
											 , ISNULL( (SELECT DATEADD(DD, -1, CONVERT( DATETIME, MIN(X.DT_TRAN) ) )
														  FROM dwehrdev.dbo.H_PAY_BANK_HISTORY X
														 WHERE X.CD_COMPANY = HIS.CD_COMPANY
														   AND X.NO_PERSON = HIS.NO_PERSON
														   AND X.DT_TRAN > HIS.DT_TRAN)
													  , CONVERT(DATETIME, '29991231')) AS END_YMD  -- ��������
											 , HIS.REM_COMMENT AS REM_COMMENT
										  FROM DWEHRDEV.DBO.H_PAY_BANK_HISTORY HIS
										 WHERE HIS.CD_COMPANY = @s_company_cd
										   AND HIS.NO_PERSON = @no_person
									   ) A
									   LEFT OUTER JOIN DWEHRDEV.DBO.H_PAY_MASTER B
											   ON A.CD_COMPANY = B.CD_COMPANY
											  AND A.NO_PERSON = B.NO_PERSON
								) AA
						 GROUP BY AA.ORD, AA.CD_COMPANY, AA.NO_PERSON, AA.NO_BANK_ACCNT_H


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
							  --+ ',dt_tran=' + ISNULL(CONVERT(nvarchar(100), @dt_tran),'NULL')
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
							  --+ ',dt_tran=' + ISNULL(CONVERT(nvarchar(100), @dt_tran),'NULL')
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
	PRINT 'CNV_PAY_WORK_ID = ' + CONVERT(varchar(100), @n_log_h_id)
	RETURN @n_log_h_id
END

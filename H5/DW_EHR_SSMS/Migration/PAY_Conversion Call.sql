
DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
DECLARE @results TABLE (
    log_id	numeric(38)
)
SET NOCOUNT ON;

set @an_try_no = 2 -- �õ�ȸ��( ���� [��ȣ + �Ķ����]�� �α׸� ���� )
-- TODO: ���⿡�� �Ű� ���� ���� �����մϴ�.
set @av_company_cd = 'E'

-- ==============================================
-- ȸ������ڵ����
-- ==============================================
	---- �ڷ����
	--DELETE FROM PAY_ACNT_CD
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_ACNT_CD
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- �޻󿩰����з�
-- ==============================================
	---- �ߺ��� ���� �ڷ����
	--DELETE FROM PAY_ACNT_MNG_DUP
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ����
	--DELETE FROM PAY_ACNT_MNG
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_ACNT_MNG
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- �����ݰ����з�
-- ==============================================
	---- �ڷ����
	--DELETE FROM REP_ACNT_MNG
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_REP_ACNT_MNG
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- �޿�������
-- ==============================================
	-- �ڷ����
	--DELETE FROM PAY_PHM_EMP
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	--Print '����(PAY_PHM_EMP):'+convert(varchar(100), @@RowCount)
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PHM_EMP
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
	---- CNS (HRD)�� ���
	--IF @av_company_cd = 'M' OR @av_company_cd = ''
	--	BEGIN
	--		EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PHM_EMP_HRD
	--				   @an_try_no
	--				  ,'M' --@av_company_cd
	--		INSERT INTO @results (log_id) VALUES (@n_log_h_id)
	--	END
-- ==============================================

-- ==============================================
-- �޿���������
-- ==============================================
	-- �ڷ����
	DELETE FROM PAY_PHM_FAMILY
	 WHERE EMP_ID in (select EMP_ID from PHM_EMP_NO_HIS where company_cd like ISNULL(@av_company_cd,'') + '%' )
	-- �ڷ���ȯ
	EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PHM_FAMILY
			   @an_try_no
			  ,@av_company_cd
	INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- �޿�����
-- ==============================================
	---- �ڷ����
	--DELETE FROM PAY_ACCOUNT
	-- WHERE EMP_ID in (select EMP_ID from PHM_EMP_NO_HIS where company_cd like ISNULL(@av_company_cd,'') + '%' )
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_ACCOUNT
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- ���κ���õ¡������
-- ==============================================
	---- �ڷ����
	--DELETE FROM PAY_EXP_TAX
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%' 
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_EXP_TAX
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- ȣ��
-- ==============================================
	---- �ڷ����
	--DELETE FROM PAY_HOBONG
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_HOBONG
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- ȣ��
-- ==============================================
	---- �ڷ����
	--DELETE FROM PAY_HOBONG_U
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_HOBONG_U
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- �����������ӱݱ���������
-- ==============================================
	-- �ڷ����
	--DELETE FROM PAY_SHIP_RATE
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_SHIP_RATE
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- �������ұݱ��ذ���
-- ==============================================
	---- �ڷ����
	--DELETE FROM PAY_SHIP_ADV
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_SHIP_ADV
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- ���ұݰ���
-- ==============================================
	---- �ڷ����
	--DELETE FROM PAY_ADV
	-- --WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_ADV
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- ���ұݰ�������
-- ==============================================
	---- �ڷ����
	--DELETE FROM PAY_SHIP_ADV_DTL
	-- --WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_SHIP_ADV_DTL
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- �����������
-- ==============================================
	---- �ڷ����
	--DELETE FROM PAY_STANDBY
	-- --WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_STANDBY
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- ���ο���/�ǰ�����
-- ==============================================
	---- �ڷ����
	---- ���ο���
	--DELETE FROM STP_JOIN_INFO
	-- WHERE EMP_ID IN (SELECT EMP_ID FROM PHM_EMP WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%')
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_H_MED_INSUR
	--		   @an_try_no
	--		  ,@av_company_cd
	--		  ,'1'
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- ���ο���/�ǰ�����
-- ==============================================
	---- �ǰ�����
	--DELETE FROM NHS_JOIN_INFO
	-- WHERE EMP_ID IN (SELECT EMP_ID FROM PHM_EMP WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%')
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_H_MED_INSUR
	--		   @an_try_no
	--		  ,@av_company_cd
	--		  ,'2'
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- COST���� ( �ϼ����� ����. ���� ����? )
-- ==============================================
	---- COST����
	--DELETE FROM ORM_COST
	-- WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_ORM_COST
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- ���κ�COST���� ( �ϼ����� ����. ���� ����? )
-- ==============================================
	---- ���κ�COST����
	--DELETE FROM ORM_EMP_COST
	-- WHERE EMP_ID IN (SELECT EMP_ID FROM PHM_EMP_NO_HIS WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%')
	---- �ڷ���ȯ
	--EXECUTE @n_log_h_id = dbo.P_CNV_ORM_EMP_COST
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- �α����Ϻ���
-- ==============================================
SELECT *
  FROM CNV_PAY_WORK A
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)
SELECT *
  FROM CNV_PAY_WORK_LOG B
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)

--SELECT A.CNV_PAY_WORK_ID, A.PROGRAM_NM, A.TITLE, A.PARAMS, CNT_TRY, CNT_OK, CNT_FAIL, ERR_MSG, KEYS
--  FROM CNV_PAY_WORK A WITH(NOLOCK)
--  JOIN CNV_PAY_WORK_LOG B WITH(NOLOCK)
--    ON A.CNV_PAY_WORK_ID = B.CNV_PAY_WORK_ID
-- WHERE A.PROGRAM_NM = 'P_CNV_PAY_ACNT_MNG'
--   AND A.CNV_PAY_WORK_ID = MAX(A.CNV_PAY_WORK_ID)
-- ORDER BY B.CNV_PAY_WORK_LOG_ID
GO

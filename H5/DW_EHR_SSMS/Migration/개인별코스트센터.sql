USE [dwehrdev_H5]
GO

DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
DECLARE @results TABLE (
    log_id	numeric(38)
)
SET NOCOUNT ON;

set @an_try_no = 2 -- �õ�ȸ��( ���� [��ȣ + �Ķ����]�� �α׸� ���� )
-- TODO: ���⿡�� �Ű� ���� ���� �����մϴ�.
set @av_company_cd = 'X'

-- ==============================================
-- ���κ�COST���� ( �ϼ����� ����. ���� ����? )
-- ==============================================
	-- ���κ�COST����
	DELETE FROM ORM_EMP_COST
	 WHERE EMP_ID IN (SELECT EMP_ID FROM PHM_EMP_NO_HIS WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%')
	-- �ڷ���ȯ
	EXECUTE @n_log_h_id = dbo.P_CNV_ORM_EMP_COST
			   @an_try_no
			  ,@av_company_cd
	INSERT INTO @results (log_id) VALUES (@n_log_h_id)
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

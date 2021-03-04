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
set @av_company_cd = 'E'

-- ==============================================
-- ��������
-- ==============================================
	-- �ڷ����
	DELETE FROM PAY_FIXED_PAY
	 WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	-- �ڷ���ȯ
	EXECUTE @n_log_h_id = dbo.P_CNV_PAY_FIXED_PAY
			   @an_try_no
			  ,@av_company_cd
	INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- ��������
-- ==============================================
	-- �ڷ����
	DELETE FROM PAY_FIXED_DEDUCTION
	 WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	-- �ڷ���ȯ
	EXECUTE @n_log_h_id = dbo.P_CNV_PAY_FIXED_DEDUCTION
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

GO

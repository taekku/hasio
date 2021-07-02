DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
DECLARE @results TABLE (
    log_id	numeric(38)
)
SET NOCOUNT ON;

set @an_try_no = 2 -- �õ�ȸ��( ���� [��ȣ + �Ķ����]�� �α׸� ���� )
-- TODO: ���⿡�� �Ű� ���� ���� �����մϴ�.
set @av_company_cd = ''

-- ==============================================
-- �����ڵ����(�ο���_����������)
-- ==============================================
	-- �ο���(����)
	DELETE FROM A
	  FROM PBT_INCITEM A
	  JOIN PBT_ACCNT_STD B
	    ON A.PBT_ACCNT_STD_ID = B.PBT_ACCNT_STD_ID
	 WHERE B.COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
	-- �ο���(����)
	DELETE FROM A
	  FROM PBT_EXCITEM A
	  JOIN PBT_ACCNT_STD B
	    ON A.PBT_ACCNT_STD_ID = B.PBT_ACCNT_STD_ID
	 WHERE B.COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
	-- �����ڵ����(�ο���_����������)
	DELETE FROM PBT_ACCNT_STD
	 WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
	-- �ڷ���ȯ
	EXECUTE @n_log_h_id = dbo.P_CNV_PBT_ACCNT_STD
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
 --and ERR_MSG not like '%�����ڵ�%'

GO

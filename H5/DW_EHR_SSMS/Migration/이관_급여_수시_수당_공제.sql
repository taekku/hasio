USE [dwehrdev_H5]
GO

DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
	, @av_fr_month		NVARCHAR(6)		-- ���۳��
	, @av_to_month		NVARCHAR(6)		-- ������
	, @av_fg_supp		NVARCHAR(2)		-- �޿�����
	, @av_dt_prov		NVARCHAR(08)	-- �޿�������
DECLARE @results TABLE (
    log_id	numeric(38)
)
SET NOCOUNT ON;

set @an_try_no = 2 -- �õ�ȸ��( ���� [��ȣ + �Ķ����]�� �α׸� ���� )
-- TODO: ���⿡�� �Ű� ���� ���� �����մϴ�.
set @av_company_cd = 'E'
set @av_fr_month = '202001'
set @av_to_month = '202006'
--set @av_dt_prov = '20200125'

-- ==============================================
-- �޿������̰�(�޿� ���� ����)
-- ==============================================
  -- �ڷ����
	DELETE FROM PAY_ETC_PAY
	 WHERE PAY_YMD_ID in (select PAY_YMD_ID from PAY_PAY_YMD t
	                       where company_cd like ISNULL(@av_company_cd,'') + '%'
													 and t.PAY_YM between @av_fr_month and @av_to_month
	                     )
	-- �ڷ���ȯ
	EXECUTE @n_log_h_id = dbo.P_CNV_PAY_ETC_PAY
      @an_try_no		-- �õ�ȸ��
    , @av_company_cd	-- ȸ���ڵ�
	, @av_fr_month		-- ���۳��
	, @av_to_month		-- ������
	INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- �޿������̰�(�޿� ���� ����)
-- ==============================================
  -- �ڷ����
	DELETE FROM PAY_ANY_DEDU
	 WHERE PAY_YMD_ID in (select PAY_YMD_ID from PAY_PAY_YMD t
	                       where company_cd like ISNULL(@av_company_cd,'') + '%'
													 and t.PAY_YM between @av_fr_month and @av_to_month
	                     )
	-- �ڷ���ȯ
	EXECUTE @n_log_h_id = dbo.P_CNV_PAY_ANY_DEDU
      @an_try_no		-- �õ�ȸ��
    , @av_company_cd	-- ȸ���ڵ�
	, @av_fr_month		-- ���۳��
	, @av_to_month		-- ������
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

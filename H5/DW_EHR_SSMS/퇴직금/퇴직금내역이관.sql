USE [dwehrdev_H5]
GO

DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
	, @av_fr_month		NVARCHAR(6)		-- ���۳��
	, @av_to_month		NVARCHAR(6)		-- ������
	, @av_fg_supp		NVARCHAR(2)		-- �޿�����
	, @av_dt_prov		NVARCHAR(08)	-- �޿�������
	, @v_work_kind		nvarchar(10)    -- D:������
DECLARE @results TABLE (
    log_id	numeric(38)
)
SET NOCOUNT ON;

set @an_try_no = 2 -- �õ�ȸ��( ���� [��ȣ + �Ķ����]�� �α׸� ���� )
-- TODO: ���⿡�� �Ű� ���� ���� �����մϴ�.
set @av_company_cd = 'E'
set @av_fr_month = '202010'
set @av_to_month = '202011'

-- ==============================================
-- �������̰�
-- ==============================================
    -- �ڷ����
	DELETE FROM REP_CALC_LIST
	 WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
	   --AND dbo.XF_TO_CHAR_D(C1_END_YMD, 'yyyymm') between ISNULL(@av_fr_month,'') and ISNULL(@av_to_month,'999999')
	   AND FORMAT(C1_END_YMD, 'yyyyMM') BETWEEN ISNULL(@av_fr_month,'') AND ISNULL(@av_to_month,'999999')

	-- �ڷ���ȯ
	EXECUTE @n_log_h_id = dbo.P_CNV_REP_CALC_LIST
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

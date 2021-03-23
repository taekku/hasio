DECLARE @av_company_cd nvarchar(10) = 'X'
      , @v_bill_gbn nvarchar(10) = 'P5108'
	  , @v_bill_gbn_to nvarchar(10) = 'R5108'
-- PBT_ACCNT_STD �ο���_����������
-- PBT_INCITEM �ο���_�����׸�
-- PBT_EXCITEM �ο���_�����׸�

-- �����׸� ����
--SELECT *
DELETE B
  FROM PBT_ACCNT_STD A
  JOIN PBT_EXCITEM B
    ON A.PBT_ACCNT_STD_ID = B.PBT_ACCNT_STD_ID
 WHERE A.COMPANY_CD = @av_company_cd
   AND A.BILL_GBN = @v_bill_gbn_to
-- �����׸� ����
--SELECT *
DELETE B
  FROM PBT_ACCNT_STD A
  JOIN PBT_INCITEM B
    ON A.PBT_ACCNT_STD_ID = B.PBT_ACCNT_STD_ID
 WHERE A.COMPANY_CD = @av_company_cd
   AND A.BILL_GBN = @v_bill_gbn_to
   
-- ���������� ����
--SELECT *
DELETE A
  FROM PBT_ACCNT_STD A
 WHERE A.COMPANY_CD = @av_company_cd
   AND A.BILL_GBN = @v_bill_gbn_to
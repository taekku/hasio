DECLARE @av_company_cd nvarchar(10) = 'X'
      , @v_bill_gbn nvarchar(10) = 'P5108'--'P5103', 'P5107', 'P5104', 'P5108'
	  , @v_bill_gbn_to nvarchar(10) = 'R5108'--'R5103','R5107', 'R5104', 'R5108'
-- PBT_ACCNT_STD �ο���_����������

INSERT INTO PBT_ACCNT_STD(PBT_ACCNT_STD_ID, -- ����������ID
		COMPANY_CD, -- �λ翵��
		HRTYPE_GBN, -- ��������
		WRTDPT_CD, -- �ۼ��μ�
		TRDTYP_CD, -- �ŷ�����
		BILL_GBN, -- ��ǥ����
		ACCNT_CD, -- �����ڵ�
		COST_ACCTCD, -- �������ڵ�
		MGNT_ACCTCD, -- ���������ڵ�
		TRDTYP_NM, -- �ŷ�������Ī
		CUST_CD, -- �ŷ�ó�ڵ�
		DEBSER_GBN, -- ���뱸��
		SUMMARY, -- �������
		CSTDPAT_CD, -- CSTDPAT_CD
		AGGR_GBN, -- AGGR_GBN
		USE_YN, -- ��뿩��
		MOD_USER_ID, -- ������
		MOD_DATE, -- �����Ͻ�
		TZ_CD, -- Ÿ�����ڵ�
		TZ_DATE -- Ÿ�����Ͻ�
)
select NEXT VALUE FOR S_PBT_SEQUENCE PBT_ACCNT_STD_ID, -- ����������ID
		COMPANY_CD, -- �λ翵��
		HRTYPE_GBN, -- ��������
		WRTDPT_CD, -- �ۼ��μ�
		TRDTYP_CD, -- �ŷ�����
		@v_bill_gbn_to	BILL_GBN, -- ��ǥ����
		ACCNT_CD, -- �����ڵ�
		COST_ACCTCD, -- �������ڵ�
		MGNT_ACCTCD, -- ���������ڵ�
		TRDTYP_NM, -- �ŷ�������Ī
		CUST_CD, -- �ŷ�ó�ڵ�
		DEBSER_GBN, -- ���뱸��
		SUMMARY, -- �������
		CSTDPAT_CD, -- CSTDPAT_CD
		AGGR_GBN, -- AGGR_GBN
		USE_YN, -- ��뿩��
		MOD_USER_ID, -- ������
		MOD_DATE, -- �����Ͻ�
		'KKK' TZ_CD, -- Ÿ�����ڵ�
		TZ_DATE -- Ÿ�����Ͻ�
  from PBT_ACCNT_STD
 where COMPANY_CD=@av_company_cd
   and BILL_GBN=@v_bill_gbn
   
-- PBT_INCITEM �ο���_�����׸�
INSERT INTO PBT_INCITEM(
		PBT_INCITEM_ID, -- �����׸�ID
		PBT_ACCNT_STD_ID, -- ����������ID
		ITEM_CD, -- �����׸������ڵ�
		SEQ, -- ����
		INCITEM_FR, -- �����׸�����ڵ�
		INCITEM_TO, -- �����׸������ڵ�
		INCITEM, -- �����׸��ڵ�
		MOD_USER_ID, -- ������
		MOD_DATE, -- �����Ͻ�
		TZ_CD, -- Ÿ�����ڵ�
		TZ_DATE -- Ÿ�����Ͻ�
)
SELECT NEXT VALUE FOR S_PBT_SEQUENCE AS PBT_INCITEM_ID, -- �����׸�ID
		T.PBT_ACCNT_STD_ID, -- ����������ID
		B.ITEM_CD, -- �����׸������ڵ�
		B.SEQ, -- ����
		B.INCITEM_FR, -- �����׸�����ڵ�
		B.INCITEM_TO, -- �����׸������ڵ�
		B.INCITEM, -- �����׸��ڵ�
		B.MOD_USER_ID, -- ������
		B.MOD_DATE, -- �����Ͻ�
		--B.TZ_CD, -- Ÿ�����ڵ�
		'KKK',
		B.TZ_DATE -- Ÿ�����Ͻ�
  FROM PBT_ACCNT_STD A
  JOIN PBT_ACCNT_STD T
    ON A.COMPANY_CD = T.COMPANY_CD 
   AND A.HRTYPE_GBN = T.HRTYPE_GBN -- ��������
   AND A.WRTDPT_CD = T.WRTDPT_CD   -- �ۼ��μ�
   AND A.TRDTYP_CD = T.TRDTYP_CD   -- �ŷ�����
   AND A.BILL_GBN = @v_bill_gbn	   -- ��ǥ����
   AND @v_bill_gbn_to = T.BILL_GBN	   -- ��ǥ����
   AND A.ACCNT_CD = T.ACCNT_CD	   -- �����ڵ�
  JOIN PBT_INCITEM B
    ON A.PBT_ACCNT_STD_ID = B.PBT_ACCNT_STD_ID
 WHERE A.COMPANY_CD = @av_company_cd
   AND A.BILL_GBN = @v_bill_gbn
-- PBT_EXCITEM �ο���_�����׸�
INSERT INTO PBT_EXCITEM(
		PBT_EXCITEM_ID, -- �����׸�ID
		PBT_ACCNT_STD_ID, -- ����������ID
		ITEM_CD, -- �����׸������ڵ�
		SEQ, -- ����
		EXCITEM_FR, -- �����׸�����ڵ�
		EXCITEM_TO, -- �����׸������ڵ�
		EXCITEM, -- �����׸��ڵ�
		MOD_USER_ID, -- ������
		MOD_DATE, -- �����Ͻ�
		TZ_CD, -- Ÿ�����ڵ�
		TZ_DATE  -- Ÿ�����Ͻ�
)
SELECT NEXT VALUE FOR S_PBT_SEQUENCE PBT_EXCITEM_ID, -- �����׸�ID
		T.PBT_ACCNT_STD_ID, -- ����������ID
		B.ITEM_CD, -- �����׸������ڵ�
		B.SEQ, -- ����
		B.EXCITEM_FR, -- �����׸�����ڵ�
		B.EXCITEM_TO, -- �����׸������ڵ�
		B.EXCITEM, -- �����׸��ڵ�
		B.MOD_USER_ID, -- ������
		B.MOD_DATE, -- �����Ͻ�
		--B.TZ_CD, -- Ÿ�����ڵ�
		'KKK',
		B.TZ_DATE  -- Ÿ�����Ͻ�
  FROM PBT_ACCNT_STD A
  JOIN PBT_ACCNT_STD T
    ON A.COMPANY_CD = T.COMPANY_CD 
   AND A.HRTYPE_GBN = T.HRTYPE_GBN -- ��������
   AND A.WRTDPT_CD = T.WRTDPT_CD   -- �ۼ��μ�
   AND A.TRDTYP_CD = T.TRDTYP_CD   -- �ŷ�����
   AND A.BILL_GBN = @v_bill_gbn	   -- ��ǥ����
   AND @v_bill_gbn_to = T.BILL_GBN	   -- ��ǥ����
   AND A.ACCNT_CD = T.ACCNT_CD	   -- �����ڵ�
  JOIN PBT_EXCITEM B
    ON A.PBT_ACCNT_STD_ID = B.PBT_ACCNT_STD_ID
 WHERE A.COMPANY_CD = @av_company_cd
   AND A.BILL_GBN = @v_bill_gbn
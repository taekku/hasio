declare @appl_id numeric(38) = 43008226
SELECT A.COMPANY_CD
     , 'A' AS P_GUBUN -- ������
     , dbo.XF_LPAD(ISNULL((SELECT EMP_NO FROM PHM_EMP WHERE EMP_ID = A.EMP_ID),''), 10, '0') AS P_PERNR -- �����ڻ��
	 --, (select ELA_DOC_NO from ELA_APPL WHERE APPL_ID = A.APPL_ID) AS P_EBELN -- ����Ű
     , RIGHT(dbo.XF_TO_CHAR_D(A.APPL_YMD,'yyyy'),3) + dbo.XF_LPAD(A.ECC_REQ_ID % 10000000, 7,'0') AS P_EBELN
     , dbo.XF_TO_CHAR_D(A.CNF_BASE_YMD, 'yyyyMMdd') AS P_BUDAT -- ��ǥ�� ������
     , dbo.XF_TO_CHAR_N(A.BASE_MON, NULL) AS P_AMOUNT -- ���� �����޾�
     , 'https://dwehr.dongwon.com'
       --'http://172.20.16.40:8081'
       --(SELECT REGISTRY_VALUE FROM FRM_REGISTRY WHERE REGISTRY_KEY LIKE 'SERVER_URL' AND TYPE_CD='VALUE' AND GROUP_CD='SYSTEM_VAR')
        + '/ecc/web/eccElaInterface.jsp?appl_id=' + dbo.XF_TO_CHAR_N(A.APPL_ID, NULL)
		AS P_GIAN -- ���繮�� ��ũ
     , dbo.XF_LPAD(ISNULL((SELECT EMP_NO FROM PHM_EMP WHERE EMP_ID = A.APPL_EMP_ID),''), 10, '0') AS P_PERNR2 -- �����
  FROM ECC_REQ A
 WHERE A.APPL_ID = @appl_id
   AND A.ACC_CD > ' '
   AND A.ACNT_TYPE_CD > ' '
   --AND A.STAT_CD = '132'
   AND ISNULL(A.SEND_YN,'N') != 'Y'

SELECT A.SUBJECT_CD AS GL_ACCOUNT -- �Ѱ������� ����
     , A.ACC_SUMMARY AS POSITION_TEXT -- ����
     , dbo.XF_LPAD(A.ORM_COST_ORG_CD, 10, '0') AS KOSTL -- �ڽ�Ʈ����
     , dbo.XF_TO_CHAR_N(A.BASE_MON, NULL) AS WRBTR -- �ݾ�
  FROM ECC_REQ A
 WHERE A.APPL_ID = @appl_id
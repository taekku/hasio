
SELECT A.REP_CALC_LIST_ID,   -- ������ ��� ID
       A.COMPANY_CD,     -- �λ翵��
       A.EMP_ID EMP_ID,   -- ���ID
       P.DAY_EMP_MST_ID, -- �Ͽ���
       P.EMP_NO,   -- ���
       P.EMP_NM,   -- ����
       A.ORG_ID,   -- �Ҽ�ID
       A.PAY_ORG_ID, -- �޿��μ�ID
       A.PAY_YMD,    -- ������
       A.CALC_TYPE_CD, -- ���걸��
       A.TAX_TYPE,     -- ���ݹ��
       A.CALC_RETIRE_CD, -- ��������
       A.END_YN,   -- �ϷῩ��
       A.C1_STA_YMD,   -- �����
       A.C1_END_YMD,   -- ��(��)������
       A.WORK_YY,   -- (��)�ټӳ��
       A.WORK_MM,   -- (��)�ټӿ���
       A.WORK_DD,   -- (��)�ټ��ϼ�
       A.WORK_DAY,  -- �ټ����ϼ�
       A.EXCE_STA_YMD,   -- �������ܽ�����
       A.EXCE_END_YMD,   -- ��������������
       A.PAY_TOT_AMT,    -- 3�����޿�
       A.AVG_PAY_AMT_M,  -- ��ձ޿�(��)
       A.AVG_PAY_AMT_D,  -- ��ձ޿�(��)
       A.C_01,  -- ������
       A.CT01,   -- �����ҵ漼
       A.CT02,   -- �����ֹμ�
       A.NOTE,    -- ���
       '<div class="width_100" ><input type="button" class="btn_gride" value="���뺸��"></div>' as detail_view,
       '<div class="width_100" ><input type="button" class="btn_gride" value="�����"></div>' AS REPORT1,
       '/common/img/popup_up.png' AS REPORT2,
       '<div class="width_100" ><input type="button" class="btn_gride" value="��õ¡��������"></div>' AS REPORT3
  FROM REP_CALC_LIST A
 INNER JOIN DAY_EMP_MST P
         ON A.EMP_ID = P.DAY_EMP_MST_ID
        AND A.CALC_TYPE_CD = '20'
 WHERE P.COMPANY_CD =  'E' 
   AND A.C1_END_YMD BETWEEN  '2020-10-28 00:00:00.0'  and  '2020-10-31 00:00:00.0'
   AND ( '20'  IS NULL OR A.CALC_TYPE_CD =  '20' )
   AND ( NULL  IS NULL OR P.DAY_EMP_MST_ID =  NULL )
 ORDER BY A.COMPANY_CD, A.C1_END_YMD, A.EMP_ID

SELECT A.REP_ESTIMATION_ID    -- ���� �߰��ID
     , A.ESTIMATION_YM    -- �����߰���
     , A.EMP_ID    -- ���ID
     , dbo.F_PHM_EMP_NO( A.EMP_ID, '1' ) AS EMP_NO
     , dbo.F_PHM_EMP_NM( A.EMP_ID, dbo.XF_SYSDATE(0), B.LOCALE_CD ) AS EMP_NM
     , A.ORG_ID    -- �߷ɺμ�ID
     , dbo.F_FRM_ORM_ORG_NM( A.ORG_ID, B.LOCALE_CD, A.END_YMD, '11' ) AS ORG_NM    -- �ҼӸ�
     , A.PAY_ORG_ID    -- �޿��μ�ID
     , A.EMP_KIND_CD    -- ��������[�ӿ�,����,�Ϲ�]
     , A.POS_GRD_CD    -- �����ڵ� [PHM_POS_GRD_CD]
     , dbo.F_FRM_CODE_NM( B.COMPANY_CD, B.LOCALE_CD, 'PHM_POS_GRD_CD', A.POS_GRD_CD, A.END_YMD, '1' ) AS POS_GRD_NM
     , A.DUTY_CD    -- ��å�ڵ� [PHM_DUTY_CD]
     , dbo.F_FRM_CODE_NM( B.COMPANY_CD, B.LOCALE_CD, 'PHM_DUTY_CD', A.DUTY_CD, A.END_YMD, '1' ) AS DUTY_NM    -- ��å
     , A.POS_CD    -- �����ڵ� [PHM_POS_CD]
     , dbo.F_FRM_CODE_NM( B.COMPANY_CD, B.LOCALE_CD, 'ORM_ORG_ACC_CD', A.POS_CD, A.END_YMD, '1' ) AS ORG_ACC_NM    -- ��������
     , A.ACC_CD    -- �ڽ�Ʈ����
     , dbo.XF_TO_CHAR_D( A.HIRE_YMD, 'YYYYMMDD' ) AS HIRE_YMD    -- �Ի�����
     , dbo.XF_TO_CHAR_D( A.STA_YMD, 'YYYYMMDD' ) AS STA_YMD      -- ���������
     , dbo.XF_TO_CHAR_D( A.END_YMD, 'YYYYMMDD' ) AS END_YMD      -- ����������
     , dbo.XF_TO_CHAR_D( dbo.XF_NVL_D( A.STA_YMD, A.HIRE_YMD ), 'YYYYMMDD' ) AS HIRE_STA_YMD    -- �����/�Ի���
     , A.WORK_DAY    -- �Ǳټ����ϼ�
     , dbo.XF_CEIL( A.WORK_YY_PT, 1 ) AS WORK_YY_PT    -- �Ǳټӳ��(�Ҽ���)
     , A.ADD_WORK_YY    -- �߰��ټӳ��
     , A.WORK_YY    -- �Ǳټӳ��
     , A.WORK_MM    -- �Ǳټӿ���
     , A.WORK_DD    -- �Ǳټ��ϼ�
     , A.EST_RATE    -- ������
     , A.CNT_SALARY    -- �ӱ��Ѿ�
     , A.PAY_AMT1    -- �� �޿� 1
     , A.PAY_AMT2    -- �� �޿� 2
     , A.PAY_AMT3    -- �� �޿� 3
     , A.PAY_AMT4    -- �� �޿� 4
     , A.PAY_AMT    -- ���޿���
     , A.BONUS_AMT1    -- �����ޱݾ� 1
     , A.BONUS_AMT2    -- �����ޱݾ� 2
     , A.BONUS_AMT3    -- �����ޱݾ� 3
     , A.BONUS_AMT4    -- �����ޱݾ� 4
     , A.BONUS_AMT5    -- �����ޱݾ� 5
     , A.BONUS_AMT6    -- �����ޱݾ� 6
     , A.BONUS_AMT7    -- �����ޱݾ� 7
     , A.BONUS_AMT8    -- �����ޱݾ� 8
     , A.BONUS_AMT9    -- �����ޱݾ� 9
     , A.BONUS_AMT10    -- �����ޱݾ� 10
     , A.BONUS_AMT11    -- �����ޱݾ� 11
     , A.BONUS_AMT12    -- �����ޱݾ� 12
     , A.BONUS_AMT    -- ����
     , A.BASE_PAY_AMT    -- ���ر޿�
     , A.DAY_AMT    -- ���������ݾ�
     , A.AVG_PAY    -- ��ձ޿�
     , A.AVG_BONUS    -- ��ջ�
     , A.AVG_DAY    -- ��տ�����
     , A.AVG_PAY_AMT    -- ����ӱ�
     , A.RETIRE_AMT    -- �����߰��
     , A.RETIRE_MON_AMT    -- ��������(���� �����߰�װ��� ����)
     , A.RETIRE_YEAR_AMT    -- ��������(���⸻ �����߰�װ��� ����)
     , A.NOTE    -- ���
  FROM REP_ESTIMATION A
     , ( SELECT ? AS COMPANY_CD
              , ? AS LOCALE_CD
           FROM DUAL ) B
 WHERE A.ESTIMATION_YM = ?
   AND ( ? IS NULL OR A.EMP_ID = ? )
   AND ( ? IS NULL OR A.EMP_KIND_CD = ? )
 ORDER BY dbo.F_FRM_CODE_NM( B.COMPANY_CD, B.LOCALE_CD, 'REP_EMP_KIND_CD', A.EMP_KIND_CD, dbo.XF_SYSDATE(0), 'O' )
        , dbo.F_FRM_CODE_NM( B.COMPANY_CD, B.LOCALE_CD, 'PHM_POS_GRD_CD', A.POS_GRD_CD, dbo.XF_SYSDATE(0), 'O' )
        , dbo.F_PHM_EMP_ORDER( B.COMPANY_CD, B.LOCALE_CD, A.EMP_ID, A.END_YMD, '1' )
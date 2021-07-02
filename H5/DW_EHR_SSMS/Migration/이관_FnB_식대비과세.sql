-- FnB ����ӱ�
--------------------
-- C001 �Ĵ�����
-- C002 ��������
-- C003 ��������
--------------------
-- C100	�������ݾ�
--------------------
-- C101	����ӱ�
-- C102	���ñ�
-- C110	�ñ�
-- C111	�ϱ�
-- C112	����ϱ�
------------------

INSERT INTO PAY_PAYROLL_DETAIL(
		PAY_PAYROLL_DETAIL_ID, -- �޿��󼼳���ID
		PAY_PAYROLL_ID, -- �޿�����ID
		BEL_PAY_TYPE_CD, -- �޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
		BEL_PAY_YM, -- �ͼӿ�
		BEL_PAY_YMD_ID, -- �ͼӱ޿�����ID
		SALARY_TYPE_CD, -- �޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
		PAY_ITEM_CD, -- �޿��׸��ڵ�
		BASE_MON, -- ���رݾ�
		CAL_MON, -- ���ݾ�
		FOREIGN_BASE_MON, -- ��ȭ���رݾ�
		FOREIGN_CAL_MON, -- ��ȭ���ݾ�
		PAY_ITEM_TYPE_CD, -- �޿��׸�����
		BEL_ORG_ID, -- �ͼӺμ�ID
		NOTE, -- ���
		MOD_USER_ID, -- ������
		MOD_DATE, -- �����Ͻ�
		TZ_CD, -- Ÿ�����ڵ�
		TZ_DATE -- Ÿ�����Ͻ�
)
SELECT 
		NEXT VALUE FOR S_PAY_SEQUENCE	PAY_PAYROLL_DETAIL_ID, -- �޿��󼼳���ID
		PAY_PAYROLL_ID, -- �޿�����ID
		A.PAY_TYPE_CD	BEL_PAY_TYPE_CD, -- �޿����������ڵ�-�ͼӿ�[PAY_TYPE_CD]
		A.PAY_YM	BEL_PAY_YM, -- �ͼӿ�
		A.PAY_YMD_ID	BEL_PAY_YMD_ID, -- �ͼӱ޿�����ID
		A.SALARY_TYPE_CD, -- �޿������ڵ�[PAY_SALARY_TYPE_CD ����,ȣ��]
		A.ITEM_CD	PAY_ITEM_CD, -- �޿��׸��ڵ�
		A.AMT	BASE_MON, -- ���رݾ�
		A.AMT	CAL_MON, -- ���ݾ�
		0 FOREIGN_BASE_MON, -- ��ȭ���رݾ�
		0 FOREIGN_CAL_MON, -- ��ȭ���ݾ�
		'TAX_N_P'	PAY_ITEM_TYPE_CD, -- �޿��׸�����
		A.ORG_ID	BEL_ORG_ID, -- �ͼӺμ�ID
		'SAP(FnB)'	NOTE, -- ���
		0	MOD_USER_ID, -- ������
		GETDATE()	MOD_DATE, -- �����Ͻ�
		'KST'	TZ_CD, -- Ÿ�����ڵ�
		SYSDATETIME()	TZ_DATE -- Ÿ�����Ͻ�
  FROM (
		SELECT YMD.PAY_YM, YMD.PAY_YMD_ID, YMD.PAY_TYPE_CD
		     , PAY.PAY_PAYROLL_ID, PAY.SALARY_TYPE_CD
			 , PAY.EMP_ID, PAY.ORG_ID
			 , (SELECT EMP_NO FROM PHM_EMP WHERE COMPANY_CD='F' AND EMP_ID=PAY.EMP_ID) AS EMP_NO
			 , A.ITEM_CD, A.AMT
		  FROM PAY_PAY_YMD YMD
		  JOIN PAY_PAYROLL PAY ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
		  JOIN CNV_PAY_FnB_fTAX A
			ON YMD.PAY_YM = A.PAY_YM
			AND PAY.EMP_ID = A.EMP_ID
			AND YMD.PAY_TYPE_CD = A.PAY_TYPE_CD
			AND YMD.PAY_YMD = A.DT_PROV
		 WHERE YMD.COMPANY_CD='F'
		   --AND PAY.EMP_ID!=58099
	--	   AND PAY.EMP_ID=59465
	--AND PAY.ORG_ID=59465
	-- PAY_PAYROLL_ID, BEL_ORG_ID, BEL_PAY_TYPE_CD, BEL_PAY_YMD_ID, SALARY_TYPE_CD, PAY_ITEM_CD
	AND NOT EXISTS (SELECT 1 FROM PAY_PAYROLL_DETAIL
	                        WHERE PAY_PAYROLL_ID=PAY.PAY_PAYROLL_ID
							  AND BEL_ORG_ID = PAY.ORG_ID
							  AND BEL_PAY_TYPE_CD = YMD.PAY_TYPE_CD
							  AND BEL_PAY_YMD_ID = YMD.PAY_YMD_ID
							  AND SALARY_TYPE_CD = PAY.SALARY_TYPE_CD
							  AND PAY_ITEM_CD = A.ITEM_CD
							)
		   AND AMT <> 0
	) A
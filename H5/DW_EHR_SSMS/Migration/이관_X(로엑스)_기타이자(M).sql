-- X �ο��� ��Ÿ����(M) �����
-- C006	�����
--------------------
-- C100	�������ݾ�
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
		dbo.F_FRM_UNIT_STD_VALUE ('X', 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
										  NULL, NULL, NULL, NULL, NULL,
										  ITEM_CD, NULL, NULL, NULL, NULL,
										  getdATE(),
										  'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
											   -- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
										  )		PAY_ITEM_TYPE_CD, -- �޿��׸�����( �������� )
		A.ORG_ID	BEL_ORG_ID, -- �ͼӺμ�ID
		'�̰�'	NOTE, -- ���
		0	MOD_USER_ID, -- ������
		GETDATE()	MOD_DATE, -- �����Ͻ�
		'KST'	TZ_CD, -- Ÿ�����ڵ�
		SYSDATETIME()	TZ_DATE -- Ÿ�����Ͻ�
  FROM (
		SELECT YMD.PAY_YM, YMD.PAY_YMD_ID, YMD.PAY_TYPE_CD
		     , PAY.PAY_PAYROLL_ID, PAY.SALARY_TYPE_CD
			 , PAY.EMP_ID, PAY.ORG_ID
			 , (SELECT EMP_NO FROM PHM_EMP WHERE COMPANY_CD='X' AND EMP_ID=PAY.EMP_ID) AS EMP_NO
			 , COM.ITEM_CD, COM.AMT
		  FROM PAY_PAY_YMD YMD
		  JOIN FRM_CODE T
			ON YMD.COMPANY_CD = T.COMPANY_CD AND YMD.PAY_TYPE_CD = T.CD AND T.CD_KIND = 'PAY_TYPE_CD'
		   AND T.SYS_CD = '001' AND YMD.COMPANY_CD='X' -- ������
		  JOIN PAY_PAYROLL PAY ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
		  JOIN (SELECT PAY_PAYROLL_ID
					 , 'C006' AS ITEM_CD -- �����
					 , SUM(CAL_MON) AMT
				  FROM PAY_PAYROLL_DETAIL A
				 WHERE PAY_ITEM_CD IN ( 'P316' )
				 GROUP BY PAY_PAYROLL_ID) COM
			ON PAY.PAY_PAYROLL_ID = COM.PAY_PAYROLL_ID
		 WHERE YMD.COMPANY_CD='X'
		   AND YMD.PAY_YM BETWEEN '202105' AND '202105'
			AND NOT EXISTS (SELECT 1 FROM PAY_PAYROLL_DETAIL K
									WHERE K.PAY_PAYROLL_ID=PAY.PAY_PAYROLL_ID
									  AND K.BEL_ORG_ID = PAY.ORG_ID
									  AND K.BEL_PAY_TYPE_CD = YMD.PAY_TYPE_CD
									  AND K.BEL_PAY_YMD_ID = YMD.PAY_YMD_ID
									  AND K.SALARY_TYPE_CD = PAY.SALARY_TYPE_CD
									  AND K.PAY_ITEM_CD = COM.ITEM_CD
									)
		   AND AMT <> 0
	) A
--   ORDER BY YMD.PAY_YM
--ORDER BY PAY_PAYROLL_ID

--SELECT COUNT(*)
--FROM PAY_PAY_YMD YMD
--		  JOIN FRM_CODE T
--			ON YMD.COMPANY_CD = T.COMPANY_CD AND YMD.PAY_TYPE_CD = T.CD AND T.CD_KIND = 'PAY_TYPE_CD'
--		   AND T.SYS_CD = '002' AND YMD.COMPANY_CD='F' -- ������
--JOIN PAY_PAYROLL PAY
--ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
--JOIN PAY_PAYROLL_DETAIL DTL
--ON PAY.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID
--WHERE YMD.COMPANY_CD='F'
--AND DTL.PAY_ITEM_CD='C100'
--AND YMD.PAY_YM >= '202101'

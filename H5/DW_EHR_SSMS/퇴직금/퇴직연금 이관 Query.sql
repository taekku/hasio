DELETE FROM REP_INSUR_MON ;

INSERT INTO REP_INSUR_MON (
						   REP_INSUR_MON_ID,		-- ���������ID
						   EMP_ID,					-- ���ID
						   INS_TYPE_CD,				-- �������ݱ���
						   MIX_YN,					-- ȥ��������
						   HEADE_YN,				-- �ӿ�����
						   EMP_MON,					-- ����ںδ��
						   BASE_MON,				-- ������رݾ�
						   INSUR_NM,				-- ����ȸ��
						   IRP_BANK_CD,				-- ���������ڵ�[PAY_BANK_CD]
						   IRP_ACCOUNT_NO,			-- ���¹�ȣ
						   INSUR_BIZ_NO,			-- ����ڹ�ȣ
						   IRP_EXPIRATION_YMD,		-- ��������
						   STA_YMD,					-- ������
						   END_YMD,					-- ������
						   NOTE,					-- ���
						   MOD_USER_ID,				-- ������
						   MOD_DATE,				-- ������
						   TZ_CD,					-- Ÿ�����ڵ�
						   TZ_DATE					-- Ÿ�����Ͻ�
						  )
                    SELECT NEXT VALUE FOR dbo.S_REP_SEQUENCE AS REP_INSUR_MON_ID,		-- ���������ID
						   B.EMP_ID,					-- ���ID
						   CASE WHEN A.CD_RETR_ANNU = 'DB' THEN '10'
						        WHEN A.CD_RETR_ANNU = 'DC' THEN '20'
								ELSE '00'
						   END AS CALC_TYPE_CD,			-- ���걸��
						   'N' AS MIX_YN,				-- ȥ��������
						   'N' AS HEADE_YN,				-- �ӿ�����
						   0 AS EMP_MON,				-- ����ںδ��
						   0 AS BASE_MON,				-- ������رݾ�
						   A.NM_BANK_IRP AS INSUR_NM,		-- ����ȸ��
						   CASE A.CD_BANK_IRP WHEN '002' THEN '002' -- �������002 	�������
											  WHEN '003' THEN '003' -- �������003 	NULL
											  WHEN '004' THEN '004' -- ��������004 	��������
                                              WHEN '005' THEN '005' -- ��ȯ����005	KEB�ϳ�����
											  WHEN '011' THEN '011' -- �߾ӳ���011	�����߾�ȸ
											  WHEN '012' THEN '012' -- ��������012  ��������
                                              WHEN '020' THEN '020' -- �츮����020	�츮
											  WHEN '023' THEN '023' -- SC����023	SC��������(��������)023
											  WHEN '026' THEN '026' -- ��������026	��������
											  WHEN '03' THEN '03'   -- �߼ұ������03 �������
											  WHEN '031' THEN '031' -- �뱸����031	�뱸����
											  WHEN '032' THEN '032' -- �λ�����032	�λ�����
											  WHEN '034' THEN '034' -- ��������034	��������
											  WHEN '039' THEN '039' -- �泲����039	�泲����
											  WHEN '04' THEN '04'   -- ��������04	KB��������
											  WHEN '05' THEN '05'   -- ��ȯ����05	��ȯ����
											  WHEN '071' THEN '071' -- ��ü��(������ź�)071
											  WHEN '081' THEN '081' -- �ϳ�����     KEB�ϳ�����
											  WHEN '088' THEN '088' -- ��������(��������)088	��������(��������)088
											  WHEN '090' THEN '090' -- īī����ũ090	īī����ũ
											  WHEN '11' THEN '11'   -- �߾ӳ���11
											  WHEN '190' THEN '11'  -- �߾ӳ���11
											  WHEN '12' THEN '12'   -- ��������12
										      WHEN '20' THEN '20'	-- �츮����(�Ѻ�����)20
											  WHEN '304' THEN '20'  -- �츮����(�Ѻ�����)20
											  WHEN '209' THEN '209' -- �������ձ�������209
											  WHEN '218' THEN '218' -- KB����	KB����
											  WHEN '230' THEN '230' -- �̷���������230	�̷���������
											  WHEN '240' THEN '240' -- �Ｚ����240	�Ｚ����
											  WHEN '243' THEN '243' -- �ѱ���������243 �ѱ���������
											  WHEN '510' THEN '243' -- �ѱ���������243 �ѱ���������
											  WHEN '26' THEN '26'   -- ��������26	����
											  WHEN '262' THEN '262' -- ������������262	�ѱ���������
											  WHEN '269' THEN '269' -- ��ȭ����269	��ȭ����
											  WHEN '31' THEN '31'   -- �뱸����31	�뱸����
											  WHEN '311' THEN '34'  -- ��������341	��������34
											  WHEN '32' THEN '32'   -- �λ�����32	�λ�����
											  WHEN '34' THEN '34'   -- ��������34	����
											  WHEN '35' THEN '35'   -- ��������35	��������
											  WHEN '39' THEN '39'   -- �泲����39	�泲����
											  WHEN '71' THEN '71'   -- ��ü��(������ź�)71
											  WHEN '81' THEN '81'   -- �ϳ�����81
											  WHEN '88' THEN '88'   -- ��������(��������)88
											  ELSE NULL
						   END AS IRP_BANK_CD,		-- ���������ڵ�[PAY_BANK_CD]
						   A.NO_BANK_ACCNT_IRP AS IRP_ACCOUNT_NO,	-- ���¹�ȣ
						   A.BIZ_NO_IRP AS INSUR_BIZ_NO,			-- ����ڹ�ȣ
						   NULL AS IRP_EXPIRATION_YMD,		-- ��������
						   dbo.XF_TO_DATE('19000101', 'YYYYMMDD') AS STA_YMD,	-- ������
						   dbo.XF_TO_DATE('29991231', 'YYYYMMDD') AS END_YMD,	-- ������
						   NULL AS NOTE,					-- ���
						   0 AS MOD_USER_ID,				-- ������
						   dbo.XF_SYSDATE(0) AS MOD_DATE,	-- ������
						   'KST' AS TZ_CD,					-- Ÿ�����ڵ�
						   dbo.XF_SYSDATE(0) AS TZ_DATE		-- Ÿ�����Ͻ�
					  FROM [DWEHRDEV].DBO.H_PAY_MASTER A
						INNER JOIN PHM_EMP B
						   ON A.CD_COMPANY = B.COMPANY_CD
						  AND A.NO_PERSON = B.EMP_NO ;  
						  

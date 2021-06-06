DECLARE @s_type_nm nvarchar(50) = '�η���� ����'
DECLARE @t_type_nm nvarchar(50) = '�ΰǺ� ����'
--SELECT *
--FROM HRS_STD_MGR
--WHERE TYPE_NM = @s_type_nm
------ ����������(HRS_STD_MGR) ����
INSERT INTO HRS_STD_MGR(
	HRS_STD_MGR, -- ����������id
	TYPE_NM, -- ��豸��
	VIEW_CD, -- ǥ���ڵ�
	VIEW_NM, -- ǥ������
	NOTE, -- ���
	MOD_USER_ID, -- ������
	MOD_DATE, -- �����Ͻ�
	TZ_CD, -- Ÿ�����ڵ�
	TZ_DATE  -- Ÿ�����Ͻ�
)
SELECT NEXT VALUE FOR S_HRS_SEQUENCE,
       @t_type_nm AS TYPE_NM
     , VIEW_CD
	 , VIEW_NM
	 , NOTE
	 , 0 MOD_USER_ID
	 , SYSDATETIME() MOD_DATE
	 , 'KST' TZ_CD
	 , SYSDATETIME() TZ_DATE
  FROM (
		SELECT VIEW_CD, VIEW_NM, NOTE--, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE
		FROM HRS_STD_MGR
		WHERE TYPE_NM = @s_type_nm

		except

		SELECT VIEW_CD, VIEW_NM, NOTE--, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE
		FROM HRS_STD_MGR
		WHERE TYPE_NM = @t_type_nm
	) A

--SELECT *
--FROM HRS_STD_MGR
--WHERE TYPE_NM = @t_type_nm

---- ��������׸�
INSERT INTO HRS_STD_ITEM (HRS_STD_ITEM_ID, -- ��������׸�ID
		HRS_STD_MGR, -- ����������id
		ITEM_TYPE_CD, -- �׸񱸺�
		ITEM_CD, -- �׸�
		NOTE, -- ���
		MOD_USER_ID, -- ������
		MOD_DATE, -- �����Ͻ�
		TZ_CD, -- Ÿ�����ڵ�
		TZ_DATE  -- Ÿ�����Ͻ�
)
SELECT  NEXT VALUE FOR S_HRS_SEQUENCE AS HRS_STD_ITEM_ID, -- ��������׸�ID
		T.HRS_STD_MGR, -- ����������id
		A.ITEM_TYPE_CD, -- �׸񱸺�
		A.ITEM_CD, -- �׸�
		'' NOTE, -- ���
		0 MOD_USER_ID, -- ������
		SYSDATETIME() MOD_DATE, -- �����Ͻ�
		'KST' TZ_CD, -- Ÿ�����ڵ�
		SYSDATETIME() TZ_DATE -- Ÿ�����Ͻ�
		--, T.TYPE_NM, S.HRS_STD_MGR
--SELECT A.HRS_STD_MGR, A.ITEM_TYPE_CD, A.ITEM_CD, A.NOTE, S.HRS_STD_MGR, S.VIEW_CD, S.VIEW_NM,
--       T.HRS_STD_MGR, T.VIEW_CD, T.VIEW_NM
  FROM HRS_STD_ITEM A
  JOIN HRS_STD_MGR S
    ON A.HRS_STD_MGR = S.HRS_STD_MGR
   AND S.TYPE_NM = @s_type_nm
  JOIN HRS_STD_MGR T
    ON T.TYPE_NM = @t_type_nm
   AND S.VIEW_CD = T.VIEW_CD
 WHERE NOT EXISTS (SELECT 1 FROM HRS_STD_ITEM WHERE HRS_STD_MGR = T.HRS_STD_MGR AND ITEM_CD = A.ITEM_CD) 
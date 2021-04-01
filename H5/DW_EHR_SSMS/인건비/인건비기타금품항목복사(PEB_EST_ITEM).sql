/*
 * PEB_EST_ITEM 
 * �ΰǺ��Ÿ��ǰ�׸񺹻�
 */
BEGIN
	 DECLARE @v_source_company_cd NVARCHAR(100) = 'E'
	       , @v_target_company_cd NVARCHAR(100) = 'A,B,C,E,F,H,I,M,R,S,T,U,W,X,Y'
	DECLARE @TARGET_COMPANY TABLE(
		COMPANY_CD	NVARCHAR(10)
	)
	INSERT INTO @TARGET_COMPANY
	SELECT ITEMS
	FROM dbo.fn_split_array(@v_target_company_cd,',')
	WHERE Items != @v_source_company_cd

	DELETE A
	  FROM PEB_EST_ITEM A
	  WHERE EXISTS (SELECT * FROM @TARGET_COMPANY WHERE COMPANY_CD = A.COMPANY_CD)
	INSERT INTO PEB_EST_ITEM(
	PEB_EST_ITEM_ID, -- �ΰǺ����ID
	COMPANY_CD, -- ȸ���ڵ�
	PAY_ITEM_CD, -- �޿��׸��ڵ�
	STA_YMD, -- ��������
	END_YMD, -- ��������
	NOTE, -- ���
	MOD_USER_ID, -- ������
	MOD_DATE, -- ������
	TZ_CD, -- Ÿ�����ڵ�
	TZ_DATE -- Ÿ�����Ͻ�
	)
	SELECT NEXT VALUE FOR S_PEB_SEQUENCE -- A.PEB_EST_ITEM_ID -- �ΰǺ����ID
		 , B.COMPANY_CD -- ȸ���ڵ�
		 , A.PAY_ITEM_CD -- �޿��׸��ڵ�
		 , A.STA_YMD -- ��������
		 , A.END_YMD -- ��������
		 , A.NOTE -- ���
		 , A.MOD_USER_ID
		 , A.MOD_DATE
		 , A.TZ_CD
		 , A.TZ_DATE
	  FROM PEB_EST_ITEM A
	  JOIN @TARGET_COMPANY B
		ON 1 = 1
	 WHERE A.COMPANY_CD = @v_source_company_cd
END
GO
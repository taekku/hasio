USE [dwehr_H5]
BEGIN
	DECLARE @v_cd_kind nvarchar(150)	-- �ڵ�з�
	      , @v_target_company_cd nvarchar(150)  -- ȸ��
		, @b_master_copy char(1) -- ������ ���翩��
		, @b_code_copy char(1) -- ȸ�纰�ڵ� ���翩��
		, @b_code_sys_copy char(1) -- �ý����ڵ� ���翩��

	SET @v_cd_kind = 'PEB_POS_CLS_CD' -- �ڵ�з�
	SET @v_target_company_cd = 'A,B,C,E,F,H,I,M,R,S,T,U,W,X,Y' -- ������ ȸ�� -- �޸��� ����
	-----------------------------------------------------
	SET @b_master_copy = 'Y' -- Y/N  ������ ���翩��
	SET @b_code_copy = 'Y' -- Y/N ȸ�纰�ڵ� ���翩��
	SET @b_code_sys_copy = 'Y' -- Y/N �ý����ڵ� ���翩��

	DECLARE @TARGET_COMPANY TABLE(
		COMPANY_CD	NVARCHAR(10)
	)
	
	-- ==============================================================================
	-- ������ ���翩��
	-- ==============================================================================
	IF @b_master_copy = 'Y'
		BEGIN
			DELETE A
			  FROM FRM_CODE_KIND A
			 WHERE CD_KIND = @v_cd_kind
			INSERT INTO FRM_CODE_KIND(
				CD_KIND_ID, -- �ڵ�з�ID
				LOCALE_CD, -- �����ڵ�
				CD_KIND, -- �ڵ�з�
				CD_KIND_NM, -- �ڵ�з���
				STA_YMD, -- ��������
				END_YMD, -- ��������
				CHANGE_YN, -- �ڷắ�濩��(�ڷ����,�߰� ���ɿ���)
				NOTE, -- ���
				MOD_USER_ID, -- ������
				MOD_DATE, -- �����Ͻ�
				GROUP_YN  -- �׷쿩�� ( Y:�ϴ��ǳ��������Ұ�-��뿩������ / N:�ϴ����������� )
			)
			SELECT 
				NEXT VALUE FOR S_FRM_SEQUENCE	CD_KIND_ID, -- �ڵ�з�ID
				LOCALE_CD, -- �����ڵ�
				CD_KIND, -- �ڵ�з�
				CD_KIND_NM, -- �ڵ�з���
				STA_YMD, -- ��������
				END_YMD, -- ��������
				CHANGE_YN, -- �ڷắ�濩��(�ڷ����,�߰� ���ɿ���)
				NOTE, -- ���
				MOD_USER_ID, -- ������
				MOD_DATE, -- �����Ͻ�
				GROUP_YN  -- �׷쿩�� ( Y:�ϴ��ǳ��������Ұ�-��뿩������ / N:�ϴ����������� )
			  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_CODE_KIND
			  WHERE CD_KIND = @v_cd_kind
		END

	-- ==============================================================================
	-- ȸ�纰�ڵ� ���翩��
	-- ==============================================================================
	IF @b_code_copy = 'Y'
		BEGIN
			INSERT INTO @TARGET_COMPANY
			SELECT ITEMS
			  FROM dbo.fn_split_array(@v_target_company_cd,',')

			DELETE A
			  FROM FRM_CODE A
			  JOIN @TARGET_COMPANY T
			    ON A.COMPANY_CD = T.COMPANY_CD
			   AND A.CD_KIND = @v_cd_kind
			INSERT INTO FRM_CODE(
					CD_ID, -- �ڵ�id
					LOCALE_CD, -- �����ڵ�
					COMPANY_CD, -- ȸ���ڵ�(�λ翵��)
					CD_KIND, -- �ڵ�з�
					CD, -- �ڵ�
					CD_NM, -- �ڵ��
					SHORT_NM, -- �ڵ���
					FOR_NM, -- �ܱ����
					PRINT_NM, -- ��¸�
					MAIN_CD, -- ���ڵ�
					SYS_CD, -- �ý����ڵ�
					STA_YMD, -- ��������
					END_YMD, -- ��������
					ORD_NO, -- ���ļ���
					NOTE, -- ���
					MOD_USER_ID, -- ������
					MOD_DATE, -- �����Ͻ�
					LABEL_CD, -- ���ְ��� �׸�� 2016.07.13 �߰�
					GROUP_USE_YN -- �׷��뿩��( Y / N )
			)
			SELECT NEXT VALUE FOR S_FRM_SEQUENCE CD_ID, -- �ڵ�id
					A.LOCALE_CD, -- �����ڵ�
					A.COMPANY_CD, -- ȸ���ڵ�(�λ翵��)
					A.CD_KIND, -- �ڵ�з�
					A.CD, -- �ڵ�
					A.CD_NM, -- �ڵ��
					A.SHORT_NM, -- �ڵ���
					A.FOR_NM, -- �ܱ����
					A.PRINT_NM, -- ��¸�
					A.MAIN_CD, -- ���ڵ�
					A.SYS_CD, -- �ý����ڵ�
					A.STA_YMD, -- ��������
					A.END_YMD, -- ��������
					A.ORD_NO, -- ���ļ���
					A.NOTE, -- ���
					A.MOD_USER_ID, -- ������
					A.MOD_DATE, -- �����Ͻ�
					A.LABEL_CD, -- ���ְ��� �׸�� 2016.07.13 �߰�
					A.GROUP_USE_YN -- �׷��뿩��( Y / N )
			  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_CODE A
			  JOIN @TARGET_COMPANY T
			    ON A.COMPANY_CD = T.COMPANY_CD
			   AND A.CD_KIND = @v_cd_kind
		END
	-- ==============================================================================
	-- �ý����ڵ� ���翩��
	-- ==============================================================================
	IF @b_code_sys_copy = 'Y'
		BEGIN
			DELETE A
			  FROM FRM_CODE_SYS A
			 WHERE CD_KIND = @v_cd_kind
			INSERT INTO FRM_CODE_SYS(
					SYS_CD_ID, -- �ý����ڵ�ID
					LOCALE_CD, -- �����ڵ�
					CD_KIND, -- �ڵ�з�
					SYS_CD, -- �ý����ڵ�
					SYS_CD_NM, -- �ý����ڵ��
					NOTE, -- ���
					MOD_USER_ID, -- ������
					MOD_DATE, -- �����Ͻ�
					LABEL_CD -- ���ְ��� �׸�� 2016.07.13 �߰�
			)
			SELECT
					NEXT VALUE FOR S_FRM_SEQUENCE	SYS_CD_ID, -- �ý����ڵ�ID
					LOCALE_CD, -- �����ڵ�
					CD_KIND, -- �ڵ�з�
					SYS_CD, -- �ý����ڵ�
					SYS_CD_NM, -- �ý����ڵ��
					NOTE, -- ���
					MOD_USER_ID, -- ������
					MOD_DATE, -- �����Ͻ�
					LABEL_CD -- ���ְ��� �׸�� 2016.07.13 �߰�
			  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_CODE_SYS
			 WHERE CD_KIND = @v_cd_kind
		END
END
GO
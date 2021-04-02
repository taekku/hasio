BEGIN
	 DECLARE @v_source_company_cd NVARCHAR(100) = 'X'
	       , @v_target_company_cd NVARCHAR(100) = 'A,B,C,E,F,H,I,M,R,S,T,U,W,X,Y'
		   , @v_unit_cd NVARCHAR(100) = 'TBS'
		   , @v_std_kind	NVARCHAR(100) = 'TBS_DEBIS_PAY'
	DECLARE @TARGET_COMPANY TABLE(
		COMPANY_CD	NVARCHAR(10)
	)
	INSERT INTO @TARGET_COMPANY
	SELECT ITEMS
	FROM dbo.fn_split_array(@v_target_company_cd,',')
	WHERE Items != @v_source_company_cd

--������ ����
DELETE FROM FRM_UNIT_STD_HIS
WHERE FRM_UNIT_STD_MGR_ID IN (
															SELECT FRM_UNIT_STD_MGR_ID
															FROM FRM_UNIT_STD_MGR 
															WHERE COMPANY_CD IN (SELECT COMPANY_CD FROM @TARGET_COMPANY)
															AND UNIT_CD = @v_unit_cd
															AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
															)

--�������ذ��� �з�Ű
DELETE FROM FRM_UNIT_ETC
WHERE FRM_UNIT_STD_MGR_ID IN (
															SELECT FRM_UNIT_STD_MGR_ID 
															FROM FRM_UNIT_STD_MGR 
															WHERE COMPANY_CD IN (SELECT COMPANY_CD FROM @TARGET_COMPANY)
															AND UNIT_CD = @v_unit_cd
															AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
															)

--�������ذ��� �ڵ�Ű
DELETE FROM FRM_UNIT_STD_ETC
WHERE FRM_UNIT_STD_MGR_ID IN (
															SELECT FRM_UNIT_STD_MGR_ID 
															FROM FRM_UNIT_STD_MGR 
															WHERE COMPANY_CD IN (SELECT COMPANY_CD FROM @TARGET_COMPANY)
															AND UNIT_CD = @v_unit_cd
															AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
															)

DELETE FROM FRM_UNIT_STD_MGR 
							WHERE COMPANY_CD IN (SELECT COMPANY_CD FROM @TARGET_COMPANY)
							AND UNIT_CD = @v_unit_cd
							AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))


/*=============================================================================================================
�������� FRM_UNIT_STD_MGR ����
=============================================================================================================*/
	BEGIN
		INSERT INTO FRM_UNIT_STD_MGR
		SELECT 
				next VALUE FOR S_FRM_SEQUENCE ,    --���ذ���ID
				A.LOCALE_CD,    --�����ڵ�
				T.COMPANY_CD,    --�λ翵���ڵ�
				A.UNIT_CD,    --���������ڵ�
				A.KEY1,    --�з�Ű1
				A.KEY2,    --�з�Ű2
				A.KEY3,    --�з�Ű3
				A.KEY4,    --�з�Ű4
				A.KEY5,    --�з�Ű5
				A.STD_KIND,    --���غз�
				A.STD_KIND_NM,    --���غз���
				A.FUNCTION_CM,    --FUNCTION����
				A.SQL,    --SQL
				A.CHANGE_YN,    --�ڷắ�濩��
				A.NOTE,    --���
				A.MOD_USER_ID,    --������
				A.MOD_DATE,    --�����Ͻ�
				A.LABEL_CD    --�����ڵ�
		  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_MGR A
		  JOIN @TARGET_COMPANY T
		    ON 1=1
		  WHERE A.COMPANY_CD = @v_source_company_cd
							AND UNIT_CD = @v_unit_cd
							AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
	END  
  
/*=============================================================================================================
�������� FRM_UNIT_STD_HIS ����
=============================================================================================================*/
	BEGIN
		INSERT INTO FRM_UNIT_STD_HIS
		SELECT 
				next VALUE FOR S_FRM_SEQUENCE FRM_UNIT_STD_HIS_ID,    --���ذ�������ID
				C.FRM_UNIT_STD_MGR_ID,    --���ذ���ID
				B.KEY_CD1,    --Ű�ڵ�1
				B.KEY_CD2,    --Ű�ڵ�2
				B.KEY_CD3,    --Ű�ڵ�3
				B.KEY_CD4,    --Ű�ڵ�4
				B.KEY_CD5,    --Ű�ڵ�5
				B.CD1,    --�ڵ�1
				B.CD2,    --�ڵ�2
				B.CD3,    --�ڵ�3
				B.CD4,    --�ڵ�4
				B.CD5,    --�ڵ�5
				B.ETC_CD1,    --��Ÿ�ڵ�1
				B.ETC_CD2,    --��Ÿ�ڵ�2
				B.ETC_CD3,    --��Ÿ�ڵ�3
				B.ETC_CD4,    --��Ÿ�ڵ�4
				B.ETC_CD5,    --��Ÿ�ڵ�5
				B.STA_YMD,    --��������
				B.END_YMD,    --��������
				B.NOTE,    --���
				B.MOD_USER_ID,    --������
				B.MOD_DATE    --�����Ͻ�
		  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_MGR A
		 INNER JOIN [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_HIS B
		    ON A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
		 INNER JOIN FRM_UNIT_STD_MGR C
		    ON A.UNIT_CD = C.UNIT_CD
		   AND A.STD_KIND = C.STD_KIND
		   AND A.LOCALE_CD = C.LOCALE_CD
		   AND ISNULL(A.KEY1,'') = ISNULL(C.KEY1,'')
		   AND ISNULL(A.KEY2,'') = ISNULL(C.KEY2,'')
		   AND ISNULL(A.KEY3,'') = ISNULL(C.KEY3,'')
		   AND ISNULL(A.KEY4,'') = ISNULL(C.KEY4,'')
		   AND ISNULL(A.KEY5,'') = ISNULL(C.KEY5,'')
		 INNER JOIN @TARGET_COMPANY T
		   ON C.COMPANY_CD = T.COMPANY_CD
		  -- AND C.COMPANY_CD = @v_target_company_cd
		 WHERE A.COMPANY_CD = @v_source_company_cd
		AND A.UNIT_CD = @v_unit_cd
		AND A.STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
	END

/*=============================================================================================================
�������� FRM_UNIT_STD_ETC ����
=============================================================================================================*/
	BEGIN
			INSERT INTO FRM_UNIT_STD_ETC
			SELECT 
					C.FRM_UNIT_STD_MGR_ID FRM_UNIT_STD_MGR_ID,    --���ذ���ID
					B.TITLE_NM_K1,    --Ű�ڵ�1_Ÿ��Ʋ��
					B.EDIT_FORMAT_K1,    --Ű�ڵ�1_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_K1,    --Ű�ڵ�1_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_K1,    --Ű�ڵ�1_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_K1,    --Ű�ڵ�1_�ʼ�����
					B.SQLS_K1,    --Ű�ڵ�1_�˻�SQL����
					B.CD_KIND_K1,    --Ű�ڵ�1_�з�
					B.TITLE_NM_K2,    --Ű�ڵ�2_Ÿ��Ʋ��
					B.EDIT_FORMAT_K2,    --Ű�ڵ�2_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_K2,    --Ű�ڵ�2_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_K2,    --Ű�ڵ�2_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_K2,    --Ű�ڵ�2_�ʼ�����
					B.SQLS_K2,    --Ű�ڵ�2_�˻�SQL����
					B.CD_KIND_K2,    --Ű�ڵ�2_�з�
					B.TITLE_NM_K3,    --Ű�ڵ�3_Ÿ��Ʋ��
					B.EDIT_FORMAT_K3,    --Ű�ڵ�3_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_K3,    --Ű�ڵ�3_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_K3,    --Ű�ڵ�3_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_K3,    --Ű�ڵ�3_�ʼ�����
					B.SQLS_K3,    --Ű�ڵ�3_�˻�SQL����
					B.CD_KIND_K3,    --Ű�ڵ�3_�з�
					B.TITLE_NM_K4,    --Ű�ڵ�4_Ÿ��Ʋ��
					B.EDIT_FORMAT_K4,    --Ű�ڵ�4_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_K4,    --Ű�ڵ�4_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_K4,    --Ű�ڵ�4_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_K4,    --Ű�ڵ�4_�ʼ�����
					B.SQLS_K4,    --Ű�ڵ�4_�˻�SQL����
					B.CD_KIND_K4,    --Ű�ڵ�4_�з�
					B.TITLE_NM_K5,    --Ű�ڵ�5_Ÿ��Ʋ��
					B.EDIT_FORMAT_K5,    --Ű�ڵ�5_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_K5,    --Ű�ڵ�5_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_K5,    --Ű�ڵ�5_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_K5,    --Ű�ڵ�5_�ʼ�����
					B.SQLS_K5,    --Ű�ڵ�5_�˻�SQL����
					B.CD_KIND_K5,    --Ű�ڵ�5_�з�
					B.TITLE_NM_H1,    --�ڵ�1_Ÿ��Ʋ��
					B.EDIT_FORMAT_H1,    --�ڵ�1_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_H1,    --�ڵ�1_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_H1,    --�ڵ�1_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_H1,    --�ڵ�1_�ʼ�����
					B.SQLS_H1,    --�ڵ�1_�˻�SQL����
					B.CD_KIND_H1,    --�ڵ�1_�з�
					B.TITLE_NM_H2,    --�ڵ�2_Ÿ��Ʋ��
					B.EDIT_FORMAT_H2,    --�ڵ�2_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_H2,    --�ڵ�2_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_H2,    --�ڵ�2_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_H2,    --�ڵ�2_�ʼ�����
					B.SQLS_H2,    --�ڵ�2_�˻�SQL����
					B.CD_KIND_H2,    --�ڵ�2_�з�
					B.TITLE_NM_H3,    --�ڵ�3_Ÿ��Ʋ��
					B.EDIT_FORMAT_H3,    --�ڵ�3_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_H3,    --�ڵ�3_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_H3,    --�ڵ�3_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_H3,    --�ڵ�3_�ʼ�����
					B.SQLS_H3,    --�ڵ�3_�˻�SQL����
					B.CD_KIND_H3,    --�ڵ�3_�з�
					B.TITLE_NM_H4,    --�ڵ�4_Ÿ��Ʋ��
					B.EDIT_FORMAT_H4,    --�ڵ�4_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_H4,    --�ڵ�4_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_H4,    --�ڵ�4_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_H4,    --�ڵ�4_�ʼ�����
					B.SQLS_H4,    --�ڵ�4_�˻�SQL����
					B.CD_KIND_H4,    --�ڵ�4_�з�
					B.TITLE_NM_H5,    --�ڵ�5_Ÿ��Ʋ��
					B.EDIT_FORMAT_H5,    --�ڵ�5_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_H5,    --�ڵ�5_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_H5,    --�ڵ�5_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_H5,    --�ڵ�5_�ʼ�����
					B.SQLS_H5,    --�ڵ�5_�˻�SQL����
					B.CD_KIND_H5,    --�ڵ�5_�з�
					B.TITLE_NM_U1,    --��Ÿ�ڵ�1_Ÿ��Ʋ��1
					B.EDIT_FORMAT_U1,    --��Ÿ�ڵ�1_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_U1,    --��Ÿ�ڵ�1_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_U1,    --��Ÿ�ڵ�1_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_U1,    --��Ÿ�ڵ�1_�ʼ�����
					B.SQLS_U1,    --��Ÿ�ڵ�1_�˻�SQL����
					B.CD_KIND_U1,    --��Ÿ�ڵ�1_�з�
					B.TITLE_NM_U2,    --��Ÿ�ڵ�2_Ÿ��Ʋ��
					B.EDIT_FORMAT_U2,    --��Ÿ�ڵ�2_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_U2,    --��Ÿ�ڵ�2_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_U2,    --��Ÿ�ڵ�2_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_U2,    --��Ÿ�ڵ�2_�ʼ�����
					B.SQLS_U2,    --��Ÿ�ڵ�2_�˻�SQL����
					B.CD_KIND_U2,    --��Ÿ�ڵ�2_�з�
					B.TITLE_NM_U3,    --��Ÿ�ڵ�3_Ÿ��Ʋ��1
					B.EDIT_FORMAT_U3,    --��Ÿ�ڵ�3_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_U3,    --��Ÿ�ڵ�3_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_U3,    --��Ÿ�ڵ�3_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_U3,    --��Ÿ�ڵ�3_�ʼ�����
					B.SQLS_U3,    --��Ÿ�ڵ�3_�˻�SQL����
					B.CD_KIND_U3,    --��Ÿ�ڵ�3_�з�
					B.TITLE_NM_U4,    --��Ÿ�ڵ�4_Ÿ��Ʋ��1
					B.EDIT_FORMAT_U4,    --��Ÿ�ڵ�4_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_U4,    --��Ÿ�ڵ�4_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_U4,    --��Ÿ�ڵ�4_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_U4,    --��Ÿ�ڵ�4_�ʼ�����
					B.SQLS_U4,    --��Ÿ�ڵ�4_�˻�SQL����
					B.CD_KIND_U4,    --��Ÿ�ڵ�4_�з�
					B.TITLE_NM_U5,    --��Ÿ�ڵ�5_Ÿ��Ʋ��1
					B.EDIT_FORMAT_U5,    --��Ÿ�ڵ�5_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
					B.ALIGN_U5,    --��Ÿ�ڵ�5_�¿�����(L:����/C:�߾�/R:������)
					B.FORM_EDIT_U5,    --��Ÿ�ڵ�5_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
					B.MAN_YN_U5,    --��Ÿ�ڵ�5_�ʼ�����
					B.SQLS_U5,    --��Ÿ�ڵ�5_�˻�SQL����
					B.CD_KIND_U5,    --��Ÿ�ڵ�5_�з�
					B.NOTE,    --���
					B.MOD_USER_ID,    --������
					B.MOD_DATE,    --�����Ͻ�
					B.LABEL_CD_K1,    --Ű�ڵ�1_�����ڵ�
					B.LABEL_CD_K2,    --Ű�ڵ�2_�����ڵ�
					B.LABEL_CD_K3,    --Ű�ڵ�3_�����ڵ�
					B.LABEL_CD_K4,    --Ű�ڵ�4_�����ڵ�
					B.LABEL_CD_K5,    --Ű�ڵ�5_�����ڵ�
					B.LABEL_CD_H1,    --�ڵ�1_�����ڵ�
					B.LABEL_CD_H2,    --�ڵ�2_�����ڵ�
					B.LABEL_CD_H3,    --�ڵ�3_�����ڵ�
					B.LABEL_CD_H4,    --�ڵ�4_�����ڵ�
					B.LABEL_CD_H5,    --�ڵ�5_�����ڵ�
					B.LABEL_CD_U1,    --��Ÿ�ڵ�1_�����ڵ�
					B.LABEL_CD_U2,    --��Ÿ�ڵ�2_�����ڵ�
					B.LABEL_CD_U3,    --��Ÿ�ڵ�3_�����ڵ�
					B.LABEL_CD_U4,    --��Ÿ�ڵ�4_�����ڵ�
					B.LABEL_CD_U5    --��Ÿ�ڵ�5_�����ڵ�
			  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_MGR A
			 INNER JOIN [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_ETC B
			    ON A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
			 INNER JOIN FRM_UNIT_STD_MGR C
			    ON A.UNIT_CD = C.UNIT_CD
			   AND A.STD_KIND = C.STD_KIND
			   AND A.LOCALE_CD = C.LOCALE_CD
			   AND ISNULL(A.KEY1,'') = ISNULL(C.KEY1,'')
			   AND ISNULL(A.KEY2,'') = ISNULL(C.KEY2,'')
			   AND ISNULL(A.KEY3,'') = ISNULL(C.KEY3,'')
			   AND ISNULL(A.KEY4,'') = ISNULL(C.KEY4,'')
			   AND ISNULL(A.KEY5,'') = ISNULL(C.KEY5,'')
			 INNER JOIN @TARGET_COMPANY T
			   ON C.COMPANY_CD = T.COMPANY_CD
			  -- AND C.COMPANY_CD = @v_target_company_cd
			 WHERE A.COMPANY_CD = @v_source_company_cd
		AND A.UNIT_CD = @v_unit_cd
		AND A.STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
	END

	
	BEGIN
		INSERT FRM_UNIT_ETC  -- �������з�Ű����  
		(       
		   FRM_UNIT_STD_MGR_ID            -- ���ذ���ID
		 , TITLE_NM1                      -- �з�Ű1_Ÿ��Ʋ��
		 , EDIT_FORMAT1                   -- �з�Ű1_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
		 , ALIGN1                         -- �з�Ű1_�¿�����(L:����/C:�߾�/R:������)
		 , FORM_EDIT1                     -- �з�Ű1_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
		 , MAN_YN1                        -- �з�Ű1_�ʼ�����
		 , SQLS1                          -- �з�Ű1_�˻�SQL����
		 , TITLE_NM2                      -- �з�Ű2_Ÿ��Ʋ��
		 , EDIT_FORMAT2                   -- �з�Ű2_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
		 , ALIGN2                         -- �з�Ű2_�¿�����(L:����/C:�߾�/R:������)
		 , FORM_EDIT2                     -- �з�Ű2_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
		 , MAN_YN2                        -- �з�Ű2_�ʼ�����
		 , SQLS2                          -- �з�Ű2_�˻�SQL����
		 , TITLE_NM3                      -- �з�Ű3_Ÿ��Ʋ��
		 , EDIT_FORMAT3                   -- �з�Ű3_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
		 , ALIGN3                         -- �з�Ű3_�¿�����(L:����/C:�߾�/R:������)
		 , FORM_EDIT3                     -- �з�Ű3_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
		 , MAN_YN3                        -- �з�Ű3_�ʼ�����
		 , SQLS3                          -- �з�Ű3_�˻�SQL����
		 , TITLE_NM4                      -- �з�Ű4_Ÿ��Ʋ��
		 , EDIT_FORMAT4                   -- �з�Ű4_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
		 , ALIGN4                         -- �з�Ű4_�¿�����(L:����/C:�߾�/R:������)
		 , FORM_EDIT4                     -- �з�Ű4_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
		 , MAN_YN4                        -- �з�Ű4_�ʼ�����
		 , SQLS4                          -- �з�Ű4_�˻�SQL����
		 , TITLE_NM5                      -- �з�Ű5_Ÿ��Ʋ��
		 , EDIT_FORMAT5                   -- �з�Ű5_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
		 , ALIGN5                         -- �з�Ű5_�¿�����(L:����/C:�߾�/R:������)
		 , FORM_EDIT5                     -- �з�Ű5_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
		 , MAN_YN5                        -- �з�Ű5_�ʼ�����
		 , SQLS5                          -- �з�Ű5_�˻�SQL����
		 , NOTE                           -- ���
		 , MOD_USER_ID                    -- ������
		 , MOD_DATE                       -- �����Ͻ�
		 , TZ_CD                          -- Ÿ�����ڵ�
		 , TZ_DATE                        -- Ÿ�����Ͻ�
		 , LABEL_CD1                      -- �з�Ű1_�����ڵ�
		 , LABEL_CD2                      -- �з�Ű2_�����ڵ�
		 , LABEL_CD3                      -- �з�Ű3_�����ڵ�
		 , LABEL_CD4                      -- �з�Ű4_�����ڵ�
		 , LABEL_CD5                      -- �з�Ű5_�����ڵ�
		) 
		SELECT 
				   C.FRM_UNIT_STD_MGR_ID
		     , B.TITLE_NM1                      -- �з�Ű1_Ÿ��Ʋ��
		     , B.EDIT_FORMAT1                   -- �з�Ű1_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
		     , B.ALIGN1                         -- �з�Ű1_�¿�����(L:����/C:�߾�/R:������)
		     , B.FORM_EDIT1                     -- �з�Ű1_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
		     , B.MAN_YN1                        -- �з�Ű1_�ʼ�����
		     , B.SQLS1                          -- �з�Ű1_�˻�SQL����
		     , B.TITLE_NM2                      -- �з�Ű2_Ÿ��Ʋ��
		     , B.EDIT_FORMAT2                   -- �з�Ű2_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
		     , B.ALIGN2                         -- �з�Ű2_�¿�����(L:����/C:�߾�/R:������)
		     , B.FORM_EDIT2                     -- �з�Ű2_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
		     , B.MAN_YN2                        -- �з�Ű2_�ʼ�����
		     , B.SQLS2                          -- �з�Ű2_�˻�SQL����
		     , B.TITLE_NM3                      -- �з�Ű3_Ÿ��Ʋ��
		     , B.EDIT_FORMAT3                   -- �з�Ű3_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
		     , B.ALIGN3                         -- �з�Ű3_�¿�����(L:����/C:�߾�/R:������)
		     , B.FORM_EDIT3                     -- �з�Ű3_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
		     , B.MAN_YN3                        -- �з�Ű3_�ʼ�����
		     , B.SQLS3                          -- �з�Ű3_�˻�SQL����
		     , B.TITLE_NM4                      -- �з�Ű4_Ÿ��Ʋ��
		     , B.EDIT_FORMAT4                   -- �з�Ű4_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
		     , B.ALIGN4                         -- �з�Ű4_�¿�����(L:����/C:�߾�/R:������)
		     , B.FORM_EDIT4                     -- �з�Ű4_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
		     , B.MAN_YN4                        -- �з�Ű4_�ʼ�����
		     , B.SQLS4                          -- �з�Ű4_�˻�SQL����
		     , B.TITLE_NM5                      -- �з�Ű5_Ÿ��Ʋ��
		     , B.EDIT_FORMAT5                   -- �з�Ű5_EDIT����(1:�ؽ�Ʈ/2:����/3:����/4:�ݾ�)
		     , B.ALIGN5                         -- �з�Ű5_�¿�����(L:����/C:�߾�/R:������)
		     , B.FORM_EDIT5                     -- �з�Ű5_�˻�����(1:�����Է�/2:�޺�/3:�˾�)
		     , B.MAN_YN5                        -- �з�Ű5_�ʼ�����
		     , B.SQLS5                          -- �з�Ű5_�˻�SQL����
		     , B.NOTE                           -- ���
		     , B.MOD_USER_ID                    -- ������
		     , B.MOD_DATE                       -- �����Ͻ�
		     , B.TZ_CD                          -- Ÿ�����ڵ�
		     , B.TZ_DATE                        -- Ÿ�����Ͻ�
		     , B.LABEL_CD1                      -- �з�Ű1_�����ڵ�
		     , B.LABEL_CD2                      -- �з�Ű2_�����ڵ�
		     , B.LABEL_CD3                      -- �з�Ű3_�����ڵ�
		     , B.LABEL_CD4                      -- �з�Ű4_�����ڵ�
		     , B.LABEL_CD5                      -- �з�Ű5_�����ڵ�
		  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_MGR A
		 INNER JOIN [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_ETC B
		    ON A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
		 INNER JOIN FRM_UNIT_STD_MGR C
		    ON A.UNIT_CD = C.UNIT_CD
		   AND A.STD_KIND = C.STD_KIND
		   AND A.LOCALE_CD = C.LOCALE_CD
		   AND ISNULL(A.KEY1,'') = ISNULL(C.KEY1,'')
		   AND ISNULL(A.KEY2,'') = ISNULL(C.KEY2,'')
		   AND ISNULL(A.KEY3,'') = ISNULL(C.KEY3,'')
		   AND ISNULL(A.KEY4,'') = ISNULL(C.KEY4,'')
		   AND ISNULL(A.KEY5,'') = ISNULL(C.KEY5,'')
		 INNER JOIN @TARGET_COMPANY T
		   ON C.COMPANY_CD = T.COMPANY_CD
		  -- AND C.COMPANY_CD = @v_target_company_cd
		 WHERE A.COMPANY_CD = @v_source_company_cd
		AND A.UNIT_CD = @v_unit_cd
		AND A.STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
	END
  

END   
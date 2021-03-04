DECLARE @company_cd nvarchar(10)
      , @locale_cd nvarchar(10)
      , @emp_no nvarchar(10)
set @company_cd = 'E'
set @locale_cd = 'KO'
set @emp_no = '20140002'
SELECT 1 AS IDID
     , EMP.EMP_ID -- ���ID
     , EMP.EMP_NO -- �����ȣ
     , EMP.EMP_NM -- ����
	   , EMP.ORG_CD -- �μ�
     , dbo.F_FRM_ORM_ORG_NM( EMP.ORG_ID, EMP.LOCALE_CD, dbo.XF_SYSDATE(0), '10' ) AS ORG_CD -- �μ��ڵ�
     , dbo.F_FRM_ORM_ORG_NM( EMP.ORG_ID, EMP.LOCALE_CD, dbo.XF_SYSDATE(0), '11' ) AS ORG_NM -- �μ���
	 , dbo.F_PAY_GET_COST( EMP.COMPANY_CD, EMP.EMP_ID, EMP.ORG_ID, dbo.XF_SYSDATE(0), '1') AS COST_CD -- �ڽ�Ʈ����
     , dbo.F_FRM_CODE_NM( EMP.COMPANY_CD, EMP.LOCALE_CD, 'PHM_POS_CD', EMP.POS_CD, dbo.XF_SYSDATE(0), '1') AS POS_NM -- ����
     , dbo.F_FRM_CODE_NM( EMP.COMPANY_CD, EMP.LOCALE_CD, 'PHM_POS_GRD_CD', EMP.POS_GRD_CD, dbo.XF_SYSDATE(0), '1') AS POS_GRD_NM -- ����
     , dbo.F_FRM_CODE_NM( EMP.COMPANY_CD, EMP.LOCALE_CD, 'PHM_POS_GRD_CD', EMP.POS_GRD_CD, dbo.XF_SYSDATE(0), '1') AS PAY_ITEM_NM -- �޿��׸��
     , EMP.ORG_CD -- �����ڵ�
     , dbo.F_FRM_ORM_ORG_NM( ORG_ID, LOCALE_CD, dbo.XF_SYSDATE(0), '11' ) AS ORG_NM -- ������
     , EMP.HIRE_YMD -- �Ի�����
	 , dbo.F_ORM_ORG_BIZ(EMP.ORG_ID, GETDATE(), 'PAY') PAY_BIZ_CD -- ���������
	-- , dbo.F_PHM_EMP_ORDER(COMPANY_CD, LOCALE_CD, EMP_ID, dbo.XF_SYSDATE(0), '1') AS ORDERING
  FROM (SELECT A.*,
			   (CASE WHEN IN_OFFI_YN = 'Y' THEN dbo.XF_SYSDATE(0) 
               WHEN IN_OFFI_YN = 'N' THEN dbo.XF_LEAST_D( dbo.XF_NVL_D(RETIRE_YMD,dbo.XF_TO_DATE('29991231','yyyymmdd')), dbo.XF_SYSDATE(0), NULL, NULL )
               ELSE dbo.XF_SYSDATE(0) END ) AS BASE_YMD
        FROM VI_FRM_PHM_EMP A ) EMP
 WHERE COMPANY_CD = @company_cd
   AND LOCALE_CD =  @locale_cd
   AND EMP.IN_OFFI_YN = 'Y'
   AND EMP.EMP_NO = @emp_no
   AND (:pay_group_id IS NULL OR dbo.F_PAY_GROUP_CHK(:pay_group_id, EMP.EMP_ID, NULL) = :pay_group_id
 --ORDER BY dbo.F_PHM_EMP_ORDER(:company_cd, :locale_cd, EMP.EMP_ID, dbo.XF_SYSDATE(0), '1')
 --ORDER BY dbo.F_PHM_EMP_ORDER(:company_cd, :locale_cd, EMP.EMP_ID, dbo.XF_TRUNC_D(dbo.XF_SYSDATE(0)), '1')
 ORDER BY dbo.F_FRM_CODE_NM( EMP.COMPANY_CD, EMP.LOCALE_CD, 'PHM_POS_GRD_CD', EMP.POS_GRD_CD, dbo.XF_SYSDATE(0), 'O')
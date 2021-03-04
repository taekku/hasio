
 --ORDER BY dbo.F_PHM_EMP_ORDER(:company_cd, :locale_cd, EMP.EMP_ID, dbo.XF_SYSDATE(0), '1')
 --ORDER BY dbo.F_PHM_EMP_ORDER(:company_cd, :locale_cd, EMP.EMP_ID, dbo.XF_TRUNC_D(dbo.XF_SYSDATE(0)), '1')
 ORDER BY dbo.F_FRM_CODE_NM( EMP.COMPANY_CD, EMP.LOCALE_CD, 'PHM_POS_GRD_CD', EMP.POS_GRD_CD, dbo.XF_SYSDATE(0), 'O')
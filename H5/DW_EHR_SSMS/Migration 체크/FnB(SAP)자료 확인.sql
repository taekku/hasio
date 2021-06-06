--SELECT *
--FROM CNV_PAY_WORK
--WHERE PROGRAM_NM LIKE 'P_CNV_PAY_PAYROLL_FnB%'
--ORDER BY PARAMS

--SELECT A.CNV_PAY_WORK_ID, KEYS, ERR_MSG--, LOG_DATE
--  FROM CNV_PAY_WORK_LOG A
--  JOIN CNV_PAY_WORK B
--    ON A.CNV_PAY_WORK_ID = B.CNV_PAY_WORK_ID
--WHERE PROGRAM_NM LIKE 'P_CNV_PAY_PAYROLL_FnB%'
--ORDER BY PARAMS
with WORK as (
SELECT A.CNV_PAY_WORK_ID, KEYS, ERR_MSG--, LOG_DATE
     , (SELECT SUBSTRING(Items, CHARINDEX('=', Items) + 1, LEN(Items)) FROM dbo.fn_split_array(KEYS,',') WHERE Items LIKE '@sap_kind1%') sap_kind1
     , (SELECT SUBSTRING(Items, CHARINDEX('=', Items) + 1, LEN(Items)) FROM dbo.fn_split_array(KEYS,',') WHERE Items LIKE '@sap_kind2%') sap_kind2
     , (SELECT SUBSTRING(Items, CHARINDEX('=', Items) + 1, LEN(Items)) FROM dbo.fn_split_array(KEYS,',') WHERE Items LIKE '@dt_prov%') dt_prov
     , (SELECT SUBSTRING(Items, CHARINDEX('=', Items) + 1, LEN(Items)) FROM dbo.fn_split_array(KEYS,',') WHERE Items LIKE '@pay_type_cd%') pay_type_cd
     , (SELECT SUBSTRING(Items, CHARINDEX('=', Items) + 1, LEN(Items)) FROM dbo.fn_split_array(KEYS,',') WHERE Items LIKE '@cd_paygp%') cd_paygp
     , SUBSTRING(ERR_MSG, 128, 5) EMP_ID
  FROM CNV_PAY_WORK_LOG A
  JOIN CNV_PAY_WORK B
    ON A.CNV_PAY_WORK_ID = B.CNV_PAY_WORK_ID
WHERE PROGRAM_NM LIKE 'P_CNV_PAY_PAYROLL_FnB%'
AND FORMAT(B.STA_TIME, 'yyyyMMdd') <= '20210524'
)
SELECT A.sap_kind1, A.sap_kind2, dt_prov
     , pay_type_cd
	 , (select CD_NM FROM FRM_CODE WHERE COMPANY_CD='F' AND CD_KIND='PAY_TYPE_CD' AND CD = A.pay_type_cd) AS PAY_TYPE_NM
     , cd_paygp
	 , (select CD_NM FROM FRM_CODE WHERE COMPANY_CD='F' AND CD_KIND='PAY_GROUP_CD' AND CD = A.cd_paygp) AS PAY_GROUP_NM
	 , EMP.EMP_NO
	 , EMP.EMP_NM
--  INTO CNV_PAY_FNB_DUP
  FROM WORK A
  JOIN VI_FRM_PHM_EMP EMP
    ON A.EMP_ID = EMP.EMP_ID
   AND EMP.LOCALE_CD='KO'
 ORDER BY dt_prov, sap_kind1, sap_kind2

SELECT *
--DELETE A
--UPDATE A SET SAP_KIND2=''
  FROM CNV_PAY_DTL_SAP A
  JOIN CNV_PAY_FNB_DUP B
    ON 1=1
	AND A.SAP_KIND1 = B.sap_kind1
   --AND A.SAP_KIND2 = B.sap_kind2
   --AND B.sap_kind2 = ''
   AND A.DT_PROV = B.dt_prov
   AND A.CD_PAYGP = B.cd_paygp
   AND A.EMP_NO = B.EMP_NO
WHERE 1=1
  AND B.PAY_GROUP_NM='창원생산'
  AND A.DT_PROV = '20161231'
  AND A.SAP_KIND1 = 'B'
  AND A.SAP_KIND2 = '1'
ORDER BY CNV_PAY_DTL_SAP_ID


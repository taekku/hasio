--select *
--from PAY_PAY_YMD ymd
--join PAY_PAYROLL pay
--on ymd.PAY_YMD_ID = pay.PAY_YMD_ID
--where ymd.COMPANY_CD='H'
--and ymd.PAY_YM='202106'
--AND pay.JOB_POSITION_CD IS NULL

SELECT DISTINCT CD_PAYGP, NM_PAYGP
FROM CNV_PAY_TYPE_SAP_FINAL
--WHERE DT_PROV >= '20210101'
WHERE FORMAT(DT_PROV, 'yyyy') = '2021'
AND FORMAT(DT_PROV, 'yyyyMM') BETWEEN '202101' AND '202105'
--AND SAP_KIND1 = 'B'
AND SYS_CD='007'
--AND CD_PAYGP='F11'


SELECT *
FROM CNV_PAY_TYPE_SAP_FINAL
--WHERE DT_PROV >= '20210101'
WHERE FORMAT(DT_PROV, 'yyyy') = '2021'
AND FORMAT(DT_PROV, 'yyyyMM') BETWEEN '202101' AND '202105'
--AND SAP_KIND1 = 'B'
AND SYS_CD='007'
--AND CD_PAYGP='F11'

UPDATE A SET PAY_TYPE_CD = CASE WHEN CD_PAYGP='F11' THEN '105'
                                WHEN CD_PAYGP='F21' THEN '125'
                                WHEN CD_PAYGP='F31' THEN '145'
                                WHEN CD_PAYGP='F37' THEN '265'
                                WHEN CD_PAYGP='F40' THEN '325'
                                WHEN CD_PAYGP='F41' THEN '345'
                                WHEN CD_PAYGP='F42' THEN '365'
                                WHEN CD_PAYGP='F32' THEN '165'
                                WHEN CD_PAYGP='F33' THEN '185'
                                WHEN CD_PAYGP='F35' THEN '225'
								ELSE PAY_TYPE_CD END
           , PAY_TYPE_NM = CASE WHEN CD_PAYGP='F11' THEN '퇴직월급여_관리'
                                WHEN CD_PAYGP='F21' THEN '퇴직월급여_SC'
                                WHEN CD_PAYGP='F31' THEN '퇴직월급여_창원생산'
                                WHEN CD_PAYGP='F37' THEN '퇴직월급여_아산생산'
                                WHEN CD_PAYGP='F40' THEN '퇴직월급여_수원생산'
                                WHEN CD_PAYGP='F41' THEN '퇴직월급여_강진생산'
                                WHEN CD_PAYGP='F42' THEN '퇴직월급여_정읍생산'
                                WHEN CD_PAYGP='F32' THEN '퇴직월급여_성남생산'
                                WHEN CD_PAYGP='F33' THEN '퇴직월급여_광주생산'
                                WHEN CD_PAYGP='F35' THEN '퇴직월급여_연천생산'
								ELSE PAY_TYPE_NM END
FROM CNV_PAY_TYPE_SAP_FINAL A
--WHERE DT_PROV >= '20210101'
WHERE FORMAT(DT_PROV, 'yyyy') = '2021'
AND FORMAT(DT_PROV, 'yyyyMM') BETWEEN '202101' AND '202104'
--AND SAP_KIND1 = 'B'
AND SYS_CD='007'
--AND CD_PAYGP='F11'

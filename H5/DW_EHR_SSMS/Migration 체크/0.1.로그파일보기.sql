SELECT *
--DELETE A
  FROM CNV_PAY_WORK A
-- WHERE CNV_PAY_WORK_ID=1505
 WHERE PROGRAM_NM LIKE 'P_CNV_PAY_PAYROLL_FnB%'
   --AND PARAMS LIKE '2,@company_cd=A%'
   --AND PARAMS LIKE '2,@company_cd=T%'
   --AND PARAMS LIKE '2,@company_cd=W%'
   --AND PARAMS LIKE '3,@company_cd=F%'
   AND PARAMS LIKE '4,@company_cd=F%'
   --AND PARAMS LIKE '3,@company_cd=C%'
   --AND PARAMS LIKE '3,@company_cd=E%'
   --AND PARAMS LIKE '3,@company_cd=H%'
   --AND PARAMS LIKE '3,@company_cd=M%'
   AND FORMAT(STA_TIME, 'yyyyMMdd')  = '20210607'
   --AND CNV_PAY_WORK_ID <= 1684
   --AND CNT_FAIL > 0
   --AND CNV_PAY_WORK_ID IN (1507)
ORDER BY PROGRAM_NM, PARAMS, CNV_PAY_WORK_ID


SELECT A.CNV_PAY_WORK_ID, KEYS, ERR_MSG--, LOG_DATE
--DELETE A
  FROM CNV_PAY_WORK_LOG A
  JOIN CNV_PAY_WORK B
    ON A.CNV_PAY_WORK_ID = B.CNV_PAY_WORK_ID
 WHERE B.PROGRAM_NM LIKE 'P_CNV_PAY_PAYROLL_FnB%'
   --AND PARAMS LIKE '2,@company_cd=T%'
   --AND B.PARAMS LIKE '2,@company_cd=W%'
   --AND PARAMS LIKE '3,@company_cd=H%'
   --AND PARAMS LIKE '3,@company_cd=E%'
   AND PARAMS LIKE '4,@company_cd=F%'
   --AND PARAMS LIKE '3,@company_cd=C%'
   and CNT_TRY > 0
   AND FORMAT(STA_TIME, 'yyyyMMdd') = '20210607'


--SELECT *
----DELETE A
--  FROM CNV_PAY_WORK_LOG A
-- WHERE NOT EXISTS(SELECT 1 FROM CNV_PAY_WORK WHERE CNV_PAY_WORK_ID = A.CNV_PAY_WORK_ID)

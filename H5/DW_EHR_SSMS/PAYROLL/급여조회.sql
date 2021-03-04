SELECT 
   A.SUB_COMPANY_NM, 
   A.SUB_COMPANY, 
   A.EMP_NO, 
   A.EMP_NM, 
   A.P01, 
   A.P02, 
   A.P03, 
   A.P04, 
   A.P05, 
   A.P06, 
   A.D51, 
   A.D52, 
   A.D50, 
   A.D53, 
   A.D54, 
   A.D55, 
   A.D24, 
   A.P07, 
   A.P08, 
   A.P09, 
   A.P10, 
   A.P12, 
   A.P11, 
   A.D01, 
   A.D02, 
   A.D03, 
   A.D04, 
   A.P17, 
   A.P14, 
   A.P15, 
   A.P16, 
   A.P24, 
   A.D08, 
   A.D10, 
   A.D11, 
   A.D12, 
   A.D13, 
   A.D14, 
   A.D15, 
   A.D16, 
   A.D17, 
   A.D18, 
   A.D19, 
   A.P20, 
   A.P21, 
   A.P22, 
   A.P23, 
   A.D30, 
   A.D31, 
   A.D32, 
   A.D33, 
   A.D34, 
   A.D35, 
   A.D36, 
   A.PSUM, 
   A.D37, 
   A.D38, 
   A.DSUM, 
   A.REAL_AMT, 
   B.HIRE_YMD, 
   B.RETIRE_YMD
FROM 
   (
      SELECT 
         dbo.F_FRM_SUB_COMPANY_VALUE(A.SUB_COMPANY_CD, '1') AS SUB_COMPANY_NM, 
         A.SUB_COMPANY_CD AS SUB_COMPANY, 
         C.EMP_NO, 
         C.EMP_NM, 
         /*         , F_FRM_ORM_ORG_NM(A.ORG_ID, X.LOCALE_CD, B.PAY_YMD, 'S0') LOS_ID           , F_FRM_ORM_ORG_NM(A.ORG_ID, X.LOCALE_CD, B.PAY_YMD, 'S2') LOS           , F_FRM_ORM_ORG_NM(A.ORG_ID, X.LOCALE_CD, B.PAY_YMD, '10') ORG           , F_FRM_CODE_NM(B.COMPANY_CD, X.LOCALE_CD, 'PHM_POS_CD', A.POS_CD, B.PAY_YMD, '1') POS_NM           , F_PHM_PARTNER2(B.COMPANY_CD, 'KO', A.EMP_ID , '42', B.PAY_YMD) JOB_GROUP_CD2           , C.GENDER_CD           , NVL((SELECT BIZ_CD FROM V_INT_Y10_BIZ_AUTH                   WHERE SUB_COMPANY_CD = A.SUB_COMPANY_CD                     AND BON_ORG_CD = F_FRM_ORM_ORG_NM(A.ORG_ID, X.LOCALE_CD, B.PAY_YMD, '10'))                ,(SELECT BIZ_CD FROM V_INT_Y10_BIZ_AUTH                   WHERE SUB_COMPANY_CD = A.SUB_COMPANY_CD                     AND BON_ORG_CD = F_FRM_ORM_ORG_NM(A.ORG_ID, X.LOCALE_CD, B.PAY_YMD, 'T1'))) BIZ_CD*/sum(B.P01) AS P01, 
         sum(B.P02) AS P02, 
         sum(B.P03) AS P03, 
         sum(B.P04) AS P04, 
         sum(B.P05) AS P05, 
         sum(B.P06) AS P06, 
         sum(B.D51) AS D51, 
         sum(B.D52) AS D52, 
         sum(B.D50) AS D50, 
         sum(B.D53) AS D53, 
         sum(B.D54) AS D54, 
         sum(B.D55) AS D55, 
         sum(B.D24) AS D24, 
         sum(B.P07) AS P07, 
         sum(B.P08) AS P08, 
         sum(B.P09) AS P09, 
         sum(B.P10) AS P10, 
         sum(B.P12) AS P12, 
         sum(B.P11) AS P11, 
         sum(B.D01) AS D01, 
         sum(B.D02) AS D02, 
         sum(B.D03) AS D03, 
         sum(B.D04) AS D04, 
         sum(B.P17) AS P17, 
         sum(B.P14) AS P14, 
         sum(B.P15) AS P15, 
         sum(B.P16) AS P16, 
         sum(B.P24) AS P24, 
         sum(B.D08) AS D08, 
         /*, SUM(D09) D09*/sum(B.D10) AS D10, 
         CAST(sum(B.D11) AS float(53)) + CAST(sum(B.D09)/*교육비공제에 GBC교육비 포함 조회*/ AS float(53)) AS D11, 
         sum(B.D12) AS D12, 
         sum(B.D13) AS D13, 
         sum(B.D14) AS D14, 
         sum(B.D15) AS D15, 
         sum(B.D16) AS D16, 
         sum(B.D17) AS D17, 
         sum(B.D18) AS D18, 
         sum(B.D19) AS D19, 
         sum(B.P20) AS P20, 
         sum(B.P21) AS P21, 
         sum(B.P22) AS P22, 
         sum(B.P23) AS P23, 
         sum(B.D30) AS D30, 
         sum(B.D31) AS D31, 
         sum(B.D32) AS D32, 
         sum(B.D33) AS D33, 
         sum(B.D34) AS D34, 
         sum(B.D35) AS D35, 
         sum(B.D36) AS D36, 
         sum(A.PSUM) AS PSUM, 
         sum(B.D37) AS D37, 
         sum(B.D38) AS D38, 
         sum(A.DSUM) + sum(A.TSUM) AS DSUM, 
         sum(A.REAL_AMT) AS REAL_AMT
      FROM 
         dbo.PAY_PAYROLL  AS A 
            JOIN 
            (
               SELECT 
                  A.PAY_PAYROLL_ID, 
                  B.PAY_YMD, 
                  B.COMPANY_CD, 
                  sum(B.P01) AS P01, 
                  sum(B.P02) AS P02, 
                  sum(B.P03) AS P03, 
                  sum(B.P04) AS P04, 
                  sum(B.P05) AS P05, 
                  sum(B.P06) AS P06, 
                  sum(B.D51) AS D51, 
                  sum(B.D52) AS D52, 
                  sum(B.D50) AS D50, 
                  sum(B.D53) AS D53, 
                  sum(B.D54) AS D54, 
                  sum(B.D55) AS D55, 
                  sum(B.D24) AS D24, 
                  sum(B.P07) AS P07, 
                  sum(B.P08) AS P08, 
                  sum(B.P09) AS P09, 
                  sum(B.P10) AS P10, 
                  sum(B.P12) AS P12, 
                  sum(B.P11) AS P11, 
                  sum(B.D01) AS D01, 
                  sum(B.D02) AS D02, 
                  sum(B.D03) AS D03, 
                  sum(B.D04) AS D04, 
                  sum(B.P17) AS P17, 
                  sum(B.P14) AS P14, 
                  sum(B.P15) AS P15, 
                  sum(B.P16) AS P16, 
                  sum(B.P24) AS P24, 
                  sum(B.D08) AS D08, 
                  sum(B.D09) AS D09, 
                  sum(B.D10) AS D10, 
                  sum(B.D11) AS D11, 
                  sum(B.D12) AS D12, 
                  sum(B.D13) AS D13, 
                  sum(B.D14) AS D14, 
                  sum(B.D15) AS D15, 
                  sum(B.D16) AS D16, 
                  sum(B.D17) AS D17, 
                  sum(B.D18) AS D18, 
                  sum(B.D19) AS D19, 
                  sum(B.P20) AS P20, 
                  sum(B.P21) AS P21, 
                  sum(B.P22) AS P22, 
                  sum(B.P23) AS P23, 
                  sum(B.D30) AS D30, 
                  sum(B.D31) AS D31, 
                  sum(B.D32) AS D32, 
                  sum(B.D33) AS D33, 
                  sum(B.D34) AS D34, 
                  sum(B.D35) AS D35, 
                  sum(B.D36) AS D36, 
                  sum(B.D37) AS D37, 
                  sum(B.D38) AS D38
               FROM 
                  dbo.PAY_PAYROLL  AS A 
                     JOIN dbo.VI_PAY_PAYROLL_DETAIL  AS B 
                     ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
                     JOIN dbo.PAY_PAY_YMD  AS C 
                     ON 
                        A.PAY_YMD_ID = C.PAY_YMD_ID AND 
                        C.COMPANY_CD = '01' AND 
                        /*           AND C.PAY_YMD_ID = :pay_ymd_id*/c.pay_ymd_id IN 
                        (
                           SELECT PAY_PAY_YMD.PAY_YMD_ID
                           FROM dbo.PAY_PAY_YMD
                           WHERE CONVERT(varchar(6), PAY_PAY_YMD.PAY_YMD, 112) BETWEEN ? AND ?
                        )
               WHERE A.SUB_COMPANY_CD LIKE ? + '%' AND (/*           AND (? IS NULL OR A.ORG_ID = ?)*/? IS NULL OR A.EMP_ID = ?)
               GROUP BY 
                  A.PAY_PAYROLL_ID, 
                  B.PAY_YMD, 
                  B.COMPANY_CD
            )  AS B 
            ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
            JOIN dbo.VI_PAY_PHM_EMP  AS C 
            ON A.EMP_ID = C.EMP_ID, 
         
            (
               SELECT 'KO' AS LOCALE_CD
            )  AS X
      /*     GROUP BY A.SUB_COMPANY_CD, A.EMP_ID,A.ORG_ID,A.POS_CD, B.COMPANY_CD, B.PAY_YMD, C.EMP_NO, C.EMP_NM, C.GENDER_CD*/
      GROUP BY 
         A.SUB_COMPANY_CD, 
         A.EMP_ID, 
         C.EMP_NO, 
         C.EMP_NM
   )  AS A, dbo.VI_FRM_PHM_EMP  AS B
WHERE 
   1 = 1/* (? IS NULL OR LOS_ID = ?)*/ AND 
   A.EMP_NO = B.EMP_NO AND 
   ((? = '0') OR (? = '1' AND A.PSUM <> 0))

/*
*      AND PSUM <> 0
*      AND (? IS NULL
*          OR (? = '+' AND PSUM > 0)
*          OR (? = '-' AND PSUM < 0)
*          )
*    ORDER BY SUB_COMPANY, ORG, b.EMP_NO
*/
ORDER BY A.SUB_COMPANY, B.EMP_NO
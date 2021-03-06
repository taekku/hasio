SELECT CASE WHEN AA.TYPE_ORD = '2' THEN 'DBO.F_PAY_RETRO_MON(COMPANY_CD, EMP_ID, PAY_YMD_ID, ''1'') '
            WHEN AA.TYPE_ORD = '3' THEN 'DBO.XF_NVL_N(MAX(PSUM),0)'
            WHEN AA.TYPE_ORD = '5' THEN 'DBO.F_PAY_RETRO_MON(COMPANY_CD, EMP_ID, PAY_YMD_ID, ''2'') '
            WHEN AA.TYPE_ORD = '6' THEN 'DBO.XF_NVL_N(MAX(ISNULL(DSUM,0)+ISNULL(TSUM,0)),0)'
            WHEN AA.TYPE_ORD = '7' THEN  'DBO.XF_NVL_N(MAX(REAL_AMT),0)'
       ELSE 'DBO.XF_NVL_N(SUM(CASE WHEN PAY_ITEM_CD = '''+ CD2 +''' THEN CAL_MON END),0) '  
              END + ' AS col' + CAST( ROW_NUMBER() OVER( ORDER BY AA.TYPE_ORD, MIN(DBO.XF_NVL_N(PRINT_ORD_NO, ORD_NO)) ) AS NVARCHAR ) AS SQL_COL, 

       ROW_NUMBER() OVER( ORDER BY AA.TYPE_ORD, MIN(DBO.XF_NVL_N(PRINT_ORD_NO, ORD_NO)) ) AS CD2,
       
       'col' + CD2 AS CD,
       
       CASE WHEN AA.TYPE_ORD IN ('1', '2') THEN DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'PLIST'), '지급내역') 
            WHEN AA.TYPE_ORD = '3' THEN DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'SUM_PAY_AMT'), '총지급액')
            WHEN AA.TYPE_ORD IN ('4', '5') THEN DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'SUM_PAY_AMT'), '공제내역')
            WHEN AA.TYPE_ORD = '6' THEN  DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'SUM_DED_AMT'), '총공제액')
            WHEN AA.TYPE_ORD = '7' THEN DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'REAL_AMT'), '차인지급액')
            WHEN AA.TYPE_ORD = '9' THEN DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'UNTAX'), '비과세') 
       END CD_NM,
            
       CD_NM AS PRINT_NM
FROM
(
    SELECT  PAY_ITEM_CD CD2, 
            DBO.F_FRM_CODE_NM(:company_cd, :locale_cd, 'PAY_ITEM_CD', PAY_ITEM_CD, MAX(Z.PAY_YMD), '1') CD_NM,
            CASE WHEN PAY_ITEM_TYPE_CD IN ('PAY_PAY', 'PAY', 'PAY_GN', 'PAY_G') THEN '1'
                WHEN PAY_ITEM_TYPE_CD IN ( 'DEDUCT', 'TAX' ) THEN '4' 
                WHEN PAY_ITEM_TYPE_CD IN ( 'TAX_N_P' ) THEN '9' 
                  END AS   TYPE_ORD ,
			(SELECT MIN(X.CD_ORDER) AS CD_ORDER FROM PAY_PAYITEM_CODE X
				WHERE X.PAY_ITEM_CD = U.PAY_ITEM_CD
    		      AND Z.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
    		      AND X.COMPANY_CD = :company_cd) AS ORD_NO,
			U.PRINT_ORD_NO
            --MIN(DBO.XF_NVL_N(U.PRINT_ORD_NO, ORD_NO)) AS ORD_NO
    FROM (SELECT PAY_YMD
            FROM PAY_PAY_YMD A
           WHERE COMPANY_CD = :company_cd
             AND (:pay_ymd_id IS NOT NULL AND PAY_YMD_ID = :pay_ymd_id  )
                 OR (:pay_ymd_id IS NULL AND  PAY_YMD BETWEEN :sta_ymd AND :end_ymd )
          ) Z,          
          (SELECT KEY_CD1 AS PAY_ITEM_CD
          		, CD1 AS PAY_ITEM_TYPE_CD 
          		, DBO.XF_TO_NUMBER(ETC_CD4) AS PRINT_ORD_NO
          		, STA_YMD
          		, END_YMD
           FROM FRM_UNIT_STD_MGR MGR,
                   FRM_UNIT_STD_HIS HIS
           WHERE MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
             AND MGR.COMPANY_CD = :company_cd
             AND MGR.UNIT_CD =  'PAY'
             AND MGR.STD_KIND = 'PAY_ITEM_CD_BASE'
             AND (CD1 IN ('PAY_PAY', 'PAY', 'PAY_GN', 'PAY_G', 'DEDUCT', 'TAX', 'TAX_N_P'))  -- 급여지급액,합산지급액,기지급(급여성아님),기지급(기지급급여), 공제, 세금 항목유형[PAY_ITEM_TYPE_CD]  
            ) U
    WHERE Z.PAY_YMD BETWEEN  U.STA_YMD AND U.END_YMD
    GROUP BY PAY_ITEM_TYPE_CD ,PAY_ITEM_CD, Z.PAY_YMD, U.PRINT_ORD_NO 
    UNION ALL 
    SELECT  '2' CD,  DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'RETRO_AMT'), '소급액') CD_NM,
            '2'  TYPE_ORD ,   1  ORD_NO, NULL AS PRINT_ORG_NO
    FROM DUAL WHERE 'N' = :retro_yn
    UNION ALL
    SELECT  '3' CD,  DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'SUM_PAY_AMT'), '총지급액') CD_NM,
            '3'  TYPE_ORD ,   1  ORD_NO, NULL AS PRINT_ORG_NO
    FROM DUAL
     UNION ALL
    SELECT  '5' CD,  DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'RETRO_AMT'), '소급액') CD_NM,
            '5'  TYPE_ORD ,   1  ORD_NO, NULL AS PRINT_ORG_NO
    FROM DUAL WHERE 'N' = :retro_yn
     UNION ALL
    SELECT  '6' CD,  DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'SUM_DED_AMT'), '총공제액') CD_NM,
            '6'  TYPE_ORD ,   1  ORD_NO, NULL AS PRINT_ORG_NO
    FROM DUAL
    UNION ALL
     SELECT  '7' CD,  DBO.XF_NVL_C(DBO.F_FRM_GET_TERM(:locale_cd, 'TERM', 'REAL_AMT'), '차인지급액') CD_NM,
            '7'  TYPE_ORD ,   1  ORD_NO, NULL AS PRINT_ORG_NO
    FROM DUAL
) AA
GROUP BY AA.TYPE_ORD, AA.CD2, AA.CD_NM, AA.ORD_NO
ORDER BY AA.TYPE_ORD, AA.ORD_NO
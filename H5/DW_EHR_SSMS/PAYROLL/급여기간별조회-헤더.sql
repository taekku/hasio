DECLARE @company_cd nvarchar(10) = 'C'
DECLARE @locale_cd nvarchar(10) = 'KO'
DECLARE @pay_ymd_id numeric
DECLARE @sta_ymd date = '20210201'
DECLARE @end_ymd date = '20210228'
DECLARE @pay_type_cd nvarchar(10)
DECLARE @retro_yn nvarchar(10)

SELECT CASE WHEN AA.TYPE_ORD = '2' THEN 'DBO.F_PAY_RETRO_MON(COMPANY_CD, EMP_ID, PAY_YMD_ID, ''1'') '
            WHEN AA.TYPE_ORD = '3' THEN 'ISNULL(MAX(PSUM),0)'
            WHEN AA.TYPE_ORD = '5' THEN 'DBO.F_PAY_RETRO_MON(COMPANY_CD, EMP_ID, PAY_YMD_ID, ''2'') '
            WHEN AA.TYPE_ORD = '6' THEN 'ISNULL(MAX(ISNULL(DSUM,0)+ISNULL(TSUM,0)),0)'
            WHEN AA.TYPE_ORD = '7' THEN 'ISNULL(MAX(REAL_AMT),0)'
            ELSE 'ISNULL(SUM(CASE WHEN PAY_ITEM_CD = '''+ CD2 +''' THEN CAL_MON END),0) '  
       END + ' AS col' + CAST( ROW_NUMBER() OVER(ORDER BY AA.TYPE_ORD, AA.ORD_NO, AA.ORD_NO2) AS NVARCHAR) AS SQL_COL
     , 'col' + CAST( ROW_NUMBER() OVER(ORDER BY AA.TYPE_ORD, AA.ORD_NO, AA.ORD_NO2) AS NVARCHAR ) AS CD
     , CASE WHEN AA.TYPE_ORD IN ('1', '2') THEN ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'PLIST')      , '지급내역') 
            WHEN AA.TYPE_ORD = '3'         THEN ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'SUM_PAY_AMT'), '총지급액')
            WHEN AA.TYPE_ORD IN ('4', '5') THEN ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'SUM_PAY_AMT'), '공제내역')
            WHEN AA.TYPE_ORD = '6'         THEN ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'SUM_DED_AMT'), '총공제액')
            WHEN AA.TYPE_ORD = '7'         THEN ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'REAL_AMT')   , '차인지급액')
            WHEN AA.TYPE_ORD = '8'         THEN ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'UNTAX')      , '비과세') 
            WHEN AA.TYPE_ORD = '9'         THEN ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'PAY_P')      , '지급과정') 
       END CD_NM
     , CD_NM AS PRINT_NM
  FROM (
        SELECT HIS.KEY_CD1 AS CD2
             , DBO.F_FRM_CODE_NM(MGR.COMPANY_CD, MGR.LOCALE_CD, 'PAY_ITEM_CD', HIS.KEY_CD1, MAX(YMD.PAY_YMD), '1') AS CD_NM
             , CASE WHEN HIS.CD1 IN ('PAY_PAY', 'PAY', 'PAY_GN', 'PAY_G') THEN '1'
                    WHEN HIS.CD1 IN ('DEDUCT', 'TAX') THEN '4' 
                    WHEN HIS.CD1 IN ('TAX_N_P') THEN '8' 
                    WHEN HIS.CD1 IN ('PAY_P') THEN '9' 
               END AS TYPE_ORD
             , MAX(COALESCE(ITEM.NO_PRT_ORD, ITEM.PRO_PRT_ORD, ITEM.SAIL_PRT_ORD, '999')) AS ORD_NO
             , DBO.F_FRM_CODE_NM(MGR.COMPANY_CD, MGR.LOCALE_CD, 'PAY_ITEM_CD', HIS.KEY_CD1, MAX(YMD.PAY_YMD), 'O') AS ORD_NO2
          FROM PAY_PAY_YMD YMD
               INNER JOIN FRM_UNIT_STD_MGR MGR
                       ON YMD.COMPANY_CD = MGR.COMPANY_CD
                      AND YMD.COMPANY_CD = @company_cd
                      AND (YMD.PAY_YMD_ID = @pay_ymd_id OR YMD.PAY_YMD BETWEEN @sta_ymd AND @end_ymd)
               INNER JOIN FRM_UNIT_STD_HIS HIS
                       ON MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
                      AND MGR.UNIT_CD = 'PAY'
                      AND MGR.STD_KIND = 'PAY_ITEM_CD_BASE'
                      AND HIS.CD1 IN ('PAY_PAY', 'PAY', 'PAY_GN', 'PAY_G', 'DEDUCT', 'TAX', 'TAX_N_P','PAY_P')
                      AND YMD.PAY_YMD BETWEEN HIS.STA_YMD AND HIS.END_YMD
               LEFT OUTER JOIN PAY_ITEM_MST ITEM
                       ON YMD.COMPANY_CD = ITEM.COMPANY_CD
                      AND YMD.PAY_YMD BETWEEN ITEM.STA_YMD AND ITEM.END_YMD
                      AND HIS.KEY_CD1 = ITEM.PAY_ITEM_CD
               INNER JOIN PAY_PAYITEM_CODE CALC
                       ON CALC.COMPANY_CD = YMD.COMPANY_CD
                      AND CALC.PAY_TYPE_CD = YMD.PAY_TYPE_CD
                      AND YMD.PAY_YMD BETWEEN CALC.STA_YMD AND CALC.END_YMD
                      AND CALC.PAY_ITEM_CD = HIS.KEY_CD1
                      AND (CALC.PAY_TYPE_CD = @pay_type_cd OR @pay_type_cd IS NULL)
               INNER JOIN PAY_GROUP_TYPE PGT
                       ON YMD.COMPANY_CD = PGT.COMPANY_CD
                      AND YMD.PAY_TYPE_CD = PGT.PAY_TYPE_CD
                      AND YMD.PAY_YMD BETWEEN PGT.STA_YMD AND PGT.END_YMD
         GROUP BY MGR.COMPANY_CD, MGR.LOCALE_CD, HIS.CD1, HIS.KEY_CD1
  UNION ALL 
		SELECT '2' AS CD, ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'RETRO_AMT'), '소급액') AS CD_NM
             , '2' AS TYPE_ORD, 1 AS ORD_NO, NULL AS ORD_NO2
          FROM DUAL
         WHERE 'N' = @retro_yn
  UNION ALL
        SELECT '3' AS CD, ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'SUM_PAY_AMT'), '총지급액') AS CD_NM
             , '3' AS TYPE_ORD , 1 AS ORD_NO, NULL AS ORD_NO2
          FROM DUAL
  UNION ALL
        SELECT '5' AS CD, ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'RETRO_AMT'), '소급액') AS CD_NM
             , '5' AS TYPE_ORD , 1 AS ORD_NO, NULL AS ORD_NO2
          FROM DUAL
		 WHERE 'N' = @retro_yn
  UNION ALL
        SELECT '6' AS CD, ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'SUM_DED_AMT'), '총공제액') AS CD_NM
             , '6' AS TYPE_ORD , 1 AS ORD_NO, NULL AS ORD_NO2
          FROM DUAL
  UNION ALL
        SELECT '7' AS CD, ISNULL(DBO.F_FRM_GET_TERM(@locale_cd, 'TERM', 'REAL_AMT'), '차인지급액') AS CD_NM
             , '7' AS TYPE_ORD , 1 AS ORD_NO, NULL AS ORD_NO2
          FROM DUAL
     ) AA
 ORDER BY AA.TYPE_ORD, AA.ORD_NO, AA.ORD_NO2
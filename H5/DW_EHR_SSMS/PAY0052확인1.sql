declare @company_cd nvarchar(10) = 'F'
declare @locale_cd nvarchar(10) = 'KO'
declare @pay_ym nvarchar(10) = '202105'
declare @bef_ym nvarchar(10) = '202104'
declare @pay_type_cd nvarchar(10) = '120'
;
WITH CTE AS (
	SELECT '10' AS ORD_NO, '10' AS ITEM_TYPE, NULL AS PAY_ITEM_CD
	     , COUNT( DISTINCT CASE WHEN YMD.PAY_YM = @bef_ym THEN ROLL.EMP_ID ELSE NULL END) BEF_MON
	     , COUNT( DISTINCT CASE WHEN YMD.PAY_YM = @pay_ym THEN ROLL.EMP_ID ELSE NULL END) CUR_MON
	  FROM PAY_PAY_YMD YMD
     INNER JOIN PAY_PAYROLL ROLL
             ON YMD.PAY_YMD_ID = ROLL.PAY_YMD_ID
	  WHERE YMD.COMPANY_CD = @company_cd
	    AND YMD.PAY_TYPE_CD = @pay_type_cd
		AND YMD.PAY_YM IN (@pay_ym, @bef_ym)
), PAY AS (
SELECT CASE WHEN DTL.PAY_ITEM_TYPE_CD IN ('PAY_PAY', 'PAY', 'PAY_GN', 'PAY_G') THEN '20' -- 지급
            ELSE '30'  -- 공제
       END AS ORD_NO
     , CASE WHEN ISNULL(ITEM.YN_FIX, 'N') = 'Y' THEN '20'  -- 고정지급
            ELSE 
                 CASE WHEN DTL.PAY_ITEM_TYPE_CD IN ('PAY_PAY', 'PAY', 'PAY_GN', 'PAY_G') THEN '30'  --변동지급
                      WHEN DTL.PAY_ITEM_TYPE_CD IN ('TAX') THEN '40'   -- 과세
                      WHEN DTL.PAY_ITEM_TYPE_CD IN ('DEDUCT') THEN '50'  -- 공제
                      ELSE '60' -- 공제-비과세
                 END
       END AS ITEM_TYPE
	 , DTL.PAY_ITEM_CD
	 , SUM(CASE WHEN YMD.PAY_YM = @bef_ym THEN ISNULL(DTL.CAL_MON, 0) ELSE 0 END) AS BEF_MON
	 , SUM(CASE WHEN YMD.PAY_YM = @pay_ym THEN ISNULL(DTL.CAL_MON, 0) ELSE 0 END) AS CUR_MON
  FROM PAY_PAY_YMD YMD
       INNER JOIN PAY_PAYROLL ROLL
               ON YMD.PAY_YMD_ID = ROLL.PAY_YMD_ID
			  AND YMD.COMPANY_CD = @company_cd
				AND YMD.PAY_TYPE_CD = @pay_type_cd
				AND YMD.PAY_YM IN (@pay_ym, @bef_ym)
       INNER JOIN PAY_PAYROLL_DETAIL DTL
               ON ROLL.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID
              AND DTL.PAY_ITEM_TYPE_CD IN ('PAY_PAY', 'PAY', 'PAY_GN', 'PAY_G', 'DEDUCT', 'TAX', 'TAX_N_P')
  GROUP BY CASE WHEN DTL.PAY_ITEM_TYPE_CD IN ('PAY_PAY', 'PAY', 'PAY_GN', 'PAY_G') THEN '20' -- 지급
            ELSE '30'  -- 공제
       END
	 , DTL.PAY_ITEM_CD
)
SELECT * FROM CTE
UNION ALL
SELECT * FROM PAY
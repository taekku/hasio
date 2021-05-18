
--GO
--SELECT SYSDATETIME()
--GO
DECLARE @av_company_cd nvarchar(10) = 'F'
DECLARE @av_locale_cd nvarchar(10) = 'KO'
DECLARE @av_calc_type_cd nvarchar(10) = '03'
DECLARE @ad_std_ymd date = '20201130'
DECLARE @ad_calc_sta_ymd date = '20191201'
DECLARE @ad_calc_end_ymd date = '20201130'
DECLARE @MYTABLE TABLE(
	EMP_ID	NUMERIC(38),
	BEL_PAY_YM NVARCHAR(10),
	CAL_MON NUMERIC(18,0)
)
--select PAY_GROUP, INS_TYPE_CD, COUNT(*)-- YEAR_MONTH_AMT --9*
--from REP_CALC_LIST
--where  COMPANY_CD='F'
--and PAY_YMD = @ad_std_ymd
--AND CALC_TYPE_CD='03'
----AND PAY_GROUP='F11', 'F12'
--GROUP BY PAY_GROUP, INS_TYPE_CD
--ORDER BY PAY_GROUP, INS_TYPE_CD

DECLARE @v_pay_group_cd nvarchar(10) = 'F21'--'EA01'--'F21'

	--SELECT CASE WHEN B.STD_KIND = 'REP_AVG_ITEM_CD' THEN 'Y' ELSE 'N' END AS OFFICERS_YN
	--	 , KEY_CD2 PAY_ITEM_SYS_CD, KEY_CD3 AS PAY_ITEM_CD  
	--	 , C.CD AS PAY_TYPE_CD
	--FROM FRM_UNIT_STD_HIS A
	--JOIN FRM_UNIT_STD_MGR B
	--  ON B.COMPANY_CD = @av_company_cd
	-- AND B.UNIT_CD = 'REP'
	-- AND STD_KIND IN ('REP_AVG_ITEM_CD','REP_AVG_MGR_ITEM_CD')
	-- AND A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
	--JOIN FRM_CODE C
	--  ON C.COMPANY_CD = @av_company_cd
	-- AND C.CD_KIND = 'PAY_TYPE_CD'
	-- AND C.SYS_CD != '100'
	-- AND @ad_calc_end_ymd BETWEEN C.STA_YMD AND C.END_YMD  
	-- AND A.KEY_CD2 = C.SYS_CD
 --  WHERE A.KEY_CD1 = '10'
	-- AND @ad_calc_end_ymd BETWEEN A.STA_YMD AND A.END_YMD  

;
WITH LIST AS (
	SELECT EMP_ID, INS_TYPE_CD, OFFICERS_YN
	  FROM REP_CALC_LIST 
	 WHERE COMPANY_CD = @av_company_cd
	   AND CALC_TYPE_CD = @av_calc_type_cd
	   AND PAY_GROUP = @v_pay_group_cd
	   and C1_END_YMD = @ad_calc_end_ymd
)
, PAY_ITEM AS (
	SELECT CASE WHEN B.STD_KIND = 'REP_AVG_ITEM_CD' THEN 'Y' ELSE 'N' END AS OFFICERS_YN
		 , KEY_CD2 PAY_ITEM_SYS_CD, KEY_CD3 AS PAY_ITEM_CD  
		 , C.CD AS PAY_TYPE_CD
	FROM FRM_UNIT_STD_HIS A
	JOIN FRM_UNIT_STD_MGR B
	  ON B.COMPANY_CD = @av_company_cd
	 AND B.UNIT_CD = 'REP'
	 AND STD_KIND IN ('REP_AVG_ITEM_CD','REP_AVG_MGR_ITEM_CD')
	 AND A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
	JOIN FRM_CODE C
	  ON C.COMPANY_CD = @av_company_cd
	 AND C.CD_KIND = 'PAY_TYPE_CD'
	 AND C.SYS_CD != '100'
	 AND @ad_calc_end_ymd BETWEEN C.STA_YMD AND C.END_YMD  
	 AND A.KEY_CD2 = C.SYS_CD
   WHERE A.KEY_CD1 = '10'
	 AND @ad_calc_end_ymd BETWEEN A.STA_YMD AND A.END_YMD  
)
INSERT INTO @MYTABLE
SELECT *
FROM(
SELECT A.*
    -- , ROW_NUMBER() OVER (PARTITION BY EMP_ID ORDER BY BEL_PAY_YM DESC) AS ROWNUM
  FROM (
		SELECT LIST.EMP_ID, B.BEL_PAY_YM, SUM(dbo.XF_NVL_N(CAL_MON,0)) AS CAL_MON
										FROM PAY_PAYROLL A
											INNER JOIN PAY_PAY_YMD C 
												ON A.PAY_YMD_ID = C.PAY_YMD_ID
											INNER JOIN PAY_PAYROLL_DETAIL B
												ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
											INNER JOIN LIST
											    ON A.EMP_ID = LIST.EMP_ID
											INNER JOIN PAY_ITEM T1
											    ON LIST.OFFICERS_YN = T1.OFFICERS_YN
											   AND B.PAY_ITEM_CD = T1.PAY_ITEM_CD
											   AND C.PAY_TYPE_CD = T1.PAY_TYPE_CD
											--INNER JOIN (
											--	SELECT PAY_TYPE_CD, PAY_ITEM_CD
											--	 FROM (
											--		   SELECT CD PAY_TYPE_CD, SYS_CD
											--			 FROM FRM_CODE
											--			WHERE COMPANY_CD = @av_company_cd
											--			  AND CD_KIND = 'PAY_TYPE_CD'
											--			  AND SYS_CD != '100' -- 시뮬레이션제외
											--		  ) A
											--		INNER JOIN (
											--					SELECT KEY_CD2 PAY_ITEM_SYS_CD, KEY_CD3 AS PAY_ITEM_CD  
											--					  FROM FRM_UNIT_STD_HIS  
											--					 WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
											--													FROM FRM_UNIT_STD_MGR  
											--												   WHERE COMPANY_CD = @av_company_cd  
											--													 AND UNIT_CD = 'REP'  
											--  													 AND STD_KIND = CASE WHEN LIST.OFFICERS_YN = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
											--					   AND @ad_calc_end_ymd BETWEEN STA_YMD AND END_YMD  
											--					   AND KEY_CD1 = '10'  
											--			) B
											--			ON (A.SYS_CD = B.PAY_ITEM_SYS_CD OR B.PAY_ITEM_SYS_CD IS NULL)
											--		) T1
											--	ON C.PAY_TYPE_CD = T1.PAY_TYPE_CD
											--	AND B.PAY_ITEM_CD = T1.PAY_ITEM_CD
											WHERE C.CLOSE_YN = 'Y'
											AND C.PAY_YN = 'Y'
											--AND B.BEL_PAY_YM = @v_base_pay_ym  
											AND B.BEL_PAY_YM <= FORMAT(@ad_calc_end_ymd, 'yyyyMM')
											AND B.BEL_PAY_YM >= '201901'
											--AND B.BEL_PAY_YM >= '201911'
											AND C.COMPANY_CD = @av_company_cd 
											AND A.EMP_ID = LIST.EMP_ID
											--AND A.EMP_ID = 50324
											GROUP BY LIST.EMP_ID, B.BEL_PAY_YM
										--	) A
										--WHERE CAL_MON <> 0
										--ORDER BY BEL_PAY_YM DESC
) A
) AA
--WHERE ROWNUM <= 4
--GO
--SELECT SYSDATETIME()
SELECT COUNT(*) FROM @MYTABLE

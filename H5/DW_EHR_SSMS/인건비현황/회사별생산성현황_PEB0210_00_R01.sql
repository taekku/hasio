DECLARE @company_cd nvarchar(10) = 'F'
DECLARE @fr_month nvarchar(06) = '202101'
DECLARE @to_month nvarchar(06) = '202104'
DECLARE @prod_kind nvarchar(06) = '20'
DECLARE @peb_kind nvarchar(06) = '10'
DECLARE @arb_inc_yn nvarchar(10) = 'N'

DECLARE @d_std_date date
set @d_std_date = '20210531'
;
SELECT ISNULL(dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', MAX(BASE_YMD), '1'),
			    (SELECT ORG_NM FROM ORM_ORG WHERE ORG_ID = A.ORG_ID)) AS ORG_NM
	 , SUPER_ORG_ID
	 , ORG_ID
	 , T.MON_CNT
	, SUM(TAKE_AMT) AS TAKE_AMT
	, SUM(PROFIT_AMT) AS PROFIT_AMT
	 , SUM(PHM_CNT)  AS PHM_CNT
	 , SUM(PAY_CNT) / T.MON_CNT AS PAY_CNT
	 , SUM(PAY_AMT) AS PAY_AMT
  FROM (SELECT BASE_YM, BASE_YMD, B.SUPER_ORG_ID, A.ORG_ID, TAKE_AMT, PROFIT_AMT, PHM_CNT, PAY_CNT, PAY_AMT
          FROM (SELECT BASE_YM, BASE_YMD, ORG_ID
				     , SUM(TAKE_AMT) AS TAKE_AMT
				     , SUM(PROFIT_AMT) AS PROFIT_AMT
				     , SUM(PHM_CNT) AS PHM_CNT
				     , SUM(PAY_CNT) AS PAY_CNT
				     , SUM(PAY_AMT) AS PAY_AMT
				  FROM (
				  SELECT BASE_YM, DBO.XF_LAST_DAY(BASE_YM + '01') BASE_YMD, ORG_ID
					   , TAKE_AMT , PROFIT_AMT, 0 PHM_CNT, 0 PAY_CNT, 0 PAY_AMT
					  FROM PEB_PROD_PLAN
					 WHERE COMPANY_CD = @company_cd
					   AND BASE_YM >= @fr_month
					   AND BASE_YM <= @to_month
					   AND (@prod_kind = '10' AND PLAN_CD = '10') -- 계획
					UNION ALL
				  SELECT CONVERT(NVARCHAR(4),SUBSTRING(BASE_YM,1,4) + 1) + SUBSTRING(BASE_YM,5,2) BASE_YM
				         , DBO.XF_LAST_DAY(BASE_YM + '01') BASE_YMD, ORG_ID
					   , TAKE_AMT , PROFIT_AMT, 0 PHM_CNT, 0 PAY_CNT, 0 PAY_AMT
					  FROM PEB_PROD_PLAN
					 WHERE COMPANY_CD = @company_cd
					   AND BASE_YM >= CONVERT(NVARCHAR(4), SUBSTRING(@fr_month, 1, 4) - 1) + SUBSTRING(@fr_month, 5, 2)
					   AND BASE_YM <= CONVERT(NVARCHAR(4), SUBSTRING(@to_month, 1, 4) - 1) + SUBSTRING(@to_month, 5, 2)
					   AND (@prod_kind = '20' AND PLAN_CD = '20') -- 전년
					UNION ALL
				  SELECT BASE_YM, DBO.XF_LAST_DAY(BASE_YM + '01') BASE_YMD, ORG_ID
						 , 0 TAKE_AMT, 0 PROFIT_AMT
						 , CASE WHEN BASE_YM = @to_month THEN PAY_CNT ELSE 0 END PHM_CNT
						 , PAY_CNT
						 , PAY_AMT + CASE WHEN @peb_kind = '20' THEN PAY_ETC_AMT ELSE 0 END AS PAY_AMT
					  FROM PEB_EST_PAY
					 WHERE COMPANY_CD = @company_cd
					   AND BASE_YM >= @fr_month
					   AND BASE_YM <= @to_month
					   AND PLAN_CD = '20' 
					   AND CASE WHEN VIEW_CD='50' THEN 'Y' ELSE @arb_inc_yn END = @arb_inc_yn-- 일용/도급포함
					   ) U
					GROUP BY BASE_YM, BASE_YMD, ORG_ID
			) A
		  LEFT OUTER JOIN (SELECT org_cd, org_nm, SUPER_ORG_ID, ORG_ID, STA_YMD, END_YMD
					from VI_FRM_ORM_ORG
					where COMPANY_CD = @company_cd
					) B
			ON A.ORG_ID = B.ORG_ID
		   AND A.BASE_YMD BETWEEN B.STA_YMD AND B.END_YMD
			UNION ALL
			SELECT NULL BASE_YM, NULL BASE_YMD, SUPER_ORG_ID, ORG_ID, NULL TAKE_AMT, NULL PROFIT_AMT, NULL PHM_CNT, NULL PAY_CNT, NULL PAY_AMT
			  FROM VI_FRM_ORM_ORG A
			 WHERE COMPANY_CD = @company_cd
			   AND @fr_month <= FORMAT(END_YMD, 'yyyyMM')
			   AND @to_month >= FORMAT(STA_YMD, 'yyyyMM')
   ) A
   join (select round(dbo.XF_MONTHDIFF( dbo.XF_LAST_DAY( @to_month  + '01'),  @fr_month  + '01' ),0) as MON_CNT ) T
     ON 1=1
 GROUP BY SUPER_ORG_ID, ORG_ID, T.MON_CNT
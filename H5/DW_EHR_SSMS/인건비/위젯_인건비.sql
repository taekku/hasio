DECLARE @company_cd nvarchar(10) = 'I'
      , @std_ym nvarchar(10) = '202103' -- 기준년
	  , @plan_cd nvarchar(10) = '20' -- 실적
	  , @cmp_ym nvarchar(10) --= '202003' -- 비교년
	  , @pre_mm nvarchar(10) --전월
	  , @d_base_ymd date
	  , @n_mm int
	  , @n_qq int
	  , @n_ha int
	  , @n_yy int
	  , @n_super_org_id numeric(38,0)

			SELECT @n_yy = DATEPART(YY, BASE_YMD)
				 , @n_ha = CASE WHEN DATEPART(QQ, BASE_YMD) <= 2 THEN 1 ELSE 2 END
				 , @n_qq = DATEPART(QQ, BASE_YMD)
			     , @n_mm = DATEPART(MM, BASE_YMD)
				 , @d_base_ymd = BASE_YMD
			  FROM (SELECT dbo.XF_LAST_DAY(@std_ym + '01') AS BASE_YMD) A
			SET @cmp_ym = CAST(@n_yy - 1 AS nvarchar(4)) + SUBSTRING(@std_ym, 5, 2)
			SELECT @pre_mm = CASE WHEN @n_mm = 1 THEN CAST(@n_yy - 1 AS nvarchar(4)) + '12' ELSE NULL END -- DATA선택시만 체크

	  select @n_super_org_id = ORG_ID
	    from VI_FRM_ORM_ORG ORG
	   WHERE COMPANY_CD = @company_cd
		   AND @d_base_ymd BETWEEN STA_YMD AND END_YMD
		   AND SUPER_ORG_ID IS NULL

			PRINT @cmp_ym + ':' + @std_ym + ':' + ISNULL(@PRE_MM,'')
;
		WITH CTE AS (
			SELECT DATEPART(YY, BASE_YMD) AS D_YY
				 , CASE WHEN DATEPART(QQ, BASE_YMD) <= 2 THEN 1 ELSE 2 END AS D_HA
				 , DATEPART(QQ, BASE_YMD) AS D_QQ
			     , DATEPART(MM, BASE_YMD) AS D_MM
				 , BASE_YM
			     , ORG_ID, PAY_AMT
			  FROM (
					SELECT DBO.XF_LAST_DAY(BASE_YM + '01') BASE_YMD
					     , BASE_YM, ORG_ID, PAY_AMT
					  FROM PEB_EST_PAY
					 WHERE COMPANY_CD = @company_cd
					   AND (BASE_YM BETWEEN SUBSTRING(@std_ym, 1, 4) + '01' AND @std_ym OR
					        BASE_YM = @pre_mm OR
					        BASE_YM BETWEEN SUBSTRING(@cmp_ym, 1, 4) + '01' AND @cmp_ym)
					   AND PLAN_CD = @plan_cd
					   AND TYPE_NM = '인건비'
				   ) A
		), CTE2 AS (
		SELECT ORG_ID
		     , SUM(CASE WHEN D_YY = @n_yy AND D_MM = @n_mm THEN PAY_AMT ELSE NULL END) AS A_MM_AMT -- 당월
		     , SUM(CASE WHEN CASE WHEN D_YY = @n_yy THEN 12 ELSE 0 END + D_MM = 12 + @n_mm - 1 THEN PAY_AMT ELSE NULL END) AS B_MM_AMT -- 전월
		     , SUM(CASE WHEN D_YY = @n_yy AND D_QQ = @n_qq THEN PAY_AMT ELSE NULL END) AS A_QQ_AMT -- 당해분기
		     , SUM(CASE WHEN D_YY = (@n_yy - 1) AND D_QQ = @n_qq AND D_MM <= @n_mm THEN PAY_AMT ELSE NULL END) AS B_QQ_AMT -- 전년분기
		     , SUM(CASE WHEN D_YY = @n_yy AND D_HA = @n_ha THEN PAY_AMT ELSE NULL END) AS A_HA_AMT -- 당해반기
		     , SUM(CASE WHEN D_YY = (@n_yy - 1) AND D_HA = @n_ha AND D_MM <= @n_mm THEN PAY_AMT ELSE NULL END) AS B_HA_AMT -- 전년반기
		     , SUM(CASE WHEN D_YY = @n_yy THEN PAY_AMT ELSE NULL END) AS A_YY_AMT -- 당년
		     , SUM(CASE WHEN D_YY = (@n_yy - 1) AND D_MM <= @n_mm THEN PAY_AMT ELSE NULL END) AS B_YY_AMT -- 전년
		  FROM CTE
		 GROUP BY ORG_ID)
		SELECT ISNULL(ORG.SUPER_ORG_ID, @n_super_org_id) SUPER_ORG_ID
		     , CTE2.*
		  FROM CTE2
		  LEFT OUTER JOIN VI_FRM_ORM_ORG ORG
		    ON CTE2.ORG_ID = ORG.ORG_ID
		   AND @d_base_ymd BETWEEN STA_YMD AND END_YMD
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[F_PEB_0231] 
( 
	@av_company_cd		nvarchar(50),
	@av_locale_cd		nvarchar(50),
	@av_std_ym			nvarchar(10)
)
RETURNS @returnTable TABLE
(
	COMPANY_CD		nvarchar(10),	-- 회사코드
	ORG_NM			nvarchar(50),	-- 소속명
	SUPER_ORG_ID	numeric(38),	-- 상위부서
	ORG_ID			numeric(38),	-- 부서
	
	A_MM_AMT		numeric(18),	-- 당월실적
	B_MM_AMT		numeric(18),	-- 전월실적
	A_QQ_AMT		numeric(18),	-- 당해분기
	B_QQ_AMT		numeric(18),	-- 전년분기
	A_HA_AMT		numeric(18),	-- 당해반기
	B_HA_AMT		numeric(18),	-- 전년반기
	A_YY_AMT		numeric(18),	-- 당년
	B_YY_AMT		numeric(18) 	-- 전년
)   
AS 
--<DOCLINE> ***************************************************************************
--<DOCLINE>   TITLE       : 회사별인건비현황(위젯)
--<DOCLINE>   PROJECT     : H5
--<DOCLINE>   AUTHOR      : ltg
--<DOCLINE>   PROGRAM_ID  : F_PEB_0231
--<DOCLINE>   ARGUMENT    : 
--<DOCLINE>   RETURN      : 
--<DOCLINE>   COMMENT     : 
--<DOCLINE>   HISTORY     : 작성 ltg 2021.06.02
--<DOCLINE> ***************************************************************************
BEGIN
	DECLARE @TEMP_COMPANY TABLE (
		COMPANY_CD		nvarchar(10),	-- 회사코드
		ORG_ID			numeric(38) 	-- 부서
	)
	DECLARE @TEMP_REAL TABLE
(
	COMPANY_CD		nvarchar(10),	-- 회사코드
	ORG_NM			nvarchar(50),	-- 소속명
	SUPER_ORG_ID	numeric(38),	-- 상위부서
	ORG_ID			numeric(38),	-- 부서
	
	A_MM_AMT		numeric(18),	-- 당월실적
	B_MM_AMT		numeric(18),	-- 전월실적
	A_QQ_AMT		numeric(18),	-- 당해분기
	B_QQ_AMT		numeric(18),	-- 전년분기
	A_HA_AMT		numeric(18),	-- 당해반기
	B_HA_AMT		numeric(18),	-- 전년반기
	A_YY_AMT		numeric(18),	-- 당년
	B_YY_AMT		numeric(18) 	-- 전년
)   
	DECLARE @d_base_ymd	date			-- = '20201231'
	DECLARE @v_pre_ym	nvarchar(10)	-- = '202011'
	DECLARE @v_cmp_ym	nvarchar(10)	-- = '201912'
	DECLARE @v_plan_cd	nvarchar(10) = '20'
	DECLARE @n_yy		numeric(5)		-- = 2020
	DECLARE @n_mm		numeric(5)		-- = 12
	DECLARE @n_qq		numeric(5)		-- = 4
	DECLARE @n_ha		numeric(5)		-- = 2020

	set @d_base_ymd = dbo.XF_LAST_DAY(@av_std_ym + '01')
	set @v_pre_ym   = FORMAT(DATEADD(MONTH, -1, @d_base_ymd), 'yyyyMM')
	set @v_cmp_ym   = FORMAT(DATEADD(YEAR,  -1, @d_base_ymd), 'yyyyMM')
	set @n_yy = DATEPART(YEAR, @d_base_ymd)
	set @n_mm = DATEPART(MONTH, @d_base_ymd)
	set @n_qq = DATEPART(QUARTER, @d_base_ymd)
	set @n_ha = CASE WHEN @n_qq <= 2 THEN 1 ELSE 2 END
	
	--INSERT INTO @returnTable
	--	SELECT 
	--			'' AS COMPANY_CD, --	A.COMPANY_CD		, -- 회사코드
	--			'회사계' ORG_NM			, -- 소속명
	--			0 SUPER_ORG_ID	,	-- 상위부서
	--			NULL ORG_ID			,	-- 부서
	
	--			NULL A_MM_AMT		,	-- 당월실적
	--			NULL B_MM_AMT		,	-- 전월실적
	--			NULL A_QQ_AMT		,	-- 당해분기
	--			NULL B_QQ_AMT		,	-- 전년분기
	--			NULL A_HA_AMT		,	-- 당해반기
	--			NULL B_HA_AMT		,	-- 전년반기
	--			NULL A_YY_AMT		,	-- 당년
	--			NULL B_YY_AMT		 	-- 전년
;
	WITH CTE AS (
			SELECT DATEPART(YY, BASE_YMD) AS D_YY
				 , CASE WHEN DATEPART(QQ, BASE_YMD) <= 2 THEN 1 ELSE 2 END AS D_HA
				 , DATEPART(QQ, BASE_YMD) AS D_QQ
			     , DATEPART(MM, BASE_YMD) AS D_MM
				 --, BASE_YM
				 --, BASE_YMD
			     , A.ORG_ID
				 --, SUPER_ORG_ID
				 , PAY_AMT
			  FROM (
					SELECT DBO.XF_LAST_DAY(BASE_YM + '01') BASE_YMD
					     , BASE_YM, ORG_ID, PAY_AMT
					  FROM PEB_EST_PAY
					 WHERE COMPANY_CD = @av_company_cd
					   AND (BASE_YM BETWEEN SUBSTRING(@av_std_ym, 1, 4) + '01' AND @av_std_ym OR
					        BASE_YM = @v_pre_ym OR
					        BASE_YM BETWEEN SUBSTRING(@v_cmp_ym, 1, 4) + '01' AND @v_cmp_ym)
					   AND PLAN_CD = @v_plan_cd
					   AND TYPE_NM = '인건비'
				   ) A
				   --LEFT OUTER JOIN VI_FRM_ORM_ORG ORG
				   --             ON A.ORG_ID = ORG.ORG_ID
							--   AND A.BASE_YMD BETWEEN ORG.STA_YMD AND ORG.END_YMD
		), CTE2 AS (
		SELECT ORG_ID
		    -- , SUPER_ORG_ID
		     , SUM(CASE WHEN D_YY = @n_yy AND D_MM = @n_mm THEN PAY_AMT ELSE NULL END) AS A_MM_AMT -- 당월
		     , SUM(CASE WHEN CASE WHEN D_YY = @n_yy THEN 12 ELSE 0 END + D_MM = 12 + @n_mm - 1 THEN PAY_AMT ELSE NULL END) AS B_MM_AMT -- 전월
		     , SUM(CASE WHEN D_YY = @n_yy AND D_QQ = @n_qq THEN PAY_AMT ELSE NULL END) AS A_QQ_AMT -- 당해분기
		     , SUM(CASE WHEN D_YY = (@n_yy - 1) AND D_QQ = @n_qq AND D_MM <= @n_mm THEN PAY_AMT ELSE NULL END) AS B_QQ_AMT -- 전년분기
		     , SUM(CASE WHEN D_YY = @n_yy AND D_HA = @n_ha THEN PAY_AMT ELSE NULL END) AS A_HA_AMT -- 당해반기
		     , SUM(CASE WHEN D_YY = (@n_yy - 1) AND D_HA = @n_ha AND D_MM <= @n_mm THEN PAY_AMT ELSE NULL END) AS B_HA_AMT -- 전년반기
		     , SUM(CASE WHEN D_YY = @n_yy THEN PAY_AMT ELSE NULL END) AS A_YY_AMT -- 당년
		     , SUM(CASE WHEN D_YY = (@n_yy - 1) AND D_MM <= @n_mm THEN PAY_AMT ELSE NULL END) AS B_YY_AMT -- 전년
		  FROM CTE
		 GROUP BY ORG_ID--, SUPER_ORG_ID
        )
		INSERT INTO @TEMP_REAL
		SELECT @av_company_cd AS COMPANY_CD
		     , ISNULL(M.ORG_NM, M.ORG_NM) AS ORG_NM
			 , NULL AS SUPER_ORG_ID
		     , CTE2.*
		  FROM CTE2
		  LEFT OUTER JOIN VI_FRM_ORM_ORG ORG
		    ON CTE2.ORG_ID = ORG.ORG_ID
		   AND @d_base_ymd BETWEEN STA_YMD AND END_YMD
		  JOIN ORM_ORG M
		    ON CTE2.ORG_ID = M.ORG_ID
	;
	
	WITH H_ORG AS (
		SELECT ORG_ID, MAX(STA_YMD) STA_YMD
		FROM ORM_ORG_HIS
		WHERE STA_YMD <= @d_base_ymd
		GROUP BY ORG_ID
	), T_ORG AS (
		SELECT B.SUPER_ORG_ID, A.ORG_ID
		  FROM H_ORG A
		  JOIN ORM_ORG_HIS B
		    ON A.ORG_ID = B.ORG_ID
		   AND A.STA_YMD = B.STA_YMD
	), CTE AS (
		SELECT 
				A.COMPANY_CD		, -- 회사코드
				A.ORG_NM			, -- 소속명
				ORG.SUPER_ORG_ID	, -- 상위부서
				A.ORG_ID			, -- 부서
				A.A_MM_AMT			, -- 당월
				A.B_MM_AMT			, -- 전월
				A.A_QQ_AMT			, -- 당해분기
				A.B_QQ_AMT			, -- 전년분기
				A.A_HA_AMT			, -- 당해반기
				A.B_HA_AMT			, -- 전년반기
				A.A_YY_AMT			, -- 당년
				A.B_YY_AMT -- 전년
		  FROM @TEMP_REAL A
		  JOIN T_ORG ORG
		    ON ORG.ORG_ID = A.ORG_ID
	)
	INSERT INTO @returnTable
	SELECT *
	  FROM CTE
	;
	-- 상위조직찾기
	WITH H_ORG AS (
		SELECT ORG_ID, MAX(STA_YMD) STA_YMD
		FROM ORM_ORG_HIS
		WHERE STA_YMD <= @d_base_ymd
		GROUP BY ORG_ID
	), T_ORG AS (
		SELECT B.SUPER_ORG_ID, A.ORG_ID, B.ORG_NM, ORG.COMPANY_CD
		  FROM H_ORG A
		  JOIN ORM_ORG_HIS B
		    ON A.ORG_ID = B.ORG_ID
		   AND A.STA_YMD = B.STA_YMD
		  JOIN ORM_ORG ORG
		    ON B.ORG_ID = ORG.ORG_ID
		 WHERE ORG.COMPANY_CD =  @av_company_cd -- 특정회사만
	), CTE AS (
		SELECT 
				ORG.COMPANY_CD AS COMPANY_CD, --	A.COMPANY_CD		, -- 회사코드
				ORG.ORG_NM			, -- 소속명
				ORG.SUPER_ORG_ID	, -- 상위부서
				ORG.ORG_ID			, -- 부서
				NULL AS A_MM_AMT			, -- 당월
				NULL AS B_MM_AMT			, -- 전월
				NULL AS A_QQ_AMT			, -- 당해분기
				NULL AS B_QQ_AMT			, -- 전년분기
				NULL AS A_HA_AMT			, -- 당해반기
				NULL AS B_HA_AMT			, -- 전년반기
				NULL AS A_YY_AMT			, -- 당년
				NULL AS B_YY_AMT -- 전년
		  FROM @returnTable A
		  JOIN T_ORG ORG
		    ON A.SUPER_ORG_ID = ORG.ORG_ID
		 WHERE A.SUPER_ORG_ID > 0
		   AND NOT EXISTS(SELECT 1 FROM @returnTable WHERE ORG_ID = A.SUPER_ORG_ID)
		UNION ALL
		SELECT 
				ORG.COMPANY_CD AS COMPANY_CD, --	A.COMPANY_CD		, -- 회사코드
				ORG.ORG_NM			, -- 소속명
				ORG.SUPER_ORG_ID	, -- 상위부서
				ORG.ORG_ID			, -- 부서
				NULL AS A_MM_AMT			, -- 당월
				NULL AS B_MM_AMT			, -- 전월
				NULL AS A_QQ_AMT			, -- 당해분기
				NULL AS B_QQ_AMT			, -- 전년분기
				NULL AS A_HA_AMT			, -- 당해반기
				NULL AS B_HA_AMT			, -- 전년반기
				NULL AS A_YY_AMT			, -- 당년
				NULL AS B_YY_AMT -- 전년
		  FROM CTE A
		  JOIN T_ORG ORG
		    ON A.SUPER_ORG_ID = ORG.ORG_ID
		 WHERE A.SUPER_ORG_ID > 0
		   AND NOT EXISTS(SELECT 1 FROM @returnTable WHERE ORG_ID = A.SUPER_ORG_ID)
	)
	INSERT INTO @returnTable
	SELECT DISTINCT *
	  FROM CTE
	;
	
	-- 최상위 회사코드
	INSERT INTO @TEMP_COMPANY
	SELECT COMPANY_CD, MIN( ORG_ID ) AS ORG_ID
	  FROM @returnTable
	 WHERE SUPER_ORG_ID IS NULL AND ORG_ID > 0
	 GROUP BY COMPANY_CD
	-- 상위부서가 없는 부서
	UPDATE A
	   SET A.SUPER_ORG_ID = -B.ORG_ID
	  FROM @returnTable A
	  JOIN @TEMP_COMPANY B
	    ON A.COMPANY_CD = B.COMPANY_CD
	  LEFT OUTER JOIN @returnTable A1
	    ON A.SUPER_ORG_ID = A1.ORG_ID
	 WHERE A1.ORG_ID IS NULL
	   AND A.SUPER_ORG_ID > 0
	IF @@ROWCOUNT > 0
	BEGIN
		INSERT INTO @returnTable
			SELECT 
					COMPANY_CD, --	A.COMPANY_CD		, -- 회사코드
					'폐쇄된조직' ORG_NM			, -- 소속명
					ORG_ID SUPER_ORG_ID	,	-- 상위부서
					-ORG_ID ORG_ID			,	-- 부서
	
					NULL A_MM_AMT		,	-- 당월실적
					NULL B_MM_AMT		,	-- 전월실적
					NULL A_QQ_AMT		,	-- 당해분기
					NULL B_QQ_AMT		,	-- 전년분기
					NULL A_HA_AMT		,	-- 당해반기
					NULL B_HA_AMT		,	-- 전년반기
					NULL A_YY_AMT		,	-- 당년
					NULL B_YY_AMT		 	-- 전년
				FROM @TEMP_COMPANY
	END
	--UPDATE @returnTable
	--   SET SUPER_ORG_ID = 0
	-- WHERE SUPER_ORG_ID IS NULL AND ORG_ID > 0
	
	RETURN
	
END
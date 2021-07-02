SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[F_PEB_0202] 
( 
	@av_company_cd		nvarchar(50),
	@av_locale_cd		nvarchar(50),
	@fr_month			nvarchar(10),-- = '202101'
	@to_month			nvarchar(10),-- = '202103'
	@plan_cd			nvarchar(10) -- = '10'--계획 '20'--실적
)
RETURNS @returnTable TABLE
(
	COMPANY_CD		nvarchar(10),	-- 회사코드
	ORG_NM			nvarchar(50),	-- 소속명
	SUPER_ORG_ID	numeric(38),	-- 상위부서
	ORG_ID			numeric(38),	-- 부서
	MON_CNT			numeric(3),		-- 개월수

	VIEW_CD			nvarchar(10),	-- 

	PHM_CNT			numeric(8,2),		-- 인원실적
	PAY_CNT			numeric(8,2),		-- 인원실적
	PAY_AMT			numeric(18), 	-- 급여실적
	PAY_ETC_AMT		numeric(18) 	-- 급여실적(기타금품)
)   
AS 
--<DOCLINE> ***************************************************************************
--<DOCLINE>   TITLE       : 인건비계획/실적
--<DOCLINE>   PROJECT     : H5
--<DOCLINE>   AUTHOR      : ltg
--<DOCLINE>   PROGRAM_ID  : F_PEB_0202
--<DOCLINE>   ARGUMENT    : 
--<DOCLINE>   RETURN      : 
--<DOCLINE>   COMMENT     : 
--<DOCLINE>   HISTORY     : 작성 lhs 2021.07.01
--<DOCLINE> ***************************************************************************
BEGIN
	DECLARE @TEMP_COMPANY TABLE (
		COMPANY_CD		nvarchar(10),	-- 회사코드
		ORG_ID			numeric(38)	-- 부서
	)
	DECLARE @TEMP_REAL TABLE
(
	COMPANY_CD		nvarchar(10),	-- 회사코드
	ORG_NM			nvarchar(50),	-- 소속명
	SUPER_ORG_ID	numeric(38),	-- 상위부서
	ORG_ID			numeric(38),	-- 부서
	MON_CNT			numeric(3),		-- 개월수

	VIEW_CD			nvarchar(10),	-- 

	PHM_CNT			numeric(8,2),		-- 인원실적
	PAY_CNT			numeric(8,2),		-- 인원실적
	PAY_AMT			numeric(18), 	-- 급여실적
	PAY_ETC_AMT		numeric(18) 	-- 급여실적(기타금품)
)   
	DECLARE @d_std_date			date;
	set @d_std_date = dbo.XF_LAST_DAY(@to_month + '01')
	
	INSERT INTO @returnTable
		SELECT 
				'' AS COMPANY_CD, --	A.COMPANY_CD		, -- 회사코드
				'회사계' ORG_NM			, -- 소속명
				NULL SUPER_ORG_ID	, -- 상위부서
				0 ORG_ID			, -- 부서
				NULL MON_CNT		, -- 개월수
				NULL VIEW_CD		,	-- 
				NULL PHM_CNT		,	-- 인원실적
				NULL PAY_CNT		,	-- 인원실적
				NULL PAY_AMT		, 	-- 급여실적
				NULL PAY_ETC_AMT		-- 급여실적(기타금품)

	INSERT INTO @TEMP_REAL
	SELECT --@av_company_cd
			(SELECT COMPANY_CD FROM ORM_ORG WHERE ORG_ID = A.ORG_ID) AS COMPANY_CD
		, ISNULL(dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', MAX(BASE_YMD), '1'),
			    (SELECT ORG_NM FROM ORM_ORG WHERE ORG_ID = A.ORG_ID)) AS ORG_NM
		 , SUPER_ORG_ID -- 
		 , ORG_ID
		 , T.MON_CNT
		 , VIEW_CD
		 , SUM(PHM_CNT   ) / T.MON_CNT AS PHM_CNT
		 , SUM(PAY_CNT   ) / T.MON_CNT AS PAY_CNT
		 , SUM(PAY_AMT   ) AS PAY_AMT
		 , SUM(PAY_ETC_AMT) AS PAY_ETC_AMT
	  FROM (
		SELECT DBO.XF_LAST_DAY(BASE_YM + '01') BASE_YMD,
				NULL SUPER_ORG_ID, ORG_ID, VIEW_CD
				     , PHM_CNT, PAY_CNT, PAY_AMT, PAY_ETC_AMT
				  FROM PEB_EST_PAY
				 WHERE BASE_YM >= @fr_month
				   AND BASE_YM <= @fr_month
				   AND PLAN_CD = @plan_cd 
				   AND TYPE_NM = '인건비'
	   ) A
	   join (select round(dbo.XF_MONTHDIFF( dbo.XF_LAST_DAY( @to_month  + '01'),  @fr_month  + '01' ),0) as MON_CNT ) T
		 ON 1=1
	 GROUP BY SUPER_ORG_ID, ORG_ID, VIEW_CD, T.MON_CNT
	;
	WITH H_ORG AS (
		SELECT ORG_ID, MAX(STA_YMD) STA_YMD
		FROM ORM_ORG_HIS
		WHERE STA_YMD <= @d_std_date
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
				A.MON_CNT			, -- 개월수
				A.VIEW_CD			, -- 구분명
				A.PHM_CNT			, -- 인원실적
				A.PAY_CNT			, -- 인원실적
				A.PAY_AMT			,  -- 급여실적
				A.PAY_ETC_AMT		  -- 급여실적
		  FROM @TEMP_REAL A
		  JOIN T_ORG ORG
		    ON ORG.ORG_ID = A.ORG_ID
	)
	INSERT INTO @returnTable
	SELECT *
	  FROM CTE
	;
	
	WITH H_ORG AS (
		SELECT ORG_ID, MAX(STA_YMD) STA_YMD
		FROM ORM_ORG_HIS
		WHERE STA_YMD <= @d_std_date
		GROUP BY ORG_ID
	), T_ORG AS (
		SELECT B.SUPER_ORG_ID, A.ORG_ID, B.ORG_NM, ORG.COMPANY_CD
		  FROM H_ORG A
		  JOIN ORM_ORG_HIS B
		    ON A.ORG_ID = B.ORG_ID
		   AND A.STA_YMD = B.STA_YMD
		  JOIN ORM_ORG ORG
		    ON B.ORG_ID = ORG.ORG_ID
	), CTE AS (
		SELECT 
				ORG.COMPANY_CD AS COMPANY_CD, --	A.COMPANY_CD		, -- 회사코드
				ORG.ORG_NM			, -- 소속명
				ORG.SUPER_ORG_ID	, -- 상위부서
				ORG.ORG_ID			, -- 부서
				NULL MON_CNT			, -- 개월수
				NULL VIEW_CD		,	-- 
				NULL PHM_CNT		,	-- 인원실적
				NULL PAY_CNT		,	-- 인원실적
				NULL PAY_AMT		, 	-- 급여실적
				NULL PAY_ETC_AMT		-- 급여실적(기타금품)
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
				NULL MON_CNT			, -- 개월수
				NULL VIEW_CD		,	-- 
				NULL PHM_CNT		,	-- 인원실적
				NULL PAY_CNT		,	-- 인원실적
				NULL PAY_AMT		, 	-- 급여실적
				NULL PAY_ETC_AMT		-- 급여실적(기타금품)
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
	INSERT INTO @TEMP_COMPANY
	SELECT COMPANY_CD, MIN( ORG_ID ) AS ORG_ID
	  FROM @returnTable
	 WHERE SUPER_ORG_ID IS NULL AND ORG_ID > 0
	 GROUP BY COMPANY_CD
	UPDATE A
	   SET A.SUPER_ORG_ID = -B.ORG_ID
	  FROM @returnTable A
	  JOIN @TEMP_COMPANY B
	    ON A.COMPANY_CD = B.COMPANY_CD
	  LEFT OUTER JOIN @returnTable A1
	    ON A.SUPER_ORG_ID = A1.ORG_ID
	 WHERE A1.ORG_ID IS NULL
	   AND A.SUPER_ORG_ID > 0
	-- 폐쇄된조직
		INSERT INTO @returnTable
			SELECT 
					COMPANY_CD, --	A.COMPANY_CD		, -- 회사코드
					'폐쇄된조직' ORG_NM			, -- 소속명
					ORG_ID SUPER_ORG_ID	,	-- 상위부서
					-ORG_ID			,	-- 부서
				NULL MON_CNT			, -- 개월수
				NULL VIEW_CD		,	-- 
				NULL PHM_CNT		,	-- 인원실적
				NULL PAY_CNT		,	-- 인원실적
				NULL PAY_AMT		, 	-- 급여실적
				NULL PAY_ETC_AMT		-- 급여실적(기타금품)
				FROM @TEMP_COMPANY A
				WHERE EXISTS (SELECT * FROM @returnTable WHERE SUPER_ORG_ID = -A.ORG_ID)

	UPDATE @returnTable
	   SET SUPER_ORG_ID = 0
	 WHERE SUPER_ORG_ID IS NULL AND ORG_ID > 0
	RETURN
	
END
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[F_PEB_0220] 
( 
	@av_company_cd		nvarchar(50),
	@av_locale_cd		nvarchar(50),
	@fr_month			nvarchar(10),-- = '202101'
	@to_month			nvarchar(10),-- = '202103'
	@prod_kind			nvarchar(10),-- = '20' -- ���꼺���� ��ȹ(10) �� ����(20)
	@peb_kind			nvarchar(10),-- = '10' -- �������� �ӱ�(10) �Ѿ�(20)
	@arb_inc_yn			nvarchar(10) -- = 'N' -- �Ͽ�/�������Կ��� N:������, Y:����
)
RETURNS @returnTable TABLE
(
	COMPANY_CD		nvarchar(10),	-- ȸ���ڵ�
	ORG_NM			nvarchar(50),	-- �ҼӸ�
	SUPER_ORG_ID	numeric(38),	-- �����μ�
	ORG_ID			numeric(38),	-- �μ�
	MON_CNT			numeric(3),		-- ������

	TAKE_AMT		numeric(18),	-- ����-���꼺(����)
	PROFIT_AMT		numeric(18),	-- ����-���꼺(����)
	PHM_CNT			numeric(8,2),		-- �ο�����
	PAY_CNT			numeric(8,2),		-- �ο�����
	PAY_AMT			numeric(18) 	-- �޿�����
)   
AS 
--<DOCLINE> ***************************************************************************
--<DOCLINE>   TITLE       : ȸ�纰���꼺��Ȳ
--<DOCLINE>   PROJECT     : H5
--<DOCLINE>   AUTHOR      : ltg
--<DOCLINE>   PROGRAM_ID  : F_PEB_0210
--<DOCLINE>   ARGUMENT    : 
--<DOCLINE>   RETURN      : 
--<DOCLINE>   COMMENT     : 
--<DOCLINE>   HISTORY     : �ۼ� ltg 2021.05.24
--<DOCLINE> ***************************************************************************
BEGIN
	DECLARE @TEMP_COMPANY TABLE (
		COMPANY_CD		nvarchar(10),	-- ȸ���ڵ�
		ORG_ID			numeric(38)	-- �μ�
	)
	DECLARE @TEMP_REAL TABLE
(
	COMPANY_CD		nvarchar(10),	-- ȸ���ڵ�
	ORG_NM			nvarchar(50),	-- �ҼӸ�
	SUPER_ORG_ID	numeric(38),	-- �����μ�
	ORG_ID			numeric(38),	-- �μ�
	MON_CNT			numeric(3),		-- ������

	TAKE_AMT		numeric(18),	-- ����-���꼺(����)
	PROFIT_AMT		numeric(18),	-- ����-���꼺(����)
	PHM_CNT			numeric(8,2),		-- �ο�����
	PAY_CNT			numeric(8,2),		-- �ο�����
	PAY_AMT			numeric(18) 	-- �޿�����
)   
	DECLARE @d_std_date			date;
	set @d_std_date = dbo.XF_LAST_DAY(@to_month + '01')
	
	INSERT INTO @returnTable
		SELECT 
				'' AS COMPANY_CD, --	A.COMPANY_CD		, -- ȸ���ڵ�
				'ȸ���' ORG_NM			, -- �ҼӸ�
				NULL SUPER_ORG_ID	, -- �����μ�
				0 ORG_ID			, -- �μ�
				NULL MON_CNT			, -- ������

				NULL TAKE_AMT		, -- ����-���꼺(����)
				NULL PROFIT_AMT		, -- ����-���꼺(����)
				NULL PHM_CNT			, -- �ο�����
				NULL PAY_CNT			, -- �ο�����
				NULL PAY_AMT			  -- �޿�����

	INSERT INTO @TEMP_REAL
	SELECT --@av_company_cd
			(SELECT COMPANY_CD FROM ORM_ORG WHERE ORG_ID = A.ORG_ID) AS COMPANY_CD
		, ISNULL(dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', MAX(BASE_YMD), '1'),
			    (SELECT ORG_NM FROM ORM_ORG WHERE ORG_ID = A.ORG_ID)) AS ORG_NM
		 , SUPER_ORG_ID -- MAX(SUPER_ORG_ID) AS SUPER_ORG_ID
		 , ORG_ID
		 , T.MON_CNT

		 , SUM(TAKE_AMT  ) AS TAKE_AMT
		 , SUM(PROFIT_AMT) AS PROFIT_AMT
		 , SUM(PHM_CNT   ) AS PHM_CNT
		 , SUM(PAY_CNT   ) / T.MON_CNT AS PAY_CNT
		 , SUM(PAY_AMT   ) AS PAY_AMT
	  FROM (
		SELECT BASE_YM, BASE_YMD, NULL SUPER_ORG_ID, /* B.SUPER_ORG_ID,*/ A.ORG_ID,
				TAKE_AMT, PROFIT_AMT, PHM_CNT, PAY_CNT, PAY_AMT
			  FROM (SELECT BASE_YM, BASE_YMD, ORG_ID

						 , SUM(CASE WHEN PLAN_CD='20' THEN TAKE_AMT   ELSE 0 END) AS TAKE_AMT
						 , SUM(CASE WHEN PLAN_CD='20' THEN PROFIT_AMT ELSE 0 END) AS PROFIT_AMT
						 , SUM(CASE WHEN PLAN_CD='20' THEN PHM_CNT    ELSE 0 END) AS PHM_CNT
						 , SUM(CASE WHEN PLAN_CD='20' THEN PAY_CNT    ELSE 0 END) AS PAY_CNT
						 , SUM(CASE WHEN PLAN_CD='20' THEN PAY_AMT    ELSE 0 END) AS PAY_AMT
					  FROM (
					  SELECT BASE_YM, DBO.XF_LAST_DAY(BASE_YM + '01') BASE_YMD, ORG_ID, PLAN_CD
						   , TAKE_AMT , PROFIT_AMT, 0 PHM_CNT, 0 PAY_CNT, 0 PAY_AMT
						  FROM PEB_PROD_PLAN -- ���꼺��ǥ
						 WHERE 1=1
						   --AND COMPANY_CD = @av_company_cd
						   AND BASE_YM >= @fr_month
						   AND BASE_YM <= @to_month
						   AND (@prod_kind = '10' AND PLAN_CD = '10') -- ��ȹ �� ���� -- PLAN_CD-10-��ȹ,20-����
					-- ���ⵥ��Ÿ��
						UNION ALL
					  SELECT CONVERT(NVARCHAR(4),SUBSTRING(BASE_YM,1,4) + 1) + SUBSTRING(BASE_YM,5,2) BASE_YM
						   , DBO.XF_LAST_DAY(BASE_YM + '01') BASE_YMD, ORG_ID, '10' PLAN_CD
						   , TAKE_AMT , PROFIT_AMT, 0 PHM_CNT, 0 PAY_CNT, 0 PAY_AMT
						  FROM PEB_PROD_PLAN -- ���꼺��ǥ
						 WHERE 1=1
						   --AND COMPANY_CD = @av_company_cd
						   AND BASE_YM >= CONVERT(NVARCHAR(4), SUBSTRING(@fr_month, 1, 4) - 1) + SUBSTRING(@fr_month, 5, 2)
						   AND BASE_YM <= CONVERT(NVARCHAR(4), SUBSTRING(@to_month, 1, 4) - 1) + SUBSTRING(@to_month, 5, 2)
						   AND (@prod_kind = '20' AND PLAN_CD='20') -- ���� ( ������� )
						UNION ALL
					  SELECT BASE_YM, DBO.XF_LAST_DAY(BASE_YM + '01') BASE_YMD, ORG_ID, PLAN_CD
							 , 0 TAKE_AMT, 0 PROFIT_AMT
							 , CASE WHEN BASE_YM = @to_month THEN PAY_CNT ELSE 0 END PHM_CNT
							 , PAY_CNT
							 , PAY_AMT + CASE WHEN @peb_kind = '20' THEN PAY_ETC_AMT ELSE 0 END AS PAY_AMT
						  FROM PEB_EST_PAY -- �޿� ��ȹ/����
						 WHERE 1=1
						   --AND COMPANY_CD = @av_company_cd
						   AND BASE_YM >= @fr_month
						   AND BASE_YM <= @to_month
						   AND PLAN_CD = '20' -- ��ȹ �� ���� -- PLAN_CD-10-��ȹ,20-����
						   AND CASE WHEN VIEW_CD='50' THEN 'Y' ELSE @arb_inc_yn END = @arb_inc_yn-- �Ͽ�/��������
						   ) U
						GROUP BY BASE_YM, BASE_YMD, ORG_ID
				) A
	   ) A
	   join (select round(dbo.XF_MONTHDIFF( dbo.XF_LAST_DAY( @to_month  + '01'),  @fr_month  + '01' ),0) as MON_CNT ) T
		 ON 1=1
	 GROUP BY SUPER_ORG_ID, ORG_ID, T.MON_CNT
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
				A.COMPANY_CD		, -- ȸ���ڵ�
				A.ORG_NM			, -- �ҼӸ�
				ORG.SUPER_ORG_ID	, -- �����μ�
				A.ORG_ID			, -- �μ�
				A.MON_CNT			, -- ������
				A.TAKE_AMT		, -- ����-���꼺(����)
				A.PROFIT_AMT		, -- ����-���꼺(����)
				A.PHM_CNT			, -- �ο�����
				A.PAY_CNT			, -- �ο�����
				A.PAY_AMT			  -- �޿�����
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
				ORG.COMPANY_CD AS COMPANY_CD, --	A.COMPANY_CD		, -- ȸ���ڵ�
				ORG.ORG_NM			, -- �ҼӸ�
				ORG.SUPER_ORG_ID	, -- �����μ�
				ORG.ORG_ID			, -- �μ�
				NULL MON_CNT			, -- ������
				NULL TAKE_AMT		, -- ����-���꼺(����)
				NULL PROFIT_AMT		, -- ����-���꼺(����)
				NULL PHM_CNT			, -- �ο�����
				NULL PAY_CNT			, -- �ο�����
				NULL PAY_AMT			  -- �޿�����
		  FROM @returnTable A
		  JOIN T_ORG ORG
		    ON A.SUPER_ORG_ID = ORG.ORG_ID
		 WHERE A.SUPER_ORG_ID > 0
		   AND NOT EXISTS(SELECT 1 FROM @returnTable WHERE ORG_ID = A.SUPER_ORG_ID)
		UNION ALL
		SELECT 
				ORG.COMPANY_CD AS COMPANY_CD, --	A.COMPANY_CD		, -- ȸ���ڵ�
				ORG.ORG_NM			, -- �ҼӸ�
				ORG.SUPER_ORG_ID	, -- �����μ�
				ORG.ORG_ID			, -- �μ�
				NULL MON_CNT			, -- ������
				NULL TAKE_AMT		, -- ����-���꼺(����)
				NULL PROFIT_AMT		, -- ����-���꼺(����)
				NULL PHM_CNT			, -- �ο�����
				NULL PAY_CNT			, -- �ο�����
				NULL PAY_AMT			  -- �޿�����
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
	-- ��������
		INSERT INTO @returnTable
			SELECT 
					COMPANY_CD, --	A.COMPANY_CD		, -- ȸ���ڵ�
					'��������' ORG_NM			, -- �ҼӸ�
					ORG_ID SUPER_ORG_ID	,	-- �����μ�
					-ORG_ID			,	-- �μ�
				NULL MON_CNT			, -- ������
				NULL TAKE_AMT		, -- ����-���꼺(����)
				NULL PROFIT_AMT		, -- ����-���꼺(����)
				NULL PHM_CNT			, -- �ο�����
				NULL PAY_CNT			, -- �ο�����
				NULL PAY_AMT			  -- �޿�����
				FROM @TEMP_COMPANY A
				WHERE EXISTS (SELECT * FROM @returnTable WHERE SUPER_ORG_ID = -A.ORG_ID)

	UPDATE @returnTable
	   SET SUPER_ORG_ID = 0
	 WHERE SUPER_ORG_ID IS NULL AND ORG_ID > 0
	RETURN
	
END
DECLARE @v_source_company_cd NVARCHAR(100) = 'E'
	, @v_target_company_cd NVARCHAR(100) = 'A,B,C,E,F,H,I,M,R,S,T,U,W,X,Y'
	, @v_unit_cd NVARCHAR(100) = 'REP'
	, @v_std_kind	NVARCHAR(100) = 'REP_AVG_DC_ITEM_CD,REP_AVG_ITEM_CD,REP_AVG_MGR_ITEM_CD'
	--, @v_std_kind	NVARCHAR(100) = 'REP_AVG_MGR_ITEM_CD'
DECLARE @TARGET_COMPANY TABLE(
	COMPANY_CD	NVARCHAR(10)
)
INSERT INTO @TARGET_COMPANY
SELECT ITEMS
FROM dbo.fn_split_array(@v_target_company_cd,',')
--WHERE Items != @v_source_company_cd

-- 자료수정
--UPDATE A
--   SET KEY_CD2 = NULL
SELECT B.COMPANY_CD, A.*
  FROM FRM_UNIT_STD_HIS A
  JOIN FRM_UNIT_STD_MGR B
    ON A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
  JOIN @TARGET_COMPANY T
    ON B.COMPANY_CD = T.COMPANY_CD
 WHERE 1=1 -- COMPANY_CD = @v_source_company_cd
   AND UNIT_CD = @v_unit_cd
   AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
--   AND A.NOTE IS NOT NULL
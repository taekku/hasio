
DECLARE @company_cd nvarchar(10) = 'F'
DECLARE @session_emp_id numeric(38) = 51747 --50616-- 52046 --51747
DECLARE @emp_id numeric(38) --
DECLARE @locale_cd nvarchar(10) = 'KO' -- @pay_type_cd
DECLARE @pay_type_cd nvarchar(10) 
declare @sta_ymd date = '20210101'
declare @end_ymd date = '20210131'
DECLARE @retro_yn nvarchar(10)  = 'Y'
DECLARE @salary_type_cd nvarchar(10) 
DECLARE @res_biz_cd nvarchar(10) 
DECLARE @mgr_type_cd nvarchar(10) 
DECLARE @org_id numeric(38)
SELECT * FROM VI_FRM_PHM_EMP WHERE EMP_ID=@session_emp_id
;
WITH BIZ AS (
	SELECT PAY_VIEW_ID, PAY_VIEW_NM, CD AS BIZ_CD
	  FROM (
			SELECT A.BIZ_CD AS CD
				 , A.BIZ_NM AS CD_NM
			  FROM ORM_BIZ_INFO A
				   INNER JOIN ORM_BIZ_TYPE B
						   ON A.ORM_BIZ_INFO_ID = B.ORM_BIZ_INFO_ID
						  AND B.BIZ_TYPE_CD = 'PAY'
						  AND dbo.XF_TRUNC_D( GETDATE() ) BETWEEN B.STA_YMD AND B.END_YMD
			 WHERE A.COMPANY_CD =  @company_cd
			) T
	  JOIN (select B.PAY_VIEW_ID, B.PAY_VIEW_NM, ISNULL(ITEM_VALS1,'') ITEM_VALS
			  from PAY_VIEW_USER A JOIN PAY_VIEW B ON A.PAY_VIEW_ID = B.PAY_VIEW_ID
			 WHERE dbo.XF_TRUNC_D( GETDATE() ) BETWEEN A.STA_YMD AND A.END_YMD
			   AND A.EMP_ID =  @session_emp_id 
			   AND B.COMPANY_CD =  @company_cd
			   ) A
		ON 1=1
	   AND (CHARINDEX('|'+T.CD+'|', ITEM_VALS) > 0
				OR ITEM_VALS = '')
 ), MGR AS (
	SELECT PAY_VIEW_ID, PAY_VIEW_NM, CD AS MGR_TYPE_CD 
	  FROM (
			SELECT A.CD
				 , A.CD_NM
				 , A.ORD_NO
			  FROM FRM_CODE A
			 WHERE A.COMPANY_CD = @company_cd
			   AND A.CD_KIND = 'PHM_MGR_TYPE_CD'
			   AND dbo.XF_TRUNC_D( GETDATE() ) BETWEEN STA_YMD AND END_YMD
			) T
	  JOIN (select B.PAY_VIEW_ID, B.PAY_VIEW_NM, ISNULL(ITEM_VALS2,'') ITEM_VALS
			  from PAY_VIEW_USER A
			  JOIN PAY_VIEW B
				ON A.PAY_VIEW_ID = B.PAY_VIEW_ID
			 WHERE dbo.XF_TRUNC_D( GETDATE() ) BETWEEN A.STA_YMD AND A.END_YMD
			   AND A.EMP_ID =  @session_emp_id 
			   AND B.COMPANY_CD = @company_cd
			   ) A
		ON 1=1
	   AND (CHARINDEX('|'+T.CD+'|', ITEM_VALS) > 0
				OR ITEM_VALS = '')
 ), DPT AS (
	SELECT PAY_VIEW_ID, PAY_VIEW_NM, ORG_ID
	  FROM (
			SELECT CAST(ORG_ID AS NVARCHAR) AS CD
			     , ORG_ID
				 --, ORG_NM AS CD_NM
				 --, ORG_CD
			  FROM VI_FRM_ORM_ORG
			 WHERE COMPANY_CD = @company_cd
			   AND dbo.XF_TRUNC_D( GETDATE() ) BETWEEN STA_YMD AND END_YMD
			) T
	  JOIN (select B.PAY_VIEW_ID, B.PAY_VIEW_NM, ISNULL(ITEM_VALS3,'') ITEM_VALS
			  from PAY_VIEW_USER A
			  JOIN PAY_VIEW B
				ON A.PAY_VIEW_ID = B.PAY_VIEW_ID
			 WHERE dbo.XF_TRUNC_D( GETDATE() ) BETWEEN A.STA_YMD AND A.END_YMD
			   AND A.EMP_ID = @session_emp_id 
			   AND B.COMPANY_CD = @company_cd
			   ) A
		ON 1=1
	   AND (CHARINDEX('|'+T.CD+'|', ITEM_VALS) > 0
				OR ITEM_VALS = '')
 ), CTE AS (
 SELECT --DISTINCT
        --COALESCE(A.PAY_VIEW_ID, B.PAY_VIEW_ID, C.PAY_VIEW_ID) PAY_VIEW_ID,
        --COALESCE(A.PAY_VIEW_NM, B.PAY_VIEW_NM, C.PAY_VIEW_NM) PAY_VIEW_NM,
	  A.BIZ_CD, B.MGR_TYPE_CD, C.ORG_ID
 FROM BIZ A
 FULL OUTER JOIN MGR B
   ON A.PAY_VIEW_ID = B.PAY_VIEW_ID
  AND A.PAY_VIEW_NM = B.PAY_VIEW_NM
 FULL OUTER JOIN DPT C
   ON A.PAY_VIEW_ID = C.PAY_VIEW_ID
  AND A.PAY_VIEW_NM = C.PAY_VIEW_NM
 )
SELECT A.PAY_YMD
     , DBO.F_FRM_CODE_NM(@company_cd, @locale_cd, 'PAY_TYPE_CD', A.PAY_TYPE_CD, PAY_YMD, '1') PAY_TYPE_NM
     , DBO.F_FRM_PHM_EMP_NO(A.EMP_ID, @locale_cd, '1') AS EMP_NO --사번
     , DBO.F_FRM_PHM_EMP_NM(A.EMP_ID, @locale_cd, '1') AS EMP_NM  --성명
     , DBO.F_FRM_CODE_NM(@company_cd, @locale_cd, 'PAY_SALARY_TYPE_CD', A.SALARY_TYPE_CD, PAY_YMD, '1') AS SALARY_TYPE_NM  --고용구분
     , DBO.F_FRM_CODE_NM(@company_cd, @locale_cd, 'PHM_POS_GRD_CD',     A.POS_GRD_CD,     PAY_YMD, '1') AS POS_GRD_NM      -- 직급
     , DBO.F_FRM_CODE_NM(@company_cd, @locale_cd, 'PHM_POS_CD',         A.POS_CD,         PAY_YMD, '1') AS POS_NM          -- 직위
     , DBO.F_FRM_CODE_NM(@company_cd, @locale_cd, 'PHM_DUTY_CD',        A.DUTY_CD,        PAY_YMD, '1') AS DUTY_NM         -- 직책
     , DBO.F_FRM_CODE_NM(@company_cd, @locale_cd, 'PAY_GROUP_CD',       A.PAY_GROUP_CD,   PAY_YMD, '1') AS PAY_GROUP_NM    -- 급여그룹
     , DBO.F_FRM_CODE_NM(@company_cd, @locale_cd, 'PHM_YEARNUM_CD',     A.PAY_GRADE,      PAY_YMD, '1') AS PAY_GRADE_NM    -- 호봉
     , DBO.F_ORM_COST_NM(@company_cd, A.ACC_CD, PAY_YMD) AS ACC_NM -- 코스트센터
     , DBO.F_FRM_CODE_NM(@company_cd, @locale_cd, 'PHM_MGR_TYPE_CD',    A.MGR_TYPE_CD,    PAY_YMD, '1') AS MGR_TYPE_NM    -- 관리구분
     , DBO.F_FRM_CODE_NM(@company_cd, @locale_cd, 'PHM_IN_OFFI_YN_CD',  B.IN_OFFI_YN,     PAY_YMD, '1') AS IN_OFFI_YN_NM   -- 재직구분
     , B.HIRE_YMD
     , B.RETIRE_YMD
     , DBO.F_FRM_ORM_ORG_NM(A.ORG_ID, @locale_cd ,PAY_YMD,'1') AS ORG_NM -- 소속
     , DBO.F_FRM_ORM_ORG_NM(A.ORG_ID, @locale_cd ,PAY_YMD,'10') AS ORG_CD -- 소속
     , DBO.F_FRM_DECRYPT_C(B.CTZ_NO) AS CTZ_NO
     --<<dstmt>>
 FROM VI_PAY_PAYROLL_DETAIL_ALL A
      INNER JOIN VI_FRM_PHM_EMP B ON A.COMPANY_CD = B.COMPANY_CD AND A.EMP_ID = B.EMP_ID AND B.LOCALE_CD = @locale_cd
WHERE (A.PAY_YMD BETWEEN @sta_ymd AND @end_ymd AND ( @pay_type_cd IS NULL OR  A.PAY_TYPE_CD =  @pay_type_cd))
--AND ( PAY_ITEM_TYPE_CD IN ('PAY_PAY', 'PAY', 'PAY_GN', 'PAY_G', 'DEDUCT', 'TAX', 'TAX_N_P')  )
  AND ( (@retro_yn = 'Y') OR (@retro_yn = 'N' AND A.PAY_YMD_ID = A.BEL_PAY_YMD_ID))
  AND ( @org_id IS NULL OR A.ORG_ID  = @org_id  )
  AND ( @emp_id IS NULL OR A.EMP_ID  = @emp_id ) 
  AND ( @salary_type_cd IS NULL OR  A.SALARY_TYPE_CD = @salary_type_cd )
  AND A.COMPANY_CD = @company_cd
  AND DBO.F_FRM_CODE_NM(@company_cd, @locale_cd, 'PAY_TYPE_CD', A.PAY_TYPE_CD, A.PAY_YMD, 'S') <> '100'	--시뮬레이션 제외
  AND (@res_biz_cd IS NULL OR A.RES_BIZ_CD = @res_biz_cd)
  AND (@mgr_type_cd IS NULL OR A.MGR_TYPE_CD = @mgr_type_cd)
  AND EXISTS (SELECT 1 FROM CTE WHERE BIZ_CD = A.RES_BIZ_CD AND MGR_TYPE_CD = A.MGR_TYPE_CD AND ORG_ID = A.ORG_ID)
GROUP BY A.COMPANY_CD, A.PAY_YMD_ID,A.PAY_YMD, A.PAY_TYPE_CD
, A.EMP_ID         -- 사원ID  
, A.SALARY_TYPE_CD --급여유형
, A.POS_GRD_CD     -- 직급코드 [PHM_POS_GRD_CD] 
, A.POS_CD         -- 직위코드 [PHM_POS_CD] 
, A.ORG_ID         -- 발령부서ID
, A.DUTY_CD        -- 직책
, A.PAY_GROUP_CD   -- 급여그룹
, A.PAY_GRADE      -- 호봉
, A.ACC_CD         -- 코스트센터
, A.MGR_TYPE_CD    -- 관리구분
, B.IN_OFFI_YN     -- 재직구분
, B.HIRE_YMD
, B.RETIRE_YMD
, B.CTZ_NO
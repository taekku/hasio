SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   FUNCTION [dbo].[F_PAY_GROUP_CHK]
    (  @an_pay_group_id         NUMERIC,         -- 급여그룹ID
	   @an_emp_id               NUMERIC,         -- 사원ID
       @ad_base_ymd             DATE             -- 기준일자
    ) RETURNS INT
    -- ***************************************************************************
    --   TITLE       : 급여그룹체크
	--   DESCRIPTION : 급여그룹ID에 사원ID가 포함되는지 여부
    --   PROJECT     : H5
    --   AUTHOR      : 임택구
    --   PROGRAM_ID  : F_PAY_GROUP_CHK
    --   ARGUMENT    : an_pay_group_id      : 급여그룹ID
	--                 an_emp_id            : 사원ID
    --                 ad_base_ymd          : 기준일자
    --   RETURN      : 0(false), @an_pay_group_id(true)
    --   HISTORY     :
    -- ***************************************************************************
AS
BEGIN
    DECLARE @v_company_cd     NVARCHAR(50),    -- 회사코드
            @v_locale_cd      NVARCHAR(50),    -- 지역코드
            @v_pay_group      NVARCHAR(50),    -- 그룹코드
			@v_item_type      NVARCHAR(10),    -- 적용항목구분
			@v_item_cond      NVARCHAR(10),    -- 적용조건
			@v_item_vals      NVARCHAR(4000),  -- 적용항목상세
			@v_org_id         NVARCHAR(50),    -- 소속ID
			@n_org_id		  NUMERIC(38),     -- 소속ID
			@d_base_ymd		  DATE,
			@v_pay_biz_cd     NVARCHAR(50),	   -- 급여사업장
			@v_pos_grade_cd   NVARCHAR(10),    -- 직급
			@v_mgr_cd         NVARCHAR(10),    -- 관리구분
			@v_emp_kind_cd    NVARCHAR(10),    -- 근로형태
												  
            @n_cond_val       NUMERIC(1,0),    -- 조건 적용값
            @v_ret            INT              -- 결과값
/*
항목구분
10	사업장
20	부서
30	직급
40	관리구분
50	근로형태
*/

    SELECT @v_company_cd = COMPANY_CD
         , @v_locale_cd  = LOCALE_CD
		 , @v_pay_group = PAY_GROUP
		 , @an_pay_group_id = PAY_GROUP_ID
      FROM PAY_GROUP 
     WHERE PAY_GROUP_ID = @an_pay_group_id--3597848

	IF SUBSTRING(@v_pay_group, 2, 3) = 'XXX' -- 조회전용은 바로 리턴
		BEGIN
			set @v_ret = @an_pay_group_id
			RETURN @v_ret
		END

	SELECT @v_org_id       = CONVERT(NVARCHAR(50), EMP.ORG_ID),        -- 부서ID 20
	       @v_pos_grade_cd = EMP.POS_GRD_CD,    -- 직급 30
	       @v_mgr_cd       = EMP.MGR_TYPE_CD,   -- 관리구분 40
	       @v_emp_kind_cd  = emp.EMP_KIND_CD,    -- 근로형태 50
		   --@v_pay_biz_cd   = ISNULL(dbo.F_ORM_ORG_BIZ(EMP.ORG_ID, ISNULL(EMP.RETIRE_YMD, GETDATE()), 'PAY'),'001') -- 사업장 10
		   @v_pay_biz_cd   = dbo.F_ORM_ORG_BIZ(EMP.ORG_ID, ISNULL(EMP.RETIRE_YMD, GETDATE()), 'PAY') -- 사업장 10
		   --@n_org_id       = EMP.ORG_ID,
		   --@d_base_ymd     = ISNULL(EMP.RETIRE_YMD, GETDATE())
	  FROM VI_FRM_PHM_EMP EMP 
	 WHERE EMP.EMP_ID      = @an_emp_id
	   AND EMP.COMPANY_CD  = @v_company_cd
       AND EMP.LOCALE_CD   = @v_locale_cd

	SET @v_ret = @an_pay_group_id

	SELECT TOP 1 @v_ret = CHECK_BIT
	  FROM (
        SELECT
			 CASE WHEN ISNULL(NULLIF(CHARINDEX('|' + 
								CASE WHEN ITEM_TYPE = '10' THEN @v_pay_biz_cd-- dbo.F_ORM_ORG_BIZ(@n_org_id, @d_base_ymd, 'PAY')--@v_pay_biz_cd
									 WHEN ITEM_TYPE = '20' THEN @v_org_id
									 WHEN ITEM_TYPE = '30' THEN @v_pos_grade_cd
									 WHEN ITEM_TYPE = '40' THEN @v_mgr_cd
									 WHEN ITEM_TYPE = '50' THEN @v_emp_kind_cd
									 ELSE NULL END
							+ '|', ITEM_VALS), 0), -1) * CASE WHEN ITEM_COND='10' THEN 1 ELSE -1 END < 0
						THEN 0
						ELSE 1 END AS CHECK_BIT
          FROM PAY_GROUP 
          UNPIVOT ( ITEM_TYPE FOR ITEM_TYPE_COL IN (ITEM_TYPE1, ITEM_TYPE2, ITEM_TYPE3, ITEM_TYPE4, ITEM_TYPE5) )  UNPVT1
          UNPIVOT ( ITEM_COND FOR ITEM_COND_COL IN (ITEM_COND1, ITEM_COND2, ITEM_COND3, ITEM_COND4, ITEM_COND5) )  UNPVT2
          UNPIVOT ( ITEM_VALS FOR ITEM_VALS_COL IN (ITEM_VALS1, ITEM_VALS2, ITEM_VALS3, ITEM_VALS4, ITEM_VALS5) )  UNPVT3
         WHERE PAY_GROUP_ID = @an_pay_group_id
           AND RIGHT(ITEM_TYPE_COL,1)  = RIGHT(ITEM_COND_COL, 1)
           AND RIGHT(ITEM_COND_COL,1)  = RIGHT(ITEM_VALS_COL, 1)
           AND RIGHT(ITEM_VALS_COL,1)  = RIGHT(ITEM_TYPE_COL, 1)
		   ) A
		WHERE CHECK_BIT = 0
    RETURN @v_ret
END

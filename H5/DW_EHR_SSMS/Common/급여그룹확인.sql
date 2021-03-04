DECLARE @an_pay_group_id NUMERIC(38) = 3625050
      , @v_company_cd NVARCHAR(10) = 'C'
	  , @ad_base_ymd DATE-- = '20170082'
	  , @an_emp_id numeric(38)
select @an_emp_id = emp_id
     , @ad_base_ymd = ISNULL(RETIRE_YMD, GETDATE())
  from phm_emp
 where COMPANY_CD='C'
   and EMP_NO='20170082'
SELECT ITEM_TYPE
             , ITEM_COND
             , ITEM_VALS
          FROM PAY_GROUP WITH (NOLOCK)
          UNPIVOT ( ITEM_TYPE FOR ITEM_TYPE_COL IN (ITEM_TYPE1, ITEM_TYPE2, ITEM_TYPE3, ITEM_TYPE4, ITEM_TYPE5) )  UNPVT1
          UNPIVOT ( ITEM_COND FOR ITEM_COND_COL IN (ITEM_COND1, ITEM_COND2, ITEM_COND3, ITEM_COND4, ITEM_COND5) )  UNPVT2
          UNPIVOT ( ITEM_VALS FOR ITEM_VALS_COL IN (ITEM_VALS1, ITEM_VALS2, ITEM_VALS3, ITEM_VALS4, ITEM_VALS5) )  UNPVT3
         WHERE PAY_GROUP_ID = @an_pay_group_id
           AND RIGHT(ITEM_TYPE_COL,1)  = RIGHT(ITEM_COND_COL, 1) -- RIGHT('ITEM_TYPE1',1) = RIGHT('ITEM_COND1',1)
           AND RIGHT(ITEM_COND_COL,1)  = RIGHT(ITEM_VALS_COL, 1)
           AND RIGHT(ITEM_VALS_COL,1)  = RIGHT(ITEM_TYPE_COL, 1)

SELECT EMP.ORG_ID,        -- 부서ID 20
	      -- @v_org_cd       = EMP.ORG_CD,        -- 부서 20
	       EMP.POS_GRD_CD,    -- 직급 30
	       EMP.MGR_TYPE_CD,   -- 관리구분 40
	       emp.EMP_KIND_CD,    -- 근로형태 50
		   dbo.F_ORM_ORG_BIZ(EMP.ORG_ID, @ad_base_ymd, 'PAY') -- 사업장 10
		   , EMP.EMP_ID
		   , dbo.F_PAY_GROUP_CHK( @an_pay_group_id , EMP.EMP_ID, @ad_base_ymd)
		   , @ad_base_ymd retire_ymd
	  FROM VI_FRM_PHM_EMP EMP WITH (NOLOCK)
	  --FROM VI_FRM_CAM_HISTORY EMP WITH (NOLOCK)
	 WHERE EMP.EMP_ID      = @an_emp_id
	   AND EMP.COMPANY_CD  = @v_company_cd
	   --AND ISNULL(@ad_base_ymd, getDate()) BETWEEN STA_YMD AND END_YMD
select @an_emp_id, @v_company_cd, @ad_base_ymd, dbo.F_ORM_ORG_BIZ(EMP.ORG_ID, GETDATE(), 'PAY')
from VI_FRM_PHM_EMP emp
where EMP_ID=@an_emp_id
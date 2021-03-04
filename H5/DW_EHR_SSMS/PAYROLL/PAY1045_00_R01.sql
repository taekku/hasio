DECLARE @company_cd nvarchar(10)
DECLARE @sta_ymd date
DECLARE @end_ymd date
DECLARE @pay_group_id numeric(38)
DECLARE @pay_type_cd nvarchar(10)
DECLARE @pay_item_type_cd nvarchar(10)
set @company_cd = 'E'
set @sta_ymd = '2020-04-01'
set @end_ymd = '2020-04-30'

SELECT C.PAY_ITEM_TYPE_CD, A.PAY_YMD, C.BEL_PAY_TYPE_CD, C.PAY_ITEM_CD,
		SUM(CASE WHEN C.CAL_MON <> 0 THEN 1 ELSE 0 END) CAL_CNT,
	   SUM(C.CAL_MON) AS CAL_MON
  FROM PAY_PAYROLL_DETAIL AS C, PAY_PAYROLL AS B, PAY_PAY_YMD  AS A,
       VI_FRM_PHM_EMP EMP
 WHERE C.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID AND B.PAY_YMD_ID = A.PAY_YMD_ID
   AND B.EMP_ID = EMP.EMP_ID AND EMP.LOCALE_CD = 'KO'
   AND A.COMPANY_CD = @company_cd
   AND A.PAY_YMD BETWEEN @sta_ymd and @end_ymd
   AND (@pay_group_id IS NULL OR dbo.F_PAY_GROUP_CHK(@pay_group_id, EMP.EMP_ID, PAY_YMD) = @pay_group_id)
   AND (@pay_type_cd IS NULL OR c.BEL_PAY_TYPE_CD = @pay_type_cd)
   AND (@pay_item_type_cd IS NULL OR c.PAY_ITEM_TYPE_CD = @pay_item_type_cd)
 group by C.PAY_ITEM_TYPE_CD, A.PAY_YMD, C.BEL_PAY_TYPE_CD, C.PAY_ITEM_CD
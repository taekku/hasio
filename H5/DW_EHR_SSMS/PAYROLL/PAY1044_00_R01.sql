DECLARE @company_cd nvarchar(10)
DECLARE @sta_ymd date
DECLARE @end_ymd date
DECLARE @pay_group_id numeric(38)
DECLARE @pay_type_cd nvarchar(10)
DECLARE @pay_item_type_cd nvarchar(10)
set @company_cd = 'E'
set @sta_ymd = '2020-04-01'
set @end_ymd = '2020-04-30'

SELECT A.PAY_YMD,
       dbo.XF_TO_CHAR_D(A.PAY_YMD,'yyyy.mm.dd_')+
       dbo.F_FRM_CODE_NM(A.COMPANY_CD, EMP.LOCALE_CD,'PAY_TYPE_CD',A.PAY_TYPE_CD, A.PAY_YMD, '1') AS PAY_BEL_NM,
       EMP.EMP_ID,
	   EMP.EMP_NO,
	   EMP.EMP_NM,
	   dbo.F_FRM_ORM_ORG_NM( EMP.ORG_ID, EMP.LOCALE_CD, A.PAY_YMD, '11' ) AS ORG_NM,
	   dbo.F_FRM_CODE_NM( EMP.COMPANY_CD, EMP.LOCALE_CD, 'PHM_POS_GRD_CD', EMP.POS_GRD_CD, PAY_YMD, '1') AS POS_GRD_NM,
	   dbo.F_FRM_CODE_NM( EMP.COMPANY_CD, EMP.LOCALE_CD, 'PAY_TYPE_CD', C.BEL_PAY_TYPE_CD, PAY_YMD, '1') AS BEL_PAY_TYPE_NM,
	   dbo.F_FRM_CODE_NM( EMP.COMPANY_CD, EMP.LOCALE_CD, 'PAY_ITEM_TYPE_CD', C.PAY_ITEM_TYPE_CD, PAY_YMD, '1') AS PAY_ITEM_TYPE_NM,
	   dbo.F_FRM_CODE_NM( EMP.COMPANY_CD, EMP.LOCALE_CD, 'PAY_ITEM_CD', C.PAY_ITEM_CD, PAY_YMD, '1') AS PAY_ITEM_NM,
	   A.PAY_YM,
	   C.CAL_MON,
	   C.BEL_PAY_YM
  FROM PAY_PAYROLL_DETAIL AS C, PAY_PAYROLL AS B, PAY_PAY_YMD  AS A,
       VI_FRM_PHM_EMP EMP
 WHERE C.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID AND B.PAY_YMD_ID = A.PAY_YMD_ID
   AND B.EMP_ID = EMP.EMP_ID AND EMP.LOCALE_CD = 'KO'
   AND A.COMPANY_CD = @company_cd
   AND A.PAY_YMD BETWEEN @sta_ymd and @end_ymd
   AND (@pay_group_id IS NULL OR dbo.F_PAY_GROUP_CHK(@pay_group_id, EMP.EMP_ID, PAY_YMD) = @pay_group_id)
   AND (@pay_type_cd IS NULL OR c.BEL_PAY_TYPE_CD = @pay_type_cd)
   AND (@pay_item_type_cd IS NULL OR c.PAY_ITEM_TYPE_CD = @pay_item_type_cd)
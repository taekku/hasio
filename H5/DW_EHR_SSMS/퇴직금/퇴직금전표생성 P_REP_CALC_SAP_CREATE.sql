USE [dwehrdev_H5]
GO

DECLARE @RC int
DECLARE @av_company_cd nvarchar(10) = 'E'
DECLARE @av_locale_cd nvarchar(10) = 'KO'
DECLARE @an_rep_calc_list_id numeric(38,0) = 4374347
DECLARE @an_mod_user_id numeric(38,0) = 60487
DECLARE @av_ret_code nvarchar(4000)
DECLARE @av_ret_message nvarchar(4000)

SELECT  GETDATE()
	     ,  FILLDT
		 , FILLNO
		 , AUTO_YN
		 , AUTO_YMD
		 , AUTO_NO
	  FROM REP_CALC_LIST
	 WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id

SELECT A.COMPANY_CD, A.REP_CALC_LIST_ID,
				dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', A.PAY_YMD, '10') AS ORG_CD,
				EMP.EMP_NO, EMP.EMP_NM,
				A.POS_GRD_CD, A.INS_TYPE_YN, ISNULL(A.INS_TYPE_CD,'00'),
				A.C_01, A.CT01, A.CT02, A.PENSION_RESERVE,
				--@v_acct_type,
				dbo.F_PAY_GET_COST( @av_company_cd, A.EMP_ID, A.ORG_ID, GETDATE(), '1') AS COST_CD -- 코스트센터
				, A.ORG_ID
		  FROM REP_CALC_LIST A
		  INNER JOIN VI_FRM_PHM_EMP EMP
				  ON A.EMP_ID = EMP.EMP_ID AND EMP.LOCALE_CD = @av_locale_cd
				 AND A.CALC_TYPE_CD IN ('01','02','04')
		 WHERE A.REP_CALC_LIST_ID = @an_rep_calc_list_id
EXECUTE @RC = [dbo].[P_REP_CALC_SAP_CREATE] 
   @av_company_cd
  ,@av_locale_cd
  ,@an_rep_calc_list_id
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT

SELECT @av_ret_code, @av_ret_message

SELECT FILLDT
					     , FILLNO
						 , AUTO_YN
						 , AUTO_YMD
						 , AUTO_NO
FROM REP_CALC_LIST
					 WHERE REP_CALC_LIST_ID = 4374347-- @an_rep_calc_list_id
GO



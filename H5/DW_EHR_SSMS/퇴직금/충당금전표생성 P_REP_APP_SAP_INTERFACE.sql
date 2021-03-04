USE [dwehrdev_H5]
GO

DECLARE @RC int
DECLARE @av_company_cd nvarchar(10)
DECLARE @av_locale_cd nvarchar(10)
DECLARE @ad_std_date date
DECLARE @av_pay_group nvarchar(10)
DECLARE @av_ins_type_cd nvarchar(10)
DECLARE @av_mgr_type_cd nvarchar(10)
DECLARE @av_fr_org_cd nvarchar(10)
DECLARE @av_to_org_cd nvarchar(10)
DECLARE @an_emp_id numeric(38,0)
DECLARE @an_mod_user_id numeric(38,0)
DECLARE @av_ret_code nvarchar(4000)
DECLARE @av_ret_message nvarchar(4000)

-- TODO: 여기에서 매개 변수 값을 설정합니다.
SELECT @av_company_cd = 'E'
     , @av_locale_cd = 'KO'
	 , @ad_std_date = '20191231'
	 , @an_mod_user_id = 123456789

EXECUTE @RC = [dbo].[P_REP_APP_SAIP_INTERFACE] 
   @av_company_cd
  ,@av_locale_cd
  ,@ad_std_date
  ,@av_pay_group
  ,@av_ins_type_cd
  ,@av_mgr_type_cd
  ,@av_fr_org_cd
  ,@av_to_org_cd
  ,@an_emp_id
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT
SELECT @RC, @av_ret_code, @av_ret_message
GO
USE [dwehrdev_H5]
GO

DECLARE @RC int
DECLARE @av_company_cd nvarchar(10)
DECLARE @av_locale_cd nvarchar(10)
DECLARE @ad_std_ymd date
DECLARE @av_pay_group nvarchar(10)
DECLARE @an_org_id numeric(38,0)
DECLARE @an_emp_id numeric(38,0)
DECLARE @an_mod_user_id numeric(38,0)
DECLARE @av_ret_code varchar(500)
DECLARE @av_ret_message varchar(4000)

-- TODO: 여기에서 매개 변수 값을 설정합니다.
set @av_company_cd = 'E'
set @av_locale_cd = 'KO'
set @ad_std_ymd = '20191231'
--set @av_pay_group = 'EA01'
--set @an_emp_id = 60487
set @an_mod_user_id = 1234

EXECUTE @RC = [dbo].[P_REP_ESTIMATION_CALC] 
   @av_company_cd
  ,@av_locale_cd
  ,@ad_std_ymd
  ,@av_pay_group
  ,@an_org_id
  ,@an_emp_id
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT

SELECT @RC, @av_ret_code, @av_ret_message

SELECT *
FROM REP_ESTIMATION
WHERE COMPANY_CD = 'E'
AND ESTIMATION_YMD = @ad_std_ymd
GO

USE [dwehrdev_H5]
GO

DECLARE @RC int
DECLARE @av_company_cd nvarchar(10) = 'E'
DECLARE @av_locale_cd nvarchar(10) = 'KO'
DECLARE @av_calc_type_cd nvarchar(10) = '03'
DECLARE @ad_std_ymd date = '20201231'
DECLARE @an_pay_group_id numeric(38,0)
DECLARE @an_org_id numeric(38,0)
DECLARE @an_emp_id numeric(38,0)
DECLARE @an_mod_user_id numeric(38,0) = 60487111
DECLARE @av_ret_code varchar(500)
DECLARE @av_ret_message varchar(4000)

-- TODO: 여기에서 매개 변수 값을 설정합니다.

declare @s_time datetime2
      , @e_time datetime2
	  
set @s_time = SYSDATETIME()
EXECUTE @RC = [dbo].[P_REP_ESTIMATION_MAKE] 
   @av_company_cd
  ,@av_locale_cd
  ,@av_calc_type_cd
  ,@ad_std_ymd
  ,@an_pay_group_id
  ,@an_org_id
  ,@an_emp_id
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT

set @e_time = SYSDATETIME()
SELECT @s_time, @e_time, DATEDIFF(microsecond, @s_time, @e_time) 마이크로,DATEDIFF(MILLISECOND, @s_time, @e_time) 밀리초, @av_ret_code, @av_ret_message
GO



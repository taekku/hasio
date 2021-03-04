DECLARE @RC int
DECLARE @av_company_cd nvarchar(10)
DECLARE @av_locale_cd nvarchar(10)
DECLARE @an_pay_ymd_id numeric(18,0)
DECLARE @an_org_id numeric(18,0)
DECLARE @an_emp_id numeric(18,0)
DECLARE @an_mod_user_id numeric(18,0)
DECLARE @av_ret_code nvarchar(4000)
DECLARE @av_ret_message nvarchar(4000)

-- TODO: 여기에서 매개 변수 값을 설정합니다.
set @av_company_cd = 'E'
set @av_locale_cd = 'KO'
set @an_pay_ymd_id = 3598187
set @an_mod_user_id = 6459695

EXECUTE @RC = [dbo].[P_PAY_PAYROLL_MAKE] 
   @av_company_cd
  ,@av_locale_cd
  ,@an_pay_ymd_id
  ,@an_org_id
  ,@an_emp_id
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT

print @av_ret_code + @av_ret_message
GO

select *
from PAY_PAYROLL
where pay_ymd_id = 3598187
GO

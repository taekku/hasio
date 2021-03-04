USE [dwehrdev_H5]
GO

DECLARE @RC int
DECLARE @an_peb_base_id numeric(18,0)
DECLARE @av_company_cd nvarchar(10)
DECLARE @ad_base_ymd date
DECLARE @av_cal_emp_no nvarchar(max)
DECLARE @av_locale_cd nvarchar(10)
DECLARE @av_tz_cd nvarchar(10)
DECLARE @an_mod_user_id numeric(18,0)
DECLARE @av_ret_code nvarchar(100)
DECLARE @av_ret_message nvarchar(500)

-- TODO: 여기에서 매개 변수 값을 설정합니다.
set @an_peb_base_id = 107123
set @av_company_cd = 'E'
set @ad_base_ymd = '20201031'
set @av_cal_emp_no = NULL--'20140002'
--set @av_cal_emp_no = '20110022'
set @av_cal_emp_no = '20140002'
set @av_locale_cd = 'KO'
set @av_tz_cd = 'KST'
set @an_mod_user_id = 6639947
PRINT '시작시간:' + CONVERT(VARCHAR(100), GETDATE())
EXECUTE @RC = [dbo].[P_PEB_PAYROLL_CALC] 
   @an_peb_base_id
  ,@av_company_cd
  ,@ad_base_ymd
  ,@av_cal_emp_no
  ,@av_locale_cd
  ,@av_tz_cd
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT
  
PRINT 'END 시간:' + CONVERT(VARCHAR(100), GETDATE())
print  @av_ret_code + ':' + @av_ret_message

GO



USE [dwehrdev_H5]
GO

DECLARE @RC int
DECLARE @av_company_cd nvarchar(10) = 'X'
DECLARE @av_hrtype_gbn nvarchar(10) = 'H8301'
DECLARE @av_bill_gbn nvarchar(10) = 'R5108'
DECLARE @av_pay_ym nvarchar(10) = '202103'
DECLARE @av_pay_type_sys_cd nvarchar(10) = '001'
DECLARE @ad_proc_date date = '20210322'
DECLARE @av_emp_no nvarchar(10) = '20200470'
DECLARE @av_locale_cd nvarchar(10) = 'KO'
DECLARE @av_tz_cd nvarchar(10) = 'KST'
DECLARE @an_mod_user_id numeric(18,0) = 111381
DECLARE @av_ret_code nvarchar(100)
DECLARE @av_ret_message nvarchar(500)

-- TODO: 여기에서 매개 변수 값을 설정합니다.

EXECUTE @RC = [dbo].[P_PBT_AT_DEBIS_IF] 
   @av_company_cd
  ,@av_hrtype_gbn
  ,@av_bill_gbn
  ,@av_pay_ym
  ,@av_pay_type_sys_cd
  ,@ad_proc_date
  ,@av_emp_no
  ,@av_locale_cd
  ,@av_tz_cd
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT
SELECT @RC, @av_ret_code, @av_ret_message
GO



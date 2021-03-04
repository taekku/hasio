USE [dwehrdev_H5]
GO
--SELECT REP_CALC_LIST_ID, EMP_ID, CALC_TYPE_CD, RETIRE_YMD, EMP_ID
--FROM REP_CALC_LIST
--WHERE EMP_ID=69073
---- 4283722, 69073

--SELECT *
--FROM rep_pay_std
--WHERE REP_CALC_LIST_ID = 4283722
---- 4376189

--SELECT *
--FROM REP_PAYROLL_DETAIL
--WHERE REP_PAY_STD_ID=4376189

declare @s_time datetime2
      , @e_time datetime2
DECLARE @RC int
DECLARE @av_company_cd varchar(10) = 'E'
DECLARE @an_rep_calc_list_id numeric(38,0) = 4283722
DECLARE @an_rep_pay_std_id numeric(38,0) = 4376189
DECLARE @av_pay_ym varchar(8) = '202003'
DECLARE @av_pay_type_cd varchar(10) = '10'
DECLARE @an_base_day numeric(10,0) = 20
DECLARE @an_real_day numeric(10,0) = 20
DECLARE @av_flag varchar(10) = 'Y'
DECLARE @an_mod_user_id numeric(38,0) = 60487
DECLARE @an_retrun_cal_mon numeric(38,0)
DECLARE @av_ret_code varchar(4000)
DECLARE @av_ret_message varchar(4000)

-- TODO: 여기에서 매개 변수 값을 설정합니다.

SET @s_time = SYSDATETIME()
EXECUTE @RC = [dbo].[P_REP_CAL_PAY_DETAIL_NEW] 
   @av_company_cd
  ,@an_rep_calc_list_id
  ,@an_rep_pay_std_id
  ,@av_pay_ym
  ,@av_pay_type_cd
  ,@an_base_day
  ,@an_real_day
  ,@av_flag
  ,@an_mod_user_id
  ,@an_retrun_cal_mon OUTPUT
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT

set @e_time = SYSDATETIME()
SELECT 'OLD' KIND,  @s_time, @e_time, datediff( microsecond , @s_time , @e_time) as 시간차, @an_retrun_cal_mon, @av_ret_code, @av_ret_message

SET @s_time = SYSDATETIME()
EXECUTE @RC = [dbo].[P_REP_CAL_PAY_DETAIL] 
   @av_company_cd
  ,@an_rep_calc_list_id
  ,@an_rep_pay_std_id
  ,@av_pay_ym
  ,@av_pay_type_cd
  ,@an_base_day
  ,@an_real_day
  ,@av_flag
  ,@an_mod_user_id
  ,@an_retrun_cal_mon OUTPUT
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT

set @e_time = SYSDATETIME()
SELECT 'NEW' KIND,  @s_time, @e_time, datediff( microsecond , @s_time , @e_time) as 시간차,  @an_retrun_cal_mon, @av_ret_code, @av_ret_message
GO



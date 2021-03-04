USE [dwehrdev_H5]
GO

DECLARE @RC int
DECLARE @av_company_cd nvarchar(10) = 'E'
DECLARE @av_locale_cd nvarchar(10) = 'KO'
DECLARE @an_work_id numeric(38,0) = 1853592021028131022
DECLARE @av_work_cd nvarchar(10) = '1'
DECLARE @an_mod_user_id numeric(38,0) = 60487
DECLARE @av_ret_code nvarchar(4000)
DECLARE @av_ret_message nvarchar(4000)

declare @s_time datetime2
      , @e_time datetime2

insert
 into	REP_TMP_SAVE (
	work_id
 ,	etc
 ,	tmp_list_id
 ,	emp_id
 ) values (
 	@an_work_id
 ,	NULL
 ,	4283722
 ,	60487
 )
-- TODO: 여기에서 매개 변수 값을 설정합니다.
set @s_time = SYSDATETIME()
EXECUTE @RC = [dbo].[P_REP_CAL_RETIRE_AMT] 
   @av_company_cd
  ,@av_locale_cd
  ,@an_work_id
  ,@av_work_cd
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT
set @e_time = SYSDATETIME()
SELECT @s_time, @e_time, DATEDIFF(microsecond, @s_time, @e_time) 마이크로,DATEDIFF(MILLISECOND, @s_time, @e_time) 밀리초, @av_ret_code, @av_ret_message
GO
-- 2021-01-28 16:48:52.0208430	2021-01-28 16:48:52.2239636	203120	203	SUCCESS!	프로시져 실행 완료[ERR] [PROGRAM_NAME : P_REP_CAL_RETIRE_AMT(9999)] : 
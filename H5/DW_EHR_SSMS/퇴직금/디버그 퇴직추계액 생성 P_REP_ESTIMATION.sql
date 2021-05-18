DECLARE @RC int
DECLARE @av_company_cd nvarchar(10) --= 'F'
DECLARE @av_locale_cd nvarchar(10) = 'KO'
DECLARE @av_calc_type_cd nvarchar(10) = '03'
DECLARE @ad_std_ymd date = '20201130'
DECLARE @ad_calc_sta_ymd date = '20191201'
DECLARE @ad_calc_end_ymd date = '20201130'
DECLARE @ad_res_yn nvarchar(10) = 'N'
DECLARE @an_pay_group_id numeric(38,0) --= 29586151
DECLARE @an_org_id numeric(38,0)
DECLARE @an_emp_id numeric(38,0)-- = 50150 -- 50403
DECLARE @an_mod_user_id numeric(38,0) =1234
DECLARE @av_ret_code nvarchar(50)
DECLARE @av_ret_message nvarchar(2000)

SELECT @an_pay_group_id = PAY_GROUP_ID
     , @av_company_cd = COMPANY_CD
  FROM PAY_GROUP
 WHERE COMPANY_CD= 'F' -- @av_company_cd
   AND PAY_GROUP = 'F11'
IF @@ROWCOUNT < 1
	BEGIN
		PRINT '급여그룹확인'
		RETURN
	END
-- TODO: 여기에서 매개 변수 값을 설정합니다.
/*
SELECT *
FROM PAY_GROUP
WHERE COMPANY_CD = 'f'
*/

EXECUTE @RC = [dbo].[P_REP_ESTIMATION] 
   @av_company_cd
  ,@av_locale_cd
  ,@av_calc_type_cd
  ,@ad_std_ymd
  ,@ad_calc_sta_ymd
  ,@ad_calc_end_ymd
  ,@ad_res_yn
  ,@an_pay_group_id
  ,@an_org_id
  ,@an_emp_id
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT
  print @av_ret_code
  print @av_ret_message
select @av_ret_code, @av_ret_message
--select YEAR_MONTH_AMT --9*
--from REP_CALC_LIST
--where EMP_ID=@an_emp_id
--and COMPANY_CD='F'
--and PAY_YMD = @ad_std_ymd

GO




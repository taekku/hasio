USE [dwehrdev_H5]
GO

DECLARE @RC int
DECLARE @av_company_cd nvarchar(100)
DECLARE @av_locale_cd nvarchar(100)
DECLARE @an_emp_id numeric(18,0)
DECLARE @av_pay_item_cd nvarchar(max)
DECLARE @av_pay_item_value nvarchar(max)
DECLARE @av_pay_item_value_text nvarchar(max)
DECLARE @ad_sta_ymd date
DECLARE @ad_end_ymd date
DECLARE @an_pay_ymd_id numeric(18,0)
DECLARE @an_in_pay_ymd_id numeric(18,0)
DECLARE @av_salary_type_cd nvarchar(max)
DECLARE @av_retro_type nvarchar(max)
DECLARE @av_pay_type_cd nvarchar(max)
DECLARE @an_bel_org_id numeric(18,0)
DECLARE @av_tz_cd nvarchar(max)
DECLARE @an_mod_user_id numeric(18,0)
DECLARE @av_ret_code nvarchar(1000)
DECLARE @av_ret_message nvarchar(1000)

-- TODO: 여기에서 매개 변수 값을 설정합니다.
set @av_company_cd = 'E'
set @av_locale_cd = 'KO'
set @an_emp_id = 60487
set @av_pay_item_cd = 'BP001'
set @av_pay_item_value = '' -- 데이타
set @av_pay_item_value_text = '테스트임' -- 데이타 설명
set @ad_sta_ymd = '20200801' -- 시작일자
set @ad_end_ymd = '20200831' -- 종료일자
set @an_pay_ymd_id = 4266750 -- 현재급여일자ID(개인별소급급열일자 테이블에 넣을 급여 일자)
--set @an_in_pay_ymd_id -- 급여일자 ID (기초원장에 넣을 경우에만 넘기고 아니면 NULL을 넘김, 기초원장에 등록될 급여일자)
set @av_salary_type_cd = '002' -- 대상자의 급여유형
set @av_retro_type = '3' -- 소급 유형 [1 :모든 지급유형 소급, 2 : 같은 지급유형만 소급, 3: 소급 없음]
--set @av_pay_type_cd -- 지급유형
--set @an_bel_org_id  -- 귀속부서id
set @av_tz_cd = 'KST' -- 타임존코드
set @an_mod_user_id = 0 -- 변경자 사원id

EXECUTE @RC = [dbo].[P_PAY_MST_CHANGE_INSERT] 
   @av_company_cd
  ,@av_locale_cd
  ,@an_emp_id
  ,@av_pay_item_cd
  ,@av_pay_item_value
  ,@av_pay_item_value_text
  ,@ad_sta_ymd
  ,@ad_end_ymd
  ,@an_pay_ymd_id
  ,@an_in_pay_ymd_id
  ,@av_salary_type_cd
  ,@av_retro_type
  ,@av_pay_type_cd
  ,@an_bel_org_id
  ,@av_tz_cd
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT
GO



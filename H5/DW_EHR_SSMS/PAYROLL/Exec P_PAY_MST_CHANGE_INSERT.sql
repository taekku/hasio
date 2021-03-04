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

-- TODO: ���⿡�� �Ű� ���� ���� �����մϴ�.
set @av_company_cd = 'E'
set @av_locale_cd = 'KO'
set @an_emp_id = 60487
set @av_pay_item_cd = 'BP001'
set @av_pay_item_value = '' -- ����Ÿ
set @av_pay_item_value_text = '�׽�Ʈ��' -- ����Ÿ ����
set @ad_sta_ymd = '20200801' -- ��������
set @ad_end_ymd = '20200831' -- ��������
set @an_pay_ymd_id = 4266750 -- ����޿�����ID(���κ��ұޱ޿����� ���̺� ���� �޿� ����)
--set @an_in_pay_ymd_id -- �޿����� ID (���ʿ��忡 ���� ��쿡�� �ѱ�� �ƴϸ� NULL�� �ѱ�, ���ʿ��忡 ��ϵ� �޿�����)
set @av_salary_type_cd = '002' -- ������� �޿�����
set @av_retro_type = '3' -- �ұ� ���� [1 :��� �������� �ұ�, 2 : ���� ���������� �ұ�, 3: �ұ� ����]
--set @av_pay_type_cd -- ��������
--set @an_bel_org_id  -- �ͼӺμ�id
set @av_tz_cd = 'KST' -- Ÿ�����ڵ�
set @an_mod_user_id = 0 -- ������ ���id

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



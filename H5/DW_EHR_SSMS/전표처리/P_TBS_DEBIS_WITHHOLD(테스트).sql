
DECLARE @RC int
DECLARE @av_company_cd nvarchar(10) = 'X'
DECLARE @av_hrtype_gbn nvarchar(10) = 'H8301'
DECLARE @av_tax_kind_cd nvarchar(10) = 'A1' -- (�޿� : A1, �� : B1, �������� : E1, �������� : C1 ,�ߵ����� : D1)
DECLARE @av_close_ym nvarchar(10) = '202101'
DECLARE @ad_proc_date date = '20210131'
DECLARE @av_emp_id nvarchar(10) = 67791
DECLARE @av_locale_cd nvarchar(10) = 'KO'
DECLARE @av_tz_cd nvarchar(10) = 'KST'
DECLARE @an_mod_user_id numeric(18,0) = 6643645
DECLARE @av_ret_code nvarchar(100)
DECLARE @av_ret_message nvarchar(500)


-- TODO: ���⿡�� �Ű� ���� ���� �����մϴ�.

EXECUTE @RC = [dbo].[P_TBS_DEBIS_WITHHOLD] 
   @av_company_cd
  ,@av_hrtype_gbn
  ,@av_tax_kind_cd
  ,@av_close_ym
  ,@ad_proc_date
  ,@av_emp_id
  ,@av_locale_cd
  ,@av_tz_cd
  ,@an_mod_user_id
  ,@av_ret_code OUTPUT
  ,@av_ret_message OUTPUT

SELECT @RC, @av_ret_code, @av_ret_message
GO

--�޿����� ���߼���->����� ����
USE [dwehr_H5];
GO
DECLARE @av_ret_code varchar(4000);
DECLARE @av_ret_message varchar(4000);
DECLARE @return_value int;
SET @av_ret_code = NULL;
SET @av_ret_message = NULL;
EXEC  @return_value = dwehr_H5.dbo.P_PAY_PAYITEM_CODE_COPY_TO_LIVE 
    @av_copy_type = '10',
    @ad_base_ymd = '2021-04-02',
    
    @av_s_company_cd = 'E',								--������ ȸ���ڵ�		�ʼ�
    @av_s_pay_type_cd = '001',						--������ ��������		����
    @av_s_salary_type_cd = 'CODE_COMM',		--������ �޿�����		����
    @av_s_pay_item_cd = 'P001',						--������ �޿��׸�		����
    
    @av_t_company_cd = 'E',								--s�� �����ϰ�		�ʼ�
    @av_t_pay_type_cd = '001',						--s�� �����ϰ�		����
    @av_t_salary_type_cd = 'CODE_COMM',		--s�� �����ϰ�		����
    @av_t_pay_item_cd = 'P001',						--s�� �����ϰ�		����
    
    @av_locale_cd = 'KO',
    @an_mod_user_id = '99999',
    @av_ret_code = @av_ret_code out,
    @av_ret_message = @av_ret_message out;
	
SELECT @av_ret_code as '@av_ret_code', @av_ret_message as '@av_ret_message', @return_value as '@Return Value';
GO
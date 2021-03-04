DECLARE @RC int
DECLARE @av_company_cd nvarchar(10)
DECLARE @av_hrtype_gbn nvarchar(10)
DECLARE @av_bill_gbn nvarchar(10)
DECLARE @av_pay_ym nvarchar(10)
DECLARE @av_pay_type_sys_cd nvarchar(10)
DECLARE @ad_proc_date date
DECLARE @av_emp_no nvarchar(10)
DECLARE @av_locale_cd nvarchar(10)
DECLARE @av_tz_cd nvarchar(10)
DECLARE @an_mod_user_id numeric(18,0)
DECLARE @av_ret_code nvarchar(100)
DECLARE @av_ret_message nvarchar(500)

-- TODO: 여기에서 매개 변수 값을 설정합니다.
-- { call dbo.P_PBT_AT_DEBIS_IF('X','H8301','P5101','202012','001' ,2020-12-03 00:00:00.0,'20160294','KO','KST',67791 ,[out]'SUCCESS!',[out]'급여전표를 생성했습니다..[ERR] [PROGRAM_NAME : P_PBT_AT_DEBIS_IF(0)] : ')}
SELECT @av_company_cd='X'
     , @av_hrtype_gbn='H8301'
	 , @av_bill_gbn='P5101'
	 , @av_pay_ym='202012'
	 , @av_pay_type_sys_cd='001'
	 , @ad_proc_date='20201203'
	 , @av_emp_no='20160294'
	 , @av_locale_cd='KO'
	 , @av_tz_cd='KST'
	 , @an_mod_user_id=67791
	 
SELECT PBT_ACCNT_STD_ID, WRTDPT_CD,   BILL_GBN,   TRDTYP_CD,    ACCNT_CD
			  ,CUST_CD,     AGGR_GBN,   CSTDPAT_CD,   CSTDPAT_CD
			  ,TRDTYP_NM,   TRDTYP_NM,  SUMMARY,      DEBSER_GBN
			  ,COST_ACCTCD, MGNT_ACCTCD    -- 판관비계정코드
		  FROM PBT_ACCNT_STD
		 WHERE COMPANY_CD = @av_company_cd         -- 회사코드
		   AND HRTYPE_GBN = @av_hrtype_gbn    -- 인력유형구분
		   AND BILL_GBN = @av_bill_gbn          -- 전표구분
		   AND USE_YN = 'Y'
		 ORDER BY DEBSER_GBN, TRDTYP_CD
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

SELECT @RC
     , @av_ret_code
     , @av_ret_message

SELECT *
	FROM PBT_BILL_CREATE
	WHERE COMPANY_CD = @av_company_cd
	AND HRTYPE_GBN = @av_hrtype_gbn
	AND PAY_YM = @av_pay_ym
	AND PAY_CD = @av_pay_type_sys_cd
	AND BILL_GBN = @av_bill_gbn
	ORDER BY SEQ
--insert openquery(EHRIF,'select * from CT_IF_EHRDATA')
					 --  (SITE_CD, --	사업장코드
						--FILE_GB, --	파일구분
						--FILE_DATE, --	파일생성일
						--FILE_CNT, --	파일회차
						--FILE_SEQ, --	SEQ
						--IN_BANK_CD, --	입금은행코드
						--IN_ACCT_NO, --	입금계좌번호
						--TRAN_AMT, --	이체금액
						--PRE_RECI_MAN, --	예상수취인명
						--PAY_GB, --	지급구분
						--REMARK, --	적요
						--ERP_REC_NO, --	ERP_REC_NO
						--ERP_DATE, --	ERP_DATE
						--ERP_TIME --	ERP_TIME
						--)
select SITE_CD, -- 사업장코드
	FILE_GB, -- 파일구분
	FILE_DATE, -- 파일생성일
	FILE_CNT, -- 파일회차
	FILE_SEQ, -- SEQ
	dbo.XF_LPAD( IN_BANK_CD, 3, '0' ) AS IN_BANK_CD, -- 입금은행코드
	IN_ACCT_NO, -- 입금계좌번호
	TRAN_AMT, -- 이체금액
	PRE_RECI_MAN, -- 예상수취인명
	PAY_GB, -- 지급구분
	REMARK, -- 적요
	ERP_REC_NO, -- ERP_REC_NO
	ERP_DATE, -- ERP_DATE
	ERP_TIME -- ERP_TIME
from CT_IF_EHRDATA
where SITE_CD='104-86-17961' -- T 테크팩
--where SITE_CD='123-81-15163' -- C 시스템즈
AND FILE_DATE='20210625'

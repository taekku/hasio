--insert openquery(EHRIF,'select * from CT_IF_EHRDATA')
					 --  (SITE_CD, --	������ڵ�
						--FILE_GB, --	���ϱ���
						--FILE_DATE, --	���ϻ�����
						--FILE_CNT, --	����ȸ��
						--FILE_SEQ, --	SEQ
						--IN_BANK_CD, --	�Ա������ڵ�
						--IN_ACCT_NO, --	�Աݰ��¹�ȣ
						--TRAN_AMT, --	��ü�ݾ�
						--PRE_RECI_MAN, --	��������θ�
						--PAY_GB, --	���ޱ���
						--REMARK, --	����
						--ERP_REC_NO, --	ERP_REC_NO
						--ERP_DATE, --	ERP_DATE
						--ERP_TIME --	ERP_TIME
						--)
select SITE_CD, -- ������ڵ�
	FILE_GB, -- ���ϱ���
	FILE_DATE, -- ���ϻ�����
	FILE_CNT, -- ����ȸ��
	FILE_SEQ, -- SEQ
	dbo.XF_LPAD( IN_BANK_CD, 3, '0' ) AS IN_BANK_CD, -- �Ա������ڵ�
	IN_ACCT_NO, -- �Աݰ��¹�ȣ
	TRAN_AMT, -- ��ü�ݾ�
	PRE_RECI_MAN, -- ��������θ�
	PAY_GB, -- ���ޱ���
	REMARK, -- ����
	ERP_REC_NO, -- ERP_REC_NO
	ERP_DATE, -- ERP_DATE
	ERP_TIME -- ERP_TIME
from CT_IF_EHRDATA
where SITE_CD='104-86-17961' -- T ��ũ��
--where SITE_CD='123-81-15163' -- C �ý�����
AND FILE_DATE='20210625'

-----------------------
-- H_IF_SAPINTERFACE --
-----------------------
/*
CD_COMPANY	ȸ���ڵ�
MANDT_S	��������
GSBER_S	�ͼӺμ� <-- �ڽ�Ʈ����?
LIFNR_S	����ó�ڵ� <-- 
ZPOSN_S	���� <-- CD_POSITION : POS_GRD_CD
SEQNO_S	�������� <-- ��ĭ 0���� ä�� 10�ڸ�
DRAW_DATE	�̰�����
SNO	���	<-- EMP_NO
SNM	����� <-- EMP_NM
COST_CENTER	�ڽ�Ʈ���� <-- COST_CD
SAP_ACCTCODE	ȸ����� <-- '00' + �����ڵ�
AMT	�ݾ�
DBCR_GU	���뱸�� <-- 40:����(Debit) 50:�뺯(Credit) 31:�����ޱ�
SEQ	����
ACCT_TYPE	�̰�����
FLAG	FLAG <-- N���� ����
PAY_YM	�޿����
PAY_DATE	��������
PAY_SUPP	���ޱ���	<-- �ڵ尡 �ƴ� ��Ī
ITEM_CODE	�����׸� <--
PAYGP_CODE	�޿��׷�
IFC_SORT	��õ����
SLIP_DATE	�޿�������
REMARK	���
ID_INSERT	�Է���
DT_INSERT	�Է���
ID_UPDATE	������
DT_UPDATE	������
XNEGP	-������
ACCNT_CD	������
SEQ_H	��ǥ��ȣ
GUBUN	
COMPANY_CD	ȸ���ڵ�
PAY_TYPE_CD	���ޱ���
PAY_ACNT_TYPE_CD	�������� 510:��������_SAP, 805:�뿪����_SAP
PAY_ITEM_NM	�޿��׸��
*/

select *
from H_IF_SAPINTERFACE
where SEQ = 1
AND DRAW_DATE='20201117'

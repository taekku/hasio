/**
 * �����ο����� ���� �ڷắ��
 * �η������� H8301�� �׸��� �ٹ����ڵ尪�� �ִ� �͸� �̰�
 **/
DELETE
from TBS_EMP_BIZ
WHERE COMPANY_CD='X'

INSERT INTO TBS_EMP_BIZ(
TBS_EMP_BIZ_ID, -- ����������ID
COMPANY_CD, -- ȸ���ڵ�
EMP_ID, -- ���ID
BIZ_CD, -- �Ű������ڵ�
STA_YMD, -- ��������
END_YMD, -- ��������
NOTE, -- ���
MOD_USER_ID, -- ������
MOD_DATE, -- �����Ͻ�
TZ_CD, -- Ÿ�����ڵ�
TZ_DATE -- Ÿ�����Ͻ�
)
SELECT 
next value for S_TBS_SEQUENCE TBS_EMP_BIZ_ID, -- ����������ID
B.COMPANY_CD, -- ȸ���ڵ�
B.EMP_ID, -- ���ID
A.CD_WORK_AREA AS BIZ_CD, -- �Ű������ڵ�
A.DT_JOIN STA_YMD, -- ��������
ISNULL(A.DT_RETIRE, '29991231') END_YMD, -- ��������
'HUMAN' NOTE, -- ���
0 MOD_USER_ID, -- ������
SYSDATETIME() MOD_DATE, -- �����Ͻ�
'KST' TZ_CD, -- Ÿ�����ڵ�
SYSDATETIME() TZ_DATE -- Ÿ�����Ͻ�
FROM dwehrdev.dbo.H_HUMAN A
JOIN PHM_EMP_NO_HIS B
ON A.CD_COMPANY = B.COMPANY_CD
AND A.NO_PERSON = B.EMP_NO
where HRTYPE_GBN = 'H8301'
and CD_WORK_AREA > ' '

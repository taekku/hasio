SELECT A.PHM_BASE_DAY_ID              --������ ID
	 , A.EMP_ID                       --��� ID
	 , A.PERSON_ID                    --���� ID
	 , A.BASE_TYPE_CD                 --�����������ڵ�
	 , convert(char(20), A.BASE_YMD, 102)   AS BASE_YMD                --��������
	 , A.STA_YMD                      --��������
	 , A.END_YMD                      --��������
	 , A.NOTE                         --���
  FROM PHM_BASE_DAY A
INNER JOIN PHM_EMP B ON (A.EMP_ID = B.EMP_ID)
 WHERE (1=1)
 AND B.COMPANY_CD='E'
 AND A.EMP_ID =  78734 
 AND  '2020-09-07 00:00:00.0'  BETWEEN A.STA_YMD AND A.END_YMD
-- AND A.BASE_TYPE_CD='RETIRE_STD_YMD'
 AND A.BASE_TYPE_CD='FRIST_JOIN_YMD'
;

SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=78734 AND GETDATE() BETWEEN STA_YMD AND END_YMD AND BASE_TYPE_CD='RETIRE_STD_YMD'
;

HIRE_YMD	--	�Ի���
GROUP_YMD	-- �׷��Ի���
FIRST_JOIN_YMD	--	�����Ի���
POS_GRD_YMD	--	���޽�����
POS_YMD	--	����������
ORG_YMD	--	�μ���ġ��
YEARNUM_YMD	--	ȣ����ȣ��
BE_POS_GRD_YMD	--	�迭�����޽�����
WORK_AMT_YMD	--	�ټӼ�������
NEXT_POS_GRD_YMD	--	���������
NEXT_YEARNUM_YMD	--	�����ȣ��
POINT_STD_YMD	--	POINT�����
ANNUAL_CAL_YMD	--	���������
RETIRE_STD_YMD	--	���������

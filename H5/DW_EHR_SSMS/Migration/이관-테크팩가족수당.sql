DECLARE @company_cd varchar(10) = 'T'
      , @locale_cd varchar(10) = 'KO'
	  , @in_offi_yn varchar(10) = 'Y'
	  , @pay_group_id numeric(38)
	  , @org_id numeric(38)
	  , @emp_id numeric(38) = 51753

insert into PAY_PHM_FAMILY(
PAY_PHM_FAMILY_ID, -- ��������ID
EMP_ID, -- ���ID
PERSON_ID, -- ����ID
FAM_CTZ_NO, -- �����ֹι�ȣ
FAM_LAST_NM, -- ��������(��)
FAM_FIRST_NM, -- ��������(�̸�)
FAM_REL_CD, -- ���������ڵ� [PHM_REL_CD]
SUPPORT_YN, -- �ξ��ڿ���
HANICAP_YN, -- ����ڿ���
FAM_PAY_YN, -- �������翩��
NOTE, -- ���
MOD_USER_ID, -- ������
MOD_DATE, -- �����Ͻ�
TZ_CD, -- Ÿ�����ڵ�
TZ_DATE -- Ÿ�����Ͻ�
)
select NEXT value FOR S_PAY_SEQUENCE pay_phm_family_id
     , a.emp_id
	 , a.person_id
	 , fam_ctz_no
	 , fam_last_nm
	 , fam_first_nm
	 ,  fam_rel_cd
	 , SUPPORT_YN
	 , HANICAP_YN
	 , 'Y' as fam_pay_yn
	 , 'MIG' note
	 , A.MOD_USER_ID
	 , A.MOD_DATE
	 , A.TZ_CD
	 , A.TZ_DATE
from phm_family A
join PHM_EMP EMP
on A.EMP_ID = EMP.EMP_ID
where getDate() between STA_YMD and END_YMD 
  and EMP.COMPANY_CD = @company_cd
  and A.FAM_REL_CD in ('11','21','22')
  and EMP.IN_OFFI_YN = 'Y'
  and not EXISTS (select * from PAY_PHM_FAMILY pay
                   where pay.emp_id = a.EMP_ID
                     and pay.fam_ctz_no = a.FAM_CTZ_NO
                     and pay.fam_last_nm = a.fam_last_nm )
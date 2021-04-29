DECLARE @company_cd varchar(10) = 'T'
      , @locale_cd varchar(10) = 'KO'
	  , @in_offi_yn varchar(10) = 'Y'
	  , @pay_group_id numeric(38)
	  , @org_id numeric(38)
	  , @emp_id numeric(38) = 51753

insert into PAY_PHM_FAMILY(
PAY_PHM_FAMILY_ID, -- 가족수당ID
EMP_ID, -- 사원ID
PERSON_ID, -- 개인ID
FAM_CTZ_NO, -- 가족주민번호
FAM_LAST_NM, -- 가족성명(성)
FAM_FIRST_NM, -- 가족성명(이름)
FAM_REL_CD, -- 가족관계코드 [PHM_REL_CD]
SUPPORT_YN, -- 부양자여부
HANICAP_YN, -- 장애자여부
FAM_PAY_YN, -- 가족수당여부
NOTE, -- 비고
MOD_USER_ID, -- 변경자
MOD_DATE, -- 변경일시
TZ_CD, -- 타임존코드
TZ_DATE -- 타임존일시
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
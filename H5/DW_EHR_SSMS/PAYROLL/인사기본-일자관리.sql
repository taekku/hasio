SELECT A.PHM_BASE_DAY_ID              --기준일 ID
	 , A.EMP_ID                       --사원 ID
	 , A.PERSON_ID                    --개인 ID
	 , A.BASE_TYPE_CD                 --기준일종류코드
	 , convert(char(20), A.BASE_YMD, 102)   AS BASE_YMD                --기준일자
	 , A.STA_YMD                      --시작일자
	 , A.END_YMD                      --종료일자
	 , A.NOTE                         --비고
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

HIRE_YMD	--	입사일
GROUP_YMD	-- 그룹입사일
FIRST_JOIN_YMD	--	최초입사일
POS_GRD_YMD	--	직급승진일
POS_YMD	--	직위승진일
ORG_YMD	--	부서배치일
YEARNUM_YMD	--	호봉승호일
BE_POS_GRD_YMD	--	계열사직급승진일
WORK_AMT_YMD	--	근속수당기산일
NEXT_POS_GRD_YMD	--	차기승진일
NEXT_YEARNUM_YMD	--	차기승호일
POINT_STD_YMD	--	POINT기산일
ANNUAL_CAL_YMD	--	연차기산일
RETIRE_STD_YMD	--	퇴직기산일

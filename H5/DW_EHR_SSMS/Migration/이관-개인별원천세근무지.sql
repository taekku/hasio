/**
 * 동원로엑스를 위한 자료변경
 * 인력유형이 H8301만 그리고 근무지코드값이 있는 것만 이관
 **/
DELETE
from TBS_EMP_BIZ
WHERE COMPANY_CD='X'

INSERT INTO TBS_EMP_BIZ(
TBS_EMP_BIZ_ID, -- 사원별사업장ID
COMPANY_CD, -- 회사코드
EMP_ID, -- 사원ID
BIZ_CD, -- 신고사업장코드
STA_YMD, -- 시작일자
END_YMD, -- 종료일자
NOTE, -- 비고
MOD_USER_ID, -- 변경자
MOD_DATE, -- 변경일시
TZ_CD, -- 타임존코드
TZ_DATE -- 타임존일시
)
SELECT 
next value for S_TBS_SEQUENCE TBS_EMP_BIZ_ID, -- 사원별사업장ID
B.COMPANY_CD, -- 회사코드
B.EMP_ID, -- 사원ID
A.CD_WORK_AREA AS BIZ_CD, -- 신고사업장코드
A.DT_JOIN STA_YMD, -- 시작일자
ISNULL(A.DT_RETIRE, '29991231') END_YMD, -- 종료일자
'HUMAN' NOTE, -- 비고
0 MOD_USER_ID, -- 변경자
SYSDATETIME() MOD_DATE, -- 변경일시
'KST' TZ_CD, -- 타임존코드
SYSDATETIME() TZ_DATE -- 타임존일시
FROM dwehrdev.dbo.H_HUMAN A
JOIN PHM_EMP_NO_HIS B
ON A.CD_COMPANY = B.COMPANY_CD
AND A.NO_PERSON = B.EMP_NO
where HRTYPE_GBN = 'H8301'
and CD_WORK_AREA > ' '

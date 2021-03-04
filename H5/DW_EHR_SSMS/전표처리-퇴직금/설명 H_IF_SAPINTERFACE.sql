-----------------------
-- H_IF_SAPINTERFACE --
-----------------------
/*
CD_COMPANY	회사코드
MANDT_S	서버정보
GSBER_S	귀속부서 <-- 코스트센터?
LIFNR_S	구매처코드 <-- 
ZPOSN_S	직위 <-- CD_POSITION : POS_GRD_CD
SEQNO_S	문서순서 <-- 빈칸 0으로 채운 10자리
DRAW_DATE	이관일자
SNO	사번	<-- EMP_NO
SNM	사원명 <-- EMP_NM
COST_CENTER	코스트센터 <-- COST_CD
SAP_ACCTCODE	회계계정 <-- '00' + 계정코드
AMT	금액
DBCR_GU	차대구분 <-- 40:차변(Debit) 50:대변(Credit) 31:미지급금
SEQ	순번
ACCT_TYPE	이관구분
FLAG	FLAG <-- N으로 고정
PAY_YM	급여년월
PAY_DATE	지급일자
PAY_SUPP	지급구분	<-- 코드가 아닌 명칭
ITEM_CODE	지급항목 <--
PAYGP_CODE	급여그룹
IFC_SORT	원천구분
SLIP_DATE	급여지급일
REMARK	비고
ID_INSERT	입력자
DT_INSERT	입력일
ID_UPDATE	수정자
DT_UPDATE	수정일
XNEGP	-지시자
ACCNT_CD	상대계정
SEQ_H	전표번호
GUBUN	
COMPANY_CD	회사코드
PAY_TYPE_CD	지급구분
PAY_ACNT_TYPE_CD	계정유형 510:관리계정_SAP, 805:용역계정_SAP
PAY_ITEM_NM	급여항목명
*/

select *
from H_IF_SAPINTERFACE
where SEQ = 1
AND DRAW_DATE='20201117'

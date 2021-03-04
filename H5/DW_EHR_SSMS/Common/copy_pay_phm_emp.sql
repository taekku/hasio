INSERT INTO PAY_PHM_EMP (
	 EMP_ID	-- 사원ID
	,PERSON_ID	-- 개인ID
	,COMPANY_CD	-- 인사영역코드
	,EMP_NO	-- 사번
	,TAX_FAMILY_CNT	-- 부양가족수
	,FOREIGN_YM	-- 외국인여부
	,FOREJOB_YN	-- 국외근로여부
	,PROD_YN	-- 생산직여부
	,PICK_YN	-- 임금피크대상여부
	,TRBNK_YN	-- 신협공제대상여부
	,WORK_YN	-- 근속수당지급여부
	,UNION_CD	-- 노조사업장코드
	,UNION_YN	-- 노조회비공제대상여부
	,PAY_METH_CD	-- 급여지급방식코드[PAY_METH_CD]
	,EMP_CLS_CD	-- 고용유형코드[PAY_EMP_CLS_CD]
	,EMAIL_YN	-- E_MAIL발송여부
	,SMS_YN	-- SMS발송여부
	,YEAR_YMD	-- 연차기산일자
	,RETR_YMD	-- 퇴직금기산일자
	,WORK_YMD	-- 근속기산일자
	,ADV_YN	-- 선망가불금공제여부
	,CONT_TIME	-- 소정근로시간
	,PEN_ACCU_AMT	-- 연금적립액
	,MOD_USER_ID	-- 변경자
	,MOD_DATE	-- 변경일시
	,TZ_CD	-- 타임존코드
	,TZ_DATE	-- 타임존일시
)
select B.EMP_ID, B.PERSON_ID, B.COMPANY_CD , B.EMP_NO
     , A.CNT_FAMILY -- 부양가족수
     , A.YN_FOREIGN -- 외국인여부
     , A.YN_FOREJOB -- 국외근로여부
     , A.YN_PROD_LABOR -- 생산직여부
     , 'N' -- 임긒피스대상여부
     , A.YN_CRE -- 신협공제대상여부	
	, 'N' --WORK_YN	--근속수당지급여부
	, '' -- TODO -- UNION_CD	--노조사업장코드
	, A.YN_LABOR_OBJ --UNION_YN	--노조회비공제대상여부
	, A.TP_CALC_PAY --PAY_METH_CD	--급여지급방식코드[PAY_METH_CD]
	, A.TP_CALC_INS --EMP_CLS_CD	--고용유형코드[PAY_EMP_CLS_CD]
	, A.YN_EMAIL -- EMAIL_YN	--E_MAIL발송여부
	, A.YN_SMS -- SMS_YN	--SMS발송여부
	, dbo.XF_TO_DATE(A.DT_YEAR_RECK,'YYYYMMDD') --YEAR_YMD	--연차기산일자
	, dbo.XF_TO_DATE(A.DT_RETR_RECK,'YYYYMMDD')RETR_YMD	--퇴직금기산일자
	, b.HIRE_YMD -- TODO -- WORK_YMD	--근속기산일자
	, A.YN_ADVANCE -- ADV_YN	--선망가불금공제여부
	, NULL -- TODO -- CONT_TIME	--소정근로시간
	, A.AMT_RETR_ANNU -- PEN_ACCU_AMT	--연금적립액
	, 0 --MOD_USER_ID	--변경자
	, ISNULL(DT_INS_UPDATE,'1900-01-01') --MOD_DATE	--변경일시
	, 'KST' TZ_CD	--타임존코드
	, ISNULL(DT_INS_UPDATE,'1900-01-01') -- TZ_DATE	--타임존일시
from dwehrdev.dbo.H_PAY_MASTER A
join dwehrdev_H5.dbo.phm_emp b
on a.CD_COMPANY  = b.COMPANY_CD 
and a.NO_PERSON = b.EMP_NO 
--WHERE A.CD_COMPANY <> 'E'

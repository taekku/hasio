
SELECT A.REP_CALC_LIST_ID,   -- 퇴직금 대상 ID
       A.COMPANY_CD,     -- 인사영역
       A.EMP_ID EMP_ID,   -- 사원ID
       P.DAY_EMP_MST_ID, -- 일용직
       P.EMP_NO,   -- 사번
       P.EMP_NM,   -- 성명
       A.ORG_ID,   -- 소속ID
       A.PAY_ORG_ID, -- 급여부서ID
       A.PAY_YMD,    -- 지급일
       A.CALC_TYPE_CD, -- 정산구분
       A.TAX_TYPE,     -- 세금방식
       A.CALC_RETIRE_CD, -- 정산유형
       A.END_YN,   -- 완료여부
       A.C1_STA_YMD,   -- 기산일
       A.C1_END_YMD,   -- 주(현)정산일
       A.WORK_YY,   -- (실)근속년수
       A.WORK_MM,   -- (실)근속월수
       A.WORK_DD,   -- (실)근속일수
       A.WORK_DAY,  -- 근속총일수
       A.EXCE_STA_YMD,   -- 퇴직제외시작일
       A.EXCE_END_YMD,   -- 퇴직제외종료일
       A.PAY_TOT_AMT,    -- 3개월급여
       A.AVG_PAY_AMT_M,  -- 평균급여(월)
       A.AVG_PAY_AMT_D,  -- 평균급여(일)
       A.C_01,  -- 퇴직금
       A.CT01,   -- 퇴직소득세
       A.CT02,   -- 퇴직주민세
       A.NOTE,    -- 비고
       '<div class="width_100" ><input type="button" class="btn_gride" value="내용보기"></div>' as detail_view,
       '<div class="width_100" ><input type="button" class="btn_gride" value="정산명세"></div>' AS REPORT1,
       '/common/img/popup_up.png' AS REPORT2,
       '<div class="width_100" ><input type="button" class="btn_gride" value="원천징수영수증"></div>' AS REPORT3
  FROM REP_CALC_LIST A
 INNER JOIN DAY_EMP_MST P
         ON A.EMP_ID = P.DAY_EMP_MST_ID
        AND A.CALC_TYPE_CD = '20'
 WHERE P.COMPANY_CD =  'E' 
   AND A.C1_END_YMD BETWEEN  '2020-10-28 00:00:00.0'  and  '2020-10-31 00:00:00.0'
   AND ( '20'  IS NULL OR A.CALC_TYPE_CD =  '20' )
   AND ( NULL  IS NULL OR P.DAY_EMP_MST_ID =  NULL )
 ORDER BY A.COMPANY_CD, A.C1_END_YMD, A.EMP_ID

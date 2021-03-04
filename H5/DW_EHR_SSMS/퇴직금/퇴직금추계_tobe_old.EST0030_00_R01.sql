SELECT A.REP_ESTIMATION_ID    -- 퇴직 추계액ID
     , A.ESTIMATION_YM    -- 퇴직추계년월
     , A.EMP_ID    -- 사원ID
     , dbo.F_PHM_EMP_NO( A.EMP_ID, '1' ) AS EMP_NO
     , dbo.F_PHM_EMP_NM( A.EMP_ID, dbo.XF_SYSDATE(0), B.LOCALE_CD ) AS EMP_NM
     , A.ORG_ID    -- 발령부서ID
     , dbo.F_FRM_ORM_ORG_NM( A.ORG_ID, B.LOCALE_CD, A.END_YMD, '11' ) AS ORG_NM    -- 소속명
     , A.PAY_ORG_ID    -- 급여부서ID
     , A.EMP_KIND_CD    -- 직원구분[임원,연봉,일반]
     , A.POS_GRD_CD    -- 직급코드 [PHM_POS_GRD_CD]
     , dbo.F_FRM_CODE_NM( B.COMPANY_CD, B.LOCALE_CD, 'PHM_POS_GRD_CD', A.POS_GRD_CD, A.END_YMD, '1' ) AS POS_GRD_NM
     , A.DUTY_CD    -- 직책코드 [PHM_DUTY_CD]
     , dbo.F_FRM_CODE_NM( B.COMPANY_CD, B.LOCALE_CD, 'PHM_DUTY_CD', A.DUTY_CD, A.END_YMD, '1' ) AS DUTY_NM    -- 직책
     , A.POS_CD    -- 직위코드 [PHM_POS_CD]
     , dbo.F_FRM_CODE_NM( B.COMPANY_CD, B.LOCALE_CD, 'ORM_ORG_ACC_CD', A.POS_CD, A.END_YMD, '1' ) AS ORG_ACC_NM    -- 계정유형
     , A.ACC_CD    -- 코스트센터
     , dbo.XF_TO_CHAR_D( A.HIRE_YMD, 'YYYYMMDD' ) AS HIRE_YMD    -- 입사일자
     , dbo.XF_TO_CHAR_D( A.STA_YMD, 'YYYYMMDD' ) AS STA_YMD      -- 퇴직기산일
     , dbo.XF_TO_CHAR_D( A.END_YMD, 'YYYYMMDD' ) AS END_YMD      -- 퇴직종료일
     , dbo.XF_TO_CHAR_D( dbo.XF_NVL_D( A.STA_YMD, A.HIRE_YMD ), 'YYYYMMDD' ) AS HIRE_STA_YMD    -- 기산일/입사일
     , A.WORK_DAY    -- 실근속총일수
     , dbo.XF_CEIL( A.WORK_YY_PT, 1 ) AS WORK_YY_PT    -- 실근속년수(소수점)
     , A.ADD_WORK_YY    -- 추가근속년수
     , A.WORK_YY    -- 실근속년수
     , A.WORK_MM    -- 실근속월수
     , A.WORK_DD    -- 실근속일수
     , A.EST_RATE    -- 지급율
     , A.CNT_SALARY    -- 임금총액
     , A.PAY_AMT1    -- 월 급여 1
     , A.PAY_AMT2    -- 월 급여 2
     , A.PAY_AMT3    -- 월 급여 3
     , A.PAY_AMT4    -- 월 급여 4
     , A.PAY_AMT    -- 월급여합
     , A.BONUS_AMT1    -- 상여지급금액 1
     , A.BONUS_AMT2    -- 상여지급금액 2
     , A.BONUS_AMT3    -- 상여지급금액 3
     , A.BONUS_AMT4    -- 상여지급금액 4
     , A.BONUS_AMT5    -- 상여지급금액 5
     , A.BONUS_AMT6    -- 상여지급금액 6
     , A.BONUS_AMT7    -- 상여지급금액 7
     , A.BONUS_AMT8    -- 상여지급금액 8
     , A.BONUS_AMT9    -- 상여지급금액 9
     , A.BONUS_AMT10    -- 상여지급금액 10
     , A.BONUS_AMT11    -- 상여지급금액 11
     , A.BONUS_AMT12    -- 상여지급금액 12
     , A.BONUS_AMT    -- 상여합
     , A.BASE_PAY_AMT    -- 기준급여
     , A.DAY_AMT    -- 년월차보상금액
     , A.AVG_PAY    -- 평균급여
     , A.AVG_BONUS    -- 평균상여
     , A.AVG_DAY    -- 평균연월차
     , A.AVG_PAY_AMT    -- 평균임금
     , A.RETIRE_AMT    -- 퇴직추계액
     , A.RETIRE_MON_AMT    -- 퇴직충당금(전달 퇴직추계액과의 차이)
     , A.RETIRE_YEAR_AMT    -- 퇴직충당금(전년말 퇴직추계액과의 차이)
     , A.NOTE    -- 비고
  FROM REP_ESTIMATION A
     , ( SELECT ? AS COMPANY_CD
              , ? AS LOCALE_CD
           FROM DUAL ) B
 WHERE A.ESTIMATION_YM = ?
   AND ( ? IS NULL OR A.EMP_ID = ? )
   AND ( ? IS NULL OR A.EMP_KIND_CD = ? )
 ORDER BY dbo.F_FRM_CODE_NM( B.COMPANY_CD, B.LOCALE_CD, 'REP_EMP_KIND_CD', A.EMP_KIND_CD, dbo.XF_SYSDATE(0), 'O' )
        , dbo.F_FRM_CODE_NM( B.COMPANY_CD, B.LOCALE_CD, 'PHM_POS_GRD_CD', A.POS_GRD_CD, dbo.XF_SYSDATE(0), 'O' )
        , dbo.F_PHM_EMP_ORDER( B.COMPANY_CD, B.LOCALE_CD, A.EMP_ID, A.END_YMD, '1' )
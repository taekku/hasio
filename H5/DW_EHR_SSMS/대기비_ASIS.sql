select H_HUMAN.NO_PERSON, H_HUMAN.NM_PERSON, DT_RETIRE, TP_CALC_INS, DT_JOIN, DT_F_SHIP, DT_T_SHIP,
-- 고용형태 : 선원에 대한 급/호봉에 따른 기본급 으로 나머지는 급여마스타의 기본급으로 검색
        (CASE WHEN H_PAY_MASTER.TP_CALC_INS = 'S' AND H_HUMAN.CD_COMPANY = 'I' THEN
                 ISNULL(( SELECT TOP 1 H_PAY_LEVEL_V.AMT_ALLOW      
                          FROM H_PAY_LEVEL_V WITH (NOLOCK)
                               INNER JOIN  H_SHIP_BASE_RULE1  WITH (NOLOCK)
                                  ON H_PAY_LEVEL_V.CD_COMPANY = H_SHIP_BASE_RULE1.CD_COMPANY
                                 AND H_PAY_LEVEL_V.TP_SHIP    = H_SHIP_BASE_RULE1.TP_SHIP
                                 AND H_PAY_LEVEL_V.TP_SHIP_D  = H_SHIP_BASE_RULE1.TP_SHIP_D
                          WHERE H_PAY_LEVEL_V.CD_COMPANY = 'I'    -- 회사코드
                          AND H_PAY_LEVEL_V.CD_ALLOW = '001'      -- 기본급
                          AND H_PAY_LEVEL_V.DT_APPLY <= '20200930'     -- param에서넘어온 지급일자
                          AND H_PAY_LEVEL_V.LVL_PAY1 = H_HUMAN.LVL_PAY1
                          AND H_PAY_LEVEL_V.LVL_PAY2 = H_HUMAN.LVL_PAY2
                          AND H_PAY_LEVEL_V.CD_POSITION = H_HUMAN.CD_POSITION
                          AND H_SHIP_BASE_RULE1.CD_SHIP = H_HUMAN.CD_DEPT
                          ORDER BY H_PAY_LEVEL_V.DT_APPLY DESC), 0) 
        ELSE 0 END) AS AMT_BASE
  FROM  H_HUMAN INNER JOIN H_PAY_MASTER
                        ON H_HUMAN.CD_COMPANY = H_PAY_MASTER.CD_COMPANY
                       AND H_HUMAN.NO_PERSON = H_PAY_MASTER.NO_PERSON
 WHERE  ( ISNULL(H_HUMAN.DT_RETIRE, '') = '' OR H_HUMAN.DT_RETIRE = '00000000' ) -- 재직중인
   AND  ISNULL(H_HUMAN.DT_T_SHIP, '') = '' -- 하선하지않은
   --대기 시작일
   --입사일과 지급해당월 1일중 큰 날짜
   AND  (ISNULL(H_HUMAN.DT_F_SHIP, '') = '' OR ISNULL(H_HUMAN.DT_F_SHIP, '') >= '20200930') -- 승선일자가 지급일보다 큰
   AND  ISNULL(H_HUMAN.DT_JOIN, '') <= '20200930' -- 대기비 계산하는달 말일 이전 입사자만
   AND  H_HUMAN.CD_COMPANY = 'I'              --* 법인코드
   -- 부서
   AND  H_PAY_MASTER.TP_CALC_INS = 'S'       --* 고용유형(선원에 한하여)
   
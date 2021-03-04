SELECT CD, CD_NM
     , (SELECT PAY_GROUP_ID FROM PAY_GROUP WHERE COMPANY_CD=CODE.COMPANY_CD AND PAY_GROUP=CODE.CD) PAY_GROUP_ID
  FROM FRM_CODE CODE
 WHERE COMPANY_CD='I'
   AND CD_KIND='PAY_GROUP_CD'
   AND CD LIKE 'IB%'

DECLARE @company_cd nvarchar(10)
      , @pay_ymd date
select @company_cd = 'I'
     , @pay_ymd = '20200121'
SELECT NULL PAY_STANDBY_ID -- 대기비관리ID
     , @pay_ymd AS PAY_YMD -- 지급일자
	 , EMP_NO
	 , ORG_CD
	 , ORG_NM
	 , POS_CD
	 , HIRE_YMD
	 , SHIP_STA_YMD
	 , SHIP_END_YMD
	 , BASE_AMT
	 , STAN_F_YMD
	 , STAN_T_YMD
	 , DATEDIFF(day, STAN_F_YMD, STAN_T_YMD) + 1 STAN_CNT -- 대기일수
	 , PAY_RATE
	 , PAY_AMT
	 , NOTE
  FROM (SELECT EMP.EMP_ID -- 사원ID
		 , EMP.EMP_NO -- 사원번호
		 , EMP.EMP_NM -- 성명
		 , EMP.ORG_CD -- 부서
		 , dbo.F_FRM_ORM_ORG_NM( ORG_ID, LOCALE_CD, dbo.XF_SYSDATE(0), '11' ) AS ORG_NM
		 , EMP.POS_CD -- 직위
		 , EMP.HIRE_YMD -- 입사일자
		 , SHIP_STA_YMD -- 승선일자
		 , SHIP_END_YMD -- 하선일자
		 -- 고용형태 : 선원에 대한 급/호봉에 따른 기본급 으로 나머지는 급여마스타의 기본급으로 검색
		 , (SELECT TOP 1 PAY_AMT
			  FROM PAY_HOBONG H
			  INNER JOIN PAY_SHIP_RATE S
					  ON H.SHIP_CD = S.SHIP_CD -- 선반
					 AND H.SHIP_CD_D = S.SHIP_CD_D
					 AND H.COMPANY_CD = S.COMPANY_CD
					 AND @pay_ymd BETWEEN S.STA_YMD AND S.END_YMD
					 AND @pay_ymd BETWEEN H.STA_YMD AND H.END_YMD
			 WHERE H.COMPANY_CD = EMP.COMPANY_CD
			   AND S.ORG_ID = EMP.ORG_ID
			   AND H.STA_YMD <= @pay_ymd
			   AND H.PAY_POS_GRD_CD = EMP.POS_GRD_CD -- 직급
			   AND H.POS_CD = EMP.POS_CD -- 직위
			   AND H.PAY_GRADE = EMP.YEARNUM_CD
			 ORDER BY H.STA_YMD DESC) BASE_AMT -- 기준금액
		 -- 입사일과 지급해당월 1일중 큰 날짜
		 , CASE WHEN dbo.XF_TO_DATE(dbo.XF_TO_CHAR_D(@pay_ymd, 'yyyymm01'), 'yyyymmdd') > EMP.HIRE_YMD
				THEN dbo.XF_TO_DATE(dbo.XF_TO_CHAR_D(@pay_ymd, 'yyyymm01'), 'yyyymmdd')
				ELSE EMP.HIRE_YMD END AS STAN_F_YMD -- 대기시작일자
		 -- 승선발령이 있는경우 발령일 전일까지
		 -- 승선발령이 없는경우 지급해당월 말일까지
		 --, CASE WHEN SHIP_STA_YMD IS NOT NULL THEN SHIP_STA_YMD - 1
			--	ELSE dbo.XF_LAST_DAY(@pay_ymd) END AS STAN_T_YMD -- 대리종료일자
		 , CASE WHEN SHIP_STA_YMD IS NULL OR dbo.XF_TO_CHAR_D(SHIP_STA_YMD,'yyyymm') > dbo.XF_TO_CHAR_D(@pay_ymd, 'yyyymm')
					THEN dbo.XF_LAST_DAY(@pay_ymd)
				ELSE SHIP_STA_YMD - 1 END STAN_T_YMD -- 대기종료일자
		 --, DATEDIFF(day, STAN_F_YMD, STAN_E_YMD) STAN_CNT -- 대기일수
		 , CAST(100 AS NUMERIC(5,2)) PAY_RATE -- 지급율
		 , 0 PAY_AMT -- 지급금액
		 , NULL NOTE -- 비고
	  FROM VI_FRM_PHM_EMP EMP
	  INNER JOIN PAY_PHM_EMP PAY
			  ON EMP.EMP_ID = PAY.EMP_ID
			 AND EMP.COMPANY_CD = PAY.COMPANY_CD
			 AND EMP.COMPANY_CD = @company_cd
	  LEFT OUTER JOIN (SELECT EMP_ID, MAX(CAM_YMD) AS SHIP_STA_YMD
						 FROM CAM_HISTORY
						WHERE COMPANY_CD = @company_cd
						  AND TYPE_CD = '11' -- 선원승선
						GROUP BY EMP_ID
						) HIS_S
					ON EMP.EMP_ID = HIS_S.EMP_ID
	  LEFT OUTER JOIN (SELECT EMP_ID, MAX(CAM_YMD) AS SHIP_END_YMD
						 FROM CAM_HISTORY
						WHERE COMPANY_CD = @company_cd
						  AND TYPE_CD = '1A' -- 선원하선
						GROUP BY EMP_ID
						) HIS_E
					ON EMP.EMP_ID = HIS_E.EMP_ID
	 WHERE EMP.IN_OFFI_YN = 'Y' -- 재직중인
	   AND SHIP_END_YMD IS NULL -- 하선하지않은
		   -- 20100118 승선일자가 없거나 지급일자보다 크거나같은경우만 대상
	   AND (SHIP_STA_YMD IS NULL OR SHIP_STA_YMD >= @pay_ymd)
	   AND EMP.HIRE_YMD <= @pay_ymd -- 대기비 계산하는달 말일 이전 입사자만
	   AND EMP.COMPANY_CD = @company_cd --* 법인코드
	   AND PAY.EMP_CLS_CD = 'S' --* 고용유형(선원에 한하여)
	  -- AND (
	) M
-- FnB 통상임금
-- C100	과세대상금액
--------------------
-- C101	통상임금
-- C102	통상시급
-- C110	시급
-- C111	일급
-- C112	통상일급
------------------
INSERT INTO PAY_PAYROLL_DETAIL(
		PAY_PAYROLL_DETAIL_ID, -- 급여상세내역ID
		PAY_PAYROLL_ID, -- 급여내역ID
		BEL_PAY_TYPE_CD, -- 급여지급유형코드-귀속월[PAY_TYPE_CD]
		BEL_PAY_YM, -- 귀속월
		BEL_PAY_YMD_ID, -- 귀속급여일자ID
		SALARY_TYPE_CD, -- 급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
		PAY_ITEM_CD, -- 급여항목코드
		BASE_MON, -- 기준금액
		CAL_MON, -- 계산금액
		FOREIGN_BASE_MON, -- 외화기준금액
		FOREIGN_CAL_MON, -- 외화계산금액
		PAY_ITEM_TYPE_CD, -- 급여항목유형
		BEL_ORG_ID, -- 귀속부서ID
		NOTE, -- 비고
		MOD_USER_ID, -- 변경자
		MOD_DATE, -- 변경일시
		TZ_CD, -- 타임존코드
		TZ_DATE -- 타임존일시
)
SELECT 
		NEXT VALUE FOR S_PAY_SEQUENCE	PAY_PAYROLL_DETAIL_ID, -- 급여상세내역ID
		PAY_PAYROLL_ID, -- 급여내역ID
		A.PAY_TYPE_CD	BEL_PAY_TYPE_CD, -- 급여지급유형코드-귀속월[PAY_TYPE_CD]
		A.PAY_YM	BEL_PAY_YM, -- 귀속월
		A.PAY_YMD_ID	BEL_PAY_YMD_ID, -- 귀속급여일자ID
		A.SALARY_TYPE_CD, -- 급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
		A.ITEM_CD	PAY_ITEM_CD, -- 급여항목코드
		A.AMT	BASE_MON, -- 기준금액
		A.AMT	CAL_MON, -- 계산금액
		0 FOREIGN_BASE_MON, -- 외화기준금액
		0 FOREIGN_CAL_MON, -- 외화계산금액
		'DEDUCT_P'	PAY_ITEM_TYPE_CD, -- 급여항목유형( 공제과정 )
		A.ORG_ID	BEL_ORG_ID, -- 귀속부서ID
		'과세대상생성'	NOTE, -- 비고
		0	MOD_USER_ID, -- 변경자
		GETDATE()	MOD_DATE, -- 변경일시
		'KST'	TZ_CD, -- 타임존코드
		SYSDATETIME()	TZ_DATE -- 타임존일시
  FROM (
		SELECT YMD.PAY_YM, YMD.PAY_YMD_ID, YMD.PAY_TYPE_CD
		     , PAY.PAY_PAYROLL_ID, PAY.SALARY_TYPE_CD
			 , PAY.EMP_ID, PAY.ORG_ID
			 , (SELECT EMP_NO FROM PHM_EMP WHERE COMPANY_CD='F' AND EMP_ID=PAY.EMP_ID) AS EMP_NO
			 , COM.ITEM_CD, COM.AMT
		  FROM PAY_PAY_YMD YMD
		  JOIN FRM_CODE T
			ON YMD.COMPANY_CD = T.COMPANY_CD AND YMD.PAY_TYPE_CD = T.CD AND T.CD_KIND = 'PAY_TYPE_CD'
		   AND T.SYS_CD = '002' AND YMD.COMPANY_CD='F' -- 제수당
		  JOIN PAY_PAYROLL PAY ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
		  JOIN (SELECT PAY_PAYROLL_ID
					 , 'C100' AS ITEM_CD -- 과세대상금액
					 , SUM(CAL_MON) AMT
				  FROM PAY_PAYROLL_DETAIL A
				 WHERE PAY_ITEM_CD LIKE 'P%'
				 GROUP BY PAY_PAYROLL_ID) COM
			ON PAY.PAY_PAYROLL_ID = COM.PAY_PAYROLL_ID
		 WHERE YMD.COMPANY_CD='F'
		   AND YMD.PAY_YM BETWEEN '202101' AND '202105'
			AND NOT EXISTS (SELECT 1 FROM PAY_PAYROLL_DETAIL K
									WHERE K.PAY_PAYROLL_ID=PAY.PAY_PAYROLL_ID
									  AND K.BEL_ORG_ID = PAY.ORG_ID
									  AND K.BEL_PAY_TYPE_CD = YMD.PAY_TYPE_CD
									  AND K.BEL_PAY_YMD_ID = YMD.PAY_YMD_ID
									  AND K.SALARY_TYPE_CD = PAY.SALARY_TYPE_CD
									  AND K.PAY_ITEM_CD = COM.ITEM_CD
									)
		   AND AMT <> 0
	) A
--   ORDER BY YMD.PAY_YM
--ORDER BY PAY_PAYROLL_ID

--SELECT COUNT(*)
--FROM PAY_PAY_YMD YMD
--		  JOIN FRM_CODE T
--			ON YMD.COMPANY_CD = T.COMPANY_CD AND YMD.PAY_TYPE_CD = T.CD AND T.CD_KIND = 'PAY_TYPE_CD'
--		   AND T.SYS_CD = '002' AND YMD.COMPANY_CD='F' -- 제수당
--JOIN PAY_PAYROLL PAY
--ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
--JOIN PAY_PAYROLL_DETAIL DTL
--ON PAY.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID
--WHERE YMD.COMPANY_CD='F'
--AND DTL.PAY_ITEM_CD='C100'
--AND YMD.PAY_YM >= '202101'

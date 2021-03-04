USE dwehrdev
GO
DECLARE @P_COMPANY VARCHAR(10) = 'Y'
      , @P_HRTYPE_GBN VARCHAR(10) = 'H8306'
	  , @V_PAY_CD VARCHAR(10) = '03' -- 01:월급여,02:상여,03:사무직급여,04:급여소급,05:PI수당,06:제수당
	  , @V_PAY_CD1 VARCHAR(10) = '04'
	  ,@P_PROC_DATE VARCHAR(8) = '20200325'

DECLARE @av_company_cd nvarchar(10) = 'Y'
DECLARE @av_hrtype_gbn nvarchar(10) = 'H8306'
DECLARE @av_tax_kind_cd nvarchar(10) = 'A1' -- (급여 : A1, 상여 : B1, 연말정산 : E1, 퇴직정산 : C1 ,중도정산 : D1)
DECLARE @av_close_ym nvarchar(10) = '202101'
DECLARE @ad_proc_date date = '20200325'
DECLARE @av_emp_id nvarchar(10) = 67791
DECLARE @av_locale_cd nvarchar(10) = 'KO'
DECLARE @av_tz_cd nvarchar(10) = 'KST'
DECLARE @an_mod_user_id numeric(18,0) = 6643645
DECLARE @av_ret_code nvarchar(100)
DECLARE @av_ret_message nvarchar(500)

			SELECT A.WORK_SITE_CD                                               --근무지 
				  ,ISNULL(MAPCOSTDPT_CD,'XXXXX')  MAPCOSTDPT_CD                -- 원가부서
				  ,CD_COST
				  ,COUNT(DISTINCT(A.SABUN)) AS SABUN_CNT                       -- 총인원
				  ,SUM(A.ALOWTOT_AMT) AS AOLWTOT_AMT                           -- 급여총액
				  ,SUM(A.TAXFREEALOW_TOTAMT) AS TAXFREEALOW                    -- 비과세
				  ,SUM(A.INCTAX_AMT) AS INCTAX                                 -- 소득세
				  ,SUM(A.INHTAX_AMT) AS INGTAX 
			  FROM (SELECT A.CD_WORK_AREA AS WORK_SITE_CD              -- 근무지코드 필드 신설 및 수정(2019/03/15)
						  ,CASE D.BIZ_ACCT WHEN '00689' THEN '00177'   --선사영업팀장
										   ELSE  D.BIZ_ACCT     --END    
							END AS MAPCOSTDPT_CD 
						  ,A.CD_COST 
						  ,A.LVL_PAY1                                       -- 원가부서
						  ,A.NO_PERSON SABUN                                -- 총인원
						  ,A.AMT_SUPPLY_TOTAL ALOWTOT_AMT                   -- 급여총액
						  ,A.AMT_TAX_EXEMPTION1 + A.AMT_TAX_EXEMPTION2 + A.AMT_TAX_EXEMPTION3 + A.AMT_TAX_EXEMPTION4 + 
						   A.AMT_TAX_EXEMPTION5 + A.AMT_TAX_EXEMPTION6 + A.AMT_TAX_EXEMPTION7 + A.AMT_TAX_EXEMPTION8 TAXFREEALOW_TOTAMT -- 비과세
						  ,B.AMT_DEDUCT INCTAX_AMT                                     -- 소득세
						  ,C.AMT_DEDUCT INHTAX_AMT                                     -- 주민세         
					 FROM H_MONTH_PAY_BONUS A 
						  INNER JOIN H_HUMAN H ON A.CD_COMPANY = H.CD_COMPANY AND A.NO_PERSON = H.NO_PERSON
						  LEFT OUTER JOIN H_MONTH_DEDUCT B ON A.CD_COMPANY = B.CD_COMPANY AND A.NO_PERSON = B.NO_PERSON AND A.YM_PAY = B.YM_PAY AND A.FG_SUPP = B.FG_SUPP AND B.CD_DEDUCT = 'INC' AND A.DT_PROV = B.DT_PROV
						  LEFT OUTER JOIN H_MONTH_DEDUCT C ON A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON AND A.YM_PAY = C.YM_PAY AND A.FG_SUPP = C.FG_SUPP AND C.CD_DEDUCT = 'LOC' AND A.DT_PROV = C.DT_PROV
						  LEFT OUTER JOIN B_COST_CENTER D ON A.CD_COMPANY = D.CD_COMPANY AND A.CD_COST = D.CD_CC                                                               
					WHERE A.CD_COMPANY = @P_COMPANY
					  AND H.HRTYPE_GBN = @P_HRTYPE_GBN    -- 인력유형 
					  AND (A.FG_SUPP  = @V_PAY_CD OR A.FG_SUPP  = @V_PAY_CD1)
					  AND (
							-- 동부익스프레스 재경팀 송윤호 과장 요청 8/20
							-- 25일 급여 -> 25, 26일 급여
							-- 10일 급여 -> 10, 11, 15, 16, 20, 21 급여
					       (A.DT_PROV IN (@P_PROC_DATE, LEFT(@P_PROC_DATE, 6) + '11', LEFT(@P_PROC_DATE, 6) + '15', LEFT(@P_PROC_DATE, 6) + '16', LEFT(@P_PROC_DATE, 6) + '20', LEFT(@P_PROC_DATE, 6) + '21') AND 1 = CASE WHEN RIGHT(@P_PROC_DATE, 2) = '10' THEN 1 ELSE 0 END) OR 
					       (A.DT_PROV IN (@P_PROC_DATE, LEFT(@P_PROC_DATE, 6) + '26') AND 1 = CASE WHEN RIGHT(@P_PROC_DATE, 2) = '25' THEN 1 ELSE 0 END)
						  )
					) A
			 GROUP BY A.WORK_SITE_CD                                          --근무지 
					 ,MAPCOSTDPT_CD                                           -- 원가부서
					 ,CD_COST
			 ORDER BY-- WORK_SITE_CD                                            --근무지 
					 /*,*/MAPCOSTDPT_CD, CD_COST
					 ;                                          -- 원가부서  


					 
USE dwehrdev_H5
GO
DECLARE @av_company_cd varchar(10) = 'Y'
      , @av_locale_cd varchar(10) = 'KO'
      , @v_yyyymm varchar(10)='202003'
	  , @v_hrtype_cd varchar(10) = 'H8306'
	  , @av_tax_kind_cd varchar(10) = 'A1'
SELECT PAY_BIZ_CD, MAPCOSTDPT_CD, COST_CD, COUNT( EMP_ID) SABUN_CNT, SUM(PSUM) AS AOLWTOT_AMT, SUM(C001_AMT) TAXFREEALOW, SUM(D001_AMT) AS INCTAX, SUM(D002_AMT) AS INGTAX
FROM(
SELECT PAY.PAY_BIZ_CD
     , PRI.FROM_TYPE_CD 
	 , PAY.ACC_CD COST_CD
	 , PAY.EMP_ID
	 --, dbo.F_ORM_ORG_COST(YMD.COMPANY_CD, PAY.EMP_ID, YMD.PAY_YMD, '1') AS COST_CD
	 , PAY.PSUM, PAY.DSUM
	 , (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD=YMD.COMPANY_CD AND COST_CD = PAY.ACC_CD AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD ) AS MAPCOSTDPT_CD
     , D001_AMT -- 갑근세
	 , D002_AMT -- 주민세
	 , C001_AMT -- 비과세
  FROM PAY_PAY_YMD YMD
  JOIN PAY_PAYROLL PAY
    ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
  JOIN PHM_PRIVATE PRI
    ON PAY.EMP_ID = PRI.EMP_ID
   AND YMD.PAY_YMD BETWEEN PRI.STA_YMD AND PRI.END_YMD
  JOIN ORM_COST COST
    ON PAY.ACC_CD = COST.COST_CD
   AND YMD.COMPANY_CD = COST.COMPANY_CD
   AND YMD.PAY_YMD BETWEEN COST.STA_YMD AND COST.END_YMD
  LEFT OUTER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) D001_AMT FROM PAY_PAYROLL_DETAIL DTL WHERE DTL.PAY_ITEM_CD='D001' GROUP BY PAY_PAYROLL_ID) DTL_D
    ON PAY.PAY_PAYROLL_ID = DTL_D.PAY_PAYROLL_ID
  LEFT OUTER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) D002_AMT FROM PAY_PAYROLL_DETAIL DTL WHERE DTL.PAY_ITEM_CD='D002' GROUP BY PAY_PAYROLL_ID) DTL_D2
    ON PAY.PAY_PAYROLL_ID = DTL_D2.PAY_PAYROLL_ID
					-- C001	식대비과세	AMT_TAX_EXEMPTION2	비과세금액(식대)
					-- C002	생산비과세	AMT_TAX_EXEMPTION1	비과세금액(연장)
					-- C003	교통비비과세	AMT_TAX_EXEMPTION3	비과세금액(기타)
					-- C004	국외근로비과세	AMT_TAX_EXEMPTION4	비과세금액(국외근로)
  LEFT OUTER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) C001_AMT FROM PAY_PAYROLL_DETAIL DTL WHERE DTL.PAY_ITEM_CD IN('C001','C002','C003','C004') GROUP BY PAY_PAYROLL_ID) DTL_D3
    ON PAY.PAY_PAYROLL_ID = DTL_D3.PAY_PAYROLL_ID
 WHERE YMD.COMPANY_CD = @av_company_cd
   AND YMD.PAY_YM = @v_yyyymm
   AND PRI.FROM_TYPE_CD = @v_hrtype_cd
   AND YMD.PAY_TYPE_CD IN (
							SELECT CD
							  FROM FRM_CODE
							 WHERE COMPANY_CD=@av_company_cd
							   AND CD_KIND = 'PAY_TYPE_CD'
							   AND SYS_CD IN (
									SELECT HIS.KEY_CD1 AS CD
									  FROM FRM_UNIT_STD_HIS HIS
											   , FRM_UNIT_STD_MGR MGR
									 WHERE HIS.FRM_UNIT_STD_MGR_ID = MGR.FRM_UNIT_STD_MGR_ID
									   AND MGR.UNIT_CD = 'TBS'
									   AND MGR.STD_KIND = 'TBS_DEBIS_PAY'
										  AND MGR.COMPANY_CD = @av_company_cd
									   AND MGR.LOCALE_CD = @av_locale_cd
									   AND HIS.CD1=@av_tax_kind_cd
									   AND dbo.XF_SYSDATE(0) BETWEEN HIS.STA_YMD AND HIS.END_YMD
									   )
							   )
) A
GROUP BY PAY_BIZ_CD, MAPCOSTDPT_CD, COST_CD
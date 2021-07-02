DECLARE @company_cd nvarchar(10) = 'H'
DECLARE @emp_id numeric(38)
DECLARE @appl_id numeric(38)=0
DECLARE @sch_grd_cd nvarchar(10) = '10'
DECLARE @fam_nm nvarchar(10) = '이하연'
DECLARE @group_ymd date = '19980801'
DECLARE @hire_ymd date = '19980801'
DECLARE @appl_year nvarchar(10) = '2021'
DECLARE @edu_pos nvarchar(10) = '1'
DECLARE @sce_edu_term nvarchar(10) = '1'

select @emp_id = EMP_ID
from VI_FRM_PHM_EMP
where COMPANY_CD='H'
--and EMP_NO='20160576'
and EMP_NM='이윤철'
and LOCALE_CD='KO'

SELECT TOT_APPL_CNT		--총지급횟수
      ,TOT_APPL_AMT
	  ,TOT_CONFIRM_AMT
	  ,YEAR_APPL_AMT	--연간기신청금액
	  ,TERM_APPL_AMT	--학기신청금액
	  ,CONG_EXIST_YN	--입학축하금 기수령여부
	  ,ALLOW_POINT		--인정학점기준
 	  ,(SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	      FROM SEC_EDU
	     WHERE COMPANY_CD = @company_cd
	       AND EMP_ID = @emp_id
	       AND SCH_GRD_CD = @sch_grd_cd
	       --AND dbo.F_FRM_DECRYPT_C(FAM_CTZ_NO) = fam_ctz_no 
	       AND dbo.XF_TRIM(FAM_NM) = @fam_nm
	       AND PAY_YN = 'Y' 
	       AND ISNULL(RETURN_YN,'N') <> 'Y'
	       AND ISNULL(POINT,0) < T2.ALLOW_POINT  --3
	       --AND (EDU_POS <> '1' AND SCE_EDU_TERM <> '1') --1학년1학기 직전성적없음
	       AND EDU_POS + SCE_EDU_TERM <> '11' --1학년1학기 직전성적없음
	   ) AS ALLOW_POINT_SKIP_YN --인정학점기준미만 신청건여부(1회이상있으면(Y) 인정학점기준체크하고 없으면 1회에 한하여 신청가능)
	  ,ISNULL(SCH_LIMIT_CNT,99999) as SCH_LIMIT_CNT	--수혜인원기준
	  ,SCH_TOT_CNT		--기수혜인원
	  ,CASE WHEN SCH_TOT_CNT >= ISNULL(SCH_LIMIT_CNT,99999) THEN 'N' ELSE 'Y' END AS SCH_LIMIT_YN --수혜인원기준 초과여부(Y->신청가능)
	  ,ISNULL(ALLOW_PERIOD,99999) as ALLOW_PERIOD		--인정학기기준
	  ,ALLOW_TOT_PERIOD --학교구분별 수혜자녀 기신청학기
	  ,CASE WHEN ALLOW_TOT_PERIOD >= ISNULL(ALLOW_PERIOD,99999) THEN 'N' ELSE 'Y' END AS ALLOW_PERIOD_LIMIT_YN --인정학기기준 초과여부(Y->신청가능)
	  ,WORK_YEAR		--근속년수기준
	  ,WORK_STD_MD		--근속기준월일
	  ,DATEDIFF(YEAR,@group_ymd,ISNULL(WORK_STD_MD,GETDATE())) + 1 AS WORK_YY --근속년수
	  ,CASE WHEN DATEDIFF(YEAR,@group_ymd,ISNULL(WORK_STD_MD,GETDATE())) + 1 >= WORK_YEAR THEN 'Y' ELSE 'N' END AS WORK_YY_YN --근속년수 충족여부(Y->신청가능)
	  ,HIRE_STD_YMD		--입사적용기준일
	  ,CASE WHEN HIRE_STD_YMD IS NULL THEN 'Y' ELSE CASE WHEN @hire_ymd > HIRE_STD_YMD THEN 'N' ELSE 'Y' END END AS HIRE_STD_YN --입사적용기준일 기준 신청가능여부(Y->신청가능)
	  ,(SELECT CASE WHEN COUNT(RET_VAL) > 0 THEN 'Y' ELSE 'N' END
		  FROM (
				SELECT dbo.F_SEC_GROUP_CHK(SEC_APPL_CD_STD_ID, @emp_id, GETDATE()) as RET_VAL
				  FROM SEC_APPL_CD_STD 
				 WHERE COMPANY_CD = @company_cd
				   AND SCH_GRD_CD = @sch_grd_cd
		   	   ) A
		 WHERE RET_VAL <> 0) AS SEC_GROUP_CHK_YN --적용대상 기준 (Y->신청가능)
  FROM (
		SELECT TOT_APPL_CNT
				,TOT_APPL_AMT
				,TOT_CONFIRM_AMT
				,YEAR_APPL_AMT		--연간기신청금액
				,TERM_APPL_AMT		--학기신청금액
				,(SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
					FROM SEC_EDU_DET A
						INNER JOIN SEC_STD_ITEM B ON A.ITEM_CD = B.ITEM_CD
					WHERE A.SEC_EDU_ID IN (SELECT A.SEC_EDU_ID
											FROM SEC_EDU A 
											     INNER JOIN SEC_EDU_APPL B 
											     ON A.SEC_EDU_APPL_ID = B.SEC_EDU_APPL_ID
											WHERE A.COMPANY_CD = @company_cd
											AND A.EMP_ID = @emp_id
											--AND dbo.F_FRM_DECRYPT_C(A.FAM_CTZ_NO) = fam_ctz_no
	       									AND dbo.XF_TRIM(A.FAM_NM) = @fam_nm
											AND A.SCH_GRD_CD = @sch_grd_cd
											--AND B.STAT_CD = '132'
											AND A.PAY_YN = 'Y' 
											AND ISNULL(A.RETURN_YN,'N') <> 'Y'
										) 
					AND B.CONG_YN = 'Y'
				) AS CONG_EXIST_YN	--입학축하금 기수령여부
				,(SELECT ISNULL(ALLOW_POINT,0) FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS ALLOW_POINT		--인정학점기준
				,(SELECT SCH_LIMIT_CNT FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS SCH_LIMIT_CNT		--수혜인원기준
				
				--,(SELECT COUNT(*) FROM (SELECT A.FAM_CTZ_NO FROM SEC_EDU A INNER JOIN SEC_EDU_APPL B ON A.SEC_EDU_APPL_ID = B.SEC_EDU_APPL_ID WHERE A.COMPANY_CD = company_cd AND A.EMP_ID = emp_id AND A.SCH_GRD_CD = sch_grd_cd AND dbo.F_FRM_DECRYPT_C(A.FAM_CTZ_NO) <> fam_ctz_no  AND B.STAT_CD = '132' GROUP BY A.FAM_CTZ_NO) D) AS SCH_TOT_CNT   -- 기수혜인원
				,(SELECT COUNT(*) FROM (SELECT FAM_CTZ_NO FROM SEC_EDU WHERE COMPANY_CD = @company_cd AND EMP_ID = @emp_id AND SCH_GRD_CD = @sch_grd_cd AND dbo.XF_TRIM(FAM_NM) <> @fam_nm  AND PAY_YN = 'Y' AND ISNULL(RETURN_YN,'N') <> 'Y' GROUP BY FAM_CTZ_NO) D) AS SCH_TOT_CNT   -- 기수혜인원
				
				,(SELECT ALLOW_PERIOD FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS ALLOW_PERIOD		--인정학기기준
				
				--,(SELECT COUNT(*) FROM (SELECT DISTINCT A.SCH_GRD_CD, A.APPL_YEAR, A.SCE_EDU_TERM FROM SEC_EDU A INNER JOIN SEC_EDU_APPL B ON A.SEC_EDU_APPL_ID = B.SEC_EDU_APPL_ID WHERE A.COMPANY_CD = company_cd AND A.EMP_ID = emp_id AND A.SCH_GRD_CD = sch_grd_cd AND dbo.F_FRM_DECRYPT_C(A.FAM_CTZ_NO) = fam_ctz_no  AND B.STAT_CD = '132') A) AS ALLOW_TOT_PERIOD   -- 기신청학기(학교구분,년도,학기 기준으로 분할신청건은 한건으로 본다)
				,(SELECT COUNT(*) FROM (SELECT DISTINCT SCH_GRD_CD, APPL_YEAR, SCE_EDU_TERM FROM  SEC_EDU WHERE COMPANY_CD = @company_cd AND EMP_ID = @emp_id AND SCH_GRD_CD = @sch_grd_cd AND dbo.XF_TRIM(FAM_NM) = @fam_nm  AND PAY_YN = 'Y' AND ISNULL(RETURN_YN,'N') <> 'Y') A) AS ALLOW_TOT_PERIOD   -- 기신청학기(학교구분,년도,학기 기준으로 분할신청건은 한건으로 본다)
				
				,(SELECT ISNULL(WORK_YEAR,0) FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS WORK_YEAR		--근속년수기준
				,(SELECT dbo.XF_TO_DATE(dbo.XF_TO_CHAR_N(datepart(year,GETDATE()),null) + WORK_STD_MD,'YYYYMMDD') FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS WORK_STD_MD		--근속기준월일
				,(SELECT HIRE_STD_YMD FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS HIRE_STD_YMD		--입사적용기준일
			FROM (
				SELECT ISNULL(SUM(CASE WHEN B.APPL_ID != @appl_id AND (A.PAY_YN = 'Y' OR B.STAT_CD NOT IN ('131','132','133')) AND ISNULL(A.RETURN_YN,'N') <> 'Y' THEN 1 ELSE 0 END),0) AS TOT_APPL_CNT
						,ISNULL(SUM(CASE WHEN B.APPL_ID != @appl_id AND (A.PAY_YN = 'Y' OR B.STAT_CD NOT IN ('131','132','133')) AND ISNULL(A.RETURN_YN,'N') <> 'Y' THEN A.APPL_AMT ELSE 0 END),0) AS TOT_APPL_AMT
						,ISNULL(SUM(CASE WHEN B.APPL_ID != @appl_id AND A.PAY_YN = 'Y' AND ISNULL(A.RETURN_YN,'N') <> 'Y' THEN A.CONFIRM_AMT ELSE 0 END),0) AS TOT_CONFIRM_AMT
						,ISNULL(SUM(CASE WHEN B.APPL_ID != @appl_id AND (A.PAY_YN = 'Y' OR B.STAT_CD NOT IN ('131','132','133')) AND ISNULL(A.RETURN_YN,'N') <> 'Y' AND A.APPL_YEAR = @appl_year THEN APPL_AMT ELSE 0 END),0) AS YEAR_APPL_AMT	--연간신청금액
						,ISNULL(SUM(CASE WHEN B.APPL_ID != @appl_id AND (A.PAY_YN = 'Y' OR B.STAT_CD NOT IN ('131','132','133')) AND ISNULL(A.RETURN_YN,'N') <> 'Y' AND A.APPL_YEAR = @appl_year AND A.EDU_POS = @edu_pos AND A.SCE_EDU_TERM=@sce_edu_term THEN APPL_AMT ELSE 0 END),0) AS TERM_APPL_AMT	--학기신청금액
					FROM SEC_EDU A 
					     INNER JOIN SEC_EDU_APPL B 
					     ON A.SEC_EDU_APPL_ID = B.SEC_EDU_APPL_ID
					WHERE A.COMPANY_CD = @company_cd
					AND A.EMP_ID = @emp_id
					--AND dbo.F_FRM_DECRYPT_C(A.FAM_CTZ_NO) = fam_ctz_no
					AND dbo.XF_TRIM(A.FAM_NM) = @fam_nm
					AND A.SCH_GRD_CD = @sch_grd_cd
				) T1
		) T2
DECLARE @an_pay_ymd_id numeric(38) = 35427483 --27946605-- 35427483-- 28639403 --27178855
	  , @av_company_cd nvarchar(10) = 'T'
	  , @d_std_ymd date
	  , @an_mod_user_id numeric(38) = 0
	  , @av_locale_cd nvarchar(10) = 'KO'
	  , @v_pay_ym nvarchar(10)
	  , @v_pay_type_sys_cd nvarchar(10)
	  , @v_pay_type_cd nvarchar(10)
	  , @an_emp_id numeric(38)
	  , @an_org_id numeric(38)
	  , @d_pay_ymd date

	  , @n_pay_group_id numeric(38)
	  , @v_pay_group_cd nvarchar(10)
	  
		SELECT @v_pay_type_cd	= A.PAY_TYPE_CD,
			   @v_pay_ym		= A.PAY_YM,
			   --@v_pre_pay_ym	= DBO.XF_SUBSTR(CONVERT(NVARCHAR,DBO.XF_DATEADD(DBO.XF_TO_DATE(A.PAY_YM+'01','yyyymmdd'),-1),112),1,6),
			   @d_pay_ymd		= A.PAY_YMD,
			   @d_std_ymd		= A.STD_YMD,
			   --@d_sta_ymd		= A.STA_YMD,         
			   --@d_end_ymd		= A.END_YMD,
			   @v_pay_type_sys_cd = B.SYS_CD,
			   @n_pay_group_id	= C.PAY_GROUP_ID,
			   @v_pay_group_cd  = D.PAY_GROUP
		FROM dbo.PAY_PAY_YMD A, FRM_CODE B, PAY_GROUP_TYPE C, PAY_GROUP D
		WHERE A.PAY_YMD_ID  = @an_pay_ymd_id
		AND B.LOCALE_CD  	= @av_locale_cd
		AND B.COMPANY_CD 	= @av_company_cd
		AND B.CD_KIND 		= 'PAY_TYPE_CD'
		AND B.CD 			= A.PAY_TYPE_CD					 
		AND A.STD_YMD BETWEEN B.STA_YMD AND B.END_YMD
		AND C.COMPANY_CD	= @av_company_cd
		AND C.PAY_TYPE_CD   = A.PAY_TYPE_CD
		AND A.STD_YMD BETWEEN C.STA_YMD AND C.END_YMD
		AND D.PAY_GROUP_ID  = C.PAY_GROUP_ID
		SELECT A.PAY_TYPE_CD,
			   A.PAY_YM,
			   DBO.XF_SUBSTR(CONVERT(NVARCHAR,DBO.XF_DATEADD(DBO.XF_TO_DATE(A.PAY_YM+'01','yyyymmdd'),-1),112),1,6),
			   A.PAY_YMD,
			   A.STD_YMD,
			   A.STA_YMD,         
			   A.END_YMD,
			   B.SYS_CD,
			   C.PAY_GROUP_ID,
			   D.PAY_GROUP
		FROM dbo.PAY_PAY_YMD A, FRM_CODE B, PAY_GROUP_TYPE C, PAY_GROUP D
		WHERE A.PAY_YMD_ID  = @an_pay_ymd_id
		AND B.LOCALE_CD  	= @av_locale_cd
		AND B.COMPANY_CD 	= @av_company_cd
		AND B.CD_KIND 		= 'PAY_TYPE_CD'
		AND B.CD 			= A.PAY_TYPE_CD					 
		AND A.STD_YMD BETWEEN B.STA_YMD AND B.END_YMD
		AND C.COMPANY_CD	= @av_company_cd
		AND C.PAY_TYPE_CD   = A.PAY_TYPE_CD
		AND A.STD_YMD BETWEEN C.STA_YMD AND C.END_YMD
		AND D.PAY_GROUP_ID  = C.PAY_GROUP_ID

select @an_pay_ymd_id    an_pay_ymd_id
	  , @av_company_cd   av_company_cd
	  , @d_std_ymd		 d_std_ymd
	  , @an_mod_user_id	 an_mod_user_id
	  , @av_locale_cd	 av_locale_cd
	  , @v_pay_ym		 v_pay_ym
	  , @v_pay_type_cd	 v_pay_type_cd
	  , @an_emp_id		 an_emp_id
	  , @an_org_id		 an_org_id
	  , @n_pay_group_id	 n_pay_group_id
	  , @v_pay_group_cd	 v_pay_group_cd
	  , @v_pay_type_sys_cd v_pay_type_sys_cd

SELECT *
                  								 FROM PAY_EXP_UPLOAD Z
                  								 WHERE Z.COMPANY_CD = @av_company_cd
                  								 --AND Z.EMP_ID = A.EMP_ID
                  								 AND Z.PAY_EXP_CD = '301'  --급여제외자 제외
SELECT 
--             				NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    						T1.*
						 FROM (
								 SELECT @an_pay_ymd_id 		AS PAY_YMD_ID, 		--	급여일자ID
								 --dbo.F_PAY_GROUP_CHK(@n_pay_group_id, A.EMP_ID, @d_pay_ymd) as PAY_GROUP_ID,
										A.EMP_ID  			AS EMP_ID,			--	사원ID
										C.SALARY_TYPE_CD 	AS SALARY_TYPE_CD,	--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
										C.PAY_BAS_TYPE_CD	AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]	
										--C.BP12				AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]
										'' 					AS SUB_COMPANY_CD,	--	서브회사코드
										@v_pay_group_cd		AS PAY_GROUP_CD,	--	급여그룹
									    --	DBO.F_ORM_ORG_BIZ(A.ORG_ID,@d_std_ymd,'PAY') AS PAY_BIZ_CD,					--	급여사업장코드										
										--DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,A.ORG_ID,@d_std_ymd) 	AS RES_BIZ_CD,	--	지방세사업장코드
										DBO.F_ORM_ORG_BIZ(dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd,'PAY') AS PAY_BIZ_CD,	--	급여사업장코드
										DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd) AS RES_BIZ_CD,	--	지방세사업장코드
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') 		AS ORG_ID,		--	발령부서ID
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') 		AS PAY_ORG_ID,	--	급여부서ID
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'POS_CD') 		AS POS_CD,		--	직위코드[PHM_POS_CD]
										--A.ORG_ID 			AS ORG_ID,			--	발령부서ID
										--A.ORG_ID 			AS PAY_ORG_ID,		--	급여부서ID
										--A.POS_CD			AS POS_CD,			--	직위코드[PHM_POS_CD]
										A.MGR_TYPE_CD		AS MGR_TYPE_CD,		--  관리구분[PHM_MR_TYPE_CD]
										A.JOB_POSITION_CD	AS JOB_POSITION_CD,	--	직종코드
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'DUTY_CD') AS DUTY_CD,       --  직책코드[PHM_DUTY_CD]
						                --A.DUTY_CD           AS DUTY_CD,         --  직책코드[PHM_DUTY_CD]
										DBO.F_ORM_ORG_COST(A.COMPANY_CD,A.EMP_ID,@d_std_ymd,'1') AS ACC_CD,			--	코스트센터(ORM_COST_ORG_CD)
										0 					AS PSUM,			--	지급집계(모든기지급포함)
										0 					AS PSUM1,			--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
										0 					AS PSUM2,			--	지급집계(모든기지급포함안함)
										0 					AS DSUM,			--	공제집계
										0 					AS TSUM,			--	세금집계
										0 					AS REAL_AMT,		--	실지급액
										Z.BANK_CD 			AS BANK_CD,			--	은행코드[PAY_BANK_CD]
										Z.ACCOUNT_NO 		AS ACCOUNT_NO,		--	계좌번호
										'' 					AS FILLDT,			--	기표일
										--A.POS_GRD_CD 		AS POS_GRD_CD,		--	직급[PHM_POS_GRD_CD]
										--A.YEARNUM_CD		AS PAY_GRADE,		-- 	호봉코드 [PHM_YEARNUM_CD]
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'POS_GRD_CD') AS POS_GRD_CD,		--	직급[PHM_POS_GRD_CD]
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'YEARNUM_CD') AS PAY_GRADE,		-- 	호봉코드 [PHM_YEARNUM_CD]
										'' 					AS DTM_TYPE,		--	근태유형
										0 					AS FILLNO,			--	전표번호
										'' 					AS NOTICE,			--	급여명세공지
										'' 					AS TAX_YMD,			--	원천징수신고일자
										0 					AS FOREIGN_PSUM,	--	외화지급집계(모든기지급포함)
										0 					AS FOREIGN_PSUM1,	--	외화지급집계(PSUM에서 급여성기지급 포함 안함)
										0 					AS FOREIGN_PSUM2,	--	외화지급집계(모든기지급포함안함)
										0 					AS FOREIGN_DSUM,	--	외화공제집계
										0 					AS FOREIGN_TSUM,	--	외화세금집계
										0 					AS FOREIGN_REAL_AMT,--	외화실지급액
										'KRW' 				AS CURRENCY_CD,		--	통화코드[PAY_CURRENCY_CD] --필수
										'' 					AS TAX_SUBSIDY_YN,	--	세금보조여부
										B.TAX_FAMILY_CNT 	AS TAX_FAMILY_CNT,	--	부양가족수
										B.FAM20_CNT 		AS FAM20_CNT,		--	20세이하자녀수
										B.FOREIGN_YN 		AS FOREIGN_YN,		--	외국인여부
										CASE WHEN ISNULL(B.PEAK_YMD,'19000101') ='19000101' THEN 'N' ELSE 'Y' END AS PEAK_YN	,--임금피크대상여부
										B.PEAK_YMD 			AS PEAK_DATE,		--	임금피크적용일자
										B.PAY_METH_CD 		AS PAY_METH_CD,		--	급여지급방식코드[PAY_METH_CD]
										B.EMP_CLS_CD 		AS PAY_EMP_CLS_CD,	--	고용유형코드[PAY_EMP_CLS_CD]
										C.CONT_TIME 		AS CONT_TIME,		--	소정근로시간
										--C.BP05				AS CONT_TIME,		--	소정근로시간
										B.UNION_YN 			AS UNION_YN,		--	노조회비공제대상여부
										B.UNION_FULL_YN 	AS UNION_FULL_YN,	--	노조전임여부
										B.UNION_CD 			AS PAY_UNION_CD,	--	노조사업장코드[PAY_UNION_CD]
										B.FOREJOB_YN 		AS FOREJOB_YN,		--	국외근로여부
										B.TRBNK_YN 			AS TRBNK_YN,		--	신협공제대상여부
										B.PROD_YN 			AS PROD_YN,			--	생산직여부
										B.ADV_YN 			AS ADV_YN,			--	선망가불금공제여부
										B.SMS_YN 			AS SMS_YN,			--	SMS발송여부
										B.EMAIL_YN 			AS EMAIL_YN,		--	E_MAIL발송여부
										B.WORK_YN 			AS WORK_YN,			--	근속수당지급여부
										B.WORK_YMD 			AS WORK_YMD,		--	근속기산일자
										B.RETR_YMD 			AS RETR_YMD,		--	퇴직금기산일자
										'' 					AS NOTE, 			--	비고
										@an_mod_user_id		AS MOD_USER_ID, 	--	변경자
										GETDATE() 			AS MOD_DATE, 		--	변경일시
										'KST' 				AS TZ_CD, 			--	타임존코드
										GETDATE() 			AS TZ_DATE,  		--	타임존일시
										B.ULSAN_YN 			AS ULSAN_YN,  		--	울산호봉적용여부
										B.INS_TRANS_YN		AS INS_TRANS_YN, 	--	동원산업전입여부
										B.GLS_WORK_CD		AS GLS_WORK_CD,  	--	유리근무유형[PAY_GLS_WORK_CD]
										--A.JOB_CD  			AS JOB_CD			--	직무코드[PHM_JOB_CD]
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'JOB_CD') AS JOB_CD	--	직무코드[PHM_JOB_CD]
								FROM PHM_EMP A
								INNER JOIN PAY_PHM_EMP B ON B.EMP_ID = A.EMP_ID
		       --    				INNER JOIN (
					    --       				SELECT  S.EMP_ID, S.BP12 AS PAY_BAS_TYPE_CD, S.SALARY_TYPE_CD, S.STA_YMD, S.END_YMD, DBO.XF_TO_NUMBER(S.BP05) AS CONT_TIME
									--		FROM CNM_CNT S
									--		WHERE S.COMPANY_CD = @av_company_cd
									--		AND S.STA_YMD = (
									--						SELECT  TOP 1 S1.STA_YMD
									--						FROM CNM_CNT S1
									--						WHERE S1.COMPANY_CD=S.COMPANY_CD
									--						AND S1.EMP_ID = S.EMP_ID 
									--						ORDER BY S1.STA_YMD DESC
									--						)
									--		) C
									--ON C.EMP_ID = A.EMP_ID
								INNER JOIN (
											SELECT A1.PAY_YMD, A1.PAY_YM,A1.PAY_TYPE_CD,B1.SALARY_TYPE_CD, C1.PAY_TERM_TYPE_CD, C1.STA_YMD , C1.END_YMD,A1.STD_YMD
											FROM PAY_PAY_YMD A1
											INNER JOIN PAY_PAY_YMD_DTL B1
													ON  B1.PAY_YMD_ID = A1.PAY_YMD_ID
													and a1.pay_ymd_id = @an_pay_ymd_id
											INNER JOIN PAY_PAY_YMD_DTL_TERM C1
													ON  C1.PAYYMD_DTL_ID = B1.PAYYMD_DTL_ID
											INNER JOIN FRM_CODE D1
													ON D1.CD = C1.PAY_TERM_TYPE_CD
											AND D1.LOCALE_CD = @av_locale_cd
											AND D1.COMPANY_CD = A1.COMPANY_CD-- @av_company_cd
											AND D1.CD_KIND = 'PAY_TERM_TYPE_CD'
											AND D1.SYS_CD = '01'  --각 유형의 급여일자 기간만 읽어온다
											AND A1.STD_YMD BETWEEN D1.STA_YMD AND D1.END_YMD			                 	
											WHERE  1=1
											AND D1.LOCALE_CD = @av_locale_cd
											AND D1.COMPANY_CD = @av_company_cd
											AND D1.CD_KIND = 'PAY_TERM_TYPE_CD'
											AND D1.SYS_CD = '01'  --각 유형의 급여일자 기간만 읽어온다
											AND A1.PAY_YMD_ID = @an_pay_ymd_id
											AND A1.STD_YMD BETWEEN D1.STA_YMD AND D1.END_YMD			                 	
									) D ON 1 = 1    
                 					--ON C.STA_YMD <= D.END_YMD
                 					--AND C.END_YMD >= D.STA_YMD
                 					--AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD	
								INNER JOIN (
											SELECT Y.EMP_ID, Y.SALARY_TYPE_CD, Y.BP12 AS PAY_BAS_TYPE_CD,Y.BP05 AS CONT_TIME
											FROM  (
															SELECT  COMPANY_CD, EMP_ID, SALARY_TYPE_CD, MIN(STA_YMD) AS STA_YMD
															FROM CNM_CNT 
															WHERE COMPANY_CD = @av_company_cd
															--AND DBO.XF_TO_DATE(@v_pay_ym+'01','YYYY-MM-DD') <= END_YMD
															--AND DBO.XF_LAST_DAY(DBO.XF_TO_DATE(@v_pay_ym+'01','YYYY-MM-DD'))>= STA_YMD
															AND @v_pay_ym <= FORMAT(END_YMD,'yyyyMM')
															AND @v_pay_ym >= FORMAT(STA_YMD,'yyyyMM')
															GROUP BY COMPANY_CD, EMP_ID, SALARY_TYPE_CD
															) X
											INNER JOIN CNM_CNT Y  ON X.COMPANY_CD = Y.COMPANY_CD  AND X.EMP_ID = Y.EMP_ID AND X.SALARY_TYPE_CD = Y.SALARY_TYPE_CD AND X.STA_YMD = Y.STA_YMD
											) C	 ON C.EMP_ID = A.EMP_ID AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD
								--INNER JOIN (
     			--							SELECT X1.PAY_TYPE_CD , Y1.PAY_GROUP ,X1.PAY_GROUP_ID
     			--							FROM PAY_GROUP_TYPE X1, PAY_GROUP Y1
     			--							WHERE 1 = 1
			     --            				  AND X1.COMPANY_CD = @av_company_cd
			     --            				  AND X1.PAY_TYPE_CD = @v_pay_type_cd
			     --            				  AND X1.PAY_GROUP_ID = Y1.PAY_GROUP_ID
		      --           			  		) E
			     --          			ON E.PAY_TYPE_CD = D.PAY_TYPE_CD
								LEFT OUTER JOIN (
												 SELECT EMP_ID              ,     -- 사원ID
												   		BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
												   		ACCOUNT_NO               -- 계좌번호
												 FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
												 WHERE X.ACCOUNT_TYPE_CD  = CASE WHEN Y.ACCOUNT_TYPE_CD = X.ACCOUNT_TYPE_CD THEN Y.ACCOUNT_TYPE_CD ELSE '01' END  --계좌유형 같은게 있으면 읽어오고 없으면 급여계좌
												   AND Y.PAY_YMD_ID 	  = @an_pay_ymd_id												   
												   AND @d_std_ymd  BETWEEN X.STA_YMD AND X.END_YMD
												) Z ON B.EMP_ID = Z.EMP_ID
								 WHERE 1=1
								 AND A.COMPANY_CD = @av_company_cd
								 AND DBO.XF_NVL_D(A.RETIRE_YMD,'29991231') >= D.STA_YMD
								 --AND A.IN_OFFI_YN = 'Y'
								 --AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
								-- AND DBO.F_PAY_GROUP_CHK(E.PAY_GROUP_ID,A.EMP_ID,D.PAY_YMD) = E.PAY_GROUP_ID
								 AND NOT EXISTS	(
												 SELECT 'X'
                  								 FROM PAY_EXP_UPLOAD Z
                  								 WHERE Z.COMPANY_CD = @av_company_cd
                  								 AND Z.EMP_ID = A.EMP_ID
                  								 AND Z.PAY_EXP_CD = '301'  --급여제외자 제외
												 --AND D.PAY_YM  BETWEEN Z.STA_YM AND Z.END_YM
												 AND @v_pay_ym  BETWEEN Z.STA_YM AND Z.END_YM
                  								 )
								  ) T1
								  WHERE dbo.F_PAY_GROUP_CHK(@n_pay_group_id, T1.EMP_ID, @d_pay_ymd) = @n_pay_group_id
								  --where T1.PAY_GROUP_ID > 0
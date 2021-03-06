USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_PAY_PAYROLL_MAKE_E]    Script Date: 2021-04-21 오전 11:20:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[P_PAY_PAYROLL_MAKE_E](
    @av_company_cd           NVARCHAR(10),           -- 인사영역
    @av_locale_cd            NVARCHAR(10),           -- 지역코드
    @an_pay_ymd_id           NUMERIC,                -- 급여일자ID
    @an_org_id               NUMERIC,                -- 조직
    @an_emp_id               NUMERIC,                -- 사원ID
    @an_mod_user_id          NUMERIC,                -- 변경자 ID
    @av_ret_code             NVARCHAR(4000) OUTPUT,  -- 결과코드
    @av_ret_message          NVARCHAR(4000) OUTPUT   -- 결과메시지
)   AS

    -- ***************************************************************************
    --   TITLE       : 급여대상자선정
    --   PROJECT     : H5 5.7
    --   AUTHOR      :
    --   PROGRAM_ID  : P_PAY_PAYROLL_MAKE_E
    --   ARGUMENT    : 
    --   RETURN      : 결과코드 = SUCCESS!/FAILURE!
    --                 결과메시지
    --   COMMENT     : 매월 정기적으로 급여지급되는 대상자를 생성한다.
    --   HISTORY     : 작성 2020.08.28
    -- ***************************************************************************
    --  001 급여,    002 정기상여,    003 성과급,    004 퇴직당월급여

BEGIN
    /* 기본적으로 사용되는 변수 */
    DECLARE 
    	  @v_program_id        NVARCHAR(30)
        , @v_program_nm        NVARCHAR(100)
        , @d_pay_ymd           DATE					-- 급여일자
		, @v_pay_type_cd       NVARCHAR(10)			-- 급여지급유형코드
		, @v_retro_pay_type_cd NVARCHAR(10)			-- 소급유형코드
		, @v_pay_ym            NVARCHAR(8)			-- 급여적용년월
		, @v_pre_pay_ym        NVARCHAR(8)			-- 급여적용전월
		, @d_std_ymd           DATE 
		, @d_sta_ymd           DATE 
		, @d_end_ymd           DATE
		, @v_salary_type_cd    NVARCHAR(10)			-- 급여유형
		, @v_close_type_cd     NVARCHAR(10)			-- 대상자생성
		, @d_retire_ymd        DATE					-- 퇴직일자
		, @n_cnt               NUMERIC(10)
		, @n_pay_group_id      NUMERIC(18)			-- 급여그룹ID
		, @v_pay_group_cd	   NVARCHAR(50)			-- 급여그룹코드
		
		, @n_pre_pay_ymd_id    NUMERIC(17) = 0		--급여일자ID
		, @v_pay_type_sys_cd   NVARCHAR(50)			--지급구분 시스템코드

		, @errornumber         NUMERIC
        , @errormessage        NVARCHAR(4000)
        
	    /* 기본변수 초기값 셋팅 */
		SET @v_close_type_cd = 'PAY02';
	    SET @v_program_id    = 'P_PAY_PAYROLL_MAKE_E';       -- 현재 프로시져의 영문명
	    SET @v_program_nm    = '대상자생성';                -- 현재 프로시져의 한글문명
	    
	
	    SET @av_ret_code     = 'SUCCESS!';
	    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null, @an_mod_user_id );

	/****************************************************************************
    ** 급여마감 체크
    *****************************************************************************/
	BEGIN
		EXECUTE dbo.P_PAY_CLOSE_CHECK @an_pay_ymd_id, @v_close_type_cd, @av_locale_cd, @av_ret_code OUTPUT, @av_ret_message  OUTPUT
	
		IF @av_ret_code = 'FAILURE!'
            BEGIN
               SET @av_ret_code = 'FAILURE!';
               SET @av_ret_message = @av_ret_message;
               RETURN 
            END
	END
	
    
	/***********************************************************************************************************************************
    ** 급여정보 체크
    ***********************************************************************************************************************************/
    -- 급여일자 조회
	BEGIN
		SELECT @v_pay_type_cd	= A.PAY_TYPE_CD,
			   @v_pay_ym		= A.PAY_YM,
			   @v_pre_pay_ym	= DBO.XF_SUBSTR(CONVERT(NVARCHAR,DBO.XF_DATEADD(DBO.XF_TO_DATE(A.PAY_YM+'01','yyyymmdd'),-1),112),1,6),
			   @d_pay_ymd		= A.PAY_YMD,
			   @d_std_ymd		= A.STD_YMD,
			   @d_sta_ymd		= A.STA_YMD,
			   @d_end_ymd		= A.END_YMD,
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
		
		IF @@ROWCOUNT < 1
			BEGIN
				SET @av_ret_code    = 'FAILURE!'
	            SET @av_ret_message = DBO.F_FRM_ERRMSG('급여일자가 없습니다.[ERR]', @v_program_id,  0095,  null, null)
				RETURN	
			END
	END
	
    -- 급여지급유형이 조회
	BEGIN
		SELECT @n_cnt = COUNT(PAY_PAY_YMD_DTL.SALARY_TYPE_CD)
		  FROM PAY_PAY_YMD_DTL
		 WHERE PAY_PAY_YMD_DTL.PAY_YMD_ID = @an_pay_ymd_id
		 
		IF @@ROWCOUNT < 1
			BEGIN
				SET @av_ret_code    = 'FAILURE!'
		        SET @av_ret_message = DBO.F_FRM_ERRMSG('급여지급유형이 없습니다.[ERR]', @v_program_id,  0112,  null, null)
			    RETURN	
			END
	END
	

	/***********************************************************************************************************************************
    ** 정기급여대상자선정
    ***********************************************************************************************************************************/	
	--정기급여
	IF @v_pay_type_sys_cd = '001' 
		BEGIN				
			--대상자 INSERT
			BEGIN TRY
					INSERT INTO PAY_PAYROLL
					(
						PAY_PAYROLL_ID,		--	급여내역ID
						PAY_YMD_ID,			--	급여일자ID
						EMP_ID,				--	사원ID
						SALARY_TYPE_CD,		--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
						PAY_BAS_TYPE_CD,	--  기본급산정유형코드[PAY_BAS_TYPE_CD]	
						SUB_COMPANY_CD,		--	서브회사코드
						PAY_GROUP_CD,		--	급여그룹
						PAY_BIZ_CD,			--	급여사업장코드
						RES_BIZ_CD,			--	지방세사업장코드
						ORG_ID,				--	발령부서ID
						PAY_ORG_ID,			--	급여부서ID
						POS_CD,				--	직위코드[PHM_POS_CD]
						MGR_TYPE_CD	,		--  관리구분[PHM_MR_TYPE_CD]
						JOB_POSITION_CD,	--	직종코드
						DUTY_CD,            --  직책코드[PHM_DUTY_CD]
						ACC_CD,				--	코스트센터(ORM_COST_ORG_CD)
						PSUM,				--	지급집계(모든기지급포함)
						PSUM1,				--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
						PSUM2,				--	지급집계(모든기지급포함안함)
						DSUM,				--	공제집계
						TSUM,				--	세금집계
						REAL_AMT,			--	실지급액
						BANK_CD,			--	은행코드[PAY_BANK_CD]
						ACCOUNT_NO,			--	계좌번호
						FILLDT,				--	기표일
						POS_GRD_CD,			--	직급[PHM_POS_GRD_CD]
						PAY_GRADE,			--	호봉코드 [PHM_YEARNUM_CD]
						DTM_TYPE,			--	근태유형
						FILLNO,				--	전표번호
						NOTICE,				--	급여명세공지
						TAX_YMD,			--	원천징수신고일자
						FOREIGN_PSUM,		--	외화지급집계(모든기지급포함)
						FOREIGN_PSUM1,		--	외화지급집계(PSUM에서 급여성기지급 포함 안함)
						FOREIGN_PSUM2,		--	외화지급집계(모든기지급포함안함)
						FOREIGN_DSUM,		--	외화공제집계
						FOREIGN_TSUM,		--	외화세금집계
						FOREIGN_REAL_AMT,	--	외화실지급액
						CURRENCY_CD,		--	통화코드[PAY_CURRENCY_CD]
						TAX_SUBSIDY_YN,		--	세금보조여부
						TAX_FAMILY_CNT,		--	부양가족수
						FAM20_CNT,			--	20세이하자녀수
						FOREIGN_YN,			--	외국인여부
						PEAK_YN	,			--  임금피크대상여부
						PEAK_DATE,			--	임금피크적용일자
						PAY_METH_CD,		--	급여지급방식코드[PAY_METH_CD]
						PAY_EMP_CLS_CD,		--	고용유형코드[PAY_EMP_CLS_CD]
						CONT_TIME,			--	소정근로시간
						UNION_YN,			--	노조회비공제대상여부
						UNION_FULL_YN,		--	노조전임여부
						PAY_UNION_CD,		--	노조사업장코드[PAY_UNION_CD]
						FOREJOB_YN,			--	국외근로여부
						TRBNK_YN,			--	신협공제대상여부
						PROD_YN,			--	생산직여부
						ADV_YN,				--	선망가불금공제여부
						SMS_YN,				--	SMS발송여부
						EMAIL_YN,			--	E_MAIL발송여부
						WORK_YN,			--	근속수당지급여부
						WORK_YMD,			--	근속기산일자
						RETR_YMD,			--	퇴직금기산일자
						NOTE, 				--	비고
						MOD_USER_ID, 		--	변경자
						MOD_DATE, 			--	변경일시
						TZ_CD, 				--	타임존코드
						TZ_DATE,  			--	타임존일시
						ULSAN_YN,  			--	울산호봉적용여부
						INS_TRANS_YN,  		--	동원산업전입여부
						GLS_WORK_CD,  		--	유리근무유형[PAY_GLS_WORK_CD]
						JOB_CD  			--	직무코드[PHM_JOB_CD]
					   )
             			SELECT 
             				NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    						T1.*
						 FROM (
								 SELECT @an_pay_ymd_id 		AS PAY_YMD_ID, 		--	급여일자ID
										A.EMP_ID  			AS EMP_ID,			--	사원ID
										C.SALARY_TYPE_CD 	AS SALARY_TYPE_CD,	--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
										C.PAY_BAS_TYPE_CD	AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]	
										--C.BP12				AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]
										'' 					AS SUB_COMPANY_CD,	--	서브회사코드
										E.PAY_GROUP 		AS PAY_GROUP_CD,	--	급여그룹
										--DBO.F_ORM_ORG_BIZ(A.ORG_ID,@d_std_ymd,'PAY') AS PAY_BIZ_CD,					--	급여사업장코드										
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
											SELECT A1.PAY_YMD, A1.PAY_YM,A1.PAY_TYPE_CD,A1.ACCOUNT_TYPE_CD,B1.SALARY_TYPE_CD, C1.PAY_TERM_TYPE_CD, C1.STA_YMD , C1.END_YMD,A1.STD_YMD
											FROM PAY_PAY_YMD A1
											INNER JOIN PAY_PAY_YMD_DTL B1
													ON  B1.PAY_YMD_ID = A1.PAY_YMD_ID
											INNER JOIN PAY_PAY_YMD_DTL_TERM C1
													ON  C1.PAYYMD_DTL_ID = B1.PAYYMD_DTL_ID
											INNER JOIN FRM_CODE D1
													ON D1.CD = C1.PAY_TERM_TYPE_CD
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
 								--INNER JOIN CNM_CNT C ON (
							  --                            C.COMPANY_CD = @av_company_cd
									--					AND C.EMP_ID = A.EMP_ID
									--					AND @d_std_ymd  BETWEEN C.STA_YMD AND C.END_YMD
									--					--AND C.STA_YMD <= D.END_YMD
					    --             					--AND C.END_YMD >= D.STA_YMD
					    --             					AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD
					    --             					)
								INNER JOIN (
											SELECT Y.EMP_ID, Y.SALARY_TYPE_CD, Y.BP12 AS PAY_BAS_TYPE_CD,Y.BP05 AS CONT_TIME
											FROM  (
															SELECT  COMPANY_CD, EMP_ID, SALARY_TYPE_CD, MIN(STA_YMD) AS STA_YMD
															FROM CNM_CNT 
															WHERE COMPANY_CD = @av_company_cd
															AND DBO.XF_TO_DATE(@v_pay_ym+'01','YYYY-MM-DD') <= END_YMD
															AND DBO.XF_LAST_DAY(DBO.XF_TO_DATE(@v_pay_ym+'01','YYYY-MM-DD'))>= STA_YMD
															GROUP BY COMPANY_CD, EMP_ID, SALARY_TYPE_CD
															) X
											INNER JOIN CNM_CNT Y  ON X.COMPANY_CD = Y.COMPANY_CD  AND X.EMP_ID = Y.EMP_ID AND X.SALARY_TYPE_CD = Y.SALARY_TYPE_CD AND X.STA_YMD = Y.STA_YMD
											) C	 ON C.EMP_ID = A.EMP_ID AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD
								INNER JOIN (
     										SELECT X1.PAY_TYPE_CD , Y1.PAY_GROUP ,X1.PAY_GROUP_ID
     										FROM PAY_GROUP_TYPE X1, PAY_GROUP Y1
     										WHERE 1 = 1
			                 				  AND X1.COMPANY_CD = @av_company_cd
											  AND X1.PAY_TYPE_CD = @v_pay_type_cd
			                 				  AND X1.PAY_GROUP_ID = Y1.PAY_GROUP_ID
		                 			  		) E
			               			ON E.PAY_TYPE_CD = D.PAY_TYPE_CD
								LEFT OUTER JOIN (
												--SELECT Y.EMP_ID,Y.BANK_CD,Y.ACCOUNT_NO
												--FROM (
												--		SELECT RANK() OVER (PARTITION BY X.EMP_ID ORDER BY X.PRI_ORD ) SET_ORD, X.*
												--		FROM (
												--				SELECT  
												--						CASE WHEN X.ACCOUNT_TYPE_CD = Y.ACCOUNT_TYPE_CD THEN 1 ELSE 2 END AS PRI_ORD,
												--						X.EMP_ID              ,     -- 사원ID
												--						X.BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
												--						X.ACCOUNT_NO,               -- 계좌번호
												--						X.ACCOUNT_TYPE_CD
												--				FROM PAY_ACCOUNT X , PAY_PAY_YMD Y
												--				WHERE X.ACCOUNT_TYPE_CD  IN (Y.ACCOUNT_TYPE_CD,'01')  --계좌유형 같은게 있으면 읽어오고 없으면 급여계좌
												--				AND Y.PAY_YMD_ID 	= @an_pay_ymd_id
												--				AND Y.STD_YMD  BETWEEN X.STA_YMD AND X.END_YMD
												--			) X
												--		) Y
												--WHERE SET_ORD = 1
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
								 AND ((@an_emp_id IS NULL) OR (A.EMP_ID = @an_emp_id))
								 AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)								  
								 --AND A.IN_OFFI_YN = 'Y'
								 AND NOT EXISTS(SELECT 'X' FROM PAY_PAYROLL S WHERE S.PAY_YMD_ID = @an_pay_ymd_id AND S.EMP_ID = A.EMP_ID)  --이미만들어진사람 제외
								 AND DBO.F_PAY_GROUP_CHK(E.PAY_GROUP_ID,A.EMP_ID,D.PAY_YMD) = E.PAY_GROUP_ID
								 AND NOT EXISTS	(
												 SELECT 'X'
                  								 FROM PAY_EXP_UPLOAD Z
                  								 WHERE Z.COMPANY_CD = @av_company_cd
                  								 AND Z.EMP_ID = A.EMP_ID
                  								 AND Z.PAY_EXP_CD = '301'  --급여제외자 제외
												 AND D.PAY_YM  BETWEEN Z.STA_YM AND Z.END_YM
                  								 )
								  ) T1		              
			END TRY
       
			BEGIN CATCH
       			SET @errornumber   = ERROR_NUMBER()
				SET @errormessage  = ERROR_MESSAGE()
	
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 생성시 오류발생[ERR]',
										  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
				IF @@TRANCOUNT > 0
					ROLLBACK WORK
				RETURN
			END CATCH

			--원장생성시 반영하도록 되어있음...여기는 막아둠
			--전월급여일자 ID 정보를 읽어온다
			SELECT @n_pre_pay_ymd_id = DBO.F_PAY_GET_PAY_ID(@av_company_cd,@v_pay_type_cd,@v_pre_pay_ym)			

			--PRINT('START-RETRO_PAYROLL')

			IF @n_pre_pay_ymd_id <> 0
			BEGIN
				--전월입사자 급여미지급 되었으면 소급일자를 생성하여 지급 한다
				BEGIN TRY
					INSERT INTO PAY_RETRO_PAY_YMD
					(
						PAY_RETRO_PAY_YMD_ID,	--개인별소급급여일자ID
						PAY_YMD_ID,				--급여일자ID
						EMP_ID,					--사원ID
						SALARY_TYPE_CD,			--급여유형[PAY_SALARY_TYPE_CD]
						RETRO_PAY_YMD_ID,		--소급대상급여일자ID
						ALL_YN,					--모든항목여부
						APPLY_YN,				--적용여부
						RETRO_NOTE,				--소급사유
						NOTE,					--비고
						MOD_USER_ID,			--변경자
						MOD_DATE,				--변경일시
						TZ_CD,					--타임존코드
						TZ_DATE					--타임존일시
					)
					SELECT  
						NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_RETRO_PAY_YMD_ID,	--개인별소급급여일자ID
						@an_pay_ymd_id			AS PAY_YMD_ID,		--	급여일자ID
						A.EMP_ID				AS EMP_ID,			--	사원ID
						A.SALARY_TYPE_CD		AS SALARY_TYPE_CD,	--	급여유형[PAY_SALARY_TYPE_CD]
						@n_pre_pay_ymd_id		AS RETRO_PAY_YMD_ID,--	소급대상급여일자ID
						'N'						AS ALL_YN,			--	모든항목여부
						'Y'						AS APPLY_YN,		--	적용여부
						'전월 입사자 자동생성'	AS RETRO_NOTE,		--	소급사유
						''						AS NOTE,			--	비고
						@an_mod_user_id			AS MOD_USER_ID, 	--	변경자
						GETDATE() 				AS MOD_DATE, 		--	변경일시
						'KST' 					AS TZ_CD, 			--	타임존코드
						GETDATE() 				AS TZ_DATE  		--	타임존일시
					FROM PAY_PAYROLL A, PHM_EMP B,
									(
									SELECT  B1.SALARY_TYPE_CD,C1.PAY_TERM_TYPE_CD,C1.STA_YMD,C1.END_YMD
									FROM PAY_PAY_YMD A1
									INNER JOIN PAY_PAY_YMD_DTL B1 ON A1.PAY_YMD_ID = B1.PAY_YMD_ID
									INNER JOIN PAY_PAY_YMD_DTL_TERM C1 ON B1.PAYYMD_DTL_ID = C1.PAYYMD_DTL_ID
									WHERE C1.PAY_TERM_TYPE_CD IN (
																	SELECT X.CD
																	FROM FRM_CODE X
																	WHERE 1=1
																	AND X.LOCALE_CD  = @av_locale_cd
																	AND X.COMPANY_CD = @av_company_cd
																	AND X.CD_KIND 		= 'PAY_TERM_TYPE_CD'
																	AND X.SYS_CD 		= '01'  -- 급여일자 유형이 급여기간만 읽어온다(공통코드 관리 시스템코드참조)
																	AND A1.PAY_YMD 		BETWEEN X.STA_YMD AND X.END_YMD	  											 
																	)				
									AND A1.PAY_YMD_ID = @an_pay_ymd_id
									AND A1.COMPANY_CD = @av_company_cd
									) C
					WHERE A.PAY_YMD_ID = @an_pay_ymd_id
					AND A.EMP_ID = B.EMP_ID
					AND C.SALARY_TYPE_CD = A.SALARY_TYPE_CD
					AND C.SALARY_TYPE_CD NOT IN (   --후불급여 대상자는 제외처리
												'004',	--연봉제(전전)
												'007',	--호봉제(전전)
												'008',	--호봉제(전21전11)
												'009',	--호봉제(전21전21)
												'010',	--시급제(전전)
												'100'	--일급제(전전)
												)
					AND B.HIRE_YMD BETWEEN dbo.XF_MONTHADD(C.STA_YMD, -1) AND dbo.XF_MONTHADD(C.END_YMD, -1)										
					AND NOT EXISTS (
								   SELECT 1  --전월지급된 내역이 없는 사람만 체크
								   FROM PAY_PAYROLL X
								   WHERE X.PAY_YMD_ID = @n_pre_pay_ymd_id
								   AND X.EMP_ID = A.EMP_ID
								   )
					AND NOT EXISTS  --이미 만들어진 사람은 제외한다
									(
										SELECT 1
										FROM PAY_RETRO_PAY_YMD X
										WHERE X.PAY_YMD_ID = @an_pay_ymd_id
										AND X.EMP_ID = A.EMP_ID
										AND X.SALARY_TYPE_CD = A.SALARY_TYPE_CD
										AND X.RETRO_PAY_YMD_ID = @n_pre_pay_ymd_id
									)

				END TRY

				BEGIN CATCH
       				SET @errornumber   = ERROR_NUMBER()
					SET @errormessage  = ERROR_MESSAGE()
	
					SET @av_ret_code    = 'FAILURE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG(' 전월입사자 소급일자등록 오류발생[ERR]',
											  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
					IF @@TRANCOUNT > 0
						ROLLBACK WORK
					RETURN

				END CATCH

				--PRINT('START-RETRO_PAYROLL')

				--소급일자에 대한 대상자정보 생성
				BEGIN
					EXECUTE P_PAY_MST_CHANGE_RETRO_PAYROLL 
												@av_company_cd ,			-- 인사영역
												@av_locale_cd,				-- 지역코드									
												@an_pay_ymd_id,				-- 급여일자									
			                  					@an_mod_user_id,            -- 변경자
 												@av_ret_code	  OUTPUT,   -- SUCCESS!/FAILURE!
												@av_ret_message   OUTPUT    -- 결과메시지
				END
			
				IF @av_ret_code = 'FAILURE!' 
				   BEGIN
						  SET @av_ret_code = 'FAILURE!' 
						  SET @av_ret_message = @av_ret_message 
						  RETURN
				   END

			END
		END
	
	/***********************************************************************************************************************************
    ** 제수당 대상자선정 - 003
	**    => 제수당 대상자를 급여처럼 사전 정의 할수 없으므로 명단을 직접 입력을 한다
	**    => 만약 버튼을 클릭할 경우 정기급여 대상자 똑같이 생성을 한다
    ***********************************************************************************************************************************/			
	--제수당
	IF @v_pay_type_sys_cd = '002' 
		BEGIN				
			--대상자 INSERT
			BEGIN TRY
					INSERT INTO PAY_PAYROLL
					(
						PAY_PAYROLL_ID,		--	급여내역ID
						PAY_YMD_ID,			--	급여일자ID
						EMP_ID,				--	사원ID
						SALARY_TYPE_CD,		--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
						PAY_BAS_TYPE_CD,	--  기본급산정유형코드[PAY_BAS_TYPE_CD]	
						SUB_COMPANY_CD,		--	서브회사코드
						PAY_GROUP_CD,		--	급여그룹
						PAY_BIZ_CD,			--	급여사업장코드
						RES_BIZ_CD,			--	지방세사업장코드
						ORG_ID,				--	발령부서ID
						PAY_ORG_ID,			--	급여부서ID
						POS_CD,				--	직위코드[PHM_POS_CD]
						MGR_TYPE_CD	,		--  관리구분[PHM_MR_TYPE_CD]
						JOB_POSITION_CD,	--	직종코드
						DUTY_CD,            --  직책코드[PHM_DUTY_CD]
						ACC_CD,				--	코스트센터(ORM_COST_ORG_CD)
						PSUM,				--	지급집계(모든기지급포함)
						PSUM1,				--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
						PSUM2,				--	지급집계(모든기지급포함안함)
						DSUM,				--	공제집계
						TSUM,				--	세금집계
						REAL_AMT,			--	실지급액
						BANK_CD,			--	은행코드[PAY_BANK_CD]
						ACCOUNT_NO,			--	계좌번호
						FILLDT,				--	기표일
						POS_GRD_CD,			--	직급[PHM_POS_GRD_CD]
						PAY_GRADE,			--	호봉코드 [PHM_YEARNUM_CD]
						DTM_TYPE,			--	근태유형
						FILLNO,				--	전표번호
						NOTICE,				--	급여명세공지
						TAX_YMD,			--	원천징수신고일자
						FOREIGN_PSUM,		--	외화지급집계(모든기지급포함)
						FOREIGN_PSUM1,		--	외화지급집계(PSUM에서 급여성기지급 포함 안함)
						FOREIGN_PSUM2,		--	외화지급집계(모든기지급포함안함)
						FOREIGN_DSUM,		--	외화공제집계
						FOREIGN_TSUM,		--	외화세금집계
						FOREIGN_REAL_AMT,	--	외화실지급액
						CURRENCY_CD,		--	통화코드[PAY_CURRENCY_CD]
						TAX_SUBSIDY_YN,		--	세금보조여부
						TAX_FAMILY_CNT,		--	부양가족수
						FAM20_CNT,			--	20세이하자녀수
						FOREIGN_YN,			--	외국인여부
						PEAK_YN	,			--  임금피크대상여부
						PEAK_DATE,			--	임금피크적용일자
						PAY_METH_CD,		--	급여지급방식코드[PAY_METH_CD]
						PAY_EMP_CLS_CD,		--	고용유형코드[PAY_EMP_CLS_CD]
						CONT_TIME,			--	소정근로시간
						UNION_YN,			--	노조회비공제대상여부
						UNION_FULL_YN,		--	노조전임여부
						PAY_UNION_CD,		--	노조사업장코드[PAY_UNION_CD]
						FOREJOB_YN,			--	국외근로여부
						TRBNK_YN,			--	신협공제대상여부
						PROD_YN,			--	생산직여부
						ADV_YN,				--	선망가불금공제여부
						SMS_YN,				--	SMS발송여부
						EMAIL_YN,			--	E_MAIL발송여부
						WORK_YN,			--	근속수당지급여부
						WORK_YMD,			--	근속기산일자
						RETR_YMD,			--	퇴직금기산일자
						NOTE, 				--	비고
						MOD_USER_ID, 		--	변경자
						MOD_DATE, 			--	변경일시
						TZ_CD, 				--	타임존코드
						TZ_DATE,  			--	타임존일시
						ULSAN_YN,  			--	울산호봉적용여부
						INS_TRANS_YN,  		--	동원산업전입여부
						GLS_WORK_CD,  		--	유리근무유형[PAY_GLS_WORK_CD]
						JOB_CD  			--	직무코드[PHM_JOB_CD]
					   )
             			SELECT 
             				NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    						T1.*
						 FROM (
								 SELECT @an_pay_ymd_id 		AS PAY_YMD_ID, 		--	급여일자ID
										A.EMP_ID  			AS EMP_ID,			--	사원ID
										C.SALARY_TYPE_CD 	AS SALARY_TYPE_CD,	--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
										--C.PAY_BAS_TYPE_CD	AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]	
										C.BP12				AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]
										'' 					AS SUB_COMPANY_CD,	--	서브회사코드
										E.PAY_GROUP 		AS PAY_GROUP_CD,	--	급여그룹
										DBO.F_ORM_ORG_BIZ(dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd,'PAY') AS PAY_BIZ_CD,	--	급여사업장코드
										DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd) AS RES_BIZ_CD,	--	지방세사업장코드
										--DBO.F_ORM_ORG_BIZ(A.ORG_ID,@d_std_ymd,'PAY') AS PAY_BIZ_CD,		--	급여사업장코드										
										--DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,A.ORG_ID,@d_std_ymd) AS RES_BIZ_CD,		--	지방세사업장코드
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS ORG_ID,			--	발령부서ID
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS PAY_ORG_ID,		--	급여부서ID
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'POS_CD') AS POS_CD,			--	직위코드[PHM_POS_CD]										
										--A.ORG_ID 			AS ORG_ID,			--	발령부서ID
										--A.ORG_ID 			AS PAY_ORG_ID,		--	급여부서ID
										--A.POS_CD			AS POS_CD,			--	직위코드[PHM_POS_CD]
										
										A.MGR_TYPE_CD		AS MGR_TYPE_CD,		--  관리구분[PHM_MR_TYPE_CD]
										A.JOB_POSITION_CD	AS JOB_POSITION_CD,	--	직종코드
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'DUTY_CD') AS DUTY_CD,       --  직책코드[PHM_DUTY_CD]
						                --A.DUTY_CD           AS DUTY_CD,         --  직책코드[PHM_DUTY_CD]
										DBO.F_ORM_ORG_COST(A.COMPANY_CD,A.EMP_ID,@d_std_ymd,'1')	AS ACC_CD,			--	코스트센터(ORM_COST_ORG_CD)
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
										--C.CONT_TIME 		AS CONT_TIME,		--	소정근로시간
										C.BP05				AS CONT_TIME,		--	소정근로시간
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
											SELECT A1.PAY_YMD, A1.PAY_YM,A1.PAY_TYPE_CD,B1.SALARY_TYPE_CD, C1.PAY_TERM_TYPE_CD, C1.STA_YMD , C1.END_YMD
											FROM PAY_PAY_YMD A1
											INNER JOIN PAY_PAY_YMD_DTL B1
													ON  B1.PAY_YMD_ID = A1.PAY_YMD_ID
											INNER JOIN PAY_PAY_YMD_DTL_TERM C1
													ON  C1.PAYYMD_DTL_ID = B1.PAYYMD_DTL_ID
											INNER JOIN FRM_CODE D1
													ON D1.CD = C1.PAY_TERM_TYPE_CD
											WHERE  1=1
											AND D1.LOCALE_CD = @av_locale_cd
											AND D1.COMPANY_CD = @av_company_cd
											AND D1.CD_KIND = 'PAY_TERM_TYPE_CD'
											AND D1.SYS_CD = '01'  --각 유형의 급여일자 기간만 읽어온다
											AND A1.PAY_YMD_ID = @an_pay_ymd_id
											AND A1.STD_YMD BETWEEN D1.STA_YMD AND D1.END_YMD			                 	
									) D ON 1=1
                 					--ON C.STA_YMD <= D.END_YMD
                 					--AND C.END_YMD >= D.STA_YMD
                 					--AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD
 								INNER JOIN CNM_CNT C ON (
							                              C.COMPANY_CD = @av_company_cd			
														AND C.EMP_ID = A.EMP_ID           
														AND C.STA_YMD <= D.END_YMD
					                 					AND C.END_YMD >= D.STA_YMD
					                 					AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD       
					                 					)
								INNER JOIN (
     										SELECT X1.PAY_TYPE_CD , Y1.PAY_GROUP ,X1.PAY_GROUP_ID
     										FROM PAY_GROUP_TYPE X1, PAY_GROUP Y1
     										WHERE 1 = 1
			                 				  AND X1.COMPANY_CD = @av_company_cd
			                 				  AND X1.PAY_GROUP_ID = Y1.PAY_GROUP_ID
		                 			  		) E
			               			ON E.PAY_TYPE_CD = D.PAY_TYPE_CD
								LEFT OUTER JOIN (
												 SELECT EMP_ID              ,     -- 사원ID
												   		BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
												   		ACCOUNT_NO               -- 계좌번호
												 FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
												 WHERE X.ACCOUNT_TYPE_CD  = CASE WHEN Y.ACCOUNT_TYPE_CD = X.ACCOUNT_TYPE_CD THEN Y.ACCOUNT_TYPE_CD ELSE '01' END  --계좌유형 같은게 있으면 읽어오고 없으면 급여계좌
												   AND Y.PAY_YMD_ID 	  = @an_pay_ymd_id
												   --AND DBO.XF_TO_DATE(Y.PAY_YM + '01','YYYY-MM-DD') BETWEEN X.STA_YMD AND X.END_YMD
												   AND @d_std_ymd  BETWEEN X.STA_YMD AND X.END_YMD
												) Z ON B.EMP_ID = Z.EMP_ID
								 WHERE 1=1
								 AND A.COMPANY_CD = @av_company_cd
								 AND DBO.XF_NVL_D(A.RETIRE_YMD,'29991231') >= D.STA_YMD
								 AND ((@an_emp_id IS NULL) OR (A.EMP_ID = @an_emp_id))
								 AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)								  
								 AND A.IN_OFFI_YN = 'Y'
								 AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
								 AND DBO.F_PAY_GROUP_CHK(E.PAY_GROUP_ID,A.EMP_ID,D.PAY_YMD) = E.PAY_GROUP_ID
								 AND NOT EXISTS	(
												 SELECT 'X'
                  								 FROM PAY_EXP_UPLOAD Z
                  								 WHERE Z.COMPANY_CD = @av_company_cd
                  								 AND Z.EMP_ID = A.EMP_ID
                  								 AND Z.PAY_EXP_CD = '301'  --급여제외자 제외
												 AND D.PAY_YM  BETWEEN Z.STA_YM AND Z.END_YM
                  								 )
								  ) T1		              
			END TRY
       
			BEGIN CATCH
       			SET @errornumber   = ERROR_NUMBER()
				SET @errormessage  = ERROR_MESSAGE()
	
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 생성시 오류발생[ERR]',
										  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
				IF @@TRANCOUNT > 0
					ROLLBACK WORK
				RETURN
			END CATCH
			
		END
	/***********************************************************************************************************************************
    ** 상여 대상자선정 - 003
	**    => 만약 버튼을 클릭할 경우 정기급여 대상자 똑같이 생성을 한다
    ***********************************************************************************************************************************/			
	IF @v_pay_type_sys_cd = '003' 
		BEGIN				
			--대상자 INSERT
			BEGIN TRY
					INSERT INTO PAY_PAYROLL
					(
						PAY_PAYROLL_ID,		--	급여내역ID
						PAY_YMD_ID,			--	급여일자ID
						EMP_ID,				--	사원ID
						SALARY_TYPE_CD,		--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
						PAY_BAS_TYPE_CD,	--  기본급산정유형코드[PAY_BAS_TYPE_CD]	
						SUB_COMPANY_CD,		--	서브회사코드
						PAY_GROUP_CD,		--	급여그룹
						PAY_BIZ_CD,			--	급여사업장코드
						RES_BIZ_CD,			--	지방세사업장코드
						ORG_ID,				--	발령부서ID
						PAY_ORG_ID,			--	급여부서ID
						POS_CD,				--	직위코드[PHM_POS_CD]
						MGR_TYPE_CD	,		--  관리구분[PHM_MR_TYPE_CD]
						JOB_POSITION_CD,	--	직종코드
						DUTY_CD,            --  직책코드[PHM_DUTY_CD]
						ACC_CD,				--	코스트센터(ORM_COST_ORG_CD)
						PSUM,				--	지급집계(모든기지급포함)
						PSUM1,				--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
						PSUM2,				--	지급집계(모든기지급포함안함)
						DSUM,				--	공제집계
						TSUM,				--	세금집계
						REAL_AMT,			--	실지급액
						BANK_CD,			--	은행코드[PAY_BANK_CD]
						ACCOUNT_NO,			--	계좌번호
						FILLDT,				--	기표일
						POS_GRD_CD,			--	직급[PHM_POS_GRD_CD]
						PAY_GRADE,			--	호봉코드 [PHM_YEARNUM_CD]
						DTM_TYPE,			--	근태유형
						FILLNO,				--	전표번호
						NOTICE,				--	급여명세공지
						TAX_YMD,			--	원천징수신고일자
						FOREIGN_PSUM,		--	외화지급집계(모든기지급포함)
						FOREIGN_PSUM1,		--	외화지급집계(PSUM에서 급여성기지급 포함 안함)
						FOREIGN_PSUM2,		--	외화지급집계(모든기지급포함안함)
						FOREIGN_DSUM,		--	외화공제집계
						FOREIGN_TSUM,		--	외화세금집계
						FOREIGN_REAL_AMT,	--	외화실지급액
						CURRENCY_CD,		--	통화코드[PAY_CURRENCY_CD]
						TAX_SUBSIDY_YN,		--	세금보조여부
						TAX_FAMILY_CNT,		--	부양가족수
						FAM20_CNT,			--	20세이하자녀수
						FOREIGN_YN,			--	외국인여부
						PEAK_YN	,			--  임금피크대상여부
						PEAK_DATE,			--	임금피크적용일자
						PAY_METH_CD,		--	급여지급방식코드[PAY_METH_CD]
						PAY_EMP_CLS_CD,		--	고용유형코드[PAY_EMP_CLS_CD]
						CONT_TIME,			--	소정근로시간
						UNION_YN,			--	노조회비공제대상여부
						UNION_FULL_YN,		--	노조전임여부
						PAY_UNION_CD,		--	노조사업장코드[PAY_UNION_CD]
						FOREJOB_YN,			--	국외근로여부
						TRBNK_YN,			--	신협공제대상여부
						PROD_YN,			--	생산직여부
						ADV_YN,				--	선망가불금공제여부
						SMS_YN,				--	SMS발송여부
						EMAIL_YN,			--	E_MAIL발송여부
						WORK_YN,			--	근속수당지급여부
						WORK_YMD,			--	근속기산일자
						RETR_YMD,			--	퇴직금기산일자
						NOTE, 				--	비고
						MOD_USER_ID, 		--	변경자
						MOD_DATE, 			--	변경일시
						TZ_CD, 				--	타임존코드
						TZ_DATE,  			--	타임존일시
						ULSAN_YN,  			--	울산호봉적용여부
						INS_TRANS_YN,		--	동원산업전입여부
						GLS_WORK_CD,  		--	유리근무유형[PAY_GLS_WORK_CD]
						JOB_CD  			--	직무코드[PHM_JOB_CD]
					   )
             			SELECT 
             				NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    						T1.*
						 FROM (
								 SELECT @an_pay_ymd_id 		AS PAY_YMD_ID, 		--	급여일자ID
										A.EMP_ID  			AS EMP_ID,			--	사원ID
										C.SALARY_TYPE_CD 	AS SALARY_TYPE_CD,	--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
										--C.PAY_BAS_TYPE_CD	AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]	
										C.BP12				AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]
										'' 					AS SUB_COMPANY_CD,	--	서브회사코드
										E.PAY_GROUP 		AS PAY_GROUP_CD,	--	급여그룹
										DBO.F_ORM_ORG_BIZ(dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd,'PAY') AS PAY_BIZ_CD,	--	급여사업장코드
										DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd) AS RES_BIZ_CD,	--	지방세사업장코드										
										--DBO.F_ORM_ORG_BIZ(A.ORG_ID,@d_std_ymd,'PAY') AS PAY_BIZ_CD,		--	급여사업장코드										
										--DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,A.ORG_ID,@d_std_ymd) AS RES_BIZ_CD,		--	지방세사업장코드
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS ORG_ID,			--	발령부서ID
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS PAY_ORG_ID,		--	급여부서ID
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'POS_CD') AS POS_CD,			--	직위코드[PHM_POS_CD]										
										--A.ORG_ID 			AS ORG_ID,			--	발령부서ID
										--A.ORG_ID 			AS PAY_ORG_ID,		--	급여부서ID
										--A.POS_CD			AS POS_CD,			--	직위코드[PHM_POS_CD]										
										A.MGR_TYPE_CD		AS MGR_TYPE_CD,		--  관리구분[PHM_MR_TYPE_CD]
										A.JOB_POSITION_CD	AS JOB_POSITION_CD,	--	직종코드
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'DUTY_CD') AS DUTY_CD,       --  직책코드[PHM_DUTY_CD]
						                --A.DUTY_CD           AS DUTY_CD,         --  직책코드[PHM_DUTY_CD]
										DBO.F_ORM_ORG_COST(A.COMPANY_CD,A.EMP_ID,@d_std_ymd,'1')		AS ACC_CD,			--	코스트센터(ORM_COST_ORG_CD)
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
										--C.CONT_TIME 		AS CONT_TIME,		--	소정근로시간
										C.BP05				AS CONT_TIME,		--	소정근로시간
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
										RETR_YMD 			AS RETR_YMD,		--	퇴직금기산일자
										'' 					AS NOTE, 			--	비고
										@an_mod_user_id		AS MOD_USER_ID, 	--	변경자
										GETDATE() 			AS MOD_DATE, 		--	변경일시
										'KST' 				AS TZ_CD, 			--	타임존코드
										GETDATE() 			AS TZ_DATE,  		--	타임존일시
										B.ULSAN_YN 			AS ULSAN_YN,  		--	울산호봉적용여부
										B.INS_TRANS_YN		AS INS_TRANS_YN,  	--	동원산업전입여부
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
											SELECT A1.PAY_YMD, A1.PAY_YM, A1.PAY_TYPE_CD,B1.SALARY_TYPE_CD, C1.PAY_TERM_TYPE_CD, C1.STA_YMD , C1.END_YMD
											FROM PAY_PAY_YMD A1
											INNER JOIN PAY_PAY_YMD_DTL B1
													ON  B1.PAY_YMD_ID = A1.PAY_YMD_ID
											INNER JOIN PAY_PAY_YMD_DTL_TERM C1
													ON  C1.PAYYMD_DTL_ID = B1.PAYYMD_DTL_ID
											INNER JOIN FRM_CODE D1
													ON D1.CD = C1.PAY_TERM_TYPE_CD
											WHERE  1=1
											AND D1.LOCALE_CD = @av_locale_cd
											AND D1.COMPANY_CD = @av_company_cd
											AND D1.CD_KIND = 'PAY_TERM_TYPE_CD'
											AND D1.SYS_CD = '01'  --각 유형의 급여일자 기간만 읽어온다
											AND A1.PAY_YMD_ID = @an_pay_ymd_id
											AND A1.STD_YMD BETWEEN D1.STA_YMD AND D1.END_YMD			                 	
									) D ON 1=1
                 					--ON C.STA_YMD <= D.END_YMD
                 					--AND C.END_YMD >= D.STA_YMD
                 					--AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD
 								INNER JOIN CNM_CNT C ON (
							                              C.COMPANY_CD = @av_company_cd			
														AND C.EMP_ID = A.EMP_ID           
														AND C.STA_YMD <= D.END_YMD
					                 					AND C.END_YMD >= D.STA_YMD
					                 					AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD       
					                 					)
								INNER JOIN (
     										SELECT X1.PAY_TYPE_CD , Y1.PAY_GROUP ,X1.PAY_GROUP_ID
     										FROM PAY_GROUP_TYPE X1, PAY_GROUP Y1
     										WHERE 1 = 1
			                 				AND X1.COMPANY_CD = @av_company_cd
			                 				AND X1.PAY_GROUP_ID = Y1.PAY_GROUP_ID
		                 			  		) E
			               			ON E.PAY_TYPE_CD = D.PAY_TYPE_CD
								LEFT OUTER JOIN (
												 SELECT EMP_ID              ,     -- 사원ID
												   		BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
												   		ACCOUNT_NO               -- 계좌번호
												 FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
												 WHERE X.ACCOUNT_TYPE_CD  = CASE WHEN Y.ACCOUNT_TYPE_CD = X.ACCOUNT_TYPE_CD THEN Y.ACCOUNT_TYPE_CD ELSE '01' END  --계좌유형 같은게 있으면 읽어오고 없으면 급여계좌
												   AND Y.PAY_YMD_ID 		= @an_pay_ymd_id
												   --AND DBO.XF_TO_DATE(Y.PAY_YM + '01','YYYY-MM-DD') BETWEEN X.STA_YMD AND X.END_YMD
												   AND @d_std_ymd  BETWEEN X.STA_YMD AND X.END_YMD
												) Z ON B.EMP_ID = Z.EMP_ID
								 WHERE 1=1
								 AND A.COMPANY_CD = @av_company_cd
								 AND DBO.XF_NVL_D(A.RETIRE_YMD,'29991231') >= D.STA_YMD
								 AND ((@an_emp_id IS NULL) OR (A.EMP_ID = @an_emp_id))
								 AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)								  
								 AND A.IN_OFFI_YN ='Y'
								 AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
								 AND DBO.F_PAY_GROUP_CHK(E.PAY_GROUP_ID,A.EMP_ID,D.PAY_YMD) = E.PAY_GROUP_ID
								 AND NOT EXISTS	(
												 SELECT 'X'
                  								 FROM PAY_EXP_UPLOAD Z
                  								 WHERE Z.COMPANY_CD = @av_company_cd
                  								 AND Z.EMP_ID = A.EMP_ID
                  								 AND Z.PAY_EXP_CD = '301'  --급여제외자 제외
												 AND D.PAY_YM  BETWEEN Z.STA_YM AND Z.END_YM
                  								 )
								  ) T1		              
			END TRY
       
			BEGIN CATCH
       			SET @errornumber   = ERROR_NUMBER()
				SET @errormessage  = ERROR_MESSAGE()
	
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 생성시 오류발생[ERR]',
										  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
				IF @@TRANCOUNT > 0
					ROLLBACK WORK
				RETURN
			END CATCH

		END		

	/***********************************************************************************************************************************
    ** 명절상여 대상자선정 - 004
	** 지급시점의 재직자 정보를 생성한다
    ***********************************************************************************************************************************/		
	IF @v_pay_type_sys_cd = '004' 
	BEGIN				
			--대상자 INSERT
			BEGIN TRY
					INSERT INTO PAY_PAYROLL
					(
						PAY_PAYROLL_ID,		--	급여내역ID
						PAY_YMD_ID,			--	급여일자ID
						EMP_ID,				--	사원ID
						SALARY_TYPE_CD,		--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
						PAY_BAS_TYPE_CD,	--  기본급산정유형코드[PAY_BAS_TYPE_CD]	
						SUB_COMPANY_CD,		--	서브회사코드
						PAY_GROUP_CD,		--	급여그룹
						PAY_BIZ_CD,			--	급여사업장코드
						RES_BIZ_CD,			--	지방세사업장코드
						ORG_ID,				--	발령부서ID
						PAY_ORG_ID,			--	급여부서ID
						POS_CD,				--	직위코드[PHM_POS_CD]
						MGR_TYPE_CD	,		--  관리구분[PHM_MR_TYPE_CD]
						JOB_POSITION_CD,	--	직종코드
						DUTY_CD,            --  직책코드[PHM_DUTY_CD]
						ACC_CD,				--	코스트센터(ORM_COST_ORG_CD)
						PSUM,				--	지급집계(모든기지급포함)
						PSUM1,				--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
						PSUM2,				--	지급집계(모든기지급포함안함)
						DSUM,				--	공제집계
						TSUM,				--	세금집계
						REAL_AMT,			--	실지급액
						BANK_CD,			--	은행코드[PAY_BANK_CD]
						ACCOUNT_NO,			--	계좌번호
						FILLDT,				--	기표일
						POS_GRD_CD,			--	직급[PHM_POS_GRD_CD]
						PAY_GRADE,			--	호봉코드 [PHM_YEARNUM_CD]
						DTM_TYPE,			--	근태유형
						FILLNO,				--	전표번호
						NOTICE,				--	급여명세공지
						TAX_YMD,			--	원천징수신고일자
						FOREIGN_PSUM,		--	외화지급집계(모든기지급포함)
						FOREIGN_PSUM1,		--	외화지급집계(PSUM에서 급여성기지급 포함 안함)
						FOREIGN_PSUM2,		--	외화지급집계(모든기지급포함안함)
						FOREIGN_DSUM,		--	외화공제집계
						FOREIGN_TSUM,		--	외화세금집계
						FOREIGN_REAL_AMT,	--	외화실지급액
						CURRENCY_CD,		--	통화코드[PAY_CURRENCY_CD]
						TAX_SUBSIDY_YN,		--	세금보조여부
						TAX_FAMILY_CNT,		--	부양가족수
						FAM20_CNT,			--	20세이하자녀수
						FOREIGN_YN,			--	외국인여부
						PEAK_YN	,			--  임금피크대상여부
						PEAK_DATE,			--	임금피크적용일자
						PAY_METH_CD,		--	급여지급방식코드[PAY_METH_CD]
						PAY_EMP_CLS_CD,		--	고용유형코드[PAY_EMP_CLS_CD]
						CONT_TIME,			--	소정근로시간
						UNION_YN,			--	노조회비공제대상여부
						UNION_FULL_YN,		--	노조전임여부
						PAY_UNION_CD,		--	노조사업장코드[PAY_UNION_CD]
						FOREJOB_YN,			--	국외근로여부
						TRBNK_YN,			--	신협공제대상여부
						PROD_YN,			--	생산직여부
						ADV_YN,				--	선망가불금공제여부
						SMS_YN,				--	SMS발송여부
						EMAIL_YN,			--	E_MAIL발송여부
						WORK_YN,			--	근속수당지급여부
						WORK_YMD,			--	근속기산일자
						RETR_YMD,			--	퇴직금기산일자
						NOTE, 				--	비고
						MOD_USER_ID, 		--	변경자
						MOD_DATE, 			--	변경일시
						TZ_CD, 				--	타임존코드
						TZ_DATE,  			--	타임존일시
						ULSAN_YN,  			--	울산호봉적용여부
						INS_TRANS_YN,		--	동원산업전입여부
						GLS_WORK_CD,  		--	유리근무유형[PAY_GLS_WORK_CD]
						JOB_CD  			--	직무코드[PHM_JOB_CD]
					   )
             			SELECT 
             				NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    						T1.*
						 FROM (
								 SELECT @an_pay_ymd_id 		AS PAY_YMD_ID, 		--	급여일자ID
										A.EMP_ID  			AS EMP_ID,			--	사원ID
										C.SALARY_TYPE_CD 	AS SALARY_TYPE_CD,	--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
										--C.PAY_BAS_TYPE_CD	AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]	
										C.BP12				AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]
										'' 					AS SUB_COMPANY_CD,	--	서브회사코드
										E.PAY_GROUP 		AS PAY_GROUP_CD,	--	급여그룹
--										DBO.F_ORM_ORG_BIZ(A.ORG_ID,@d_std_ymd,'PAY') AS PAY_BIZ_CD,		--	급여사업장코드										
--										DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,A.ORG_ID,@d_std_ymd) AS RES_BIZ_CD,		--	지방세사업장코드
										DBO.F_ORM_ORG_BIZ(dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd,'PAY') AS PAY_BIZ_CD,	--	급여사업장코드
										DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd) AS RES_BIZ_CD,	--	지방세사업장코드										
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS ORG_ID,			--	발령부서ID
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS PAY_ORG_ID,		--	급여부서ID
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'POS_CD') AS POS_CD,			--	직위코드[PHM_POS_CD]										
										--A.ORG_ID 			AS ORG_ID,			--	발령부서ID
										--A.ORG_ID 			AS PAY_ORG_ID,		--	급여부서ID
										--A.POS_CD			AS POS_CD,			--	직위코드[PHM_POS_CD]
										A.MGR_TYPE_CD		AS MGR_TYPE_CD,		--  관리구분[PHM_MR_TYPE_CD]
										A.JOB_POSITION_CD	AS JOB_POSITION_CD,	--	직종코드
						                A.DUTY_CD           AS DUTY_CD,         --  직책코드[PHM_DUTY_CD]
										DBO.F_ORM_ORG_COST(A.COMPANY_CD,A.EMP_ID,@d_std_ymd,'1')		AS ACC_CD,			--	코스트센터(ORM_COST_ORG_CD)
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
										--C.CONT_TIME 		AS CONT_TIME,		--	소정근로시간
										C.BP05				AS CONT_TIME,		--	소정근로시간
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
											SELECT A1.PAY_YMD, A1.PAY_YM, A1.PAY_TYPE_CD,B1.SALARY_TYPE_CD, C1.PAY_TERM_TYPE_CD, C1.STA_YMD , C1.END_YMD
											FROM PAY_PAY_YMD A1
											INNER JOIN PAY_PAY_YMD_DTL B1
													ON  B1.PAY_YMD_ID = A1.PAY_YMD_ID
											INNER JOIN PAY_PAY_YMD_DTL_TERM C1
													ON  C1.PAYYMD_DTL_ID = B1.PAYYMD_DTL_ID
											INNER JOIN FRM_CODE D1
													ON D1.CD = C1.PAY_TERM_TYPE_CD
											WHERE  1=1
											AND D1.LOCALE_CD = @av_locale_cd
											AND D1.COMPANY_CD = @av_company_cd
											AND D1.CD_KIND = 'PAY_TERM_TYPE_CD'
											AND D1.SYS_CD = '01'  --각 유형의 급여일자 기간만 읽어온다
											AND A1.PAY_YMD_ID = @an_pay_ymd_id
											AND A1.STD_YMD BETWEEN D1.STA_YMD AND D1.END_YMD			                 	
									) D ON 1=1
                 					--ON C.STA_YMD <= D.END_YMD
                 					--AND C.END_YMD >= D.STA_YMD
                 					--AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD
 								INNER JOIN CNM_CNT C ON (
							                              C.COMPANY_CD = @av_company_cd			
														AND C.EMP_ID = A.EMP_ID           
														AND C.STA_YMD <= D.END_YMD
					                 					AND C.END_YMD >= D.STA_YMD
					                 					AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD       
					                 					)
								INNER JOIN (
     										SELECT X1.PAY_TYPE_CD , Y1.PAY_GROUP ,X1.PAY_GROUP_ID
     										FROM PAY_GROUP_TYPE X1, PAY_GROUP Y1
     										WHERE 1 = 1
			                 				  AND X1.COMPANY_CD = @av_company_cd
			                 				  AND X1.PAY_GROUP_ID = Y1.PAY_GROUP_ID
		                 			  		) E
			               			ON E.PAY_TYPE_CD = D.PAY_TYPE_CD
								LEFT OUTER JOIN (
												 SELECT EMP_ID              ,     -- 사원ID
												   		BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
												   		ACCOUNT_NO               -- 계좌번호
												 FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
												 WHERE X.ACCOUNT_TYPE_CD  = CASE WHEN Y.ACCOUNT_TYPE_CD = X.ACCOUNT_TYPE_CD THEN Y.ACCOUNT_TYPE_CD ELSE '01' END  --계좌유형 같은게 있으면 읽어오고 없으면 급여계좌
												   AND Y.PAY_YMD_ID 		= @an_pay_ymd_id
												   --AND DBO.XF_TO_DATE(Y.PAY_YM + '01','YYYY-MM-DD') BETWEEN X.STA_YMD AND X.END_YMD
												   AND @d_std_ymd  BETWEEN X.STA_YMD AND X.END_YMD
												) Z ON B.EMP_ID = Z.EMP_ID
								 WHERE 1=1
								 AND A.COMPANY_CD = @av_company_cd
								 AND DBO.XF_NVL_D(A.RETIRE_YMD,'29991231') >= D.STA_YMD
								 AND ((@an_emp_id IS NULL) OR (A.EMP_ID = @an_emp_id))
								 AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)								  
								 AND A.IN_OFFI_YN ='Y'
								 AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
								 AND DBO.F_PAY_GROUP_CHK(E.PAY_GROUP_ID,A.EMP_ID,D.PAY_YMD) = E.PAY_GROUP_ID								 
								  ) T1		              
			END TRY
       
			BEGIN CATCH
       			SET @errornumber   = ERROR_NUMBER()
				SET @errormessage  = ERROR_MESSAGE()
	
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 생성시 오류발생[ERR]',
										  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
				IF @@TRANCOUNT > 0
					ROLLBACK WORK
				RETURN
			END CATCH

		END				
	/***********************************************************************************************************************************
    ** 임원성과급 대상자선정 - 005
	**    => 계약자료의 급여유형이 임원이 직원을 대상으로 생성 한다
    ***********************************************************************************************************************************/
	IF @v_pay_type_sys_cd = '005' 
		BEGIN
			--대상자 INSERT
			BEGIN TRY
				INSERT INTO PAY_PAYROLL
				(
					PAY_PAYROLL_ID,		--	급여내역ID
					PAY_YMD_ID,			--	급여일자ID
					EMP_ID,				--	사원ID
					SALARY_TYPE_CD,		--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
					PAY_BAS_TYPE_CD,	--  기본급산정유형코드[PAY_BAS_TYPE_CD]	
					SUB_COMPANY_CD,		--	서브회사코드
					PAY_GROUP_CD,		--	급여그룹
					PAY_BIZ_CD,			--	급여사업장코드
					RES_BIZ_CD,			--	지방세사업장코드
					ORG_ID,				--	발령부서ID
					PAY_ORG_ID,			--	급여부서ID
					POS_CD,				--	직위코드[PHM_POS_CD]
					MGR_TYPE_CD	,		--  관리구분[PHM_MR_TYPE_CD]
					JOB_POSITION_CD,	--	직종코드
					DUTY_CD,            --  직책코드[PHM_DUTY_CD]
					ACC_CD,				--	코스트센터(ORM_COST_ORG_CD)
					PSUM,				--	지급집계(모든기지급포함)
					PSUM1,				--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
					PSUM2,				--	지급집계(모든기지급포함안함)
					DSUM,				--	공제집계
					TSUM,				--	세금집계
					REAL_AMT,			--	실지급액
					BANK_CD,			--	은행코드[PAY_BANK_CD]
					ACCOUNT_NO,			--	계좌번호
					FILLDT,				--	기표일
					POS_GRD_CD,			--	직급[PHM_POS_GRD_CD]
					PAY_GRADE,			--	호봉코드 [PHM_YEARNUM_CD]
					DTM_TYPE,			--	근태유형
					FILLNO,				--	전표번호
					NOTICE,				--	급여명세공지
					TAX_YMD,			--	원천징수신고일자
					FOREIGN_PSUM,		--	외화지급집계(모든기지급포함)
					FOREIGN_PSUM1,		--	외화지급집계(PSUM에서 급여성기지급 포함 안함)
					FOREIGN_PSUM2,		--	외화지급집계(모든기지급포함안함)
					FOREIGN_DSUM,		--	외화공제집계
					FOREIGN_TSUM,		--	외화세금집계
					FOREIGN_REAL_AMT,	--	외화실지급액
					CURRENCY_CD,		--	통화코드[PAY_CURRENCY_CD]
					TAX_SUBSIDY_YN,		--	세금보조여부
					TAX_FAMILY_CNT,		--	부양가족수
					FAM20_CNT,			--	20세이하자녀수
					FOREIGN_YN,			--	외국인여부
					PEAK_YN	,			--  임금피크대상여부
					PEAK_DATE,			--	임금피크적용일자
					PAY_METH_CD,		--	급여지급방식코드[PAY_METH_CD]
					PAY_EMP_CLS_CD,		--	고용유형코드[PAY_EMP_CLS_CD]
					CONT_TIME,			--	소정근로시간
					UNION_YN,			--	노조회비공제대상여부
					UNION_FULL_YN,		--	노조전임여부
					PAY_UNION_CD,		--	노조사업장코드[PAY_UNION_CD]
					FOREJOB_YN,			--	국외근로여부
					TRBNK_YN,			--	신협공제대상여부
					PROD_YN,			--	생산직여부
					ADV_YN,				--	선망가불금공제여부
					SMS_YN,				--	SMS발송여부
					EMAIL_YN,			--	E_MAIL발송여부
					WORK_YN,			--	근속수당지급여부
					WORK_YMD,			--	근속기산일자
					RETR_YMD,			--	퇴직금기산일자
					NOTE, 				--	비고
					MOD_USER_ID, 		--	변경자
					MOD_DATE, 			--	변경일시
					TZ_CD, 				--	타임존코드
					TZ_DATE,  			--	타임존일시
					ULSAN_YN,  			--	울산호봉적용여부
					INS_TRANS_YN,		--	동원산업전입여부
					GLS_WORK_CD,  		--	유리근무유형[PAY_GLS_WORK_CD]
					JOB_CD  			--	직무코드[PHM_JOB_CD]
					)
             		SELECT 
             			NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    					T1.*
						FROM (
								SELECT @an_pay_ymd_id 		AS PAY_YMD_ID, 		--	급여일자ID
									A.EMP_ID  			AS EMP_ID,			--	사원ID
									C.SALARY_TYPE_CD 	AS SALARY_TYPE_CD,	--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
									--C.PAY_BAS_TYPE_CD	AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]	
									C.BP12				AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]
									'' 					AS SUB_COMPANY_CD,	--	서브회사코드
									E.PAY_GROUP 		AS PAY_GROUP_CD,	--	급여그룹
									DBO.F_ORM_ORG_BIZ(dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd,'PAY') AS PAY_BIZ_CD,	--	급여사업장코드
									DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd) AS RES_BIZ_CD,	--	지방세사업장코드										
									--DBO.F_ORM_ORG_BIZ(A.ORG_ID,@d_std_ymd,'PAY') AS PAY_BIZ_CD,		--	급여사업장코드									
									--DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,A.ORG_ID,@d_std_ymd) AS RES_BIZ_CD,		--	지방세사업장코드
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS ORG_ID,			--	발령부서ID
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS PAY_ORG_ID,		--	급여부서ID
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'POS_CD') AS POS_CD,			--	직위코드[PHM_POS_CD]
									--A.ORG_ID 			AS ORG_ID,			--	발령부서ID
									--A.ORG_ID 			AS PAY_ORG_ID,		--	급여부서ID
									--A.POS_CD			AS POS_CD,			--	직위코드[PHM_POS_CD]
									A.MGR_TYPE_CD		AS MGR_TYPE_CD,		--  관리구분[PHM_MR_TYPE_CD]
									A.JOB_POSITION_CD	AS JOB_POSITION_CD,	--	직종코드
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'DUTY_CD') AS DUTY_CD,       --  직책코드[PHM_DUTY_CD]
						            --A.DUTY_CD           AS DUTY_CD,         --  직책코드[PHM_DUTY_CD]
									DBO.F_ORM_ORG_COST(A.COMPANY_CD,A.EMP_ID,@d_std_ymd,'1')	AS ACC_CD,			--	코스트센터(ORM_COST_ORG_CD)
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
									--C.CONT_TIME 		AS CONT_TIME,		--	소정근로시간
									C.BP05				AS CONT_TIME,		--	소정근로시간
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
									B.INS_TRANS_YN		AS INS_TRANS_YN,  	--	동원산업전입여부
									B.GLS_WORK_CD		AS GLS_WORK_CD,  	--	유리근무유형[PAY_GLS_WORK_CD]
									--A.JOB_CD  			AS JOB_CD			--	직무코드[PHM_JOB_CD]
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'JOB_CD') AS JOB_CD	--	직무코드[PHM_JOB_CD]
							FROM PHM_EMP A
							INNER JOIN PAY_PHM_EMP B ON B.EMP_ID = A.EMP_ID
		      --     			INNER JOIN (
					   --        			SELECT  S.EMP_ID, S.BP12 AS PAY_BAS_TYPE_CD, S.SALARY_TYPE_CD, S.STA_YMD, S.END_YMD, DBO.XF_TO_NUMBER(S.BP05) AS CONT_TIME
								--		FROM CNM_CNT S
								--		WHERE S.COMPANY_CD = @av_company_cd
								--		AND S.SALARY_TYPE_CD = '001'  --임원만 대상으로 생성한다
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
										SELECT A1.PAY_YMD, A1.PAY_YM, A1.PAY_TYPE_CD,B1.SALARY_TYPE_CD, C1.PAY_TERM_TYPE_CD, C1.STA_YMD , C1.END_YMD
										FROM PAY_PAY_YMD A1
										INNER JOIN PAY_PAY_YMD_DTL B1
												ON  B1.PAY_YMD_ID = A1.PAY_YMD_ID
										INNER JOIN PAY_PAY_YMD_DTL_TERM C1
												ON  C1.PAYYMD_DTL_ID = B1.PAYYMD_DTL_ID
										INNER JOIN FRM_CODE D1
												ON D1.CD = C1.PAY_TERM_TYPE_CD
										WHERE  1=1
										AND D1.LOCALE_CD = @av_locale_cd
										AND D1.COMPANY_CD = @av_company_cd
										AND D1.CD_KIND = 'PAY_TERM_TYPE_CD'
										AND D1.SYS_CD = '01'  --각 유형의 급여일자 기간만 읽어온다
										AND A1.PAY_YMD_ID = @an_pay_ymd_id
										AND A1.STD_YMD BETWEEN D1.STA_YMD AND D1.END_YMD
								) D ON 1=1
                 				--ON C.STA_YMD <= D.END_YMD
                 				--AND C.END_YMD >= D.STA_YMD
                 				--AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD
 							INNER JOIN CNM_CNT C ON (
							                            C.COMPANY_CD = @av_company_cd			
													AND C.EMP_ID = A.EMP_ID           
													AND C.STA_YMD <= D.END_YMD
					                 				AND C.END_YMD >= D.STA_YMD
					                 				AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD       
					                 				)
							INNER JOIN (
     									SELECT X1.PAY_TYPE_CD , Y1.PAY_GROUP ,X1.PAY_GROUP_ID
     									FROM PAY_GROUP_TYPE X1, PAY_GROUP Y1
     									WHERE 1 = 1
			                 				AND X1.COMPANY_CD = @av_company_cd
			                 				AND X1.PAY_GROUP_ID = Y1.PAY_GROUP_ID
		                 			  	) E
			               		ON E.PAY_TYPE_CD = D.PAY_TYPE_CD
							LEFT OUTER JOIN (
												SELECT  EMP_ID              ,     -- 사원ID
												   		BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
												   		ACCOUNT_NO                -- 계좌번호
												FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
												WHERE X.ACCOUNT_TYPE_CD  = CASE WHEN Y.ACCOUNT_TYPE_CD = X.ACCOUNT_TYPE_CD THEN Y.ACCOUNT_TYPE_CD ELSE '01' END  --계좌유형 같은게 있으면 읽어오고 없으면 급여계좌
												AND Y.PAY_YMD_ID 		= @an_pay_ymd_id
												--AND DBO.XF_TO_DATE(Y.PAY_YM + '01','YYYY-MM-DD') BETWEEN X.STA_YMD AND X.END_YMD
												AND @d_std_ymd  BETWEEN X.STA_YMD AND X.END_YMD
											) Z ON B.EMP_ID = Z.EMP_ID
								WHERE 1=1
								AND A.COMPANY_CD = @av_company_cd
								AND DBO.XF_NVL_D(A.RETIRE_YMD,'29991231') >= D.STA_YMD
								AND ((@an_emp_id IS NULL) OR (A.EMP_ID = @an_emp_id))
								AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)								
								AND A.IN_OFFI_YN ='Y'
								AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
								AND DBO.F_PAY_GROUP_CHK(E.PAY_GROUP_ID,A.EMP_ID,D.PAY_YMD) = E.PAY_GROUP_ID								
								) T1
			END TRY
       
			BEGIN CATCH
       			SET @errornumber   = ERROR_NUMBER()
				SET @errormessage  = ERROR_MESSAGE()
	
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 생성시 오류발생[ERR]',
										  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
				IF @@TRANCOUNT > 0
					ROLLBACK WORK
				RETURN
			END CATCH
		END
	/****************************************************************************************************************************************************
    ** 직원성과급 대상자선정 - 006
	**    => 직원성과급은 시스템에서 자동산정하는게 아니라 수작업 계산 후 업로드 한다. 따라서 계산을 한 후 최종 명단확정되면 확정된 명단을 등록
	**    => 만약 버튼을 클릭할 경우 임원성과급 대상자 생성기준과 같은 방법으로 급여형태를 임원 제외하고 다른 직원만 생성한다
    ****************************************************************************************************************************************************/
	IF @v_pay_type_sys_cd = '006'
		BEGIN
			--대상자 INSERT
			BEGIN TRY
				INSERT INTO PAY_PAYROLL
				(
					PAY_PAYROLL_ID,		--	급여내역ID
					PAY_YMD_ID,			--	급여일자ID
					EMP_ID,				--	사원ID
					SALARY_TYPE_CD,		--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
					PAY_BAS_TYPE_CD,	--  기본급산정유형코드[PAY_BAS_TYPE_CD]	
					SUB_COMPANY_CD,		--	서브회사코드
					PAY_GROUP_CD,		--	급여그룹
					PAY_BIZ_CD,			--	급여사업장코드
					RES_BIZ_CD,			--	지방세사업장코드
					ORG_ID,				--	발령부서ID
					PAY_ORG_ID,			--	급여부서ID
					POS_CD,				--	직위코드[PHM_POS_CD]
					MGR_TYPE_CD	,		--  관리구분[PHM_MR_TYPE_CD]
					JOB_POSITION_CD,	--	직종코드
					DUTY_CD,            --  직책코드[PHM_DUTY_CD]
					ACC_CD,				--	코스트센터(ORM_COST_ORG_CD)
					PSUM,				--	지급집계(모든기지급포함)
					PSUM1,				--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
					PSUM2,				--	지급집계(모든기지급포함안함)
					DSUM,				--	공제집계
					TSUM,				--	세금집계
					REAL_AMT,			--	실지급액
					BANK_CD,			--	은행코드[PAY_BANK_CD]
					ACCOUNT_NO,			--	계좌번호
					FILLDT,				--	기표일
					POS_GRD_CD,			--	직급[PHM_POS_GRD_CD]
					PAY_GRADE,			--	호봉코드 [PHM_YEARNUM_CD]
					DTM_TYPE,			--	근태유형
					FILLNO,				--	전표번호
					NOTICE,				--	급여명세공지
					TAX_YMD,			--	원천징수신고일자
					FOREIGN_PSUM,		--	외화지급집계(모든기지급포함)
					FOREIGN_PSUM1,		--	외화지급집계(PSUM에서 급여성기지급 포함 안함)
					FOREIGN_PSUM2,		--	외화지급집계(모든기지급포함안함)
					FOREIGN_DSUM,		--	외화공제집계
					FOREIGN_TSUM,		--	외화세금집계
					FOREIGN_REAL_AMT,	--	외화실지급액
					CURRENCY_CD,		--	통화코드[PAY_CURRENCY_CD]
					TAX_SUBSIDY_YN,		--	세금보조여부
					TAX_FAMILY_CNT,		--	부양가족수
					FAM20_CNT,			--	20세이하자녀수
					FOREIGN_YN,			--	외국인여부
					PEAK_YN	,			--  임금피크대상여부
					PEAK_DATE,			--	임금피크적용일자
					PAY_METH_CD,		--	급여지급방식코드[PAY_METH_CD]
					PAY_EMP_CLS_CD,		--	고용유형코드[PAY_EMP_CLS_CD]
					CONT_TIME,			--	소정근로시간
					UNION_YN,			--	노조회비공제대상여부
					UNION_FULL_YN,		--	노조전임여부
					PAY_UNION_CD,		--	노조사업장코드[PAY_UNION_CD]
					FOREJOB_YN,			--	국외근로여부
					TRBNK_YN,			--	신협공제대상여부
					PROD_YN,			--	생산직여부
					ADV_YN,				--	선망가불금공제여부
					SMS_YN,				--	SMS발송여부
					EMAIL_YN,			--	E_MAIL발송여부
					WORK_YN,			--	근속수당지급여부
					WORK_YMD,			--	근속기산일자
					RETR_YMD,			--	퇴직금기산일자
					NOTE, 				--	비고
					MOD_USER_ID, 		--	변경자
					MOD_DATE, 			--	변경일시
					TZ_CD, 				--	타임존코드
					TZ_DATE,  			--	타임존일시
					ULSAN_YN,  			--	울산호봉적용여부
					INS_TRANS_YN,		--	동원산업전입여부
					GLS_WORK_CD,  		--	유리근무유형[PAY_GLS_WORK_CD]
					JOB_CD  			--	직무코드[PHM_JOB_CD]
					)
             		SELECT 
             			NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    					T1.*
						FROM (
								SELECT @an_pay_ymd_id 		AS PAY_YMD_ID, 		--	급여일자ID
									A.EMP_ID  			AS EMP_ID,			--	사원ID
									C.SALARY_TYPE_CD 	AS SALARY_TYPE_CD,	--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
									--C.PAY_BAS_TYPE_CD	AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]	
									C.BP12				AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]
									'' 					AS SUB_COMPANY_CD,	--	서브회사코드
									E.PAY_GROUP 		AS PAY_GROUP_CD,	--	급여그룹
									DBO.F_ORM_ORG_BIZ(dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd,'PAY') AS PAY_BIZ_CD,	--	급여사업장코드
									DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd) AS RES_BIZ_CD,	--	지방세사업장코드										
									
									--DBO.F_ORM_ORG_BIZ(A.ORG_ID,@d_std_ymd,'PAY') AS PAY_BIZ_CD,		--	급여사업장코드									
									--DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,A.ORG_ID,@d_std_ymd) AS RES_BIZ_CD,		--	지방세사업장코드
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS ORG_ID,			--	발령부서ID
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS PAY_ORG_ID,		--	급여부서ID
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'POS_CD') AS POS_CD,			--	직위코드[PHM_POS_CD]									
									--A.ORG_ID 			AS ORG_ID,			--	발령부서ID
									--A.ORG_ID 			AS PAY_ORG_ID,		--	급여부서ID
									--A.POS_CD			AS POS_CD,			--	직위코드[PHM_POS_CD]
									A.MGR_TYPE_CD		AS MGR_TYPE_CD,		--  관리구분[PHM_MR_TYPE_CD]
									A.JOB_POSITION_CD	AS JOB_POSITION_CD,	--	직종코드
						            A.DUTY_CD           AS DUTY_CD,         --  직책코드[PHM_DUTY_CD]
									DBO.F_ORM_ORG_COST(A.COMPANY_CD,A.EMP_ID,@d_std_ymd,'1')	AS ACC_CD,			--	코스트센터(ORM_COST_ORG_CD)
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
									--C.CONT_TIME 		AS CONT_TIME,		--	소정근로시간
									C.BP05				AS CONT_TIME,		--	소정근로시간
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
									B.INS_TRANS_YN		AS INS_TRANS_YN,  	--	동원산업전입여부
									B.GLS_WORK_CD		AS GLS_WORK_CD,  	--	유리근무유형[PAY_GLS_WORK_CD]
									--A.JOB_CD  			AS JOB_CD			--	직무코드[PHM_JOB_CD]
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'JOB_CD') AS JOB_CD	--	직무코드[PHM_JOB_CD]
							FROM PHM_EMP A
							INNER JOIN PAY_PHM_EMP B ON B.EMP_ID = A.EMP_ID
		      --     			INNER JOIN (
					   --        			SELECT  S.EMP_ID, S.BP12 AS PAY_BAS_TYPE_CD, S.SALARY_TYPE_CD, S.STA_YMD, S.END_YMD, DBO.XF_TO_NUMBER(S.BP05) AS CONT_TIME
								--		FROM CNM_CNT S
								--		WHERE S.COMPANY_CD = @av_company_cd
								--		AND S.SALARY_TYPE_CD <> '001'  --임원만 제외한다
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
										SELECT A1.PAY_YMD, A1.PAY_YM, A1.PAY_TYPE_CD,B1.SALARY_TYPE_CD, C1.PAY_TERM_TYPE_CD, C1.STA_YMD , C1.END_YMD
										FROM PAY_PAY_YMD A1
										INNER JOIN PAY_PAY_YMD_DTL B1
												ON  B1.PAY_YMD_ID = A1.PAY_YMD_ID
										INNER JOIN PAY_PAY_YMD_DTL_TERM C1
												ON  C1.PAYYMD_DTL_ID = B1.PAYYMD_DTL_ID
										INNER JOIN FRM_CODE D1
												ON D1.CD = C1.PAY_TERM_TYPE_CD
										WHERE  1=1
										AND D1.LOCALE_CD = @av_locale_cd
										AND D1.COMPANY_CD = @av_company_cd
										AND D1.CD_KIND = 'PAY_TERM_TYPE_CD'
										AND D1.SYS_CD = '01'  --각 유형의 급여일자 기간만 읽어온다
										AND A1.PAY_YMD_ID = @an_pay_ymd_id
										AND A1.STD_YMD BETWEEN D1.STA_YMD AND D1.END_YMD
								) D ON 1=1
                 				--ON C.STA_YMD <= D.END_YMD
                 				--AND C.END_YMD >= D.STA_YMD
                 				--AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD
 							INNER JOIN CNM_CNT C ON (
							                            C.COMPANY_CD = @av_company_cd			
													AND C.EMP_ID = A.EMP_ID           
													AND C.STA_YMD <= D.END_YMD
					                 				AND C.END_YMD >= D.STA_YMD
					                 				AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD       
					                 				)
							INNER JOIN (
     									SELECT X1.PAY_TYPE_CD , Y1.PAY_GROUP ,X1.PAY_GROUP_ID
     									FROM PAY_GROUP_TYPE X1, PAY_GROUP Y1
     									WHERE 1 = 1
			                 				AND X1.COMPANY_CD = @av_company_cd
			                 				AND X1.PAY_GROUP_ID = Y1.PAY_GROUP_ID
		                 			  	) E
			               		ON E.PAY_TYPE_CD = D.PAY_TYPE_CD
							LEFT OUTER JOIN (
												SELECT  EMP_ID              ,     -- 사원ID
												   		BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
												   		ACCOUNT_NO                -- 계좌번호
												FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
												WHERE X.ACCOUNT_TYPE_CD  = CASE WHEN Y.ACCOUNT_TYPE_CD = X.ACCOUNT_TYPE_CD THEN Y.ACCOUNT_TYPE_CD ELSE '01' END  --계좌유형 같은게 있으면 읽어오고 없으면 급여계좌
												AND Y.PAY_YMD_ID 		= @an_pay_ymd_id
												AND Y.STD_YMD BETWEEN X.STA_YMD AND X.END_YMD
											) Z ON B.EMP_ID = Z.EMP_ID
								WHERE 1=1
								AND A.COMPANY_CD = @av_company_cd
								AND DBO.XF_NVL_D(A.RETIRE_YMD,'29991231') >= D.STA_YMD
								AND ((@an_emp_id IS NULL) OR (A.EMP_ID = @an_emp_id))
								AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)								
								AND A.IN_OFFI_YN = 'Y'
								AND A.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
								AND DBO.F_PAY_GROUP_CHK(E.PAY_GROUP_ID,A.EMP_ID,D.PAY_YMD) = E.PAY_GROUP_ID
								) T1
			END TRY
       
			BEGIN CATCH
       			SET @errornumber   = ERROR_NUMBER()
				SET @errormessage  = ERROR_MESSAGE()
	
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 생성시 오류발생[ERR]',
										  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
				IF @@TRANCOUNT > 0
					ROLLBACK WORK
				RETURN
			END CATCH
		END
	/***********************************************************************************************************************************
    ** 퇴직월급여 대상자선정 - 007
	** 전월퇴직자만 자동 생성한다
    ***********************************************************************************************************************************/		
	IF @v_pay_type_sys_cd = '007'
		BEGIN
			
			--퇴직월 급여계산시 전월정기급여를 재계산 또는 정기급여 + 퇴직원급여 합산하여 계산할수 있으므로 해당 급여그룹의 정기급여 지급구분을 읽어온다
			BEGIN

				SELECT  @v_retro_pay_type_cd = Y.PAY_TYPE_CD
				FROM PAY_GROUP_TYPE X
				INNER JOIN PAY_GROUP_TYPE Y ON X.PAY_GROUP_ID = Y.PAY_GROUP_ID
				INNER JOIN FRM_CODE C ON (C.LOCALE_CD = @av_locale_cd
										AND C.COMPANY_CD = @av_company_cd
										AND C.CD_KIND = 'PAY_TYPE_CD'
										AND GETDATE() BETWEEN C.STA_YMD AND C.END_YMD						
										AND Y.PAY_TYPE_CD = C.CD
										AND C.SYS_CD = '001'  --지급유형이 급여인 자료를 읽어온다
										)
				WHERE 1 = 1
				AND X.COMPANY_CD = @av_company_cd
				AND X.PAY_TYPE_CD = @v_pay_type_cd

				IF (@@ROWCOUNT < 1)			
					BEGIN
						SET @v_retro_pay_type_cd = 'X'
					END

			END

			--대상자 INSERT
			BEGIN TRY
					INSERT INTO PAY_PAYROLL
					(
						PAY_PAYROLL_ID,		--	급여내역ID
						PAY_YMD_ID,			--	급여일자ID
						EMP_ID,				--	사원ID
						SALARY_TYPE_CD,		--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
						PAY_BAS_TYPE_CD,	--  기본급산정유형코드[PAY_BAS_TYPE_CD]	
						SUB_COMPANY_CD,		--	서브회사코드
						PAY_GROUP_CD,		--	급여그룹
						PAY_BIZ_CD,			--	급여사업장코드
						RES_BIZ_CD,			--	지방세사업장코드
						ORG_ID,				--	발령부서ID
						PAY_ORG_ID,			--	급여부서ID
						POS_CD,				--	직위코드[PHM_POS_CD]
						MGR_TYPE_CD	,		--  관리구분[PHM_MR_TYPE_CD]
						JOB_POSITION_CD,	--	직종코드
						DUTY_CD,            --  직책코드[PHM_DUTY_CD]
						ACC_CD,				--	코스트센터(ORM_COST_ORG_CD)
						PSUM,				--	지급집계(모든기지급포함)
						PSUM1,				--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
						PSUM2,				--	지급집계(모든기지급포함안함)
						DSUM,				--	공제집계
						TSUM,				--	세금집계
						REAL_AMT,			--	실지급액
						BANK_CD,			--	은행코드[PAY_BANK_CD]
						ACCOUNT_NO,			--	계좌번호
						FILLDT,				--	기표일
						POS_GRD_CD,			--	직급[PHM_POS_GRD_CD]
						PAY_GRADE,			--	호봉코드 [PHM_YEARNUM_CD]
						DTM_TYPE,			--	근태유형
						FILLNO,				--	전표번호
						NOTICE,				--	급여명세공지
						TAX_YMD,			--	원천징수신고일자
						FOREIGN_PSUM,		--	외화지급집계(모든기지급포함)
						FOREIGN_PSUM1,		--	외화지급집계(PSUM에서 급여성기지급 포함 안함)
						FOREIGN_PSUM2,		--	외화지급집계(모든기지급포함안함)
						FOREIGN_DSUM,		--	외화공제집계
						FOREIGN_TSUM,		--	외화세금집계
						FOREIGN_REAL_AMT,	--	외화실지급액
						CURRENCY_CD,		--	통화코드[PAY_CURRENCY_CD]
						TAX_SUBSIDY_YN,		--	세금보조여부
						TAX_FAMILY_CNT,		--	부양가족수
						FAM20_CNT,			--	20세이하자녀수
						FOREIGN_YN,			--	외국인여부
						PEAK_YN	,			--  임금피크대상여부
						PEAK_DATE,			--	임금피크적용일자
						PAY_METH_CD,		--	급여지급방식코드[PAY_METH_CD]
						PAY_EMP_CLS_CD,		--	고용유형코드[PAY_EMP_CLS_CD]
						CONT_TIME,			--	소정근로시간
						UNION_YN,			--	노조회비공제대상여부
						UNION_FULL_YN,		--	노조전임여부
						PAY_UNION_CD,		--	노조사업장코드[PAY_UNION_CD]
						FOREJOB_YN,			--	국외근로여부
						TRBNK_YN,			--	신협공제대상여부
						PROD_YN,			--	생산직여부
						ADV_YN,				--	선망가불금공제여부
						SMS_YN,				--	SMS발송여부
						EMAIL_YN,			--	E_MAIL발송여부
						WORK_YN,			--	근속수당지급여부
						WORK_YMD,			--	근속기산일자
						RETR_YMD,			--	퇴직금기산일자
						NOTE, 				--	비고
						MOD_USER_ID, 		--	변경자
						MOD_DATE, 			--	변경일시
						TZ_CD, 				--	타임존코드
						TZ_DATE,  			--	타임존일시
						ULSAN_YN,  			--	울산호봉적용여부
						INS_TRANS_YN,		--	동원산업전입여부
						GLS_WORK_CD,  		--	유리근무유형[PAY_GLS_WORK_CD]
						JOB_CD  			--	직무코드[PHM_JOB_CD]
					   )
             			SELECT 
             				NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    						T1.*
						 FROM (
								 SELECT @an_pay_ymd_id 		AS PAY_YMD_ID, 		--	급여일자ID
										A.EMP_ID  			AS EMP_ID,			--	사원ID
										C.SALARY_TYPE_CD 	AS SALARY_TYPE_CD,	--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
										--C.PAY_BAS_TYPE_CD	AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]	
										C.BP12				AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]
										'' 					AS SUB_COMPANY_CD,	--	서브회사코드
										E.PAY_GROUP 		AS PAY_GROUP_CD,	--	급여그룹
										DBO.F_ORM_ORG_BIZ(dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd,'PAY') AS PAY_BIZ_CD,	--	급여사업장코드
										DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd) AS RES_BIZ_CD,	--	지방세사업장코드										

										--DBO.F_ORM_ORG_BIZ(A.ORG_ID,@d_std_ymd,'PAY') AS PAY_BIZ_CD,		--	급여사업장코드										
										--DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,A.ORG_ID,@d_std_ymd) AS RES_BIZ_CD,		--	지방세사업장코드

										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS ORG_ID,			--	발령부서ID
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS PAY_ORG_ID,		--	급여부서ID
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'POS_CD') AS POS_CD,			--	직위코드[PHM_POS_CD]										
										--A.ORG_ID 			AS ORG_ID,			--	발령부서ID
										--A.ORG_ID 			AS PAY_ORG_ID,		--	급여부서ID
										--A.POS_CD			AS POS_CD,			--	직위코드[PHM_POS_CD]
										A.MGR_TYPE_CD		AS MGR_TYPE_CD,		--  관리구분[PHM_MR_TYPE_CD]
										A.JOB_POSITION_CD	AS JOB_POSITION_CD,	--	직종코드
						                A.DUTY_CD           AS DUTY_CD,         --  직책코드[PHM_DUTY_CD]
										DBO.F_ORM_ORG_COST(A.COMPANY_CD,A.EMP_ID,@d_std_ymd,'1')	AS ACC_CD,			--	코스트센터(ORM_COST_ORG_CD)
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
										'KRW' 				AS CURRENCY_CD,		--	통화코드[PAY_CURRENCY_CD]
										'' 					AS TAX_SUBSIDY_YN,	--	세금보조여부
										B.TAX_FAMILY_CNT 	AS TAX_FAMILY_CNT,	--	부양가족수
										B.FAM20_CNT 		AS FAM20_CNT,		--	20세이하자녀수
										B.FOREIGN_YN 		AS FOREIGN_YN,		--	외국인여부
										CASE WHEN ISNULL(B.PEAK_YMD,'19000101') ='19000101' THEN 'N' ELSE 'Y' END AS PEAK_YN	,--임금피크대상여부
										B.PEAK_YMD 			AS PEAK_DATE,		--	임금피크적용일자
										B.PAY_METH_CD 		AS PAY_METH_CD,		--	급여지급방식코드[PAY_METH_CD]
										B.EMP_CLS_CD 		AS PAY_EMP_CLS_CD,	--	고용유형코드[PAY_EMP_CLS_CD]
										--C.CONT_TIME 		AS CONT_TIME,		--	소정근로시간
										C.BP05				AS CONT_TIME,		--	소정근로시간
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
										B.INS_TRANS_YN		AS INS_TRANS_YN,  	--	동원산업전입여부
										B.GLS_WORK_CD		AS GLS_WORK_CD,  	--	유리근무유형[PAY_GLS_WORK_CD]
										--A.JOB_CD  			AS JOB_CD			--	직무코드[PHM_JOB_CD]
										dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'JOB_CD') AS JOB_CD	--	직무코드[PHM_JOB_CD]
								FROM PHM_EMP A
								INNER JOIN PAY_PHM_EMP B ON B.EMP_ID = A.EMP_ID
		       --    				INNER JOIN (
					    --       				SELECT  S.EMP_ID, S.BP12 AS PAY_BAS_TYPE_CD, S.SALARY_TYPE_CD, S.STA_YMD, S.END_YMD, DBO.XF_TO_NUMBER(S.BP05) AS CONT_TIME
									--					FROM CNM_CNT S
									--					WHERE S.COMPANY_CD = @av_company_cd
									--					AND S.STA_YMD = (
									--									SELECT  TOP 1 S1.STA_YMD
									--									FROM CNM_CNT S1
									--									WHERE S1.COMPANY_CD=S.COMPANY_CD
									--									AND S1.EMP_ID = S.EMP_ID 
									--									ORDER BY S1.STA_YMD DESC
									--									)
									--					) C 				
									--ON C.EMP_ID = A.EMP_ID
								INNER JOIN (
											SELECT A1.PAY_YMD, A1.PAY_YM,A1.PAY_TYPE_CD,B1.SALARY_TYPE_CD, C1.PAY_TERM_TYPE_CD, C1.STA_YMD , C1.END_YMD
											FROM PAY_PAY_YMD A1
											INNER JOIN PAY_PAY_YMD_DTL B1
													ON  B1.PAY_YMD_ID = A1.PAY_YMD_ID
											INNER JOIN PAY_PAY_YMD_DTL_TERM C1
													ON  C1.PAYYMD_DTL_ID = B1.PAYYMD_DTL_ID
											INNER JOIN FRM_CODE D1
													ON D1.CD = C1.PAY_TERM_TYPE_CD
											WHERE  1=1
											AND D1.LOCALE_CD = @av_locale_cd
											AND D1.COMPANY_CD = @av_company_cd
											AND D1.CD_KIND = 'PAY_TERM_TYPE_CD'
											AND D1.SYS_CD = '01'  --각 유형의 급여일자 기간만 읽어온다
											AND A1.STD_YMD BETWEEN D1.STA_YMD AND D1.END_YMD
											AND A1.PAY_YMD_ID  = @an_pay_ymd_id
									) D ON 1=1
                 					--ON C.STA_YMD <= D.END_YMD
                 					--AND C.END_YMD >= D.STA_YMD
                 					--AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD
 								INNER JOIN CNM_CNT C ON (
							                              C.COMPANY_CD = @av_company_cd			
														AND C.EMP_ID = A.EMP_ID           
														AND C.STA_YMD <= D.END_YMD
					                 					AND C.END_YMD >= D.STA_YMD
					                 					AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD       
					                 					)
								INNER JOIN (
     										SELECT X1.PAY_TYPE_CD , Y1.PAY_GROUP ,X1.PAY_GROUP_ID
     										FROM PAY_GROUP_TYPE X1, PAY_GROUP Y1
     										WHERE 1 = 1
			                 				  AND X1.COMPANY_CD = @av_company_cd
			                 				  AND X1.PAY_GROUP_ID = Y1.PAY_GROUP_ID
		                 			  		) E
			               			ON E.PAY_TYPE_CD = D.PAY_TYPE_CD
								LEFT OUTER JOIN (
												 SELECT EMP_ID              ,     -- 사원ID
												   		BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
												   		ACCOUNT_NO                -- 계좌번호
												 FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
												 WHERE X.ACCOUNT_TYPE_CD  = CASE WHEN Y.ACCOUNT_TYPE_CD = X.ACCOUNT_TYPE_CD THEN Y.ACCOUNT_TYPE_CD ELSE '01' END  --계좌유형 같은게 있으면 읽어오고 없으면 급여계좌
												   AND Y.PAY_YMD_ID 		= @an_pay_ymd_id
												   --AND DBO.XF_TO_DATE(Y.PAY_YM + '01','YYYY-MM-DD') BETWEEN X.STA_YMD AND X.END_YMD
												   AND Y.STD_YMD BETWEEN X.STA_YMD AND X.END_YMD
												) Z ON B.EMP_ID = Z.EMP_ID
								 WHERE 1=1
								 AND A.COMPANY_CD = @av_company_cd
								 AND A.RETIRE_YMD BETWEEN DBO.XF_MONTHADD(D.STA_YMD,-1) AND DBO.XF_MONTHADD(D.END_YMD,-1)  --개인별 급여기간을 확인하여 전월체크
								 AND ((@an_emp_id IS NULL) OR (A.EMP_ID = @an_emp_id))
								 AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)
								  -- AND A.ACC_CD IS NOT NULL
								 AND A.IN_OFFI_YN = 'N'
								 AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
								 AND DBO.F_PAY_GROUP_CHK(E.PAY_GROUP_ID,A.EMP_ID,D.PAY_YMD) = E.PAY_GROUP_ID
								 AND NOT EXISTS(SELECT 'X'  --퇴직월급여 이미 계산된 사람제외
												FROM PAY_PAY_YMD X
												INNER JOIN PAY_PAYROLL Y ON (Y.PAY_YMD_ID = X.PAY_YMD_ID AND Y.EMP_ID = A.EMP_ID)
												INNER JOIN FRM_CODE Z ON (Z.LOCALE_CD = @av_locale_cd
																		AND Z.COMPANY_CD = @av_company_cd
																		AND Z.CD_KIND = 'PAY_TYPE_CD'
																		AND GETDATE() BETWEEN Z.STA_YMD AND Z.END_YMD						
																		AND X.PAY_TYPE_CD = Z.CD
																		AND Z.SYS_CD = '007'  --퇴직월급여
																		)
												WHERE X.COMPANY_CD = @av_company_cd
												AND X.PAY_YMD BETWEEN  DBO.XF_MONTHADD(D.STA_YMD,-2) AND D.END_YMD  --최근2달 기간을 조회한다
												)
								 --AND NOT EXISTS	(
									--			 SELECT 'X'
         --         								 FROM PAY_EXP_UPLOAD Z
         --         								 WHERE Z.COMPANY_CD = @av_company_cd
         --         								 AND Z.EMP_ID = A.EMP_ID
         --         								 AND Z.PAY_EXP_CD = '301'  --급여제외자 제외
         --         								 )
								  ) T1
			END TRY
       
			BEGIN CATCH
       			SET @errornumber   = ERROR_NUMBER()
				SET @errormessage  = ERROR_MESSAGE()
	
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 입력시 오류발생[ERR]', @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
				IF @@TRANCOUNT > 0
					ROLLBACK WORK
				RETURN
			END CATCH


			--전월급여일자 ID 정보를 읽어온다
			SELECT @n_pre_pay_ymd_id = DBO.F_PAY_GET_PAY_ID(@av_company_cd,@v_retro_pay_type_cd,@v_pre_pay_ym)

			IF @n_pre_pay_ymd_id <> 0
			
			BEGIN

				--전월퇴직자 급여지급이후 퇴직을 했을수 있으므로 재계산하여 정산한다
				BEGIN TRY
					INSERT INTO PAY_RETRO_PAY_YMD
					(
						PAY_RETRO_PAY_YMD_ID,	--	개인별소급급여일자ID
						PAY_YMD_ID,				--	급여일자ID
						EMP_ID,					--	사원ID
						SALARY_TYPE_CD,			--	급여유형[PAY_SALARY_TYPE_CD]
						RETRO_PAY_YMD_ID,		--	소급대상급여일자ID
						ALL_YN,					--	모든항목여부
						APPLY_YN,				--	적용여부
						RETRO_NOTE,				--	소급사유
						NOTE,					--	비고
						MOD_USER_ID,			--	변경자
						MOD_DATE,				--	변경일시
						TZ_CD,					--	타임존코드
						TZ_DATE					--	타임존일시
					)
					SELECT
						NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_RETRO_PAY_YMD_ID,	--개인별소급급여일자ID
						@an_pay_ymd_id			AS PAY_YMD_ID,		--	급여일자ID
						A.EMP_ID				AS EMP_ID,			--	사원ID
						A.SALARY_TYPE_CD		AS SALARY_TYPE_CD,	--	급여유형[PAY_SALARY_TYPE_CD]
						@n_pre_pay_ymd_id		AS RETRO_PAY_YMD_ID,--	소급대상급여일자ID
						'N'						AS ALL_YN,			--	모든항목여부
						'Y'						AS APPLY_YN,		--	적용여부
						'전월 퇴직자 자동생성'	AS RETRO_NOTE,		--	소급사유
						''						AS NOTE,			--	비고
						@an_mod_user_id			AS MOD_USER_ID, 	--	변경자
						GETDATE() 				AS MOD_DATE, 		--	변경일시
						'KST' 					AS TZ_CD, 			--	타임존코드
						GETDATE() 				AS TZ_DATE  		--	타임존일시
					FROM PAY_PAYROLL A, PHM_EMP B,
									(
									SELECT  B1.SALARY_TYPE_CD,C1.PAY_TERM_TYPE_CD,C1.STA_YMD,C1.END_YMD
									FROM PAY_PAY_YMD A1
									INNER JOIN PAY_PAY_YMD_DTL B1 ON A1.PAY_YMD_ID = B1.PAY_YMD_ID
									INNER JOIN PAY_PAY_YMD_DTL_TERM C1 ON B1.PAYYMD_DTL_ID = C1.PAYYMD_DTL_ID
									WHERE C1.PAY_TERM_TYPE_CD IN (
																	SELECT X.CD
																	FROM FRM_CODE X
																	WHERE 1=1
																	AND X.LOCALE_CD  = @av_locale_cd
																	AND X.COMPANY_CD = @av_company_cd
																	AND X.CD_KIND 		= 'PAY_TERM_TYPE_CD'
																	AND X.SYS_CD 		= '01'  -- 급여일자 유형이 급여기간만 읽어온다(공통코드 관리 시스템코드참조)
																	AND A1.PAY_YMD 		BETWEEN X.STA_YMD AND X.END_YMD	  											 
																	)				
									AND A1.PAY_YMD_ID = @an_pay_ymd_id
									AND A1.COMPANY_CD = @av_company_cd	
									) C
					WHERE A.PAY_YMD_ID = @an_pay_ymd_id
					AND A.EMP_ID = B.EMP_ID
					AND C.SALARY_TYPE_CD = A.SALARY_TYPE_CD
					AND B.RETIRE_YMD BETWEEN dbo.XF_MONTHADD(C.STA_YMD, -1) AND dbo.XF_MONTHADD(C.END_YMD, -1)	--급여일 이후 퇴직일자에 상관없이 다시 한번 재계산 하도록 체크한다
					--AND EXISTS(  --전월퇴직자이면 급여계산 여부와 상관없이 무조건 대상자로 생성한다(계산되었으면 차액정산이 있을 수도 있고 정기급여 계산없이 퇴직월 급여에서 합산하여 처리할 수도 있음)
					--			SELECT 1
					--			FROM PAY_PAYROLL X
					--			WHERE X.PAY_YMD_ID = @n_pre_pay_ymd_id
					--			AND X.EMP_ID = A.EMP_ID
					--			)
					AND NOT EXISTS  --이미 만들어진 사람은 제외한다
								(
									SELECT 1
									FROM PAY_RETRO_PAY_YMD X
									WHERE X.PAY_YMD_ID = @an_pay_ymd_id
									AND X.EMP_ID = A.EMP_ID
									AND X.SALARY_TYPE_CD = A.SALARY_TYPE_CD
									AND X.RETRO_PAY_YMD_ID = @n_pre_pay_ymd_id
								)
				END TRY

				BEGIN CATCH
       				SET @errornumber   = ERROR_NUMBER()
					SET @errormessage  = ERROR_MESSAGE()
	
					SET @av_ret_code    = 'FAILURE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG(' 전월퇴사자 소급일자등록 오류발생[ERR]', @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
					IF @@TRANCOUNT > 0
						ROLLBACK WORK
					RETURN

				END CATCH
				
				
				--소급일자에 대한 대상자정보 생성
				BEGIN
					EXECUTE P_PAY_MST_CHANGE_RETRO_PAYROLL 
												@av_company_cd ,			-- 인사영역
												@av_locale_cd,				-- 지역코드									
												@an_pay_ymd_id,				-- 급여일자									
			                  					@an_mod_user_id,            -- 변경자
 												@av_ret_code	  OUTPUT,   -- SUCCESS!/FAILURE!
												@av_ret_message   OUTPUT    -- 결과메시지
				END
			
				IF @av_ret_code = 'FAILURE!' 
				   BEGIN
						  SET @av_ret_code = 'FAILURE!' 
						  SET @av_ret_message = @av_ret_message 
						  RETURN
				   END

			END

		END
	/***********************************************************************************************************************************
    ** 연차수당 대상자선정 - 008
    ***********************************************************************************************************************************/

	/***********************************************************************************************************************************
    ** 소급급여 대상자선정 - 009
	** 소급대상자 정의된 사람들만 생성한다
    ***********************************************************************************************************************************/		
	IF @v_pay_type_sys_cd = '009'
		BEGIN
			--대상자 INSERT
			BEGIN TRY
				INSERT INTO PAY_PAYROLL
				(
					PAY_PAYROLL_ID,		--	급여내역ID
					PAY_YMD_ID,			--	급여일자ID
					EMP_ID,				--	사원ID
					SALARY_TYPE_CD,		--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
					PAY_BAS_TYPE_CD,	--  기본급산정유형코드[PAY_BAS_TYPE_CD]	
					SUB_COMPANY_CD,		--	서브회사코드
					PAY_GROUP_CD,		--	급여그룹
					PAY_BIZ_CD,			--	급여사업장코드
					RES_BIZ_CD,			--	지방세사업장코드
					ORG_ID,				--	발령부서ID
					PAY_ORG_ID,			--	급여부서ID
					POS_CD,				--	직위코드[PHM_POS_CD]
					MGR_TYPE_CD	,		--  관리구분[PHM_MR_TYPE_CD]
					JOB_POSITION_CD,	--	직종코드
					DUTY_CD,            --  직책코드[PHM_DUTY_CD]
					ACC_CD,				--	코스트센터(ORM_COST_ORG_CD)
					PSUM,				--	지급집계(모든기지급포함)
					PSUM1,				--	지급집계(PSUM에서 급여성기지급 포함 안함, 연말정산에서 사용)
					PSUM2,				--	지급집계(모든기지급포함안함)
					DSUM,				--	공제집계
					TSUM,				--	세금집계
					REAL_AMT,			--	실지급액
					BANK_CD,			--	은행코드[PAY_BANK_CD]
					ACCOUNT_NO,			--	계좌번호
					FILLDT,				--	기표일
					POS_GRD_CD,			--	직급[PHM_POS_GRD_CD]
					PAY_GRADE,			--	호봉코드 [PHM_YEARNUM_CD]
					DTM_TYPE,			--	근태유형
					FILLNO,				--	전표번호
					NOTICE,				--	급여명세공지
					TAX_YMD,			--	원천징수신고일자
					FOREIGN_PSUM,		--	외화지급집계(모든기지급포함)
					FOREIGN_PSUM1,		--	외화지급집계(PSUM에서 급여성기지급 포함 안함)
					FOREIGN_PSUM2,		--	외화지급집계(모든기지급포함안함)
					FOREIGN_DSUM,		--	외화공제집계
					FOREIGN_TSUM,		--	외화세금집계
					FOREIGN_REAL_AMT,	--	외화실지급액
					CURRENCY_CD,		--	통화코드[PAY_CURRENCY_CD]
					TAX_SUBSIDY_YN,		--	세금보조여부
					TAX_FAMILY_CNT,		--	부양가족수
					FAM20_CNT,			--	20세이하자녀수
					FOREIGN_YN,			--	외국인여부
					PEAK_YN	,			--  임금피크대상여부
					PEAK_DATE,			--	임금피크적용일자
					PAY_METH_CD,		--	급여지급방식코드[PAY_METH_CD]
					PAY_EMP_CLS_CD,		--	고용유형코드[PAY_EMP_CLS_CD]
					CONT_TIME,			--	소정근로시간
					UNION_YN,			--	노조회비공제대상여부
					UNION_FULL_YN,		--	노조전임여부
					PAY_UNION_CD,		--	노조사업장코드[PAY_UNION_CD]
					FOREJOB_YN,			--	국외근로여부
					TRBNK_YN,			--	신협공제대상여부
					PROD_YN,			--	생산직여부
					ADV_YN,				--	선망가불금공제여부
					SMS_YN,				--	SMS발송여부
					EMAIL_YN,			--	E_MAIL발송여부
					WORK_YN,			--	근속수당지급여부
					WORK_YMD,			--	근속기산일자
					RETR_YMD,			--	퇴직금기산일자
					NOTE, 				--	비고
					MOD_USER_ID, 		--	변경자
					MOD_DATE, 			--	변경일시
					TZ_CD, 				--	타임존코드
					TZ_DATE,  			--	타임존일시
					ULSAN_YN,  			--	울산호봉적용여부
					INS_TRANS_YN,		--	동원산업전입여부
					GLS_WORK_CD,  		--	유리근무유형[PAY_GLS_WORK_CD]
					JOB_CD  			--	직무코드[PHM_JOB_CD]
					)
             		SELECT 
             			NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    					T1.*
						FROM (
								SELECT @an_pay_ymd_id 		AS PAY_YMD_ID, 		--	급여일자ID
									A.EMP_ID  			AS EMP_ID,			--	사원ID
									C.SALARY_TYPE_CD 	AS SALARY_TYPE_CD,	--	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
									--C.PAY_BAS_TYPE_CD	AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]	
									C.BP12				AS PAY_BAS_TYPE_CD,	--	기본급산정유형코드[PAY_BAS_TYPE_CD]
									'' 					AS SUB_COMPANY_CD,	--	서브회사코드
									E.PAY_GROUP 		AS PAY_GROUP_CD,	--	급여그룹
									DBO.F_ORM_ORG_BIZ(dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd,'PAY') AS PAY_BIZ_CD,	--	급여사업장코드
									DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID'),@d_std_ymd) AS RES_BIZ_CD,	--	지방세사업장코드																			
									--DBO.F_ORM_ORG_BIZ(A.ORG_ID,@d_std_ymd,'PAY') AS PAY_BIZ_CD,		--	급여사업장코드									
									--DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,A.ORG_ID,@d_std_ymd) AS RES_BIZ_CD,		--	지방세사업장코드

									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS ORG_ID,			--	발령부서ID
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'ORG_ID') AS PAY_ORG_ID,		--	급여부서ID
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'POS_CD') AS POS_CD,			--	직위코드[PHM_POS_CD]									
									--A.ORG_ID 			AS ORG_ID,			--	발령부서ID
									--A.ORG_ID 			AS PAY_ORG_ID,		--	급여부서ID
									--A.POS_CD			AS POS_CD,			--	직위코드[PHM_POS_CD]
									A.MGR_TYPE_CD		AS MGR_TYPE_CD,		--  관리구분[PHM_MR_TYPE_CD]
									A.JOB_POSITION_CD	AS JOB_POSITION_CD,	--	직종코드
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'DUTY_CD') AS DUTY_CD,       --  직책코드[PHM_DUTY_CD]
						            --A.DUTY_CD           AS DUTY_CD,         --  직책코드[PHM_DUTY_CD]
									DBO.F_ORM_ORG_COST(A.COMPANY_CD,A.EMP_ID,@d_std_ymd,'1')	AS ACC_CD,			--	코스트센터(ORM_COST_ORG_CD)
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
									--C.CONT_TIME 		AS CONT_TIME,		--	소정근로시간
									C.BP05				AS CONT_TIME,		--	소정근로시간
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
									B.INS_TRANS_YN		AS INS_TRANS_YN,  	--	동원산업전입여부
									B.GLS_WORK_CD		AS GLS_WORK_CD,  	--	유리근무유형[PAY_GLS_WORK_CD]
									--A.JOB_CD  			AS JOB_CD			--	직무코드[PHM_JOB_CD]
									dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',@d_std_ymd,'JOB_CD') AS JOB_CD	--	직무코드[PHM_JOB_CD]
							FROM PHM_EMP A
							INNER JOIN PAY_PHM_EMP B ON B.EMP_ID = A.EMP_ID
		      --     			INNER JOIN (
					   --        			SELECT  S.EMP_ID, S.BP12 AS PAY_BAS_TYPE_CD, S.SALARY_TYPE_CD, S.STA_YMD, S.END_YMD, DBO.XF_TO_NUMBER(S.BP05) AS CONT_TIME
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
										SELECT A1.PAY_YMD, A1.PAY_TYPE_CD,B1.SALARY_TYPE_CD, C1.PAY_TERM_TYPE_CD, C1.STA_YMD , C1.END_YMD
										FROM PAY_PAY_YMD A1
										INNER JOIN PAY_PAY_YMD_DTL B1
												ON  B1.PAY_YMD_ID = A1.PAY_YMD_ID
										INNER JOIN PAY_PAY_YMD_DTL_TERM C1
												ON  C1.PAYYMD_DTL_ID = B1.PAYYMD_DTL_ID
										INNER JOIN FRM_CODE D1
												ON D1.CD = C1.PAY_TERM_TYPE_CD
										WHERE  1=1
										AND D1.LOCALE_CD = @av_locale_cd
										AND D1.COMPANY_CD = @av_company_cd
										AND D1.CD_KIND = 'PAY_TERM_TYPE_CD'
										AND D1.SYS_CD = '01'  --각 유형의 급여일자 기간만 읽어온다
										AND A1.PAY_YMD_ID = @an_pay_ymd_id
										AND A1.STD_YMD BETWEEN D1.STA_YMD AND D1.END_YMD
								) D ON 1=1
                 				--ON C.STA_YMD <= D.END_YMD
                 				--AND C.END_YMD >= D.STA_YMD
                 				--AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD
 							INNER JOIN CNM_CNT C ON (
							                            C.COMPANY_CD = @av_company_cd			
													AND C.EMP_ID = A.EMP_ID           
													AND C.STA_YMD <= D.END_YMD
					                 				AND C.END_YMD >= D.STA_YMD
					                 				AND C.SALARY_TYPE_CD = D.SALARY_TYPE_CD       
					                 				)
							INNER JOIN (
     									SELECT X1.PAY_TYPE_CD , Y1.PAY_GROUP ,X1.PAY_GROUP_ID
     									FROM PAY_GROUP_TYPE X1, PAY_GROUP Y1
     									WHERE 1 = 1
			                 				AND X1.COMPANY_CD = @av_company_cd
			                 				AND X1.PAY_GROUP_ID = Y1.PAY_GROUP_ID
		                 			  	) E
			               		ON E.PAY_TYPE_CD = D.PAY_TYPE_CD
							LEFT OUTER JOIN (
												SELECT  EMP_ID              ,     -- 사원ID
												   		BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
												   		ACCOUNT_NO                -- 계좌번호
												FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
												WHERE X.ACCOUNT_TYPE_CD  = CASE WHEN Y.ACCOUNT_TYPE_CD = X.ACCOUNT_TYPE_CD THEN Y.ACCOUNT_TYPE_CD ELSE '01' END  --계좌유형 같은게 있으면 읽어오고 없으면 급여계좌
												AND Y.PAY_YMD_ID 		= @an_pay_ymd_id
												--AND DBO.XF_TO_DATE(Y.PAY_YM + '01','YYYY-MM-DD') BETWEEN X.STA_YMD AND X.END_YMD
												AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
											) Z ON B.EMP_ID = Z.EMP_ID
								WHERE 1=1
								AND A.COMPANY_CD = @av_company_cd
								AND DBO.XF_NVL_D(A.RETIRE_YMD,'29991231') >= D.STA_YMD
								AND ((@an_emp_id IS NULL) OR (A.EMP_ID = @an_emp_id))
								AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)
								-- AND A.ACC_CD IS NOT NULL
								-- AND B.IN_OFFI_YN ='Y'
								AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
								AND DBO.F_PAY_GROUP_CHK(E.PAY_GROUP_ID,A.EMP_ID,D.PAY_YMD) = E.PAY_GROUP_ID
								AND EXISTS(
											SELECT 'X'  --정기소급대상으로 등록된 사람만 체크
											FROM PAY_RETRO_PAY_YMD X
											WHERE X.PAY_YMD_ID = @an_pay_ymd_id
											AND X.EMP_ID = A.EMP_ID
											)
								) T1
			END TRY
       
			BEGIN CATCH
       			SET @errornumber   = ERROR_NUMBER()
				SET @errormessage  = ERROR_MESSAGE()
	
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 생성시 오류발생[ERR]',
										  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
				IF @@TRANCOUNT > 0
					ROLLBACK WORK
				RETURN
			END CATCH
		END
    -- ***********************************************************
    -- 작업 완료
    -- ***********************************************************
    SET @av_ret_code    = 'SUCCESS!';
    SET @av_ret_message  = DBO.F_FRM_ERRMSG('급여대상자 생성완료..',@v_program_id,  0900,  null, @an_mod_user_id);
    	
		
END -- 끝

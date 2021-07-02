SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_TBS_DEBIS_WITHHOLD](
		@av_company_cd			NVARCHAR(10),   -- 회사코드
		@av_hrtype_cd			NVARCHAR(10),	-- 인력유형
		@av_tax_kind_cd			NVARCHAR(10),	-- 원천세구분 (급여 : A1, 상여 : B1, 연말정산 : E1, 퇴직정산 : C1 ,중도정산 : D1)
		@av_close_ym			NVARCHAR(10),	-- 마감년월
		@ad_proc_date			DATE,			-- 처리일자
		@an_emp_id				NUMERIC(38),	-- 처리자
		@av_locale_cd			NVARCHAR(10),
		@av_tz_cd				NVARCHAR(10),    -- 타임존코드
		@an_mod_user_id			NUMERIC(18,0)  ,    -- 변경자 ID
		@av_ret_code			NVARCHAR(100)    OUTPUT,
		@av_ret_message			NVARCHAR(500)    OUTPUT
		)
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 원천세생성 - DEBIS
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_TBS_DEBIS_WITHHOLD
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 
    --<DOCLINE>   HISTORY     : 작성 2020.11.04
    --<DOCLINE> ***************************************************************************
SET NOCOUNT ON

DECLARE
	-- 사용 변수선언
	@v_emp_no					varchar(10),		 -- 작업자사번
	@V_CO_CD                    VARCHAR(3),          -- 데비스회사코드
	@V_CLOSE_YM					VARCHAR(6),			 -- 마감년월
	@V_YYYYMM   			    VARCHAR(6),			 -- 처리년월
	@V_ACCT_DEPT_CD				VARCHAR(5),			 -- 귀속부서코드
	@V_WITHHOLD_CLS_CD			VARCHAR(2),			 -- 원천세구분코드
	@V_PAY_DT				    VARCHAR(8),			 -- 지급일자
	@V_STAFF				    NUMERIC(5,0),		 -- 인원
	@V_TOT_AMT					NUMERIC(20,0),		 -- 총금액
	@V_TAXN_AMT					NUMERIC(20,0),		 --	과세금액
	@V_INCOME_TAX			    NUMERIC(20,0),		 --	소득세
	@V_MAN_TAX					NUMERIC(20,0),		 -- 주민세
	@V_REPLY_CLS_CD				VARCHAR(1),			 --	응답구분코드
	@V_PROC_YN					NUMERIC(1,0),		 -- 처리여부
	@V_REG_ID					VARCHAR(8),			 -- 등록자ID
	@V_REG_DTM					DATETIME,			 -- 등록일시
	@V_MOD_ID					VARCHAR(8),			 --	수정자ID
	@V_MOD_DTM					DATETIME,		     -- 수정일시
	@V_PROC_CNT					NUMERIC(10,0),		 -- 처리건

	@V_WITHHOLDING_ID			NUMERIC(10,0),		 -- ID       
	@V_DEPT_TYPE				VARCHAR(20),         -- 본사구분
	@V_WORK_SITE_CD				VARCHAR(10),          --  근무지
	@V_COSTDPT_CD				VARCHAR(20),         -- 원가부서
	@V_SABUN_CNT				NUMERIC(10,0),        -- 총인원
	@V_AOLWTOT_AMT				NUMERIC(20,0),       -- 급여총액
	@V_TAXFREEALOW				NUMERIC(20,0),       -- 비과세
	@V_INCTAX					NUMERIC(20,0),       -- 소득세
	@V_INGTAX					NUMERIC(20,0),       -- 주민세
	@V_INCTAX_OLD				NUMERIC(20,0),       -- 소득세
	@V_INGTAX_OLD				NUMERIC(20,0),       -- 주민세  

	@V_CNT						NUMERIC(10,0),        -- 처리건수
	@V_USER1					VARCHAR(20),         -- 원가부서매핑코드
	@V_PAY_CD					VARCHAR(10),         -- 급여코드
	@V_PAY_CD1					VARCHAR(10),         -- 급여코드  
	
	@V_CNT_DUP                  NUMERIC(10),
	@OPENQUERY					nvarchar(4000), 
	@TSQL						nvarchar(4000), 
	@LinkedServer				nvarchar(20) = 'DEBIS',
	--@LinkedServer				nvarchar(20) = 'DEBIS_DEV',
	
	/* BEGIN CATCH 사용할 변수 정의  */
	@v_error_number				INT,
	@v_error_severity			INT,
	@v_error_state				INT,
	@v_error_procedure			VARCHAR(1000),
	@v_error_line				INT,
	@v_error_message			VARCHAR(3000),

	/* ERR_HANDLER 사용할 변수 정의 */
	@v_error_num			    INT,
	@v_row_count				INT,
	@v_error_code				VARCHAR(1000),										-- 에러코드
	@v_error_note				VARCHAR(3000)										-- 에러노트 (exec : '문자열A|문자열B')

/* 기본적으로 사용되는 변수 */
DECLARE @v_program_id		NVARCHAR(30)
      , @v_program_nm		NVARCHAR(100)
      , @v_ret_code			NVARCHAR(100)
      , @v_ret_message		NVARCHAR(500)
    SET @v_program_id   = 'P_TBS_DEBIS_WITHHOLD'
    SET @v_program_nm   = 'DEBIS원천세생성'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
	SELECT @v_emp_no = EMP_NO
	  FROM PHM_EMP
	 WHERE EMP_ID = @an_emp_id

    print('인력유형 실행 전' + ISNULL(@v_emp_no,''))
    -- 인력유형에 대응하는 데비스회사코드
	BEGIN
		SELECT @V_CO_CD = dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, 'KO', 'PAY', 'PAY_PBT_HRTYPE',
                              NULL, NULL, NULL, NULL, NULL,
                              @av_hrtype_cd, NULL, NULL, NULL, NULL,
                              @ad_proc_date,
                              'H1' -- 'H1' : 코드1,     'H2' : 코드2,    'H3' :  코드3,    'H4' : 코드4,    'H5' : 코드5
							       -- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
                              )
    END
    print('인력유형 실행 후:' + @V_CO_CD)
	-- 마감년월
    SET @V_CLOSE_YM = @av_close_ym

	--코드구분( 연말정산 : E1) 전년 12월
    IF @av_tax_kind_cd = 'E1'
		BEGIN
			IF SUBSTRING(@V_CLOSE_YM,5,2) <> '02'  --2월이 아니면 오류
				BEGIN
					SET @av_ret_code = 'FAILURE!';
					SET @av_ret_message = dbo.F_FRM_ERRMSG('연말정산은 마감년월을 확인하세요.(2)' + '[ERR]',
													@v_program_id,  0901,  NULL, NULL)
					RETURN
				END
        END

    print('CNT_PROC 실행 전')
	PRINT('@V_CLOSE_YM : ' + @V_CLOSE_YM)
	PRINT('@V_CO_CD : ' + @V_CO_CD)
    SET @V_PROC_CNT = 0; 
  ----  BEGIN
		----SET @OPENQUERY = 'SELECT @V_PROC_CNT = CNT_PROC FROM OPENQUERY('+ @LinkedServer + ','''
		----SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_PROC FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
		----SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
		----SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
		----SET @OPENQUERY = @OPENQUERY + '   AND (PROC_YN = 1 OR REPLY_CLS_CD <> ''''D''''))'') '
		
		----PRINT @OPENQUERY

		------ 수정중
		----EXEC sp_executesql @OPENQUERY, N'@V_PROC_CNT NUMERIC(5) OUTPUT', @V_PROC_CNT output
   
		----IF @V_PROC_CNT > 0
		----	BEGIN
		----		SET @p_error_str = 'ERROR';
		----			GOTO ERR_HANDLER
		----	END
  ----  END 
    print('CNT_PROC 실행 후')

    --코드구분(급여 : A1) 마감년월의전월
	IF @av_tax_kind_cd = 'A1'
		BEGIN
			IF @av_company_cd = 'B'
				BEGIN
					SET @V_YYYYMM = @V_CLOSE_YM;
				END
			ELSE
				BEGIN
					--IF (SUBSTRING(@P_PROC_DATE,7,2) in ( '25'))
					IF (dbo.XF_TO_CHAR_D(@ad_proc_date, 'dd') in ( '25'))
						BEGIN
							SET @V_YYYYMM = @V_CLOSE_YM;
						END
					ELSE
						BEGIN
							-- TO_CHAR(ADD_MONTHS(TO_DATE(V_CLOSE_YM,'YYYYMM'),-1),'YYYYMM'); 
							SET @V_YYYYMM = SUBSTRING(CONVERT(VARCHAR(10), DATEADD(MONTH, -1, CONVERT(DATETIME, @V_CLOSE_YM + '01', 112)), 112), 1, 6)
							PRINT ('@V_YYYYMM = ' + @V_YYYYMM);
						END
				END
       END
    --코드구분( 상여 : B1) 마감년월과동일
    IF @av_tax_kind_cd = 'B1'
		BEGIN
			SET @V_YYYYMM = @V_CLOSE_YM;
        END
    --코드구분( 연말정산 : E1) 전년 12월
    IF @av_tax_kind_cd = 'E1'
		BEGIN
			SET @V_YYYYMM = SUBSTRING(CONVERT(VARCHAR(10), DATEADD(MONTH, -12, CONVERT(DATETIME, @V_CLOSE_YM + '01', 112)), 112), 1, 4) + '12'
		END
    --코드구분( 퇴직정산 : C1 ) 마감년월과동일한 전표생성년월
    IF @av_tax_kind_cd = 'C1'
		BEGIN
			SET @V_YYYYMM = @V_CLOSE_YM; 
		END
    --코드구분(중도정산 : D1)  마감년월과동일
    IF @av_tax_kind_cd = 'D1' OR @av_tax_kind_cd = 'P1'
		BEGIN
			SET @V_YYYYMM = @V_CLOSE_YM;
			
		END 
    
    --코드구분
    SET @V_WITHHOLD_CLS_CD = @av_tax_kind_cd;
    
    print('코드구분 실행 전')
    PRINT(@av_tax_kind_cd)
	IF @av_tax_kind_cd = 'A1'
		BEGIN
        -- 급여
			IF @av_company_cd = 'B'
				BEGIN
					SET @V_PAY_CD = '002';  --급여
					SET @V_PAY_CD1 = '002';  --소급액
					SET @V_WITHHOLD_CLS_CD = 'A1';  --사무직급여
					print(@V_PAY_CD + ', ' + @V_PAY_CD1 + ', ' + @V_WITHHOLD_CLS_CD)
				END
			ELSE

			BEGIN
				--IF (SUBSTRING(@P_PROC_DATE,7,2) in ( '25'))
				IF dbo.XF_TO_CHAR_D(@ad_proc_date,'dd') in ('25')
					BEGIN
						SET @V_PAY_CD = '03';  --급여
						SET @V_PAY_CD1 = '04';  --소급액
						SET @V_WITHHOLD_CLS_CD = 'A2';  --사무직급여
						print(@V_PAY_CD + ', ' + @V_PAY_CD1 + ', ' + @V_WITHHOLD_CLS_CD)
					END
				ELSE
					BEGIN
						SET @V_PAY_CD = '01';  --급여
						SET @V_PAY_CD1 = 'XXXXX';  --소급액
					END
			END
			
			BEGIN
				PRINT('DELETE쿼리 수행 전')
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''' AND (PROC_YN = 1 OR REPLY_CLS_CD <> ''''D''''))'') '
				
				PRINT(@OPENQUERY)
				exec (@OPENQUERY)
				PRINT('DELETE쿼리 수행 후')
			END
	        
	        PRINT('커서선언 전')
	        PRINT('@av_company_cd : ' + @av_company_cd)
	        PRINT('@av_hrtype_cd : ' + @av_hrtype_cd)
	        PRINT('@V_YYYYMM : ' + @V_YYYYMM)
	        PRINT('@V_PAY_CD : ' + @V_PAY_CD)
	        PRINT('@V_PAY_CD : ' + @V_PAY_CD1)
			PRINT('@ad_proc_date : ' + dbo.XF_TO_CHAR_D(@ad_proc_date,'yyyyMMdd'))
	        
	        DECLARE C_PBT_WITHHOOD_E CURSOR FOR                       -- 원천세생성 데이터를 가져온다. 
			SELECT A.RES_BIZ_CD                                       -- 사업장 - 근무지 
				  ,ISNULL(MAPCOSTDPT_CD,'XXXXX')  MAPCOSTDPT_CD       -- 원가부서
				  ,COUNT(DISTINCT(A.EMP_ID)) AS SABUN_CNT             -- 총인원
				  ,SUM(A.PSUM) AS AOLWTOT_AMT                         -- 급여총액
				  ,SUM(A.C001_AMT) AS TAXFREEALOW                     -- 비과세
				  ,SUM(A.D001_AMT) AS INCTAX                          -- 소득세
				  ,SUM(A.D002_AMT) AS INGTAX						  -- 주민세
			  FROM (
					SELECT PAY.RES_BIZ_CD
						 , PRI.FROM_TYPE_CD 
						 , PAY.ACC_CD COST_CD
						 , PAY.EMP_ID
						 , PAY.PSUM
						 , (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD=YMD.COMPANY_CD AND COST_CD = PAY.ACC_CD AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD ) AS MAPCOSTDPT_CD
						 , D001_AMT -- 갑근세
						 , D002_AMT -- 주민세
						 , C001_AMT -- 비과세
					  FROM PAY_PAY_YMD YMD
					  JOIN PAY_PAYROLL PAY
						ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
					  JOIN PHM_PRIVATE PRI
						ON PAY.EMP_ID = PRI.EMP_ID
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
					   AND PRI.FROM_TYPE_CD = @av_hrtype_cd
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
			 GROUP BY A.RES_BIZ_CD		-- 사업장 - 근무지 
					 ,MAPCOSTDPT_CD		-- 원가부서
			 ORDER BY RES_BIZ_CD		-- 사업장 - 근무지 
					 ,MAPCOSTDPT_CD;	-- 원가부서  

			OPEN C_PBT_WITHHOOD_E  -- 커서 패치
			FETCH NEXT FROM C_PBT_WITHHOOD_E INTO   @V_WORK_SITE_CD,
													 @V_COSTDPT_CD,
													 @V_SABUN_CNT,
													 @V_AOLWTOT_AMT,
													 @V_TAXFREEALOW,
													 @V_INCTAX,
													 @V_INGTAX
			WHILE	@@fetch_status = 0
			BEGIN
				
				PRINT ('커서수행')
				PRINT(@@ROWCOUNT)
				
				--IF(@@ROWCOUNT < 1)
				--	BEGIN
				--		GOTO ERR_HANDLER
				--	END
	            
				-- 처리건수
				SET @V_CNT = @V_CNT +1;
	            
				-- 원가부서
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
	            
				-- 지급일자 
				SET @V_PAY_DT = dbo.XF_TO_CHAR_D( @ad_proc_date, 'yyyyMMdd')
				-- 총인원
				SET @V_STAFF = @V_SABUN_CNT;
				-- 급여총액
				SET @V_TOT_AMT = @V_AOLWTOT_AMT;
				-- 비과세(비과세를 과세로 변환)
				SET @V_TAXN_AMT = @V_AOLWTOT_AMT - @V_TAXFREEALOW;
				-- 직원　소득세
				SET @V_INCOME_TAX = @V_INCTAX;
				-- 직원　주민세
				SET @V_MAN_TAX = @V_INGTAX;
	            
	            PRINT('중복체크 전')
				BEGIN
					SET @V_CNT_DUP = 0;
					SET @OPENQUERY = 'SELECT @V_CNT_DUP = CNT_DUP FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_DUP FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND PAY_DT = ''''' + @V_PAY_DT + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WORK_SITE_CD =  ''''' + @V_WORK_SITE_CD + ''''''') '
					EXEC sp_executesql @OPENQUERY, N'@V_CNT_DUP NUMERIC(3) OUTPUT', @V_CNT_DUP output
					PRINT(@OPENQUERY)
					PRINT('중복체크 후')
					PRINT('@V_CNT_DUP : ' + CAST(@V_CNT_DUP AS VARCHAR))
					IF @V_CNT_DUP > 0 -- 중복, 업데이트 수행
						BEGIN
							PRINT('업데이트 문 실행')
							SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT PAY_DT, STAFF, TOT_AMT, TAXN_AMT, INCOME_TAX, MAN_TAX '
							SET @OPENQUERY = @OPENQUERY + ' , REPLY_CLS_CD, PROC_YN, REG_ID, REG_DTM FROM TB_FI312 '
							SET @OPENQUERY = @OPENQUERY + 'WHERE ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WORK_SITE_CD = ''''' + @V_WORK_SITE_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''')' 
							SET @OPENQUERY = @OPENQUERY + ' SET PAY_DT = ''' + @V_PAY_DT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,STAFF = ' + CAST(@V_STAFF AS VARCHAR) + ''
							SET @OPENQUERY = @OPENQUERY + '    ,TOT_AMT = ' + CAST(@V_TOT_AMT AS VARCHAR) + ''
							SET @OPENQUERY = @OPENQUERY + '    ,TAXN_AMT = ' + CAST(@V_TAXN_AMT AS VARCHAR) + ''
							SET @OPENQUERY = @OPENQUERY + '    ,INCOME_TAX = ' + CAST(@V_INCOME_TAX AS VARCHAR) + ''
							SET @OPENQUERY = @OPENQUERY + '    ,MAN_TAX = ' + CAST(@V_MAN_TAX AS VARCHAR) + ''
							SET @OPENQUERY = @OPENQUERY + '    ,REPLY_CLS_CD = '''''
							SET @OPENQUERY = @OPENQUERY + '    ,PROC_YN = 0'
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @v_emp_no + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							PRINT(@OPENQUERY)
							EXECUTE(@OPENQUERY);	
						END
					ELSE
						BEGIN
							PRINT('인서트 문 실행')
							PRINT('@V_CLOSE_YM : ' + CAST(@V_CLOSE_YM AS VARCHAR))
							PRINT('@V_ACCT_DEPT_CD : ' + CAST(@V_ACCT_DEPT_CD AS VARCHAR))
							PRINT('@V_WITHHOLD_CLS_CD : ' +CAST( @V_WITHHOLD_CLS_CD AS VARCHAR))
							PRINT('@V_WORK_SITE_CD : ' + CAST(@V_WORK_SITE_CD AS VARCHAR))
							PRINT('@V_PAY_DT : ' + CAST(@V_PAY_DT AS VARCHAR))
							PRINT('@V_STAFF : ' + CAST(@V_STAFF AS VARCHAR))
							PRINT('@V_TOT_AMT : ' + CAST(@V_TOT_AMT AS VARCHAR))
							PRINT('@V_TAXN_AMT : ' + CAST(@V_TAXN_AMT AS VARCHAR))
							PRINT('@V_INCOME_TAX : ' + CAST(@V_INCOME_TAX AS VARCHAR))
							PRINT('@V_MAN_TAX : ' + CAST(@V_MAN_TAX AS VARCHAR))
							PRINT('@P_SABUN : ' + CAST(@v_emp_no AS VARCHAR))
							--INSERT INTO TB_FI312
							INSERT OPENQUERY(DEBIS, 'SELECT CLOSE_YM      
															 ,ACCT_DEPT_CD   
															 ,WITHHOLD_CLS_CD
															 ,WORK_SITE_CD
															 ,PAY_DT         
															 ,STAFF          
															 ,TOT_AMT        
															 ,TAXN_AMT       
															 ,INCOME_TAX     
															 ,MAN_TAX        
															 ,REPLY_CLS_CD     
															 ,PROC_YN        
															 ,REG_ID         
															 ,REG_DTM
														 FROM TB_FI312') 
														 VALUES(    
														  @V_CLOSE_YM  
														 ,@V_ACCT_DEPT_CD   
														 ,@V_WITHHOLD_CLS_CD
														 ,@V_WORK_SITE_CD
														 ,@V_PAY_DT         
														 ,@V_STAFF          
														 ,@V_TOT_AMT        
														 ,@V_TAXN_AMT       
														 ,@V_INCOME_TAX     
														 ,@V_MAN_TAX        
														 ,''     
														 ,0       
														 ,@v_emp_no         
														 ,CONVERT(VARCHAR(10), GETDATE(), 112)  
														 );
						END
				
				END  
			FETCH NEXT FROM C_PBT_WITHHOOD_E INTO   @V_WORK_SITE_CD,
													@V_COSTDPT_CD,
													@V_SABUN_CNT,
													@V_AOLWTOT_AMT,
													@V_TAXFREEALOW,
													@V_INCTAX,
													@V_INGTAX
			END 
	           
			CLOSE C_PBT_WITHHOOD_E        
			DEALLOCATE C_PBT_WITHHOOD_E; 
		END
		
    ELSE IF @av_tax_kind_cd = 'B1'
		BEGIN
        --상여
			SET @V_PAY_CD = '02';
			SET @V_PAY_CD1 = 'XXXXX';
			PRINT('@V_PAY_CD : ' + @V_PAY_CD);
			PRINT('@V_PAY_CD1 : ' + @V_PAY_CD1);
			BEGIN 
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @av_tax_kind_cd + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '
				
				EXEC (@OPENQUERY)      
			END
			
			PRINT('커서 수행 전')
			DECLARE C_PBT_WITHHOOD_E CURSOR FOR                                     -- 원천세생성 데이터를 가져온다. 
			SELECT A.RES_BIZ_CD                                       -- 사업장 - 근무지 
				  ,ISNULL(MAPCOSTDPT_CD,'XXXXX')  MAPCOSTDPT_CD       -- 원가부서
				  ,COUNT(DISTINCT(A.EMP_ID)) AS SABUN_CNT             -- 총인원
				  ,SUM(A.PSUM) AS AOLWTOT_AMT                         -- 급여총액
				  ,SUM(A.C001_AMT) AS TAXFREEALOW                     -- 비과세
				  ,SUM(A.D001_AMT) AS INCTAX                          -- 소득세
				  ,SUM(A.D002_AMT) AS INGTAX						  -- 주민세
			  FROM (
					SELECT PAY.RES_BIZ_CD
						 , PRI.FROM_TYPE_CD 
						 , PAY.ACC_CD COST_CD
						 , PAY.EMP_ID
						 , PAY.PSUM
						 , (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD=YMD.COMPANY_CD AND COST_CD = PAY.ACC_CD AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD ) AS MAPCOSTDPT_CD
						 , D001_AMT -- 갑근세
						 , D002_AMT -- 주민세
						 , C001_AMT -- 비과세
					  FROM PAY_PAY_YMD YMD
					  JOIN PAY_PAYROLL PAY
						ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
					  JOIN PHM_EMP EMP
					    ON PAY.EMP_ID = EMP.EMP_ID
					  JOIN PHM_PRIVATE PRI
						ON PAY.EMP_ID = PRI.EMP_ID
					   AND CASE WHEN EMP.IN_OFFI_YN != 'Y' THEN EMP.RETIRE_YMD WHEN YMD.PAY_YMD < EMP.HIRE_YMD THEN EMP.HIRE_YMD ELSE YMD.PAY_YMD END BETWEEN PRI.STA_YMD AND PRI.END_YMD
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
					   AND PRI.FROM_TYPE_CD = @av_hrtype_cd
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
			 GROUP BY A.RES_BIZ_CD		-- 사업장 - 근무지 
					 ,MAPCOSTDPT_CD		-- 원가부서
			 ORDER BY RES_BIZ_CD		-- 사업장 - 근무지 
					 ,MAPCOSTDPT_CD;	-- 원가부서  

			OPEN C_PBT_WITHHOOD_E  -- 커서 패치
			FETCH NEXT FROM C_PBT_WITHHOOD_E INTO   @V_WORK_SITE_CD,
													@V_COSTDPT_CD,
													@V_SABUN_CNT,
													@V_AOLWTOT_AMT,
													@V_TAXFREEALOW,
													@V_INCTAX,
													@V_INGTAX
			WHILE	@@fetch_status = 0
			BEGIN
				--IF(@@ROWCOUNT < 1)
				--	BEGIN
				--		GOTO ERR_HANDLER
				--	END
				
				PRINT('커서 수행중')
				-- 처리건수
				SET @V_CNT = @V_CNT+1;
				-- 원가부서
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
				-- 지급일자 
				SET @V_PAY_DT = dbo.XF_TO_CHAR_D(@ad_proc_date, 'yyyyMMdd')
				-- 총인원
				SET @V_STAFF = @V_SABUN_CNT;
				-- 급여총액
				SET @V_TOT_AMT = @V_AOLWTOT_AMT;
				-- 비과세(비과세를 과세로 변환)
				SET @V_TAXN_AMT = @V_AOLWTOT_AMT - @V_TAXFREEALOW;
				-- 직원　소득세
				SET @V_INCOME_TAX = @V_INCTAX;
				-- 직원　주민세
				SET @V_MAN_TAX = @V_INGTAX;
            
				BEGIN
					SET @V_CNT_DUP = 0;
					SET @OPENQUERY = 'SELECT @V_CNT_DUP = CNT_DUP FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_DUP FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WORK_SITE_CD =  ''''' + @V_WORK_SITE_CD + ''''''') '
					EXEC sp_executesql @OPENQUERY, N'@V_CNT_DUP NUMERIC(3) OUTPUT', @V_CNT_DUP output
					
					IF @V_CNT_DUP > 0 -- 중복, 업데이트 수행
						BEGIN
							SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT PAY_DT, STAFF, TOT_AMT, TAXN_AMT, INCOME_TAX, MAN_TAX '
							SET @OPENQUERY = @OPENQUERY + ' , REPLY_CLS_CD, PROC_YN, REG_ID, REG_DTM FROM TB_FI312 '
							SET @OPENQUERY = @OPENQUERY + 'WHERE ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WORK_SITE_CD = ''''' + @V_WORK_SITE_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''')' 
							SET @OPENQUERY = @OPENQUERY + ' SET PAY_DT = ''' + @V_PAY_DT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,STAFF = ''' + @V_STAFF + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TOT_AMT = ''' + @V_TOT_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TAXN_AMT = ''' + @V_TAXN_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,INCOME_TAX = ''' + @V_INCOME_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,MAN_TAX = ''' + @V_MAN_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REPLY_CLS_CD = '''''
							SET @OPENQUERY = @OPENQUERY + '    ,PROC_YN = 0'
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @v_emp_no + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC (@OPENQUERY);
						END
					ELSE
						BEGIN
						 --INSERT INTO TB_FI312
							INSERT OPENQUERY(DEBIS, 'SELECT CLOSE_YM   
															 ,ACCT_DEPT_CD   
															 ,WITHHOLD_CLS_CD
															 ,WORK_SITE_CD
															 ,PAY_DT         
															 ,STAFF          
															 ,TOT_AMT        
															 ,TAXN_AMT       
															 ,INCOME_TAX     
															 ,MAN_TAX        
															 ,REPLY_CLS_CD     
															 ,PROC_YN        
															 ,REG_ID         
															 ,REG_DTM
													     FROM TB_FI312')
													   VALUES(    
															  @V_CLOSE_YM    
															 ,@V_ACCT_DEPT_CD   
															 ,@V_WITHHOLD_CLS_CD
															 ,@V_WORK_SITE_CD
															 ,@V_PAY_DT         
															 ,@V_STAFF          
															 ,@V_TOT_AMT        
															 ,@V_TAXN_AMT       
															 ,@V_INCOME_TAX     
															 ,@V_MAN_TAX        
															 ,''     
															 ,0       
															 ,@v_emp_no         
															 ,CONVERT(VARCHAR(10), GETDATE(), 112)  
														 );      	
						END   
				END
				FETCH NEXT FROM C_PBT_WITHHOOD_E INTO   @V_WORK_SITE_CD,
													 @V_COSTDPT_CD,
													 @V_SABUN_CNT,
													 @V_AOLWTOT_AMT,
													 @V_TAXFREEALOW,
													 @V_INCTAX,
													 @V_INGTAX             
			END                                     
			CLOSE C_PBT_WITHHOOD_E;  -- 원천세생성 종료
			DEALLOCATE C_PBT_WITHHOOD_E
		END
		
    ELSE IF @av_tax_kind_cd = 'C1'
		BEGIN
			--퇴직정산
			SET @V_PAY_CD = '';
			
			BEGIN
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @av_tax_kind_cd + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '
				
				EXEC (@OPENQUERY)  
			END
			
			--퇴직정산
			PRINT('CURSOR 선언(퇴직정산)')
			                                           -- 원천세생성 데이터를 가져온다. 
			DECLARE C_PBT_RET_RESULT CURSOR FOR    
			   SELECT A.REG_BIZ_CD
					 ,A.MAPCOSTDPT_CD  
					 ,COUNT(DISTINCT(A.EMP_ID)) AS SABUN_CNT      -- 총인원
					 ,SUM(A.AMT_RETR_PAY) AS AOLWTOT_AMT          -- 급여총액
					 ,0 AS TAXFREEALOW   -- 비과세
					 ,SUM(A.T01) AS INCTAX                -- 소득세
					 ,SUM(A.T02) AS INGTAX                -- 주민세  
					 ,SUM(A.INCTAX_OLD) AS INCTAX_OLD        -- 원본소득세
					 ,SUM(A.INHTAX_OLD) AS INHTAX_OLD        -- 원본주민세
				FROM ( 
					   SELECT DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',A.C1_END_YMD,'ORG_ID'),A.C1_END_YMD) AS REG_BIZ_CD,
							   dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.PAY_YMD, '1') AS COST_CD,
							   (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD = A.COMPANY_CD AND COST_CD = dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.PAY_YMD, '1')
															   AND A.C1_END_YMD BETWEEN STA_YMD AND END_YMD) AS MAPCOSTDPT_CD,
								A.EMP_ID,
								A.C_01 AS AMT_RETR_PAY, -- 급여총액
								0 TAXFREEALOW,          -- 비과세
								A.R06_S AS INCTAX_OLD,                -- 소득세
								A.CT02 AS INHTAX_OLD,                 -- 주민세
								A.TRANS_INCOME_AMT INCTAX,     -- 과세이연소득세
								A.TRANS_RESIDENCE_AMT INHTAX,   -- 과세이연주민세
								A.T01, -- 차감소득세
								A.T02  -- 차감주민세
						  FROM REP_CALC_LIST A
						  JOIN PHM_PRIVATE PRI
							ON A.EMP_ID = PRI.EMP_ID
						   AND A.C1_END_YMD BETWEEN PRI.STA_YMD AND PRI.END_YMD
						 WHERE A.COMPANY_CD = @av_company_cd
						   AND PRI.FROM_TYPE_CD = @av_hrtype_cd -- 인력유형
						   AND FORMAT(A.C1_END_YMD, 'yyyyMM') = @V_YYYYMM
						   AND A.CALC_TYPE_CD IN ('01','02') -- 퇴직, 중간정산
						   AND A.REP_MID_YN != 'Y'
						   AND A.INS_TYPE_CD = '10' -- DB형
						   AND A.C_01 <> 0) A
				GROUP BY A.REG_BIZ_CD
						,A.MAPCOSTDPT_CD  
				ORDER BY A.REG_BIZ_CD
						,A.MAPCOSTDPT_CD
			OPEN C_PBT_RET_RESULT  -- 커서 패치
	        FETCH NEXT FROM C_PBT_RET_RESULT INTO    @V_WORK_SITE_CD,
													 @V_COSTDPT_CD,
													 @V_SABUN_CNT,
													 @V_AOLWTOT_AMT,
													 @V_TAXFREEALOW,
													 @V_INCTAX,
													 @V_INGTAX,
													 @V_INCTAX_OLD,
													 @V_INGTAX_OLD
			WHILE	@@fetch_status = 0
			BEGIN
				--IF(@@ROWCOUNT < 1)
				--	BEGIN
				--		GOTO ERR_HANDLER
				--	END
				
				PRINT('테스트')

				-- 처리건수
				SET @V_CNT = @V_CNT+1;
				-- 원가부서
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
				-- 지급일자 
				SET @V_PAY_DT = dbo.XF_TO_CHAR_D(@ad_proc_date, 'yyyyMMdd')
				-- 총인원
				SET @V_STAFF = @V_SABUN_CNT;
				-- 급여총액
				SET @V_TOT_AMT = @V_AOLWTOT_AMT;
				-- 비과세(비과세를 과세로 변환)
				SET @V_TAXN_AMT = @V_AOLWTOT_AMT - @V_TAXFREEALOW;
				-- 직원　소득세
				SET @V_INCOME_TAX = @V_INCTAX;
				-- 직원　주민세
				SET @V_MAN_TAX = @V_INGTAX;
	            
				BEGIN
					SET @V_CNT_DUP = 0;
					SET @OPENQUERY = 'SELECT @V_CNT_DUP = CNT_DUP FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_DUP FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WORK_SITE_CD =  ''''' + @V_WORK_SITE_CD + ''''''') '
					EXEC sp_executesql @OPENQUERY, N'@V_CNT_DUP NUMERIC(3) OUTPUT', @V_CNT_DUP output

					PRINT(@OPENQUERY)
					
					IF @V_CNT_DUP > 0 -- 중복, 업데이트 수행
						BEGIN
							SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT PAY_DT, STAFF, TOT_AMT, TAXN_AMT, INCOME_TAX, MAN_TAX '
							SET @OPENQUERY = @OPENQUERY + ' , REPLY_CLS_CD, PROC_YN, REG_ID, REG_DTM FROM TB_FI312 '
							SET @OPENQUERY = @OPENQUERY + 'WHERE ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WORK_SITE_CD = ''''' + @V_WORK_SITE_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''')' 
							SET @OPENQUERY = @OPENQUERY + ' SET PAY_DT = ''' + @V_PAY_DT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,STAFF = ''' + @V_STAFF + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TOT_AMT = ''' + @V_TOT_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TAXN_AMT = ''' + @V_TAXN_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,INCOME_TAX = ''' + @V_INCOME_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,MAN_TAX = ''' + @V_MAN_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REPLY_CLS_CD = '''''
							SET @OPENQUERY = @OPENQUERY + '    ,PROC_YN = 0'
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @v_emp_no + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC (@OPENQUERY);
						END
					ELSE
						BEGIN
							--INSERT INTO TB_FI312
							INSERT OPENQUERY(DEBIS, 'SELECT CLOSE_YM  
															 ,ACCT_DEPT_CD   
															 ,WITHHOLD_CLS_CD
															 ,WORK_SITE_CD
															 ,PAY_DT         
															 ,STAFF          
															 ,TOT_AMT        
															 ,TAXN_AMT       
															 ,INCOME_TAX     
															 ,MAN_TAX        
															 ,REPLY_CLS_CD     
															 ,PROC_YN        
															 ,REG_ID         
															 ,REG_DTM 
														 FROM TB_FI312 ')
													  VALUES(    
															  @V_CLOSE_YM     
															 ,@V_ACCT_DEPT_CD   
															 ,@V_WITHHOLD_CLS_CD
															 ,@V_WORK_SITE_CD
															 ,@V_PAY_DT         
															 ,@V_STAFF          
															 ,@V_TOT_AMT        
															 ,@V_TAXN_AMT       
															 ,@V_INCOME_TAX     
															 ,@V_MAN_TAX        
															 ,''     
															 ,0       
															 ,@v_emp_no         
															 ,CONVERT(VARCHAR(10), GETDATE(), 112)   
															 );
						END  
				END 
				FETCH NEXT FROM C_PBT_RET_RESULT INTO    @V_WORK_SITE_CD,
														 @V_COSTDPT_CD,
														 @V_SABUN_CNT,
														 @V_AOLWTOT_AMT,
														 @V_TAXFREEALOW,
														 @V_INCTAX,
														 @V_INGTAX,
														 @V_INCTAX_OLD,
														 @V_INGTAX_OLD
			END                                           
			CLOSE C_PBT_RET_RESULT  -- 퇴직정산원천세생성 종료
			DEALLOCATE C_PBT_RET_RESULT
		END

    ELSE IF @av_tax_kind_cd = 'E1'
		BEGIN
			--연말정산
			SET @V_PAY_CD = 'P2101';

			BEGIN
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @av_tax_kind_cd + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '
				print(@OPENQUERY)
				EXEC (@OPENQUERY)   
			END
        
            --연말정산 원천세 신고
			
			PRINT('@P_COMPANY : ' + @av_company_cd);
			PRINT('@P_HRTYPE_GBN : ' + @av_hrtype_cd);
			PRINT('@V_YYYYMM : ' + @V_YYYYMM);


			-- CURSOR 선언(연말정산)
		    DECLARE C_PBT_WITHHOOD_YETA CURSOR FOR    -- 원천세생성 데이터를 가져온다. 
				SELECT   A.REG_BIZ_CD
					    ,A.MAPCOSTDPT_CD  
						,COUNT(DISTINCT(A.SABUN)) AS SABUN_CNT      -- 총인원
						,SUM(A.INC_TOTAMT) AS AOLWTOT_AMT          -- 급여총액
						,SUM(A.AMT_BITAX_TOT) AS TAXFREEALOW   -- 비과세
						,SUM(A.AMT_NEW_STAX) AS INCTAX                -- 소득세
						,SUM(A.AMT_NEW_JTAX) AS INGTAX                -- 주민세  
				  FROM (
						SELECT DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',A.IN_END_YMD,'ORG_ID'),A.IN_END_YMD) AS REG_BIZ_CD,
							   dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.IN_END_YMD, '1') AS COST_CD,
							   (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD = A.COMPANY_CD AND COST_CD = dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.IN_END_YMD, '1')
															   AND A.IN_END_YMD BETWEEN STA_YMD AND END_YMD) AS MAPCOSTDPT_CD
						   ,A.EMP_ID SABUN     -- 총인원
						   ,(A.X01_SUM) AS INC_TOTAMT        -- 급여총액
						   ,A.Y_SUM AMT_BITAX_TOT               -- 비과세
						   ,A.F0310 AMT_NEW_STAX                -- 소득세
						   ,A.F0320 AMT_NEW_JTAX                -- 주민세         
						  FROM INT_Y08_EC_DETAIL A
						  JOIN PHM_PRIVATE PRI
							ON A.EMP_ID = PRI.EMP_ID
						   AND A.IN_END_YMD BETWEEN PRI.STA_YMD AND PRI.END_YMD
						 WHERE A.COMPANY_CD = @av_company_cd
						   AND PRI.FROM_TYPE_CD = @av_hrtype_cd -- 인력유형
						   AND A.EC_YY = SUBSTRING(@V_YYYYMM, 1, 4)
						   AND A.X01_SUM <> 0) A
			  GROUP BY  A.REG_BIZ_CD
					   ,A.MAPCOSTDPT_CD  
			  ORDER BY  A.REG_BIZ_CD
					   ,A.MAPCOSTDPT_CD;
		   OPEN C_PBT_WITHHOOD_YETA  -- 커서 패치
		   FETCH NEXT FROM C_PBT_WITHHOOD_YETA INTO    @V_WORK_SITE_CD,
													   @V_COSTDPT_CD,
													   @V_SABUN_CNT,
													   @V_AOLWTOT_AMT,
													   @V_TAXFREEALOW,
													   @V_INCTAX,
													   @V_INGTAX
			WHILE	@@fetch_status = 0
			BEGIN
				--PRINT('로우수')
				--PRINT(@@ROWCOUNT);
				--IF(@@ROWCOUNT < 1)
				--	BEGIN
				--		GOTO ERR_HANDLER
				--	END
			
				-- 처리건수
				SET @V_CNT = @V_CNT+1;
				-- 원가부서
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
				-- 지급일자 
				SET @V_PAY_DT = dbo.XF_TO_CHAR_D(@ad_proc_date, 'yyyyMMdd') -- @P_PROC_DATE;
				-- 총인원
				SET @V_STAFF = @V_SABUN_CNT;
				-- 급여총액
				SET @V_TOT_AMT = @V_AOLWTOT_AMT;
				-- 비과세(비과세를 과세로 변환)
				SET @V_TAXN_AMT = @V_AOLWTOT_AMT - @V_TAXFREEALOW;
				-- 직원　소득세
				SET @V_INCOME_TAX = @V_INCTAX;
				-- 직원　주민세
				SET @V_MAN_TAX = @V_INGTAX;
	            
	            BEGIN
					SET @V_CNT_DUP = 0;
					SET @OPENQUERY = 'SELECT @V_CNT_DUP = CNT_DUP FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_DUP FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WORK_SITE_CD =  ''''' + @V_WORK_SITE_CD + ''''') '
					EXEC sp_executesql @OPENQUERY, N'@V_CNT_DUP NUMERIC(3) OUTPUT', @V_CNT_DUP output
					
					IF @V_CNT_DUP > 0 -- 중복, 업데이트 수행
						BEGIN
							print('업데이트구문 실행')
							SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT PAY_DT, STAFF, TOT_AMT, TAXN_AMT, INCOME_TAX, MAN_TAX '
							SET @OPENQUERY = @OPENQUERY + ' , REPLY_CLS_CD, PROC_YN, REG_ID, REG_DTM FROM TB_FI312 '
							SET @OPENQUERY = @OPENQUERY + 'WHERE ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WORK_SITE_CD = ''''' + @V_WORK_SITE_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''')' 
							SET @OPENQUERY = @OPENQUERY + ' SET PAY_DT = ''' + @V_PAY_DT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,STAFF = ''' + @V_STAFF + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TOT_AMT = ''' + @V_TOT_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TAXN_AMT = ''' + @V_TAXN_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,INCOME_TAX = ''' + @V_INCOME_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,MAN_TAX = ''' + @V_MAN_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REPLY_CLS_CD = '''''
							SET @OPENQUERY = @OPENQUERY + '    ,PROC_YN = 0'
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @v_emp_no + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC (@OPENQUERY);
							
						END
					ELSE
						BEGIN
							print('인서트구문 실행')
							--INSERT INTO TB_FI312
							INSERT OPENQUERY(DEBIS, 'SELECT CLOSE_YM   
															 ,ACCT_DEPT_CD   
															 ,WITHHOLD_CLS_CD
															 ,WORK_SITE_CD
															 ,PAY_DT         
															 ,STAFF          
															 ,TOT_AMT        
															 ,TAXN_AMT       
															 ,INCOME_TAX     
															 ,MAN_TAX        
															 ,REPLY_CLS_CD     
															 ,PROC_YN        
															 ,REG_ID         
															 ,REG_DTM  
													     FROM TB_FI312 ') 
													 VALUES(    
															  @V_CLOSE_YM      
															 ,@V_ACCT_DEPT_CD   
															 ,@V_WITHHOLD_CLS_CD
															 ,@V_WORK_SITE_CD
															 ,@V_PAY_DT         
															 ,@V_STAFF          
															 ,@V_TOT_AMT        
															 ,@V_TAXN_AMT       
															 ,@V_INCOME_TAX     
															 ,@V_MAN_TAX        
															 ,''     
															 ,0       
															 ,@v_emp_no         
															 ,CONVERT(VARCHAR(10), GETDATE(), 112)   
															)
						END
					
	            END       
			
			FETCH NEXT FROM C_PBT_WITHHOOD_YETA INTO   @V_WORK_SITE_CD,
													   @V_COSTDPT_CD,
													   @V_SABUN_CNT,
													   @V_AOLWTOT_AMT,
													   @V_TAXFREEALOW,
													   @V_INCTAX,
													   @V_INGTAX
			
			END                                       
			CLOSE C_PBT_WITHHOOD_YETA  -- 연말정산원천세생성 종료
			DEALLOCATE C_PBT_WITHHOOD_YETA
        END
    ELSE IF @av_tax_kind_cd = 'D1' 
		BEGIN
        --중도정산
			SET @V_PAY_CD = 'P2102';
			
			BEGIN
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @av_tax_kind_cd + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '

				EXEC (@OPENQUERY)     
				
			END
			
			
        
			-- 퇴직중도정산
			-- CURSOR 선언(중간정산)
			DECLARE C_PBT_WITHHOOD_D1 CURSOR FOR    -- 원천세생성 데이터를 가져온다. 
			  SELECT A.REG_BIZ_CD
					,A.MAPCOSTDPT_CD  
					 ,COUNT(DISTINCT(A.EMP_ID)) AS SABUN_CNT      -- 총인원
					 ,SUM(A.AMT_RETR_PAY) AS AOLWTOT_AMT          -- 급여총액
					 ,SUM(A.TAXFREEALOW) AS TAXFREEALOW   -- 비과세
					 ,SUM(A.T01) AS INCTAX                -- 소득세
					 ,SUM(A.T02) AS INGTAX                -- 주민세  
			  FROM (
					   SELECT DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',A.C1_END_YMD,'ORG_ID'),A.C1_END_YMD) AS REG_BIZ_CD,
							   dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.PAY_YMD, '1') AS COST_CD,
							   (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD = A.COMPANY_CD AND COST_CD = dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.PAY_YMD, '1')
															   AND A.C1_END_YMD BETWEEN STA_YMD AND END_YMD) AS MAPCOSTDPT_CD,
								A.EMP_ID,
								A.C_01 AS AMT_RETR_PAY, -- 급여총액
								0 TAXFREEALOW,          -- 비과세
								A.R06_S AS INCTAX_OLD,                -- 소득세
								A.CT02 AS INHTAX_OLD,                 -- 주민세
								A.TRANS_INCOME_AMT INCTAX,     -- 과세이연소득세
								A.TRANS_RESIDENCE_AMT INHTAX,   -- 과세이연주민세
								A.T01, -- 차감소득세
								A.T02  -- 차감주민세
						  FROM REP_CALC_LIST A
						  JOIN PHM_PRIVATE PRI
							ON A.EMP_ID = PRI.EMP_ID
						   AND A.C1_END_YMD BETWEEN PRI.STA_YMD AND PRI.END_YMD
						 WHERE A.COMPANY_CD = @av_company_cd
						   AND PRI.FROM_TYPE_CD = @av_hrtype_cd -- 인력유형
						   AND FORMAT(A.C1_END_YMD, 'yyyyMM') = @V_YYYYMM
						   AND A.CALC_TYPE_CD IN ('01')--,'02') -- 퇴직, 중간정산
						   AND A.REP_MID_YN = 'Y' -- 중도정산
						   AND A.INS_TYPE_CD = '10' -- DB형
						   AND A.C_01 <> 0) A
			  GROUP BY A.REG_BIZ_CD
					,A.MAPCOSTDPT_CD  
			  ORDER BY A.REG_BIZ_CD
					,A.MAPCOSTDPT_CD  ;
	        
			OPEN C_PBT_WITHHOOD_D1
	        FETCH NEXT FROM C_PBT_WITHHOOD_D1 INTO    @V_WORK_SITE_CD,
													   @V_COSTDPT_CD,
													   @V_SABUN_CNT,
													   @V_AOLWTOT_AMT,
													   @V_TAXFREEALOW,
													   @V_INCTAX,
													   @V_INGTAX
			WHILE	@@fetch_status = 0
			BEGIN
				--IF(@@ROWCOUNT < 1)
				--	BEGIN
				--		GOTO ERR_HANDLER
				--	END
			
            
				-- 처리건수
				SET @V_CNT = @V_CNT+1;
				-- 원가부서
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
				-- 지급일자 
				SET @V_PAY_DT = dbo.XF_TO_CHAR_D(@ad_proc_date, 'yyyyMMdd')
				-- 총인원
				SET @V_STAFF = @V_SABUN_CNT;
				-- 급여총액
				SET @V_TOT_AMT = @V_AOLWTOT_AMT;
				-- 비과세(비과세를 과세로 변환)
				SET @V_TAXN_AMT = @V_AOLWTOT_AMT - @V_TAXFREEALOW;
				-- 직원　소득세
				SET @V_INCOME_TAX = @V_INCTAX;
				-- 직원　주민세
				SET @V_MAN_TAX = @V_INGTAX;
	            
				BEGIN
					SET @V_CNT_DUP = 0;
					SET @OPENQUERY = 'SELECT @V_CNT_DUP = CNT_DUP FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_DUP FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WORK_SITE_CD =  ''''' + @V_WORK_SITE_CD + ''''''') '
					PRINT(@OPENQUERY)
					EXEC sp_executesql @OPENQUERY, N'@V_CNT_DUP NUMERIC(3) OUTPUT', @V_CNT_DUP output
					
					IF @V_CNT_DUP > 0 -- 중복, 업데이트 수행
						BEGIN
							PRINT('업데이트구문 수행')
							SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT PAY_DT, STAFF, TOT_AMT, TAXN_AMT, INCOME_TAX, MAN_TAX '
							SET @OPENQUERY = @OPENQUERY + ' , REPLY_CLS_CD, PROC_YN, REG_ID, REG_DTM FROM TB_FI312 '
							SET @OPENQUERY = @OPENQUERY + 'WHERE ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WORK_SITE_CD = ''''' + @V_WORK_SITE_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''')' 
							SET @OPENQUERY = @OPENQUERY + ' SET PAY_DT = ''' + @V_PAY_DT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,STAFF = ''' + @V_STAFF + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TOT_AMT = ''' + @V_TOT_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TAXN_AMT = ''' + @V_TAXN_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,INCOME_TAX = ''' + @V_INCOME_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,MAN_TAX = ''' + @V_MAN_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REPLY_CLS_CD = '''''
							SET @OPENQUERY = @OPENQUERY + '    ,PROC_YN = 0'
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @v_emp_no + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC @OPENQUERY;
							 
						END
					ELSE
						BEGIN
							PRINT('인서트구문 수행')
							--INSERT INTO TB_FI312
							INSERT OPENQUERY(DEBIS, 'SELECT CLOSE_YM  
															 ,ACCT_DEPT_CD   
															 ,WITHHOLD_CLS_CD
															 ,WORK_SITE_CD
															 ,PAY_DT         
															 ,STAFF          
															 ,TOT_AMT        
															 ,TAXN_AMT       
															 ,INCOME_TAX     
															 ,MAN_TAX        
															 ,REPLY_CLS_CD     
															 ,PROC_YN        
															 ,REG_ID         
															 ,REG_DTM  
													     FROM TB_FI312 ')
												VALUES(    
														  @V_CLOSE_YM     
														 ,@V_ACCT_DEPT_CD   
														 ,@V_WITHHOLD_CLS_CD
														 ,@V_WORK_SITE_CD
														 ,@V_PAY_DT         
														 ,@V_STAFF          
														 ,@V_TOT_AMT        
														 ,@V_TAXN_AMT       
														 ,@V_INCOME_TAX     
														 ,@V_MAN_TAX        
														 ,''     
														 ,0       
														 ,@v_emp_no         
														 ,CONVERT(VARCHAR(10), GETDATE(), 112)   
													 );
						END      
				END    
	        FETCH NEXT FROM C_PBT_WITHHOOD_D1 INTO    @V_WORK_SITE_CD,
													   @V_COSTDPT_CD,
													   @V_SABUN_CNT,
													   @V_AOLWTOT_AMT,
													   @V_TAXFREEALOW,
													   @V_INCTAX,
													   @V_INGTAX             
			END                                       
			CLOSE C_PBT_WITHHOOD_D1  -- 원천세생성 종료
			DEALLOCATE C_PBT_WITHHOOD_D1
	END
  SET @av_ret_code = 'SUCCESS!';
  SET @av_ret_message = dbo.F_FRM_ERRMSG('원천세를 생성하였습니다..[ERR]' + ISNULL(ERROR_MESSAGE(),''),
                                        @v_program_id,  0000,  NULL, NULL);
	RETURN;
 ----------------------------------------------------------------------------------------------------------------------- 
	SET @v_error_note = '종료..!!!'
  ERR_HANDLER:
		PRINT('----------------------------------------------------')
		PRINT('ERR_HANDLER:')
		PRINT('V_CLOSE_YM:' + @V_CLOSE_YM)
		PRINT('V_YYYYMM:' + @V_YYYYMM)
		begin try
			CLOSE C_PBT_ACCNT_STD;
			CLOSE C_PBT_RET_RESULT;
			CLOSE C_PBT_WITHHOOD_D1;
			CLOSE C_PBT_WITHHOOD_YETA;
			
			DEALLOCATE	C_PBT_ACCNT_STD;
			DEALLOCATE	C_PBT_RET_RESULT;
			DEALLOCATE	C_PBT_WITHHOOD_D1;
			DEALLOCATE  C_PBT_WITHHOOD_YETA;
		end try
		
		begin catch
			print 'ERR_HANDLER:';
		end catch;

		SET @v_error_number = ERROR_NUMBER();
		SET @v_error_severity = ERROR_SEVERITY();
		SET @v_error_state = ERROR_STATE();
		SET @v_error_line = ERROR_LINE();
		SET @v_error_message = @v_error_note;
		SET @av_ret_code = 'FAILURE!';
		SET @av_ret_message = dbo.F_FRM_ERRMSG(@v_error_message + '[ERR]',
                                        @v_program_id,  0000,  NULL, NULL)
		PRINT('av_ret_message:' + @av_ret_message)
	RETURN

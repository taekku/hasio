USE dwehrdev
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/************************************************************************
 * SYSTEM명         : 동부그룹 신인사 시스템
 * SUB SYSTEM명     : 물류 원천세생성
 * PROCEDURE 명     : SP_WITHHOLD_E
 * DESCRIPTION      : 물류 원천세를 생성한다.
 * 사용 TABLE명     : 
 * IN  PARAMETER    : P_COMPANY        회사구분
 *                    P_YYYYMM         급여년월
 *                    P_CODE_GBN       코드구분
 *                    P_PROC_DATE      처리일자
 *                    P_ENDYM          마감년월
 *                    P_SABUN
 * OUT PARAMETER    : R_RESULT
 * IN OUT PARAMETER : N/A
 * 변경자     변경일자            변경사유
 *-----------------------------------------------------------------------
 * 박성진     2006-03-30          초기생성
  ************************************************************************/

--6363 2628 권정민 대리

CREATE PROCEDURE [dbo].[SP_DEBIS_WITHHOLD] 
(
     @P_COMPANY         VARCHAR(20)   -- 회사구분
    ,@P_HRTYPE_GBN      VARCHAR(20)   -- 인력유형 
    ,@P_CODE_GBN        VARCHAR(20)   -- 코드구분(급여 : A1, 상여 : B1, 연말정산 : E1, 퇴직정산 : C1 ,중도정산 : D1)
    ,@P_PROC_DATE       VARCHAR(20)   -- 처리일자
    ,@P_ENDYM           VARCHAR(20)   -- 마감년월 
   	,@P_SABUN           VARCHAR(20)   -- 처리자
    ,@p_error_code      VARCHAR(1000) OUTPUT				-- 에러코드 리턴
    ,@p_error_str       VARCHAR(3000) OUTPUT				-- 에러메시지 리턴
 ) 

AS
SET NOCOUNT ON
DECLARE
	-- 사용 변수선언
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
	--@LinkedServer				nvarchar(20) = 'DBTOP_P',
	
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


	BEGIN
	print('커서선언')	
	-- CURSOR 선언(급상여)
	
	SET @V_CNT = 0;
	SET @V_DEPT_TYPE = '';
	SET @V_COSTDPT_CD ='';
	SET @V_SABUN_CNT = 0;
	SET @V_AOLWTOT_AMT = 0;
	SET @V_TAXFREEALOW = 0;
	SET @V_INCTAX = 0;
	SET @V_INGTAX = 0;
 
    print('인력유형 실행 전')
    -- 인력유형에 대응하는 데비스회사코드
	BEGIN
		SET @V_CO_CD = NULL;
		SELECT @V_CO_CD = USER3  
			FROM B_DETAIL_CODE_COMPANY
			WHERE CD_COMPANY = @P_COMPANY
			AND CD_MASTER = 'HU513'
			AND CD_DETAIL = @P_HRTYPE_GBN;
	END
		
	
	
	print('인력유형 실행 후')       
    -- 마감년월
    SET @V_CLOSE_YM = @P_ENDYM;
    
    --코드구분( 연말정산 : E1) 전년 12월
    IF @P_CODE_GBN = 'E1'
		BEGIN
			IF SUBSTRING(@V_CLOSE_YM,5,2) <> '02'  --2월이 아니면 오류
				BEGIN
					SET @p_error_str = 'YETAERR';
					GOTO ERR_HANDLER
				END
        END    
    
    print('CNT_PROC 실행 전')
	PRINT('@V_CLOSE_YM : ' + @V_CLOSE_YM)
	PRINT('@V_CO_CD : ' + @V_CO_CD)
    SET @V_PROC_CNT = 0; 
  --  BEGIN
		--SET @OPENQUERY = 'SELECT @V_PROC_CNT = CNT_PROC FROM OPENQUERY('+ @LinkedServer + ','''
		--SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_PROC FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
		--SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
		--SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
		--SET @OPENQUERY = @OPENQUERY + '   AND (PROC_YN = 1 OR REPLY_CLS_CD <> ''''D''''))'') '
		
		--PRINT @OPENQUERY

		---- 수정중
		--EXEC sp_executesql @OPENQUERY, N'@V_PROC_CNT NUMERIC(5) OUTPUT', @V_PROC_CNT output
   
		--IF @V_PROC_CNT > 0
		--	BEGIN
		--		SET @p_error_str = 'ERROR';
		--			GOTO ERR_HANDLER
		--	END
  --  END 
    print('CNT_PROC 실행 후')
    
    --코드구분(급여 : A1) 마감년월의전월
	IF @P_CODE_GBN = 'A1'
		BEGIN
			IF @P_COMPANY = 'B'
				BEGIN
					SET @V_YYYYMM = @V_CLOSE_YM;
				END
			ELSE
				BEGIN
					IF (SUBSTRING(@P_PROC_DATE,7,2) in ( '25'))
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
    IF @P_CODE_GBN = 'B1'
		BEGIN
			SET @V_YYYYMM = @V_CLOSE_YM;
        END
    --코드구분( 연말정산 : E1) 전년 12월
    IF @P_CODE_GBN = 'E1'
		BEGIN
			SET @V_YYYYMM = SUBSTRING(CONVERT(VARCHAR(10), DATEADD(MONTH, -12, CONVERT(DATETIME, @V_CLOSE_YM + '01', 112)), 112), 1, 4) + '12'
		END
    --코드구분( 퇴직정산 : C1 ) 마감년월과동일한 전표생성년월
    IF @P_CODE_GBN = 'C1'
		BEGIN
			SET @V_YYYYMM = @V_CLOSE_YM; 
		END
    --코드구분(중도정산 : D1)  마감년월과동일
    IF @P_CODE_GBN = 'D1' OR @P_CODE_GBN = 'P1'
		BEGIN
			SET @V_YYYYMM = @V_CLOSE_YM;
			
		END 
    
    --코드구분
    SET @V_WITHHOLD_CLS_CD = @P_CODE_GBN;
    
    print('코드구분 실행 전')
    PRINT(@P_CODE_GBN)
    -- 코드구분이 급여일 경우  PI수당포함
    IF @P_CODE_GBN = 'A1'
		BEGIN
        -- 급여
			IF @P_COMPANY = 'B'
				BEGIN
					SET @V_PAY_CD = '002';  --급여
					SET @V_PAY_CD1 = '002';  --소급액
					SET @V_WITHHOLD_CLS_CD = 'A1';  --사무직급여
					print(@V_PAY_CD + ', ' + @V_PAY_CD1 + ', ' + @V_WITHHOLD_CLS_CD)
				END
			ELSE

			BEGIN
				IF (SUBSTRING(@P_PROC_DATE,7,2) in ( '25'))
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
	        PRINT('@P_COMPANY : ' + @P_COMPANY)
	        PRINT('@P_HRTYPE_GBN : ' + @P_HRTYPE_GBN)
	        PRINT('@V_YYYYMM : ' + @V_YYYYMM)
	        PRINT('@V_PAY_CD : ' + @V_PAY_CD)
	        PRINT('@V_PAY_CD : ' + @V_PAY_CD1)
			PRINT('@P_PROC_DATE : ' + @P_PROC_DATE)
	        
	        DECLARE C_PBT_WITHHOOD_E CURSOR FOR                                     -- 원천세생성 데이터를 가져온다. 
			SELECT A.WORK_SITE_CD                                               --근무지 
				  ,ISNULL(MAPCOSTDPT_CD,'XXXXX')  MAPCOSTDPT_CD                -- 원가부서
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
			 ORDER BY WORK_SITE_CD                                            --근무지 
					 ,MAPCOSTDPT_CD;                                          -- 원가부서  

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
				SET @V_PAY_DT = @P_PROC_DATE;
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
					SET @OPENQUERY = @OPENQUERY + '   AND PAY_DT = ''''' + @P_PROC_DATE + ''''''
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
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @P_SABUN + ''''
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
							PRINT('@P_SABUN : ' + CAST(@P_SABUN AS VARCHAR))
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
														 ,@P_SABUN         
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
		
    ELSE IF @P_CODE_GBN = 'B1'
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
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @P_CODE_GBN + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '
				
				EXEC (@OPENQUERY)      
			END
			
			PRINT('커서 수행 전')
			DECLARE C_PBT_WITHHOOD_E CURSOR FOR                                     -- 원천세생성 데이터를 가져온다. 
			SELECT A.WORK_SITE_CD                                               --근무지 
				  ,ISNULL(MAPCOSTDPT_CD,'XXXXX')  MAPCOSTDPT_CD                -- 원가부서
				  ,COUNT(DISTINCT(A.SABUN)) AS SABUN_CNT                       -- 총인원
				  ,SUM(A.ALOWTOT_AMT) AS AOLWTOT_AMT                           -- 급여총액
				  ,SUM(A.TAXFREEALOW_TOTAMT) AS TAXFREEALOW                    -- 비과세
				  ,SUM(A.INCTAX_AMT) AS INCTAX                                 -- 소득세
				  ,SUM(A.INHTAX_AMT) AS INGTAX 
			  FROM (SELECT A.CD_WORK_AREA AS WORK_SITE_CD     
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
					  AND A.YM_PAY = @V_YYYYMM
					  AND (A.FG_SUPP  = @V_PAY_CD OR A.FG_SUPP  = @V_PAY_CD1)
					  AND A.AMT_SUPPLY_TOTAL <> 0
					  AND (A.DT_PROV IN (@P_PROC_DATE, LEFT(@P_PROC_DATE, 6) + '11') AND 1 = CASE WHEN RIGHT(@P_PROC_DATE, 2) = '10' THEN 1 ELSE 0 END)
					  ) A
			 GROUP BY A.WORK_SITE_CD                                          --근무지 
					 ,MAPCOSTDPT_CD                                           -- 원가부서
			 ORDER BY WORK_SITE_CD                                            --근무지 
					 ,MAPCOSTDPT_CD;                                          -- 원가부서 

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
				SET @V_PAY_DT = @P_PROC_DATE;
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
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @P_SABUN + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC (@OPENQUERY);
						END
					ELSE
						BEGIN
						-- INSERT INTO TB_FI312
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
															 ,@P_SABUN         
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
		
    ELSE IF @P_CODE_GBN = 'P1'
		BEGIN
        --상여
			print('성과급!!!!!')
			SET @V_PAY_CD = '05';

			PRINT(@V_YYYYMM)
			PRINT(@V_PAY_CD)
			PRINT('--------')
			BEGIN
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @P_CODE_GBN + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '
				
				EXEC (@OPENQUERY)  
			END;
			
			DECLARE C_PBT_WITHHOOD_E CURSOR FOR                                     -- 원천세생성 데이터를 가져온다. 
			SELECT A.WORK_SITE_CD                                               --근무지 
				  ,ISNULL(MAPCOSTDPT_CD,'XXXXX')  MAPCOSTDPT_CD                -- 원가부서
				  ,COUNT(DISTINCT(A.SABUN)) AS SABUN_CNT                       -- 총인원
				  ,SUM(A.ALOWTOT_AMT) AS AOLWTOT_AMT                           -- 급여총액
				  ,SUM(A.TAXFREEALOW_TOTAMT) AS TAXFREEALOW                    -- 비과세
				  ,SUM(A.INCTAX_AMT) AS INCTAX                                 -- 소득세
				  ,SUM(A.INHTAX_AMT) AS INGTAX 
			  FROM (SELECT A.CD_WORK_AREA AS WORK_SITE_CD     
						  ,CASE D.BIZ_ACCT WHEN '00689' THEN '00177'   --선사영업팀장
										   ELSE  D.BIZ_ACCT     --END    
							END AS MAPCOSTDPT_CD 
						  ,A.CD_COST 
						  ,A.LVL_PAY1                                       -- 원가부서
						  ,A.NO_PERSON SABUN                                -- 총인원
						  ,A.AMT_SUPPLY_TOTAL ALOWTOT_AMT                   -- 급여총액
						  ,A.AMT_TAX_EXEMPTION1 + A.AMT_TAX_EXEMPTION2 + A.AMT_TAX_EXEMPTION3 + A.AMT_TAX_EXEMPTION4 + 
						   A.AMT_TAX_EXEMPTION5 + A.AMT_TAX_EXEMPTION6 + A.AMT_TAX_EXEMPTION7 + A.AMT_TAX_EXEMPTION8 TAXFREEALOW_TOTAMT -- 비과세
						  ,ISNULL(B.AMT_DEDUCT, 0) INCTAX_AMT                                     -- 소득세
						  ,ISNULL(C.AMT_DEDUCT, 0) INHTAX_AMT                                     -- 주민세         
					 FROM H_MONTH_PAY_BONUS A 
						  INNER JOIN H_HUMAN H ON A.CD_COMPANY = H.CD_COMPANY AND A.NO_PERSON = H.NO_PERSON
						  LEFT OUTER JOIN H_MONTH_DEDUCT B ON A.CD_COMPANY = B.CD_COMPANY AND A.NO_PERSON = B.NO_PERSON AND A.YM_PAY = B.YM_PAY AND A.FG_SUPP = B.FG_SUPP AND B.CD_DEDUCT = 'INC' AND A.DT_PROV = B.DT_PROV
						  LEFT OUTER JOIN H_MONTH_DEDUCT C ON A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON AND A.YM_PAY = C.YM_PAY AND A.FG_SUPP = C.FG_SUPP AND C.CD_DEDUCT = 'LOC' AND A.DT_PROV = C.DT_PROV
						  LEFT OUTER JOIN B_COST_CENTER D ON A.CD_COMPANY = D.CD_COMPANY AND A.CD_COST = D.CD_CC                                                               
					WHERE A.CD_COMPANY = @P_COMPANY
					  AND H.HRTYPE_GBN = @P_HRTYPE_GBN    -- 인력유형 
					  AND A.YM_PAY = @V_YYYYMM
					  AND A.FG_SUPP  = @V_PAY_CD
					  AND A.DT_PROV = @P_PROC_DATE
					  AND A.AMT_SUPPLY_TOTAL <> 0) A
			 GROUP BY A.WORK_SITE_CD                                          --근무지 
					 ,MAPCOSTDPT_CD                                           -- 원가부서
			 ORDER BY WORK_SITE_CD                                            --근무지 
					 ,MAPCOSTDPT_CD;                                          -- 원가부서 
			
			PRINT('배치수행 전')
			OPEN C_PBT_WITHHOOD_E  -- 커서 패치
			FETCH NEXT FROM C_PBT_WITHHOOD_E INTO    @V_WORK_SITE_CD,
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
				
				print('성과금 배치 시작')
				-- 처리건수
				SET @V_CNT = @V_CNT+1;    
				-- 원가부서
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
				-- 지급일자 
				SET @V_PAY_DT = @P_PROC_DATE;
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
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @P_SABUN + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC (@OPENQUERY);
						END
					ELSE
						BEGIN
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
														 ,@P_SABUN         
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
        DEALLOCATE C_PBT_WITHHOOD_E;
		END
	
    ELSE IF @P_CODE_GBN = 'C1'
		BEGIN
			--퇴직정산
			SET @V_PAY_CD = '';
			
			BEGIN
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @P_CODE_GBN + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '
				
				EXEC (@OPENQUERY)  
			END
			
			--퇴직정산
			PRINT('CURSOR 선언(퇴직정산)')
			                                           -- 원천세생성 데이터를 가져온다. 
			DECLARE C_PBT_RET_RESULT CURSOR FOR    
			   SELECT A.WORK_SITE_CD
					 ,A.MAPCOSTDPT_CD  
					 ,COUNT(DISTINCT(A.SABUN)) AS SABUN_CNT      -- 총인원
					 ,SUM(A.AMT_RETR_PAY) AS AOLWTOT_AMT          -- 급여총액
					 ,0 AS TAXFREEALOW   -- 비과세
					 ,SUM(A.INCTAX) AS INCTAX                -- 소득세
					 ,SUM(A.INHTAX) AS INGTAX                -- 주민세  
					 ,SUM(A.INCTAX_OLD) AS INCTAX_OLD        -- 원본소득세
					 ,SUM(A.INHTAX_OLD) AS INHTAX_OLD        -- 원본주민세
				FROM ( 
					   SELECT ISNULL(C.CD_WORK_AREA, '') AS WORK_SITE_CD
							  ,CASE B.BIZ_ACCT WHEN '00689' THEN '00177' --선사영업팀장
											   ELSE  B.BIZ_ACCT   --END    
								END AS      MAPCOSTDPT_CD 
							 ,A.NO_PERSON SABUN                      -- 총인원
							 ,A.AMT_RETR_PAY                    -- 급여총액
							 ,0 AS TAXFREEALOW                  -- 비과세
							 ,A.AMT_FIX_STAX  INCTAX_OLD              -- 소득세
							 ,A.AMT_FIX_JTAX  INHTAX_OLD              -- 주민세
							 /* 과세이연 -퇴직연금대상자 */
							 ,CASE WHEN A.NO_PERSON = '20160325' THEN 0 
								   ELSE CASE WHEN SUBSTRING(dbo.fn_GetDongbuCode('HU010', A.LVL_PAY1), 1, 4) IN ('H120','H121') THEN 0 
											 ELSE CASE WHEN ISNULL(A.POSTPONE_TAX,0) = 0 THEN A.POSTPONE_TAX -- 소득세
													   ELSE 0 
												   END 
										  END
								END INCTAX 
							 ,CASE WHEN A.NO_PERSON = '20160325' THEN 0
								   ELSE CASE WHEN SUBSTRING(dbo.fn_GetDongbuCode('HU010', A.LVL_PAY1), 1, 4) IN ('H120','H121') THEN 0 
											 ELSE CASE WHEN ISNULL(FLOOR(A.POSTPONE_TAX / 10),0) = 0  THEN FLOOR(A.POSTPONE_TAX / 10) -- 주민세
													   ELSE 0 
												   END 
									     END
							   END INHTAX              
						 FROM H_RETIRE_DETAIL A
							  INNER JOIN H_HUMAN C
							     ON A.CD_COMPANY = C.CD_COMPANY
							    AND A.NO_PERSON = C.NO_PERSON
							  LEFT OUTER JOIN B_COST_CENTER B
							    ON B.CD_CC = C.CD_CC
							   AND B.CD_COMPANY = C.CD_COMPANY
						WHERE A.CD_COMPANY = @P_COMPANY
						  AND C.HRTYPE_GBN = @P_HRTYPE_GBN -- 인력유형 
						  AND SUBSTRING(A.DT_BASE,1,6) = @V_YYYYMM
						  AND A.FG_RETR IN ('1','3')
						  AND A.YN_MID <> 'Y'
						  AND A.FG_RETPENSION_KIND = 'DB'
						  AND A.AMT_RETR_PAY <> 0) A
				GROUP BY A.WORK_SITE_CD
						,A.MAPCOSTDPT_CD  
				ORDER BY A.WORK_SITE_CD
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
				SET @V_PAY_DT = @P_PROC_DATE;
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
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @P_SABUN + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC (@OPENQUERY);
						END
					ELSE
						BEGIN
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
															 ,@P_SABUN         
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
        
    ELSE IF @P_CODE_GBN = 'E1'
		BEGIN
			--연말정산
			SET @V_PAY_CD = 'P2101';

			BEGIN
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @P_CODE_GBN + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '
				print(@OPENQUERY)
				EXEC (@OPENQUERY)   
			END
        
            --연말정산 원천세 신고
			
			PRINT('@P_COMPANY : ' + @P_COMPANY);
			PRINT('@P_HRTYPE_GBN : ' + @P_HRTYPE_GBN);
			PRINT('@V_YYYYMM : ' + @V_YYYYMM);


			-- CURSOR 선언(연말정산)
		    DECLARE C_PBT_WITHHOOD_YETA CURSOR FOR    -- 원천세생성 데이터를 가져온다. 
				SELECT   A.WORK_SITE_CD
					    ,A.MAPCOSTDPT_CD  
						,COUNT(DISTINCT(A.SABUN)) AS SABUN_CNT      -- 총인원
						,SUM(A.INC_TOTAMT) AS AOLWTOT_AMT          -- 급여총액
						,SUM(A.AMT_BITAX_TOT) AS TAXFREEALOW   -- 비과세
						,SUM(A.AMT_NEW_STAX) AS INCTAX                -- 소득세
						,SUM(A.AMT_NEW_JTAX) AS INGTAX                -- 주민세  
				  FROM (
						SELECT H.CD_WORK_AREA AS WORK_SITE_CD
						   ,CASE B.BIZ_ACCT WHEN '00689' THEN '00177' --선사영업팀장
		--                                ELSE case WHEN A.JIKGUB_CD = 'H12A1' and A.COSTDPT_CD <> 'B200' THEN '00194' --고속기사는 고속공통으로처리(HR소속제외)
											 ELSE  B.BIZ_ACCT   --END    
										END AS      MAPCOSTDPT_CD 
						   ,A.NO_PERSON SABUN     -- 총인원
						   ,(A.AMT_INCOME) AS INC_TOTAMT        -- 급여총액
						   ,A.AMT_BITAX_TOT               -- 비과세
						   ,A.AMT_NEW_STAX                -- 소득세
						   ,A.AMT_NEW_JTAX                -- 주민세         
					   FROM H_ADJUSTMENT_DETAIL A 
					        INNER JOIN H_HUMAN H 
					           ON A.CD_COMPANY = H.CD_COMPANY 
					          AND A.NO_PERSON = H.NO_PERSON 
							LEFT OUTER JOIN B_COST_CENTER B
							  ON H.CD_CC = B.CD_CC     
							 AND H.CD_COMPANY = B.CD_COMPANY
							LEFT OUTER JOIN H_MONTH_PAY_BONUS D
							  ON A.CD_COMPANY= D.CD_COMPANY 
							 AND A.NO_PERSON = D.NO_PERSON  
							 AND A.YM_PROV = D.YM_PAY
							 AND dbo.fn_GetDongbuCode('HU109', D.FG_SUPP) IN ('P0501', 'P0503')                                      
					  WHERE A.CD_COMPANY = @P_COMPANY
						AND H.HRTYPE_GBN = @P_HRTYPE_GBN -- 인력유형 
						AND A.YY_YEAR = LEFT(@V_YYYYMM, 4)
					--	AND A.SETTLEMT_CD = @V_PAY_CD
						AND A.AMT_INCOME <> 0) A
			  GROUP BY  A.WORK_SITE_CD
					   ,A.MAPCOSTDPT_CD  
			  ORDER BY  A.WORK_SITE_CD
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
				SET @V_PAY_DT = @P_PROC_DATE;
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
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @P_SABUN + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC (@OPENQUERY);
							
						END
					ELSE
						BEGIN
							print('인서트구문 실행')
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
															 ,@P_SABUN         
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
    ELSE IF @P_CODE_GBN = 'D1' 
		BEGIN
        --중도정산
			SET @V_PAY_CD = 'P2102';
			
			BEGIN
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @P_CODE_GBN + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '

				EXEC (@OPENQUERY)     
				
			END
			
			
        
			-- 퇴직중도정산
			-- CURSOR 선언(중간정산)
			DECLARE C_PBT_WITHHOOD_D1 CURSOR FOR    -- 원천세생성 데이터를 가져온다. 
			  SELECT A.WORK_SITE_CD
					,A.MAPCOSTDPT_CD  
					 ,COUNT(DISTINCT(A.SABUN)) AS SABUN_CNT      -- 총인원
					 ,SUM(A.INC_TOTAMT) AS AOLWTOT_AMT          -- 급여총액
					 ,SUM(A.AMT_BITAX_TOT) AS TAXFREEALOW   -- 비과세
					 ,SUM(A.AMT_NEW_STAX) AS INCTAX                -- 소득세
					 ,SUM(A.AMT_NEW_JTAX) AS INGTAX                -- 주민세  
			  FROM (
					SELECT  ISNULL(H.CD_WORK_AREA, '') AS WORK_SITE_CD
						   ,CASE B.BIZ_ACCT WHEN '00689' THEN '00177' --선사영업팀장
										   ELSE  B.BIZ_ACCT   --END    
							 END AS MAPCOSTDPT_CD  
						   ,C.NO_PERSON SABUN    -- 총인원					   
						   ,C.AMT_INCOME INC_TOTAMT      -- 급여총액
						   ,C.AMT_BITAX_TOT -- 비과세
						   ,C.AMT_NEW_STAX                -- 소득세
						   ,C.AMT_NEW_JTAX                -- 주민세       
					   FROM H_RETIRE_DETAIL A
							INNER JOIN H_HUMAN H
							   ON A.CD_COMPANY = H.CD_COMPANY
							  AND A.NO_PERSON = H.NO_PERSON
							LEFT OUTER JOIN B_COST_CENTER B
							  ON H.CD_CC = B.CD_CC
							 AND H.CD_COMPANY = B.CD_COMPANY  
							LEFT OUTER JOIN H_ADJUSTMENT_DETAIL C
							  ON A.CD_COMPANY = C.CD_COMPANY
							 AND A.NO_PERSON = C.NO_PERSON
							 AND C.FG_HALFWAY = 'Y'          -- 중도정산 
							 AND LEFT(A.DT_BASE, 4) = C.YY_YEAR             
					  WHERE A.CD_COMPANY = @P_COMPANY
						AND H.HRTYPE_GBN = @P_HRTYPE_GBN -- 인력유형 
						AND SUBSTRING(A.DT_BASE,1,6) = @V_YYYYMM
						AND A.FG_RETR IN ('1')
						AND C.AMT_INCOME <> 0) A
			  GROUP BY A.WORK_SITE_CD
					,A.MAPCOSTDPT_CD  
			  ORDER BY A.WORK_SITE_CD
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
				SET @V_PAY_DT = @P_PROC_DATE;
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
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @P_SABUN + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC @OPENQUERY;
							 
						END
					ELSE
						BEGIN
							PRINT('인서트구문 수행')
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
														 ,@P_SABUN         
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
  SET @p_error_code = '0';
	 

  RETURN
 ----------------------------------------------------------------------------------------------------------------------- 
  ERR_HANDLER:
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

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;

	EXECUTE p_ba_errlib_getusererrormsg 'X', 'SP_DEBIS_WITHHOLD',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message
	RETURN
END	

USE [dwehrdev]
GO
/****** Object:  StoredProcedure [dbo].[SP_DEBIS_INSERT]    Script Date: 2020-12-14 오후 4:45:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/************************************************************************
 * SYSTEM명         : 동부그룹 신인사 시스템
 * SUB SYSTEM명     : 물류 전표이체
 * PROCEDURE 명     : SP_TRE_INSERT
 * DESCRIPTION      : 물류 전표이체를 생성한다.
 * 사용 TABLE명     : 
 * IN  PARAMETER    : P_COMPANY        회사구분
 *                    P_PROC_DATE      처리일자
 *                    P_BILL_GBN       전표구분  
 *                    P_SABUN
 * OUT PARAMETER    : R_RESULT
 * IN OUT PARAMETER : N/A
 * 변경자     변경일자            변경사유
 *-----------------------------------------------------------------------
 * 박성진     2006-03-29          초기생성
  ************************************************************************/

/*************************************************************************

 DECLARE
     @p_error_code VARCHAR(30),
     @p_error_str VARCHAR(30)
 BEGIN
	  EXECUTE p_at_pay_debis_interface 'X'
	                                 ,'H8301'
                                    ,'P5101'
	                                 ,'201805'
	                                 ,'01'
	                                 ,'20180822'
	                                 ,'20130054'
	                                 ,@p_error_code output
	                                 ,@p_error_str output
 END
***************************************************************************/


ALTER PROCEDURE [dbo].[SP_DEBIS_INSERT] (
					  @P_COMPANY         VARCHAR(20)   -- 회사구분 (E: 익스프레스, 단독)
					 ,@P_HRTYPE_GBN      VARCHAR(20)   -- 인력유형 (자회사냐? 익스프레스냐? H8301 익스프레스, H8306 DIMT 확인필요 2가지만 사용중) 
					 ,@P_PROC_DATE       VARCHAR(20)   -- 처리일자 (급여일자인데 기능직의 경우 해당 급여월로.... 6/10일 지급일일 경우 5/10)
					 ,@P_BILL_GBN        VARCHAR(20)   -- 전표구분 (급여전표, 상여전표, 건강보험전표, 국민연금전표 * 2, PI전표(?)) 
					 ,@P_SABUN           VARCHAR(20)   -- 처리자 
					 ,@p_error_code      VARCHAR(1000) OUTPUT				-- 에러코드 리턴
                     ,@p_error_str       VARCHAR(3000) OUTPUT				-- 에러메시지 리턴
                   )                                                                              
AS
SET NOCOUNT ON
DECLARE
  -- 사용 변수선언
    @V_WRTDPT_CD             VARCHAR(40),         -- 작성부서
    @V_BILL_GBN              VARCHAR(40),         -- 전표구분
    @V_TRDTYP_CD             VARCHAR(40),         -- 거래유형
    @V_ACCNT_CD              VARCHAR(40),         -- 계정코드
    @V_SEQ_BILL              NUMERIC(5,0),        -- 순번
    @V_AMT_BILL              NUMERIC(13,0),       -- 금액
    @V_CUST_CD               VARCHAR(40),         -- 거래처코드
    @V_DEBSER_GBN            VARCHAR(40),         -- 차대구분(차변/대변)
    @V_COSTDPT_CD            VARCHAR(40),         -- 원가부서
    @V_TRDTYP_NM             VARCHAR(500),        -- 거래명
    @V_SUMMARY_BILL          VARCHAR(500),        -- 적요
    @V_PROC_DT               VARCHAR(40),         -- 처리일자
    @V_BANK_CD               VARCHAR(40),         -- 은행코드
    @V_PAYMTWAY              VARCHAR(40),         -- 지불수단
    @V_SABUN                 VARCHAR(12),         -- 사번
    
    @V_CUST_CHK              VARCHAR(1) = 'N',  
    
    @V_CO_CD                 VARCHAR(3),          -- 데비스회사코드
    
    @V_SAL_PAY_DT            VARCHAR(8),          -- 급여지급일자       
    @V_SAL_PAY_CLS_CD        VARCHAR(1),          -- 급여지급구분코드
    @V_PERS_CLS_CD           VARCHAR(2),          -- 직원구분코드    
    @V_DRAW_ACCT_DEPT_CD     VARCHAR(5),          -- 작성귀속부서코드
    @V_DRCR_CLS_CD           VARCHAR(1),          -- 차대구분코드    
    @V_ACCT_DEPT_CD          VARCHAR(5),          -- 귀속부서코드    
    @V_ACCT_CD               VARCHAR(7),          -- 계정코드        
    @V_SEQ                   NUMERIC(5, 0),       -- 순번            
    @V_PAY_BANK_CD           VARCHAR(2),          -- 지급은행코드    
    @V_PCOST_DIV             VARCHAR(5),          -- 원가부문        
    @V_ACCT_NM               VARCHAR(100),        --TB_FI403.ACCT_NM%TYPE,               -- 계정명          
    @V_AMT                   NUMERIC(13, 0),      -- 금액            
    @V_CLNT_NO               VARCHAR(100),        --TB_FI403.CLNT_NO%TYPE,               -- 거래처번호      
    @V_SUMMARY               VARCHAR(100),        -- 적요            
    @V_REQ_PAY_MTHD_CD       VARCHAR(2),          -- 요청지급방법코드
    @V_PAY_DT                VARCHAR(8),          -- 지급일자        
    @V_OUTBR_SLIP_NO         VARCHAR(10),         -- 발생전표번호    
    @V_PAY_SLIP_NO           VARCHAR(10),         -- 지급전표번호    
    @V_SND_CLS_CD            VARCHAR(1),          -- 전송구분코드    
    @V_REPLY_CLS_CD          VARCHAR(1),          -- 응답구분코드    
    @V_SND_DT                VARCHAR(8),          -- 전송일자        
    @V_SND_HH                VARCHAR(6),          -- 전송시간  
    
    @V_BILL_USER1            VARCHAR(100),        -- 코드명
    @V_BILL_USER2            VARCHAR(100),        -- 코드명
    @V_WDPTMAP_USER1         VARCHAR(20),         -- 작성부서명
    @V_BANK_USER1            VARCHAR(100),        -- 은행코드
    @V_COSTMAP_USER1         VARCHAR(20),         -- 원가부서 매핑코드
    @ACCT_DEPT_CD            VARCHAR(20),         -- 자회사 도입
    
    @V_CLNT_MGNT_YN	         NUMERIC(1, 0) = 0,   --거래처관리여부(1:관리,0 : 미관리) 
    
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
	@v_error_note				VARCHAR(3000),
    
    @OPENQUERY			     nvarchar(4000), 
	@TSQL					 nvarchar(4000), 
	--@LinkedServer			 nvarchar(20) = 'DEBISDEV'; 
	@LinkedServer			 nvarchar(20) = 'DEBIS'; 

BEGIN TRY
	/* 변수에 대한 초기화 처리 */
	SET @v_error_code = '';
	SET @v_error_note = '';
	PRINT('시작')
	
    -- 인력유형에 대응하는 데비스회사코드
	BEGIN
		SELECT @V_CO_CD = USER3
		  FROM B_DETAIL_CODE_COMPANY
		 WHERE CD_COMPANY = @P_COMPANY
		   AND CD_MASTER = 'HU513'
		   AND CD_DETAIL = @P_HRTYPE_GBN;
    END 
    
	 
	 -- 생성된 전표삭제처리를 위한 급여지급구분코드 
     BEGIN
		SELECT @V_BILL_USER1 = USER1
              ,@V_BILL_USER2 = USER2  
          FROM B_DETAIL_CODE_COMPANY
         WHERE CD_COMPANY = @P_COMPANY
           AND CD_MASTER = 'HU443'
           AND CD_DETAIL = @P_BILL_GBN;
     END 
     -- 급여지급구분코드      
     SET @V_SAL_PAY_CLS_CD = SUBSTRING(@V_BILL_USER2, 1, 1);
	
	 -- 직원구분코드
	 SET @V_PERS_CLS_CD =  SUBSTRING(@V_BILL_USER1, 1, 2);
	 PRINT('삭제쿼리전')
     BEGIN		
		SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
		SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI403 where SAL_PAY_DT = ''''' + @P_PROC_DATE + ''''' '
		SET @OPENQUERY = @OPENQUERY + ' AND SAL_PAY_CLS_CD = ''''' + @V_SAL_PAY_CLS_CD + ''''' AND PERS_CLS_CD = ''''' + @V_PERS_CLS_CD + ''''' '
		SET @OPENQUERY = @OPENQUERY + ' AND (REPLY_CLS_CD = ''''' + 'D' + ''''' OR REPLY_CLS_CD IS NULL )'
		SET @OPENQUERY = @OPENQUERY + ' AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 WHERE ACCT_YEAR = ''''' + SUBSTRING(@P_PROC_DATE, 1, 4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''')'')'
		EXEC (@OPENQUERY)
     END
	 
	 PRINT('삭제쿼리후')
     --순번 초기화
     SET @V_SEQ = 0;
     -- 전표생성테이블에서 이체할 데이터를 가져온다.
     
     -- CURSOR 선언
   	DECLARE C_PBT_BILL_CREATE CURSOR FOR -- 전표생성 데이터를 가져온다. 
		SELECT  WRTDPT_CD
		       ,BILL_GBN
		       ,ACCNT_CD
		       ,SEQ
		       ,AMT
		       ,CASE DEBSER_GBN WHEN '40' THEN 'C'
								WHEN '50' THEN 'D'
				 END DEBSER_GBN
			   ,CUST_CD
			   ,COSTDPT_CD
			   ,SUMMARY
			   ,PROC_DT
			   ,BANK_CD
			   ,PAYMTWAY
		  FROM PBT_BILL_CREATE
		 WHERE COMPANY  = @P_COMPANY
		   AND HRTYPE_GBN = @P_HRTYPE_GBN
		   AND BILL_GBN = @P_BILL_GBN
		   AND PROC_DT  = @P_PROC_DATE;
             
    OPEN C_PBT_BILL_CREATE  -- 커서 패치
    FETCH NEXT FROM C_PBT_BILL_CREATE INTO   @V_WRTDPT_CD,
											 @V_BILL_GBN,
											 @V_ACCNT_CD,
											 @V_SEQ_BILL,
											 @V_AMT_BILL,
											 @V_DEBSER_GBN,
											 @V_CUST_CD,
											 @V_COSTDPT_CD,
											 @V_SUMMARY_BILL,
											 @V_PROC_DT,
											 @V_BANK_CD,
											 @V_PAYMTWAY
	WHILE	@@fetch_status = 0
    BEGIN
		PRINT('커서 수행')
         -- 변수초기화  
         SET @V_BILL_USER1     = '';  --   VARCHAR2(100);  -- 코드명
         SET @V_BILL_USER2     = '';  --   VARCHAR2(100);  -- 코드명
         SET @V_WDPTMAP_USER1  = '';  --   VARCHAR2(20);   -- 작성부서명
         SET @V_BANK_USER1     = '';  --   VARCHAR2(100);  -- 은행코드
         SET @V_COSTMAP_USER1  = '';  --   VARCHAR2(20);   -- 원가부서 매핑코드
         SET @V_CLNT_NO        = '';  --                   --거래처
         
         
         -- 급여지급일자 
         SET @V_SAL_PAY_DT = @P_PROC_DATE;
         
         -- 급여지급구분코드
         BEGIN
			SELECT @V_BILL_USER1 = USER1
                  ,@V_BILL_USER2 = USER2  
			  FROM B_DETAIL_CODE_COMPANY
			 WHERE CD_COMPANY = @P_COMPANY
			   AND CD_MASTER = 'HU443'
			   AND CD_DETAIL = @P_BILL_GBN;
         END 
         
         PRINT('@V_BILL_USER1 : ' + @V_BILL_USER1)
         PRINT('@V_BILL_USER2 : ' + @V_BILL_USER2)
	        
	     SET @V_SAL_PAY_CLS_CD = SUBSTRING(@V_BILL_USER2, 1, 1);
	
	     -- 직원구분코드
	     SET @V_PERS_CLS_CD =  SUBSTRING(@V_BILL_USER1, 1, 2);
	        
	     -- 작성귀속부서코드
	     SET @V_DRAW_ACCT_DEPT_CD = @V_COSTDPT_CD;
	     
	    
	     PRINT '@@V_SAL_PAY_CLS_CD : ' + @V_SAL_PAY_CLS_CD
	     PRINT '@@V_PERS_CLS_CD : ' + @V_PERS_CLS_CD
	     PRINT '@V_COSTDPT_CD : ' + @V_COSTDPT_CD
	     PRINT '@V_DRAW_ACCT_DEPT_CD : ' + @V_DRAW_ACCT_DEPT_CD
	        
	        -- 차대구분코드(물류와 건설은 반대)
	     SET @V_DRCR_CLS_CD = @V_DEBSER_GBN;
	     IF  @V_DRCR_CLS_CD  = 'D'
			BEGIN
				SET @V_DRCR_CLS_CD  = 'C';
			END	
	     ELSE
			BEGIN
	            SET @V_DRCR_CLS_CD  = 'D';
	        END 
	    
	    PRINT('@V_DRCR_CLS_CD : ' + @V_DRCR_CLS_CD);
	    
	    -- 귀속부서코드
        BEGIN
			SELECT @V_WDPTMAP_USER1 = BIZ_ACCT  
              FROM B_COST_CENTER
             WHERE CD_COMPANY = @P_COMPANY
               AND CD_CC = @V_WRTDPT_CD;
        END 
        
        PRINT('@V_WDPTMAP_USER1 : ' + @V_WDPTMAP_USER1);
	        
	    SET @V_ACCT_DEPT_CD = SUBSTRING(@V_WDPTMAP_USER1, 1, 6);

		PRINT('@V_ACCT_DEPT_CD : ' + @V_ACCT_DEPT_CD);
	        
        -- 계정코드
        SET @V_ACCT_CD = SUBSTRING(@V_ACCNT_CD, 1, 7);
        --미지급비용-거래처(2100810)인 경우 지불수단 입력 여부체크
        print(@V_ACCT_CD)
        IF @V_ACCT_CD = '2100810'
			BEGIN
				IF ISNULL(@V_PAYMTWAY, '') = ''
					BEGIN
						SET @p_error_code = 'E1';
						--PRINT('ERROR @V_PAYMTWAY: ' + @V_PAYMTWAY)
						PRINT('111');
						PRINT(@V_SEQ_BILL);
						PRINT('@SEQ : ' + CAST(@V_SEQ_BILL AS VARCHAR));
						GOTO ERR_HANDLER;
					END
			END 
	        
	        -- 순번
	        SET @V_SEQ = @V_SEQ +1;
	        
	        -- 지급은행코드  
	   --     BEGIN
				--SELECT @V_BANK_USER1 = USER1  
				--  FROM COT_CODE_INFO
				-- WHERE COMPANY_CD = @P_COMPANY
				--   AND CODE = @V_BANK_CD;
	   --     END 
	 
	        --SET @V_PAY_BANK_CD = SUBSTRING(@V_BANK_USER1, 1, 2);
	        
	        -- 원가부문
	        BEGIN
				SELECT @V_COSTMAP_USER1 = BIZ_ACCT  
				  FROM B_COST_CENTER
				 WHERE CD_COMPANY = @P_COMPANY
				   AND CD_CC = @V_COSTDPT_CD;
	        END

	        SET @V_PCOST_DIV = SUBSTRING(@V_COSTMAP_USER1, 1, 6);
	        
	                
	        -- 계정명
	        BEGIN
				SELECT @V_ACCT_NM = NM_ACCNT  
                  FROM H_ACCOUNT
                 WHERE CD_COMPANY = @P_COMPANY
                   AND CD_ACCNT = @V_ACCNT_CD;
	        END
	        
	        -- 금액
	        SET @V_AMT = @V_AMT_BILL;
	        
	        BEGIN
				SELECT @V_CLNT_NO = USER1 
                  FROM B_DETAIL_CODE_COMPANY
                 WHERE CD_COMPANY = @P_COMPANY
                   AND CD_MASTER = 'HU514'
                   AND CD_DETAIL = @V_CUST_CD;
                   
                IF @@ROWCOUNT < 1 
					BEGIN
						SET @V_CLNT_NO = @V_CUST_CD;
					END    
	        END
	        PRINT('@V_CUST_CD : ' + @V_CUST_CD)
	        PRINT('@V_CLNT_NO : ' + CAST(@V_CLNT_NO AS VARCHAR))
	        
	        --DEBIS 거래처번호체크
	        SET @V_CUST_CHK = 'Y';
	        IF ISNULL(@V_CLNT_NO, '') <> ''
				BEGIN
					SET @V_CUST_CHK = 'N';
					
				    SET @OPENQUERY = 'SELECT @V_CUST_CHK = CUST_CHK FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT ''''Y'''' CUST_CHK FROM TB_ZZ510 where CLNT_NO = ''''' + @V_CLNT_NO + ''''' AND CLNT_DEL_YN = 0'')'
					EXEC sp_executesql @OPENQUERY, N'@V_CUST_CHK nvarchar(5) OUTPUT', @V_CUST_CHK output

					IF @@ROWCOUNT < 1
						BEGIN
							SET @V_CUST_CHK = 'N'
						END
					PRINT('거래처번호 : ' + @V_CLNT_NO)
					PRINT('@V_CUST_CHK : ' + @V_CUST_CHK)
				END
				
    	    PRINT('@V_CUST_CHK : ' + @V_CUST_CHK)
    	      
	        IF @V_CUST_CHK = 'N' 
				BEGIN 
					SET @p_error_code = 'E2';
					PRINT('ERROR @V_CUST_CHK : ' + @V_CUST_CHK)
					GOTO ERR_HANDLER;
				END
	        
	        
	        
	        --미지급비용-거래처(2100810)인 경우 거래처입력여부 체크
	        IF @V_ACCT_CD = '2100810'
				BEGIN 
					IF @V_CLNT_NO  IS NULL OR @V_CLNT_NO =''
						BEGIN
							SET @p_error_code = 'E2'
							PRINT('ERROR @V_CLNT_NO, @V_CLNT_NO: ' + @V_CLNT_NO + ', ' + @V_CLNT_NO)
							GOTO ERR_HANDLER;
						END	
	            END 
	        
	        -- 적요
	        SET @V_SUMMARY = @V_SUMMARY_BILL;
	        
	        -- 요청지급방법코드
	        SET @V_REQ_PAY_MTHD_CD = SUBSTRING(@V_PAYMTWAY, 1, 2);
	        
	        -- 지급일자 (요청지급방법코드가 경비이체(20), 급여이체(70)인 경우 지급일자 SETTING
	        SET @V_PAY_DT = '';
	        IF @V_PAYMTWAY = '20' OR @V_PAYMTWAY = '70'
				BEGIN
					IF @V_SAL_PAY_CLS_CD = 'B'
						BEGIN
							SET @V_PAY_DT = @V_PROC_DT;   --상여는 그대로처리
						END	
					ELSE
						BEGIN
							IF (SUBSTRING(@V_PROC_DT, 7, 2) = '10')
								BEGIN
									SET @V_PAY_DT = CONVERT(VARCHAR(10), DATEADD(MONTH, 1, GETDATE()), 112) --익월구하기
								END
							ELSE
								BEGIN
									SET @V_PAY_DT = @V_PROC_DT;   --사무직은 그대로 처리
								END
						END
				END
				
	        -- 발생전표번호
	        SET @V_OUTBR_SLIP_NO = '';
	        
	        -- 지급전표번호
	        SET @V_PAY_SLIP_NO = '';
	        
	        -- 전송구분코드
	        SET @V_SND_CLS_CD = '0';
	        
	        -- 응답구분코드
	        SET @V_REPLY_CLS_CD = '';
	        
	        -- 전송일자
	        BEGIN
				SET @V_SND_DT = CONVERT(VARCHAR(10), GETDATE(), 112)
            END
         
         -- 전송시간
           BEGIN
             SET @V_SND_HH = REPLACE(CONVERT(VARCHAR(10), GETDATE(), 8), ':', '')
           END
          
		   PRINT('AA');	
		   
           /* 거래처필수 계정확인 */
           SET @V_CLNT_MGNT_YN = 0;                      --거래처관리여부(1:관리,0 : 미관리)    
           BEGIN    
				SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT CLNT_MGNT_YN FROM TB_FI001 where ACCT_CD = ''''' + @V_ACCT_CD + ''''''')'
				EXEC sp_executesql @OPENQUERY, N'@V_CLNT_MGNT_YN nvarchar(5) OUTPUT', @V_CLNT_MGNT_YN output
           END
           
           PRINT('BB')
           
           IF @V_CLNT_MGNT_YN = 1
				BEGIN
				  IF ISNULL(@V_CLNT_NO, '') = '' 
					 SET @V_CLNT_NO = '999912';    --인사공통거래처 
				END
           /* 거래처필수 계정확인 종료 */     
           
/*  H83	인력유형구분	데비스회사코드
    H8301	EXPRESS	000
    H8302	DPCT	  007
    H8303	TOC	
    H8304	NTS	    001
    H8305	대성	  003
    H8306	DIMT	  011
    H8307	DBEX U.S.A	017
    H8308   BIDC	023
*/		
		PRINT('CC')
		IF @P_HRTYPE_GBN = 'H8301' 
			BEGIN   
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO =''
					BEGIN 
						SET @V_CLNT_NO = '999912';    --인사공통거래처 
					END
             END               
           
		IF @P_HRTYPE_GBN = 'H8304'
			BEGIN 
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO ='' 
					BEGIN
						SET @V_CLNT_NO = '999914';    --NTS인사공통거래처 
					END	
			END;           

		IF @P_HRTYPE_GBN = 'H8305'
			BEGIN 
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO =''
					BEGIN 
						SET @V_CLNT_NO = '999915';    --대성인사공통거래처 
					END
			END;

		IF @P_HRTYPE_GBN = 'H8306'
			BEGIN 
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO =''
					BEGIN  
						SET @V_CLNT_NO = '999916';    --DIMT 인사공통거래처
					END
			END;
		
		IF @P_HRTYPE_GBN = 'H8308'
			BEGIN 
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO =''
					BEGIN  
						SET @V_CLNT_NO = '999917';    --BIDC 인사공통거래처
					END
			END;

		IF @P_HRTYPE_GBN = 'H8309'
			BEGIN 
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO =''
					BEGIN  
						SET @V_CLNT_NO = '999918';    --동화 인사공통거래처
					END
			END;

         BEGIN
         
		PRINT('@V_DRAW_ACCT_DEPT_CD 테스트 : ' + @V_DRAW_ACCT_DEPT_CD)
         --INSERT INTO TB_FI403               --개발
		 insert openquery(DEBIS,'select SAL_PAY_DT
									     ,SAL_PAY_CLS_CD   
									     ,PERS_CLS_CD      
									     ,DRAW_ACCT_DEPT_CD
									     ,DRCR_CLS_CD      
									     ,ACCT_DEPT_CD     
									     ,ACCT_CD          
									     ,SEQ              
									     ,PAY_BANK_CD      
									     ,PCOST_DIV        
									     ,ACCT_NM          
									     ,AMT              
									     ,CLNT_NO          
									     ,SUMMARY          
									     ,REQ_PAY_MTHD_CD  
									     ,PAY_DT           
									     ,OUTBR_SLIP_NO    
									     ,PAY_SLIP_NO      
									     ,SND_CLS_CD       
									     ,REPLY_CLS_CD     
									     ,SND_DT           
									     ,SND_HH
									 from TB_FI403')
		 select    @V_SAL_PAY_DT 
                  ,@V_SAL_PAY_CLS_CD             
                  ,@V_PERS_CLS_CD      
                  ,@V_DRAW_ACCT_DEPT_CD
                  ,@V_DRCR_CLS_CD      
                  ,@V_ACCT_DEPT_CD     
                  ,@V_ACCT_CD          
                  ,@V_SEQ              
                  ,@V_PAY_BANK_CD      
                  ,@V_PCOST_DIV        
                  ,CASE WHEN ISNULL(@V_ACCT_NM, '') = '' THEN '' ELSE SUBSTRING(@V_ACCT_NM,1,50) END     
                  ,@V_AMT              
                  ,CASE WHEN ISNULL(@V_CLNT_NO, '') = '' THEN '' ELSE SUBSTRING(@V_CLNT_NO,1,6) END          
                  ,@V_SUMMARY          
                  ,@V_REQ_PAY_MTHD_CD  
                  ,@V_PAY_DT           
                  ,@V_OUTBR_SLIP_NO    
                  ,@V_PAY_SLIP_NO      
                  ,@V_SND_CLS_CD       
                  ,@V_REPLY_CLS_CD     
                  ,@V_SND_DT           
                  ,@V_SND_HH      
        
     END;   
     
     FETCH NEXT FROM C_PBT_BILL_CREATE INTO  @V_WRTDPT_CD,
											 @V_BILL_GBN,
											 @V_ACCNT_CD,
											 @V_SEQ_BILL,
											 @V_AMT_BILL,
											 @V_DEBSER_GBN,
											 @V_CUST_CD,
											 @V_COSTDPT_CD,
											 @V_SUMMARY_BILL,
											 @V_PROC_DT,
											 @V_BANK_CD,
											 @V_PAYMTWAY
	 END 
       
     CLOSE C_PBT_BILL_CREATE  --1번째 커서 종료         
	 DEALLOCATE C_PBT_BILL_CREATE
         
     SET @p_error_code = 0;      
  RETURN

 -----------------------------------------------------------------------------------------------------------------------
  -- END Message Setting Block 
  ----------------------------------------------------------------------------------------------------------------------- 
  ERR_HANDLER:
		begin try
			PRINT('에러발생')
			DEALLOCATE	C_PBT_BILL_CREATE;
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

	EXECUTE p_ba_errlib_getusererrormsg @P_COMPANY, 'SP_DEBIS_INSERT',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

	RETURN
END TRY
  ----------------------------------------------------------------------------------------------------------------------- 
  -- Error CATCH Process Block 
  ----------------------------------------------------------------------------------------------------------------------- 
BEGIN CATCH

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line =  ERROR_LINE();
	SET @v_error_message = ERROR_MESSAGE()+ ' ' + @v_error_note;
	
	EXECUTE p_ba_errlib_getusererrormsg @P_COMPANY, 'SP_DEBIS_INSERT',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

		begin try
		PRINT('비긴트라이')
			DEALLOCATE	C_PBT_BILL_CREATE;
		end try
		begin catch
		print 'Error CATCH Process Block';
		end catch;
	RETURN;
END CATCH 

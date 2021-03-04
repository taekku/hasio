CREATE OR REPLACE PROCEDURE SP_TRE_RET_INSERT
/************************************************************************
 * SYSTEM명         : 동부그룹 신인사 시스템
 * SUB SYSTEM명     : 물류 퇴직전표이체
 * PROCEDURE 명     : SP_TRE_RET_INSERT
 * DESCRIPTION      : 물류 퇴직전표이체를 생성한다.
 * 사용 TABLE명     : 
 * IN  PARAMETER    : P_COMPANY        회사구분
 *                    P_PROC_DATE      처리일자
 *                    P_BILL_GBN       전표구분  
 *                    P_SABUN
 * OUT PARAMETER    : R_RESULT
 * IN OUT PARAMETER : N/A
 * 변경자     변경일자            변경사유
 *-----------------------------------------------------------------------
 * 김민영     2008-07-02          초기생성
  ************************************************************************/
  (
     P_COMPANY         IN     VARCHAR2   -- 회사구분
    ,P_HRTYPE_GBN      IN     VARCHAR2   -- 인력유형 
    ,P_PROC_DATE       IN     VARCHAR2   -- 처리일자
    ,P_BILL_GBN        IN     VARCHAR2   -- 전표구분 
    ,P_TRN_DATE        IN     VARCHAR2   -- 실이체일자
    ,P_SAWON_GBN       IN     VARCHAR2   -- 사원구분
   	,P_SABUN           IN     VARCHAR2   -- 처리자
    ,R_RESULT          OUT    VARCHAR2   -- RETURN
 ) 
 IS
  --  R_RESULT          VARCHAR2(100);   -- RETURN
  -- 사용 변수선언
    V_WRTDPT_CD       PBT_RET_BILL.WRTDPT_CD%TYPE;      -- 작성부서
    V_BILL_GBN        PBT_RET_BILL.BILL_GBN%TYPE;       -- 전표구분
    V_TRDTYP_CD       PBT_RET_BILL.TRDTYP_CD%TYPE;      -- 거래유형
    V_ACCNT_CD        PBT_RET_BILL.ACCNT_CD%TYPE;       -- 계정코드
    V_SEQ_BILL        PBT_RET_BILL.SEQ%TYPE;            -- 순번
    V_AMT_BILL        PBT_RET_BILL.AMT%TYPE;            -- 순번
    V_CUST_CD         PBT_RET_BILL.CUST_CD%TYPE;        -- 거래처코드
    V_DEBSER_GBN      PBT_RET_BILL.DEBSER_GBN%TYPE;     -- 차대구분(차변/대변)
    V_COSTDPT_CD      PBT_RET_BILL.COSTDPT_CD%TYPE;     -- 원가부서
    V_TRDTYP_NM       PBT_RET_BILL.TRDTYP_NM%TYPE;      -- 거래명
    V_SUMMARY_BILL    PBT_RET_BILL.SUMMARY%TYPE;        -- 적요
    V_PROC_DT         PBT_RET_BILL.PROC_DT%TYPE;        -- 처리일자
    V_BANK_CD         PBT_RET_BILL.BANK_CD%TYPE;        -- 은행코드
    V_PAYMTWAY        PBT_RET_BILL.PAYMTWAY%TYPE;       -- 지불수단
    V_SABUN           VARCHAR2(6);                         -- 사번
    
    V_SAL_PAY_DT            VARCHAR2(8);          -- 퇴직금지급일자    
    V_SAL_PAY_CLS_CD        VARCHAR2(1);        -- 퇴직금지급구분코드
    V_PERS_CLS_CD           VARCHAR2(2);          -- 직원구분코드    
    V_DRAW_ACCT_DEPT_CD     VARCHAR2(5);     -- 작성귀속부서코드
    V_DRCR_CLS_CD           VARCHAR2(1);          -- 차대구분코드    
    V_ACCT_DEPT_CD          VARCHAR2(5);         -- 귀속부서코드    
    V_ACCT_CD               VARCHAR2(7);             -- 계정코드        
    V_SEQ                   NUMBER(5);                  -- 순번            
    V_PAY_BANK_CD           VARCHAR2(2);          -- 지급은행코드    
    V_PCOST_DIV             VARCHAR2(5);             -- 원가부문        
    V_ACCT_NM               varchar2(100);  --TB_FI403.ACCT_NM%TYPE;               -- 계정명          
    V_AMT                   NUMBER(13);                   -- 금액            
    V_CLNT_NO               varchar2(100);  --TB_FI403.CLNT_NO%TYPE;               -- 거래처번호      
    V_SUMMARY               VARCHAR2(100);               -- 적요            
    V_REQ_PAY_MTHD_CD       VARCHAR2(2);      -- 요청지급방법코드
    V_PAY_DT                VARCHAR2(8);              -- 지급일자        
    V_OUTBR_SLIP_NO         VARCHAR2(10);         -- 발생전표번호    
    V_PAY_SLIP_NO           VARCHAR2(10);           -- 지급전표번호    
    V_SND_CLS_CD            VARCHAR2(1);            -- 전송구분코드    
    V_REPLY_CLS_CD          VARCHAR2(1);          -- 응답구분코드    
    V_SND_DT                VARCHAR2(8);                -- 전송일자        
    V_SND_HH                VARCHAR2(6);                -- 전송시간  
    
    V_BILL_USER1            VARCHAR2(100);                     -- 코드명
    V_BILL_USER2            VARCHAR2(100);                     -- 코드명
    V_WDPTMAP_USER1         VARCHAR2(20);                      -- 작성부서명
    V_BANK_USER1            VARCHAR2(100);                     -- 은행코드
    V_COSTMAP_USER1         VARCHAR2(20);                      -- 원가부서 매핑코드
    
    V_CLS_CD                VARCHAR2(2) := '';
    V_CO_CD                 VARCHAR2(3) := '';
    
    V_CLNT_MGNT_YN	        NUMBER(1) := 0;                      --거래처관리여부(1:관리,0 : 미관리)             

    V_BATCH_LOGID        NUMBER(10);                                   -- 배치로그ID
    V_BATCH_WORKNM       VARCHAR2(100) := '퇴직전표이체';     -- 배치로그내용에 남길값  
    V_BATCH_ID           VARCHAR2(50) := 'SP_TRE_RET_INSERT';     -- 배치로그내용에 남길값      
    
    -- CURSOR용 변수
   	V_PBT_RET_BILL   PBT_RET_BILL%ROWTYPE;   -- 전표생성
   	
   	 -- CURSOR 선언
    CURSOR C_PBT_RET_BILL IS                -- 전표생성 데이터를 가져온다. 
        SELECT *
          FROM PBT_RET_BILL
         WHERE COMPANY  = P_COMPANY
           AND HRTYPE_GBN = P_HRTYPE_GBN -- 인력유형 
           AND BILL_GBN = P_BILL_GBN
           AND PROC_DT  = P_PROC_DATE 
           AND SAWON_GBN =  P_SAWON_GBN
         ORDER BY PAY_CD,RET_SABUN,DEBSER_GBN,SEQ;
  --  FOR UPDATE OF TRANSFER_YN	--이체여부   
  --               ,UPDATE_SABUN
  --               ,UPDATE_DT;
                 	
 BEGIN 

    BEGIN
        SELECT COS_LOG_ID.NEXTVAL 
          INTO V_BATCH_LOGID
          FROM DUAL;
    END;

    -- BATCH시작 정보를 기록하는 프로시져를 호출한다.(1:작업중 , 10퍼센트)
    BEGIN
        SP_STORE_BATCHLOG( V_BATCH_LOGID, P_COMPANY, V_BATCH_ID, '1', 10, P_SABUN, V_BATCH_WORKNM||'_'||P_PROC_DATE||'_'||P_HRTYPE_GBN||'_'||P_BILL_GBN );
    END;        
   
   -- 인력유형에 대응하는 데비스회ㅅ코드
   BEGIN
        SELECT USER3
          INTO V_CO_CD  
          FROM COT_CODE_INFO
         WHERE COMPANY_CD = P_COMPANY
           AND CODE = P_HRTYPE_GBN;
         EXCEPTION WHEN OTHERS THEN
	           NULL;
	 END; 
     
    -- 퇴직퇴직금지급구분코드      
	 V_SAL_PAY_CLS_CD := 'T'; --퇴직금
	 
	 IF P_SAWON_GBN = 'H2201' THEN
	    V_PERS_CLS_CD := 'AA';
	 ELSE 
	    V_PERS_CLS_CD := 'BB';
	 END IF; 
	 
     BEGIN    
    --   DELETE FROM TB_FI403                  --개발  
       DELETE FROM TB_FI403@TODEBIS_LINK   --운영
             WHERE SAL_PAY_DT     = P_PROC_DATE
               AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD             --자회사도입
                                      FROM TB_CO011@TODEBIS_LINK
                                     WHERE ACCT_YEAR = substr(P_PROC_DATE,1,4)
                                       AND CO_CD = V_CO_CD)
               AND SAL_PAY_CLS_CD = V_SAL_PAY_CLS_CD
               AND PERS_CLS_CD    = V_PERS_CLS_CD
               AND (REPLY_CLS_CD = 'D' OR REPLY_CLS_CD IS NULL);
     END;
  
     --순번 초기화
     V_SEQ := 0;
     -- 전표생성테이블에서 이체할 데이터를 가져온다.
     OPEN C_PBT_RET_BILL;
     LOOP 
     FETCH C_PBT_RET_BILL INTO V_PBT_RET_BILL;
     EXIT WHEN C_PBT_RET_BILL%NOTFOUND;   
     
         -- 변수초기화  
         V_WDPTMAP_USER1  := '';  --   VARCHAR2(20);   -- 작성부서명
         V_BANK_USER1     := '';  --   VARCHAR2(100);  -- 은행코드
         V_COSTMAP_USER1  := '';  --   VARCHAR2(20);   -- 원가부서 매핑코드
         V_CLNT_NO        := '';  --                   --거래처
         -- 이체에 필요한 데이터
         V_WRTDPT_CD    := V_PBT_RET_BILL.WRTDPT_CD;      -- 작성부서           
         V_BILL_GBN     := V_PBT_RET_BILL.BILL_GBN;       -- 전표구분                      
         V_ACCNT_CD     := V_PBT_RET_BILL.ACCNT_CD;       -- 계정코드  
         V_SEQ_BILL     := V_PBT_RET_BILL.SEQ;            -- 순번    
         V_AMT_BILL     := V_PBT_RET_BILL.AMT;            -- 금액        
         V_DEBSER_GBN   := V_PBT_RET_BILL.DEBSER_GBN;     -- 차대구분(차변/대변)             
         V_CUST_CD      := V_PBT_RET_BILL.CUST_CD;        -- 거래처코드         
         V_COSTDPT_CD   := V_PBT_RET_BILL.COSTDPT_CD;     -- 원가부서
         V_SUMMARY_BILL := V_PBT_RET_BILL.SUMMARY;        -- 적요 
         V_PROC_DT      := V_PBT_RET_BILL.PROC_DT;        -- 처리일자
         V_BANK_CD      := V_PBT_RET_BILL.BANK_CD;        -- 은행코드
         V_PAYMTWAY     := V_PBT_RET_BILL.PAYMTWAY;        -- 지불수단
         
         	-- 직원구분코드
         	IF V_PBT_RET_BILL.SAWON_GBN = 'H2201' THEN
         	   V_PERS_CLS_CD :=  'AA';
            ELSE
               V_PERS_CLS_CD :=  'BB';
            END IF;
 
         -- 퇴직금지급일자 
            V_SAL_PAY_DT := P_PROC_DATE;
	        
	        -- 작성귀속부서코드
	        V_DRAW_ACCT_DEPT_CD := V_COSTDPT_CD;
	        
	        -- 차대구분코드(물류와 건설은 반대)
	        V_DRCR_CLS_CD := V_DEBSER_GBN;
	        IF  V_DRCR_CLS_CD  = 'D' THEN
	            V_DRCR_CLS_CD  := 'C';
	        ELSE
	            V_DRCR_CLS_CD  := 'D';
	        END IF; 
	        
	        -- 귀속부서코드
	        
	        BEGIN 
              SELECT B.COST_CLS_CD ,A.MAPCOSTDPT_CD   ,           --  ('01' : 원가,'02' :판관비)
                     B.CO_CD                                     -- DEBIS의 회사구분(000:익스프레스) 
    	        INTO V_CLS_CD   ,  V_WDPTMAP_USER1   ,                           
                     V_CO_CD
                FROM  PBT_COSTDPT A
                 LEFT OUTER JOIN TB_CO001@TODEBIS_LINK B
                 ON A.MAPCOSTDPT_CD = B.ACCT_DEPT_CD
               WHERE A.COMPANY = P_COMPANY
                 AND A.COSTDPT_CD = V_WRTDPT_CD;
            END;
            
--            IF V_CO_CD <> '000' THEN 
--               
--               ROLLBACK;
--               R_RESULT := 1;   --DEBIS귀속부서오류 
--               RETURN;
--               
--            END IF;
	        
	        
	        
	        
	        V_ACCT_DEPT_CD := SUBSTR(V_WDPTMAP_USER1,1,6);
	        
	        -- 계정코드
	        V_ACCT_CD := SUBSTR(V_ACCNT_CD,1,7);
	        --미지급비용-사원(2100820)인 경우 지불수단 입력 여부체크
	        IF V_ACCT_CD = '2100820' THEN 
	           IF V_PAYMTWAY  IS NULL OR V_PAYMTWAY ='' THEN
	              R_RESULT := 1;
	              ROLLBACK;
	              RETURN;
	           END IF;
	        END IF; 
	        
	        -- 순번
	        V_SEQ := V_SEQ +1;
	        
	        -- 지급은행코드  
	        BEGIN
             SELECT USER1  
             INTO V_BANK_USER1
                FROM COT_CODE_INFO
               WHERE COMPANY_CD = P_COMPANY
                 AND CODE = V_BANK_CD;
             EXCEPTION WHEN OTHERS THEN
		           NULL;
	        END; 
	 
	        V_PAY_BANK_CD := SUBSTR(V_BANK_USER1,1,2);
	        
	        -- 원가부문(회계귀속부서)


	        BEGIN 
              SELECT B.COST_CLS_CD ,A.MAPCOSTDPT_CD   ,           --  ('01' : 원가,'02' :판관비)
                     B.CO_CD                                     -- DEBIS의 회사구분(000:익스프레스) 
    	        INTO V_CLS_CD   ,  V_COSTMAP_USER1   ,                           
                     V_CO_CD
                FROM  PBT_COSTDPT A
                 LEFT OUTER JOIN TB_CO001@TODEBIS_LINK B
                 ON A.MAPCOSTDPT_CD = B.ACCT_DEPT_CD
               WHERE A.COMPANY = P_COMPANY
                 AND A.COSTDPT_CD = V_COSTDPT_CD;
            END;
            
--            IF V_CO_CD <> '000' THEN 
--               
--               ROLLBACK;
--               R_RESULT := 1;   --DEBIS귀속부서오류 
--               RETURN;
--               
--            END IF;
	        


	        V_PCOST_DIV := SUBSTR(V_COSTMAP_USER1,1,6);
	        
	        -- 계정명
	        BEGIN
             SELECT ACCNT_NM  
             INTO V_ACCT_NM
                FROM PBT_ACCOUNT_CODE
               WHERE COMPANY = P_COMPANY
                 AND ACCNT_CD = V_ACCNT_CD;
             EXCEPTION WHEN OTHERS THEN
		           NULL;
	        END;
	        
	        -- 금액
	        V_AMT := V_AMT_BILL;
	        
	        -- 거래처번호
            V_CLNT_NO  := V_CUST_CD;
	      
	        --미지급비용-사원(2100820)인 경우 거래처입력여부 체크
	        
	        IF V_ACCT_CD = '2100820' THEN 
	           IF V_CLNT_NO  IS NULL OR V_CLNT_NO ='' THEN
	              R_RESULT := 2;
	              V_SEQ :=9999;
	              ROLLBACK;
	              RETURN;
	           END IF;
	        END IF; 
	        
	        -- 적요
	        V_SUMMARY := V_SUMMARY_BILL;
	        
	        -- 요청지급방법코드
	        V_REQ_PAY_MTHD_CD := SUBSTR(V_PAYMTWAY,1,2);
	        
	        -- 지급일자 (요청지급방법코드가 경비이체(20), 퇴직금이체(70)인 경우 지급일자 SETTING
	        V_PAY_DT := '';
	        IF V_PAYMTWAY = '20' OR V_PAYMTWAY = '70' THEN
	           V_PAY_DT := P_TRN_DATE;
	        END IF;
	        -- 발생전표번호
	        V_OUTBR_SLIP_NO := '';
	        
	        -- 지급전표번호
	        V_PAY_SLIP_NO := '';
	        
	        -- 전송구분코드
	        V_SND_CLS_CD := '0';
	        
	        -- 응답구분코드
	        V_REPLY_CLS_CD := '';
	        
	        -- 전송일자
	        BEGIN
             SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') AS TODAY  
             INTO V_SND_DT
                FROM DUAL;
             EXCEPTION WHEN OTHERS THEN
		              NULL;
            END;
         
         -- 전송시간
           BEGIN
             SELECT TO_CHAR(SYSDATE, 'HHMMSS') AS TIME_E  
             INTO V_SND_HH
                FROM DUAL;
             EXCEPTION WHEN OTHERS THEN
		              NULL;
           END;
           
           
           

           /* 거래처필수 계정확인 */
           V_CLNT_MGNT_YN := 0;                      --거래처관리여부(1:관리,0 : 미관리)    
           BEGIN    
             SELECT CLNT_MGNT_YN
               INTO V_CLNT_MGNT_YN
               FROM TB_FI001@TODEBIS_LINK   --운영
              WHERE  ACCT_CD     = V_ACCT_CD ;
           END;
           
           IF V_CLNT_MGNT_YN = 1 THEN 
              NULL;
              
--              IF V_CLNT_NO IS NULL OR V_CLNT_NO ='' THEN 
--                 V_CLNT_NO := '999912';    --인사공통거래처 
--              END IF;
           
           END IF;
           
           IF P_HRTYPE_GBN = 'H8301' THEN -- 본사  
             IF V_CLNT_NO IS NULL OR V_CLNT_NO ='' THEN 
                V_CLNT_NO := '999912';    --인사공통거래처 
             END IF; 
           END IF;    

           IF P_HRTYPE_GBN = 'H8304' THEN -- NTS 
             IF V_CLNT_NO IS NULL OR V_CLNT_NO ='' THEN 
                V_CLNT_NO := '999914';    --인사급상여공통_NTS
             END IF; 
           END IF;    

           IF P_HRTYPE_GBN = 'H8305' THEN -- 대성
             IF V_CLNT_NO IS NULL OR V_CLNT_NO ='' THEN 
                V_CLNT_NO := '999915';    --인사급상여공통_대성 
             END IF; 
           END IF;    

           IF P_HRTYPE_GBN = 'H8306' THEN -- DIMT  
             IF V_CLNT_NO IS NULL OR V_CLNT_NO ='' THEN 
                V_CLNT_NO := '999916';    --인사급상여공통_DIMT
             END IF; 
           END IF;                                     
                   
           /* 거래처필수 계정확인 종료 */              
         
           BEGIN
      --       INSERT INTO TB_FI403               --개발
             INSERT INTO TB_FI403@TODEBIS_LINK  --운영
                  (SAL_PAY_DT       
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
                  )VALUES( 
                   V_SAL_PAY_DT       
                  ,V_SAL_PAY_CLS_CD             
                  ,V_PERS_CLS_CD      
                  ,V_DRAW_ACCT_DEPT_CD
                  ,V_DRCR_CLS_CD      
                  ,V_ACCT_DEPT_CD     
                  ,V_ACCT_CD          
                  ,V_SEQ              
                  ,V_PAY_BANK_CD      
                  ,V_PCOST_DIV        
                  ,SUBSTR(V_ACCT_NM,1,50)          
                  ,V_AMT              
                  ,SUBSTR(V_CLNT_NO,1,6)          
                  ,V_SUMMARY          
                  ,V_REQ_PAY_MTHD_CD  
                  ,V_PAY_DT           
                  ,V_OUTBR_SLIP_NO    
                  ,V_PAY_SLIP_NO      
                  ,V_SND_CLS_CD       
                  ,V_REPLY_CLS_CD     
                  ,V_SND_DT           
                  ,V_SND_HH      
                  );     
              EXCEPTION                  
              WHEN DUP_VAL_ON_INDEX THEN 
    --           UPDATE TB_FI403                   --개발
               UPDATE TB_FI403@TODEBIS_LINK    --운영
                 SET PAY_BANK_CD     = V_PAY_BANK_CD     
                    ,PCOST_DIV       = V_PCOST_DIV     
                    ,ACCT_NM         = SUBSTR(V_ACCT_NM,1,50)       
                    ,AMT             = V_AMT           
                    ,CLNT_NO         = SUBSTR(V_CLNT_NO,1,6)       
                    ,SUMMARY         = V_SUMMARY       
                    ,REQ_PAY_MTHD_CD = V_REQ_PAY_MTHD_CD
                    ,PAY_DT          = V_PAY_DT        
                    ,OUTBR_SLIP_NO   = V_OUTBR_SLIP_NO 
                    ,PAY_SLIP_NO     = V_PAY_SLIP_NO   
                    ,SND_CLS_CD      = V_SND_CLS_CD    
                    ,REPLY_CLS_CD    = V_REPLY_CLS_CD  
                    ,SND_DT          = V_SND_DT        
                    ,SND_HH          = V_SND_HH 
                 WHERE SAL_PAY_DT        = V_SAL_PAY_DT             
                   AND SAL_PAY_CLS_CD    = V_SAL_PAY_CLS_CD   
                   AND PERS_CLS_CD       = V_PERS_CLS_CD      
                   AND DRAW_ACCT_DEPT_CD = V_DRAW_ACCT_DEPT_CD
                   AND DRCR_CLS_CD       = V_DRCR_CLS_CD      
                   AND ACCT_DEPT_CD      = V_ACCT_DEPT_CD     
                   AND ACCT_CD           = V_ACCT_CD          
                   AND SEQ               = V_SEQ;     
         END;   

         --대출상환처리,국민연금전환금,퇴직신탁처리
         IF  V_PBT_RET_BILL.ACCNT_CD IN  ('2200710','2200610')  AND 
             V_PBT_RET_BILL.CUST_CD IS NOT NULL AND 
             V_PBT_RET_BILL.DEBSER_GBN ='D'  THEN
         
             BEGIN
                SP_RESIGN_SLIP_CREATE
                  (  V_PBT_RET_BILL.COMPANY  
                    ,P_HRTYPE_GBN      
                    ,V_PBT_RET_BILL.PAY_YM         
                    ,V_PBT_RET_BILL.PAY_CD           
                    ,V_PBT_RET_BILL.RET_SABUN               
                    ,''         
                    ,P_SABUN);
             END;  
             
         END IF;

        
        --전표이체여부 UPDATE
      
         BEGIN
           UPDATE PBT_RET_BILL
              SET  TRANSFER_YN     = 'Y'
                  ,UPDATE_SABUN     = P_SABUN
                  ,UPDATE_DT       = SYSDATE
            WHERE COMPANY = V_PBT_RET_BILL.COMPANY   
              AND HRTYPE_GBN = P_HRTYPE_GBN -- 인력유형  
              AND PAY_YM = V_PBT_RET_BILL.PAY_YM    
              AND PAY_CD = V_PBT_RET_BILL.PAY_CD 
              AND RET_SABUN = V_PBT_RET_BILL.RET_SABUN 
              AND WRTDPT_CD = V_PBT_RET_BILL.WRTDPT_CD 
              AND TRDTYP_CD = V_PBT_RET_BILL.TRDTYP_CD 
              AND BILL_GBN = V_PBT_RET_BILL.BILL_GBN 
              AND ACCNT_CD = V_PBT_RET_BILL.ACCNT_CD 
              AND SEQ = V_PBT_RET_BILL.SEQ ;
           EXCEPTION WHEN OTHERS THEN 
                NULL;
         END;
         --DBMS_OUTPUT.PUT_LINE('사번--> '||sqlerrm);
     END LOOP;                                       
     CLOSE C_PBT_RET_BILL;  -- 전표이체 종료 
     
     /*전표이체후 지급예정일자를 신고일자에 SETTING 원천세신고완 관련 */
     BEGIN
        UPDATE PBT_RET_RESULT
           SET TAXRPT_DT = P_TRN_DATE   	--VARCHAR2(16)		세액신고일자(지급예정일자)
         WHERE COMPANY = P_COMPANY 
           AND SABUN IN (SELECT SABUN FROM PBT_PAY_MAST WHERE HRTYPE_GBN = P_HRTYPE_GBN)  -- 인력유형     
           AND SLIP_PROC_DT = P_PROC_DATE;  --전표발생일자 
     END; 
     
     R_RESULT := TO_CHAR(V_SEQ);

     
    -- 4. BATCH종료 정보를 기록하는 프로시져를 호출한다.(3:완료 , 100퍼센트)
     BEGIN
        SP_STORE_BATCHLOG( V_BATCH_LOGID, P_COMPANY, V_BATCH_ID, '3', 100, P_SABUN, V_BATCH_WORKNM||'_'||P_PROC_DATE||'_'||P_HRTYPE_GBN||'_'||P_BILL_GBN );
     END;     

                                
     COMMIT;       
     
EXCEPTION WHEN OTHERS THEN                     
    -- BATCH오류 정보를 기록하는 프로시져를 호출한다.(2:오류 , 진행율:-1)
    SP_STORE_BATCHLOG( V_BATCH_LOGID, P_COMPANY, V_BATCH_ID, '2', -1, P_SABUN, V_BATCH_WORKNM||'_'||P_PROC_DATE||'_'||P_HRTYPE_GBN||'_'||P_BILL_GBN||' '||SQLERRM );
    R_RESULT := 0;                
    ROLLBACK;                     
                                  
END SP_TRE_RET_INSERT;

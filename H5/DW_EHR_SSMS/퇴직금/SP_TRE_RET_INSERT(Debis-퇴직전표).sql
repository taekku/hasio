CREATE OR REPLACE PROCEDURE SP_TRE_RET_INSERT
/************************************************************************
 * SYSTEM��         : ���α׷� ���λ� �ý���
 * SUB SYSTEM��     : ���� ������ǥ��ü
 * PROCEDURE ��     : SP_TRE_RET_INSERT
 * DESCRIPTION      : ���� ������ǥ��ü�� �����Ѵ�.
 * ��� TABLE��     : 
 * IN  PARAMETER    : P_COMPANY        ȸ�籸��
 *                    P_PROC_DATE      ó������
 *                    P_BILL_GBN       ��ǥ����  
 *                    P_SABUN
 * OUT PARAMETER    : R_RESULT
 * IN OUT PARAMETER : N/A
 * ������     ��������            �������
 *-----------------------------------------------------------------------
 * ��ο�     2008-07-02          �ʱ����
  ************************************************************************/
  (
     P_COMPANY         IN     VARCHAR2   -- ȸ�籸��
    ,P_HRTYPE_GBN      IN     VARCHAR2   -- �η����� 
    ,P_PROC_DATE       IN     VARCHAR2   -- ó������
    ,P_BILL_GBN        IN     VARCHAR2   -- ��ǥ���� 
    ,P_TRN_DATE        IN     VARCHAR2   -- ����ü����
    ,P_SAWON_GBN       IN     VARCHAR2   -- �������
   	,P_SABUN           IN     VARCHAR2   -- ó����
    ,R_RESULT          OUT    VARCHAR2   -- RETURN
 ) 
 IS
  --  R_RESULT          VARCHAR2(100);   -- RETURN
  -- ��� ��������
    V_WRTDPT_CD       PBT_RET_BILL.WRTDPT_CD%TYPE;      -- �ۼ��μ�
    V_BILL_GBN        PBT_RET_BILL.BILL_GBN%TYPE;       -- ��ǥ����
    V_TRDTYP_CD       PBT_RET_BILL.TRDTYP_CD%TYPE;      -- �ŷ�����
    V_ACCNT_CD        PBT_RET_BILL.ACCNT_CD%TYPE;       -- �����ڵ�
    V_SEQ_BILL        PBT_RET_BILL.SEQ%TYPE;            -- ����
    V_AMT_BILL        PBT_RET_BILL.AMT%TYPE;            -- ����
    V_CUST_CD         PBT_RET_BILL.CUST_CD%TYPE;        -- �ŷ�ó�ڵ�
    V_DEBSER_GBN      PBT_RET_BILL.DEBSER_GBN%TYPE;     -- ���뱸��(����/�뺯)
    V_COSTDPT_CD      PBT_RET_BILL.COSTDPT_CD%TYPE;     -- �����μ�
    V_TRDTYP_NM       PBT_RET_BILL.TRDTYP_NM%TYPE;      -- �ŷ���
    V_SUMMARY_BILL    PBT_RET_BILL.SUMMARY%TYPE;        -- ����
    V_PROC_DT         PBT_RET_BILL.PROC_DT%TYPE;        -- ó������
    V_BANK_CD         PBT_RET_BILL.BANK_CD%TYPE;        -- �����ڵ�
    V_PAYMTWAY        PBT_RET_BILL.PAYMTWAY%TYPE;       -- ���Ҽ���
    V_SABUN           VARCHAR2(6);                         -- ���
    
    V_SAL_PAY_DT            VARCHAR2(8);          -- ��������������    
    V_SAL_PAY_CLS_CD        VARCHAR2(1);        -- ���������ޱ����ڵ�
    V_PERS_CLS_CD           VARCHAR2(2);          -- ���������ڵ�    
    V_DRAW_ACCT_DEPT_CD     VARCHAR2(5);     -- �ۼ��ͼӺμ��ڵ�
    V_DRCR_CLS_CD           VARCHAR2(1);          -- ���뱸���ڵ�    
    V_ACCT_DEPT_CD          VARCHAR2(5);         -- �ͼӺμ��ڵ�    
    V_ACCT_CD               VARCHAR2(7);             -- �����ڵ�        
    V_SEQ                   NUMBER(5);                  -- ����            
    V_PAY_BANK_CD           VARCHAR2(2);          -- ���������ڵ�    
    V_PCOST_DIV             VARCHAR2(5);             -- �����ι�        
    V_ACCT_NM               varchar2(100);  --TB_FI403.ACCT_NM%TYPE;               -- ������          
    V_AMT                   NUMBER(13);                   -- �ݾ�            
    V_CLNT_NO               varchar2(100);  --TB_FI403.CLNT_NO%TYPE;               -- �ŷ�ó��ȣ      
    V_SUMMARY               VARCHAR2(100);               -- ����            
    V_REQ_PAY_MTHD_CD       VARCHAR2(2);      -- ��û���޹���ڵ�
    V_PAY_DT                VARCHAR2(8);              -- ��������        
    V_OUTBR_SLIP_NO         VARCHAR2(10);         -- �߻���ǥ��ȣ    
    V_PAY_SLIP_NO           VARCHAR2(10);           -- ������ǥ��ȣ    
    V_SND_CLS_CD            VARCHAR2(1);            -- ���۱����ڵ�    
    V_REPLY_CLS_CD          VARCHAR2(1);          -- ���䱸���ڵ�    
    V_SND_DT                VARCHAR2(8);                -- ��������        
    V_SND_HH                VARCHAR2(6);                -- ���۽ð�  
    
    V_BILL_USER1            VARCHAR2(100);                     -- �ڵ��
    V_BILL_USER2            VARCHAR2(100);                     -- �ڵ��
    V_WDPTMAP_USER1         VARCHAR2(20);                      -- �ۼ��μ���
    V_BANK_USER1            VARCHAR2(100);                     -- �����ڵ�
    V_COSTMAP_USER1         VARCHAR2(20);                      -- �����μ� �����ڵ�
    
    V_CLS_CD                VARCHAR2(2) := '';
    V_CO_CD                 VARCHAR2(3) := '';
    
    V_CLNT_MGNT_YN	        NUMBER(1) := 0;                      --�ŷ�ó��������(1:����,0 : �̰���)             

    V_BATCH_LOGID        NUMBER(10);                                   -- ��ġ�α�ID
    V_BATCH_WORKNM       VARCHAR2(100) := '������ǥ��ü';     -- ��ġ�α׳��뿡 ���氪  
    V_BATCH_ID           VARCHAR2(50) := 'SP_TRE_RET_INSERT';     -- ��ġ�α׳��뿡 ���氪      
    
    -- CURSOR�� ����
   	V_PBT_RET_BILL   PBT_RET_BILL%ROWTYPE;   -- ��ǥ����
   	
   	 -- CURSOR ����
    CURSOR C_PBT_RET_BILL IS                -- ��ǥ���� �����͸� �����´�. 
        SELECT *
          FROM PBT_RET_BILL
         WHERE COMPANY  = P_COMPANY
           AND HRTYPE_GBN = P_HRTYPE_GBN -- �η����� 
           AND BILL_GBN = P_BILL_GBN
           AND PROC_DT  = P_PROC_DATE 
           AND SAWON_GBN =  P_SAWON_GBN
         ORDER BY PAY_CD,RET_SABUN,DEBSER_GBN,SEQ;
  --  FOR UPDATE OF TRANSFER_YN	--��ü����   
  --               ,UPDATE_SABUN
  --               ,UPDATE_DT;
                 	
 BEGIN 

    BEGIN
        SELECT COS_LOG_ID.NEXTVAL 
          INTO V_BATCH_LOGID
          FROM DUAL;
    END;

    -- BATCH���� ������ ����ϴ� ���ν����� ȣ���Ѵ�.(1:�۾��� , 10�ۼ�Ʈ)
    BEGIN
        SP_STORE_BATCHLOG( V_BATCH_LOGID, P_COMPANY, V_BATCH_ID, '1', 10, P_SABUN, V_BATCH_WORKNM||'_'||P_PROC_DATE||'_'||P_HRTYPE_GBN||'_'||P_BILL_GBN );
    END;        
   
   -- �η������� �����ϴ� ����ȸ���ڵ�
   BEGIN
        SELECT USER3
          INTO V_CO_CD  
          FROM COT_CODE_INFO
         WHERE COMPANY_CD = P_COMPANY
           AND CODE = P_HRTYPE_GBN;
         EXCEPTION WHEN OTHERS THEN
	           NULL;
	 END; 
     
    -- �������������ޱ����ڵ�      
	 V_SAL_PAY_CLS_CD := 'T'; --������
	 
	 IF P_SAWON_GBN = 'H2201' THEN
	    V_PERS_CLS_CD := 'AA';
	 ELSE 
	    V_PERS_CLS_CD := 'BB';
	 END IF; 
	 
     BEGIN    
    --   DELETE FROM TB_FI403                  --����  
       DELETE FROM TB_FI403@TODEBIS_LINK   --�
             WHERE SAL_PAY_DT     = P_PROC_DATE
               AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD             --��ȸ�絵��
                                      FROM TB_CO011@TODEBIS_LINK
                                     WHERE ACCT_YEAR = substr(P_PROC_DATE,1,4)
                                       AND CO_CD = V_CO_CD)
               AND SAL_PAY_CLS_CD = V_SAL_PAY_CLS_CD
               AND PERS_CLS_CD    = V_PERS_CLS_CD
               AND (REPLY_CLS_CD = 'D' OR REPLY_CLS_CD IS NULL);
     END;
  
     --���� �ʱ�ȭ
     V_SEQ := 0;
     -- ��ǥ�������̺��� ��ü�� �����͸� �����´�.
     OPEN C_PBT_RET_BILL;
     LOOP 
     FETCH C_PBT_RET_BILL INTO V_PBT_RET_BILL;
     EXIT WHEN C_PBT_RET_BILL%NOTFOUND;   
     
         -- �����ʱ�ȭ  
         V_WDPTMAP_USER1  := '';  --   VARCHAR2(20);   -- �ۼ��μ���
         V_BANK_USER1     := '';  --   VARCHAR2(100);  -- �����ڵ�
         V_COSTMAP_USER1  := '';  --   VARCHAR2(20);   -- �����μ� �����ڵ�
         V_CLNT_NO        := '';  --                   --�ŷ�ó
         -- ��ü�� �ʿ��� ������
         V_WRTDPT_CD    := V_PBT_RET_BILL.WRTDPT_CD;      -- �ۼ��μ�           
         V_BILL_GBN     := V_PBT_RET_BILL.BILL_GBN;       -- ��ǥ����                      
         V_ACCNT_CD     := V_PBT_RET_BILL.ACCNT_CD;       -- �����ڵ�  
         V_SEQ_BILL     := V_PBT_RET_BILL.SEQ;            -- ����    
         V_AMT_BILL     := V_PBT_RET_BILL.AMT;            -- �ݾ�        
         V_DEBSER_GBN   := V_PBT_RET_BILL.DEBSER_GBN;     -- ���뱸��(����/�뺯)             
         V_CUST_CD      := V_PBT_RET_BILL.CUST_CD;        -- �ŷ�ó�ڵ�         
         V_COSTDPT_CD   := V_PBT_RET_BILL.COSTDPT_CD;     -- �����μ�
         V_SUMMARY_BILL := V_PBT_RET_BILL.SUMMARY;        -- ���� 
         V_PROC_DT      := V_PBT_RET_BILL.PROC_DT;        -- ó������
         V_BANK_CD      := V_PBT_RET_BILL.BANK_CD;        -- �����ڵ�
         V_PAYMTWAY     := V_PBT_RET_BILL.PAYMTWAY;        -- ���Ҽ���
         
         	-- ���������ڵ�
         	IF V_PBT_RET_BILL.SAWON_GBN = 'H2201' THEN
         	   V_PERS_CLS_CD :=  'AA';
            ELSE
               V_PERS_CLS_CD :=  'BB';
            END IF;
 
         -- �������������� 
            V_SAL_PAY_DT := P_PROC_DATE;
	        
	        -- �ۼ��ͼӺμ��ڵ�
	        V_DRAW_ACCT_DEPT_CD := V_COSTDPT_CD;
	        
	        -- ���뱸���ڵ�(������ �Ǽ��� �ݴ�)
	        V_DRCR_CLS_CD := V_DEBSER_GBN;
	        IF  V_DRCR_CLS_CD  = 'D' THEN
	            V_DRCR_CLS_CD  := 'C';
	        ELSE
	            V_DRCR_CLS_CD  := 'D';
	        END IF; 
	        
	        -- �ͼӺμ��ڵ�
	        
	        BEGIN 
              SELECT B.COST_CLS_CD ,A.MAPCOSTDPT_CD   ,           --  ('01' : ����,'02' :�ǰ���)
                     B.CO_CD                                     -- DEBIS�� ȸ�籸��(000:�ͽ�������) 
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
--               R_RESULT := 1;   --DEBIS�ͼӺμ����� 
--               RETURN;
--               
--            END IF;
	        
	        
	        
	        
	        V_ACCT_DEPT_CD := SUBSTR(V_WDPTMAP_USER1,1,6);
	        
	        -- �����ڵ�
	        V_ACCT_CD := SUBSTR(V_ACCNT_CD,1,7);
	        --�����޺��-���(2100820)�� ��� ���Ҽ��� �Է� ����üũ
	        IF V_ACCT_CD = '2100820' THEN 
	           IF V_PAYMTWAY  IS NULL OR V_PAYMTWAY ='' THEN
	              R_RESULT := 1;
	              ROLLBACK;
	              RETURN;
	           END IF;
	        END IF; 
	        
	        -- ����
	        V_SEQ := V_SEQ +1;
	        
	        -- ���������ڵ�  
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
	        
	        -- �����ι�(ȸ��ͼӺμ�)


	        BEGIN 
              SELECT B.COST_CLS_CD ,A.MAPCOSTDPT_CD   ,           --  ('01' : ����,'02' :�ǰ���)
                     B.CO_CD                                     -- DEBIS�� ȸ�籸��(000:�ͽ�������) 
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
--               R_RESULT := 1;   --DEBIS�ͼӺμ����� 
--               RETURN;
--               
--            END IF;
	        


	        V_PCOST_DIV := SUBSTR(V_COSTMAP_USER1,1,6);
	        
	        -- ������
	        BEGIN
             SELECT ACCNT_NM  
             INTO V_ACCT_NM
                FROM PBT_ACCOUNT_CODE
               WHERE COMPANY = P_COMPANY
                 AND ACCNT_CD = V_ACCNT_CD;
             EXCEPTION WHEN OTHERS THEN
		           NULL;
	        END;
	        
	        -- �ݾ�
	        V_AMT := V_AMT_BILL;
	        
	        -- �ŷ�ó��ȣ
            V_CLNT_NO  := V_CUST_CD;
	      
	        --�����޺��-���(2100820)�� ��� �ŷ�ó�Է¿��� üũ
	        
	        IF V_ACCT_CD = '2100820' THEN 
	           IF V_CLNT_NO  IS NULL OR V_CLNT_NO ='' THEN
	              R_RESULT := 2;
	              V_SEQ :=9999;
	              ROLLBACK;
	              RETURN;
	           END IF;
	        END IF; 
	        
	        -- ����
	        V_SUMMARY := V_SUMMARY_BILL;
	        
	        -- ��û���޹���ڵ�
	        V_REQ_PAY_MTHD_CD := SUBSTR(V_PAYMTWAY,1,2);
	        
	        -- �������� (��û���޹���ڵ尡 �����ü(20), ��������ü(70)�� ��� �������� SETTING
	        V_PAY_DT := '';
	        IF V_PAYMTWAY = '20' OR V_PAYMTWAY = '70' THEN
	           V_PAY_DT := P_TRN_DATE;
	        END IF;
	        -- �߻���ǥ��ȣ
	        V_OUTBR_SLIP_NO := '';
	        
	        -- ������ǥ��ȣ
	        V_PAY_SLIP_NO := '';
	        
	        -- ���۱����ڵ�
	        V_SND_CLS_CD := '0';
	        
	        -- ���䱸���ڵ�
	        V_REPLY_CLS_CD := '';
	        
	        -- ��������
	        BEGIN
             SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') AS TODAY  
             INTO V_SND_DT
                FROM DUAL;
             EXCEPTION WHEN OTHERS THEN
		              NULL;
            END;
         
         -- ���۽ð�
           BEGIN
             SELECT TO_CHAR(SYSDATE, 'HHMMSS') AS TIME_E  
             INTO V_SND_HH
                FROM DUAL;
             EXCEPTION WHEN OTHERS THEN
		              NULL;
           END;
           
           
           

           /* �ŷ�ó�ʼ� ����Ȯ�� */
           V_CLNT_MGNT_YN := 0;                      --�ŷ�ó��������(1:����,0 : �̰���)    
           BEGIN    
             SELECT CLNT_MGNT_YN
               INTO V_CLNT_MGNT_YN
               FROM TB_FI001@TODEBIS_LINK   --�
              WHERE  ACCT_CD     = V_ACCT_CD ;
           END;
           
           IF V_CLNT_MGNT_YN = 1 THEN 
              NULL;
              
--              IF V_CLNT_NO IS NULL OR V_CLNT_NO ='' THEN 
--                 V_CLNT_NO := '999912';    --�λ����ŷ�ó 
--              END IF;
           
           END IF;
           
           IF P_HRTYPE_GBN = 'H8301' THEN -- ����  
             IF V_CLNT_NO IS NULL OR V_CLNT_NO ='' THEN 
                V_CLNT_NO := '999912';    --�λ����ŷ�ó 
             END IF; 
           END IF;    

           IF P_HRTYPE_GBN = 'H8304' THEN -- NTS 
             IF V_CLNT_NO IS NULL OR V_CLNT_NO ='' THEN 
                V_CLNT_NO := '999914';    --�λ�޻󿩰���_NTS
             END IF; 
           END IF;    

           IF P_HRTYPE_GBN = 'H8305' THEN -- �뼺
             IF V_CLNT_NO IS NULL OR V_CLNT_NO ='' THEN 
                V_CLNT_NO := '999915';    --�λ�޻󿩰���_�뼺 
             END IF; 
           END IF;    

           IF P_HRTYPE_GBN = 'H8306' THEN -- DIMT  
             IF V_CLNT_NO IS NULL OR V_CLNT_NO ='' THEN 
                V_CLNT_NO := '999916';    --�λ�޻󿩰���_DIMT
             END IF; 
           END IF;                                     
                   
           /* �ŷ�ó�ʼ� ����Ȯ�� ���� */              
         
           BEGIN
      --       INSERT INTO TB_FI403               --����
             INSERT INTO TB_FI403@TODEBIS_LINK  --�
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
    --           UPDATE TB_FI403                   --����
               UPDATE TB_FI403@TODEBIS_LINK    --�
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

         --�����ȯó��,���ο�����ȯ��,������Źó��
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

        
        --��ǥ��ü���� UPDATE
      
         BEGIN
           UPDATE PBT_RET_BILL
              SET  TRANSFER_YN     = 'Y'
                  ,UPDATE_SABUN     = P_SABUN
                  ,UPDATE_DT       = SYSDATE
            WHERE COMPANY = V_PBT_RET_BILL.COMPANY   
              AND HRTYPE_GBN = P_HRTYPE_GBN -- �η�����  
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
         --DBMS_OUTPUT.PUT_LINE('���--> '||sqlerrm);
     END LOOP;                                       
     CLOSE C_PBT_RET_BILL;  -- ��ǥ��ü ���� 
     
     /*��ǥ��ü�� ���޿������ڸ� �Ű����ڿ� SETTING ��õ���Ű�� ���� */
     BEGIN
        UPDATE PBT_RET_RESULT
           SET TAXRPT_DT = P_TRN_DATE   	--VARCHAR2(16)		���׽Ű�����(���޿�������)
         WHERE COMPANY = P_COMPANY 
           AND SABUN IN (SELECT SABUN FROM PBT_PAY_MAST WHERE HRTYPE_GBN = P_HRTYPE_GBN)  -- �η�����     
           AND SLIP_PROC_DT = P_PROC_DATE;  --��ǥ�߻����� 
     END; 
     
     R_RESULT := TO_CHAR(V_SEQ);

     
    -- 4. BATCH���� ������ ����ϴ� ���ν����� ȣ���Ѵ�.(3:�Ϸ� , 100�ۼ�Ʈ)
     BEGIN
        SP_STORE_BATCHLOG( V_BATCH_LOGID, P_COMPANY, V_BATCH_ID, '3', 100, P_SABUN, V_BATCH_WORKNM||'_'||P_PROC_DATE||'_'||P_HRTYPE_GBN||'_'||P_BILL_GBN );
     END;     

                                
     COMMIT;       
     
EXCEPTION WHEN OTHERS THEN                     
    -- BATCH���� ������ ����ϴ� ���ν����� ȣ���Ѵ�.(2:���� , ������:-1)
    SP_STORE_BATCHLOG( V_BATCH_LOGID, P_COMPANY, V_BATCH_ID, '2', -1, P_SABUN, V_BATCH_WORKNM||'_'||P_PROC_DATE||'_'||P_HRTYPE_GBN||'_'||P_BILL_GBN||' '||SQLERRM );
    R_RESULT := 0;                
    ROLLBACK;                     
                                  
END SP_TRE_RET_INSERT;

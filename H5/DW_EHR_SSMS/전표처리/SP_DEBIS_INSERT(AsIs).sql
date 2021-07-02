USE [dwehrdev]
GO
/****** Object:  StoredProcedure [dbo].[SP_DEBIS_INSERT]    Script Date: 2020-12-14 ���� 4:45:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/************************************************************************
 * SYSTEM��         : ���α׷� ���λ� �ý���
 * SUB SYSTEM��     : ���� ��ǥ��ü
 * PROCEDURE ��     : SP_TRE_INSERT
 * DESCRIPTION      : ���� ��ǥ��ü�� �����Ѵ�.
 * ��� TABLE��     : 
 * IN  PARAMETER    : P_COMPANY        ȸ�籸��
 *                    P_PROC_DATE      ó������
 *                    P_BILL_GBN       ��ǥ����  
 *                    P_SABUN
 * OUT PARAMETER    : R_RESULT
 * IN OUT PARAMETER : N/A
 * ������     ��������            �������
 *-----------------------------------------------------------------------
 * �ڼ���     2006-03-29          �ʱ����
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
					  @P_COMPANY         VARCHAR(20)   -- ȸ�籸�� (E: �ͽ�������, �ܵ�)
					 ,@P_HRTYPE_GBN      VARCHAR(20)   -- �η����� (��ȸ���? �ͽ���������? H8301 �ͽ�������, H8306 DIMT Ȯ���ʿ� 2������ �����) 
					 ,@P_PROC_DATE       VARCHAR(20)   -- ó������ (�޿������ε� ������� ��� �ش� �޿�����.... 6/10�� �������� ��� 5/10)
					 ,@P_BILL_GBN        VARCHAR(20)   -- ��ǥ���� (�޿���ǥ, ����ǥ, �ǰ�������ǥ, ���ο�����ǥ * 2, PI��ǥ(?)) 
					 ,@P_SABUN           VARCHAR(20)   -- ó���� 
					 ,@p_error_code      VARCHAR(1000) OUTPUT				-- �����ڵ� ����
                     ,@p_error_str       VARCHAR(3000) OUTPUT				-- �����޽��� ����
                   )                                                                              
AS
SET NOCOUNT ON
DECLARE
  -- ��� ��������
    @V_WRTDPT_CD             VARCHAR(40),         -- �ۼ��μ�
    @V_BILL_GBN              VARCHAR(40),         -- ��ǥ����
    @V_TRDTYP_CD             VARCHAR(40),         -- �ŷ�����
    @V_ACCNT_CD              VARCHAR(40),         -- �����ڵ�
    @V_SEQ_BILL              NUMERIC(5,0),        -- ����
    @V_AMT_BILL              NUMERIC(13,0),       -- �ݾ�
    @V_CUST_CD               VARCHAR(40),         -- �ŷ�ó�ڵ�
    @V_DEBSER_GBN            VARCHAR(40),         -- ���뱸��(����/�뺯)
    @V_COSTDPT_CD            VARCHAR(40),         -- �����μ�
    @V_TRDTYP_NM             VARCHAR(500),        -- �ŷ���
    @V_SUMMARY_BILL          VARCHAR(500),        -- ����
    @V_PROC_DT               VARCHAR(40),         -- ó������
    @V_BANK_CD               VARCHAR(40),         -- �����ڵ�
    @V_PAYMTWAY              VARCHAR(40),         -- ���Ҽ���
    @V_SABUN                 VARCHAR(12),         -- ���
    
    @V_CUST_CHK              VARCHAR(1) = 'N',  
    
    @V_CO_CD                 VARCHAR(3),          -- ����ȸ���ڵ�
    
    @V_SAL_PAY_DT            VARCHAR(8),          -- �޿���������       
    @V_SAL_PAY_CLS_CD        VARCHAR(1),          -- �޿����ޱ����ڵ�
    @V_PERS_CLS_CD           VARCHAR(2),          -- ���������ڵ�    
    @V_DRAW_ACCT_DEPT_CD     VARCHAR(5),          -- �ۼ��ͼӺμ��ڵ�
    @V_DRCR_CLS_CD           VARCHAR(1),          -- ���뱸���ڵ�    
    @V_ACCT_DEPT_CD          VARCHAR(5),          -- �ͼӺμ��ڵ�    
    @V_ACCT_CD               VARCHAR(7),          -- �����ڵ�        
    @V_SEQ                   NUMERIC(5, 0),       -- ����            
    @V_PAY_BANK_CD           VARCHAR(2),          -- ���������ڵ�    
    @V_PCOST_DIV             VARCHAR(5),          -- �����ι�        
    @V_ACCT_NM               VARCHAR(100),        --TB_FI403.ACCT_NM%TYPE,               -- ������          
    @V_AMT                   NUMERIC(13, 0),      -- �ݾ�            
    @V_CLNT_NO               VARCHAR(100),        --TB_FI403.CLNT_NO%TYPE,               -- �ŷ�ó��ȣ      
    @V_SUMMARY               VARCHAR(100),        -- ����            
    @V_REQ_PAY_MTHD_CD       VARCHAR(2),          -- ��û���޹���ڵ�
    @V_PAY_DT                VARCHAR(8),          -- ��������        
    @V_OUTBR_SLIP_NO         VARCHAR(10),         -- �߻���ǥ��ȣ    
    @V_PAY_SLIP_NO           VARCHAR(10),         -- ������ǥ��ȣ    
    @V_SND_CLS_CD            VARCHAR(1),          -- ���۱����ڵ�    
    @V_REPLY_CLS_CD          VARCHAR(1),          -- ���䱸���ڵ�    
    @V_SND_DT                VARCHAR(8),          -- ��������        
    @V_SND_HH                VARCHAR(6),          -- ���۽ð�  
    
    @V_BILL_USER1            VARCHAR(100),        -- �ڵ��
    @V_BILL_USER2            VARCHAR(100),        -- �ڵ��
    @V_WDPTMAP_USER1         VARCHAR(20),         -- �ۼ��μ���
    @V_BANK_USER1            VARCHAR(100),        -- �����ڵ�
    @V_COSTMAP_USER1         VARCHAR(20),         -- �����μ� �����ڵ�
    @ACCT_DEPT_CD            VARCHAR(20),         -- ��ȸ�� ����
    
    @V_CLNT_MGNT_YN	         NUMERIC(1, 0) = 0,   --�ŷ�ó��������(1:����,0 : �̰���) 
    
    /* BEGIN CATCH ����� ���� ����  */
	@v_error_number				INT,
	@v_error_severity			INT,
	@v_error_state				INT,
	@v_error_procedure			VARCHAR(1000),
	@v_error_line				INT,
	@v_error_message			VARCHAR(3000),

	/* ERR_HANDLER ����� ���� ���� */
	@v_error_num			    INT,
	@v_row_count				INT,
	@v_error_code				VARCHAR(1000),										-- �����ڵ�
	@v_error_note				VARCHAR(3000),
    
    @OPENQUERY			     nvarchar(4000), 
	@TSQL					 nvarchar(4000), 
	--@LinkedServer			 nvarchar(20) = 'DEBISDEV'; 
	@LinkedServer			 nvarchar(20) = 'DEBIS'; 

BEGIN TRY
	/* ������ ���� �ʱ�ȭ ó�� */
	SET @v_error_code = '';
	SET @v_error_note = '';
	PRINT('����')
	
    -- �η������� �����ϴ� ����ȸ���ڵ�
	BEGIN
		SELECT @V_CO_CD = USER3
		  FROM B_DETAIL_CODE_COMPANY
		 WHERE CD_COMPANY = @P_COMPANY
		   AND CD_MASTER = 'HU513'
		   AND CD_DETAIL = @P_HRTYPE_GBN;
    END 
    
	 
	 -- ������ ��ǥ����ó���� ���� �޿����ޱ����ڵ� 
     BEGIN
		SELECT @V_BILL_USER1 = USER1
              ,@V_BILL_USER2 = USER2  
          FROM B_DETAIL_CODE_COMPANY
         WHERE CD_COMPANY = @P_COMPANY
           AND CD_MASTER = 'HU443'
           AND CD_DETAIL = @P_BILL_GBN;
     END 
     -- �޿����ޱ����ڵ�      
     SET @V_SAL_PAY_CLS_CD = SUBSTRING(@V_BILL_USER2, 1, 1);
	
	 -- ���������ڵ�
	 SET @V_PERS_CLS_CD =  SUBSTRING(@V_BILL_USER1, 1, 2);
	 PRINT('����������')
     BEGIN		
		SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
		SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI403 where SAL_PAY_DT = ''''' + @P_PROC_DATE + ''''' '
		SET @OPENQUERY = @OPENQUERY + ' AND SAL_PAY_CLS_CD = ''''' + @V_SAL_PAY_CLS_CD + ''''' AND PERS_CLS_CD = ''''' + @V_PERS_CLS_CD + ''''' '
		SET @OPENQUERY = @OPENQUERY + ' AND (REPLY_CLS_CD = ''''' + 'D' + ''''' OR REPLY_CLS_CD IS NULL )'
		SET @OPENQUERY = @OPENQUERY + ' AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 WHERE ACCT_YEAR = ''''' + SUBSTRING(@P_PROC_DATE, 1, 4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''')'')'
		EXEC (@OPENQUERY)
     END
	 
	 PRINT('����������')
     --���� �ʱ�ȭ
     SET @V_SEQ = 0;
     -- ��ǥ�������̺��� ��ü�� �����͸� �����´�.
     
     -- CURSOR ����
   	DECLARE C_PBT_BILL_CREATE CURSOR FOR -- ��ǥ���� �����͸� �����´�. 
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
             
    OPEN C_PBT_BILL_CREATE  -- Ŀ�� ��ġ
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
		PRINT('Ŀ�� ����')
         -- �����ʱ�ȭ  
         SET @V_BILL_USER1     = '';  --   VARCHAR2(100);  -- �ڵ��
         SET @V_BILL_USER2     = '';  --   VARCHAR2(100);  -- �ڵ��
         SET @V_WDPTMAP_USER1  = '';  --   VARCHAR2(20);   -- �ۼ��μ���
         SET @V_BANK_USER1     = '';  --   VARCHAR2(100);  -- �����ڵ�
         SET @V_COSTMAP_USER1  = '';  --   VARCHAR2(20);   -- �����μ� �����ڵ�
         SET @V_CLNT_NO        = '';  --                   --�ŷ�ó
         
         
         -- �޿��������� 
         SET @V_SAL_PAY_DT = @P_PROC_DATE;
         
         -- �޿����ޱ����ڵ�
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
	
	     -- ���������ڵ�
	     SET @V_PERS_CLS_CD =  SUBSTRING(@V_BILL_USER1, 1, 2);
	        
	     -- �ۼ��ͼӺμ��ڵ�
	     SET @V_DRAW_ACCT_DEPT_CD = @V_COSTDPT_CD;
	     
	    
	     PRINT '@@V_SAL_PAY_CLS_CD : ' + @V_SAL_PAY_CLS_CD
	     PRINT '@@V_PERS_CLS_CD : ' + @V_PERS_CLS_CD
	     PRINT '@V_COSTDPT_CD : ' + @V_COSTDPT_CD
	     PRINT '@V_DRAW_ACCT_DEPT_CD : ' + @V_DRAW_ACCT_DEPT_CD
	        
	        -- ���뱸���ڵ�(������ �Ǽ��� �ݴ�)
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
	    
	    -- �ͼӺμ��ڵ�
        BEGIN
			SELECT @V_WDPTMAP_USER1 = BIZ_ACCT  
              FROM B_COST_CENTER
             WHERE CD_COMPANY = @P_COMPANY
               AND CD_CC = @V_WRTDPT_CD;
        END 
        
        PRINT('@V_WDPTMAP_USER1 : ' + @V_WDPTMAP_USER1);
	        
	    SET @V_ACCT_DEPT_CD = SUBSTRING(@V_WDPTMAP_USER1, 1, 6);

		PRINT('@V_ACCT_DEPT_CD : ' + @V_ACCT_DEPT_CD);
	        
        -- �����ڵ�
        SET @V_ACCT_CD = SUBSTRING(@V_ACCNT_CD, 1, 7);
        --�����޺��-�ŷ�ó(2100810)�� ��� ���Ҽ��� �Է� ����üũ
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
	        
	        -- ����
	        SET @V_SEQ = @V_SEQ +1;
	        
	        -- ���������ڵ�  
	   --     BEGIN
				--SELECT @V_BANK_USER1 = USER1  
				--  FROM COT_CODE_INFO
				-- WHERE COMPANY_CD = @P_COMPANY
				--   AND CODE = @V_BANK_CD;
	   --     END 
	 
	        --SET @V_PAY_BANK_CD = SUBSTRING(@V_BANK_USER1, 1, 2);
	        
	        -- �����ι�
	        BEGIN
				SELECT @V_COSTMAP_USER1 = BIZ_ACCT  
				  FROM B_COST_CENTER
				 WHERE CD_COMPANY = @P_COMPANY
				   AND CD_CC = @V_COSTDPT_CD;
	        END

	        SET @V_PCOST_DIV = SUBSTRING(@V_COSTMAP_USER1, 1, 6);
	        
	                
	        -- ������
	        BEGIN
				SELECT @V_ACCT_NM = NM_ACCNT  
                  FROM H_ACCOUNT
                 WHERE CD_COMPANY = @P_COMPANY
                   AND CD_ACCNT = @V_ACCNT_CD;
	        END
	        
	        -- �ݾ�
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
	        
	        --DEBIS �ŷ�ó��ȣüũ
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
					PRINT('�ŷ�ó��ȣ : ' + @V_CLNT_NO)
					PRINT('@V_CUST_CHK : ' + @V_CUST_CHK)
				END
				
    	    PRINT('@V_CUST_CHK : ' + @V_CUST_CHK)
    	      
	        IF @V_CUST_CHK = 'N' 
				BEGIN 
					SET @p_error_code = 'E2';
					PRINT('ERROR @V_CUST_CHK : ' + @V_CUST_CHK)
					GOTO ERR_HANDLER;
				END
	        
	        
	        
	        --�����޺��-�ŷ�ó(2100810)�� ��� �ŷ�ó�Է¿��� üũ
	        IF @V_ACCT_CD = '2100810'
				BEGIN 
					IF @V_CLNT_NO  IS NULL OR @V_CLNT_NO =''
						BEGIN
							SET @p_error_code = 'E2'
							PRINT('ERROR @V_CLNT_NO, @V_CLNT_NO: ' + @V_CLNT_NO + ', ' + @V_CLNT_NO)
							GOTO ERR_HANDLER;
						END	
	            END 
	        
	        -- ����
	        SET @V_SUMMARY = @V_SUMMARY_BILL;
	        
	        -- ��û���޹���ڵ�
	        SET @V_REQ_PAY_MTHD_CD = SUBSTRING(@V_PAYMTWAY, 1, 2);
	        
	        -- �������� (��û���޹���ڵ尡 �����ü(20), �޿���ü(70)�� ��� �������� SETTING
	        SET @V_PAY_DT = '';
	        IF @V_PAYMTWAY = '20' OR @V_PAYMTWAY = '70'
				BEGIN
					IF @V_SAL_PAY_CLS_CD = 'B'
						BEGIN
							SET @V_PAY_DT = @V_PROC_DT;   --�󿩴� �״��ó��
						END	
					ELSE
						BEGIN
							IF (SUBSTRING(@V_PROC_DT, 7, 2) = '10')
								BEGIN
									SET @V_PAY_DT = CONVERT(VARCHAR(10), DATEADD(MONTH, 1, GETDATE()), 112) --�Ϳ����ϱ�
								END
							ELSE
								BEGIN
									SET @V_PAY_DT = @V_PROC_DT;   --�繫���� �״�� ó��
								END
						END
				END
				
	        -- �߻���ǥ��ȣ
	        SET @V_OUTBR_SLIP_NO = '';
	        
	        -- ������ǥ��ȣ
	        SET @V_PAY_SLIP_NO = '';
	        
	        -- ���۱����ڵ�
	        SET @V_SND_CLS_CD = '0';
	        
	        -- ���䱸���ڵ�
	        SET @V_REPLY_CLS_CD = '';
	        
	        -- ��������
	        BEGIN
				SET @V_SND_DT = CONVERT(VARCHAR(10), GETDATE(), 112)
            END
         
         -- ���۽ð�
           BEGIN
             SET @V_SND_HH = REPLACE(CONVERT(VARCHAR(10), GETDATE(), 8), ':', '')
           END
          
		   PRINT('AA');	
		   
           /* �ŷ�ó�ʼ� ����Ȯ�� */
           SET @V_CLNT_MGNT_YN = 0;                      --�ŷ�ó��������(1:����,0 : �̰���)    
           BEGIN    
				SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT CLNT_MGNT_YN FROM TB_FI001 where ACCT_CD = ''''' + @V_ACCT_CD + ''''''')'
				EXEC sp_executesql @OPENQUERY, N'@V_CLNT_MGNT_YN nvarchar(5) OUTPUT', @V_CLNT_MGNT_YN output
           END
           
           PRINT('BB')
           
           IF @V_CLNT_MGNT_YN = 1
				BEGIN
				  IF ISNULL(@V_CLNT_NO, '') = '' 
					 SET @V_CLNT_NO = '999912';    --�λ����ŷ�ó 
				END
           /* �ŷ�ó�ʼ� ����Ȯ�� ���� */     
           
/*  H83	�η���������	����ȸ���ڵ�
    H8301	EXPRESS	000
    H8302	DPCT	  007
    H8303	TOC	
    H8304	NTS	    001
    H8305	�뼺	  003
    H8306	DIMT	  011
    H8307	DBEX U.S.A	017
    H8308   BIDC	023
*/		
		PRINT('CC')
		IF @P_HRTYPE_GBN = 'H8301' 
			BEGIN   
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO =''
					BEGIN 
						SET @V_CLNT_NO = '999912';    --�λ����ŷ�ó 
					END
             END               
           
		IF @P_HRTYPE_GBN = 'H8304'
			BEGIN 
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO ='' 
					BEGIN
						SET @V_CLNT_NO = '999914';    --NTS�λ����ŷ�ó 
					END	
			END;           

		IF @P_HRTYPE_GBN = 'H8305'
			BEGIN 
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO =''
					BEGIN 
						SET @V_CLNT_NO = '999915';    --�뼺�λ����ŷ�ó 
					END
			END;

		IF @P_HRTYPE_GBN = 'H8306'
			BEGIN 
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO =''
					BEGIN  
						SET @V_CLNT_NO = '999916';    --DIMT �λ����ŷ�ó
					END
			END;
		
		IF @P_HRTYPE_GBN = 'H8308'
			BEGIN 
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO =''
					BEGIN  
						SET @V_CLNT_NO = '999917';    --BIDC �λ����ŷ�ó
					END
			END;

		IF @P_HRTYPE_GBN = 'H8309'
			BEGIN 
				IF @V_CLNT_NO IS NULL OR @V_CLNT_NO =''
					BEGIN  
						SET @V_CLNT_NO = '999918';    --��ȭ �λ����ŷ�ó
					END
			END;

         BEGIN
         
		PRINT('@V_DRAW_ACCT_DEPT_CD �׽�Ʈ : ' + @V_DRAW_ACCT_DEPT_CD)
         --INSERT INTO TB_FI403               --����
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
       
     CLOSE C_PBT_BILL_CREATE  --1��° Ŀ�� ����         
	 DEALLOCATE C_PBT_BILL_CREATE
         
     SET @p_error_code = 0;      
  RETURN

 -----------------------------------------------------------------------------------------------------------------------
  -- END Message Setting Block 
  ----------------------------------------------------------------------------------------------------------------------- 
  ERR_HANDLER:
		begin try
			PRINT('�����߻�')
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
		PRINT('���Ʈ����')
			DEALLOCATE	C_PBT_BILL_CREATE;
		end try
		begin catch
		print 'Error CATCH Process Block';
		end catch;
	RETURN;
END CATCH 

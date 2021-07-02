SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_PBT_AT_DEBIS_B_IF](
		@av_company_cd			NVARCHAR(10),
		@av_hrtype_gbn			NVARCHAR(10),	-- �η�����
		@av_bill_gbn			NVARCHAR(10),	-- ��ǥ����
		@av_pay_ym				NVARCHAR(10),	-- �޿����
		--@an_pay_ymd_id			NUMERIC(38,0),	-- �޿�����
		@av_pay_type_sys_cd		NVARCHAR(10),	-- �޿��ڵ�[pay_type_cd:sys_cd]

		@ad_proc_date			DATE,			-- ó������
		@av_emp_no				NVARCHAR(10),	-- ó����
		@av_locale_cd			NVARCHAR(10),
		@av_tz_cd				NVARCHAR(10),    -- Ÿ�����ڵ�
		@an_mod_user_id			NUMERIC(18,0)  ,    -- ������ ID
		@av_ret_code			NVARCHAR(100)    OUTPUT,
		@av_ret_message			NVARCHAR(500)    OUTPUT
		)
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : ���α׷� ���λ� �ý��� - ��ǥ����(BIDC)
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PBT_AT_DEBIS_B_IF
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 
    --<DOCLINE>   HISTORY     : �ۼ� 2020.11.04
    --<DOCLINE> ***************************************************************************
SET NOCOUNT ON

DECLARE
	@objcursor            as cursor,
 -- ��� ��������
	@V_PBT_ACCNT_STD_ID		NUMERIC(38),		-- ����������ID
    @V_WRTDPT_CD           VARCHAR(40),          -- �ۼ��μ�
    @V_BILL_GBN            VARCHAR(40),          -- ��ǥ����
    @V_TRDTYP_CD           VARCHAR(40),          -- �ŷ�����
    @V_ACCNT_CD            VARCHAR(40),          -- �����ڵ�
    @V_AGGR_GBN            VARCHAR(40),          -- ���豸��(�����μ�/���/����)
    @V_CUST_CD             VARCHAR(40),          -- �ŷ�ó�ڵ�
    @V_DEBSER_GBN          VARCHAR(40),          -- ���뱸��(����/�뺯)
    @V_COSTDPT_CD          VARCHAR(40),          -- �����μ�
    @V_COSTDPT_TM          VARCHAR(40),          -- �����μ�
    @V_TRDTYP_NM           VARCHAR(200),         -- �ŷ�ó��
    @V_TRDTYP_NM_E         VARCHAR(200),         -- �ŷ�ó��
    @V_SUMMARY             VARCHAR(400),         -- ����
    @V_SUMMARY_TM          VARCHAR(400),         -- ����(TEMP)
    @V_SUMMARY_CNT         NUMERIC(5, 0),        -- ���� ��
    @V_SABUN               VARCHAR(24),          -- ���
    
    @V_INCITEM             VARCHAR(20),          -- �����׸�
    @V_ITEM_CD             VARCHAR(20),          -- �׸��ڵ�
    @V_INCITEM_FR          VARCHAR(20),          -- �����׸�From
    @V_INCITEM_TO          VARCHAR(20),          -- �����׸�To
    
    @V_EXCITEM             VARCHAR(20),          -- �����׸�
    @V_EXITEM_CD           VARCHAR(20),          -- �����ڵ�
    @V_EXCITEM_FR          VARCHAR(20),          -- �����׸�From
    @V_EXCITEM_TO          VARCHAR(20),          -- �����׸�To
    
    @V_INCITEM_STR         varchar(max),                    -- ���ǿ� �� �����׸�
    @V_EXCITEM_STR         varchar(max),                    -- ���ǿ� �� �����׸�
    @V_RESULT_STR          Nvarchar(max),                   -- ���ǿ� ���� �ݾ��� ���´�.
    @V_ALOW_STR            varchar(max),                    -- �����׸���
    @V_DEDT_STR            varchar(max),                    -- �����׸���
    @V_INCCOSTDPT_STR      varchar(max),                    -- ���ǿ� �� �����׸�
    @V_INCJIKGUB_STR       varchar(max),                    -- ���ǿ� �� �����׸�
    @V_SABUN_STR           varchar(max),                    -- ����(���)
    @V_BANK_STR            varchar(max),                    -- ����(����)
    @V_EXCOSTDPT_STR       varchar(max),                    -- ���ǿ� �� �����׸�
    @V_EXJIKGUB_STR        varchar(max),                    -- ���ǿ� �� �����׸�
    @V_EXSABUN_STR         varchar(max),                    -- ����(���ܻ��)
    @V_EXBANK_STR          varchar(max),                    -- ����(��������)
    @V_ALOW_CNT            NUMERIC(4, 0),                   -- ���� ��
    @V_DEDT_CNT            NUMERIC(4, 0),                   -- ���� ��
    @V_INCCOSTDPT_CNT      NUMERIC(4, 0),                   -- �����μ� ��
    @V_INCJIKGUB_CNT       NUMERIC(4, 0),                   -- ���� ��
    @V_SABUN_CNT           NUMERIC(4, 0),                   -- ��� ��
    @V_BANK_CNT            NUMERIC(4, 0),                   -- ���� ��
    @V_EXCOSTDPT_CNT       NUMERIC(4, 0),                   -- �����μ� ��
    @V_EXJIKGUB_CNT        NUMERIC(4, 0),                   -- ���� ��
    @V_EXSABUN_CNT         NUMERIC(4, 0),                   -- ���ܻ�� ��
    @V_EXBANK_CNT          NUMERIC(4, 0),                   -- �������� ��
    @V_HRTYPE_GBN          VARCHAR(20),                     -- �η�����
    @V_SAWON_GBN           VARCHAR(20),                     -- �������
    @V_PAY_YN              VARCHAR(20),                     -- �������޾�YN
    @V_PAY_TOT             NUMERIC(12,0),                   -- �������޾� 
    @V_COSTDPTCD           VARCHAR(20),                     -- �����μ�  
    @V_ORG_COSTCD          VARCHAR(20),                     -- �����μ�  
    
    @V_BANK_NM             VARCHAR(200),                    -- �����
    @V_TOT                 NUMERIC(12,0),                   -- ������ ������ ��� 
    @V_SQL_PAY_MASTER      varchar(max),                    -- �������� ����� DYNAMIC QUERY�� 
    @V_SEQ                 NUMERIC(5,0),                    -- ����
    @V_MM                  VARCHAR(4),                      -- ��
    @V_BANK_CD             VARCHAR(20),                     -- �����ڵ�         
    @V_PAYMTWAY            VARCHAR(20),                     -- ���Ҽ���
    @V_SQL_STR             varchar(max),                    -- BILL ����
    
    @S_TEMP                varchar(max),
    
    @V_CLNT_MGNT_YN	       NUMERIC(1,0) = 0,                 --�ŷ�ó��������(1:����,0 : �̰���)        
    @V_ACCT_CLS_CD         VARCHAR(01), 
    @V_COST_CLS_CD         VARCHAR(02),      
    @V_COST_ACCTCD         VARCHAR(20),    -- ���������ڵ�
    @V_MGNT_ACCTCD         VARCHAR(20),    -- �ǰ�������ڵ�
    @V_BIZ_ACCT            NVARCHAR(20),
    

    @V_BATCH_LOGID         NUMERIC(10),                                                -- ��ġ�α�ID
    @V_BATCH_WORKNM        VARCHAR(100) = '�λ��/����ǥ����',     -- ��ġ�α׳��뿡 ���氪
    @V_PROCNM              VARCHAR(200),     
    
    @V_PRE_MON_YYMMDD      VARCHAR(16),            -- ����
    @V_CSTDPAT_CD          VARCHAR(20),
        
 -- CURSOR�� ����
   	@V_PBT_ACCNT_STD       VARCHAR,    -- ��ǥ����
   	@V_PBT_INCITEM         VARCHAR,     -- ���Ե� �׸�
   	@V_PBT_EXCITEM         VARCHAR,     -- ���ܵ� �׸�
	
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
	@v_error_note				VARCHAR(3000),										-- ������Ʈ (exec : '���ڿ�A|���ڿ�B')
	
	@V_CNT_MAIN                 INT,
	@OPENQUERY					nvarchar(4000), 
	@TSQL						nvarchar(4000), 
	@LinkedServer				nvarchar(20) = 'DEBIS';
	--@LinkedServer				nvarchar(20) = 'DEBIS_DEV';
        /* �⺻������ ���Ǵ� ���� */
DECLARE @v_program_id		NVARCHAR(30)
      , @v_program_nm		NVARCHAR(100)
      , @v_ret_code			NVARCHAR(100)
      , @v_ret_message		NVARCHAR(500)
DECLARE @v_is_link_test			NVARCHAR(10)
      , @v_is_print			NVARCHAR(10)
DECLARE @n_cnt				INT
BEGIN TRY
	SET @v_is_link_test = 'TEST'
	SET @v_is_print = 'TEST'

    SET @v_program_id   = 'P_PBT_AT_DEBIS_B_IF'
    SET @v_program_nm   = 'DEBIS�޿���ǥ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);

	IF @v_is_print = 'TEST' print('����')
    BEGIN
		SET @v_error_code = '';
		SET @v_error_note = '';
		
		SET @V_CNT_MAIN = 0;
		IF @v_is_print = 'TEST' PRINT('��ǥ���̺� ����')    
		DELETE FROM PBT_BILL_CREATE 
		 WHERE COMPANY_CD  = @av_company_cd         -- ȸ���ڵ� (E����)
		   AND HRTYPE_GBN = @av_hrtype_gbn    -- �η���������
		   AND PAY_YM   = @av_pay_ym          -- �޿����
		   AND PAY_CD   = @av_pay_type_sys_cd          -- �޿��ڵ�
		   --AND PAY_YMD_ID = @an_pay_ymd_id    -- �޿�����
		   AND BILL_GBN = @av_bill_gbn        -- ��ǥ����
		   AND PROC_DT  = dbo.XF_TO_CHAR_D( @ad_proc_date, 'yyyymmdd');      -- ó������
		IF @@error <> 0
			BEGIN
				SET @v_error_number = @@error;
				SET @v_error_code = 'P_PBT_AT_DEBIS_B_IF';
				SET @v_error_note = 'PBT_BILL_CREATE TABLE ���� ���� �� ������ �߻��Ͽ����ϴ�.'
				GOTO ERR_HANDLER
			END
	END
	
	BEGIN
		--PRINT('Ŀ������!!')
		SELECT @V_SEQ = ISNULL(MAX(SEQ), 0)
		  FROM PBT_BILL_CREATE 
		 WHERE COMPANY_CD  = @av_company_cd         -- ȸ���ڵ�
		   AND HRTYPE_GBN = @av_hrtype_gbn    -- �η���������
		   AND PAY_YM   = @av_pay_ym          -- �޿����
		   AND PAY_CD   = @av_pay_type_sys_cd          -- �޿��ڵ�
		   --AND PAY_YMD_ID = @an_pay_ymd_id    -- �޿�����
		   AND BILL_GBN = @av_bill_gbn        -- ��ǥ����
		
		DECLARE	C_PBT_ACCNT_STD	CURSOR	FOR                 -- ��ǥ�ڵ�� ������ ��ǥ�� �����´�. 
		SELECT PBT_ACCNT_STD_ID, WRTDPT_CD,   BILL_GBN,   TRDTYP_CD,    ACCNT_CD
			  ,CUST_CD,     AGGR_GBN,   CSTDPAT_CD,   CSTDPAT_CD
			  ,TRDTYP_NM,   TRDTYP_NM,  SUMMARY,      DEBSER_GBN
			  ,COST_ACCTCD, MGNT_ACCTCD    -- �ǰ�������ڵ�
		  FROM PBT_ACCNT_STD
		 WHERE COMPANY_CD = @av_company_cd         -- ȸ���ڵ�
		   AND HRTYPE_GBN = @av_hrtype_gbn    -- �η���������
		   AND BILL_GBN = @av_bill_gbn          -- ��ǥ����
		   AND USE_YN = 'Y'
		 ORDER BY DEBSER_GBN, TRDTYP_CD
		   --��ǥ�ڵ庰�� ��ǥ������ �����´�. 
        
        OPEN C_PBT_ACCNT_STD  -- Ŀ�� ��ġ
		FETCH NEXT FROM C_PBT_ACCNT_STD	INTO	@V_PBT_ACCNT_STD_ID,
												@V_WRTDPT_CD,
												@V_BILL_GBN,
												@V_TRDTYP_CD,
												@V_ACCNT_CD,
												@V_CUST_CD,
												@V_AGGR_GBN,
												@V_CSTDPAT_CD,
												@V_COSTDPT_TM,
												@V_TRDTYP_NM,
												@V_TRDTYP_NM_E,
												@V_SUMMARY,
												@V_DEBSER_GBN,
												@V_COST_ACCTCD,
												@V_MGNT_ACCTCD
		
		WHILE	@@fetch_status	=	0
		
		BEGIN
			IF @v_is_print = 'TEST' PRINT('C_PBT_ACCNT_STD Ŀ�� ���� ' + CAST(@V_CNT_MAIN AS VARCHAR) + '��° ����')
			SET @V_CNT_MAIN = @V_CNT_MAIN + 1;
			SET @V_SUMMARY_TM = '';
			SET @V_BANK_CD = '';
			SET @V_PAYMTWAY = '';
			SET @V_SABUN = '';
			SET @V_SUMMARY_CNT = 0;
			SET @V_INCITEM_STR = '';
			SET @V_COSTDPTCD ='';
			SET @V_COSTDPT_CD ='';
			SET @V_ORG_COSTCD = '';
			SET @V_INCCOSTDPT_STR = '';
			SET @V_INCJIKGUB_STR  = '';
			SET @V_EXCITEM_STR = '';
			SET @V_RESULT_STR  = '';
			SET @V_ALOW_STR    = '';
			SET @V_DEDT_STR    = '';
			SET @V_SABUN_STR   = '';
			SET @V_BANK_STR    = '';
			SET @V_EXCOSTDPT_STR = '';
			SET @V_EXJIKGUB_STR  = '';
			SET @V_EXSABUN_STR = '';
			SET @V_EXBANK_STR  = '';
			SET @V_PAY_YN      = '';
			SET @V_ALOW_CNT    = 0;
			SET @V_DEDT_CNT    = 0;
			SET @V_INCCOSTDPT_CNT = 0;
			SET @V_INCJIKGUB_CNT  = 0;
			SET @V_SABUN_CNT   = 0;
			SET @V_BANK_CNT    = 0;
			SET @V_EXCOSTDPT_CNT  = 0;
			SET @V_EXJIKGUB_CNT   = 0;
			SET @V_EXSABUN_CNT = 0;
			SET @V_EXBANK_CNT  = 0;
			
			/* ��ǥ���� Ȯ�ο� ���� */
			--PRINT('========================================')
			--PRINT('@V_WRTDPT_CD   ' + @V_WRTDPT_CD );
			--PRINT('@V_BILL_GBN    ' + @V_BILL_GBN );
			--PRINT('@V_TRDTYP_CD   ' + @V_TRDTYP_CD);
			--PRINT('@V_ACCNT_CD    ' + @V_ACCNT_CD);
			--PRINT('========================================')
		
          
			--PRINT('2��° Ŀ������!!') 
			DECLARE C_PBT_INCITEM CURSOR FOR                  -- ��ǥ������ ���� ���Ե� �׸��� �����´�. 
			SELECT ITEM_CD,
				   INCITEM,
				   INCITEM_FR,
				   INCITEM_TO 
			  FROM PBT_INCITEM
			 WHERE PBT_ACCNT_STD_ID = @V_PBT_ACCNT_STD_ID
			 ORDER BY ITEM_CD, SEQ
			
			OPEN C_PBT_INCITEM  -- Ŀ�� ��ġ
			FETCH NEXT FROM C_PBT_INCITEM INTO   @V_ITEM_CD,
												 @V_INCITEM,
												 @V_INCITEM_FR,
												 @V_INCITEM_TO 
			WHILE	@@fetch_status = 0
		
			BEGIN   
				 --�η������� ���
				 IF @V_ITEM_CD = 'A'
					BEGIN
						SET @V_INCITEM_STR = @V_INCITEM_STR + ' AND PRI.FROM_TYPE_CD = ''' + @V_INCITEM + '''';
					END
				 --��������� ���
				 IF @V_ITEM_CD = 'B'
					BEGIN
						SET @V_INCITEM_STR = @V_INCITEM_STR + ' AND ROLL.EMP_KIND_CD = ''' + @V_INCITEM + '''';
					END
				 --�����μ��� ���
				 IF @V_ITEM_CD = 'C'
					BEGIN
						SET @V_INCCOSTDPT_CNT = @V_INCCOSTDPT_CNT + 1;
						IF @V_INCCOSTDPT_CNT = 1
							BEGIN
								SET @V_INCCOSTDPT_STR = @V_INCCOSTDPT_STR + ' AND ((ROLL.ACC_CD BETWEEN ''' + @V_INCITEM_FR + ''' AND ''' + @V_INCITEM_TO + ''')' + CHAR(13);
							END
						ELSE
							BEGIN
								SET @V_INCCOSTDPT_STR = @V_INCCOSTDPT_STR + ' OR (ROLL.ACC_CD BETWEEN ''' + @V_INCITEM_FR + ''' AND ''' + @V_INCITEM_TO + ''')' + CHAR(13);
							END
					END    
				 --������ ���
				 IF @V_ITEM_CD = 'D'
					BEGIN
						SET @V_INCJIKGUB_CNT = @V_INCJIKGUB_CNT + 1;
						IF @V_INCJIKGUB_CNT = 1
							BEGIN
								SET @V_INCJIKGUB_STR = @V_INCJIKGUB_STR + ' AND ((ISNULL(dbo.F_FRM_CODE_NM(YMD.COMPANY_CD,''KO'',''PBT_POS_GRD_CD'', EMP.POS_GRD_CD, YMD.PAY_YMD,''M''),'''') BETWEEN ''' + @V_INCITEM_FR + ''' AND ''' + @V_INCITEM_TO + ''')';
							END
						ELSE
							BEGIN
                 				SET @V_INCJIKGUB_STR = @V_INCJIKGUB_STR + ' OR (ISNULL(dbo.F_FRM_CODE_NM(YMD.COMPANY_CD,''KO'',''PBT_POS_GRD_CD'', EMP.POS_GRD_CD, YMD.PAY_YMD,''M''),'''') BETWEEN ''' + @V_INCITEM_FR + ''' AND ''' + @V_INCITEM_TO + ''')';
							END
					END
				 
				 --����� ���
				 IF @V_ITEM_CD = 'E'
					BEGIN
						SET @V_SABUN_CNT = @V_SABUN_CNT + 1;
						IF @V_SABUN_CNT = 1
							BEGIN
								SET @V_SABUN_STR = @V_SABUN_STR + ' AND EMP.EMP_NO IN (''' + @V_INCITEM + ''''
							END
						ELSE
							BEGIN
                   				SET @V_SABUN_STR = @V_SABUN_STR + ' ,''' + @V_INCITEM + ''''
							END
					END
				 -- ������ �����Ͱ� ����
				 ----������ ���
				 --IF @V_ITEM_CD = 'F'
					--BEGIN
					--	SET @V_BANK_CNT = @V_BANK_CNT + 1;
					--	IF @V_BANK_CNT = 1
					--		BEGIN
					--			SET @V_BANK_STR = @V_BANK_STR + ' AND PAY_BANKCD IN (''' + (CASE WHEN LEFT(@V_INCITEM, 1) > 1 THEN '19' ELSE '20' END + @V_INCITEM) + ''''
					--		END
					--	ELSE
					--		BEGIN
     --              				SET @V_BANK_STR = @V_BANK_STR + ' ,''' + @V_INCITEM + ''''
	                 
					--		END
					--END
				 --������ ���
				 IF @V_ITEM_CD = 'G'
					 BEGIN
						IF @V_INCITEM = 'P98080'   --(�޿��Ѿ�)
							BEGIN
							--SET @V_ALOW_STR = @V_ALOW_STR + ' AND CD_ALLOW IN ( SELECT CD_ALLOW FROM H_MONTH_SUPPLY WHERE CD_COMPANY = ''' + @P_COMPANY + '''' +
							--				  ' AND YM_PAY = ''' + @P_YYYYMM + '''' + ' AND FG_SUPP = ''' + @P_PAY_CD + '''' 
							-- �����Ѿ�
							SET @V_ALOW_STR = @V_ALOW_STR + ' AND (DTL.PAY_ITEM_TYPE_CD=''PAY_PAY'''
							END
						ELSE
							BEGIN
								SET @V_ALOW_CNT = @V_ALOW_CNT + 1;
								IF @V_ALOW_CNT = 1
									BEGIN 
										SET @V_ALOW_STR = @V_ALOW_STR + ' AND DTL.PAY_ITEM_CD IN (''' + @V_INCITEM + ''''
									END
								ELSE
									BEGIN
                     					SET @V_ALOW_STR = @V_ALOW_STR + ' ,''' + @V_INCITEM + ''''
                     				END
                     		END
					END
				 --������ ���
				 IF @V_ITEM_CD = 'H'
					BEGIN
						IF @V_INCITEM = 'P99051'  --(�������޾�)
							BEGIN
								--PRINT('�������޾�')
								SET @V_PAY_YN = 'Y';
							END
						ELSE IF @V_INCITEM = 'P99050'  --(�����Ѿ�)
							BEGIN
								--PRINT('�����Ѿ� SELECT')
								--SET @V_DEDT_STR = @V_DEDT_STR + ' AND CD_DEDUCT IN ( SELECT CD_DEDUCT FROM H_MONTH_DEDUCT WHERE CD_DEDUCT NOT IN (''205'') AND CD_COMPANY = ''' + @P_COMPANY + '''' +
								--					 ' AND YM_PAY = ''' + @P_YYYYMM + '''' + ' AND FG_SUPP = ''' + @P_PAY_CD + ''''; 
								SET @V_DEDT_STR = @V_DEDT_STR + ' AND (DTL.PAY_ITEM_CD NOT IN (''D020'') AND DTL.PAY_ITEM_TYPE_CD=''DEDUCT'' '
							END
						ELSE
							BEGIN
                 				SET @V_DEDT_CNT = @V_DEDT_CNT + 1;
								IF @V_DEDT_CNT = 1 
									BEGIN
										SET @V_DEDT_STR = @V_DEDT_STR + ' AND DTL.PAY_ITEM_CD IN (''' + @V_INCITEM + '''';
									END
								ELSE
									BEGIN
                     					SET @V_DEDT_STR = @V_DEDT_STR + ' ,''' + @V_INCITEM + '''';
                     				END
                     		END
					 END
			
				 FETCH NEXT FROM C_PBT_INCITEM INTO   @V_ITEM_CD,
													  @V_INCITEM,
													  @V_INCITEM_FR,
													  @V_INCITEM_TO 
			END    
        
			CLOSE	C_PBT_INCITEM
			-- Ŀ�� ����
			DEALLOCATE	C_PBT_INCITEM
		
		IF ISNULL(@V_INCCOSTDPT_STR, '') <> ''
			BEGIN
				SET @V_INCCOSTDPT_STR = @V_INCCOSTDPT_STR + ')';
			END
         
         IF ISNULL(@V_INCJIKGUB_STR, '') <> ''
			BEGIN
				SET @V_INCJIKGUB_STR = @V_INCJIKGUB_STR + ')';
			END
         
         IF ISNULL(@V_SABUN_STR, '') <> ''
			BEGIN
				SET @V_SABUN_STR = @V_SABUN_STR + ')';
			END
         
         IF ISNULL(@V_BANK_STR, '') <> ''
			BEGIN
				SET @V_BANK_STR = @V_BANK_STR + ')';
			END
         
         IF ISNULL(@V_ALOW_STR, '') <> ''
			BEGIN
				SET @V_ALOW_STR = @V_ALOW_STR + ')';
			END
         
         IF ISNULL(@V_DEDT_STR, '') <> ''
			BEGIN
				SET @V_DEDT_STR = @V_DEDT_STR + ')';
			END     
           
		DECLARE C_PBT_EXCITEM CURSOR FOR                 -- ��ǥ������ ���� ���ܵ� �׸��� �����´�. 
			SELECT ITEM_CD,
                   EXCITEM,
				   EXCITEM_FR,
				   EXCITEM_TO 
			  FROM PBT_EXCITEM
			 WHERE PBT_ACCNT_STD_ID = @V_PBT_ACCNT_STD_ID
			ORDER BY ITEM_CD, SEQ;
		
		OPEN C_PBT_EXCITEM
         FETCH NEXT FROM C_PBT_EXCITEM INTO   @V_EXITEM_CD,
											  @V_EXCITEM,
											  @V_EXCITEM_FR,
											  @V_EXCITEM_TO 
		
		 WHILE	@@fetch_status	=	0  
		 
		 BEGIN       
             --�����μ��� ���
              IF @V_EXITEM_CD = 'C'
				BEGIN
					SET @V_EXCOSTDPT_CNT = @V_EXCOSTDPT_CNT + 1;
					IF @V_EXCOSTDPT_CNT = 1
						BEGIN
							SET @V_EXCOSTDPT_STR = @V_EXCOSTDPT_STR + ' AND ((ROLL.ACC_CD NOT BETWEEN '''+ @V_EXCITEM_FR + ''' AND ''' + @V_EXCITEM_TO + ''')';
						END
					ELSE
						BEGIN
                 			SET @V_EXCOSTDPT_STR = @V_EXCOSTDPT_STR + ' AND  (ROLL.ACC_CD NOT BETWEEN '''+ @V_EXCITEM_FR + ''' AND ''' + @V_EXCITEM_TO + ''')';
						END
				END
             --������ ���
              IF @V_EXITEM_CD = 'D'
				BEGIN
					SET @V_EXJIKGUB_CNT = @V_EXJIKGUB_CNT + 1;
					IF @V_EXJIKGUB_CNT = 1
						BEGIN 
							SET @V_EXJIKGUB_STR = @V_EXJIKGUB_STR + ' AND ((ISNULL(dbo.F_FRM_CODE_NM(YMD.COMPANY_CD,''KO'',''PBT_POS_GRD_CD'', EMP.POS_GRD_CD, YMD.PAY_YMD,''M''),'''') NOT BETWEEN ''' + @V_EXCITEM_FR + ''' AND ''' + @V_EXCITEM_TO + ''')';
						END
					ELSE
						BEGIN
							SET @V_EXJIKGUB_STR = @V_EXJIKGUB_STR + ' AND (ISNULL(dbo.F_FRM_CODE_NM(YMD.COMPANY_CD,''KO'',''PBT_POS_GRD_CD'', EMP.POS_GRD_CD, YMD.PAY_YMD,''M''),'''') NOT BETWEEN ''' + @V_EXCITEM_FR + ''' AND ''' + @V_EXCITEM_TO + ''')';
						END
				END		
              --����� ���
              IF @V_EXITEM_CD = 'E'
				BEGIN
					SET @V_EXSABUN_CNT = @V_EXSABUN_CNT + 1;
					IF @V_EXSABUN_CNT = 1
						BEGIN 
							SET @V_EXSABUN_STR = @V_EXSABUN_STR + ' AND EMP.EMP_NO NOT IN (''' + @V_EXCITEM + '''';
						END
					ELSE
						BEGIN
                   			SET @V_EXSABUN_STR = @V_EXSABUN_STR + ' ,''' + @V_EXCITEM + '''';
                   		END
                END
				-- �����ڵ�� DATA�� ����.
    --         --������ ���
    --          IF @V_EXITEM_CD = 'F'
				--BEGIN 
				--	SET @V_EXBANK_CNT = @V_EXBANK_CNT + 1;
				--	IF @V_EXBANK_CNT = 1
				--		BEGIN
				--			SET @V_EXBANK_STR = @V_EXBANK_STR + ' AND PAY_BANKCD NOT IN (''' + @V_EXCITEM + '''';
				--		END
				--	ELSE
				--		BEGIN
    --               			SET @V_EXBANK_STR = @V_EXBANK_STR + ' ,''' + @V_EXCITEM + '''';
    --               		END
    --            END
  
			FETCH NEXT FROM C_PBT_EXCITEM INTO  @V_EXITEM_CD,
											    @V_EXCITEM,
											    @V_EXCITEM_FR,
											    @V_EXCITEM_TO
	         
         END
        
         CLOSE C_PBT_EXCITEM;  -- �����׸� ����
         DEALLOCATE C_PBT_EXCITEM;
		
		 
		 IF ISNULL(@V_EXCOSTDPT_STR, '') <> ''
			BEGIN
				SET @V_EXCOSTDPT_STR = @V_EXCOSTDPT_STR + ')';
			END

         IF ISNULL(@V_EXJIKGUB_STR, '') <> ''
			BEGIN
				SET @V_EXJIKGUB_STR = @V_EXJIKGUB_STR + ')';
			END
         
         IF ISNULL(@V_EXSABUN_STR, '') <> ''
			BEGIN
				SET @V_EXSABUN_STR = @V_EXSABUN_STR + ')';
			END
         
         IF ISNULL(@V_EXBANK_STR, '') <> ''
			BEGIN
				SET @V_EXBANK_STR = @V_EXBANK_STR + ')';
			END
		
		 --PRINT('@V_EXCOSTDPT_STR : ' + @V_EXCOSTDPT_STR); 
		 --PRINT('@V_EXJIKGUB_STR : ' + @V_EXJIKGUB_STR);
		 --PRINT('@V_EXSABUN_STR : ' + @V_EXSABUN_STR);
		 --PRINT('@V_EXBANK_STR : ' + @V_EXBANK_STR);
		 
		 
		 --PRINT('@V_ITEM_CD : ' + @V_ITEM_CD);
		 --PRINT('@V_AGGR_GBN : ' + @V_AGGR_GBN);
		 	       
         --������ ���                                                                                                                   
         IF @V_ITEM_CD = 'G'
			BEGIN                                                                                                
             --���豸���� �����μ��� ���                                                                                         
				IF @V_AGGR_GBN = 'A1'
					BEGIN
						SET @V_RESULT_STR = ' SELECT '''' AS SABUN' +
						                    ' , ROLL.ACC_CD AS COSTDPT_CD' +
											' , SUM(DTL.CAL_MON) AS TOT' +
											' , SUM(DTL.CAL_MON) AS AMT' +
											' FROM PAY_PAY_YMD YMD' +
											' INNER JOIN PAY_PAYROLL ROLL' +
											'         ON YMD.PAY_YMD_ID = ROLL.PAY_YMD_ID' +
											' INNER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) AS CAL_MON' +
											'               FROM PAY_PAYROLL_DETAIL DTL' +
											'              WHERE 1=1 ' + @V_ALOW_STR +
											'              GROUP BY PAY_PAYROLL_ID) DTL' +
											'         ON ROLL.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID ' +
											' INNER JOIN VI_FRM_PHM_EMP EMP' +
											'         ON ROLL.EMP_ID = EMP.EMP_ID' +
											'        AND YMD.COMPANY_CD = EMP.COMPANY_CD AND EMP.LOCALE_CD=''KO''' +
											' INNER JOIN PHM_PRIVATE PRI' +
											'         ON ROLL.EMP_ID = PRI.EMP_ID' +
											'        AND CASE WHEN EMP.IN_OFFI_YN != ''Y'' THEN RETIRE_YMD WHEN YMD.PAY_YMD < EMP.HIRE_YMD THEN EMP.HIRE_YMD ELSE YMD.PAY_YMD END BETWEEN PRI.STA_YMD AND PRI.END_YMD' +
											--' WHERE YMD.PAY_YMD_ID = ' + CONVERT(nvarchar(100), @an_pay_ymd_id) +
											' WHERE YMD.COMPANY_CD = ''' + @av_company_cd + '''' +
											'   AND YMD.CLOSE_YN = ''Y''' +
											'   AND YMD.PAY_YM = ''' + @av_pay_ym + '''' +
											'   AND YMD.PAY_YMD = ''' + dbo.XF_TO_CHAR_D(@ad_proc_date,'YYYYMMDD') + '''' +
											'   AND YMD.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE' +
											'                            WHERE COMPANY_CD=YMD.COMPANY_CD' +
											'                              AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD' +
											'                              AND SYS_CD = ''' + @av_pay_type_sys_cd + ''')' +
											'   AND PRI.FROM_TYPE_CD = ''' + @av_hrtype_gbn + '''' + --����
											 CHAR(13) +
											        @V_INCITEM_STR +
											 CHAR(13) + @V_INCCOSTDPT_STR +
											 CHAR(13) + @V_INCJIKGUB_STR +
											 CHAR(13) + @V_SABUN_STR +
											 CHAR(13) + @V_BANK_STR + 
											 CHAR(13) + @V_EXCITEM_STR +
											 CHAR(13) + @V_EXCOSTDPT_STR +
											 CHAR(13) + @V_EXJIKGUB_STR +
											 CHAR(13) + @V_EXSABUN_STR +
											 CHAR(13) + @V_EXBANK_STR + 
											 CHAR(13) +
											' GROUP BY ROLL.ACC_CD'
											 --PRINT('@V_INCITEM_STR : ' + @V_INCITEM_STR)
											 --PRINT('@V_INCCOSTDPT_STR : ' + @V_INCCOSTDPT_STR)
											 --PRINT('@V_INCJIKGUB_STR : ' + @V_INCJIKGUB_STR)
											 --PRINT('@V_SABUN_STR : ' + @V_SABUN_STR)
											 --PRINT('@V_BANK_STR : ' + @V_BANK_STR)
											 --PRINT('@V_EXCITEM_STR : ' + @V_EXCITEM_STR)
											 --PRINT('@V_EXCOSTDPT_STR : ' + @V_EXCOSTDPT_STR)
											 --PRINT('@V_EXJIKGUB_STR : ' + @V_EXJIKGUB_STR)
											 --PRINT('@V_EXSABUN_STR : ' + @V_EXSABUN_STR)
											 --PRINT('@V_EXBANK_STR : ' + @V_EXBANK_STR)
			--20070403  ' GROUP BY A.COMPANY, A.WORK_YM, A.PAY_CD, A.COSTDPT_CD, TOT, ALOWTOT_AMT, DEDTTOT_AMT  '; 
					END     

             --���豸���� ������ ���                                                                                             
				ELSE IF @V_AGGR_GBN = 'A2'
					BEGIN
						SET @V_RESULT_STR = ' SELECT '''' AS SABUN' +
						                    ' , '''' AS COSTDPT_CD' +
											' , SUM(DTL.CAL_MON) AS TOT' +
											' , SUM(DTL.CAL_MON) AS AMT' +
											' FROM PAY_PAY_YMD YMD' +
											' INNER JOIN PAY_PAYROLL ROLL' +
											'         ON YMD.PAY_YMD_ID = ROLL.PAY_YMD_ID' +
											' INNER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) AS CAL_MON' +
											'               FROM PAY_PAYROLL_DETAIL DTL' +
											'              WHERE 1=1 ' + @V_ALOW_STR +
											'              GROUP BY PAY_PAYROLL_ID) DTL' +
											'         ON ROLL.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID ' +
											' INNER JOIN VI_FRM_PHM_EMP EMP' +
											'         ON ROLL.EMP_ID = EMP.EMP_ID' +
											'        AND YMD.COMPANY_CD = EMP.COMPANY_CD AND EMP.LOCALE_CD=''KO''' +
											' INNER JOIN PHM_PRIVATE PRI' +
											'         ON ROLL.EMP_ID = PRI.EMP_ID' +
											'        AND CASE WHEN EMP.IN_OFFI_YN != ''Y'' THEN RETIRE_YMD WHEN YMD.PAY_YMD < EMP.HIRE_YMD THEN EMP.HIRE_YMD ELSE YMD.PAY_YMD END BETWEEN PRI.STA_YMD AND PRI.END_YMD' +
											--' WHERE YMD.PAY_YMD_ID = ' + CONVERT(nvarchar(100), @an_pay_ymd_id) +
											' WHERE YMD.COMPANY_CD = ''' + @av_company_cd + '''' +
											'   AND YMD.CLOSE_YN = ''Y''' +
											'   AND YMD.PAY_YM = ''' + @av_pay_ym + '''' +
											'   AND YMD.PAY_YMD = ''' + dbo.XF_TO_CHAR_D(@ad_proc_date,'YYYYMMDD') + '''' +
											'   AND YMD.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE' +
											'                            WHERE COMPANY_CD=YMD.COMPANY_CD' +
											'                              AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD' +
											'                              AND SYS_CD = ''' + @av_pay_type_sys_cd + ''')' +
											'   AND PRI.FROM_TYPE_CD = ''' + @av_hrtype_gbn + '''' + --����
											 CHAR(13) +
											        @V_INCITEM_STR +
											 CHAR(13) + @V_INCCOSTDPT_STR +
											 CHAR(13) + @V_INCJIKGUB_STR +
											 CHAR(13) + @V_SABUN_STR +
											 CHAR(13) + @V_BANK_STR + 
											 CHAR(13) + @V_EXCITEM_STR +
											 CHAR(13) + @V_EXCOSTDPT_STR +
											 CHAR(13) + @V_EXJIKGUB_STR +
											 CHAR(13) + @V_EXSABUN_STR +
											 CHAR(13) + @V_EXBANK_STR + 
											 CHAR(13)
					END
             --���豸���� ����� ���                                                                                             
				ELSE IF @V_AGGR_GBN = 'A3'
					BEGIN 
						--PRINT('�ӿ�����')
						SET @V_RESULT_STR = ' SELECT EMP.EMP_NO AS SABUN' +
						                    ' , ROLL.ACC_CD AS COSTDPT_CD' +
											' , DTL.CAL_MON AS TOT' +
											' , DTL.CAL_MON AS AMT' +
											' FROM PAY_PAY_YMD YMD' +
											' INNER JOIN PAY_PAYROLL ROLL' +
											'         ON YMD.PAY_YMD_ID = ROLL.PAY_YMD_ID' +
											' INNER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) AS CAL_MON' +
											'               FROM PAY_PAYROLL_DETAIL DTL' +
											'              WHERE 1=1 ' + @V_ALOW_STR +
											'              GROUP BY PAY_PAYROLL_ID) DTL' +
											'         ON ROLL.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID ' +
											' INNER JOIN VI_FRM_PHM_EMP EMP' +
											'         ON ROLL.EMP_ID = EMP.EMP_ID' +
											'        AND YMD.COMPANY_CD = EMP.COMPANY_CD AND EMP.LOCALE_CD=''KO''' +
											' INNER JOIN PHM_PRIVATE PRI' +
											'         ON ROLL.EMP_ID = PRI.EMP_ID' +
											'        AND CASE WHEN EMP.IN_OFFI_YN != ''Y'' THEN RETIRE_YMD WHEN YMD.PAY_YMD < EMP.HIRE_YMD THEN EMP.HIRE_YMD ELSE YMD.PAY_YMD END BETWEEN PRI.STA_YMD AND PRI.END_YMD' +
											--' WHERE YMD.PAY_YMD_ID = ' + CONVERT(nvarchar(100), @an_pay_ymd_id) +
											' WHERE YMD.COMPANY_CD = ''' + @av_company_cd + '''' +
											'   AND YMD.CLOSE_YN = ''Y''' +
											'   AND YMD.PAY_YM = ''' + @av_pay_ym + '''' +
											'   AND YMD.PAY_YMD = ''' + dbo.XF_TO_CHAR_D(@ad_proc_date,'YYYYMMDD') + '''' +
											'   AND YMD.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE' +
											'                            WHERE COMPANY_CD=YMD.COMPANY_CD' +
											'                              AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD' +
											'                              AND SYS_CD = ''' + @av_pay_type_sys_cd + ''')' +
											'   AND PRI.FROM_TYPE_CD = ''' + @av_hrtype_gbn + '''' + --����
											 CHAR(13) +
											        @V_INCITEM_STR +
											 CHAR(13) + @V_INCCOSTDPT_STR +
											 CHAR(13) + @V_INCJIKGUB_STR +
											 CHAR(13) + @V_SABUN_STR +
											 CHAR(13) + @V_BANK_STR + 
											 CHAR(13) + @V_EXCITEM_STR +
											 CHAR(13) + @V_EXCOSTDPT_STR +
											 CHAR(13) + @V_EXJIKGUB_STR +
											 CHAR(13) + @V_EXSABUN_STR +
											 CHAR(13) + @V_EXBANK_STR + 
											 CHAR(13) 
						--PRINT('���� : ' + @V_RESULT_STR);
						--PRINT('@V_INCITEM_STR : ' + @V_INCITEM_STR);
						--PRINT('@V_INCCOSTDPT_STR : ' + @V_INCCOSTDPT_STR);
						--PRINT('@V_INCJIKGUB_STR : ' + @V_INCJIKGUB_STR);
						--PRINT('@V_SABUN_STR : ' + @V_SABUN_STR);
						--PRINT('@V_BANK_STR : ' + @V_BANK_STR);
						--PRINT('@V_EXCITEM_STR : ' + @V_EXCITEM_STR);
						--PRINT('@V_EXCOSTDPT_STR : ' + @V_EXCOSTDPT_STR);
						--PRINT('@V_EXJIKGUB_STR : ' + @V_EXJIKGUB_STR);
						--PRINT('@V_EXSABUN_STR : ' + @V_EXSABUN_STR);
						--PRINT('@V_EXBANK_STR : ' + @V_EXBANK_STR);
						--PRINT('�ӿ�������');
					END 
--���豸���� ������ ���
				ELSE IF @V_AGGR_GBN = 'A4'
					BEGIN 
						SET @V_RESULT_STR = ' SELECT EMP.EMP_NO AS SABUN' +
						                    ' , '''' AS COSTDPT_CD' +
											' , SUM(DTL.CAL_MON) AS TOT' +
											' , SUM(DTL.CAL_MON) AS AMT' +
											' FROM PAY_PAY_YMD YMD' +
											' INNER JOIN PAY_PAYROLL ROLL' +
											'         ON YMD.PAY_YMD_ID = ROLL.PAY_YMD_ID' +
											' INNER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) AS CAL_MON' +
											'               FROM PAY_PAYROLL_DETAIL DTL' +
											'              WHERE 1=1 ' + @V_ALOW_STR +
											'              GROUP BY PAY_PAYROLL_ID) DTL' +
											'         ON ROLL.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID ' +
											' INNER JOIN VI_FRM_PHM_EMP EMP' +
											'         ON ROLL.EMP_ID = EMP.EMP_ID' +
											'        AND YMD.COMPANY_CD = EMP.COMPANY_CD AND EMP.LOCALE_CD=''KO''' +
											' INNER JOIN PHM_PRIVATE PRI' +
											'         ON ROLL.EMP_ID = PRI.EMP_ID' +
											'        AND CASE WHEN EMP.IN_OFFI_YN != ''Y'' THEN RETIRE_YMD WHEN YMD.PAY_YMD < EMP.HIRE_YMD THEN EMP.HIRE_YMD ELSE YMD.PAY_YMD END BETWEEN PRI.STA_YMD AND PRI.END_YMD' +
											--' WHERE YMD.PAY_YMD_ID = ' + CONVERT(nvarchar(100), @an_pay_ymd_id) +
											' WHERE YMD.COMPANY_CD = ''' + @av_company_cd + '''' +
											'   AND YMD.CLOSE_YN = ''Y''' +
											'   AND YMD.PAY_YM = ''' + @av_pay_ym + '''' +
											'   AND YMD.PAY_YMD = ''' + dbo.XF_TO_CHAR_D(@ad_proc_date,'YYYYMMDD') + '''' +
											'   AND YMD.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE' +
											'                            WHERE COMPANY_CD=YMD.COMPANY_CD' +
											'                              AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD' +
											'                              AND SYS_CD = ''' + @av_pay_type_sys_cd + ''')' +
											'   AND PRI.FROM_TYPE_CD = ''' + @av_hrtype_gbn + '''' + --����
											 CHAR(13) +
											        @V_INCITEM_STR +
											 CHAR(13) + @V_INCCOSTDPT_STR +
											 CHAR(13) + @V_INCJIKGUB_STR +
											 CHAR(13) + @V_SABUN_STR +
											 CHAR(13) + @V_BANK_STR + 
											 CHAR(13) + @V_EXCITEM_STR +
											 CHAR(13) + @V_EXCOSTDPT_STR +
											 CHAR(13) + @V_EXJIKGUB_STR +
											 CHAR(13) + @V_EXSABUN_STR +
											 CHAR(13) + @V_EXBANK_STR + 
											 CHAR(13) +
											 ' GROUP BY EMP.EMP_NO'
					END
			END
IF @v_is_print='TEST' PRINT('@V_ITEM_CD:' + @V_ITEM_CD + '@V_AGGR_GBN:' + @V_AGGR_GBN)
--������ ��� 
IF @V_ITEM_CD = 'H'
			BEGIN 
--���豸���� �����μ��� ��� 
				IF @V_AGGR_GBN = 'A1'
					BEGIN
						SET @V_RESULT_STR = ' SELECT '''' AS SABUN' +
						                    ' , ROLL.ACC_CD AS COSTDPT_CD' +
											' , SUM(DTL.CAL_MON) AS TOT' +
											' , SUM(ROLL.PSUM2 - ROLL.DSUM - ROLL.TSUM) AS AMT' +
											' FROM PAY_PAY_YMD YMD' +
											' INNER JOIN PAY_PAYROLL ROLL' +
											'         ON YMD.PAY_YMD_ID = ROLL.PAY_YMD_ID' +
											' INNER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) AS CAL_MON' +
											'               FROM PAY_PAYROLL_DETAIL DTL' +
											'              WHERE 1=1 ' + @V_DEDT_STR +
											'              GROUP BY PAY_PAYROLL_ID) DTL' +
											'         ON ROLL.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID ' +
											' INNER JOIN VI_FRM_PHM_EMP EMP' +
											'         ON ROLL.EMP_ID = EMP.EMP_ID' +
											'        AND YMD.COMPANY_CD = EMP.COMPANY_CD AND EMP.LOCALE_CD=''KO''' +
											' INNER JOIN PHM_PRIVATE PRI' +
											'         ON ROLL.EMP_ID = PRI.EMP_ID' +
											'        AND CASE WHEN EMP.IN_OFFI_YN != ''Y'' THEN RETIRE_YMD WHEN YMD.PAY_YMD < EMP.HIRE_YMD THEN EMP.HIRE_YMD ELSE YMD.PAY_YMD END BETWEEN PRI.STA_YMD AND PRI.END_YMD' +
											--' WHERE YMD.PAY_YMD_ID = ' + CONVERT(nvarchar(100), @an_pay_ymd_id) +
											' WHERE YMD.COMPANY_CD = ''' + @av_company_cd + '''' +
											'   AND YMD.CLOSE_YN = ''Y''' +
											'   AND YMD.PAY_YM = ''' + @av_pay_ym + '''' +
											'   AND YMD.PAY_YMD = ''' + dbo.XF_TO_CHAR_D(@ad_proc_date,'YYYYMMDD') + '''' +
											'   AND YMD.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE' +
											'                            WHERE COMPANY_CD=YMD.COMPANY_CD' +
											'                              AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD' +
											'                              AND SYS_CD = ''' + @av_pay_type_sys_cd + ''')' +
											'   AND PRI.FROM_TYPE_CD = ''' + @av_hrtype_gbn + '''' + --����
											 CHAR(13) +
											        @V_INCITEM_STR +
											 CHAR(13) + @V_INCCOSTDPT_STR +
											 CHAR(13) + @V_INCJIKGUB_STR +
											 CHAR(13) + @V_SABUN_STR +
											 CHAR(13) + @V_BANK_STR + 
											 CHAR(13) + @V_EXCITEM_STR +
											 CHAR(13) + @V_EXCOSTDPT_STR +
											 CHAR(13) + @V_EXJIKGUB_STR +
											 CHAR(13) + @V_EXSABUN_STR +
											 CHAR(13) + @V_EXBANK_STR + 
											 CHAR(13) +
											' GROUP BY ROLL.ACC_CD'
					END
				--���豸���� ������ ���
				ELSE IF @V_AGGR_GBN = 'A2'
					BEGIN
						SET @V_RESULT_STR = ' SELECT '''' AS SABUN' +
						                    ' , '''' AS COSTDPT_CD' +
											' , SUM(DTL.CAL_MON) AS TOT' +
											' , SUM(ROLL.PSUM2 - ROLL.DSUM - ROLL.TSUM) AS AMT' +
											' FROM PAY_PAY_YMD YMD' +
											' INNER JOIN PAY_PAYROLL ROLL' +
											'         ON YMD.PAY_YMD_ID = ROLL.PAY_YMD_ID' +
											' INNER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) AS CAL_MON' +
											'               FROM PAY_PAYROLL_DETAIL DTL' +
											'              WHERE 1=1 ' + @V_DEDT_STR +
											'              GROUP BY PAY_PAYROLL_ID) DTL' +
											'         ON ROLL.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID ' +
											' INNER JOIN VI_FRM_PHM_EMP EMP' +
											'         ON ROLL.EMP_ID = EMP.EMP_ID' +
											'        AND YMD.COMPANY_CD = EMP.COMPANY_CD AND EMP.LOCALE_CD=''KO''' +
											' INNER JOIN PHM_PRIVATE PRI' +
											'         ON ROLL.EMP_ID = PRI.EMP_ID' +
											'        AND CASE WHEN EMP.IN_OFFI_YN != ''Y'' THEN RETIRE_YMD WHEN YMD.PAY_YMD < EMP.HIRE_YMD THEN EMP.HIRE_YMD ELSE YMD.PAY_YMD END BETWEEN PRI.STA_YMD AND PRI.END_YMD' +
											--' WHERE YMD.PAY_YMD_ID = ' + CONVERT(nvarchar(100), @an_pay_ymd_id) +
											' WHERE YMD.COMPANY_CD = ''' + @av_company_cd + '''' +
											'   AND YMD.CLOSE_YN = ''Y''' +
											'   AND YMD.PAY_YM = ''' + @av_pay_ym + '''' +
											'   AND YMD.PAY_YMD = ''' + dbo.XF_TO_CHAR_D(@ad_proc_date,'YYYYMMDD') + '''' +
											'   AND YMD.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE' +
											'                            WHERE COMPANY_CD=YMD.COMPANY_CD' +
											'                              AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD' +
											'                              AND SYS_CD = ''' + @av_pay_type_sys_cd + ''')' +
											'   AND PRI.FROM_TYPE_CD = ''' + @av_hrtype_gbn + '''' + --����
											 CHAR(13) +
											        @V_INCITEM_STR +
											 CHAR(13) + @V_INCCOSTDPT_STR +
											 CHAR(13) + @V_INCJIKGUB_STR +
											 CHAR(13) + @V_SABUN_STR +
											 CHAR(13) + @V_BANK_STR + 
											 CHAR(13) + @V_EXCITEM_STR +
											 CHAR(13) + @V_EXCOSTDPT_STR +
											 CHAR(13) + @V_EXJIKGUB_STR +
											 CHAR(13) + @V_EXSABUN_STR +
											 CHAR(13) + @V_EXBANK_STR + 
											 CHAR(13) 
						--PRINT(@V_RESULT_STR)
					END
				--���豸���� ����� ���
				ELSE IF @V_AGGR_GBN = 'A3'
					BEGIN 
						SET @V_RESULT_STR = ' SELECT EMP.EMP_NO AS SABUN' +
						                    ' , ROLL.ACC_CD AS COSTDPT_CD' +
											' , DTL.CAL_MON AS TOT' +
											' , ROLL.PSUM2 - ROLL.DSUM - ROLL.TSUM AS AMT' +
											' FROM PAY_PAY_YMD YMD' +
											' INNER JOIN PAY_PAYROLL ROLL' +
											'         ON YMD.PAY_YMD_ID = ROLL.PAY_YMD_ID' +
											' INNER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) AS CAL_MON' +
											'               FROM PAY_PAYROLL_DETAIL DTL' +
											'              WHERE 1=1 ' + @V_DEDT_STR +
											'              GROUP BY PAY_PAYROLL_ID) DTL' +
											'         ON ROLL.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID ' +
											' INNER JOIN VI_FRM_PHM_EMP EMP' +
											'         ON ROLL.EMP_ID = EMP.EMP_ID' +
											'        AND YMD.COMPANY_CD = EMP.COMPANY_CD AND EMP.LOCALE_CD=''KO''' +
											' INNER JOIN PHM_PRIVATE PRI' +
											'         ON ROLL.EMP_ID = PRI.EMP_ID' +
											'        AND CASE WHEN EMP.IN_OFFI_YN != ''Y'' THEN RETIRE_YMD WHEN YMD.PAY_YMD < EMP.HIRE_YMD THEN EMP.HIRE_YMD ELSE YMD.PAY_YMD END BETWEEN PRI.STA_YMD AND PRI.END_YMD' +
											--' WHERE YMD.PAY_YMD_ID = ' + CONVERT(nvarchar(100), @an_pay_ymd_id) +
											' WHERE YMD.COMPANY_CD = ''' + @av_company_cd + '''' +
											'   AND YMD.CLOSE_YN = ''Y''' +
											'   AND YMD.PAY_YM = ''' + @av_pay_ym + '''' +
											'   AND YMD.PAY_YMD = ''' + dbo.XF_TO_CHAR_D(@ad_proc_date,'YYYYMMDD') + '''' +
											'   AND YMD.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE' +
											'                            WHERE COMPANY_CD=YMD.COMPANY_CD' +
											'                              AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD' +
											'                              AND SYS_CD = ''' + @av_pay_type_sys_cd + ''')' +
											'   AND PRI.FROM_TYPE_CD = ''' + @av_hrtype_gbn + '''' + --����
											 CHAR(13) +
											        @V_INCITEM_STR +
											 CHAR(13) + @V_INCCOSTDPT_STR +
											 CHAR(13) + @V_INCJIKGUB_STR +
											 CHAR(13) + @V_SABUN_STR +
											 CHAR(13) + @V_BANK_STR + 
											 CHAR(13) + @V_EXCITEM_STR +
											 CHAR(13) + @V_EXCOSTDPT_STR +
											 CHAR(13) + @V_EXJIKGUB_STR +
											 CHAR(13) + @V_EXSABUN_STR +
											 CHAR(13) + @V_EXBANK_STR + 
											 CHAR(13)
					END
--���豸���� ������ ���
				ELSE IF @V_AGGR_GBN = 'A4'
					BEGIN 
						SET @V_RESULT_STR = ' SELECT EMP.EMP_NO AS SABUN' +
						                    ' , ''' + @V_CSTDPAT_CD + ''' AS COSTDPT_CD' +
											' , ISNULL(SUM(DTL.CAL_MON),0) AS TOT' +
											' , SUM(ROLL.PSUM2 - ROLL.DSUM - ROLL.TSUM) AS AMT' +
											' FROM PAY_PAY_YMD YMD' +
											' INNER JOIN PAY_PAYROLL ROLL' +
											'         ON YMD.PAY_YMD_ID = ROLL.PAY_YMD_ID' +
											' LEFT OUTER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) AS CAL_MON' +
											'               FROM PAY_PAYROLL_DETAIL' +
											'              WHERE 1=1 ' + @V_DEDT_STR +
											'              GROUP BY PAY_PAYROLL_ID) DTL' +
											'         ON ROLL.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID ' +
											' INNER JOIN VI_FRM_PHM_EMP EMP' +
											'         ON ROLL.EMP_ID = EMP.EMP_ID' +
											'        AND YMD.COMPANY_CD = EMP.COMPANY_CD AND EMP.LOCALE_CD=''KO''' +
											' INNER JOIN PHM_PRIVATE PRI' +
											'         ON ROLL.EMP_ID = PRI.EMP_ID' +
											'        AND CASE WHEN EMP.IN_OFFI_YN != ''Y'' THEN RETIRE_YMD WHEN YMD.PAY_YMD < EMP.HIRE_YMD THEN EMP.HIRE_YMD ELSE YMD.PAY_YMD END BETWEEN PRI.STA_YMD AND PRI.END_YMD' +
											--' WHERE YMD.PAY_YMD_ID = ' + CONVERT(nvarchar(100), @an_pay_ymd_id) +
											' WHERE YMD.COMPANY_CD = ''' + @av_company_cd + '''' +
											'   AND YMD.CLOSE_YN = ''Y''' +
											'   AND YMD.PAY_YM = ''' + @av_pay_ym + '''' +
											'   AND YMD.PAY_YMD = ''' + dbo.XF_TO_CHAR_D(@ad_proc_date,'YYYYMMDD') + '''' +
											'   AND YMD.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE' +
											'                            WHERE COMPANY_CD=YMD.COMPANY_CD' +
											'                              AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD' +
											'                              AND SYS_CD = ''' + @av_pay_type_sys_cd + ''')' +
											'   AND PRI.FROM_TYPE_CD = ''' + @av_hrtype_gbn + '''' + --����
											 CHAR(13) +
											        @V_INCITEM_STR +
											 CHAR(13) + @V_INCCOSTDPT_STR +
											 CHAR(13) + @V_INCJIKGUB_STR +
											 CHAR(13) + @V_SABUN_STR +
											 CHAR(13) + @V_BANK_STR + 
											 CHAR(13) + @V_EXCITEM_STR +
											 CHAR(13) + @V_EXCOSTDPT_STR +
											 CHAR(13) + @V_EXJIKGUB_STR +
											 CHAR(13) + @V_EXSABUN_STR +
											 CHAR(13) + @V_EXBANK_STR + 
											 CHAR(13) 
											 + ' GROUP BY EMP.EMP_NO'
					END
			END
			                                          
		 --PRINT('@V_WRTDPT_CD : ' + @V_WRTDPT_CD)
		 --PRINT('@V_BILL_GBN : ' + @V_BILL_GBN)
		 --PRINT('@V_TRDTYP_CD : ' + @V_TRDTYP_CD)
		 --PRINT('@V_ACCNT_CD : ' + @V_ACCNT_CD)                                                                                                           
		 -- IF @v_is_test='TEST'      PRINT('@V_RESULT_STR : ' + @V_RESULT_STR);
         -- ����(1), �뺯(2) ����
		--IF @v_is_print='TEST' PRINT('@V_DEBSER_GBN1:' + @V_DEBSER_GBN)
   --      IF @V_DEBSER_GBN = '2'
			--BEGIN
			--	SET @V_DEBSER_GBN = '50'; -- �뺯(CREDIT)
			--END
   --      ELSE
			--BEGIN
   --       		SET @V_DEBSER_GBN = '40'; -- ����(DEBIT)
   --       	END
		--IF @v_is_print='TEST' PRINT('@V_DEBSER_GBN2:' + @V_DEBSER_GBN)
         
         --��ǥ����
         
         IF ISNULL(@V_RESULT_STR, '') = ''
			Goto NEXT_C_PBT_ACCNT_STD
         
         SET @V_RESULT_STR = 'set @cursor = cursor forward_only static for ' + @V_RESULT_STR + ' open @cursor;'

         IF @v_is_print='TEST' PRINT('@V_RESULT_STR:' + @V_RESULT_STR);
		 
		 EXEC SP_EXECUTESQL @V_RESULT_STR, N'@cursor cursor output', @objcursor output
			FETCH NEXT FROM @objcursor INTO @V_SABUN, @V_COSTDPTCD, @V_TOT, @V_PAY_TOT
		 IF @v_is_print='TEST' PRINT('�����͸� �����ɴϴ�.')
		 WHILE @@FETCH_STATUS = 0
		 BEGIN
			 IF @v_is_print='TEST' PRINT('�������� ���� ����!!')
			 IF @v_is_print='TEST' PRINT('@V_TRDTYP_CD : ' + @V_TRDTYP_CD)
			 IF @v_is_print='TEST' PRINT('@V_SABUN : ' + @V_SABUN)
			 IF @v_is_print='TEST' PRINT('@V_COSTDPTCD : ' + @V_COSTDPTCD)
			 IF @v_is_print='TEST' PRINT('@V_TOT : ' + CAST(ISNULL(@V_TOT, 0) AS VARCHAR))
			 IF @v_is_print='TEST' PRINT('@V_PAY_TOT : ' + CAST(ISNULL(@V_PAY_TOT, 0) AS VARCHAR))
			 SET @V_SEQ = @V_SEQ + 1;
			 SET @V_MM = '';
			 SET @V_COSTDPT_CD = '';
			   
	         --�������޾��� ���(����:Z01)
             IF @V_PAY_YN = 'Y'
				BEGIN
					SET @V_TOT = @V_PAY_TOT; 
				END
             --���������ڵ�
             SET @V_ORG_COSTCD = @V_COSTDPTCD; 
             
              -- �����μ� ����(v_costdpt_cd,v_costdpt_TM:�����ǿ���, v_costdptcd:����Ÿ�ǿ���)
             IF @V_AGGR_GBN = 'A1'
				BEGIN
					IF @V_COSTDPT_TM IS NULL OR @V_COSTDPT_TM = ''
						BEGIN
							SET @V_COSTDPT_CD = @V_COSTDPTCD;
						END
					ELSE
						BEGIN
						    --����������� ���ؿ� �����μ��� �ִ� ��� ���������μ�ó���ÿ��⿡ ���� --
						    SET @V_TRDTYP_NM_E = SUBSTRING(@V_COSTDPTCD,1,4) +'_'+ SUBSTRING(@V_TRDTYP_NM,1,40);                             --*/
						    SET @V_COSTDPT_CD  = @V_COSTDPT_TM;
						END
				END
				
			--IF @V_AGGR_GBN = 'A2' or @V_AGGR_GBN = 'A4'
			--	BEGIN
			--		SET @V_COSTDPT_CD = @V_COSTDPTCD;
			--	END
				
             SET @V_MM = SUBSTRING(@av_pay_ym,5,2);
             
             --������ ���
             IF @av_company_cd IN ('X', 'Y', 'B')
				BEGIN  
                 -- ����(�տ� �Ŵ� ��ǥ�����Ǵ� ���� ǥ��)
					SET @V_SUMMARY_CNT = @V_SUMMARY_CNT +1;
					IF @V_SUMMARY_CNT = 1
						BEGIN
							SET @V_SUMMARY = @V_MM + @V_SUMMARY;
							SET @V_SUMMARY_TM = @V_SUMMARY;
						END
					-- ����� ���
					IF @V_AGGR_GBN = 'A3'
						BEGIN  
							SET @V_PAYMTWAY  = '20'    -- ���Ҽ���:�����ü
							--����ŷ�ó ã��
							SET @V_CUST_CD = '';

							SET @OPENQUERY = 'SELECT @V_CUST_CD = C.CD_DETAIL FROM OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_ZZ510 where ACCOUNT_CLNT_KND_CD = ''''EM'''' AND CLNT_DEL_YN = 0 AND EMP_NO = ''''' + @V_SABUN + ''''''' )B '
							SET @OPENQUERY = @OPENQUERY + 'LEFT OUTER JOIN FRM_CODE C ON C.COMPANY_CD ='+ @V_SABUN + ' AND C.CD_KIND = ''PBT_CUST_CD'' AND C.MAIN_CD = B.CLNT_NO'
							-- TEST
							IF @v_is_link_test = 'TEST' SET @OPENQUERY = 'SELECT @V_CUST_CD = ''ASDF'''
							IF @v_is_print = 'TEST' PRINT('DB��ũ ����1 : ' + @OPENQUERY)
					
							EXEC sp_executesql @OPENQUERY, N'@V_CUST_CD nvarchar(40) OUTPUT', @V_CUST_CD output
							
                    
						--  V_CUST_CD := V_COSTDPTCD + '_' + V_SABUN;
						-- ���豸���� ����� ��쿡�� �����μ��� ����� �����μ��� �������ش�
						--    V_COSTDPT_CD := V_COSTDPTCD;
							 IF @V_COSTDPT_TM IS NULL OR @V_COSTDPT_TM = ''
								BEGIN
									SET @V_COSTDPT_CD = @V_COSTDPTCD;
								END
							 ELSE
								BEGIN
									SET @V_COSTDPT_CD = @V_COSTDPT_TM;
								END	
                     
							 IF @V_TRDTYP_CD  IN ('101','600','605')  --�ӿ��� ��� ó�� - �ŷ�����:101,600,605
								BEGIN
									SET @V_CUST_CD = '';
									SET @V_PAYMTWAY  = ''; 
								END
						END 
                 -- ������ ���
					ELSE IF @V_AGGR_GBN = 'A4'  
						BEGIN
							SET @V_PAYMTWAY = '70';    --���Ҽ���:�޿���ü
							SET @V_BANK_CD = @V_COSTDPTCD;
							SET @V_BANK_NM = '';
							
							-- ������� �����´�.
							-- WHITE - �ǹ̸� �𸣰ڴ�.PI
							--IF  @P_PAY_CD  = '05'
							IF @av_pay_type_sys_cd IN ('005','006') -- PI
								BEGIN
									SET @V_BANK_CD = '';
									SET @V_BANK_NM = ''; -- �ӽ��ּ� dbo.fn_GetCodesNm(); --GETCODENAME(@P_COMPANY, @V_BANK_CD); 
									SET @V_SUMMARY = @V_BANK_NM +'_'+ @V_SUMMARY_TM; 
								END
						 END
							--�ǰ�����, �����̰� ������ �����޺��(2100810)�� ��� 
					IF (@V_BILL_GBN = 'P5103' OR @V_BILL_GBN = 'P5104' OR @V_BILL_GBN = 'P5107' OR @V_BILL_GBN = 'P5108') AND @V_ACCNT_CD = '2100810'
						BEGIN
							SET @V_PAYMTWAY = '60';   -- ���Ҽ���:���¹���
						END
					
					--IF (@V_BILL_GBN = 'P5101' OR @V_BILL_GBN = 'P5105') AND @V_ACCNT_CD = '2100810' AND @V_AGGR_GBN <> 'A4'
					--	BEGIN
					--		SET @V_PAYMTWAY = '20';   -- ���Ҽ���:���¹���
					--	END
				 END
				 
                   
          
           /* �����μ��� ��뱸�� COST_CLS_CD (01:���� , 02:�ǰ���, 03: ����+�ǰ���) Ȯ�� */
           SET @V_COST_CLS_CD = '';
           --SELECT @V_BIZ_ACCT = BIZ_ACCT FROM B_COST_CENTER WHERE CD_COMPANY = @P_COMPANY AND CD_CC = @V_COSTDPT_CD
		   SELECT @V_BIZ_ACCT = COST_TYPE
		     FROM ORM_COST
		    WHERE COMPANY_CD = @av_company_cd
			  AND COST_CD = @V_COSTDPT_CD
			  AND @ad_proc_date BETWEEN STA_YMD AND END_YMD
		   

		   IF @v_is_print= 'TEST' PRINT('@V_BIZ_ACCT : ' + @V_BIZ_ACCT)
		   SET @OPENQUERY = 'SELECT @V_COST_CLS_CD = COST_CLS_CD FROM OPENQUERY('+ @LinkedServer + ','''
		   SET @OPENQUERY = @OPENQUERY + 'SELECT COST_CLS_CD FROM TB_CO011 where ACCT_DEPT_CD = ''''' + @V_BIZ_ACCT + ''''' AND ACCT_YEAR = ''''' + dbo.XF_TO_CHAR_D(@ad_proc_date,'yyyy') + ''''''' )'
		   IF @v_is_link_test='TEST' SET @OPENQUERY = 'SELECT @V_COST_CLS_CD=''ASDF'''
		   IF @v_is_print='TEST' PRINT('OPENQUERY:' + @OPENQUERY)
		   EXEC sp_executesql @OPENQUERY, N'@V_COST_CLS_CD nvarchar(5) OUTPUT', @V_COST_CLS_CD output
           
           
           /* ��������: ACCT_CLS_CD (5;�ǰ���,6:����) Ȯ���Ͽ� �����ڵ�üũ */
           SET @V_ACCT_CLS_CD = '';
           SET @OPENQUERY = 'SELECT @V_ACCT_CLS_CD = ACCT_CLS_CD FROM OPENQUERY('+ @LinkedServer + ','''
           SET @OPENQUERY = @OPENQUERY + 'SELECT ACCT_CLS_CD FROM TB_FI001 where ACCT_CD = ''''' + @V_ACCNT_CD + ''''''')' 
		   IF @v_is_link_test='TEST' SET @OPENQUERY = 'SELECT @V_ACCT_CLS_CD=''1234'''
		   IF @v_is_print='TEST' PRINT('OPENQUERY:' + @OPENQUERY)
           EXEC sp_executesql @OPENQUERY, N'@V_ACCT_CLS_CD nvarchar(5) OUTPUT', @V_ACCT_CLS_CD output

         --print('CHECK �����ڵ�1 >>> ' + @V_ACCNT_CD );
         --print('CHECK ��������(���񽺵�����) >>> ' + @V_ACCT_CLS_CD );
         --print('CHECK ��������(���񽺵�����) >>> ' + @V_COST_CLS_CD );
         --print('CHECK �ǰ�������ڵ� >>> ' + @V_MGNT_ACCTCD );
         --print('CHECK ���������ڵ� >>> ' + @V_COST_ACCTCD );

           /* �ͼӺμ��� ��뱸�а� �߻��� ������ ���������� �� �Ѵ� - ��ǥ���ؿ��� ���������̹Ƿ� �ǰ��� �μ��� ��� �����ڵ�(�ǰ���������� ���� �Ѵ�) */
             IF @V_ACCT_CLS_CD IN ('5','6') --��������(5;�ǰ���,6:����)
				BEGIN	
					IF @V_COST_CLS_CD = '03' --����+�ǰ��� �μ��� ��� 
						BEGIN
						PRINT('NULL')
					 END
					ELSE   
						IF @V_COST_CLS_CD = '02' --�ǰ��� �μ��� ��� 
							BEGIN
								SET @V_ACCNT_CD = @V_MGNT_ACCTCD;
								SET @V_SUMMARY  = REPLACE(@V_SUMMARY,'����','�ǰ���');
							END
						ELSE
							BEGIN
								SET @V_ACCNT_CD = @V_COST_ACCTCD;
								SET @V_SUMMARY  = REPLACE(@V_SUMMARY,'�ǰ���','����');
							END              
				END
           
             --PRINT('CHECK �����ڵ�2 >>> ' + @V_ACCNT_CD );

             --IF @P_PAY_CD  = '02' -- ��
			 IF @av_pay_type_sys_cd IN ('003','004') -- ��, ������
				BEGIN
				   --7���󿩴� �ϰ��ް���
					IF SUBSTRING(@av_pay_ym,5,2) = '07'
						BEGIN 
							IF @V_ACCNT_CD = '4200220'
								BEGIN  
									SET @V_ACCNT_CD = '4200615';
									SET @V_SUMMARY  = REPLACE(@V_SUMMARY,'��','�ϰ��ް���');
								END
						END
				   -- 11���󿩴� ���庸����
					IF SUBSTRING(@av_pay_ym,5,2) = '11' 
						BEGIN
							IF @V_ACCNT_CD = '4200220'  
								BEGIN
									SET @V_ACCNT_CD = '4200616';
									SET @V_SUMMARY  = REPLACE(@V_SUMMARY,'��','���庸����');
								END
						END
				END
			 --PRINT(@V_TOT);
		  --   PRINT('CHECK �����ڵ�3 >>> ' + @V_ACCNT_CD );

    --         PRINT('@V_TOT >>> ' + CAST(@V_TOT AS VARCHAR) );
             IF @V_TOT <> 0    
             BEGIN
				SELECT @n_cnt = COUNT(*) -- *
				  FROM PBT_BILL_CREATE
				 WHERE COMPANY_CD = @av_company_cd
				   AND HRTYPE_GBN = @av_hrtype_gbn
				   AND PAY_YM = @av_pay_ym
				   AND PAY_CD = @av_pay_type_sys_cd
				   --AND PAY_YMD_ID = @an_pay_ymd_id
				   AND WRTDPT_CD = @V_WRTDPT_CD
				   AND TRDTYP_CD = @V_TRDTYP_CD
				   AND BILL_GBN = @V_BILL_GBN
				   AND ACCNT_CD = @V_ACCNT_CD
				   AND SEQ = @V_SEQ
				
				
				IF @n_cnt > 0
					BEGIN
					PRINT('================������Ʈ���� ����=====================')
					   UPDATE PBT_BILL_CREATE
						  SET AMT = @V_TOT
   							 ,TRDTYP_NM  = @V_TRDTYP_NM_E
   							 ,CUST_CD    = @V_CUST_CD
   							 ,COSTDPT_CD = @V_COSTDPT_CD
   							 ,DEBSER_GBN = @V_DEBSER_GBN
   							 ,SUMMARY    = @V_SUMMARY
   							 ,BANK_CD    = @V_BANK_CD
   							 ,PAYMTWAY   = @V_PAYMTWAY
							 ,PROC_DT    = dbo.XF_TO_CHAR_D(@ad_proc_date,'yyyymmdd') --@P_PROC_DATE
							 ,UPDATE_DT  = GETDATE()
							 ,UPDATE_SABUN = @av_emp_no
							 ,ORG_COST_CD = @V_ORG_COSTCD
   						WHERE COMPANY_CD = @av_company_cd
   						  AND HRTYPE_GBN = @av_hrtype_gbn
   						  AND PAY_YM  = @av_pay_ym
   						  AND PAY_CD = @av_pay_type_sys_cd
						  --AND PAY_YMD_ID = @an_pay_ymd_id
   						  AND WRTDPT_CD = @V_WRTDPT_CD
   						  AND TRDTYP_CD = @V_TRDTYP_CD
   						  AND BILL_GBN = @V_BILL_GBN
   						  AND ACCNT_CD = @V_ACCNT_CD
   						  AND SEQ = @V_SEQ
					END
				ELSE
					BEGIN
						PRINT('================�μ�Ʈ���� ����=====================')
						--PRINT('@P_COMPANY : ' + @P_COMPANY)
						--PRINT('@P_HRTYPE_GBN : ' + @P_HRTYPE_GBN)
						--PRINT('@P_YYYYMM : ' + @P_YYYYMM)
						--PRINT('@P_PAY_CD : ' + @P_PAY_CD)
						--PRINT('@V_WRTDPT_CD : ' + @V_WRTDPT_CD)
						--PRINT('@V_TRDTYP_CD : ' + @V_TRDTYP_CD)
						--PRINT('@V_BILL_GBN : ' + @V_BILL_GBN)
						--PRINT('@V_ACCNT_CD : ' + @V_ACCNT_CD)
						--PRINT('@V_SEQ : ' + CAST(@V_SEQ AS VARCHAR))
						INSERT INTO PBT_BILL_CREATE
    	   					  ( 
    	   						COMPANY_CD
    	   					   ,HRTYPE_GBN 
    	   					   ,PAY_YM
    	   					   ,PAY_CD
							   ,WRTDPT_CD              -- �ۼ��μ�
							   ,TRDTYP_CD              -- �ŷ�����
							   ,BILL_GBN               -- ��ǥ����
							   ,ACCNT_CD               -- �����ڵ�
							   ,SEQ                    -- ����
							   ,AMT                    -- �ݾ�
							   ,TRDTYP_NM              -- �ŷ���
							   ,CUST_CD                -- �ŷ�ó�ڵ�
							   ,COSTDPT_CD             -- �����μ��ڵ�
							   ,DEBSER_GBN             -- ���뱸��
							   ,SUMMARY                -- �������
							   ,BANK_CD                -- �����ڵ�
							   ,PAYMTWAY               -- ���Ҽ���
							   ,PROC_DT                -- ó������
							   ,INPUT_DT
							   ,INPUT_SABUN
							   ,ORG_COST_CD
    	   					  )
    	   					  VALUES(
    	   					   @av_company_cd
    	   					  ,@av_hrtype_gbn
    	   					  ,@av_pay_ym
    	   					  ,@av_pay_type_sys_cd
    	   					  ,@V_WRTDPT_CD
    	   					  ,@V_TRDTYP_CD
    	   					  ,@V_BILL_GBN
    	   					  ,@V_ACCNT_CD
    	   					  ,@V_SEQ
    	   					  ,@V_TOT
    	   					  ,@V_TRDTYP_NM_E
    	   					  ,@V_CUST_CD
    	   					  ,@V_COSTDPT_CD
    	   					  ,@V_DEBSER_GBN
    	   					  ,@V_SUMMARY
    	   					  ,@V_BANK_CD
    	   					  ,@V_PAYMTWAY
							  ,dbo.XF_TO_CHAR_D(@ad_proc_date, 'YYYYMMDD')
    	   					  ,GETDATE()
    	   					  ,@av_emp_no
    	   					  ,@V_ORG_COSTCD
    	   					 )
					--PRINT('�μ�Ʈ �� �హ�� : ' + CAST (@@ROWCOUNT AS VARCHAR))
					--PRINT('��� : ' + @P_HRTYPE_GBN + ' ' +@P_YYYYMM + ' ' + @P_PAY_CD + ' ' + @V_WRTDPT_CD + ' ' +@V_TRDTYP_CD + ' ' + @V_BILL_GBN )  

					END   
    	   	 END 
    	  	 			
		 FETCH NEXT FROM @objcursor INTO @V_SABUN, @V_COSTDPTCD, @V_TOT, @V_PAY_TOT
		 END 
           
         CLOSE @objcursor  --1��° Ŀ�� ����         
		 DEALLOCATE @objcursor
	 
NEXT_C_PBT_ACCNT_STD:
		FETCH NEXT FROM C_PBT_ACCNT_STD	INTO	@V_PBT_ACCNT_STD_ID,
												@V_WRTDPT_CD,
												@V_BILL_GBN,
												@V_TRDTYP_CD,
												@V_ACCNT_CD,
												@V_CUST_CD,
												@V_AGGR_GBN,
												@V_CSTDPAT_CD,
												@V_COSTDPT_TM,
												@V_TRDTYP_NM,
												@V_TRDTYP_NM_E,
												@V_SUMMARY,
												@V_DEBSER_GBN,
												@V_COST_ACCTCD,
												@V_MGNT_ACCTCD
     END 	 
     CLOSE C_PBT_ACCNT_STD;  -- ��ǥ�ڵ�� ������ ��ǥ ����
     DEALLOCATE C_PBT_ACCNT_STD;

    -- SET @p_error_code = '0';

	SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG( '�޿���ǥ�� �����߽��ϴ�..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
	RETURN	
 ----------------------------------------------------------------------------------------------------------------------- 
  ERR_HANDLER:
		begin try
			DEALLOCATE	C_PBT_ACCNT_STD;
			DEALLOCATE	C_PBT_EXCITEM;
			DEALLOCATE	C_PBT_INCITEM;
			DEALLOCATE  @objcursor;
		end try
		
		begin catch
			print 'ERR_HANDLER:';
		end catch;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;
	
    SET @av_ret_code    = 'FAILURE!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG(@v_error_message + '[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
	--EXECUTE p_ba_errlib_getusererrormsg 'X', 'p_at_pay_DEBIS_interface',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message
	RETURN
END	
END TRY  

  ----------------------------------------------------------------------------------------------------------------------- 
  -- Error CATCH Process Block 
  ----------------------------------------------------------------------------------------------------------------------- 
BEGIN CATCH

	--SET @p_error_code = @v_error_code;
	--SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line =  ERROR_LINE();
	SET @v_error_message = ERROR_MESSAGE()+ ' ' + @v_error_note;
	
	--EXECUTE p_ba_errlib_getusererrormsg 'X', 'p_at_pay_DEBIS_interface',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message
	
    SET @av_ret_code    = 'FAILURE!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG(@v_error_message + '[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
		begin try

			DEALLOCATE	C_PBT_ACCNT_STD;
			DEALLOCATE	C_PBT_EXCITEM;
			DEALLOCATE	C_PBT_INCITEM;
			DEALLOCATE  @objcursor;
		end try
		begin catch
		PRINT (@v_error_message);
		print 'Error CATCH Process Block';
		end catch;
	RETURN
END CATCH

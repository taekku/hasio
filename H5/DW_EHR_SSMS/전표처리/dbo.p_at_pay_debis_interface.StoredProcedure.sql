USE [dwehr_20191220]
GO
/****** Object:  StoredProcedure [dbo].[p_at_pay_debis_interface]    Script Date: 2020-04-27 오전 11:00:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/************************************************************************
 * SYSTEM명         : 동부그룹 신인사 시스템
 * SUB SYSTEM명     : 전표생성
 * PROCEDURE 명     : SP_BILL_INSERT
 * DESCRIPTION      : 전표를 생성한다.
 * 사용 TABLE명     : PBT_ACCNT_STD
 *                    PBT_INCITEM
 *                    PBT_EXCITEM
 *                    PBT_PAY_RESULT
 *                    PBT_ALOW_RESULT
 *                    PBT_DEDT_RESULT
 *                    PBT_BILL_CREATE
 * IN  PARAMETER    : P_COMPANY        회사구분
 *                    P_START_DATE     시작일자
 *                    P_END_DATE       종료일자  
 *                    P_GUBUN          기준
 *                                     'A' : 전체
 *                                     'H22' : 사원구분
 *                                     'P0602' : 원가부서
 *                                     'H12' : 직급
 *                                     'SAWON' : 사원 
 *                    P_CODE           기준에 따른 코드
 *                    P_SABUN
 * OUT PARAMETER    : R_RESULT
 * IN OUT PARAMETER : N/A
 * 변경자     변경일자            변경사유
 *-----------------------------------------------------------------------
 * 박성진     2006-03-21          초기생성
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


CREATE PROCEDURE [dbo].[p_at_pay_debis_interface] (
							  @P_COMPANY         VARCHAR(20),				    -- 회사구분 초기값 : E.
                              @P_HRTYPE_GBN      VARCHAR(20),					-- 인력유형
							  @P_BILL_GBN		 VARCHAR(20),						-- 전표구분
							  @P_YYYYMM		     VARCHAR(8) ,						-- 급여년월
							  @P_PAY_CD		     VARCHAR(20) ,						-- 급여코드
							  @P_PROC_DATE		 VARCHAR(20) ,						-- 처리일자
							  @P_SABUN		     VARCHAR(20) ,						-- 처리자
                              @p_error_code      VARCHAR(1000) OUTPUT,				-- 에러코드 리턴
                              @p_error_str       VARCHAR(3000) OUTPUT				-- 에러메시지 리턴
                              )                                                                              
AS
SET NOCOUNT ON


DECLARE
	@objcursor            as cursor,
 -- 사용 변수선언
    @V_WRTDPT_CD           VARCHAR(40),          -- 작성부서
    @V_BILL_GBN            VARCHAR(40),          -- 전표구분
    @V_TRDTYP_CD           VARCHAR(40),          -- 거래유형
    @V_ACCNT_CD            VARCHAR(40),          -- 계정코드
    @V_AGGR_GBN            VARCHAR(40),          -- 집계구분(원가부서/사번/총합)
    @V_CUST_CD             VARCHAR(40),          -- 거래처코드
    @V_DEBSER_GBN          VARCHAR(40),          -- 차대구분(차변/대변)
    @V_COSTDPT_CD          VARCHAR(40),          -- 원가부서
    @V_COSTDPT_TM          VARCHAR(40),          -- 원가부서
    @V_TRDTYP_NM           VARCHAR(200),         -- 거래처명
    @V_TRDTYP_NM_E         VARCHAR(200),         -- 거래처명
    @V_SUMMARY             VARCHAR(400),         -- 적요
    @V_SUMMARY_TM          VARCHAR(400),         -- 적요(TEMP)
    @V_SUMMARY_CNT         NUMERIC(5, 0),        -- 적요 수
    @V_SABUN               VARCHAR(24),          -- 사번
    
    @V_INCITEM             VARCHAR(20),          -- 포함항목
    @V_ITEM_CD             VARCHAR(20),          -- 항목코드
    @V_INCITEM_FR          VARCHAR(20),          -- 포함항목From
    @V_INCITEM_TO          VARCHAR(20),          -- 포함항목To
    
    @V_EXCITEM             VARCHAR(20),          -- 제외항목
    @V_EXITEM_CD           VARCHAR(20),          -- 제외코드
    @V_EXCITEM_FR          VARCHAR(20),          -- 제외항목From
    @V_EXCITEM_TO          VARCHAR(20),          -- 제외항목To
    
    @V_INCITEM_STR         varchar(max),                    -- 조건에 들어갈 포함항목
    @V_EXCITEM_STR         varchar(max),                    -- 조건에 들어갈 제외항목
    @V_RESULT_STR          Nvarchar(max),                   -- 조건에 따른 금액을 얻어온다.
    @V_ALOW_STR            varchar(max),                    -- 수당항목합
    @V_DEDT_STR            varchar(max),                    -- 공제항목합
    @V_INCCOSTDPT_STR      varchar(max),                    -- 조건에 들어갈 포함항목
    @V_INCJIKGUB_STR       varchar(max),                    -- 조건에 들어갈 포함항목
    @V_SABUN_STR           varchar(max),                    -- 조건(사번)
    @V_BANK_STR            varchar(max),                    -- 조건(은행)
    @V_EXCOSTDPT_STR       varchar(max),                    -- 조건에 들어갈 포함항목
    @V_EXJIKGUB_STR        varchar(max),                    -- 조건에 들어갈 포함항목
    @V_EXSABUN_STR         varchar(max),                    -- 조건(제외사번)
    @V_EXBANK_STR          varchar(max),                    -- 조건(제외은행)
    @V_ALOW_CNT            NUMERIC(4, 0),                   -- 수당 수
    @V_DEDT_CNT            NUMERIC(4, 0),                   -- 공제 수
    @V_INCCOSTDPT_CNT      NUMERIC(4, 0),                   -- 원가부서 수
    @V_INCJIKGUB_CNT       NUMERIC(4, 0),                   -- 직급 수
    @V_SABUN_CNT           NUMERIC(4, 0),                   -- 사번 수
    @V_BANK_CNT            NUMERIC(4, 0),                   -- 은행 수
    @V_EXCOSTDPT_CNT       NUMERIC(4, 0),                   -- 원가부서 수
    @V_EXJIKGUB_CNT        NUMERIC(4, 0),                   -- 직급 수
    @V_EXSABUN_CNT         NUMERIC(4, 0),                   -- 제외사번 수
    @V_EXBANK_CNT          NUMERIC(4, 0),                   -- 제외은행 수
    @V_HRTYPE_GBN          VARCHAR(20),                     -- 인력유형
    @V_SAWON_GBN           VARCHAR(20),                     -- 사원구분
    @V_PAY_YN              VARCHAR(20),                     -- 차인지급액YN
    @V_PAY_TOT             NUMERIC(12,0),                   -- 차인지급액 
    @V_COSTDPTCD           VARCHAR(20),                     -- 원가부서  
    @V_ORG_COSTCD          VARCHAR(20),                     -- 원가부서  
    
    @V_BANK_NM             VARCHAR(200),                    -- 은행명
    @V_TOT                 NUMERIC(12,0),                   -- 구분이 총합일 경우 
    @V_SQL_PAY_MASTER      varchar(max),                    -- 일집계할 대상자 DYNAMIC QUERY용 
    @V_SEQ                 NUMERIC(5,0),                    -- 수번
    @V_MM                  VARCHAR(4),                      -- 월
    @V_BANK_CD             VARCHAR(20),                     -- 은행코드         
    @V_PAYMTWAY            VARCHAR(20),                     -- 지불수단
    @V_SQL_STR             varchar(max),                    -- BILL 삭제
    
    @S_TEMP                varchar(max),
    
    @V_CLNT_MGNT_YN	       NUMERIC(1,0) = 0,                 --거래처관리여부(1:관리,0 : 미관리)        
    @V_ACCT_CLS_CD         VARCHAR(01), 
    @V_COST_CLS_CD         VARCHAR(02),      
    @V_COST_ACCTCD         VARCHAR(20),    -- 원가계정코드
    @V_MGNT_ACCTCD         VARCHAR(20),    -- 판관비계정코드
    @V_BIZ_ACCT            NVARCHAR(20),
    

    @V_BATCH_LOGID         NUMERIC(10),                                                -- 배치로그ID
    @V_BATCH_WORKNM        VARCHAR(100) = '인사급/상여전표생성',     -- 배치로그내용에 남길값
    @V_PROCNM              VARCHAR(200),     
    
    @V_PRE_MON_YYMMDD      VARCHAR(16),            -- 전월
    @V_CSTDPAT_CD          VARCHAR(20),
        
 -- CURSOR용 변수
   	@V_PBT_ACCNT_STD       VARCHAR,    -- 전표기준
   	@V_PBT_INCITEM         VARCHAR,     -- 포함된 항목
   	@V_PBT_EXCITEM         VARCHAR,     -- 제외된 항목
	
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
	@v_error_note				VARCHAR(3000),										-- 에러노트 (exec : '문자열A|문자열B')
	
	@V_CNT_MAIN                 INT,
	@OPENQUERY					nvarchar(4000), 
	@TSQL						nvarchar(4000), 
	@LinkedServer				nvarchar(20) = 'DEBIS';
	--@LinkedServer				nvarchar(20) = 'DBTOP_P';

BEGIN TRY
--	BEGIN TRANSACTION
-- CURSOR 선언 
	--print('시작')
    BEGIN
		SET @v_error_code = '';
		SET @v_error_note = '';
		
		SET @V_CNT_MAIN = 0;
		--PRINT('전표테이블 삭제')    
		DELETE FROM PBT_BILL_CREATE 
		 WHERE COMPANY  = @P_COMPANY         -- 회사코드 (E고정)
		   AND HRTYPE_GBN = @P_HRTYPE_GBN    -- 인력유형구분
		   AND PAY_YM   = @P_YYYYMM          -- 급여년월
		   AND PAY_CD   = @P_PAY_CD          -- 급여코드
		   AND BILL_GBN = @P_BILL_GBN        -- 전표구분
		   AND PROC_DT  = @P_PROC_DATE;      -- 처리일자
		IF @@error <> 0
			BEGIN
				SET @v_error_number = @@error;
				SET @v_error_code = 'p_at_pay_debis_interface';
				SET @v_error_note = 'PBT_BILL_CREATE TABLE 내역 삭제 중 오류가 발생하였습니다.'
				GOTO ERR_HANDLER
			END
	END
	
	BEGIN
		--PRINT('커서선언!!')
		SELECT @V_SEQ = ISNULL(MAX(SEQ), 0)
		  FROM PBT_BILL_CREATE 
		 WHERE COMPANY = @P_COMPANY
		   AND HRTYPE_GBN = @P_HRTYPE_GBN
		   AND PAY_YM = @P_YYYYMM
		   AND PAY_CD = @P_PAY_CD
		   AND BILL_GBN = @P_BILL_GBN
		--SET @V_SEQ = 0;
		
		DECLARE	C_PBT_ACCNT_STD	CURSOR	FOR                 -- 전표코드로 생성할 전표를 가져온다. 
		SELECT WRTDPT_CD,   BILL_GBN,   TRDTYP_CD,    ACCNT_CD
			  ,CUST_CD,     AGGR_GBN,   CSTDPAT_CD,   CSTDPAT_CD
			  ,TRDTYP_NM,   TRDTYP_NM,  SUMMARY,      DEBSER_GBN
			  ,COST_ACCTCD, MGNT_ACCTCD    -- 판관비계정코드
		  FROM PBT_ACCNT_STD
		 WHERE COMPANY = @P_COMPANY
		   AND HRTYPE_GBN = @P_HRTYPE_GBN
		   AND BILL_GBN = @P_BILL_GBN
		   AND USE_YN = 'Y'
		 ORDER BY DEBSER_GBN, TRDTYP_CD
		   --전표코드별로 전표기준을 가져온다. 
        
        OPEN C_PBT_ACCNT_STD  -- 커서 패치
		FETCH NEXT FROM C_PBT_ACCNT_STD	INTO	@V_WRTDPT_CD,
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
			--PRINT('C_PBT_ACCNT_STD 커서 오픈 ' + CAST(@V_CNT_MAIN AS VARCHAR) + '번째 수행')
			SET @V_CNT_MAIN = @V_CNT_MAIN + 1;
			SET @V_SUMMARY_TM = '';
			SET @V_BANK_CD = '';
			SET @V_PAYMTWAY = '';
			SET @V_SABUN = '';
			SET @V_SUMMARY_CNT = 0;
			SET @V_INCITEM_STR = '';
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
			
			/* 전표유형 확인용 변수 */
			--PRINT('========================================')
			--PRINT('@V_WRTDPT_CD   ' + @V_WRTDPT_CD );
			--PRINT('@V_BILL_GBN    ' + @V_BILL_GBN );
			--PRINT('@V_TRDTYP_CD   ' + @V_TRDTYP_CD);
			--PRINT('@V_ACCNT_CD    ' + @V_ACCNT_CD);
			--PRINT('========================================')
		
          
			--PRINT('2번째 커서선언!!') 
			DECLARE C_PBT_INCITEM CURSOR FOR                  -- 전표생성을 위해 포함된 항목을 가져온다. 
			SELECT ITEM_CD,
				   INCITEM,
				   INCITEM_FR,
				   INCITEM_TO 
			  FROM PBT_INCITEM
			 WHERE COMPANY = @P_COMPANY
			   AND HRTYPE_GBN = @P_HRTYPE_GBN
			   AND WRTDPT_CD  = @V_WRTDPT_CD
			   AND BILL_GBN   = @V_BILL_GBN
			   AND TRDTYP_CD  = @V_TRDTYP_CD
			   AND ACCNT_CD   = @V_ACCNT_CD
			 ORDER BY ITEM_CD, SEQ
			
			OPEN C_PBT_INCITEM  -- 커서 패치
			FETCH NEXT FROM C_PBT_INCITEM INTO   @V_ITEM_CD,
												 @V_INCITEM,
												 @V_INCITEM_FR,
												 @V_INCITEM_TO 
			WHILE	@@fetch_status = 0
		
			BEGIN   
				 --인력유형일 경우
				 IF @V_ITEM_CD = 'A'
					BEGIN
						SET @V_INCITEM_STR = @V_INCITEM_STR + ' AND C.HRTYPE_GBN = ''' + @V_INCITEM + '''';
					END
				 --사원구분일 경우
				 IF @V_ITEM_CD = 'B'
					BEGIN
						SET @V_INCITEM_STR = @V_INCITEM_STR + ' AND dbo.fn_GetDongbuCode(''HU012'', TP_CALC_INS) = ''' + @V_INCITEM + '''';
					END
				 --원가부서일 경우
				 IF @V_ITEM_CD = 'C'
					BEGIN
						SET @V_INCCOSTDPT_CNT = @V_INCCOSTDPT_CNT + 1;
						IF @V_INCCOSTDPT_CNT = 1
							BEGIN
								SET @V_INCCOSTDPT_STR = @V_INCCOSTDPT_STR + ' AND ((CD_COST BETWEEN ''' + @V_INCITEM_FR + ''' AND ''' + @V_INCITEM_TO + ''')';
							END
						ELSE
							BEGIN
								SET @V_INCCOSTDPT_STR = @V_INCCOSTDPT_STR + ' OR (CD_COST BETWEEN ''' + @V_INCITEM_FR + ''' AND ''' + @V_INCITEM_TO + ''')';
							END
					END    
				 --직급일 경우
				 IF @V_ITEM_CD = 'D'
					BEGIN
						SET @V_INCJIKGUB_CNT = @V_INCJIKGUB_CNT + 1;
						IF @V_INCJIKGUB_CNT = 1
							BEGIN
								SET @V_INCJIKGUB_STR = @V_INCJIKGUB_STR + ' AND ((dbo.fn_GetDongbuCode(''HU010'', A.LVL_PAY1) BETWEEN ''' + @V_INCITEM_FR + ''' AND ''' + @V_INCITEM_TO + ''')';
							END
						ELSE
							BEGIN
                 				SET @V_INCJIKGUB_STR = @V_INCJIKGUB_STR + ' OR (dbo.fn_GetDongbuCode(''HU010'', A.LVL_PAY1) BETWEEN ''' + @V_INCITEM_FR + ''' AND ''' + @V_INCITEM_TO + ''')';
							END
					END
				 
				 --사번일 경우
				 IF @V_ITEM_CD = 'E'
					BEGIN
						SET @V_SABUN_CNT = @V_SABUN_CNT + 1;
						IF @V_SABUN_CNT = 1
							BEGIN
								SET @V_SABUN_STR = @V_SABUN_STR + ' AND B.NO_PERSON IN (''' + (CASE WHEN LEFT(@V_INCITEM, 1) > 1 THEN '19' ELSE '20' END + @V_INCITEM) + ''''
							END
						ELSE
							BEGIN
                   				SET @V_SABUN_STR = @V_SABUN_STR + ' ,''' + @V_INCITEM + ''''
							END
					END
				 --은행일 경우
				 IF @V_ITEM_CD = 'F'
					BEGIN
						SET @V_BANK_CNT = @V_BANK_CNT + 1;
						IF @V_BANK_CNT = 1
							BEGIN
								SET @V_BANK_STR = @V_BANK_STR + ' AND PAY_BANKCD IN (''' + (CASE WHEN LEFT(@V_INCITEM, 1) > 1 THEN '19' ELSE '20' END + @V_INCITEM) + ''''
							END
						ELSE
							BEGIN
                   				SET @V_BANK_STR = @V_BANK_STR + ' ,''' + @V_INCITEM + ''''
	                 
							END
					END
				 --지급일 경우
				 IF @V_ITEM_CD = 'G'
					 BEGIN
						IF @V_INCITEM = 'P98080'   --(급여총액)
							BEGIN
							SET @V_ALOW_STR = @V_ALOW_STR + ' AND CD_ALLOW IN ( SELECT CD_ALLOW FROM H_MONTH_SUPPLY WHERE CD_COMPANY = ''' + @P_COMPANY + '''' +
											  ' AND YM_PAY = ''' + @P_YYYYMM + '''' + ' AND FG_SUPP = ''' + @P_PAY_CD + '''' 
							END
						ELSE
							BEGIN
								SET @V_ALOW_CNT = @V_ALOW_CNT + 1;
								IF @V_ALOW_CNT = 1
									BEGIN 
										SET @V_ALOW_STR = @V_ALOW_STR + ' AND CD_ALLOW IN (''' + @V_INCITEM + ''''
									END
								ELSE
									BEGIN
                     					SET @V_ALOW_STR = @V_ALOW_STR + ' ,''' + @V_INCITEM + ''''
                     				END
                     		END
					END
				 --공제일 경우
				 IF @V_ITEM_CD = 'H'
					BEGIN
						IF @V_INCITEM = 'P99051'  --(차인지급액)
							BEGIN
								--PRINT('차인지급액')
								SET @V_PAY_YN = 'Y';
							END
						ELSE IF @V_INCITEM = 'P99050'  --(공제총액)
							BEGIN
								--PRINT('공제총액 SELECT')
								SET @V_DEDT_STR = @V_DEDT_STR + ' AND CD_DEDUCT IN ( SELECT CD_DEDUCT FROM H_MONTH_DEDUCT WHERE CD_DEDUCT NOT IN (''205'') CD_COMPANY = ''' + @P_COMPANY + '''' +
													 ' AND YM_PAY = ''' + @P_YYYYMM + '''' + ' AND FG_SUPP = ''' + @P_PAY_CD + ''''; 
							END
						ELSE
							BEGIN
                 				SET @V_DEDT_CNT = @V_DEDT_CNT + 1;
								IF @V_DEDT_CNT = 1 
									BEGIN
										SET @V_DEDT_STR = @V_DEDT_STR + ' AND CD_DEDUCT IN (''' + @V_INCITEM + '''';
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
			-- 커서 제거
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
           
		DECLARE C_PBT_EXCITEM CURSOR FOR                 -- 전표생성을 위해 제외된 항목을 가져온다. 
			SELECT ITEM_CD,
                   EXCITEM,
				   EXCITEM_FR,
				   EXCITEM_TO 
			  FROM PBT_EXCITEM
			 WHERE COMPANY = @P_COMPANY
			   AND HRTYPE_GBN = @P_HRTYPE_GBN    -- 인력유형구분
			   AND WRTDPT_CD  = @V_WRTDPT_CD
			   AND BILL_GBN   = @V_BILL_GBN      -- 전표구분
			   AND TRDTYP_CD  = @V_TRDTYP_CD
			   AND ACCNT_CD   = @V_ACCNT_CD
			ORDER BY ITEM_CD, SEQ;
		
		OPEN C_PBT_EXCITEM
         FETCH NEXT FROM C_PBT_EXCITEM INTO   @V_EXITEM_CD,
											  @V_EXCITEM,
											  @V_EXCITEM_FR,
											  @V_EXCITEM_TO 
		
		 WHILE	@@fetch_status	=	0  
		 
		 BEGIN       
             --원가부서일 경우
              IF @V_EXITEM_CD = 'C'
				BEGIN
					SET @V_EXCOSTDPT_CNT = @V_EXCOSTDPT_CNT + 1;
					IF @V_EXCOSTDPT_CNT = 1
						BEGIN
							SET @V_EXCOSTDPT_STR = @V_EXCOSTDPT_STR + ' AND ((CD_COST NOT BETWEEN '''+ @V_EXCITEM_FR + ''' AND ''' + @V_EXCITEM_TO + ''')';
						END
					ELSE
						BEGIN
                 			SET @V_EXCOSTDPT_STR = @V_EXCOSTDPT_STR + ' AND  (CD_COST NOT BETWEEN '''+ @V_EXCITEM_FR + ''' AND ''' + @V_EXCITEM_TO + ''')';
						END
				END
             --직급일 경우
              IF @V_EXITEM_CD = 'D'
				BEGIN
					SET @V_EXJIKGUB_CNT = @V_EXJIKGUB_CNT + 1;
					IF @V_EXJIKGUB_CNT = 1
						BEGIN 
							SET @V_EXJIKGUB_STR = @V_EXJIKGUB_STR + ' AND ((dbo.fn_GetDongbuCode(''HU010'', A.LVL_PAY1) NOT BETWEEN ''' + @V_EXCITEM_FR + ''' AND ''' + @V_EXCITEM_TO + ''')';
						END
					ELSE
						BEGIN
							SET @V_EXJIKGUB_STR = @V_EXJIKGUB_STR + ' AND (dbo.fn_GetDongbuCode(''HU010'',A.LVL_PAY1) NOT BETWEEN ''' + @V_EXCITEM_FR + ''' AND ''' + @V_EXCITEM_TO + ''')';
						END
				END		
              --사번일 경우
              IF @V_EXITEM_CD = 'E'
				BEGIN
					SET @V_EXSABUN_CNT = @V_EXSABUN_CNT + 1;
					IF @V_EXSABUN_CNT = 1
						BEGIN 
							SET @V_EXSABUN_STR = @V_EXSABUN_STR + ' AND B.NO_PERSON NOT IN (''' + @V_EXCITEM + '''';
						END
					ELSE
						BEGIN
                   			SET @V_EXSABUN_STR = @V_EXSABUN_STR + ' ,''' + @V_EXCITEM + '''';
                   		END
                END
             --은행일 경우
              IF @V_EXITEM_CD = 'F'
				BEGIN 
					SET @V_EXBANK_CNT = @V_EXBANK_CNT + 1;
					IF @V_EXBANK_CNT = 1
						BEGIN
							SET @V_EXBANK_STR = @V_EXBANK_STR + ' AND PAY_BANKCD NOT IN (''' + @V_EXCITEM + '''';
						END
					ELSE
						BEGIN
                   			SET @V_EXBANK_STR = @V_EXBANK_STR + ' ,''' + @V_EXCITEM + '''';
                   		END
                END
  
			FETCH NEXT FROM C_PBT_EXCITEM INTO  @V_EXITEM_CD,
											    @V_EXCITEM,
											    @V_EXCITEM_FR,
											    @V_EXCITEM_TO
	         
         END
        
         CLOSE C_PBT_EXCITEM;  -- 제외항목 종료
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
		 	       
         --지급일 경우                                                                                                                   
         IF @V_ITEM_CD = 'G'
			BEGIN                                                                                                
             --집계구분이 원가부서일 경우                                                                                         
				IF @V_AGGR_GBN = 'A1'
					BEGIN                                                                                         
						SET @V_RESULT_STR =  ' SELECT '''' AS SABUN, A.CD_COST COSTDPT_CD, SUM(TOT) AS TOT, SUM(TOT) AS AMT'+  
									         ' FROM H_MONTH_PAY_BONUS A LEFT OUTER JOIN '+ 
											 ' (SELECT CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON, SUM(AMT_ALLOW) AS TOT '+ 
											 '    FROM H_MONTH_SUPPLY A '+
											 '   WHERE 1=1 ' + @V_ALOW_STR +  
											 ' GROUP BY CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON) B '+
											 '   ON A.CD_COMPANY = B.CD_COMPANY AND A.NO_PERSON = B.NO_PERSON '+
											 '  AND A.YM_PAY = B.YM_PAY AND A.FG_SUPP = B.FG_SUPP AND A.DT_PROV = B.DT_PROV JOIN '+
											 ' H_HUMAN C ON A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON '+
											 ' WHERE A.CD_COMPANY = ''' + @P_COMPANY  + '''' +  
											 ' AND A.YM_PAY  = ''' + @P_YYYYMM+ '''' +
											 ' AND A.DT_PROV = ''' + @P_PROC_DATE + '''' +   
											 ' AND A.FG_SUPP= ''' + @P_PAY_CD+ '''' + 
											 ' AND C.HRTYPE_GBN = ''' + @P_HRTYPE_GBN + '''' +  --여기  
											 @V_INCITEM_STR + @V_INCCOSTDPT_STR + @V_INCJIKGUB_STR + @V_SABUN_STR + @V_BANK_STR + 
											 @V_EXCITEM_STR + @V_EXCOSTDPT_STR + @V_EXJIKGUB_STR + @V_EXSABUN_STR + @V_EXBANK_STR + 
											 ' GROUP BY A.CD_COMPANY, A.YM_PAY, A.FG_SUPP, A.CD_COST' 
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

             --집계구분이 총합일 경우                                                                                             
				ELSE IF @V_AGGR_GBN = 'A2'
					BEGIN                                                                                        
						SET @V_RESULT_STR =  ' SELECT '''' AS SABUN,'''' AS COSTDPT_CD, SUM(TOT) AS TOT,  SUM(TOT) AS AMT ' +   
											 ' FROM H_MONTH_PAY_BONUS A LEFT OUTER JOIN '+    
											 '(SELECT CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON, SUM(AMT_ALLOW) AS TOT '+    
											 ' FROM H_MONTH_SUPPLY A '+    
											 '   WHERE 1=1 ' + @V_ALOW_STR +  
											 ' GROUP BY CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON) B '+ 
											 '   ON A.CD_COMPANY = B.CD_COMPANY AND A.NO_PERSON = B.NO_PERSON '+
											 '  AND A.YM_PAY = B.YM_PAY AND A.FG_SUPP = B.FG_SUPP AND A.DT_PROV = B.DT_PROV JOIN '+
											 ' H_HUMAN C ON A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON '+ 
											 ' WHERE  A.CD_COMPANY = '''+ @P_COMPANY   + '''' +     
											 ' AND A.YM_PAY = '''+ @P_YYYYMM + '''' +    
											 ' AND A.DT_PROV = ''' + @P_PROC_DATE + '''' +  
											 ' AND A.FG_SUPP = '''+ @P_PAY_CD + '''' +   
											 ' AND C.HRTYPE_GBN = '''+ @P_HRTYPE_GBN + '''' +     --여기    
											  @V_INCITEM_STR + @V_INCCOSTDPT_STR + @V_INCJIKGUB_STR + @V_SABUN_STR + @V_BANK_STR + 
											  @V_EXCITEM_STR + @V_EXCOSTDPT_STR + @V_EXJIKGUB_STR + @V_EXSABUN_STR + @V_EXBANK_STR ;
					END
             --집계구분이 사번일 경우                                                                                             
				ELSE IF @V_AGGR_GBN = 'A3'
					BEGIN 
						--PRINT('임원쿼리')                                                                                        
						SET @V_RESULT_STR =' SELECT A.NO_PERSON AS SABUN, A.CD_COST COSTDPT_CD, TOT, TOT AS AMT '+ 
										   ' FROM H_MONTH_PAY_BONUS A LEFT OUTER JOIN '+ 
											 ' (SELECT CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON, SUM(AMT_ALLOW) AS TOT '+ 
											 ' FROM H_MONTH_SUPPLY A '+ 
											 '   WHERE 1=1 ' + @V_ALOW_STR +  
											 ' GROUP BY CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON) B '+
											 '   ON A.CD_COMPANY = B.CD_COMPANY AND A.NO_PERSON = B.NO_PERSON '+
											 '  AND A.YM_PAY = B.YM_PAY AND A.FG_SUPP = B.FG_SUPP AND A.DT_PROV = B.DT_PROV JOIN '+
											 ' H_HUMAN C ON A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON '+ 
											 ' WHERE A.CD_COMPANY = '''+ @P_COMPANY + '''' + 
											 ' AND A.YM_PAY = '''+ @P_YYYYMM+ '''' + 
											 ' AND A.DT_PROV = ''' + @P_PROC_DATE + '''' + 
											 ' AND A.FG_SUPP= '''+ @P_PAY_CD+ '''' + 
											 ' AND C.HRTYPE_GBN = '''+ @P_HRTYPE_GBN + '''' +     --여기   
											  @V_INCITEM_STR + @V_INCCOSTDPT_STR + @V_INCJIKGUB_STR + @V_SABUN_STR + @V_BANK_STR + 
										      @V_EXCITEM_STR + @V_EXCOSTDPT_STR + @V_EXJIKGUB_STR + @V_EXSABUN_STR + @V_EXBANK_STR; 
						--PRINT('쿼리 : ' + @V_RESULT_STR);
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
						--PRINT('임원쿼리끝');
					END 
--집계구분이 은행일 경우
				ELSE IF @V_AGGR_GBN = 'A4'
					BEGIN 
						SET @V_RESULT_STR =' SELECT A.SABUN, '''' AS COSTDPT_CD, SUM(TOT) AS TOT,SUM(TOT) AS AMT '+ 
											 ' FROM H_MONTH_PAY_BONUS A, '+ 
											 '(SELECT CD_COMPANY, YM_PAY, FG_SUPP, NO_PERSON, SUM(AMT_ALLOW) AS TOT '+ 
											 ' FROM H_MONTH_SUPPLY A '+ 
											 ' WHERE A.CD_COMPANY = '''+ @P_COMPANY + '''' + 
											 ' AND A.YM_PAY = '''+ @P_YYYYMM+ '''' + 
											 ' AND A.DT_PROV = ''' + @P_PROC_DATE + '''' + 
											 ' AND A.FG_SUPP = '''+ @P_PAY_CD+ '''' + @V_ALOW_STR + 
											 ' GROUP BY CD_COMPANY, YM_PAY, FG_SUPP, NO_PERSON) B, '+ 
											 ' H_HUMAN C '+
											 ' WHERE A.CD_COMPANY = B.CD_COMPANY '+
											 ' AND A.CD_COMPANY = C.CD_COMPANY '+
											 ' AND A.NO_PERSON = C.NO_PERSON '+
											 ' AND C.HRTYPE_GBN = '''+ @P_HRTYPE_GBN+ '''' +--여기
											 ' AND A.YM_PAY = B.YM_PAY '+ 
											 ' AND A.FG_SUPP = B.PAY_CD '+ 
											 ' AND A.NO_PERSON = B.NO_PERSON '+ 
											@V_INCITEM_STR + @V_INCCOSTDPT_STR + @V_INCJIKGUB_STR + @V_SABUN_STR + @V_BANK_STR + 
											@V_EXCITEM_STR + @V_EXCOSTDPT_STR + @V_EXJIKGUB_STR + @V_EXSABUN_STR + @V_EXBANK_STR + 
											 ' GROUP BY A.CD_COMPANY, A.YM_PAY, A.FG_SUPP, A.PAY_BANKCD'; -- PAY_BANKCD는 ????
					END
			END
--공제일 경우 
IF @V_ITEM_CD = 'H'
			BEGIN 
--집계구분이 원가부서일 경우 
				IF @V_AGGR_GBN = 'A1'
					BEGIN
						SET @V_RESULT_STR =' SELECT '''' AS SABUN, A.CD_COST AS COSTDPT_CD, SUM(TOT) AS TOT,SUM(AMT_SUPPLY_TOTAL - AMT_DEDUCT_TOTAL) AS AMT '+ 
											 ' FROM H_MONTH_PAY_BONUS A LEFT OUTER JOIN '+ 
											 ' (SELECT CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON, SUM(AMT_DEDUCT) AS TOT '+ 
											 ' FROM H_MONTH_DEDUCT A '+ 
											 ' WHERE 1=1 ' + @V_DEDT_STR + 
											 ' GROUP BY CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON) B '+ 
											 '   ON A.CD_COMPANY = B.CD_COMPANY AND A.NO_PERSON = B.NO_PERSON '+
											 '  AND A.YM_PAY = B.YM_PAY AND A.FG_SUPP = B.FG_SUPP AND A.DT_PROV = B.DT_PROV JOIN '+
											 ' H_HUMAN C ON A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON '+
											 ' WHERE A.CD_COMPANY = '''+ @P_COMPANY + '''' + 
											 '   AND A.YM_PAY = '''+ @P_YYYYMM+ '''' + 
											 '   AND A.DT_PROV = ''' + @P_PROC_DATE + '''' + 
											 '   AND A.FG_SUPP= '''+ @P_PAY_CD+ '''' + 
											 '   AND C.HRTYPE_GBN = '''+ @P_HRTYPE_GBN+ '''' + --여기 
											@V_INCITEM_STR + @V_INCCOSTDPT_STR + @V_INCJIKGUB_STR + @V_SABUN_STR + @V_BANK_STR + 
											@V_EXCITEM_STR + @V_EXCOSTDPT_STR + @V_EXJIKGUB_STR + @V_EXSABUN_STR + @V_EXBANK_STR + 
											 ' GROUP BY A.CD_COMPANY, A.YM_PAY, A.FG_SUPP, A.CD_COST ';
			-- 'GROUP BY A.COMPANY, A.WORK_YM, A.PAY_CD, A.COSTDPT_CD, TOT, ALOWTOT_AMT, DEDTTOT_AMT ';
					END
--집계구분이 총합일 경우
				ELSE IF @V_AGGR_GBN = 'A2'
					BEGIN 
						SET @V_RESULT_STR =' SELECT '''' AS SABUN, ''' + @V_CSTDPAT_CD + ''' AS COSTDPT_CD, SUM(TOT) AS TOT,SUM(AMT_SUPPLY_TOTAL-AMT_DEDUCT_TOTAL) AS AMT'+ 
											 ' FROM H_MONTH_PAY_BONUS A LEFT OUTER JOIN '+ 
											 ' (SELECT CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON, SUM(AMT_DEDUCT) AS TOT '+ 
											 ' FROM H_MONTH_DEDUCT A'+ 
											 ' WHERE 1=1 ' + @V_DEDT_STR + 
											 ' GROUP BY CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON) B '+
											 '   ON A.CD_COMPANY = B.CD_COMPANY AND A.NO_PERSON = B.NO_PERSON '+
											 '  AND A.YM_PAY = B.YM_PAY AND A.FG_SUPP = B.FG_SUPP AND A.DT_PROV = B.DT_PROV JOIN '+
											 ' H_HUMAN C ON A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON '+
											 ' WHERE A.CD_COMPANY = '''+ @P_COMPANY + '''' + 
											 '   AND A.YM_PAY = '''+ @P_YYYYMM+ '''' + 
											 '   AND A.DT_PROV = ''' + @P_PROC_DATE + '''' + 
											 '   AND A.FG_SUPP= '''+ @P_PAY_CD+ '''' +  
											 '   AND C.HRTYPE_GBN = '''+ @P_HRTYPE_GBN+ '''' + --여기 
											@V_INCITEM_STR + @V_INCCOSTDPT_STR + @V_INCJIKGUB_STR + @V_SABUN_STR + @V_BANK_STR + 
											@V_EXCITEM_STR + @V_EXCOSTDPT_STR + @V_EXJIKGUB_STR + @V_EXSABUN_STR + @V_EXBANK_STR ;
						PRINT(@V_RESULT_STR)
END
--집계구분이 사번일 경우
				ELSE IF @V_AGGR_GBN = 'A3'
					BEGIN 
						SET @V_RESULT_STR =' SELECT A.NO_PERSON AS SABUN, A.CD_COST AS COSTDPT_CD, TOT,AMT_SUPPLY_TOTAL-AMT_DEDUCT_TOTAL AS AMT'+ 
											 ' FROM H_MONTH_PAY_BONUS A LEFT OUTER JOIN '+ 
											 ' (SELECT CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON, SUM(AMT_DEDUCT) AS TOT '+ 
											 ' FROM H_MONTH_DEDUCT A'+ 
											 ' WHERE 1=1 ' + @V_DEDT_STR + 
											 ' GROUP BY CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON) B '+ 
											 '   ON A.CD_COMPANY = B.CD_COMPANY AND A.NO_PERSON = B.NO_PERSON '+
											 '  AND A.YM_PAY = B.YM_PAY AND A.FG_SUPP = B.FG_SUPP AND A.DT_PROV = B.DT_PROV JOIN '+
											 ' H_HUMAN C ON A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON '+
											 ' WHERE A.CD_COMPANY = '''+ @P_COMPANY + '''' + 
											 '   AND A.YM_PAY = '''+ @P_YYYYMM+ '''' + 
											 '   AND A.DT_PROV = ''' + @P_PROC_DATE + '''' + 
											 '   AND A.FG_SUPP= '''+ @P_PAY_CD+ '''' + 
											 '   AND C.HRTYPE_GBN = '''+ @P_HRTYPE_GBN+ '''' +--여기 
											@V_INCITEM_STR + @V_INCCOSTDPT_STR + @V_INCJIKGUB_STR + @V_SABUN_STR + @V_BANK_STR + 
											@V_EXCITEM_STR + @V_EXCOSTDPT_STR + @V_EXJIKGUB_STR + @V_EXSABUN_STR + @V_EXBANK_STR;
					END
--집계구분이 은행일 경우
				ELSE IF @V_AGGR_GBN = 'A4'
					BEGIN 
						SET @V_RESULT_STR =' SELECT '''' AS SABUN, ''' + @V_CSTDPAT_CD + ''' AS COSTDPT_CD, SUM(TOT) AS TOT,SUM(AMT_SUPPLY_TOTAL-AMT_DEDUCT_TOTAL) AS AMT'+ 
											 ' FROM H_MONTH_PAY_BONUS A LEFT OUTER JOIN '+ 
											 ' (SELECT CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON, SUM(AMT_DEDUCT) AS TOT '+ 
											 ' FROM H_MONTH_DEDUCT A'+ 
											 ' WHERE 1=1 ' + @V_DEDT_STR + 
											 ' GROUP BY CD_COMPANY, YM_PAY, DT_PROV, FG_SUPP, NO_PERSON) B '+
											 '   ON A.CD_COMPANY = B.CD_COMPANY AND A.NO_PERSON = B.NO_PERSON '+
											 '  AND A.YM_PAY = B.YM_PAY AND A.FG_SUPP = B.FG_SUPP AND A.DT_PROV = B.DT_PROV JOIN '+
											 ' H_HUMAN C ON A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON '+
											 ' WHERE A.CD_COMPANY = '''+ @P_COMPANY + '''' + 
											 '   AND A.YM_PAY = '''+ @P_YYYYMM+ '''' + 
											 '   AND A.DT_PROV = ''' + @P_PROC_DATE + '''' + 
											 '   AND A.FG_SUPP= '''+ @P_PAY_CD+ '''' +  
											 '   AND C.HRTYPE_GBN = '''+ @P_HRTYPE_GBN+ '''' + --여기 
											@V_INCITEM_STR + @V_INCCOSTDPT_STR + @V_INCJIKGUB_STR + @V_SABUN_STR + @V_BANK_STR + 
											@V_EXCITEM_STR + @V_EXCOSTDPT_STR + @V_EXJIKGUB_STR + @V_EXSABUN_STR + @V_EXBANK_STR ;
					END
			END
			                                          
		 --PRINT('@V_WRTDPT_CD : ' + @V_WRTDPT_CD)
		 --PRINT('@V_BILL_GBN : ' + @V_BILL_GBN)
		 --PRINT('@V_TRDTYP_CD : ' + @V_TRDTYP_CD)
		 --PRINT('@V_ACCNT_CD : ' + @V_ACCNT_CD)                                                                                                           
         --PRINT('@V_RESULT_STR : ' + @V_RESULT_STR);
         -- 차변, 대변 구분
         IF @V_DEBSER_GBN= '2'   --차변일때
			BEGIN
				SET @V_DEBSER_GBN = '50';
			END
         ELSE
			BEGIN
          		SET @V_DEBSER_GBN = '40';
          	END
         
         --전표생성
         
         IF ISNULL(@V_RESULT_STR, '') = ''
			Goto NEXT_C_PBT_ACCNT_STD
         
         SET @V_RESULT_STR = 'set @cursor = cursor forward_only static for ' + @V_RESULT_STR + ' open @cursor;'
         --PRINT(@V_RESULT_STR);
		 
		 EXEC SP_EXECUTESQL @V_RESULT_STR, N'@cursor cursor output', @objcursor output
			FETCH NEXT FROM @objcursor INTO @V_SABUN, @V_COSTDPTCD, @V_TOT, @V_PAY_TOT
		 
		 WHILE @@FETCH_STATUS = 0
		 BEGIN
			 PRINT('내부쿼리 수행 시작!!')
			 PRINT('@V_SABUN : ' + @V_SABUN)
			 PRINT('@V_COSTDPTCD : ' + @V_COSTDPTCD)
			 PRINT('@V_TOT : ' + CAST(ISNULL(@V_TOT, 0) AS VARCHAR))
			 PRINT('@V_PAY_TOT : ' + CAST(ISNULL(@V_PAY_TOT, 0) AS VARCHAR))
			 SET @V_SEQ = @V_SEQ + 1;
			 SET @V_MM = '';
			 SET @V_COSTDPT_CD = '';
			   
	         --차인지급액일 경우(공제:Z01)
             IF @V_PAY_YN = 'Y'
				BEGIN
					SET @V_TOT = @V_PAY_TOT; 
				END
             --원래원가코드
             SET @V_ORG_COSTCD = @V_COSTDPTCD; 
             
              -- 원가부서 구분(v_costdpt_cd,v_costdpt_TM:기준의원가, v_costdptcd:데이타의원가)
             IF @V_AGGR_GBN = 'A1'
				BEGIN
					IF @V_COSTDPT_TM IS NULL OR @V_COSTDPT_TM = ''
						BEGIN
							SET @V_COSTDPT_CD = @V_COSTDPTCD;
						END
					ELSE
						BEGIN
						    --원가별집계시 기준에 원가부서가 있는 경우 원래원가부서처리시여기에 수정 --
						    SET @V_TRDTYP_NM_E = SUBSTRING(@V_COSTDPTCD,1,4) +'_'+ SUBSTRING(@V_TRDTYP_NM,1,40);                             --*/
						    SET @V_COSTDPT_CD  = @V_COSTDPT_TM;
						END
				END
				
			IF @V_AGGR_GBN = 'A2' or @V_AGGR_GBN = 'A4'
				BEGIN
					SET @V_COSTDPT_CD = @V_COSTDPTCD;
				END
				
             SET @V_MM = SUBSTRING(@P_YYYYMM,5,2);
             
             --물류일 경우
             IF @P_COMPANY IN ('X', 'Y', 'B')
				BEGIN  
                 -- 적요(앞에 매달 전표생성되는 월을 표시)
					SET @V_SUMMARY_CNT = @V_SUMMARY_CNT +1;
					IF @V_SUMMARY_CNT = 1
						BEGIN
							SET @V_SUMMARY = @V_MM + @V_SUMMARY;
							SET @V_SUMMARY_TM = @V_SUMMARY;
						END
					-- 사번일 경우
					IF @V_AGGR_GBN = 'A3'
						BEGIN  
							SET @V_PAYMTWAY  = '20'    -- 지불수단:경비이체
							--사원거래처 찾기
							SET @V_CUST_CD = '';
							SET @OPENQUERY = 'SELECT @V_CUST_CD = C.CD_DETAIL FROM OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_ZZ510 where ACCOUNT_CLNT_KND_CD = ''''EM'''' AND CLNT_DEL_YN = 0 AND EMP_NO = ''''' + @V_SABUN + ''''''' )B '
							SET @OPENQUERY = @OPENQUERY + 'LEFT OUTER JOIN B_DETAIL_CODE_COMPANY C ON C.CD_COMPANY =''X'' AND C.CD_MASTER = ''HU514'' AND C.USER1 = B.CLNT_NO'
					
							EXEC sp_executesql @OPENQUERY, N'@V_CUST_CD nvarchar(40) OUTPUT', @V_CUST_CD output
							
							--PRINT('DB링크 쿼리1 : ' + @OPENQUERY)
                    
						--  V_CUST_CD := V_COSTDPTCD + '_' + V_SABUN;
						-- 집계구분이 사번일 경우에는 원가부서에 사번의 원가부서를 생성해준다
						--    V_COSTDPT_CD := V_COSTDPTCD;
							 IF @V_COSTDPT_TM IS NULL OR @V_COSTDPT_TM = ''
								BEGIN
									SET @V_COSTDPT_CD = @V_COSTDPTCD;
								END
							 ELSE
								BEGIN
									SET @V_COSTDPT_CD = @V_COSTDPT_TM;
								END	
                     
							 IF @V_TRDTYP_CD  IN ('101','600','605')  --임원일 경우 처리
								BEGIN
									SET @V_CUST_CD = '';
									SET @V_PAYMTWAY  = ''; 
								END
						END 
                 -- 은행일 경우
					ELSE IF @V_AGGR_GBN = 'A4'  
						BEGIN
							SET @V_PAYMTWAY = '70';    --지불수단:급여이체
							SET @V_BANK_CD = @V_COSTDPTCD;
							SET @V_BANK_NM = '';
							
							-- 은행명을 가져온다.
							IF  @P_PAY_CD  = '05'
								BEGIN
									SET @V_BANK_CD = '';
									SET @V_BANK_NM = ''; -- 임시주석 dbo.fn_GetCodesNm(); --GETCODENAME(@P_COMPANY, @V_BANK_CD); 
									SET @V_SUMMARY = @V_BANK_NM +'_'+ @V_SUMMARY_TM; 
								END
						 END
							--건강보험, 연금이고 계정이 미지급비용(2100810)인 경우 
					IF (@V_BILL_GBN = 'P5103' OR @V_BILL_GBN = 'P5104' OR @V_BILL_GBN = 'P5107' OR @V_BILL_GBN = 'P5108') AND @V_ACCNT_CD = '2100810'
						BEGIN
							SET @V_PAYMTWAY = '60';   -- 지불수단:당좌발행
						END
					
					IF (@V_BILL_GBN = 'P5101' OR @V_BILL_GBN = 'P5105') AND @V_ACCNT_CD = '2100810' AND @V_AGGR_GBN <> 'A4'
						BEGIN
							SET @V_PAYMTWAY = '20';   -- 지불수단:당좌발행
						END
				 END
				 
                   
          
           /* 원가부서의 비용구분 COST_CLS_CD (01:원가 , 02:판관비, 03: 원가+판관비) 확인 */
           SET @V_COST_CLS_CD = '';
           SELECT @V_BIZ_ACCT = BIZ_ACCT FROM B_COST_CENTER WHERE CD_COMPANY = @P_COMPANY AND CD_CC = @V_COSTDPT_CD
		   

		   --PRINT('@V_BIZ_ACCT : ' + @V_BIZ_ACCT)
		   SET @OPENQUERY = 'SELECT @V_COST_CLS_CD = COST_CLS_CD FROM OPENQUERY('+ @LinkedServer + ','''
		   SET @OPENQUERY = @OPENQUERY + 'SELECT COST_CLS_CD FROM TB_CO011 where ACCT_DEPT_CD = ''''' + @V_BIZ_ACCT + ''''' AND ACCT_YEAR = ''''' + SUBSTRING(@P_PROC_DATE,1,4) + ''''''' )'
		   EXEC sp_executesql @OPENQUERY, N'@V_COST_CLS_CD nvarchar(5) OUTPUT', @V_COST_CLS_CD output
           
           
           /* 계정구분: ACCT_CLS_CD (5;판관비,6:원가) 확인하여 계정코드체크 */
           SET @V_ACCT_CLS_CD = '';
           SET @OPENQUERY = 'SELECT @V_ACCT_CLS_CD = ACCT_CLS_CD FROM OPENQUERY('+ @LinkedServer + ','''
           SET @OPENQUERY = @OPENQUERY + 'SELECT ACCT_CLS_CD FROM TB_FI001 where ACCT_CD = ''''' + @V_ACCNT_CD + ''''''')' 
           EXEC sp_executesql @OPENQUERY, N'@V_ACCT_CLS_CD nvarchar(5) OUTPUT', @V_ACCT_CLS_CD output
           

         --print('CHECK 계정코드1 >>> ' + @V_ACCNT_CD );
         --print('CHECK 계정구분(데비스데이터) >>> ' + @V_ACCT_CLS_CD );
         --print('CHECK 원가구분(데비스데이터) >>> ' + @V_COST_CLS_CD );
         --print('CHECK 판관비계정코드 >>> ' + @V_MGNT_ACCTCD );
         --print('CHECK 원가계정코드 >>> ' + @V_COST_ACCTCD );

           /* 귀속부서의 비용구분과 발생한 계정의 계정구분을 비교 한다 - 전표기준에는 원가계정이므로 판관비 부서인 경우 대응코드(판관비계정으로 변경 한다) */
             IF @V_ACCT_CLS_CD IN ('5','6') --계정구분(5;판관비,6:원가)
				BEGIN	
					IF @V_COST_CLS_CD = '03' --원가+판관비 부서인 경우 
						BEGIN
						PRINT('NULL')
					 END
					ELSE   
						IF @V_COST_CLS_CD = '02' --판관비 부서인 경우 
							BEGIN
								SET @V_ACCNT_CD = @V_MGNT_ACCTCD;
								SET @V_SUMMARY  = REPLACE(@V_SUMMARY,'원가','판관비');
							END
						ELSE
							BEGIN
								SET @V_ACCNT_CD = @V_COST_ACCTCD;
								SET @V_SUMMARY  = REPLACE(@V_SUMMARY,'판관비','원가');
							END              
				END
           
             --PRINT('CHECK 계정코드2 >>> ' + @V_ACCNT_CD );

             IF @P_PAY_CD  = '02'
				BEGIN
				   --7월상여는 하계휴가비
					IF SUBSTRING(@P_YYYYMM,5,2) = '07'
						BEGIN 
							IF @V_ACCNT_CD = '4200220'
								BEGIN  
									SET @V_ACCNT_CD = '4200615';
									SET @V_SUMMARY  = REPLACE(@V_SUMMARY,'상여','하계휴가비');
								END
						END
				   -- 11월상여는 김장보조금
					IF SUBSTRING(@P_YYYYMM,5,2) = '11' 
						BEGIN
							IF @V_ACCNT_CD = '4200220'  
								BEGIN
									SET @V_ACCNT_CD = '4200616';
									SET @V_SUMMARY  = REPLACE(@V_SUMMARY,'상여','김장보조금');
								END
						END
				END
			 --PRINT(@V_TOT);
		  --   PRINT('CHECK 계정코드3 >>> ' + @V_ACCNT_CD );

    --         PRINT('@V_TOT >>> ' + CAST(@V_TOT AS VARCHAR) );
             IF @V_TOT <> 0    
             BEGIN
				SELECT *
				  FROM PBT_BILL_CREATE
				 WHERE COMPANY = @P_COMPANY
				   AND HRTYPE_GBN = @P_HRTYPE_GBN
				   AND PAY_YM = @P_YYYYMM
				   AND PAY_CD = @P_PAY_CD
				   AND WRTDPT_CD = @V_WRTDPT_CD
				   AND TRDTYP_CD = @V_TRDTYP_CD
				   AND BILL_GBN = @V_BILL_GBN
				   AND ACCNT_CD = @V_ACCNT_CD
				   AND SEQ = @V_SEQ
				
				
				IF @@ROWCOUNT > 1
					BEGIN
					PRINT('================업데이트구문 실행=====================')
					   UPDATE PBT_BILL_CREATE
						  SET AMT = @V_TOT
   							 ,TRDTYP_NM  = @V_TRDTYP_NM_E
   							 ,CUST_CD    = @V_CUST_CD
   							 ,COSTDPT_CD = @V_COSTDPT_CD
   							 ,DEBSER_GBN = @V_DEBSER_GBN
   							 ,SUMMARY    = @V_SUMMARY
   							 ,BANK_CD    = @V_BANK_CD
   							 ,PAYMTWAY   = @V_PAYMTWAY
							 ,PROC_DT    = @P_PROC_DATE
							 ,UPDATE_DT  = GETDATE()
							 ,UPDATE_SABUN = @P_SABUN
							 ,ORG_COST_CD = @V_ORG_COSTCD
   						WHERE COMPANY = @P_COMPANY
   						  AND HRTYPE_GBN = @P_HRTYPE_GBN
   						  AND PAY_YM  = @P_YYYYMM
   						  AND PAY_CD = @P_PAY_CD
   						  AND WRTDPT_CD = @V_WRTDPT_CD
   						  AND TRDTYP_CD = @V_TRDTYP_CD
   						  AND BILL_GBN = @V_BILL_GBN
   						  AND ACCNT_CD = @V_ACCNT_CD
   						  AND SEQ = @V_SEQ
					END
				ELSE
					BEGIN
						PRINT('================인서트구문 실행=====================')
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
    	   						COMPANY
    	   					   ,HRTYPE_GBN 
    	   					   ,PAY_YM
    	   					   ,PAY_CD
							   ,WRTDPT_CD              -- 작성부서
							   ,TRDTYP_CD              -- 거래유형
							   ,BILL_GBN               -- 전표구분
							   ,ACCNT_CD               -- 계정코드
							   ,SEQ                    -- 순번
							   ,AMT                    -- 금액
							   ,TRDTYP_NM              -- 거래명
							   ,CUST_CD                -- 거래처코드
							   ,COSTDPT_CD             -- 원가부서코드
							   ,DEBSER_GBN             -- 차대구분
							   ,SUMMARY                -- 적요사항
							   ,BANK_CD                -- 은행코드
							   ,PAYMTWAY               -- 지불수단
							   ,PROC_DT                -- 처리일자
							   ,INPUT_DT
							   ,INPUT_SABUN
							   ,ORG_COST_CD
    	   					  )
    	   					  VALUES(
    	   					   @P_COMPANY
    	   					  ,@P_HRTYPE_GBN
    	   					  ,@P_YYYYMM
    	   					  ,@P_PAY_CD
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
							  ,@P_PROC_DATE
    	   					  ,GETDATE()
    	   					  ,@P_SABUN
    	   					  ,@V_ORG_COSTCD
    	   					 )
					--PRINT('인서트 된 행갯수 : ' + CAST (@@ROWCOUNT AS VARCHAR))
					--PRINT('대상 : ' + @P_HRTYPE_GBN + ' ' +@P_YYYYMM + ' ' + @P_PAY_CD + ' ' + @V_WRTDPT_CD + ' ' +@V_TRDTYP_CD + ' ' + @V_BILL_GBN )  
    	   	
					
					END   
    	   	 END 
    	  	 			
		 FETCH NEXT FROM @objcursor INTO @V_SABUN, @V_COSTDPTCD, @V_TOT, @V_PAY_TOT
		 END 
           
         CLOSE @objcursor  --1번째 커서 종료         
		 DEALLOCATE @objcursor
	 
NEXT_C_PBT_ACCNT_STD:
		FETCH NEXT FROM C_PBT_ACCNT_STD	INTO	@V_WRTDPT_CD,
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
     CLOSE C_PBT_ACCNT_STD;  -- 전표코드로 생성할 전표 종료
     DEALLOCATE C_PBT_ACCNT_STD;
		 
     SET @p_error_code = '0';
	 

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

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;

	EXECUTE p_ba_errlib_getusererrormsg 'X', 'p_at_pay_DEBIS_interface',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message
	RETURN
END	
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
	
	EXECUTE p_ba_errlib_getusererrormsg 'X', 'p_at_pay_DEBIS_interface',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

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


GO

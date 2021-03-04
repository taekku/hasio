SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE dbo.P_REP_APP_SAIP_INTERFACE (
		@av_company_cd		nvarchar(10),			-- 회사코드
		@av_locale_cd		nvarchar(10),			-- 지역코드   
		@ad_std_date		date ,					-- 기준일자
		@av_pay_group		nvarchar(10),			-- 급여그룹
       @an_mod_user_id                NUMERIC(38),				-- 변경자 사번
       @av_ret_code                   NVARCHAR(4000)    OUTPUT, -- 결과코드   
       @av_ret_message                NVARCHAR(4000)    OUTPUT  -- 결과메시지   
    ) AS   
   
    -- ***************************************************************************   
    --   TITLE       : 퇴직충당금 분개처리
    --   PROJECT     : E-HR 시스템   
    --   AUTHOR      :   
    --   PROGRAM_ID  : P_REP_APP_SAIP_INTERFACE   
    --   RETURN      : 1) SUCCESS!/FAILURE!   
    --                 2) 결과 메시지   
    --   COMMENT     : 퇴직금계산    
    --   HISTORY     : 
    -- ***************************************************************************   
   
BEGIN
-- 임시 테이블 생성(퇴직추계액 내역 저장)
IF OBJECT_ID('tempdb..#TEMP_HUMAN') IS NOT NULL
	DROP TABLE #TEMP_HUMAN
CREATE TABLE #TEMP_HUMAN
	(
	COMPANY_CD [nvarchar](10) NULL,						--* 회사코드
	ORG_CD [nvarchar](10) NULL,						--* 부서코드
	EMP_NO [nvarchar](10) NULL,						--* 사번
	EMP_NM [nvarchar](20) NULL,						--* 성명
	POS_GRD_CD  [nvarchar](10) NULL,						--* 직급
	INS_TYPE_YN [nvarchar](2) NULL,					--* 연금가입여부
	INS_TYPE_CD [nvarchar](10) NULL,				--* 연금종류
	AMT_NEW_RETR_PAY [numeric](18,0) NULL,					--* 당월전입금.
	ACNT_TYPE_CD [nvarchar](10) NULL,						--* 계정구분
	COST_CD [nvarchar](10) NULL,							--* 코스트센터
    PAY_GROUP [nvarchar](10) NULL						--* 급여그룹
)
    /* 기본적으로 사용되는 변수 */   
    DECLARE @v_program_id              NVARCHAR(30)   
          , @v_program_nm              NVARCHAR(100)   
          , @ERRCODE                   NVARCHAR(10)   

DECLARE
	@v_company_cd				NVARCHAR(10),		-- 회사코드
	@n_pay_group_id				NUMERIC(38),		-- 급여그룹ID
   /* 프로시저 내에서 사용할 변수 정의  */
	@v_cd_company				NVARCHAR(10),		-- 회사코드
	@v_cd_dept					NVARCHAR(20),		-- 부서코드
	----
	@v_company_code				NVARCHAR(20),		-- 회사코드
	@v_cost_type				NVARCHAR(20),		-- 코스트센터 사업부분 ORM_COST.COST_TYPE
	@v_pos_grd_cd				NVARCHAR(20),		-- 직위코드
    @n_seqno_s                  INT = 0,			-- 문서순서
	@v_dt_dian					NVARCHAR(08),		-- 이관일자
	@v_dt_gian					NVARCHAR(06),		-- 기준월
	@v_emp_no					NVARCHAR(20),		-- 사번
	@v_emp_nm					NVARCHAR(20),		-- 사원명
	@v_cost_cd					NVARCHAR(20),		-- 코스트센터 코드 ORM_COST.COST_CD
	@v_acnt_cd					NVARCHAR(20),		-- 계정코드
	@v_rel_cd					NVARCHAR(20),		-- 상태계정
	@v_amt_new_retr_pay			NUMERIC(15),		-- 당월전입액
	@v_dbcr_cd					NVARCHAR(20),		-- 차대구분
    @v_seq                      NVARCHAR(10),			-- 생성순번
    @v_seq_h                    NVARCHAR(20),			-- 전표번호
    @v_acct_type                NVARCHAR(20) = 'E012',	-- 이관구분 - 퇴직충당금
    @v_pay_group                NVARCHAR(20),			-- 급여그룹
    @v_ifc_sort                 NVARCHAR(20),			-- 원천구분
    --@v_bill_type                NVARCHAR(20),			-- 계정유형

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


DECLARE @MSEQ INT;

      /* 기본변수 초기값 셋팅*/   
    SET @v_program_id    = 'P_REP_APP_SAIP_INTERFACE'   -- 현재 프로시져의 영문명   
    SET @v_program_nm    = '퇴직충당금 분개처리'        -- 현재 프로시져의 한글문명   
    SET @av_ret_code     = 'SUCCESS!'   
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)   
PRINT('시작 ===> ')   

	--//***************************************************************************
	--//*****************		 퇴직충당금 분개 처리				 **************
	--//***************************************************************************

	/* 파라메터를 로컬변수로 처리하며 이때 NULL일 경우에 필요한 처리를 한다. */
	SET @v_dt_dian		= dbo.XF_TO_CHAR_D(@ad_std_date, 'yyyymmdd')
	SET @v_dt_gian      = LEFT(@v_dt_dian, 6)
	SET @v_ifc_sort		= @v_acct_type
	--SET @v_id_user		= @p_id_user;		-- 로그인사용자
--===========================================================================================================
-- 전표 생성순번 및 전표번호 구하기
-------------------------------------------------------------------------------------------------------------
-- 생성순번 : 해당 전표생성일에 생성된 생성순번 기준으로 1부터 1씩 순차적으로 증가(1,2,3....)
-- 전표번호 : e-HR회사코드 + 품의일자 + 생성순번에 0을 채운 4자리 문자열
--      ex) 엔터프라이즈 2020년 8월 30일 품의일자로 해당일자에 두번째로 전표생성할 경우 ( E + 20200830 + 0002 )
--===========================================================================================================
    BEGIN

        SELECT @v_seq = ISNULL(MAX(SEQ), 0) + 1
          FROM H_IF_SAPINTERFACE
         WHERE CD_COMPANY = @av_company_cd
           AND DRAW_DATE  = @v_dt_dian

        SET @v_seq_h = @av_company_cd + @v_dt_dian + dbo.XF_LPAD(@v_seq, 4, '0')
    END
	PRINT '@v_seq ' + @v_seq + ' ' + @av_company_cd + @v_dt_dian


	BEGIN
		-- SAP I/F 테이블 삭제
		if ISNULL(@av_pay_group,'') = ''
			begin
				DELETE FROM H_IF_SAPINTERFACE
				WHERE CD_COMPANY = @av_company_cd
				  AND DRAW_DATE = @v_dt_dian					-- 이관일자		
				  AND ACCT_TYPE = @v_acct_type
				  AND FLAG = 'N'	
			end
		else
			begin
				DELETE FROM H_IF_SAPINTERFACE
				WHERE CD_COMPANY = @av_company_cd
				  AND DRAW_DATE = @v_dt_dian					-- 이관일자		
				  AND ACCT_TYPE = @v_acct_type
                  AND PAYGP_CODE = @av_pay_group		
				  AND FLAG = 'N'	
			end
		--------------------------------------------------------------------------------------------------------------------
		-- Message Setting Block 
		--------------------------------------------------------------------------------------------------------------------
		IF @@error <> 0
			BEGIN
				SET @v_error_number = @@error;
				SET @v_error_code = 'p_at_app_sap_interface';
				SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 내역 삭제 중 오류가 발생하였습니다.'
				GOTO ERR_HANDLER
			END
		-- 급여그룹 조건 가져오기
		IF @av_pay_group <> ''
			BEGIN
				SELECT @n_pay_group_id = PAY_GROUP_ID
				  FROM PAY_GROUP WITH(NOLOCK)
				 WHERE COMPANY_CD = @av_company_cd
				   AND PAY_GROUP = @av_pay_group
			END 
		----------------------------------
		-- 퇴직추계액 내역, 임시테이블에 생성
		----------------------------------
		--SET @v_sql = '';
                         --, DBO.F_PAY_GET_COST(YMD.COMPANY_CD, ROLL.EMP_ID, ROLL.ORG_ID, YMD.PAY_YMD, '1') AS COST_CD
                         --, DBO.F_PAY_GET_COST(YMD.COMPANY_CD, ROLL.EMP_ID, ROLL.ORG_ID, YMD.PAY_YMD, '2') AS COST_NM
                         --, DBO.F_PAY_GET_COST(YMD.COMPANY_CD, ROLL.EMP_ID, ROLL.ORG_ID, YMD.PAY_YMD, '3') AS ACCT_CD
                         --, DBO.F_PAY_GET_COST(YMD.COMPANY_CD, ROLL.EMP_ID, ROLL.ORG_ID, YMD.PAY_YMD, '4') AS COST_TYPE
		INSERT INTO #TEMP_HUMAN
			(COMPANY_CD, ORG_CD, EMP_NO, EMP_NM,
			 POS_GRD_CD, INS_TYPE_YN, INS_TYPE_CD, AMT_NEW_RETR_PAY,
			 ACNT_TYPE_CD, COST_CD, PAY_GROUP)
		SELECT A.COMPANY_CD,
				dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', A.ESTIMATION_YMD, '10') AS ORG_CD,
				EMP.EMP_NO, EMP.EMP_NM,
				B.POS_GRD_CD, B.INS_TYPE_YN, ISNULL(A.INS_TYPE_CD,'00'), A.NEW_RETIRE_AMT,
				'E012', A.ACC_CD, B.PAY_GROUP
		  FROM REP_ESTIMATION A
		  INNER JOIN REP_CALC_LIST B
		          ON A.COMPANY_CD = B.COMPANY_CD
				 AND A.ESTIMATION_YMD = B.PAY_YMD
				 AND A.EMP_ID = B.EMP_ID
				 AND B.CALC_TYPE_CD = '03'
		  INNER JOIN VI_FRM_PHM_EMP EMP
				  ON A.EMP_ID = EMP.EMP_ID AND EMP.LOCALE_CD = @av_locale_cd
		 WHERE A.COMPANY_CD = @av_company_cd
		   AND A.ESTIMATION_YMD = @ad_std_date
		   AND CASE WHEN A.COMPANY_CD IN ('A','B','C') THEN
		                 CASE WHEN dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', A.ESTIMATION_YMD, '10') <> 'Z999' -- 하우징 제외
						           AND A.INS_TYPE_CD = '20' -- DC제외
								THEN 1
							ELSE 0 END
					ELSE 1 END = 1
		----------------------------------
		-- 퇴직추계액 내역, 임시테이블에 생성
		----------------------------------
		--DECLARE PER_CUR	CURSOR	FOR
			--SELECT A.COMPANY_CD
			--	  ,CC.COST_TYPE
			--	  ,A.POS_GRD_CD
			--	  ,A.EMP_NO
			--	  ,A.EMP_NM
			--	  ,A.COST_CD
			--	  ,CASE WHEN A.INS_TYPE_CD='10' THEN AC.INS_DB_ACNT_CD
			--			WHEN A.INS_TYPE_CD='20' THEN AC.INS_DC_ACNT_CD
			--			ELSE AC.INS_NO_ACNT_CD END AS ACNT_CD -- 
			--	  ,CASE WHEN A.INS_TYPE_CD='10' THEN AC.INS_DB_REL_CD
			--			WHEN A.INS_TYPE_CD='20' THEN AC.INS_DC_REL_CD
			--			ELSE AC.INS_NO_REL_CD END AS REL_CD -- 
			--	  ,A.AMT_NEW_RETR_PAY
			--	  ,AC.DBCR_CD
   --               ,A.PAY_GROUP
			--	  , AC.REP_BILL_TYPE_CD BILL_TYPE_CD
			--	  ,A.ORG_CD
			--	  ,A.INS_TYPE_YN
			--	  ,A.INS_TYPE_CD
   --               ,A.ACNT_TYPE_CD
			--	  FROM #TEMP_HUMAN A
			--	  JOIN ORM_COST CC
			--	    ON A.COMPANY_CD = CC.COMPANY_CD
			--	   AND A.COST_CD = CC.COST_CD
			--	   AND @ad_std_date BETWEEN CC.STA_YMD AND CC.END_YMD
			--	  JOIN REP_ACNT_MNG AC
			--	    ON A.COMPANY_CD = AC.COMPANY_CD
			--	   AND CC.ACCT_CD = AC.PAY_ACNT_TYPE_CD
			--	   AND AC.REP_BILL_TYPE_CD = @v_acct_type
			--	   AND @ad_std_date BETWEEN AC.STA_YMD AND AC.END_YMD
			--	 WHERE A.AMT_NEW_RETR_PAY <> 0

		DECLARE PER_CUR	CURSOR	FOR
			SELECT A.COMPANY_CD
				  ,CC.COST_TYPE
				  ,A.POS_GRD_CD
				  ,A.EMP_NO
				  ,A.EMP_NM
				  ,A.COST_CD
				  ,CASE WHEN A.INS_TYPE_CD='10' THEN AC.INS_DB_ACNT_CD
						WHEN A.INS_TYPE_CD='20' THEN AC.INS_DC_ACNT_CD
						ELSE AC.INS_NO_ACNT_CD END AS ACNT_CD -- 
				  ,CASE WHEN A.INS_TYPE_CD='10' THEN AC.INS_DB_REL_CD
						WHEN A.INS_TYPE_CD='20' THEN AC.INS_DC_REL_CD
						ELSE AC.INS_NO_REL_CD END AS REL_CD -- 
				  ,A.AMT_NEW_RETR_PAY
				  ,AC.DBCR_CD
                  ,A.PAY_GROUP
				  --, AC.REP_BILL_TYPE_CD BILL_TYPE_CD
				  --,A.ORG_CD
				  --,A.INS_TYPE_YN
				  --,A.INS_TYPE_CD
      --            ,A.ACNT_TYPE_CD
				  FROM #TEMP_HUMAN A
				  JOIN ORM_COST CC
				    ON A.COMPANY_CD = CC.COMPANY_CD
				   AND A.COST_CD = CC.COST_CD
				   AND @ad_std_date BETWEEN CC.STA_YMD AND CC.END_YMD
				  JOIN REP_ACNT_MNG AC
				    ON A.COMPANY_CD = AC.COMPANY_CD
				   AND CC.ACCT_CD = AC.PAY_ACNT_TYPE_CD
				   AND AC.REP_BILL_TYPE_CD = @v_acct_type
				   AND @ad_std_date BETWEEN AC.STA_YMD AND AC.END_YMD
				 WHERE A.AMT_NEW_RETR_PAY <> 0
		OPEN PER_CUR
		WHILE 1=1
		BEGIN
			FETCH NEXT FROM PER_CUR INTO @v_company_code, @v_cost_type, @v_pos_grd_cd, @v_emp_no, @v_emp_nm,
										@v_cost_cd, @v_acnt_cd, @v_rel_cd, @v_amt_new_retr_pay, @v_dbcr_cd,
										@v_pay_group
			IF @@FETCH_STATUS <> 0 BREAK
			SET @n_seqno_s = @n_seqno_s + 1
            BEGIN TRY
                INSERT INTO H_IF_SAPINTERFACE ( CD_COMPANY        -- 회사코드
                                              , MANDT_S           -- 서버정보
                                              , GSBER_S           -- 귀속부서
                                              , LIFNR_S           -- 구매처코드
                                              , ZPOSN_S           -- 직위
                                              , SEQNO_S           -- 문서순서
                                              , DRAW_DATE         -- 이관일자
                                              , SNO               -- 사번
                                              , SNM               -- 사원명
                                              , COST_CENTER       -- 코스트센터
                                              , SAP_ACCTCODE      -- 회계계정
                                              , AMT               -- 금액
                                              , DBCR_GU           -- 차대구분
                                              , SEQ               -- 순번
                                              , ACCT_TYPE         -- 이관구분
                                              , FLAG              -- FLAG
                                              , PAY_YM            -- 급여년월
                                              , PAY_DATE          -- 지급일자
                                              , PAY_SUPP          -- 지급구분
                                              , ITEM_CODE         -- 지급항목
                                              , PAYGP_CODE        -- 급여그룹
                                              , IFC_SORT          -- 원천구분
                                              , SLIP_DATE         -- 품의일자
                                              , REMARK            -- 비고
                                              , ID_INSERT         -- 입력자
                                              , DT_INSERT         -- 입력일
                                              , ID_UPDATE         -- 수정자
                                              , DT_UPDATE         -- 수정일
                                              , XNEGP             -- -지시자
                                              , ACCNT_CD          -- 상대계정
                                              , SEQ_H             -- 전표번호
                                              , GUBUN
                                              , COMPANY_CD        -- EHR회사코드
                                              , PAY_TYPE_CD       -- 지급구분
                                              , PAY_ACNT_TYPE_CD  -- 계정분류
                                              , PAY_ITEM_NM       -- 급여항목명
                                     ) VALUES (
                                                @v_company_code      -- CD_COMPANY(회사코드)
                                              , NULL                 -- MANDT_S(서버정보)
                                              , @v_cost_type         -- GSBER_S(귀속부서)
                                              , NULL                 -- LIFNR_S(구매처코드)
                                              , @v_pos_grd_cd        -- ZPOSN_S(직위)
                                              , dbo.XF_LPAD(@n_seqno_s, 10, '0')          -- SEQNO_S(문서순서)
                                              , @v_dt_dian           -- DRAW_DATE(이관일자)
                                              , @v_emp_no			 -- SNO(사번)
                                              , @v_emp_nm            -- SNM(사원명)
                                              , dbo.XF_LPAD(@v_cost_cd, 10, '0')		-- COST_CENTER(코스트센터)
                                              , dbo.XF_LPAD(@v_acnt_cd, 10, '0')        -- SAP_ACCTCODE(회계계정)
                                              , @v_amt_new_retr_pay  -- AMT(금액)
                                              , @v_dbcr_cd			 -- DBCR_GU(차대구분)
                                              , @v_seq               -- SEQ(순번)
                                              , @v_acct_type         -- ACCT_TYPE(이관구분)
                                              , 'N'                  -- FLAG(FLAG)
                                              , @v_dt_gian           -- PAY_YM(급여년월)
                                              , @v_dt_dian           -- PAY_DATE(지급일자)
                                              , '퇴직충당금'           -- PAY_SUPP(지급구분)
                                              , ''				     -- ITEM_CODE(지급항목)
                                              , @v_pay_group		 -- PAYGP_CODE(급여그룹)
                                              , @v_ifc_sort          -- IFC_SORT(원천구분)
                                              , @v_dt_dian           -- SLIP_DATE(품의일자)
                                              , '퇴직충당금(' + @v_acct_type + ')'   -- REMARK(비고)
                                              , @an_mod_user_id      -- ID_INSERT(입력자)
                                              , GETDATE()            -- DT_INSERT(입력일)
                                              , @an_mod_user_id      -- ID_UPDATE(수정자)
                                              , GETDATE()            -- DT_UPDATE(수정일)
                                              , ''                 -- XNEGP(-지시자)
                                              , dbo.XF_LPAD(@v_rel_cd, 10, '0')  -- ACCNT_CD(상대계정)
                                              , @v_seq_h             -- SEQ_H(전표번호)
                                              , NULL                 -- GUBUN
                                              , @av_company_cd       -- COMPANY_CD(EHR회사코드)
                                              , ''     -- PAY_TYPE_CD(지급구분)
                                              , @v_acct_type         -- PAY_ACNT_TYPE_CD(계정분류)
                                              , '퇴직충당금'     -- PAY_ITEM_NM(급여항목명)
                                              )

            END TRY
            BEGIN CATCH
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG(@v_emp_no + '[' + @v_emp_nm + ']전표생성 중 에러발생[ERR]', @v_program_id,  0060, ERROR_MESSAGE(), @an_mod_user_id)
                IF @@TRANCOUNT > 0
                    ROLLBACK
                RETURN
            END CATCH
		END -- End Of Cursor
		CLOSE	PER_CUR
		DEALLOCATE	PER_CUR
--=========================================================================================
-- 상대계정 생성(집계)
--=========================================================================================
        BEGIN TRY
            INSERT INTO H_IF_SAPINTERFACE (   CD_COMPANY           -- 회사코드
                                            , MANDT_S              -- 서버정보
                                            , GSBER_S              -- 귀속부서
                                            , LIFNR_S              -- 구매처코드
                                            , ZPOSN_S              -- 직위
                                            , SEQNO_S              -- 문서순서
                                            , DRAW_DATE            -- 이관일자
                                            , SNO                  -- 사번
                                            , SNM                  -- 사원명
                                            , COST_CENTER          -- 코스트센터
                                            , SAP_ACCTCODE         -- 회계계정
                                            , AMT                  -- 금액
                                            , DBCR_GU              -- 차대구분
                                            , SEQ                  -- 순번
                                            , ACCT_TYPE            -- 이관구분
                                            , FLAG                 -- FLAG
                                            , PAY_YM               -- 급여년월
                                            , PAY_DATE             -- 지급일자
                                            , PAY_SUPP             -- 지급구분
                                            , ITEM_CODE            -- 지급항목
                                            , PAYGP_CODE           -- 급여그룹
                                            , IFC_SORT             -- 원천구분
                                            , SLIP_DATE            -- 품의일자
                                            , REMARK               -- 비고
                                            , ID_INSERT            -- 입력자
                                            , DT_INSERT            -- 입력일
                                            , ID_UPDATE            -- 수정자
                                            , DT_UPDATE            -- 수정일
                                            , XNEGP                -- -지시자
                                            , ACCNT_CD             -- 상대계정
                                            , SEQ_H                -- 전표번호
                                            , GUBUN			     
                                            , COMPANY_CD           -- EHR회사코드
                                            , PAY_TYPE_CD          -- 지급구분
                                              , PAY_ACNT_TYPE_CD  -- 계정분류
                                            , PAY_ITEM_NM          -- 급여항목명
                                            )
                                       SELECT @v_company_code      -- CD_COMPANY(회사코드)
                                            , NULL                 -- MANDT_S(서버정보)
                                            , GSBER_S              -- @v_ifc_sort          -- GSBER_S(귀속부서)
                                            , NULL                 -- LIFNR_S(구매처코드)
                                            , ''                 -- ZPOSN_S(직위)
                                            , dbo.XF_LPAD(RANK() OVER(ORDER BY ACCNT_CD, GSBER_S) + @n_seqno_s, 10, '0')
                                            , DRAW_DATE            -- DRAW_DATE(이관일자)
                                            , ''            -- SNO(사번)
                                            , ''                   -- SNM(사원명)
                                            , ''           -- COST_CENTER(코스트센터)
                                            , ACCNT_CD       -- SAP_ACCTCODE(회계계정)
                                            , SUM(CASE WHEN DBCR_GU = '40' THEN AMT ELSE -AMT END)         -- AMT(금액)
                                            , '50'           -- DBCR_GU(차대구분)
                                            , SEQ                  -- SEQ(순번)
                                            , ACCT_TYPE            -- ACCT_TYPE(이관구분)
                                            , 'N'                  -- FLAG(FLAG)
                                            , MAX(PAY_YM)          -- PAY_YM(급여년월)
                                            , MAX(PAY_DATE)        -- PAY_DATE(지급일자)
                                              , '퇴직충당금'           -- PAY_SUPP(지급구분)
                                            , ''             -- ITEM_CODE(지급항목)
                                            , PAYGP_CODE               -- PAYGP_CODE(급여그룹)
                                            , @v_ifc_sort          -- IFC_SORT(원천구분)
                                            , DRAW_DATE                 -- SLIP_DATE(품의일자)
                                            , '퇴직충당금(' + @v_acct_type + ')집계'        -- REMARK(비고)
                                            , @an_mod_user_id      -- ID_INSERT(입력자)
                                            , GETDATE()            -- DT_INSERT(입력일)
                                            , @an_mod_user_id      -- ID_UPDATE(수정자)
                                            , GETDATE()            -- DT_UPDATE(수정일)
                                            , ''                 -- XNEGP(-지시자)
                                            , ''                 -- ACCNT_CD(상대계정)
                                            , @v_seq_h             -- SEQ_H(전표번호)
                                            , NULL                 -- GUBUN
                                            , @av_company_cd       -- COMPANY_CD(EHR회사코드)
                                              , ''     -- PAY_TYPE_CD(지급구분)
                                              , @v_acct_type         -- PAY_ACNT_TYPE_CD(계정분류)
                                              , '퇴직충당금'     -- PAY_ITEM_NM(급여항목명)
                                         FROM H_IF_SAPINTERFACE
                                        WHERE CD_COMPANY  = @v_company_code
                                          AND ACCT_TYPE   = @v_acct_type
                                          AND DRAW_DATE    = @v_dt_dian
										  AND (ISNULL(@av_pay_group,'')='' OR PAYGP_CODE = @av_pay_group)
                                        GROUP BY CD_COMPANY, DRAW_DATE, SEQ, PAYGP_CODE, ACCT_TYPE, ACCNT_CD, GSBER_S

        END TRY
        BEGIN CATCH
            SET @av_ret_code = 'FAILURE!'
            SET @av_ret_message = DBO.F_FRM_ERRMSG('차액 총액 전표생성 중 에러발생[ERR]', @v_program_id,  0090, ERROR_MESSAGE(), @an_mod_user_id)
            IF @@TRANCOUNT > 0
                ROLLBACK
            RETURN
        END CATCH
	END
  -----------------------------------------------------------------------------------------------------------------------
  -- END Message Setting Block 
  ----------------------------------------------------------------------------------------------------------------------- 

  --SELECT *
  --FROM H_IF_SAPINTERFACE
		--		WHERE CD_COMPANY = @av_company_cd
		--		  AND DRAW_DATE = @v_dt_dian					-- 이관일자		
		--		  AND ACCT_TYPE = @v_acct_type
  --                AND (ISNULL(@av_pay_group,'')='' OR PAYGP_CODE = @av_pay_group)

PRINT('<<===== P_REP_APP_SAIP_INTERFACE END')   
   -- ***********************************************************   
   -- 작업 완료   
   -- ***********************************************************   
--SELECT dbo.F_FRM_CODE_NM( A.COMPANY_CD, @av_locale_cd, 'PHM_POS_GRD_CD', A.POS_GRD_CD, dbo.XF_SYSDATE(0), '1') AS POS_GRD_NM, -- 직급
--	A.*
--  FROM #TEMP_HUMAN A
-- WHERE A.AMT_NEW_RETR_PAY <> 0
--   AND EMP_NO IN (SELECT EMP_NO
--			  FROM #TEMP_HUMAN
--			 WHERE AMT_NEW_RETR_PAY <> 0
--			EXCEPT
--			SELECT A.EMP_NO
--				  FROM #TEMP_HUMAN A
--				  JOIN ORM_COST CC
--				    ON A.COMPANY_CD = CC.COMPANY_CD
--				   AND A.COST_CD = CC.COST_CD
--				   AND @ad_std_date BETWEEN CC.STA_YMD AND CC.END_YMD
--				  JOIN REP_ACNT_MNG AC
--				    ON A.COMPANY_CD = AC.COMPANY_CD
--				   AND CC.ACCT_CD = AC.PAY_ACNT_TYPE_CD
--				   AND AC.REP_BILL_TYPE_CD = 'E012'
--				   AND @ad_std_date BETWEEN AC.STA_YMD AND AC.END_YMD
--				 WHERE A.AMT_NEW_RETR_PAY <> 0)
--ORDER BY EMP_NO

    SET @av_ret_code    = 'SUCCESS!'   
    SET @av_ret_message = dbo.F_FRM_ERRMSG('퇴직충당금 분개처리가 완료되었습니다[ERR]', @v_program_id, 9999, null, @an_mod_user_id)   
	RETURN
  ERR_HANDLER:
  
--SELECT * FROM #TEMP_HUMAN
	DEALLOCATE	PER_CUR
--	DROP TABLE #TEMP_HUMAN
	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;

    SET @av_ret_code    = 'FAILURE!'   
    SET @av_ret_message = dbo.F_FRM_ERRMSG(@v_error_message, @v_program_id, 9999, null, @an_mod_user_id)

	RETURN
END

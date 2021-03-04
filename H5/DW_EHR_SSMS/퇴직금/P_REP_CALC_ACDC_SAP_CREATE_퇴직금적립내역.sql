SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_REP_CALC_ACDC_SAP_CREATE] (
		@av_company_cd			nvarchar(10),		-- 회사코드
		@av_locale_cd			nvarchar(10),		-- 지역코드   
		@ad_pay_ymd				DATE,				-- 기준일자
		@an_pay_group_id		NUMERIC(38),		-- 급여그룹
		@an_mod_user_id         NUMERIC(38),		-- 변경자 사번
		@av_ret_code            NVARCHAR(4000)    OUTPUT, -- 결과코드   
		@av_ret_message         NVARCHAR(4000)    OUTPUT  -- 결과메시지   
    ) AS   
   
    -- ***************************************************************************   
    --   TITLE       : 퇴직금적립내역(DC) 분개처리
    --   PROJECT     : E-HR 시스템   
    --   AUTHOR      :   
    --   PROGRAM_ID  : P_REP_CALC_ACDC_SAP_CREATE   
    --   RETURN      : 1) SUCCESS!/FAILURE!   
    --                 2) 결과 메시지   
    --   COMMENT     : 퇴직금적립내역    
    --   HISTORY     : 
    -- ***************************************************************************   
   
BEGIN
-- 임시 테이블 생성(퇴직추계액 내역 저장)
DECLARE @TEMP_HUMAN TABLE(
	COMPANY_CD [nvarchar](10) NULL,					--* 회사코드
	--REP_CALC_LIST_ID [numeric](38) NULL,			--* 퇴직금ID
	--ORG_CD [nvarchar](10) NULL,						--* 부서코드
	--EMP_NO [nvarchar](10) NULL,						--* 사번
	--EMP_NM [nvarchar](20) NULL,						--* 성명
	--POS_GRD_CD  [nvarchar](10) NULL,				--* 직급
	--INS_TYPE_YN [nvarchar](2) NULL,					--* 연금가입여부
	--INS_TYPE_CD [nvarchar](10) NULL,				--* 연금종류
	C_01 [numeric](18,0) NULL,					--* 퇴직금
	R01_S [numeric](18,0) NULL,					--* 퇴직급여액
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
	@d_std_date					DATE,				-- 전표일자
	@v_company_code				NVARCHAR(20),		-- 회사코드
	@v_cost_type				NVARCHAR(20),		-- 코스트센터 사업부분 ORM_COST.COST_TYPE
	@v_pos_grd_cd				NVARCHAR(20),		-- 직위코드
    @n_seqno_s                  INT = 0,			-- 문서순서
	@v_dt_dian					NVARCHAR(08),		-- 이관일자
	@v_dt_gian					NVARCHAR(06),		-- 기준월
	--@v_emp_no					NVARCHAR(20),		-- 사번
	--@v_emp_nm					NVARCHAR(20),		-- 사원명
	@v_cost_cd					NVARCHAR(20),		-- 코스트센터 코드 ORM_COST.COST_CD
	@v_acnt_cd					NVARCHAR(20),		-- 계정코드
	@v_stax_acnt_cd				NVARCHAR(20),		-- 계정코드-소득세
	@v_jtax_acnt_cd				NVARCHAR(20),		-- 계정코드-주민세
	@v_rel_cd					NVARCHAR(20),		-- 상대계정
	@v_tmp_acnt_cd				NVARCHAR(20),		-- 미지급금계정
	@n_c_01						NUMERIC(18),		-- 퇴직금
	@n_r01_s					NUMERIC(18),		-- 퇴직급여액
	@n_tmp_amt					NUMERIC(18),
	@v_dbcr_cd					NVARCHAR(20),		-- 차대구분
    @v_seq                      NVARCHAR(10),			-- 생성순번
    @v_seq_h                    NVARCHAR(20),			-- 전표번호
    @v_acct_type                NVARCHAR(20) = 'E013',	-- 임시 이관구분 - 퇴직금적립내역
    @v_pay_group                NVARCHAR(20),			-- 급여그룹
    @v_ifc_sort                 NVARCHAR(20),			-- 원천구분
	@v_filldt					NVARCHAR(8),
	@n_fillno					NUMERIC(18),
	@n_auto_yn					NVARCHAR(10),
	@d_auto_ymd					DATE,
	@n_auto_no					NUMERIC(18),
	@n_cnt						INT,

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
    SET @v_program_id    = 'P_REP_CALC_ACDC_SAP_CREATE'   -- 현재 프로시져의 영문명   
    SET @v_program_nm    = '퇴직금 분개처리'        -- 현재 프로시져의 한글문명   
    SET @av_ret_code     = 'SUCCESS!'   
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)   
--PRINT('시작 ===> ')

	--//***************************************************************************
	--//*****************		 퇴직금적립내역(DC) 분개 처리				 **************
	--//***************************************************************************
	SELECT TOP 1 @d_std_date = @ad_pay_ymd --GETDATE()
	     , @v_filldt = FILLDT
		 , @n_fillno = FILLNO
		 , @n_auto_yn = AUTO_YN
		 , @d_auto_ymd = AUTO_YMD
		 , @n_auto_no = AUTO_NO
	  FROM REP_CALC_LIST A
	 WHERE A.COMPANY_CD = @av_company_cd
	   AND A.PAY_YMD =  @ad_pay_ymd
	   AND A.CALC_TYPE_CD = '03' -- 퇴직금추계
	   AND A.INS_TYPE_CD  = '20'  -- DC

	/* 파라메터를 로컬변수로 처리하며 이때 NULL일 경우에 필요한 처리를 한다. */
	SET @v_dt_dian		= dbo.XF_TO_CHAR_D(@d_std_date, 'yyyyMMdd')
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

	BEGIN
		-- SAP I/F 테이블 삭제
		DELETE FROM H_IF_SAPINTERFACE
		WHERE CD_COMPANY = @av_company_cd
			AND DRAW_DATE = @v_filldt					-- 이관일자
			AND SEQ = @n_fillno
			AND ACCT_TYPE = @v_acct_type
			AND ISNULL(FLAG,'N') = 'N'
		--------------------------------------------------------------------------------------------------------------------
		-- Message Setting Block 
		--------------------------------------------------------------------------------------------------------------------
		IF @@error <> 0
			BEGIN
				SET @v_error_number = @@error;
				SET @v_error_code = 'P_REP_CALC_ACDC_CREATE';
				SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 내역 삭제 중 오류가 발생하였습니다.'
				GOTO ERR_HANDLER
			END
		-- 급여그룹 조건 가져오기
		----------------------------------
		-- 퇴직추계액 내역, 임시테이블에 생성
		----------------------------------
		INSERT INTO @TEMP_HUMAN
			(COMPANY_CD, -- REP_CALC_LIST_ID, ORG_CD, EMP_NO, EMP_NM,
			 -- POS_GRD_CD, INS_TYPE_YN, INS_TYPE_CD,
			 C_01, R01_S,
			 ACNT_TYPE_CD,
			 COST_CD)
		SELECT A.COMPANY_CD,-- A.REP_CALC_LIST_ID,
				--dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', A.PAY_YMD, '10') AS ORG_CD,
				--EMP.EMP_NO, EMP.EMP_NM,
				--A.POS_GRD_CD, A.INS_TYPE_YN, ISNULL(A.INS_TYPE_CD,'00'),
				SUM(A.C_01) AS C_01,
				SUM(A.R01_S) AS R01_S,
				@v_acct_type,
				dbo.F_PAY_GET_COST( @av_company_cd, A.EMP_ID, A.ORG_ID, @d_std_date, '1') AS COST_CD -- 코스트센터
		  FROM REP_CALC_LIST A
		  INNER JOIN VI_FRM_PHM_EMP EMP
				  ON A.EMP_ID = EMP.EMP_ID AND EMP.LOCALE_CD = @av_locale_cd
				 AND A.CALC_TYPE_CD IN ('03')
		 WHERE A.COMPANY_CD = @av_company_cd
		   AND A.PAY_YMD =  @ad_pay_ymd
		   AND A.CALC_TYPE_CD = '03' -- 퇴직금추계
		   AND A.INS_TYPE_CD  = '20'
		 GROUP BY A.COMPANY_CD, dbo.F_PAY_GET_COST( @av_company_cd, A.EMP_ID, A.ORG_ID, @d_std_date, '1')
		 IF @@ROWCOUNT <= 0
			BEGIN
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('전표생성 중 에러발생[ERR]대상건이 없습니다.', @v_program_id,  0060, ERROR_MESSAGE(), @an_mod_user_id)
                IF @@TRANCOUNT > 0
                    ROLLBACK
                RETURN
			END
		 --print '퇴직금전표커서 전'
		----------------------------------
		-- 퇴직금적립내역전표
		----------------------------------
		DECLARE PER_CUR	CURSOR	FOR
			SELECT A.COMPANY_CD
				  ,CC.COST_TYPE
				  ,A.COST_CD
				  ,AC.INS_DC_ACNT_CD AS ACNT_CD -- 
				  ,AC.INS_DC_REL_CD AS REL_CD -- 
				  ,A.C_01, A.R01_S
				  ,AC.DBCR_CD
				  ,AC.STAX_ACNT_CD
				  ,AC.JTAX_ACNT_CD
				  ,AC.TMP_ACNT_CD
				  FROM @TEMP_HUMAN A
				  left outer JOIN ORM_COST CC
				    ON A.COMPANY_CD = CC.COMPANY_CD
				   AND A.COST_CD = CC.COST_CD
				   AND @d_std_date BETWEEN CC.STA_YMD AND CC.END_YMD
				  left outer JOIN REP_ACNT_MNG AC
				    ON A.COMPANY_CD = AC.COMPANY_CD
				   AND CC.ACCT_CD = AC.PAY_ACNT_TYPE_CD
				   AND AC.REP_BILL_TYPE_CD = @v_acct_type
				   AND @d_std_date BETWEEN AC.STA_YMD AND AC.END_YMD
		OPEN PER_CUR
		WHILE 1=1
		BEGIN
			FETCH NEXT FROM PER_CUR INTO @v_company_code, @v_cost_type,
										@v_cost_cd, @v_acnt_cd, @v_rel_cd,
										@n_c_01, @n_r01_s,
										@v_dbcr_cd, @v_stax_acnt_cd, @v_jtax_acnt_cd, @v_tmp_acnt_cd
			IF @@FETCH_STATUS <> 0 BREAK
			SET @n_seqno_s = @n_seqno_s + 1
			--print 'n_seqno_s:' + convert(varchar(10), @n_seqno_s) + ':' + @v_cost_cd
            BEGIN TRY
				-- 퇴직금금액(DC적립)
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
                                              , ''--@v_emp_no			 -- SNO(사번)
                                              , ''--@v_emp_nm            -- SNM(사원명)
                                              , @v_cost_cd--dbo.XF_LPAD(@v_cost_cd, 10, '0')		-- COST_CENTER(코스트센터)
                                              , @v_acnt_cd--dbo.XF_LPAD(@v_acnt_cd, 10, '0')        -- SAP_ACCTCODE(회계계정)
                                              , @n_c_01				 -- AMT(금액)
                                              , @v_dbcr_cd			 -- DBCR_GU(차대구분)
                                              , @v_seq               -- SEQ(순번)
                                              , @v_acct_type         -- ACCT_TYPE(이관구분)
                                              , 'N'                  -- FLAG(FLAG)
                                              , @v_dt_gian           -- PAY_YM(급여년월)
                                              , @v_dt_dian           -- PAY_DATE(지급일자)
                                              , '퇴직금적립DC'           -- PAY_SUPP(지급구분)
                                              , ''				     -- ITEM_CODE(지급항목)
                                              , @v_pay_group		 -- PAYGP_CODE(급여그룹)
                                              , @v_ifc_sort          -- IFC_SORT(원천구분)
                                              , NULL           -- SLIP_DATE(품의일자)
                                              , '퇴직금적립DC(' + @v_acct_type + ')'   -- REMARK(비고)
                                              , @an_mod_user_id      -- ID_INSERT(입력자)
                                              , GETDATE()            -- DT_INSERT(입력일)
                                              , @an_mod_user_id      -- ID_UPDATE(수정자)
                                              , GETDATE()            -- DT_UPDATE(수정일)
                                              , ''                 -- XNEGP(-지시자)
                                              , ''--dbo.XF_LPAD(@v_rel_cd, 10, '0')  -- ACCNT_CD(상대계정)
                                              , @v_seq_h             -- SEQ_H(전표번호)
                                              , NULL                 -- GUBUN
                                              , @av_company_cd       -- COMPANY_CD(EHR회사코드)
                                              , ''     -- PAY_TYPE_CD(지급구분)
                                              , @v_acct_type         -- PAY_ACNT_TYPE_CD(계정분류)
                                              , '퇴직금'     -- PAY_ITEM_NM(급여항목명)
                                              )
				-- 퇴직금금액(DC적립-상대)
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
                                              , dbo.XF_LPAD(@n_seqno_s + 10000, 10, '0')          -- SEQNO_S(문서순서)
                                              , @v_dt_dian           -- DRAW_DATE(이관일자)
                                              , ''--@v_emp_no			 -- SNO(사번)
                                              , ''--@v_emp_nm            -- SNM(사원명)
                                              , @v_cost_cd--dbo.XF_LPAD(@v_cost_cd, 10, '0')		-- COST_CENTER(코스트센터)
                                              , @v_rel_cd--dbo.XF_LPAD(@v_acnt_cd, 10, '0')        -- SAP_ACCTCODE(회계계정)
                                              , @n_c_01				 -- AMT(금액)
                                              , CASE WHEN @v_dbcr_cd = '40' THEN '50'
											         WHEN @v_dbcr_cd = '50' THEN '40'
													 ELSE '' END -- DBCR_GU(차대구분)
                                              , @v_seq               -- SEQ(순번)
                                              , @v_acct_type         -- ACCT_TYPE(이관구분)
                                              , 'N'                  -- FLAG(FLAG)
                                              , @v_dt_gian           -- PAY_YM(급여년월)
                                              , @v_dt_dian           -- PAY_DATE(지급일자)
                                              , '퇴직금적립DC'           -- PAY_SUPP(지급구분)
                                              , ''				     -- ITEM_CODE(지급항목)
                                              , @v_pay_group		 -- PAYGP_CODE(급여그룹)
                                              , @v_ifc_sort          -- IFC_SORT(원천구분)
                                              , NULL           -- SLIP_DATE(품의일자)
                                              , '퇴직금적립DC(' + @v_acct_type + ')'   -- REMARK(비고)
                                              , @an_mod_user_id      -- ID_INSERT(입력자)
                                              , GETDATE()            -- DT_INSERT(입력일)
                                              , @an_mod_user_id      -- ID_UPDATE(수정자)
                                              , GETDATE()            -- DT_UPDATE(수정일)
                                              , ''                 -- XNEGP(-지시자)
                                              , ''--dbo.XF_LPAD(@v_rel_cd, 10, '0')  -- ACCNT_CD(상대계정)
                                              , @v_seq_h             -- SEQ_H(전표번호)
                                              , NULL                 -- GUBUN
                                              , @av_company_cd       -- COMPANY_CD(EHR회사코드)
                                              , ''     -- PAY_TYPE_CD(지급구분)
                                              , @v_acct_type         -- PAY_ACNT_TYPE_CD(계정분류)
                                              , '퇴직금'     -- PAY_ITEM_NM(급여항목명)
                                              )
            END TRY
            BEGIN CATCH
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('전표생성 중 에러발생[ERR]', @v_program_id,  0060, ERROR_MESSAGE(), @an_mod_user_id)
                IF @@TRANCOUNT > 0
                    ROLLBACK
                RETURN
            END CATCH
		END -- End Of Cursor
		CLOSE	PER_CUR
		DEALLOCATE	PER_CUR
		IF @n_seqno_s < 1
			BEGIN
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('전표생성 중 에러발생[ERR] 처리건이없습니다.', @v_program_id,  0060, ERROR_MESSAGE(), @an_mod_user_id)
                IF @@TRANCOUNT > 0
                    ROLLBACK
                RETURN
			END
					UPDATE A
					   SET FILLDT = FORMAT(@d_std_date, 'yyyyMMdd')
					     , FILLNO = @v_seq
						 , AUTO_YN = 'Y'
						 , AUTO_YMD = @d_std_date
						 , AUTO_NO = @v_seq
					  FROM REP_CALC_LIST A
					 WHERE A.COMPANY_CD = @av_company_cd
					   AND A.PAY_YMD =  @ad_pay_ymd
					   AND A.CALC_TYPE_CD = '03' -- 퇴직금추계
					   AND A.INS_TYPE_CD  = '20'
	END
  -----------------------------------------------------------------------------------------------------------------------
  -- END Message Setting Block 
  ----------------------------------------------------------------------------------------------------------------------- 

--PRINT('<<===== P_REP_CALC_ACDC_SAP_CREATE END')   
   -- ***********************************************************   
   -- 작업 완료   
   -- ***********************************************************   

    SET @av_ret_code    = 'SUCCESS!'   
    SET @av_ret_message = dbo.F_FRM_ERRMSG('퇴직금 분개처리가 완료되었습니다[ERR]' + dbo.XF_TO_CHAR_N(@n_seqno_s,NULL), @v_program_id, 9999, null, @an_mod_user_id)   
	RETURN
  ERR_HANDLER:
  
--SELECT * FROM @TEMP_HUMAN
	DEALLOCATE	PER_CUR
--	DROP TABLE @TEMP_HUMAN
	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;

    SET @av_ret_code    = 'FAILURE!'   
    SET @av_ret_message = dbo.F_FRM_ERRMSG(@v_error_message, @v_program_id, 9999, null, @an_mod_user_id)

	RETURN
END
GO



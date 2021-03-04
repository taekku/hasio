USE [dwehrdev]
GO
/****** Object:  StoredProcedure [dbo].[p_at_ret_sap_interface]    Script Date: 2020-11-30 오후 3:51:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Create date: <Create Date,,2010.01>
-- Description:	<Description,,퇴직금/퇴직정산 자동분개처리 >
-- =============================================
/* Execute Sample
DECLARE
   @p_error_code VARCHAR(30),
   @p_error_str VARCHAR(500)
BEGIN
   SET @p_error_code = '';
   SET @p_error_str = '';

   EXECUTE p_at_ret_sap_interface
			'KOR',                      -- @p_lang_code       VARCHAR(3)
			'1',                        -- @p_return_no       VARCHAR(1)
			'I',						-- @p_cd_compnay	회사코드
			'20100302',					-- @p_dt_gian기안일자
			'WISEN',					-- @p_id_user사용자ID
           @p_error_code OUTPUT,        -- @p_error_code      VARCHAR(30)
           @p_error_str  OUTPUT         -- @p_error_str       VARCHAR(500)

	-- SELECT * FROM H_ERRORLOG WITH (nolock)
	-- DELETE FROM H_ERRORLOG
	-- SELECT * FROM H_IF_AUTOSLIPM_TEMP
	-- SELECT * FROM H_IF_SAPINTERFACE WHERE CD_COMPANY = 'H' AND DRAW_DATE = '20091031' AND  IFC_SORT = 'H20004' AND SEQ = '260'
	-- SELECT * FROM H_IF_SAPINTERFACE WHERE CD_COMPANY = 'H' AND DRAW_DATE = '20091031' AND  IFC_SORT = 'H20004'
	-- SELECT * FROM H_IF_SAPINTERFACE WHERE CD_COMPANY = 'H' AND DRAW_DATE = '20091031' AND  IFC_SORT = 'H20003'
	-- SELECT * FROM H_IF_SAPINTERFACE WHERE CD_COMPANY = 'H' AND DRAW_DATE = '20091031' AND  IFC_SORT = 'H20002'
	-- SELECT * FROM H_IF_SAPINTERFACE WHERE CD_COMPANY = 'H' AND DRAW_DATE = '20091031' AND  IFC_SORT = 'H20001'
END


 DECLARE 
      @p_error_code VARCHAR(30), 
      @p_error_str VARCHAR(500) 
 BEGIN
      SET @p_error_code = ''; 
      SET @p_error_str = ''; 
      EXECUTE p_at_ret_sap_interface
      'KOR',                      -- @p_lang_code     VARCHAR(3) 
      '1',                        -- @p_return_no     VARCHAR(1) 
      'I',
      '20100304',
      'newikim',
      @p_error_code OUTPUT,		-- @p_error_code      VARCHAR(30) 
      @p_error_str OUTPUT 		-- @p_error_str       VARCHAR(500) 
 END

H_ERRORLOG

*/
ALTER PROCEDURE [dbo].[p_at_ret_sap_interface] (
         @p_lang_code       VARCHAR(3) = 'KOR',				-- LANGUAGE 초기값 : KOR.
         @p_return_no       VARCHAR(1) = '1',				-- 리턴 분기 번호
         @p_cd_compnay		 VARCHAR(10),						-- 회사코드
         @p_dt_gian		    VARCHAR(8) ,						-- 품의일자
         @p_id_user		    VARCHAR(20) ,						-- 사용자ID
         @p_error_code      VARCHAR(1000) OUTPUT,			-- 에러코드 리턴
         @p_error_str       VARCHAR(3000) OUTPUT			-- 에러메시지 리턴
         )                                                                              
AS
SET NOCOUNT ON
DECLARE
   /* 프로시저 내에서 사용할 변수 정의  */
	@v_cd_company				VARCHAR(10),										-- 회사코드
   @v_dt_gian					VARCHAR(8) ,										-- 급여년월 PK : 1
	@v_id_user					VARCHAR(20),										-- 사용자ID
	@v_draw_date				VARCHAR(8) ,										-- 이관일자
	@v_no_person				VARCHAR(10) ,
	@v_auto_date				VARCHAR(8) ,
	@v_auto_seq					NUMERIC(18,0),

	@v_account_source			VARCHAR(20) ,
	@v_auto_sno					VARCHAR(20) ,
	@v_dt_dian					VARCHAR(10) ,			-- 품의일자
	@v_seq						NUMERIC(18,0),			-- 순번 numeric
	@v_str_seq					VARCHAR(10),			-- 순번 varchar

	@v_cost_center				VARCHAR(20),
	@v_sap_acctcode				VARCHAR(20),
	@v_source_type				VARCHAR(20),
	@v_amt						NUMERIC(18,0),

	@v_dbcr_gu					VARCHAR(02),

	@v_pay_ym					VARCHAR(10),
	@v_pay_date					VARCHAR(10),
	@v_pay_supp					VARCHAR(20),

	@v_item_code				VARCHAR(20),
	@v_paygp_code				VARCHAR(10),
	
	@v_cd_accnt1				VARCHAR(10),
	@v_cd_accnt2				VARCHAR(10),
	@v_cd_accnt10				VARCHAR(10),
	@v_fg_person				VARCHAR(10),

	@v_sno						VARCHAR(10),
	@v_snm						VARCHAR(30),
	@v_acct_type				VARCHAR(10),
	@v_item_kind				VARCHAR(10),
	@v_ifc_sort					VARCHAR(10),
	@v_slip_nbr					VARCHAR(20),
	@v_cd_acctu					VARCHAR(10),
	@v_fg_accnt					VARCHAR(10),		--원가계정
	@v_cnt						NUMERIC(18,0),
	@v_rec_count				NUMERIC(18,0),

	/* 퇴직정산 */
	@v_s_no_person				VARCHAR(10),
	@v_s_nm_person				VARCHAR(30),
	@v_s_ym_pay					VARCHAR(30),		-- 퇴직월
	@v_s_dt_prov				VARCHAR(30),		-- 퇴직일자
	@v_s_fg_supp				VARCHAR(30),		-- (퇴직정산)
    @v_amt_new_tot				NUMERIC(18,0),		-- 미지급금(급여) total
	@v_amt_new_stax				NUMERIC(18,0),		-- 소득세예수금
	@v_amt_new_jtax				NUMERIC(18,0),		-- 주민세예수금
	@v_s_fg_accnt				VARCHAR(10),		-- 원가계정 51판관비
	@v_s_fg_drcr				VARCHAR(10),		-- 차/대
	@v_s_cd_accnt1				VARCHAR(10),		-- 발생코드1
    @v_s_cd_accnt2				VARCHAR(10),		-- 발생코드2
	@v_s_cd_accnt8				VARCHAR(10),		-- 소득세예수금코드
	@v_s_cd_accnt9				VARCHAR(10),		-- 주민세예수금코드
	@v_s_cd_accnt10				VARCHAR(10),		-- 상대계정코드	
	@v_cd_cost					VARCHAR(10),		-- 코스트코드

    @v_amt_retr_pay				NUMERIC(18,0),		-- 퇴직금 total
    @v_amt_real_pay_1			NUMERIC(18,0),		-- 미지급금(실지급액)

	@v_seq_h					VARCHAR(10),		-- SEQNO_S dp에 들어갈 값
    @v_gsbers					VARCHAR(20),		-- 사업부문
	@v_zposn_s					VARCHAR(10),		-- 직급
	
	@v_fg_retpension_kind		VARCHAR(2),

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



/* 기타공제용 변수 */
declare 
@NM_ETC01_SUB_TIT VARCHAR(60)
,@NM_ETC02_SUB_TIT VARCHAR(60)
,@NM_ETC03_SUB_TIT VARCHAR(60)
,@NM_ETC04_SUB_TIT VARCHAR(60)
,@NM_ETC05_SUB_TIT VARCHAR(60)
,@AMT_ETC01_SUB NUMERIC(18,0)
,@AMT_ETC02_SUB NUMERIC(18,0)
,@AMT_ETC03_SUB NUMERIC(18,0)
,@AMT_ETC04_SUB NUMERIC(18,0)
,@AMT_ETC05_SUB NUMERIC(18,0)
,@NM_ETC01_PROV_TIT VARCHAR(60)
,@NM_ETC02_PROV_TIT VARCHAR(60)
,@NM_ETC03_PROV_TIT VARCHAR(60)
,@AMT_ETC01_PROV NUMERIC(18,0)
,@AMT_ETC02_PROV NUMERIC(18,0)
,@AMT_ETC03_PROV NUMERIC(18,0)
,@_x1_cd_accnt1  VARCHAR(60)
,@_x1_cd_accnt2  VARCHAR(60)
,@_x1_cd_accnt10 VARCHAR(60)
,@_x2_cd_accnt1  VARCHAR(60)
,@_x2_cd_accnt2  VARCHAR(60)
,@_x2_cd_accnt10 VARCHAR(60)
,@_x3_cd_accnt1  VARCHAR(60)
,@_x3_cd_accnt2  VARCHAR(60)
,@_x3_cd_accnt10 VARCHAR(60)
,@_x4_cd_accnt1  VARCHAR(60)
,@_x4_cd_accnt2  VARCHAR(60)
,@_x4_cd_accnt10 VARCHAR(60)
,@_x5_cd_accnt1  VARCHAR(60)
,@_x5_cd_accnt2  VARCHAR(60)
,@_x5_cd_accnt10 VARCHAR(60)
,@_x1_fg_drcr varchar(8)
,@_x2_fg_drcr varchar(8)
,@_x3_fg_drcr varchar(8)
,@_x4_fg_drcr varchar(8)
,@_x5_fg_drcr varchar(8)
,@_y1_cd_accnt1  VARCHAR(60)
,@_y1_cd_accnt2  VARCHAR(60)
,@_y1_cd_accnt10 VARCHAR(60)
,@_y2_cd_accnt1  VARCHAR(60)
,@_y2_cd_accnt2  VARCHAR(60)
,@_y2_cd_accnt10 VARCHAR(60)
,@_y3_cd_accnt1  VARCHAR(60)
,@_y3_cd_accnt2  VARCHAR(60)
,@_y3_cd_accnt10 VARCHAR(60)
,@_y1_fg_drcr varchar(8)
,@_y2_fg_drcr varchar(8)
,@_y3_fg_drcr varchar(8)

BEGIN TRY
	/* 변수에 대한 초기화 처리 */
	SET @v_error_code = '';
	SET @v_error_note = '';

	/* 파라메터를 로컬변수로 처리하며 이때 NULL일 경우에 필요한 처리를 한다. */
	SET @v_cd_company   = @p_cd_compnay ;
	SET @v_dt_gian		= @p_dt_gian;
	SET @v_id_user		= @p_id_user;		--로그인사용자
	SET @v_rec_count	= 0;
	SET @v_cnt			= 0;
	SET @v_seq_h		= 0;
	-- 오류TABLE삭제
	DELETE FROM H_ERRORLOG
	WHERE CD_COMPANY = @v_cd_company
	AND ERROR_PROCEDURE = 'p_at_ret_sap_interface'
	--------------------------------------------------------------------------------------------------------------------
	-- 홈푸드 일때 [p_at_ret_sap_interface_H] 실행
	--------------------------------------------------------------------------------------------------------------------
	IF @p_cd_compnay = 'H'
	BEGIN
       	 EXEC dbo.p_at_ret_sap_interface_H 'KOR', '1', @p_cd_compnay, @p_dt_gian, @p_id_user,
         @p_error_code OUTPUT, @p_error_str OUTPUT
        RETURN		
	END
	else IF @p_cd_compnay = 'I'
	BEGIN
       	 EXEC dbo.p_at_ret_sap_interface_I 'KOR', '1', @p_cd_compnay, @p_dt_gian, @p_id_user,
         @p_error_code OUTPUT, @p_error_str OUTPUT
        RETURN		
	END
	--------------------------------------------------------------------------------------------------------------------
	-- Message Setting Block 
	--------------------------------------------------------------------------------------------------------------------      
	/* 에러 발생시 에러 핸들러로 분기 처리 */ 
	IF @@error <> 0
	BEGIN
		SET @v_error_number = @@error;
		SET @v_error_code = 'p_at_ret_sap_interface';
		SET @v_error_note = '오류TABLE삭제 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END

	/* select * from H_IF_AUTOSLIPM_TEMP TABLE */
--	SELECT @v_cnt = COUNT(CD_COMPANY)
--	FROM H_IF_AUTOSLIPM_TEMP WITH (NOLOCK)
--	WHERE CD_COMPANY = 'H'
--	AND ISNULL(APPR_DATE, '') <> ''
--	AND SOURCE_TYPE IN ('E017', 'E018')

	-------------------------------------------------------------------------------------------------------------------
	-- Message Setting Block 
	--------------------------------------------------------------------------------------------------------------------      
	/* 에러 발생시 에러 핸들러로 분기 처리 */ 
--	IF @@error <> 0
--	BEGIN
--		SET @v_error_number = @@error;
--		SET @v_error_code = 'p_at_ret_sap_interface';
--		SET @v_error_note = 'H_IF_AUTOSLIPM_TEMP TABLE 검색 중 오류가 발생하였습니다.'
--		GOTO ERR_HANDLER
--	END
--
--	IF @v_cnt > 0
--	BEGIN
--		SET @v_error_number = @@error;
--		SET @v_error_code = 'p_at_ret_sap_interface';
--		SET @v_error_note = '이미 전표 승인 되었습니다. 승인 취소 후 작업하십시요.'
--		GOTO ERR_HANDLER
--	END

--	/* SELECT * FROM H_IF_AUTOSLIPM_TEMP TABLE */
--	SELECT @v_cnt = COUNT(CD_COMPANY)
--	FROM H_IF_AUTOSLIPM_TEMP WITH (NOLOCK)
--	WHERE CD_COMPANY = @v_cd_company
--	AND ISNULL(APPR_DATE, '') = ''
--	AND SOURCE_TYPE IN ('E017', 'E018')
--	--------------------------------------------------------------------------------------------------------------------
--	-- Message Setting Block 
--	--------------------------------------------------------------------------------------------------------------------      
--	/* 에러 발생시 에러 핸들러로 분기 처리 */ 
--	IF @@error <> 0
--	BEGIN
--		SET @v_error_number = @@error;
--		SET @v_error_code = 'p_at_ret_sap_interface';
--		SET @v_error_note = 'H_IF_AUTOSLIPM_TEMP TABLE 검색 중 오류가 발생하였습니다.'
--		GOTO ERR_HANDLER
--	END
--
--	IF @v_cnt <= 0
--	BEGIN
--		SET @v_error_number = @@error;
--		SET @v_error_code = 'p_at_ret_sap_interface';
--		SET @v_error_note = '전표 처리 할 기초 자료가 없습니다.'
--		GOTO ERR_HANDLER
--	END

	--//***************************************************************************
	--//*****************		 퇴직정산	자동분개 처리			 **************
	--//***************************************************************************
	-- E018	퇴직정산
	BEGIN
	   -- 커서 생성 SELECT * FROM H_IF_AUTOSLIPM_TEMP
	   DECLARE	ACCNT_CUR_2	CURSOR	FOR
		SELECT M.CD_COMPANY, M.AUTO_DATE, AUTO_SEQ, SOURCE_TYPE, ACCOUNT_SOURCE, AUTO_SNO, DT_GIAN
		  FROM H_IF_AUTOSLIPM_TEMP M WITH (NOLOCK)
		 WHERE M.CD_COMPANY   = @v_cd_company
		   AND M.SOURCE_TYPE IN ('E018')
		 ORDER BY M.AUTO_DATE, M.AUTO_SEQ
		



		OPEN	ACCNT_CUR_2
		-- 커서 패치
		FETCH	NEXT	FROM	ACCNT_CUR_2	INTO	@v_cd_company,
													@v_auto_date,
													@v_auto_seq,
													@v_source_type,
													@v_account_source,
													@v_auto_sno,
													@v_dt_dian
		-- 항목 처리
		WHILE	@@fetch_status	=	0
		BEGIN

			
		-- 자료 삭제
		DELETE FROM H_IF_SAPINTERFACE
		 WHERE CD_COMPANY = @v_cd_company
		   AND DRAW_DATE  = @v_auto_date				-- 이관일자
		   AND SEQ        = @v_auto_seq						-- 순번(varchar)
		   AND ACCT_TYPE  = @v_source_type				-- 구분 E018퇴직정산

		--------------------------------------------------------------------------------------------------------------------
		-- Message Setting Block 
		--------------------------------------------------------------------------------------------------------------------      
		/* 에러 발생시 에러 핸들러로 분기 처리 */ 
		IF @@error <> 0
		BEGIN
			SET @v_error_number = @@error;
			SET @v_error_code = 'p_at_ret_sap_interface';
			SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 내역 삭제 중 오류가 발생하였습니다.'
			GOTO ERR_HANDLER
		END



		-- 퇴직정산 select * from H_IF_SAPINTERFACE
		IF @v_source_type = 'E018'
		BEGIN
			SELECT  @v_s_no_person  = m.NO_PERSON, 
					@v_s_nm_person  = h.NM_PERSON,
					--@v_zposn_s		= m.LVL_PAY1,		-- 직급
					@v_zposn_s		= m.cd_position,		-- 직급
				    @v_s_ym_pay     = m.YM_PAY,			-- 퇴직월
					@v_s_dt_prov    = m.DT_PROV,		-- 퇴직일자
					@v_s_fg_supp    = m.FG_SUPP,		-- (퇴직정산)
				    @v_amt_new_tot  = m.AMT_NEW_TOT,	-- 미지급금(급여) total
					@v_amt_new_stax = m.AMT_NEW_STAX,	-- 소득세예수금
					@v_amt_new_jtax = m.AMT_NEW_JTAX,	-- 주민세예수금
					@v_cd_cost		= RIGHT('0000000000' + m.CD_COST,10),		-- 코스트코드(10자리)
					@v_gsbers		= (select biz_acct from b_cost_center where cd_company = m.CD_COMPANY and cd_cc = m.CD_COST), -- 사업영역
				    @v_s_fg_accnt   = m.FG_ACCNT,		-- 원가계정 51판관비
					@v_s_fg_drcr	= n.FG_DRCR,		-- 차/대변
				    @v_s_cd_accnt1  = '00' + ISNULL(n.CD_ACCNT1,''),	-- 미지급금(급여)코드
					@v_s_cd_accnt8  = '00' + ISNULL(n.CD_ACCNT8,''),	-- 소득세예수금코드
					@v_s_cd_accnt9  = '00' + ISNULL(n.CD_ACCNT9,''),	-- 주민세예수금코드
					@v_s_cd_accnt10 = '00' + ISNULL(n.CD_ACCNT10,'')	-- 상대계정코드 -> 사용안함
			FROM
			( SELECT	a.CD_COMPANY,
						a.cd_position,
						a.LVL_PAY1, 
						a.NO_PERSON,
						LEFT(a.DT_RETR,6) AS YM_PAY,
						a.DT_RETR AS DT_PROV,
						'퇴직정산' AS FG_SUPP,
						-- 미지급금(급여)
						( a.AMT_NEW_STAX + a.AMT_NEW_JTAX ) AS AMT_NEW_TOT,
						-- 소득세
						a.AMT_NEW_STAX AS AMT_NEW_STAX,
						-- 주민세
						a.AMT_NEW_JTAX AS AMT_NEW_JTAX,
						ISNULL((SELECT CD_COST FROM H_PER_MATCH WITH(NOLOCK) WHERE CD_COMPANY = a.CD_COMPANY AND NO_PERSON = a.NO_PERSON ), '') AS CD_COST,
						ISNULL((SELECT TOP 1 FG_ACCT 
								  FROM B_COST_CENTER WITH(NOLOCK)
								 WHERE CD_COMPANY = a.CD_COMPANY 
								   AND CD_CC = ISNULL((SELECT CD_COST FROM H_PER_MATCH WITH(NOLOCK) WHERE CD_COMPANY = a.CD_COMPANY AND NO_PERSON = a.NO_PERSON ), '')
						), '') AS FG_ACCNT
				FROM H_ADJUSTMENT_DETAIL a WITH(NOLOCK) 
				WHERE a.CD_COMPANY = @v_cd_company
				AND a.DT_AUTO = @v_auto_date		-- 이관일자
				AND a.NO_AUTO = @v_auto_seq			-- 순번
			) m INNER JOIN H_HUMAN h ON ( m.CD_COMPANY = h.CD_COMPANY AND m.NO_PERSON = h.NO_PERSON )
				LEFT OUTER JOIN ( SELECT CD_COMPANY, TP_CODE, CD_ITEM, FG_ACCNT, FG_DRCR, CD_ACCNT1, CD_ACCNT8, CD_ACCNT9, CD_ACCNT10
								  FROM H_ACCNT_MATRIX_2 WITH (NOLOCK)
								  WHERE CD_COMPANY = @v_cd_company
								  AND CD_ITEM = 'E018'
								) n ON ( m.CD_COMPANY = n.CD_COMPANY AND m.FG_ACCNT = n.FG_ACCNT )
			IF @@error <> 0
			BEGIN
				SET @v_error_number = @@error;
				SET @v_error_code = 'p_at_ret_sap_interface';
				SET @v_error_note = 'H_ADJUSTMENT_DETAIL TABLE 퇴직정산 내역 검색 중 오류가 발생하였습니다.'
				GOTO ERR_HANDLER
			END



			SET @v_seq_h = @v_seq_h + 1 
			-- 퇴직정산(1) (대변) 미지급금(급여) - [홈푸드사용중]
			INSERT INTO H_IF_SAPINTERFACE 
				( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
				  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
				  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
				, LIFNR_S)
			VALUES
				( @v_cd_company,  @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_snm, @v_cd_cost, @v_s_cd_accnt1,
				  @v_amt_new_tot, @v_s_fg_drcr, @v_auto_seq, RIGHT(@v_s_ym_pay,2) + '월 퇴직정산 전표(' + @v_s_nm_person + ')' + @v_s_no_person,
				  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, @v_s_cd_accnt1,
				  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
				, @v_s_no_person
				)
			IF @@error <> 0
			BEGIN
				SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
				GOTO ERR_HANDLER
			END



			SET @v_seq_h = @v_seq_h + 1 
			-- 퇴직정산(2) (대변) 소득세예수금(갑근세) - [홈푸드사용중]
			INSERT INTO H_IF_SAPINTERFACE 
				( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
				  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
				  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
				, LIFNR_S)
			VALUES
				( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, @v_s_cd_accnt8,
				  @v_amt_new_stax, @v_s_fg_drcr, @v_auto_seq, RIGHT(@v_s_ym_pay,2) + '월 퇴직정산 전표(' + @v_s_nm_person + ')' + @v_s_no_person,
				  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, @v_s_cd_accnt8,
				  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
				, @v_s_no_person
				)
			IF @@error <> 0
			BEGIN
				SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
				GOTO ERR_HANDLER
			END


			SET @v_seq_h = @v_seq_h + 1 
			-- 퇴직정산(3) (대변) 소득세예수금(주민세) - [홈푸드사용중]
			INSERT INTO H_IF_SAPINTERFACE 
				( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
				  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
				  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
				, LIFNR_S)
			VALUES
				( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, @v_s_cd_accnt9,
				  @v_amt_new_jtax, @v_s_fg_drcr, @v_auto_seq, RIGHT(@v_s_ym_pay,2) + '월 퇴직정산 전표(' + @v_s_nm_person + ')' + @v_s_no_person,
				  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, @v_s_cd_accnt9,
				  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
				, @v_s_no_person
				)
			IF @@error <> 0
			BEGIN
				SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
				GOTO ERR_HANDLER
			END

		END
		

declare @MSEQ as int;
/* 전표번호 생성용 순번 찾아오는 부분*/
-- 전기일기준으로 생성한다.
SELECT @MSEQ = MAX(cast(SEQ as int))
FROM H_IF_SAPINTERFACE
WHERE CD_COMPANY = @p_cd_compnay
AND SLIP_DATE = @p_dt_gian;

select @MSEQ = isnull(@MSEQ,0) + 1;
SET @v_slip_nbr = @v_cd_company + @v_dt_gian + convert(varchar,dbo.fn_HomeTax_Num(@MSEQ, 4));


		  --SET @v_slip_nbr = @v_cd_company + @v_dt_gian + convert(varchar,dbo.fn_HomeTax_Num(@v_auto_seq, 4));

			-- 전표 update
		   UPDATE H_IF_AUTOSLIPM SET SLIP_NBR = @v_slip_nbr
			WHERE CD_COMPANY = @v_cd_company
			  AND AUTO_DATE = @v_auto_date
			  AND AUTO_SEQ  = @v_auto_seq
			  AND SOURCE_TYPE = @v_source_type

			-- 전표 update (H_IF_SAPINTERFACE)
			UPDATE H_IF_SAPINTERFACE  SET SEQ_H = @v_slip_nbr
			WHERE CD_COMPANY = @v_cd_company
			AND DRAW_DATE	 = @v_auto_date
			AND SEQ			 = @v_auto_seq
			AND IFC_SORT	 = @v_source_type


NEXT_ACCNT_2_CUR:
		-- 다음 커서 패치
		FETCH	NEXT	FROM	ACCNT_CUR_2 INTO	@v_cd_company,
													@v_auto_date,
													@v_auto_seq,
													@v_source_type,
													@v_account_source,
													@v_auto_sno,
													@v_dt_gian
		END
		-- 클로즈
		CLOSE	ACCNT_CUR_2
		-- 커서 제거
		DEALLOCATE	ACCNT_CUR_2

--	    -- 완료시 전표 업데이트 해줌 10.02.26
--	   SELECT TOP 1 @v_cd_acctu = CD_ACCTU
--		 FROM B_HUMAN_DEPT WITH (NOLOCK)
--		WHERE CD_COMPANY = @v_cd_company
--		  AND CD_ACCTU <> ''	-- 회계단위 있는 부서에서만 가져옴.
--	  ORDER BY CD_ORG
--
--		IF @@error <> 0
--		BEGIN
--			SET @v_error_note = 'B_HUMAN_DEPT TABLE 회계단위 검색 중 오류가 발생하였습니다.'
--			GOTO ERR_HANDLER
--		END


	END  

	--//***************************************************************************
	--//*****************		 퇴직금	자동분개 처리				 **************
	--//***************************************************************************
	-- E017	퇴직금
	BEGIN
	   -- 커서 생성 SELECT * FROM H_IF_AUTOSLIPM_TEMP
	   DECLARE	ACCNT_CUR_1	CURSOR	FOR
		SELECT M.CD_COMPANY, M.AUTO_DATE, AUTO_SEQ, SOURCE_TYPE, ACCOUNT_SOURCE, AUTO_SNO, DT_GIAN
		  FROM H_IF_AUTOSLIPM_TEMP M WITH (NOLOCK)
		 WHERE M.CD_COMPANY   = @v_cd_company
		   AND M.SOURCE_TYPE IN ('E017')
		ORDER BY M.AUTO_DATE, M.AUTO_SEQ

		OPEN	ACCNT_CUR_1
		-- 커서 패치
		FETCH	NEXT	FROM	ACCNT_CUR_1	INTO	@v_cd_company,
													@v_auto_date,
													@v_auto_seq,
													@v_source_type,
													@v_account_source,
													@v_auto_sno,
													@v_dt_dian
		-- 항목 처리
		WHILE	@@fetch_status	=	0
		BEGIN
	
		   -- 자료 삭제
		   DELETE FROM H_IF_SAPINTERFACE
		    WHERE CD_COMPANY = @v_cd_company
		      AND DRAW_DATE  = @v_auto_date				-- 이관일자
		      AND SEQ        = @v_auto_seq						-- 순번(varchar)
		      AND ACCT_TYPE  = @v_source_type				-- 구분E017퇴직금, E018퇴직정산

		   --------------------------------------------------------------------------------------------------------------------
		   -- Message Setting Block 
		   --------------------------------------------------------------------------------------------------------------------      
		   /* 에러 발생시 에러 핸들러로 분기 처리 */ 
		   IF @@error <> 0
		   BEGIN
			   SET @v_error_number = @@error;
			   SET @v_error_code = 'p_at_ret_sap_interface';
			   SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 내역 삭제 중 오류가 발생하였습니다.'
			   GOTO ERR_HANDLER
		   END

         SET    @v_s_no_person   = '' 
         SET    @v_s_nm_person   = ''
         SET    @v_s_ym_pay      = ''	-- 퇴직월
         SET    @v_s_dt_prov     = ''	-- 퇴직일자
         SET    @v_s_fg_supp     = ''	-- 퇴직금
         SET    @v_amt_retr_pay  = 0	-- 퇴직금 total
         SET    @v_amt_real_pay_1= 0	-- 미지급금(실지급액)
         SET    @v_amt_new_stax  = 0	-- 소득세예수금
         SET    @v_amt_new_jtax  = 0	-- 주민세예수금
         SET    @v_cd_cost		 = ''	-- 코스트코드
         SET    @v_s_fg_accnt    = ''	-- 원가계정 51판관비
         SET    @v_s_fg_drcr	 = ''	-- 차/대변
         SET    @v_s_cd_accnt1   = ''   
         SET    @v_s_cd_accnt2   = ''                                    
         SET    @v_s_cd_accnt8   = ''	-- 소득세예수금코드
         SET    @v_s_cd_accnt9   = ''	-- 주민세예수금코드
         SET    @v_s_cd_accnt10  = ''	-- 상대계정코드



         SELECT 
                @v_s_no_person   = m.NO_PERSON, 
                @v_s_nm_person   = h.NM_PERSON,
				--@v_zposn_s		 = m.LVL_PAY1,		-- 직급
				@v_zposn_s		= m.cd_position,		-- 직급
                @v_s_ym_pay      = m.YM_PAY,			-- 퇴직월
                @v_s_dt_prov     = m.DT_PROV,		   -- 퇴직일자
                @v_s_fg_supp     = m.FG_SUPP,		   -- 퇴직금
                @v_amt_retr_pay  = m.AMT_RETR_PAY,	-- 퇴직금 total

				--시스템즈는 당사지급액이 아닌 차인지급액을 표기
                @v_amt_real_pay_1 = case when @v_cd_company in ( 'A','B','C','T' ) then m.AMT_REAL_PAY else m.AMT_REAL_PAY_1 end,	-- 미지급금(실지급액) 
                @v_amt_new_stax  = m.AMT_NEW_STAX,	-- 소득세예수금
                @v_amt_new_jtax  = m.AMT_NEW_JTAX,	-- 주민세예수금
                @v_cd_cost		 = RIGHT('0000000000' + m.CD_COST,10),	-- 코스트코드
				@v_gsbers		 = (select biz_acct from b_cost_center where cd_company = m.CD_COMPANY and cd_cc = m.CD_COST), -- 사업영역
                @v_s_fg_accnt    = m.FG_ACCNT,		-- 원가계정 51판관비
                @v_s_fg_drcr	 = n.FG_DRCR,		-- 차/대변
                @v_s_cd_accnt1   = CASE WHEN m.YN_RETPENSION = 'N' THEN '00' + ISNULL(n.CD_ACCNT1,'')
                                        ELSE CASE m.FG_RETPENSION_KIND WHEN 'DB' THEN '00' + ISNULL(n.CD_ACCNT3,'')
                                                                       WHEN 'DC' THEN '00' + ISNULL(n.CD_ACCNT5,'')
                                                                       ELSE '00' + ISNULL(n.CD_ACCNT1,'') 
                                         END
                                    END,    
                @v_s_cd_accnt2   = CASE WHEN m.YN_RETPENSION = 'N' THEN '00' + ISNULL(n.CD_ACCNT2,'')
                                        ELSE CASE m.FG_RETPENSION_KIND WHEN 'DB' THEN '00' + ISNULL(n.CD_ACCNT4,'')
                                                                       WHEN 'DC' THEN '00' + ISNULL(n.CD_ACCNT6,'')
                                                                       ELSE '00' + ISNULL(n.CD_ACCNT2,'') 
                                         END
                                    END ,                                    
                @v_s_cd_accnt8   = '00' + ISNULL(n.CD_ACCNT8,''),	-- 소득세예수금코드
                @v_s_cd_accnt9   = '00' + ISNULL(n.CD_ACCNT9,''),	-- 주민세예수금코드
                @v_s_cd_accnt10  =  ISNULL(n.CD_ACCNT10,'')	-- 상대계정코드   
                , @v_fg_retpension_kind =  m.FG_RETPENSION_KIND


           FROM
                (SELECT a.CD_COMPANY         CD_COMPANY, 
						      a.NO_PERSON          NO_PERSON,
							  a.LVL_PAY1,a.CD_POSITION,
						      LEFT(a.DT_RETR,6)    YM_PAY,
						      a.DT_RETR            DT_PROV,
						      '퇴직금'             FG_SUPP,
                        a.AMT_RETR_PAY       AMT_RETR_PAY,
						      a.AMT_REAL_PAY     AMT_REAL_PAY,	
						      a.AMT_REAL_PAY_1     AMT_REAL_PAY_1,
                        a.AMT_NEW_STAX       AMT_NEW_STAX,
                        a.AMT_NEW_JTAX       AMT_NEW_JTAX,
                        ISNULL(a.YN_RETPENSION,'N')      YN_RETPENSION,
                        ISNULL(a.FG_RETPENSION_KIND,'') FG_RETPENSION_KIND,
						      ISNULL((SELECT CD_COST FROM H_PER_MATCH WITH(NOLOCK) WHERE CD_COMPANY = a.CD_COMPANY AND NO_PERSON = a.NO_PERSON ), '') AS CD_COST,
						      ISNULL((SELECT TOP 1 FG_ACCT 
								          FROM B_COST_CENTER WITH(NOLOCK)
								         WHERE CD_COMPANY = a.CD_COMPANY 
								           AND CD_CC      = ISNULL((SELECT CD_COST FROM H_PER_MATCH WITH(NOLOCK) 
                                                             WHERE CD_COMPANY = a.CD_COMPANY AND NO_PERSON = a.NO_PERSON ), '')
						              ), '')       FG_ACCNT

				        FROM H_RETIRE_DETAIL a WITH(NOLOCK) 
				       WHERE a.CD_COMPANY = @v_cd_company
				         AND a.FG_RETR    = '1'			    -- 퇴직금
				         AND a.DT_AUTO    = @v_auto_date	 -- 이관일자
				         AND a.NO_AUTO    = @v_auto_seq	 -- 순번
			         ) m 
                  INNER JOIN H_HUMAN h ON m.CD_COMPANY = h.CD_COMPANY AND m.NO_PERSON = h.NO_PERSON
				      LEFT OUTER JOIN (SELECT CD_COMPANY, TP_CODE, CD_ITEM, FG_ACCNT, FG_DRCR, 
                                          CD_ACCNT1, CD_ACCNT2, 
                                          CD_ACCNT3, CD_ACCNT4,
                                          CD_ACCNT5, CD_ACCNT6,
                                          CD_ACCNT8, CD_ACCNT9, CD_ACCNT10
								             FROM H_ACCNT_MATRIX_2 WITH (NOLOCK)
								            WHERE CD_COMPANY = @v_cd_company
								              AND CD_ITEM = 'E017'
								           ) n 
                   ON m.CD_COMPANY = n.CD_COMPANY AND m.FG_ACCNT = n.FG_ACCNT
          WHERE m.CD_COMPANY = @v_cd_company

			IF @@error <> 0
			BEGIN
				SET @v_error_number = @@error;
				SET @v_error_code = 'p_at_ret_sap_interface';
				SET @v_error_note = 'H_ADJUSTMENT_DETAIL TABLE 퇴직금 내역 검색 중 오류가 발생하였습니다.'
				GOTO ERR_HANDLER
			END


			
			-- 퇴직금(1) 퇴직금액 생성
			if( @v_amt_retr_pay <> 0 )
			begin
				SET @v_seq_h = @v_seq_h + 1 
				INSERT INTO H_IF_SAPINTERFACE 
					( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
					  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
					  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S 
					, LIFNR_S)
				VALUES
					( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, @v_s_cd_accnt1,
					  case when @v_cd_company in ( 'A','B','C','T' )and @v_fg_retpension_kind <>'00' then @v_amt_real_pay_1 
					  
					  else @v_amt_retr_pay end
					  , @v_s_fg_drcr, @v_auto_seq, '퇴직금(' + @v_s_nm_person + ')'  ,
					  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '999',
					  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
					, CASE WHEN @v_s_fg_drcr = '31' THEN @v_s_no_person ELSE NULL END
					)
				IF @@error <> 0
				BEGIN
					SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 퇴직금 등록 중 오류가 발생하였습니다.'
					GOTO ERR_HANDLER
				END
			end


			if( @v_amt_real_pay_1 <> 0 )
			begin
				SET @v_seq_h = @v_seq_h + 1 

				-- 퇴직금(2) 미지급금 생성 
				INSERT INTO H_IF_SAPINTERFACE 
					( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
					  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
					  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S 
					, LIFNR_S)
				VALUES
					( @v_cd_company,  @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost,  case when @v_cd_company <>  'M'  then @v_s_cd_accnt2 ELSE '00'+@v_s_no_person END,
					  case when @v_cd_company <>  'M'  then @v_amt_real_pay_1 else @v_amt_real_pay_1-@v_amt_retr_pay end , '31', @v_auto_seq, '미지급금(' + @v_s_nm_person+')',
					  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp,  '887',
					  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
					, @v_s_no_person
					)


				IF @@error <> 0
				BEGIN
					SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 퇴직금 등록 중 오류가 발생하였습니다.'
					GOTO ERR_HANDLER
				END
			end

/*
구분코드:
1 : 퇴직소득세
2 : 근로소득세환급
3 : 퇴직소득 주민세
4 : 근로소득 주민세환급
*/

			if( @v_amt_new_stax <> 0 )
			begin
				SET @v_seq_h = @v_seq_h + 1 
				-- 퇴직금(3) 소득세예수금 생성 
				INSERT INTO H_IF_SAPINTERFACE 
					( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
					  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
					  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S 
					, GUBUN)
				VALUES
					( @v_cd_company,  @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, @v_s_cd_accnt8,
					  @v_amt_new_stax, '50', @v_auto_seq, '퇴직소득세('+@v_s_nm_person+')',
					  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, @v_s_cd_accnt8,
					  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
					, '1'
					)
				IF @@error <> 0
				BEGIN
					SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
					GOTO ERR_HANDLER
				END
			end

			if( @v_amt_new_jtax <> 0 )
			begin
				SET @v_seq_h = @v_seq_h + 1 
				-- 퇴직금(4) 주민세예수금 생성 
				INSERT INTO H_IF_SAPINTERFACE 
					( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
					  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
					  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S 
					, GUBUN )
				VALUES
					( @v_cd_company,  @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, @v_s_cd_accnt9,
					  @v_amt_new_jtax, '50', @v_auto_seq, '퇴직주민세(' +@v_s_nm_person+')',
					  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, @v_s_cd_accnt9,
					  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
					, '2'
					)
				IF @@error <> 0
				BEGIN
					SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
					GOTO ERR_HANDLER
				END
			end

-- 김정의 요청 20131001
IF @v_cd_company ='M'
BEGIN
			SET @v_seq_h = @v_seq_h + 1 
			INSERT INTO H_IF_SAPINTERFACE 
				( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
				  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
				  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S )
			VALUES
				--( @v_cd_company,  @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, '21060150',
				--  @V_AMT_PENSION_RESERVE, '50', @v_auto_seq, '퇴직연금',
				--  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '889',
				--  '퇴직연금' , 		  @v_s_fg_supp, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
				--)
				-- 김정의 요청 20130927
				( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, '0021130100',
				  @v_amt_retr_pay, '50', @v_auto_seq, '퇴직금('+@v_s_nm_person+')',
				  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '889',
				  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
				)
			IF @@error <> 0
			BEGIN
				SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
				GOTO ERR_HANDLER
			END
END
-----------------------------------------------------------------------------------------------------------------------------
-- 기타지급공제 처리

SELECT 
@NM_ETC01_SUB_TIT = M.NM_ETC01_SUB_TIT-- 	기타공제1 제목
,@NM_ETC02_SUB_TIT = M.NM_ETC02_SUB_TIT-- 	기타공제2 제목	
,@NM_ETC03_SUB_TIT = M.NM_ETC03_SUB_TIT-- 	기타공제3 제목	
,@NM_ETC04_SUB_TIT = M.NM_ETC04_SUB_TIT-- 	기타공제4 제목	
,@NM_ETC05_SUB_TIT = M.NM_ETC05_SUB_TIT-- 	기타공제5 제목
,@AMT_ETC01_SUB = M.AMT_ETC01_SUB-- 	기타공제1	
,@AMT_ETC02_SUB = M.AMT_ETC02_SUB-- 	기타공제2	
,@AMT_ETC03_SUB = M.AMT_ETC03_SUB-- 	기타공제3	
,@AMT_ETC04_SUB = M.AMT_ETC04_SUB-- 	기타공제4	
,@AMT_ETC05_SUB = M.AMT_ETC05_SUB-- 	기타공제5	
,@NM_ETC01_PROV_TIT = M.NM_ETC01_PROV_TIT-- 	기타지급1 제목	
,@NM_ETC02_PROV_TIT = M.NM_ETC02_PROV_TIT-- 	기타지급2 제목	
,@NM_ETC03_PROV_TIT = M.NM_ETC03_PROV_TIT-- 	기타지급3 제목	
,@AMT_ETC01_PROV = M.AMT_ETC01_PROV-- 	기타지급1	
,@AMT_ETC02_PROV = M.AMT_ETC02_PROV-- 	기타지급2	
,@AMT_ETC03_PROV = M.AMT_ETC03_PROV-- 	기타지급3	
,@_x1_cd_accnt1  = x1.cd_accnt1 	-- 직원
,@_x1_cd_accnt2  = x1.cd_accnt2 	-- 임원
,@_x1_cd_accnt10 = x1.cd_accnt10	 -- 상대
,@_x2_cd_accnt1  = x2.cd_accnt1 	-- 직원
,@_x2_cd_accnt2  = x2.cd_accnt2 	-- 임원
,@_x2_cd_accnt10 = x2.cd_accnt10	 -- 상대
,@_x3_cd_accnt1  = x3.cd_accnt1 	-- 직원
,@_x3_cd_accnt2  = x3.cd_accnt2 	-- 임원
,@_x3_cd_accnt10 = x3.cd_accnt10	 -- 상대
,@_x4_cd_accnt1  = x4.cd_accnt1 	-- 직원
,@_x4_cd_accnt2  = x4.cd_accnt2 	-- 임원
,@_x4_cd_accnt10 = x4.cd_accnt10	 -- 상대
,@_x5_cd_accnt1  = x5.cd_accnt1 	-- 직원
,@_x5_cd_accnt2  = x5.cd_accnt2 	-- 임원
,@_x5_cd_accnt10 = x5.cd_accnt10	 -- 상대
,@_x1_fg_drcr = x1.fg_drcr
,@_x2_fg_drcr = x2.fg_drcr
,@_x3_fg_drcr = x3.fg_drcr
,@_x4_fg_drcr = x4.fg_drcr
,@_x5_fg_drcr = x5.fg_drcr
,@_y1_cd_accnt1 = y1.cd_accnt1 
,@_y1_cd_accnt2 = y1.cd_accnt2 
,@_y1_cd_accnt10= y1.cd_accnt10
,@_y2_cd_accnt1 = y2.cd_accnt1 
,@_y2_cd_accnt2 = y2.cd_accnt2 
,@_y2_cd_accnt10= y2.cd_accnt10
,@_y3_cd_accnt1 = y3.cd_accnt1 
,@_y3_cd_accnt2  = y3.cd_accnt1 
,@_y3_cd_accnt10 = y3.cd_accnt1 
,@_y1_fg_drcr  = y1.fg_drcr
,@_y2_fg_drcr  = y2.fg_drcr
,@_y3_fg_drcr  = y3.fg_drcr

FROM H_RETIRE_DETAIL M
left outer join H_ACCNT_PAY_ITEM_2_NM X1
	on m.cd_company = x1.cd_company and m.NM_ETC01_SUB_TIT = x1.nm_item and x1.fg_accnt = @v_s_fg_accnt
left outer join H_ACCNT_PAY_ITEM_2_NM X2
	on m.cd_company = x2.cd_company and m.NM_ETC02_SUB_TIT = x2.nm_item and x2.fg_accnt = @v_s_fg_accnt
left outer join H_ACCNT_PAY_ITEM_2_NM X3
	on m.cd_company = x3.cd_company and m.NM_ETC03_SUB_TIT = x3.nm_item and x3.fg_accnt = @v_s_fg_accnt
left outer join H_ACCNT_PAY_ITEM_2_NM X4
	on m.cd_company = x4.cd_company and m.NM_ETC04_SUB_TIT = x4.nm_item and x4.fg_accnt = @v_s_fg_accnt
left outer join H_ACCNT_PAY_ITEM_2_NM X5
	on m.cd_company = x5.cd_company and m.NM_ETC05_SUB_TIT = x5.nm_item and x5.fg_accnt = @v_s_fg_accnt
left outer join H_ACCNT_PAY_ITEM_2_NM y1
	on m.cd_company = y1.cd_company and m.NM_ETC01_PROV_TIT = y1.nm_item and y1.fg_accnt = @v_s_fg_accnt
left outer join H_ACCNT_PAY_ITEM_2_NM y2
	on m.cd_company = y2.cd_company and m.NM_ETC02_PROV_TIT = y2.nm_item and y2.fg_accnt = @v_s_fg_accnt
left outer join H_ACCNT_PAY_ITEM_2_NM y3
	on m.cd_company = y3.cd_company and m.NM_ETC03_PROV_TIT = y3.nm_item and y3.fg_accnt = @v_s_fg_accnt
WHERE M.FG_RETR = '1'	
AND M.CD_COMPANY = @p_cd_compnay
AND M.DT_BASE    = @v_s_dt_prov
AND M.NO_PERSON  = @v_s_no_person


if(isnull(@_x1_cd_accnt1,'') != '' and @AMT_ETC01_SUB != 0 )
begin
	SET @v_seq_h = @v_seq_h + 1 
	INSERT INTO H_IF_SAPINTERFACE 
		( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
		  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
		  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
		, LIFNR_S)
	VALUES
		( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, '00'+@_x1_cd_accnt1,
		  abs(@AMT_ETC01_SUB) , case when @AMT_ETC01_SUB < 0 then '40'  else @_x1_fg_drcr end , @v_auto_seq, @NM_ETC01_SUB_TIT+'('+@v_s_nm_person+')',
		  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '00',
		  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), '00'+@_x1_cd_accnt10, @v_gsbers
		, CASE WHEN @_x1_fg_drcr = '31' THEN @v_s_no_person ELSE NULL END
		)
	IF @@error <> 0
	BEGIN
		SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END
end

if(isnull(@_x2_cd_accnt1,'') != '' and @AMT_ETC02_SUB != 0 )
begin
	SET @v_seq_h = @v_seq_h + 1 
	INSERT INTO H_IF_SAPINTERFACE 
		( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
		  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
		  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
		, LIFNR_S)
	VALUES
		( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, '00'+@_x2_cd_accnt1,
		 abs( @AMT_ETC02_SUB), case when @AMT_ETC02_SUB < 0 then '40'  else @_x2_fg_drcr end , @v_auto_seq, @NM_ETC02_SUB_TIT+'('+@v_s_nm_person+')',
		  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '00',
		  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), '00'+@_x2_cd_accnt10, @v_gsbers
		, CASE WHEN @_x2_fg_drcr = '31' THEN @v_s_no_person ELSE NULL END
		)
	IF @@error <> 0
	BEGIN
		SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END
end

if(isnull(@_x3_cd_accnt1,'') != '' and @AMT_ETC03_SUB != 0 )
begin
	SET @v_seq_h = @v_seq_h + 1 
	INSERT INTO H_IF_SAPINTERFACE 
		( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
		  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
		  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
		, LIFNR_S)
	VALUES
		( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, '00'+@_x3_cd_accnt1,
		 ABS( @AMT_ETC03_SUB), case when @AMT_ETC03_SUB < 0 then '40'  else @_x3_fg_drcr end  , @v_auto_seq, @NM_ETC03_SUB_TIT+'('+@v_s_nm_person+')',
		  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '00',
		  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), '00'+@_x3_cd_accnt10, @v_gsbers
		, CASE WHEN @_x3_fg_drcr = '31' THEN @v_s_no_person ELSE NULL END
		)
	IF @@error <> 0
	BEGIN
		SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END
end

if(isnull(@_x4_cd_accnt1,'') != '' and @AMT_ETC04_SUB != 0 )
begin

	SET @v_seq_h = @v_seq_h + 1; 
	INSERT INTO H_IF_SAPINTERFACE 
		( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
		  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
		  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
		, LIFNR_S)
	VALUES
		( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, '00'+@_x4_cd_accnt1,
		 abs( @AMT_ETC04_SUB), case when @AMT_ETC04_SUB < 0 then '40'  else @_x4_fg_drcr end  , @v_auto_seq, @NM_ETC04_SUB_TIT+'('+@v_s_nm_person+')',
		  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '00',
		  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), '00'+@_x4_cd_accnt10, @v_gsbers
		, CASE WHEN @_x4_fg_drcr = '31' THEN @v_s_no_person ELSE NULL END
		);

	IF @@error <> 0
	BEGIN
		SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END
end


if(isnull(@_x5_cd_accnt1,'') != '' and @AMT_ETC05_SUB != 0 )
begin
	SET @v_seq_h = @v_seq_h + 1 
	INSERT INTO H_IF_SAPINTERFACE 
		( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
		  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
		  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
		, LIFNR_S)
	VALUES
		( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, '00'+@_x5_cd_accnt1,
		  abs(@AMT_ETC05_SUB), case when @AMT_ETC05_SUB < 0 then '40'  else @_x5_fg_drcr end , @v_auto_seq, @NM_ETC05_SUB_TIT+'('+@v_s_nm_person+')',
		  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '00',
		  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), '00'+@_x5_cd_accnt10, @v_gsbers
		, CASE WHEN @_x5_fg_drcr = '31' THEN @v_s_no_person ELSE NULL END
		)
	IF @@error <> 0
	BEGIN
		SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END
end



if( ( @NM_ETC01_SUB_TIT = '근로소득세' and @AMT_ETC01_SUB <> 0 )
	or ( @NM_ETC02_SUB_TIT = '근로소득세' and @AMT_ETC02_SUB <> 0 )
	or ( @NM_ETC03_SUB_TIT = '근로소득세' and @AMT_ETC03_SUB <> 0 )
	or ( @NM_ETC04_SUB_TIT = '근로소득세' and @AMT_ETC04_SUB <> 0 )
	or ( @NM_ETC05_SUB_TIT = '근로소득세' and @AMT_ETC05_SUB <> 0 )  )
begin

	SET @v_seq_h = @v_seq_h + 1 
	-- 근로소득세예수금 생성 
	INSERT INTO H_IF_SAPINTERFACE 
		( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
		  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
		  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S 
		, GUBUN)
	VALUES
		( @v_cd_company,  @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, @v_s_cd_accnt8,
		case when @NM_ETC01_SUB_TIT = '근로소득세' then @AMT_ETC01_SUB
			when @NM_ETC02_SUB_TIT = '근로소득세' then @AMT_ETC02_SUB
			when @NM_ETC03_SUB_TIT = '근로소득세' then @AMT_ETC03_SUB
			when @NM_ETC04_SUB_TIT = '근로소득세' then @AMT_ETC04_SUB
			when @NM_ETC05_SUB_TIT = '근로소득세' then @AMT_ETC05_SUB end


			, '50', @v_auto_seq, '근로소득세(' + @v_s_nm_person + ')' + @v_s_no_person,
		  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, @v_s_cd_accnt8,
		  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
		, '3'
		)
	IF @@error <> 0
	BEGIN
		SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END
end

if( ( @NM_ETC01_SUB_TIT = '근로주민세' and @AMT_ETC01_SUB <> 0 )
	or ( @NM_ETC02_SUB_TIT = '근로주민세' and @AMT_ETC02_SUB <> 0 )
	or ( @NM_ETC03_SUB_TIT = '근로주민세' and @AMT_ETC03_SUB <> 0 )
	or ( @NM_ETC04_SUB_TIT = '근로주민세' and @AMT_ETC04_SUB <> 0 )
	or ( @NM_ETC05_SUB_TIT = '근로주민세' and @AMT_ETC05_SUB <> 0 ) )
begin
	SET @v_seq_h = @v_seq_h + 1 
	-- 퇴직금(4) 주민세예수금 생성 
	INSERT INTO H_IF_SAPINTERFACE 
		( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
		  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
		  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S 
		, GUBUN)
	VALUES
		( @v_cd_company,  @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, @v_s_cd_accnt9,
		case when @NM_ETC01_SUB_TIT = '근로주민세' then @AMT_ETC01_SUB
			when @NM_ETC02_SUB_TIT = '근로주민세' then @AMT_ETC02_SUB
			when @NM_ETC03_SUB_TIT = '근로주민세' then @AMT_ETC03_SUB
			when @NM_ETC04_SUB_TIT = '근로주민세' then @AMT_ETC04_SUB
			when @NM_ETC05_SUB_TIT = '근로주민세' then @AMT_ETC05_SUB end
		, '50', @v_auto_seq, '근로주민세(' + @v_s_nm_person + ')' + @v_s_no_person,
		  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, @v_s_cd_accnt9,
		  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), @v_s_cd_accnt10, @v_gsbers
		, '4'
		)
	IF @@error <> 0
	BEGIN
		SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END
end


if(isnull(@_y1_cd_accnt1,'') != '' and @AMT_ETC01_PROV != 0 )
begin
	SET @v_seq_h = @v_seq_h + 1 
	INSERT INTO H_IF_SAPINTERFACE 
		( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
		  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
		  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
		, LIFNR_S)
	VALUES
		( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, '00'+@_y1_cd_accnt1,
		  @AMT_ETC01_PROV, @_y1_fg_drcr, @v_auto_seq, @NM_ETC01_PROV_TIT +'('+@v_s_nm_person+')',
		  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '00',
		  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), '00'+@_y1_cd_accnt10, @v_gsbers
		, CASE WHEN @_y1_fg_drcr = '31' THEN @v_s_no_person ELSE NULL END
		)
	IF @@error <> 0
	BEGIN
		SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END
end

if(isnull(@_y2_cd_accnt1,'') != '' and @AMT_ETC02_PROV != 0 )
begin
	SET @v_seq_h = @v_seq_h + 1 
	INSERT INTO H_IF_SAPINTERFACE 
		( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
		  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
		  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
		, LIFNR_S)
	VALUES
		( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, '00'+@_y2_cd_accnt1,
		  @AMT_ETC02_PROV, @_y2_fg_drcr, @v_auto_seq, @NM_ETC02_PROV_TIT+'('+@v_s_nm_person+')',
		  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '00',
		  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), '00'+@_y2_cd_accnt10, @v_gsbers
		, CASE WHEN @_y2_fg_drcr = '31' THEN @v_s_no_person ELSE NULL END
		)
	IF @@error <> 0
	BEGIN
		SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END
end

if(isnull(@_y3_cd_accnt1,'') != '' and @AMT_ETC03_PROV != 0 )
begin
	SET @v_seq_h = @v_seq_h + 1 
	INSERT INTO H_IF_SAPINTERFACE 
		( CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
		  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
		  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD , GSBER_S
		, LIFNR_S)
	VALUES
		( @v_cd_company,   @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_auto_date, @v_s_no_person, @v_s_nm_person, @v_cd_cost, '00'+@_y3_cd_accnt1,
		  @AMT_ETC03_PROV, @_y3_fg_drcr, @v_auto_seq, @NM_ETC03_PROV_TIT+'('+@v_s_nm_person+')',
		  @v_source_type,  'N',	@v_s_ym_pay, @v_s_dt_prov, @v_s_fg_supp, '00',
		  'none' , 		  @v_source_type, @v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), '00'+@_y3_cd_accnt10, @v_gsbers
		, CASE WHEN @_y3_fg_drcr = '31' THEN @v_s_no_person ELSE NULL END
		)
	IF @@error <> 0
	BEGIN
		SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 등록 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END
end

-----------------------------------------------------------------------------------------------------------------------------

			



			
			--SET @v_slip_nbr = @v_cd_company + CONVERT(NVARCHAR(8), GETDATE(), 112) + convert(varchar,dbo.fn_HomeTax_Num(@v_auto_seq, 4));
			--- 자꾸 중복번호가 나와서 바꿈
			
			SET @v_slip_nbr = @v_cd_company + CONVERT(NVARCHAR(8), GETDATE(), 112) + convert(varchar,dbo.fn_HomeTax_Num(@v_auto_seq, 4));
			
			
			
			-- 전표 update
		   UPDATE H_IF_AUTOSLIPM SET SLIP_NBR = @v_slip_nbr
			 WHERE CD_COMPANY  = @v_cd_company
			   AND AUTO_DATE   = @v_auto_date
			   AND AUTO_SEQ    = @v_auto_seq
			   AND SOURCE_TYPE = @v_source_type

			-- 전표 update (H_IF_SAPINTERFACE)
			UPDATE H_IF_SAPINTERFACE  SET SEQ_H = @v_slip_nbr
			WHERE CD_COMPANY = @v_cd_company
			AND DRAW_DATE	 = @v_auto_date
			AND SEQ			 = @v_auto_seq
			AND IFC_SORT	 = @v_source_type


		/* 테크팩솔루션 코스트센터,회계계정 관련 예외처리 요청자: 김선일
		1) 코스트센터: 테크팩 코스트센터에 영문자 포함으로 앞에 붙여주는 '000000' 빼주기 */

		if @v_cd_company = 'T'
			begin
				UPDATE H_IF_SAPINTERFACE
				SET COST_CENTER = SUBSTRING(COST_CENTER,7,4)
				WHERE 1=1
					AND DRAW_DATE	 = @v_auto_date
					AND SEQ			 = @v_auto_seq
					AND IFC_SORT	 = @v_source_type
			end;
			
			
--		-- 퇴직금 select * from H_IF_SAPINTERFACE
--		BEGIN
--			INSERT INTO H_IF_SAPINTERFACE 
--				( CD_COMPANY, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
--				  AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
--				  PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD )
--			SELECT     m.CD_COMPANY,
--					   @v_auto_date,
--					   m.NO_PERSON AS SNO,
--					   h.NM_PERSON AS SNM,
--					   m.CD_COST AS COST_CENTER,
----					   m.FG_ACCNT,		-- 원가계정 51판관비, 제조 등등
--						-- 직급(임원구분) '000' 임원직급
--					   ( CASE WHEN ISNULL(h.LVL_PAY1, '') = '000' THEN ISNULL(n.CD_ACCNT2, '' )
--							ELSE ISNULL(n.CD_ACCNT1, '' ) END )  AS SAP_ACCTCODE,
--					   ISNULL(m.AMT_ITEM, 0) AS AMT,
--					   ISNULL(n.FG_DRCR, '') AS DBCR_GU,
--					   @v_auto_seq,
--					   '퇴직금(' + @v_source_type + ')',
--					   @v_source_type,
--					   'N',
--					   m.YM_PAY AS PAY_YM,
--					   m.DT_PROV AS PAY_DATE,
--					   m.FG_SUPP AS PAY_SUPP,
--					   '' AS ITEM_CODE,
--					   m.CD_PAYGP AS PAYGP_CODE,
--					   @v_source_type,@v_dt_gian, @v_id_user, getdate(), @v_id_user, getdate(), 
----					   -- 사원
----					   ISNULL(n.CD_ACCNT1, '' ) AS CD_ACCNT1,
----					   -- 임원
----					   ISNULL(n.CD_ACCNT2, '' ) AS CD_ACCNT2,
--					   -- 상대계정
--					   ISNULL(n.CD_ACCNT10, '') AS CD_ACCNT10
--					   -- 정규/비정규 구분 '1'정규, '2'비정규
----					   ISNULL(h.FG_PERSON, '') AS FG_PERSON
--			FROM
--			( SELECT	a.CD_COMPANY,
--						a.NO_PERSON,
--						LEFT(a.DT_RETR,6) AS YM_PAY,
--						a.DT_RETR AS DT_PROV,
--						'퇴직금' AS FG_SUPP,
--						a.AMT_REAL_PAY_1 AS AMT_ITEM,
--						ISNULL(( SELECT CD_COST FROM H_PER_MATCH WITH(NOLOCK) WHERE CD_COMPANY = a.CD_COMPANY AND NO_PERSON = a.NO_PERSON ), '') AS CD_COST,
--						ISNULL((  SELECT TOP 1 FG_ACCT 
--								 FROM B_COST_CENTER WITH(NOLOCK)
--								 WHERE CD_COMPANY = a.CD_COMPANY 
--								 AND CD_CC = ISNULL(( SELECT CD_COST FROM H_PER_MATCH WITH(NOLOCK) WHERE CD_COMPANY = a.CD_COMPANY AND NO_PERSON = a.NO_PERSON ), '')
--						), '') AS FG_ACCNT,
--						a.CD_PAYGP
--				FROM H_RETIRE_DETAIL a WITH(NOLOCK) 
--				WHERE a.CD_COMPANY = @v_cd_company
--				AND a.FG_RETR = '1'			-- 퇴직금
--				AND a.DT_AUTO = @v_auto_date		-- 이관일자
--				AND a.NO_AUTO = @v_auto_seq			-- 순번
--			) m INNER JOIN H_HUMAN h ON ( m.CD_COMPANY = h.CD_COMPANY AND m.NO_PERSON = h.NO_PERSON )
--				LEFT OUTER JOIN ( SELECT CD_COMPANY, TP_CODE, CD_ITEM, FG_ACCNT, FG_DRCR, CD_ACCNT1, CD_ACCNT2, CD_ACCNT10
--								  FROM H_ACCNT_MATRIX_2 WITH (NOLOCK)
--								 WHERE CD_COMPANY = @v_cd_company
--								  AND CD_ITEM = 'E017'
--								) n ON ( m.CD_COMPANY = n.CD_COMPANY AND m.FG_ACCNT = n.FG_ACCNT )
--			WHERE m.CD_COMPANY = @v_cd_company
----				AND ISNULL(m.CD_COST, '') <> ''  --AND ISNULL(m.FG_ACCNT, '') <> '' )
--
--
--				IF @@error <> 0
--				BEGIN
--					SET @v_error_note = 'H_IF_SAPINTERFACE TABLE [퇴직금] 등록 중 오류가 발생하였습니다.'
--					GOTO ERR_HANDLER
--				END
--
--
--		END


NEXT_ACCNT_1_CUR:
		   -- 다음 커서 패치
		   FETCH	NEXT	FROM	ACCNT_CUR_1 INTO	@v_cd_company,
													   @v_auto_date,
													   @v_auto_seq,
													   @v_source_type,
													   @v_account_source,
													   @v_auto_sno,
													   @v_dt_gian
		END
		-- 클로즈
		CLOSE	ACCNT_CUR_1
		-- 커서 제거
		DEALLOCATE	ACCNT_CUR_1

--	    -- 완료시 전표 업데이트 해줌 10.02.26
--	   SELECT TOP 1 @v_cd_acctu = CD_ACCTU
--		 FROM B_HUMAN_DEPT WITH (NOLOCK)
--		WHERE CD_COMPANY = @v_cd_company
--		  AND CD_ACCTU <> ''	-- 회계단위 있는 부서에서만 가져옴.
--	  ORDER BY CD_ORG
--
--		IF @@error <> 0
--		BEGIN
--			SET @v_error_note = 'B_HUMAN_DEPT TABLE 회계단위 검색 중 오류가 발생하였습니다.'
--			GOTO ERR_HANDLER
--		END

	END

	RETURN			/* 끝 */

  -----------------------------------------------------------------------------------------------------------------------
  -- END Message Setting Block 
  ----------------------------------------------------------------------------------------------------------------------- 
  ERR_HANDLER:

	DEALLOCATE	ACCNT_CUR_1
--	DEALLOCATE	ACCNT_CUR_2

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;

	EXECUTE p_ba_errlib_getusererrormsg @v_cd_company, 'p_at_ret_sap_interface',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

	RETURN
END TRY

  ----------------------------------------------------------------------------------------------------------------------- 
  -- Error CATCH Process Block 
  ----------------------------------------------------------------------------------------------------------------------- 
BEGIN CATCH

	DEALLOCATE	ACCNT_CUR_1
--	DEALLOCATE	ACCNT_CUR_2

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line =  ERROR_LINE();
	SET @v_error_message = ERROR_MESSAGE()+ ' ' + @v_error_note;
select @v_error_number, @v_error_message
	EXECUTE p_ba_errlib_getusererrormsg @v_cd_company, 'p_at_ret_sap_interface',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

	RETURN
END CATCH

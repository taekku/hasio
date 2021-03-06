USE [dwehrdev]
GO
/****** Object:  StoredProcedure [dbo].[p_at_pay_sap_interface]    Script Date: 2020-12-01 오후 5:42:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Create date: <Create Date,,2010.01>
-- Description:	<Description,,급상여 자동분개처리 >
-- =============================================
/* Execute Sample
DECLARE
   @p_error_code VARCHAR(30),
   @p_error_str VARCHAR(500)
BEGIN
   SET @p_error_code = '';
   SET @p_error_str = '';

   EXECUTE p_at_pay_sap_interface
			'KOR',                      -- @p_lang_code       VARCHAR(3)
			'1',                        -- @p_return_no       VARCHAR(1)
			'Q',						-- @p_cd_compnay	회사코드
			'20100225',					-- @p_dt_gian기안일자
			'WISEN',					-- @p_id_user사용자ID
           @p_error_code OUTPUT,        -- @p_error_code      VARCHAR(30)
           @p_error_str  OUTPUT         -- @p_error_str       VARCHAR(500)

	-- SELECT * FROM H_ERRORLOG WITH (nolock)
	-- DELETE FROM H_ERRORLOG

	-- SELECT * FROM H_IF_SAPINTERFACE WHERE CD_COMPANY = 'H' AND DRAW_DATE = '20100114' AND  IFC_SORT = 'H20004' AND SEQ = '260'
	-- SELECT * FROM H_IF_SAPINTERFACE WHERE CD_COMPANY = 'H' AND DRAW_DATE = '20091031' AND  IFC_SORT = 'H20004'
	-- SELECT * FROM H_IF_SAPINTERFACE WHERE CD_COMPANY = 'H' AND DRAW_DATE = '20091031' AND  IFC_SORT = 'H20003'
	-- SELECT * FROM H_IF_SAPINTERFACE WHERE CD_COMPANY = 'H' AND DRAW_DATE = '20091031' AND  IFC_SORT = 'H20002'
	
	-- SELECT * FROM H_IF_AUTOSLIPM_TEMP
	-- SELECT * FROM H_IF_SAPINTERFACE	WHERE CD_COMPANY = 'H' AND DRAW_DATE = '20100114'
	-- SELECT * FROM H_IF_AUTOSLIPM		WHERE CD_COMPANY = 'H' AND AUTO_DATE = '20100114' AND AUTO_SEQ = 8
END

-- SELECT * FROM H_IF_AUTOSLIPM_TEMP
INSERT INTO H_IF_AUTOSLIPM_TEMP ( CD_COMPANY, AUTO_DATE, AUTO_SEQ, SOURCE_TYPE, ACCOUNT_SOURCE, AUTO_SNO, DT_GIAN )
SELECT CD_COMPANY, AUTO_DATE, AUTO_SEQ, SOURCE_TYPE, ACCOUNT_SOURCE, AUTO_SNO, '20101231' AS DT_GIAN
FROM H_IF_AUTOSLIPM 
WHERE CD_COMPANY = 'H'
AND AUTO_DATE = '20100114'
AND AUTO_SEQ = '4'
*/

/*

 DECLARE 
      @p_error_code VARCHAR(30), 
      @p_error_str VARCHAR(500) 
 BEGIN
      SET @p_error_code = ''; 
      SET @p_error_str = ''; 
      EXECUTE p_at_pay_sap_interface
      'KOR',                      -- @p_lang_code     VARCHAR(3) 
      '1',                        -- @p_return_no     VARCHAR(1) 
      'Q',
      '20100304',
      'newikim',
      @p_error_code OUTPUT,		-- @p_error_code      VARCHAR(30) 
      @p_error_str OUTPUT 		-- @p_error_str       VARCHAR(500) 
 END

*/

ALTER PROCEDURE [dbo].[p_at_pay_sap_interface] (
							  @p_lang_code       VARCHAR(3) = 'KOR',				-- LANGUAGE 초기값 : KOR.
                              @p_return_no       VARCHAR(1) = '1',					-- 리턴 분기 번호
							  @p_cd_compnay		 VARCHAR(10),						-- 회사코드
							  @p_dt_gian		 VARCHAR(8) ,						-- 품의일자
							  @p_id_user		 VARCHAR(20) ,						-- 사용자ID
                              @p_error_code      VARCHAR(1000) OUTPUT,				-- 에러코드 리턴
                              @p_error_str       VARCHAR(3000) OUTPUT				-- 에러메시지 리턴
                              )                                                                              
AS
SET NOCOUNT ON
/*
  동원산업의 경우 p_at_pay_sap_interface_I 에서 처리 하는것으로 변경함. 2010.04.06 유성현
*/
If (@p_cd_compnay = 'I' )
Begin
   Exec p_at_pay_sap_interface_I @p_lang_code
                               , @p_return_no
                               , @p_cd_compnay
                               , @p_dt_gian
                               , @p_id_user
                               , @p_error_code Output
                               , @p_error_str Output
   Return
End

--------------------------------------------------------------------------------------------------------------------
-- 홈푸드 일때 [p_at_pay_sap_interface_H] 실행 2010.04.19
--------------------------------------------------------------------------------------------------------------------
	IF @p_cd_compnay = 'H'
	BEGIN
       	 EXEC p_at_pay_sap_interface_H 'KOR', '1', @p_cd_compnay, @p_dt_gian, @p_id_user,
         @p_error_code OUTPUT, @p_error_str OUTPUT
        RETURN		
	END
--------------------------------------------------------------------------------------------------------------------
-- 홈푸드 일때 [p_at_pay_sap_interface_H] 종료.
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-- 홈푸드 일때 [p_at_pay_sap_interface_w] 실행 2019.07.17
--------------------------------------------------------------------------------------------------------------------
	IF @p_cd_compnay = 'W'
	BEGIN
       	 EXEC p_at_pay_sap_interface_W 'KOR', '1', @p_cd_compnay, @p_dt_gian, @p_id_user,
         @p_error_code OUTPUT, @p_error_str OUTPUT
        RETURN		
	END
--------------------------------------------------------------------------------------------------------------------
-- 홈푸드 일때 [p_at_pay_sap_interface_H] 종료.
--------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------
-- 엔터프라이즈 일때 [p_at_pay_sap_interface_E] 실행 2010.05.14
--------------------------------------------------------------------------------------------------------------------
	IF @p_cd_compnay = 'E'
	BEGIN

       	 EXEC p_at_pay_sap_interface_e 'KOR', '1', @p_cd_compnay, @p_dt_gian, @p_id_user,
         @p_error_code OUTPUT, @p_error_str OUTPUT
        RETURN		
	END
--------------------------------------------------------------------------------------------------------------------
-- 엔터프라이즈 일때 [p_at_pay_sap_interface_E] 종료.
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------
-- 동원냉장 일때 [p_at_pay_sap_interface_l] 실행 2012.10.22
--------------------------------------------------------------------------------------------------------------------
	IF @p_cd_compnay IN ('L', 'R')
	BEGIN

       	 EXEC p_at_pay_sap_interface_l 'KOR', '1', @p_cd_compnay, @p_dt_gian, @p_id_user,
         @p_error_code OUTPUT, @p_error_str OUTPUT
        RETURN		
	END
--------------------------------------------------------------------------------------------------------------------
--동원냉장 일때 [p_at_pay_sap_interface_l] 종료.
--------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------
-- 동원씨앤에스 일때 [p_at_pay_sap_interface_m] 실행 2010.05.14
--------------------------------------------------------------------------------------------------------------------
	IF @p_cd_compnay = 'M'
	BEGIN

       	 EXEC p_at_pay_sap_interface_m 'KOR', '1', @p_cd_compnay, @p_dt_gian, @p_id_user,
         @p_error_code OUTPUT, @p_error_str OUTPUT
        RETURN		
	END
--------------------------------------------------------------------------------------------------------------------
--동원씨앤에스 일때 [p_at_pay_sap_interface_m] 종료.
--------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------
-- 동원팜스 일때 [p_at_pay_sap_interface_s2] 실행 2010.05.14
--------------------------------------------------------------------------------------------------------------------
	IF @p_cd_compnay = 'S'
	BEGIN
       	 EXEC p_at_pay_sap_interface_s2 'KOR', '1', @p_cd_compnay, @p_dt_gian, @p_id_user,
         @p_error_code OUTPUT, @p_error_str OUTPUT
        RETURN		
	END
--------------------------------------------------------------------------------------------------------------------
--동원씨앤에스 일때 [p_at_pay_sap_interface_m] 종료.
--------------------------------------------------------------------------------------------------------------------


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
    @v_gsbers					VARCHAR(20),			-- 사업부문

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
	
	@v_zposn_s					VARCHAR(10),
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

	@v_seq_h					VARCHAR(10),	-- SEQNO_S dp에 들어갈 값

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

	declare @tmp_fg_acct varchar(10);


BEGIN TRY
	/* 변수에 대한 초기화 처리 */
	SET @v_error_code = '';
	SET @v_error_note = '';

	/* 파라메터를 로컬변수로 처리하며 이때 NULL일 경우에 필요한 처리를 한다. */
	SET @v_cd_company   = @p_cd_compnay ;
	SET @v_dt_gian		= @p_dt_gian;
	SET @v_id_user		= @p_id_user;		-- 로그인사용자
	SET @v_rec_count	= 0;
	SET @v_cnt			= 0;
	SET @v_seq_h		= 0;
	-- 오류TABLE삭제
	DELETE FROM H_ERRORLOG
	WHERE CD_COMPANY = @v_cd_company
	AND ERROR_PROCEDURE = 'p_at_pay_sap_interface'

	--------------------------------------------------------------------------------------------------------------------
	-- Message Setting Block 
	--------------------------------------------------------------------------------------------------------------------      
	/* 에러 발생시 에러 핸들러로 분기 처리 */ 
	IF @@error <> 0
	BEGIN
		SET @v_error_number = @@error;
		SET @v_error_code = 'p_at_pay_sap_interface';
		SET @v_error_note = '오류TABLE삭제 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END

	/* select * from H_IF_AUTOSLIPM_TEMP TABLE */
--	SELECT @v_cnt = COUNT(CD_COMPANY)
--	FROM H_IF_AUTOSLIPM_TEMP WITH (NOLOCK)
--	WHERE CD_COMPANY = @v_cd_company
--	AND ISNULL(APPR_DATE, '') <> ''
--	AND SOURCE_TYPE IN ('E010', 'E011')

	-------------------------------------------------------------------------------------------------------------------
	-- Message Setting Block 
	--------------------------------------------------------------------------------------------------------------------      
	/* 에러 발생시 에러 핸들러로 분기 처리 */ 
	IF @@error <> 0
	BEGIN
		SET @v_error_number = @@error;
		SET @v_error_code = 'p_at_pay_sap_interface';
		SET @v_error_note = 'H_IF_AUTOSLIPM_TEMP TABLE 검색 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END

--	IF @v_cnt > 0
--	BEGIN
--		SET @v_error_number = @@error;
--		SET @v_error_code = 'p_at_pay_sap_interface';
--		SET @v_error_note = '이미 전표 승인 되었습니다. 승인 취소 후 작업하십시요.'
--		GOTO ERR_HANDLER
--	END

	/* SELECT * FROM H_IF_AUTOSLIPM_TEMP TABLE */
--	SELECT @v_cnt = COUNT(CD_COMPANY)
--	FROM H_IF_AUTOSLIPM_TEMP WITH (NOLOCK)
--	WHERE CD_COMPANY = @v_cd_company
--	AND ISNULL(APPR_DATE, '') = ''
--	AND SOURCE_TYPE IN ('E010', 'E011')
	--------------------------------------------------------------------------------------------------------------------
	-- Message Setting Block 
	--------------------------------------------------------------------------------------------------------------------      
	/* 에러 발생시 에러 핸들러로 분기 처리 */ 
	IF @@error <> 0
	BEGIN
		SET @v_error_number = @@error;
		SET @v_error_code = 'p_at_pay_sap_interface';
		SET @v_error_note = 'H_IF_AUTOSLIPM_TEMP TABLE 검색 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END

--	IF @v_cnt <= 0
--	BEGIN
--		SET @v_error_number = @@error;
--		SET @v_error_code = 'p_at_pay_sap_interface';
--		SET @v_error_note = '전표 처리 할 기초 자료가 없습니다.'
--		GOTO ERR_HANDLER
--	END

	--//***************************************************************************
	--//*****************		 급/상여 자동분개 처리				 **************
	--//***************************************************************************
	--E010	급여전표, E011	상여전표
	BEGIN
	-- 커서 생성 SELECT * FROM H_IF_AUTOSLIPM_TEMP
	DECLARE	ACCNT_CUR	CURSOR	FOR
		SELECT M.CD_COMPANY, M.AUTO_DATE, AUTO_SEQ, SOURCE_TYPE, ACCOUNT_SOURCE, AUTO_SNO, DT_GIAN
		FROM H_IF_AUTOSLIPM_TEMP M WITH (NOLOCK)
		WHERE M.CD_COMPANY = @v_cd_company
		AND M.SOURCE_TYPE IN ('E010', 'E011')
		ORDER BY M.AUTO_DATE, M.AUTO_SEQ
		
		OPEN	ACCNT_CUR
		-- 커서 패치
		FETCH	NEXT	FROM	ACCNT_CUR	INTO	@v_cd_company,
													@v_auto_date,
													@v_auto_seq,
													@v_source_type,
													@v_account_source,
													@v_auto_sno,
													@v_dt_Dian
		-- 항목 처리
		WHILE	@@fetch_status	=	0
		BEGIN
		-- 자료 삭제
		DELETE FROM H_IF_SAPINTERFACE
		WHERE CD_COMPANY = @v_cd_company
		AND DRAW_DATE = @v_auto_date				-- 이관일자
		AND SEQ = @v_str_seq						-- 순번(varchar)
		AND ACCT_TYPE = @v_source_type				-- 구분E010급여, E011상여, E012, E017, E018

		--------------------------------------------------------------------------------------------------------------------
		-- Message Setting Block 
		--------------------------------------------------------------------------------------------------------------------      
		/* 에러 발생시 에러 핸들러로 분기 처리 */ 



		IF @@error <> 0
		BEGIN
			SET @v_error_number = @@error;
			SET @v_error_code = 'p_at_pay_sap_interface';
			SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 내역 삭제 중 오류가 발생하였습니다.'
			GOTO ERR_HANDLER
		END
		-- 급여/상여 select * from H_IF_SAPINTERFACE
		IF @v_source_type = 'E010' OR @v_source_type = 'E011'
		BEGIN
			DECLARE	PER_CUR	CURSOR	FOR
				SELECT m.CD_COMPANY,
					   --m.LVL_PAY1 AS ZPOSN_S,
						m.cd_position AS ZPOSN_S,
					   m.NO_PERSON AS SNO,
					   h.NM_PERSON AS SNM,
					   m.CD_COST AS COST_CENTER,
                      (select biz_acct from b_cost_center where cd_company = m.CD_COMPANY and cd_cc = m.CD_COST) as biz_acct,
					   m.FG_ACCNT,		-- 원가계정 51판관비, 제조 등등
					/*2016.05.23 테크팩솔루션 기본급 (급여/상여) 내역에 대해 기본급-상여로 예외처리  
					 직급(임원구분) '000' 임원직급*/
					 /* 2016.08.17 박현미대리 요청 상여일경우 기본급 포함 수당도 상여전표로 귀속되도록 수정 요청처리 
					  m.CD_ITEM = '001' AND */
					 CASE WHEN @V_CD_COMPANY = 'T' AND @V_SOURCE_TYPE = 'E011' AND n.TP_CODE = '1'
					 THEN	( CASE WHEN m.fg_accnt = '51' --판관비계정
										THEN ( CASE WHEN ISNULL(H.LVL_PAY1, '') = '000' THEN '51101020'
													ELSE '51103010'
												END 
											  )
								   WHEN m.fg_accnt = '81' --제조계정
										THEN (CASE WHEN  ISNULL(H.LVL_PAY1, '') = '000' THEN '81101020'
											       ELSE '81103010' 
											   END 
											 )
								   ELSE ( CASE WHEN ISNULL(H.LVL_PAY1, '') = '000' THEN ISNULL(N.CD_ACCNT2, '')
										       ELSE ISNULL(N.CD_ACCNT1, '' ) 
										   END 
										) 
							   END
							 )
					 ELSE    ( CASE WHEN ISNULL(H.LVL_PAY1, '') = '000' THEN ISNULL(N.CD_ACCNT2, '' )
								    ELSE ISNULL(N.CD_ACCNT1, '' ) 
								END 
						     )
					 END AS SAP_ACCTCODE,
					   ISNULL(m.AMT_ITEM, 0) AS AMT,
					   ISNULL(n.FG_DRCR, '') AS DBCR_GU,
					   m.YM_PAY AS PAY_YM,
					   m.DT_PROV AS PAY_DATE,
					   m.FG_SUPP AS PAY_SUPP,
					   m.CD_ITEM AS ITEM_CODE,
					   m.CD_PAYGP AS PAYGP_CODE,
					   -- 사원
					   ISNULL(n.CD_ACCNT1, '' ) AS CD_ACCNT1,
					   -- 임원
					   ISNULL(n.CD_ACCNT2, '' ) AS CD_ACCNT2,
					   -- 상대계정
					   ISNULL(n.CD_ACCNT10, '') AS CD_ACCNT10,
					   -- 정규/비정규 구분 '1'정규, '2'비정규
					   ISNULL(h.FG_PERSON, '') AS FG_PERSON
				FROM
				(
				SELECT	a.CD_COMPANY,
						a.LVL_PAY1,	-- 직급
						a.cd_position,
						a.NO_PERSON,
						a.YM_PAY,
						a.DT_PROV,
						dbo.fn_GetCodesNm('HU109', a.FG_SUPP) AS FG_SUPP,
						a.CD_PAYGP,
						b.CD_ALLOW AS CD_ITEM,
						b.AMT_ALLOW AS AMT_ITEM,
						ISNULL(( SELECT CD_COST FROM H_PER_MATCH WITH(NOLOCK) WHERE CD_COMPANY = a.CD_COMPANY AND NO_PERSON = a.NO_PERSON ), '') AS CD_COST,
						ISNULL(( SELECT TOP 1 FG_ACCT 
								 FROM B_COST_CENTER WITH(NOLOCK)
								 WHERE CD_COMPANY = a.CD_COMPANY 
								 AND CD_CC = ISNULL(( SELECT CD_COST FROM H_PER_MATCH WITH(NOLOCK) WHERE CD_COMPANY = a.CD_COMPANY AND NO_PERSON = a.NO_PERSON ), '')
						), '') AS FG_ACCNT
				FROM H_MONTH_PAY_BONUS a WITH(NOLOCK)
							INNER JOIN
								( SELECT CD_COMPANY, YM_PAY, FG_SUPP, DT_PROV,
										 NO_PERSON, CD_ALLOW, AMT_ALLOW
								  FROM H_MONTH_SUPPLY WITH (NOLOCK)
								  WHERE CD_COMPANY = @v_cd_company
								)  b ON ( a.cd_company  = b.cd_company
										AND a.YM_PAY   = b.YM_PAY
										AND a.FG_SUPP  = b.FG_SUPP
										AND a.DT_PROV  = b.DT_PROV
										AND a.NO_PERSON = b.NO_PERSON )
				WHERE a.CD_COMPANY = @v_cd_company
				AND a.DT_AUTO = @v_auto_date		-- 이관일자
				AND a.NO_AUTO = @v_auto_seq			-- 순번
				UNION ALL
				SELECT	a.CD_COMPANY,
						a.LVL_PAY1,	-- 직급
						a.cd_position,
						a.NO_PERSON,
						a.YM_PAY,
						a.DT_PROV,
						dbo.fn_GetCodesNm('HU109', a.FG_SUPP) AS FG_SUPP,
						a.CD_PAYGP,
						b.CD_DEDUCT AS CD_ITEM,
						b.AMT_DEDUCT AS AMT_ITEM,
						ISNULL(( SELECT CD_COST FROM H_PER_MATCH WITH(NOLOCK) WHERE CD_COMPANY = a.CD_COMPANY AND NO_PERSON = a.NO_PERSON ), '') AS CD_COST,
						ISNULL(( SELECT TOP 1 FG_ACCT 
								 FROM B_COST_CENTER WITH(NOLOCK)
								 WHERE CD_COMPANY = a.CD_COMPANY 
								 AND CD_CC = ISNULL(( SELECT CD_COST FROM H_PER_MATCH WITH(NOLOCK) WHERE CD_COMPANY = a.CD_COMPANY AND NO_PERSON = a.NO_PERSON ), '')
						), '') AS FG_ACCNT
				FROM H_MONTH_PAY_BONUS a WITH(NOLOCK)
							INNER JOIN
								( SELECT CD_COMPANY, YM_PAY, FG_SUPP, DT_PROV,
										 NO_PERSON, CD_DEDUCT, AMT_DEDUCT
								  FROM H_MONTH_DEDUCT WITH (NOLOCK)
								  WHERE CD_COMPANY = @v_cd_company
								)  b ON ( a.cd_company  = b.cd_company
										AND a.YM_PAY   = b.YM_PAY
										AND a.FG_SUPP  = b.FG_SUPP
										AND a.DT_PROV  = b.DT_PROV
										AND a.NO_PERSON = b.NO_PERSON )
				WHERE a.CD_COMPANY = @v_cd_company
				AND a.DT_AUTO = @v_auto_date	-- 이관일자
				AND a.NO_AUTO = @v_auto_seq
				) m INNER JOIN H_HUMAN h ON ( m.CD_COMPANY = h.CD_COMPANY AND m.NO_PERSON = h.NO_PERSON )
					LEFT OUTER JOIN
						 (  SELECT CD_COMPANY, TP_CODE, CD_ITEM, FG_ACCNT, FG_DRCR, CD_ACCNT1, CD_ACCNT2, CD_ACCNT10
							FROM H_ACCNT_PAY_ITEM_2 WITH (NOLOCK)
							WHERE CD_COMPANY = @v_cd_company
                              AND YN_USE = 'Y'
						  ) n ON (	  m.CD_COMPANY = n.CD_COMPANY
								  AND m.CD_ITEM	= n.CD_ITEM
								  AND m.FG_ACCNT = n.FG_ACCNT
								  )
				WHERE m.CD_COMPANY = @v_cd_company
				AND ISNULL(m.CD_COST, '') <> ''  --AND ISNULL(m.FG_ACCNT, '') <> '' )

				ORDER BY m.CD_COMPANY, m.NO_PERSON
				
			
				

				OPEN	PER_CUR

				-- 커서 패치
				FETCH	NEXT	FROM	PER_CUR	INTO		@v_cd_company,
															@v_zposn_s,
															@v_sno,
															@v_snm,
															@v_cost_center,
                                                            @v_gsbers,
															@v_fg_accnt,
															@v_sap_acctcode,
															@v_amt,
															@v_dbcr_gu,
															@v_pay_ym,
															@v_pay_date,
															@v_pay_supp,
															@v_item_code,
															@v_paygp_code,
															@v_cd_accnt1,
															@v_cd_accnt2,
															@v_cd_accnt10,
															@v_fg_person
				-- 개인별 처리
				WHILE	@@fetch_status	=	0

				BEGIN
					
					print('SAP_ACCTCODE : ' + @v_sap_acctcode+':'+@v_sno)
	
					SET @v_acct_type = @v_source_type;
					SET @v_ifc_sort  = @v_source_type;
					SET @v_str_seq	 = convert(varchar, @v_auto_seq);

					SET @v_rec_count  = @v_rec_count + 1;

					-------------------------------------------------------------------------------------------------------------------
					--  자 동 기 표 처리 SELECT * FROM H_IF_SAPINTERFACE
					-------------------------------------------------------------------------------------------------------------------
					-- 자료 삭제
					DELETE FROM H_IF_SAPINTERFACE
					WHERE CD_COMPANY = @v_cd_company
					AND DRAW_DATE = @v_auto_date				-- 이관일자
					AND SNO = @v_sno							-- 사번
					AND SEQ = @v_str_seq						-- 순번(varchar)
					AND ACCT_TYPE = @v_source_type				-- 구분E010급여, E011상여, E012, E017, E018
					AND ITEM_CODE = @v_item_code

					------------------------------------------------------------------------------------------------------------------
					-- Message Setting Block 
					------------------------------------------------------------------------------------------------------------------      
					/* 에러 발생시 에러 핸들러로 분기 처리 */ 
					IF @@error <> 0
					BEGIN
						SET @v_error_number = @@error;
						SET @v_error_code = 'p_at_pay_sap_interface';
						SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 내역 삭제 중 오류가 발생하였습니다.'
						GOTO ERR_HANDLER
					END
					
					
					
					-- select * from H_IF_SAPINTERFACE
					-- 이관일/ 사번 / SAP계정(sap_acctcode)/ 순서seq /이관구분@v_acct_type급여E010상여E011 /급여항목item_code
					IF @v_cost_center <> '' AND @v_acct_type <> '' AND @v_item_code <> '' --AND @v_sap_acctcode <> '' 
					BEGIN
						-- 자료 등록
						SET @v_sap_acctcode = '00' + @v_sap_acctcode
						--SEQNO_H
						SET @v_seq_h = @v_seq_h + 1
						SET @v_cost_center = '0000000000' + @v_cost_center


--select @v_cd_company, @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10),		@v_auto_date,	@v_sno, @v_snm, RIGHT(@v_cost_center,10), @v_sap_acctcode,
--							 @v_amt,		@v_dbcr_gu,		@v_str_seq,		'급여자동기표(' + @v_acct_type + ')',
--								 @v_acct_type,	'N',			@v_pay_ym,		@v_pay_date,	@v_pay_supp, @v_item_code,
--								 @v_paygp_code,	@v_ifc_sort,	@v_dt_Dian,
--								 @v_id_user,	getdate(),
--								 @v_id_user,	getdate(),
--								 @v_cd_accnt10, @v_gsbers;
						 
						
						INSERT INTO H_IF_SAPINTERFACE (
											CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, SAP_ACCTCODE,
											AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
											PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S)
						VALUES ( @v_cd_company, @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10),		@v_auto_date,	@v_sno, @v_snm, RIGHT(@v_cost_center,10), @v_sap_acctcode,
								 @v_amt,		@v_dbcr_gu,		@v_str_seq,		'급여자동기표(' + @v_acct_type + ')',
								 @v_acct_type,	'N',			@v_pay_ym,		@v_pay_date,	@v_pay_supp, @v_item_code,
								 @v_paygp_code,	@v_ifc_sort,	@v_dt_Dian,
								 @v_id_user,	getdate(),
								 @v_id_user,	getdate(),
								 @v_cd_accnt10, @v_gsbers)



						if @v_item_code in ('AME' -- 추가장기요양
											,'ANA' -- 추가국민연금
											,'ANU' -- 국민연금
											,'HIA' -- 추가고용보험
											,'HIR' -- 고용보험
											,'MEA' -- 추가건강보험
											,'MED' -- 건강보험
											,'MES' -- 노인장기요양보험
											) and @v_cd_company in ( 'A','B','C','D','O','T')
						begin


							select @tmp_fg_acct = FG_ACCT
							from (
								SELECT TOP 1 FG_ACCT FROM B_COST_CENTER WITH(NOLOCK) 
									WHERE CD_COMPANY = @v_cd_company AND right('0000000000000'+CD_CC,14) = @v_cost_center
							) A;
							
							--select @v_item_code,@tmp_fg_acct;
							
--select isnull(@v_cost_center,'')+'  :  '+isnull(@v_sap_acctcode,'') + '  :  ' + isnull(@tmp_fg_acct,'');
							if(@v_cd_company in( 'A','B','C','D','T'))
							begin
							select @v_sap_acctcode = CASE 
								WHEN @tmp_fg_acct = '51' AND @v_sap_acctcode = '0021080400' THEN '0051301020' 
								WHEN @tmp_fg_acct = '51' AND @v_sap_acctcode = '0021080501' THEN '0051301030' 
								WHEN @tmp_fg_acct = '51' AND @v_sap_acctcode = '0021080601' THEN '0051321010'
								WHEN @tmp_fg_acct = '81' AND @v_sap_acctcode = '0021080400' THEN '0081301020' 
								WHEN @tmp_fg_acct = '81' AND @v_sap_acctcode = '0021080501' THEN '0081301030' 
								WHEN @tmp_fg_acct = '81' AND @v_sap_acctcode = '0021080601' THEN '0081321010'
								WHEN @tmp_fg_acct = '52' AND @v_sap_acctcode = '0021080400' THEN '0052301020' 
								WHEN @tmp_fg_acct = '52' AND @v_sap_acctcode = '0021080501' THEN '0052301030' 
								WHEN @tmp_fg_acct = '52' AND @v_sap_acctcode = '0021080601' THEN '0052321010'
								WHEN @tmp_fg_acct = '83' AND @v_sap_acctcode = '0021080400' THEN '0083301020' 
								WHEN @tmp_fg_acct = '83' AND @v_sap_acctcode = '0021080501' THEN '0083301030' 
								WHEN @tmp_fg_acct = '83' AND @v_sap_acctcode = '0021080601' THEN '0083321010'
								WHEN @tmp_fg_acct = '84' AND @v_sap_acctcode = '0021080400' THEN '0084301020' 
								WHEN @tmp_fg_acct = '84' AND @v_sap_acctcode = '0021080501' THEN '0084301030' 
								WHEN @tmp_fg_acct = '84' AND @v_sap_acctcode = '0021080601' THEN '0084321010'
								WHEN @tmp_fg_acct = '85' AND @v_sap_acctcode = '0021080400' THEN '0085301020' 
								WHEN @tmp_fg_acct = '85' AND @v_sap_acctcode = '0021080501' THEN '0085301030' 
								WHEN @tmp_fg_acct = '85' AND @v_sap_acctcode = '0021080601' THEN '0085321010'
								WHEN @tmp_fg_acct = '88' AND @v_sap_acctcode = '0021080400' THEN '0088301020' 
								WHEN @tmp_fg_acct = '88' AND @v_sap_acctcode = '0021080501' THEN '0088301030' 
								WHEN @tmp_fg_acct = '88' AND @v_sap_acctcode = '0021080601' THEN '0088321010'
							END ;
							end;
							--select @v_item_code,@tmp_fg_acct,@v_sap_acctcode;
							if(@v_cd_company = 'O')
							begin
							select @v_sap_acctcode = CASE 
								WHEN @tmp_fg_acct = '510' AND @v_sap_acctcode = '0021110300' THEN '0051040100' 
								WHEN @tmp_fg_acct = '510' AND @v_sap_acctcode = '0021110400' THEN '0051040200' 
								WHEN @tmp_fg_acct = '510' AND @v_sap_acctcode = '0021110500' THEN '0051040400'
								WHEN @tmp_fg_acct = '523' AND @v_sap_acctcode = '0021110300' THEN '0051040100' 
								WHEN @tmp_fg_acct = '523' AND @v_sap_acctcode = '0021110400' THEN '0051040200' 
								WHEN @tmp_fg_acct = '523' AND @v_sap_acctcode = '0021110500' THEN '0051040400'
							END ;
							end;

							if not exists( 
									select * from H_IF_SAPINTERFACE 
									where cd_company = @v_cd_company and SNO = @v_sno and DRAW_DATE= @v_auto_date and SEQ = @v_str_seq and SAP_ACCTCODE = @v_sap_acctcode
							)
							begin
--print 'IF1';
								SET @v_seq_h = @v_seq_h + 1;

								INSERT INTO H_IF_SAPINTERFACE (
													CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER
													, SAP_ACCTCODE
													, AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP,
													 ITEM_CODE,
													PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S)
								VALUES ( @v_cd_company, @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10),		@v_auto_date,	@v_sno, @v_snm, RIGHT(@v_cost_center,10), 
										 @v_sap_acctcode,
										 @v_amt,		'40',		@v_str_seq,		'급여자동기표(' + @v_acct_type + ')',
										 @v_acct_type,	'N',			@v_pay_ym,		@v_pay_date,	@v_pay_supp,
										 @v_item_code+'_COM',
										 @v_paygp_code,	@v_ifc_sort,	@v_dt_Dian,
										 @v_id_user,	getdate(),
										 @v_id_user,	getdate(),
										 @v_cd_accnt10, @v_gsbers );
										 
							end
							else
							begin
--print 'IF2';
								update H_IF_SAPINTERFACE 
								set AMT = AMT + @v_amt--, ITEM_CODE = @v_item_code + '+' + ITEM_CODE
								where cd_company = @v_cd_company and SNO = @v_sno and DRAW_DATE = @v_auto_date 
									and SEQ = @v_str_seq and SAP_ACCTCODE = @v_sap_acctcode;
							end;



						end;


						--------------------------------------------------------------------------------------------------------------------
						-- Message Setting Block 
						--------------------------------------------------------------------------------------------------------------------      
						/* 에러 발생시 에러 핸들러로 분기 처리 */ 
						IF @@error <> 0
						BEGIN
							SET @v_error_number = @@error;
							SET @v_error_code = 'p_at_pay_sap_interface';
							SET @v_error_note = 'H_IF_COMP_AMOUNT_H TABLE  등록 중 오류가 발생하였습니다.'
							GOTO ERR_HANDLER
						END
					END

					-- 다음 커서 패치
					FETCH	NEXT	FROM	PER_CUR INTO	@v_cd_company,
															@v_zposn_s,
															@v_sno,
															@v_snm,
															@v_cost_center,
                                                            @v_gsbers,
															@v_fg_accnt,
															@v_sap_acctcode,
															@v_amt,
															@v_dbcr_gu,
															@v_pay_ym,
															@v_pay_date,
															@v_pay_supp,
															@v_item_code,
															@v_paygp_code,
															@v_cd_accnt1,
															@v_cd_accnt2,
															@v_cd_accnt10,
															@v_fg_person
			END

			-- 클로즈
			CLOSE	PER_CUR
			-- 커서 제거
			DEALLOCATE	PER_CUR


			BEGIN


	


------------------------------------

				-- 회사부담금 생성(시스템즈 전용)
				IF @v_cd_company in ( 'A','B','C','D','O','T')
				BEGIN
					DELETE FROM H_IF_SAPINTERFACE
					WHERE CD_COMPANY = @v_cd_company
					AND DRAW_DATE = @v_auto_date
					AND SEQ  = @v_str_seq				-- @v_str_seq
					AND SNO  = '2000'					-- 미지급금-국내 구분자
					AND ACCT_TYPE = @v_source_type

					IF @@error <> 0
					BEGIN
						SET @v_error_note = 'H_IF_SAPINTERFACE TABLE[미지급금] 삭제 중 오류가 발생하였습니다.'
						GOTO ERR_HANDLER
					END

				
						
					select @v_cost_center = max(COST_CENTER) FROM H_IF_SAPINTERFACE A
						WHERE A.CD_COMPANY = @v_cd_company
						  AND A.DRAW_DATE = @v_auto_date 
						  AND A.SEQ = @v_str_seq
						  AND A.ACCT_TYPE = @v_source_type --'E010'
						GROUP BY A.CD_COMPANY, A.DRAW_DATE, A.SEQ, A.ACCT_TYPE;
						


					INSERT INTO H_IF_SAPINTERFACE (
						CD_COMPANY, GSBER_S, LIFNR_S, 
						SEQNO_S, 
						DRAW_DATE, SNO, COST_CENTER, SAP_ACCTCODE, AMT, DBCR_GU, SEQ,
						PAY_YM, PAY_DATE, ACCT_TYPE, PAY_SUPP, 
						REMARK,  FLAG, ITEM_CODE,
						PAYGP_CODE, IFC_SORT, 
						SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE)
					SELECT KK.CD_COMPANY, KK.GSBER_S, KK.LIFNR_S
						  ,dbo.fn_HomeTax_Num((ROW_NUMBER() OVER(ORDER BY CD_COMPANY,GSBER_S)) +@v_seq_h,10) AS SEQNO_S
--						, dbo.fn_HomeTax_Num(@v_seq_h 
--								+ (case LIFNR_S when '0000600007' then 1  when '0000600008' then 2 when '0000600009' then 3 end) 
--								+ (case when CD_COMPANY ='C' and GSBER_S = '1200' then 3  else 0 end)  ,10)
						  ,KK.DRAW_DATE, '2000' AS SNO,RIGHT( @v_cost_center,10) AS COST_CENTER, KK.SAP_ACCTCODE, KK.AMT, KK.DBCR_GU, KK.SEQ
						  , KK.PAY_YM, KK.PAY_DATE,@v_source_type AS ACCT_TYPE --'E010'
						  --, '급여/상여' AS PAY_SUPP
						  , @v_pay_supp AS PAY_SUPP
						  , '미지급금-국내' AS REMARK, 'N' AS FLAG, '' AS ITEM_CODE
						  ,'none' AS PAYGP_CODE, @v_source_type AS IFC_SORT --'E010'
						  ,@v_dt_Dian AS SLIP_DATE,@v_id_user, getdate(), @v_id_user, getdate()
					FROM (
						SELECT A.CD_COMPANY
								, /*case when a.CD_COMPANY='C' and a.sno = '20080086' then '1200' else GSBER_S end as*/ GSBER_S
								, A.DRAW_DATE, '31' AS DBCR_GU, 
							   (CASE WHEN A.SAP_ACCTCODE = '0021080400' or A.SAP_ACCTCODE = '0021110300' THEN '0000600007' 
									 WHEN A.SAP_ACCTCODE = '0021080501' or A.SAP_ACCTCODE = '0021110400' THEN '0000600008' 
									 WHEN A.SAP_ACCTCODE = '0021080601' or A.SAP_ACCTCODE = '0021110500' THEN '0000600009' END) AS LIFNR_S 
							   ,'0021030101' AS SAP_ACCTCODE, SUM(A.AMT) AS AMT, A.SEQ, A.PAY_YM, A.PAY_DATE
						FROM H_IF_SAPINTERFACE A
						WHERE A.CD_COMPANY = @v_cd_company
						  AND A.DRAW_DATE = @v_auto_date 
						  AND A.SEQ = @v_str_seq
						  AND A.ACCT_TYPE = @v_source_type  --'E010'
						  AND (A.SAP_ACCTCODE IN ('0021080400', '0021080501', '0021080601')		--국민연금, 건강보험, 고용보험
							or A.SAP_ACCTCODE IN ('0021110300', '0021110400', '0021110500') )
						GROUP BY A.CD_COMPANY
							, /*case when a.CD_COMPANY='C' and a.sno = '20080086' then '1200' else GSBER_S end*/ GSBER_S
							, A.DRAW_DATE, A.SAP_ACCTCODE, A.SEQ, A.PAY_YM, A.PAY_DATE) KK

						IF @@error <> 0
						BEGIN
							SET @v_error_note = 'H_IF_SAPINTERFACE TABLE [회사부담금] 등록 중 오류가 발생하였습니다.'
							GOTO ERR_HANDLER
						END
						

					END 
------------------------------------





if @v_cd_company in ( 'A','B','C','D', 'I', 'Q', 'O','T')
begin

						

				DELETE FROM H_IF_SAPINTERFACE
				WHERE CD_COMPANY = @v_cd_company
				AND DRAW_DATE = @v_auto_date
				AND SEQ  = @v_str_seq				-- @v_str_seq
				AND SNO  = '1000'					-- 미지급금 구분자
				AND ACCT_TYPE = @v_source_type


				IF @@error <> 0
				BEGIN
					SET @v_error_note = 'H_IF_SAPINTERFACE TABLE[미지급금] 삭제 중 오류가 발생하였습니다.'
					GOTO ERR_HANDLER
				END


				-- 마지막 미지급금 처리 ACCNT_CD로 group by 해서 INSERT
				-- 1000 임의의 값 셋팅
				-- 자료 등록
				-- SET @v_sap_acctcode = '00' + @v_sap_acctcode
				-- SEQNO_H
--				SET @v_seq_h = @v_seq_h + 1
/* --시스템즈 미지급비용에 회사부담금을 넣기위해 아래걸로 수정
				INSERT INTO H_IF_SAPINTERFACE (
					CD_COMPANY, SEQNO_S, DRAW_DATE, SNO, COST_CENTER, SAP_ACCTCODE,
					AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
					PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S)
				SELECT  M.CD_COMPANY, dbo.fn_HomeTax_Num(SEQ_H + @v_seq_h,10) AS SEQ_H, M.DRAW_DATE, '1000' AS SNO, '' AS COST_CENTER, '00' + M.ACCNT_CD AS SAP_ACCTCODE,
						M.AMT,	'50' AS DBCR_GU,	M.SEQ,	'미지급금(상대계정)' AS REMAK,		M.ACCT_TYPE,	'N' AS FLAG,	M.PAY_YM,  M.PAY_DATE, M.PAY_SUPP, M.ACCNT_CD AS ITEM_CODE,
						'none' AS PAYGP_CODE,		@v_ifc_sort AS IFC_SORT,	@v_dt_Dian AS SLIP_DATE,
						@v_id_user AS ID_INSERT,	getdate() AS DT_INSERT,	@v_id_user AS ID_UPDATE, getdate() AS DT_UPDATE,  '' AS ACCNT_CD, M.GSBER_S
				FROM
				(
					SELECT  CD_COMPANY,                            
							ROW_NUMBER() OVER(ORDER BY CD_COMPANY) AS SEQ_H,
							DRAW_DATE,
							ACCNT_CD, 
							SUM(CASE WHEN DBCR_GU = '40' THEN AMT ELSE -1 * AMT END) AS AMT,
							SEQ,
							ACCT_TYPE,
							MAX(PAY_YM) AS PAY_YM,
							MAX(PAY_DATE) AS PAY_DATE,
							MAX(PAY_SUPP) AS PAY_SUPP,
							ACCNT_CD AS ITEM_CODE,
                            GSBER_S
					FROM H_IF_SAPINTERFACE
					WHERE CD_COMPANY = @v_cd_company
					AND DRAW_DATE = @v_auto_date
					AND SEQ  = @v_str_seq
					AND ACCT_TYPE = @v_source_type
					GROUP BY CD_COMPANY, DRAW_DATE, SEQ, ACCT_TYPE, ACCNT_CD, GSBER_S
				) M		
*/		

				
				--SET @v_seq_h = @v_seq_h + 3;


					SELECT @v_seq_h = @v_seq_h + count(*)
					FROM (
						SELECT A.CD_COMPANY, A.GSBER_S, A.DRAW_DATE, '31' AS DBCR_GU, 
							   (CASE WHEN A.SAP_ACCTCODE = '0021080400' or A.SAP_ACCTCODE = '0021110300' THEN '0000600007' 
									 WHEN A.SAP_ACCTCODE = '0021080501' or A.SAP_ACCTCODE = '0021110400' THEN '0000600008' 
									 WHEN A.SAP_ACCTCODE = '0021080601' or A.SAP_ACCTCODE = '0021110500' THEN '0000600009' END) AS LIFNR_S 
							   ,'0021030101' AS SAP_ACCTCODE, SUM(A.AMT) AS AMT, A.SEQ, A.PAY_YM, A.PAY_DATE
						FROM H_IF_SAPINTERFACE A
						WHERE A.CD_COMPANY = @v_cd_company
						  AND A.DRAW_DATE = @v_auto_date 
						  AND A.SEQ = @v_str_seq
						  AND A.ACCT_TYPE = @v_source_type  --'E010'
						  AND (A.SAP_ACCTCODE IN ('0021080400', '0021080501', '0021080601')		--국민연금, 건강보험, 고용보험
							or A.SAP_ACCTCODE IN ('0021110300', '0021110400', '0021110500') )
						GROUP BY A.CD_COMPANY, A.GSBER_S, A.DRAW_DATE, A.SAP_ACCTCODE, A.SEQ, A.PAY_YM, A.PAY_DATE) KK

		if @v_source_type = 'E011'
		begin
			print 'E011'
				INSERT INTO H_IF_SAPINTERFACE (
					CD_COMPANY, SEQNO_S, DRAW_DATE, SNO, COST_CENTER, SAP_ACCTCODE,
					AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
					PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S)
				SELECT  M.CD_COMPANY
						, dbo.fn_HomeTax_Num(SEQ_H + @v_seq_h,10) AS SEQ_H, M.DRAW_DATE, '1000' AS SNO
						, RIGHT(@v_cost_center,10) AS COST_CENTER, '00' + M.ACCNT_CD AS SAP_ACCTCODE,
						M.AMT,	'50' AS DBCR_GU,	M.SEQ,	'미지급금(상대계정)' AS REMAK,		M.ACCT_TYPE,	'N' AS FLAG,	M.PAY_YM,  M.PAY_DATE, M.PAY_SUPP, M.ACCNT_CD AS ITEM_CODE,
						'none' AS PAYGP_CODE,		@v_ifc_sort AS IFC_SORT,	@v_dt_Dian AS SLIP_DATE,
						@v_id_user AS ID_INSERT,	getdate() AS DT_INSERT,	@v_id_user AS ID_UPDATE, getdate() AS DT_UPDATE,  '' AS ACCNT_CD, M.GSBER_S
				FROM
				(
					SELECT  CD_COMPANY,                            
							ROW_NUMBER() OVER(ORDER BY CD_COMPANY) AS SEQ_H,
							DRAW_DATE,
							 case when CD_COMPANY in('A','B','C','D','O','T') and DBCR_GU='31' then '21100300' else ACCNT_CD end as ACCNT_CD, 
							SUM(CASE WHEN DBCR_GU = '40' /* or ( CD_COMPANY='C'and DBCR_GU='31' )*/ THEN AMT ELSE -1 * AMT END) AS AMT,
							SEQ,
							ACCT_TYPE,
							MAX(PAY_YM) AS PAY_YM,
							MAX(PAY_DATE) AS PAY_DATE,
							MAX(PAY_SUPP) AS PAY_SUPP,
							case when CD_COMPANY in('A','B','C','D','O','T') and DBCR_GU='31' then '21100300' else ACCNT_CD end AS ITEM_CODE,
                            /*case when CD_COMPANY='C' and sno = '20080086' then '1200' else GSBER_S end as*/ GSBER_S
					FROM H_IF_SAPINTERFACE
					WHERE CD_COMPANY = @v_cd_company
					AND DRAW_DATE = @v_auto_date
					AND SEQ  = @v_str_seq
					AND ACCT_TYPE = @v_source_type
					GROUP BY CD_COMPANY, DRAW_DATE, SEQ, ACCT_TYPE,  case when CD_COMPANY in('A','B','C','D','O','T')and DBCR_GU='31' then '21100300' else ACCNT_CD end
						, /*case when CD_COMPANY='C' and sno = '20080086' then '1200' else GSBER_S end*/ GSBER_S
				) M	


				IF @@error <> 0
				BEGIN
					SET @v_error_note = 'H_IF_SAPINTERFACE TABLE [미지급금] 등록 중 오류가 발생하였습니다.'
					GOTO ERR_HANDLER
				END
		end
		else
		begin

				INSERT INTO H_IF_SAPINTERFACE (
					CD_COMPANY, SEQNO_S, DRAW_DATE, SNO, COST_CENTER, SAP_ACCTCODE,
					AMT, DBCR_GU, SEQ, REMARK, ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, ITEM_CODE,
					PAYGP_CODE, IFC_SORT, SLIP_DATE, ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S)
				SELECT  M.CD_COMPANY
						, dbo.fn_HomeTax_Num(SEQ_H + @v_seq_h,10) AS SEQ_H, M.DRAW_DATE, '1000' AS SNO
						, RIGHT(@v_cost_center,10) AS COST_CENTER, '00' + M.ACCNT_CD AS SAP_ACCTCODE,
						M.AMT,	'50' AS DBCR_GU,	M.SEQ,	'미지급금(상대계정)' AS REMAK,		M.ACCT_TYPE,	'N' AS FLAG,	M.PAY_YM,  M.PAY_DATE, M.PAY_SUPP, M.ACCNT_CD AS ITEM_CODE,
						'none' AS PAYGP_CODE,		@v_ifc_sort AS IFC_SORT,	@v_dt_Dian AS SLIP_DATE,
						@v_id_user AS ID_INSERT,	getdate() AS DT_INSERT,	@v_id_user AS ID_UPDATE, getdate() AS DT_UPDATE,  '' AS ACCNT_CD, M.GSBER_S
				FROM
				(
					SELECT  CD_COMPANY,                            
							ROW_NUMBER() OVER(ORDER BY CD_COMPANY) AS SEQ_H,
							DRAW_DATE,
							 case when CD_COMPANY in('A','B','C','D','O','T') and DBCR_GU='31' then '21100300' else ACCNT_CD end as ACCNT_CD, 
							SUM(CASE WHEN DBCR_GU = '40' /* or ( CD_COMPANY='C'and DBCR_GU='31' )*/ THEN AMT ELSE -1 * AMT END) AS AMT,
							SEQ,
							ACCT_TYPE,
							MAX(PAY_YM) AS PAY_YM,
							MAX(PAY_DATE) AS PAY_DATE,
							MAX(PAY_SUPP) AS PAY_SUPP,
							case when CD_COMPANY in('A','B','C','D','O','T') and DBCR_GU='31' then '21100300' else ACCNT_CD end AS ITEM_CODE,
                            /*case when CD_COMPANY='C' and sno = '20080086' then '1200' else GSBER_S end as*/ GSBER_S
					FROM H_IF_SAPINTERFACE
					WHERE CD_COMPANY = @v_cd_company
					AND DRAW_DATE = @v_auto_date
					AND SEQ  = @v_str_seq
					AND ACCT_TYPE = @v_source_type
					GROUP BY CD_COMPANY, DRAW_DATE, SEQ, ACCT_TYPE,  case when CD_COMPANY in('A','B','C','D','O','T')and DBCR_GU='31' then '21100300' else ACCNT_CD end
						, /*case when CD_COMPANY='C' and sno = '20080086' then '1200' else GSBER_S end*/ GSBER_S
				) M	


				IF @@error <> 0
				BEGIN
					SET @v_error_note = 'H_IF_SAPINTERFACE TABLE [미지급금] 등록 중 오류가 발생하였습니다.'
					GOTO ERR_HANDLER
				END
		end
end;

/* 테크팩솔루션 코스트센터,회계계정 관련 예외처리 요청자: 김선일
1) 코스트센터: 테크팩 코스트센터에 영문자 포함으로 앞에 붙여주는 '000000' 빼주기
2) 회계계정(sap_acctcode) 필드가 
	21080400 국민연금예수금 / 21080501 건강보험예수금 / 21080601 고용보험예수금인 경우 차/대(dbcr_gu)를 50으로 변경*/

if @v_cd_company = 'T'
	begin
		UPDATE H_IF_SAPINTERFACE
		SET DBCR_GU = '50'
		WHERE 1=1
		AND DRAW_DATE = @v_auto_date				-- 이관일자
		AND SEQ = @v_str_seq						-- 순번(varchar)
		AND ACCT_TYPE = @v_source_type	
		AND SAP_ACCTCODE IN ('0021080400','0021080501','0021080601')

		UPDATE H_IF_SAPINTERFACE
		SET COST_CENTER = SUBSTRING(COST_CENTER,7,4)
		WHERE 1=1
		AND DRAW_DATE = @v_auto_date				-- 이관일자
		AND SEQ = @v_str_seq						-- 순번(varchar)
		AND ACCT_TYPE = @v_source_type	
	end;

------하자보수 충당금 처리(현재 대상 없음 18.03.19)
--if @v_cd_company = ('A')
--begin
--UPDATE H_IF_SAPINTERFACE  
--SET SAP_ACCTCODE = '21090200'
--WHERE CD_COMPANY = @v_cd_company
--	AND DRAW_DATE = @v_auto_date
--	AND SEQ  = @v_str_seq
--	AND IFC_SORT = @v_acct_type
--	and SAP_ACCTCODE in ('0051102010','0051102020')
--	and SNO in ('20144049'); --2016.10.04 손민정 주임 요청으로 20164098 추가
--	-- 2018.01.18 손민정 대리 요청으로 추가(20030042, 20070184, 20080066)
--	-- 2018.03.19 손민정 대리 요청으로 삭제(20030042, 20070184, 20080066, 20144045, 20144046, 20144047, 20144048, 20154020, 20164098)

--end;
---------------------------------
---------------------------------

--				IF @@rowcount > 0
--				BEGIN
					-- @v_auto_date + @v_auto_seq
					-- SELECT * FROM H_IF_AUTOSLIPM TABLE UPDATE 처리
					-- 회계단위 + 이관일자 + 순번
--					SELECT TOP 1 @v_cd_acctu = CD_ACCTU
--					FROM B_HUMAN_DEPT WITH (NOLOCK)
--					WHERE CD_COMPANY = @v_cd_company
--					  AND CD_ACCTU <> ''	-- 회계단위 있는 부서에서만 가져옴.
--					ORDER BY CD_ORG

--					IF @@error <> 0
--					BEGIN
--						SET @v_error_note = 'B_HUMAN_DEPT TABLE 회계단위 검색 중 오류가 발생하였습니다.'
--						GOTO ERR_HANDLER
--					END


declare @MSEQ as int;
/* 전표번호 생성용 순번 찾아오는 부분*/
-- 전기일기준으로 생성한다.
SELECT @MSEQ = MAX(cast(SEQ as int))
FROM H_IF_SAPINTERFACE
WHERE CD_COMPANY = @p_cd_compnay
AND SLIP_DATE = @p_dt_gian;

--select @MSEQ = isnull(@MSEQ,0) + 1;

--전표번호 중복문제처리....
while(1=1)
begin
	if exists ( select top 1 SEQ_H from H_IF_SAPINTERFACE where SEQ_H = (select @v_cd_company + @v_dt_gian + convert(varchar,dbo.fn_HomeTax_Num(@MSEQ, 4))))
	begin 
		--select @MSEQ,1; 
		select @MSEQ = isnull(@MSEQ,0) + 1; 
	end;
	else 
	begin 
		break; 
	end;
	--select @MSEQ;
end;

SET @v_slip_nbr = @v_cd_company + @v_dt_gian + convert(varchar,dbo.fn_HomeTax_Num(@MSEQ, 4));

					--SET @v_slip_nbr = @v_cd_company + @v_dt_gian + convert(varchar,dbo.fn_HomeTax_Num(@v_auto_seq, 4));


					-- 전표 update
					UPDATE H_IF_AUTOSLIPM SET SLIP_NBR = @v_slip_nbr, AUTO_SEQ = @MSEQ
					WHERE CD_COMPANY = @v_cd_company
					AND AUTO_DATE = @v_auto_date
					AND AUTO_SEQ  = @v_str_seq
					AND SOURCE_TYPE = @v_acct_type

					-- 전표 update (H_IF_SAPINTERFACE)

					UPDATE H_IF_SAPINTERFACE  SET SEQ_H = @v_slip_nbr, SEQ = @MSEQ
					WHERE CD_COMPANY = @v_cd_company
					AND DRAW_DATE = @v_auto_date
					AND SEQ  = @v_str_seq
					AND IFC_SORT = @v_acct_type



				update H_IF_AUTOSEQ set AUTO_MAX_SEQ = @MSEQ
				WHERE CD_COMPANY = @v_cd_company
				AND AUTO_DATE  = CONVERT(NVARCHAR(8), GETDATE(), 112) 
				
	
					--------------------------------------------------------------------------------------------------------------------
					-- Message Setting Block 
					--------------------------------------------------------------------------------------------------------------------      
					/* 에러 발생시 에러 핸들러로 분기 처리 */ 
					IF @@error <> 0
					BEGIN
						SET @v_error_number = @@error;
						SET @v_error_code = 'p_at_pay_sap_interface';
						SET @v_error_note = 'H_IF_AUTOSLIPM TABLE  갱신 중 오류가 발생하였습니다.'
						GOTO ERR_HANDLER
					END
--				END
			END
		END

		SET @v_rec_count = 0;

NEXT_ACCNT_CUR:
		-- 다음 커서 패치
		FETCH	NEXT	FROM	ACCNT_CUR INTO		@v_cd_company,
													@v_auto_date,
													@v_auto_seq,
													@v_source_type,
													@v_account_source,
													@v_auto_sno,
													@v_dt_Dian
		END
		-- 클로즈
		CLOSE	ACCNT_CUR
		-- 커서 제거
		DEALLOCATE	ACCNT_CUR
	END

	RETURN			/* 끝 */

  -----------------------------------------------------------------------------------------------------------------------
  -- END Message Setting Block 
  ----------------------------------------------------------------------------------------------------------------------- 
  ERR_HANDLER:
		begin try

			DEALLOCATE	ACCNT_CUR;
			DEALLOCATE	PER_CUR;
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

	EXECUTE p_ba_errlib_getusererrormsg @v_cd_company, 'p_at_pay_sap_interface',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

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

	EXECUTE p_ba_errlib_getusererrormsg @v_cd_company, 'p_at_pay_sap_interface',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

		begin try

			DEALLOCATE	ACCNT_CUR;
			DEALLOCATE	PER_CUR;
		end try
		begin catch
		print 'Error CATCH Process Block';
		end catch;

	RETURN
END CATCH
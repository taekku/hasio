USE [dwehrdev]
GO
/****** Object:  StoredProcedure [dbo].[p_at_app_sap_interface]    Script Date: 2020-12-01 오후 3:20:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Create date: <Create Date,,2010.01>
-- Description:	<Description,,퇴직충당금 분개처리 >
-- =============================================
/* Execute Sample
H_ERRORLOG

 DECLARE 
      @p_error_code VARCHAR(30), 
      @p_error_str VARCHAR(500) 
 BEGIN
      SET @p_error_code = ''; 
      SET @p_error_str = ''; 
      EXECUTE p_at_app_sap_interface
      'I',
      '20100131',
      '',
      '',
      '',
      '',
      '',
      '',
      'newikim',
      @p_error_code OUTPUT,		-- @p_error_code      VARCHAR(30) 
      @p_error_str OUTPUT 		-- @p_error_str       VARCHAR(500) 
 END

*/
ALTER PROCEDURE [dbo].[p_at_app_sap_interface] (
							  @p_cd_compnay		 VARCHAR(10),						-- 회사코드
							  @p_dt_gian		 VARCHAR(8) ,						-- 품의일자
                              @p_pay_group		 VARCHAR(10),						-- 급여그룹
                              @P_retr_annu       VARCHAR(10),                       -- 연급종류
                              @p_tp_duty         VARCHAR(2),                        -- 관리구분
                              @p_fr_Dept         VARCHAR(10),                       -- 부서코드(From)
                              @p_to_Dept         VARCHAR(10),                       -- 부서코드(To)
                              @p_cd_person       VARCHAR(10),                       -- 사원
							  @p_id_user		 VARCHAR(20) ,						-- 사용자ID
                              @p_error_code      VARCHAR(1000) OUTPUT,				-- 에러코드 리턴
                              @p_error_str       VARCHAR(3000) OUTPUT				-- 에러메시지 리턴
                              )                                                                              
AS
SET NOCOUNT ON
-- 임시 테이블 생성(퇴직추계액 내역 저장)
--DROP TABLE #TEMP_HUMAN
CREATE TABLE #TEMP_HUMAN
	(
	CD_COMPANY [nvarchar](10) NULL,						--* 회사코드
	CD_DEPT [nvarchar](10) NULL,						--* 부서코드
	NO_PERSON [nvarchar](10) NULL,						--* 사번
	NM_PERSON [nvarchar](20) NULL,						--* 성명
	LVL_PAY1  [nvarchar](10) NULL,						--* 직급
	YN_RETPENSION [nvarchar](2) NULL,					--* 연금가입여부
	FG_RETPENSION_KIND [nvarchar](10) NULL,				--* 연금종류
	AMT_RETR_PAY [numeric](18,0) NULL,					--* 충당금
	ACCT_GU [nvarchar](10) NULL,						--* 계정구분
	CD_CC [nvarchar](10) NULL,							--* 코스트센터
    PAY_GROUP [nvarchar](10) NULL						--* 급여그룹
)

DECLARE
   /* 프로시저 내에서 사용할 변수 정의  */
	@v_cd_company				VARCHAR(10),										-- 회사코드
	@v_cd_dept					VARCHAR(20),										-- 부서코드
	@v_no_person				VARCHAR(10),										-- 사번
	@v_nm_person				VARCHAR(20),										-- 성명
	@v_yn_retpension			VARCHAR(1), 										-- 연금가입여부
	@v_fg_retpension_kind		VARCHAR(10),										-- 연금종류
	@v_amt_retr_pay				NUMERIC(18,0),										-- 충당금
	@v_fg_drcr					VARCHAR(4),											-- 차/대변
    @v_cd_accnt_dr              VARCHAR(20),										-- 계정코드(계정)
    @v_cd_accnt_cr              VARCHAR(20),										-- 계정코드(상대계정)
	@v_cd_accnt1				VARCHAR(20),										-- 계정코드(연금미가입자)
	@v_cd_accnt2				VARCHAR(20),										-- 계정코드(연금미가입자-상대계정)
	@v_cd_accnt3				VARCHAR(20),										-- 계정코드(연금DB형가입자)
	@v_cd_accnt4				VARCHAR(20),										-- 계정코드(연금DB형가입자-상대계정)
	@v_cd_accnt5				VARCHAR(20),										-- 계정코드(연금DC형가입자)
	@v_cd_accnt6				VARCHAR(20),										-- 계정코드(연금DC형가입자-상대계정)
    @v_acct_gu					VARCHAR(10),										-- 계정구분
    @v_cd_cc                    VARCHAR(20),										-- 코스트센터
    @v_pay_group                VARCHAR(10),                                        -- 급여그룹

	@v_id_user					VARCHAR(20),										-- 사용자ID
    @v_dt_gian					VARCHAR(6) ,										-- 급여년월 PK : 1	
	@v_auto_sno					VARCHAR(20) ,
	@v_dt_dian					VARCHAR(10) ,			-- 품의일자
	@v_seq						NUMERIC(18,0),			-- 순번 numeric
	@v_str_seq					VARCHAR(10),			-- 순번 varchar

	@v_seq_h					VARCHAR(10),		-- SEQNO_S dp에 들어갈 값
    @v_gsbers					VARCHAR(20),		-- 사업부문
	@v_zposn_s					VARCHAR(10),		-- 직급
	@v_slip_nbr					VARCHAR(20),

	@v_rsn_paygp_where			VARCHAR(MAX),
	@v_sql						VARCHAR(MAX),

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


BEGIN TRY
	/* 변수에 대한 초기화 처리 */
	SET @v_error_code = '';
	SET @v_error_note = '';
	SET @v_seq_h	  = 0;

	/* 파라메터를 로컬변수로 처리하며 이때 NULL일 경우에 필요한 처리를 한다. */
	SET @v_dt_dian		= @p_dt_gian;
	SET @v_dt_gian      = left(@p_dt_gian,6);
	SET @v_id_user		= @p_id_user;		-- 로그인사용자



	-- 오류TABLE삭제
	DELETE FROM H_ERRORLOG
	WHERE CD_COMPANY = @p_cd_compnay
	AND ERROR_PROCEDURE = 'p_at_app_sap_interface'

	--------------------------------------------------------------------------------------------------------------------
	-- Message Setting Block 
	--------------------------------------------------------------------------------------------------------------------      
	/* 에러 발생시 에러 핸들러로 분기 처리 */ 
	IF @@error <> 0
	BEGIN
		SET @v_error_number = @@error;
		SET @v_error_code = 'p_at_app_sap_interface';
		SET @v_error_note = '오류TABLE삭제 중 오류가 발생하였습니다.'
		GOTO ERR_HANDLER
	END

	--//***************************************************************************
	--//*****************		 퇴직충당금 분개 처리				 **************
	--//***************************************************************************
	BEGIN
		-- SAP I/F 테이블 삭제
		if @p_pay_group = ''
			begin
				DELETE FROM H_IF_SAPINTERFACE
				WHERE CD_COMPANY = @p_cd_compnay
				  AND DRAW_DATE = @v_dt_dian					-- 이관일자		
				  AND ACCT_TYPE = 'E012'	
				  AND FLAG = 'N'	
			end
		else
			begin
				DELETE FROM H_IF_SAPINTERFACE
				WHERE CD_COMPANY = @p_cd_compnay
				  AND DRAW_DATE = @v_dt_dian					-- 이관일자		
				  AND ACCT_TYPE = 'E012'
                  AND PAYGP_CODE = @p_pay_group		
				  AND FLAG = 'N'	
			end
	
		--------------------------------------------------------------------------------------------------------------------
		-- Message Setting Block 
		--------------------------------------------------------------------------------------------------------------------      
		/* 에러 발생시 에러 핸들러로 분기 처리 */ 
		IF @@error <> 0
		BEGIN
			SET @v_error_number = @@error;
			SET @v_error_code = 'p_at_app_sap_interface';
			SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 내역 삭제 중 오류가 발생하였습니다.'
			GOTO ERR_HANDLER
		END

		-- 급여그룹 조건 가져오기
		IF @p_pay_group <> ''
			BEGIN
				SELECT @v_rsn_paygp_where = (CASE WHEN ISNULL(LTRIM(H_PAY_GROUP.RSN_PAYGP_WHERE),'') = '' THEN '' ELSE LTRIM(H_PAY_GROUP.RSN_PAYGP_WHERE) END)
				FROM H_PAY_GROUP WITH(NOLOCK)
				WHERE H_PAY_GROUP.CD_COMPANY = @p_cd_compnay
				AND H_PAY_GROUP.CD_PAYGP = @p_pay_group;
			END 

		-- 퇴직추계액 내역, 임시테이블에 생성
		SET @v_sql = '';
/*		SET @v_sql = ' INSERT INTO #TEMP_HUMAN ' + CHAR(13)
		SET @v_sql = @v_sql + ' SELECT A.CD_COMPANY ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,A.CD_DEPT ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,A.NO_PERSON ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,H_HUMAN.NM_PERSON ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,A.LVL_PAY1 ' + CHAR(13)		-- 직급
		SET @v_sql = @v_sql + ' 		  ,A.YN_RETPENSION ' + CHAR(13)			--연금가입여부
		SET @v_sql = @v_sql + ' 		  ,A.FG_RETPENSION_KIND ' + CHAR(13)		--연금종류
		SET @v_sql = @v_sql + ' 		  ,ISNULL((SELECT SUM(N.AMT_RETR_PAY) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				 FROM H_RETIRE_DETAIL N WITH(NOLOCK) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				 WHERE N.CD_COMPANY = ''I'' ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND N.FG_RETR = ''1'' ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND LEFT(N.DT_RETR, 6) = ''' + @v_dt_gian + '''' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND N.NO_PERSON = A.NO_PERSON), 0) ' + CHAR(13)							-- 지급액
		SET @v_sql = @v_sql + ' 			  + ISNULL((SELECT SUM(N.AMT_RETR_PAY) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				  FROM H_RETIRE_DETAIL N WITH(NOLOCK) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				 WHERE N.CD_COMPANY = A.CD_COMPANY ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND N.FG_RETR = ''2'' ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND LEFT(N.DT_RETR, 6) = ''' + @v_dt_gian + '''' + CHAR(13) 
		SET @v_sql = @v_sql + '				   AND N.NO_PERSON = A.NO_PERSON), 0) ' + CHAR(13)						--당월퇴직추계액
		SET @v_sql = @v_sql + ' 			  - ISNULL((SELECT SUM(N.AMT_RETR_PAY) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				  FROM H_RETIRE_DETAIL N WITH(NOLOCK) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				 WHERE N.CD_COMPANY = A.CD_COMPANY ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND N.FG_RETR = ''2'' ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND LEFT(N.DT_RETR, 6) = LEFT(CONVERT(VARCHAR(8), DATEADD(MM, -1,''' + @v_dt_dian + '''), 112),6) ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 				   AND N.NO_PERSON = A.NO_PERSON), 0) AS AMT_RETR_PAY, ' + CHAR(13)	    --전월퇴직추계액
		SET @v_sql = @v_sql + '           (SELECT ACCT_GU FROM B_HUMAN_DEPT WHERE CD_COMPANY = A.CD_COMPANY AND CD_HUMAN_DEPT = A.CD_DEPT) AS ACCT_GU, ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  (SELECT CD_COST FROM H_PER_MATCH WHERE CD_COMPANY = A.CD_COMPANY AND NO_PERSON = A.NO_PERSON) AS CD_CC, ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  (select CD_PAYGP from H_MONTH_PAY_BONUS WHERE CD_COMPANY = A.CD_COMPANY AND YM_PAY = ''' + @v_dt_gian + '''' + CHAR(13) 
		SET @v_sql = @v_sql + ' 		   AND NO_PERSON = A.NO_PERSON GROUP BY CD_PAYGP, YM_PAY) AS PAY_GROUP ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 	FROM H_RETIRE_DETAIL A WITH(NOLOCK) ' + CHAR(13)  
		SET @v_sql = @v_sql + ' 		  INNER JOIN H_HUMAN WITH(NOLOCK) ON ( A.CD_COMPANY = H_HUMAN.CD_COMPANY AND A.NO_PERSON = H_HUMAN.NO_PERSON ) ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 		  INNER JOIN H_PAY_MASTER C WITH(NOLOCK) ON ( A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON ) ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 	WHERE A.CD_COMPANY = ''' +  @p_cd_compnay + '''' + CHAR(13)
*/


		-- 약간수정 
		SET @v_sql = ' INSERT INTO #TEMP_HUMAN ' + CHAR(13)
		SET @v_sql = @v_sql + ' SELECT A.CD_COMPANY ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,A.CD_DEPT ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,A.NO_PERSON ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,H_HUMAN.NM_PERSON ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,A.CD_POSITION ' + CHAR(13)		-- 직위
		SET @v_sql = @v_sql + ' 		  ,A.YN_RETPENSION ' + CHAR(13)			--연금가입여부
		SET @v_sql = @v_sql + ' 		  ,A.FG_RETPENSION_KIND ' + CHAR(13)		--연금종류
		SET @v_sql = @v_sql + ' 		  ,ISNULL((SELECT SUM(N.AMT_RETR_PAY) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				 FROM H_RETIRE_DETAIL N WITH(NOLOCK) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				 WHERE N.CD_COMPANY = A.CD_COMPANY ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND N.FG_RETR = ''1'' ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND LEFT(N.DT_RETR, 6) = ''' + @v_dt_gian + '''' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND N.NO_PERSON = A.NO_PERSON), 0) ' + CHAR(13)							-- 지급액
		SET @v_sql = @v_sql + ' 			  + ISNULL((SELECT SUM(N.AMT_RETR_PAY) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				  FROM H_RETIRE_DETAIL N WITH(NOLOCK) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				 WHERE N.CD_COMPANY = A.CD_COMPANY ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND N.FG_RETR = ''2'' ' + CHAR(13)
		SET @v_sql = @v_sql + ' 				   AND LEFT(N.DT_RETR, 6) = ''' + @v_dt_gian + '''' + CHAR(13) 
		SET @v_sql = @v_sql + '				   AND N.NO_PERSON = A.NO_PERSON), 0) ' + CHAR(13)						--당월퇴직추계액

-- DC형은 1월달 전월추계액을 0으로 한다
--		SET @v_sql = @v_sql + ' 			  - ISNULL((SELECT SUM(N.AMT_RETR_PAY) ' + CHAR(13)
		
		--SET @v_sql = @v_sql + ' 			  - case when right(''' + @v_dt_gian + ''',2) = ''01'' and CD_RETR_ANNU = ''DC'' and left(isnull(H_HUMAN.DT_RETIRE,''''),6) <> ''' + @v_dt_gian + ''' then 0 else ISNULL((SELECT SUM(N.AMT_RETR_PAY) ' + CHAR(13)
		-- 201312부터 12월은 전달추계가 0 -> 해당월 퇴사시는 0아님
		--SET @v_sql = @v_sql + ' 			  - case when right(''' + @v_dt_gian + ''',2) = ''12'' and CD_RETR_ANNU = ''DC''  and left(isnull(H_HUMAN.DT_RETIRE,''''),6) <> ''' + @v_dt_gian + ''' then 0 else ISNULL((SELECT SUM(N.AMT_RETR_PAY) ' + CHAR(13)
		--201601부터
		SET @v_sql = @v_sql + ' 			  -  ISNULL(
												 case when a.FG_RETPENSION_KIND=''DC'' and substring(a.dt_base,5,2)=''01'' then 0  													else (SELECT SUM(N.AMT_RETR_PAY) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 							 FROM H_RETIRE_DETAIL N WITH(NOLOCK) ' + CHAR(13)
		SET @v_sql = @v_sql + ' 							 WHERE N.CD_COMPANY = A.CD_COMPANY ' + CHAR(13)
		SET @v_sql = @v_sql + ' 							   AND N.FG_RETR = ''2'' ' + CHAR(13)
		SET @v_sql = @v_sql + ' 							   AND LEFT(N.DT_RETR, 6) = LEFT(CONVERT(VARCHAR(8), DATEADD(MM, -1,''' + @v_dt_dian + '''), 112),6) ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 							  AND N.NO_PERSON = A.NO_PERSON)
													end, 0)  AS AMT_RETR_PAY, ' + CHAR(13)	    --전월퇴직추계액
		SET @v_sql = @v_sql + '           F.FG_ACCT AS ACCT_GU,  ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  D.CD_COST AS CD_CC, ' + CHAR(13)
--		SET @v_sql = @v_sql + ' 		  isnull(E.CD_PAYGP, ( select case ' + CHAR(13)
--		SET @v_sql = @v_sql + ' 				when H_HUMAN.CD_REG_BIZ_AREA IN (''D101'') then ''CA01''	' + CHAR(13)
--		SET @v_sql = @v_sql + ' 				when H_HUMAN.CD_REG_BIZ_AREA IN (''D500'') AND H_HUMAN.TP_DUTY IN (''M'') then ''CB01''	' + CHAR(13)
--		SET @v_sql = @v_sql + ' 				when H_HUMAN.CD_REG_BIZ_AREA IN (''D500'') AND H_HUMAN.TP_DUTY IN (''B'') then ''CB02''	' + CHAR(13)
--		SET @v_sql = @v_sql + ' 				when H_HUMAN.CD_REG_BIZ_AREA IN (''D100'',''D200'',''D300'',''D600'') AND H_HUMAN.TP_DUTY IN (''O'') then ''CC01''	' + CHAR(13)
--		SET @v_sql = @v_sql + ' 				when H_HUMAN.CD_REG_BIZ_AREA IN (''D400'') then ''CD01''	' + CHAR(13)
--		SET @v_sql = @v_sql + ' 				when H_HUMAN.CD_REG_BIZ_AREA IN (''D100'',''D200'',''D300'') AND H_HUMAN.TP_DUTY IN (''B'') then ''CE01''	' + CHAR(13)
--		SET @v_sql = @v_sql + '         		when H_HUMAN.CD_REG_BIZ_AREA IN (''D100'',''D200'',''D300'') then ''CF01''	' + CHAR(13)
--		SET @v_sql = @v_sql + ' 				when H_HUMAN.CD_REG_BIZ_AREA IN (''Z100'') then ''CZ01''	end ' + CHAR(13)
--		SET @v_sql = @v_sql + ' 				from h_human where cd_company =''' +  @p_cd_compnay + ''' and no_person = ''' + @p_cd_person + ''' ) ) AS PAY_GROUP ' + CHAR(13) 

		SET @v_sql = @v_sql + ' 		  '''+@p_pay_group+'''  AS PAY_GROUP ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 	FROM H_RETIRE_DETAIL A WITH(NOLOCK) ' + CHAR(13)  
		SET @v_sql = @v_sql + ' 		  INNER JOIN H_HUMAN WITH(NOLOCK) ON ( A.CD_COMPANY = H_HUMAN.CD_COMPANY AND A.NO_PERSON = H_HUMAN.NO_PERSON ) ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 		  INNER JOIN H_PAY_MASTER C WITH(NOLOCK) ON ( A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON ) ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 		  left outer join H_PER_MATCH D on D.CD_COMPANY = A.CD_COMPANY AND D.NO_PERSON = A.NO_PERSON ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 		  left outer join B_COST_CENTER F on D.CD_COMPANY = F.CD_COMPANY AND D.CD_COST = F.CD_CC ' + CHAR(13) 
		
		--실행해보면 의미없어서 뺌
		--SET @v_sql = @v_sql + ' 		  left outer join (select CD_PAYGP, NO_PERSON from H_MONTH_PAY_BONUS WHERE CD_COMPANY = ''' +  @p_cd_compnay + ''' AND YM_PAY = ''' 
		--					+ @v_dt_gian + ''' GROUP BY NO_PERSON,CD_PAYGP ) E on E.NO_PERSON = A.NO_PERSON ' + CHAR(13) 


		SET @v_sql = @v_sql + ' 	WHERE A.CD_COMPANY = ''' +  @p_cd_compnay + '''' + CHAR(13)
		SET @v_sql = @v_sql + ' 	  AND A.FG_RETR = ''2'' ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 	  AND A.DT_BASE = ''' + @v_dt_dian + '''' + CHAR(13)

		IF @p_cd_compnay in ('A','B','C')
		begin
			 -- 하우징 제외
			SET @v_sql = @v_sql + ' 	  AND A.CD_DEPT <> ''Z999'' ' + CHAR(13)
			-- DC형만 전표처리
			SET @v_sql = @v_sql + ' 	  AND A.fg_retpension_kind = ''DC'' ' + CHAR(13)
		end


		IF @v_rsn_paygp_where <> ''-- 급여그룹
			SET @v_sql = @v_sql + ' 	  AND ' + @v_rsn_paygp_where + '' + CHAR(13)
		IF @P_retr_annu <> ''-- 연급종류
			SET @v_sql = @v_sql + ' 	  AND C.CD_RETR_ANNU = ''' + @P_retr_annu + '''' + CHAR(13)
		IF @p_tp_duty <> ''-- 관리구분
			SET @v_sql = @v_sql + ' 	  AND A.TP_DUTY = ''' + @p_tp_duty + '''' + CHAR(13)
		IF @p_fr_Dept <> ''-- 부서코드(From)
			SET @v_sql = @v_sql + ' 	  AND A.CD_DEPT >= ''' + @p_fr_Dept + '''' + CHAR(13)
		IF @p_to_Dept <> ''-- 부서코드(To)
			SET @v_sql = @v_sql + ' 	  AND A.CD_DEPT <= ''' + @p_to_Dept + '''' + CHAR(13)
		IF @p_cd_person <> ''-- 사원
			SET @v_sql = @v_sql + ' 	  AND A.NO_PERSON = ''' + @p_cd_person + '''' + CHAR(13)
--print @v_sql
		EXEC(@v_sql);



/* 전표번호 생성용 순번 찾아오는 부분*/
-- 전기일기준으로 생성한다.
SELECT @MSEQ = MAX(cast(SEQ as int))
FROM H_IF_SAPINTERFACE
WHERE CD_COMPANY = @p_cd_compnay
AND SLIP_DATE = @p_dt_gian;

select @MSEQ = isnull(@MSEQ,0) + 1;

--전표번호 중복문제처리....
while(1=1)
begin
	if exists ( select top 1 SEQ_H from H_IF_SAPINTERFACE where SEQ_H = (select @p_cd_compnay + @p_dt_gian + convert(varchar,dbo.fn_HomeTax_Num(@MSEQ, 4))))
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


select '순번',@MSEQ;

		-- 생성된 퇴직추계액을 이용하여 계정과목 생성
		DECLARE	PER_CUR	CURSOR	FOR
			SELECT CD_COMPANY
				  ,CD_DEPT
				  ,NO_PERSON
				  ,NM_PERSON
				  ,LVL_PAY1
				  ,YN_RETPENSION	
				  ,FG_RETPENSION_KIND
				  ,AMT_RETR_PAY
                  ,ACCT_GU
				  ,ISNULL(CD_CC,'')
                  ,PAY_GROUP                  
			FROM #TEMP_HUMAN
            WHERE AMT_RETR_PAY <> 0
			OPEN	PER_CUR

			-- 커서 패치
			FETCH	NEXT	FROM	PER_CUR	INTO		@v_cd_company,
														@v_cd_dept,
														@v_no_person,
														@v_nm_person,
														@v_zposn_s,
														@v_yn_retpension,
														@v_fg_retpension_kind,
														@v_amt_retr_pay,
                                                        @v_acct_gu,
                                                        @v_cd_cc,
                                                        @v_pay_group
				-- 개인별 처리
				WHILE	@@fetch_status	=	0

				BEGIN
					-------------------------------------------------------------------------------------------------------------------
					--  자 동 기 표 처리 SELECT * FROM H_ACCNT_MATRIX_2
					-------------------------------------------------------------------------------------------------------------------
					SET @v_fg_drcr = '';
					SET @v_cd_accnt1 = '';
					SET @v_cd_accnt2 = '';
					SET @v_cd_accnt3 = '';
					SET @v_cd_accnt4 = '';
					SET @v_cd_accnt5 = '';
					SET @v_cd_accnt6 = '';

					SELECT @v_fg_drcr = FG_DRCR
                          ,@v_cd_accnt1 = ISNULL(CD_ACCNT1,''), @v_cd_accnt2 = ISNULL(CD_ACCNT2,'')	-- 연금미가입자
                          ,@v_cd_accnt3 = ISNULL(CD_ACCNT3,''), @v_cd_accnt4 = ISNULL(CD_ACCNT4,'')	-- DB형
                          ,@v_cd_accnt5 = ISNULL(CD_ACCNT5,''), @v_cd_accnt6 = ISNULL(CD_ACCNT6,'')	-- DC형
					FROM H_ACCNT_MATRIX_2
					WHERE CD_COMPANY = @v_cd_company
                      AND FG_ACCNT = @v_acct_gu
                      AND CD_ITEM = 'E012'

					BEGIN
						-- 연금가입여부(미가입/DB/DC)							
						if @v_fg_retpension_kind = 'DB'			-- DB형
							begin
								set @v_cd_accnt_dr = '00'+@v_cd_accnt3	-- SAP 계정코드에 00 붙임
								set @v_cd_accnt_cr = @v_cd_accnt4
							end
						else if @v_fg_retpension_kind = 'DC'	-- DC형
							begin
								set @v_cd_accnt_dr = '00'+@v_cd_accnt5
								set @v_cd_accnt_cr = @v_cd_accnt6
							end
						else									-- 미가입
							begin
								set @v_cd_accnt_dr = '00'+@v_cd_accnt1
								set @v_cd_accnt_cr = @v_cd_accnt2
							end

						IF @v_cd_accnt_dr = '00'
							begin
								set @v_cd_accnt_dr = '0000000000'
								set @v_cd_accnt_cr = '22030100'
								set @v_fg_drcr = '40'
							end
						
						SELECT @v_gsbers = BIZ_ACCT 
						  FROM B_COST_CENTER 
						 WHERE CD_COMPANY = @v_cd_company
						   AND CD_CC = @v_cd_cc -- 사업영역
						
						SET @v_cd_cc = RIGHT('0000000000' + @v_cd_cc,10)

						SET @v_seq_h = @v_seq_h + 1 
						INSERT INTO H_IF_SAPINTERFACE (
											CD_COMPANY, ZPOSN_S, SEQNO_S, DRAW_DATE, SNO,	SNM, COST_CENTER, 
                                            SAP_ACCTCODE, AMT, DBCR_GU, SEQ, REMARK, 
                                            ACCT_TYPE, FLAG, PAY_YM, PAY_DATE, PAY_SUPP, 
                                            ITEM_CODE, PAYGP_CODE, IFC_SORT, SLIP_DATE, 
                                            ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE, ACCNT_CD, GSBER_S)
						VALUES ( @v_cd_company,	 @v_zposn_s, dbo.fn_HomeTax_Num(@v_seq_h,10), @v_dt_dian,	@v_no_person, @v_nm_person, @v_cd_cc, 
                                 @v_cd_accnt_dr, @v_amt_retr_pay, @v_fg_drcr, @MSEQ, '퇴직충당금(E012)',
								 'E012', 'N',left(@p_dt_gian,6), @p_dt_gian, '퇴직충당금', 
                                 '', @v_pay_group, 'E012', @p_dt_gian,
								 @v_id_user,	getdate(), @v_id_user,	getdate(), @v_cd_accnt_cr, @v_gsbers)

						/* 에러 발생시 에러 핸들러로 분기 처리 */ 
						IF @@error <> 0
						BEGIN
							SET @v_error_number = @@error;
							SET @v_error_code = 'p_at_app_sap_interface';
							SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 계정 생성 중 오류가 발생하였습니다.'
							GOTO ERR_HANDLER
						END
					END

					------------------------------------------------------------------------------------------------------------------
					-- Message Setting Block 
					------------------------------------------------------------------------------------------------------------------      
					/* 에러 발생시 에러 핸들러로 분기 처리 */ 
					IF @@error <> 0
					BEGIN
						SET @v_error_number = @@error;
						SET @v_error_code = 'p_at_app_sap_interface';
						SET @v_error_note = 'H_IF_SAPINTERFACE TABLE 내역 삭제 중 오류가 발생하였습니다.'
						GOTO ERR_HANDLER
					END


					-- 다음 커서 패치
					FETCH	NEXT	FROM	PER_CUR INTO	@v_cd_company,
															@v_cd_dept,
															@v_no_person,
															@v_nm_person,
															@v_zposn_s,
															@v_yn_retpension,
															@v_fg_retpension_kind,
															@v_amt_retr_pay,
                                                            @v_acct_gu,
                                                            @v_cd_cc,
                                                            @v_pay_group
				END

				--SET @v_seq_h = @v_seq_h + 1 



SELECT RANK() OVER (ORDER BY ACCNT_CD) AS ROWID, ACCNT_CD AS ACCNT
INTO #ROWID
FROM H_IF_SAPINTERFACE
WHERE ACCT_TYPE = 'E012'
AND CD_COMPANY = @V_CD_COMPANY
AND SLIP_DATE = @P_DT_GIAN
AND SEQ = @MSEQ
AND ISNULL(ACCNT_CD,'') != ''
GROUP BY ACCNT_CD

/*
시스템즈
CA01	양재부분 1000
CB01	통신부분 1100
CC01	정밀부분  1200
CD01	건설부분  1300
CE01	생산부분  1200
declare @sum_GSBER_S varchar(8) -- 집계용 사업장
*/

print 2
				-- 시스템즈 정밀부분에 통신이 섞여있어서 하드코딩 차후 개선필요
				--if @v_cd_company = 'C' and @p_pay_group ='CC01'
				if @v_cd_company = 'B'
				begin


					--SELECT 1,@v_cd_company, dbo.fn_HomeTax_Num(@v_seq_h+ROWID,10), DRAW_DATE, '00'+ACCNT_CD, SUM(AMT), '50', SEQ, '퇴직충당금(E012)-집계',
					--	   'E012', 'N', 'E012', SLIP_DATE, @v_id_user, GETDATE(), @v_id_user, GETDATE(),PAYGP_CODE
					--		,left(SLIP_DATE,6),SLIP_DATE,'1200',@v_cd_cc
					--FROM H_IF_SAPINTERFACE A
					--join #ROWID B on A.ACCNT_CD= B.ACCNT
					--WHERE ACCT_TYPE = 'E012'
					--  AND CD_COMPANY = @v_cd_company
					--  AND SLIP_DATE = @p_dt_gian
					--	and seq = @MSEQ
					--GROUP BY CD_COMPANY, DRAW_DATE, ACCNT_CD, SEQ, SLIP_DATE,PAYGP_CODE,ROWID -- 상대계정(ACCNT_CD)

					-- 상대계정 생성(집계)
					INSERT INTO H_IF_SAPINTERFACE (
										CD_COMPANY, SEQNO_S, DRAW_DATE, SAP_ACCTCODE, AMT, DBCR_GU, SEQ, REMARK, 
										ACCT_TYPE, FLAG, IFC_SORT, SLIP_DATE, 
										ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE,PAYGP_CODE
										, PAY_YM, PAY_DATE,GSBER_S,COST_CENTER)
					SELECT @v_cd_company, dbo.fn_HomeTax_Num(@v_seq_h+ROWID,10), DRAW_DATE, '00'+ACCNT_CD, SUM(AMT), '50', SEQ, '퇴직충당금(E012)-집계',
						   'E012', 'N', 'E012', SLIP_DATE, @v_id_user, GETDATE(), @v_id_user, GETDATE(),PAYGP_CODE
							,left(SLIP_DATE,6),SLIP_DATE,'1100',@v_cd_cc
					FROM H_IF_SAPINTERFACE A
					join #ROWID B on A.ACCNT_CD= B.ACCNT
					WHERE ACCT_TYPE = 'E012'
					  AND CD_COMPANY = @v_cd_company
					  AND SLIP_DATE = @p_dt_gian
						and seq = @MSEQ
					GROUP BY CD_COMPANY, DRAW_DATE, ACCNT_CD, SEQ, SLIP_DATE,PAYGP_CODE,ROWID -- 상대계정(ACCNT_CD)
				end
				else
				begin
					
					
					-- 상대계정 생성(집계)
					INSERT INTO H_IF_SAPINTERFACE (
										CD_COMPANY, SEQNO_S, DRAW_DATE, SAP_ACCTCODE, AMT, DBCR_GU, SEQ, REMARK, 
										ACCT_TYPE, FLAG, IFC_SORT, SLIP_DATE, 
										ID_INSERT, DT_INSERT, ID_UPDATE, DT_UPDATE,PAYGP_CODE
										, PAY_YM, PAY_DATE,GSBER_S,COST_CENTER)
					SELECT @v_cd_company, dbo.fn_HomeTax_Num(@v_seq_h+ROWID + cast(GSBER_S as int)*10000,10), DRAW_DATE, '00'+ACCNT_CD, SUM(AMT), '50', SEQ, '퇴직충당금(E012)-집계',
						   'E012', 'N', 'E012', SLIP_DATE, @v_id_user, GETDATE(), @v_id_user, GETDATE(),PAYGP_CODE
							,left(SLIP_DATE,6),SLIP_DATE,GSBER_S,@v_cd_cc
					FROM H_IF_SAPINTERFACE A
					join #ROWID B on A.ACCNT_CD= B.ACCNT
					WHERE ACCT_TYPE = 'E012'
					  AND CD_COMPANY = @v_cd_company
					  AND SLIP_DATE = @p_dt_gian
						and seq = @MSEQ
					GROUP BY CD_COMPANY, DRAW_DATE, ACCNT_CD, SEQ, SLIP_DATE,PAYGP_CODE,GSBER_S,ROWID -- 상대계정(ACCNT_CD)
				end
--select @v_cd_company + @p_dt_gian + convert(varchar,dbo.fn_HomeTax_Num(@MSEQ, 4));

				
				SET @v_slip_nbr = @v_cd_company + @p_dt_gian + convert(varchar,dbo.fn_HomeTax_Num(@MSEQ, 4));
--select @v_slip_nbr,@v_cd_company,@p_dt_gian,convert(varchar,dbo.fn_HomeTax_Num(@MSEQ, 4))

				-- 전표 update (H_IF_SAPINTERFACE)
				UPDATE H_IF_SAPINTERFACE  SET SEQ_H = @v_slip_nbr
				WHERE CD_COMPANY = @v_cd_company
				AND DRAW_DATE = @v_dt_dian
				AND SEQ  = @MSEQ
				AND IFC_SORT = 'E012'

			-- 클로즈
			CLOSE	PER_CUR
			-- 커서 제거
			DEALLOCATE	PER_CUR
			-- 임시테이블 삭제
			DROP TABLE #TEMP_HUMAN
	END

	RETURN			/* 끝 */
	
  -----------------------------------------------------------------------------------------------------------------------
  -- END Message Setting Block 
  ----------------------------------------------------------------------------------------------------------------------- 
  ERR_HANDLER:

	DEALLOCATE	PER_CUR
	DROP TABLE #TEMP_HUMAN

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;

	EXECUTE p_ba_errlib_getusererrormsg @v_cd_company, 'p_at_app_sap_interface',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

	RETURN
END TRY

  ----------------------------------------------------------------------------------------------------------------------- 
  -- Error CATCH Process Block 
  ----------------------------------------------------------------------------------------------------------------------- 
BEGIN CATCH

	DEALLOCATE	PER_CUR
	DROP TABLE #TEMP_HUMAN

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line =  ERROR_LINE();
	SET @v_error_message = ERROR_MESSAGE()+ ' ' + @v_error_note;
select @v_error_message
	--EXECUTE p_ba_errlib_getusererrormsg @v_cd_company, 'p_at_app_sap_interface',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

	RETURN
END CATCH
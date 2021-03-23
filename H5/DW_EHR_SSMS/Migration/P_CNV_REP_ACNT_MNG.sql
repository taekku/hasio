SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 퇴직금계정분류관리
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_REP_ACNT_MNG]
      @an_try_no         NUMERIC(4)       -- 시도회차
    , @av_company_cd     NVARCHAR(10)     -- 회사코드
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @s_company_cd nvarchar(10)
	      , @t_company_cd nvarchar(10)
		  -- 변환작업결과
		  , @v_proc_nm   nvarchar(50) -- 프로그램ID
		  , @v_pgm_title nvarchar(100) -- 프로그램Title
		  , @v_params       nvarchar(4000) -- 파라미터
		  , @n_total_record numeric
		  , @n_cnt_success  numeric
		  , @n_cnt_failure  numeric
		  , @v_s_table      nvarchar(50) -- source table
		  , @v_t_table      nvarchar(50) -- target table
		  , @n_log_h_id		  numeric
		  , @v_keys			nvarchar(2000)
		  , @n_err_cod		numeric
		  , @v_err_msg		nvarchar(4000)
		  -- AS-IS Table Key
		  , @cd_company   nvarchar(20) -- 회사코드
		  , @tp_code			nvarchar(40) -- 지급/공제구분
		  , @cd_item			nvarchar(40) -- 항목구분
		  , @fg_accnt			nvarchar(40) -- 계정구분
		  -- 참조변수
		  , @salary_type_cd nvarchar(10) -- 급여유형코드
		  , @pay_item_cd	nvarchar(10) -- 급여항목코드
		  , @pay_item_type_cd nvarchar(10) -- 급여항목유형코드
			, @cnt_dup      numeric

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '퇴직금계정분류관리'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_ACCNT_MATRIX_2'   -- As-Is Table
	set @v_t_table = 'REP_ACNT_MNG' -- To-Be Table
	-- =============================================
	-- 전환프로그램설명
	-- =============================================

	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	
	-- Conversion로그정보 Header
	EXEC @n_log_h_id = dbo.P_CNV_PAY_LOG_H 0, 'S', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table
	
	-- =============================================
	--   As-Is Key Column Select
	--   Source Table Key
	-- =============================================
    DECLARE CNV_CUR CURSOR READ_ONLY FOR
		SELECT CD_COMPANY
				 , TP_CODE
				 , CD_ITEM
				 , FG_ACCNT
			  FROM dwehrdev.dbo.H_ACCNT_MATRIX_2
			 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
	-- =============================================
	--   As-Is Key Column Select
	-- =============================================
	OPEN CNV_CUR

	WHILE 1 = 1
		BEGIN
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			FETCH NEXT FROM CNV_CUR
			      INTO @cd_company, @tp_code, @cd_item, @fg_accnt
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- 총 건수확인
				set @s_company_cd = @cd_company -- AS-IS 회사코드
				set @t_company_cd = @cd_company -- TO-BE 회사코드
				
				INSERT INTO REP_ACNT_MNG (
						REP_ACNT_MNG_ID, --	퇴직금계정관리ID
						COMPANY_CD, --	회사코드
						REP_BILL_TYPE_CD, --	전표구분[REP_BILL_TYPE_CD]
						PAY_ACNT_TYPE_CD, --	계정구분[PAY_ACNT_TYPE_CD]
						DBCR_CD, --	차대구분[PAY_DBCR_SAP_CD]
						INS_NO_ACNT_CD, --	퇴직금계정(미가입자)
						INS_NO_REL_CD, --	상대계정(미가입자)
						INS_DB_ACNT_CD, --	퇴직금계정(DB형)
						INS_DB_REL_CD, --	상대계정(DB형)
						INS_DC_ACNT_CD, --	퇴직금계정(DC형)
						INS_DC_REL_CD, --	상태계정(DC형)
						STAX_ACNT_CD, --	소득세계정
						JTAX_ACNT_CD, --	주민세계정
						STA_YMD, --	시작일자
						END_YMD, --	종료일자
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일시
						TZ_CD, --	타임존코드
						TZ_DATE  --	타임존일시
				       )
				SELECT NEXT VALUE FOR S_REP_SEQUENCE as REP_ACNT_MNG_ID,
						@t_company_cd AS COMPANY_CD,
						A.CD_ITEM AS REP_BILL_TYPE_CD, --	전표구분[REP_BILL_TYPE_CD]
						A.FG_ACCNT	PAY_ACNT_TYPE_CD, --	계정구분[PAY_ACNT_TYPE_CD]
						A.FG_DRCR	DBCR_CD, --	차대구분[PAY_DBCR_SAP_CD]
						A.CD_ACCNT1	INS_NO_ACNT_CD, --	퇴직금계정(미가입자)
						A.CD_ACCNT2	INS_NO_REL_CD, --	상대계정(미가입자)
						A.CD_ACCNT3	INS_DB_ACNT_CD, --	퇴직금계정(DB형)
						A.CD_ACCNT4	INS_DB_REL_CD, --	상대계정(DB형)
						A.CD_ACCNT5	INS_DC_ACNT_CD, --	퇴직금계정(DC형)
						A.CD_ACCNT6	INS_DC_REL_CD, --	상태계정(DC형)
						A.CD_ACCNT8	STAX_ACNT_CD, --	소득세계정
						A.CD_ACCNT9	JTAX_ACNT_CD, --	주민세계정
						'19000101' STA_YMD, --	시작일자
						CASE WHEN YN_USE = 'Y' THEN '29991231' ELSE '19000101' END END_YMD, --	종료일자
						  REM_COMMENT NOTE -- 비고
						, 0 AS MOD_USER_ID
						, ISNULL(DT_UPDATE,'1900-01-01')
						, 'KST'
						, ISNULL(DT_UPDATE,'1900-01-01')
				  FROM dwehrdev.dbo.H_ACCNT_MATRIX_2 A
				 WHERE CD_COMPANY = @s_company_cd
				   AND TP_CODE = @tp_code
					 AND CD_ITEM = @cd_item
					 AND FG_ACCNT = @fg_accnt
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================
				if @@ROWCOUNT > 0 
					begin
						-- *** 성공메시지 로그에 저장 ***
						--set @v_keys = ISNULL(CONVERT(nvarchar(100), @@cd_company),'NULL')
						--      + ',' + ISNULL(CONVERT(nvarchar(100), @cd_accnt),'NULL')
						--set @v_err_msg = '선택된 Record가 없습니다.!'
						--EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 성공메시지 로그에 저장 ***
						set @n_cnt_success = @n_cnt_success + 1 -- 성공건수
					end
				else
					begin
						-- *** 로그에 실패 메시지 저장 ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',tp_code=' + ISNULL(CONVERT(nvarchar(100), @tp_code),'NULL')
							  + ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
							  + ',fg_accnt=' + ISNULL(CONVERT(nvarchar(100), @fg_accnt),'NULL')
						set @v_err_msg = '선택된 Record가 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
					end
			END TRY
			BEGIN CATCH
				-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						IF @n_err_cod = 2627
							BEGIN
									set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
											+ ',tp_code=' + ISNULL(CONVERT(nvarchar(100), @tp_code),'NULL')
											+ ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
											+ ',fg_accnt=' + ISNULL(CONVERT(nvarchar(100), @fg_accnt),'NULL')
											+ ',pay_item_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_cd),'NULL')
											+ ',pay_item_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_type_cd),'NULL')
									set @v_err_msg = 'pay_item_cd[' + @pay_item_cd + ']의 계정코드가 중복입니다.'
									EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
									-- *** 로그에 실패 메시지 저장 ***
									set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
							END
						ELSE
							BEGIN
								set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
										+ ',tp_code=' + ISNULL(CONVERT(nvarchar(100), @tp_code),'NULL')
										+ ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
										+ ',fg_accnt=' + ISNULL(CONVERT(nvarchar(100), @fg_accnt),'NULL')
										+ ',pay_item_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_cd),'NULL')
										+ ',pay_item_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_type_cd),'NULL')
								set @v_err_msg = ERROR_MESSAGE()
								EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
								-- *** 로그에 실패 메시지 저장 ***
								set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
							END
			END CATCH
		END
	--print '종료 총건수 : ' + dbo.xf_to_char_n(@n_total_record, default)
	--print '성공 : ' + dbo.xf_to_char_n(@n_cnt_success, default)
	--print '실패 : ' + dbo.xf_to_char_n(@n_cnt_failure, default)
	-- Conversion 로그정보 - 전환건수저장
	EXEC [dbo].[P_CNV_PAY_LOG_H] @n_log_h_id, 'E', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table, @n_total_record, @n_cnt_success, @n_cnt_failure

	CLOSE CNV_CUR
	DEALLOCATE CNV_CUR
	PRINT @v_proc_nm + ' 완료!'
	PRINT 'CNT_PAY_WORK_ID = ' + CONVERT(varchar(100), @n_log_h_id)
	RETURN @n_log_h_id
END

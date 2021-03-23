SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 계정코드관리(로엑스_계정마스터)
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PBT_ACCNT_STD]
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
		  , @HRTYPE_GBN		nvarchar(20)
		  , @WRTDPT_CD		nvarchar(20)
		  , @TRDTYP_CD		nvarchar(20)
		  , @BILL_GBN		nvarchar(20)
		  , @ACCNT_CD		nvarchar(20)
		  , @PBT_ACCNT_STD_ID	NUMERIC(38,0)

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '로엑스_계정마스터'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'PBT_ACCNT_STD'   -- As-Is Table
	set @v_t_table = 'PBT_ACCNT_STD' -- To-Be Table
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
		SELECT COMPANY
				 , HRTYPE_GBN, WRTDPT_CD, TRDTYP_CD, BILL_GBN, ACCNT_CD
			  FROM dwehrdev.dbo.PBT_ACCNT_STD
			 WHERE COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
			   AND BILL_GBN != 'P5110' -- 전표구분(코드에 없는 것)
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
			      INTO @cd_company, @HRTYPE_GBN, @WRTDPT_CD, @TRDTYP_CD, @BILL_GBN, @ACCNT_CD
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- 총 건수확인
				set @s_company_cd = @cd_company -- AS-IS 회사코드
				set @t_company_cd = @cd_company -- TO-BE 회사코드
				
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				SET @PBT_ACCNT_STD_ID = NEXT VALUE FOR S_PBT_SEQUENCE
				INSERT INTO PBT_ACCNT_STD (
						PBT_ACCNT_STD_ID, --	계정마스터ID
						COMPANY_CD, --	인사영역
						HRTYPE_GBN, --	직원유형
						WRTDPT_CD, --	작성부서
						TRDTYP_CD, --	거래유형
						BILL_GBN, --	전표구분
						ACCNT_CD, --	계정코드
						COST_ACCTCD, --	비용계정코드
						MGNT_ACCTCD, --	관리계정코드
						TRDTYP_NM, --	거래유형명칭
						CUST_CD, --	거래처코드
						DEBSER_GBN, --	차대구분
						SUMMARY, --	적요사항
						CSTDPAT_CD, --	CSTDPAT_CD
						AGGR_GBN, --	AGGR_GBN
						USE_YN, --	사용여부
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일시
						TZ_CD, --	타임존코드
						TZ_DATE  --	타임존일시
				       )
				SELECT @PBT_ACCNT_STD_ID as PBT_ACCNT_STD_ID
						, @t_company_cd AS COMPANY_CD
						, HRTYPE_GBN, --	직원유형
						WRTDPT_CD, --	작성부서
						TRDTYP_CD, --	거래유형
						BILL_GBN, --	전표구분
						ACCNT_CD, --	계정코드
						COST_ACCTCD, --	비용계정코드
						MGNT_ACCTCD, --	관리계정코드
						TRDTYP_NM, --	거래유형명칭
						CUST_CD, --	거래처코드
						CASE WHEN DEBSER_GBN = '1' THEN '40' ELSE '50' END, --	차대구분
						SUMMARY, --	적요사항
						CSTDPAT_CD, --	CSTDPAT_CD
						AGGR_GBN, --	AGGR_GBN
						USE_YN --	사용여부
						, 0 AS MOD_USER_ID
						, ISNULL(UPDATE_DT,'1900-01-01')
						, 'KST'
						, ISNULL(UPDATE_DT,'1900-01-01')
				  FROM dwehrdev.dbo.PBT_ACCNT_STD
				 WHERE COMPANY = @s_company_cd
				   AND HRTYPE_GBN = @HRTYPE_GBN --	직원유형
				   AND WRTDPT_CD = @WRTDPT_CD --	작성부서
				   AND TRDTYP_CD = @TRDTYP_CD --	거래유형
				   AND BILL_GBN = @BILL_GBN --	전표구분
				   AND ACCNT_CD = @ACCNT_CD --	계정코드
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
							  + ',HRTYPE_GBN=' + ISNULL(CONVERT(nvarchar(100), @HRTYPE_GBN),'NULL')
							  + ',WRTDPT_CD=' + ISNULL(CONVERT(nvarchar(100), @WRTDPT_CD),'NULL')
							  + ',TRDTYP_CD=' + ISNULL(CONVERT(nvarchar(100), @TRDTYP_CD),'NULL')
							  + ',BILL_GBN=' + ISNULL(CONVERT(nvarchar(100), @BILL_GBN),'NULL')
							  + ',ACCNT_CD=' + ISNULL(CONVERT(nvarchar(100), @ACCNT_CD),'NULL')
						set @v_err_msg = '선택된 Record가 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
					end
				-- 로엑스_포함항목
				INSERT INTO PBT_INCITEM(
						PBT_INCITEM_ID, --	포함항목ID
						PBT_ACCNT_STD_ID, --	계정마스터ID
						ITEM_CD, --	포함항목유형코드
						SEQ, --	순서
						INCITEM_FR, --	포함항목시작코드
						INCITEM_TO, --	포함항목종료코드
						INCITEM, --	포함항목코드
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일시
						TZ_CD, --	타임존코드
						TZ_DATE  --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PBT_SEQUENCE as PBT_INCITEM_ID,
				        @PBT_ACCNT_STD_ID as PBT_ACCNT_STD_ID,
						ITEM_CD, --	포함항목유형코드
						SEQ, --	순서
						INCITEM_FR, --	포함항목시작코드
						--CASE WHEN ITEM_CD IN ('G','H') THEN -- 급여항목 지급(G)/공제(H) == 백업
						--	INCITEM
						--	ELSE INCITEM_TO END
						INCITEM_TO, --	포함항목종료코드
						CASE WHEN ITEM_CD = 'B' THEN
									CASE WHEN INCITEM='H2201' THEN '1'
										 WHEN INCITEM='H2203' THEN '2'
										 WHEN INCITEM='H2202' THEN '4'
										 ELSE INCITEM END
							 WHEN ITEM_CD = 'E' THEN -- 사번
									CASE WHEN LEFT(INCITEM,1) > 1 THEN '19' ELSE '20' END + INCITEM
							 WHEN ITEM_CD IN ('G','H') THEN -- 급여항목 지급(G)/공제(H)
									ISNULL((SELECT ITEM_CD
									   FROM CNV_PAY_ITEM
									  WHERE TP_CODE = CASE WHEN A.ITEM_CD='G' THEN '1' ELSE '2' END
									    AND CD_ITEM = A.INCITEM AND COMPANY_CD=@s_company_cd) , A.INCITEM)
							ELSE INCITEM END   --	포함항목코드
						, 0 AS MOD_USER_ID
						, ISNULL(UPDATE_DT,'1900-01-01')
						, 'KST'
						, ISNULL(UPDATE_DT,'1900-01-01')
				  FROM dwehrdev.dbo.PBT_INCITEM A
				 WHERE COMPANY = @s_company_cd
				   AND HRTYPE_GBN = @HRTYPE_GBN --	직원유형
				   AND WRTDPT_CD = @WRTDPT_CD --	작성부서
				   AND TRDTYP_CD = @TRDTYP_CD --	거래유형
				   AND BILL_GBN = @BILL_GBN --	전표구분
				   AND ACCNT_CD = @ACCNT_CD --	계정코드
				   
				-- 로엑스_제외항목
				INSERT INTO PBT_EXCITEM(
						PBT_EXCITEM_ID,--	제외항목ID
						PBT_ACCNT_STD_ID, --	계정마스터ID
						ITEM_CD, --	제외항목유형코드
						SEQ, --	순서
						EXCITEM_FR, --	제외항목시작코드
						EXCITEM_TO, --	제외항목종료코드
						EXCITEM, --	제외항목코드
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일시
						TZ_CD, --	타임존코드
						TZ_DATE  --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PBT_SEQUENCE as PBT_INCITEM_ID,
				        @PBT_ACCNT_STD_ID as PBT_ACCNT_STD_ID,
						ITEM_CD, --	포함항목유형코드
						SEQ, --	순서
						EXCITEM_FR, --	제외항목시작코드
						EXCITEM_TO, --	제외항목종료코드
						CASE WHEN ITEM_CD = 'B' THEN -- 사원구분(근로형태)
									CASE WHEN EXCITEM='H2201' THEN '1' -- 정규직
										 WHEN EXCITEM='H2203' THEN '2' -- 비정규직
										 WHEN EXCITEM='H2202' THEN '4' -- 파견직
										 ELSE EXCITEM END
							 WHEN ITEM_CD = 'E' THEN -- 사번
									CASE WHEN LEFT(EXCITEM,1) > 1 THEN '19' ELSE '20' END + EXCITEM
							 WHEN ITEM_CD IN ('G','H') THEN -- 급여항목 지급(G)/공제(H)
									ISNULL((SELECT ITEM_CD
									   FROM CNV_PAY_ITEM
									  WHERE TP_CODE = CASE WHEN A.ITEM_CD='G' THEN '1' ELSE '2' END
									    AND CD_ITEM = A.EXCITEM AND COMPANY_CD=@s_company_cd) , A.EXCITEM)
							ELSE EXCITEM END EXCITEM --	제외항목코드
						, 0 AS MOD_USER_ID
						, ISNULL(UPDATE_DT,'1900-01-01')
						, 'KST'
						, ISNULL(UPDATE_DT,'1900-01-01')
				  FROM dwehrdev.dbo.PBT_EXCITEM A
				 WHERE COMPANY = @s_company_cd
				   AND HRTYPE_GBN = @HRTYPE_GBN --	직원유형
				   AND WRTDPT_CD = @WRTDPT_CD --	작성부서
				   AND TRDTYP_CD = @TRDTYP_CD --	거래유형
				   AND BILL_GBN = @BILL_GBN --	전표구분
				   AND ACCNT_CD = @ACCNT_CD --	계정코드
			END TRY
			BEGIN CATCH
				-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',HRTYPE_GBN=' + ISNULL(CONVERT(nvarchar(100), @HRTYPE_GBN),'NULL')
							  + ',WRTDPT_CD=' + ISNULL(CONVERT(nvarchar(100), @WRTDPT_CD),'NULL')
							  + ',TRDTYP_CD=' + ISNULL(CONVERT(nvarchar(100), @TRDTYP_CD),'NULL')
							  + ',BILL_GBN=' + ISNULL(CONVERT(nvarchar(100), @BILL_GBN),'NULL')
							  + ',ACCNT_CD=' + ISNULL(CONVERT(nvarchar(100), @ACCNT_CD),'NULL')
						set @v_err_msg = ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
				-- *** 로그에 실패 메시지 저장 ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
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

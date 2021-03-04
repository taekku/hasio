SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 코스트센터코드
-- 
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_ORM_COST
      @an_try_no         NUMERIC(4)       -- 시도회차
    , @av_company_cd     NVARCHAR(10)     -- 회사코드
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @s_company_cd nvarchar(10)
	      , @t_company_cd nvarchar(10)
		  -- 변환작업결과
		  , @v_proc_nm		nvarchar(50) -- 프로그램ID
		  , @v_pgm_title	nvarchar(100) -- 프로그램Title
		  , @v_params       nvarchar(4000) -- 파라미터
		  , @n_total_record numeric
		  , @n_cnt_success  numeric
		  , @n_cnt_failure  numeric
		  , @v_s_table      nvarchar(50) -- source table
		  , @v_t_table      nvarchar(50) -- target table
		  , @n_log_h_id		numeric
		  , @v_keys			nvarchar(2000)
		  , @n_err_cod		numeric
		  , @v_err_msg		nvarchar(4000)
		  -- AS-IS Table Key
		  , @cd_company		nvarchar(20) -- 회사코드
		  , @cd_cc		nvarchar(40) -- 코스트센터코드
		  -- 참조변수
		  , @emp_id			numeric -- 사원ID
		  , @person_id		numeric -- 개인ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = 'COST센터관리'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'B_COST_CENTER'   -- As-Is Table
	set @v_t_table = 'ORM_COST' -- To-Be Table
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
				 , CD_CC
			  FROM dwehrdev.dbo.B_COST_CENTER
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
			      INTO @cd_company, @cd_cc
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
				INSERT INTO dwehrdev_H5.dbo.ORM_COST(
							  ORM_COST_ID, --	코스트센터관리ID
								COMPANY_CD, --	회사코드
								COST_CD, --	코스트센터
								COST_NM, --	코스트센터명
								COST_ENG_NM, --	코스트센터영문명
								PROD_TYPE_CD, --	제조구분[ORM_PROD_TYPE_CD]
								PROFIT_TYPE_CD, --	손익구분[ORM_PROFIT_TYPE_CD]
								PAY_TYPE_CD, --	급여구분[ORM_PAY_TYPE_CD]
								COST_TYPE, --	사업부문
								ACCT_CD, --	계정구분
								SUB_COMP_CD, --	서브회사
								STA_YMD, --	시작일
								END_YMD, --	종료일
								NOTE --	비고
							,MOD_USER_ID	-- 변경자
							,MOD_DATE	-- 변경일시
							,TZ_CD	-- 타임존코드
							,TZ_DATE	-- 타임존일시
				       )
				SELECT NEXT VALUE FOR S_ORM_SEQUENCE ORM_COST_ID,
							A.CD_COMPANY	COMPANY_CD, --	회사코드
							A.CD_CC	COST_CD, --	코스트센터
							A.NM_CC	COST_NM, --	코스트센터명
							A.NM_CC	COST_ENG_NM, --	코스트센터영문명
							A.FG_COST_CC	PROD_TYPE_CD, --	제조구분[ORM_PROD_TYPE_CD]
							A.FG_PROFIT_CC	PROFIT_TYPE_CD, --	손익구분[ORM_PROFIT_TYPE_CD]
							A.FG_HUMAN_CC	PAY_TYPE_CD, --	급여구분[ORM_PAY_TYPE_CD]
							A.BIZ_ACCT	COST_TYPE, --	사업부문
							A.FG_ACCT	ACCT_CD, --	계정구분
							NULL	SUB_COMP_CD, --	서브회사
							'19000101'	STA_YMD, --	시작일
							CASE WHEN A.YN_USE='Y' THEN '29991231' ELSE ISNULL(A.DT_UPDATE,'2019-12-31') END AS END_YMD, --	종료일
								A.TXT_REMARK	NOTE --	비고
					, 0 --MOD_USER_ID	--변경자
					, ISNULL(A.DT_UPDATE,'1900-01-01') --MOD_DATE	--변경일시
					, 'KST' TZ_CD	--타임존코드
					, ISNULL(A.DT_UPDATE,'1900-01-01') -- TZ_DATE	--타임존일시
				  FROM dwehrdev.dbo.B_COST_CENTER A
				 WHERE A.CD_COMPANY = @s_company_cd
				   AND A.CD_CC = @cd_cc
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
							  + ',cd_cc=' + ISNULL(CONVERT(nvarchar(100), @cd_cc),'NULL')
						set @v_err_msg = '선택된 Record가 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
					end
			END TRY
			BEGIN CATCH
				-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',cd_cc=' + ISNULL(CONVERT(nvarchar(100), @cd_cc),'NULL')
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
GO

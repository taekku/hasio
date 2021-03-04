SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 학자금실적
-- 
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_SEC_EDU
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
		  , @family_repre		nvarchar(100) -- 주민번호
		  , @tp_school		nvarchar(40) -- 학교구분
		  , @seq		numeric -- 일련번호
			-- Etc Field
		  , @cd_company		nvarchar(40) -- 회사
		  , @no_person		nvarchar(40) -- 사번
		  -- 참조변수
		  , @emp_id			numeric -- 사원ID
		  , @person_id		numeric -- 개인ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '학자금'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_SCHOOL_EXPENSES_LIST'   -- As-Is Table
	set @v_t_table = 'SEC_EDU' -- To-Be Table
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
		SELECT FAMILY_REPRE
		     , TP_SCHOOL
				 , SEQ
				 , CD_COMPANY
				 , NO_PERSON
			  FROM dwehrdev.dbo.H_SCHOOL_EXPENSES_LIST
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
			      INTO	@family_repre, @tp_school, @seq, @cd_company, @no_person
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- 총 건수확인
				set @s_company_cd = @cd_company -- AS-IS 회사코드
				set @t_company_cd = @cd_company -- TO-BE 회사코드
				
				-- =======================================================
				--  EMP_ID 찾기
				-- =======================================================
				SELECT @emp_id = EMP_ID, @person_id = PERSON_ID
				  FROM PHM_EMP_NO_HIS
				 WHERE COMPANY_CD = @cd_company
				   AND EMP_NO = @no_person
				IF @@ROWCOUNT < 1
					BEGIN
						-- *** 로그에 실패 메시지 저장 ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS에서 사번을 찾을 수 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				INSERT INTO dwehrdev_H5.dbo.SEC_EDU(
							 SEC_EDU_ID, --	학자금신청ID
							 EMP_ID, --	사원ID
							 APPL_YMD, --	신청일자
							 RECEIPT_YMD, --	영수일자
							 FAM_REL_CD, --	수혜자관계
							 FAM_NAME, --	수혜자명
							 APPL_AMT, --	신청금액
							 CONFIRM_AMT, --	지원금액
							 BANK_CD, --	은행코드
							 MEE_ACCOUNT_NO, --	계좌번호
							 SCH_GRD_CD, --	학교
							 EDU_POS, --	학년
							 EDU_TERM, --	학기[SCE_EDU_TERM]
							 MAJOR_NM, --	학과
							 SCH_NM, --	학교명
							 REGEDU_MON, --	수업료
							 FEES_MON, --	육성회비
							 APPL_ID, --	신청서ID
							 STAT_CD, --	신청서상태코드
							 FINAL_APPR_YMD, --	최종결재일자
							 APPR_EMP_ID, --	승인자
							 POS_YN, --	임원여부
							 REQ_NOTE, --	신청내역
							 REMARK, --	반려사유
							 ACCOUNT_YMD, --	전표일자
							 ACCOUNT_NO, --	전표번호
							 NOTE --	비고
							,MOD_USER_ID	-- 변경자
							,MOD_DATE	-- 변경일시
							,TZ_CD	-- 타임존코드
							,TZ_DATE	-- 타임존일시
				       )
				SELECT NEXT VALUE FOR S_SEC_SEQUENCE SEC_EDU_ID, --	학자금신청ID
							@emp_id EMP_ID, --	사원ID
							A.DT_INSERT APPL_YMD, --	신청일자
							NULL RECEIPT_YMD, --	영수일자
							'004' FAM_REL_CD, --	수혜자관계
							A.NM_FAMLY FAM_NAME, --	수혜자명
							A.AMT_PAYMENT APPL_AMT, --	신청금액
							A.AMT_CONFIRM CONFIRM_AMT, --	지원금액
							NULL BANK_CD, --	은행코드
							NULL MEE_ACCOUNT_NO, --	계좌번호
							A.TP_SCHOOL SCH_GRD_CD, --	학교
							A.TP_YEAR EDU_POS, --	학년
							A.TP_TERM EDU_TERM, --	학기[SCE_EDU_TERM]
							A.NM_MAJOR MAJOR_NM, --	학과
							A.NM_SCHOOL SCH_NM, --	학교명
							0 REGEDU_MON, --	수업료
							0 FEES_MON, --	육성회비
							0 APPL_ID, --	신청서ID
							CASE WHEN A.YN_PAYMENT='Y' THEN '132' ELSE '131' END STAT_CD, --	신청서상태코드 132:결재완료, 131:반려
							A.DT_PAYMENT  FINAL_APPR_YMD, --	최종결재일자
							NULL APPR_EMP_ID, --	승인자
							NULL POS_YN, --	임원여부
							NULL REQ_NOTE, --	신청내역
							NULL REMARK, --	반려사유
							NULL ACCOUNT_YMD, --	전표일자
							NULL ACCOUNT_NO, --	전표번호
							NULL NOTE --	비고
					, 0 --MOD_USER_ID	--변경자
					, ISNULL(A.DT_UPDATE,'1900-01-01') --MOD_DATE	--변경일시
					, 'KST' TZ_CD	--타임존코드
					, ISNULL(A.DT_UPDATE,'1900-01-01') -- TZ_DATE	--타임존일시
				  FROM dwehrdev.dbo.H_SCHOOL_EXPENSES_LIST A
				 WHERE A.FAMILY_REPRE = @family_repre
				   AND A.TP_SCHOOL = @tp_school
					 AND A.SEQ = @seq
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
							  + ',' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
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
							  + ',' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
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

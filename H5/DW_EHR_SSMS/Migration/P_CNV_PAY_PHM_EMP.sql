SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 급여마스터
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PAY_PHM_EMP]
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
		  , @no_person		nvarchar(40) -- 사번
		  -- 참조변수
		  , @emp_id			numeric -- 사원ID
		  , @person_id		numeric -- 개인ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '급여마스터'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_PAY_MASTER'   -- As-Is Table
	set @v_t_table = 'PAY_PHM_EMP' -- To-Be Table
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
				 , NO_PERSON
			  FROM dwehrdev.dbo.H_PAY_MASTER
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
			      INTO @cd_company, @no_person
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
				INSERT INTO PAY_PHM_EMP (
							 EMP_ID, -- 사원ID
							PERSON_ID, -- 개인ID
							COMPANY_CD, -- 인사영역코드
							EMP_NO, -- 사번
							TAX_FAMILY_CNT, -- 부양가족수
							FAM20_CNT, -- 20세이하자녀수
							FOREIGN_YN, -- 외국인여부
							PEAK_YMD, -- 임피적용일자
							FOREJOB_YN, -- 국외근로여부
							PROD_YN, -- 생산직여부
							PEAK_YN, -- 임금피크대상여부
							TRBNK_YN, -- 신협공제대상여부
							WORK_YN, -- 근속수당지급여부
							UNION_CD, -- 노조사업장코드[PAY_UNION_CD]
							UNION_FULL_YN, -- 노조전임여부
							UNION_YN, -- 노조회비공제대상여부
							PAY_METH_CD, -- 급여지급방식코드[PAY_METH_CD]
							EMP_CLS_CD, -- 고용유형코드[PAY_EMP_CLS_CD]
							EMAIL_YN, -- E_MAIL발송여부
							SMS_YN, -- SMS발송여부
							YEAR_YMD, -- 연차기산일자
							RETR_YMD, -- 퇴직금기산일자
							WORK_YMD, -- 근속기산일자
							ADV_YN, -- 선망가불금공제여부
							CONT_TIME, -- 소정근로시간
							PEN_ACCU_AMT, -- 연금적립액
							RET_PROC_YN, -- 퇴직정산완료여부
							ULSAN_YN, -- 울산여부
							INS_TRANS_YN, -- 동원산업전입여부
							GLS_WORK_CD, -- 유리근무유형[PAY_GLS_WORK_CD]
							MOD_USER_ID, -- 변경자
							MOD_DATE, -- 변경일시
							TZ_CD, -- 타임존코드
							TZ_DATE -- 타임존일시
				       )
				SELECT @emp_id, @person_id, @t_company_cd , @no_person
					 , A.CNT_FAMILY -- 부양가족수
					 , A.CNT_CHILD FAM20_CNT -- 20세이하자녀수
					 , A.YN_FOREIGN -- 외국인여부
					 , NULL PEAK_YMD -- 임피적용일자
					 , A.YN_FOREJOB -- 국외근로여부
					 , A.YN_PROD_LABOR -- 생산직여부
					 , 'N' PEAK_YN -- 임금피크대상여부
					 , A.YN_CRE -- 신협공제대상여부	
					, 'N' --WORK_YN	--근속수당지급여부
					, '' -- TODO -- UNION_CD	--노조사업장코드
					, '' -- UNION_FULL_YN - 노조전임여부
					, A.YN_LABOR_OBJ --UNION_YN	--노조회비공제대상여부
					, A.TP_CALC_PAY --PAY_METH_CD	--급여지급방식코드[PAY_METH_CD]
					, A.TP_CALC_INS --EMP_CLS_CD	--고용유형코드[PAY_EMP_CLS_CD]
					, A.YN_EMAIL -- EMAIL_YN	--E_MAIL발송여부
					, A.YN_SMS -- SMS_YN	--SMS발송여부
					, dbo.XF_TO_DATE(A.DT_YEAR_RECK,'yyyyMMdd') --YEAR_YMD	--연차기산일자
					, dbo.XF_TO_DATE(A.DT_RETR_RECK,'yyyyMMdd') RETR_YMD	--퇴직금기산일자
					, dbo.XF_TO_DATE(B.DT_LONG_BASE,'yyyyMMdd') -- TODO -- WORK_YMD	--근속기산일자
					, A.YN_ADVANCE -- ADV_YN	--선망가불금공제여부
					, NULL -- TODO -- CONT_TIME	--소정근로시간
					, A.AMT_RETR_ANNU -- PEN_ACCU_AMT	--연금적립액
					, A.YN_RETR_SUPPLY RET_PROC_YN -- 퇴직정산완료여부
					, A.YN_ULSAN ULSAN_YN -- 울산여부
					, NULL INS_TRANS_YN -- 동원산업전입여부
					, A.CD_DUTY_TYPE GLS_WORK_CD -- 유리근무유형[PAY_GLS_WORK_CD]
					, 0 --MOD_USER_ID	--변경자
					, ISNULL(A.DT_INS_UPDATE,'1900-01-01') --MOD_DATE	--변경일시
					, 'KST' TZ_CD	--타임존코드
					, ISNULL(A.DT_INS_UPDATE,'1900-01-01') -- TZ_DATE	--타임존일시
				  FROM dwehrdev.dbo.H_PAY_MASTER A
				  JOIN dwehrdev.dbo.H_HUMAN B
				    ON A.CD_COMPANY = B.CD_COMPANY
				   AND A.NO_PERSON = B.NO_PERSON
				 WHERE A.CD_COMPANY = @s_company_cd
				   AND A.NO_PERSON = @no_person
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

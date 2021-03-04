SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 계정분류관리
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PAY_ACNT_MNG]
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
	set @v_pgm_title = '계정분류관리'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_ACCNT_PAY_ITEM_2'   -- As-Is Table
	set @v_t_table = 'PAY_ACNT_MNG' -- To-Be Table
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
			  FROM dwehrdev.dbo.H_ACCNT_PAY_ITEM_2
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
				
				-- =======================================================
				--  급여항목코드 매핑코드 찾기
				-- =======================================================
				SELECT @salary_type_cd = '001'
						 , @pay_item_cd = ITEM_CD
				     , @pay_item_type_cd = dbo.F_FRM_UNIT_STD_VALUE (@t_company_cd, 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
                              NULL, NULL, NULL, NULL, NULL,
                              ITEM_CD, NULL, NULL, NULL, NULL,
                              getdATE(),
                              'H1' -- 'H1' : 코드1,     'H2' : 코드2,     'H3' :  코드3,     'H4' : 코드4,     'H5' : 코드5
							       -- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
                              ) --AS PAY_ITEM_TYPE_CD
				  FROM CNV_PAY_ITEM A
				 WHERE COMPANY_CD = @s_company_cd
				   AND CD_ITEM = @cd_item
				   AND TP_CODE = @tp_code -- 지급항목코드
				IF @@ROWCOUNT < 1 OR ISNULL(@pay_item_cd,'') = '' --OR ISNULL(@pay_item_type_cd, '') = ''
					BEGIN
						-- *** 로그에 실패 메시지 저장 ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
							  + ',tp_code=' + ISNULL(CONVERT(nvarchar(100), @tp_code),'NULL')
							  + ',fg_accnt=' + ISNULL(CONVERT(nvarchar(100), @fg_accnt),'NULL')
							  + ',pay_item_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_cd),'NULL')
							  + ',pay_item_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_type_cd),'NULL')
						set @v_err_msg = 'CNV_PAY_ITEM에서 맵핑코드를 찾을 수 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE;
					END
				IF isnull(@pay_item_type_cd,'') not in ('PAY_PAY','DEDUCT','TAX')
					BEGIN
						-- *** 로그에 실패 메시지 저장 ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',cd_item=' + ISNULL(CONVERT(nvarchar(100), @cd_item),'NULL')
							  + ',tp_code=' + ISNULL(CONVERT(nvarchar(100), @tp_code),'NULL')
							  + ',fg_accnt=' + ISNULL(CONVERT(nvarchar(100), @fg_accnt),'NULL')
							  + ',pay_item_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_cd),'NULL')
							  + ',pay_item_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_type_cd),'NULL')
						set @v_err_msg = '항목코드의 항목유형코드가 정의되지 않았습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE;
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				-- 로그작성 START
				INSERT INTO dwehrdev_H5.dbo.PAY_ACNT_MNG_DUP(
						PAY_ACNT_MNG_ID, --	계정분류ID
						COMPANY_CD, --	회사코드
						PAY_TYPE_CD, --	급여지급유형코드[PAY_TYPE_CD]
						PAY_ITEM_CD, --	급여항목코드
						PAY_ACNT_TYPE_CD, --	계정분류코드[PAY_ACNT_TYPE_CD]
						PAY_DBCR_SAP_CD, --	차대구분[PAY_DBCR_SAP_CD]
						EMP_ACNT_CD, --	사원계정
						EXC_ACNT_CD, --	임원계정
						OFFSET_ACNT_CD, --	상대계정
						ACNT_3, --	계정코드_3
						ACNT_4, --	계정코드_4
						ACNT_5, --	계정코드_5
						ACNT_6, --	계정코드_6
						ACNT_7, --	계정코드_7
						STA_YMD, --	시작일자
						END_YMD, --	종료일자
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일시
						TZ_CD, --	타임존코드
						TZ_DATE  --	타임존일시
				       )
				SELECT NEXT VALUE FOR S_PAY_SEQUENCE as PAY_ACNT_MNG_ID,
						@t_company_cd AS COMPANY_CD,
						@salary_type_cd	PAY_TYPE_CD, --	급여지급유형코드[PAY_TYPE_CD]
						@pay_item_cd	PAY_ITEM_CD, --	급여항목코드
						A.FG_ACCNT	PAY_ACNT_TYPE_CD, --	계정분류코드[PAY_ACNT_TYPE_CD]
						A.FG_DRCR	PAY_DBCR_SAP_CD, --	차대구분[PAY_DBCR_SAP_CD]
						ISNULL(A.CD_ACCNT1,'')	EMP_ACNT_CD, --	사원계정
						ISNULL(A.CD_ACCNT2,'')	EXC_ACNT_CD, --	임원계정
						ISNULL(A.CD_ACCNT10,'')	OFFSET_ANCT_CD, --	상대계정
						NULL ACNT_3, --	계정코드_3
						NULL ACNT_4, --	계정코드_4
						NULL ACNT_5, --	계정코드_5
						NULL ACNT_6, --	계정코드_6
						A.CD_ITEM ACNT_7, --	계정코드_7
						'19000101' STA_YMD, --	시작일자
						CASE WHEN YN_USE = 'Y' THEN '29991231' ELSE '19000101' END END_YMD, --	종료일자
						  REM_COMMENT NOTE -- 비고
						, 0 AS MOD_USER_ID
						, ISNULL(DT_UPDATE,'1900-01-01')
						, 'KST'
						, ISNULL(DT_UPDATE,'1900-01-01')
				  FROM dwehrdev.dbo.H_ACCNT_PAY_ITEM_2 A
				 WHERE CD_COMPANY = @s_company_cd
				   AND TP_CODE = @tp_code
					 AND CD_ITEM = @cd_item
					 AND FG_ACCNT = @fg_accnt
				-- 로그작성 END
				INSERT INTO dwehrdev_H5.dbo.PAY_ACNT_MNG(
						PAY_ACNT_MNG_ID, --	계정분류ID
						COMPANY_CD, --	회사코드
						PAY_TYPE_CD, --	급여지급유형코드[PAY_TYPE_CD]
						PAY_ITEM_CD, --	급여항목코드
						PAY_ACNT_TYPE_CD, --	계정분류코드[PAY_ACNT_TYPE_CD]
						PAY_DBCR_SAP_CD, --	차대구분[PAY_DBCR_SAP_CD]
						EMP_ACNT_CD, --	사원계정
						EXC_ACNT_CD, --	임원계정
						OFFSET_ACNT_CD, --	상대계정
						ACNT_3, --	계정코드_3
						ACNT_4, --	계정코드_4
						ACNT_5, --	계정코드_5
						ACNT_6, --	계정코드_6
						ACNT_7, --	계정코드_7
						STA_YMD, --	시작일자
						END_YMD, --	종료일자
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일시
						TZ_CD, --	타임존코드
						TZ_DATE  --	타임존일시
				       )
				SELECT NEXT VALUE FOR S_PAY_SEQUENCE as PAY_ACNT_MNG_ID,
						@t_company_cd AS COMPANY_CD,
						@salary_type_cd	PAY_TYPE_CD, --	급여지급유형코드[PAY_TYPE_CD]
						@pay_item_cd	PAY_ITEM_CD, --	급여항목코드
						A.FG_ACCNT	PAY_ACNT_TYPE_CD, --	계정분류코드[PAY_ACNT_TYPE_CD]
						A.FG_DRCR	PAY_DBCR_SAP_CD, --	차대구분[PAY_DBCR_SAP_CD]
						ISNULL(A.CD_ACCNT1,'')	EMP_ACNT_CD, --	사원계정
						ISNULL(A.CD_ACCNT2,'')	EXC_ACNT_CD, --	임원계정
						ISNULL(A.CD_ACCNT10,'')	OFFSET_ANCT_CD, --	상대계정
						NULL ACNT_3, --	계정코드_3
						NULL ACNT_4, --	계정코드_4
						NULL ACNT_5, --	계정코드_5
						NULL ACNT_6, --	계정코드_6
						NULL ACNT_7, --	계정코드_7
						'19000101' STA_YMD, --	시작일자
						CASE WHEN YN_USE = 'Y' THEN '29991231' ELSE '19000101' END END_YMD, --	종료일자
						  REM_COMMENT NOTE -- 비고
						, 0 AS MOD_USER_ID
						, ISNULL(DT_UPDATE,'1900-01-01')
						, 'KST'
						, ISNULL(DT_UPDATE,'1900-01-01')
				  FROM dwehrdev.dbo.H_ACCNT_PAY_ITEM_2 A
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
							
								-- 계정코드가 동일한지 확인
								SELECT @cnt_dup = COUNT(*)
									FROM dwehrdev.dbo.H_ACCNT_PAY_ITEM_2 A
									JOIN PAY_ACNT_MNG B
										ON A.FG_ACCNT = B.PAY_ACNT_TYPE_CD
									 AND A.FG_DRCR = B.PAY_DBCR_SAP_CD
									 AND ISNULL(A.CD_ACCNT1,'') = B.EMP_ACNT_CD
									 AND ISNULL(A.CD_ACCNT2,'') = B.EXC_ACNT_CD
									 AND ISNULL(A.CD_ACCNT10,'') = B.OFFSET_ACNT_CD
									 AND @t_company_cd = B.COMPANY_CD
									 AND @salary_type_cd = B.PAY_TYPE_CD
									 AND @pay_item_cd = B.PAY_ITEM_CD
								 WHERE A.CD_COMPANY = @s_company_cd
									 AND A.TP_CODE = @tp_code
									 AND A.CD_ITEM = @cd_item
									 AND A.FG_ACCNT = @fg_accnt
								IF @cnt_dup = 0
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
GO

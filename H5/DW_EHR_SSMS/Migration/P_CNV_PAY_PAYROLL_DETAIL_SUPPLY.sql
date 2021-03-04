SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 급여지급내역
-- H_MONTH_SUPPLY => PAY_PAYROLL_DETAIL(지급항목)
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_PAYROLL_DETAIL_SUPPLY
      @an_try_no		NUMERIC(4)      -- 시도회차
    , @av_company_cd	NVARCHAR(10)    -- 회사코드
	, @av_fr_month		NVARCHAR(6)		-- 시작년월
	, @av_to_month		NVARCHAR(6)		-- 종료년월
	, @av_fg_supp		NVARCHAR(2)		-- 급여구분
	, @av_dt_prov		NVARCHAR(08)	-- 급여지급일
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
		  , @cd_company		nvarchar(20) -- 회사코드
		  , @ym_pay			nvarchar(10)
		  , @fg_supp		nvarchar(10)
		  , @dt_prov		nvarchar(10)
		  , @no_person		nvarchar(10)
		  , @cd_allow		nvarchar(10)
		  -- 참조변수
		  , @nm_item		nvarchar(100)
		  , @cd_paygp		nvarchar(10)
		  , @dt_update		datetime
		  , @pay_ymd_id		numeric
		  , @emp_id			numeric -- 사원ID
		  , @person_id		numeric -- 개인ID
		  , @pay_payroll_id	numeric -- PAYROLL_ID
		  , @bel_pay_type_cd nvarchar(10) -- 급여지급유형코드 - 귀속월[PAY_TYPE_CD]
		  , @bel_pay_ym		nvarchar(06) -- 귀속월
		  , @bel_pay_ymd_id numeric(18) -- 귀속급여일자ID
		  , @salary_type_cd nvarchar(10) -- 급여유형코드
		  , @pay_item_cd	nvarchar(10) -- 급여항목코드
		  , @pay_item_type_cd nvarchar(10) -- 급여항목유형코드
		  , @bel_org_id		numeric(18) -- 귀속부서ID
		  , @pay_payroll_detail_id	numeric(18) -- 급여계산상세내역ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '급여지급내역'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@av_fr_month=' + ISNULL(CONVERT(nvarchar(100), @av_fr_month),'NULL')
				+ ',@av_to_month=' + ISNULL(CONVERT(nvarchar(100), @av_to_month),'NULL')
				+ ',@av_fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
				+ ',@av_dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
	set @v_s_table = 'H_MONTH_SUPPLY'   -- As-Is Table
	set @v_t_table = 'PAY_PAYROLL_DETAIL' -- To-Be Table
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
				 , YM_PAY
				 , FG_SUPP
				 , DT_PROV
				 , NO_PERSON
				 , CD_ALLOW
				 , DT_UPDATE
			  FROM dwehrdev.dbo.H_MONTH_SUPPLY
			 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
			   AND YM_PAY BETWEEN @av_fr_month AND @av_to_month
			   AND FG_SUPP LIKE ISNULL(@av_fg_supp, '') + '%'
			   AND DT_PROV LIKE ISNULL(@av_dt_prov, '') + '%'
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
			      INTO @cd_company
				     , @ym_pay
					 , @fg_supp
					 , @dt_prov
					 , @no_person
					 , @cd_allow
					 , @dt_update
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- 총 건수확인
				set @s_company_cd = @cd_company -- AS-IS 회사코드
				set @t_company_cd = @cd_company -- TO-BE 회사코드
				SELECT @cd_paygp = CD_PAYGP
				  FROM dwehrdev.dbo.H_MONTH_PAY_BONUS WITH (NOLOCK)
				 WHERE CD_COMPANY = @cd_company
				   AND YM_PAY = @ym_pay
				   AND FG_SUPP = @fg_supp
				   AND DT_PROV = @dt_prov
				   AND NO_PERSON = @no_person
				IF @@ROWCOUNT < 1
					BEGIN
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = 'H_MONTH_PAY_BONUS에서 찾을수없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE;
					END
				-- =======================================================
				-- 급여일자얻기
				-- =======================================================
				EXECUTE @pay_ymd_id = dbo.P_CNV_PAY_PAY_YMD
								   @n_log_h_id
								 , @cd_company
								 , @ym_pay
								 , @fg_supp
								 , @dt_prov
								 , @cd_paygp
								 , @dt_update
				IF ISNULL(@pay_ymd_id,0) = 0
					BEGIN
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = '급여일자를 구할 수 없습니다.!' -- ERROR_MESSAGE()
						-- EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE;
					END
				-- =======================================================
				--  EMP_ID 찾기
				-- =======================================================
				SELECT @emp_id = EMP_ID, @person_id = PERSON_ID
				  FROM PHM_EMP_NO_HIS WITH (NOLOCK)
				 WHERE COMPANY_CD = @cd_company
				   AND EMP_NO = @no_person
				IF @@ROWCOUNT < 1
					BEGIN
						-- *** 로그에 실패 메시지 저장 ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS에서 사번을 찾을 수 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE;
					END
				-- =======================================================
				--  PAY_PAYROLL_ID찾기
				-- =======================================================
				select @pay_payroll_id = A.PAY_PAYROLL_ID
				     , @bel_pay_ym = B.PAY_YM
				     , @bel_pay_ymd_id = A.PAY_YMD_ID -- 귀속급여일자
					 , @bel_org_id = A.ORG_ID -- 귀속부서ID
					 , @bel_pay_type_cd = B.PAY_TYPE_CD
					 , @salary_type_cd = A.SALARY_TYPE_CD -- 002	연봉제(당당)
				  from PAY_PAYROLL A WITH (NOLOCK)
				  JOIN PAY_PAY_YMD B WITH (NOLOCK)
				    ON A.PAY_YMD_ID = B.PAY_YMD_ID
				 where A.PAY_YMD_ID = @pay_ymd_id
				   AND A.EMP_ID = @emp_id
				IF @@ROWCOUNT < 1
					BEGIN
						-- *** 로그에 실패 메시지 저장 ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',pay_ymd_id=' + ISNULL(CONVERT(nvarchar(100), @pay_ymd_id),'NULL')
							  + ',emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
						set @v_err_msg = 'PAY_PAYROLL을 찾을 수 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE;
					END
				-- =======================================================
				--  급여항목코드 매핑코드 찾기
				-- =======================================================
				SELECT @pay_item_cd = ITEM_CD, @nm_item = NM_ITEM
				     , @pay_item_type_cd = dbo.F_FRM_UNIT_STD_VALUE (@t_company_cd, 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
                              NULL, NULL, NULL, NULL, NULL,
                              ITEM_CD, NULL, NULL, NULL, NULL,
                              getdATE(),
                              'H1' -- 'H1' : 코드1,     'H2' : 코드2,     'H3' :  코드3,     'H4' : 코드4,     'H5' : 코드5
							       -- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
                              ) --AS PAY_ITEM_TYPE_CD
				  FROM CNV_PAY_ITEM A WITH (NOLOCK)
				 WHERE COMPANY_CD = @s_company_cd
				   AND CD_ITEM = @cd_allow
				   AND TP_CODE = '1' -- 지급항목코드
				IF @@ROWCOUNT < 1 OR ISNULL(@pay_item_cd,'') = '' --OR ISNULL(@pay_item_type_cd, '') = ''
					BEGIN
						-- *** 로그에 실패 메시지 저장 ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',cd_allow=' + ISNULL(CONVERT(nvarchar(100), @cd_allow),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',pay_ymd_id=' + ISNULL(CONVERT(nvarchar(100), @pay_ymd_id),'NULL')
							  + ',emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
							  + ',cd_allow=' + ISNULL(CONVERT(nvarchar(100), @cd_allow),'NULL')
							  + ',nm_item=' + ISNULL(CONVERT(nvarchar(100), @nm_item),'NULL')
							  + ',pay_item_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_cd),'NULL')
							  + ',pay_item_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_item_type_cd),'NULL')
						set @v_err_msg = 'CNV_PAY_ITEM에서 맵핑코드를 찾을 수 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE;
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				SELECT @pay_payroll_detail_id = NEXT VALUE FOR S_PAY_SEQUENCE
				BEGIN TRY
				INSERT INTO PAY_PAYROLL_DETAIL(
							PAY_PAYROLL_DETAIL_ID, --	급여상세내역ID
							PAY_PAYROLL_ID, --	급여내역ID
							BEL_PAY_TYPE_CD, --	급여지급유형코드-귀속월[PAY_TYPE_CD]
							BEL_PAY_YM, --	귀속월
							BEL_PAY_YMD_ID, --	귀속급여일자ID
							SALARY_TYPE_CD, --	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
							PAY_ITEM_CD, --	급여항목코드
							BASE_MON, --	기준금액
							CAL_MON, --	계산금액
							FOREIGN_BASE_MON, --	외화기준금액
							FOREIGN_CAL_MON, --	외화계산금액
							PAY_ITEM_TYPE_CD, --	급여항목유형
							BEL_ORG_ID, --	귀속부서ID
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일시
							TZ_CD, --	타임존코드
							TZ_DATE  --	타임존일시
				       )
					SELECT  @pay_payroll_detail_id	PAY_PAYROLL_DETAIL_ID, --	급여상세내역ID
							@pay_payroll_id	PAY_PAYROLL_ID, --	급여내역ID
							@bel_pay_type_cd	BEL_PAY_TYPE_CD, --	급여지급유형코드-귀속월[PAY_TYPE_CD]
							@bel_pay_ym	BEL_PAY_YM, --	귀속월
							@bel_pay_ymd_id	BEL_PAY_YMD_ID, --	귀속급여일자ID
							@salary_type_cd	SALARY_TYPE_CD, --	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
							@pay_item_cd	PAY_ITEM_CD, --	급여항목코드
							A.AMT_ALLOW_2	BASE_MON, --	기준금액
							A.AMT_ALLOW	CAL_MON, --	계산금액
							0	FOREIGN_BASE_MON, --	외화기준금액
							0	FOREIGN_CAL_MON, --	외화계산금액
							@pay_item_type_cd	PAY_ITEM_TYPE_CD, --	급여항목유형
							@bel_org_id	BEL_ORG_ID, --	귀속부서ID
							A.REM_COMMENT	NOTE, --	비고
						 0 AS MOD_USER_ID
						, ISNULL(A.DT_UPDATE,'1900-01-01')
						, 'KST'
						, ISNULL(A.DT_UPDATE,'1900-01-01')
				  FROM dwehrdev.dbo.H_MONTH_SUPPLY A WITH (NOLOCK)
				  --JOIN dwehrdev.dbo.H_MONTH_PAY_BONUS B
				  --  ON A.CD_COMPANY = B.CD_COMPANY
				  -- AND A.YM_PAY = B.YM_PAY
				  -- AND A.FG_SUPP = B.FG_SUPP
				  -- AND A.DT_PROV = B.DT_PROV
				  -- AND A.NO_PERSON = B.NO_PERSON
				 WHERE A.CD_COMPANY = @s_company_cd
				   AND A.YM_PAY = @ym_pay
				   AND A.FG_SUPP = @fg_supp
				   AND A.DT_PROV = @dt_prov
				   AND A.NO_PERSON = @no_person
				   AND A.CD_ALLOW = @cd_allow
				END TRY
				BEGIN CATCH
					set @n_err_cod = ERROR_NUMBER()
					IF @n_err_cod = 2627 -- 중복키
						BEGIN
							UPDATE A
							   SET BASE_MON = BASE_MON + B.AMT_ALLOW_2
								 , CAL_MON = CAL_MON + B.AMT_ALLOW
							  FROM PAY_PAYROLL_DETAIL A
							  JOIN (SELECT AMT_ALLOW_2, AMT_ALLOW FROM dwehrdev.dbo.H_MONTH_SUPPLY A WITH (NOLOCK)
									 WHERE A.CD_COMPANY = @s_company_cd
									   AND A.YM_PAY = @ym_pay
									   AND A.FG_SUPP = @fg_supp
									   AND A.DT_PROV = @dt_prov
									   AND A.NO_PERSON = @no_person
									   AND A.CD_ALLOW = @cd_allow) B
								ON 1=1
							 WHERE @pay_payroll_id	= PAY_PAYROLL_ID --	급여내역ID
								AND	@bel_pay_type_cd	= BEL_PAY_TYPE_CD --	급여지급유형코드-귀속월[PAY_TYPE_CD]
								AND	@bel_pay_ym	= BEL_PAY_YM --	귀속월
								AND	@bel_pay_ymd_id	= BEL_PAY_YMD_ID --	귀속급여일자ID
								AND	@salary_type_cd	= SALARY_TYPE_CD --	급여유형코드[PAY_SALARY_TYPE_CD 연봉,호봉]
								AND	@pay_item_cd	= PAY_ITEM_CD --	급여항목코드
							IF @@ROWCOUNT < 1
								begin
									-- *** 로그에 실패 메시지 저장 ***
									set @v_keys = 'cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
										  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
										  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
										  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
										  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
										  + ',cd_allow=' + ISNULL(CONVERT(nvarchar(100), @cd_allow),'NULL')
									set @v_err_msg = '선택된 Record가 없습니다.!' -- ERROR_MESSAGE()
									EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
									-- *** 로그에 실패 메시지 저장 ***
									set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
								end
						END
					ELSE
						THROW;
				END CATCH;
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================

				--if @@ROWCOUNT > 0 
					begin
						-- *** 성공메시지 로그에 저장 ***
						--set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
						--      + ',' + ISNULL(CONVERT(nvarchar(100), @cd_accnt),'NULL')
						--set @v_err_msg = '선택된 Record가 없습니다.!'
						--EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 성공메시지 로그에 저장 ***
						set @n_cnt_success = @n_cnt_success + 1 -- 성공건수
					end
				--else
				--	begin
				--		-- *** 로그에 실패 메시지 저장 ***
				--		set @v_keys = 'cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
				--			  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
				--			  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
				--			  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
				--			  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
				--			  + ',cd_allow=' + ISNULL(CONVERT(nvarchar(100), @cd_allow),'NULL')
				--		set @v_err_msg = '선택된 Record가 없습니다.!' -- ERROR_MESSAGE()
				--		EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
				--		-- *** 로그에 실패 메시지 저장 ***
				--		set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
				--	end
			END TRY
			BEGIN CATCH
				-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = 'cd_company=' + ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
							  + ',fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
							  + ',dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',cd_allow=' + ISNULL(CONVERT(nvarchar(100), @cd_allow),'NULL')
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

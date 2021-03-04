SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 복지포인트
-- 
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_CAT_PAY_MGR
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
			, @fg_supp			nvarchar(20)
			, @dt_prov			nvarchar(20)
		  , @no_person		nvarchar(20) -- 
		  , @cd_item		nvarchar(20)
			-- Etc Field
		  -- 참조변수
		  , @emp_id			numeric -- 사원ID
		  , @person_id		numeric -- 개인ID

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '복지포인트'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_CHA_SUDANG'   -- As-Is Table
	set @v_t_table = 'CAT_PAY_MGR' -- To-Be Table
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
		SELECT A.CD_COMPANY
		     , A.FG_SUPP
				 , A.DT_PROV
				 , A.NO_PERSON
				 , A.CD_ITEM
			  FROM dwehrdev.dbo.H_CHA_SUDANG A
			 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
				AND A.CD_ITEM='051' -- 엔터프라이즈
				AND A.REM_COMMENT LIKE '%복지%'
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
				   , @fg_supp
				   , @dt_prov
				   , @no_person
					 , @cd_item
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
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS에서 사번을 찾을 수 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
						CONTINUE
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				INSERT INTO dwehrdev_H5.dbo.CAT_PAY_MGR(
						CAT_PAY_MGR_ID, --	복지포인트ID
						PAY_YEAR, --	지급년도
						CAT_POINT_TIME_CD, --	지급시기[CAT_POINT_TIME_CD]
						CAT_POINT_TYPE, --	지급구분[CAT_POINT_TYPE]
						GIVE_YMD, --	지급일자
						COMPANY_CD, --	인사영역
						PAY_GROUP_CD, --	급여그룹CD
						EMP_ID, --	사원ID
						PERSON_ID, --	개인ID
						POINT, --	지급Point
						BIRTH_POINT, --	생일지급Point
						PAY_CD, --	과세여부[CAT_POINT_PAY_TYPE]
						PAY_YMD, --	과세일자
						CONF_CD, --	승인구분[CAT_POINT_CONF_TYPE]
						CONF_YMD, --	승인일자
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일시
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
					)
					SELECT NEXT VALUE FOR S_CAT_SEQUENCE CAT_PAY_MGR_ID, --	복지포인트ID
						SUBSTRING(A.DT_PROV,1,4) PAY_YEAR, --	지급년도
						SUBSTRING(A.DT_PROV, 5, 2) CAT_POINT_TIME_CD, --	지급시기[CAT_POINT_TIME_CD]
						'10'	CAT_POINT_TYPE, --	지급구분[CAT_POINT_TYPE] 10:동원몰, 20:더반찬
						A.DT_PROV GIVE_YMD, --	지급일자
						A.CD_COMPANY	COMPANY_CD, --	인사영역
						'EA01'	PAY_GROUP_CD, --	급여그룹CD
						@emp_id	EMP_ID, --	사원ID
						@person_id	PERSON_ID, --	개인ID
						AMT_ITEM	POINT, --	지급Point
						0	BIRTH_POINT, --	생일지급Point
						'Y'	PAY_CD, --	과세여부[CAT_POINT_PAY_TYPE]
						NULL	PAY_YMD, --	과세일자
						'Y'	CONF_CD, --	승인구분[CAT_POINT_CONF_TYPE]
						A.DT_INSERT	CONF_YMD, --	승인일자
						A.REM_COMMENT	NOTE, --	비고
						0	MOD_USER_ID, --	변경자
						ISNULL(A.DT_UPDATE, '19000101')	MOD_DATE, --	변경일시
						'KST'	TZ_CD, --	타임존코드
						ISNULL(A.DT_UPDATE, '19000101')	TZ_DATE --	타임존일시
					FROM dwehrdev.dbo.H_CHA_SUDANG A
					WHERE A.CD_COMPANY=@cd_company
					AND A.FG_SUPP = @fg_supp
					AND A.DT_PROV = @dt_prov
					AND A.NO_PERSON = @no_person
					AND A.CD_ITEM = @cd_item
					--AND A.REM_COMMENT LIKE '%복지%'
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

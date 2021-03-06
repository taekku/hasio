SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 급여가족수당
-- 
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[P_CNV_PAY_PHM_FAMILY]
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
			, @nm_family		nvarchar(40) -- 가족성명
			, @no_repre			nvarchar(300) -- 주민번호
		  -- 참조변수
		  , @emp_id			numeric -- 사원ID
		  , @person_id		numeric -- 개인ID
			, @fam_ctz_no		nvarchar(300) -- 가족주민번호

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '급여가족수당'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_HUMAN_FAMILY'   -- As-Is Table
	set @v_t_table = 'PAY_PHM_FAMILY' -- To-Be Table
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
    DECLARE CNV_CUR CURSOR READ_ONLY
	    FOR SELECT CD_COMPANY
				 , NO_PERSON
				 , NO_REPRE
				 , NM_FAMILY
			  FROM dwehrdev.dbo.H_HUMAN_FAMILY
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
			      INTO @cd_company, @no_person, @no_repre, @nm_family
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
				set @fam_ctz_no = @no_repre
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				INSERT INTO PAY_PHM_FAMILY (
							 PAY_PHM_FAMILY_ID, --	가족수당ID
								EMP_ID, --	사원ID
								PERSON_ID, --	개인ID
								FAM_CTZ_NO, --	가족주민번호
								FAM_LAST_NM, --	가족성명(성)
								FAM_FIRST_NM, --	가족성명(이름)
								FAM_REL_CD, --	가족관계코드 [PHM_REL_CD]
								SUPPORT_YN, --	부양자여부
								HANICAP_YN, --	장애자여부
								FAM_PAY_YN, --	가족수당여부
								NOTE, --	비고
							 MOD_USER_ID	-- 변경자
							,MOD_DATE	-- 변경일시
							,TZ_CD	-- 타임존코드
							,TZ_DATE	-- 타임존일시
				       )
				SELECT NEXT VALUE FOR S_PAY_SEQUENCE AS PAY_PHM_FAMILY_ID,
								@emp_id	EMP_ID, --	사원ID
								@person_id	PERSON_ID, --	개인ID
								@fam_ctz_no	FAM_CTZ_NO, --	가족주민번호
								@nm_family	FAM_LAST_NM, --	가족성명(성)
								NULL	FAM_FIRST_NM, --	가족성명(이름)
								(SELECT CD
FROM MIG_STD_CD_MAP MAP
WHERE MAP.CD_KIND='PHM_FAM_REL_CD'
AND ASIS_CD=A.CD_RELATION)	FAM_REL_CD, --	가족관계코드 [PHM_REL_CD]
								NULL	SUPPORT_YN, --	부양자여부
								A.YN_DISABLED	HANICAP_YN, --	장애자여부
								A.YN_FAMILY	FAM_PAY_YN, --	가족수당여부
								A.REMARK	NOTE  --	비고
					, 0 --MOD_USER_ID	--변경자
					, ISNULL(A.DT_UPDATE,'1900-01-01') --MOD_DATE	--변경일시
					, 'KST' TZ_CD	--타임존코드
					, ISNULL(A.DT_UPDATE,'1900-01-01') -- TZ_DATE	--타임존일시
				  FROM dwehrdev.dbo.H_HUMAN_FAMILY A
				 WHERE A.CD_COMPANY = @s_company_cd
				   AND A.NO_PERSON = @no_person
					 AND A.NM_FAMILY = @nm_family
					 AND A.NO_REPRE = @no_repre
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
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',no_repre=' + ISNULL(CONVERT(nvarchar(100), @no_repre),'NULL')
							  + ',nm_family=' + ISNULL(CONVERT(nvarchar(100), @nm_family),'NULL')
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
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',no_repre=' + ISNULL(CONVERT(nvarchar(100), @no_repre),'NULL')
							  + ',nm_family=' + ISNULL(CONVERT(nvarchar(100), @nm_family),'NULL')
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

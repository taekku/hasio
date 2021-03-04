SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 건강보험/국민연금
-- 건강보험/국민연금 업로드 --> 건겅보험가입정보
                        --> 국민연금가입정보
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_H_MED_INSUR
      @an_try_no         NUMERIC(4)       -- 시도회차
    , @av_company_cd     NVARCHAR(10)     -- 회사코드
    , @av_fg_insur	     NVARCHAR(10)     -- 국민(1)/건강(2)
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
		  , @fg_insur		nvarchar(20) -- 
		  , @init_ym_insur		nvarchar(20)
		  , @ym_insur		nvarchar(20)
		  , @no_person		nvarchar(20)
		  -- 참조변수
		  , @emp_id			numeric -- 사원ID
		  , @person_id		numeric -- 개인ID
		  , @hire_ymd		date
		  , @insert_ok		numeric

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '건강보험/국민연금'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_fg_insur),'NULL')
	set @v_s_table = 'H_MED_INSUR'   -- As-Is Table
	IF @av_fg_insur = '1'
		begin
			set @v_pgm_title = '국민연금가입정보'
			set @v_t_table = 'STP_JOIN_INFO' -- To-Be Table(국민연금가입정보)
		end
	else
		begin
			set @v_pgm_title = '건강보험가입정보'
			set @v_t_table = 'NHS_JOIN_INFO' -- To-Be Table(건강보험가입정보)
		end
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
				 , FG_INSUR
				 , MIN(YM_INSUR) AS INIT_YM_INSUR
				 , MAX(YM_INSUR) AS YM_INSUR
				 , NO_PERSON
			  FROM dwehrdev.dbo.H_MED_INSUR
			 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
			   AND FG_INSUR = @av_fg_insur -- > 국민연금
			 GROUP BY CD_COMPANY, FG_INSUR, NO_PERSON
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
				     , @fg_insur, @init_ym_insur, @ym_insur, @no_person
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- 총 건수확인
				set @s_company_cd = @cd_company -- AS-IS 회사코드
				set @t_company_cd = UPPER(@cd_company) -- TO-BE 회사코드
				
				-- =======================================================
				--  EMP_ID 찾기
				-- =======================================================
				SELECT @emp_id = EMP_ID, @person_id = PERSON_ID, @hire_ymd = STA_YMD
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
						CONTINUE;
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				IF @fg_insur = '1' -- 국민연금
					begin
						INSERT INTO dwehrdev_H5.dbo.STP_JOIN_INFO(
								STP_JOIN_INFO_ID, --	국민연금가입정보ID
								EMP_ID, --	사원ID
								REPORT_TYPE, --	신고구분[STP_STAT_TYPE_CD]
								STA_YMD, --	시작일자
								END_YMD, --	종료일자
								SUB_COMPANY_CD, --	서브회사코드
								REPORT_YMD, --	취득신고일
								REPORT_CD, --	취득월납부여부(STP_REPORT_CD)
								CAUSE_CD, --	사유부호
								NATION_CD, --	국적코드[STP_NATIVE_TYPE_CD)
								STAY_CD, --	외국인체류자격[STP_STAY_CAPA_CD]
								SIN_YN, --	신고여부
								STAND_AMT, --	보수월액
								INSU_AMT, --	보험료
								SPECIAL_CD, --	특수직종부호[STP_SPEC_TYPE_CD]
								EXCEP_CD, --	납부예외부호(STP_EXCE_CD)
								EXP_YMD, --	납부(재개)예외일
								RE_STA_YMD, --	납부재개예정일
								STATUS, --	납부상태[STP_SUBT_TYPE_CD]
								RATE, --	납부율
								NOTE,--	비고
								MOD_USER_ID, --	변경자
								MOD_DATE, --	변경일시
								TZ_CD, --	타임존코드
								TZ_DATE  --	타임존일시
							   )
						SELECT NEXT VALUE FOR S_STP_SEQUENCE as STP_JOIN_INFO_ID, --	국민연금가입정보ID
								@emp_id	EMP_ID, --	사원ID
								'01' REPORT_TYPE, --	신고구분[STP_STAT_TYPE_CD] '01':취득
								@hire_ymd, --(SELECT HIRE_YMD FROM PHM_EMP WHERE EMP_ID=@emp_id), -- 시작일자
								case  when @init_ym_insur < @ym_insur then
										dbo.XF_DATEADD( dbo.XF_TO_DATE(@ym_insur + '01', 'yyyymmdd') , -1)
									  else
										dbo.XF_TO_DATE('29991231','yyyymmdd') end END_YMD, --	종료일자
								'' SUB_COMPANY_CD, --	서브회사코드
								@hire_ymd, --(SELECT HIRE_YMD FROM PHM_EMP WHERE EMP_ID=@emp_id) REPORT_YMD, --	취득신고일
								'1' REPORT_CD, --	취득월납부여부(STP_REPORT_CD) 1:희망
								NULL CAUSE_CD, --	사유부호
								'1' NATION_CD, --	국적코드[STP_NATIVE_TYPE_CD) 1:내국인, 9:외국인
								NULL	STAY_CD, --	외국인체류자격[STP_STAY_CAPA_CD]
								'Y'	SIN_YN, --	신고여부
								AMT_STANDARD	STAND_AMT, --	보수월액
								AMT_INSUR	INSU_AMT, --	보험료
								NULL	SPECIAL_CD, --	특수직종부호[STP_SPEC_TYPE_CD]
								NULL	EXCEP_CD, --	납부예외부호(STP_EXCE_CD)
								NULL	EXP_YMD, --	납부(재개)예외일
								NULL	RE_STA_YMD, --	납부재개예정일
								'01'	STATUS, --	납부상태[STP_SUBT_TYPE_CD] 01:적용, 02:비적용, 03:면제
								100 RATE-- RATE_INSUR	RATE --	납부율
								,  REM_COMMENT
								, 0 AS MOD_USER_ID
								, ISNULL(DT_UPDATE,'1900-01-01')
								, 'KST'
								, ISNULL(DT_UPDATE,'1900-01-01')
						  FROM dwehrdev.dbo.H_MED_INSUR A
						 WHERE CD_COMPANY = @s_company_cd
						   AND FG_INSUR = @fg_insur
						   AND YM_INSUR = @init_ym_insur
						   AND NO_PERSON = @no_person
						IF @@ROWCOUNT > 0
							set @insert_ok = 1
						ELSE
							set @insert_ok = 0

						IF @init_ym_insur < @ym_insur
							BEGIN
								-- 변경
								INSERT INTO dwehrdev_H5.dbo.STP_JOIN_INFO(
										STP_JOIN_INFO_ID, --	국민연금가입정보ID
										EMP_ID, --	사원ID
										REPORT_TYPE, --	신고구분[STP_STAT_TYPE_CD]
										STA_YMD, --	시작일자
										END_YMD, --	종료일자
										SUB_COMPANY_CD, --	서브회사코드
										REPORT_YMD, --	취득신고일
										REPORT_CD, --	취득월납부여부(STP_REPORT_CD)
										CAUSE_CD, --	사유부호
										NATION_CD, --	국적코드[STP_NATIVE_TYPE_CD)
										STAY_CD, --	외국인체류자격[STP_STAY_CAPA_CD]
										SIN_YN, --	신고여부
										STAND_AMT, --	보수월액
										INSU_AMT, --	보험료
										SPECIAL_CD, --	특수직종부호[STP_SPEC_TYPE_CD]
										EXCEP_CD, --	납부예외부호(STP_EXCE_CD)
										EXP_YMD, --	납부(재개)예외일
										RE_STA_YMD, --	납부재개예정일
										STATUS, --	납부상태[STP_SUBT_TYPE_CD]
										RATE, --	납부율
										NOTE,--	비고
										MOD_USER_ID, --	변경자
										MOD_DATE, --	변경일시
										TZ_CD, --	타임존코드
										TZ_DATE  --	타임존일시
											)
								SELECT NEXT VALUE FOR S_STP_SEQUENCE as STP_JOIN_INFO_ID, --	국민연금가입정보ID
										@emp_id	EMP_ID, --	사원ID
										'12' REPORT_TYPE, --	신고구분[STP_STAT_TYPE_CD] '12':보수월액변경
										@ym_insur + '01', -- -- 시작일자
										'29991231'	END_YMD, --	종료일자
										'' SUB_COMPANY_CD, --	서브회사코드
										NULL REPORT_YMD, --	취득신고일
										'1' REPORT_CD, --	취득월납부여부(STP_REPORT_CD) 1:희망
										NULL CAUSE_CD, --	사유부호
										'1' NATION_CD, --	국적코드[STP_NATIVE_TYPE_CD) 1:내국인, 9:외국인
										NULL	STAY_CD, --	외국인체류자격[STP_STAY_CAPA_CD]
										'Y'	SIN_YN, --	신고여부
										AMT_STANDARD	STAND_AMT, --	보수월액
										AMT_INSUR	INSU_AMT, --	보험료
										NULL	SPECIAL_CD, --	특수직종부호[STP_SPEC_TYPE_CD]
										NULL	EXCEP_CD, --	납부예외부호(STP_EXCE_CD)
										NULL	EXP_YMD, --	납부(재개)예외일
										NULL	RE_STA_YMD, --	납부재개예정일
										'01'	STATUS, --	납부상태[STP_SUBT_TYPE_CD] 01:적용, 02:비적용, 03:면제
										100 RATE--RATE_INSUR	RATE --	납부율
										,  REM_COMMENT
										, 0 AS MOD_USER_ID
										, ISNULL(DT_UPDATE,'1900-01-01')
										, 'KST'
										, ISNULL(DT_UPDATE,'1900-01-01')
									FROM dwehrdev.dbo.H_MED_INSUR A
									WHERE CD_COMPANY = @s_company_cd
										AND FG_INSUR = @fg_insur
										AND YM_INSUR = @ym_insur
										AND NO_PERSON = @no_person
								IF @@ROWCOUNT > 0
									set @insert_ok = 1
								ELSE
									set @insert_ok = 0
							END
					end
				ELSE IF @fg_insur = '2' -- 건강보험
					begin
						INSERT INTO dwehrdev_H5.dbo.NHS_JOIN_INFO(
								NHS_JOIN_INFO_ID,--	건강보험가입정보ID
								EMP_ID,--	사원ID
								REPORT_TYPE,--	신고구분(NHS_STAT_TYPE_CD)
								STA_YMD,--	시작일자
								END_YMD,--	종료일자
								SUB_COMPANY_CD,--	서브회사코드
								REPORT_YMD,--	신고일자
								CAUSE_CD,--	사유부호
								NATION_CD,--	국적코드[NHS_NATIVE_TYPE_CD)
								STAY_CD,--	외국인체류자격[NHS_STAY_CAPA_CD]
								RED_AMT_CD,--	감면부호(NHS_RED_AMT_CD)
								HNDCP_CD,--	장애유공자부호(NHS_INJURY_CD)
								HNDCP_GRADE,--	장애유공자등급(PHM_HANDICAP_GRD_CD)
								HNDCP_YMD,--	장애유공자등록일자
								SIN_YN,--	신고여부
								NHS_NO,--	증번호
								SEND_YN,--	즐사업장발송여부
								STAND_AMT,--	보수월액
								INSU_AMT,--	보험료
								LONG_INSU_AMT,--	장기요양보험료
								EXP_YMD,--	납부예외일
								RE_STA_YMD,--	납부재개예정일
								EXEC_CD,--	유예사유코드
								STATUS,--	급여적용상태[NHS_JOIN_STATE_CD]
								RATE,--	납부율
								RETIRE_YN,--	동시퇴직여부
								ACCNT_CD,--	회계(공교사업장)
								JOB_CD,--	직종
								NOTE,--	비고
								MOD_USER_ID, --	변경자
								MOD_DATE, --	변경일시
								TZ_CD, --	타임존코드
								TZ_DATE  --	타임존일시
							   )
						SELECT NEXT VALUE FOR S_NHS_SEQUENCE as NHS_JOIN_INFO_ID,--	건강보험가입정보ID
								@emp_id	EMP_ID,--	사원ID
								'01'	REPORT_TYPE,--	신고구분(NHS_STAT_TYPE_CD) 01:취득
								@hire_ymd, --(SELECT HIRE_YMD FROM PHM_EMP WHERE EMP_ID=@emp_id), -- 시작일자
								case  when @init_ym_insur < @ym_insur then
										dbo.XF_DATEADD( dbo.XF_TO_DATE(@ym_insur + '01', 'yyyymmdd') , -1)
									  else
										dbo.XF_TO_DATE('29991231','yyyymmdd') end END_YMD, --	종료일자
								''	SUB_COMPANY_CD,--	서브회사코드
								@hire_ymd, --(SELECT HIRE_YMD FROM PHM_EMP WHERE EMP_ID=@emp_id)	REPORT_YMD,--	신고일자
								NULL	CAUSE_CD,--	사유부호
								'1'	NATION_CD,--	국적코드[NHS_NATIVE_TYPE_CD) 1:내국인, 9:외국인
								NULL	STAY_CD,--	외국인체류자격[NHS_STAY_CAPA_CD]
								NULL	RED_AMT_CD,--	감면부호(NHS_RED_AMT_CD)
								NULL	HNDCP_CD,--	장애유공자부호(NHS_INJURY_CD)
								NULL	HNDCP_GRADE,--	장애유공자등급(PHM_HANDICAP_GRD_CD)
								NULL	HNDCP_YMD,--	장애유공자등록일자
								'Y'	SIN_YN,--	신고여부
								NULL	NHS_NO,--	증번호
								'Y'	SEND_YN,--	즐사업장발송여부
								AMT_STANDARD	STAND_AMT,--	보수월액
								AMT_INSUR	INSU_AMT,--	보험료
								0	LONG_INSU_AMT,--	장기요양보험료
								NULL	EXP_YMD,--	납부예외일
								NULL	RE_STA_YMD,--	납부재개예정일
								NULL	EXEC_CD,--	유예사유코드
								'01'	STATUS,--	급여적용상태[NHS_JOIN_STATE_CD] 01:적용
								100 RATE, --RATE_INSUR	RATE,--	납부율
								NULL	RETIRE_YN,--	동시퇴직여부
								NULL	ACCNT_CD,--	회계(공교사업장)
								NULL	JOB_CD--	직종
								,  REM_COMMENT
								, 0 AS MOD_USER_ID
								, ISNULL(DT_UPDATE,'1900-01-01')
								, 'KST'
								, ISNULL(DT_UPDATE,'1900-01-01')
						  FROM dwehrdev.dbo.H_MED_INSUR A
						 WHERE CD_COMPANY = @s_company_cd
						   AND FG_INSUR = @fg_insur
						   AND YM_INSUR = @init_ym_insur
						   AND NO_PERSON = @no_person
						IF @@ROWCOUNT > 0
							set @insert_ok = 1
						ELSE
							set @insert_ok = 0
						IF @init_ym_insur < @ym_insur
							BEGIN
								INSERT INTO dwehrdev_H5.dbo.NHS_JOIN_INFO(
										NHS_JOIN_INFO_ID,--	건강보험가입정보ID
										EMP_ID,--	사원ID
										REPORT_TYPE,--	신고구분(NHS_STAT_TYPE_CD)
										STA_YMD,--	시작일자
										END_YMD,--	종료일자
										SUB_COMPANY_CD,--	서브회사코드
										REPORT_YMD,--	신고일자
										CAUSE_CD,--	사유부호
										NATION_CD,--	국적코드[NHS_NATIVE_TYPE_CD)
										STAY_CD,--	외국인체류자격[NHS_STAY_CAPA_CD]
										RED_AMT_CD,--	감면부호(NHS_RED_AMT_CD)
										HNDCP_CD,--	장애유공자부호(NHS_INJURY_CD)
										HNDCP_GRADE,--	장애유공자등급(PHM_HANDICAP_GRD_CD)
										HNDCP_YMD,--	장애유공자등록일자
										SIN_YN,--	신고여부
										NHS_NO,--	증번호
										SEND_YN,--	즐사업장발송여부
										STAND_AMT,--	보수월액
										INSU_AMT,--	보험료
										LONG_INSU_AMT,--	장기요양보험료
										EXP_YMD,--	납부예외일
										RE_STA_YMD,--	납부재개예정일
										EXEC_CD,--	유예사유코드
										STATUS,--	급여적용상태[NHS_JOIN_STATE_CD]
										RATE,--	납부율
										RETIRE_YN,--	동시퇴직여부
										ACCNT_CD,--	회계(공교사업장)
										JOB_CD,--	직종
										NOTE,--	비고
										MOD_USER_ID, --	변경자
										MOD_DATE, --	변경일시
										TZ_CD, --	타임존코드
										TZ_DATE  --	타임존일시
										 )
								SELECT NEXT VALUE FOR S_NHS_SEQUENCE as NHS_JOIN_INFO_ID,--	건강보험가입정보ID
										@emp_id	EMP_ID,--	사원ID
										'16'	REPORT_TYPE,--	신고구분(NHS_STAT_TYPE_CD) 16:보수월액변경
										@ym_insur + '01' , -- 시작일자
										'29991231'	END_YMD,--	종료일자
										''	SUB_COMPANY_CD,--	서브회사코드
										NULL	REPORT_YMD,--	신고일자
										NULL	CAUSE_CD,--	사유부호
										'1'	NATION_CD,--	국적코드[NHS_NATIVE_TYPE_CD) 1:내국인, 9:외국인
										NULL	STAY_CD,--	외국인체류자격[NHS_STAY_CAPA_CD]
										NULL	RED_AMT_CD,--	감면부호(NHS_RED_AMT_CD)
										NULL	HNDCP_CD,--	장애유공자부호(NHS_INJURY_CD)
										NULL	HNDCP_GRADE,--	장애유공자등급(PHM_HANDICAP_GRD_CD)
										NULL	HNDCP_YMD,--	장애유공자등록일자
										'Y'	SIN_YN,--	신고여부
										NULL	NHS_NO,--	증번호
										'Y'	SEND_YN,--	즐사업장발송여부
										AMT_STANDARD	STAND_AMT,--	보수월액
										AMT_INSUR	INSU_AMT,--	보험료
										0	LONG_INSU_AMT,--	장기요양보험료
										NULL	EXP_YMD,--	납부예외일
										NULL	RE_STA_YMD,--	납부재개예정일
										NULL	EXEC_CD,--	유예사유코드
										'01'	STATUS,--	급여적용상태[NHS_JOIN_STATE_CD] 01:적용
										100 RATE,--RATE_INSUR	RATE,--	납부율
										NULL	RETIRE_YN,--	동시퇴직여부
										NULL	ACCNT_CD,--	회계(공교사업장)
										NULL	JOB_CD--	직종
										,  REM_COMMENT
										, 0 AS MOD_USER_ID
										, ISNULL(DT_UPDATE,'1900-01-01')
										, 'KST'
										, ISNULL(DT_UPDATE,'1900-01-01')
									FROM dwehrdev.dbo.H_MED_INSUR A
								 WHERE CD_COMPANY = @s_company_cd
									 AND FG_INSUR = @fg_insur
									 AND YM_INSUR = @ym_insur
									 AND NO_PERSON = @no_person
								IF @@ROWCOUNT > 0
									set @insert_ok = 1
								ELSE
									set @insert_ok = 0
							END
					end
				IF @fg_insur not in ('1','2')
					print 'fg_insur=[' + @fg_insur + ']'
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================

				if @insert_ok > 0 
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
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @s_company_cd),'NULL')
							  + ',' + ISNULL(CONVERT(nvarchar(100), @fg_insur),'NULL')
							  + ',' + ISNULL(CONVERT(nvarchar(100), @ym_insur),'NULL')
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
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @s_company_cd),'NULL')
							  + ',@fg_insur=' + ISNULL(CONVERT(nvarchar(100), @fg_insur),'NULL')
							  + ',@init_ym_insur=' + ISNULL(CONVERT(nvarchar(100), @init_ym_insur),'NULL')
							  + ',@ym_insur=' + ISNULL(CONVERT(nvarchar(100), @ym_insur),'NULL')
							  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',@emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
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

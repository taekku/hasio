SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 급여일자관리
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_PAY_YMD
      @an_log_h_id		NUMERIC(20)      -- 로그H코드
    , @av_company_cd	NVARCHAR(10)    -- 회사코드
	, @av_ym_pay		nvarchar(10)	-- 급여년월
	, @av_fg_supp		nvarchar(10)	-- 급여구분
	, @av_dt_prov		nvarchar(10)	-- 급여지급일
	, @cd_paygp			nvarchar(10)	-- 급여그룹
	, @ad_dt_update		datetime	-- 수정일
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
		  -- 기타
		  , @pay_ymd_id numeric -- 급여일자ID
		  , @pay_type_cd	nvarchar(10) -- 급여지급유형
		  , @alter_pay_type_cd	nvarchar(10) -- 대체급여지급유형
		  , @pay_type_sys_cd nvarchar(10) -- 급여지급유형(시스템)
		  , @v_err_message	nvarchar(100)

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '급여일자관리'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@av_ym_pay=' + ISNULL(CONVERT(nvarchar(100), @av_ym_pay),'NULL')
				+ ',@av_fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
				+ ',@av_dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
				+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
	set @v_s_table = 'H_MONTH_PAY_BONUS'   -- As-Is Table
	set @v_t_table = 'PAY_PAY_YMD' -- To-Be Table
	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	
	set @fg_supp = @av_fg_supp
	set @n_log_h_id = @an_log_h_id
	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	-- =============================================
	--   회사별로 급여지급유형구하기
	-- =============================================
	SELECT @pay_type_cd = CASE WHEN PAY_TYPE_CD = '' THEN NULL ELSE PAY_TYPE_CD END
	     , @pay_type_sys_cd = (SELECT SYS_CD FROM FRM_CODE (NOLOCK) WHERE COMPANY_CD=A.COMPANY_CD AND CD = A.PAY_TYPE_CD AND CD_KIND='PAY_TYPE_CD' AND GETDATE() BETWEEN STA_YMD AND END_YMD)
	  FROM CNV_PAY_TYPE A (NOLOCK)
	 WHERE COMPANY_CD = @av_company_cd
	   AND CD_PAYGP = @cd_paygp
	   AND FG_SUPP = @fg_supp
	--PRINT ISNULL(@pay_type_cd,'NULL') + ':' + ISNULL(@pay_type_sys_cd,'NULL') + ':' + ISNULL(@av_company_cd,'NULL') + ':' + ISNULL(@cd_paygp,'NULL') + ':' + ISNULL(@fg_supp,'NULL')
	IF @@ROWCOUNT < 1
		BEGIN
			set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
					+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
					+ ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
					+ ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
					+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
					+ ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
			set @v_err_msg = @v_proc_nm + ' ' + '급여지급유형를 구할 수 없습니다.(CNV_PAY_TYPE)'
			
			EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
			RETURN
		END
	-------------------------
	-- 대체지급유형코드가 있는지
	-------------------------
	SELECT @alter_pay_type_cd = CASE WHEN ALTER_PAY_TYPE_CD > '' THEN ALTER_PAY_TYPE_CD ELSE NULL END
	  FROM CNV_PAY_YMD
	 WHERE CD_COMPANY = @av_company_cd
	   AND YM_PAY = @av_ym_pay
	   AND FG_SUPP = @av_fg_supp
	   AND DT_PROV = @av_dt_prov
	   AND PAY_TYPE_CD = @pay_type_cd
	IF @@ROWCOUNT < 1
		SET @alter_pay_type_cd = NULL
	IF @alter_pay_type_cd > ''
	BEGIN
						set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
							  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @av_ym_pay),'NULL')
							  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
							  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
							  + ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
							  + ',@alter_pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @alter_pay_type_cd),'NULL')
							  + ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
		set @v_err_message = '대체유형코드사용:' + @alter_pay_type_cd
		EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, '999', @v_err_message
	END
	-------------------------
	-- 급여일자가 있는지
	-------------------------
	SELECT @pay_ymd_id = PAY_YMD_ID
	  FROM PAY_PAY_YMD WITH (NOLOCK)
	 WHERE COMPANY_CD = @av_company_cd
	   AND PAY_YM = @av_ym_pay
	   AND PAY_YMD =  @av_dt_prov
	   AND PAY_TYPE_CD = ISNULL(@alter_pay_type_cd, @pay_type_cd)
	IF @@ROWCOUNT < 1
		SET @pay_ymd_id = 0

	IF ISNULL(@alter_pay_type_cd, @pay_type_cd) is not NULL AND @pay_ymd_id = 0
		BEGIN
			--print 'insert:' + @av_company_cd + @av_ym_pay + @av_dt_prov + @pay_type_cd
			select @pay_ymd_id = NEXT VALUE FOR S_PAY_SEQUENCE
			begin try
				INSERT INTO PAY_PAY_YMD(
					PAY_YMD_ID, --	급여일자ID
					COMPANY_CD, --	인사영역
					PAY_YMD, --	급여일자
					GIVE_YMD, --	지급일자
					PAY_TYPE_CD, --	급여지급유형[PAY_TYPE_CD]
					PAY_YM, --	급여적용년월
					TAX_YM, -- 세무신고년월
					STD_YMD, --	산출기준일
					STA_YMD, --	산정기간(From)
					END_YMD, --	산정기간(to)
					RETRO_YN, --	소급대상여부
					TAX_YN, --	세금계산여부
					EMI_YN, --	고용보험계산여부
					ACCOUNT_TYPE_CD, --	계좌유형[PAY_ACCOUNT_TYPE_CD]
					PRINT_TITLE, --	출력명칭
					CLOSE_YN, --	마감여부
					NOTICE, --	급여명세공지
					SLIP_DATE, --	전표생성일자
					RETRO_PAY_YMD_ID, --	임금인상대상급여ID
					PAY_YN, --	지급여부
					NOTE, --	비고
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일시
					TZ_CD, --	타임존코드
					TZ_DATE --	타임존일시
					)
				SELECT 
					@pay_ymd_id	PAY_YMD_ID, --	급여일자ID
					@av_company_cd	COMPANY_CD, --	인사영역
					@av_dt_prov	PAY_YMD, --	급여일자
					@av_dt_prov	GIVE_YMD, --	지급일자
					ISNULL(@alter_pay_type_cd, @pay_type_cd)	PAY_TYPE_CD, --	급여지급유형[PAY_TYPE_CD]
					@av_ym_pay	PAY_YM, --	급여적용년월
					@av_ym_pay  TAX_YM, -- 세금신고년월
					@av_dt_prov	STD_YMD, --	산출기준일
					SUBSTRING(@av_dt_prov, 1, 6) + '01'	STA_YMD, --	산정기간(From)
					dbo.XF_LAST_DAY(@av_dt_prov)	END_YMD, --	산정기간(to)
					case when @pay_type_sys_cd = '009' then 'Y' else 'N' end	RETRO_YN, --	소급대상여부
					'Y'	TAX_YN, --	세금계산여부
					'Y'	EMI_YN, --	고용보험계산여부
					'01'	ACCOUNT_TYPE_CD, --	계좌유형[PAY_ACCOUNT_TYPE_CD] 급여계좌
					@av_ym_pay + dbo.F_FRM_CODE_NM( @av_company_cd, 'KO', 'PAY_TYPE_CD', @pay_type_cd, dbo.XF_SYSDATE(0), '1')	PRINT_TITLE, --	출력명칭
					'Y'	CLOSE_YN, --	마감여부
					--'N'	CLOSE_YN, --	마감여부 [임시로 마감]
					NULL	NOTICE, --	급여명세공지
					NULL	SLIP_DATE, --	전표생성일자
					NULL	RETRO_PAY_YMD_ID, --	임금인상대상급여ID
					'Y'	PAY_YN, --	지급여부
					NULL	NOTE, --	비고
						0 AS MOD_USER_ID
					, ISNULL(@ad_dt_update, '1900-01-01')
					, 'KST'
					, ISNULL(@ad_dt_update, '1900-01-01')
				--IF @@ROWCOUNT < 1
				--	BEGIN
				--		set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				--			  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @ym_pay),'NULL')
				--			  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @fg_supp),'NULL')
				--			  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @dt_prov),'NULL')
				--			  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
				--		set @v_err_msg = @v_proc_nm + ' ' + ERROR_MESSAGE()
						
				--		EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
				--	END
				exec dbo.P_PAY_CLOSE_CREATE @pay_ymd_id, 0, '', '' -- 유형별 산정기간생성
			end Try
				
			BEGIN CATCH
				print 'Error' + Error_message()
				-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
							  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @av_ym_pay),'NULL')
							  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
							  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
							  + ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
							  + ',@alter_pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @alter_pay_type_cd),'NULL')
							  + ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
						set @v_err_msg = @v_proc_nm + ' ' + ERROR_MESSAGE()
						
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
						set @pay_ymd_id = 0
				-- *** 로그에 실패 메시지 저장 ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
			END CATCH
		END
	--ELSE
	--	BEGIN
	--		IF @pay_ymd_id = 0
	--		BEGIN
	--					set @n_err_cod = 999
	--					set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	--						  + ',@ym_pay=' + ISNULL(CONVERT(nvarchar(100), @av_ym_pay),'NULL')
	--						  + ',@fg_supp=' + ISNULL(CONVERT(nvarchar(100), @av_fg_supp),'NULL')
	--						  + ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @av_dt_prov),'NULL')
	--						  + ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
	--						  + ',@alter_pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @alter_pay_type_cd),'NULL')
	--						  + ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
	--					set @v_err_msg = @v_proc_nm + ' ' + '급여일자를 알수없음.'
						
	--					EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
	--		END
	--	END
	RETURN @pay_ymd_id
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 급여일자관리
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_PAY_YMD_SAP
      @an_log_h_id		NUMERIC(20)      -- 로그H코드
    , @av_company_cd	NVARCHAR(10)    -- 회사코드
	, @av_sap_kind1		nvarchar(10)	-- 유형1
	, @av_sap_kind2		nvarchar(10)	-- 유형2
	, @ad_dt_prov		date			-- 급여지급일
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
		  -- 기타
		  , @pay_ymd_id numeric -- 급여일자ID
		  , @pay_type_cd	nvarchar(10) -- 급여지급유형
		  , @pay_type_sys_cd nvarchar(10) -- 급여지급유형(시스템)
		  , @v_err_message	nvarchar(100)

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '급여일자관리'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@av_sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind1),'NULL')
				+ ',@av_sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind2),'NULL')
				+ ',@av_dt_prov=' + ISNULL(CONVERT(nvarchar(100), @ad_dt_prov),'NULL')
				+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
	set @v_s_table = 'CNV_PAY_TYPE_SAP'   -- As-Is Table
	set @v_t_table = 'PAY_PAY_YMD' -- To-Be Table
	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @n_log_h_id = @an_log_h_id
	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	-- =============================================
	--   회사별로 급여지급유형구하기 222222222
	-- =============================================
	SELECT @pay_type_cd = CASE WHEN PAY_TYPE_CD = '' THEN NULL ELSE PAY_TYPE_CD END
	     , @pay_type_sys_cd = SYS_CD
	  FROM CNV_PAY_TYPE_SAP A (NOLOCK)
	 WHERE CD_PAYGP = @cd_paygp
	   AND SAP_KIND1 = @av_sap_kind1
	   AND SAP_KIND2 = @av_sap_kind2
	   AND DT_PROV = @ad_dt_prov

	IF @@ROWCOUNT < 1
		BEGIN
				BEGIN
					set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
							+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
							+ ',@av_sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind1),'NULL')
							+ ',@av_sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind2),'NULL')
							+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @ad_dt_prov),'NULL')
					set @v_err_msg = @v_proc_nm + ' ' + '급여지급유형를 구할 수 없습니다.(CNV_PAY_TYPE_SAP)'
			
					EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
					RETURN
				END
		END
	-------------------------
	-- 급여일자가 있는지
	-------------------------
	SELECT @pay_ymd_id = PAY_YMD_ID
	  FROM PAY_PAY_YMD WITH (NOLOCK)
	 WHERE COMPANY_CD = @av_company_cd
	   AND PAY_YMD =  @ad_dt_prov
	   AND PAY_TYPE_CD = @pay_type_cd
	   AND NOTE = 'FnB(SAP)'
	IF @@ROWCOUNT < 1
		SET @pay_ymd_id = 0
	--PRINT 'DHK:' + ISNULL(@alter_pay_type_cd,'') + ':' + ISNULL(@pay_type_cd,'')
	IF @pay_type_cd is not NULL AND @pay_ymd_id = 0
		BEGIN
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
					@ad_dt_prov	PAY_YMD, --	급여일자
					@ad_dt_prov	GIVE_YMD, --	지급일자
					@pay_type_cd	PAY_TYPE_CD, --	급여지급유형[PAY_TYPE_CD]
					FORMAT(@ad_dt_prov,'yyyyMM')	PAY_YM, --	급여적용년월
					FORMAT(@ad_dt_prov,'yyyyMM')  TAX_YM, -- 세금신고년월
					@ad_dt_prov	STD_YMD, --	산출기준일
					FORMAT(@aD_dt_prov, 'yyyyMM') + '01'	STA_YMD, --	산정기간(From)
					dbo.XF_LAST_DAY(@ad_dt_prov)	END_YMD, --	산정기간(to)
					case when @pay_type_sys_cd in ('001') then 'Y' else 'N' end	RETRO_YN, --	소급대상여부
					'Y'	TAX_YN, --	세금계산여부
					'Y'	EMI_YN, --	고용보험계산여부
					'01'	ACCOUNT_TYPE_CD, --	계좌유형[PAY_ACCOUNT_TYPE_CD] 급여계좌
					FORMAT(@ad_dt_prov,'yyyyMM') + dbo.F_FRM_CODE_NM( @av_company_cd, 'KO', 'PAY_TYPE_CD', @pay_type_cd, dbo.XF_SYSDATE(0), '1')	PRINT_TITLE, --	출력명칭
					'Y'	CLOSE_YN, --	마감여부
					--'N'	CLOSE_YN, --	마감여부 [임시로 마감]
					NULL	NOTICE, --	급여명세공지
					NULL	SLIP_DATE, --	전표생성일자
					NULL	RETRO_PAY_YMD_ID, --	임금인상대상급여ID
					'Y'	PAY_YN, --	지급여부
					'FnB(SAP)'	NOTE, --	비고
						0 AS MOD_USER_ID
					, ISNULL(@ad_dt_update, '1900-01-01')
					, 'KST'
					, ISNULL(@ad_dt_update, '1900-01-01')
				exec dbo.P_PAY_CLOSE_CREATE @pay_ymd_id, 0, '', '' -- 유형별 산정기간생성
			end Try
				
			BEGIN CATCH
				print 'Error' + Error_message()
				-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = '@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
								+ ',@av_sap_kind1=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind1),'NULL')
								+ ',@av_sap_kind2=' + ISNULL(CONVERT(nvarchar(100), @av_sap_kind2),'NULL')
								+ ',@dt_prov=' + ISNULL(CONVERT(nvarchar(100), @ad_dt_prov),'NULL')
								+ ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @pay_type_cd),'NULL')
								+ ',@cd_paygp=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
						set @v_err_msg = @v_proc_nm + ' ' + ERROR_MESSAGE()
						
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
						set @pay_ymd_id = 0
				-- *** 로그에 실패 메시지 저장 ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
			END CATCH
		END
	RETURN @pay_ymd_id
END
GO

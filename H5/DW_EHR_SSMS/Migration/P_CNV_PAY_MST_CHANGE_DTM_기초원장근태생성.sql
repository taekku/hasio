SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 기초원장생성(DTM:근태)
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_MST_CHANGE_for_DTM
      @an_try_no		NUMERIC(4)      -- 시도회차
    , @av_company_cd	NVARCHAR(10)    -- 회사코드
	, @av_fr_month		NVARCHAR(6)		-- 시작년월
	, @av_to_month		NVARCHAR(6)		-- 종료년월
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE 
		  -- 변환작업결과
		    @v_proc_nm   nvarchar(50) -- 프로그램ID
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
		  , @v_locale_cd	nvarchar(10) = 'KO'
		  -- AS-IS Table Key
	DECLARE @n_pay_ymd_id		NUMERIC(38)
	      , @d_pay_ymd			DATE
		  , @v_pay_ym			NVARCHAR(10)
		  , @v_pay_type_cd		NVARCHAR(10)
		  , @v_pay_group_cd		NVARCHAR(10)
		  , @v_salary_type_cd	NVARCHAR(10)
		  , @v_pay_term_type_cd	NVARCHAR(10)
		  , @d_term_sta_ymd		DATE
		  , @d_term_end_ymd		DATE

		  , @n_ins_cnt			INT

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '급여-근태집계'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',@av_company_cd=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',@av_fr_month=' + ISNULL(CONVERT(nvarchar(100), @av_fr_month),'NULL')
				+ ',@av_to_month=' + ISNULL(CONVERT(nvarchar(100), @av_to_month),'NULL')
	set @v_s_table = 'DTM_MONTH'   -- As-Is Table
	set @v_t_table = 'PAY_MST_CHANGE' -- To-Be Table
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
		SELECT YMD.PAY_YMD_ID, PAY_YMD, PAY_YM, YMD.PAY_TYPE_CD, G.PAY_GROUP
			 , YMD_DTL.SALARY_TYPE_CD, TERM.PAY_TERM_TYPE_CD
			 , TERM.STA_YMD, TERM.END_YMD
		  FROM PAY_PAY_YMD YMD
		  JOIN PAY_PAY_YMD_DTL YMD_DTL
		    ON YMD.PAY_YMD_ID = YMD_DTL.PAY_YMD_ID
		  JOIN PAY_PAY_YMD_DTL_TERM TERM
		    ON YMD_DTL.PAYYMD_DTL_ID = TERM.PAYYMD_DTL_ID
		   AND TERM.PAY_TERM_TYPE_CD IN ('21','22','23','24') -- 근태기간
		  JOIN FRM_CODE C1
			ON YMD.COMPANY_CD = C1.COMPANY_CD
		   AND YMD.PAY_TYPE_CD = C1.CD
		   AND C1.CD_KIND = 'PAY_TYPE_CD'
		   AND YMD.PAY_YMD BETWEEN C1.STA_YMD AND C1.END_YMD
		   AND C1.SYS_CD='001' -- 정기급여
		  JOIN PAY_GROUP_TYPE T
			ON YMD.COMPANY_CD = T.COMPANY_CD
		   AND YMD.PAY_TYPE_CD = T.PAY_TYPE_CD
		  JOIN PAY_GROUP G
			ON T.COMPANY_CD = G.COMPANY_CD
		   AND T.PAY_GROUP_ID = G.PAY_GROUP_ID
		 WHERE YMD.PAY_YM BETWEEN @av_fr_month AND @av_to_month
		   AND YMD.COMPANY_CD = @av_company_cd
	-- =============================================
	--   Pay Column Select
	-- =============================================
	OPEN CNV_CUR

	WHILE 1 = 1
		BEGIN
			-- =============================================
			--  작업할 급여유형
			-- =============================================
			FETCH NEXT FROM CNV_CUR
			      INTO @n_pay_ymd_id, @d_pay_ymd, @v_pay_ym, @v_pay_type_cd, @v_pay_group_cd
				     , @v_salary_type_cd, @v_pay_term_type_cd
					 , @d_term_sta_ymd, @d_term_end_ymd
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				DELETE A
				  FROM PAY_MST_CHANGE A
				  JOIN PAY_PAYROLL P
					ON A.PAY_YMD_ID = P.PAY_YMD_ID
				   AND A.EMP_ID = P.EMP_ID
				   AND P.PAY_GROUP_CD = @v_pay_group_cd
				   AND A.PAY_YMD_ID = @n_pay_ymd_id
				   AND A.SALARY_TYPE_CD = @v_salary_type_cd
				  JOIN (SELECT DISTINCT
														   A.KEY_CD1 AS PAY_GRPCD,
														   A.KEY_CD2 AS PAY_DTM_CD--,
														   --A.KEY_CD3 AS DTM_ITEM_CD
												  FROM FRM_UNIT_STD_HIS A,
													   FRM_UNIT_STD_MGR B
												 WHERE A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
												   AND B.LOCALE_CD  = @v_locale_cd
												   AND B.COMPANY_CD = @av_company_cd
												   AND B.UNIT_CD    = 'PAY'
												   AND B.STD_KIND   = 'PAY_DTM_MST_MAP'   
												   AND A.KEY_CD1	= @v_pay_group_cd
												   AND @d_pay_ymd BETWEEN A.STA_YMD AND A.END_YMD
												   ) C ON A.PAY_ITEM_CD = C.PAY_DTM_CD
				INSERT INTO PAY_MST_CHANGE
                        (
                            PAY_MST_CHANGE_ID       ,  -- 기초원장ID
                            EMP_ID                  ,  -- 사원ID
                            SALARY_TYPE_CD          ,  -- 급여유형
                            PAY_ITEM_CD             ,  -- 급여항목기준코드(PAY_ITEM_CD)
                            PAY_ITEM_VALUE          ,  -- 급여기준항목값
                            PAY_ITEM_VALUE_TEXT     ,  -- 급여기준항목값 설명
                            STA_YMD                 ,  -- 시작일자
                            END_YMD                 ,  -- 종료일자
                            LAST_YN                 ,  -- 최종데이타여부
                            PAY_YMD_ID              ,  -- 급여일자ID(급여 의뢰 데이타만
                            MOD_USER_ID             ,  -- 변경자
                            MOD_DATE                ,  -- 변경일시
                            TZ_CD                   ,  -- 타임존코드
                            TZ_DATE                 ,  -- 타임존일시
                            BEL_ORG_ID              ,  -- 귀속부서id
						    MAKE_PAY_YMD_ID         ,  --생성시급여일자ID(소급체크를 위해 넣음)
                            RETRO_CHK_STA_YMD          --소급일자체크여부
                        )
					SELECT 
							next value for s_pay_sequence PAY_MST_CHANGE_ID       ,  -- 기초원장ID
                            PAY.EMP_ID EMP_ID                  ,  -- 사원ID
                            @v_salary_type_cd SALARY_TYPE_CD          ,  -- 급여유형
                            C.PAY_DTM_CD PAY_ITEM_CD             ,  -- 급여항목기준코드(PAY_ITEM_CD)
                            SUM(B.ITEM_VAL) PAY_ITEM_VALUE          ,  -- 급여기준항목값
                            DBO.F_FRM_CODE_NM(@av_company_cd, @v_locale_cd,  'PAY_ITEM_CD', C.PAY_DTM_CD, GETDATE(), '1') PAY_ITEM_VALUE_TEXT     ,  -- 급여기준항목값 설명
                            STA_YMD                 ,  -- 시작일자
                            END_YMD                 ,  -- 종료일자
                            'Y' LAST_YN                 ,  -- 최종데이타여부
                            @n_pay_ymd_id PAY_YMD_ID              ,  -- 급여일자ID(급여 의뢰 데이타만
                            0 MOD_USER_ID             ,  -- 변경자
                            SYSDATETIME() MOD_DATE                ,  -- 변경일시
                            'KST' TZ_CD                   ,  -- 타임존코드
							SYSDATETIME() TZ_DATE                 ,  -- 타임존일시
                            NULL BEL_ORG_ID              ,  -- 귀속부서id
						    NULL MAKE_PAY_YMD_ID         ,  --생성시급여일자ID(소급체크를 위해 넣음)
                            NULL RETRO_CHK_STA_YMD          --소급일자체크여부
					FROM DTM_MONTH A --JOIN PHM_EMP EMP ON (A.EMP_ID=EMP.EMP_ID AND EMP.COMPANY_CD = @av_company_cd)
					JOIN PAY_PAYROLL PAY
					  ON A.EMP_ID = PAY.EMP_ID
					 AND PAY.PAY_YMD_ID = @n_pay_ymd_id
					 AND PAY.SALARY_TYPE_CD = @v_salary_type_cd
					 AND PAY.PAY_GROUP_CD = @v_pay_group_cd
					INNER JOIN DTM_MONTH_DTL B
					        ON (B.DTM_MONTH_ID = A.DTM_MONTH_ID
							    AND @d_term_sta_ymd >= B.STA_YMD
								AND @d_term_end_ymd <= B.END_YMD) 
									INNER JOIN (SELECT 
													   A.KEY_CD1 AS PAY_GRPCD,
													   A.KEY_CD2 AS PAY_DTM_CD,
													   A.KEY_CD3 AS DTM_ITEM_CD
											  FROM FRM_UNIT_STD_HIS A,
												   FRM_UNIT_STD_MGR B
											 WHERE A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
											   AND B.LOCALE_CD  = @v_locale_cd
											   AND B.COMPANY_CD = @av_company_cd
											   AND B.UNIT_CD    = 'PAY'
											   AND B.STD_KIND   = 'PAY_DTM_MST_MAP'   
											   AND A.KEY_CD1	= @v_pay_group_cd
											   AND @d_pay_ymd BETWEEN A.STA_YMD AND A.END_YMD
											   ) C ON C.DTM_ITEM_CD = B.MONTH_ITEM_CD
					--WHERE A.WORK_YM BETWEEN FORMAT(@d_term_sta_ymd, 'yyyyMM') AND FORMAT(@d_term_end_ymd, 'yyyyMM')
					--WHERE WORK_YM = @v_pay_ym
					WHERE A.WORK_YM = FORMAT(@d_term_sta_ymd, 'yyyyMM')
					  AND A.CLOSE_YN='Y'
					--AND dbo.F_PAY_GROUP_CHK(@n_pay_group_id, A.EMP_ID, GETDATE()) = @n_pay_group_id
					--AND A.EMP_ID = @n_emp_id
					GROUP BY PAY.EMP_ID, B.STA_YMD, B.END_YMD, C.PAY_DTM_CD
				
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================
				set @n_ins_cnt = @@ROWCOUNT
				if @n_ins_cnt > 0 
					begin
						set @n_cnt_success = @n_cnt_success + @n_ins_cnt -- 성공건수
					end
				--else
				--	begin
				--		-- *** 로그에 실패 메시지 저장 ***
				--		set @v_keys = '@cd_company=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				--			  + ',@fr_month=' + ISNULL(CONVERT(nvarchar(100), @av_fr_month),'NULL')
				--			  + ',@to_month=' + ISNULL(CONVERT(nvarchar(100), @av_to_month),'NULL')
				--			  + ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @v_pay_type_cd),'NULL')
				--			  + ',@pay_group_cd=' + ISNULL(CONVERT(nvarchar(100), @v_pay_group_cd),'NULL')
				--			  + ',@salary_type_cd=' + ISNULL(CONVERT(nvarchar(100), @v_salary_type_cd),'NULL')
				--			  + ',@pay_term_type_cd=' + ISNULL(CONVERT(nvarchar(100), @v_pay_term_type_cd),'NULL')
				--			  + ',@term_sta_ymd=' + ISNULL(CONVERT(nvarchar(100), @d_term_sta_ymd),'NULL')
				--			  + ',@term_end_ymd=' + ISNULL(CONVERT(nvarchar(100), @d_term_end_ymd),'NULL')
				--		set @v_err_msg = '선택된 Record가 없습니다.!!!' -- ERROR_MESSAGE()
				--		EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
				--		-- *** 로그에 실패 메시지 저장 ***
				--		set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
				--	end
			END TRY
			BEGIN CATCH
				-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = '@cd_company=' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
							  + ',@fr_month=' + ISNULL(CONVERT(nvarchar(100), @av_fr_month),'NULL')
							  + ',@to_month=' + ISNULL(CONVERT(nvarchar(100), @av_to_month),'NULL')
							  + ',@pay_type_cd=' + ISNULL(CONVERT(nvarchar(100), @v_pay_type_cd),'NULL')
							  + ',@pay_group_cd=' + ISNULL(CONVERT(nvarchar(100), @v_pay_group_cd),'NULL')
							  + ',@salary_type_cd=' + ISNULL(CONVERT(nvarchar(100), @v_salary_type_cd),'NULL')
							  + ',@pay_term_type_cd=' + ISNULL(CONVERT(nvarchar(100), @v_pay_term_type_cd),'NULL')
							  + ',@term_sta_ymd=' + ISNULL(CONVERT(nvarchar(100), @d_term_sta_ymd),'NULL')
							  + ',@term_end_ymd=' + ISNULL(CONVERT(nvarchar(100), @d_term_end_ymd),'NULL')
						set @v_err_msg = CONVERT(NVARCHAR(100), ERROR_LINE()) + ':' + ERROR_MESSAGE()
						
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
				-- *** 로그에 실패 메시지 저장 ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
			END CATCH
		END
	EXEC [dbo].[P_CNV_PAY_LOG_H] @n_log_h_id, 'E', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table, @n_total_record, @n_cnt_success, @n_cnt_failure

	CLOSE CNV_CUR
	DEALLOCATE CNV_CUR
	PRINT @v_proc_nm + ' 완료!'
	PRINT 'CNT_PAY_WORK_ID = ' + CONVERT(varchar(100), @n_log_h_id)
	RETURN @n_log_h_id
END
GO

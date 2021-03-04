DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
	, @av_fr_month		NVARCHAR(6)		-- 시작년월
	, @av_to_month		NVARCHAR(6)		-- 종료년월
	, @av_fg_supp		NVARCHAR(2)		-- 급여구분
	, @av_dt_prov		NVARCHAR(08)	-- 급여지급일
	, @v_work_kind		nvarchar(10)    -- D:삭제만
DECLARE @results TABLE (
    log_id	numeric(38)
)
SET NOCOUNT ON;

set @an_try_no = 2 -- 시도회차( 같은 [번호 + 파라미터]의 로그를 삭제 )
-- TODO: 여기에서 매개 변수 값을 설정합니다.
-- E(엔터프라이즈):200801~
-- I(동원산업):
set @av_company_cd = 'A'
set @av_fr_month = '201912'
set @av_to_month = '201912'
--set @av_dt_prov = '20200125'
--set @v_work_kind = 'D' -- 삭제만 처리 Yes!

-- ==============================================
-- 급여실적이관(급여내역(대상자))
-- ==============================================
    -- 자료삭제
	DELETE FROM PAY_PAYROLL_DETAIL
	 WHERE BEL_PAY_YMD_ID in (select PAY_YMD_ID from PAY_PAY_YMD t
	                       where company_cd like ISNULL(@av_company_cd,'') + '%'
						     and t.PAY_YM between @av_fr_month and @av_to_month
	                     )
	-- 자료삭제
	DELETE FROM PAY_PAYROLL
	 WHERE PAY_YMD_ID in (select PAY_YMD_ID from PAY_PAY_YMD
	                       where company_cd like ISNULL(@av_company_cd,'') + '%'
						     and PAY_YM between @av_fr_month and @av_to_month
	                     )
	-- 급여일자삭제
	DELETE
		from PAY_PAY_YMD
	    where company_cd like ISNULL(@av_company_cd,'') + '%'
			and PAY_YM between @av_fr_month and @av_to_month
	-- 자료전환
	IF ISNULL(@v_work_kind, '') <> 'D'
		BEGIN
	EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PAYROLL
      @an_try_no		-- 시도회차
    , @av_company_cd	-- 회사코드
	, @av_fr_month		-- 시작년월
	, @av_to_month		-- 종료년월
	, @av_fg_supp		-- 급여구분
	, @av_dt_prov		-- 급여지급일
	INSERT INTO @results (log_id) VALUES (@n_log_h_id)
		END
-- ==============================================

-- ==============================================
-- 급여실적이관(급여계산상세내역) - 지급항목
-- ==============================================
	-- 자료삭제
	--DELETE FROM PAY_PAYROLL_DETAIL
	-- WHERE BEL_PAY_YMD_ID in (select PAY_YMD_ID from PAY_PAY_YMD t
	--                       where company_cd like ISNULL(@av_company_cd,'') + '%'
	--					     and t.PAY_YM between @av_fr_month and @av_to_month
	--                     )
	--   AND PAY_ITEM_CD LIKE 'P%'
	-- 자료전환
	IF ISNULL(@v_work_kind, '') <> 'D'
		BEGIN
			EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PAYROLL_DETAIL_SUPPLY
			  @an_try_no		-- 시도회차
			, @av_company_cd	-- 회사코드
			, @av_fr_month		-- 시작년월
			, @av_to_month		-- 종료년월
			, @av_fg_supp		-- 급여구분
			, @av_dt_prov		-- 급여지급일
			INSERT INTO @results (log_id) VALUES (@n_log_h_id)
		END
-- ==============================================

-- ==============================================
-- 급여실적이관(급여계산상세내역) - 공제항목
-- ==============================================
	---- 자료삭제
	--DELETE FROM PAY_PAYROLL_DETAIL
	-- WHERE BEL_PAY_YMD_ID in (select PAY_YMD_ID from PAY_PAY_YMD t
	--                       where company_cd like ISNULL(@av_company_cd,'') + '%'
	--					     and t.PAY_YM between @av_fr_month and @av_to_month
	--                     )
	--   AND PAY_ITEM_CD LIKE 'D%'
	---- 자료전환
	IF ISNULL(@v_work_kind, '') <> 'D'
		BEGIN
			EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PAYROLL_DETAIL_DEDUCT
			  @an_try_no		-- 시도회차
			, @av_company_cd	-- 회사코드
			, @av_fr_month		-- 시작년월
			, @av_to_month		-- 종료년월
			, @av_fg_supp		-- 급여구분
			, @av_dt_prov		-- 급여지급일
			INSERT INTO @results (log_id) VALUES (@n_log_h_id)
		END
-- ==============================================
-- DSUM , TSUM 재계산
UPDATE PAY
   SET DSUM = DTL.DAMT, TSUM = DTL.TAMT
  FROM PAY_PAYROLL PAY
  JOIN PAY_PAY_YMD YMD
    ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
  JOIN (SELECT PAY_PAYROLL_ID
             , ISNULL(SUM(CASE WHEN PAY_ITEM_TYPE_CD='DEDUCT' THEN CAL_MON ELSE 0 END),0) AS DAMT
             , ISNULL(SUM(CASE WHEN PAY_ITEM_TYPE_CD='TAX' THEN CAL_MON ELSE 0 END),0) AS TAMT
		 FROM PAY_PAYROLL_DETAIL  GROUP BY PAY_PAYROLL_ID) DTL
    ON PAY.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID
 WHERE YMD.COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
   AND YMD.PAY_YM BETWEEN @av_fr_month AND @av_to_month

-- ==============================================
-- 로그파일보기
-- ==============================================
SELECT *
  FROM CNV_PAY_WORK A
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)
SELECT *
  FROM CNV_PAY_WORK_LOG B
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)

GO

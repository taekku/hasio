USE [dwehrdev_H5]
GO

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
set @av_company_cd = 'E'
set @av_fr_month = '202010'
set @av_to_month = '202011'

-- ==============================================
-- 퇴직금이관
-- ==============================================
    -- 자료삭제
	DELETE FROM REP_CALC_LIST
	 WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
	   --AND dbo.XF_TO_CHAR_D(C1_END_YMD, 'yyyymm') between ISNULL(@av_fr_month,'') and ISNULL(@av_to_month,'999999')
	   AND FORMAT(C1_END_YMD, 'yyyyMM') BETWEEN ISNULL(@av_fr_month,'') AND ISNULL(@av_to_month,'999999')

	-- 자료전환
	EXECUTE @n_log_h_id = dbo.P_CNV_REP_CALC_LIST
      @an_try_no		-- 시도회차
    , @av_company_cd	-- 회사코드
	, @av_fr_month		-- 시작년월
	, @av_to_month		-- 종료년월
	INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

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

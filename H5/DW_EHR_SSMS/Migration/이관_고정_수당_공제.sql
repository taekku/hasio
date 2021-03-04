USE [dwehrdev_H5]
GO

DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
DECLARE @results TABLE (
    log_id	numeric(38)
)
SET NOCOUNT ON;

set @an_try_no = 2 -- 시도회차( 같은 [번호 + 파라미터]의 로그를 삭제 )
-- TODO: 여기에서 매개 변수 값을 설정합니다.
set @av_company_cd = 'E'

-- ==============================================
-- 고정수당
-- ==============================================
	-- 자료삭제
	DELETE FROM PAY_FIXED_PAY
	 WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	-- 자료전환
	EXECUTE @n_log_h_id = dbo.P_CNV_PAY_FIXED_PAY
			   @an_try_no
			  ,@av_company_cd
	INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 고정공제
-- ==============================================
	-- 자료삭제
	DELETE FROM PAY_FIXED_DEDUCTION
	 WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	-- 자료전환
	EXECUTE @n_log_h_id = dbo.P_CNV_PAY_FIXED_DEDUCTION
			   @an_try_no
			  ,@av_company_cd
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

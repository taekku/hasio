DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
DECLARE @av_fr_month nvarchar(10)
DECLARE @av_to_month nvarchar(10)
DECLARE @results TABLE (
    log_id	numeric(38)
)
DECLARE @bundle TABLE (
	FR_MONTH NVARCHAR(6),
	TO_MONTH NVARCHAR(6)
)
SET NOCOUNT ON;

set @an_try_no = 4 -- 시도회차( 같은 [번호 + 파라미터]의 로그를 삭제 )
-- TODO: 여기에서 매개 변수 값을 설정합니다.
set @av_company_cd = 'H'
insert into @bundle(FR_MONTH, TO_MONTH) values ('202006','202007') -- 

DECLARE CNV_PAY_CUR CURSOR READ_ONLY FOR
SELECT FR_MONTH, TO_MONTH
  FROM @bundle
;
OPEN CNV_PAY_CUR
WHILE 1=1
	BEGIN
		FETCH NEXT FROM CNV_PAY_CUR
			      INTO @av_fr_month, @av_to_month
		IF @@FETCH_STATUS <> 0 BREAK
		BEGIN TRY
			-- ==============================================
			-- 근태집계 PAY_MST_CHANGE
			-- ==============================================
				-- 자료전환
				EXECUTE @n_log_h_id = dbo.P_CNV_PAY_MST_CHANGE_for_DTM
						   @an_try_no
							, @av_company_cd	-- 회사코드
							, @av_fr_month		-- 시작년월
							, @av_to_month		-- 종료년월
			  
				INSERT INTO @results (log_id) VALUES (@n_log_h_id)
			-- ==============================================
		END TRY
		BEGIN CATCH
			PRINT ERROR_NUMBER()
			PRINT ERROR_MESSAGE()
		END CATCH
	END
CLOSE CNV_PAY_CUR
DEALLOCATE CNV_PAY_CUR

-- ==============================================
-- 로그파일보기
-- ==============================================
SELECT *
  FROM CNV_PAY_WORK A
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)
SELECT CNV_PAY_WORK_ID, KEYS, ERR_MSG, LOG_DATE
  FROM CNV_PAY_WORK_LOG B
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)
GO

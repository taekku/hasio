
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
-- 회계계정코드관리
-- ==============================================
	---- 자료삭제
	--DELETE FROM PAY_ACNT_CD
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_ACNT_CD
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 급상여계정분류
-- ==============================================
	---- 중복을 위한 자료수집
	--DELETE FROM PAY_ACNT_MNG_DUP
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료삭제
	--DELETE FROM PAY_ACNT_MNG
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_ACNT_MNG
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 퇴직금계정분류
-- ==============================================
	---- 자료삭제
	--DELETE FROM REP_ACNT_MNG
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_REP_ACNT_MNG
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 급여마스터
-- ==============================================
	-- 자료삭제
	--DELETE FROM PAY_PHM_EMP
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	--Print '삭제(PAY_PHM_EMP):'+convert(varchar(100), @@RowCount)
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PHM_EMP
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
	---- CNS (HRD)인 경우
	--IF @av_company_cd = 'M' OR @av_company_cd = ''
	--	BEGIN
	--		EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PHM_EMP_HRD
	--				   @an_try_no
	--				  ,'M' --@av_company_cd
	--		INSERT INTO @results (log_id) VALUES (@n_log_h_id)
	--	END
-- ==============================================

-- ==============================================
-- 급여가족수당
-- ==============================================
	-- 자료삭제
	DELETE FROM PAY_PHM_FAMILY
	 WHERE EMP_ID in (select EMP_ID from PHM_EMP_NO_HIS where company_cd like ISNULL(@av_company_cd,'') + '%' )
	-- 자료전환
	EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PHM_FAMILY
			   @an_try_no
			  ,@av_company_cd
	INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 급여계좌
-- ==============================================
	---- 자료삭제
	--DELETE FROM PAY_ACCOUNT
	-- WHERE EMP_ID in (select EMP_ID from PHM_EMP_NO_HIS where company_cd like ISNULL(@av_company_cd,'') + '%' )
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_ACCOUNT
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 개인별원천징수세율
-- ==============================================
	---- 자료삭제
	--DELETE FROM PAY_EXP_TAX
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%' 
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_EXP_TAX
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 호봉
-- ==============================================
	---- 자료삭제
	--DELETE FROM PAY_HOBONG
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_HOBONG
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 호봉
-- ==============================================
	---- 자료삭제
	--DELETE FROM PAY_HOBONG_U
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_HOBONG_U
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 선원평균통상임금기준율관리
-- ==============================================
	-- 자료삭제
	--DELETE FROM PAY_SHIP_RATE
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_SHIP_RATE
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 선원가불금기준관리
-- ==============================================
	---- 자료삭제
	--DELETE FROM PAY_SHIP_ADV
	-- WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_SHIP_ADV
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 출어가불금관리
-- ==============================================
	---- 자료삭제
	--DELETE FROM PAY_ADV
	-- --WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_ADV
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 출어가불금공제관리
-- ==============================================
	---- 자료삭제
	--DELETE FROM PAY_SHIP_ADV_DTL
	-- --WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_SHIP_ADV_DTL
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 선원대기비관리
-- ==============================================
	---- 자료삭제
	--DELETE FROM PAY_STANDBY
	-- --WHERE company_cd like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_STANDBY
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 국민연금/건강보험
-- ==============================================
	---- 자료삭제
	---- 국민연금
	--DELETE FROM STP_JOIN_INFO
	-- WHERE EMP_ID IN (SELECT EMP_ID FROM PHM_EMP WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%')
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_H_MED_INSUR
	--		   @an_try_no
	--		  ,@av_company_cd
	--		  ,'1'
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 국민연금/건강보험
-- ==============================================
	---- 건강보험
	--DELETE FROM NHS_JOIN_INFO
	-- WHERE EMP_ID IN (SELECT EMP_ID FROM PHM_EMP WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%')
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_H_MED_INSUR
	--		   @an_try_no
	--		  ,@av_company_cd
	--		  ,'2'
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- COST센터 ( 완성되지 않음. 향후 수정? )
-- ==============================================
	---- COST센터
	--DELETE FROM ORM_COST
	-- WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_ORM_COST
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
-- ==============================================

-- ==============================================
-- 개인별COST센터 ( 완성되지 않음. 향후 수정? )
-- ==============================================
	---- 개인별COST센터
	--DELETE FROM ORM_EMP_COST
	-- WHERE EMP_ID IN (SELECT EMP_ID FROM PHM_EMP_NO_HIS WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%')
	---- 자료전환
	--EXECUTE @n_log_h_id = dbo.P_CNV_ORM_EMP_COST
	--		   @an_try_no
	--		  ,@av_company_cd
	--INSERT INTO @results (log_id) VALUES (@n_log_h_id)
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

--SELECT A.CNV_PAY_WORK_ID, A.PROGRAM_NM, A.TITLE, A.PARAMS, CNT_TRY, CNT_OK, CNT_FAIL, ERR_MSG, KEYS
--  FROM CNV_PAY_WORK A WITH(NOLOCK)
--  JOIN CNV_PAY_WORK_LOG B WITH(NOLOCK)
--    ON A.CNV_PAY_WORK_ID = B.CNV_PAY_WORK_ID
-- WHERE A.PROGRAM_NM = 'P_CNV_PAY_ACNT_MNG'
--   AND A.CNV_PAY_WORK_ID = MAX(A.CNV_PAY_WORK_ID)
-- ORDER BY B.CNV_PAY_WORK_LOG_ID
GO

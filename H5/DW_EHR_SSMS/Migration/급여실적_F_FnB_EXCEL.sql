
DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
	, @av_fr_month		NVARCHAR(6)		-- 시작년월
	, @av_to_month		NVARCHAR(6)		-- 종료년월
	, @av_fg_supp		NVARCHAR(2)		-- 급여구분
	, @av_dt_prov		NVARCHAR(08)	-- 급여지급일
	, @v_work_kind		nvarchar(10)    -- D@삭제만
DECLARE @results TABLE (
    log_id	numeric(38)
)
DECLARE @bundle TABLE (
	FR_MONTH NVARCHAR(6),
	TO_MONTH NVARCHAR(6)
)
SET NOCOUNT ON;

set @an_try_no = 4 -- 시도회차( 같은 [번호 + 파라미터]의 로그를 삭제 )
-- TODO@ 여기에서 매개 변수 값을 설정합니다.
-- F(FnB)@201501 ~
set @av_company_cd = 'F'
insert into @bundle(FR_MONTH, TO_MONTH) values ('201601','201603')
insert into @bundle(FR_MONTH, TO_MONTH) values ('201604','201606')
insert into @bundle(FR_MONTH, TO_MONTH) values ('201607','201609')
insert into @bundle(FR_MONTH, TO_MONTH) values ('201610','201612')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201701','201703')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201704','201706')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201707','201709')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201710','201712')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201801','201803')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201804','201806')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201807','201809')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201810','201812')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201901','201903')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201904','201906')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201907','201909')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201910','201912')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('202001','202003')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('202004','202006')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('202007','202009')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('202010','202012')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('202101','202102')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('202103','202104')


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
	
		--set @av_dt_prov = '20200125'
		--set @v_work_kind = 'D' -- 삭제만 처리 Yes!
		-- ==============================================
		-- 급여실적이관(급여내역(대상자))
		-- ==============================================
			-- 자료삭제
			DELETE FROM PAY_PAYROLL_DETAIL
			 WHERE BEL_PAY_YMD_ID in (select PAY_YMD_ID 
										from PAY_PAY_YMD YMD
										JOIN FRM_CODE B
										  ON YMD.COMPANY_CD = B.COMPANY_CD
										 AND B.CD_KIND = 'PAY_TYPE_CD'
										 AND YMD.PAY_TYPE_CD = B.CD
										 AND ISNULL(B.SYS_CD, '') != '001'
										 AND YMD.COMPANY_CD = @av_company_cd
										 AND B.COMPANY_CD = @av_company_cd
										where YMD.COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
											and PAY_YM between @av_fr_month and @av_to_month
								 )
			-- 자료삭제
			DELETE FROM PAY_PAYROLL
			 WHERE PAY_YMD_ID in (select PAY_YMD_ID 
										from PAY_PAY_YMD YMD
										JOIN FRM_CODE B
										  ON YMD.COMPANY_CD = B.COMPANY_CD
										 AND B.CD_KIND = 'PAY_TYPE_CD'
										 AND YMD.PAY_TYPE_CD = B.CD
										 AND ISNULL(B.SYS_CD, '') != '001'
										 AND YMD.COMPANY_CD = @av_company_cd
										 AND B.COMPANY_CD = @av_company_cd
										where YMD.COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
											and PAY_YM between @av_fr_month and @av_to_month
								 )
			-- 급여일자삭제
			DELETE YMD
										from PAY_PAY_YMD YMD
										JOIN FRM_CODE B
										  ON YMD.COMPANY_CD = B.COMPANY_CD
										 AND B.CD_KIND = 'PAY_TYPE_CD'
										 AND YMD.PAY_TYPE_CD = B.CD
										 AND ISNULL(B.SYS_CD, '') != '001'
										 AND YMD.COMPANY_CD = @av_company_cd
										 AND B.COMPANY_CD = @av_company_cd
										where YMD.COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
											and PAY_YM between @av_fr_month and @av_to_month
											--AND YMD.NOTE = 'FnB(SAP)'
			-- 자료전환
			IF ISNULL(@v_work_kind, '') <> 'D'
				BEGIN
			--EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PAYROLL_NEW
			EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PAYROLL_FnB @an_try_no = @an_try_no
								, @av_company_cd = @av_company_cd
								, @av_fr_month = @av_fr_month
								, @av_to_month = @av_to_month
								, @av_cd_paygp = NULL
								, @av_sap_kind1 = NULL
								, @av_sap_kind2 = NULL
								, @av_dt_prov = NULL


			INSERT INTO @results (log_id) VALUES (@n_log_h_id)
				END
		-- ==============================================
		-- DSUM , TSUM 재계산
		-- ==============================================
		--UPDATE PAY
		--   SET DSUM = DTL.DAMT, TSUM = DTL.TAMT
		--  FROM PAY_PAYROLL PAY
		--  JOIN PAY_PAY_YMD YMD
		--	ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
		--  JOIN (SELECT PAY_PAYROLL_ID
		--			 , ISNULL(SUM(CASE WHEN PAY_ITEM_TYPE_CD='DEDUCT' THEN CAL_MON ELSE 0 END),0) AS DAMT
		--			 , ISNULL(SUM(CASE WHEN PAY_ITEM_TYPE_CD='TAX' THEN CAL_MON ELSE 0 END),0) AS TAMT
		--		 FROM PAY_PAYROLL_DETAIL  GROUP BY PAY_PAYROLL_ID) DTL
		--	ON PAY.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID
		-- WHERE YMD.COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
		--   AND YMD.PAY_YM BETWEEN @av_fr_month AND @av_to_month
		--   AND PAY.NOTE='FnB(SAP)'
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
SELECT CNV_PAY_WORK_ID, KEYS, ERR_MSG--, LOG_DATE
  FROM CNV_PAY_WORK_LOG B
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)

GO

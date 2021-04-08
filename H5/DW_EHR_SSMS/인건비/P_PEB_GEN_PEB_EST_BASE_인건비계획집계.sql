SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_GEN_PEB_EST_BASE]
		@av_company_cd      NVARCHAR(10),
		@av_locale_cd       NVARCHAR(10),
		@an_peb_base_id		NUMERIC(38,0),
		@av_fr_pay_ym		nvarchar(06),
		@av_to_pay_ym		nvarchar(06),
    @av_tz_cd           NVARCHAR(10),    -- 타임존코드
    @an_mod_user_id     NUMERIC(18,0)  ,    -- 변경자 ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 인건비계획 인건비집계
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_PEB_GEN_PEB_EST_BASE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획에서 인건비집계
    --<DOCLINE>   HISTORY     : 작성 임택구 2021.01.07
    --<DOCLINE> ***************************************************************************
BEGIN
	DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)

	  , @v_base_yyyy	nvarchar(10)
	  , @v_plan_cd		nvarchar(10) = '10'
	  , @v_type_nm		nvarchar(50) = '인건비'

	SET @v_program_id   = 'P_PEB_GEN_PEB_EST_BASE'
	SET @v_program_nm   = '인건비계획 계획집계'
	SET @av_ret_code    = 'SUCCESS!'
	SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
										@v_program_id,  0000,  NULL, NULL);
	BEGIN TRY
		 SELECT @v_base_yyyy = BASE_YYYY
		   FROM PEB_BASE
		  WHERE PEB_BASE_ID = @an_peb_base_id
		    AND COMPANY_CD = @av_company_cd
		IF @@ROWCOUNT < 1
		BEGIN
			SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비실적 집계중(계획) - 인건비계획을 읽어올 수 없습니다.[ERR]',
									@v_program_id,  0100,  null, null
								)
			SET @av_ret_code    = 'FAILURE!'
			RETURN
		END
  -- 기존자료 삭제
		DELETE
		  FROM A
		  FROM PEB_EST_PAY A
		  WHERE A.BASE_YM LIKE @v_base_yyyy + '%'
		  AND COMPANY_CD = @av_company_cd
		  AND PLAN_CD = @v_plan_cd
		  AND TYPE_NM = @v_type_nm
		  AND A.BASE_YM BETWEEN @av_fr_pay_ym AND @av_to_pay_ym
		INSERT INTO PEB_EST_PAY(
			PEB_EST_PAY_ID,--	인건비통계ID
			COMPANY_CD,--	회사코드
			BASE_YM,--	기준년월
			PLAN_CD,--	인건비계획실적[PEB_PLAN_CD]
			ORG_ID,--	부서ID
			TYPE_NM,--	통계구분
			VIEW_CD,--	표시코드
			PHM_CNT,--	월말인원
			PAY_CNT,--	월평균인원(급여지급)
			PAY_AMT,--	임금
			PAY_ETC_AMT,--	기타금품
			MOD_USER_ID,--	변경자
			MOD_DATE,--	변경일
			TZ_CD,--	타임존코드
			TZ_DATE --	타임존일시
		)
		SELECT NEXT VALUE FOR S_PEB_SEQUENCE
			 , COMPANY_CD, BASE_YM, PLAN_CD, ORG_ID, TYPE_NM, VIEW_CD
			 , COUNT(DISTINCT PEB_PHM_MST_ID) AS PHM_CNT
			 , COUNT(DISTINCT PEB_PHM_MST_ID) AS PAY_CNT
			 , SUM(PAY_AMT) AS PAY_AMT
			 , SUM(PAY_ETC_AMT) AS PAY_ETC_AMT
			 , @an_mod_user_id --MOD_USER_ID,--	변경자
			 , SYSDATETIME() -- MOD_DATE,--	변경일
			 , @av_tz_cd -- TZ_CD,--	타임존코드
			 , SYSDATETIME() --TZ_DATE --	타임존일시
		  FROM (
				SELECT @av_company_cd AS COMPANY_CD
					 , PEB_YM BASE_YM
					 , @v_plan_cd AS PLAN_CD -- 10:계획/20:실적
					 , MST.PAY_ORG_ID AS ORG_ID
					 , @v_type_nm AS TYPE_NM
					 , dbo.F_PEB_GET_VIEW_CD(@v_type_nm, PAY.POS_GRD_CD, PAY.POS_CD, PAY.DUTY_CD, PAY.JOB_POSITION_CD
								, MST.MGR_TYPE_CD, MST.JOB_CD, MST.EMP_KIND_CD) AS VIEW_CD
					 , MST.PEB_PHM_MST_ID
					, CASE when PEB.PAY_ITEM_CD IS NULL AND ITEM.CD1 = 'PAY_PAY' THEN DTL.CAM_AMT
							ELSE 0 END AS PAY_AMT
					, CASE when PEB.PAY_ITEM_CD IS NULL THEN 0
							ELSE DTL.CAM_AMT END AS PAY_ETC_AMT
					, DTL.PAY_ITEM_CD
				  FROM PEB_PHM_MST MST
				  JOIN PEB_PAYROLL PAY
					ON MST.PEB_PHM_MST_ID = PAY.PEB_PHM_MST_ID
		  INNER JOIN (select KEY_CD1 ITEM_CD, CD1, HIS.STA_YMD, HIS.END_YMD
						  FROM FRM_UNIT_STD_HIS HIS
								   , FRM_UNIT_STD_MGR MGR
						 WHERE HIS.FRM_UNIT_STD_MGR_ID = MGR.FRM_UNIT_STD_MGR_ID
						   AND MGR.UNIT_CD = 'PAY'
						   AND MGR.STD_KIND = 'PAY_ITEM_CD_BASE'
							  AND MGR.COMPANY_CD = @av_company_cd
						   AND MGR.LOCALE_CD = 'KO'
						   AND CD1 IN ('PAY_PAY', 'PAY_G', 'PAY_GN')) ITEM
					ON dbo.XF_LAST_DAY(PAY.PEB_YM + '01') BETWEEN ITEM.STA_YMD AND ITEM.END_YMD
				  JOIN PEB_PAYROLL_DETAIL DTL
					ON PAY.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
				   AND ITEM.ITEM_CD = DTL.PAY_ITEM_CD
				  LEFT OUTER JOIN PEB_EST_ITEM PEB
							ON DTL.PAY_ITEM_CD = PEB.PAY_ITEM_CD
							AND dbo.XF_LAST_DAY(PAY.PEB_YM + '01')  BETWEEN PEB.STA_YMD AND PEB.END_YMD
							AND PEB.COMPANY_CD = @av_company_cd
				 WHERE MST.PEB_BASE_ID = @an_peb_base_id
				 AND PAY.PEB_YM BETWEEN @av_fr_pay_ym AND @av_to_pay_ym
				 AND CAM_AMT <> 0
				 AND DTL.PAY_ITEM_CD LIKE 'P%'
				 ) A
		 GROUP BY COMPANY_CD, BASE_YM, PLAN_CD, ORG_ID, TYPE_NM, VIEW_CD
		 IF @@ROWCOUNT < 1
		 BEGIN
			SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비계획에 계산된 급여내역이 없습니다.[ERR]',
									@v_program_id,  0110,  null, null
								)
			SET @av_ret_code    = 'FAILURE!'
			RETURN
		 END
	END TRY
	BEGIN CATCH
		SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비실적 집계중(계획) 에러[ERR]' + ISNULL(ERROR_MESSAGE(), ''),
								@v_program_id,  0150,  null, null
							)
		SET @av_ret_code    = 'FAILURE!'
		RETURN
	END CATCH
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END
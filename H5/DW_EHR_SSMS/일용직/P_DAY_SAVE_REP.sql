SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_DAY_SAVE_REP]
		@an_rep_calc_list_id	NUMERIC(38),
		@an_day_emp_mst_id		NUMERIC(38),
		@av_payroll_ids			NVARCHAR(max),
		@av_locale_cd			NVARCHAR(10),
		@av_tz_cd				NVARCHAR(10),    -- 타임존코드
		@an_mod_user_id			NUMERIC(18,0)  ,    -- 변경자 ID
		@av_ret_code			NVARCHAR(100)    OUTPUT,
		@av_ret_message			NVARCHAR(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 일용직 급여지급내역 저장
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_DAY_SAVE_REP
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 일용직 급여지급내역 저장
    --<DOCLINE>   HISTORY     : 작성 2020.10.29
    --<DOCLINE> ***************************************************************************
BEGIN
	SET NOCOUNT ON;
	DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id		NVARCHAR(30)
      , @v_program_nm		NVARCHAR(100)
      , @v_ret_code			NVARCHAR(100)
      , @v_ret_message		NVARCHAR(500)
	  , @REP_PAY_STD_ID		NUMERIC(38)
	
    SET @v_program_id   = 'P_DAY_SAVE_REP'
    SET @v_program_nm   = '일용직 급여지급내역 저장'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);

    -- 기존자료 삭제
	DELETE A
	  FROM REP_PAYROLL_DETAIL A
	 WHERE REP_PAY_STD_ID IN (SELECT REP_PAY_STD_ID
	                            FROM REP_PAY_STD
							   WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id)
	DELETE A
	  FROM REP_PAY_STD A
	 WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id
	
	-- =============================================
	--   As-Is Key Column Select
	--   Source Table Key
	-- =============================================
	SELECT Items as DAY_PAY_PAYROLL_ID
	  INTO #SAVE
	  FROM dbo.fn_split_array(@av_payroll_ids,',') A

	DECLARE @revert_ym		nvarchar(6)
		  , @sta_ymd		date
		  , @end_ymd		date
		  , @rd_appl_s		numeric(5,0)
		  , @pay_total		numeric(18,0)
    DECLARE PAY_CUR CURSOR READ_ONLY FOR
		SELECT YMD.REVERT_YM, YMD.STA_YMD, YMD.END_YMD,
				SUM(PAY.RD_APPL_S) AS RD_APPL_S,	-- 근무적용일수
				SUM(PAY.PAY_TOTAL) AS PAY_TOTAL		-- 지급합계
		  FROM #SAVE A
		  INNER JOIN DAY_PAY_PAYROLL PAY
		          ON A.DAY_PAY_PAYROLL_ID = PAY.DAY_PAY_PAYROLL_ID
				  INNER JOIN DAY_PHM_EMP EMP
						  ON PAY.EMP_ID = EMP.EMP_ID
				  INNER JOIN DAY_EMP_MST MST
						  ON EMP.DAY_EMP_MST_ID = MST.DAY_EMP_MST_ID
				  INNER JOIN DAY_PAY_YMD YMD
						  ON PAY.DAY_PAY_YMD_ID = YMD.DAY_PAY_YMD_ID
						 AND YMD.CLOSE_YN = 'Y'
		GROUP BY YMD.REVERT_YM, YMD.STA_YMD, YMD.END_YMD
	OPEN PAY_CUR

	WHILE 1 = 1
	BEGIN
		BEGIN TRY
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			FETCH NEXT FROM PAY_CUR
			      INTO @revert_ym, @sta_ymd, @end_ymd, @rd_appl_s, @pay_total
			IF @@FETCH_STATUS <> 0 BREAK
			SET @REP_PAY_STD_ID = NEXT VALUE FOR S_REP_SEQUENCE
				INSERT INTO REP_PAY_STD(
						REP_PAY_STD_ID, --	퇴직금기준 임금 관리ID
						REP_CALC_LIST_ID, --	퇴직금대상ID
						PAY_TYPE_CD, --	급여지급구분[PAY_TYPE_CD]
						PAY_YM, --	급여일자
						SEQ, --	순서
						STA_YMD, --	시작일자
						END_YMD, --	종료일자
						BASE_DAY, --	기준일수
						MINUS_DAY, --	차감일수
						REAL_DAY, --	대상일수
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일시
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				)
				SELECT @REP_PAY_STD_ID AS REP_PAY_STD_ID, --	퇴직금기준 임금 관리ID
						@an_rep_calc_list_id	REP_CALC_LIST_ID, --	퇴직금대상ID
						'10'	PAY_TYPE_CD, --	급여지급구분[REP_PAY_TYPE_CD] 10:급여, 20:상여, 30:연차
						@revert_ym	PAY_YM, --	급여일자
						--ROW_NUMBER() OVER(ORDER BY (SELECT 1))	SEQ, --	순서
						1	SEQ, -- 순서
						@sta_ymd	STA_YMD, --	시작일자
						@end_ymd	END_YMD, --	종료일자
						@rd_appl_s	BASE_DAY, --	기준일수
						0	MINUS_DAY, --	차감일수
						dbo.XF_TO_CHAR_D(@end_ymd, 'DD')	REAL_DAY, --	대상일수
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일시
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시

				INSERT INTO REP_PAYROLL_DETAIL(
						REP_PAYROLL_DETAIL_ID, --	퇴직금기준임금항목관리ID
						REP_PAY_STD_ID, --	퇴직금기준 임금 관리ID
						PAY_ITEM_CD, --	급여항목코드[PAY_ITEM_CD]
						CAL_MON, --	금액
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일시
						TZ_CD, --	타임존코드
						TZ_DATE  --	타임존일시
				)
				SELECT  NEXT VALUE FOR S_REP_SEQUENCE AS REP_PAYROLL_DETAIL_ID, --	퇴직금기준임금항목관리ID
						@REP_PAY_STD_ID	AS REP_PAY_STD_ID, --	퇴직금기준 임금 관리ID
						'P001'	AS PAY_ITEM_CD, --	급여항목코드[PAY_ITEM_CD] 기본급
						@pay_total	CAL_MON, --	금액
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일시
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
		END TRY
		BEGIN Catch
					SET @av_ret_message = dbo.F_FRM_ERRMSG( '일용직 급여지급내역 저장 에러[ERR]' + ERROR_MESSAGE(),
											@v_program_id,  0150,  null, null
										)
					SET @av_ret_code    = 'FAILURE!'
					RETURN
		END CATCH
	END
	CLOSE PAY_CUR
	DEALLOCATE PAY_CUR
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END

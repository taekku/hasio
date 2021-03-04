SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_DTM_MNG_CREATE]
		@an_peb_base_id			NUMERIC,
		@av_company_cd      NVARCHAR(10),
		@ad_base_ymd				DATE,
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- 타임존코드
    @an_mod_user_id     NUMERIC(18,0)  ,    -- 변경자 ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 인건비계획 연차자료 생성
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_PEB_DTM_MNG_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획 연차자료 생성
    --<DOCLINE>   HISTORY     : 작성 임택구 2020.09.08
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @PEB_PHM_MST_ID		NUMERIC
	  , @v_base_yyyy		NVARCHAR(04) -- 기준년도
	  , @d_peb_sta_ymd		DATE
	  , @d_peb_end_ymd		DATE
	  , @d_std_ymd			DATE
	  , @v_company_cd		NVARCHAR(10)
	  , @v_pay_group		NVARCHAR(50) -- 급여그룹
	  , @n_year_gen_cnt		NUMERIC --	1년미만발생
	  , @n_gen_cnt			NUMERIC --	발생연차
	  , @n_wk_gen_cnt		NUMERIC --	근속발생연차
	  , @n_use_cnt			NUMERIC --	사용일수
	  , @n_un_use_cnt		NUMERIC --	미사용일수

    SET @v_program_id   = 'P_PEB_DTM_MNG_CREATE'
    SET @v_program_nm   = '인건비계획 연차자료 생성'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
  -- 기존자료 삭제
	DELETE FROM PEB_DTM_MNG
		FROM PEB_DTM_MNG A
		JOIN PEB_PHM_MST MST
		  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id

	SELECT @d_peb_sta_ymd = STA_YMD
	     , @d_peb_end_ymd = END_YMD
		 , @d_std_ymd     = STD_YMD
		 , @v_company_cd  = COMPANY_CD
		 , @v_base_yyyy   = BASE_YYYY
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id

	/** 인건비계획 대상명단 **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID
			FROM PEB_PHM_MST MST
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id

	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID
    --<DOCLINE> ********************************************************
    --<DOCLINE> 인건비 연차생성 생성
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				SELECT @v_pay_group = dbo.F_PEB_GET_PAY_GROUP(@PEB_PHM_MST_ID)
				SELECT @n_year_gen_cnt = case when dbo.XF_TO_CHAR_D(dbo.XF_ADD_MONTH( A.ANNUAL_CAL_YMD, 12), 'yyyy') >= @v_base_yyyy THEN
											dbo.F_DTM_YY_NUM_FAKE(@v_company_cd, @av_locale_cd, A.ANNUAL_CAL_YMD,
												dbo.XF_TO_CHAR_D( dbo.XF_ADD_MONTH(A.ANNUAL_CAL_YMD, 11), 'yyyymm')
											)
											else 0 end
					 , @n_gen_cnt = dbo.F_DTM_YY_NUM_PURE(@v_company_cd, @av_locale_cd, A.ANNUAL_CAL_YMD, @v_base_yyyy)
					 , @n_wk_gen_cnt = 0
					 , @n_use_cnt = ISNULL( dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@v_company_cd, @av_locale_cd, 'PEB', 'PEB_DTM_USE',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, NULL, NULL, NULL, NULL,
									@d_peb_sta_ymd, 'H1' -- 'H1' : 코드1,  'E1' : 기타코드1
									) ), 0)
				  FROM PEB_PHM_MST A
				 WHERE PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				IF @n_gen_cnt > 0
					set @n_year_gen_cnt = 0
				set @n_use_cnt = case
								 when @n_use_cnt > (@n_year_gen_cnt + @n_gen_cnt + @n_wk_gen_cnt) then
										(@n_year_gen_cnt + @n_gen_cnt + @n_wk_gen_cnt)
								 else @n_use_cnt end
				set @n_un_use_cnt = (@n_year_gen_cnt + @n_gen_cnt + @n_wk_gen_cnt) - @n_use_cnt
				INSERT INTO PEB_DTM_MNG(
						PEB_DTM_MNG_ID, --	인건비연차ID
						PEB_PHM_MST_ID, --	인건비계획대상자ID
						YEAR_GEN_CNT, --	1년미만발생
						GEN_CNT, --	발생연차
						WK_GEN_CNT, --	근속발생연차
						USE_CNT, --	사용일수
						UN_USE_CNT, --	미사용일수
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
						A.PEB_PHM_MST_ID, --	인건비계획대상자ID
						@n_year_gen_cnt YEAR_GEN_CNT, --	1년미만발생
						@n_gen_cnt GEN_CNT, --	발생연차
						@n_wk_gen_cnt WK_GEN_CNT, --	근속발생연차
						@n_use_cnt USE_CNT, --	사용일수
						@n_un_use_cnt UN_USE_CNT, --	미사용일수
						NULL	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
				  FROM PEB_PHM_MST A
				 WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 인상율 INSERT 에러[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END

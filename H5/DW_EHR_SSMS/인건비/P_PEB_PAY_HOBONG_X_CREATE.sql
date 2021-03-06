SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[P_PEB_PAY_HOBONG_X_CREATE]
    @av_company_cd      NVARCHAR(10),       -- 인사영역
    @av_locale_cd       NVARCHAR(10),       -- 지역코드
    @an_peb_base_id     NUMERIC,            -- 인건비기준id
    @an_mod_user_id     NUMERIC,            -- 변경자
    @av_ret_code        NVARCHAR(100) OUTPUT,
    @av_ret_message     NVARCHAR(500) OUTPUT
AS
    -- ***************************************************************************
    --   TITLE       : 인건비 호봉표 생성(로엑스)
    ---  PROJECT     : 신인사정보시스템
    --   AUTHOR      : 
    --   PROGRAM_ID  : P_PEB_PAY_HOBONG_X_CREATE
    --   ARGUMENT    :
    --   RETURN      :
    --   HISTORY     :
    -- ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id       NVARCHAR(30)
      , @v_program_nm       NVARCHAR(100)
      , @v_ret_code         NVARCHAR(100)
      , @v_ret_message      NVARCHAR(500)
	  
      -- 인건비계획 기준정보
      , @v_base_yyyy        NVARCHAR(4)    -- 기준년도
      , @d_std_ymd          DATE           -- 기준일
      , @d_std_sta_ymd      DATE           -- 인건비계획시작일
      , @d_std_end_ymd      DATE           -- 인건비계획종료일
	  
      -- 인건비계획 인상율정보
      , @n_up_rate          NUMERIC(8,4)   -- 인상율
      , @v_peb_ym           NVARCHAR(2)    -- 반영월

      , @d_sta_ymd          DATE           -- 시작일
      , @d_end_ymd          DATE           -- 종료일
	  

    /*기본변수 초기값 세팅*/
    SET @v_program_id   = 'P_PEB_PAY_HOBONG_X_CREATE'
    SET @v_program_nm   = '인건비 호봉표 생성(로엑스)'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('프로시저 실행 시작..[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
	
--=======================================================================
-- 호봉인상율 정보조회
--=======================================================================
    BEGIN
        SELECT @v_base_yyyy   = A.BASE_YYYY
             , @d_std_ymd     = A.STD_YMD
             , @d_std_sta_ymd = A.STA_YMD
             , @d_std_end_ymd = A.END_YMD
             , @n_up_rate     = (ISNULL(B.PEB_RATE, 0) / 100.0) + 1
             , @v_peb_ym      = B.PEB_YM
          FROM PEB_BASE A
               LEFT OUTER JOIN PEB_RATE B
                       ON A.PEB_BASE_ID = B.PEB_BASE_ID
                      AND B.PEB_TYPE_CD = '123' -- 110:연봉인상율, 120:호봉인상율, 121:선원, 122:울산, 123:로엑스
         WHERE A.PEB_BASE_ID = @an_peb_base_id

		IF @@ROWCOUNT < 1
            BEGIN
                SET @v_peb_ym = NULL
            END

        IF @@ERROR <> 0
            BEGIN
                SET @av_ret_code = 'FAILUERE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('호봉인상율 정보 조회 중 에러발생[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
                RETURN
            END

        -- 인건비 반영월은 1월~12월에서 선택, '매월'로 지정할 수 없음(인건비항목지급월[PEB_MONTH_CD])
        IF @v_peb_ym = '00'
			
            BEGIN
                SET @av_ret_code = 'FAILUERE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('인건비 반영월로 [매월]을 지정할 수 없습니다.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
                RETURN
            END

    END


--===========================================================
-- 기존자료삭제
--===========================================================
    BEGIN TRY
        DELETE FROM PEB_PAY_HOBONG_X
         WHERE PEB_BASE_ID = @an_peb_base_id
    END TRY
    BEGIN CATCH
        SET @av_ret_code = 'FAILURE!'
        SET @av_ret_message = DBO.F_FRM_ERRMSG('인건비 호봉자료 삭제 중 에러발생[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
        IF @@TRANCOUNT > 0
            ROLLBACK
        RETURN
    END CATCH

--===========================================================
-- 시작/종료일 세팅
--===========================================================
    -- 인건비 인상 정보가 없을 경우
    IF @v_peb_ym IS NULL OR ISNULL(@n_up_rate, 1) = 1
        BEGIN
            SET @d_sta_ymd = NULL
            SET @d_end_ymd = @d_std_end_ymd
        END

    -- 인건비 인상 정보가 있을 경우
    ELSE
        BEGIN
            SET @d_sta_ymd = CONVERT(DATE, @v_base_yyyy + @v_peb_ym + '01')
            SET @d_end_ymd = DATEADD(DD, -1, @d_sta_ymd)
        END


--===========================================================
-- 호봉정보 복사(급여관리 > 기준관리 > 급호테이블관리)
--===========================================================
    BEGIN TRY
        INSERT INTO PEB_PAY_HOBONG_X ( PEB_PAY_HOBONG_ID        -- 인건비계획호봉ID
                                     , PEB_BASE_ID              -- 인건비계획기준ID
                                     , COMPANY_CD               -- 인사영역
                                     , UNION_CD					-- 노조사업장코드[PAY_UNION_CD]
                                     , PAY_GRADE                -- 호봉코드 [PHM_YEARNUM_CD]
                                     , STA_YMD                  -- 시작일
                                     , END_YMD                  -- 종료일
                                     , OLD_PAY_AMT              -- 이전기본급
                                     , OLD_PAY_HOUR_AMT			-- 이전시급
                                     , PAY_AMT                  -- 기본급
                                     , PAY_HOUR_AMT				-- 시급
                                     , PAY_GRADE_DIF            -- 호간
									 , HIRE_BASE_YEAR			-- 입사기준년도
                                     , NOTE                     -- 비고
                                     , MOD_USER_ID              -- 변경자
                                     , MOD_DATE                 -- 변경일시
                                     , TZ_CD                    -- 타임존코드
                                     , TZ_DATE                  -- 타임존일시
                                     )
                                SELECT NEXT VALUE FOR S_PEB_SEQUENCE   -- PEB_PAY_HOBONG_ID
                                     , @an_peb_base_id                 -- PEB_BASE_ID
                                     , COMPANY_CD                      -- COMPANY_CD
                                     , UNION_CD						   -- UNION_CD
                                     , PAY_GRADE                       -- PAY_GRADE
                                     , @d_std_sta_ymd                  -- STA_YMD
                                     , @d_end_ymd                      -- END_YMD
                                     , PAY_AMT                         -- OLD_PAY_AMT
                                     , PAY_HOUR_AMT					   -- OLD_PAY_HOUR_AMT
                                     , PAY_AMT                         -- PAY_AMT
                                     , PAY_HOUR_AMT					   -- PAY_HOUR_AMT
                                     , PAY_GRADE_DIF                   -- PAY_GRADE_DIF
									 , HIRE_BASE_YEAR				   -- HIRE_BASE_YEAR
                                     , NOTE                            -- NOTE
                                     , @an_mod_user_id                 -- MOD_USER_ID
                                     , GETDATE()                       -- MOD_DATE
                                     , 'KST'                           -- TZ_CD
                                     , GETDATE()                       -- TZ_DATE
                                  FROM PAY_HOBONG_X
                                 WHERE COMPANY_CD = @av_company_cd
                                   AND @d_std_ymd BETWEEN STA_YMD AND END_YMD
                                   AND ISNULL(PAY_AMT, 0) <> 0
								   
    END TRY
    BEGIN CATCH
        SET @av_ret_code = 'FAILURE!'
        SET @av_ret_message = DBO.F_FRM_ERRMSG('인건비 호봉자료 복사 중 에러발생[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
        IF @@TRANCOUNT > 0
            ROLLBACK
        RETURN
    END CATCH

--===========================================================
-- 인건비 인상정보 있을 경우 추가 INSERT
--===========================================================
    IF @v_peb_ym IS NOT NULL
        BEGIN
            BEGIN TRY
                INSERT INTO PEB_PAY_HOBONG_X ( PEB_PAY_HOBONG_ID        -- 인건비계획호봉ID
                                             , PEB_BASE_ID              -- 인건비계획기준ID
                                             , COMPANY_CD               -- 인사영역
                                             , UNION_CD					-- 노조사업장코드[PAY_UNION_CD]
                                             , PAY_GRADE                -- 호봉코드 [PHM_YEARNUM_CD]
                                             , STA_YMD                  -- 시작일
                                             , END_YMD                  -- 종료일
                                             , OLD_PAY_AMT              -- 이전기본급
                                             , OLD_PAY_HOUR_AMT			-- 이전시급
                                             , PAY_AMT                  -- 기본급
                                             , PAY_HOUR_AMT             -- 시급
                                             , PAY_GRADE_DIF            -- 호간
											 , HIRE_BASE_YEAR			-- 입사기준년도
                                             , NOTE                     -- 비고
                                             , MOD_USER_ID              -- 변경자
                                             , MOD_DATE                 -- 변경일시
                                             , TZ_CD                    -- 타임존코드
                                             , TZ_DATE                  -- 타임존일시
                                             )
                                        SELECT NEXT VALUE FOR S_PEB_SEQUENCE   -- PEB_PAY_HOBONG_ID
                                             , @an_peb_base_id                 -- PEB_BASE_ID
                                             , COMPANY_CD                      -- COMPANY_CD
                                             , UNION_CD						   -- UNION_CD
                                             , PAY_GRADE                       -- PAY_GRADE
                                             , @d_sta_ymd                      -- STA_YMD
                                             , @d_std_end_ymd                  -- END_YMD
                                             , PAY_AMT                         -- OLD_PAY_AMT
                                             , PAY_HOUR_AMT					   -- OLD_PAY_HOUR_AMT
                                             , DBO.XF_CEIL(@n_up_rate * PAY_AMT       , -2)    -- PAY_AMT
                                             , DBO.XF_CEIL(@n_up_rate * PAY_HOUR_AMT  , -2)    -- PAY_HOUR_AMT
											 , PAY_GRADE_DIF                   -- PAY_GRADE_DIF
											 , HIRE_BASE_YEAR				   -- HIRE_BASE_YEAR 
                                             , NOTE                            -- NOTE
                                             , @an_mod_user_id                 -- MOD_USER_ID
                                             , GETDATE()                       -- MOD_DATE
                                             , 'KST'                           -- TZ_CD
                                             , GETDATE()                       -- TZ_DATE
                                          FROM PAY_HOBONG_X
                                         WHERE COMPANY_CD = @av_company_cd
                                           AND @d_std_ymd BETWEEN STA_YMD AND END_YMD
                                           AND ISNULL(PAY_AMT, 0) <> 0

            END TRY
            BEGIN CATCH
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('인상율반영 호봉자료 생성 중 에러발생[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
                IF @@TRANCOUNT > 0
                    ROLLBACK
                RETURN
            END CATCH
        END

--=========================================================
-- 작업완료
--=========================================================
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('호봉복사가 완료되었습니다.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
END

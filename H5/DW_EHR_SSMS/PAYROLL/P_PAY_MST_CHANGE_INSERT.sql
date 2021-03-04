SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PAY_MST_CHANGE_INSERT] (
    @av_company_cd              NVARCHAR(100),            -- 인사영역
    @av_locale_cd               NVARCHAR(100),            -- 언어
    @an_emp_id                  NUMERIC,                  -- 사원id
    @av_pay_item_cd             NVARCHAR(10),            -- 급여항목기준코드
    @av_pay_item_value          NVARCHAR(50),            -- 데이타
    @av_pay_item_value_text     NVARCHAR(100),            -- 데이타 설명
    @ad_sta_ymd                 DATE,                     -- 시작일자
    @ad_end_ymd                 DATE,                     -- 종료일자
    @an_pay_ymd_id              NUMERIC,                  -- 현재급여일자ID(개인별소급급열일자 테이블에 넣을 급여 일자)
    @an_in_pay_ymd_id           NUMERIC,                  -- 급여일자 ID (기초원장에 넣을 경우에만 넘기고 아니면 NULL을 넘김, 기초원장에 등록될 급여일자)
    @av_salary_type_cd          NVARCHAR(50),            -- 대상자의 급여유형
    @av_retro_type              NVARCHAR(50),            -- 소급 유형 [1 :모든 지급유형 소급, 2 : 같은 지급유형만 소급, 3: 소급 없음]
    @av_pay_type_cd             NVARCHAR(50),            -- 지급유형
    @an_bel_org_id              NUMERIC,                  -- 귀속부서id
    @av_tz_cd                   NVARCHAR(50),            -- 타임존코드
    @an_mod_user_id             NUMERIC,                  -- 변경자 사원id
    @av_ret_code                NVARCHAR(1000) OUTPUT,    -- SUCCESS!/FAILURE!
    @av_ret_message             NVARCHAR(1000) OUTPUT     -- 결과메시지
) AS
    -- ***************************************************************************
    --   TITLE       : 급여기초원장 TABLE INSERT
    --   PROJECT     : 신인사정보시스템
    --   AUTHOR      : 정순보
    --   PROGRAM_ID  : P_PAY_MST_CHANGE_INSERT
    --   ARGUMENT    :
    --   RETURN      :
    --   COMMENT     : **급여기초원장 TABLE INSERT  (최종데이타는 사원,급여항목기준별로 날짜가 겹치지 않는것이 원칙이다)
    --                   최종데이타와 기간과 값이 같은 경우는 그냥 RETURN 한다.
    --                   ELSE 최종데이타와 기간이 같고 값이 다르면 최종데이타의  최종여부 N 로 하고 새로운 데이타를 INSERT 한다.
    --                   ELSE 최종데이타와 기간이 겹칠 경우 최종데이타의 최종여부 N 로 하고 겹치는 데이타는 새로운 데이타와 겹치지
    --                         않게 INSERT 하고 새로운 데이타를 INSERT 한다. (새로운 데이타의 종료일 이후의 최종데이타는  insert 하지 않는다.)
    --                 **기간연속여부느가 'N' 이면 최종데이타와 새로운 데이타가 겹치면 최종여부 N 로  새로운 데이타를 INSERT 한다.
    --                 **급여 의뢰에서는 사용하지 마세요
    --                 **  소급할때 산출기간이 정산일자를 벗어났을때 체크하기 위해 정산기간을 따로 받아야 할까? 선지급 문제인디
    --                     우선은 근태는 알아서 소그일자관리 테이블에 넣었땅.
    --   HISTORY     : 작성 정순보 2006.08.30
    --               : 2020.03.30 - MS-SQL 변환작업 : 오상진
    -- ***************************************************************************
DECLARE

    /* 공통 변수 (에러코드 처리시 사용) */
    @v_program_id            NVARCHAR(30),
    @v_program_nm            NVARCHAR(100),
    @n_cnt                   NUMERIC,
    @at_pay_mst_change       NUMERIC,
    @d_sta_ymd               DATE,
    @d_end_ymd               DATE,
    @d_mst_sta_ymd           DATE,
    @v_retro_chk_sta_ymd     DATE = NULL,
    @v_retro_check_yn        CHAR(1),
    @v_day_retro_yn          NVARCHAR(1),      -- 일할계산(휴직등)으로 소급  할지 여부 Y/N
    @v_term_yn               CHAR(1),          -- 기간 연속 여부
    @v_retro_type            NVARCHAR(1),      -- 소급 유형 [1 :모든 지급유형 소급, 2 : 같은 지급유형만 소급, 3: 소급 없음]
    @v_rest_cal_yn           CHAR(1),          -- 휴직내역 계산여부
    @v_cd_kind               NVARCHAR(50),     -- 코드분류 ( 데이타 값 넣기 위함)

    @errornumber             INT,
    @errormessage            NVARCHAR(4000)

BEGIN

    /* 기본변수 초기값 셋팅 */
    SET @v_program_id    = 'P_PAY_MST_CHANGE_INSERT'                 -- 현재 프로시져의 영문명
    SET @v_program_nm    = '[기초원장 TABLE INSERT]'                  -- 현재 프로시져의 한글명

    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = DBO.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null, @an_mod_user_id)

    SET @errornumber   = ERROR_NUMBER()
    SET @errormessage  = ERROR_MESSAGE()

    -- 퇴직자 일할계산 안하려고 종료일 가공할 경우가 있는데.. 시작일이  퇴직일 보다 큰게 있을 경우 발생해서 그냥 리턴
    IF @ad_sta_ymd > @ad_end_ymd
        RETURN

    SET @d_mst_sta_ymd = @ad_sta_ymd
    SET @v_retro_type  = @av_retro_type

    -- ***********************************************************************************************************
    -- 1.급여의뢰일자가 있으면 무조건 등록하고 프로시저를 빠져 나간다.
    --   기초원장 생성시 처음에 급여의뢰일자가 있으면 모두 삭제하기 때문
    -- ***********************************************************************************************************

    IF @an_in_pay_ymd_id IS NOT NULL

        BEGIN

            -- 화면에서 수정할 경우가 있어서 최종여부 'N' 으로 넣는다.
            BEGIN TRY

                UPDATE PAY_MST_CHANGE
                   SET LAST_YN = 'N'
                 WHERE EMP_ID          =  @an_emp_id           -- 사원ID
                   AND PAY_ITEM_CD     =  @av_pay_item_cd      -- 급여항목기준코드[PAY_ITEM_CD]
                   AND SALARY_TYPE_CD  =  @av_salary_type_cd   -- 급여항목기준코드[PAY_ITEM_CD]
                   AND LAST_YN         =  'Y'                  -- 최종데이타여부
                   AND PAY_YMD_ID      =  @an_in_pay_ymd_id

            END TRY
            BEGIN CATCH

                SET @errornumber    = ERROR_NUMBER()
                SET @errormessage   = ERROR_MESSAGE()
                
                SET @av_ret_code    = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('PAY_MST_CHANGE 업데이트 에러 발생 [ERR]', @v_program_id , 0128, @errormessage, @an_mod_user_id)
                
                IF @@TRANCOUNT > 0
                    ROLLBACK WORK
                RETURN

            END CATCH


            -- 기초원장(급여변동내역)
            BEGIN TRY
                INSERT INTO PAY_MST_CHANGE
                (
                    PAY_MST_CHANGE_ID       ,  -- 기초원장ID
                    EMP_ID                  ,  -- 사원ID
                    SALARY_TYPE_CD          ,  -- 급여유형
                    PAY_ITEM_CD             ,  -- 급여항목기준코드(PAY_ITEM_CD)
                    PAY_ITEM_VALUE          ,  -- 급여기준항목값
                    PAY_ITEM_VALUE_TEXT     ,  -- 급여기준항목값 설명
                    STA_YMD                 ,  -- 시작일자
                    END_YMD                 ,  -- 종료일자
                    LAST_YN                 ,  -- 최종데이타여부
                    PAY_YMD_ID              ,  -- 급여일자ID(급여 의뢰 데이타만
                    MOD_USER_ID             ,  -- 변경자
                    MOD_DATE                ,  -- 변경일시
                    TZ_CD                   ,  -- 타임존코드
                    TZ_DATE                 ,  -- 타임존일시
                    BEL_ORG_ID              ,  -- 귀속부서id
                    MAKE_PAY_YMD_ID         ,  -- 생성시급여일자ID(소급체크를 위해 넣음)
                    RETRO_CHK_STA_YMD          -- 소급일자체크여부
                )
                VALUES
                (
                    NEXT VALUE FOR DBO.S_PAY_SEQUENCE   ,  -- 기초원장ID
                    @an_emp_id                  ,    -- 사원ID
                    @av_salary_type_cd          ,    -- 급여유형
                    @av_pay_item_cd             ,    -- 급여항목기준코드(PAY_ITEM_CD)
                    @av_pay_item_value          ,    -- 급여기준항목값
                    @av_pay_item_value_text     ,    -- 급여기준항목값 설명
                    @d_mst_sta_ymd              ,    -- 시작일자
                    @ad_end_ymd                 ,    -- 종료일자
                    'Y'                         ,    -- 최종데이타여부
                    @an_in_pay_ymd_id           ,    -- 급여일자ID(급여 의뢰 데이타만)
                    @an_mod_user_id             ,    -- 변경자
                    GETDATE()                   ,    -- 변경일시
                    @av_tz_cd                   ,    -- 타임존코드
                    DBO.F_FRM_GETDATE(GETDATE(), @av_tz_cd)   , -- 타임존일시
                    @an_bel_org_id              ,    -- 귀속부서id
                    @an_pay_ymd_id              ,    -- 생성시급여일자ID(소급체크를 위해 넣음)
                    NULL                             -- 소급일자체크여부
                )
            END TRY
            BEGIN CATCH

                SET @errornumber   = ERROR_NUMBER()
                SET @errormessage  = ERROR_MESSAGE()
                
                SET @av_ret_code    = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('PAY_MST_CHANGE INSERT시 에러 발생 [ERR]', @v_program_id , 0180, @errormessage, @an_mod_user_id)
                
                IF @@TRANCOUNT > 0
                    ROLLBACK WORK
                
                RETURN

            END CATCH

            RETURN

        END --IF @an_in_pay_ymd_id IS NOT NULL

    -- ***********************************************************************************************************
    -- 2.중복자료가 기존에 존재하는지 체크한다
    -- 중복자료일 경우 급여기준항목값, 급여기준항목값 설명만 업데이트 함.
    -- ***********************************************************************************************************
    BEGIN

        SELECT @n_cnt = COUNT(*)
          FROM PAY_MST_CHANGE
         WHERE EMP_ID                 =  @an_emp_id                 -- 사원ID
           AND PAY_ITEM_CD            =  @av_pay_item_cd            -- 급여항목기준코드(PAY_ITEM_CD)
           --AND PAY_ITEM_VALUE         =  @av_pay_item_value         -- 급여기준항목값
           AND STA_YMD                =  @ad_sta_ymd                -- 시작일자
           AND END_YMD                =  @ad_end_ymd                -- 종료일자
           AND LAST_YN                =  'Y'                        -- 최종데이타여부
           AND SALARY_TYPE_CD         =  @av_salary_type_cd         -- 급여유형코드
           AND ISNULL(BEL_ORG_ID, -1) =  ISNULL(@an_bel_org_id, -1) -- 귀속부서도 체크 필요  null 이었을 경우 틀린 것으로 나오기 땜시 nvl 처리

        -- 기초원장에 넣으려는 값이 똑 같은것이 있으면 안 넣는다.
        -- 급여기준항목값 설명만 UPDATE 한다
        IF @n_cnt > 0

            BEGIN
                BEGIN TRY
                    UPDATE PAY_MST_CHANGE
                       SET PAY_ITEM_VALUE_TEXT    =  @av_pay_item_value_text    -- 급여기준항목값 설명
					     , PAY_ITEM_VALUE         =  @av_pay_item_value         -- 최종데이타여부
                         , MOD_USER_ID            =  @an_mod_user_id            -- 변경자
                         , MOD_DATE               =  GETDATE()                  -- 변경일시

                     WHERE EMP_ID                 =  @an_emp_id                 -- 사원ID
                       AND PAY_ITEM_CD            =  @av_pay_item_cd            -- 급여항목기준코드(PAY_ITEM_CD)
                       --AND PAY_ITEM_VALUE         =  @av_pay_item_value         -- 급여기준항목값
                       AND STA_YMD                =  @ad_sta_ymd                -- 시작일자
                       AND END_YMD                =  @ad_end_ymd                -- 종료일자
                       AND LAST_YN                =  'Y'                        -- 최종데이타여부
                       AND SALARY_TYPE_CD         =  @av_salary_type_cd
                       AND ISNULL(BEL_ORG_ID, -1) =  ISNULL(@an_bel_org_id, -1)
                END TRY
                BEGIN CATCH
                    SET @errornumber   = ERROR_NUMBER()
                    SET @errormessage  = ERROR_MESSAGE()
                    
                    SET @av_ret_code    = 'FAILURE!'
                    SET @av_ret_message = DBO.F_FRM_ERRMSG('PAY_MST_CHANGE UPDATE시 에러 발생 [ERR]', @v_program_id , 0226, @errormessage, @an_mod_user_id)
                    
                    IF @@TRANCOUNT > 0
                        ROLLBACK WORK
                    RETURN
                END CATCH

                RETURN

            END --IF @n_cnt > 0
    END


    -- ***********************************************************************************************************
    -- 3. 기간은 같은데 값이 틀릴 경우 기존자료 값만 UPDATE 처리 하고 종료한다
    -- ***********************************************************************************************************
	/*
    BEGIN

        SELECT @at_pay_mst_change = PAY_MST_CHANGE_ID
          FROM PAY_MST_CHANGE
         WHERE EMP_ID                 =  @an_emp_id               -- 사원ID
           AND SALARY_TYPE_CD         =  @av_salary_type_cd       -- 급여유형코드
           AND PAY_ITEM_CD            =  @av_pay_item_cd          -- 급여항목기준코드(PAY_ITEM_CD)
           AND PAY_ITEM_VALUE         <>  @av_pay_item_value      -- 급여기준항목값
           AND STA_YMD                =  @ad_sta_ymd              -- 시작일자
           AND END_YMD                =  @ad_end_ymd              -- 종료일자
           AND LAST_YN                =  'Y'                      -- 최종데이타여부
           AND ISNULL(BEL_ORG_ID, -1) = ISNULL(@an_bel_org_id, -1)

        --중복자료 자료가 존재할 경우 기존자료 최종여부 UPDATE 후 신규자료 등록하고 종료한다
        IF @at_pay_mst_change IS NOT NULL

            BEGIN

                BEGIN TRY

                    UPDATE PAY_MST_CHANGE
                    SET PAY_ITEM_VALUE          =  @av_pay_item_value   ,   -- 최종데이타여부
                        MOD_USER_ID             =  @an_mod_user_id      ,   -- 변경자
                        MOD_DATE                =  GETDATE()                -- 변경일시
                    WHERE PAY_MST_CHANGE_ID     =  @at_pay_mst_change

                END TRY

                BEGIN CATCH

                    SET @errornumber   = ERROR_NUMBER()
                    SET @errormessage  = ERROR_MESSAGE()

                    SET @av_ret_code = 'FAILURE!'
                    SET @av_ret_message = DBO.F_FRM_ERRMSG('[기간은 같은데 값이 틀릴 경우UPDATE] (' + DBO.F_FRM_CODE_NM(@av_company_cd , @av_locale_cd, 'PAY_ITEM_CD', @av_pay_item_cd, GETDATE(),'1') + ') INSERT 시 에러발생 -' + @an_emp_id,
                                                            @v_program_id,  0259,  @errormessage, @an_mod_user_id)
                    RETURN

                END CATCH

                RETURN

            END

    END
	*/

    -- ***********************************************************************************************************
    -- 4.자료 체크를 위해 급여계산설정의 해당 급여항목의 기준정보를 읽어온다
    -- ***********************************************************************************************************

    BEGIN

        SELECT
            @v_term_yn          = CASE WHEN B.ETC_CD1 IS NULL THEN 'Y' ELSE B.ETC_CD1 END,  -- 기간연속여부
            @v_day_retro_yn     = CASE WHEN CD4 IS NULL THEN   'N' ELSE CD4 END,            -- 일할계산 사유가 있는것은 일할계산 지급율 관리 rule 을 따르는 것이다.
            @v_retro_type       = CASE WHEN @av_pay_type_cd = 'P' AND B.ETC_CD2 = 'Y' THEN '3' ELSE @v_retro_type END,  -- 급여일 경우 소급 별도 체크 여부가 Y 이면 소급 안함. 따로 체크할거기 때문
            @v_retro_check_yn   = CASE WHEN B.ETC_CD2 IS NULL THEN 'N' ELSE  B.ETC_CD2  END,   -- 급여일 경우 소급 별도 체크 여부가 Y 이면 나중에 소급 체크 하라고 해야 함.
            @v_rest_cal_yn      = B.ETC_CD2,
            @v_cd_kind          = B.ETC_CD5
        FROM
            FRM_UNIT_STD_MGR A,    -- 업무기준관리
            FRM_UNIT_STD_HIS B     -- 기준관리내역
        WHERE A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
        AND A.COMPANY_CD    = @av_company_cd
        AND A.UNIT_CD       = 'PAY'                --업무분류코드(급여)
        AND A.STD_KIND      = 'PAY_ITEM_CD_BASE'   --기준분류코드(급여항목)
        AND @ad_end_ymd BETWEEN B.STA_YMD AND B.END_YMD
        AND B.KEY_CD1 = @av_pay_item_cd

        IF (@@ROWCOUNT < 1)

            BEGIN
				
				--회사별 급여계산설정에 반영되지 않은 항목은 SKIP 한다

                --SET @av_ret_code    = 'FAILURE!'
                --SET @av_ret_message = DBO.F_FRM_ERRMSG('기초원장 코드 [' +  @av_pay_item_cd + '] 코드가 존재하지 않습니다.-' + CONVERT(NVARCHAR(50),@an_emp_id) + '-' + CONVERT(VARCHAR(10), @ad_end_ymd, 120),
                --                                        @v_program_id,  0142,  @errormessage,  @an_mod_user_id)

                RETURN
            END

         IF (@@ERROR > 0)
            BEGIN
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('[기간연속여부조회]기초원장  (' + DBO.F_FRM_CODE_NM(@av_company_cd , @av_locale_cd, 'PAY_ITEM_CD',@av_pay_item_cd,  GETDATE(),'1') + ') INSERT 시 에러발생 -' + CONVERT(NVARCHAR(50),@an_emp_id),
                                                        @v_program_id,  0153,  @errormessage,  @an_mod_user_id)

                RETURN
            END
    END


    IF @v_retro_check_yn = 'Y'
        SET @v_retro_chk_sta_ymd = @ad_sta_ymd

    -- ***********************************************************************************************************
    -- 5.기간연속체크 항목에 기간포함무시로 체크되어 있을 경우 채쿠
    --   종료일자가 같고 신규 시작일자만 기존시작일자 보다 클 경우 기간에 포함된 자료가 이미 존재하기 때문에 SKIP
    -- ***********************************************************************************************************


    IF @v_term_yn = 'M' -- 기간포함무시(종료일같은경우만)

        BEGIN
            SELECT @n_cnt = COUNT(*)
              FROM PAY_MST_CHANGE  -- 기초원장(급여변동내역)
             WHERE EMP_ID          =  @an_emp_id               -- 사원ID
               AND PAY_ITEM_CD     =  @av_pay_item_cd          -- 급여항목기준코드(PAY_ITEM_CD)
               AND PAY_ITEM_VALUE  =  @av_pay_item_value       -- 급여기준항목값
               AND STA_YMD         <= @ad_sta_ymd              -- 시작일자
               AND END_YMD         =  @ad_end_ymd              -- 종료일자
               AND LAST_YN         =  'Y'                      -- 최종데이타여부
               AND SALARY_TYPE_CD  =  @av_salary_type_cd	   -- 급여유형
               AND ISNULL(BEL_ORG_ID, -1)  = ISNULL(@an_bel_org_id, -1)

            IF @n_cnt > 0
                RETURN
        END

    -- ***********************************************************************************************************
    -- 6. 신규등록자료와 기간이 겹치는 기존원장 자료를 체크하여 기간을 재산정한다
    -- ***********************************************************************************************************
    IF @av_pay_item_value IS NOT NULL

        BEGIN

            DECLARE @for_mst_chg_bel_org_id                    NUMERIC
                  , @for_mst_chg_emp_id                        NUMERIC
                  , @for_mst_chg_end_ymd                       DATE
                  , @for_mst_chg_last_yn                       CHAR(1)
                  , @for_mst_chg_make_pay_ymd_id               NUMERIC
                  , @for_mst_chg_mod_date                      DATE
                  , @for_mst_chg_mod_user_id                   NUMERIC
                  , @for_mst_chg_pay_item_cd                   NVARCHAR(10)
                  , @for_mst_chg_pay_item_value                NVARCHAR(50)
                  , @for_mst_chg_pay_item_value_text           NVARCHAR(100)
                  , @for_mst_chg_pay_mst_change_id             NUMERIC
                  , @for_mst_chg_pay_ymd_id                    NUMERIC
                  , @for_mst_chg_retro_chk_sta_ymd             DATE
                  , @for_mst_chg_salary_type_cd                NVARCHAR(10)
                  , @for_mst_chg_sta_ymd                       DATE
                  , @for_mst_chg_tz_cd                         NVARCHAR(10)
                  , @for_mst_chg_tz_date                       DATE

                --기간이 겹치는 경우가 있을 경우
            DECLARE for_mst_chg CURSOR LOCAL FORWARD_ONLY FOR
                SELECT EMP_ID
                     , PAY_ITEM_CD
                     , PAY_ITEM_VALUE
                     , PAY_ITEM_VALUE_TEXT
                     , PAY_MST_CHANGE_ID
                     , PAY_YMD_ID
                     , RETRO_CHK_STA_YMD
                     , SALARY_TYPE_CD
                     , STA_YMD
                     , END_YMD
                     , LAST_YN
                     , BEL_ORG_ID
                     , MAKE_PAY_YMD_ID
                     , MOD_DATE
                     , MOD_USER_ID
                     , TZ_CD
                     , TZ_DATE
                  FROM PAY_MST_CHANGE  -- 기초원장
                 WHERE EMP_ID         =  @an_emp_id            -- 사원ID
                   AND SALARY_TYPE_CD =  @av_salary_type_cd    -- 급여유형
                   AND PAY_ITEM_CD    =  @av_pay_item_cd       -- 급여항목기준코드(PAY_ITEM_CD)
                   AND STA_YMD        <= @ad_end_ymd           -- 시작일자
                   AND END_YMD        >= @ad_sta_ymd           -- 종료일자
                   AND LAST_YN        =  'Y'                   -- 최종데이타여부
                   AND ISNULL(BEL_ORG_ID, -1)    = ISNULL(@an_bel_org_id, -1)
								 ORDER BY STA_YMD DESC
                OPEN for_mst_chg

                FETCH NEXT FROM for_mst_chg INTO @for_mst_chg_emp_id
                                               , @for_mst_chg_pay_item_cd
                                               , @for_mst_chg_pay_item_value
                                               , @for_mst_chg_pay_item_value_text
                                               , @for_mst_chg_pay_mst_change_id
                                               , @for_mst_chg_pay_ymd_id
                                               , @for_mst_chg_retro_chk_sta_ymd
                                               , @for_mst_chg_salary_type_cd
                                               , @for_mst_chg_sta_ymd
                                               , @for_mst_chg_end_ymd
                                               , @for_mst_chg_last_yn
                                               , @for_mst_chg_bel_org_id
                                               , @for_mst_chg_make_pay_ymd_id
                                               , @for_mst_chg_mod_date
                                               , @for_mst_chg_mod_user_id
                                               , @for_mst_chg_tz_cd
                                               , @for_mst_chg_tz_date

                WHILE @@FETCH_STATUS = 0

                    BEGIN

                        IF @@FETCH_STATUS = -1
                            BREAK

                        -- ***********************************************************************************************************
                        -- 6.1 기존에 존재하는 값은 종료처리 한다
                        -- ***********************************************************************************************************
                        BEGIN TRY

                            UPDATE PAY_MST_CHANGE
                               SET LAST_YN           = 'N'                 -- 최종데이타여부
                                 , MOD_USER_ID       = @an_mod_user_id     -- 변경자
                                 , MOD_DATE          = GETDATE()           -- 변경일시
                             WHERE PAY_MST_CHANGE_ID = @for_mst_chg_pay_mst_change_id

                        END TRY
                        BEGIN CATCH
                            --중복오류일 경우 기존자료를 삭제한다
                            IF ERROR_NUMBER() = 2627

                                BEGIN

                                    DELETE FROM PAY_MST_CHANGE
                                    WHERE PAY_MST_CHANGE_ID = (
                                                                SELECT PAY_MST_CHANGE_ID
                                                                FROM PAY_MST_CHANGE
                                                                WHERE EMP_ID        = @for_mst_chg_emp_id
                                                                AND SALARY_TYPE_CD  = @for_mst_chg_salary_type_cd
                                                                AND PAY_ITEM_CD     = @for_mst_chg_pay_item_cd
                                                                AND STA_YMD         = @for_mst_chg_sta_ymd
                                                                AND LAST_YN         = 'N'
                                                                )

                                    UPDATE PAY_MST_CHANGE
                                    SET PAY_ITEM_VALUE          =  @av_pay_item_value   ,   -- 최종데이타여부
                                        MOD_USER_ID             =  @an_mod_user_id      ,   -- 변경자
                                        MOD_DATE                =  GETDATE()                -- 변경일시
                                    WHERE PAY_MST_CHANGE_ID     =  @for_mst_chg_pay_mst_change_id

                                     IF (@@ERROR > 0)
                                        BEGIN
                                            SET @av_ret_code = 'FAILURE!'
                                            SET @av_ret_message = DBO.F_FRM_ERRMSG('기초원장  (' + DBO.F_FRM_CODE_NM(@av_company_cd , @av_locale_cd, 'PAY_ITEM_CD',@av_pay_item_cd,  GETDATE(),'1') + ') UPDATE 시 에러발생 -' + @an_emp_id,
                                                                @v_program_id,  0153,  @errormessage,  @an_mod_user_id)
                                            RETURN
                                        END

                                END

                            ELSE

                                BEGIN

                                    SET @av_ret_code = 'FAILURE!'
                                    SET @av_ret_message = DBO.F_FRM_ERRMSG('기초원장  (' + DBO.F_FRM_CODE_NM(@av_company_cd , @av_locale_cd, 'PAY_ITEM_CD',@av_pay_item_cd,  GETDATE(),'1') + ') DELETE 시 에러발생 -' + @an_emp_id,
                                                                    @v_program_id,  0153,  @errormessage,  @an_mod_user_id)
                                    RETURN

                                END

                        END CATCH

                        -- ***********************************************************************************************************
                        -- 6.2 구간연속인 자료는 일자별로 구간을 재생성 한다
                        -- ***********************************************************************************************************
												print 'v_term_yn=' + @v_term_yn
                        IF @v_term_yn = 'Y' -- 데이타가 연속성이 있을 경우에만 겹치지 않는 부분을 다시 등록한다.

                            BEGIN
																PRINT 'ad_sta_ymd=' + convert(varchar(100),  @for_mst_chg_sta_ymd)
                                IF @ad_sta_ymd > @for_mst_chg_sta_ymd

                                    BEGIN

                                        SET @d_sta_ymd = @for_mst_chg_sta_ymd
                                        SET @d_end_ymd = DBO.XF_TO_CHAR_D(DATEADD(dd, -1, @ad_sta_ymd), 'YYYYMMDD')

                                        BEGIN TRY
                                            INSERT INTO PAY_MST_CHANGE
                                            (
                                                PAY_MST_CHANGE_ID       ,  -- 기초원장ID
                                                EMP_ID                  ,  -- 사원ID
                                                SALARY_TYPE_CD          ,  -- 급여유형
                                                PAY_ITEM_CD             ,  -- 급여항목기준코드(PAY_ITEM_CD)
                                                PAY_ITEM_VALUE          ,  -- 급여기준항목값
                                                PAY_ITEM_VALUE_TEXT     ,  -- 급여기준항목값 설명
                                                STA_YMD                 ,  -- 시작일자
                                                END_YMD                 ,  -- 종료일자
                                                LAST_YN                 ,  -- 최종데이타여부
                                                PAY_YMD_ID              ,  -- 급여일자ID(급여 의뢰 데이타만
                                                MOD_USER_ID             ,  -- 변경자
                                                MOD_DATE                ,  -- 변경일시
                                                TZ_CD                   ,  -- 타임존코드
                                                TZ_DATE                 ,  -- 타임존일시
                                                BEL_ORG_ID              ,  -- 귀속부서id
                                                MAKE_PAY_YMD_ID         ,  --생성시급여일자ID(소급체크를 위해 넣음)
                                                RETRO_CHK_STA_YMD          --소급일자체크여부
                                            )
                                            VALUES
                                            (
                                                NEXT VALUE FOR DBO.S_PAY_SEQUENCE   ,  -- 기초원장ID
                                                @for_mst_chg_emp_id                 ,  -- 사원ID
                                                @av_salary_type_cd                  ,  -- 급여유형
                                                @for_mst_chg_pay_item_cd            ,  -- 급여항목기준코드(PAY_ITEM_CD)
                                                @for_mst_chg_pay_item_value         ,  -- 급여기준항목값
                                                @for_mst_chg_pay_item_value_text    ,  -- 급여기준항목값 설명
                                                @d_sta_ymd                          ,  -- 시작일자
                                                @d_end_ymd                          ,  -- 종료일자
                                                'Y'                                 ,  -- 최종데이타여부
                                                @for_mst_chg_pay_ymd_id             ,  -- 급여일자ID(급여 의뢰 데이타만
                                                @an_mod_user_id                     ,  -- 변경자
                                                GETDATE()                           ,  -- 변경일시
                                                @av_tz_cd                           ,  -- 타임존코드
                                                DBO.F_FRM_GETDATE(GETDATE(), @av_tz_cd)    ,   -- 타임존일시
                                                @an_bel_org_id                      ,  -- 귀속부서id
                                                @an_pay_ymd_id                      ,  -- 생성시급여일자ID(소급체크를 위해 넣음)
                                                @v_retro_chk_sta_ymd
                                            )
                                        END TRY

                                        BEGIN CATCH
                                            SET @errornumber   = ERROR_NUMBER()
                                            SET @errormessage  = ERROR_MESSAGE()

                                            SET @av_ret_code    = 'FAILURE!'
                                            SET @av_ret_message = DBO.F_FRM_ERRMSG('PAY_MST_CHANGE INSERT시 에러 발생 [ERR]', @v_program_id , 0443, @errormessage, @an_mod_user_id)

                                            IF @@TRANCOUNT > 0
                                                ROLLBACK WORK
                                            RETURN

                                        END CATCH

                                    END --@ad_sta_ymd > @for_mst_chg_sta_ymd

                                IF @ad_end_ymd < @for_mst_chg_end_ymd

                                    BEGIN

                                        SET @d_sta_ymd = DBO.XF_TO_CHAR_D(DATEADD(dd, 1, @ad_end_ymd), 'YYYYMMDD')
                                        SET @d_end_ymd = @for_mst_chg_end_ymd

                                        BEGIN TRY
                                            INSERT INTO PAY_MST_CHANGE
                                                (
                                                    PAY_MST_CHANGE_ID       ,  -- 기초원장ID
                                                    EMP_ID                  ,  -- 사원ID
                                                    SALARY_TYPE_CD          ,  -- 급여유형
                                                    PAY_ITEM_CD             ,  -- 급여항목기준코드(PAY_ITEM_CD)
                                                    PAY_ITEM_VALUE          ,  -- 급여기준항목값
                                                    PAY_ITEM_VALUE_TEXT     ,  -- 급여기준항목값 설명
                                                    STA_YMD                 ,  -- 시작일자
                                                    END_YMD                 ,  -- 종료일자
                                                    LAST_YN                 ,  -- 최종데이타여부
                                                    PAY_YMD_ID              ,  -- 급여일자ID(급여 의뢰 데이타만
                                                    MOD_USER_ID             ,  -- 변경자
                                                    MOD_DATE                ,  -- 변경일시
                                                    TZ_CD                   ,  -- 타임존코드
                                                    TZ_DATE                 ,  -- 타임존일시
                                                    BEL_ORG_ID              ,  -- 귀속부서id
                                                    MAKE_PAY_YMD_ID         ,  --생성시급여일자ID(소급체크를 위해 넣음)
                                                    RETRO_CHK_STA_YMD          --소급일자체크여부
                                                )
                                            VALUES
                                            (
                                                    NEXT VALUE FOR DBO.S_PAY_SEQUENCE   ,  -- 기초원장ID
                                                    @for_mst_chg_emp_id                 ,  -- 사원ID
                                                    @av_salary_type_cd                  ,  -- 급여유형
                                                    @for_mst_chg_pay_item_cd            ,  -- 급여항목기준코드(PAY_ITEM_CD)
                                                    @for_mst_chg_pay_item_value         ,  -- 급여기준항목값
                                                    @for_mst_chg_pay_item_value_text    ,  -- 급여기준항목값 설명
                                                    @d_sta_ymd                          ,  -- 시작일자
                                                    @d_end_ymd                          ,  -- 종료일자
                                                    'Y'                                 ,  -- 최종데이타여부
                                                    @for_mst_chg_pay_ymd_id             ,  -- 급여일자ID(급여 의뢰 데이타만
                                                    @an_mod_user_id                     ,  -- 변경자
                                                    GETDATE()                           ,  -- 변경일시
                                                    @av_tz_cd                           ,  -- 타임존코드
                                                    DBO.F_FRM_GETDATE(GETDATE(), @av_tz_cd) ,   -- 타임존일시
                                                    @an_bel_org_id                      ,  -- 귀속부서id
                                                    @an_pay_ymd_id                      ,  --생성시급여일자ID(소급체크를 위해 넣음)
                                                    @v_retro_chk_sta_ymd
                                            )
                                        END TRY

                                        BEGIN CATCH
                                            SET @errornumber   = ERROR_NUMBER()
                                            SET @errormessage  = ERROR_MESSAGE()

                                            SET @av_ret_code    = 'FAILURE!'
                                            SET @av_ret_message = DBO.F_FRM_ERRMSG('PAY_MST_CHANGE INSERT시 에러 발생 [ERR]', @v_program_id , 0443, @errormessage, @an_mod_user_id)

                                            IF @@TRANCOUNT > 0
                                                ROLLBACK WORK
                                            RETURN
                                        END CATCH

                                    END


                            END --IF v_term_yn = 'Y'


                        FETCH NEXT FROM for_mst_chg INTO
                                         @for_mst_chg_emp_id
                                        ,@for_mst_chg_pay_item_cd
                                        ,@for_mst_chg_pay_item_value
                                        ,@for_mst_chg_pay_item_value_text
                                        ,@for_mst_chg_pay_mst_change_id
                                        ,@for_mst_chg_pay_ymd_id
                                        ,@for_mst_chg_retro_chk_sta_ymd
                                        ,@for_mst_chg_salary_type_cd
                                        ,@for_mst_chg_sta_ymd
                                        ,@for_mst_chg_end_ymd
                                        ,@for_mst_chg_last_yn
                                        ,@for_mst_chg_bel_org_id
                                        ,@for_mst_chg_make_pay_ymd_id
                                        ,@for_mst_chg_mod_date
                                        ,@for_mst_chg_mod_user_id
                                        ,@for_mst_chg_tz_cd
                                        ,@for_mst_chg_tz_date
                    END --WHILE

            END --IF @av_pay_item_value IS NOT NULL

            INS:

            -- 기초원장에 insert
            IF @av_pay_item_value IS NOT NULL  -- 값이 NULL 이면 기존에 데이타에 대해 날짜 조정은 하지만 기초원장에 넣을 필요가 없다.
                BEGIN
                    INSERT INTO PAY_MST_CHANGE
                    (
                        PAY_MST_CHANGE_ID       ,  -- 기초원장ID
                        EMP_ID                  ,  -- 사원ID
                        SALARY_TYPE_CD          ,  -- 급여유형
                        PAY_ITEM_CD             ,  -- 급여항목기준코드(PAY_ITEM_CD)
                        PAY_ITEM_VALUE          ,  -- 급여기준항목값
                        PAY_ITEM_VALUE_TEXT     ,  -- 급여기준항목값 설명
                        STA_YMD                 ,  -- 시작일자
                        END_YMD                 ,  -- 종료일자
                        LAST_YN                 ,  -- 최종데이타여부
                        PAY_YMD_ID              ,  -- 급여일자ID(급여 의뢰 데이타만
                        MOD_USER_ID             ,  -- 변경자
                        MOD_DATE                ,  -- 변경일시
                        TZ_CD                   ,  -- 타임존코드
                        TZ_DATE                 ,  -- 타임존일시
                        BEL_ORG_ID              ,  -- 귀속부서id
                        MAKE_PAY_YMD_ID         ,  -- 생성시급여일자ID(소급체크를 위해 넣음)
                        RETRO_CHK_STA_YMD          -- 소급일자체크여부
                        )
                    VALUES
                    (
                        NEXT VALUE FOR DBO.S_PAY_SEQUENCE       ,  -- 기초원장ID
                        @an_emp_id                              ,  -- 사원ID
                        @av_salary_type_cd                      ,  -- 급여유형
                        @av_pay_item_cd                         ,  -- 급여항목기준코드(PAY_ITEM_CD)
                        @av_pay_item_value                      ,  -- 급여기준항목값
                        CASE WHEN @v_cd_kind IS NOT NULL AND @av_pay_item_value_text IS NULL
                            THEN DBO.F_FRM_CODE_NM(@av_company_cd, @av_locale_cd, @v_cd_kind, @av_pay_item_value, @ad_end_ymd, '1')
                            ELSE @av_pay_item_value_text
                        END                                     ,  -- 급여기준항목값 설명
                        @d_mst_sta_ymd                          ,  -- 시작일자
                        @ad_end_ymd                             ,  -- 종료일자
                        'Y'                                     ,  -- 최종데이타여부
                        @an_in_pay_ymd_id                       ,  -- 급여일자ID(급여 의뢰 데이타만
                        @an_mod_user_id                         ,  -- 변경자
                        GETDATE()                               ,  -- 변경일시
                        @av_tz_cd                               ,  -- 타임존코드
                        DBO.F_FRM_GETDATE(GETDATE(), @av_tz_cd) ,  -- 타임존일시
                        @an_bel_org_id                          ,  -- 귀속부서id
                        @an_pay_ymd_id   ,                         --생성시급여일자ID(소급체크를 위해 넣음)
                        @v_retro_chk_sta_ymd
                    )
                END --IF @av_pay_item_value IS NOT NULL

                SET @errornumber   = ERROR_NUMBER()
                SET @errormessage  = ERROR_MESSAGE()

                IF (@@ROWCOUNT < 1)
                    BEGIN
                        SET @av_ret_code    = 'FAILURE!'
                        SET @av_ret_message = DBO.F_FRM_ERRMSG('P_PAY_MST_CHANGE_INSERT 에러',@v_program_id,  0249,  @errormessage,  @an_mod_user_id)
                        RETURN
                    END

                IF (@@ERROR > 0)
                    BEGIN
                        SET @av_ret_code = 'FAILURE!'
                        SET @av_ret_message = DBO.F_FRM_ERRMSG('[기간은 같은데 값이 틀릴 경우 조회]기초원장 (' + DBO.F_FRM_CODE_NM(@av_company_cd , @av_locale_cd, 'PAY_ITEM_CD', @av_pay_item_cd, GETDATE(),'1') + ') INSERT 시 에러발생 -' + @an_emp_id,
                                                @v_program_id,  0259,  @errormessage, @an_mod_user_id
                                            )
                        RETURN
                    END

            IF @v_retro_type != '3' AND @v_retro_chk_sta_ymd IS NOT NULL
            BEGIN
                EXECUTE P_PAY_MST_CHANGE_RETRO_PAY
                                    @av_company_cd       ,       -- 인사영역
                                    @av_locale_cd        ,       -- 언어
                                    @an_emp_id           ,       -- 사원id
                                    @av_pay_item_cd      ,       -- 급여항목기준코드
                                    @v_retro_chk_sta_ymd ,       -- 시작일자
                                    @ad_end_ymd          ,       -- 종료일자
                                    @an_pay_ymd_id       ,       -- 현재급여일자 ID(개인별소급급열일자 테이블에 넣을 급여 일자, 소급을 안 하면 NULL을 넘김)
                                    @av_salary_type_cd   ,       -- 대상자의 급여유형
                                    @v_day_retro_yn      ,       -- 일할계산 지급율 관리에 등록된 일할계산 종류일 경우 Y, 아니면 N
                                    @v_retro_type       ,        -- 소급 유형 [1 :모든 지급유형 소급, 2 : 같은 지급유형만 소급, 3: 소급 없음]
                                    @av_pay_type_cd      ,       -- 지급유형
                                    @av_tz_cd            ,
                                    @an_mod_user_id      ,       -- 변경자 사원id
                                    @av_ret_code         ,       -- SUCCESS!/FAILURE!
                                    @av_ret_message              -- 결과메시지


                IF @av_ret_code = 'FAILURE!'
                        RETURN
            END --IF @v_retro_type != '3' AND v_retro_chk_sta_ymd IS NOT NULL

    -- ***********************************************************
    -- 작업 완료
    -- ***********************************************************
    SET @av_ret_code   = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('프로시져 실행 완료..', @v_program_id,  0900,  null, @an_mod_user_id)


END
GO

IF NOT EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'MS_SSMA_SOURCE' , N'SCHEMA',N'dbo', N'PROCEDURE',N'P_PAY_MST_CHANGE_INSERT', NULL,NULL))
	EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'H551.P_PAY_MST_CHANGE_INSERT' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'P_PAY_MST_CHANGE_INSERT'
ELSE
BEGIN
	EXEC sys.sp_updateextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'H551.P_PAY_MST_CHANGE_INSERT' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'P_PAY_MST_CHANGE_INSERT'
END
GO



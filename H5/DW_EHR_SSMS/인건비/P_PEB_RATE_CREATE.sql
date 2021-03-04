SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_PEB_RATE_CREATE]
		@av_company_cd      NVARCHAR(10),
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- 타임존코드
    @an_mod_user_id     NUMERIC(18,0)  ,    -- 변경자 ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 인건비계획 인상율 기본 생성
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 이동현
    --<DOCLINE>   PROGRAM_ID  : P_PEB_RATE_CREATE
    --<DOCLINE>   ARGUMENT    : P_PEB_RATE_CREATE('01', 'KO', 'KST', 11 )
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획 기준관리 저장 후 인상율관리 기본생성
    --<DOCLINE>                 - 인상율관리에 기본값이 없을 경우 생성
    --<DOCLINE>   HISTORY     : 작성 이동현 2013.12.10
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @CD				NVARCHAR(50)
	  , @PEB_BASE_ID	NUMERIC
	  , @myCd			NVARCHAR(50)

	/** 인상율이 없는 기준관리 조회 **/
	DECLARE CUR_LIST CURSOR LOCAL FOR
		SELECT PEB_BASE_ID
	      FROM PEB_BASE
		 WHERE PEB_BASE_ID NOT IN ( SELECT DISTINCT PEB_BASE_ID
									  FROM PEB_RATE )

	/** 인건비 구분 공통코드 **/
	DECLARE CUR_CODE CURSOR LOCAL FOR
		SELECT CD
			FROM FRM_CODE
			WHERE CD_KIND = 'PEB_RATE_TYPE_CD'
			AND COMPANY_CD = @av_company_cd
			AND LOCALE_CD = @av_locale_cd
			AND GROUP_USE_YN = 'Y'
			AND dbo.XF_SYSDATE(0) BETWEEN STA_YMD AND END_YMD

    SET @v_program_id   = 'P_PEB_RATE_CREATE'
    SET @v_program_nm   = '인건비계획 인상율 기본 생성'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
	OPEN CUR_LIST
	FETCH NEXT FROM CUR_LIST INTO @PEB_BASE_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> 인상율 기본 생성
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			OPEN CUR_CODE 
			FETCH NEXT FROM CUR_CODE INTO @CD
			--set @myCd = isnull(@CD,':') + @av_company_cd + @av_locale_cd + dbo.XF_TO_CHAR_N( @@FETCH_STATUS, default)
			--<DOCLINE> 인건비 구분 공통코드 조회 후 생성
			WHILE(@@FETCH_STATUS = 0)
				BEGIN Try
					INSERT INTO PEB_RATE( PEB_RATE_ID    -- 인건비인상율관리ID
                                        , PEB_BASE_ID    -- 인건비계획기준ID
                                        , PEB_TYPE_CD    -- 인건비구분
                                        , PEB_RATE       -- 인상율
                                        --, ETC_CD1        -- 기타1
                                        --, ETC_CD2        -- 기타2
                                        , NOTE           -- 비고
                                        , MOD_USER_ID    -- 변경자
                                        , MOD_DATE       -- 변경일시
                                        , TZ_CD          -- 타임존코드
                                        , TZ_DATE        -- 타임존일시
                                 ) VALUES (
                                        NEXT VALUE FOR S_PEB_SEQUENCE
                                        , @PEB_BASE_ID    -- 인건비계획기준ID
                                        , @CD        -- 인건비구분
                                        , 0                 -- 인상율
                                        --, NULL
                                        --, NULL
                                        , NULL
                                        , @an_mod_user_id
                                        , dbo.XF_SYSDATE(0)
                                        , @av_tz_cd
                                        , dbo.XF_SYSDATE(0)
									)
					IF @@ERROR <> 0
						BEGIN
							SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 인상율 INSERT 에러[ERR]',
													@v_program_id,  0150,  null, null
												)
							SET @av_ret_code    = 'FAILURE!'
							RETURN
						END
					FETCH NEXT FROM CUR_CODE INTO @CD
				END Try
				BEGIN Catch
							SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 인상율 INSERT 에러[ERR]' + ERROR_MESSAGE(),
													@v_program_id,  0150,  null, null
												)
							SET @av_ret_code    = 'FAILURE!'
							RETURN
				END CATCH
			CLOSE CUR_CODE
			--DEALLOCATE CUR_CODE

			FETCH NEXT FROM CUR_LIST INTO @PEB_BASE_ID
		END
	CLOSE CUR_LIST
	DEALLOCATE CUR_LIST
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END

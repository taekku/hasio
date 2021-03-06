SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_INT0003_COPY_SYNC]  (
	@av_base_company_cd     nvarchar(50), --복사 기준이 되는 현재 소속 계열사 
	@av_table_name			nvarchar(50), -- 복사할 Table
	@av_target_companys		nvarchar(4000),  -- 복사Target회사
	@an_mod_user_id         NUMERIC(38,0),	--복사한 유저
   	@av_ret_code			nvarchar(400)/* 결과코드*/  OUTPUT,
   	@av_ret_message		    nvarchar(4000)/* 결과메시지*/  OUTPUT
)
AS 
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 연말정산 법정공제율기준을 복사함
    --<DOCLINE>   PROJECT     : 동원 인사시스템 구축 
    --<DOCLINE>   AUTHOR      : 오상진
    --<DOCLINE>   PROGRAM_ID  : P_INT0003_COPY_SYNC
    --<DOCLINE>   ARGUMENT    :
    --<DOCLINE>   RETURN      : 결과코드 : SUCCESS! :
    --<DOCLINE>                           FAILURE! :
    --<DOCLINE>                 결과메시지
    --<DOCLINE>   COMMENT     : 
    --<DOCLINE>   HISTORY     : 2020.12.10   오상진 작성 
    --<DOCLINE> ***************************************************************************
BEGIN
	
	
	DECLARE 
		@v_program_id	NVARCHAR(30),
		@v_program_nm   NVARCHAR(100)  
	
    /* 기본변수 초기값 세팅 */
    SET @av_ret_code     = 'SUCCESS!'
    SET @v_program_id    = 'P_FRM_CODE_COPY_SYNC'
    SET @v_program_nm    = '연말정산 법정공제율기준을 복사함'
    SET @av_ret_message  = DBO.F_FRM_ERRMSG('프로시저 실행 시작..', @v_program_id, 0000, null, null);
  
    /*DATA INSERT 시 사용할 변수 */
	IF @av_target_companys = ''
		set @av_target_companys = NULL
  
	IF @av_base_company_cd IS NOT NULL 
	BEGIN
		
		BEGIN TRY
			SELECT Items as COMPANY_CD
			  into #target
			  from dbo.fn_split_array(@av_target_companys, ',')
			IF @av_table_name = 'INT_Y08_WORK_REF'
			BEGIN
				DELETE A
				  FROM INT_Y08_WORK_REF A
				  JOIN #target B
				    ON A.COMPANY_CD = B.COMPANY_CD
				INSERT INTO INT_Y08_WORK_REF(
						WORK_REF_ID, --	세액공제율ID
						COMPANY_CD, --	인사영역
						STA_YMD, --	시작일자
						END_YMD, --	종료일자
						STA_AMT, --	시작액
						END_AMT, --	종료액
						BASE_AMT, --	공제기준금액
						OVER_AMT, --	초과기준금액
						REF_RATE, --	공제율
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_INT_SEQUENCE WORK_REF_ID, --	세액공제율ID
						B.COMPANY_CD, --	인사영역
						STA_YMD, --	시작일자
						END_YMD, --	종료일자
						STA_AMT, --	시작액
						END_AMT, --	종료액
						BASE_AMT, --	공제기준금액
						OVER_AMT, --	초과기준금액
						REF_RATE, --	공제율
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				  FROM INT_Y08_WORK_REF A
				  JOIN #target B ON (1=1)
				 WHERE A.COMPANY_CD = @av_base_company_cd
			END

			IF @av_table_name = 'INT_Y08_TAX_REF'
			BEGIN
				DELETE A
				  FROM INT_Y08_TAX_REF A
				  JOIN #target B
				    ON A.COMPANY_CD = B.COMPANY_CD
				INSERT INTO INT_Y08_TAX_REF(
					TAX_REF_ID, --	세액공제율ID
					COMPANY_CD, --	인사영역
					STA_YMD, --	시작일자
					END_YMD, --	종료일자
					STA_AMT, --	시작액
					END_AMT, --	종료액
					BASE_AMT, --	공제기준금액
					OVER_AMT, --	초과기준금액
					REF_RATE, --	공제율
					LIMIT_AMT, --	공제한도금액
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE  --	타임존일시
				)
				SELECT NEXT VALUE FOR S_INT_SEQUENCE TAX_REF_ID, --	세액공제율ID
					B.COMPANY_CD, --	인사영역
					STA_YMD, --	시작일자
					END_YMD, --	종료일자
					STA_AMT, --	시작액
					END_AMT, --	종료액
					BASE_AMT, --	공제기준금액
					OVER_AMT, --	초과기준금액
					REF_RATE, --	공제율
					LIMIT_AMT, --	공제한도금액
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE  --	타임존일시
				  FROM INT_Y08_TAX_REF A
				  JOIN #target B ON (1=1)
				 WHERE A.COMPANY_CD = @av_base_company_cd
			END

			IF @av_table_name = 'INT_Y14_TAX_REF_LIMIT'
			BEGIN
				DELETE A
				  FROM INT_Y14_TAX_REF_LIMIT A
				  JOIN #target B
				    ON A.COMPANY_CD = B.COMPANY_CD
				INSERT INTO INT_Y14_TAX_REF_LIMIT(
					TAX_REF_LIMIT_ID,--	근로소득세액공제한도ID
					COMPANY_CD,--	인사영역
					STA_YMD,--	시작일자
					END_YMD,--	종료일자
					STA_AMT,--	시작액
					END_AMT,--	종료액
					BASE_AMT,--	공제기준금액
					OVER_AMT,--	초과기준금액
					MIN_LIMIT_AMT,--	최소한도금액
					MOD_USER_ID,--	변경자
					MOD_DATE,--	변경일
					REF_RATE --	
				)
				SELECT NEXT VALUE FOR S_INT_SEQUENCE TAX_REF_LIMIT_ID,--	근로소득세액공제한도ID
					B.COMPANY_CD,--	인사영역
					STA_YMD,--	시작일자
					END_YMD,--	종료일자
					STA_AMT,--	시작액
					END_AMT,--	종료액
					BASE_AMT,--	공제기준금액
					OVER_AMT,--	초과기준금액
					MIN_LIMIT_AMT,--	최소한도금액
					MOD_USER_ID,--	변경자
					MOD_DATE,--	변경일
					REF_RATE --	
				  FROM INT_Y14_TAX_REF_LIMIT A
				  JOIN #target B ON (1=1)
				 WHERE A.COMPANY_CD = @av_base_company_cd
			END

			IF @av_table_name = 'INT_Y08_TAX_RATE'
			BEGIN
				DELETE A
				  FROM INT_Y08_TAX_RATE A
				  JOIN #target B
				    ON A.COMPANY_CD = B.COMPANY_CD
				INSERT INTO INT_Y08_TAX_RATE(
					TAX_RATE_ID, -- 세율관리ID
					COMPANY_CD, -- 인사영역
					STA_AMT, -- 시작액
					END_AMT, -- 종료액
					TAX_RATE, -- 세율
					REF_AMT, -- 공제액
					NOTE, -- 비고
					STA_YMD, -- 시작일자
					END_YMD, -- 종료일자
					MOD_USER_ID, -- 변경자
					MOD_DATE, -- 변경일
					TZ_CD, -- 타임존코드
					TZ_DATE  -- 타임존일시
				)
				SELECT NEXT VALUE FOR S_INT_SEQUENCE TAX_RATE_ID, -- 세율관리ID
					B.COMPANY_CD, -- 인사영역
					STA_AMT, -- 시작액
					END_AMT, -- 종료액
					TAX_RATE, -- 세율
					REF_AMT, -- 공제액
					NOTE, -- 비고
					STA_YMD, -- 시작일자
					END_YMD, -- 종료일자
					MOD_USER_ID, -- 변경자
					MOD_DATE, -- 변경일
					TZ_CD, -- 타임존코드
					TZ_DATE  -- 타임존일시
				  FROM INT_Y08_TAX_RATE A
				  JOIN #target B ON (1=1)
				 WHERE A.COMPANY_CD = @av_base_company_cd
			END
		END TRY 
		BEGIN CATCH 
			SET @av_ret_code  = 'FAILURE!'
			SET @av_ret_message = DBO.F_FRM_ERRMSG('연말정산법정공제율 복사중 오류!', @v_program_id, 0040, ERROR_MESSAGE(), NULL)
			RETURN;
		END CATCH
	END --IF @av_base_company_cd IS NOT NULL 
	
	ELSE 
		BEGIN
			SET @av_ret_code  = 'FAILURE!'
			SET @av_ret_message = DBO.F_FRM_ERRMSG('기준 계열사코드값이 없습니다.', @v_program_id, 0040, ERROR_MESSAGE(), NULL)
			RETURN;
		END
	
	
	
	
	/*
	*    ***********************************************************
	*    작업 완료
	*    ***********************************************************
	*/
	SET @av_ret_code = 'SUCCESS!'
	SET @av_ret_message = dbo.F_FRM_ERRMSG(
								'프로시져 실행 완료.[ERR]', 
								@v_program_id, 
								0235, 
								NULL, 
								1)

END
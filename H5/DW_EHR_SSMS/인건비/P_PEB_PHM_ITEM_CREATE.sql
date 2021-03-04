SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER   PROCEDURE [dbo].[P_PEB_PHM_ITEM_CREATE]
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
    --<DOCLINE>   TITLE       : 인건비계획 인건비제수당 생성
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : 임택구
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PHM_ITEM_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 결과 메시지
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 인건비계획 인건비제수당 생성
    --<DOCLINE>   HISTORY     : 작성 임택구 2020.09.14
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	  , @v_pay_ym		NVARCHAR(10) -- 급여년월
	  , @PEB_PHM_MST_ID	NUMERIC
		, @STD_YMD DATE -- 기준일자
		, @STA_YMD DATE -- 적용시작일
		, @END_YMD DATE -- 적용종료일
		, @COMPANY_CD NVARCHAR(10)
		, @BASE_YYYY NVARCHAR(10)
		, @EMP_ID       NUMERIC

    SET @v_program_id   = 'P_PEB_PHM_ITEM_CREATE'
    SET @v_program_nm   = '인건비계획 인건비제수당 생성'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
  -- 기존자료 삭제
	DELETE FROM PEB_PHM_ITEM
		FROM PEB_PHM_ITEM A
		JOIN PEB_PHM_MST MST
		  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id
	SELECT @BASE_YYYY = BASE_YYYY
	     , @COMPANY_CD = COMPANY_CD
			 , @STD_YMD = STD_YMD
			 , @STA_YMD = STA_YMD
			 , @END_YMD = END_YMD
			 , @v_pay_ym = dbo.XF_TO_CHAR_D(@ad_base_ymd, 'yyyyMM')
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id
	/** 인건비계획 대상명단 **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID, EMP.EMP_ID
			FROM PEB_PHM_MST MST
			LEFT OUTER JOIN PHM_EMP EMP
			  ON EMP.COMPANY_CD = @COMPANY_CD
			 AND MST.EMP_NO = EMP.EMP_NO
			 AND MST.PEB_BASE_ID = @an_peb_base_id
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @EMP_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> 인건비 복지포인트 생성
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				-- 급여실적에서 제수당항목을 생성
				INSERT INTO PEB_PHM_ITEM(
						PEB_PHM_ITEM_ID, --	인건비제수당ID
						PEB_PHM_MST_ID, --	인건비계획대상자ID
						PAY_ITEM_CD, --	급여항목코드
						BASE_AMT, --	기준금액
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
						@PEB_PHM_MST_ID	PEB_PHM_MST_ID, --	인건비계획대상자ID
						B.PAY_ITEM_CD, --	급여항목코드 
						sum(B.CAL_MON) AS	BASE_AMT, --	기준금액
						'실적-' + @v_pay_ym as	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
						--A.EMP_ID, B.PAY_ITEM_CD, B.CAL_MON
					FROM PAY_PAYROLL A
					JOIN PAY_PAYROLL_DETAIL B
						ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID
					JOIN PAY_PAY_YMD P
					 ON A.PAY_YMD_ID = P.PAY_YMD_ID
					JOIN (SELECT HIS.KEY_CD2 AS PAY_ITEM_CD
										 --, DBO.F_FRM_CODE_NM('E', 'KO', 'PAY_ITEM_CD', HIS.KEY_CD2, GETDATE(), '1') AS CD_NM
										 , HIS.KEY_CD1 PAY_GROUP_CD
									FROM FRM_UNIT_STD_MGR MGR
											 INNER JOIN FRM_UNIT_STD_HIS HIS
															 ON MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
															AND MGR.UNIT_CD = 'PEB'
															AND MGR.STD_KIND = 'PEB_ETC_SUPPLY'
								 WHERE MGR.COMPANY_CD = @COMPANY_CD
									 AND MGR.LOCALE_CD = @av_locale_cd
									 AND GETDATE() BETWEEN HIS.STA_YMD AND HIS.END_YMD) B_ITEM
						ON B.PAY_ITEM_CD = B_ITEM.PAY_ITEM_CD
					 AND A.PAY_GROUP_CD = B_ITEM.PAY_GROUP_CD
				 WHERE P.COMPANY_CD = @COMPANY_CD
					 AND PAY_YM = @v_pay_ym
					 AND P.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE
											WHERE COMPANY_CD=@COMPANY_CD
											AND CD_KIND='PAY_TYPE_CD'
											AND SYS_CD !='100')
					 AND P.CLOSE_YN = 'Y'
					 AND P.PAY_YN = 'Y'
					 AND A.EMP_ID = @EMP_ID
				 group by B.PAY_ITEM_CD
				-- 직책수당( BP017 )
				--INSERT INTO PEB_PHM_ITEM(
				--		PEB_PHM_ITEM_ID, --	인건비제수당ID
				--		PEB_PHM_MST_ID, --	인건비계획대상자ID
				--		PAY_ITEM_CD, --	급여항목코드
				--		BASE_AMT, --	기준금액
				--		NOTE, --	비고
				--		MOD_USER_ID, --	변경자
				--		MOD_DATE, --	변경일
				--		TZ_CD, --	타임존코드
				--		TZ_DATE --	타임존일시
				--)
				--SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
				--		@PEB_PHM_MST_ID	PEB_PHM_MST_ID, --	인건비계획대상자ID
				--		'BP017'	PAY_ITEM_CD, --	급여항목코드 
				--		dbo.F_FRM_UNIT_STD_VALUE (@COMPANY_CD, @av_locale_cd, 'PEB', 'PEB_BASE_DUTY',
    --                          NULL, NULL, NULL, NULL, NULL,
    --                          A.DUTY_CD, NULL, NULL, NULL, NULL,
    --                          getdATE(),
    --                          'H1' -- 'H1' : 코드1,     'H2' : 코드2,     'H3' :  코드3,     'H4' : 코드4,     'H5' : 코드5
				--														-- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
    --                          ) AS	BASE_AMT, --	기준금액
				--		'기준-' + ISNULL(dbo.F_FRM_CODE_NM(@COMPANY_CD, @av_locale_cd, 'PHM_DUTY_CD', A.DUTY_CD, @ad_base_ymd, '1'),'') as	NOTE, --	비고
				--		@an_mod_user_id	MOD_USER_ID, --	변경자
				--		SYSDATETIME()	MOD_DATE, --	변경일
				--		@av_tz_cd	TZ_CD, --	타임존코드
				--		SYSDATETIME()	TZ_DATE --	타임존일시
				--  FROM PEB_PHM_MST A
				-- WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				--   AND dbo.F_FRM_UNIT_STD_VALUE (@COMPANY_CD, @av_locale_cd, 'PEB', 'PEB_BASE_DUTY',
    --                          NULL, NULL, NULL, NULL, NULL,
    --                          A.DUTY_CD, NULL, NULL, NULL, NULL,
    --                          getdATE(),
    --                          'H1' -- 'H1' : 코드1,     'H2' : 코드2,     'H3' :  코드3,     'H4' : 코드4,     'H5' : 코드5
				--														-- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
    --                          ) IS NOT NULL -- 직책에 대한 기준금액이 있는 경우
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '인건비 복지포인트 INSERT 에러[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @EMP_ID
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END
GO

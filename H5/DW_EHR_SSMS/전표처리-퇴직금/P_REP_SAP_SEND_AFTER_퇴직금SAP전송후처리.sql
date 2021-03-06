SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER  PROCEDURE [dbo].[P_REP_SAP_SEND_AFTER]
   @av_company_cd nvarchar(max)/* 회사코드*/,
   @av_locale_cd nvarchar(max)/* 지역코드*/,
   @an_rep_calc_list_id numeric(38)/* 퇴직금대상ID */,
   @an_mod_user_id numeric(38)/* 변경자ID*/,
   @av_ret_code nvarchar(max)/* 결과코드*/  OUTPUT,
   @av_ret_message nvarchar(max)/* 결과메시지*/  OUTPUT
AS 
   BEGIN
      SET @av_ret_code = NULL
      SET @av_ret_message = NULL
      /*
      *   <DOCLINE> ***************************************************************************
      *   <DOCLINE>   TITLE       : 퇴직금 SAP전송후 후처리
      *   <DOCLINE>   PROJECT     : H5 5.0

      *   <DOCLINE>   AUTHOR      :
      *   <DOCLINE>   PROGRAM_ID  : P_REP_SAP_SEND_AFTER
      *   <DOCLINE>   ARGUMENT    :
      *   <DOCLINE>   RETURN      : 결과코드   : av_ret_code    SUCCESS!       / FAILURE!
      *   <DOCLINE>                 결과메시지 : av_ret_message null, 알림내용 / 오류메세지
      *   <DOCLINE>   COMMENT     :
      *   <DOCLINE>   HISTORY     :
      *   <DOCLINE> ***************************************************************************
      *    기본 변수
      */
      DECLARE
         @v_program_id nvarchar(30), 
         @v_program_nm nvarchar(100), 
		 @v_ins_type_cd nvarchar(10),
		 @v_chg_ins_type_yn nvarchar(10),
		 @v_rep_mid_yn nvarchar(10),
		 @d_c1_end_ymd date,
		 @n_emp_id	numeric(38,0)

      /*<DOCLINE> 기본변수 초기값 셋팅*/
      SET @v_program_id = 'P_REP_SAP_SEND_AFTER' /* 현재 프로시져의 영문명*/
      SET @v_program_nm = 'SAP 전송후 후처리' /* 현재 프로시져의 한글문명*/
      SET @av_ret_code = 'SUCCESS!'
      SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id, 0000, NULL, @an_mod_user_id)


      /*
      *   <DOCLINE> ***************************************************************************
      *   <DOCLINE> 배열에 값을 Setting
      *   <DOCLINE> ***************************************************************************
      */
	  SELECT @v_ins_type_cd = INS_TYPE_CD -- 퇴직연금종류
	       , @v_chg_ins_type_yn = CHG_INS_TYPE_YN -- 제도전환여부
		   , @v_rep_mid_yn = REP_MID_YN -- 중간정산여부
		   , @d_c1_end_ymd = C1_END_YMD -- 퇴직일
		   , @n_emp_id = EMP_ID
	    FROM REP_CALC_LIST 
	   WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id
	 
	  IF @@ROWCOUNT < 1
		BEGIN
                    SET @av_ret_code    = 'FAILURE!'   
                    SET @av_ret_message = dbo.F_FRM_ERRMSG('퇴직금내역이 없습니다.[ERR]' + ERROR_MESSAGE(), @v_program_id, 0040, null, @an_mod_user_id)   
                    RETURN
        END
	BEGIN TRY
	  IF @v_chg_ins_type_yn = 'Y' -- 제도전환인경우
		BEGIN
			UPDATE A
			   SET END_YMD = @d_c1_end_ymd
			     , MOD_USER_ID = @an_mod_user_id
				 , MOD_DATE = SYSDATETIME()
				 , TZ_CD = 'KST'
				 , TZ_DATE = SYSDATETIME()
			  FROM REP_INSUR_MON A
			 WHERE EMP_ID = @n_emp_id
			   AND @d_c1_end_ymd BETWEEN STA_YMD AND END_YMD
			INSERT INTO REP_INSUR_MON(
				REP_INSUR_MON_ID, --	퇴직보험금ID
				EMP_ID, --	사원ID
				INS_TYPE_CD, --	퇴직연금구분
				MIX_YN, --	혼합형여부
				HEADE_YN, --	임원여부
				EMP_MON, --	사용자부담금
				BASE_MON, --	산출기준금액
				INSUR_NM, --	연금회사
				IRP_BANK_CD, --	연금은행코드[PAY_BANK_CD]
				IRP_ACCOUNT_NO, --	계좌번호
				INSUR_BIZ_NO, --	사업자번호
				RES_STA_YMD, --	DC형 적립시작일
				IRP_EXPIRATION_YMD, --	만료일자
				STA_YMD, --	시작일
				END_YMD, --	종료일
				NOTE, --	비고
				MOD_USER_ID, --	변경자
				MOD_DATE, --	변경일
				TZ_CD, --	타임존코드
				TZ_DATE --	타임존일시
			) SELECT NEXT VALUE FOR S_REP_SEQUENCE,
						EMP_ID, --	사원ID
						INS_TYPE_CD, --	퇴직연금구분
						'N' MIX_YN, --	혼합형여부
						ISNULL(OFFICERS_YN,'N')	HEADE_YN, --	임원여부
						0	EMP_MON, --	사용자부담금
						0	BASE_MON, --	산출기준금액
						NULL	INSUR_NM, --	연금회사
						NULL	IRP_BANK_CD, --	연금은행코드[PAY_BANK_CD]
						NULL	IRP_ACCOUNT_NO, --	계좌번호
						NULL INSUR_BIZ_NO, --	사업자번호
						DATEADD(DD, 1, @d_c1_end_ymd)	RES_STA_YMD, --	DC형 적립시작일
						'29991231'	IRP_EXPIRATION_YMD, --	만료일자
						DATEADD(DD, 1, @d_c1_end_ymd)	STA_YMD, --	시작일
						'29991231'	END_YMD, --	종료일
						'' NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						'KST'	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
			    FROM REP_CALC_LIST
			   WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id
		END
	  IF @v_rep_mid_yn = 'Y' -- 중간정산여부
		BEGIN
			UPDATE A
			   SET BASE_YMD = @d_c1_end_ymd
			     , MOD_USER_ID = @an_mod_user_id
				 , MOD_DATE = SYSDATETIME()
				 , TZ_CD = 'KST'
				 , TZ_DATE = SYSDATETIME()
			  FROM PHM_BASE_DAY A
			 WHERE A.EMP_ID = @n_emp_id
			   AND A.BASE_TYPE_CD = 'RETIRE_STD_YMD' -- 퇴직기산일
			   --AND @d_c1_end_ymd BETWEEN STA_YMD AND END_YMD
			IF @@ROWCOUNT < 1
				BEGIN
					INSERT INTO PHM_BASE_DAY(
						PHM_BASE_DAY_ID, --	기준일ID
						EMP_ID, --	사원ID
						PERSON_ID, --	개인ID
						BASE_TYPE_CD, --	기준일종류코드 [PHM_BASE_TYPE_CD]
						BASE_YMD, --	기준일자
						STA_YMD, --	시작일자
						END_YMD, --	종료일자
						NOTE, --	비고
						MOD_USER_ID, --	변경자
						MOD_DATE, --	변경일시
						TZ_CD, --	타임존코드
						TZ_DATE --	타임존일시
					) SELECT NEXT VALUE FOR S_PHM_SEQUECE, --	기준일ID
						EMP_ID, --	사원ID
						PERSON_ID, --	개인ID
						'RETIRE_STD_YMD'	BASE_TYPE_CD, --	기준일종류코드 [PHM_BASE_TYPE_CD]
						@d_c1_end_ymd BASE_YMD, --	기준일자
						''	STA_YMD, --	시작일자
						'29991231'	END_YMD, --	종료일자
						'' NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일시
						'KST'	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
					FROM PHM_EMP
					WHERE EMP_ID = @n_emp_id
				END
		END
	  
	END TRY
	BEGIN CATCH
                    SET @av_ret_code    = 'FAILURE!'   
                    SET @av_ret_message = dbo.F_FRM_ERRMSG('퇴직금 후처리중 오류발생했습니다.[ERR]' + ERROR_MESSAGE(), @v_program_id, 0040, null, @an_mod_user_id)
                    RETURN
	END CATCH
      /*
      *    ***********************************************************
      *    작업 완료
      *    ***********************************************************
      *    COMMIT;
      */
      SET @av_ret_code = 'SUCCESS!'

      SET @av_ret_message = dbo.F_FRM_ERRMSG(
         '저장완료[ERR]', 
         @v_program_id, 
         0900, 
         NULL, 
         @an_mod_user_id)

   END


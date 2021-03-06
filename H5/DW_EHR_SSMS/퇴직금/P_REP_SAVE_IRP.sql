USE [dwehrdev_H5]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_REP_SAVE_IRP]
   @av_company_cd nvarchar(max)/* 회사코드*/,
   @av_locale_cd nvarchar(max)/* 지역코드*/,
   @an_work_id numeric(38)/*작업ID*/,
   @an_mod_user_id numeric(38)/* 변경자ID*/,
   @av_ret_code nvarchar(max)/* 결과코드*/  OUTPUT,
   @av_ret_message nvarchar(max)/* 결과메시지*/  OUTPUT
AS 
   BEGIN
      SET @av_ret_code = NULL
      SET @av_ret_message = NULL
      /*
      *   <DOCLINE> ***************************************************************************
      *   <DOCLINE>   TITLE       : 퇴직연금자  IRP저장
      *   <DOCLINE>   PROJECT     : H5 5.0
      *   <DOCLINE>   AUTHOR      :
      *   <DOCLINE>   PROGRAM_ID  : P_REP_SAVE_IRP
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
         @v_title nvarchar(200) = NULL, 
         @v_contents nvarchar(4000) = NULL, 
         @v_from_emp_no nvarchar(20), 
         @v_from_emp_nm nvarchar(40), 
         @v_from_mail_id nvarchar(100), 
         @v_to_emp_no nvarchar(20), 
         @v_to_emp_nm nvarchar(40), 
         @v_to_mail_id nvarchar(100)

      /*<DOCLINE> 기본변수 초기값 셋팅*/
      SET @v_program_id = 'P_REP_SAVE_IRP' /* 현재 프로시져의 영문명*/
      SET @v_program_nm = '퇴직자 IRP' /* 현재 프로시져의 한글문명*/
      SET @av_ret_code = 'SUCCESS!'
      SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id, 0000, NULL, @an_mod_user_id)

      DECLARE
         @for_cur$WORK_ID numeric(38),
         @for_cur$TMP_LIST_ID numeric(38),
         @for_cur$EMP_ID numeric(38), 
         @for_cur$ETC nvarchar(max)

      DECLARE
          DB_IMPLICIT_CURSOR_FOR_for_cur CURSOR LOCAL FORWARD_ONLY FOR 
            SELECT B.WORK_ID, B.TMP_LIST_ID, B.EMP_ID, B.ETC
              FROM dbo.REP_CALC_LIST A
			  INNER JOIN dbo.REP_TMP_SAVE B
			          ON A.REP_CALC_LIST_ID = B.TMP_LIST_ID
             WHERE B.WORK_ID = @an_work_id

      OPEN DB_IMPLICIT_CURSOR_FOR_for_cur

      /*
      *   <DOCLINE> ***************************************************************************
      *   <DOCLINE> 배열에 값을 Setting
      *   <DOCLINE> ***************************************************************************
      */
      WHILE 1 = 1
         BEGIN
            FETCH DB_IMPLICIT_CURSOR_FOR_for_cur
                INTO @for_cur$WORK_ID, @for_cur$TMP_LIST_ID, @for_cur$EMP_ID, @for_cur$ETC
            IF @@FETCH_STATUS = -1
               BREAK

            /* IRP 저장 */
            BEGIN TRY
				INSERT INTO REP_INCOME_TAX(
					REP_INCOME_TAX_ID, -- 퇴직소득과세이연관리ID
					EMP_ID, --	사원ID
					WORK_YMD, --	정산일자
					REP_ANNUITY_BIZ_NM, --	퇴직연금사업자명
					REP_ANNUITY_BIZ_NO, --	사업장등록번호
					REP_BANK_CD, --	은행코드[PAY_BANK_CD]
					REP_ACCOUNT_NM, --	예금주
					REP_ACCOUNT_NO, --	계좌번호
					TRANS_ALLOWANCE_COURT, --	이전(이체)금액_법정 퇴직급여
					TRANS_ALLOWANCE_COURT_OTHER, --	이전(이체)금액_법정외 퇴직급여
					REP_TRANS_YMD, --	이전(이체)일
					EXPIRATION_DATE, --	만기일
					REP_DELAY_TAX_AMT, --	과세이연세액
					NOTE, --	비고
					MOD_USER_ID, --	변경자
					MOD_DATE, --	변경일
					TZ_CD, --	타임존코드
					TZ_DATE -- 	타임존일시
				)
				SELECT NEXT VALUE FOR S_REP_SEQUENCE as REP_INCOME_TAX_ID,
						A.EMP_ID, --	사원ID
						A.C1_END_YMD AS WORK_YMD, --	정산일자
						A.REP_ANNUITY_BIZ_NM AS REP_ANNUITY_BIZ_NM, --	퇴직연금사업자명
						A.REP_ANNUITY_BIZ_NO AS REP_ANNUITY_BIZ_NO, --	사업장등록번호
						INSUR.IRP_BANK_CD AS REP_BANK_CD, --	은행코드[PAY_BANK_CD]
						EMP.EMP_NM AS	REP_ACCOUNT_NM, --	예금주
						A.REP_ACCOUNT_NO AS	REP_ACCOUNT_NO, --	계좌번호
						A.TRANS_AMT AS	TRANS_ALLOWANCE_COURT, --	이전(이체)금액_법정 퇴직급여
						A.TRANS_OTHER_AMT AS	TRANS_ALLOWANCE_COURT_OTHER, --	이전(이체)금액_법정외 퇴직급여
						NULL	REP_TRANS_YMD, --	이전(이체)일
						NULL	EXPIRATION_DATE, --	만기일
						A.TRANS_INCOME_AMT	REP_DELAY_TAX_AMT, --	과세이연세액
						NULL	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						'KST'	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE -- 	타임존일시
				  FROM REP_CALC_LIST A
				  INNER JOIN VI_FRM_PHM_EMP EMP
				          ON A.EMP_ID = EMP.EMP_ID
						 AND EMP.LOCALE_CD = @av_locale_cd
				  LEFT OUTER JOIN REP_INSUR_MON INSUR
				               ON A.EMP_ID = INSUR.EMP_ID
							  AND A.C1_END_YMD BETWEEN INSUR.STA_YMD AND INSUR.END_YMD
				 WHERE REP_CALC_LIST_ID = @for_cur$TMP_LIST_ID
            END TRY
			BEGIN CATCH
				IF ERROR_NUMBER() = 2627
				BEGIN
					-- 2627 에러인 경우 처리
                    SET @av_ret_code    = 'FAILURE!'   
                    SET @av_ret_message = dbo.F_FRM_ERRMSG('REP.REP_IRP4[ERR]', @v_program_id, 0040, '중복키9090', @an_mod_user_id)   
                    RETURN
				END
				ELSE
				BEGIN
                    SET @av_ret_code    = 'FAILURE!'   
                    SET @av_ret_message = dbo.F_FRM_ERRMSG('REP.REP_IRP3[ERR]', @v_program_id, 0040, null, @an_mod_user_id)   
                    RETURN
				END
			 END CATCH

         END

      CLOSE DB_IMPLICIT_CURSOR_FOR_for_cur

      DEALLOCATE DB_IMPLICIT_CURSOR_FOR_for_cur

      
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

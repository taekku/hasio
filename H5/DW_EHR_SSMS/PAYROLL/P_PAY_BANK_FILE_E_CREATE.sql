SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_PAY_BANK_FILE_E_CREATE]  
   @av_company_cd		nvarchar(10), -- 회사코드
   @an_work_id			numeric(38), -- 작업Id
   @an_pay_ymd_id		NUMERIC(38)/* 급여일자ID*/,
   @ad_give_ymd			date, -- 지급일
   @an_mod_user_id		NUMERIC(38)/* 등록자 사원ID*/,
   @av_ret_code			NVARCHAR(4000)/* 결과코드*/  OUTPUT,
   @av_ret_message		NVARCHAR(4000)/* 결과메시지*/  OUTPUT
AS    
   /*
   *   <DOCLINE> ***************************************************************************
   *   <DOCLINE>   TITLE       : 급여 이체파일 생성
   *   <DOCLINE>   PROJECT     : 동원그룹
   *   <DOCLINE>   AUTHOR      : 임택구
   *   <DOCLINE>   PROGRAM_ID  : P_PAY_BANK_FILE_E_CREATE
   *   <DOCLINE>   ARGUMENT    : 바로 위 참조
   *   <DOCLINE>   RETURN      : 결과코드 : SUCCESS! :
   *   <DOCLINE>                            FAILURE! :
   *   <DOCLINE>                 결과메시지
   *   <DOCLINE>   COMMENT     : TEXT 다운로드용
   *   <DOCLINE>   HISTORY     : 작성 임택구 2021.01.15
   *   <DOCLINE> ***************************************************************************
   *    기본적으로 사용되는 변수
   */
BEGIN
    SET @av_ret_code = NULL  
    SET @av_ret_message = NULL  
    
    DECLARE
        @v_program_id NVARCHAR(30), 
        @v_program_nm NVARCHAR(100),
        @errornumber INT,
        @errormessage NVARCHAR(4000),
        @v_close_yn CHAR(1),
		@v_content_text	nvarchar(4000),
		@v_pay_type_cd	nvarchar(10),
		@v_pay_group	nvarchar(10),
		@v_company_name	nvarchar(100),
		@v_permit_no	nvarchar(100),
		@v_bank_no		nvarchar(100),
		@n_man_cnt		numeric(8),
		@v_in_bank_cd	nvarchar(3),
		@v_in_acct_no	nvarchar(15),
		@v_pre_reci_man nvarchar(100),
		@v_emp_no		nvarchar(10),
		@n_real_amt		numeric(11),
		@n_tot_real_amt	numeric(16) = 0,
        @n_seq			numeric(8) = 0

    /* 기본변수 초기값 셋팅*/
    SET @av_ret_code = 'SUCCESS!'
    SET @v_program_id = 'P_PAY_BANK_FILE_E_CREATE'/* 현재 프로시져의 영문명*/
    SET @v_program_nm = '급여 이체파일 생성'/* 현재 프로시져의 한글문명*/
    SET @av_ret_message = dbo.F_FRM_ERRMSG( '프로시져 실행 시작..', 
                                            @V_PROGRAM_ID, 
                                            0000, 
                                            NULL, 
                                            @AN_MOD_USER_ID)
    BEGIN
    
        /*승인여부 검증*/
        BEGIN TRY
          SELECT @v_close_yn = dbo.XF_NVL_C(YMD.CLOSE_YN,'')
		       , @v_pay_type_cd = YMD.PAY_TYPE_CD
			   , @v_pay_group = (SELECT PAY_GROUP FROM PAY_GROUP WHERE PAY_GROUP_ID = GRP.PAY_GROUP_ID)
			   , @n_man_cnt = (SELECT COUNT(*) FROM PAY_PAYROLL WHERE PAY_YMD_ID = YMD.PAY_YMD_ID AND REAL_AMT > 0)
            FROM PAY_PAY_YMD YMD
			JOIN PAY_GROUP_TYPE GRP
			  ON YMD.PAY_TYPE_CD = GRP.PAY_TYPE_CD
			 AND YMD.COMPANY_CD = GRP.COMPANY_CD
           WHERE YMD.PAY_YMD_ID = @an_pay_ymd_id
        END TRY
        BEGIN CATCH
            SET @errornumber   = ERROR_NUMBER()  
            SET @errormessage  = ERROR_MESSAGE()  

            SET @av_ret_code    = 'FAILURE!'  
            SET @av_ret_message = DBO.F_FRM_ERRMSG('급여내역 마감여부 조회시 에러.[ERR]' ,@v_program_id ,0005  ,@errormessage  ,@an_mod_user_id )  
            IF @@TRANCOUNT > 0  
               ROLLBACK WORK  
            RETURN 
        END CATCH
        
        IF @v_close_yn <> 'Y'
            BEGIN
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = dbo.F_FRM_ERRMSG('마감되지 않은 급여내역입니다.[ERR]',@v_program_id, 0006, NULL, @an_mod_user_id)

                IF @@TRANCOUNT > 0
                    ROLLBACK WORK 
                 RETURN
            END
      /*
      *   <DOCLINE> ****************************************************************************
      *   <DOCLINE> HEADER 생성
      *   <DOCLINE> ****************************************************************************
      */
        BEGIN
            BEGIN TRY
				SET @n_seq = 0
				SELECT @v_company_name = dbo.XF_RPAD('(주)동원엔터프라이즈', 34,' '),
					   @v_permit_no = dbo.XF_RPAD('21011463', 8,' '),
					   @v_bank_no = dbo.XF_RPAD('0262945', 7,' ')
				SELECT @v_content_text =
				       'GW93' +
					   '11' +
					   '00000000' +
					   '8' +
					   @v_permit_no +
					   dbo.XF_LPAD(dbo.XF_TO_CHAR_N(@n_man_cnt, NULL), 8, '0') +
					   @v_company_name +
					   SUBSTRING(dbo.XF_TO_CHAR_D(@ad_give_ymd,'yyyyMMdd'),3,6) +
					   @v_bank_no +
					   '                      '
				INSERT INTO PAY_BANK_FILE_E(
					WORK_ID,
					SEQ,
					CONTENT_TEXT,
					NOTE,
					MOD_USER_ID,
					MOD_DATE,
					TZ_CD,
					TZ_DATE
				)
				SELECT @an_work_id,
				       @n_seq,
					   @v_content_text,
					   '' NOTE,
					   @an_mod_user_id,
					   SYSDATETIME(),
					   'KST',
					   SYSDATETIME()
            END TRY
            BEGIN CATCH
                SET @errornumber = ERROR_NUMBER()
                SET @errormessage = ERROR_MESSAGE()

                BEGIN
                    SET @av_ret_code = 'FAILURE!'
                    SET @av_ret_message = dbo.F_FRM_ERRMSG('개인별은행이체파일 헤더 입력 에러[ERR]',@v_program_id, 0100, @errormessage, @an_mod_user_id)

                    IF @@TRANCOUNT > 0
                        ROLLBACK WORK 
                    RETURN
                END
            END CATCH
      END
      /*
      *   <DOCLINE> ****************************************************************************
      *   <DOCLINE> DETAIL 생성
      *   <DOCLINE> ****************************************************************************
      */
      BEGIN
		DECLARE PAY_CUR CURSOR READ_ONLY FOR
			SELECT ISNULL(dbo.F_PAY_ACC_NO(PAY.EMP_ID, @ad_give_ymd, YMD.ACCOUNT_TYPE_CD, '2'),'') AS IN_BANK_CD, -- 은행
				   ISNULL(REPLACE( dbo.F_FRM_DECRYPT_C( dbo.F_PAY_ACC_NO(PAY.EMP_ID, @ad_give_ymd, YMD.ACCOUNT_TYPE_CD, '1') ), '-', ''),'') AS IN_ACCT_NO,-- 계좌번호
                   PAY.REAL_AMT, -- 입금금액
				   ISNULL(dbo.F_PAY_ACC_NO(PAY.EMP_ID, @ad_give_ymd, YMD.ACCOUNT_TYPE_CD, '3'),'') AS PRE_RECI_MAN, -- 예금주
				   EMP.EMP_NO
            FROM PAY_PAY_YMD YMD
			INNER JOIN PAY_PAYROLL PAY
					ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
			INNER JOIN PHM_EMP EMP
					ON PAY.EMP_ID = EMP.EMP_ID
            WHERE YMD.PAY_YMD_ID = @an_pay_ymd_id
            AND PAY.REAL_AMT > 0
            AND YMD.CLOSE_YN = 'Y'
		OPEN PAY_CUR
		WHILE 1=1
          BEGIN TRY
				FETCH NEXT FROM PAY_CUR
			      INTO @v_in_bank_cd, @v_in_acct_no, @n_real_amt, @v_pre_reci_man, @v_emp_no
				IF @@FETCH_STATUS <> 0 BREAK
				SET @n_seq = @n_seq + 1
				SELECT @v_content_text =
				       'GW93' +
					   '22' +
					   dbo.XF_LPAD(@n_seq, 8, '0') +
					   dbo.XF_RPAD(@v_in_bank_cd, 3, ' ') +
					   '    ' +
					   dbo.XF_RPAD(@v_pre_reci_man, 16, ' ') +
					   dbo.XF_RPAD(@v_in_acct_no, 15, ' ') +
					   dbo.XF_LPAD(dbo.XF_TO_CHAR_N(@n_real_amt, NULL), 11, '0') +
					   'N' +
					   '             ' +
					   '                       '
				SET @n_tot_real_amt = @n_tot_real_amt + @n_real_amt
				INSERT INTO PAY_BANK_FILE_E(
					WORK_ID,
					SEQ,
					CONTENT_TEXT,
					NOTE,
					MOD_USER_ID,
					MOD_DATE,
					TZ_CD,
					TZ_DATE
				)
				SELECT @an_work_id,
				       @n_seq,
					   @v_content_text,
					   '' NOTE,
					   @an_mod_user_id,
					   SYSDATETIME(),
					   'KST',
					   SYSDATETIME()
          END TRY
          BEGIN CATCH
              SET @errornumber = ERROR_NUMBER()
              SET @errormessage = ERROR_MESSAGE()

              BEGIN
                  SET @av_ret_code = 'FAILURE!'
                  SET @av_ret_message = dbo.F_FRM_ERRMSG('개인별은행이체파일 디테일 입력 에러[ERR]',@v_program_id, 0200, @errormessage, @an_mod_user_id)

                  IF @@TRANCOUNT > 0
                      ROLLBACK WORK 
                  RETURN 
                   
              END
          END CATCH
		  
		CLOSE PAY_CUR
		DEALLOCATE PAY_CUR

				SET @n_seq = @n_seq + 1
				SELECT @v_content_text =
				       'GW93' +
					   '33' +
					   '99999999' +
					   '8' +
					   @v_permit_no +
					   dbo.XF_LPAD(dbo.XF_TO_CHAR_N(@n_man_cnt, NULL), 8, '0') +
					   dbo.XF_LPAD(dbo.XF_TO_CHAR_N(@n_man_cnt, NULL), 8, '0') +
					   dbo.XF_LPAD(dbo.XF_TO_CHAR_N(@n_tot_real_amt, NULL), 16, '0') +
					   '                                             '
				INSERT INTO PAY_BANK_FILE_E(
					WORK_ID,
					SEQ,
					CONTENT_TEXT,
					NOTE,
					MOD_USER_ID,
					MOD_DATE,
					TZ_CD,
					TZ_DATE
				)
				SELECT @an_work_id,
				       @n_seq,
					   @v_content_text,
					   '' NOTE,
					   @an_mod_user_id,
					   SYSDATETIME(),
					   'KST',
					   SYSDATETIME()
      END
      
      IF @n_seq = 0
        BEGIN
            SET @av_ret_code = 'FAILURE!'
            SET @av_ret_message = dbo.F_FRM_ERRMSG('생성된 데이터가 존재하지 않습니다.[ERR]',@v_program_id, 0450, NULL, @an_mod_user_id)

            IF @@TRANCOUNT > 0
                ROLLBACK WORK 
             RETURN 
        END
    -- ==============================================================================  
        -- 작업 완료  
        -- ==============================================================================  
        SET @av_ret_code = 'SUCCESS!'  
        SET @av_ret_message = DBO.F_FRM_ERRMSG('이체파일 생성을 완료하였습니다.[ERR]', @v_program_id, 0400, null, @an_mod_user_id)  
    END
END;
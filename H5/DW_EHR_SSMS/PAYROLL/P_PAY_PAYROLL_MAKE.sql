SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PAY_PAYROLL_MAKE](
    @av_company_cd           NVARCHAR(10),   -- 인사영역
    @av_locale_cd            NVARCHAR(10),   -- 지역코드
    @an_pay_ymd_id           numeric  ,    -- 급여일자ID
    @an_org_id               numeric,   -- 조직
    @an_emp_id               numeric  ,    -- 사원ID
    @an_mod_user_id          numeric  ,    -- 변경자 ID
    @av_ret_code             NVARCHAR(4000) OUTPUT,  -- 결과코드
    @av_ret_message          NVARCHAR(4000) OUTPUT   -- 결과메시지
)   AS

    -- ***************************************************************************
    --   TITLE       : 급여대상자선정
    --   PROJECT     : H5 5.7
    --   AUTHOR      :
    --   PROGRAM_ID  : P_PAY_PAYROLL_MAKE
    --   ARGUMENT    : 
    --   RETURN      : 결과코드 = SUCCESS!/FAILURE!
    --                 결과메시지
    --   COMMENT     : 매월 정기적으로 급여지급되는 대상자를 생성한다.
    --   HISTORY     : 작성 2011.03.03
    --                 수정 2011.05.20 KSY
    --                 MS-SQL 변환 : 2020.03.26 오상진    				   
    -- ***************************************************************************
    --  001 급여,    002 정기상여,    003 성과급,    004 퇴직당월급여

BEGIN
    /* 기본적으로 사용되는 변수 */
    DECLARE 
    	 @v_program_id        NVARCHAR(30)
        ,@v_program_nm        NVARCHAR(100)
        ,@d_pay_ymd           DATE               -- 급여일자
		,@v_pay_type_cd       NVARCHAR(10)       -- 급여지급유형코드
		,@v_pay_ym            NVARCHAR(8)        -- 급여적용년월
		,@d_std_ymd           DATE 
		,@d_sta_ymd           DATE 
		,@d_end_ymd           DATE
		,@v_salary_type_cd    NVARCHAR(10)       -- 급여유형
		,@v_close_type_cd     NVARCHAR(10)       --대상자생성
		,@d_retire_ymd        DATE               -- 퇴직일자
		,@n_cnt               NUMERIC(10)
		,@v_sub_company_cd    NVARCHAR(10)
		,@v_cam_type_cd       NVARCHAR(20)
		,@v_no_yealy_nm       NVARCHAR(4000)
		,@errornumber         NUMERIC
        ,@errormessage        NVARCHAR(4000)
        ,@an_emp_no			  NUMERIC
        ,@an_cnt_salary	      NUMERIC
        ,@an_emp_nm		      NVARCHAR(20)
        ,@av_strsum		      NVARCHAR(20)

	    /* 기본변수 초기값 셋팅 */
		SET @v_close_type_cd = 'PAY02';
	    SET @v_program_id    = 'P_PAY_PAYROLL_MAKE';       -- 현재 프로시져의 영문명
	    SET @v_program_nm    = '대상자생성';               -- 현재 프로시져의 한글문명
	    SET @v_no_yealy_nm = ' ';
	
	    SET @av_ret_code     = 'SUCCESS!';
	    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null, @an_mod_user_id );

	/****************************************************************************
    ** 급여마감 체크
    *****************************************************************************/
	BEGIN
		EXECUTE dbo.P_PAY_CLOSE_CHECK @an_pay_ymd_id, @v_close_type_cd, @av_locale_cd, @av_ret_code OUTPUT, @av_ret_message  OUTPUT
	
		IF @av_ret_code = 'FAILURE!'
            BEGIN
               SET @av_ret_code = 'FAILURE!';
               SET @av_ret_message = @av_ret_message;
               RETURN 
            END
	END
	

	
    
	/***********************************************************************************************************************************
    ** 급여대상자선정
    ***********************************************************************************************************************************/
    -- 급여일자 조회
	BEGIN
		SELECT @v_pay_type_cd = PAY_PAY_YMD.PAY_TYPE_CD,
			   @v_pay_ym	= PAY_PAY_YMD.PAY_YM,
			   @d_pay_ymd	= PAY_PAY_YMD.PAY_YMD, 
			   @d_std_ymd = PAY_PAY_YMD.STD_YMD,
			   @d_sta_ymd = PAY_PAY_YMD.STA_YMD,
			   @d_end_ymd = PAY_PAY_YMD.END_YMD
		  FROM dbo.PAY_PAY_YMD
		 WHERE PAY_PAY_YMD.PAY_YMD_ID = @an_pay_ymd_id
		
		IF @@ROWCOUNT < 1
			BEGIN
				SET @av_ret_code    = 'FAILURE!'
	            SET @av_ret_message = DBO.F_FRM_ERRMSG('급여일자가 없습니다.[ERR]',
	                                  @v_program_id,  0095,  null, null)
				RETURN	
			END
	END
	

	
    -- 급여지급유형이 조회
	BEGIN
		SELECT @n_cnt = COUNT(PAY_PAY_YMD_DTL.SALARY_TYPE_CD)
		  FROM PAY_PAY_YMD_DTL
		 WHERE PAY_PAY_YMD_DTL.PAY_YMD_ID = @an_pay_ymd_id
		 
		IF @@ROWCOUNT < 1
			BEGIN
				SET @av_ret_code    = 'FAILURE!'
		        SET @av_ret_message = DBO.F_FRM_ERRMSG('급여지급유형이 없습니다.[ERR]',
		                                  @v_program_id,  0112,  null, null)
			    RETURN	
			END
		
			
	END
	
	BEGIN 
		IF @n_cnt = 0
			BEGIN
				SET @av_ret_message = DBO.F_FRM_ERRMSG('[급여일자관리] 메뉴에서 해당 급여일자의 급여유형을 등록 하셔야만 합니다.',
                                 @v_program_id,  0100,  @errormessage, @an_mod_user_id )
	            SET @av_ret_code    = 'FAILURE!'
    	        RETURN
			END
	END
	
	

    ----------------------------------------
    -- 연봉내역이 없는직원
    ----------------------------------------
    DECLARE ilist CURSOR LOCAL FORWARD_ONLY FOR
		  SELECT A.EMP_ID,
		         A.EMP_NO,
		         A.EMP_NM, 
		         B.CNT_SALARY,
		         A.EMP_NM + '(' + A.EMP_NO + ')' AS STRSUM
	        FROM VI_FRM_PHM_EMP A
 LEFT OUTER JOIN VI_PAY_MASTER B ON A.EMP_ID = B.EMP_ID
           WHERE A.COMPANY_CD = @av_company_cd
	         AND A.LOCALE_CD = @av_locale_cd
	         AND A.IN_OFFI_YN = 'Y'
	         AND B.CNT_SALARY IS NULL
	         AND B.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
	                                    FROM PAY_PAY_YMD_DTL
	                                   WHERE PAY_YMD_ID = @an_pay_ymd_id)
								         AND (@an_emp_id IS NULL OR A.EMP_ID = @an_emp_id)
								         AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)
								         
		OPEN ilist
		
		FETCH NEXT FROM ilist INTO @an_emp_id, @an_emp_no, @an_emp_nm, @an_cnt_salary, @av_strsum
		
		SET @v_no_yealy_nm = @v_no_yealy_nm + @av_strsum
		
	CLOSE ilist
	DEALLOCATE ilist
	
--	BEGIN
--		IF @v_no_yealy_nm <> ' '
--			BEGIN
--				SET @av_ret_message = '코스트센터가 없는 사원 : ' + @v_no_yealy_nm;
--				SET @av_ret_code    = 'FAILURE!';
--				RETURN	
--			END
--	END
	
	
	--정기급여
	IF @v_pay_type_cd = '001' 
		--대상자 INSERT
       BEGIN TRY
            INSERT INTO PAY_PAYROLL (  -- 급여내역(대상자)
		                     PAY_PAYROLL_ID          ,  -- 급여내역ID
		                     PAY_YMD_ID              ,  -- 급여일자ID
		                     EMP_ID                  ,  -- 사원ID
		                     SUB_COMPANY_CD          ,  -- 서브회사
		                     SALARY_TYPE_CD          ,  -- 급여유형코드
		                     ORG_ID                  ,  -- 발령부서ID
		                     PAY_ORG_ID              ,  -- 급여부서ID
		                     POS_CD                  ,  -- 계정유형
		                     ACC_CD                  ,  -- 코스트센터
		                     BANK_CD                 ,  -- 은행코드
		                     ACCOUNT_NO              ,  -- 계좌번호
		                     POS_GRD_CD              ,  -- 급여직급
		                     DTM_TYPE                ,  -- 근태유형
		                     MOD_USER_ID             ,  -- 변경자
		                     MOD_DATE                ,  -- 변경일시
		                     TZ_CD                   ,  -- 타임존코드
		                     TZ_DATE                    -- 타임존일시
                     )
             		SELECT 
             			NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    				    T1.*
		             FROM (
		                     SELECT DISTINCT
		                            @an_pay_ymd_id AS PAY_YMD_ID,
		                            A.EMP_ID,
		                            B.COMPANY_CD,
		                            A.SALARY_TYPE_CD,
		                            ISNULL(B.ORG_ID, 99) AS ORG_ID,
		                            B.ORG_ID AS PAY_ORG_ID,
		                            A.ORG_ACC_CD,
		                            A.ACC_CD,
		                            Z.BANK_CD,
		                            Z.ACCOUNT_NO,
		                            A.PAY_POS_GRD_CD,
		                            A.DTM_TYPE,
		                            @an_mod_user_id AS mod_user_id,
		                            GETDATE() AS MOD_DATE,
		                            B.TZ_CD,
		                            GETDATE() AS TZ_DATE
		                       FROM VI_PAY_MASTER A
		           		 INNER JOIN PHM_EMP B ON A.EMP_ID = B.EMP_ID
                    LEFT OUTER JOIN (SELECT EMP_ID              ,     -- 사원ID
		                                   BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
		                                   ACCOUNT_NO               -- 계좌번호
		                              FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
		                             WHERE X.ACCOUNT_TYPE_CD  = Y.ACCOUNT_TYPE_CD
		                               AND Y.PAY_YMD_ID = @an_pay_ymd_id
		                               AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
		                            ) Z ON B.EMP_ID = Z.EMP_ID
		                INNER JOIN PAY_PAY_YMD C ON DBO.XF_NVL_D(B.RETIRE_YMD,'29991231') >= C.STA_YMD
			                 WHERE A.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
			                                             FROM PAY_PAY_YMD_DTL
			                                            WHERE PAY_YMD_ID = @an_pay_ymd_id)
			                  AND ((@an_emp_id IS NULL) OR (B.EMP_ID = @an_emp_id))
			                  AND (@an_org_id IS NULL OR B.ORG_ID = @an_org_id)
			                  AND B.COMPANY_CD = @av_company_cd
			                  AND A.ACC_CD IS NOT NULL
			                  -- AND B.IN_OFFI_YN ='Y'
			                  AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
			                  AND (A.STA_YMD BETWEEN C.STA_YMD AND C.END_YMD OR A.END_YMD BETWEEN C.STA_YMD AND C.END_YMD or (A.STA_YMD <= c.STA_YMD and A.END_YMD >= c.END_YMD))
			                  AND C.PAY_YMD_ID = @an_pay_ymd_id ) T1
		              
       END TRY
       
       BEGIN CATCH
       		SET @errornumber   = ERROR_NUMBER()
	        SET @errormessage  = ERROR_MESSAGE()
	
			SET @av_ret_code    = 'FAILURE!'
	        SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 입력시 오류발생[ERR]',
	                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
			IF @@TRANCOUNT > 0
	            ROLLBACK WORK
	        RETURN
       END CATCH
       
       
    --퇴직급여
	ELSE IF @v_pay_type_cd = '005'
		BEGIN TRY
	        INSERT INTO PAY_PAYROLL (  -- 급여내역(대상자)
                     PAY_PAYROLL_ID          ,  -- 급여내역ID
                     PAY_YMD_ID              ,  -- 급여일자ID
                     EMP_ID                  ,  -- 사원ID
                     SUB_COMPANY_CD          ,  -- 서브회사
                     SALARY_TYPE_CD          ,  -- 급여유형코드
                     ORG_ID                  ,  -- 발령부서ID
                     PAY_ORG_ID              ,  -- 급여부서ID
                     POS_CD                  ,  -- 계정유형
                     ACC_CD                  ,  -- 코스트센터
                     BANK_CD                 ,  -- 은행코드
                     ACCOUNT_NO              ,  -- 계좌번호
                     POS_GRD_CD              ,  -- 직급
                     DTM_TYPE                ,  -- 근태유형
                     MOD_USER_ID             ,  -- 변경자
                     MOD_DATE                ,  -- 변경일시
                     TZ_CD                   ,  -- 타임존코드
                     TZ_DATE                    -- 타임존일시
                     )
             SELECT NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, T1.*
               FROM (
                     SELECT DISTINCT
                            @an_pay_ymd_id AS PAY_YMD_ID,
                            A.EMP_ID,
                            B.COMPANY_CD,
                            A.SALARY_TYPE_CD,
                            B.ORG_ID,
                            B.ORG_ID PAY_ORG_ID,
                            A.ORG_ACC_CD,
                            A.ACC_CD,
                            Z.BANK_CD,
                            Z.ACCOUNT_NO,
                            A.PAY_POS_GRD_CD,
                            A.DTM_TYPE,
                            @an_mod_user_id AS MOD_USER_ID,
                            GETDATE() AS MOD_DATE,
                            B.TZ_CD,
                            GETDATE() AS TZ_DATE
                       FROM VI_PAY_MASTER A
                    INNER JOIN PHM_EMP B ON A.EMP_ID = B.EMP_ID
               LEFT OUTER JOIN (SELECT EMP_ID              ,     -- 사원ID
                                       BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
                                       ACCOUNT_NO               -- 계좌번호
                              FROM PAY_ACCOUNT X
                              INNER JOIN PAY_PAY_YMD Y ON X.ACCOUNT_TYPE_CD  = Y.ACCOUNT_TYPE_CD-- 급여계좌(Version3.1)
                             WHERE Y.PAY_YMD_ID = @an_pay_ymd_id
                               AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
                            ) Z ON B.EMP_ID = Z.EMP_ID
                   INNER JOIN PAY_PAY_YMD C ON B.RETIRE_YMD BETWEEN C.STA_YMD AND C.END_YMD
                WHERE A.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
                                             FROM PAY_PAY_YMD_DTL
                                            WHERE PAY_YMD_ID = @an_pay_ymd_id)
							                  AND ((@an_emp_id IS NULL) OR (B.EMP_ID = @an_emp_id))
							                  AND (@an_org_id IS NULL OR B.ORG_ID = @an_org_id)
							                  AND B.COMPANY_CD = @av_company_cd
							                  AND B.IN_OFFI_YN = 'N'
							                  AND B.EMP_ID NOT IN (SELECT EMP_ID 
							                  					     FROM PAY_PAYROLL 
							                  						WHERE PAY_YMD_ID = @an_pay_ymd_id)
							                  						  AND C.PAY_YMD_ID = @an_pay_ymd_id ) T1
              
		END TRY
	
		BEGIN CATCH
			SET @errornumber   = ERROR_NUMBER()
	        SET @errormessage  = ERROR_MESSAGE()
	
			SET @av_ret_code    = 'FAILURE!'
	        SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 입력시 오류발생[ERR]',
	                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0278,  null, null)
	                                  
			IF @@TRANCOUNT > 0
	            ROLLBACK WORK
	        RETURN
		END CATCH

	-- 정기상여
	ELSE IF @v_pay_type_cd = '002' 
		BEGIN TRY
			INSERT INTO PAY_PAYROLL (  -- 급여내역(대상자)
                     PAY_PAYROLL_ID          ,  -- 급여내역ID
                     PAY_YMD_ID              ,  -- 급여일자ID
                     EMP_ID                  ,  -- 사원ID
                     SUB_COMPANY_CD          ,  -- 서브회사
                     SALARY_TYPE_CD          ,  -- 급여유형코드
                     ORG_ID                  ,  -- 발령부서ID
                     PAY_ORG_ID              ,  -- 급여부서ID
                     POS_CD                  ,  -- 계정유형
                     ACC_CD                  ,  -- 코스트센터
                     BANK_CD                 ,  -- 은행코드
                     ACCOUNT_NO              ,  -- 계좌번호
                     POS_GRD_CD              ,  -- 직급
                     DTM_TYPE                ,  -- 근태유형
                     MOD_USER_ID             ,  -- 변경자
                     MOD_DATE                ,  -- 변경일시
                     TZ_CD                   ,  -- 타임존코드
                     TZ_DATE                    -- 타임존일시
                     )
             SELECT NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, T1.*
               FROM (
                     SELECT DISTINCT
                            @an_pay_ymd_id AS PAY_YMD_ID,
                            A.EMP_ID,
                            B.COMPANY_CD,
                            A.SALARY_TYPE_CD,
                            B.ORG_ID,
                            B.ORG_ID PAY_ORG_ID,
                            A.ORG_ACC_CD,
                            A.ACC_CD,
                            Z.BANK_CD,
                            Z.ACCOUNT_NO,
                            A.PAY_POS_GRD_CD,
                            A.DTM_TYPE,
                            @an_mod_user_id AS MOD_USER_ID,
                            GETDATE() AS MOD_DATE,
                            B.TZ_CD,
                            GETDATE() AS TZ_DATE
                       FROM VI_PAY_MASTER A
                 INNER JOIN PHM_EMP B ON A.EMP_ID = B.EMP_ID
            LEFT OUTER JOIN (SELECT EMP_ID              ,     -- 사원ID
                                   BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
                                   ACCOUNT_NO               -- 계좌번호
                              FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
                             WHERE X.ACCOUNT_TYPE_CD  = Y.ACCOUNT_TYPE_CD
                               AND Y.PAY_YMD_ID = @an_pay_ymd_id
                               AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
                            ) Z ON B.EMP_ID = Z.EMP_ID
                INNER JOIN PAY_PAY_YMD C ON C.PAY_YMD BETWEEN A.STA_YMD AND A.END_YMD
                WHERE A.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
                                             FROM PAY_PAY_YMD_DTL
                                            WHERE PAY_YMD_ID = @an_pay_ymd_id
                                              AND ISNULL(BONUS_RATE,0) > 0)
                  AND ((@an_emp_id IS NULL) OR (B.EMP_ID = @an_emp_id))
                  AND (@an_org_id IS NULL OR B.ORG_ID = @an_org_id)
                  AND B.COMPANY_CD = @av_company_cd
                  AND B.IN_OFFI_YN ='Y'
                  AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
                  AND B.HIRE_YMD <= C.PAY_YMD
                  AND C.PAY_YMD_ID = @an_pay_ymd_id ) T1
		END TRY
		
		BEGIN CATCH
			SET @errornumber   = ERROR_NUMBER()
	        SET @errormessage  = ERROR_MESSAGE()
	
			SET @av_ret_code    = 'FAILURE!'
	        SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 입력시 오류발생[ERR]',
	                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0420,  null, null)
	                                  
			IF @@TRANCOUNT > 0
	            ROLLBACK WORK
	        RETURN
		END CATCH
		
    -- 성과급
    ELSE IF @v_pay_type_cd = '003' 
    	--대상자 INSERT
    	BEGIN TRY
	    	INSERT INTO PAY_PAYROLL (  -- 급여내역(대상자)
                     PAY_PAYROLL_ID          ,  -- 급여내역ID
                     PAY_YMD_ID              ,  -- 급여일자ID
                     EMP_ID                  ,  -- 사원ID
                     SUB_COMPANY_CD          ,  -- 서브회사
                     SALARY_TYPE_CD          ,  -- 급여유형코드
                     ORG_ID                  ,  -- 발령부서ID
                     PAY_ORG_ID              ,  -- 급여부서ID
                     POS_CD                  ,  -- 계정유형
                     ACC_CD                  ,  -- 코스트센터
                     BANK_CD                 ,  -- 은행코드
                     ACCOUNT_NO              ,  -- 계좌번호
                     POS_GRD_CD              ,  -- 직급
                     DTM_TYPE                ,  -- 근태유형
                     MOD_USER_ID             ,  -- 변경자
                     MOD_DATE                ,  -- 변경일시
                     TZ_CD                   ,  -- 타임존코드
                     TZ_DATE                    -- 타임존일시
                     )
             SELECT NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, T1.*
               FROM (
                     SELECT DISTINCT
                            @an_pay_ymd_id AS PAY_YMD_ID,
                            A.EMP_ID,
                            B.COMPANY_CD,
                            A.SALARY_TYPE_CD,
                            B.ORG_ID,
                            B.ORG_ID PAY_ORG_ID,
                            A.ORG_ACC_CD,
                            A.ACC_CD,
                            Z.BANK_CD,
                            Z.ACCOUNT_NO,
                            A.PAY_POS_GRD_CD,
                            A.DTM_TYPE,
                            @an_mod_user_id AS MOD_USER_ID,
                            GETDATE() AS MOD_DATE,
                            B.TZ_CD,
                            GETDATE() AS TZ_DATE
                       FROM VI_PAY_MASTER A 
                     INNER JOIN PHM_EMP B ON A.EMP_ID = B.EMP_ID
                LEFT OUTER JOIN (SELECT EMP_ID              ,     -- 사원ID
                                        BANK_CD             ,     -- 은행코드(PAY_BANK_CD)
                                        ACCOUNT_NO               -- 계좌번호
                                   FROM PAY_ACCOUNT X
                             INNER JOIN PAY_PAY_YMD Y ON X.ACCOUNT_TYPE_CD  = Y.ACCOUNT_TYPE_CD -- 급여계좌(Version3.1)
	                             WHERE Y.PAY_YMD_ID = @an_pay_ymd_id
	                               AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
	                            ) Z ON B.EMP_ID = Z.EMP_ID
                     INNER JOIN PAY_PAY_YMD C ON C.PAY_YMD BETWEEN A.STA_YMD AND A.END_YMD
                WHERE A.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
                                             FROM PAY_PAY_YMD_DTL
                                            WHERE PAY_YMD_ID = @an_pay_ymd_id)
                  AND ((@an_emp_id IS NULL) OR (B.EMP_ID = @an_emp_id))
                  AND (@an_org_id IS NULL OR B.ORG_ID = @an_org_id)
                  AND B.COMPANY_CD = @av_company_cd
                  AND B.IN_OFFI_YN ='Y'
                  AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
                  AND B.HIRE_YMD <= C.PAY_YMD
                  AND C.PAY_YMD_ID = @an_pay_ymd_id ) T1
    	END TRY
    	
    	BEGIN CATCH
	    	SET @errornumber   = ERROR_NUMBER()
	        SET @errormessage  = ERROR_MESSAGE()
	
			SET @av_ret_code    = 'FAILURE!'
	        SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 입력시 오류발생[ERR]',
	                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0498,  null, null)
	                                  
			IF @@TRANCOUNT > 0
	            ROLLBACK WORK
	        RETURN
    	END CATCH
		
    -- 연차수당
    ELSE IF @v_pay_type_cd = '004' 
    	--대상자 INSERT
    	BEGIN TRY 
    		INSERT INTO PAY_PAYROLL (  -- 급여내역(대상자)
                     PAY_PAYROLL_ID          ,  -- 급여내역ID
                     PAY_YMD_ID              ,  -- 급여일자ID
                     EMP_ID                  ,  -- 사원ID
                     SUB_COMPANY_CD          ,  -- 서브회사
                     SALARY_TYPE_CD          ,  -- 급여유형코드
                     ORG_ID                  ,  -- 발령부서ID
                     PAY_ORG_ID              ,  -- 급여부서ID
                     POS_CD                  ,  -- 계정유형
                     ACC_CD                  ,  -- 코스트센터
                     BANK_CD                 ,  -- 은행코드
                     ACCOUNT_NO              ,  -- 계좌번호
                     POS_GRD_CD              ,  -- 직급
                     DTM_TYPE                ,  -- 근태유형
                     MOD_USER_ID             ,  -- 변경자
                     MOD_DATE                ,  -- 변경일시
                     TZ_CD                   ,  -- 타임존코드
                     TZ_DATE                    -- 타임존일시
                     )
             SELECT NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID
                  , T1.*
               FROM (
                     SELECT DISTINCT
                            @an_pay_ymd_id AS PAY_YMD_ID,
                            A.EMP_ID,
                            B.COMPANY_CD,
                            A.SALARY_TYPE_CD,
                            B.ORG_ID,
                            B.ORG_ID PAY_ORG_ID,
                            A.ORG_ACC_CD,
                            A.ACC_CD,
                            Z.BANK_CD,
                            Z.ACCOUNT_NO,
                            A.PAY_POS_GRD_CD,
                            A.DTM_TYPE,
                            @an_mod_user_id AS MOD_USER_ID,
                            GETDATE() AS MOD_DATE,
                            B.TZ_CD,
                            GETDATE() AS TZ_DATE
                       FROM VI_PAY_MASTER A
                            INNER JOIN PHM_EMP B ON ( A.EMP_ID = B.EMP_ID )
                            LEFT OUTER JOIN (SELECT EMP_ID              ,     -- 사원ID
				                                   BANK_CD       ,     -- 은행코드(PAY_BANK_CD)
				                                   ACCOUNT_NO               -- 계좌번호
				                              FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- 급여계좌(Version3.1)
				                             WHERE X.ACCOUNT_TYPE_CD  = Y.ACCOUNT_TYPE_CD
				                               AND Y.PAY_YMD_ID = @an_pay_ymd_id
				                               AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
				                            ) Z ON B.EMP_ID = Z.EMP_ID
		                    INNER JOIN PAY_PAY_YMD C ON C.PAY_YMD BETWEEN A.STA_YMD AND A.END_YMD
		                    INNER JOIN VI_DTM_YY_REST_PAY D ON ( D.PAY_YM = C.PAY_YM 
		                  								     AND A.EMP_ID = D.EMP_ID )
	                WHERE A.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
	                                             FROM PAY_PAY_YMD_DTL
	                                            WHERE PAY_YMD_ID = @an_pay_ymd_id)
	                  AND ((@an_emp_id IS NULL) OR (B.EMP_ID = @an_emp_id))
	                  AND (@an_org_id IS NULL OR B.ORG_ID = @an_org_id)
	                  AND B.COMPANY_CD = @av_company_cd
	                  AND D.KIND = '10'  -- 급여연차보상자 대상
	                  AND ISNULL(D.PAY_YY_NUM,0) != 0
	                 -- AND B.IN_OFFI_YN ='Y'
	                  AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
	                  AND (A.STA_YMD BETWEEN C.STA_YMD AND C.END_YMD OR A.END_YMD BETWEEN C.STA_YMD AND C.END_YMD OR (A.STA_YMD <= C.STA_YMD AND A.END_YMD >= C.END_YMD))
	                  AND C.PAY_YMD_ID = @an_pay_ymd_id ) T1
    	END TRY 
    	
    	BEGIN CATCH
    		SET @errornumber   = ERROR_NUMBER()
	        SET @errormessage  = ERROR_MESSAGE()
	
			SET @av_ret_code    = 'FAILURE!'
	        SET @av_ret_message = DBO.F_FRM_ERRMSG(' 급여대상자 입력시 오류발생[ERR]',
	                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0581,  null, null)
	                                  
			IF @@TRANCOUNT > 0
	            ROLLBACK WORK
	        RETURN
    	END CATCH 
    	
    	
	-- 전체계좌조회하여 사원이 없는경우 신규로 생성한다.
	BEGIN TRY 
		INSERT INTO PAY_SAP_VENDOR(EMPNO           ,  -- 사번
                                   GUBUN           ,  -- 구분
                                   ACCOUNT_TYPE_CD ,  -- 계좌구분(01:급여 03:경비)
                                   IDATE           ,  -- 입력일자
                                   ITIME           ,  -- 입력시간
                                   ENAME           ,  -- 성명
                                   IDNUM           ,  -- 주민번호
                                   BANKN           ,  -- 은행코드
                                   ACCNT           ,  -- 계좌번호
                                   HOLDN           ,  -- 예금주
                                   FLAG               -- 진행여부
                                  )
                           SELECT A.EMP_NO,
                                  'N' ,
                                  B.ACCOUNT_TYPE_CD,
                                  DBO.XF_TO_CHAR_D(GETDATE(),'YYYYMMDD'),
                                  DBO.XF_TO_CHAR_D(GETDATE(),'HHMISS'),
                                  A.EMP_NM,
                                  A.CTZ_NO,
                                  B.BANK_CD    ,     -- 은행코드(PAY_BANK_CD)
                                  DBO.XF_REPLACE(B.ACCOUNT_NO,'-',''), -- 계좌번호 SAP 담당자[김태국대리]가 숫자만 넣어주세요..함 (2013.10.15 김동수대리 전화로확인함)
                                  DBO.XF_NVL_C(B.HOLDER_NM,A.EMP_NM) , -- 예금주
                                  'N'
                             FROM VI_FRM_PHM_EMP A
                           INNER JOIN PAY_ACCOUNT B ON ( A.EMP_ID = B.EMP_ID )
                            WHERE B.ACCOUNT_TYPE_CD = '01'  -- 급여계좌만 sap에 인터페이스함.
                              AND B.STA_YMD = (SELECT MAX(STA_YMD)
                                                 FROM PAY_ACCOUNT
                                                WHERE EMP_ID = B.EMP_ID
                 AND GETDATE() BETWEEN STA_YMD AND END_YMD)
                              AND A.EMP_NO NOT IN (SELECT EMPNO
                                                     FROM PAY_SAP_VENDOR)
                              AND COMPANY_CD = @av_company_cd
                              AND LOCALE_CD = @av_locale_cd
	END TRY 
	
	BEGIN CATCH
		SET @errornumber   = ERROR_NUMBER()
        SET @errormessage  = ERROR_MESSAGE()

		SET @av_ret_code    = 'FAILURE!'
        SET @av_ret_message = DBO.F_FRM_ERRMSG('사원VENDOR SAP전송 시 에러발생[ERR]',
                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  633,  null, null)
                                  
		IF @@TRANCOUNT > 0
            ROLLBACK WORK
        RETURN
	END CATCH
    	
    	
    	
-- ***********************************************************
    -- 작업 완료
    -- ***********************************************************
    SET @av_ret_code    = 'SUCCESS!';
    SET @av_ret_message  = DBO.F_FRM_ERRMSG('급여대상자 생성완료..',
                                     @v_program_id,  0900,  null, @an_mod_user_id
                                    );
    	
		
END -- 끝
GO

IF NOT EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'MS_SSMA_SOURCE' , N'SCHEMA',N'dbo', N'PROCEDURE',N'P_PAY_PAYROLL_MAKE', NULL,NULL))
	EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'H551.P_PAY_PAYROLL_MAKE' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'P_PAY_PAYROLL_MAKE'
ELSE
BEGIN
	EXEC sys.sp_updateextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'H551.P_PAY_PAYROLL_MAKE' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'P_PAY_PAYROLL_MAKE'
END
GO



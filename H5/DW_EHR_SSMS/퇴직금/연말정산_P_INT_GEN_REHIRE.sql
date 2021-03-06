SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER   PROCEDURE [dbo].[P_INT_GEN_REHIRE]
    @av_company_cd     NVARCHAR(10),			-- 회사코드
    @av_locale_cd      NVARCHAR(10),			-- 국가코드
	@av_ec_yy		   NVARCHAR(10),			-- 정산년도
	@an_org_id         NUMERIC(38),				-- 소속ID
    @an_emp_id         NUMERIC(38),				-- 사원ID
	@an_pay_group_id   NUMERIC(38),				-- 급여그룹
    @an_mod_user_id    NUMERIC(38),				-- 변경자
    @av_ret_code       NVARCHAR(50)  OUTPUT,	-- SUCCESS!/FAILURE!
    @av_ret_message    NVARCHAR(2000) OUTPUT    -- 결과메시지
 AS

    -- ***************************************************************************
    --   TITLE       : 연말정산재입사자생성
    --   PROJECT     :
    --   AUTHOR      :
    --   PROGRAM_ID  : P_INT_GEN_REHIRE
    --   RETURN      : 1) SUCCESS!/FAILURE!
    --                 2) 결과 메시지
    --   COMMENT     : 연말정산재입사자생성
    --   HISTORY     : 작성 임택구  2020.12.23
    -- ***************************************************************************
BEGIN

    DECLARE @v_program_id          NVARCHAR(30),	-- 프로그램ID
            @v_program_nm          NVARCHAR(100),	-- 프로그램명
			@d_last_year			DATE,	-- 년말일자
            @d_mod_date            DATETIME2(0) 	-- 수정일

    SET @v_program_id = 'P_INT_GEN_REHIRE';
    SET @v_program_nm = '연말정산재입사자생성';

    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)

    SET @d_mod_date = dbo.xf_sysdate(0)

   BEGIN TRY
		SET @d_last_year = @av_ec_yy + '1231'
	   ;WITH CTE AS (
			SELECT EMP.PERSON_ID
			  FROM PHM_EMP EMP
			 WHERE EMP.COMPANY_CD = @av_company_cd
			   AND EMP.HIRE_YMD <= @d_last_year
			   AND (EMP.RETIRE_YMD IS NULL OR FORMAT(EMP.RETIRE_YMD, 'yyyy') =  @av_ec_yy )
			 GROUP BY EMP.PERSON_ID
			 HAVING COUNT(*) > 1
		), CTE2 AS (
			SELECT CTE.PERSON_ID, EMP.EMP_ID, EMP.ORG_ID
				 , RANK() OVER(PARTITION BY CTE.PERSON_ID ORDER BY ISNULL(RETIRE_YMD, @d_last_year) DESC) AS R_RANK
			  FROM CTE
			  JOIN PHM_EMP EMP
				ON CTE.PERSON_ID = EMP.PERSON_ID
			 WHERE EMP.COMPANY_CD = @av_company_cd
			   AND EMP.HIRE_YMD <= @d_last_year
			   AND (EMP.RETIRE_YMD IS NULL OR FORMAT(EMP.RETIRE_YMD, 'yyyy') = @av_ec_yy)
		)
		SELECT CTE2.EMP_ID, --	사원ID
				CTE2.PERSON_ID --	개인ID
			INTO #TEMP
		  FROM CTE2
		 WHERE CTE2.R_RANK = 1
		   AND (@an_pay_group_id IS NULL OR dbo.F_PAY_GROUP_CHK(@an_pay_group_id, CTE2.EMP_ID, NULL) = @an_pay_group_id)
		   AND (@an_org_id IS NULL OR CTE2.ORG_ID = @an_org_id)
		   AND (@an_emp_id IS NULL OR CTE2.EMP_ID = @an_emp_id)
		   ;
		DELETE A
		  FROM INT_REHIRE A
		  JOIN #TEMP B
		    ON A.EC_YY = @av_ec_yy
		   AND A.COMPANY_CD = @av_company_cd
		   AND A.PERSON_ID = B.PERSON_ID

	   ;WITH CTE AS (
			SELECT EMP.PERSON_ID
			  FROM PHM_EMP EMP
			 WHERE EMP.COMPANY_CD = @av_company_cd
			   AND EMP.HIRE_YMD <= @d_last_year
			   AND (EMP.RETIRE_YMD IS NULL OR FORMAT(EMP.RETIRE_YMD, 'yyyy') =  @av_ec_yy )
			 GROUP BY EMP.PERSON_ID
			 HAVING COUNT(*) > 1
		), CTE2 AS (
			SELECT CTE.PERSON_ID, EMP.EMP_ID, EMP.ORG_ID
				 , RANK() OVER(PARTITION BY CTE.PERSON_ID ORDER BY ISNULL(RETIRE_YMD, @d_last_year) DESC) AS R_RANK
			  FROM CTE
			  JOIN PHM_EMP EMP
				ON CTE.PERSON_ID = EMP.PERSON_ID
			 WHERE EMP.COMPANY_CD = @av_company_cd
			   AND EMP.HIRE_YMD <= @d_last_year
			   AND (EMP.RETIRE_YMD IS NULL OR FORMAT(EMP.RETIRE_YMD, 'yyyy') = @av_ec_yy)
		)
		INSERT INTO dbo.INT_REHIRE(
				INT_REHIRE_ID, --	재입사자관리ID
				COMPANY_CD, --	회사코드
				EC_YY, --	정산년도
				EMP_ID, --	사원ID
				PERSON_ID, --	개인ID
				ORG_ID, --	조직ID
				SEQ, --	순번
				HIRE_YMD, --	입사일자
				RETIRE_YMD, --	퇴사일자
				TGT_YN, --	정산대상
				CNF_YN, --	계산확정
				NOTE, --	비고
				MOD_USER_ID, --	변경자
				MOD_DATE, --	변경일시
				TZ_CD, --	타임존코드
				TZ_DATE --	타임존일시
		)
		SELECT NEXT VALUE FOR S_INT_SEQUENCE INT_REHIRE_ID, --	재입사자관리ID
				@av_company_cd COMPANY_CD, --	회사코드
				@av_ec_yy, --	EC_YY, --	정산년도
				EMP.EMP_ID, --	사원ID
				EMP.PERSON_ID, --	개인ID
				EMP.ORG_ID, --	조직ID
				RANK() OVER(PARTITION BY EMP.PERSON_ID ORDER BY ISNULL(EMP.RETIRE_YMD, @d_last_year)) as SEQ, --	순번
				EMP.HIRE_YMD, --	입사일자
				EMP.RETIRE_YMD , --	퇴사일자
				'Y' TGT_YN, --	정산대상
				'N' CNF_YN, --	계산확정
				'' NOTE, --	비고
				@an_mod_user_id	MOD_USER_ID, --	변경자
				SYSDATETIME()	MOD_DATE, --	변경일시
				'KST'	TZ_CD, --	타임존코드
				SYSDATETIME()	TZ_DATE --	타임존일시
		  FROM CTE2
		  JOIN VI_FRM_PHM_EMP EMP
		    ON CTE2.PERSON_ID = EMP.PERSON_ID
		   AND EMP.COMPANY_CD = @av_company_cd
		   AND EMP.LOCALE_CD = @av_locale_cd
		   AND CTE2.R_RANK = 1
		   AND (@an_pay_group_id IS NULL OR dbo.F_PAY_GROUP_CHK(@an_pay_group_id, CTE2.EMP_ID, NULL) = @an_pay_group_id)
		 WHERE EMP.HIRE_YMD <= @d_last_year
		   AND (EMP.RETIRE_YMD IS NULL OR FORMAT(EMP.RETIRE_YMD, 'yyyy') =  @av_ec_yy )
		   AND (@an_org_id IS NULL OR CTE2.ORG_ID = @an_org_id)
		   AND (@an_emp_id IS NULL OR CTE2.EMP_ID = @an_emp_id)
   END TRY
   BEGIN CATCH
    SET @av_ret_code = 'FAILURE!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('실행중오류가 발생했습니다.[ERR]' + ERROR_MESSAGE(), @v_program_id, 0150, NULL, @an_mod_user_id)
	RETURN
   END CATCH

    /*
    *    ***********************************************************
    *    작업 완료
    *    ***********************************************************
    */
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 완료..[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)

END

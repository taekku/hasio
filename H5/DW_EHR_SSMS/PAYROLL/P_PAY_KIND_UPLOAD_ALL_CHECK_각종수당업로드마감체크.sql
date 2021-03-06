SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[P_PAY_KIND_UPLOAD_ALL_CHECK]
    @av_company_cd     NVARCHAR(10),            -- 
    @av_locale_cd      NVARCHAR(10),            -- 
    @an_reg_emp_id     NUMERIC(18,0),           -- 급여일자ID
    @an_mod_user_id    NUMERIC(18,0),           -- 변경자
    @av_ret_code       NVARCHAR(4000) OUTPUT,   -- 결과코드
    @av_ret_message    NVARCHAR(4000) OUTPUT    -- 결과메시지
AS 

   BEGIN      
   SET NOCOUNT ON
      /*
      *    ***************************************************************************
      *      TITLE       : 각종수당업로드 마감체크
      *      PROJECT     : HR시스템
      *      AUTHOR      : 
      *      PROGRAM_ID  : P_PAY_KIND_UPLOAD_ALL_CHECK
      *      RETURN      : 1) SUCCESS!/FAILURE!
      *                    2) 결과 메시지
      *      COMMENT     : - 급여기초작업을 생성한다.
      *      HISTORY     : 2021.05.03
      *    ***************************************************************************
      *    공통 변수 (에러코드 처리시 사용)
      */
      DECLARE
	     @errornumber         INT,
		 @errormessage        NVARCHAR(4000),

         @v_program_id        NVARCHAR(40), 
         @v_program_nm        NVARCHAR(100),

         @v_ret_code          NVARCHAR(30), 
         @v_ret_message       NVARCHAR(1000), 

         @v_flag              NVARCHAR(10),
		 @n_emp_id			  NUMERIC(18,0),
		 @v_emp_no			  NVARCHAR(50),
		 @v_pay_group_cd	  NVARCHAR(50),
		 @v_pay_group_nm	  NVARCHAR(50),
		 @v_pay_ym			  NVARCHAR(10),
		 @v_company_cd		  NVARCHAR(10),
		 @v_close_type_cd	  NVARCHAR(50),
		 @v_close_type_nm	  NVARCHAR(50),
         @ret_code            NVARCHAR(10), 
         @ret_message         NVARCHAR(4000)

      /* 기본변수 초기값 셋팅*/
      SET @v_program_id = 'P_PAY_KIND_UPLOAD_ALL_CHECK'/* 현재 프로시져의 영문명*/
      SET @v_program_nm = '각종수당업로드 마감체크'/* 현재 프로시져의 한글문명*/

      SET @av_ret_code = 'SUCCESS!'
      SET @av_ret_message = '프로시져 실행 시작..'

      /*
      *    ***********************************************************        
      *           2.급여유형 조회     
      *    ***********************************************************
      */
      BEGIN

         BEGIN TRY
			;
            WITH CTE AS (
			SELECT YMD.PAY_YMD_ID, YMD.COMPANY_CD, YMD.PAY_YM, C.CLOSE_TYPE_CD
				 , G.PAY_GROUP AS PAY_GROUP_CD--, GT.PAY_TYPE_CD
				 , CASE WHEN YMD.CLOSE_YN = 'Y' THEN 'Y'
						WHEN C.CLOSE_YN = 'Y' THEN 'Y'
						ELSE 'N' END AS CLOSE_YN --YMD.CLOSE_YN, YMD.PAY_YN, C.CLOSE_YN
			  FROM PAY_PAY_YMD YMD
			  JOIN FRM_CODE T_C
				ON YMD.COMPANY_CD = T_C.COMPANY_CD
			   AND YMD.PAY_TYPE_CD = T_C.CD
			   AND T_C.CD_KIND = 'PAY_TYPE_CD'
			   AND YMD.PAY_YMD BETWEEN T_C.STA_YMD AND T_C.END_YMD
			   AND T_C.SYS_CD = '001'
			  JOIN PAY_GROUP_TYPE GT
				ON YMD.PAY_TYPE_CD = GT.PAY_TYPE_CD
			   AND YMD.COMPANY_CD = GT.COMPANY_CD
			  JOIN PAY_GROUP G
				ON G.PAY_GROUP_ID = GT.PAY_GROUP_ID
			   AND G.COMPANY_CD = YMD.COMPANY_CD
			  JOIN PAY_CLOSE C
				ON YMD.PAY_YMD_ID = C.PAY_YMD_ID -- CLOSE_YN CLOSE_TYPE_CD
			)
			SELECT top 1 @v_flag = 'Y', @n_emp_id = A.EMP_ID
			     , @v_pay_group_cd = CTE.PAY_GROUP_CD
				 , @v_pay_ym = A.PAY_YM
				 , @v_close_type_cd = A.CLOSE_TYPE_CD
				 , @v_company_cd = A.COMPANY_CD--CTE.*, dbo.F_PAY_GROUP_CD( A.EMP_ID ) PAY_GROUP_CD, A.*
			  FROM (SELECT * FROM PAY_KIND_UPLOAD_ALL
					 WHERE 1=1
					   AND PAY_YMD_ID IS NULL
					   AND REG_EMP_ID = @an_reg_emp_id
					   AND FORMAT(MOD_DATE,'yyyyMMdd') = FORMAT(GETDATE(),'yyyyMMdd')
				   ) A
			  JOIN CTE
				ON A.COMPANY_CD = CTE.COMPANY_CD
			   AND A.PAY_YM = CTE.PAY_YM 
			   AND A.CLOSE_TYPE_CD = CTE.CLOSE_TYPE_CD
			   AND CTE.CLOSE_YN = 'Y'
			   AND dbo.F_PAY_GROUP_CD( A.EMP_ID ) = CTE.PAY_GROUP_CD

			 
            IF @@ROWCOUNT > 0
            BEGIN
				SELECT @v_emp_no = EMP_NO
				     , @v_pay_group_nm = DBO.F_FRM_CODE_NM(EMP.COMPANY_CD, EMP.LOCALE_CD, 'PAY_GROUP_CD', @v_pay_group_cd, GETDATE(), '1')
				     , @v_close_type_nm = DBO.F_FRM_CODE_NM(EMP.COMPANY_CD, EMP.LOCALE_CD, 'PAY_CLOSE_TYPE_CD', @v_close_type_cd, GETDATE(), '1')
				  FROM VI_FRM_PHM_EMP EMP
				 WHERE EMP.COMPANY_CD = @v_company_cd
				   AND EMP.EMP_ID  = @n_emp_id
				   AND EMP.LOCALE_CD = 'KO'
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG(@v_pay_ym + '-' + @v_pay_group_nm
										 + '(' + @v_company_cd + @v_emp_no +')' + '[' + @v_close_type_nm +']'
				                         + '마감 되었습니다.[ERR]' ,@v_program_id ,0010, NULL, @an_mod_user_id)
                RETURN
            END

         END TRY

         BEGIN CATCH
		    SET @errornumber   = ERROR_NUMBER()
            SET @errormessage  = ERROR_MESSAGE()

			SET @av_ret_code    = 'FAILURE!'
            SET @av_ret_message = DBO.F_FRM_ERRMSG( '마감체크중 오류발생[ERR]' ,@v_program_id ,0020, @errormessage, @an_mod_user_id);

            IF @@TRANCOUNT > 0
               ROLLBACK WORK
            RETURN
         END CATCH

      END

      /*
      *    ***********************************************************
      *    작업 완료
      *    ***********************************************************
      */
      SET @av_ret_code = 'SUCCESS!'
      SET @av_ret_message = '프로시져 실행 완료..'

   END;

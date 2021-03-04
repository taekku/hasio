SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE  [dbo].[P_PEB_POS_WORK_SAVE](   
       @av_company_cd                 NVARCHAR(10),             -- 인사영역   
       @av_locale_cd                  NVARCHAR(10),             -- 지역코드   
       @an_work_id                    NUMERIC(38),				-- WORKID
       @an_mod_user_id                NUMERIC(38),				-- 변경자 사번   
       @av_ret_code                   NVARCHAR(4000)    OUTPUT, -- 결과코드   
       @av_ret_message                NVARCHAR(4000)    OUTPUT  -- 결과메시지   
    )
AS
    --<DOCLINE> ***************************************************************************
    --   TITLE       : 인건비계획  - 승진자 승급등급저장
    --   PROJECT     : E-HR 시스템   
    --   AUTHOR      :   
    --   PROGRAM_ID  : P_PEB_POS_WORK_SAVE
    --   RETURN      : 1) SUCCESS!/FAILURE!   
    --                 2) 결과 메시지   
    --   COMMENT     : 퇴직금계산    
    --   HISTORY     : 작성 정순보  2006.09.26   
    --               : 수정 박근한  2009.01.16   
    --               : 2016.06.24 Modified by 최성용 in KBpharma   
    --<DOCLINE> ***************************************************************************
BEGIN   
    /* 기본적으로 사용되는 변수 */   
    DECLARE @v_program_id              NVARCHAR(30)   
          , @v_program_nm              NVARCHAR(100)   
          , @ERRCODE                   NVARCHAR(10)   
   
    DECLARE @n_peb_payroll_id   NUMERIC(38)   
   
      /* 기본변수 초기값 셋팅*/   
    SET @v_program_id    = 'P_PEB_POS_WORK_SAVE'   -- 현재 프로시져의 영문명   
    SET @v_program_nm    = '인건비계획  - 승진자 승급등급저장'        -- 현재 프로시져의 한글문명   
    SET @av_ret_code     = 'SUCCESS!'   
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)   
   
    BEGIN TRY
		UPDATE A
		   SET POS_GRD_CD = CASE WHEN B.POS_CLS_CD = 'POS_GRD_CD' THEN B.GRADE_CD ELSE A.POS_GRD_CD END
			 , POS_CD     = CASE WHEN B.POS_CLS_CD = 'POS_CD'     THEN B.GRADE_CD ELSE A.POS_CD END
			 , YEARNUM_CD = CASE WHEN B.POS_CLS_CD = 'YEARNUM_CD' THEN B.GRADE_CD ELSE A.YEARNUM_CD END
			 , MOD_USER_ID = @an_mod_user_id
			 , MOD_DATE = SYSDATETIME()
			 , TZ_CD = 'KST'
			 , TZ_DATE  = SYSDATETIME()
		  FROM PEB_PAYROLL A
		  INNER JOIN (SELECT PEB_PHM_MST_ID
									 , POS_CLS_CD
									 , dbo.XF_TO_CHAR_N( SUBSTRING(COL_NM,4,10), '00') MM
									 , GRADE_CD
								  FROM PEB_POS_WORK
								  UNPIVOT ( GRADE_CD FOR COL_NM IN (COL1, COL2, COL3, COL4, COL5, COL6, COL7, COL8, COL9, COL10, COL11, COL12) )  UNPVT1
								 WHERE WORK_ID = @an_work_id
						) B
					ON A.PEB_PHM_MST_ID = B.PEB_PHM_MST_ID
					AND SUBSTRING(A.PEB_YM,5,2) = MM
		DELETE FROM PEB_POS_WORK
		 WHERE WORK_ID = @an_work_id
	END TRY
	BEGIN CATCH
        BEGIN
            SET @av_ret_code = 'FAILURE!'
            SET @av_ret_message  = dbo.F_FRM_ERRMSG('저장중 에러 발생했습니다.', @v_program_id,  0020,  null,  @an_mod_user_id)
            IF @@TRANCOUNT > 0
                ROLLBACK WORK
            RETURN
        END
    END CATCH
	-- ***********************************************************   
    -- 작업 완료   
    -- ***********************************************************   
    SET @av_ret_code    = 'SUCCESS!'   
    SET @av_ret_message = dbo.F_FRM_ERRMSG('저장되었습니다[ERR]', @v_program_id, 9999, null, @an_mod_user_id)
END

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[P_PAY_CHK_VIEW_USER](
    @av_company_cd              NVARCHAR(50),              -- 인사영역
    @av_locale_cd               NVARCHAR(50),              -- 지역코드
    @an_mod_user_id             NUMERIC,                   -- 변경자
    @av_ret_code                NVARCHAR(1000) OUTPUT,     -- SUCCESS!/FAILURE!
    @av_ret_message             NVARCHAR(1000) OUTPUT      -- 결과메시지
) AS
    -- ***************************************************************************
    --   TITLE       : 급여조회권한사용자 중복체크
    --   PROJECT     : 신인사정보시스템
    --   AUTHOR      : 성엽
    --   PROGRAM_ID  : P_PAY_CHK_VIEW_USER
    --   RETURN      : 1) SUCCESS!/FAILURE!
    --                 2) 결과 메시지
    --   COMMENT     :
    --   HISTORY     : 작성 2021.01.13 - 성엽
    -- ***************************************************************************

    /* 공통 변수 (에러코드 처리시 사용) */
DECLARE @v_program_id           NVARCHAR(30)
      , @v_program_nm           NVARCHAR(100)
	  
      , @v_pay_chk_item_cd      NVARCHAR(50)

      , @errornumber            NUMERIC
      , @errormessage           NVARCHAR(4000)
      , @v_ret_code             NVARCHAR(100)
      , @v_ret_message          NVARCHAR(4000)


BEGIN
    /* 기본변수 초기값 셋팅 */
    SET @v_program_id    = 'P_PAY_CHK_VIEW_USER'          -- 현재 프로시져의 영문명
    SET @v_program_nm    = '급여조회권한사용자 중복체크'     -- 현재 프로시져의 한글명

    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = DBO.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null, @an_mod_user_id )
	
    --=====================================
    -- 사전체크 생성
    --=====================================
	;
	WITH CTE AS (
		SELECT A.PAY_VIEW_ID, B.EMP_ID, B.STA_YMD, B.END_YMD
		  FROM PAY_VIEW A
		  JOIN PAY_VIEW_USER B
			ON A.PAY_VIEW_ID = B.PAY_VIEW_ID
		 WHERE A.COMPANY_CD = @av_company_cd)
	SELECT *
	  FROM CTE A
	  JOIN CTE B
	    ON A.EMP_ID = B.EMP_ID
	   AND A.STA_YMD <= B.END_YMD
	   AND A.END_YMD >= B.STA_YMD
	 WHERE A.COMPANY_CD = @av_company_cd
    IF @av_ret_code ='FAILURE!'
        BEGIN
            SET @av_ret_code = 'FAILURE!'
            SET @av_ret_message = @av_ret_message
            RETURN
        END


    -- ***********************************************************
    -- 작업 완료
    -- ***********************************************************
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('급여체크리스트 대상자 생성이 완료되었습니다.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)

END --끝

GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_ELA_REP_DAY_REQ]  
   @an_appl_id          NUMERIC(38),        -- 결재신청ID
   @av_stat_cd          NVARCHAR(50),   -- 결재상태코드
   @av_ret_code			nvarchar(400)/* 결과코드*/  OUTPUT,
   @av_ret_message		nvarchar(4000)/* 결과메시지*/  OUTPUT
AS 
    -- ***************************************************************************
    --   TITLE       : 단기알바 퇴직금신청 결재 후 처리
    --   PROJECT     : H551
    --   AUTHOR      : 임택구
    --   PROGRAM_ID  : P_ELA_REP_DAY_REQ
    --   RETURN      : SUCCESS!/FAILURE!
    --                 결과 메시지
    --   COMMENT     :
    --   HISTORY     : 작성 임택구  2020.09.14
    --   HISTORY     : 임택구
    -- ***************************************************************************
BEGIN

	SET @av_ret_code = NULL
	SET @av_ret_message = NULL


	DECLARE
		@v_program_id				nvarchar(30)
	  , @v_program_nm				nvarchar(100)
		
      , @n_cnt						NUMERIC(38)
	  , @v_stat_cd					NVARCHAR(10)     -- 전자결재 상태
	  
	  
	  , @n_appr_emp_id				NUMERIC(38)     -- 최종승인자
	  , @n_rep_calc_list_id			NUMERIC(38)     -- 퇴직금대상자ID
	  
	/* *****************************************************************/
	SET @v_program_id = 'P_ELA_REP_DAY_REQ'/* 현재 프로시져의 영문명*/
	SET @v_program_nm = '단기알바 퇴직금신청 결재 후 처리'/* 현재 프로시져의 한글문명*/

	/* *****************************************************************/
	SET @av_ret_code = 'SUCCESS!'



	/*******************************************************************/
    /* 전자결재 삭제( av_stat_cd : 444 ) */
    /*******************************************************************/
    IF @av_stat_cd = '444' 
    	BEGIN
	            DELETE
	              FROM REP_DAY_APPL_PAY
	             WHERE APPL_ID = @an_appl_id
	            DELETE
	              FROM REP_DAY_APPL
	             WHERE APPL_ID = @an_appl_id
	            UPDATE A
				   SET APPL_ID = NULL
	              FROM REP_CALC_LIST A
	             WHERE APPL_ID = @an_appl_id
        END
	ELSE
		BEGIN
			UPDATE A
			   SET APPL_ID = @an_appl_id
			     , APPL_YMD = B.APPL_YMD
			  FROM REP_CALC_LIST A
			  JOIN REP_DAY_APPL B
			    ON A.REP_CALC_LIST_ID = B.REP_CALC_LIST_ID
			   AND B.APPL_ID = @an_appl_id
			UPDATE REP_DAY_APPL
			   SET STAT_CD = @av_stat_cd
			 WHERE APPL_ID = @an_appl_id
		END


    /*******************************************************************/
    /* 결재상태(STAT_CD) 조회 */
    /*******************************************************************/
    BEGIN
        SELECT @v_stat_cd = STAT_CD 
          FROM ELA_APPL
         WHERE APPL_ID = @an_appl_id         
    END 
    
	/*******************************************************************/
	/* 결재상태(STAT_CD) 정보를 업무테이블(CAM_DOC)에 업데이트  */
	/*******************************************************************/
  --  BEGIN
  --      UPDATE SEC_EDU_APPL
  --         SET STAT_CD = @v_stat_cd
  --       WHERE APPL_ID = @an_appl_id
         
		--IF @@ERROR <> 0
		--	BEGIN
		--		SET @av_ret_code    = 'FAILURE!' 
		--		SET @av_ret_message = dbo.F_FRM_ERRMSG('상태코드 없데이트 시 에러발생',
		--										 @v_program_id , 0030, ERROR_MESSAGE() , 1
		--										) 
		--		ROLLBACK 
		--		RETURN 
		--	END
  --  END 
 
/**********************/
/* 결재완료 상태이면, */
/**********************/
-- [ELA_STAT_CD]
-- 111    임시저장
-- 121    결재요청
-- 122    발신결재중
-- 123    수신결재중
-- 131    반려
-- 132    결재완료
  --  IF @v_stat_cd = '132' 
  --  	BEGIN
		--	--최종승인자 조회
		--	BEGIN
		--		SELECT @n_appr_emp_id = dbo.F_ELA_FINAL_APPL_EMP('E','KO',@an_appl_id,GETDATE(),'EMP_ID')
		--		  FROM DUAL
		--		IF @@ROWCOUNT = 0 OR @@ERROR <> 0 
		--			BEGIN
		--				SET @n_appr_emp_id    = null
		--			END
		--	END
		--END


	/*
	*    ***********************************************************
	*    작업 완료
	*    ***********************************************************
	*/
	SET @av_ret_code = 'SUCCESS!'
	SET @av_ret_message = dbo.F_FRM_ERRMSG(
								'프로시져 실행 완료..[ERR]', 
								@v_program_id, 
								0150, 
								NULL, 
								1)

END





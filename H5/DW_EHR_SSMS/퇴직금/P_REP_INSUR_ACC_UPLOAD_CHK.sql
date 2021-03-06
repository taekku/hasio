USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_INSUR_ACC_UPLOAD_CHK]    Script Date: 2021-02-22 오후 2:56:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_INSUR_ACC_UPLOAD_CHK]
	@av_company_cd      nVARCHAR(10),       -- 인사영역
    @av_locale_cd       nVARCHAR(10),       -- 지역코드
    @an_work_id         numeric,         -- 작업ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS

    -- ***************************************************************************
    --   TITLE       : 퇴직연금적립액UPLOAD 체크
    ---  PROJECT     : 신인사정보시스템
    --   AUTHOR      : EHR
    --   PROGRAM_ID  : P_REP_INSUR_ACC_UPLOAD_CHK
    --   ARGUMENT    : 
    --   RETURN      :
    --   HISTORY     :
    -- ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)

    BEGIN
        SET @v_program_id   = 'P_REP_INSUR_ACC_UPLOAD_CHK'
        SET @v_program_nm   = '퇴직연금적립액UPLOAD 체크'
        SET @av_ret_code    = 'SUCCESS!'
        SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                         @v_program_id,  0000,  NULL, NULL);
    END


	
	BEGIN
		-- 기존자료삭제
		BEGIN TRY
			UPDATE A
			   SET A.EMP_ID = EMP.EMP_ID
			     , A.UPLOAD_NOTE = CASE WHEN EMP.EMP_ID IS NULL THEN '주민번호를 확인할수없습니다.'
				                        WHEN A.EMP_NM != EMP.EMP_NM THEN '성명이 틀립니다.'
				                        ELSE NULL END
			  FROM REP_INSUR_ACC_UPLOAD A
			  LEFT OUTER JOIN VI_FRM_PHM_EMP EMP
			    ON A.WORK_ID = @an_work_id
			   AND A.COMPANY_CD = EMP.COMPANY_CD
			   AND EMP.LOCALE_CD = @av_locale_cd
			   AND A.CTZ_NO = EMP.CTZ_NO
			 WHERE A.WORK_ID = @an_work_id
		END TRY
		BEGIN CATCH
					SET @av_ret_code    = 'FAILURE!'  
					SET @av_ret_message = dbo.F_FRM_ERRMSG('인건비 생산성지표 UPLOAD시 오류발생[err]', 
														@v_program_id, 0030 , ERROR_MESSAGE() , 1 
													)   
					RETURN  
		END CATCH
		
	END

    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END
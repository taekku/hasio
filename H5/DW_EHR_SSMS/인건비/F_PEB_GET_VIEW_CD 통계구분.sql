SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   FUNCTION [dbo].[F_PEB_GET_VIEW_CD]
    (  @av_type_nm		nvarchar(50) -- 통계구분
	 , @av_pos_grd_cd	nvarchar(50) -- 직급코드
	 , @av_pos_cd		nvarchar(50) -- 직위코드
	 , @av_duty_cd		nvarchar(50) -- 직책코드
	 , @av_job_position_cd	nvarchar(50) -- 직종코드
	 , @av_mgr_type_cd  nvarchar(50) -- 관리구분
	 , @av_job_cd  nvarchar(50) -- 직무
	 , @av_emp_kind_cd  nvarchar(50) -- 근로형태
    ) RETURNS NVARCHAR(50)
    -- ***************************************************************************
    --   TITLE       : 인건비 - 통계그룹얻기
	--   DESCRIPTION : 
    --   PROJECT     : H5
    --   AUTHOR      : 임택구
    --   PROGRAM_ID  : F_PEB_GET_VIEW_CD
    --   ARGUMENT    : 
    --   RETURN      : VIEW_CD
    --   HISTORY     :
    -- ***************************************************************************
AS
BEGIN
    DECLARE @v_company_cd     NVARCHAR(50),    -- 회사코드
            @v_locale_cd      NVARCHAR(50),    -- 지역코드

            @v_ret            NVARCHAR(50)              -- 결과값

	SELECT @v_ret = VIEW_CD
	  FROM(
		SELECT DISTINCT A.VIEW_CD
		  FROM HRS_STD_MGR A
		  JOIN HRS_STD_ITEM B
			ON A.HRS_STD_MGR = B.HRS_STD_MGR
		   AND A.TYPE_NM = @av_type_nm
		   EXCEPT
		   SELECT DISTINCT VIEW_CD
		   FROM (
				SELECT DISTINCT A.VIEW_CD, B.ITEM_TYPE_CD
				  FROM HRS_STD_MGR A
				  JOIN HRS_STD_ITEM B
					ON A.HRS_STD_MGR = B.HRS_STD_MGR
				   AND A.TYPE_NM = @av_type_nm
				EXCEPT
				SELECT DISTINCT A.VIEW_CD, B.ITEM_TYPE_CD
				  FROM HRS_STD_MGR A
				  JOIN HRS_STD_ITEM B
					ON A.HRS_STD_MGR = B.HRS_STD_MGR
				   AND A.TYPE_NM = @av_type_nm
				   AND ( (B.ITEM_CD = @av_pos_cd          AND B.ITEM_TYPE_CD = 'PHM_POS_CD')
					   OR(B.ITEM_CD = @av_pos_grd_cd      AND B.ITEM_TYPE_CD = 'PHM_POS_GRD_CD')
					   OR(B.ITEM_CD = @av_duty_cd         AND B.ITEM_TYPE_CD = 'PHM_DUTY_CD')
					   OR(B.ITEM_CD = @av_job_position_cd AND B.ITEM_TYPE_CD = 'PHM_JOB_POSTION_CD')
					   OR(B.ITEM_CD = @av_mgr_type_cd     AND B.ITEM_TYPE_CD = 'PHM_MGR_TYPE_CD')
					   OR(B.ITEM_CD = @av_job_cd          AND B.ITEM_TYPE_CD = 'PHM_JOB_CD')
					   OR(B.ITEM_CD = @av_emp_kind_cd     AND B.ITEM_TYPE_CD = 'PHM_EMP_KIND_CD')
					   )
			   )A
		) AA
    RETURN @v_ret
END

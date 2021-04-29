SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[F_PAY_GROUP_EDIT_EMP]
    (  @an_emp_id				NUMERIC,		-- 사원ID
	   @an_session_emp_id       NUMERIC,		-- SESSION 사원ID
       @ad_base_ymd             DATE			-- 기준일자
    ) RETURNS NVARCHAR(1)
    -- ***************************************************************************
    --   TITLE       : Session사용자가 사원ID에 접근 가능한지(조회그룹은제외)
	--   DESCRIPTION : 사원ID에 접근가능한지
    --   PROJECT     : H5
    --   AUTHOR      : 임택구
    --   PROGRAM_ID  : F_PAY_GROUP_USE_EMP
    --   ARGUMENT    : @an_emp_id			: 사원ID
	--                 @an_session_emp_id   : SESSION 사원ID
    --                 ad_base_ymd          : 기준일자(항상 GETDATE())
	--        AND dbo.F_PAY_GROUP_EDIT_EMP(EMP.EMP_ID, :session_emp_id, GETDATE()) = 'Y'
    --   RETURN      : Y:허용, N:불허
    --   HISTORY     :
    -- ***************************************************************************
AS
BEGIN
	DECLARE @rtn_val	nvarchar(1)
    DECLARE @d_base_ymd	DATE = GETDATE()

	SET @rtn_val = 'N'

	SELECT @rtn_val = 'Y'
	  FROM PAY_GROUP_USER A
	  JOIN PAY_GROUP G
	    ON A.PAY_GROUP_ID = G.PAY_GROUP_ID
	   AND @d_base_ymd BETWEEN G.STA_YMD AND G.END_YMD
	   AND A.EMP_ID = @an_session_emp_id
	  JOIN FRM_CODE C
	    ON C.CD_KIND = 'PAY_GROUP_CD'
	   AND G.PAY_GROUP = C.CD
	   AND G.COMPANY_CD = C.COMPANY_CD
	   AND C.SYS_CD = '01'
	   AND @d_base_ymd BETWEEN C.STA_YMD AND C.END_YMD
	 WHERE A.EMP_ID = @an_session_emp_id
	   AND @d_base_ymd BETWEEN A.STA_YMD AND A.END_YMD
	   AND dbo.F_PAY_GROUP_CHK(A.PAY_GROUP_ID, @an_emp_id, @d_base_ymd) > 0
	IF @@ROWCOUNT < 1
		set @rtn_val = 'N'

	RETURN @rtn_val
END
GO

USE [dwehrdev_H5]
GO

/****** Object:  UserDefinedFunction [dbo].[F_PAY_GROUP_CHK]    Script Date: 2020-08-18 오전 11:24:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER FUNCTION [dbo].[F_PAY_GROUP_USE_CHK]
    (  @an_pay_group_id         NUMERIC,         -- 급여그룹ID
	   @an_session_emp_id       NUMERIC,         -- SESSION 사원ID
       @ad_base_ymd             DATE             -- 기준일자
    ) RETURNS NVARCHAR(1)
    -- ***************************************************************************
    --   TITLE       : 급여그룹사용체크
	--   DESCRIPTION : 급여그룹ID에 사원ID가 접근가능한지
    --   PROJECT     : H5
    --   AUTHOR      : 임택구
    --   PROGRAM_ID  : F_PAY_GROUP_CHK
    --   ARGUMENT    : an_pay_group_id      : 급여그룹ID
	--                 @an_session_emp_id   : SESSION 사원ID
    --                 ad_base_ymd          : 기준일자
    --   RETURN      : Y:허용, N:불허
    --   HISTORY     :
    -- ***************************************************************************
AS
BEGIN
	DECLARE @rtn_val	nvarchar(1)
	SET @rtn_val = 'N'

	SELECT @rtn_val = 'Y'
	  FROM PAY_GROUP_USER A
	 WHERE A.PAY_GROUP_ID = @an_pay_group_id
	   AND A.EMP_ID = @an_session_emp_id
	   --AND dbo.XF_TRUNC_D(ISNULL(@ad_base_ymd,GETDATE())) BETWEEN STA_YMD AND END_YMD
	   AND GETDATE() BETWEEN STA_YMD AND END_YMD
	IF @@ROWCOUNT < 1
		set @rtn_val = 'N'

	RETURN @rtn_val
END

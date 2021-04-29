SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[F_PAY_GROUP_USE_EMP]
    (  @an_emp_id				NUMERIC,         -- ���ID
	   @an_session_emp_id       NUMERIC,         -- SESSION ���ID
       @ad_base_ymd             DATE              -- ��������
    ) RETURNS NVARCHAR(1)
    -- ***************************************************************************
    --   TITLE       : Session����ڰ� ���ID�� ���� ��������
	--   DESCRIPTION : ���ID�� ���ٰ�������
    --   PROJECT     : H5
    --   AUTHOR      : ���ñ�
    --   PROGRAM_ID  : F_PAY_GROUP_USE_EMP
    --   ARGUMENT    : @an_emp_id			: ���ID
	--                 @an_session_emp_id   : SESSION ���ID
    --                 ad_base_ymd          : ��������(�׻� GETDATE())
	--        AND dbo.F_PAY_GROUP_USE_EMP(EMP.EMP_ID, :session_emp_id, GETDATE()) = 'Y'
    --   RETURN      : Y:���, N:����
    --   HISTORY     :
    -- ***************************************************************************
AS
BEGIN
	DECLARE @rtn_val	nvarchar(1)
	SET @rtn_val = 'N'

	SELECT @rtn_val = 'Y'
	  FROM PAY_GROUP_USER A
	 WHERE A.EMP_ID = @an_session_emp_id
	   AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD
	   AND dbo.F_PAY_GROUP_CHK(A.PAY_GROUP_ID, @an_emp_id, @ad_base_ymd) > 0
	IF @@ROWCOUNT < 1
		set @rtn_val = 'N'

	RETURN @rtn_val
END
GO

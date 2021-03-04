USE [dwehrdev_H5]
GO

/****** Object:  UserDefinedFunction [dbo].[F_PAY_GROUP_CHK]    Script Date: 2020-08-18 ���� 11:24:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER FUNCTION [dbo].[F_PAY_GROUP_USE_CHK]
    (  @an_pay_group_id         NUMERIC,         -- �޿��׷�ID
	   @an_session_emp_id       NUMERIC,         -- SESSION ���ID
       @ad_base_ymd             DATE             -- ��������
    ) RETURNS NVARCHAR(1)
    -- ***************************************************************************
    --   TITLE       : �޿��׷���üũ
	--   DESCRIPTION : �޿��׷�ID�� ���ID�� ���ٰ�������
    --   PROJECT     : H5
    --   AUTHOR      : ���ñ�
    --   PROGRAM_ID  : F_PAY_GROUP_CHK
    --   ARGUMENT    : an_pay_group_id      : �޿��׷�ID
	--                 @an_session_emp_id   : SESSION ���ID
    --                 ad_base_ymd          : ��������
    --   RETURN      : Y:���, N:����
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

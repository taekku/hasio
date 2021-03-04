SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	전환로그 상세
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_LOG_D
	 @an_cnv_pay_work_id	numeric
	,@av_keys					nvarchar(2000)
	,@av_err_cod				nvarchar(10)
	,@av_err_msg				nvarchar(4000)
AS
BEGIN
	SET NOCOUNT ON
	INSERT INTO CNV_PAY_WORK_LOG(
		 CNV_PAY_WORK_ID
		,KEYS
		,ERR_COD
		,ERR_MSG
		,LOG_DATE
	) VALUES (
		 @an_cnv_pay_work_id
		,@av_keys
		,@av_err_cod
		,@av_err_msg
		,SYSDATETIME()
	)
--PRINT @av_keys + ' : ' + @av_err_cod + ' : ' + @av_err_msg + ' ' + convert(nvarchar(100), GetDate())
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion AsIs로그인ID로 emp_id얻기
-- =============================================
CREATE OR ALTER FUNCTION dbo.F_CNV_GET_EMP_ID_FROM_ASIS_LOGINID(
	@av_login_id	nvarchar(20)
)
RETURNS NUMERIC(38)
AS
BEGIN
	DECLARE @emp_id	numeric(38)

	SET @emp_id = ISNULL((SELECT HIS.EMP_ID
							FROM DWEHRDEV.DBO.O_USER A (NOLOCK)
							LEFT OUTER JOIN PHM_EMP_NO_HIS HIS (NOLOCK)
										ON A.CD_COMPANY = HIS.COMPANY_CD
										AND A.NO_PERSON = HIS.EMP_NO
							WHERE A.ID_LOGIN = @av_login_id), 0)

	RETURN @emp_id

END
GO


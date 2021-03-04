SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_Test_Decrypt]
    @av_string			NVARCHAR(MAX),
    @av_ret_string      NVARCHAR(MAX) OUTPUT    -- ����޽���
 AS

    -- ***************************************************************************
    --   TITLE       : ��ȣȭ �Լ�
    --   PROJECT     :
    --   AUTHOR      :
    --   PROGRAM_ID  : P_Test_Decrypt
    --   RETURN      : 1) ��� �޽���
    -- ***************************************************************************
BEGIN
	BEGIN TRY
		SET @av_ret_string = SecureDB.dbsec.Decrypt(@av_string, 'SecureDB.dbsec.KEY_TBL.AES')
	END TRY
	BEGIN CATCH
		SET @av_ret_string = @av_string
	END CATCH
END

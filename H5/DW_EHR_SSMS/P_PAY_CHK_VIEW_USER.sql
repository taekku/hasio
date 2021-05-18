SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[P_PAY_CHK_VIEW_USER](
    @av_company_cd              NVARCHAR(50),              -- �λ翵��
    @av_locale_cd               NVARCHAR(50),              -- �����ڵ�
    @an_mod_user_id             NUMERIC,                   -- ������
    @av_ret_code                NVARCHAR(1000) OUTPUT,     -- SUCCESS!/FAILURE!
    @av_ret_message             NVARCHAR(1000) OUTPUT      -- ����޽���
) AS
    -- ***************************************************************************
    --   TITLE       : �޿���ȸ���ѻ���� �ߺ�üũ
    --   PROJECT     : ���λ������ý���
    --   AUTHOR      : ����
    --   PROGRAM_ID  : P_PAY_CHK_VIEW_USER
    --   RETURN      : 1) SUCCESS!/FAILURE!
    --                 2) ��� �޽���
    --   COMMENT     :
    --   HISTORY     : �ۼ� 2021.01.13 - ����
    -- ***************************************************************************

    /* ���� ���� (�����ڵ� ó���� ���) */
DECLARE @v_program_id           NVARCHAR(30)
      , @v_program_nm           NVARCHAR(100)
	  
      , @v_pay_chk_item_cd      NVARCHAR(50)

      , @errornumber            NUMERIC
      , @errormessage           NVARCHAR(4000)
      , @v_ret_code             NVARCHAR(100)
      , @v_ret_message          NVARCHAR(4000)


BEGIN
    /* �⺻���� �ʱⰪ ���� */
    SET @v_program_id    = 'P_PAY_CHK_VIEW_USER'          -- ���� ���ν����� ������
    SET @v_program_nm    = '�޿���ȸ���ѻ���� �ߺ�üũ'     -- ���� ���ν����� �ѱ۸�

    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = DBO.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null, @an_mod_user_id )
	
    --=====================================
    -- ����üũ ����
    --=====================================
	;
	WITH CTE AS (
		SELECT A.PAY_VIEW_ID, B.EMP_ID, B.STA_YMD, B.END_YMD
		  FROM PAY_VIEW A
		  JOIN PAY_VIEW_USER B
			ON A.PAY_VIEW_ID = B.PAY_VIEW_ID
		 WHERE A.COMPANY_CD = @av_company_cd)
	SELECT *
	  FROM CTE A
	  JOIN CTE B
	    ON A.EMP_ID = B.EMP_ID
	   AND A.STA_YMD <= B.END_YMD
	   AND A.END_YMD >= B.STA_YMD
	 WHERE A.COMPANY_CD = @av_company_cd
    IF @av_ret_code ='FAILURE!'
        BEGIN
            SET @av_ret_code = 'FAILURE!'
            SET @av_ret_message = @av_ret_message
            RETURN
        END


    -- ***********************************************************
    -- �۾� �Ϸ�
    -- ***********************************************************
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('�޿�üũ����Ʈ ����� ������ �Ϸ�Ǿ����ϴ�.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)

END --��

GO



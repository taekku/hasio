SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE  [dbo].[P_PEB_POS_WORK_SAVE](   
       @av_company_cd                 NVARCHAR(10),             -- �λ翵��   
       @av_locale_cd                  NVARCHAR(10),             -- �����ڵ�   
       @an_work_id                    NUMERIC(38),				-- WORKID
       @an_mod_user_id                NUMERIC(38),				-- ������ ���   
       @av_ret_code                   NVARCHAR(4000)    OUTPUT, -- ����ڵ�   
       @av_ret_message                NVARCHAR(4000)    OUTPUT  -- ����޽���   
    )
AS
    --<DOCLINE> ***************************************************************************
    --   TITLE       : �ΰǺ��ȹ  - ������ �±޵������
    --   PROJECT     : E-HR �ý���   
    --   AUTHOR      :   
    --   PROGRAM_ID  : P_PEB_POS_WORK_SAVE
    --   RETURN      : 1) SUCCESS!/FAILURE!   
    --                 2) ��� �޽���   
    --   COMMENT     : �����ݰ��    
    --   HISTORY     : �ۼ� ������  2006.09.26   
    --               : ���� �ڱ���  2009.01.16   
    --               : 2016.06.24 Modified by �ּ��� in KBpharma   
    --<DOCLINE> ***************************************************************************
BEGIN   
    /* �⺻������ ���Ǵ� ���� */   
    DECLARE @v_program_id              NVARCHAR(30)   
          , @v_program_nm              NVARCHAR(100)   
          , @ERRCODE                   NVARCHAR(10)   
   
    DECLARE @n_peb_payroll_id   NUMERIC(38)   
   
      /* �⺻���� �ʱⰪ ����*/   
    SET @v_program_id    = 'P_PEB_POS_WORK_SAVE'   -- ���� ���ν����� ������   
    SET @v_program_nm    = '�ΰǺ��ȹ  - ������ �±޵������'        -- ���� ���ν����� �ѱ۹���   
    SET @av_ret_code     = 'SUCCESS!'   
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null,  @an_mod_user_id)   
   
    BEGIN TRY
		UPDATE A
		   SET POS_GRD_CD = CASE WHEN B.POS_CLS_CD = 'POS_GRD_CD' THEN B.GRADE_CD ELSE A.POS_GRD_CD END
			 , POS_CD     = CASE WHEN B.POS_CLS_CD = 'POS_CD'     THEN B.GRADE_CD ELSE A.POS_CD END
			 , YEARNUM_CD = CASE WHEN B.POS_CLS_CD = 'YEARNUM_CD' THEN B.GRADE_CD ELSE A.YEARNUM_CD END
			 , MOD_USER_ID = @an_mod_user_id
			 , MOD_DATE = SYSDATETIME()
			 , TZ_CD = 'KST'
			 , TZ_DATE  = SYSDATETIME()
		  FROM PEB_PAYROLL A
		  INNER JOIN (SELECT PEB_PHM_MST_ID
									 , POS_CLS_CD
									 , dbo.XF_TO_CHAR_N( SUBSTRING(COL_NM,4,10), '00') MM
									 , GRADE_CD
								  FROM PEB_POS_WORK
								  UNPIVOT ( GRADE_CD FOR COL_NM IN (COL1, COL2, COL3, COL4, COL5, COL6, COL7, COL8, COL9, COL10, COL11, COL12) )  UNPVT1
								 WHERE WORK_ID = @an_work_id
						) B
					ON A.PEB_PHM_MST_ID = B.PEB_PHM_MST_ID
					AND SUBSTRING(A.PEB_YM,5,2) = MM
		DELETE FROM PEB_POS_WORK
		 WHERE WORK_ID = @an_work_id
	END TRY
	BEGIN CATCH
        BEGIN
            SET @av_ret_code = 'FAILURE!'
            SET @av_ret_message  = dbo.F_FRM_ERRMSG('������ ���� �߻��߽��ϴ�.', @v_program_id,  0020,  null,  @an_mod_user_id)
            IF @@TRANCOUNT > 0
                ROLLBACK WORK
            RETURN
        END
    END CATCH
	-- ***********************************************************   
    -- �۾� �Ϸ�   
    -- ***********************************************************   
    SET @av_ret_code    = 'SUCCESS!'   
    SET @av_ret_message = dbo.F_FRM_ERRMSG('����Ǿ����ϴ�[ERR]', @v_program_id, 9999, null, @an_mod_user_id)
END

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PAY_REQUEST_ETC_UPDATE] (
    @av_company_cd         NVARCHAR(10),           -- ȸ���ڵ�
    @av_pay_request_ids    NVARCHAR(MAX),          -- �޿��Ƿ�ID(���ڿ� ',' ����)
    @an_mod_user_id        NUMERIC(18,0),          -- �۾���
    @av_ret_code           NVARCHAR(300)  OUTPUT,  -- ����ڵ�
    @av_ret_message        NVARCHAR(4000) OUTPUT   -- ����޽���
) AS

--<DOCLINE> ***************************************************************************
--<DOCLINE>   TITLE       : �޿��Ƿ�������� ��ó��
--<DOCLINE>   PROJECT     : ���λ������ý���
--<DOCLINE>   AUTHOR      : ������
--<DOCLINE>   PROGRAM_ID  : P_PAY_REQUEST_ETC_UPDATE
--<DOCLINE>   ARGUMENT    : 
--<DOCLINE>   RETURN      : ����ڵ� SUCCESS! / FAILURE! 
--<DOCLINE>               : ����޽���
--<DOCLINE>   COMMENT     : 
--<DOCLINE>   HISTORY     : 
--<DOCLINE> ***************************************************************************

BEGIN
    DECLARE
        @v_program_id          NVARCHAR(30),
        @v_program_nm          NVARCHAR(100),
		
        @req$pay_request_id    NUMERIC(18,0),     -- �޿��Ƿ�ID
        @req$pay_kind_upload_id    NUMERIC(18,0),     -- ����������ε�ID
        @req$pay_ymd_id        NUMERIC(18,0),     -- �޿�����ID
        @req$emp_id            NUMERIC(18,0),     -- ���ID
        @req$pay_item_cd       NVARCHAR(10),      -- �޿��׸��ڵ�
        @req$team_yn           CHAR(1)            -- ������ο���

    /*�⺻���� �ʱⰪ ����*/
    SET @v_program_id   = 'P_PAY_REQUEST_ETC_UPDATE'
    SET @v_program_nm   = '�޿��Ƿ�������� ��ó��'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
	
--<DOCLINE> ***************************************************************************
--<DOCLINE> �޿��Ƿڳ��� �� ���ε� ������ �����������̺� INSERT, ������� ������ DELETE
--<DOCLINE> ***************************************************************************
    BEGIN
        DECLARE CUR_REQ CURSOR LOCAL FOR
            SELECT PAY_REQUEST_ID
                 , PAY_KIND_UPLOAD_ID
                 , PAY_YMD_ID
                 , EMP_ID
                 , ITEM_CD
                 , TEAM_YN
              FROM PAY_REQUEST A
              INNER JOIN DBO.FN_SPLIT_ARRAY(@av_pay_request_ids, ',') B
                           ON A.PAY_REQUEST_ID = CAST(B.ITEMS AS NUMERIC(18,0))
			  INNER JOIN PAY_UPLOAD_MST M
			          ON A.PAY_UPLOAD_MST_ID = M.PAY_UPLOAD_MST_ID
			  INNER JOIN PAY_KIND_UPLOAD C
			          ON A.PAY_UPLOAD_MST_ID = M.PAY_UPLOAD_MST_ID
        OPEN CUR_REQ
        WHILE 1=1
        BEGIN
        FETCH NEXT FROM CUR_REQ INTO @req$pay_request_id, @req$pay_kind_upload_id, @req$pay_ymd_id, @req$emp_id, @req$pay_item_cd, @req$team_yn
        IF @@FETCH_STATUS <> 0 BREAK
            IF @req$team_yn = 'Y'
                BEGIN TRY
                    INSERT INTO PAY_ETC_PAY( PAY_ETC_PAY_ID    -- �޿���Ÿ����ID
                                           , PAY_YMD_ID		   -- �޿�����ID
                                           , EMP_ID			   -- ���ID
                                           , CLOSE_TYPE_CD	   -- �������������ڵ�
                                           , PAY_ITEM_CD	   -- �޿��׸��ڵ�
                                           , ALLW_AMT		   -- �������ޱݾ�
                                           , TAX_YN			   -- ���ݿ���
                                           , PAY_YN			   -- �޿����뿩��
                                           , CRE_FLAG		   -- ��������
                                           , REQ_ID			   -- �޿��Ƿ�ID
                                           , LOCATION_CD	   -- ������ڵ�
                                           , NOTE			   -- ���
                                           , MOD_USER_ID	   -- ������
                                           , MOD_DATE		   -- �����Ͻ�
                                           , TZ_CD			   -- Ÿ�����ڵ�
                                           , TZ_DATE		   -- Ÿ�����Ͻ�
                                           )
                                      SELECT NEXT VALUE FOR S_PAY_SEQUENCE  -- PAY_ETC_PAY_ID
                                           , PAY_YMD_ID                     -- PAY_YMD_ID
                                           , EMP_ID                         -- EMP_ID
                                           , M.CLOSE_TYPE_CD                -- CLOSE_TYPE_CD
                                           , ITEM_CD                        -- PAY_ITEM_CD
                                           , PAY_MON                        -- ALLW_AMT
                                           , 'N'                            -- TAX_YN
                                           , 'N'                            -- PAY_YN
                                           , 'REQ'                          -- CRE_FLAG
                                           , PAY_REQUEST_ID                 -- REQ_ID
                                           , NULL                           -- LOCATION_CD
                                           , NULL                           -- NOTE
                                           , @an_mod_user_id                -- MOD_USER_ID
                                           , GETDATE()                      -- MOD_DATE
                                           , 'KST'                          -- TZ_CD
                                           , GETDATE()                      -- TZ_DATE
                                        FROM PAY_REQUEST A
										JOIN PAY_KIND_UPLOAD B
										  ON A.PAY_UPLOAD_MST_ID = B.PAY_UPLOAD_MST_ID
										JOIN PAY_UPLOAD_MST M
										  ON A.PAY_UPLOAD_MST_ID = M.PAY_UPLOAD_MST_ID
                                       WHERE PAY_REQUEST_ID = @req$pay_request_id
										 AND PAY_KIND_UPLOAD_ID = @req$pay_kind_upload_id
                END TRY
                BEGIN CATCH
                    SET @av_ret_code = 'FAILURE!' 
                    SET @av_ret_message = DBO.F_FRM_ERRMSG('���γ��� �ݿ��� �����߻�[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
                    IF @@TRANCOUNT > 0
                        ROLLBACK
                    RETURN
                END CATCH
            ELSE
                BEGIN TRY
                    DELETE FROM PAY_ETC_PAY
                     WHERE REQ_ID = @req$pay_request_id
                       AND PAY_YMD_ID = @req$pay_ymd_id
                       AND EMP_ID = @req$emp_id
                       AND PAY_ITEM_CD = @req$pay_item_cd
                END TRY
                BEGIN CATCH
                    SET @av_ret_code = 'FAILURE!' 
                    SET @av_ret_message = DBO.F_FRM_ERRMSG('������ҳ��� �ݿ��� �����߻�[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
                    IF @@TRANCOUNT > 0
                        ROLLBACK
                    RETURN
                END CATCH
        END
        CLOSE CUR_REQ
        DEALLOCATE CUR_REQ
    END
--<DOCLINE> ***************************************************************************
--<DOCLINE> �۾��Ϸ�
--<DOCLINE> ***************************************************************************
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('�ڷᰡ ����Ǿ����ϴ�[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
END

GO



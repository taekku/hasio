SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER   PROCEDURE [dbo].[P_PAY_APPLY_REQ] (
    @av_company_cd     NVARCHAR(10),           -- ȸ���ڵ�
    @av_pay_upload_mst_ids    NVARCHAR(MAX),      -- �޿��Ƿڽ�ûID(���ڿ� ',' ����)
    --@an_pay_ymd_id     NUMERIC(18,0),          -- �޿�����ID
    --@av_close_type_cd  NVARCHAR(10),           -- ������������
    @an_mod_user_id    NUMERIC(18,0),          -- �۾���
    @av_ret_code       NVARCHAR(300)  OUTPUT,  -- ����ڵ�
    @av_ret_message    NVARCHAR(4000) OUTPUT   -- ����޽���
) AS

--<DOCLINE> ***************************************************************************
--<DOCLINE>   TITLE       : ��Ÿ����޿��Ƿ�
--<DOCLINE>   PROJECT     : ���λ������ý���
--<DOCLINE>   AUTHOR      : ������
--<DOCLINE>   PROGRAM_ID  : P_PAY_APPLY_REQ
--<DOCLINE>   ARGUMENT    : 
--<DOCLINE>   RETURN      : ����ڵ� SUCCESS! / FAILURE! 
--<DOCLINE>               : ����޽���
--<DOCLINE>   COMMENT     : 
--<DOCLINE>   HISTORY     : 
--<DOCLINE> ***************************************************************************

BEGIN
    DECLARE
        @v_program_id NVARCHAR(30),
        @v_program_nm NVARCHAR(100),
		
        @c_pay_close_yn CHAR(1),         -- �޿���������
        @c_req_close_yn CHAR(1),         -- �����۾���������
        @n_close_type_id NUMERIC(18,0),   -- ��������ڰ���ID
		@n_pay_upload_mst_id NUMERIC(18,0),
		@n_pay_ymd_id NUMERIC(18,0),
		@v_close_type_cd NVARCHAR(10),
		@cnt_dup_emp	NUMERIC


    /*�⺻���� �ʱⰪ ����*/
    SET @v_program_id   = 'P_PAY_APPLY_REQ'
    SET @v_program_nm   = '��Ÿ����޿��Ƿ�'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
	
--<DOCLINE> ***************************************************************************
--<DOCLINE> �޿���������, �ش���� �����۾� ��������üũ
--<DOCLINE> ***************************************************************************
    BEGIN
	
        DECLARE CUR_MST CURSOR LOCAL FOR
            SELECT PAY_UPLOAD_MST_ID
			     , PAY_YMD_ID
				 , CLOSE_TYPE_CD
              FROM PAY_UPLOAD_MST A
                   INNER JOIN DBO.FN_SPLIT_ARRAY(@av_pay_upload_mst_ids, ',') B
                           ON A.PAY_UPLOAD_MST_ID = CAST(B.ITEMS AS NUMERIC(18,0))
        OPEN CUR_MST
        WHILE 1=1
        BEGIN TRY
			FETCH NEXT FROM CUR_MST INTO @n_pay_upload_mst_id, @n_pay_ymd_id, @v_close_type_cd
			IF @@FETCH_STATUS <> 0 BREAK

			SELECT @c_pay_close_yn  = YMD.CLOSE_YN
				 , @c_req_close_yn  = PC.CLOSE_YN
				 , @n_close_type_id = PCT.PAY_CLOSE_TYPE_ID
			  FROM PAY_PAY_YMD YMD
				   LEFT OUTER JOIN PAY_CLOSE PC
						   ON YMD.PAY_YMD_ID = PC.PAY_YMD_ID
						  AND PC.CLOSE_TYPE_CD = @v_close_type_cd
				   LEFT OUTER JOIN PAY_CLOSE_TYPE PCT
						   ON YMD.PAY_YMD BETWEEN PCT.STA_YMD AND PCT.END_YMD
						  AND PCT.PAY_CLOSE_TYPE_CD = @v_close_type_cd
						  AND PCT.EMP_ID = @an_mod_user_id
			 WHERE YMD.COMPANY_CD = @av_company_cd
			   AND YMD.PAY_YMD_ID = @n_pay_ymd_id

			IF @@ROWCOUNT < 1
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('�޿����ڰ� ������ �����ϴ�.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END

			IF @@ERROR <> 0
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('�޿����� ���� ��ȸ �� �����߻�[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END

			IF @c_pay_close_yn = 'Y'
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('�޿��� �����Ǿ����ϴ�.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END

			IF @c_req_close_yn = 'Y'
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('�ش���� �޿��Ƿڰ� �����Ǿ����ϴ�.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END
			ELSE IF @c_req_close_yn IS NULL
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('�ش�޿��� �޿��Ƿڰ� ������ ������ �ƴմϴ�.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END
			ELSE IF @n_close_type_id IS NULL
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('�ش���� �޿��Ƿ� ������ �����ϴ�.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
					RETURN
				END
--<DOCLINE> ***************************************************************************
--<DOCLINE> �Ƿ�����üũ
--<DOCLINE> ***************************************************************************
			SELECT @cnt_dup_emp = COUNT(*)
			  FROM (
							SELECT DTL.EMP_ID
								FROM PAY_UPLOAD_MST MST
								JOIN PAY_KIND_UPLOAD DTL
									ON MST.PAY_UPLOAD_MST_ID = DTL.PAY_UPLOAD_MST_ID
								LEFT OUTER JOIN PAY_REQUEST REQ
									ON MST.PAY_UPLOAD_MST_ID = REQ.PAY_UPLOAD_MST_ID
								 AND ISNULL(CONF_YN, 'Y') = 'Y'
								 AND ISNULL(TEAM_YN, 'Y') = 'Y'
							 WHERE MST.PAY_YMD_ID = @n_pay_ymd_id
								 AND (REQ.PAY_UPLOAD_MST_ID IS NOT NULL OR MST.PAY_UPLOAD_MST_ID = @n_pay_upload_mst_id)
							 GROUP BY DTL.EMP_ID, DTL.PAY_ITEM_CD
							 HAVING COUNT(*) > 1
			 ) A
			IF @cnt_dup_emp > 0 
				BEGIN
					SET @av_ret_code = 'FAILUERE!'
					SET @av_ret_message = DBO.F_FRM_ERRMSG('�Ƿ��� ������ �ߺ� ����� �ֽ��ϴ�.[ERR]', @v_program_id, 0123, NULL, @an_mod_user_id)
					RETURN
				END
			-- 
			INSERT INTO PAY_REQUEST(
					PAY_REQUEST_ID,
					PAY_UPLOAD_MST_ID,
					MOD_USER_ID,
					MOD_DATE,
					TZ_CD,
					TZ_DATE
			)
			SELECT NEXT VALUE FOR S_PAY_SEQUENCE AS PAY_REQUSET_ID
					, @n_pay_upload_mst_id
					, @an_mod_user_id                 -- MOD_USER_ID
					, GETDATE()                       -- MOD_DATE
					, 'KST'                           -- TZ_CD
					, GETDATE()                       -- TZ_DATE
			UPDATE PAY_UPLOAD_MST
			   set REQ_DATE = dbo.XF_TRUNC_D(dbo.XF_SYSDATE(0))
			 WHERE PAY_UPLOAD_MST_ID = @n_pay_upload_mst_id
		END TRY
		BEGIN CATCH
			SET @av_ret_code = 'FAILUERE!'
			SET @av_ret_message = DBO.F_FRM_ERRMSG('ó���� ������ �߻��߽��ϴ�.[ERR]', @v_program_id, 0000, ERROR_MESSAGE(), @an_mod_user_id)
			RETURN
		END CATCH

		CLOSE CUR_MST
		DEALLOCATE CUR_MST
--<DOCLINE> ***************************************************************************
--<DOCLINE> �۾��Ϸ�
--<DOCLINE> ***************************************************************************
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('�޿��Ƿ� ���� �Ϸ�..[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
	END
END
GO

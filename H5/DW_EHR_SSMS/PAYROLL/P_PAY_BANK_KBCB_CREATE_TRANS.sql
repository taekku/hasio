SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_PAY_BANK_KBCB_CREATE_TRANS]
   @av_company_cd		nvarchar(10), -- ȸ���ڵ�
   @an_pay_ymd_id NUMERIC(38)/* �޿�����ID*/,
   @av_site_cd			nvarchar(50), -- CyberBank�� ���� ����ڹ�ȣ
   @ad_give_ymd			date, -- ������
   @an_mod_user_id NUMERIC(38)/* ����� ���ID*/,
   @av_ret_code NVARCHAR(4000)/* ����ڵ�*/  OUTPUT,
   @av_ret_message NVARCHAR(4000)/* ����޽���*/  OUTPUT
AS    
   /*
   *   <DOCLINE> ***************************************************************************
   *   <DOCLINE>   TITLE       : KB Cyber Branch ��������ü ����
   *   <DOCLINE>   PROJECT     : BAYER
   *   <DOCLINE>   AUTHOR      : ���ñ�
   *   <DOCLINE>   PROGRAM_ID  : P_PAY_BANK_KBCB_CREATE_TRANS
   *   <DOCLINE>   ARGUMENT    : �ٷ� �� ����
   *   <DOCLINE>   RETURN      : ����ڵ� : SUCCESS! :
   *   <DOCLINE>                            FAILURE! :
   *   <DOCLINE>                 ����޽���
   *   <DOCLINE>   COMMENT     : 
   *   <DOCLINE>   HISTORY     : �ۼ� ���ñ� 2021.01.15
   *   <DOCLINE> ***************************************************************************
   *    �⺻������ ���Ǵ� ����
   */
BEGIN
    SET @av_ret_code = NULL  
    SET @av_ret_message = NULL  
    
    DECLARE
        @v_program_id NVARCHAR(30), 
        @v_program_nm NVARCHAR(100),
        @errornumber INT,
        @errormessage NVARCHAR(4000),
        @v_close_yn CHAR(1),
		@v_pay_type_cd	nvarchar(10),
		@v_pay_group	nvarchar(10),
		@d_pay_ymd		date,
		@v_in_bank_cd	nvarchar(3),
		@v_in_acct_no	nvarchar(15),
		@v_pre_reci_man nvarchar(100),
		@v_emp_no		nvarchar(10) = '',
		@n_real_amt		numeric(11) = 0,
		@n_total_amt	numeric(18) = 0,
		@n_file_cnt		numeric(5),
		@n_pay_payroll_id	numeric(38) = 0,
		@n_seq			numeric(8) = 0,
        @n_cnt			numeric(8) = 0

    /* �⺻���� �ʱⰪ ����*/
    SET @av_ret_code = 'SUCCESS!'
    SET @v_program_id = 'P_PAY_BANK_KBCB_CREATE_TRANS'/* ���� ���ν����� ������*/
    SET @v_program_nm = 'KB CyberBank ��������ü���� ����'/* ���� ���ν����� �ѱ۹���*/
    SET @av_ret_message = dbo.F_FRM_ERRMSG( '���ν��� ���� ����..', 
                                            @V_PROGRAM_ID, 
                                            0000, 
                                            NULL, 
                                            @AN_MOD_USER_ID)
    BEGIN
    
        /*���ο��� ����*/
        BEGIN TRY
          SELECT @v_close_yn = dbo.XF_NVL_C(YMD.CLOSE_YN,'')
		       , @v_pay_type_cd = YMD.PAY_TYPE_CD
			   , @d_pay_ymd = YMD.PAY_YMD
			   , @v_pay_group = (SELECT PAY_GROUP FROM PAY_GROUP WHERE PAY_GROUP_ID = GRP.PAY_GROUP_ID)
            FROM PAY_PAY_YMD YMD
			JOIN PAY_GROUP_TYPE GRP
			  ON YMD.PAY_TYPE_CD = GRP.PAY_TYPE_CD
			 AND YMD.COMPANY_CD = GRP.COMPANY_CD
           WHERE YMD.PAY_YMD_ID = @an_pay_ymd_id
        END TRY
        BEGIN CATCH
            SET @errornumber   = ERROR_NUMBER()  
            SET @errormessage  = ERROR_MESSAGE()  

            SET @av_ret_code    = 'FAILURE!'  
            SET @av_ret_message = DBO.F_FRM_ERRMSG('�޿����� �������� ��ȸ�� ����.[ERR]' ,@v_program_id ,0005  ,@errormessage  ,@an_mod_user_id )  
            IF @@TRANCOUNT > 0  
               ROLLBACK WORK  
            RETURN 
        END CATCH
        
        IF @v_close_yn <> 'Y'
            BEGIN
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = dbo.F_FRM_ERRMSG('�������� ���� �޿������Դϴ�.[ERR]',@v_program_id, 0006, NULL, @an_mod_user_id)

                IF @@TRANCOUNT > 0
                    ROLLBACK WORK 
                 RETURN
            END

		SELECT @n_file_cnt = COUNT(*) 
		  FROM CB2_PAY_PAY_H A
		 WHERE A.SITE_CD = @av_site_cd
		   AND A.FILE_GB = @v_pay_type_cd
		   AND A.FILE_DATE = dbo.XF_TO_CHAR_D(@ad_give_ymd, 'yyyyMMdd')
		IF @@ROWCOUNT < 1
			set @n_file_cnt = 0
		set @n_file_cnt = @n_file_cnt + 1
      /*
      *   <DOCLINE> ****************************************************************************
      *   <DOCLINE> DETAIL ����
      *   <DOCLINE> ****************************************************************************
      */
      BEGIN
		-- 
		IF @av_company_cd in ('C', 'T')
			BEGIN
				--DELETE OPENQUERY(EHRIF, 'SELECT * FROM CT_IF_EHRDATA ')
				DELETE FROM CT_IF_EHRDATA
				 WHERE FILE_DATE = dbo.XF_TO_CHAR_D(@ad_give_ymd, 'yyyyMMdd')
				   AND SITE_CD = @av_site_cd
				   AND FILE_GB = @v_pay_type_cd
				   AND RIGHT(REMARK, 4) = @v_pay_group
			END
		DECLARE PAY_CUR CURSOR READ_ONLY FOR
			SELECT ISNULL(ITEM.BANK_CD,'') AS IN_BANK_CD, -- ����
					ISNULL(REPLACE( /*dbo.F_FRM_DECRYPT_C(*/ ITEM.ACCOUNT_NO /*)*/, '-', ''),'') AS IN_ACCT_NO,-- ���¹�ȣ
					SUM(DTL.CAL_MON) AS REAL_AMT, -- �Աݱݾ�
					ISNULL(ITEM.HOLDER_NM,'') AS PRE_RECI_MAN--, -- ������
					--EMP.EMP_NO,
					--PAY.PAY_PAYROLL_ID
			FROM PAY_PAY_YMD YMD
			INNER JOIN PAY_PAYROLL PAY
					ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
			INNER JOIN PAY_PAYROLL_DETAIL DTL
					ON PAY.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID
			INNER JOIN PAY_ITEM_MST ITEM
			        ON YMD.COMPANY_CD = ITEM.COMPANY_CD
				   AND DTL.PAY_ITEM_CD = ITEM.PAY_ITEM_CD
			--INNER JOIN PHM_EMP EMP
			--		ON PAY.EMP_ID = EMP.EMP_ID
			WHERE YMD.PAY_YMD_ID = @an_pay_ymd_id
			AND ITEM.ACCOUNT_NO > ' '
			AND YMD.CLOSE_YN = 'Y'
			GROUP BY ITEM.BANK_CD, ITEM.ACCOUNT_NO, ITEM.HOLDER_NM
		OPEN PAY_CUR
		WHILE 1=1
          BEGIN TRY
				FETCH NEXT FROM PAY_CUR
			      INTO @v_in_bank_cd, @v_in_acct_no, @n_real_amt, @v_pre_reci_man--, @v_emp_no, @n_pay_payroll_id
				IF @@FETCH_STATUS <> 0 BREAK
				SET @n_seq = @n_seq + 1
				INSERT CB2_PAY_REQ_D( SITE_CD, --	������ڵ�
								FILE_GB, --	���ϱ���
								FILE_DATE, --	���ϻ�����
								FILE_CNT, --	����ȸ��
								FILE_SEQ, --	SEQ
								IN_BANK_CD, --	�Ա������ڵ�
								IN_ACCT_NO, --	�Աݰ��¹�ȣ
								TRAN_AMT, --	��ü�ݾ�
								PRE_RECI_MAN, --	��������θ�
								PAY_GB, --	���ޱ���
								REMARK, --	����
								ERP_REC_NO, --	ERP_REC_NO
								ERP_DATE, --	ERP_DATE
								ERP_TIME, --	ERP_TIME
								PAY_PAYROLL_ID --	�޿�����ID
								) 
                           SELECT @av_site_cd AS SITE_CD, -- ������ڵ�
                                  @v_pay_type_cd AS FILE_GB, 
                                  dbo.XF_TO_CHAR_D(@ad_give_ymd, 'yyyyMMdd') AS FILE_DATE, -- ��������
                                  @n_file_cnt AS FILE_CNT,
                                  @n_seq AS FILE_SEQ, -- ����
								  @v_in_bank_cd AS IN_BANK_CD, -- ����
								  @v_in_acct_no AS IN_ACCT_NO,-- ���¹�ȣ
                                  @n_real_amt AS TRAN_AMT, -- �Աݱݾ�
								  @v_pre_reci_man AS PRE_RECI_MAN,-- ������
								  @v_pay_type_cd PAY_GB, 
								  dbo.F_FRM_CODE_SYS_NM('KO','PAY_TYPE_CD', dbo.F_FRM_CODE_NM(@av_company_cd, 'KO', 'PAY_TYPE_CD', @v_pay_type_cd, @ad_give_ymd, 'S'), @ad_give_ymd)
								  +
								  CASE WHEN @av_company_cd IN ('C','T') THEN '>>������>' + @v_pay_group ELSE '>>��������ü' END AS REMARK,
								  dbo.XF_TO_CHAR_D(@d_pay_ymd, 'yyyyMMdd') /*+ @v_emp_no*/ AS ERP_REC_NO, --	ERP_REC_NO
								  '', --	ERP_DATE
								  '', --	ERP_TIME
								  @n_pay_payroll_id --	�޿�����ID
				IF @av_company_cd in ('C', 'T')
				BEGIN
					--insert openquery(EHRIF,'select * from CT_IF_EHRDATA')
					INSERT INTO CT_IF_EHRDATA
					   (SITE_CD, --	������ڵ�
						FILE_GB, --	���ϱ���
						FILE_DATE, --	���ϻ�����
						FILE_CNT, --	����ȸ��
						FILE_SEQ, --	SEQ
						IN_BANK_CD, --	�Ա������ڵ�
						IN_ACCT_NO, --	�Աݰ��¹�ȣ
						TRAN_AMT, --	��ü�ݾ�
						PRE_RECI_MAN, --	��������θ�
						PAY_GB, --	���ޱ���
						REMARK, --	����
						ERP_REC_NO, --	ERP_REC_NO
						ERP_DATE, --	ERP_DATE
						ERP_TIME, --	ERP_TIME
						PAY_PAYROLL_ID --	�޿�����ID
						)
					SELECT @av_site_cd AS SITE_CD, -- ������ڵ�
                                  @v_pay_type_cd AS FILE_GB, 
                                  dbo.XF_TO_CHAR_D(@ad_give_ymd, 'yyyyMMdd') AS FILE_DATE, -- ��������
                                  @n_file_cnt AS FILE_CNT,
                                  @n_seq AS FILE_SEQ, -- ����
								  @v_in_bank_cd AS IN_BANK_CD, -- ����
								  @v_in_acct_no AS IN_ACCT_NO,-- ���¹�ȣ
                                  @n_real_amt AS TRAN_AMT, -- �Աݱݾ�
								  @v_pre_reci_man AS PRE_RECI_MAN,-- ������
								  @v_pay_type_cd PAY_GB, 
								  dbo.F_FRM_CODE_SYS_NM('KO','PAY_TYPE_CD', dbo.F_FRM_CODE_NM(@av_company_cd, 'KO', 'PAY_TYPE_CD', @v_pay_type_cd, @ad_give_ymd, 'S'), @ad_give_ymd)
								  +
								  CASE WHEN @av_company_cd IN ('C','T') THEN '>>������>' + @v_pay_group ELSE '>>��������ü' END AS REMARK,
								  dbo.XF_TO_CHAR_D(@d_pay_ymd, 'yyyyMMdd') + @v_emp_no AS ERP_REC_NO, --	ERP_REC_NO
								  '', --	ERP_DATE
								  '' --	ERP_TIME
								  ,@n_pay_payroll_id --	�޿�����ID
				END
				SET @n_cnt = @n_cnt + 1
				SET @n_total_amt = @n_total_amt + @n_real_amt
          END TRY
          BEGIN CATCH
              SET @errornumber = ERROR_NUMBER()
              SET @errormessage = ERROR_MESSAGE()

              BEGIN
                  SET @av_ret_code = 'FAILURE!'
                  SET @av_ret_message = dbo.F_FRM_ERRMSG('���κ�������ü���� ������ �Է� ����[ERR]',@v_program_id, 0200, @errormessage, @an_mod_user_id)

                  IF @@TRANCOUNT > 0
                      ROLLBACK WORK 
                  RETURN 
                   
              END
          END CATCH

		CLOSE PAY_CUR
		DEALLOCATE PAY_CUR
      END
      
      IF @n_cnt = 0
        BEGIN
            SET @av_ret_code = 'FAILURE!'
            SET @av_ret_message = dbo.F_FRM_ERRMSG('������ �����Ͱ� �������� �ʽ��ϴ�.[ERR]',@v_program_id, 0450, NULL, @an_mod_user_id)

            IF @@TRANCOUNT > 0
                ROLLBACK WORK 
             RETURN 
        END
      /*
      *   <DOCLINE> ****************************************************************************
      *   <DOCLINE> HEADER ����
      *   <DOCLINE> ****************************************************************************
      */
        BEGIN
			BEGIN TRY
				INSERT CB2_PAY_PAY_H(
					SITE_CD, --	������ڵ�
					FILE_GB, --	���ϱ���
					FILE_DATE, --	���ϻ�����
					FILE_CNT, --	ȸ��
					FILE_NM, --	�����̸�
					SUM_CNT, --	�ѰǼ�
					SUM_AMT, --	�ѱݾ�
					ERP_GET_USER_ID, --	�����
					ERP_GET_DATE, --	�����
					ERP_GET_TIME, --	��Ͻð�
					FLAG, --	���ϻ���
					trans_kind, -- ��ü����
					PAY_YMD_ID --	�޿�����ID
				)
				SELECT @av_site_cd, -- ������ڵ�
						YMD.PAY_TYPE_CD, -- �޿���������
						dbo.XF_TO_CHAR_D(@ad_give_ymd, 'yyyyMMdd'), -- ��������
						@n_file_cnt,
						SUBSTRING(@v_pay_group, 2, 4) + YMD.PAY_TYPE_CD + dbo.XF_TO_CHAR_D(@ad_give_ymd, 'yyyyMMdd') + CONVERT(nvarchar(10),@n_file_cnt) AS FILE_NM, -- �����̸�
						@n_cnt SUM_CNT,
						@n_total_amt SUM_AMT,
						dbo.XF_TO_CHAR_N(@an_mod_user_id, NULL),
						dbo.XF_TO_CHAR_D(GETDATE(), 'yyyyMMdd'),
						dbo.XF_TO_CHAR_D(GETDATE(), 'HHmiss'),
						'EE' AS DD,
						'��������ü' as trans_kind,
						YMD.PAY_YMD_ID
					FROM PAY_PAY_YMD YMD
					--INNER JOIN (SELECT PAY_YMD_ID, COUNT(*) SUM_CNT, SUM(REAL_AMT) SUM_AMT
					--			FROM PAY_PAYROLL 
					--			WHERE PAY_YMD_ID = @an_pay_ymd_id
					--				AND REAL_AMT > 0
					--			GROUP BY PAY_YMD_ID) PAY
					--		ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
					WHERE YMD.PAY_YMD_ID = @an_pay_ymd_id
					AND CLOSE_YN = 'Y'
			END TRY
			BEGIN CATCH
				SET @errornumber = ERROR_NUMBER()
				SET @errormessage = ERROR_MESSAGE()

				BEGIN
					SET @av_ret_code = 'FAILURE!'
					SET @av_ret_message = dbo.F_FRM_ERRMSG('���κ�������ü���� ��� �Է� ����[ERR]',@v_program_id, 0100, @errormessage, @an_mod_user_id)

					IF @@TRANCOUNT > 0
						ROLLBACK WORK 
					RETURN
				END
			END CATCH
      END
    -- ==============================================================================  
        -- �۾� �Ϸ�  
        -- ==============================================================================  
        SET @av_ret_code = 'SUCCESS!'  
        SET @av_ret_message = DBO.F_FRM_ERRMSG('��ü���� ������ �Ϸ��Ͽ����ϴ�.[ERR]', @v_program_id, 0400, null, @an_mod_user_id)  
    END
END;
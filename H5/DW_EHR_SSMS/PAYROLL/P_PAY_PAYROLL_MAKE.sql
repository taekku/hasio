SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PAY_PAYROLL_MAKE](
    @av_company_cd           NVARCHAR(10),   -- �λ翵��
    @av_locale_cd            NVARCHAR(10),   -- �����ڵ�
    @an_pay_ymd_id           numeric  ,    -- �޿�����ID
    @an_org_id               numeric,   -- ����
    @an_emp_id               numeric  ,    -- ���ID
    @an_mod_user_id          numeric  ,    -- ������ ID
    @av_ret_code             NVARCHAR(4000) OUTPUT,  -- ����ڵ�
    @av_ret_message          NVARCHAR(4000) OUTPUT   -- ����޽���
)   AS

    -- ***************************************************************************
    --   TITLE       : �޿�����ڼ���
    --   PROJECT     : H5 5.7
    --   AUTHOR      :
    --   PROGRAM_ID  : P_PAY_PAYROLL_MAKE
    --   ARGUMENT    : 
    --   RETURN      : ����ڵ� = SUCCESS!/FAILURE!
    --                 ����޽���
    --   COMMENT     : �ſ� ���������� �޿����޵Ǵ� ����ڸ� �����Ѵ�.
    --   HISTORY     : �ۼ� 2011.03.03
    --                 ���� 2011.05.20 KSY
    --                 MS-SQL ��ȯ : 2020.03.26 ������    				   
    -- ***************************************************************************
    --  001 �޿�,    002 �����,    003 ������,    004 ��������޿�

BEGIN
    /* �⺻������ ���Ǵ� ���� */
    DECLARE 
    	 @v_program_id        NVARCHAR(30)
        ,@v_program_nm        NVARCHAR(100)
        ,@d_pay_ymd           DATE               -- �޿�����
		,@v_pay_type_cd       NVARCHAR(10)       -- �޿����������ڵ�
		,@v_pay_ym            NVARCHAR(8)        -- �޿�������
		,@d_std_ymd           DATE 
		,@d_sta_ymd           DATE 
		,@d_end_ymd           DATE
		,@v_salary_type_cd    NVARCHAR(10)       -- �޿�����
		,@v_close_type_cd     NVARCHAR(10)       --����ڻ���
		,@d_retire_ymd        DATE               -- ��������
		,@n_cnt               NUMERIC(10)
		,@v_sub_company_cd    NVARCHAR(10)
		,@v_cam_type_cd       NVARCHAR(20)
		,@v_no_yealy_nm       NVARCHAR(4000)
		,@errornumber         NUMERIC
        ,@errormessage        NVARCHAR(4000)
        ,@an_emp_no			  NUMERIC
        ,@an_cnt_salary	      NUMERIC
        ,@an_emp_nm		      NVARCHAR(20)
        ,@av_strsum		      NVARCHAR(20)

	    /* �⺻���� �ʱⰪ ���� */
		SET @v_close_type_cd = 'PAY02';
	    SET @v_program_id    = 'P_PAY_PAYROLL_MAKE';       -- ���� ���ν����� ������
	    SET @v_program_nm    = '����ڻ���';               -- ���� ���ν����� �ѱ۹���
	    SET @v_no_yealy_nm = ' ';
	
	    SET @av_ret_code     = 'SUCCESS!';
	    SET @av_ret_message  = dbo.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null, @an_mod_user_id );

	/****************************************************************************
    ** �޿����� üũ
    *****************************************************************************/
	BEGIN
		EXECUTE dbo.P_PAY_CLOSE_CHECK @an_pay_ymd_id, @v_close_type_cd, @av_locale_cd, @av_ret_code OUTPUT, @av_ret_message  OUTPUT
	
		IF @av_ret_code = 'FAILURE!'
            BEGIN
               SET @av_ret_code = 'FAILURE!';
               SET @av_ret_message = @av_ret_message;
               RETURN 
            END
	END
	

	
    
	/***********************************************************************************************************************************
    ** �޿�����ڼ���
    ***********************************************************************************************************************************/
    -- �޿����� ��ȸ
	BEGIN
		SELECT @v_pay_type_cd = PAY_PAY_YMD.PAY_TYPE_CD,
			   @v_pay_ym	= PAY_PAY_YMD.PAY_YM,
			   @d_pay_ymd	= PAY_PAY_YMD.PAY_YMD, 
			   @d_std_ymd = PAY_PAY_YMD.STD_YMD,
			   @d_sta_ymd = PAY_PAY_YMD.STA_YMD,
			   @d_end_ymd = PAY_PAY_YMD.END_YMD
		  FROM dbo.PAY_PAY_YMD
		 WHERE PAY_PAY_YMD.PAY_YMD_ID = @an_pay_ymd_id
		
		IF @@ROWCOUNT < 1
			BEGIN
				SET @av_ret_code    = 'FAILURE!'
	            SET @av_ret_message = DBO.F_FRM_ERRMSG('�޿����ڰ� �����ϴ�.[ERR]',
	                                  @v_program_id,  0095,  null, null)
				RETURN	
			END
	END
	

	
    -- �޿����������� ��ȸ
	BEGIN
		SELECT @n_cnt = COUNT(PAY_PAY_YMD_DTL.SALARY_TYPE_CD)
		  FROM PAY_PAY_YMD_DTL
		 WHERE PAY_PAY_YMD_DTL.PAY_YMD_ID = @an_pay_ymd_id
		 
		IF @@ROWCOUNT < 1
			BEGIN
				SET @av_ret_code    = 'FAILURE!'
		        SET @av_ret_message = DBO.F_FRM_ERRMSG('�޿����������� �����ϴ�.[ERR]',
		                                  @v_program_id,  0112,  null, null)
			    RETURN	
			END
		
			
	END
	
	BEGIN 
		IF @n_cnt = 0
			BEGIN
				SET @av_ret_message = DBO.F_FRM_ERRMSG('[�޿����ڰ���] �޴����� �ش� �޿������� �޿������� ��� �ϼž߸� �մϴ�.',
                                 @v_program_id,  0100,  @errormessage, @an_mod_user_id )
	            SET @av_ret_code    = 'FAILURE!'
    	        RETURN
			END
	END
	
	

    ----------------------------------------
    -- ���������� ��������
    ----------------------------------------
    DECLARE ilist CURSOR LOCAL FORWARD_ONLY FOR
		  SELECT A.EMP_ID,
		         A.EMP_NO,
		         A.EMP_NM, 
		         B.CNT_SALARY,
		         A.EMP_NM + '(' + A.EMP_NO + ')' AS STRSUM
	        FROM VI_FRM_PHM_EMP A
 LEFT OUTER JOIN VI_PAY_MASTER B ON A.EMP_ID = B.EMP_ID
           WHERE A.COMPANY_CD = @av_company_cd
	         AND A.LOCALE_CD = @av_locale_cd
	         AND A.IN_OFFI_YN = 'Y'
	         AND B.CNT_SALARY IS NULL
	         AND B.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
	                                    FROM PAY_PAY_YMD_DTL
	                                   WHERE PAY_YMD_ID = @an_pay_ymd_id)
								         AND (@an_emp_id IS NULL OR A.EMP_ID = @an_emp_id)
								         AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)
								         
		OPEN ilist
		
		FETCH NEXT FROM ilist INTO @an_emp_id, @an_emp_no, @an_emp_nm, @an_cnt_salary, @av_strsum
		
		SET @v_no_yealy_nm = @v_no_yealy_nm + @av_strsum
		
	CLOSE ilist
	DEALLOCATE ilist
	
--	BEGIN
--		IF @v_no_yealy_nm <> ' '
--			BEGIN
--				SET @av_ret_message = '�ڽ�Ʈ���Ͱ� ���� ��� : ' + @v_no_yealy_nm;
--				SET @av_ret_code    = 'FAILURE!';
--				RETURN	
--			END
--	END
	
	
	--����޿�
	IF @v_pay_type_cd = '001' 
		--����� INSERT
       BEGIN TRY
            INSERT INTO PAY_PAYROLL (  -- �޿�����(�����)
		                     PAY_PAYROLL_ID          ,  -- �޿�����ID
		                     PAY_YMD_ID              ,  -- �޿�����ID
		                     EMP_ID                  ,  -- ���ID
		                     SUB_COMPANY_CD          ,  -- ����ȸ��
		                     SALARY_TYPE_CD          ,  -- �޿������ڵ�
		                     ORG_ID                  ,  -- �߷ɺμ�ID
		                     PAY_ORG_ID              ,  -- �޿��μ�ID
		                     POS_CD                  ,  -- ��������
		                     ACC_CD                  ,  -- �ڽ�Ʈ����
		                     BANK_CD                 ,  -- �����ڵ�
		                     ACCOUNT_NO              ,  -- ���¹�ȣ
		                     POS_GRD_CD              ,  -- �޿�����
		                     DTM_TYPE                ,  -- ��������
		                     MOD_USER_ID             ,  -- ������
		                     MOD_DATE                ,  -- �����Ͻ�
		                     TZ_CD                   ,  -- Ÿ�����ڵ�
		                     TZ_DATE                    -- Ÿ�����Ͻ�
                     )
             		SELECT 
             			NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, 
    				    T1.*
		             FROM (
		                     SELECT DISTINCT
		                            @an_pay_ymd_id AS PAY_YMD_ID,
		                            A.EMP_ID,
		                            B.COMPANY_CD,
		                            A.SALARY_TYPE_CD,
		                            ISNULL(B.ORG_ID, 99) AS ORG_ID,
		                            B.ORG_ID AS PAY_ORG_ID,
		                            A.ORG_ACC_CD,
		                            A.ACC_CD,
		                            Z.BANK_CD,
		                            Z.ACCOUNT_NO,
		                            A.PAY_POS_GRD_CD,
		                            A.DTM_TYPE,
		                            @an_mod_user_id AS mod_user_id,
		                            GETDATE() AS MOD_DATE,
		                            B.TZ_CD,
		                            GETDATE() AS TZ_DATE
		                       FROM VI_PAY_MASTER A
		           		 INNER JOIN PHM_EMP B ON A.EMP_ID = B.EMP_ID
                    LEFT OUTER JOIN (SELECT EMP_ID              ,     -- ���ID
		                                   BANK_CD             ,     -- �����ڵ�(PAY_BANK_CD)
		                                   ACCOUNT_NO               -- ���¹�ȣ
		                              FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- �޿�����(Version3.1)
		                             WHERE X.ACCOUNT_TYPE_CD  = Y.ACCOUNT_TYPE_CD
		                               AND Y.PAY_YMD_ID = @an_pay_ymd_id
		                               AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
		                            ) Z ON B.EMP_ID = Z.EMP_ID
		                INNER JOIN PAY_PAY_YMD C ON DBO.XF_NVL_D(B.RETIRE_YMD,'29991231') >= C.STA_YMD
			                 WHERE A.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
			                                             FROM PAY_PAY_YMD_DTL
			                                            WHERE PAY_YMD_ID = @an_pay_ymd_id)
			                  AND ((@an_emp_id IS NULL) OR (B.EMP_ID = @an_emp_id))
			                  AND (@an_org_id IS NULL OR B.ORG_ID = @an_org_id)
			                  AND B.COMPANY_CD = @av_company_cd
			                  AND A.ACC_CD IS NOT NULL
			                  -- AND B.IN_OFFI_YN ='Y'
			                  AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
			                  AND (A.STA_YMD BETWEEN C.STA_YMD AND C.END_YMD OR A.END_YMD BETWEEN C.STA_YMD AND C.END_YMD or (A.STA_YMD <= c.STA_YMD and A.END_YMD >= c.END_YMD))
			                  AND C.PAY_YMD_ID = @an_pay_ymd_id ) T1
		              
       END TRY
       
       BEGIN CATCH
       		SET @errornumber   = ERROR_NUMBER()
	        SET @errormessage  = ERROR_MESSAGE()
	
			SET @av_ret_code    = 'FAILURE!'
	        SET @av_ret_message = DBO.F_FRM_ERRMSG(' �޿������ �Է½� �����߻�[ERR]',
	                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0242,  null, null)
	                                  
			IF @@TRANCOUNT > 0
	            ROLLBACK WORK
	        RETURN
       END CATCH
       
       
    --�����޿�
	ELSE IF @v_pay_type_cd = '005'
		BEGIN TRY
	        INSERT INTO PAY_PAYROLL (  -- �޿�����(�����)
                     PAY_PAYROLL_ID          ,  -- �޿�����ID
                     PAY_YMD_ID              ,  -- �޿�����ID
                     EMP_ID                  ,  -- ���ID
                     SUB_COMPANY_CD          ,  -- ����ȸ��
                     SALARY_TYPE_CD          ,  -- �޿������ڵ�
                     ORG_ID                  ,  -- �߷ɺμ�ID
                     PAY_ORG_ID              ,  -- �޿��μ�ID
                     POS_CD                  ,  -- ��������
                     ACC_CD                  ,  -- �ڽ�Ʈ����
                     BANK_CD                 ,  -- �����ڵ�
                     ACCOUNT_NO              ,  -- ���¹�ȣ
                     POS_GRD_CD              ,  -- ����
                     DTM_TYPE                ,  -- ��������
                     MOD_USER_ID             ,  -- ������
                     MOD_DATE                ,  -- �����Ͻ�
                     TZ_CD                   ,  -- Ÿ�����ڵ�
                     TZ_DATE                    -- Ÿ�����Ͻ�
                     )
             SELECT NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, T1.*
               FROM (
                     SELECT DISTINCT
                            @an_pay_ymd_id AS PAY_YMD_ID,
                            A.EMP_ID,
                            B.COMPANY_CD,
                            A.SALARY_TYPE_CD,
                            B.ORG_ID,
                            B.ORG_ID PAY_ORG_ID,
                            A.ORG_ACC_CD,
                            A.ACC_CD,
                            Z.BANK_CD,
                            Z.ACCOUNT_NO,
                            A.PAY_POS_GRD_CD,
                            A.DTM_TYPE,
                            @an_mod_user_id AS MOD_USER_ID,
                            GETDATE() AS MOD_DATE,
                            B.TZ_CD,
                            GETDATE() AS TZ_DATE
                       FROM VI_PAY_MASTER A
                    INNER JOIN PHM_EMP B ON A.EMP_ID = B.EMP_ID
               LEFT OUTER JOIN (SELECT EMP_ID              ,     -- ���ID
                                       BANK_CD             ,     -- �����ڵ�(PAY_BANK_CD)
                                       ACCOUNT_NO               -- ���¹�ȣ
                              FROM PAY_ACCOUNT X
                              INNER JOIN PAY_PAY_YMD Y ON X.ACCOUNT_TYPE_CD  = Y.ACCOUNT_TYPE_CD-- �޿�����(Version3.1)
                             WHERE Y.PAY_YMD_ID = @an_pay_ymd_id
                               AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
                            ) Z ON B.EMP_ID = Z.EMP_ID
                   INNER JOIN PAY_PAY_YMD C ON B.RETIRE_YMD BETWEEN C.STA_YMD AND C.END_YMD
                WHERE A.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
                                             FROM PAY_PAY_YMD_DTL
                                            WHERE PAY_YMD_ID = @an_pay_ymd_id)
							                  AND ((@an_emp_id IS NULL) OR (B.EMP_ID = @an_emp_id))
							                  AND (@an_org_id IS NULL OR B.ORG_ID = @an_org_id)
							                  AND B.COMPANY_CD = @av_company_cd
							                  AND B.IN_OFFI_YN = 'N'
							                  AND B.EMP_ID NOT IN (SELECT EMP_ID 
							                  					     FROM PAY_PAYROLL 
							                  						WHERE PAY_YMD_ID = @an_pay_ymd_id)
							                  						  AND C.PAY_YMD_ID = @an_pay_ymd_id ) T1
              
		END TRY
	
		BEGIN CATCH
			SET @errornumber   = ERROR_NUMBER()
	        SET @errormessage  = ERROR_MESSAGE()
	
			SET @av_ret_code    = 'FAILURE!'
	        SET @av_ret_message = DBO.F_FRM_ERRMSG(' �޿������ �Է½� �����߻�[ERR]',
	                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0278,  null, null)
	                                  
			IF @@TRANCOUNT > 0
	            ROLLBACK WORK
	        RETURN
		END CATCH

	-- �����
	ELSE IF @v_pay_type_cd = '002' 
		BEGIN TRY
			INSERT INTO PAY_PAYROLL (  -- �޿�����(�����)
                     PAY_PAYROLL_ID          ,  -- �޿�����ID
                     PAY_YMD_ID              ,  -- �޿�����ID
                     EMP_ID                  ,  -- ���ID
                     SUB_COMPANY_CD          ,  -- ����ȸ��
                     SALARY_TYPE_CD          ,  -- �޿������ڵ�
                     ORG_ID                  ,  -- �߷ɺμ�ID
                     PAY_ORG_ID              ,  -- �޿��μ�ID
                     POS_CD                  ,  -- ��������
                     ACC_CD                  ,  -- �ڽ�Ʈ����
                     BANK_CD                 ,  -- �����ڵ�
                     ACCOUNT_NO              ,  -- ���¹�ȣ
                     POS_GRD_CD              ,  -- ����
                     DTM_TYPE                ,  -- ��������
                     MOD_USER_ID             ,  -- ������
                     MOD_DATE                ,  -- �����Ͻ�
                     TZ_CD                   ,  -- Ÿ�����ڵ�
                     TZ_DATE                    -- Ÿ�����Ͻ�
                     )
             SELECT NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, T1.*
               FROM (
                     SELECT DISTINCT
                            @an_pay_ymd_id AS PAY_YMD_ID,
                            A.EMP_ID,
                            B.COMPANY_CD,
                            A.SALARY_TYPE_CD,
                            B.ORG_ID,
                            B.ORG_ID PAY_ORG_ID,
                            A.ORG_ACC_CD,
                            A.ACC_CD,
                            Z.BANK_CD,
                            Z.ACCOUNT_NO,
                            A.PAY_POS_GRD_CD,
                            A.DTM_TYPE,
                            @an_mod_user_id AS MOD_USER_ID,
                            GETDATE() AS MOD_DATE,
                            B.TZ_CD,
                            GETDATE() AS TZ_DATE
                       FROM VI_PAY_MASTER A
                 INNER JOIN PHM_EMP B ON A.EMP_ID = B.EMP_ID
            LEFT OUTER JOIN (SELECT EMP_ID              ,     -- ���ID
                                   BANK_CD             ,     -- �����ڵ�(PAY_BANK_CD)
                                   ACCOUNT_NO               -- ���¹�ȣ
                              FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- �޿�����(Version3.1)
                             WHERE X.ACCOUNT_TYPE_CD  = Y.ACCOUNT_TYPE_CD
                               AND Y.PAY_YMD_ID = @an_pay_ymd_id
                               AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
                            ) Z ON B.EMP_ID = Z.EMP_ID
                INNER JOIN PAY_PAY_YMD C ON C.PAY_YMD BETWEEN A.STA_YMD AND A.END_YMD
                WHERE A.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
                                             FROM PAY_PAY_YMD_DTL
                                            WHERE PAY_YMD_ID = @an_pay_ymd_id
                                              AND ISNULL(BONUS_RATE,0) > 0)
                  AND ((@an_emp_id IS NULL) OR (B.EMP_ID = @an_emp_id))
                  AND (@an_org_id IS NULL OR B.ORG_ID = @an_org_id)
                  AND B.COMPANY_CD = @av_company_cd
                  AND B.IN_OFFI_YN ='Y'
                  AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
                  AND B.HIRE_YMD <= C.PAY_YMD
                  AND C.PAY_YMD_ID = @an_pay_ymd_id ) T1
		END TRY
		
		BEGIN CATCH
			SET @errornumber   = ERROR_NUMBER()
	        SET @errormessage  = ERROR_MESSAGE()
	
			SET @av_ret_code    = 'FAILURE!'
	        SET @av_ret_message = DBO.F_FRM_ERRMSG(' �޿������ �Է½� �����߻�[ERR]',
	                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0420,  null, null)
	                                  
			IF @@TRANCOUNT > 0
	            ROLLBACK WORK
	        RETURN
		END CATCH
		
    -- ������
    ELSE IF @v_pay_type_cd = '003' 
    	--����� INSERT
    	BEGIN TRY
	    	INSERT INTO PAY_PAYROLL (  -- �޿�����(�����)
                     PAY_PAYROLL_ID          ,  -- �޿�����ID
                     PAY_YMD_ID              ,  -- �޿�����ID
                     EMP_ID                  ,  -- ���ID
                     SUB_COMPANY_CD          ,  -- ����ȸ��
                     SALARY_TYPE_CD          ,  -- �޿������ڵ�
                     ORG_ID                  ,  -- �߷ɺμ�ID
                     PAY_ORG_ID              ,  -- �޿��μ�ID
                     POS_CD                  ,  -- ��������
                     ACC_CD                  ,  -- �ڽ�Ʈ����
                     BANK_CD                 ,  -- �����ڵ�
                     ACCOUNT_NO              ,  -- ���¹�ȣ
                     POS_GRD_CD              ,  -- ����
                     DTM_TYPE                ,  -- ��������
                     MOD_USER_ID             ,  -- ������
                     MOD_DATE                ,  -- �����Ͻ�
                     TZ_CD                   ,  -- Ÿ�����ڵ�
                     TZ_DATE                    -- Ÿ�����Ͻ�
                     )
             SELECT NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID, T1.*
               FROM (
                     SELECT DISTINCT
                            @an_pay_ymd_id AS PAY_YMD_ID,
                            A.EMP_ID,
                            B.COMPANY_CD,
                            A.SALARY_TYPE_CD,
                            B.ORG_ID,
                            B.ORG_ID PAY_ORG_ID,
                            A.ORG_ACC_CD,
                            A.ACC_CD,
                            Z.BANK_CD,
                            Z.ACCOUNT_NO,
                            A.PAY_POS_GRD_CD,
                            A.DTM_TYPE,
                            @an_mod_user_id AS MOD_USER_ID,
                            GETDATE() AS MOD_DATE,
                            B.TZ_CD,
                            GETDATE() AS TZ_DATE
                       FROM VI_PAY_MASTER A 
                     INNER JOIN PHM_EMP B ON A.EMP_ID = B.EMP_ID
                LEFT OUTER JOIN (SELECT EMP_ID              ,     -- ���ID
                                        BANK_CD             ,     -- �����ڵ�(PAY_BANK_CD)
                                        ACCOUNT_NO               -- ���¹�ȣ
                                   FROM PAY_ACCOUNT X
                             INNER JOIN PAY_PAY_YMD Y ON X.ACCOUNT_TYPE_CD  = Y.ACCOUNT_TYPE_CD -- �޿�����(Version3.1)
	                             WHERE Y.PAY_YMD_ID = @an_pay_ymd_id
	                               AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
	                            ) Z ON B.EMP_ID = Z.EMP_ID
                     INNER JOIN PAY_PAY_YMD C ON C.PAY_YMD BETWEEN A.STA_YMD AND A.END_YMD
                WHERE A.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
                                             FROM PAY_PAY_YMD_DTL
                                            WHERE PAY_YMD_ID = @an_pay_ymd_id)
                  AND ((@an_emp_id IS NULL) OR (B.EMP_ID = @an_emp_id))
                  AND (@an_org_id IS NULL OR B.ORG_ID = @an_org_id)
                  AND B.COMPANY_CD = @av_company_cd
                  AND B.IN_OFFI_YN ='Y'
                  AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
                  AND B.HIRE_YMD <= C.PAY_YMD
                  AND C.PAY_YMD_ID = @an_pay_ymd_id ) T1
    	END TRY
    	
    	BEGIN CATCH
	    	SET @errornumber   = ERROR_NUMBER()
	        SET @errormessage  = ERROR_MESSAGE()
	
			SET @av_ret_code    = 'FAILURE!'
	        SET @av_ret_message = DBO.F_FRM_ERRMSG(' �޿������ �Է½� �����߻�[ERR]',
	                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0498,  null, null)
	                                  
			IF @@TRANCOUNT > 0
	            ROLLBACK WORK
	        RETURN
    	END CATCH
		
    -- ��������
    ELSE IF @v_pay_type_cd = '004' 
    	--����� INSERT
    	BEGIN TRY 
    		INSERT INTO PAY_PAYROLL (  -- �޿�����(�����)
                     PAY_PAYROLL_ID          ,  -- �޿�����ID
                     PAY_YMD_ID              ,  -- �޿�����ID
                     EMP_ID                  ,  -- ���ID
                     SUB_COMPANY_CD          ,  -- ����ȸ��
                     SALARY_TYPE_CD          ,  -- �޿������ڵ�
                     ORG_ID                  ,  -- �߷ɺμ�ID
                     PAY_ORG_ID              ,  -- �޿��μ�ID
                     POS_CD                  ,  -- ��������
                     ACC_CD                  ,  -- �ڽ�Ʈ����
                     BANK_CD                 ,  -- �����ڵ�
                     ACCOUNT_NO              ,  -- ���¹�ȣ
                     POS_GRD_CD              ,  -- ����
                     DTM_TYPE                ,  -- ��������
                     MOD_USER_ID             ,  -- ������
                     MOD_DATE                ,  -- �����Ͻ�
                     TZ_CD                   ,  -- Ÿ�����ڵ�
                     TZ_DATE                    -- Ÿ�����Ͻ�
                     )
             SELECT NEXT VALUE FOR DBO.S_PAY_SEQUENCE AS PAY_PAYROLL_ID
                  , T1.*
               FROM (
                     SELECT DISTINCT
                            @an_pay_ymd_id AS PAY_YMD_ID,
                            A.EMP_ID,
                            B.COMPANY_CD,
                            A.SALARY_TYPE_CD,
                            B.ORG_ID,
                            B.ORG_ID PAY_ORG_ID,
                            A.ORG_ACC_CD,
                            A.ACC_CD,
                            Z.BANK_CD,
                            Z.ACCOUNT_NO,
                            A.PAY_POS_GRD_CD,
                            A.DTM_TYPE,
                            @an_mod_user_id AS MOD_USER_ID,
                            GETDATE() AS MOD_DATE,
                            B.TZ_CD,
                            GETDATE() AS TZ_DATE
                       FROM VI_PAY_MASTER A
                            INNER JOIN PHM_EMP B ON ( A.EMP_ID = B.EMP_ID )
                            LEFT OUTER JOIN (SELECT EMP_ID              ,     -- ���ID
				                                   BANK_CD       ,     -- �����ڵ�(PAY_BANK_CD)
				                                   ACCOUNT_NO               -- ���¹�ȣ
				                              FROM PAY_ACCOUNT X , PAY_PAY_YMD Y -- �޿�����(Version3.1)
				                             WHERE X.ACCOUNT_TYPE_CD  = Y.ACCOUNT_TYPE_CD
				                               AND Y.PAY_YMD_ID = @an_pay_ymd_id
				                               AND Y.PAY_YMD BETWEEN X.STA_YMD AND X.END_YMD
				                            ) Z ON B.EMP_ID = Z.EMP_ID
		                    INNER JOIN PAY_PAY_YMD C ON C.PAY_YMD BETWEEN A.STA_YMD AND A.END_YMD
		                    INNER JOIN VI_DTM_YY_REST_PAY D ON ( D.PAY_YM = C.PAY_YM 
		                  								     AND A.EMP_ID = D.EMP_ID )
	                WHERE A.SALARY_TYPE_CD IN (SELECT SALARY_TYPE_CD
	                                             FROM PAY_PAY_YMD_DTL
	                                            WHERE PAY_YMD_ID = @an_pay_ymd_id)
	                  AND ((@an_emp_id IS NULL) OR (B.EMP_ID = @an_emp_id))
	                  AND (@an_org_id IS NULL OR B.ORG_ID = @an_org_id)
	                  AND B.COMPANY_CD = @av_company_cd
	                  AND D.KIND = '10'  -- �޿����������� ���
	                  AND ISNULL(D.PAY_YY_NUM,0) != 0
	                 -- AND B.IN_OFFI_YN ='Y'
	                  AND B.EMP_ID NOT IN (SELECT EMP_ID FROM PAY_PAYROLL WHERE PAY_YMD_ID = @an_pay_ymd_id)
	                  AND (A.STA_YMD BETWEEN C.STA_YMD AND C.END_YMD OR A.END_YMD BETWEEN C.STA_YMD AND C.END_YMD OR (A.STA_YMD <= C.STA_YMD AND A.END_YMD >= C.END_YMD))
	                  AND C.PAY_YMD_ID = @an_pay_ymd_id ) T1
    	END TRY 
    	
    	BEGIN CATCH
    		SET @errornumber   = ERROR_NUMBER()
	        SET @errormessage  = ERROR_MESSAGE()
	
			SET @av_ret_code    = 'FAILURE!'
	        SET @av_ret_message = DBO.F_FRM_ERRMSG(' �޿������ �Է½� �����߻�[ERR]',
	                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  0581,  null, null)
	                                  
			IF @@TRANCOUNT > 0
	            ROLLBACK WORK
	        RETURN
    	END CATCH 
    	
    	
	-- ��ü������ȸ�Ͽ� ����� ���°�� �űԷ� �����Ѵ�.
	BEGIN TRY 
		INSERT INTO PAY_SAP_VENDOR(EMPNO           ,  -- ���
                                   GUBUN           ,  -- ����
                                   ACCOUNT_TYPE_CD ,  -- ���±���(01:�޿� 03:���)
                                   IDATE           ,  -- �Է�����
                                   ITIME           ,  -- �Է½ð�
                                   ENAME           ,  -- ����
                                   IDNUM           ,  -- �ֹι�ȣ
                                   BANKN           ,  -- �����ڵ�
                                   ACCNT           ,  -- ���¹�ȣ
                                   HOLDN           ,  -- ������
                                   FLAG               -- ���࿩��
                                  )
                           SELECT A.EMP_NO,
                                  'N' ,
                                  B.ACCOUNT_TYPE_CD,
                                  DBO.XF_TO_CHAR_D(GETDATE(),'YYYYMMDD'),
                                  DBO.XF_TO_CHAR_D(GETDATE(),'HHMISS'),
                                  A.EMP_NM,
                                  A.CTZ_NO,
                                  B.BANK_CD    ,     -- �����ڵ�(PAY_BANK_CD)
                                  DBO.XF_REPLACE(B.ACCOUNT_NO,'-',''), -- ���¹�ȣ SAP �����[���±��븮]�� ���ڸ� �־��ּ���..�� (2013.10.15 �赿���븮 ��ȭ��Ȯ����)
                                  DBO.XF_NVL_C(B.HOLDER_NM,A.EMP_NM) , -- ������
                                  'N'
                             FROM VI_FRM_PHM_EMP A
                           INNER JOIN PAY_ACCOUNT B ON ( A.EMP_ID = B.EMP_ID )
                            WHERE B.ACCOUNT_TYPE_CD = '01'  -- �޿����¸� sap�� �������̽���.
                              AND B.STA_YMD = (SELECT MAX(STA_YMD)
                                                 FROM PAY_ACCOUNT
                                                WHERE EMP_ID = B.EMP_ID
                 AND GETDATE() BETWEEN STA_YMD AND END_YMD)
                              AND A.EMP_NO NOT IN (SELECT EMPNO
                                                     FROM PAY_SAP_VENDOR)
                              AND COMPANY_CD = @av_company_cd
                              AND LOCALE_CD = @av_locale_cd
	END TRY 
	
	BEGIN CATCH
		SET @errornumber   = ERROR_NUMBER()
        SET @errormessage  = ERROR_MESSAGE()

		SET @av_ret_code    = 'FAILURE!'
        SET @av_ret_message = DBO.F_FRM_ERRMSG('���VENDOR SAP���� �� �����߻�[ERR]',
                                  @v_program_id + CHAR(13) + CHAR(13) + DBO.XF_SUBSTRB(@errormessage, 1,200),  633,  null, null)
                                  
		IF @@TRANCOUNT > 0
            ROLLBACK WORK
        RETURN
	END CATCH
    	
    	
    	
-- ***********************************************************
    -- �۾� �Ϸ�
    -- ***********************************************************
    SET @av_ret_code    = 'SUCCESS!';
    SET @av_ret_message  = DBO.F_FRM_ERRMSG('�޿������ �����Ϸ�..',
                                     @v_program_id,  0900,  null, @an_mod_user_id
                                    );
    	
		
END -- ��
GO

IF NOT EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'MS_SSMA_SOURCE' , N'SCHEMA',N'dbo', N'PROCEDURE',N'P_PAY_PAYROLL_MAKE', NULL,NULL))
	EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'H551.P_PAY_PAYROLL_MAKE' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'P_PAY_PAYROLL_MAKE'
ELSE
BEGIN
	EXEC sys.sp_updateextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'H551.P_PAY_PAYROLL_MAKE' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'P_PAY_PAYROLL_MAKE'
END
GO



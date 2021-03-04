USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_ESTIMATION_MAKE]    Script Date: 2021-01-28 ���� 4:53:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_REP_ESTIMATION_MAKE]
    @av_company_cd     NVARCHAR(10),			-- ȸ���ڵ�
    @av_locale_cd      NVARCHAR(10),			-- �����ڵ�
    @av_calc_type_cd   NVARCHAR(10),			-- ���걸�� ('03' : �����߰�)
	@ad_std_ymd        DATE,				-- ��������
	@an_pay_group_id   NUMERIC(38),				-- �޿��׷�
	@an_org_id         NUMERIC(38),				-- �Ҽ�ID
    @an_emp_id         NUMERIC(38),				-- ���ID
    @an_mod_user_id    NUMERIC(38),				-- ������
    @av_ret_code                   VARCHAR(500)    OUTPUT, -- ����ڵ�*/    
    @av_ret_message                VARCHAR(4000)    OUTPUT  -- ����޽���*/    
AS
    -- ***************************************************************************
    --   TITLE       : �����߰��
    --   PROJECT     : EHR
    --   AUTHOR      : ȭ��Ʈ�������
    --   PROGRAM_ID  : P_REP_ESTIMATION
    --   RETURN      : 1) SUCCESS!/FAILURE!
    --                 2) ��� �޽���
    --   COMMENT     : �����߰��
    --   HISTORY     : �ۼ� 2020.10.01
    -- ***************************************************************************
BEGIN
	SET NOCOUNT ON;
   DECLARE @v_program_id          NVARCHAR(30),		-- ���α׷�ID
           @v_program_nm          NVARCHAR(100),	-- ���α׷���
           @d_mod_date            DATETIME2(0),		-- ������
 
           @n_auto_yn_cnt		  INT,				-- ��ǥ����
		   @d_begin_date		  DATE,				-- �߰�� 1����
		   @n_rep_calc_list_id    NUMERIC(38),		-- ��������ID
           @n_emp_id              NUMERIC(38),		-- ���ID
           @n_org_id              NUMERIC(38),		-- ����ID
		   @v_org_nm              NVARCHAR(100),	-- ������
		   @v_org_line            NVARCHAR(1000),	-- ��������
           @v_pos_grd_cd          NVARCHAR(50),		-- ���� [PHM_POS_GRD_CD]
           @v_pos_cd              NVARCHAR(50),		-- ����	[PHM_POS_CD]
           @v_duty_cd             NVARCHAR(50),		-- ��å [PHM_DUTY_CD]
           @v_yearnum_cd          NVARCHAR(50),		-- ȣ��
		   @v_mgr_type_cd		  NVARCHAR(50),		-- �������� [PHM_MGR_TYPE_CD]
		   @v_job_position_cd	  NVARCHAR(50),		-- ���� [PHM_JOB_POSTION_CD]
		   @v_job_cd			  NVARCHAR(50),		-- ����
		   @v_emp_kind_cd		  NVARCHAR(50),		-- �ٷα����ڵ� [PHM_EMP_KIND_CD]
		   @v_officers_yn		  NVARCHAR(1),		-- �ӿ�����
		   @v_retire_type_cd	  NVARCHAR(50),		-- ���������ڵ� [CAM_CAU_CD]
		   @d_first_join_ymd	  DATETIME2,		-- �����Ի���
           @d_group_ymd           DATETIME2,		-- �׷��Ի���
           @d_retire_ymd          DATETIME2,		-- ������
           @d_sta_ymd             DATETIME2,		-- �Ի���(���������)
           @d_end_ymd             DATETIME2,		-- ������
		   @v_pay_group			  NVARCHAR(50),		-- �޿��׷�
		   @v_biz_cd			  NVARCHAR(50),		-- �����
		   @v_reg_biz_cd		  NVARCHAR(50),		-- �Ű����� 
           @n_retire_turn_mon     NUMERIC(15),		-- ���ο���������ȯ��
		   @v_pay_meth_cd		  NVARCHAR(50),		-- �޿����޹���ڵ�[PAY_METH_CD]
		   @v_emp_cls_cd		  NVARCHAR(50),		-- ��������ڵ�[PAY_EMP_CLS_CD]
		   @v_ins_type_yn		  NVARCHAR(1),		-- �������ݰ��Կ���
		   @v_ins_type_cd		  NVARCHAR(10),		-- �������ݱ���
		   @v_ins_nm			  NVARCHAR(80),		-- �������ݻ���ڸ�
		   @v_ins_bizno			  NVARCHAR(50),		-- �������ݻ�����Ϲ�ȣ
		   @v_ins_account_no	  NVARCHAR(150),		-- �������ݰ��¹�ȣ
		   @d_retr_ymd			  DATETIME2,		-- �����ݱ������
		   @v_rep_mid_yn		  NVARCHAR(1)		-- �߰����꿩��

   SET @v_program_id = '[P_REP_ESTIMATION_MAKE]';
   SET @v_program_nm = '�����߰�� ����ڻ���';

   SET @av_ret_code     = 'SUCCESS!'
   SET @av_ret_message  = dbo.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null,  @an_mod_user_id)
   SET @d_mod_date = dbo.xf_sysdate(0)
   SET @d_begin_date = dbo.XF_TO_DATE(dbo.XF_TO_CHAR_D(@ad_std_ymd, 'YYYYMM') + '01', 'YYYYMMDD')	-- �߰�� 1����
PRINT('���� ===> ' + CONVERT(VARCHAR, dbo.XF_SYSDATE(0)))
   -- *************************************************************
   -- ��ǥ���� Check
   -- *************************************************************
   SET @n_auto_yn_cnt = 0
   BEGIN
      SELECT @n_auto_yn_cnt = COUNT(*)
	    FROM REP_CALC_LIST A
       WHERE A.COMPANY_CD = @av_company_cd
	     AND A.CALC_TYPE_CD = @av_calc_type_cd
		 AND A.PAY_YMD = @ad_std_ymd
		 AND A.C1_END_YMD = @ad_std_ymd
		 AND ISNULL(A.AUTO_YN, 'N') = 'Y'
		 AND (@an_pay_group_id is NULL OR
			 dbo.F_PAY_GROUP_CHK(@an_pay_group_id, A.EMP_ID, @ad_std_ymd) = @an_pay_group_id) -- �޿��׷�Ȯ��
         AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)                                    -- �Է��� �ҼӰ� �ִٸ� �Է��� �Ҽ� �ƴϸ� ��ü
         AND (@an_emp_id IS NULL OR A.EMP_ID = @an_emp_id)                                    -- �Է��� ����� �ִٸ� �Է��� ��� �ƴϸ� ��ü
	  
	  IF @n_auto_yn_cnt > 0
		 BEGIN
			SET @av_ret_code = 'FAILURE!'
            SET @av_ret_message  = dbo.F_FRM_ERRMSG('�̹� ��ǥó���� �Ǿ����ϴ�. ��ǥ ��� �� �۾��Ͻʽÿ�!', @v_program_id,  0001,  null,  @an_mod_user_id)

            RETURN
		 END
   END

   -- *************************************************************
   -- ������ �ʱ�ȭ
   -- *************************************************************
   BEGIN
      DELETE FROM REP_CALC_LIST
	   WHERE COMPANY_CD = @av_company_cd
	     AND CALC_TYPE_CD = @av_calc_type_cd
		 AND PAY_YMD = @ad_std_ymd
		-- AND C1_END_YMD = @ad_std_ymd
		 AND (@an_pay_group_id is NULL OR
			 dbo.F_PAY_GROUP_CHK(@an_pay_group_id, EMP_ID, @ad_std_ymd) = @an_pay_group_id) -- �޿��׷�Ȯ��
         AND (@an_org_id IS NULL OR ORG_ID = @an_org_id)                                    -- �Է��� �ҼӰ� �ִٸ� �Է��� �Ҽ� �ƴϸ� ��ü
         AND (@an_emp_id IS NULL OR EMP_ID = @an_emp_id)                                    -- �Է��� ����� �ִٸ� �Է��� ��� �ƴϸ� ��ü

	 IF @@ERROR <> 0
		BEGIN
			SET @av_ret_code    = 'FAILURE!'
			SET @av_ret_message = dbo.F_FRM_ERRMSG('���� ���� ������ �����߻�', @v_program_id , 0030 , null,  @an_mod_user_id)
			
			RETURN
		END

   END
PRINT('����� START ���� ===> ' + CONVERT(VARCHAR, dbo.XF_SYSDATE(0)))
   -- *************************************************************
   -- �߰�� ����� ����
   -- *************************************************************
   BEGIN
        DECLARE REP_CUR CURSOR LOCAL FORWARD_ONLY FOR
            SELECT A.EMP_ID																	-- ���ID
                  ,A.ORG_ID																	-- ����ID
				  ,A.POS_GRD_CD																-- ���� [PHM_POS_GRD_CD]
                  ,A.POS_CD																	-- ���� [PHM_POS_CD]
                  ,A.DUTY_CD																-- ��å [PHM_DUTY_CD]
                  ,A.YEARNUM_CD																-- ȣ��
				  ,A.MGR_TYPE_CD															-- ���������ڵ�[PHM_MGR_TYPE_CD]
				  ,A.JOB_POSITION_CD														-- �����ڵ�[PHM_JOB_POSTION_CD]
				  ,A.JOB_CD																	-- �����ڵ�
				  ,A.EMP_KIND_CD															-- �ٷα����ڵ� [PHM_EMP_KIND_CD]
				  ,dbo.F_REP_EXECUTIVE_RETIRE_YN(@av_company_cd, @av_locale_cd, @ad_std_ymd, A.EMP_ID,'1')		-- �ӿ�����
				  ,A.FIRST_JOIN_YMD															-- �����Ի���
                  ,dbo.XF_NVL_D(A.GROUP_YMD,A.HIRE_YMD)   							        -- �׷��Ի���
                  ,ISNULL(A.RETIRE_YMD, @ad_std_ymd)										-- ������ OR ������
                  ,dbo.XF_NVL_D((SELECT RETR_YMD
                                  FROM PAY_PHM_EMP
                                 WHERE EMP_ID = A.EMP_ID ), dbo.XF_NVL_D(A.GROUP_YMD, A.HIRE_YMD)) AS C1_STA_YMD -- ���������
                  ,ISNULL(A.RETIRE_YMD, @ad_std_ymd) AS C1_END_YMD							-- ����������
                  ,dbo.F_REP_PEN_RETIRE_MON(A.EMP_ID, A.RETIRE_YMD) AS RETIRE_TURN          -- ���ο���������ȯ��
				  ,dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', @ad_std_ymd, '1') AS ORG_NM
				  ,dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', @ad_std_ymd, 'LL') AS ORG_LINE
             FROM VI_PAY_PHM_EMP A
            WHERE A.COMPANY_CD = @av_company_cd
              AND A.LOCALE_CD = @av_locale_cd                                               -- ��Ű�� �⺻(KO)
              AND A.EMP_KIND_CD != '9'                                                      -- �̱����� �ƴ� ����
			  AND A.DUTY_CD != '018'														-- ����̻� ����
			  AND DBO.XF_SUBSTR(A.EMP_NO, 1, 1) != 'Z'										-- 'Z'�����ϴ� ��� ����
              AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)                             -- �Է��� �ҼӰ� �ִٸ� �Է��� �Ҽ� �ƴϸ� ��ü
              AND (@an_emp_id IS NULL OR A.EMP_ID = @an_emp_id)                             -- �Է��� ����� �ִٸ� �Է��� ��� �ƴϸ� ��ü
			  AND dbo.XF_NVL_D(A.GROUP_YMD, A.HIRE_YMD) <= @ad_std_ymd						-- ������ ���� �Ի���
              --AND dbo.XF_NVL_D(A.GROUP_YMD, A.HIRE_YMD) <= DATEADD(MM, 1, DATEADD(YYYY, -1, @ad_std_ymd))  -- �Ի�1�� �̻�Ȼ��
			  AND (@an_pay_group_id is NULL OR
				  dbo.F_PAY_GROUP_CHK(@an_pay_group_id, A.EMP_ID, @ad_std_ymd) = @an_pay_group_id) -- �޿��׷�Ȯ��
              AND (A.RETIRE_YMD IS NULL OR A.RETIRE_YMD >= @d_begin_date)					-- �������� NULL OR �������� ���� ������

            OPEN REP_CUR

            FETCH REP_CUR INTO @n_emp_id , @n_org_id, @v_pos_grd_cd , @v_pos_cd, @v_duty_cd , @v_yearnum_cd , @v_mgr_type_cd , 
							   @v_job_position_cd, @v_job_cd , @v_emp_kind_cd , @v_officers_yn, @d_first_join_ymd ,
							   @d_group_ymd , @d_retire_ymd ,@d_sta_ymd , @d_end_ymd , @n_retire_turn_mon,
							   @v_org_nm, @v_org_line

            WHILE (@@FETCH_STATUS = 0)

			-- ***************************************   
			-- 1. �⺻�ڷ�    
			-- *************************************** 

            BEGIN
--PRINT('@n_emp_id ===> ' + CONVERT(VARCHAR, @n_emp_id))
				BEGIN
				   IF @d_retire_ymd > @ad_std_ymd
				      BEGIN
					     SET @d_retire_ymd = @ad_std_ymd
						 SET @d_end_ymd = @ad_std_ymd
					  END
				END
				-- ������, ��������
				--SET @v_org_nm = dbo.F_FRM_ORM_ORG_NM(@n_org_id, 'KO', @ad_std_ymd, '1')				 -- ������
				--SET @v_org_line = dbo.F_FRM_ORM_ORG_NM(@n_org_id, 'KO', @ad_std_ymd, 'LL')			 -- ��������
					     
				-- �޿�������(PAY_PHM_EMP)���� ���������, �޿����޹��, ������������� �����´�.
				SET @v_pay_meth_cd = NULL
				SET @v_emp_cls_cd  = NULL
				BEGIN      
				   SELECT @v_pay_meth_cd = PAY_METH_CD		-- �޿����޹���ڵ�[PAY_METH_CD] 
						 ,@v_emp_cls_cd  = EMP_CLS_CD		-- ��������ڵ�[PAY_EMP_CLS_CD]   								     
					 FROM PAY_PHM_EMP      
					WHERE EMP_ID = @n_emp_id      
				   IF @@ERROR != 0                       
					  BEGIN      
						 SET @d_retr_ymd = @d_retire_ymd      
					  END      
				END

				---- ����� 
				SET @v_biz_cd = dbo.F_ORM_ORG_BIZ(@n_org_id, @ad_std_ymd, 'PAY')
				set @v_biz_cd = ISNULL( @v_biz_cd, '001' )

				-- �Ű����� 
				SET @v_reg_biz_cd = dbo.F_ORM_ORG_BIZ(@n_org_id, @ad_std_ymd, 'REG')

				-- �޿��׷��ڵ�
				SET @v_pay_group = NULL
				BEGIN 
				   SELECT @v_pay_group = PAY_GROUP
					 FROM dbo.PAY_GROUP
                    WHERE PAY_GROUP_ID = @an_pay_group_id
                   
				   IF @@ERROR != 0
					BEGIN
						SET @v_pay_group = NULL
					END

			    END
				-- �������ݰ��Կ���, �������ݱ���
				SET @v_ins_type_yn = 'N'
				SET @v_ins_type_cd = NULL
				SET @v_ins_nm = NULL
				SET @v_ins_bizno = NULL
				SET @v_ins_account_no = NULL

				BEGIN 
				   SELECT @v_ins_type_yn = CASE WHEN INS_TYPE_CD IN ('10', '20') THEN 'Y' ELSE 'N' END
						 ,@v_ins_type_cd = INS_TYPE_CD
						 ,@v_ins_nm = INSUR_NM
						 ,@v_ins_bizno = INSUR_BIZ_NO
						 ,@v_ins_account_no = IRP_ACCOUNT_NO
					 FROM dbo.REP_INSUR_MON
                    WHERE EMP_ID = @n_emp_id
					  AND @ad_std_ymd BETWEEN STA_YMD AND END_YMD

                   IF @@ERROR != 0
					  BEGIN
						 SET @v_ins_type_yn = 'N'
						 SET @v_ins_type_cd = NULL
					  END
				END

				-- �߰����꿩��
				SET @v_rep_mid_yn = 'N'
				BEGIN
				   SELECT TOP 1 @v_rep_mid_yn = 'Y'
					FROM REP_CALC_LIST
					WHERE REP_MID_YN = 'Y'  -- CALC_TYPE_CD = '02' --�߰�����  ****ȸ�縶�� �����ؾ���    
                    AND END_YN = '1' --�ϷῩ��    
                    AND EMP_ID = @n_emp_id    
                    AND REP_CALC_LIST_ID <> @n_rep_calc_list_id 
					AND CALC_TYPE_CD IN ('01','02')
					AND C1_END_YMD < @d_end_ymd  

				   IF @@ROWCOUNT < 1
					BEGIN
						SET @v_rep_mid_yn = 'N'
					END

				END
--PRINT('@d_group_ymd ===> ' + CONVERT(VARCHAR, @d_group_ymd))
--PRINT('1���� ===> ' + CONVERT(VARCHAR, DATEADD(MM, 1, DATEADD(YYYY, -1, @ad_std_ymd))))
            SET @n_rep_calc_list_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE

            BEGIN TRY
                    INSERT INTO dbo.REP_CALC_LIST (		-- �����ݰ������
								REP_CALC_LIST_ID        -- �����ݰ������ID
								,COMPANY_CD				-- ȸ���ڵ�
								,PAY_YMD				-- ������
								,EMP_ID                 -- ���ID
								,CALC_TYPE_CD			-- ���걸��[REP_CALC_TYPE_CD] 
								,RETIRE_YMD				-- ������ 
								,CALC_RETIRE_CD			-- ����(����)����[REP_CALC_RETIRE_CD]
								,ORG_ID					-- �߷ɺμ�ID 
								,PAY_ORG_ID				-- �޿��μ�ID 
								,POS_GRD_CD				-- �����ڵ� [PHM_POS_GRD_CD]
								,POS_CD					-- �����ڵ� [PHM_POS_CD]
								,ORG_NM					-- ������
								,ORG_LINE				-- ��������
								,BIZ_CD					-- �����
								,REG_BIZ_CD				-- �Ű�����
								,DUTY_CD				-- ��å�ڵ� [PHM_DUTY_CD]
								,YEARNUM_CD				-- ȣ���ڵ� [PHM_YEARNUM_CD]
								,MGR_TYPE_CD			-- ���������ڵ�[PHM_MGR_TYPE_CD]
								,JOB_POSITION_CD		-- �����ڵ�[PHM_JOB_POSTION_CD]
								,JOB_CD					-- �����ڵ�
								,PAY_METH_CD			-- �޿����޹��[PAY_METH_CD]
								,EMP_CLS_CD				-- �������[PAY_EMP_CLS_CD]
								,EMP_KIND_CD			-- �ٷα����ڵ� [PHM_EMP_KIND_CD]
								,OFFICERS_YN			-- �ӿ�����
								,RETIRE_TYPE_CD			-- �������� 
								,CAM_TYPE_CD			-- �߷����� 
								,ARMY_HIRE_YMD			-- ����°���(����)�Ի��� 
								,CALCU_TPYE				-- ��걸��
								,PAY_GROUP				-- �޿��׷�
								,FIRST_HIRE_YMD			-- �����Ի���
								,REP_MID_YN				-- �߰��������Կ���
								,INS_TYPE_YN			-- �������ݰ��Կ���
								,INS_TYPE_CD			-- ������������[RMP_INS_TYPE_CD]
								,REP_ANNUITY_BIZ_NM		-- �������ݻ���ڸ�
								,REP_ANNUITY_BIZ_NO		-- �������ݻ�����Ϲ�ȣ
								,REP_ACCOUNT_NO			-- �������ݰ��¹�ȣ
								,FLAG					-- 1��̸�����
								,FLAG2					-- �߰�����(�ӱ���ũY����N)
								,C1_STA_YMD				-- ������(��)����� 
                                ,C1_END_YMD				-- ��(��)������
								,SUM_END_YMD			-- ���� ������
								,RETIRE_TURN			-- ���ο���������ȯ��
								,MOD_DATE				-- �����Ͻ�
								,MOD_USER_ID			-- ������
								,TZ_CD					-- Ÿ�����ڵ�(�Է���)
								,TZ_DATE				-- Ÿ�����Ͻ�(�Է��Ͻ�)
                            )
                        VALUES (  
                                @n_rep_calc_list_id     -- �����ݰ������ID
								,@av_company_cd			-- ȸ���ڵ�
								,@ad_std_ymd			-- ������
								,@n_emp_id              -- ���ID
								,@av_calc_type_cd       -- ���걸��[REP_CALC_TYPE_CD] 
								,@d_retire_ymd          -- ������ 
								,'06'					-- ����(����)����[REP_CALC_RETIRE_CD]
								,@n_org_id				-- �߷ɺμ�ID 
								,@n_org_id				-- �޿��μ�ID 
								,@v_pos_grd_cd			-- �����ڵ� [PHM_POS_GRD_CD]
								,@v_pos_cd				-- �����ڵ� [PHM_POS_CD]
								,@v_org_nm				-- ������
								,@v_org_line			-- ��������
								,@v_biz_cd				-- �����
								,@v_reg_biz_cd			-- �Ű�����
								,@v_duty_cd				-- ��å�ڵ� [PHM_DUTY_CD]
								,@v_yearnum_cd			-- ȣ���ڵ� [PHM_YEARNUM_CD]
								,@v_mgr_type_cd			-- ���������ڵ�[PHM_MGR_TYPE_CD]
								,@v_job_position_cd		-- �����ڵ�[PHM_JOB_POSTION_CD]
								,@v_job_cd				-- �����ڵ�
								,@v_pay_meth_cd			-- �޿����޹��[PAY_METH_CD]
								,@v_emp_cls_cd			-- �������[PAY_EMP_CLS_CD]
								,@v_emp_kind_cd         -- �ٷα����ڵ� [PHM_EMP_KIND_CD]
								,@v_officers_yn			-- �ӿ�����
								,NULL					-- �������� 
								,NULL					-- �߷����� 
								,NULL					-- ����°���(����)�Ի��� 
								,'2'					-- ��걸�� ('1'�����Է�,'2'�����ݰ��, '9'������)
								,@v_pay_group			-- �޿��׷�
								,@d_first_join_ymd		-- �����Ի���
								,@v_rep_mid_yn			-- �߰��������Կ���
								,@v_ins_type_yn			-- �������ݰ��Կ���
								,@v_ins_type_cd			-- ������������[RMP_INS_TYPE_CD]
								,@v_ins_nm				-- �������ݻ���ڸ�
								,@v_ins_bizno			-- �������ݻ�����Ϲ�ȣ
								,@v_ins_account_no		-- �������ݰ��¹�ȣ
								,CASE WHEN @d_sta_ymd <= DATEADD(MM, 1, DATEADD(YYYY, -1, @ad_std_ymd)) THEN 'N' ELSE 'Y' END					-- 1��̸�����
								,'N'					-- �߰�����(�ӱ���ũY����N)
								,@d_sta_ymd				-- ������(��)����� 
                                ,@d_end_ymd				-- ��(��)������
								,@d_end_ymd				-- ���� ������
								,@n_retire_turn_mon		-- ���ο���������ȯ��
								,dbo.xf_sysdate(0)		-- �����Ͻ�
								,@an_mod_user_id		-- ������ 	numeric(18, 0)
								,'KST'					-- Ÿ�����ڵ� 	nvarchar(10)
								,dbo.xf_sysdate(0)		-- Ÿ�����Ͻ� 	datetime2(7)
                                )
				IF @@ROWCOUNT < 1
					BEGIN
						PRINT 'INSERT FAILURE!' + 'CONTINUE'
					END
            END TRY

            BEGIN CATCH
                BEGIN
					--print 'Error:' + Error_message()
                    SET @av_ret_code = 'FAILURE!'
                    SET @av_ret_message  = dbo.F_FRM_ERRMSG('�����ݰ�����ڻ��� ����' , @v_program_id,  0010,  ERROR_MESSAGE(),  @an_mod_user_id)
					
					--print 'Error:' + Error_message()
                    IF @@TRANCOUNT > 0
                        ROLLBACK WORK
					--print 'Error Rollback:' + Error_message()

					CLOSE REP_CUR
					DEALLOCATE REP_CUR
                    RETURN
                END

            END CATCH

            FETCH REP_CUR INTO @n_emp_id , @n_org_id, @v_pos_grd_cd , @v_pos_cd, @v_duty_cd , @v_yearnum_cd , @v_mgr_type_cd , 
							   @v_job_position_cd, @v_job_cd , @v_emp_kind_cd , @v_officers_yn, @d_first_join_ymd ,
							   @d_group_ymd , @d_retire_ymd ,@d_sta_ymd , @d_end_ymd , @n_retire_turn_mon,
							   @v_org_nm, @v_org_line
        END
        CLOSE REP_CUR
        DEALLOCATE REP_CUR 
   END
PRINT('���� ===> ' + CONVERT(VARCHAR, dbo.XF_SYSDATE(0)))
   /*
   *    ***********************************************************
   *    �۾� �Ϸ�
   *    ***********************************************************
   */
   SET @av_ret_code = 'SUCCESS!'
   SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� �Ϸ�..[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)

END
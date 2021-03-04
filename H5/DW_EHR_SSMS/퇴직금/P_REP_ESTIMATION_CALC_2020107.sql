USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_ESTIMATION_CALC]    Script Date: 2020-12-04 ���� 3:00:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_REP_ESTIMATION_CALC]
    @av_company_cd     NVARCHAR(10),			-- ȸ���ڵ�
    @av_locale_cd      NVARCHAR(10),			-- �����ڵ�
    @ad_std_ymd        DATE,					-- ��������
	@av_pay_group	   NVARCHAR(50),			-- �޿��׷�
	@an_org_id         NUMERIC(38),				-- �Ҽ�ID
    @an_emp_id         NUMERIC(38),				-- ���ID
    @an_mod_user_id    NUMERIC(38),				-- ������
    @av_ret_code                   VARCHAR(500)    OUTPUT, -- ����ڵ�*/    
    @av_ret_message                VARCHAR(4000)    OUTPUT  -- ����޽���*/    
AS
    -- ***************************************************************************
    --   TITLE       : �������� ����
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
		   @v_std_ym			  NVARCHAR(6),		-- �߰���	
		   @d_pre_month_ymd		  DATE, -- �����޸���
		   @d_pre_year_ymd		  DATE, -- ������ 12��
           @d_mod_date            DATETIME2(0),		-- ������
		   @d_begin_date		  DATE,				-- �߰�� 1����
		   @v_bef_year12		  NVARCHAR(6),		-- ���⵵ 12���߰�	
           @n_auto_yn_cnt		  INT,				-- ��ǥ����
		   @n_rep_calc_list_id    NUMERIC(38),		-- ��������ID
           @n_emp_id              NUMERIC(38),		-- ���ID
           @n_org_id              NUMERIC(38),		-- ����ID
		   @v_org_cd			  NVARCHAR(100),	-- �����ڵ�
		   @v_cost_cd			  NVARCHAR(50),		-- �ڽ�Ʈ����
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
		   @v_ins_type_cd		  NVARCHAR(50),		-- �������ݱ���
		   @n_amt_retr_amt		  NUMERIC(15,0),	-- �߰��
		   @n_old_retire_amt	  NUMERIC(15,0),	-- ���������߰��
		   @n_min_retire_amt	  NUMERIC(15,0),	-- ��������(�����߰�� - ���������߰��)
		   @n_new_retire_amt	  NUMERIC(15,0),	-- ������Ծ�
		   @n_bef_retire_amt	  NUMERIC(15,0),	-- �����ܾ�
		   @n_mon_retire_amt	  NUMERIC(15,0),	-- ���������
		   @n_add_retire_amt	  NUMERIC(15,0),	-- �߰�������
		   @n_sum_retire_amt	  NUMERIC(15,0),    -- �ջ�������
		   @v_check				  NVARCHAR(1),		-- ��������
		   @v_pay_ym			  NVARCHAR(6)		-- �޿����


   SET @v_program_id = '[P_REP_ESTIMATION_CALC]';
   SET @v_program_nm = '�������� ����';

   SET @av_ret_code     = 'SUCCESS!'
   SET @av_ret_message  = dbo.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null,  @an_mod_user_id)
   SET @d_mod_date = dbo.xf_sysdate(0)
   SET @ad_std_ymd = dbo.XF_LAST_DAY(@ad_std_ymd)
   SET @v_pay_ym = dbo.XF_TO_CHAR_D(@ad_std_ymd,'YYYYMM')
   SET @d_pre_month_ymd = dbo.XF_LAST_DAY( DATEADD(MM, -1, @ad_std_ymd) )
   SET @d_pre_year_ymd = CONVERT(VARCHAR(4), (YEAR(@ad_std_ymd) - 1)) + '1231'
PRINT('�������� ===> ' + CONVERT(VARCHAR(20), @ad_std_ymd, 112))
PRINT('������ ===> ' + CONVERT(VARCHAR(20), @d_pre_month_ymd, 112))
PRINT('�����⵵ ===> ' + CONVERT(VARCHAR(20), @d_pre_year_ymd, 112))
   SET @v_std_ym = dbo.XF_TO_CHAR_D(@ad_std_ymd, 'YYYYMM')		-- ���� ���
   SET @v_bef_year12 = dbo.XF_TO_CHAR_D(DATEADD(YYYY, -1, @ad_std_ymd), 'YYYY') + '12'
PRINT('���� ===> ' + CONVERT(VARCHAR(100), sysdatetime(), 126))
   -- *************************************************************
   -- ��ǥ���� Check
   -- *************************************************************
   SET @n_auto_yn_cnt = 0
   BEGIN
      IF @av_company_cd <> 'I'
	     BEGIN
			SELECT @n_auto_yn_cnt = COUNT(*)
			  FROM REP_ESTIMATION A
			 WHERE A.COMPANY_CD = @av_company_cd
			   AND A.ESTIMATION_YMD = @ad_std_ymd
			   AND ISNULL(A.AUTO_YN, 'N') = 'Y'
			   AND (@an_emp_id IS NULL OR EMP_ID = @an_emp_id)
			   AND EXISTS (SELECT DISTINCT C.EMP_ID 
			                      FROM PAY_PAY_YMD B      
                                    INNER JOIN PAY_PAYROLL C      
                                       ON B.PAY_YMD_ID = C.PAY_YMD_ID
								 WHERE B.COMPANY_CD = @av_company_cd 
								   AND PAY_TYPE_CD IN (SELECT CD 
														 FROM FRM_CODE 
														WHERE CD_KIND = 'PAY_TYPE_CD'
														  AND COMPANY_CD = @av_company_cd 
														  AND SYS_CD = '001'
                                                      )
								   AND B.PAY_YM = @v_std_ym
								   AND B.CLOSE_YN = 'Y' 
								   AND C.EMP_ID = A.EMP_ID
								   AND (@av_pay_group is null or C.PAY_GROUP_CD = @av_pay_group)
                                  )
	     END
	  ELSE 
	     BEGIN
		    IF @av_pay_group = 'A'
			   BEGIN
				  SELECT @n_auto_yn_cnt = COUNT(*)
					FROM REP_ESTIMATION A
				   WHERE A.COMPANY_CD = @av_company_cd
					 AND A.ESTIMATION_YMD = @ad_std_ymd
					 AND ISNULL(A.AUTO_YN, 'N') = 'Y'
					 AND A.MGR_TYPE_CD IN ('A', '8')
			   END
            ELSE 
			   BEGIN
				  SELECT @n_auto_yn_cnt = COUNT(*)
					FROM REP_ESTIMATION A
				   WHERE A.COMPANY_CD = @av_company_cd
					 AND A.ESTIMATION_YMD = @ad_std_ymd
					 AND ISNULL(A.AUTO_YN, 'N') = 'Y'
					 AND (@av_pay_group is null or A.MGR_TYPE_CD = @av_pay_group)
			   END		 
		 END

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
      IF @av_company_cd <> 'I'
	     BEGIN
			DELETE FROM REP_ESTIMATION
			 WHERE COMPANY_CD = @av_company_cd
			   AND ESTIMATION_YMD = @ad_std_ymd
			   AND ISNULL(AUTO_YN, 'N') = 'N'
			   AND (@an_emp_id IS NULL OR EMP_ID = @an_emp_id)
			   AND EMP_ID IN (SELECT DISTINCT C.EMP_ID 
			                    FROM PAY_PAY_YMD B      
                                  INNER JOIN PAY_PAYROLL C      
                                     ON B.PAY_YMD_ID = C.PAY_YMD_ID
							   WHERE B.COMPANY_CD = @av_company_cd 
								 AND PAY_TYPE_CD IN (SELECT CD 
										 			   FROM FRM_CODE 
													  WHERE CD_KIND = 'PAY_TYPE_CD'
														AND COMPANY_CD = @av_company_cd 
														AND SYS_CD = '001'
                                                      )
								 AND B.PAY_YM = @v_std_ym
								 AND B.CLOSE_YN = 'Y' 
								   AND (@av_pay_group is null or C.PAY_GROUP_CD = @av_pay_group)
                              )
	     END
	  ELSE 
	     BEGIN
		    IF @av_pay_group = 'A'
			   BEGIN
				  DELETE FROM REP_ESTIMATION
				   WHERE COMPANY_CD = @av_company_cd
					 AND ESTIMATION_YMD = @ad_std_ymd
					 AND MGR_TYPE_CD IN ('A', '8')
					 AND (@an_emp_id IS NULL OR EMP_ID=@an_emp_id)
			   END
            ELSE 
			   BEGIN
				  DELETE FROM REP_ESTIMATION
				   WHERE COMPANY_CD = @av_company_cd
					 AND ESTIMATION_YMD = @ad_std_ymd
					 AND (@av_pay_group is null or MGR_TYPE_CD = @av_pay_group)
					 AND (@an_emp_id IS NULL OR EMP_ID=@an_emp_id)
			   END		 
		 END

	 IF @@ERROR <> 0
		BEGIN
			SET @av_ret_code    = 'FAILURE!'
			SET @av_ret_message = dbo.F_FRM_ERRMSG('���� ���� ������ �����߻�', @v_program_id , 0030 , null,  @an_mod_user_id)
			
			RETURN
		END

   END
PRINT('����� START ���� ===> ' + CONVERT(VARCHAR(100), sysdatetime(), 126))
   -- *************************************************************
   -- �������� ����
   -- *************************************************************
   BEGIN
        DECLARE REP_CUR CURSOR LOCAL FORWARD_ONLY FOR
            SELECT B.EMP_ID							-- ���ID
                  ,B.ORG_ID							-- ����ID
				  ,B.POS_GRD_CD						-- ���� [PHM_POS_GRD_CD]
                  ,B.POS_CD							-- ���� [PHM_POS_CD]
                  ,B.DUTY_CD						-- ��å [PHM_DUTY_CD]
                  ,B.YEARNUM_CD						-- ȣ��
				  ,B.MGR_TYPE_CD					-- ���������ڵ�[PHM_MGR_TYPE_CD]
				  ,B.JOB_POSITION_CD				-- �����ڵ�[PHM_JOB_POSTION_CD]
				  ,B.JOB_CD							-- �����ڵ�
				  ,B.EMP_KIND_CD					-- �ٷα����ڵ� [PHM_EMP_KIND_CD]
				  ,A.INS_TYPE_CD                    -- �������ݱ���
				  ,dbo.F_PAY_GET_COST(@av_company_cd, @n_emp_id, @n_org_ID, @ad_std_ymd, '1') AS COST_CD
				  ,dbo.F_FRM_ORM_ORG_NM( B.ORG_ID, B.LOCALE_CD, dbo.XF_SYSDATE(0), '10' ) AS ORG_CD
				  ,A.C_01							-- ��(��)���������޿�
				  ,c.mon_retire_amt -- ���޾�
				  ,d.bef_retire_amt -- �����ܾ�
             FROM REP_CALC_LIST A
			  INNER JOIN VI_PAY_PHM_EMP B 
			     ON A.COMPANY_CD = B.COMPANY_CD
                AND A.EMP_ID = B.EMP_ID
			  left outer join (
							SELECT EMP_ID,
							       ISNULL(SUM(C_01), 0) mon_retire_amt -- ���޾�
							  FROM REP_CALC_LIST
							 WHERE COMPANY_CD = @av_company_cd
							   AND CALC_TYPE_CD IN ('01','02')
							   AND PAY_YMD > dbo.XF_LAST_DAY( DATEADD(MM, -1, @ad_std_ymd) )
							   AND PAY_YMD <= @ad_std_ymd
							 GROUP BY EMP_ID
							) C
			               on A.EMP_ID = C.EMP_ID
			  left outer join (
							SELECT EMP_ID,
							       ISNULL(SUM(C_01), 0) bef_retire_amt -- �����ܾ�
							  FROM REP_CALC_LIST
							 WHERE COMPANY_CD = @av_company_cd
							   AND CALC_TYPE_CD IN ('03')
							   AND PAY_YMD = @d_pre_year_ymd -- ���⵵ ����
							 GROUP BY EMP_ID
							) D
			               on A.EMP_ID = D.EMP_ID
            WHERE A.COMPANY_CD = @av_company_cd
			  AND A.CALC_TYPE_CD = '03'
			  AND A.PAY_YMD = @ad_std_ymd
			  AND (@an_emp_id IS NULL OR A.EMP_ID=@an_emp_id)
              

            OPEN REP_CUR

            FETCH REP_CUR INTO @n_emp_id , @n_org_id, @v_pos_grd_cd , @v_pos_cd, @v_duty_cd , @v_yearnum_cd , @v_mgr_type_cd , 
							   @v_job_position_cd, @v_job_cd , @v_emp_kind_cd , @v_ins_type_cd, @v_cost_cd, @v_org_cd,
							   @n_amt_retr_amt, @n_mon_retire_amt, @n_bef_retire_amt

            WHILE (@@FETCH_STATUS = 0)
			
			-- ***************************************   
			-- 1. �⺻�ڷ�    
			-- *************************************** 

            BEGIN
						Print 'fetch Time S : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)
--PRINT('@n_emp_id ===> ' + CONVERT(VARCHAR, @n_emp_id))
				-- �������ݱ���
				--SET @v_ins_type_cd = NULL
				--BEGIN 
				--   SELECT @v_ins_type_cd = CALC_TYPE_CD
				--	 FROM dbo.REP_INSUR_MON
    --                WHERE EMP_ID = @n_emp_id
				--	  AND @ad_std_ymd BETWEEN STA_YMD AND END_YMD

    --               IF @@ERROR != 0
				--	  BEGIN
				--		 SET @v_ins_type_cd = NULL
				--	  END
				--END

				-- �ڽ�Ʈ�����ڵ�
				--SET @v_cost_cd = DBO.F_PAY_GET_COST(@av_company_cd, @n_emp_id, @n_org_ID, @ad_std_ymd, '1') --AS COST_CD
				--BEGIN
				--   SELECT @v_cost_cd = COST_CD
				--     FROM ORM_EMP_COST
    --                WHERE COMPANY_CD = @av_company_cd
				--	  AND EMP_ID = @n_emp_id
				--	  AND @ad_std_ymd BETWEEN STA_YMD AND END_YMD 
    --               IF @@ERROR != 0
				--	  BEGIN
				--		 SELECT @v_cost_cd = COST_ORG_CD
				--		   FROM ORM_ORG_HIS
    --                      WHERE ORG_ID = @n_ORG_ID
				--		    AND @ad_std_ymd BETWEEN STA_YMD AND END_YMD 
				--	  END

				--END

				-- �����ڵ�
				--BEGIN
				--   SELECT @v_org_cd = ORG_CD
				--	 FROM ORM_ORG
    --                WHERE ORG_ID = @n_org_ID
				--	  AND @ad_std_ymd BETWEEN STA_YMD AND END_YMD 
				--END

				-- ���������߰��
				SET @n_old_retire_amt = 0
						Print '���������߰�� Time S : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)
				BEGIN
				   SELECT @n_old_retire_amt = ISNULL(RETIRE_AMT, 0)
				     FROM REP_ESTIMATION
                    WHERE COMPANY_CD = @av_company_cd
					  AND EMP_ID = @n_emp_id
					  AND ESTIMATION_YMD = (SELECT MAX(ESTIMATION_YMD)
					                          FROM REP_ESTIMATION
                                             WHERE COMPANY_CD = @av_company_cd
					                           AND EMP_ID = @n_emp_id
											   AND ESTIMATION_YMD < @ad_std_ymd)

                   IF @@ERROR != 0
					  BEGIN
						 SET @n_old_retire_amt = 0 
					  END
				END
						Print '���������߰�� Time E : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)

				-- DC���� ��� 1���� ��� 0
				BEGIN
				   IF @v_ins_type_cd = '20' AND dbo.XF_SUBSTR(@v_std_ym,5,2) = '01' 
				      BEGIN
					     SET @n_old_retire_amt = 0
					  END
				END

				-- �����ܾ�
				--SET @n_bef_retire_amt = 0
				--BEGIN
				--   SELECT @n_bef_retire_amt = ISNULL(SUM(C_01), 0)
				--     FROM REP_CALC_LIST
    --                WHERE COMPANY_CD = @av_company_cd
				--	  AND EMP_ID = @n_emp_id
				--	  AND CALC_TYPE_CD = '03'
				--	  AND PAY_YMD = @d_pre_year_ymd

    --               IF @@ERROR != 0
				--	  BEGIN
				--		 SET @n_bef_retire_amt = 0 
				--	  END
				--END

				-- ���޾�
				--SET @n_mon_retire_amt = 0
				--BEGIN
				--   SELECT @n_mon_retire_amt = ISNULL(SUM(C_01), 0)
				--     FROM REP_CALC_LIST
    --                WHERE COMPANY_CD = @av_company_cd
				--	  AND EMP_ID = @n_emp_id
				--	  AND CALC_TYPE_CD IN ('01','02')
				--	  AND dbo.XF_TO_CHAR_D(PAY_YMD, 'YYYYMM') = @v_std_ym

    --               IF @@ERROR != 0
				--	  BEGIN
				--		 SET @n_mon_retire_amt = 0 
				--	  END
				--END

				-- ��������(�����߰�� - ���������߰��)
				SET @n_min_retire_amt = @n_amt_retr_amt - @n_old_retire_amt

				-- ������Ծ� : ���޾� + (���-����)
				SET @n_new_retire_amt = @n_mon_retire_amt + @n_min_retire_amt

				-- �߰�������
				SET @n_add_retire_amt = 0

				-- �⸻�ܾ� = �����ܾ� + ���޾�
   				SET @n_sum_retire_amt = @n_bef_retire_amt + @n_mon_retire_amt

				-- �Է� �����
				SET @v_check = 'N'
				BEGIN
				   IF @av_company_cd = 'I'
					  BEGIN
						 IF @av_pay_group = 'A'
							BEGIN
							   SET @v_check = CASE WHEN @v_mgr_type_cd IN ('A', '8') AND dbo.XF_SUBSTR(@v_org_cd,1,1) <> '5' THEN 'Y' ELSE 'N' END
							END
						 ELSE IF @av_pay_group = 'B'
							BEGIN
							   SET @v_check = CASE WHEN @v_mgr_type_cd = 'B' OR (dbo.XF_SUBSTR(@v_org_cd,1,1) = '5' AND @v_mgr_type_cd = 'A') THEN 'Y' ELSE 'N' END
							END
						 ELSE
							BEGIN
							   SET @v_check = 'Y'
							END
					  END
				   ELSE 
					  BEGIN
						Print '�Է� ����� Time S : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)
						 SELECT @v_check = CASE WHEN count(*) > 0 THEN 'Y' ELSE 'N' END
						   FROM PAY_PAY_YMD A      
							 INNER JOIN PAY_PAYROLL B      
								ON B.PAY_YMD_ID = A.PAY_YMD_ID      
						  WHERE A.COMPANY_CD = @av_company_cd
							AND B.EMP_ID = @n_emp_id    
							AND A.CLOSE_YN = 'Y'     
							AND A.PAY_YM = @v_pay_ym -- dbo.XF_TO_CHAR_D(@ad_std_ymd,'YYYYMM') 
						IF @@ERROR != 0
						   BEGIN
							  SET @n_bef_retire_amt = 0 
						   END
						Print '�Է� ����� Time E : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)

					  END
				END

				BEGIN -- 1
				   IF @v_check = 'Y'
					  BEGIN -- 2
						SET @n_rep_calc_list_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE

						BEGIN TRY
						Print 'Insert Time S : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)
								INSERT INTO dbo.REP_ESTIMATION (	-- ��������
											REP_ESTIMATIN_ID		-- ��������ID
										   ,COMPANY_CD				-- �λ翵��
										   ,ESTIMATION_YMD			-- �������� ������
										   ,EMP_ID					-- ���ID
										   ,ORG_ID					-- ����ID
										   ,MGR_TYPE_CD				-- ���������ڵ�[PHM_MGR_TYPE_CD]
										   ,INS_TYPE_CD				-- ������������[RMP_INS_TYPE_CD]
										   ,ACC_CD					-- �ڽ�Ʈ����
										   ,RETIRE_AMT				-- �����߰��
										   ,OLD_RETIRE_AMT			-- ���������߰��
										   ,MIN_RETIRE_AMT			-- ��������(�����߰�� - ���������߰��)
										   ,NEW_RETIRE_AMT			-- ������Ծ�
										   ,BEF_RETIRE_AMT			-- �����ܾ�
										   ,MON_RETIRE_AMT			-- ���������
										   ,ADD_RETIRE_AMT			-- �߰�������
										   ,SUM_RETIRE_AMT			-- �ջ�������
										   ,AUTO_YN					-- �ڵ��а� ����
										   ,AUTO_YMD				-- �̰�����
										   ,AUTO_NO					-- �ڵ��а� �Ϸù�ȣ
										   ,NOTE					-- ���
										   ,MOD_USER_ID				-- ������
										   ,MOD_DATE				-- �����Ͻ�
										   ,TZ_CD					-- Ÿ�����ڵ�
										   ,TZ_DATE					-- Ÿ�����Ͻ�
										)
									VALUES (  
											@n_rep_calc_list_id     -- ��������ID
										   ,@av_company_cd			-- ȸ���ڵ�
						  				   ,@ad_std_ymd			    -- �������� ������
										   ,@n_emp_id               -- ���ID
										   ,@n_org_id				-- ����ID 
										   ,@v_mgr_type_cd			-- ���������ڵ�[PHM_MGR_TYPE_CD]
										   ,@v_ins_type_cd			-- ������������[RMP_INS_TYPE_CD]
										   ,@v_cost_cd				-- �ڽ�Ʈ����
										   ,@n_amt_retr_amt			-- �����߰��
										   ,@n_old_retire_amt		-- ���������߰��
										   ,@n_min_retire_amt		-- ��������(�����߰�� - ���������߰��)
										   ,@n_new_retire_amt		-- ������Ծ�
										   ,@n_bef_retire_amt		-- �����ܾ�
										   ,@n_mon_retire_amt		-- ���������
										   ,@n_add_retire_amt		-- �߰�������
										   ,@n_sum_retire_amt		-- �ջ�������
										   ,'N'						-- �ڵ��а� ����
										   ,NULL					-- �̰�����
										   ,NULL				    -- �ڵ��а� �Ϸù�ȣ
										   ,NULL					-- ���
										   ,@an_mod_user_id			-- ������ 	numeric(18, 0)
										   ,dbo.xf_sysdate(0)		-- �����Ͻ�
										   ,'KST'					-- Ÿ�����ڵ� 	nvarchar(10)
										   ,dbo.xf_sysdate(0)		-- Ÿ�����Ͻ� 	datetime2(7)
											)
							IF @@ROWCOUNT < 1
								BEGIN
									PRINT 'INSERT FAILURE!' + 'CONTINUE'
								END
						Print 'Insert Time E : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)
						END TRY

						BEGIN CATCH
							BEGIN
								--print 'Error:' + Error_message()
								SET @av_ret_code = 'FAILURE!'
								SET @av_ret_message  = dbo.F_FRM_ERRMSG('���������� ���� ����' , @v_program_id,  0010,  ERROR_MESSAGE(),  @an_mod_user_id)
					
								--print 'Error:' + Error_message()
								IF @@TRANCOUNT > 0
									ROLLBACK WORK
								--print 'Error Rollback:' + Error_message()

								CLOSE REP_CUR
								DEALLOCATE REP_CUR
								RETURN
							END

						END CATCH
					  END -- 2
				END  --1

            FETCH REP_CUR INTO @n_emp_id , @n_org_id, @v_pos_grd_cd , @v_pos_cd, @v_duty_cd , @v_yearnum_cd , @v_mgr_type_cd , 
							   @v_job_position_cd, @v_job_cd , @v_emp_kind_cd , @v_ins_type_cd, @v_cost_cd, @v_org_cd,
							   @n_amt_retr_amt, @n_mon_retire_amt, @n_bef_retire_amt
        END
        CLOSE REP_CUR
        DEALLOCATE REP_CUR 
   END
PRINT('���� ===> ' + CONVERT(VARCHAR(100), sysdatetime(), 126))
   /*
   *    ***********************************************************
   *    �۾� �Ϸ�
   *    ***********************************************************
   */
   SET @av_ret_code = 'SUCCESS!'
   SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� �Ϸ�..[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)

END
USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_CAL_PAY_STD_DC]    Script Date: 2021-01-28 ���� 5:22:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_CAL_PAY_STD_DC] (      
       @av_company_cd                 NVARCHAR(10),             -- �λ翵��      
       @av_locale_cd                  NVARCHAR(10),             -- �����ڵ�      
       @an_rep_calc_list_id_list      NUMERIC(38),				-- �����ݴ��ID      
       @an_mod_user_id                NUMERIC(38),				-- ������ ���      
       @av_ret_code                   NVARCHAR(4000)    OUTPUT, -- ����ڵ�*/      
       @av_ret_message                NVARCHAR(4000)    OUTPUT  -- ����޽���*/      
    ) AS      
    -- ***************************************************************************      
    --   TITLE       : DC�� ������ �����ӱݰ���/�ӱ��׸����      
    --   PROJECT     : HR �ý���      
    --   AUTHOR      :      
    --   PROGRAM_ID  : P_REP_CAL_PAY_STD      
    --   RETURN      : 1) SUCCESS!/FAILURE!      
    --                 2) ��� �޽���      
    --   COMMENT     : �����ݱ����ӱ�����/�ӱ��׸����� insert      
    --   HISTORY     : �ۼ� ������ 2006.09.18      
    --               : ���� �ڱ��� 2009.01.16       
    --               : 2016.06.23 Modified by �ּ��� in KBpharma      
    -- ***************************************************************************      
BEGIN      
    /* �⺻������ ���Ǵ� ���� */      
    DECLARE @v_program_id              NVARCHAR(30)     
          , @v_program_nm              NVARCHAR(100)      
          , @ERRCODE                   NVARCHAR(10)      
      
    DECLARE @n_emp_id                  NUMERIC(38)				-- ���ID
		  , @v_in_offi_yn			   NVARCHAR(1)				-- ��������
		  , @d_retire_ymd			   DATE                     -- ��������
		  , @v_flag_yn				   NVARCHAR(1)				-- 1��̸�
          , @v_base_pay_ym             NVARCHAR(6)				-- �޿����޳��
		  , @n_retire_turn_mon		   NUMERIC(15)				-- ���ο���������ȯ��
		  , @v_rep_mid_yn			   NVARCHAR(6)				-- �߰����꿩��
		  , @v_officers_yn			   NVARCHAR(1)				-- �ӿ�����
		  , @n_add_rate				   NUMERIC(5,2)				-- ������
		  , @n_org_id				   NUMERIC(38)				-- ����ID
		  , @v_org_nm				   NVARCHAR(100)			-- ������
		  , @v_org_line                NVARCHAR(1000)			-- ��������
		  , @v_pos_cd				   NVARCHAR(50)				-- ����
		  , @v_pos_grd_cd			   NVARCHAR(50)				-- ����
		  , @v_yearnum_cd			   NVARCHAR(50)				-- ȣ��
		  , @v_pay_group			   NVARCHAR(50)				-- �޿��׷�
          , @n_std_cnt                 NUMERIC                  -- ���رݰ��� ��ȸ�� 
		  ,	@v_biz_cd				   NVARCHAR(50)				-- �����
		  , @v_reg_biz_cd			   NVARCHAR(50)				-- �Ű����� 
		  , @v_mgr_type_cd			   NVARCHAR(30)				-- ���������ڵ�[PHM_MGR_TYPE_CD]
		  , @v_pay_meth_cd			   NVARCHAR(50)				-- �޿����޹���ڵ�[PAY_METH_CD]
		  ,	@v_emp_cls_cd			   NVARCHAR(50)				-- ��������ڵ�[PAY_EMP_CLS_CD]
		  ,	@v_ins_type_yn			   NVARCHAR(1)				-- �������ݰ��Կ���
		  ,	@v_ins_type_cd			   NVARCHAR(10)				-- �������ݱ���
		  ,	@v_ins_nm				   NVARCHAR(80)				-- �������ݻ���ڸ�
		  ,	@v_ins_bank_cd			   NVARCHAR(80)				-- �������������ڵ�
		  ,	@v_ins_bizno			   NVARCHAR(50)				-- �������ݻ�����Ϲ�ȣ
		  ,	@v_ins_account_no		   NVARCHAR(150)			-- �������ݰ��¹�ȣ
          , @n_rep_id                  NUMERIC(38)				-- ���ݾ� �Է�ID(Sequence)
          , @an_return_cal_mon         NUMERIC(38)				-- ����ӱ� ������ ���رݾ�
          , @d_end_ymd                 DATETIME2				-- ��(��)������ - ������
		  , @n_bef_ret_year			   NUMERIC					-- �������⵵
          , @n_rep_calc_list_id_list   NUMERIC(38)				-- �����ݴ���� Pk 
          , @n_rep_calc_id             NUMERIC					-- �����ݴ��ID
		  , @d_pay_s_ymd			   DATETIME2				-- ���޳��� ���� ������
		  , @d_pay_e_ymd			   DATETIME2				-- ���޳��� ���� ������


		  , @d_bns_s_ymd			   DATETIME2				-- �� ������ ������
		  , @d_bns_e_ymd			   DATETIME2				-- �� ������ ������
		  , @d_day_s_ymd			   DATETIME2				-- ���� ������ ������
		  , @d_day_e_ymd			   DATETIME2				-- ���� ������ ������
          , @d_base_s_ymd              DATETIME2				-- ����ӱ� ������ ������
		  , @n_base_s_ymd_cnt		   NUMERIC(3)				-- ����ӱ� ������ �����ϼ�
          , @d_base_e_ymd              DATETIME2				-- ����ӱ� ������ ������
          , @n_base_cnt                NUMERIC(3)				-- �����ϼ�      
          , @n_real_cnt                NUMERIC(3)				-- ����ϼ�       
          , @n_yy                      NUMERIC(3)				-- �ټӳ��

          , @n_roop_cnt                NUMERIC(3)				-- �ݺ�(Looping)Ƚ��_�޿�      
          , @n_pay_cnt                 NUMERIC(3)				-- �޿�����Ƚ�� 
		  , @n_bns_roop_cnt            NUMERIC(3)				-- �ݺ�(Looping)Ƚ��_�޿�
		  , @n_bns_cnt				   NUMERIC(3)				-- ������Ƚ��  
          , @n_p28_cnt                 NUMERIC(3)				-- ��Ƚ��
		  , @v_pay01_ym				   NVARCHAR(6)				-- �޿����_01
		  ,	@v_pay02_ym				   NVARCHAR(6)				-- �޿����_02
		  ,	@v_pay03_ym				   NVARCHAR(6)				-- �޿����_03
		  ,	@v_pay04_ym				   NVARCHAR(6)				-- �޿����_04
		  , @v_pay05_ym				   NVARCHAR(6)				-- �޿����_05
		  ,	@v_pay06_ym				   NVARCHAR(6)				-- �޿����_06
		  ,	@v_pay07_ym				   NVARCHAR(6)				-- �޿����_07
		  ,	@v_pay08_ym				   NVARCHAR(6)				-- �޿����_08
		  , @v_pay09_ym				   NVARCHAR(6)				-- �޿����_09
		  ,	@v_pay10_ym				   NVARCHAR(6)				-- �޿����_10
		  ,	@v_pay11_ym				   NVARCHAR(6)				-- �޿����_11
		  ,	@v_pay12_ym				   NVARCHAR(6)				-- �޿����_12
		  , @n_pay01_amt			   NUMERIC(18)				-- �޿��ݾ�_01
		  , @n_pay02_amt			   NUMERIC(18)				-- �޿��ݾ�_02
		  , @n_pay03_amt			   NUMERIC(18)				-- �޿��ݾ�_03
		  , @n_pay04_amt			   NUMERIC(18)				-- �޿��ݾ�_04
		  , @n_pay05_amt			   NUMERIC(18)				-- �޿��ݾ�_05
		  , @n_pay06_amt			   NUMERIC(18)				-- �޿��ݾ�_06
		  , @n_pay07_amt			   NUMERIC(18)				-- �޿��ݾ�_07
		  , @n_pay08_amt			   NUMERIC(18)				-- �޿��ݾ�_08
		  , @n_pay09_amt			   NUMERIC(18)				-- �޿��ݾ�_09
		  , @n_pay10_amt			   NUMERIC(18)				-- �޿��ݾ�_10
		  , @n_pay11_amt			   NUMERIC(18)				-- �޿��ݾ�_11
		  , @n_pay12_amt			   NUMERIC(18)				-- �޿��ݾ�_12
		  , @n_pay_mon				   NUMERIC(18)				-- �޿��հ�
		  ,	@n_pay_tot_amt			   NUMERIC(18)				-- 3�����޿��հ�
		  , @d_last_retire_date		   DATE						-- ������ ������	
		  , @n_real_cnt_tmp			   NUMERIC(3)				-- ����ϼ�_TEMP	
		  , @n_real_cnt_tmp1		   NUMERIC(3)				-- ����ϼ�_TEMP1
		  , @n_real_cnt_tmp2		   NUMERIC(3)				-- ����ϼ�_TEMP2
		  , @n_real_cnt_tmp3		   NUMERIC(3)				-- ����ϼ�_TEMP3
		  , @n_real_cnt_tmp4		   NUMERIC(3)				-- ����ϼ�_TEMP4

      
      /* �⺻���� �ʱⰪ ����*/      
    SET @v_program_id    = 'P_REP_CAL_PAY_STD_DC'					-- ���� ���ν����� ������      
    SET @v_program_nm    = 'DC�� ������ �����ӱݰ���/�ӱ��׸����'  -- ���� ���ν����� �ѱ۹���      
    SET @av_ret_code     = 'SUCCESS!'      
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null,  @an_mod_user_id)      
      
    BEGIN      
        SET @n_rep_calc_id = @an_rep_calc_list_id_list      
        SET @n_yy = 0  
		
        -- ***************************************      
        -- 1. �����(����) ��ȸ      
        -- ***************************************      
        BEGIN      
            SELECT @n_emp_id                = EMP_ID								-- ���ID 
                 , @d_end_ymd               = C1_END_YMD							-- ��(��)������  
                 , @n_rep_calc_list_id_list = REP_CALC_LIST_ID						-- ����� ������ID     
                 , @d_retire_ymd            = dbo.XF_NVL_D(RETIRE_YMD, C1_END_YMD)	-- ������  
				 , @n_retire_turn_mon		= RETIRE_TURN							-- ���ο���������ȯ��
				 , @v_emp_cls_cd			= ISNULL(EMP_CLS_CD, 'Z')				-- �������[PAY_EMP_CLS_CD]
				 , @v_mgr_type_cd			= ISNULL(MGR_TYPE_CD, '1')				-- ���������ڵ�[PHM_MGR_TYPE_CD]
				 , @v_officers_yn			= ISNULL(OFFICERS_YN, 'N')				-- �ӿ�����
				 , @v_flag_yn				= CASE WHEN C1_STA_YMD <= DATEADD(MM, 1, DATEADD(YYYY, -1, C1_END_YMD)) THEN 'N' ELSE 'Y' END				-- 1��̸�
              FROM REP_CALC_LIST      
             WHERE REP_CALC_LIST_ID = @n_rep_calc_id      
            IF @@ERROR != 0                       
                BEGIN      
                    SET @av_ret_code    = 'FAILURE!'      
                    SET @av_ret_message = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') �����ӱ� ����� ��ȸ ����[ERR]', @v_program_id, 0010, null, @an_mod_user_id)      
                    RETURN      
                END      
        END 
        -- ***************************************      
        -- 2. ���� �ӱ��׸� ����      
        -- ***************************************      
        BEGIN      
            DELETE FROM REP_PAYROLL_DETAIL      
             WHERE REP_PAY_STD_ID IN (SELECT REP_PAY_STD_ID      
                                        FROM REP_PAY_STD      
                                       WHERE REP_CALC_LIST_ID = @n_rep_calc_list_id_list)     
            IF @ERRCODE != 0      
                 BEGIN      
				   SET @av_ret_code    = 'FAILURE!'      
                   SET @av_ret_message = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') �����ӱ��׸���� ������ �����߻�[ERR]', @v_program_id, 0020, null, @an_mod_user_id)       
                   RETURN      
                 END      
        END      
        -- ***************************************      
        -- 3. ���� �����ӱݰ��� ����      
        -- ***************************************      
        BEGIN      
            DELETE FROM REP_PAY_STD      
             WHERE REP_CALC_LIST_ID = @n_rep_calc_list_id_list      
            IF @ERRCODE != 0      
                BEGIN      
                  SET @av_ret_code    = 'FAILURE!'      
                  SET @av_ret_message = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') �����ӱݰ��� ������ �����߻�[ERR]', @v_program_id, 0030, null, @an_mod_user_id)       
                  RETURN      
                END      
        END 

	
		-- *************************************** 
		-- �⺻���� ���� �� ��Ÿ���� Title �Է�
		-- ***************************************
---------------------------------------------------------------------------------------------------------------------------------
		BEGIN
			-- �ӿ��̸� ������ �ݿ�
			BEGIN
				IF ISNULL(@n_add_rate, 0) = 0
				   BEGIN
					  IF @v_officers_yn = 'Y'
						 BEGIN
							SELECT @n_add_rate = dbo.XF_TO_NUMBER(CD1)
								FROM FRM_UNIT_STD_HIS  
							WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
															FROM FRM_UNIT_STD_MGR  
															WHERE COMPANY_CD = @av_company_cd  
															AND UNIT_CD = 'REP'  
															AND STD_KIND = 'REP_EXE_MUL')  
								AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
								AND KEY_CD1 = @v_pos_cd 
						 END
				   END   
			END

			-- �޿�������(PAY_PHM_EMP)���� ���������, �޿����޹��, ������������� �����´�.
			SET @v_pay_meth_cd = NULL
			SET @v_emp_cls_cd  = NULL
			BEGIN      
			   SELECT @v_pay_meth_cd = PAY_METH_CD		-- �޿����޹���ڵ�[PAY_METH_CD] 
					, @v_emp_cls_cd  = EMP_CLS_CD		-- ��������ڵ�[PAY_EMP_CLS_CD]   								     
				 FROM PAY_PHM_EMP      
				WHERE EMP_ID = @n_emp_id      
				IF @@ERROR != 0                       
					BEGIN      
						SET @v_pay_meth_cd = NULL
						SET @v_emp_cls_cd = NULL
					END      
			END
-----------------------------------------------------------------------------------------------------------------------------------
			-- ������, ��������
			SET @v_org_nm = dbo.F_FRM_ORM_ORG_NM(@n_org_id, 'KO', @d_end_ymd, '1')				 -- ������
			SET @v_org_line = dbo.F_FRM_ORM_ORG_NM(@n_org_id, 'KO', @d_end_ymd, 'LL')			 -- ��������
			-- �޿�������(PAY_PHM_EMP)���� ���������, �޿����޹��, ������������� �����´�.
			SET @v_pay_meth_cd = NULL
			SET @v_emp_cls_cd  = NULL
			BEGIN      
			   SELECT @v_pay_meth_cd = PAY_METH_CD		-- �޿����޹���ڵ�[PAY_METH_CD] 
					, @v_emp_cls_cd  = EMP_CLS_CD		-- ��������ڵ�[PAY_EMP_CLS_CD]   								     
				 FROM PAY_PHM_EMP      
				WHERE EMP_ID = @n_emp_id      
				IF @@ERROR != 0                       
					BEGIN      
						SET @v_pay_meth_cd = NULL
						SET @v_emp_cls_cd = NULL
					END      
			END
-----------------------------------------------------------------------------------------------------------------------------------------------------
			-- ����� 
			SET @v_biz_cd = dbo.F_ORM_ORG_BIZ(@n_org_id, @d_end_ymd, 'PAY')
			SET @v_biz_cd = ISNULL( @v_biz_cd, '001' )

			-- �Ű����� 
			SET @v_reg_biz_cd = dbo.F_ORM_ORG_BIZ(@n_org_id, @d_end_ymd, 'REG')
			SET @v_reg_biz_cd = ISNULL(@v_reg_biz_cd, '001')

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
					  ,@v_ins_bank_cd = IRP_BANK_CD
					  ,@v_ins_bizno = INSUR_BIZ_NO
					  ,@v_ins_account_no = IRP_ACCOUNT_NO
				 FROM dbo.REP_INSUR_MON
				WHERE EMP_ID = @n_emp_id
				  AND @d_end_ymd BETWEEN STA_YMD AND END_YMD
				IF @@ERROR != 0
					BEGIN
						SET @v_ins_type_yn = 'N'
						SET @v_ins_type_cd = NULL
					END
			END

			-- ��������
			BEGIN
			   SELECT @v_in_offi_yn = IN_OFFI_YN
					 ,@d_retire_ymd = ISNULL(RETIRE_YMD, @d_end_ymd)
				 FROM PHM_EMP
				WHERE EMP_ID = @n_emp_id 
			END
-----------------------------------------------------------------------------------------------------------------------------------

		END

	
        -- ***************************************      
        -- 4. ���� ���� ��ȸ      
        -- ***************************************      
        BEGIN  
		    SET @d_last_retire_date = dbo.XF_LAST_DAY(@d_end_ymd) -- ������ ������
		    SET @d_pay_e_ymd = @d_end_ymd   -- ���޳��� ���� ������
			-- ���޳��� ���� ������ ����
			BEGIN
			   IF @v_rep_mid_yn = 'N' 
			      BEGIN
			         SET @d_pay_s_ymd = dbo.XF_TO_DATE(dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_end_ymd,'YYYYMMDD'),1,4) + '0101', 'YYYYMMDD')	-- ���޳��� ���� ������
			         BEGIN
			            IF (@av_company_cd = 'I')
                           BEGIN
                              SET @d_pay_s_ymd = dbo.XF_TO_DATE(CONVERT(VARCHAR, @n_bef_ret_year) + '1201', 'YYYYMMDD')
                           END
						ELSE IF (@av_company_cd = 'W')
						   BEGIN
						     IF dbo.XF_TO_NUMBER(dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_end_ymd,'YYYYMMDD'),5,2)) > 4
							    BEGIN
								   SET @d_pay_s_ymd = dbo.XF_TO_DATE(dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_end_ymd,'YYYYMMDD'),1,4) + '0501', 'YYYYMMDD')
								END
							 ELSE
							    BEGIN
								   SET @d_pay_s_ymd = dbo.XF_TO_DATE(CONVERT(VARCHAR, @n_bef_ret_year) + '0501', 'YYYYMMDD')
								END
						   END 
			         END -- 1
				  END
			END

            SET @n_pay_cnt = 1     
            SET @n_real_cnt_tmp  = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_end_ymd, 'DD')) -- ������ ���� 			
			SET @n_base_cnt = 30
			SET @n_real_cnt = 30
            DECLARE rep CURSOR FOR      
                SELECT DISTINCT A.PAY_YM AS BASE_YM      
                  FROM PAY_PAY_YMD A      
                       INNER JOIN PAY_PAYROLL B      
                           ON B.PAY_YMD_ID = A.PAY_YMD_ID 
                 WHERE B.EMP_ID = @n_emp_id      
                   AND A.CLOSE_YN = 'Y' 
				   AND A.PAY_YN = 'Y'
                   --AND A.PAY_YM BETWEEN dbo.XF_TO_CHAR_D(@d_pay_s_ymd, 'YYYYMM') AND dbo.XF_TO_CHAR_D(@d_pay_e_ymd, 'YYYYMM')      
				   AND A.PAY_YM BETWEEN FORMAT(@d_pay_s_ymd, 'yyyyMM') AND FORMAT(@d_pay_e_ymd, 'yyyyMM')
                   AND A.PAY_YM NOT IN (SELECT Y.BASE_YM      
                                          FROM (SELECT dbo.XF_TO_CHAR_D(T.STA_YMD, 'YYYYMM') AS STA_YM     
                                                     , dbo.XF_TO_CHAR_D(T.END_YMD, 'YYYYMM') AS END_YM      
                                                  FROM (SELECT STA_YMD      
                                                             , END_YMD      
                                                          FROM CAM_TERM_MGR      
                                                         WHERE ITEM_NM = 'LEAVE_CD'      
                                                           AND VALUE IN (SELECT CD      
                                                                           FROM FRM_CODE      
                                                                          WHERE CD_KIND = 'REP_EXCE_TYPE_CD'        
                                                                            AND LOCALE_CD = @av_locale_cd      
                                                                            AND COMPANY_CD = @av_company_cd      
                                                                            AND @d_end_ymd BETWEEN STA_YMD AND END_YMD)      
                                                           AND EMP_ID = @n_emp_id) T) X      
                                               INNER JOIN (SELECT DISTINCT BASE_YM      
                                                             FROM (SELECT dbo.XF_TO_CHAR_D(YMD, 'YYYYMM') AS BASE_YM      
                                                                     FROM HPS_CALENDAR      
                                                                    WHERE COMPANY_CD = @av_company_cd      
                                                                      AND YMD <= @d_end_ymd) B1) Y      
                                                      ON Y.BASE_YM BETWEEN X.STA_YM AND X.END_YM )      
                 ORDER BY A.PAY_YM DESC  
            OPEN rep      
                FETCH NEXT FROM rep INTO @v_base_pay_ym     
                WHILE (@@FETCH_STATUS = 0)      
                    BEGIN -- Ŀ������      
                        -- ***************************************      
                        -- 4-1. �����׸� ������ ä��      
                        -- ***************************************  
				
                        BEGIN      
                           SELECT @n_rep_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE      
                              FROM DUAL      
                        END      
   
	
                        -- ***************************************      
                        -- 4-1. �ӱ��׸� ����      
                        -- ***************************************  
						SET @an_return_cal_mon = 0
						BEGIN
						   IF @v_emp_cls_cd <> 'S'
							  BEGIN      
									EXEC dbo.P_REP_CAL_PAY_DETAIL_DC @av_company_cd      
																	, @n_rep_calc_list_id_list      
																	, @n_rep_id      
																	, @v_base_pay_ym      
																	, '10'                          -- �޿�   (�ǹ̾���)   
																	, @n_base_cnt                   -- �����ϼ�      
																	, @n_real_cnt                   -- ���ϼ�      
																	, 'Y'                           -- ���Ұ�꿩��      
																	, @an_mod_user_id      
																	, @an_return_cal_mon output      
																	, @av_ret_code output      
																	, @av_ret_message output      
									IF @av_ret_code = 'FAILURE!'      
										BEGIN      
											SET @av_ret_code     = 'FAILURE!'      
											SET @av_ret_message  = @av_ret_message      
											CLOSE rep       -- Ŀ���ݱ�      
											DEALLOCATE rep  -- Ŀ�� �Ҵ�����      
											RETURN      
										END      
							  END    
						END
                        -- ***************************************      
                        -- 4-3. �����ӱ� ����      
                        -- ***************************************      
                        IF @an_return_cal_mon <> 0                                      -- �ݾ��� �ִ°��      
                           BEGIN  
				        
                                INSERT INTO REP_PAY_STD                                 -- �����ݱ��� �ӱ� ����      
                                          ( REP_PAY_STD_ID                              -- �����ݱ��� �ӱ� ����ID      
                                          , REP_CALC_LIST_ID                            -- �����ݴ��ID      
                                          , PAY_TYPE_CD                                 -- �޿����ޱ���[PAY_TYPE_CD]      
                                          , PAY_YM                                      -- �޿����      
                                          , SEQ                                         -- ����      
                                          , STA_YMD                                     -- ��������      
                                          , END_YMD                                     -- ��������      
                                          , BASE_DAY                                    -- �����ϼ�      
                                          , MINUS_DAY                                   -- �����ϼ�      
                                          , REAL_DAY                                    -- ����ϼ�      
                                          , MOD_USER_ID                                 -- ������      
                                          , MOD_DATE                                    -- �����Ͻ�      
                                          , TZ_CD                                       -- Ÿ�����ڵ�      
                                          , TZ_DATE)                                    -- Ÿ�����Ͻ�      
                                    VALUES( @n_rep_id                                   -- �����ݱ��� �ӱ� ����ID      
                                          , @n_rep_calc_list_id_list                    -- �����ݴ��ID      
                                          , '10'                                        -- �޿����ޱ���[REP_PAY_TYPE_CD]      
                                          , @v_base_pay_ym                              -- �޿����      
                                          , @n_pay_cnt                                  -- ����      
                                          , @d_base_s_ymd                               -- ��������      
                                          , @d_base_e_ymd                               -- ��������      
                                          , @n_base_cnt                                 -- �����ϼ�      
                                          , 0                                           -- �����ϼ�      
                                          , @n_real_cnt                                 -- ����ϼ�      
                                          , @an_mod_user_id                             -- ������      
                                          , dbo.XF_SYSDATE(0)                           -- �����Ͻ�      
                                          , 'KST'                                       -- Ÿ�����ڵ�      
                                          , dbo.XF_SYSDATE(0) )                         -- Ÿ�����Ͻ�      
                                SELECT @ERRCODE = @@ERROR      
                                    IF @ERRCODE != 0      
                                        BEGIN      
                                            SET @av_ret_code      = 'FAILURE!'      
                                            SET @av_ret_message   = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') �޿� �����ӱ� ����� �����߻�[ERR]', @v_program_id, 0040, null, @an_mod_user_id)      
                                            CLOSE rep       -- Ŀ���ݱ�      
											DEALLOCATE rep  -- Ŀ�� �Ҵ�����      
                                            RETURN      
                                        END 

								-- �޿���� �� �޿��ݾ� ����(�޿��� �������� �� �ִ� 4���� ����)
								BEGIN
									IF @n_pay_cnt = 1
									   BEGIN
										   SET @v_pay01_ym = @v_base_pay_ym
										   SET @n_pay01_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 2
									   BEGIN
										  SET @v_pay02_ym = @v_base_pay_ym
										  SET @n_pay02_amt = @an_return_cal_mon
									   END 
									ELSE IF @n_pay_cnt = 3
									   BEGIN
										  SET @v_pay03_ym = @v_base_pay_ym
										  SET @n_pay03_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 4
									   BEGIN
										  SET @v_pay04_ym = @v_base_pay_ym
										  SET @n_pay04_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 5
									   BEGIN
										  SET @v_pay05_ym = @v_base_pay_ym
										  SET @n_pay05_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 6
									   BEGIN
										  SET @v_pay04_ym = @v_base_pay_ym
										  SET @n_pay04_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 7
									   BEGIN
										  SET @v_pay04_ym = @v_base_pay_ym
										  SET @n_pay04_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 8
									   BEGIN
										  SET @v_pay04_ym = @v_base_pay_ym
										  SET @n_pay04_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 9
									   BEGIN
										  SET @v_pay09_ym = @v_base_pay_ym
										  SET @n_pay09_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 10
									   BEGIN
										  SET @v_pay10_ym = @v_base_pay_ym
										  SET @n_pay10_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 11
									   BEGIN
										  SET @v_pay11_ym = @v_base_pay_ym
										  SET @n_pay11_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 12
									   BEGIN
										  SET @v_pay12_ym = @v_base_pay_ym
										  SET @n_pay12_amt = @an_return_cal_mon
									   END
								END

								BEGIN 										
								   SET @n_pay_cnt = @n_pay_cnt + 1  -- ���� ����ó��
								END
                            END      
                        FETCH NEXT FROM rep INTO @v_base_pay_ym      
                    END       -- Ŀ������ ����      
            CLOSE rep         -- Ŀ���ݱ�      
            DEALLOCATE rep    -- Ŀ�� �Ҵ�����      
        END -- Ŀ������  
		
		-- �����հ�����
		BEGIN
		   SET @n_pay_mon = ISNULL(@n_pay01_amt,0) + ISNULL(@n_pay02_amt,0) + ISNULL(@n_pay03_amt,0) + ISNULL(@n_pay04_amt,0) + ISNULL(@n_pay05_amt,0) + ISNULL(@n_pay06_amt,0) +	
		                    ISNULL(@n_pay07_amt,0) + ISNULL(@n_pay08_amt,0) + ISNULL(@n_pay09_amt,0) + ISNULL(@n_pay10_amt,0) + ISNULL(@n_pay11_amt,0) + ISNULL(@n_pay12_amt,0)
		   SET @n_pay_tot_amt = @n_pay_mon -- 3�����޿��հ�
		END

		-- ***************************************   
        -- 5. 12���� ���޳��� ����   
        -- ***************************************   
        BEGIN   
            UPDATE REP_CALC_LIST            -- �����ݰ������(����)  
               SET RETIRE_YMD			= @d_retire_ymd			-- ��������
		         , FLAG					= @v_flag_yn			-- 1��̸�
		         , BIZ_CD				= @v_biz_cd				-- �����
				 , REG_BIZ_CD			= @v_reg_biz_cd			-- �Ű�����
				 , ORG_NM				= @v_org_nm				-- ������
				 , ORG_LINE				= @v_org_line			-- ��������
	             , PAY_METH_CD			= @v_pay_meth_cd		-- �޿����޹��[PAY_METH_CD]
				 , CALCU_TPYE			= '2'					-- ��걸��
				 , EMP_CLS_CD			= @v_emp_cls_cd			-- �������[PAY_EMP_CLS_CD]
				 , INS_TYPE_YN			= @v_ins_type_yn		-- �������ݰ��Կ���
				 , INS_TYPE_CD			= @v_ins_type_cd		-- ������������[RMP_INS_TYPE_CD]								 
				 , REP_ANNUITY_BIZ_NM	= @v_ins_nm				-- �������ݻ���ڸ�
				 , REP_ANNUITY_BIZ_NO	= @v_ins_bizno			-- �������ݻ�����Ϲ�ȣ
				 , REP_BANK_CD			= @v_ins_bank_cd		-- �������������ڵ�
				 , REP_ACCOUNT_NO		= @v_ins_account_no		-- �������ݰ��¹�ȣ
			     , RETIRE_TURN          = @n_retire_turn_mon	-- ���ο���������ȯ��
			     , AMT_RATE_ADD			= @n_add_rate			-- �ӿ�������(���޹��)
			     , PAY01_YM				= @v_pay01_ym			-- �޿����_01
				 , PAY02_YM				= @v_pay02_ym			-- �޿����_02
				 , PAY03_YM				= @v_pay03_ym			-- �޿����_03
				 , PAY04_YM				= @v_pay04_ym			-- �޿����_04
				 , PAY05_YM				= @v_pay05_ym			-- �޿����_05
				 , PAY06_YM				= @v_pay06_ym			-- �޿����_06
				 , PAY07_YM				= @v_pay07_ym			-- �޿����_07
				 , PAY08_YM				= @v_pay08_ym			-- �޿����_08
				 , PAY09_YM				= @v_pay09_ym			-- �޿����_09
				 , PAY10_YM				= @v_pay10_ym			-- �޿����_10
				 , PAY11_YM				= @v_pay11_ym			-- �޿����_11
				 , PAY12_YM				= @v_pay12_ym			-- �޿����_12
				 , PAY01_AMT			= @n_pay01_amt			-- �޿��ݾ�_01
				 , PAY02_AMT			= @n_pay02_amt			-- �޿��ݾ�_02
				 , PAY03_AMT			= @n_pay03_amt			-- �޿��ݾ�_03
				 , PAY04_AMT			= @n_pay04_amt			-- �޿��ݾ�_04
				 , PAY05_AMT			= @n_pay05_amt			-- �޿��ݾ�_05
				 , PAY06_AMT			= @n_pay06_amt			-- �޿��ݾ�_06
				 , PAY07_AMT			= @n_pay07_amt			-- �޿��ݾ�_07
				 , PAY08_AMT			= @n_pay08_amt			-- �޿��ݾ�_08
				 , PAY09_AMT			= @n_pay09_amt			-- �޿��ݾ�_09
				 , PAY10_AMT			= @n_pay10_amt			-- �޿��ݾ�_10
				 , PAY11_AMT			= @n_pay11_amt			-- �޿��ݾ�_11
				 , PAY12_AMT			= @n_pay12_amt			-- �޿��ݾ�_12
				 , PAY_MON				= @n_pay_mon			-- �޿��հ�
				 , PAY_TOT_AMT			= @n_pay_tot_amt		-- 3�����޿��հ�
				 , ETC01_SUB_NM         = '������ȯ��'			-- ��Ÿ����1 ���� 
				 , ETC02_SUB_NM         = '��뺸��'			-- ��Ÿ����2 ����
				 , ETC03_SUB_NM         = '�ǰ�����'			-- ��Ÿ����3 ����
				 , ETC01_SUB_AMT		= dbo.XF_NVL_N(@n_retire_turn_mon, 0) -- ��Ÿ����1 �ݾ�
                 , MOD_USER_ID			= @an_mod_user_id		-- ������   
                 , MOD_DATE				= dbo.XF_SYSDATE(0)		-- �����Ͻ�   
             WHERE REP_CALC_LIST_ID =  @n_rep_calc_id   
            SELECT @ERRCODE = @@ERROR   
            IF @ERRCODE != 0   
                BEGIN   
                    SET @av_ret_code    = 'FAILURE!'   
                    SET @av_ret_message = dbo.F_FRM_ERRMSG('����ӱ� ����� �����߻�[ERR]', @v_program_id, 0040, null, @an_mod_user_id)   
                    RETURN   
                END   
        END---
  
    END      
    -- ***********************************************************      
    -- �۾� �Ϸ�      
    -- ***********************************************************      
    SET @av_ret_code    = 'SUCCESS!'      
    SET @av_ret_message = dbo.F_FRM_ERRMSG('�����ڷ� ������ �Ϸ�Ǿ����ϴ�[ERR]', @v_program_id, 9999, null, @an_mod_user_id)      
      
END
USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_CAL_PAY_STD]    Script Date: 2021-02-02 ���� 6:19:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_CAL_PAY_STD] (      
       @av_company_cd                 NVARCHAR(10),             -- �λ翵��      
       @av_locale_cd                  NVARCHAR(10),             -- �����ڵ�      
       @an_rep_calc_list_id_list      NUMERIC(38),				-- �����ݴ��ID      
       @an_mod_user_id                NUMERIC(38),				-- ������ ���      
       @av_ret_code                   NVARCHAR(4000)    OUTPUT, -- ����ڵ�*/      
       @av_ret_message                NVARCHAR(4000)    OUTPUT  -- ����޽���*/      
    ) AS      
    -- ***************************************************************************      
    --   TITLE       : ������ �����ӱݰ���/�ӱ��׸����      
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
		  , @n_pay01_amt			   NUMERIC(18)				-- �޿��ݾ�_01
		  , @n_pay02_amt			   NUMERIC(18)				-- �޿��ݾ�_02
		  , @n_pay03_amt			   NUMERIC(18)				-- �޿��ݾ�_03
		  , @n_pay04_amt			   NUMERIC(18)				-- �޿��ݾ�_04
		  , @n_pay_mon				   NUMERIC(18)				-- �޿��հ�
		  ,	@n_pay_tot_amt			   NUMERIC(18)				-- 3�����޿��հ�
		  , @v_bonus01_ym			   NVARCHAR(6)				-- �󿩳��_01
		  , @n_bonus01_amt			   NUMERIC(18)				-- �󿩱ݾ�_01
		  , @v_bonus02_ym			   NVARCHAR(6)				-- �󿩳��_02
		  , @n_bonus02_amt			   NUMERIC(18)				-- �󿩱ݾ�_02
		  , @v_bonus03_ym			   NVARCHAR(6)				-- �󿩳��_03
		  , @n_bonus03_amt			   NUMERIC(18)				-- �󿩱ݾ�_03
		  , @v_bonus04_ym			   NVARCHAR(6)				-- �󿩳��_04
		  , @n_bonus04_amt			   NUMERIC(18)				-- �󿩱ݾ�_04
		  , @v_bonus05_ym			   NVARCHAR(6)				-- �󿩳��_05
		  , @n_bonus05_amt			   NUMERIC(18)				-- �󿩱ݾ�_05
		  , @v_bonus06_ym			   NVARCHAR(6)				-- �󿩳��_06
		  , @n_bonus06_amt			   NUMERIC(18)				-- �󿩱ݾ�_06
		  , @v_bonus07_ym			   NVARCHAR(6)				-- �󿩳��_07
		  , @n_bonus07_amt			   NUMERIC(18)				-- �󿩱ݾ�_07
		  , @v_bonus08_ym			   NVARCHAR(6)				-- �󿩳��_08
		  , @n_bonus08_amt			   NUMERIC(18)				-- �󿩱ݾ�_08
		  , @v_bonus09_ym			   NVARCHAR(6)				-- �󿩳��_09
		  , @n_bonus09_amt			   NUMERIC(18)				-- �󿩱ݾ�_09
		  , @v_bonus10_ym			   NVARCHAR(6)				-- �󿩳��_10
		  , @n_bonus10_amt			   NUMERIC(18)				-- �󿩱ݾ�_10
		  , @v_bonus11_ym			   NVARCHAR(6)				-- �󿩳��_11
		  , @n_bonus11_amt			   NUMERIC(18)				-- �󿩱ݾ�_11
		  , @v_bonus12_ym			   NVARCHAR(6)				-- �󿩳��_12
		  , @n_bonus12_amt			   NUMERIC(18)				-- �󿩱ݾ�_12
		  , @n_bonus_mon			   NUMERIC(18)				-- ���Ѿ�
		  , @n_day_tot_amt			   NUMERIC(18)				-- �������Ѿ�
		  , @d_last_retire_date		   DATE						-- ������ ������	
		  , @n_real_cnt_tmp			   NUMERIC(3)				-- ����ϼ�_TEMP	
		  , @n_real_cnt_tmp1		   NUMERIC(3)				-- ����ϼ�_TEMP1
		  , @n_real_cnt_tmp2		   NUMERIC(3)				-- ����ϼ�_TEMP2
		  , @n_real_cnt_tmp3		   NUMERIC(3)				-- ����ϼ�_TEMP3
		  , @n_real_cnt_tmp4		   NUMERIC(3)				-- ����ϼ�_TEMP4

      
      /* �⺻���� �ʱⰪ ����*/      
    SET @v_program_id    = 'P_REP_CAL_PAY_STD'   -- ���� ���ν����� ������      
    SET @v_program_nm    = '������ �����ӱݰ���/�ӱ��׸����'        -- ���� ���ν����� �ѱ۹���      
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
			     , @n_org_id				= ORG_ID								-- ����ID
                 , @d_end_ymd               = C1_END_YMD							-- ��(��)������  
                 , @n_rep_calc_list_id_list = REP_CALC_LIST_ID						-- ����� ������ID     
				 , @n_retire_turn_mon		= ISNULL(dbo.F_REP_PEN_RETIRE_MON(EMP_ID, RETIRE_YMD), 0) 	-- ���ο���������ȯ��	
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
            DELETE A
			  FROM REP_PAYROLL_DETAIL A
			  JOIN REP_PAY_STD B
			    ON A.REP_PAY_STD_ID = B.REP_PAY_STD_ID
             WHERE B.REP_CALC_LIST_ID = @n_rep_calc_list_id_list
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
        -- 4. 3����ġ �޿� ��ȸ      
        -- ***************************************      
        BEGIN  
		    SET @d_last_retire_date = dbo.XF_LAST_DAY(@d_end_ymd) -- ������ ������
            SET @n_roop_cnt = CASE WHEN @d_end_ymd = dbo.XF_LAST_DAY(@d_end_ymd) THEN 3 ELSE 4 END     
            SET @n_pay_cnt = 1     
            SET @n_real_cnt_tmp  = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_end_ymd, 'DD')) -- ������ ���� 			
			
            DECLARE rep CURSOR FOR      
                SELECT DISTINCT A.PAY_YM AS BASE_YM      
                  FROM PAY_PAY_YMD A      
                       INNER JOIN PAY_PAYROLL B      
                           ON B.PAY_YMD_ID = A.PAY_YMD_ID 
                 WHERE B.EMP_ID = @n_emp_id      
                   AND A.CLOSE_YN = 'Y' 
				   AND A.PAY_YN = 'Y'
                   AND A.PAY_YM <= FORMAT(@d_end_ymd, 'yyyyMM') -- dbo.XF_TO_CHAR_D(@d_end_ymd, 'YYYYMM')      
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
                WHILE (@@FETCH_STATUS = 0 AND @n_roop_cnt >= @n_pay_cnt)      
                    BEGIN -- Ŀ������      
                        -- ***************************************      
                        -- 4-1. �����׸� ������ ä��      
                        -- ***************************************  
				
                        BEGIN      
                           SELECT @n_rep_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE      
                              FROM DUAL      
                        END      
                        -- ***************************************      
                        -- 4-2. ��¥, �ϼ� ����      
                        -- ***************************************  

                        BEGIN     
                            IF @n_pay_cnt = 1 AND @v_base_pay_ym <> dbo.XF_TO_CHAR_D(@d_end_ymd, 'YYYYMM')     
                                BEGIN     
                                    SET @n_roop_cnt = 3     
                                END     

                            SET @d_base_s_ymd = CASE WHEN @n_roop_cnt = @n_pay_cnt THEN dbo.XF_TO_DATE(@v_base_pay_ym + dbo.XF_TO_CHAR_D(dbo.XF_DATEADD(dbo.XF_MONTHADD(@d_end_ymd, -3), 1),'DD'),'YYYYMMDD')    
                                                     ELSE dbo.XF_TO_DATE(@v_base_pay_ym + '01','YYYYMMDD')     
                                                END     
                            SET @d_base_e_ymd = CASE WHEN @n_roop_cnt <> 3 AND @n_pay_cnt = 1 THEN @d_end_ymd     
                                                     ELSE dbo.XF_LAST_DAY(dbo.XF_TO_DATE(@v_base_pay_ym + '01','YYYYMMDD'))     
                                                END     
                            -- ��Ű�� ���� ��������
							SET @n_base_cnt = CASE WHEN @n_pay_cnt = 1 THEN dbo.XF_DATEDIFF(@d_base_e_ymd, @d_base_s_ymd)+1    
                                                   ELSE dbo.XF_DATEDIFF(dbo.XF_LAST_DAY(dbo.XF_TO_DATE(@v_base_pay_ym + '01','YYYYMMDD')), dbo.XF_TO_DATE(@v_base_pay_ym + '01','YYYYMMDD'))+1   
                                              END      
                            SET @n_real_cnt = dbo.XF_DATEDIFF(@d_base_e_ymd, @d_base_s_ymd)+1  
							
							-- �����׷� ��������
							SET @n_base_cnt = 30
							SET @n_real_cnt = 30

							IF (@d_last_retire_date != @d_end_ymd)               -- ������ ������ �ƴϸ�
							   BEGIN
							      IF @n_roop_cnt = @n_pay_cnt  --- ���� ���ۿ� �޿� 
								     BEGIN
									    SET @n_real_cnt = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(dbo.XF_LAST_DAY(@d_base_s_ymd), 'DD')) - @n_real_cnt_tmp 
										BEGIN
										   IF (@v_emp_cls_cd = 'A' AND @av_company_cd = 'H')
										      BEGIN
											     SET @n_real_cnt = 30 - @n_real_cnt_tmp
                                    		  END
										   ELSE IF (@av_company_cd = 'C' OR 
										            @av_company_cd = 'A' OR
													@av_company_cd = 'B' OR 
													@av_company_cd = 'X' OR 
													@av_company_cd = 'Y')
                                                   BEGIN
												      SET @n_real_cnt = 30 - @n_real_cnt_tmp 
												   END
										   ELSE IF (@av_company_cd = 'T') -- ��ũ�� ��� �޿��� ���� �� �ֱ� 3����ġ �޿� ������� ���
										           BEGIN
												      IF (@v_mgr_type_cd = 'B' AND @n_real_cnt_tmp >= 20)
													     BEGIN
                                                            SET @n_real_cnt = 0
														    SET @n_base_cnt = 0
														 END
                                                      ELSE IF (@v_mgr_type_cd <> 'B' AND @n_real_cnt_tmp >= 30)
													     BEGIN
                                                            SET @n_real_cnt = 0
														    SET @n_base_cnt = 0
														 END                                                      
												   END
										   ELSE IF (@av_company_cd = 'J' OR
										            @av_company_cd = 'W')
                                                   BEGIN
												      SET @n_real_cnt = 30 - @n_real_cnt_tmp
												   END
										   ELSE IF (@av_company_cd = 'S')
										           BEGIN
												      SET @n_real_cnt = 30 - @n_real_cnt_tmp
												   END
                                           ELSE
										           BEGIN
												      SET @n_base_s_ymd_cnt = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(dbo.XF_LAST_DAY(@d_base_s_ymd), 'DD'))  -- �������� ����������
                                                      SET @n_real_cnt = @n_base_s_ymd_cnt - @n_real_cnt_tmp;
												   END
										END
									 END
                                  ELSE IF @n_pay_cnt = 1 -- ������ �޿�
								     
								     BEGIN
									   SET @n_real_cnt = @n_real_cnt_tmp
									   SET @n_base_cnt = @n_real_cnt_tmp
									   IF (@av_company_cd = 'T')
									      BEGIN
										     IF (@v_mgr_type_cd = 'B' AND @n_real_cnt_tmp < 20)
											    BEGIN
												   SET @n_real_cnt = 0
												   SET @n_base_cnt = 0
												END
                                             ELSE IF (@v_mgr_type_cd <> 'B' AND @n_real_cnt_tmp < 30)
                                                BEGIN
												   SET @n_real_cnt = 0
												   SET @n_base_cnt = 0
												END
										  END
                                       ELSE IF (@av_company_cd = 'S')
									      BEGIN
									         IF (@n_real_cnt_tmp >= 10)
											    BEGIN
												   SET @n_real_cnt = @n_real_cnt_tmp
												END

										  END
									 END
							   END
                        END    
	
                        -- ***************************************      
                        -- 4-2. �ӱ��׸� ����      
                        -- ***************************************  

						-- ������ �ش� LOGIC �ݿ����� ����
						SET @an_return_cal_mon = 0

						BEGIN
							IF @v_emp_cls_cd <> 'S'
								BEGIN      
									--print 'P_REP_CAL_PAY_DETAIL 1 START ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')
									EXEC dbo.P_REP_CAL_PAY_DETAIL @av_company_cd      
																, @n_rep_calc_list_id_list      
																, @n_rep_id      
																, @v_base_pay_ym      
																, '10'                          -- �޿�      
																, @n_base_cnt                   -- �����ϼ�      
																, @n_real_cnt                   -- ���ϼ�      
																, 'Y'                           -- ���Ұ�꿩��      
																, @an_mod_user_id      
																, @an_return_cal_mon output      
																, @av_ret_code output      
																, @av_ret_message output      
									--print 'P_REP_CAL_PAY_DETAIL 1 END ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')
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
									ELSE
									   BEGIN
										  SET @v_pay04_ym = @v_base_pay_ym
										  SET @n_pay04_amt = @an_return_cal_mon
									   END
								END
                            END   
							
                        BEGIN 										
						   SET @n_pay_cnt = @n_pay_cnt + 1  -- ���� ����ó��
						END

                        FETCH NEXT FROM rep INTO @v_base_pay_ym      
                    END       -- Ŀ������ ����      
            CLOSE rep         -- Ŀ���ݱ�      
            DEALLOCATE rep    -- Ŀ�� �Ҵ�����      
        END -- Ŀ������  

		-- �޿��հ�����
		BEGIN
		   SET @n_pay_mon = ISNULL(@n_pay01_amt,0) + ISNULL(@n_pay02_amt,0) + ISNULL(@n_pay03_amt,0) + ISNULL(@n_pay04_amt,0)	-- �޿��հ�
		   SET @n_pay_tot_amt = @n_pay_mon -- 3�����޿��հ�
		END
PRINT(' �޿� ===> ' + CONVERT(VARCHAR, @n_pay_tot_amt) + ' ' + FORMAT(SYSDATETIME(), 'HH:mm:ss.fffff'))
        -- ***************************************      
        -- 5. 1��ġ ����� ��ȸ      
        -- ***************************************      
        SET @v_base_pay_ym = NULL      
        SET @d_bns_s_ymd = NULL      
        SET @d_bns_e_ymd = NULL      
		SET @an_return_cal_mon = 0      
        SET @n_rep_id = NULL
		SET @n_bns_cnt = 1
		--SET @n_bns_roop_cnt = 12
		
		-- �� �Ⱓ����
		BEGIN
		   IF (@av_company_cd = 'A' AND @v_emp_cls_cd = 'A')
              BEGIN
			     -- �󿩰�������
                 SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_end_ymd, -12)     -- DateAndTime.DateAdd("m", -12, str_t_pay_date_tmp);
                 -- �󿩰��������
                 SET @d_bns_e_ymd = dbo.XF_MONTHADD(@d_end_ymd, -1)      -- DateAndTime.DateAdd("m", -1, str_t_pay_date_tmp);
			  END
           ELSE IF (@av_company_cd = 'I' ) -- ����󿩴� �������� 12����
		      BEGIN
			     -- ��� �������� ����/���� A,����8, ����B, ����C
                 IF (@v_mgr_type_cd = 'A' OR @v_mgr_type_cd = '8')
                    BEGIN
                       -- �󿩰�������
                       SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_end_ymd, -12) -- DateAndTime.DateAdd("m", -12, str_t_pay_date_tmp);
                       -- �󿩰��������
                       SET @d_bns_e_ymd = dbo.XF_MONTHADD(@d_end_ymd, -1)  -- DateAndTime.DateAdd("m", -1, str_t_pay_date_tmp);
                    END
                 ELSE
                    BEGIN
                       -- �󿩰�������
                       SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_end_ymd, -11) -- DateAndTime.DateAdd("m", -11, str_t_pay_date_tmp);
                       -- �󿩰��������
                       SET @d_bns_e_ymd = @d_end_ymd						-- dte_t_bonus_date.ToString("yyyyMMdd");
                    END
			  END
           ELSE
              BEGIN
			     -- �󿩰�������
                 SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_end_ymd, -11)		-- DateAndTime.DateAdd("m", -11, str_t_pay_date_tmp);
                 -- �󿩰��������
				 SET @d_bns_e_ymd = @d_end_ymd								-- str_t_pay_date.Replace("-", "");
			  END
		END

        BEGIN        
--PRINT('---->'+
--        '@n_emp_id=' + CONVERT(NVARCHAR(100), @n_emp_id)+
--      ',@av_company_cd=' + CONVERT(NVARCHAR(100), @av_company_cd)+
--	  ',@av_locale_cd=' + CONVERT(NVARCHAR(100), @av_locale_cd )+
--	  ',@v_exec_yn=' + CONVERT(NVARCHAR(100), @v_exec_yn)+
--	  ',@d_end_ymd=' + CONVERT(NVARCHAR(100), @d_end_ymd)+
--	  ',@d_bns_s_ymd=' + CONVERT(NVARCHAR(100), @d_bns_s_ymd)+
--	  ',@d_bns_e_ymd=' + CONVERT(NVARCHAR(100), @d_bns_e_ymd)
--	  )
            DECLARE sbpay CURSOR FOR      
                SELECT BASE_YM      
                     --, STA_YMD      
                     --, END_YMD     
                     --, BASE_DAY     
                  FROM (SELECT BASE_YM      
                             --, STA_YMD      
                             --, END_YMD      
                             --, dbo.XF_DATEDIFF(END_YMD, STA_YMD)+1 AS BASE_DAY     
                             , ROW_NUMBER() OVER (ORDER BY BASE_YM DESC) AS ROWNUM     
                          FROM (SELECT DISTINCT A.PAY_YM AS BASE_YM      
                                              --, A.STA_YMD      
                                              --, A.END_YMD      
                                  FROM PAY_PAY_YMD A      
                                       INNER JOIN PAY_PAYROLL B      
                                                           ON B.PAY_YMD_ID = A.PAY_YMD_ID      
                                       INNER JOIN PAY_PAYROLL_DETAIL C     
                                                                  ON C.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID     
                                 WHERE B.EMP_ID = @n_emp_id      
                                   AND C.CAL_MON > 0   
                                   AND C.PAY_ITEM_CD IN (SELECT KEY_CD3 AS PAY_ITEM_CD  
					                                       FROM FRM_UNIT_STD_HIS  
					                                      WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
												                                         FROM FRM_UNIT_STD_MGR  
												                                        WHERE COMPANY_CD = @av_company_cd  
													                                      AND UNIT_CD = 'REP'  
													                                      AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END)  
					                                        AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
					                                        AND KEY_CD1 = '20')      
                                   AND A.CLOSE_YN = 'Y'  
								   AND A.PAY_YN = 'Y'
								   --AND A.PAY_YM BETWEEN dbo.XF_TO_CHAR_D(@d_bns_s_ymd,'YYYYMM') AND dbo.XF_TO_CHAR_D(@d_bns_e_ymd, 'YYYYMM')   
								   AND A.PAY_YM BETWEEN FORMAT(@d_bns_s_ymd, 'yyyyMM') AND FORMAT(@d_bns_e_ymd, 'yyyyMM')
                                   AND A.PAY_YM NOT IN (SELECT Y.BASE_YM      
                                                          FROM (SELECT dbo.XF_TO_CHAR_D(T.STA_YMD, 'YYYYMM') AS STA_YM,      
                                                                       dbo.XF_TO_CHAR_D(T.END_YMD, 'YYYYMM') AS END_YM      
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
                                                                   ON Y.BASE_YM BETWEEN X.STA_YM AND X.END_YM )) C3 ) C4               
                 ORDER BY BASE_YM ASC      
            OPEN sbpay      
                FETCH NEXT FROM sbpay INTO @v_base_pay_ym--, @d_base_s_ymd, @d_base_e_ymd, @n_base_cnt      
                WHILE (@@FETCH_STATUS = 0)      
                    BEGIN -- Ŀ������  
                        -- ***************************************      
                        -- 5-1. �����׸� ������ ä��      
                        -- ***************************************      
                        BEGIN      
                            SELECT @n_rep_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE      
                              FROM DUAL      
                        END      
                        -- ***************************************      
                        -- 5-2. �ӱ��׸� ����      
                        -- *************************************** 
						SET @n_base_cnt  = dbo.XF_DATEDIFF(dbo.XF_LAST_DAY(dbo.XF_TO_DATE(@v_base_pay_ym+'01', 'YYYYMMDD')), dbo.XF_TO_DATE(@v_base_pay_ym+'01', 'YYYYMMDD')) + 1
                        BEGIN      
									--print 'P_REP_CAL_PAY_DETAIL 2 START ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')
                            EXEC dbo.P_REP_CAL_PAY_DETAIL @av_company_cd      
                                                        , @n_rep_calc_list_id_list      
                                                        , @n_rep_id      
                                                        , @v_base_pay_ym      
                                                        , '20'      
                                                        , @n_base_cnt      
                                                        , @n_base_cnt      
                                                        , 'N'      
                                                        , @an_mod_user_id      
                                                        , @an_return_cal_mon OUTPUT      
                                                        , @av_ret_code OUTPUT      
                                                        , @av_ret_message OUTPUT      
									--print 'P_REP_CAL_PAY_DETAIL 2 END ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')
                            IF @av_ret_code = 'FAILURE!'      
                                BEGIN      
                                    SET @av_ret_code     = 'FAILURE!'      
                                    SET @av_ret_message  = @av_ret_message      
                                    CLOSE sbpay      -- Ŀ���ݱ�      
                                    DEALLOCATE sbpay -- Ŀ�� �Ҵ�����      
                                    RETURN      
                                END      
                        END 

                        -- ***************************************      
                        -- 5-3. �����ӱ� ����      
                        -- ***************************************      
                        IF @an_return_cal_mon <> 0  
						    BEGIN
							   IF @n_bns_cnt = 1 
							      BEGIN
								     SET @v_bonus01_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus01_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END							   
							   ELSE IF @n_bns_cnt = 2 
							      BEGIN
								     SET @v_bonus02_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus02_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END							   
							   ELSE IF @n_bns_cnt = 3
							      BEGIN
								     SET @v_bonus03_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus03_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END	
							   ELSE IF @n_bns_cnt = 4
							      BEGIN
								     SET @v_bonus04_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus04_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END	
							   ELSE IF @n_bns_cnt = 5
							      BEGIN
								     SET @v_bonus05_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus05_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END	
							   ELSE IF @n_bns_cnt = 6 
							      BEGIN
								     SET @v_bonus06_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus06_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END	
							   ELSE IF @n_bns_cnt = 7
							      BEGIN
								     SET @v_bonus07_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus07_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END	
							   ELSE IF @n_bns_cnt = 8
							      BEGIN
								     SET @v_bonus08_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus08_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END	
							   ELSE IF @n_bns_cnt = 9
							      BEGIN
								     SET @v_bonus09_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus09_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END	
							   ELSE IF @n_bns_cnt = 10
							      BEGIN
								     SET @v_bonus10_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus10_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END	
							   ELSE IF @n_bns_cnt = 11
							      BEGIN
								     SET @v_bonus11_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus11_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END	
							   ELSE IF @n_bns_cnt = 12
							      BEGIN
								     SET @v_bonus12_ym = @v_base_pay_ym			-- �󿩳��_01
		                             SET @n_bonus12_amt = @an_return_cal_mon	-- �󿩱ݾ�_01
								  END	
							END
						     
--Print('asdfasd����22222=>' + convert(nvarchar(100), @an_return_cal_mon))
--Print(
--		'@v_base_pay_ym =' + convert(nvarchar(100), @v_base_pay_ym) +
--	', @d_base_s_ymd =' + convert(nvarchar(100), @d_base_s_ymd) +
--	', @d_base_e_ymd =' + convert(nvarchar(100), @d_base_e_ymd) +
--	', @n_base_cnt =' + convert(nvarchar(100), @n_base_cnt) 
--)
                            BEGIN      
                                INSERT INTO REP_PAY_STD                             -- �����ݱ��� �ӱ� ����      
                                          ( REP_PAY_STD_ID                          -- �����ݱ��� �ӱ� ����ID      
                                          , REP_CALC_LIST_ID                        -- �����ݴ��ID      
                                          , PAY_TYPE_CD                             -- �޿����ޱ���[PAY_TYPE_CD]      
                                          , PAY_YM									-- �޿����      
										  , SEQ                                     -- ����      
                                          , STA_YMD                                 -- ��������      
                                          , END_YMD                                 -- ��������      
										  , BASE_DAY                                -- �����ϼ�      
                                          , MINUS_DAY                               -- �����ϼ�      
                                          , REAL_DAY                                -- ����ϼ�      
                                          , MOD_USER_ID                             -- ������      
                                          , MOD_DATE                                -- �����Ͻ�      
                                          , TZ_CD                                   -- Ÿ�����ڵ�      
                                          , TZ_DATE )                             -- Ÿ�����Ͻ�      
                                    VALUES( @n_rep_id                               -- �����ݱ��� �ӱ� ����ID      
                                          , @n_rep_calc_list_id_list                -- �����ݴ��ID      
                                          , '20'                                    -- �޿����ޱ���[REP_PAY_TYPE_CD]      
                                          , @v_base_pay_ym                          -- �޿����      
                                          , @n_bns_cnt                              -- ����      
                                          , dbo.XF_TO_DATE(@v_base_pay_ym+'01', 'YYYYMMDD') -- ��������      
                                          , dbo.XF_LAST_DAY(dbo.XF_TO_DATE(@v_base_pay_ym+'01', 'YYYYMMDD'))                           -- ��������      
                                          , @n_base_cnt                             -- �����ϼ�      
                                          , 0                                       -- �����ϼ�      
                                          , @n_base_cnt                             -- ����ϼ�      
                                          , @an_mod_user_id                         -- ������      
                                          , dbo.XF_SYSDATE(0)                       -- �����Ͻ�      
                                          , 'KST'                                   -- Ÿ�����ڵ�      
                                          , dbo.XF_SYSDATE(0) )                     -- Ÿ�����Ͻ�              
                                SELECT @ERRCODE = @@ERROR      
                                    IF @ERRCODE != 0      
                                        BEGIN      
                                            SET @av_ret_code      = 'FAILURE!'      
                                            SET @av_ret_message   = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') �� �����ӱ� ����� �����߻�', @v_program_id, 0050, null, @an_mod_user_id)      
                                            CLOSE sbpay      -- Ŀ���ݱ�      
                                            DEALLOCATE sbpay -- Ŀ�� �Ҵ�����      
                                            RETURN      
                                        END 
								BEGIN 										
								   SET @n_bns_cnt = @n_bns_cnt + 1  -- ���� ����ó��
								END		
                            END      
                        FETCH NEXT FROM sbpay INTO @v_base_pay_ym--, @d_base_s_ymd, @d_base_e_ymd, @n_base_cnt      
                    END         -- Ŀ������ ����     

            CLOSE sbpay         -- Ŀ���ݱ�      
            DEALLOCATE sbpay    -- Ŀ�� �Ҵ�����      
        END                     -- Ŀ������      

		-- ���հ�����
		BEGIN
		   SET @n_bonus_mon = ISNULL(@n_bonus01_amt,0) + ISNULL(@n_bonus02_amt,0) + ISNULL(@n_bonus03_amt,0) + ISNULL(@n_bonus04_amt,0)	 + ISNULL(@n_bonus05_amt, 0) +  
		   					  ISNULL(@n_bonus06_amt,0) + ISNULL(@n_bonus07_amt,0) + ISNULL(@n_bonus08_amt,0) + ISNULL(@n_bonus09_amt,0)	 + ISNULL(@n_bonus10_amt, 0)	-- ���հ�	
		END
PRINT(' ��KKK ===> ' + CONVERT(VARCHAR, @n_bonus_mon) )

PRINT(' @n_bef_ret_year ===> ' + CONVERT(VARCHAR, @n_bef_ret_year) )
        -- ***************************************      
        -- 6. 1��ġ ���� ��ȸ      
        -- ***************************************      
        SET @v_base_pay_ym = NULL
		SET @n_bef_ret_year = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_bns_e_ymd, 'YYYY')) - 1
        SET @d_day_s_ymd = dbo.XF_TO_DATE(CONVERT(VARCHAR, @n_bef_ret_year) + dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_bns_e_ymd,'YYYYMMDD'),5,2) + dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_bns_e_ymd,'YYYYMMDD'),7,2), 'YYYYMMDD')
        SET @d_day_e_ymd = @d_bns_e_ymd      
        SET @an_return_cal_mon = 0      
        SET @n_rep_id = NULL   
		
        BEGIN   

PRINT(' @n_bef_ret_year ===> ' + CONVERT(VARCHAR, @n_bef_ret_year) )		
PRINT(' @d_day_s_ymd ===> ' + CONVERT(VARCHAR, @d_day_s_ymd) )
PRINT(' @d_day_e_ymd ===> ' + CONVERT(VARCHAR, @d_day_e_ymd) )
PRINT('---->'+
        '@n_emp_id=' + CONVERT(NVARCHAR(100), @n_emp_id)+
      ',@av_company_cd=' + CONVERT(NVARCHAR(100), @av_company_cd)+
	  ',@av_locale_cd=' + CONVERT(NVARCHAR(100), @av_locale_cd )+
--	  ',@v_exec_yn=' + CONVERT(NVARCHAR(100), @v_exec_yn)+
	  ',@d_end_ymd=' + CONVERT(NVARCHAR(100), @d_end_ymd)+
	  ',@d_day_s_ymd=' + CONVERT(NVARCHAR(100), @d_day_s_ymd)+
	  ',@d_day_e_ymd=' + CONVERT(NVARCHAR(100), @d_day_e_ymd)
	  )
            DECLARE dtm CURSOR FOR 

                SELECT BASE_YM      
                     , STA_YMD      
                     , END_YMD     
                     , BASE_DAY     
                  FROM (SELECT BASE_YM      
                             , STA_YMD      
                             , END_YMD      
                             , dbo.XF_DATEDIFF(END_YMD, STA_YMD)+1 AS BASE_DAY     
                             , ROW_NUMBER() OVER (ORDER BY BASE_YM DESC) AS ROWNUM     
                          FROM (SELECT DISTINCT A.PAY_YM AS BASE_YM      
                                              , A.STA_YMD      
                                              , A.END_YMD      
                                  FROM PAY_PAY_YMD A      
                                       INNER JOIN PAY_PAYROLL B      
                                                           ON B.PAY_YMD_ID = A.PAY_YMD_ID      
                                       INNER JOIN PAY_PAYROLL_DETAIL C     
                                                                  ON C.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID     
                                 WHERE B.EMP_ID = @n_emp_id      
                                   AND C.CAL_MON > 0   
                                   AND C.PAY_ITEM_CD IN (SELECT KEY_CD3 AS PAY_ITEM_CD  
					                                       FROM FRM_UNIT_STD_HIS  
					                                      WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
												                                         FROM FRM_UNIT_STD_MGR  
												                                        WHERE COMPANY_CD = @av_company_cd  
													                                      AND UNIT_CD = 'REP'  
													                                      AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END)  
					                                        AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
					                                        AND KEY_CD1 = '30')      
                                   AND A.CLOSE_YN = 'Y'  
								   AND A.PAY_YN = 'Y'
								   AND A.PAY_YM >= FORMAT(@d_day_s_ymd, 'yyyyMM') -- dbo.XF_TO_CHAR_D(@d_day_s_ymd,'YYYYMM') 
								   AND A.PAY_YM < FORMAT(@d_day_e_ymd, 'yyyyMM') --dbo.XF_TO_CHAR_D(@d_day_e_ymd, 'YYYYMM')   
                                   AND A.PAY_YM NOT IN (SELECT Y.BASE_YM      
                                                          FROM (SELECT dbo.XF_TO_CHAR_D(T.STA_YMD, 'YYYYMM') AS STA_YM,      
                                                                       dbo.XF_TO_CHAR_D(T.END_YMD, 'YYYYMM') AS END_YM      
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
                                                                   ON Y.BASE_YM BETWEEN X.STA_YM AND X.END_YM )) C3 ) C4               
                 ORDER BY BASE_YM ASC   			
        
            OPEN dtm      
                FETCH NEXT FROM dtm INTO @v_base_pay_ym, @d_base_s_ymd, @d_base_e_ymd, @n_base_cnt      
                WHILE (@@FETCH_STATUS = 0)      
                    BEGIN      
                        -- ***************************************      
                        -- 6-1. �����׸� ������ ä��      
                        -- ***************************************      
                        BEGIN      
                            SELECT @n_rep_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE      
                              FROM DUAL      
                        END      
                        -- ***************************************      
                        -- 6-2. �ӱ��׸� ����      
                        -- ***************************************      
                        BEGIN      
									--print 'P_REP_CAL_PAY_DETAIL 3 START ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')
                            EXEC dbo.P_REP_CAL_PAY_DETAIL @av_company_cd      
                                                        , @n_rep_calc_list_id_list      
                                                        , @n_rep_id      
                                                        , @v_base_pay_ym      
                                                        , '30'      
                                                        , @n_base_cnt      
                                                        , @n_base_cnt      
                                                        , 'N'      
                                                        , @an_mod_user_id      
                                                        , @an_return_cal_mon OUTPUT      
                                                        , @av_ret_code OUTPUT      
                                                        , @av_ret_message OUTPUT  
									--print 'P_REP_CAL_PAY_DETAIL 3 END ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')    
                            IF @av_ret_code = 'FAILURE!'      
                                BEGIN      
                                    SET @av_ret_code     = 'FAILURE!'      
                                    SET @av_ret_message  = @av_ret_message      
                                    CLOSE dtm      -- Ŀ���ݱ�      
                                    DEALLOCATE dtm -- Ŀ�� �Ҵ�����      
                                    RETURN      
                                END      
                        END 
			
                        -- ***************************************      
                        -- 5-3. �����ӱ� ����      
                        -- ***************************************      
                        IF @an_return_cal_mon <> 0  
						
						    -- ����������
							BEGIN
							   SET @n_day_tot_amt = @an_return_cal_mon		-- �������Ѿ�
							END 
PRINT(' ���� ===> ' + CONVERT(VARCHAR, @n_day_tot_amt) )
                            BEGIN      
                                INSERT INTO REP_PAY_STD                             -- �����ݱ��� �ӱ� ����      
                                          ( REP_PAY_STD_ID                          -- �����ݱ��� �ӱ� ����ID      
                                          , REP_CALC_LIST_ID                        -- �����ݴ��ID      
                                          , PAY_TYPE_CD                             -- �޿����ޱ���[PAY_TYPE_CD]      
                                          , PAY_YM                                  -- �޿����      
                                          , SEQ                                     -- ����      
                                          , STA_YMD                                 -- ��������      
                                          , END_YMD                                 -- ��������      
                                          , BASE_DAY                                -- �����ϼ�      
                                          , MINUS_DAY                               -- �����ϼ�      
                                          , REAL_DAY                                -- ����ϼ�      
										  , MOD_USER_ID                             -- ������      
                                          , MOD_DATE                                -- �����Ͻ�      
                                          , TZ_CD                                   -- Ÿ�����ڵ�      
                                          , TZ_DATE )                               -- Ÿ�����Ͻ�      
                                    VALUES( @n_rep_id                               -- �����ݱ��� �ӱ� ����ID      
                                          , @n_rep_calc_list_id_list                -- �����ݴ��ID      
                                          , '30'                                    -- �޿����ޱ���[REP_PAY_TYPE_CD]      
                                          , @v_base_pay_ym                          -- �޿����      
                                          , 3                                       -- ����      
                                          , @d_base_s_ymd                           -- ��������      
                                          , @d_base_e_ymd                           -- ��������      
                                          , @n_base_cnt                             -- �����ϼ�      
                                          , 0                                       -- �����ϼ�      
                                          , @n_base_cnt                             -- ����ϼ�      
                                          , @an_mod_user_id                         -- ������      
                                          , dbo.XF_SYSDATE(0)                       -- �����Ͻ�      
                                          , 'KST'                                   -- Ÿ�����ڵ�      
                                          , dbo.XF_SYSDATE(0) )                     -- Ÿ�����Ͻ�              
                                SELECT @ERRCODE = @@ERROR      
                                    IF @ERRCODE != 0      
                                        BEGIN      
                                            SET @av_ret_code      = 'FAILURE!'      
                                            SET @av_ret_message   = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') ���� �����ӱ� ����� �����߻�', @v_program_id, 0050, null, @an_mod_user_id)      
                                            CLOSE dtm      -- Ŀ���ݱ�      
                                            DEALLOCATE dtm -- Ŀ�� �Ҵ�����      
                                            RETURN      
                                        END 
									
                            END      
                        FETCH NEXT FROM dtm INTO @v_base_pay_ym, @d_base_s_ymd, @d_base_e_ymd, @n_base_cnt      
                    END     -- Ŀ������ ����  
            CLOSE dtm       -- Ŀ���ݱ�      
            DEALLOCATE dtm  -- Ŀ�� �Ҵ�����      
        END -- Ŀ������  

        -- ***************************************   
        -- 7. 3�����޿�, 12������ ���� ����   
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
				 , PAY01_AMT			= @n_pay01_amt			-- �޿��ݾ�_01
				 , PAY02_AMT			= @n_pay02_amt			-- �޿��ݾ�_02
				 , PAY03_AMT			= @n_pay03_amt			-- �޿��ݾ�_03
				 , PAY04_AMT			= @n_pay04_amt			-- �޿��ݾ�_04
				 , PAY_MON				= @n_pay_mon			-- �޿��հ�
				 , PAY_TOT_AMT			= @n_pay_tot_amt		-- 3�����޿��հ�
				 , BONUS01_YM			= @v_bonus01_ym			-- �󿩳��_01
				 , BONUS02_YM			= @v_bonus02_ym			-- �󿩳��_02
				 , BONUS03_YM			= @v_bonus03_ym			-- �󿩳��_03
				 , BONUS04_YM			= @v_bonus04_ym			-- �󿩳��_04
				 , BONUS05_YM			= @v_bonus05_ym			-- �󿩳��_05
				 , BONUS06_YM			= @v_bonus06_ym			-- �󿩳��_06
				 , BONUS07_YM			= @v_bonus07_ym			-- �󿩳��_07
				 , BONUS08_YM			= @v_bonus08_ym			-- �󿩳��_08
				 , BONUS09_YM			= @v_bonus09_ym			-- �󿩳��_09
				 , BONUS10_YM			= @v_bonus10_ym			-- �󿩳��_10
				 , BONUS11_YM			= @v_bonus11_ym			-- �󿩳��_11
				 , BONUS12_YM			= @v_bonus12_ym			-- �󿩳��_12
				 , BONUS01_AMT			= @n_bonus01_amt		-- �󿩱ݾ�_01
				 , BONUS02_AMT			= @n_bonus02_amt		-- �󿩱ݾ�_02
				 , BONUS03_AMT			= @n_bonus03_amt		-- �󿩱ݾ�_03
				 , BONUS04_AMT			= @n_bonus04_amt		-- �󿩱ݾ�_04
				 , BONUS05_AMT			= @n_bonus05_amt		-- �󿩱ݾ�_05
				 , BONUS06_AMT			= @n_bonus06_amt		-- �󿩱ݾ�_06
				 , BONUS07_AMT			= @n_bonus07_amt		-- �󿩱ݾ�_07
				 , BONUS08_AMT			= @n_bonus08_amt		-- �󿩱ݾ�_08
				 , BONUS09_AMT			= @n_bonus09_amt		-- �󿩱ݾ�_09
				 , BONUS10_AMT			= @n_bonus10_amt		-- �󿩱ݾ�_10
				 , BONUS11_AMT			= @n_bonus11_amt		-- �󿩱ݾ�_11
				 , BONUS12_AMT			= @n_bonus12_amt		-- �󿩱ݾ�_12
				 , BONUS_MON			= @n_bonus_mon			-- ���Ѿ�
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
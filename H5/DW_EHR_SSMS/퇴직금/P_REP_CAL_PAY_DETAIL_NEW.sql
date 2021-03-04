SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_CAL_PAY_DETAIL] (  
       @av_company_cd                 VARCHAR(10),             -- �λ翵��  
       @an_rep_calc_list_id           NUMERIC(38),             -- �����ݴ��ID  
       @an_rep_pay_std_id             NUMERIC(38),             -- �����ӱ�ID  
       @av_pay_ym                     VARCHAR(8),              -- �޿����  
       @av_pay_type_cd                VARCHAR(10),             -- �޿����ޱ���(10:�޿�, 20:��, 40: ����)   
       @an_base_day                   NUMERIC(10),             -- �����ϼ�  
       @an_real_day                   NUMERIC(10),             -- ���ϼ�  
       @av_flag                       VARCHAR(10),             -- ���Ұ�꿩��  
       @an_mod_user_id                NUMERIC(38),             -- ������ ���  
       @an_retrun_cal_mon             NUMERIC(38)      OUTPUT, -- ���ȱݾ�  
       @av_ret_code                   VARCHAR(4000)    OUTPUT, -- ����ڵ�*/  
       @av_ret_message                VARCHAR(4000)    OUTPUT  -- ����޽���*/  
    ) AS  
    -- ***************************************************************************  
    --   TITLE       : ������ �����ӱ��׸� ���  
    --   PROJECT     : HR�ý���  
    --   AUTHOR      :  �ڱ���  
    --   PROGRAM_ID  : P_REP_CAL_PAY_DETAIL  
    --   RETURN      : 1) SUCCESS!/FAILURE!  
    --                 2) ��� �޽���  
    --   COMMENT     : ������ �����ӱ��׸� ���  
    --   HISTORY     : ���� ������ 2012.03.26  
    --               : 2016.06.24 Modified by �ּ��� in KBpharma  
    -- ***************************************************************************  
BEGIN  
   SET NOCOUNT ON;
  
    /* �⺻������ ���Ǵ� ���� */  
    DECLARE @v_program_id              VARCHAR(30)  
          , @v_program_nm              VARCHAR(100)  
          , @ERRCODE                   VARCHAR(10)  
  
    DECLARE @n_emp_id                  NUMERIC(38)		-- ���ID
          , @v_pay_item_cd             VARCHAR(10)		-- ����ӱݴ���׸� 
          , @d_retire_ymd              DATE				-- ������
          , @n_cal_mon                 NUMERIC(38)		-- ���޳��� 
		  , @v_exec_yn				   NVARCHAR(1)		-- �ӿ�����
  
    /* �⺻���� �ʱⰪ ����*/  
    SET @v_program_id    = 'P_REP_CAL_PAY_STD'   -- ���� ���ν����� ������  
    SET @v_program_nm    = '������ �����ӱݰ���/�ӱ��׸����'        -- ���� ���ν����� �ѱ۹���  
    SET @av_ret_code     = 'SUCCESS!'  
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null,  @an_mod_user_id)  
	--PRINT 'P_REP_CAL_PAY_STD'
	--print @av_pay_ym + ':' + @av_pay_type_cd + ':' + convert(varchar(10), @an_base_day) + ':' + convert(varchar(10), @an_real_day)
	--       + ':' + @av_flag
    BEGIN  
        -- ***************************************  
        -- 1. ������ �����(����) ��ȸ  
        -- *************************************** 
		SET @v_exec_yn = 'N'
        BEGIN  
            SELECT @n_emp_id     = EMP_ID  
                 , @d_retire_ymd = C1_END_YMD  
				 , @v_exec_yn    = ISNULL(OFFICERS_YN, 'N')
              FROM REP_CALC_LIST  
             WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id  
        END  
        -- ***************************************  
        -- 2. �����׸� ���� ��ȸ  
        -- ***************************************  
        SET @an_retrun_cal_mon = 0 
		-- ***************************************  
		-- 3. ���� �����׸� ����  
		-- ***************************************  
		BEGIN  
			DELETE FROM REP_PAYROLL_DETAIL  
				WHERE REP_PAY_STD_ID = @an_rep_pay_std_id  
			IF @ERRCODE != 0  
				BEGIN  
					SET @av_ret_code    = 'FAILURE!'  
					SET @av_ret_message = dbo.F_FRM_ERRMSG('�����׸� ������ �����߻�[ERR]', @v_program_id, 0010, null, @an_mod_user_id) 
					RETURN  
				END  
		END 

        BEGIN          
			INSERT INTO REP_PAYROLL_DETAIL                 -- �����ݱ����ӱ��׸����  
						( REP_PAYROLL_DETAIL_ID              -- �����ݱ����ӱ��׸����ID  
						, REP_PAY_STD_ID                     -- �����ݱ��� �ӱ� ����ID  
						, PAY_ITEM_CD                        -- �޿��׸��ڵ�[PAY_ITEM_CD]  
						, CAL_MON                            -- �ݾ�  
						, MOD_USER_ID                        -- ������  
						, MOD_DATE                           -- �����Ͻ�  
						, TZ_CD                              -- Ÿ�����ڵ�  
						, TZ_DATE )                          -- Ÿ�����Ͻ�  
					SELECT NEXT VALUE FOR dbo.S_REP_SEQUENCE  -- �����ݱ����ӱ��׸����ID  
						, @an_rep_pay_std_id                 -- �����ݱ��� �ӱ� ����ID  
						, A.PAY_ITEM_CD --@v_pay_item_cd                     -- �޿��׸��ڵ�[PAY_ITEM_CD]  
						, A.CAL_MON --@n_cal_mon                         -- �ݾ�  
						, @an_mod_user_id                    -- ������  
						, dbo.XF_SYSDATE(0)                  -- �����Ͻ�  
						, 'KST'                              -- Ÿ�����ڵ�  
						, dbo.XF_SYSDATE(0)                  -- Ÿ�����Ͻ�  
					FROM (
						SELECT B.PAY_ITEM_CD
								, CASE WHEN @av_flag = 'Y' THEN dbo.XF_ROUND((CAST(SUM(dbo.XF_NVL_N(CAL_MON,0)) AS FLOAT) * (CAST(@an_real_day AS FLOAT) / @an_base_day)), -1)  
												ELSE SUM(dbo.XF_NVL_N(CAL_MON,0))                        
								END  as CAL_MON
						FROM PAY_PAYROLL A
							INNER JOIN PAY_PAY_YMD C 
								ON A.PAY_YMD_ID = C.PAY_YMD_ID
							INNER JOIN PAY_PAYROLL_DETAIL B
								ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
							INNER JOIN (
								SELECT PAY_TYPE_CD, PAY_ITEM_CD
									FROM (
											SELECT CD PAY_TYPE_CD, SYS_CD
												FROM FRM_CODE
												WHERE COMPANY_CD = @av_company_cd
												AND CD_KIND = 'PAY_TYPE_CD'
												AND SYS_CD != '100' -- �ùķ��̼�����
											) A
									INNER JOIN (
												SELECT KEY_CD2 PAY_ITEM_SYS_CD, KEY_CD3 AS PAY_ITEM_CD  
													FROM FRM_UNIT_STD_HIS  
													WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																				FROM FRM_UNIT_STD_MGR  
																				WHERE COMPANY_CD = @av_company_cd  
																					AND UNIT_CD = 'REP'  
											  										AND STD_KIND = CASE WHEN @v_exec_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
													AND @d_retire_ymd BETWEEN STA_YMD AND END_YMD  
													AND KEY_CD1 = @av_pay_type_cd  
										) B
										ON (A.SYS_CD = B.PAY_ITEM_SYS_CD OR B.PAY_ITEM_SYS_CD IS NULL)
									) T1
								ON C.PAY_TYPE_CD = T1.PAY_TYPE_CD
								AND B.PAY_ITEM_CD = T1.PAY_ITEM_CD
							WHERE C.CLOSE_YN = 'Y'
							AND C.PAY_YN = 'Y'
							AND B.BEL_PAY_YM = @av_pay_ym  
							AND A.SUB_COMPANY_CD = @av_company_cd 
							AND A.EMP_ID = @n_emp_id
							GROUP BY B.PAY_ITEM_CD
							) A
						WHERE CAL_MON <> 0
			SELECT @ERRCODE = @@ERROR  
			IF @ERRCODE != 0  
				BEGIN  
					SET @av_ret_code      = 'FAILURE!'  
					SET @av_ret_message   = dbo.F_FRM_ERRMSG('�޿� �����ӱ��׸� ����� ����[ERR]', @v_program_id, 0020, null, @an_mod_user_id)  
					CLOSE item      -- Ŀ���ݱ�  
					DEALLOCATE item -- Ŀ�� �Ҵ�����  
					RETURN  
				END 
  
			SELECT @an_retrun_cal_mon = SUM(CAL_MON) FROM REP_PAYROLL_DETAIL WHERE REP_PAY_STD_ID = @an_rep_pay_std_id
  
		END --  

    END -- 
    -- ***********************************************************  
    -- �۾� �Ϸ�  
    -- ***********************************************************  
    SET @av_ret_code    = 'SUCCESS!'  
    SET @av_ret_message = dbo.F_FRM_ERRMSG('�����ӱ��׸� ������ �Ϸ�Ǿ����ϴ�[ERR]', @v_program_id, 9999, null, @an_mod_user_id)  
END
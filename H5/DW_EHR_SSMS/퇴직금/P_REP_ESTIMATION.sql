SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_REP_ESTIMATION]
    @av_company_cd     NVARCHAR(10),			-- ȸ���ڵ�
    @av_locale_cd      NVARCHAR(10),			-- �����ڵ�
    @av_calc_type_cd   NVARCHAR(10),			-- ���걸�� ('03' : �����߰�)
	@ad_std_ymd        DATE,					-- ��������
	@ad_calc_sta_ymd   DATE,					-- �����Ⱓ ������
	@ad_calc_end_ymd   DATE,					-- �����Ⱓ ������
	@ad_res_yn		   NVARCHAR(10),			-- ���⵵ ���������Կ���
	@an_pay_group_id   NUMERIC(38),				-- �޿��׷�
	@an_org_id         NUMERIC(38),				-- �Ҽ�ID
    @an_emp_id         NUMERIC(38),				-- ���ID
    @an_mod_user_id    NUMERIC(38),				-- ������
    @av_ret_code       NVARCHAR(50)  OUTPUT,	-- SUCCESS!/FAILURE!
    @av_ret_message    NVARCHAR(2000) OUTPUT    -- ����޽���
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
 
           @n_emp_id              NUMERIC(38),		-- ���ID
           @d_sta_ymd             DATE,		        --  ������(��)����� - �Ի���(������)
           @d_end_ymd             DATE,		        -- ��(��)������ - ������
		   @n_rep_calc_list_id    NUMERIC(38),		-- ��������ID
           @d_retire_ymd          DATETIME2,		-- ������
           @n_retire_turn_mon     NUMERIC(15),		-- ���ο���������ȯ��
		   @v_emp_cls_cd		  NVARCHAR(50),		-- ��������ڵ�[PAY_EMP_CLS_CD]
		   @v_mgr_type_cd		  NVARCHAR(50),		-- �������� [PHM_MGR_TYPE_CD]
		   @v_officers_yn		  NVARCHAR(1),		-- �ӿ�����
		   @v_rep_mid_yn		  NVARCHAR(1),		-- �߰����꿩��
		   @v_ins_type_cd		  NVARCHAR(10),		-- �������ݱ���
		   @v_ins_type_yn		  NVARCHAR(1),		-- �������ݰ��Կ���
		   @v_calc_type_cd		 NVARCHAR(50)		-- ���걸��[CALC_TYPE_CD]

		   ,@v_pay_group_cd			nvarchar(10)


   SET @v_program_id = '[P_REP_ESTIMATION]';
   SET @v_program_nm = '�����߰�׽���';

   SET @av_ret_code     = 'SUCCESS!'
   SET @av_ret_message  = dbo.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null,  @an_mod_user_id)

   SET @d_mod_date = dbo.xf_sysdate(0)
   select @v_pay_group_cd = PAY_GROUP
     from PAY_GROUP
	where PAY_GROUP_ID = @an_pay_group_id
PRINT('CHECK ===> 1 ')
   -- *************************************************************
   -- �߰�� ����� ����
   -- *************************************************************
   BEGIN
        DECLARE REP_CUR CURSOR LOCAL FORWARD_ONLY FOR
		    SELECT *
			  FROM (
					SELECT EMP_ID								-- ���ID
						 , C1_STA_YMD							-- �Ի���(������)
						 , C1_END_YMD							-- ��(��)������  
						 , REP_CALC_LIST_ID						-- ����� ������ID     
						 , RETIRE_TURN							-- ���ο���������ȯ��
						 , EMP_CLS_CD							-- �������[PAY_EMP_CLS_CD]
						 , MGR_TYPE_CD							-- ���������ڵ�[PHM_MGR_TYPE_CD]
						 , ISNULL(OFFICERS_YN, 'N')	AS OFFICERS_YN			-- �ӿ�����
						 , REP_MID_YN							-- �߰��������Կ���
						 , INS_TYPE_CD							-- �������ݱ���
						 , INS_TYPE_YN							-- �������ݰ��Կ���
						 , CALC_TYPE_CD							-- ���걸��[CALC_TYPE_CD]
					--	 , dbo.F_PAY_GROUP_CHK(@an_pay_group_id, EMP_ID, @ad_std_ymd) AS PAY_GROUP_ID
					  FROM REP_CALC_LIST      
					 WHERE COMPANY_CD = @av_company_cd
					   AND CALC_TYPE_CD = @av_calc_type_cd
					   AND PAY_YMD = @ad_std_ymd
					   AND PAY_GROUP = @v_pay_group_cd
					  -- AND (@an_pay_group_id is NULL OR
							--dbo.F_PAY_GROUP_CHK(@an_pay_group_id, EMP_ID, @ad_std_ymd) = @an_pay_group_id) -- �޿��׷�Ȯ��
					   AND (@an_org_id IS NULL OR ORG_ID = @an_org_id)                                     -- �Է��� �ҼӰ� �ִٸ� �Է��� �Ҽ� �ƴϸ� ��ü
					   AND (@an_emp_id IS NULL OR EMP_ID = @an_emp_id)                                     -- �Է��� ����� �ִٸ� �Է��� ��� �ƴϸ� ��ü
					   ) A
				 --WHERE PAY_GROUP_ID = @an_pay_group_id
        OPEN REP_CUR

        FETCH REP_CUR INTO @n_emp_id , @d_sta_ymd, @d_end_ymd , @n_rep_calc_list_id , @n_retire_turn_mon ,
			                @v_emp_cls_cd , @v_mgr_type_cd , @v_officers_yn , @v_rep_mid_yn , @v_ins_type_cd ,
							@v_ins_type_yn, @v_calc_type_cd
        WHILE (@@FETCH_STATUS = 0)
		BEGIN

PRINT('�����ڷ� ���� ===> 1 ' + FORMAT(SYSDATETIME(), 'HH:mm:ss.fffff'))
PRINT('@v_ins_type_cd ===> ' + @v_ins_type_cd)
PRINT('@v_calc_type_cd ===> ' + @v_calc_type_cd)
PRINT CASE WHEN @v_ins_type_cd='20' then 'P_REP_CAL_PAY_STD_DC_03' else 'P_REP_CAL_PAY_STD_03' end
			-- ***************************************   
			-- 1. �����ڷ� Ȯ�� �� ����    
			-- *************************************** 
		
            BEGIN 
				IF @v_ins_type_cd = '20' -- DC��
				   BEGIN
				      EXEC dbo.P_REP_CAL_PAY_STD_DC_03 @av_company_cd, @av_locale_cd, @n_rep_calc_list_id, @ad_calc_sta_ymd, @ad_calc_end_ymd, @ad_res_yn, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT   
						IF @av_ret_code = 'FAILURE!'   
							BEGIN   
								SET @av_ret_code     = 'FAILURE!'   
								SET @av_ret_message  = @av_ret_message   
								RETURN   
							END
				   END
				ELSE
				   BEGIN   
					  EXEC dbo.P_REP_CAL_PAY_STD_03 @av_company_cd, @av_locale_cd, @n_rep_calc_list_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT   
					  IF @av_ret_code = 'FAILURE!'   
							BEGIN   
								SET @av_ret_code     = 'FAILURE!'   
								SET @av_ret_message  = @av_ret_message   
								RETURN   
							END   
				  END 
            END 

PRINT('����ӱ� ���� ===> 2 ' + FORMAT(SYSDATETIME(), 'HH:mm:ss.fffff'))
PRINT('@v_ins_type_cd ===> ' + @v_ins_type_cd)	
			---- ***************************************   
			---- 2. ����ӱ� ����   
			---- ***************************************  
            BEGIN 
				IF @v_ins_type_cd = '20' -- DC��
					BEGIN   
						EXEC dbo.P_REP_CAL_AVG_AMT_DC_03 @av_company_cd, @av_locale_cd, @n_rep_calc_list_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT   
						IF @av_ret_code = 'FAILURE!'   
							BEGIN   
								SET @av_ret_code     = 'FAILURE!'   
								SET @av_ret_message  = @av_ret_message   
								RETURN   
							END   
					END 
				ELSE
					BEGIN   
						EXEC dbo.P_REP_CAL_AVG_AMT_03 @av_company_cd, @av_locale_cd, @n_rep_calc_list_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT   
						IF @av_ret_code = 'FAILURE!'   
							BEGIN   
								SET @av_ret_code     = 'FAILURE!'   
								SET @av_ret_message  = @av_ret_message   
								RETURN   
							END   
					END 
            END 

PRINT('����ӱ� ���� ===> 3 ' + FORMAT(SYSDATETIME(), 'HH:mm:ss.fffff'))

            FETCH REP_CUR INTO @n_emp_id , @d_sta_ymd, @d_end_ymd , @n_rep_calc_list_id , @n_retire_turn_mon ,
			                   @v_emp_cls_cd , @v_mgr_type_cd , @v_officers_yn , @v_rep_mid_yn , @v_ins_type_cd ,
							   @v_ins_type_yn, @v_calc_type_cd
		END
        CLOSE REP_CUR
        DEALLOCATE REP_CUR      

   END

   /*
   *    ***********************************************************
   *    �۾� �Ϸ�
   *    ***********************************************************
   */
   SET @av_ret_code = 'SUCCESS!'
   SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� �Ϸ�..[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)


END

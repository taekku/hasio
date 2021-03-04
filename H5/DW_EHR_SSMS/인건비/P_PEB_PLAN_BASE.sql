SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[P_PEB_PLAN_BASE]
	@av_company_cd      nVARCHAR,       -- �λ翵��
    @av_locale_cd       nVARCHAR,       -- �����ڵ�
    @an_plan_id         numeric,         -- �ΰǺ����id
    @an_mod_user_id     numeric,         -- ������
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS

    -- ***************************************************************************
    --   TITLE       : �ΰǺ��ȹ���رݾ׻���
    ---  PROJECT     : ���λ������ý���
    --   AUTHOR      : ����ȭ
    --   PROGRAM_ID  : P_PEB_PLAN_BASE
    --   ARGUMENT    :
    --   RETURN      :
    --   HISTORY     :
    -- ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)


	  /* CURSOR C1 ���� */
	  , @EMP_ID NUMERIC
	  , @PLAN_TYPE_01 nVARCHAR(150)
	  , @PLAN_TYPE_02 nVARCHAR(150)
	  , @PLAN_TYPE_03 nVARCHAR(150)
	  , @BASE_SALARY NUMERIC(10,0)
	  , @BP03		NVARCHAR(20)
	  , @BP04		NVARCHAR(20)
	  , @BP05		NVARCHAR(20)
	  , @BP06		NVARCHAR(20)
	  , @BP07		NVARCHAR(20)
	  , @BP08		NVARCHAR(20)
	  , @PAY_POS_GRD_CD		NVARCHAR(10)
	  , @SALARY_TYPE_CD		NVARCHAR(10)
	  , @POS_GRD_CD		NVARCHAR(10)
	  , @ORG_ID		NUMERIC
	  , @LOCALE_CD	NVARCHAR(50)
	  , @COMPANY_CD	NVARCHAR(10)
	  , @YMD	DATE
	  , @WORK_MM  NUMERIC
	  , @LOCATION_CD NVARCHAR(50)
	  , @BP45 NVARCHAR
	  , @PAY_JOP_CD NVARCHAR
	  , @BP46 NVARCHAR

	  , @n_work_mm                numeric  -- �ٹ�������
	  , @n_yy_amt                 numeric  -- �����޿�
	  , @n_pay_amt                numeric  -- ���޿�
	  , @n_bonus_amt              numeric  -- �󿩱�
	  , @n_retire_amt             numeric  -- ������
	  , @n_change_amt             numeric  -- ������

	  , @n_b_pay_amt              numeric  -- ���ؿ��޿�
	  , @n_b_bonus_amt            numeric  -- ���ػ󿩱�
	  , @n_b_retire_amt           numeric  -- ����������
	  , @n_b_stp_amt              numeric  -- ���ر��ο���
	  , @n_b_nhs_amt              numeric  -- ���ذǰ�����
	  , @n_b_emi_amt              numeric  -- ���ذ�뺸��
	  , @n_b_iai_amt              numeric  -- ���ػ��纸��
	  , @n_b_change_amt           numeric  -- ���غ�����
	  , @n_bonus_rate             numeric  -- ����

	  , @n_bp08                   numeric  -- ��������
	  , @n_bp09                   numeric  -- �ڰݼ���
	  , @n_bp10                   numeric  -- ��������

	  , @d_base_ymd               DATE  -- ������
	  , @d_sta_ymd                DATE  -- ������
      
		      

    BEGIN
        SET @v_program_id   = 'P_PEB_PLAN_BASE'
        SET @v_program_nm   = '�ΰǺ��ȹ���رݾ׻���'
        SET @av_ret_code    = 'SUCCESS!'
        SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                         @v_program_id,  0000,  NULL, NULL);
    END


	
	BEGIN
		-- �����ڷ����
		BEGIN
			DELETE FROM PEB_BASE_AMT WHERE PEB_BASE_ID = @an_plan_id

			IF @@ERROR <> 0 
				BEGIN 
					SET @av_ret_code    = 'FAILURE!'  
					SET @av_ret_message = dbo.F_FRM_ERRMSG('�ΰǺ� ���رݾװ��� DELETE�� �����߻�[err]', 
														@v_program_id, 0030 , ERROR_MESSAGE() , 1 
													)   
					RETURN  
				END 
		END


		--������ ��ȸ
		BEGIN
			SELECT @d_base_ymd = dbo.XF_TRUNC_D(STD_YMD)
			     , @d_sta_ymd = dbo.XF_TO_DATE(dbo.XF_TO_CHAR_D(STD_YMD,'YYYY')+'0301','YYYYMMDD')
			FROM PEB_BASE
			WHERE PEB_BASE_ID = @an_plan_id


			IF @@ROWCOUNT = 0 
				BEGIN 
					SET @av_ret_code    = 'FAILURE!'  
					SET @av_ret_message = dbo.F_FRM_ERRMSG('�ΰǺ� ���ذ����� �������� �ʽ��ϴ�. Ȯ���Ͻð� �����ϼ���.', 
														@v_program_id, 0030 , ERROR_MESSAGE() , 1 
													)   
					RETURN  
				END 
			IF @@ERROR <> 0 
				BEGIN 
					SET @av_ret_code    = 'FAILURE!'  
					SET @av_ret_message = dbo.F_FRM_ERRMSG('�ΰǺ� ���ذ��� ��ȸ�� �����߻�.', 
														@v_program_id, 0030 , ERROR_MESSAGE() , 1 
													)   
					RETURN  
				END 
		END

		

		DECLARE C1 CURSOR LOCAL FOR(
			SELECT A.EMP_ID,
                         (SELECT MGR.KEY_CD1
                            FROM VI_FRM_UNIT_STD_HIS MGR
                           WHERE MGR.UNIT_CD = 'ORM'
                             AND MGR.STD_KIND = 'ORM_ORG_PALN_TYPE_01'
                             AND A.YMD BETWEEN MGR.STA_YMD AND MGR.END_YMD
                             AND B.PAY_POS_GRD_CD LIKE KEY_CD2
                             AND MGR.COMPANY_CD = C.COMPANY_CD
                             AND MGR.LOCALE_CD  = C.LOCALE_CD
                             AND MGR.KEY_CD3 = (SELECT MIN(KEY_CD3)
                                                  FROM VI_FRM_UNIT_STD_HIS
                                                 WHERE UNIT_CD = 'ORM'
                                                   AND STD_KIND = 'ORM_ORG_PALN_TYPE_01'
                                                   AND A.YMD BETWEEN STA_YMD AND END_YMD
                                                   AND B.PAY_POS_GRD_CD LIKE KEY_CD2
                                                   AND COMPANY_CD = C.COMPANY_CD
                                                   AND LOCALE_CD  = C.LOCALE_CD)) PLAN_TYPE_01,
                         (SELECT MGR.KEY_CD1
                            FROM CAM_TERM_MGR CAM,
                                 VI_FRM_UNIT_STD_HIS MGR
                               WHERE MGR.UNIT_CD = 'ORM'
                                 AND MGR.STD_KIND = 'ORM_ORG_PALN_TYPE_02'
                                 AND MGR.KEY_CD2 = CAM.ITEM_NM
                                 AND CAM.EMP_ID = A.EMP_ID
                                 AND CAM.VALUE LIKE MGR.KEY_CD3
                                 AND MGR.COMPANY_CD = C.COMPANY_CD
                                 AND MGR.LOCALE_CD = C.LOCALE_CD
                                 AND A.YMD BETWEEN MGR.STA_YMD AND MGR.END_YMD
                                 AND A.YMD BETWEEN CAM.STA_YMD AND CAM.END_YMD
                                 AND MGR.KEY_CD4 = (SELECT MIN(KEY_CD4)
                                                      FROM VI_FRM_UNIT_STD_HIS W1,
                                                           CAM_TERM_MGR W2
                                                     WHERE W1.UNIT_CD  = 'ORM'
                                                       AND W1.STD_KIND = 'ORM_ORG_PALN_TYPE_02'
                                                       AND W2.EMP_ID = A.EMP_ID
                                                       AND W1.KEY_CD2 = W2.ITEM_NM
                                                       AND W2.VALUE LIKE W1.KEY_CD3
                                                       AND W1.COMPANY_CD = C.COMPANY_CD
                                                       AND W1.LOCALE_CD = C.LOCALE_CD
                                                       AND A.YMD BETWEEN W1.STA_YMD AND W1.END_YMD
                                                       AND A.YMD BETWEEN W2.STA_YMD AND W2.END_YMD))  PLAN_TYPE_02,
                         (SELECT MGR.KEY_CD1
                            FROM ORM_ORG ORG,
                                 VI_FRM_UNIT_STD_HIS MGR
                           WHERE MGR.UNIT_CD = 'ORM'
                             AND MGR.STD_KIND = 'ORM_ORG_PALN_TYPE_03'
                             AND ORG.ORG_ID = A.ORG_ID
                             AND A.YMD BETWEEN MGR.STA_YMD AND MGR.END_YMD
                             AND A.YMD BETWEEN ORG.STA_YMD AND ORG.END_YMD
                             AND ORG.PROPERTY_CD2   LIKE MGR.KEY_CD2
                             AND B.PAY_JOP_CD     LIKE MGR.KEY_CD3
                             AND B.PAY_POS_GRD_CD LIKE MGR.KEY_CD4
                             AND MGR.COMPANY_CD = C.COMPANY_CD
                             AND MGR.LOCALE_CD = C.LOCALE_CD
                             AND MGR.KEY_CD5 = (SELECT MIN(KEY_CD5)
                                                  FROM VI_FRM_UNIT_STD_HIS W1,
                                                       ORM_ORG W2
                                                 WHERE W1.COMPANY_CD  = C.COMPANY_CD
                                                   AND W1.LOCALE_CD = C.LOCALE_CD
                                                   AND W1.UNIT_CD = 'ORM'
                                                   AND W1.STD_KIND = 'ORM_ORG_PALN_TYPE_03'
                                                   AND W2.ORG_ID = A.ORG_ID
                                                   AND A.YMD BETWEEN W1.STA_YMD AND W1.END_YMD
                                                   AND A.YMD BETWEEN W2.STA_YMD AND W2.END_YMD
                                                   AND W2.PROPERTY_CD2 LIKE KEY_CD2
                                                   AND B.PAY_JOP_CD     LIKE KEY_CD3
                                                   AND B.PAY_POS_GRD_CD LIKE KEY_CD4)) PLAN_TYPE_03,
                         B.BASE_SALARY,   -- �⺻��
                         B.BP03,          -- �繫����
                         B.BP04,          -- �������
                         B.BP05,          -- �������
                         dbo.XF_TO_NUMBER(CASE WHEN B.SALARY_TYPE_CD = '001' THEN
                                                 CASE WHEN ISNULL(dbo.XF_TO_NUMBER(dbo.F_FRM_UNIT_STD_HIS(C.COMPANY_CD,C.LOCALE_CD,'PAY','PAY_BASE_TRAN_DUTY',A.DUTY_CD,NULL,NULL,NULL,NULL,A.YMD,'6')), 0) = 0 THEN
                                                           ISNULL(dbo.XF_TO_NUMBER(dbo.F_FRM_UNIT_STD_HIS(C.COMPANY_CD,C.LOCALE_CD,'PAY','PAY_BASE_TRAN',A.POS_GRD_CD,NULL,NULL,NULL,NULL,A.YMD,'6')), 0)
                                                 ELSE ISNULL(dbo.XF_TO_NUMBER(dbo.F_FRM_UNIT_STD_HIS(C.COMPANY_CD,C.LOCALE_CD,'PAY','PAY_BASE_TRAN_DUTY',A.DUTY_CD,NULL,NULL,NULL,NULL,A.YMD,'6')), 0) END
                                       ELSE '0' END)  BP06, -- �������
                         dbo.XF_TO_NUMBER(dbo.F_FRM_UNIT_STD_HIS(C.COMPANY_CD,C.LOCALE_CD,'PAY','PAY_BASE_DUTY',A.DUTY_CD,NULL,NULL,NULL,NULL,A.YMD,'6'))  BP07, -- ��å����
                         dbo.XF_TO_NUMBER(dbo.F_FRM_UNIT_STD_HIS(C.COMPANY_CD,C.LOCALE_CD,'PAY','PAY_BASE_CONTROL',A.CUST_COL1,NULL,NULL,NULL,NULL,A.YMD,'6')) BP08,  -- ��������
                         B.PAY_POS_GRD_CD, -- �޿�����
                         B.SALARY_TYPE_CD, -- �޿�����
                         A.POS_GRD_CD,
                         A.ORG_ID,
                         C.COMPANY_CD,
                         C.LOCALE_CD,
                         A.YMD,
                         dbo.XF_CEIL(dbo.XF_MONTHDIFF(dbo.XF_LAST_DAY(A.YMD)+1, CASE WHEN HIRE_YMD > @d_sta_ymd THEN HIRE_YMD ELSE @d_sta_ymd END),0) WORK_MM,
                         A.CUST_COL1  LOCATION_CD,
                         ISNULL(dbo.F_FRM_UNIT_STD_HIS(C.COMPANY_CD,'KO','PAY','PAY_OT_BASE',B.PAY_POS_GRD_CD,NULL,NULL,NULL,NULL,A.YMD,'6'), dbo.XF_ROUND(B.BASE_SALARY/226,0)) BP45,  -- ���ؽñ�
                         dbo.F_FRM_UNIT_STD_HIS(C.COMPANY_CD,'KO','PAY','PAY_JOP_GROUP',B.PAY_JOP_CD,NULL,NULL,NULL,NULL,A.YMD,'6') PAY_JOP_CD,  -- �޿� ����/���걸��
                         dbo.F_FRM_UNIT_STD_HIS(C.COMPANY_CD,'KO','PAY','PAY_OT_BASE',B.PAY_POS_GRD_CD,NULL,NULL,NULL,NULL,A.YMD,'7') BP46 -- �߰�������
                    FROM VI_EIS_CAM_HISTORY A,
                         CNM_CNT B,
                         VI_FRM_PHM_EMP C
                   WHERE A.EMP_ID = B.EMP_ID
                     AND A.EMP_ID = C.EMP_ID
                     AND C.COMPANY_CD = @av_company_cd
                     AND C.LOCALE_CD = @av_locale_cd
                     AND A.YMD = @d_base_ymd
                     AND A.YMD BETWEEN B.STA_YMD AND B.END_YMD
                 
		)

		OPEN C1

		FETCH NEXT FROM C1 INTO @EMP_ID
							  , @PLAN_TYPE_01 
							  , @PLAN_TYPE_02 
							  , @PLAN_TYPE_03 
							  , @BASE_SALARY 
							  , @BP03		
							  , @BP04		
							  , @BP05		
							  , @BP06		
							  , @BP07		
							  , @BP08		
							  , @PAY_POS_GRD_CD		
							  , @SALARY_TYPE_CD		
							  , @POS_GRD_CD		
							  , @ORG_ID		
							  , @LOCALE_CD	
							  , @COMPANY_CD	
							  , @YMD	
							  , @WORK_MM 
							  , @LOCATION_CD 
							  , @BP45 
							  , @PAY_JOP_CD 
							  , @BP46 


		WHILE(@@FETCH_STATUS = 0)

			BEGIN
				SET @n_bonus_rate      = 0
				SET  @n_pay_amt         = 0
				SET  @n_bonus_amt       = 0
				SET  @n_retire_amt      = 0  -- ������
				SET  @n_yy_amt          = 0
				SET  @n_b_pay_amt       = 0  -- ���ؿ��޿�
				SET  @n_b_bonus_amt     = 0  -- ���ػ󿩱�
				SET  @n_b_retire_amt    = 0  -- ����������
				SET  @n_b_stp_amt       = 0  -- ���ر��ο���
				SET  @n_b_nhs_amt       = 0  -- ���ذǰ�����
				SET  @n_b_emi_amt       = 0  -- ���ذ�뺸��
				SET  @n_b_iai_amt       = 0  -- ���ػ��纸��
				SET  @n_change_amt      = 0  -- ������
				SET  @n_b_change_amt    = 0  -- ���غ�����
				SET  @n_bp08            = 0  -- ��������
				SET  @n_bp09            = 0  -- �ڰݼ���
				SET  @n_bp10            = 0  -- ��������
				SET  @n_bp08 = @BP08

				BEGIN
					DECLARE @PAY_ITEM_CD NVARCHAR
					      , @C2_EMP_ID  NUMERIC
						  , @PROCESS_TYPE_CD NVARCHAR
						  , @CAL_MON  NUMERIC

					-- �޿����ܻ�����ȸ
					DECLARE C2 CURSOR LOCAL FOR(
						SELECT PAY_ITEM_CD,
                             EMP_ID,
                             PROCESS_TYPE_CD,
                             SUM(CAL_MON) CAL_MON
                        FROM PAY_EXCEPTION
                       WHERE @YMD BETWEEN dbo.XF_TO_DATE(STA_YM+'01','YYYYMMDD') AND dbo.XF_LAST_DAY(END_YM+'01')
                         AND PAY_ITEM_CD IN ( 'P10' , 'P11' , 'P12')
                         AND EMP_ID = @EMP_ID
                      GROUP BY PAY_ITEM_CD, EMP_ID, PROCESS_TYPE_CD
					)

					OPEN C2
					FETCH NEXT FROM C2 INTO @PAY_ITEM_CD, @C2_EMP_ID, @PROCESS_TYPE_CD, @CAL_MON 

					WHILE(@@FETCH_STATUS = 0)
						BEGIN
							IF @PAY_ITEM_CD = 'P12'  -- ��������
								BEGIN
									IF @PROCESS_TYPE_CD = '001'
										BEGIN
											SET @n_bp08 = @CAL_MON
										END
									ELSE
										BEGIN
											SET @n_bp08 = @n_bp08 + ISNULL(@CAL_MON, 0)
										END
								END
							ELSE IF @PAY_ITEM_CD = 'P10'   -- �ڰݼ���
								BEGIN
									SET @n_bp09 = ISNULL(@CAL_MON, 0)
								END
							ELSE IF @PAY_ITEM_CD = 'P11'    -- ��������
								BEGIN
									SET @n_bp10 = ISNULL(@CAL_MON, 0)
								END
							
							FETCH NEXT FROM C2 INTO @PAY_ITEM_CD, @C2_EMP_ID, @PROCESS_TYPE_CD, @CAL_MON 
						END

					CLOSE C2
					DEALLOCATE C2

					-- ����
					SET @n_bonus_rate = ISNULL(dbo.XF_TO_NUMBER(dbo.F_FRM_UNIT_STD_HIS(@COMPANY_CD,@LOCALE_CD,'PAY','PAY_BONUS_RATE',@SALARY_TYPE_CD,NULL,NULL,NULL,NULL,@YMD,'6')),0)
					
					-- ���޿�
					SET @n_pay_amt = ISNULL(@BASE_SALARY,0) + ISNULL(@BP03,0) + ISNULL(@BP04,0) + ISNULL(@BP05,0) + ISNULL(@BP06,0) + ISNULL(@BP07,0) + ISNULL(@n_bp08,0) + ISNULL(@n_bp09,0) + ISNULL(@n_bp10,0)

					-- �����޿�
					SET @n_yy_amt = @n_pay_amt*12

					-- �󿩱�
					SET @n_bonus_amt = dbo.XF_TRUNC_N(ISNULL(@BASE_SALARY,0)*@n_bonus_rate/100,0)

					-- ������
					SET @n_retire_amt = dbo.XF_TRUNC_N((@n_yy_amt + @n_bonus_amt)/12,0)

					-- ���ر޿�
					SET @n_b_pay_amt = dbo.XF_TRUNC_N(@n_yy_amt/365*30,0)

					-- ���ػ�
					SET @n_b_bonus_amt = dbo.XF_TRUNC_N(@n_bonus_amt/365*30,0)

					-- ����������
					SET @n_b_retire_amt = dbo.XF_TRUNC_N(@n_retire_amt/365*30,0)

					-- �ǰ�����
					BEGIN
						SELECT @n_b_nhs_amt = dbo.XF_NVL_N( INFO.INSU_AMT, 0 ) + dbo.XF_NVL_N( INFO.LONG_INSU_AMT, 0 )
						 FROM NHS_JOIN_INFO INFO
						WHERE @YMD BETWEEN INFO.STA_YMD AND INFO.END_YMD
						  AND INFO.REPORT_TYPE <> '02'
						  AND INFO.EMP_ID = @EMP_ID
						  AND INFO.EMP_ID NOT IN (SELECT EMP_ID
													FROM NHS_EXCEPTION
												   WHERE @YMD BETWEEN STA_YMD AND END_YMD)
						
						IF @@ROWCOUNT = 0 
							BEGIN 
								SET @n_b_nhs_amt = 0
							END 
						IF @@ERROR <> 0 
							BEGIN 
								SET @n_b_nhs_amt = 0
							END
					END

					-- ���ο���
					BEGIN
						SELECT @n_b_stp_amt = dbo.XF_NVL_N( INFO.INSU_AMT, 0 )
						 FROM STP_JOIN_INFO INFO
						WHERE @YMD BETWEEN INFO.STA_YMD AND INFO.END_YMD
						  AND INFO.REPORT_TYPE <> '02'
						  AND INFO.EMP_ID = @EMP_ID
						  AND INFO.EMP_ID NOT IN (SELECT EMP_ID
													FROM STP_EXCEPTION
												   WHERE @YMD BETWEEN STA_YMD AND END_YMD)
						IF @@ROWCOUNT = 0 
							BEGIN 
								SET @n_b_nhs_amt = 0
							END 
						IF @@ERROR <> 0 
							BEGIN 
								SET @n_b_nhs_amt = 0
							END
					END

					--��뺸��
					SET @n_b_emi_amt = dbo.XF_TRUNC_N((@n_b_pay_amt+@n_b_bonus_amt)*ISNULL(dbo.F_EMI_STAND_RATE(dbo.XF_TO_CHAR_D(@YMD,'YYYY'), @COMPANY_CD,@YMD,'01'),0)/100*2,0)

					-- ���纸��
					SET @n_b_iai_amt = dbo.XF_TRUNC_N((@n_b_pay_amt+@n_b_bonus_amt)*ISNULL(dbo.F_IAI_STAND_RATE(@LOCATION_CD, @COMPANY_CD,@YMD,'01'),0)/1000,0)

					-- ��뺸�� �̰�������ȸ
					BEGIN
						SELECT @n_b_emi_amt = 0, @n_b_iai_amt = 0
							FROM EMI_EXCEPTION
						   WHERE INSURE_TYPE_CD = '01'
							 AND EMP_ID = @EMP_ID
							 AND @YMD BETWEEN STA_YMD AND END_YMD
						
						IF @@ROWCOUNT = 0 
							BEGIN 
								SET @n_b_emi_amt = @n_b_emi_amt
								SET @n_b_iai_amt = @n_b_iai_amt
							END 
						IF @@ERROR <> 0 
							BEGIN 
								SET @n_b_emi_amt = @n_b_emi_amt
								SET @n_b_iai_amt = @n_b_iai_amt
							END
					END

					-- ������
					BEGIN
					   SELECT @n_change_amt =  SUM(CAL_MON)
						 FROM VI_PAY_PAYROLL_DETAIL_ALL
						WHERE PAY_YM BETWEEN dbo.XF_TO_CHAR_D(@d_sta_ymd,'YYYYMM') AND dbo.XF_TO_CHAR_D(@YMD,'YYYYMM')
						  AND EMP_ID = @EMP_ID
						  AND PAY_ITEM_CD IN (SELECT MGR.KEY_CD1
												FROM VI_FRM_UNIT_STD_HIS MGR
											   WHERE MGR.UNIT_CD = 'PEB'
												 AND MGR.STD_KIND = 'PEB_CHANGE_AMT'
												 AND @YMD BETWEEN MGR.STA_YMD AND MGR.END_YMD
												 AND MGR.COMPANY_CD = @COMPANY_CD
												 AND MGR.LOCALE_CD  = @LOCALE_CD)
						IF @@ROWCOUNT = 0 
							BEGIN 
								SET @n_change_amt = 0
							END 
						IF @@ERROR <> 0 
							BEGIN 
								SET @n_change_amt = 0
							END
					END

					-- ���غ�����
					SET @n_b_change_amt = dbo.XF_TRUNC_N(@n_change_amt/@WORK_MM,0)

					-- ���رݾ� ����
					BEGIN
						INSERT INTO PEB_BASE_AMT(PEB_BASE_AMT_ID ,  -- �ΰǺ���رݾ�ID
												PEB_BASE_ID     ,  -- �ΰǺ��ȹ����ID
												EMP_ID          ,  -- ���ID
												PAY_POS_GRD_CD  ,  -- �޿�����
												POS_GRD_CD      ,  -- ����
												SALARY_TYPE_CD  ,  -- �޿������ڵ�
												B_ORG_ID        ,  -- ����
												G_ORG_ID        ,  -- �׷�
												ORG_ID          ,  -- �Ҽ�
												WORK_MM         ,  -- �ٹ�������
												TYPE_01_CD      ,  -- �����ڵ�1
												TYPE_02_CD      ,  -- �����ڵ�2
												TYPE_03_CD      ,  -- �����ڵ�3
												TYPE_04_CD      ,  -- �����ڵ�4
												CNT_SALARY      ,  -- �����޿�
												PAY_AMT         ,  -- ���޿�
												BONUS_AMT       ,  -- ��
												RETIRE_AMT      ,  -- ������
												B_PAY_AMT       ,  -- ���ر޿�
												B_BONUS_AMT     ,  -- ���ػ�
												B_RETIRE_AMT    ,  -- ����������
												B_STP_AMT       ,  -- ���ر��ο���
												B_NHS_AMT       ,  -- ���ذǰ�����
												B_EMI_AMT       ,  -- ���ذ�뺸��
												B_IAI_AMT       ,  -- ���ػ��纸��
												CHANGE_AMT      ,  -- ������
												B_CHANGE_AMT    ,  -- ���غ�����
												B_TIME_AMT      ,  -- ���ؽñ�
												ETC_CD1         ,  -- ��Ÿ1
												ETC_CD2         ,  -- ��Ÿ2
												NOTE            ,  -- ���
												MOD_USER_ID     ,  -- ������
												MOD_DATE        ,  -- �����Ͻ�
												TZ_CD           ,  -- Ÿ�����ڵ�
												TZ_DATE            -- Ÿ�����Ͻ�
												)
										VALUES (NEXT VALUE FOR S_PEB_SEQUENCE ,  -- �ΰǺ���رݾ�ID
												@an_plan_id        ,  -- �ΰǺ��ȹ����ID
												@EMP_ID         ,  -- ���ID
												@PAY_POS_GRD_CD ,  -- �޿�����
												@POS_GRD_CD     ,  -- ����
												@SALARY_TYPE_CD ,  -- �޿������ڵ�
												NULL              ,  -- ����
												NULL              ,  -- �׷�
												@ORG_ID         ,  -- �Ҽ�
												@WORK_MM        ,  -- �ٹ�������
												@PLAN_TYPE_01   ,  -- �����ڵ�1
												@PLAN_TYPE_02   ,  -- �����ڵ�2
												@PLAN_TYPE_03   ,  -- �����ڵ�3
												@PAY_JOP_CD     ,  -- �����ڵ�4
												@n_yy_amt          ,  -- �����޿�
												@n_pay_amt         ,  -- ���޿�
												@n_bonus_amt       ,  -- ��
												@n_retire_amt      ,  -- ������
												@n_b_pay_amt       ,  -- ���ر޿�
												@n_b_bonus_amt     ,  -- ���ػ�
												@n_b_retire_amt    ,  -- ����������
												@n_b_stp_amt       ,  -- ���ر��ο���
												@n_b_nhs_amt       ,  -- ���ذǰ�����
												@n_b_emi_amt       ,  -- ���ذ�뺸��
												@n_b_iai_amt       ,  -- ���ػ��纸��
												@n_change_amt      ,  -- ������
												@n_b_change_amt    ,  -- ���غ�����
												@BP45           ,  -- ���ؽñ�
												@BP46           ,  -- �߰�������
												NULL              ,  -- ��Ÿ2
												NULL              ,  -- ���
												@an_mod_user_id    ,  -- ������
												DBO.XF_SYSDATE(0)     ,  -- �����Ͻ�
												'KST'             ,  -- Ÿ�����ڵ�
												DBO.XF_SYSDATE(0)        -- Ÿ�����Ͻ�
											   )
						IF @@ERROR <> 0 
							BEGIN 
								SET @av_ret_code    = 'FAILURE!'  
								SET @av_ret_message = dbo.F_FRM_ERRMSG('�ΰǺ� ���رݾװ��� INSERT�� �����߻�.', 
																	@v_program_id, 0030 , ERROR_MESSAGE() , 1 
																)   
								RETURN  
							END 
					END
					
				END
				FETCH NEXT FROM C1 INTO @EMP_ID
									  , @PLAN_TYPE_01 
									  , @PLAN_TYPE_02 
									  , @PLAN_TYPE_03 
									  , @BASE_SALARY 
									  , @BP03		
									  , @BP04		
									  , @BP05		
									  , @BP06		
									  , @BP07		
									  , @BP08		
									  , @PAY_POS_GRD_CD		
									  , @SALARY_TYPE_CD		
									  , @POS_GRD_CD		
									  , @ORG_ID		
									  , @LOCALE_CD	
									  , @COMPANY_CD	
									  , @YMD	
									  , @WORK_MM 
									  , @LOCATION_CD 
									  , @BP45 
									  , @PAY_JOP_CD 
									  , @BP46 
			END
		CLOSE C1
		DEALLOCATE C1
	END

    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END
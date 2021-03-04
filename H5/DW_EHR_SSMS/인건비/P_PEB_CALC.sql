SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_PEB_CALC]
	@av_company_cd      NVARCHAR,       -- �λ翵��
    @av_locale_cd       NVARCHAR,       -- �����ڵ�
    @an_plan_id         NUMERIC,         -- �ΰǺ����id
    @av_type_cd         NVARCHAR,       -- �ΰǺ񱸺�
    @an_mod_user_id     NUMERIC,         -- ������
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    -- ***************************************************************************
    --   TITLE       : �ΰǺ��ȹ����
    ---  PROJECT     : ���λ������ý���
    --   AUTHOR      : ����ȭ
    --   PROGRAM_ID  : P_PEB_CALC
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

	  , @n_base_amt      NUMERIC  -- ���رݾ�
      , @n_emp_cnt       NUMERIC  -- �����ο�

	DECLARE 
		@t_peb_plan$AMT01	NUMERIC(15,0),
		@t_peb_plan$AMT02	NUMERIC(15,0),
		@t_peb_plan$AMT03	NUMERIC(15,0),
		@t_peb_plan$AMT04	NUMERIC(15,0),
		@t_peb_plan$AMT05	NUMERIC(15,0),
		@t_peb_plan$AMT06	NUMERIC(15,0),
		@t_peb_plan$AMT07	NUMERIC(15,0),
		@t_peb_plan$AMT08	NUMERIC(15,0),
		@t_peb_plan$AMT09	NUMERIC(15,0),
		@t_peb_plan$AMT10	NUMERIC(15,0),
		@t_peb_plan$AMT11	NUMERIC(15,0),
		@t_peb_plan$AMT12	NUMERIC(15,0)

    BEGIN
        SET @v_program_id   = 'P_PEB_CALC'
        SET @v_program_nm   = '�ΰǺ��ȹ����'
        SET @av_ret_code    = 'SUCCESS!'
        SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                         @v_program_id,  0000,  NULL, NULL);
    END



	BEGIN
		-- �����ڷ����
		BEGIN
			-- ����� �ּ�ó��. 2015�⵵ �ΰǺ��ȹ�� ���� �ȵ� 2014�� �����͸� ����.
			DELETE FROM PEB_PLAN
			 WHERE PEB_BASE_ID = @an_plan_id
               AND PEB_TYPE_CD LIKE @av_type_cd

			IF @@ERROR <> 0
				BEGIN
					SET @av_ret_code    = 'FAILURE!' 
					SET @av_ret_message = dbo.F_FRM_ERRMSG('�ΰǺ��ȹ DELETE�� �����߻�', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
					RETURN  
				END
		END


		BEGIN  -- BEGIN 1 START

			-- ������ȸ
			DECLARE C1 CURSOR LOCAL FOR(
				SELECT *
				  FROM PEB_BASE
				 WHERE PEB_BASE_ID = @an_plan_id
				   AND COMPANY_CD = @av_company_cd
			)

			OPEN C1
			DECLARE @BASIC_YY	nvarchar(4),
					@COMPANY_CD	nvarchar(10),
					@ETC_CD1	nvarchar(50),
					@ETC_CD2	nvarchar(50),
					@MOD_DATE	date,
					@MOD_USER_ID	numeric(18,0),
					@NOTE	nvarchar(1000),
					@PEB_BASE_ID	numeric(18,0),
					@STD_YMD	date,
					@TZ_CD	nvarchar(10),
					@TZ_DATE	date
			      
			FETCH NEXT FROM C1 INTO @BASIC_YY, @COMPANY_CD, @ETC_CD1, @ETC_CD2, @MOD_DATE, @MOD_USER_ID, @NOTE, @PEB_BASE_ID, @STD_YMD, @TZ_CD, @TZ_DATE

			
			WHILE (@@FETCH_STATUS = 0)
				BEGIN  -- C1 WHILE BEGIN START
					
					
					-- ���رݾ���ȸ
					DECLARE BASE_AMT CURSOR LOCAL FOR(
						SELECT COUNT(B.EMP_ID) EMP_CNT,
							   dbo.XF_ROUND(SUM(B.B_PAY_AMT)/COUNT(B.EMP_ID),0) B_PAY_AMT,
							   dbo.XF_ROUND(SUM(B_BONUS_AMT)/COUNT(B.EMP_ID),0) B_BONUS_AMT,
							   dbo.XF_ROUND(SUM(B_RETIRE_AMT)/COUNT(B.EMP_ID),0) B_RETIRE_AMT,
							   dbo.XF_ROUND(SUM(B_STP_AMT)/COUNT(B.EMP_ID),0) B_STP_AMT,
							   dbo.XF_ROUND(SUM(B_NHS_AMT)/COUNT(B.EMP_ID),0) B_NHS_AMT,
							   dbo.XF_ROUND(SUM(B_EMI_AMT)/COUNT(B.EMP_ID),0) B_EMI_AMT,
							   dbo.XF_ROUND(SUM(B_IAI_AMT)/COUNT(B.EMP_ID),0) B_IAI_AMT,
							   dbo.XF_ROUND(SUM(B_CHANGE_AMT)/COUNT(B.EMP_ID),0) B_CHANGE_AMT,
							   dbo.XF_ROUND(SUM(B_TIME_AMT)/COUNT(B.EMP_ID),0) B_TIME_AMT,
								B.TYPE_03_CD, --CASE WHEN B.TYPE_03_CD = '112' THEN '112' ELSE '111' END TYPE_03_CD,
								B.ORG_ID
							FROM PEB_BASE_AMT B
							LEFT OUTER JOIN	(SELECT TYPE_03_CD,
										ORG_ID
									FROM ORM_ORG_PLAN
									WHERE COMPANY_CD = @COMPANY_CD
									AND BASE_YY = @BASIC_YY) A
							  ON B.ORG_ID = A.ORG_ID
							 AND B.TYPE_03_CD = A.TYPE_03_CD
						   WHERE B.PEB_BASE_ID = @PEB_BASE_ID
							 AND B.PAY_POS_GRD_CD != '100'
						   GROUP BY B.ORG_ID, B.TYPE_03_CD --CASE WHEN B.TYPE_03_CD = '112' THEN '112' ELSE '111' END
					)

					OPEN BASE_AMT

					DECLARE @EMP_CNT NUMERIC
					      , @B_PAY_AMT NUMERIC
						  , @B_BONUS_AMT NUMERIC
						  , @B_RETIRE_AMT NUMERIC
						  , @B_STP_AMT NUMERIC
						  , @B_NHS_AMT NUMERIC
						  , @B_EMI_AMT NUMERIC
						  , @B_IAI_AMT NUMERIC
						  , @B_CHANGE_AMT NUMERIC
						  , @B_TIME_AMT NUMERIC
						  , @TYPE_03_CD NVARCHAR
						  , @ORG_ID		NUMERIC


					FETCH NEXT FROM BASE_AMT INTO @EMP_CNT, @B_PAY_AMT, @B_BONUS_AMT, @B_BONUS_AMT, @B_STP_AMT, @B_NHS_AMT, @B_EMI_AMT, @B_IAI_AMT, @B_CHANGE_AMT, @B_TIME_AMT, @TYPE_03_CD, @ORG_ID

					WHILE (@@FETCH_STATUS = 0)
						BEGIN  -- BASE_AMT WHILE START
							 
							--�η°�ȹ ��ȸ[��������������]
							DECLARE ORM CURSOR LOCAL FOR(
								SELECT *
								  FROM ORM_ORG_PLAN
								 WHERE ORG_ID = @ORG_ID
								   AND TYPE_03_CD = @TYPE_03_CD --CASE WHEN TYPE_03_CD = '112' THEN '112' ELSE '111' END = BASE_AMT.TYPE_03_CD
								   AND BASE_YY = @BASIC_YY
								 --ORDER BY ORG_ID, TYPE_01_CD, TYPE_02_CD, TYPE_03_CD
							)

							OPEN ORM

							DECLARE @ORG_ID2	numeric(38,0),
									@TYPE_01_CD	nvarchar(10),
									@TYPE_02_CD	nvarchar(10),
									@TYPE_03_CD2	nvarchar(10),
									@EMP_CNT1	numeric(10,0),
									@EMP_CNT2	numeric(10,0),
									@EMP_CNT3	numeric(10,0),
									@EMP_CNT4	numeric(10,0),
									@EMP_CNT5	numeric(10,0),
									@EMP_CNT6	numeric(10,0),
									@EMP_CNT7	numeric(10,0),
									@EMP_CNT8	numeric(10,0),
									@EMP_CNT9	numeric(10,0),
									@EMP_CNT10	numeric(10,0),
									@EMP_CNT11	numeric(10,0),
									@EMP_CNT12	numeric(10,0)
									
							
							FETCH NEXT FROM ORM INTO @ORG_ID2, @TYPE_01_CD, @TYPE_02_CD, @TYPE_03_CD2, @EMP_CNT1, @EMP_CNT2, @EMP_CNT3, @EMP_CNT4, @EMP_CNT5, @EMP_CNT6, @EMP_CNT7, @EMP_CNT8, @EMP_CNT9, @EMP_CNT10, @EMP_CNT11, @EMP_CNT12

							WHILE (@@FETCH_STATUS = 0)
								BEGIN  -- ORM WHILE START
									
									SET @n_emp_cnt = 0
									
									-- �����ο���ȸ
									BEGIN
										SELECT @n_emp_cnt = COUNT(EMP_ID)
										  FROM PEB_BASE_AMT
										 WHERE PEB_BASE_ID = @PEB_BASE_ID
										   AND ORG_ID = @ORG_ID2
										   AND TYPE_01_CD = @TYPE_01_CD
										   AND TYPE_02_CD = @TYPE_02_CD
										   AND TYPE_03_CD = @TYPE_03_CD

										IF @@ROWCOUNT = 0
											BEGIN
												SET @n_emp_cnt = 0
											END
										ELSE 
											BEGIN
												SET @n_emp_cnt = 0
											END
									END


									DECLARE CODE CURSOR LOCAL FOR(
										SELECT A.CD AS PEB_RATE_TYPE_CD,
											  B.CD AS PEB_ITEM_TYPE_CD,
											  ISNULL(C.PEB_RATE,0) AS PEB_RATE
										 FROM FRM_CODE A
										INNER JOIN FRM_CODE B
										   ON A.COMPANY_CD = B.COMPANY_CD
										  AND A.LOCALE_CD = B.LOCALE_CD
										 LEFT OUTER JOIN(SELECT PEB_TYPE_CD,
													            PEB_RATE
												           FROM PEB_RATE
												          WHERE PEB_BASE_ID = @PEB_BASE_ID) C
										   ON A.CD = C.PEB_TYPE_CD
										WHERE A.CD_KIND = 'PEB_RATE_TYPE_CD'
										  AND @STD_YMD BETWEEN A.STA_YMD AND A.END_YMD
										  AND A.COMPANY_CD = @COMPANY_CD
										  AND A.LOCALE_CD = @av_locale_cd
										  AND B.CD_KIND = 'PEB_ITEM_TYPE_CD'
										  AND @STD_YMD BETWEEN B.STA_YMD AND B.END_YMD
										  AND A.CD LIKE @av_type_cd
										  AND A.CD != '09'  -- ����������� ���� ���ؾ���.
									   --ORDER BY A.ORD_NO, B.ORD_NO
									)

									OPEN CODE

									DECLARE @PEB_RATE_TYPE_CD NVARCHAR
									      , @PEB_ITEM_TYPE_CD NVARCHAR
										  , @PEB_RATE NUMERIC

									
									FETCH NEXT FROM CODE INTO @PEB_RATE_TYPE_CD, @PEB_ITEM_TYPE_CD, @PEB_RATE

									WHILE (@@FETCH_STATUS = 0)
										BEGIN -- CODE WHILE START
											BEGIN
												SET @n_base_amt = 0
												-- ���رݾ�
												SET @n_base_amt = CASE @PEB_RATE_TYPE_CD WHEN '01' THEN @B_PAY_AMT    -- �޿�
																						 WHEN '02' THEN @B_BONUS_AMT  -- ��
																						 WHEN '03' THEN @B_RETIRE_AMT -- ������
																						 WHEN '04' THEN @B_STP_AMT    -- ���ο���
																						 WHEN '05' THEN @B_NHS_AMT    -- �ǰ�����
																						 WHEN '06' THEN @B_EMI_AMT    -- ��뺸��
																						 WHEN '07' THEN @B_IAI_AMT    -- ���纸��
																						 WHEN '08' THEN @B_CHANGE_AMT -- ����������
																						 WHEN '09' THEN @B_TIME_AMT   -- ����������
											END

											-- �η°�ȹ INSERT											
											INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- �ΰǺ��ȹID
																	PEB_BASE_ID     ,  -- �ΰǺ��ȹ����ID
																	PEB_TYPE_CD     ,  -- �ΰǺ񱸺�
																	ORG_ID          ,  -- �Ҽ�
																	TYPE_01_CD      ,  -- �����ڵ�1
																	TYPE_02_CD      ,  -- �����ڵ�2
																	TYPE_03_CD      ,  -- �����ڵ�3
																	PEB_ITEM_TYPE   ,  -- �ΰǺ񼼺α���
																	BASE_AMT        ,  -- ���رݾ�
																	EMP_CNT         ,  -- �����ο�
																	AMT01           ,  -- 1��
																	AMT02           ,  -- 2��
																	AMT03           ,  -- 3��
																	AMT04           ,  -- 4��
																	AMT05           ,  -- 5��
																	AMT06           ,  -- 6��
																	AMT07           ,  -- 7��
																	AMT08           ,  -- 8��
																	AMT09           ,  -- 9��
																	AMT10           ,  -- 10��
																	AMT11           ,  -- 11��
																	AMT12           ,  -- 12��
																	MOD_USER_ID     ,  -- ������
																	MOD_DATE        ,  -- �����Ͻ�
																	TZ_CD           ,  -- Ÿ�����ڵ�
																	TZ_DATE            -- Ÿ�����Ͻ�
																	)
															VALUES (NEXT VALUE FOR S_PEB_SEQUENCE  ,  -- �ΰǺ���رݾ�ID
																	@an_plan_id              ,  -- �ΰǺ��ȹ����ID
																	@PEB_RATE_TYPE_CD   ,  -- �ΰǺ񱸺�
																	@ORG_ID2              ,  -- �Ҽ�
																	@TYPE_01_CD          ,  -- �����ڵ�1
																	@TYPE_02_CD         ,  -- �����ڵ�2
																	@TYPE_03_CD         ,  -- �����ڵ�3
																	@PEB_ITEM_TYPE_CD   ,  -- �ΰǺ񼼺α���
																	@n_base_amt              ,  -- ���رݾ�
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @n_emp_cnt    -- �ο�
																	ELSE @n_base_amt*@n_emp_cnt END,  -- �����ο�
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT1    -- �ο�
																	ELSE @n_base_amt*@EMP_CNT1 END,  -- 1��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT2    -- �ο�
																	ELSE @n_base_amt*@EMP_CNT2 END,  -- 2��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT3    -- �ο�
																		WHEN '02' THEN @n_base_amt*@EMP_CNT3  -- ����⵵
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT3)+(@n_base_amt*@EMP_CNT3*@PEB_RATE/100),0) END,  -- 3��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT4    -- �ο�
																		WHEN '02' THEN @n_base_amt*@EMP_CNT4  -- ����⵵
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT4)+(@n_base_amt*@EMP_CNT4*@PEB_RATE/100),0) END,  -- 4��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT5    -- �ο�
																		WHEN '02' THEN @n_base_amt*@EMP_CNT5  -- ����⵵
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT5)+(@n_base_amt*@EMP_CNT5*@PEB_RATE/100),0) END,  -- 5��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT6    -- �ο�
																		WHEN '02' THEN @n_base_amt*@EMP_CNT6  -- ����⵵
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT6)+(@n_base_amt*@EMP_CNT6*@PEB_RATE/100),0) END,  -- 6��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT7    -- �ο�
																		WHEN '02' THEN @n_base_amt*@EMP_CNT7  -- ����⵵
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT7)+(@n_base_amt*@EMP_CNT7*@PEB_RATE/100),0) END,  -- 7��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT8    -- �ο�
																		WHEN '02' THEN @n_base_amt*@EMP_CNT8  -- ����⵵
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT8)+(@n_base_amt*@EMP_CNT8*@PEB_RATE/100),0) END,  -- 8��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT9    -- �ο�
																		WHEN '02' THEN @n_base_amt*@EMP_CNT9  -- ����⵵
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT9)+(@n_base_amt*@EMP_CNT9*@PEB_RATE/100),0) END,  -- 9��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT10    -- �ο�
																		WHEN '02' THEN @n_base_amt*@EMP_CNT10  -- ����⵵
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT10)+(@n_base_amt*@EMP_CNT10*@PEB_RATE/100),0) END,  -- 10��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT11    -- �ο�
																		WHEN '02' THEN @n_base_amt*@EMP_CNT11  -- ����⵵
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT11)+(@n_base_amt*@EMP_CNT11*@PEB_RATE/100),0) END,  -- 11��
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT12    -- �ο�
																		WHEN '02' THEN @n_base_amt*@EMP_CNT12  -- ����⵵
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT12)+(@n_base_amt*@EMP_CNT12*@PEB_RATE/100),0) END,  -- 12��
																	@an_mod_user_id    ,  -- ������
																	dbo.XF_SYSDATE(0)     ,  -- �����Ͻ�
																	'KST'             ,  -- Ÿ�����ڵ�
																	dbo.XF_SYSDATE(0)        -- Ÿ�����Ͻ�
																	)
											IF @@ERROR <> 0
												BEGIN
													SET @av_ret_code    = 'FAILURE!' 
													SET @av_ret_message = dbo.F_FRM_ERRMSG('�ΰǺ��ȹ INSERT�� �����߻�', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
													RETURN  
												END
											

											FETCH NEXT FROM CODE INTO @PEB_RATE_TYPE_CD, @PEB_ITEM_TYPE_CD, @PEB_RATE
										END -- CODE WHILE END

									CLOSE CODE
									DEALLOCATE CODE

									FETCH NEXT FROM ORM INTO @ORG_ID2, @TYPE_01_CD, @TYPE_02_CD, @TYPE_03_CD2, @EMP_CNT1, @EMP_CNT2, @EMP_CNT3, @EMP_CNT4, @EMP_CNT5, @EMP_CNT6, @EMP_CNT7, @EMP_CNT8, @EMP_CNT9, @EMP_CNT10, @EMP_CNT11, @EMP_CNT12
								END -- ORM WHILE END
								
								CLOSE ORM
								DEALLOCATE ORM

							FETCH NEXT FROM BASE_AMT INTO @EMP_CNT, @B_PAY_AMT, @B_BONUS_AMT, @B_BONUS_AMT, @B_STP_AMT, @B_NHS_AMT, @B_EMI_AMT, @B_IAI_AMT, @B_CHANGE_AMT, @B_TIME_AMT, @TYPE_03_CD, @ORG_ID
						END  -- BASE_AMT WHILE END

						CLOSE BASE_AMT
						DEALLOCATE BASE_AMT





						BEGIN
							-- ��ձ��ϱ�
							UPDATE PEB_PLAN 
							   SET AVG_AMT =dbo.XF_ROUND((AMT01+AMT02+AMT03+AMT04+AMT05+AMT06+AMT07+AMT08+AMT09+AMT10+AMT11+AMT12)/12,0)
							 WHERE PEB_BASE_ID = @PEB_BASE_ID
							   AND PEB_TYPE_CD LIKE @av_type_cd
						END

						BEGIN
							-- �������ϱ�
							UPDATE PEB_PLAN 
							   SET J_AMT = AVG_AMT-EMP_CNT
							 WHERE PEB_BASE_ID = @PEB_BASE_ID
							   AND PEB_TYPE_CD LIKE @av_type_cd
						END

						DECLARE CHA CURSOR LOCAL FOR(
							SELECT ORG_ID, PEB_TYPE_CD,TYPE_01_CD, TYPE_02_CD, TYPE_03_CD,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN BASE_AMT ELSE 0 END) J_BASE_AMT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN BASE_AMT ELSE 0 END) BASE_AMT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN EMP_CNT ELSE 0 END) J_EMP_CNT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN EMP_CNT ELSE 0 END) EMP_CNT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT01 ELSE 0 END) J_AMT01,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT01 ELSE 0 END)   AMT01,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT02 ELSE 0 END) J_AMT02,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT02 ELSE 0 END)   AMT02,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT03 ELSE 0 END) J_AMT03,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT03 ELSE 0 END)   AMT03,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT04 ELSE 0 END) J_AMT04,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT04 ELSE 0 END)   AMT04,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT05 ELSE 0 END) J_AMT05,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT05 ELSE 0 END)   AMT05,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT06 ELSE 0 END) J_AMT06,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT06 ELSE 0 END)   AMT06,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT07 ELSE 0 END) J_AMT07,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT07 ELSE 0 END)   AMT07,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT08 ELSE 0 END) J_AMT08,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT08 ELSE 0 END)   AMT08,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT09 ELSE 0 END) J_AMT09,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT09 ELSE 0 END)   AMT09,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT10 ELSE 0 END) J_AMT10,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT10 ELSE 0 END)   AMT10,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT11 ELSE 0 END) J_AMT11,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT11 ELSE 0 END)   AMT11,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT12 ELSE 0 END) J_AMT12,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT12 ELSE 0 END)   AMT12,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AVG_AMT ELSE 0 END) J_AVG_AMT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AVG_AMT ELSE 0 END)   AVG_AMT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN J_AMT ELSE 0 END) J_J_AMT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN J_AMT ELSE 0 END)   J_AMT
							 FROM PEB_PLAN
							WHERE PEB_ITEM_TYPE IN ('02','03')
							  AND PEB_BASE_ID = @PEB_BASE_ID
							  AND PEB_TYPE_CD LIKE @av_type_cd
						   GROUP BY  ORG_ID, PEB_TYPE_CD,TYPE_01_CD, TYPE_02_CD, TYPE_03_CD
						)


						OPEN CHA 

						DECLARE @CHA_ORG_ID numeric(18,0)
						      , @PEB_TYPE_CD nvarchar(10)
							  , @CHA_TYPE_01_CD nvarchar(10)
							  , @CHA_TYPE_02_CD nvarchar(10)
							  , @CHA_TYPE_03_CD  nvarchar(10)
							  , @J_BASE_AMT numeric(15,0)
							  , @BASE_AMT numeric(15,0)
							  , @J_EMP_CNT numeric(15,0)
							  , @CHA_EMP_CNT numeric(15,0)
							  , @J_AMT01 numeric(15,0)
							  , @AMT01 numeric(15,0)
							  , @J_AMT02 numeric(15,0)
							  , @AMT02 numeric(15,0)
							  , @J_AMT03 numeric(15,0)
							  , @AMT03 numeric(15,0)
							  , @J_AMT04 numeric(15,0)
							  , @AMT04 numeric(15,0)
							  , @J_AMT05 numeric(15,0)
							  , @AMT05 numeric(15,0)
							  , @J_AMT06 numeric(15,0)
							  , @AMT06 numeric(15,0)
							  , @J_AMT07 numeric(15,0)
							  , @AMT07 numeric(15,0)
							  , @J_AMT08 numeric(15,0)
							  , @AMT08 numeric(15,0)
							  , @J_AMT09 numeric(15,0)
							  , @AMT09 numeric(15,0)
							  , @J_AMT10 numeric(15,0)
							  , @AMT10 numeric(15,0)
							  , @J_AMT11 numeric(15,0)
							  , @AMT11 numeric(15,0)
							  , @J_AMT12 numeric(15,0)
							  , @AMT12 numeric(15,0)
							  , @J_AVG_AMT numeric(15,0)
							  , @AVG_AMT numeric(15,0)
							  , @J_J_AMT numeric(15,0)
							  , @J_AMT numeric(15,0)
						
						FETCH NEXT FROM CHA INTO @CHA_ORG_ID, @PEB_TYPE_CD, @CHA_TYPE_01_CD, @CHA_TYPE_02_CD, @CHA_TYPE_03_CD, @J_BASE_AMT, @BASE_AMT, @J_EMP_CNT, @CHA_EMP_CNT, @J_AMT01, @AMT01
						                       , @J_AMT02, @AMT02, @J_AMT03, @AMT03, @J_AMT04, @AMT04, @J_AMT05, @AMT05, @J_AMT06, @AMT06, @J_AMT07, @AMT07, @J_AMT08, @AMT08, @J_AMT09, @AMT09
											   , @J_AMT10, @AMT10, @J_AMT11, @AMT11, @J_AMT12, @AMT12, @J_AVG_AMT, @AVG_AMT, @J_J_AMT, @J_AMT


						WHILE (@@FETCH_STATUS = 0)
							BEGIN	-- CHA WHILE START
								 UPDATE PEB_PLAN
									SET BASE_AMT  = @BASE_AMT - @J_BASE_AMT,
										EMP_CNT   = @CHA_EMP_CNT - @J_EMP_CNT,
										AMT01     = @AMT01   - @J_AMT01,
										AMT02     = @AMT02   - @J_AMT02,
										AMT03     = @AMT03   - @J_AMT03,
										AMT04     = @AMT04   - @J_AMT04,
										AMT05     = @AMT05   - @J_AMT05,
										AMT06     = @AMT06   - @J_AMT06,
										AMT07     = @AMT07   - @J_AMT07,
										AMT08     = @AMT08   - @J_AMT08,
										AMT09     = @AMT09   - @J_AMT09,
										AMT10     = @AMT10   - @J_AMT10,
										AMT11     = @AMT11   - @J_AMT11,
										AMT12     = @AMT12   - @J_AMT12,
										AVG_AMT   = @AVG_AMT - @J_AVG_AMT,
										J_AMT     = @J_AMT   - @J_J_AMT
								  WHERE PEB_ITEM_TYPE = '04'
									AND PEB_BASE_ID = @PEB_BASE_ID
									AND ORG_ID = @CHA_ORG_ID
									AND PEB_TYPE_CD = @PEB_TYPE_CD
									AND TYPE_01_CD = @CHA_TYPE_01_CD
									AND TYPE_02_CD = @CHA_TYPE_02_CD
									AND TYPE_03_CD = @CHA_TYPE_03_CD
								
								IF @@ERROR <> 0
									BEGIN
										SET @av_ret_code    = 'FAILURE!' 
										SET @av_ret_message = dbo.F_FRM_ERRMSG('�ΰǺ��ȹ ���� UPDATE�� �����߻�', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
										RETURN  
									END

								FETCH NEXT FROM CHA INTO @CHA_ORG_ID, @PEB_TYPE_CD, @CHA_TYPE_01_CD, @CHA_TYPE_02_CD, @CHA_TYPE_03_CD, @J_BASE_AMT, @BASE_AMT, @J_EMP_CNT, @CHA_EMP_CNT, @J_AMT01, @AMT01
													   , @J_AMT02, @AMT02, @J_AMT03, @AMT03, @J_AMT04, @AMT04, @J_AMT05, @AMT05, @J_AMT06, @AMT06, @J_AMT07, @AMT07, @J_AMT08, @AMT08, @J_AMT09, @AMT09
													   , @J_AMT10, @AMT10, @J_AMT11, @AMT11, @J_AMT12, @AMT12, @J_AVG_AMT, @AVG_AMT, @J_J_AMT, @J_AMT
							END	    -- CHA WHILE END
						      
							CLOSE CHA
							DEALLOCATE CHA

					-- �����ƴ븮�� ����[2013.12.18�� ��ȭ��ȭ�� ����]
					-- �����������ΰ�� ���ؽñ� : �ش�Ҽ��� �����η¿� ���� ���ؽñ��� ���Ͽ� �����۾���/������η¿� �Ȱ��� ���ؽñ��� �����Ѵ�.
					-- �λ����� 3������ ���ؽñ޿� �ݿ��Ͽ� �����Ѵ�.
					-- 3����ٹ��� ������3��, 2����ٹ��� ������2���ΰ�� *2, �������� *1.5�� �����Ѵ�.
					-- ���رݾ���ȸ[������������� �ñ�]

					IF @av_type_cd IN ('%', '09')
						BEGIN
							
							DECLARE BASE_AMT1 CURSOR LOCAL FOR(
								SELECT COUNT(B.EMP_ID) AS EMP_CNT,
										dbo.XF_ROUND(SUM(B_TIME_AMT)/COUNT(B.EMP_ID),0) AS B_TIME_AMT,
										B.ORG_ID,
										MAX(C.PEB_RATE) PEB_RATE
									FROM (SELECT DISTINCT ORG_ID
											FROM ORM_ORG_PAY_PLAN
											WHERE COMPANY_CD = @COMPANY_CD
											AND BASE_YY = @BASIC_YY) A
									LEFT OUTER JOIN PEB_BASE_AMT B
									ON B.ORG_ID = A.ORG_ID
									INNER JOIN PEB_RATE C
									ON B.PEB_BASE_ID = C.PEB_BASE_ID
									WHERE B.TYPE_03_CD = '112'  -- �������ο������� ���Ѵ�.
									AND B.PEB_BASE_ID = @PEB_BASE_ID
									AND C.PEB_TYPE_CD = '09'
								GROUP BY B.ORG_ID
							)

							OPEN BASE_AMT1 

							DECLARE @BASE_EMP_CNT NUMERIC
									, @BASE_B_TIME_AMT NUMERIC
									, @BASE_ORG_ID NUMERIC
									, @BASE_PEB_RATE NUMERIC

							FETCH NEXT FROM BASE_AMT1 INTO @PEB_RATE_TYPE_CD, @PEB_ITEM_TYPE_CD, @PEB_RATE
							
							WHILE (@@FETCH_STATUS = 0)
								BEGIN  -- BASE_AMT1 WHILE START
									BEGIN
										SET @n_base_amt = 0
										SET @n_base_amt = @BASE_B_TIME_AMT
									END

									--�η°�ȹ ��ȸ[�ٹ��ϼ�,�����ϼ�]
									DECLARE ORM1 CURSOR LOCAL FOR(
										 SELECT ORG_ID,
												TYPE_01_CD,
												TYPE_02_CD,
												TYPE_03_CD,
												EMP_CNT1,
												EMP_CNT2,
												EMP_CNT3,
												EMP_CNT4,
												EMP_CNT5,
												EMP_CNT6,
												EMP_CNT7,
												EMP_CNT8,
												EMP_CNT9,
												EMP_CNT10,
												EMP_CNT11,
												EMP_CNT12
										   FROM ORM_ORG_PAY_PLAN
										  WHERE ORG_ID = @BASE_ORG_ID
											AND TYPE_03_CD IN ('1110', '1120')
											AND BASE_YY = @BASIC_YY
										 --ORDER BY ORG_ID
									)

									OPEN ORM1 

									DECLARE @ORM1_ORG_ID	numeric(38,0),
											@ORM1_TYPE_01_CD	nvarchar(10),
											@ORM1_TYPE_02_CD	nvarchar(10),
											@ORM1_TYPE_03_CD	nvarchar(10),
											@ORM1_EMP_CNT1	numeric(10,0),
											@ORM1_EMP_CNT2	numeric(10,0),
											@ORM1_EMP_CNT3	numeric(10,0),
											@ORM1_EMP_CNT4	numeric(10,0),
											@ORM1_EMP_CNT5	numeric(10,0),
											@ORM1_EMP_CNT6	numeric(10,0),
											@ORM1_EMP_CNT7	numeric(10,0),
											@ORM1_EMP_CNT8	numeric(10,0),
											@ORM1_EMP_CNT9	numeric(10,0),
											@ORM1_EMP_CNT10	numeric(10,0),
											@ORM1_EMP_CNT11	numeric(10,0),
											@ORM1_EMP_CNT12	numeric(10,0)
									
									FETCH NEXT FROM ORM1 INTO @ORM1_ORG_ID, @ORM1_TYPE_01_CD, @ORM1_TYPE_02_CD, @ORM1_TYPE_03_CD, @ORM1_EMP_CNT1, @ORM1_EMP_CNT2, @ORM1_EMP_CNT3, @ORM1_EMP_CNT4, @ORM1_EMP_CNT5
									                        , @ORM1_EMP_CNT6, @ORM1_EMP_CNT7, @ORM1_EMP_CNT8, @ORM1_EMP_CNT9, @ORM1_EMP_CNT10, @ORM1_EMP_CNT11, @ORM1_EMP_CNT12

									WHILE (@@FETCH_STATUS = 0 )
										 -- �η°�ȹ INSERT
										BEGIN  -- ORM1 WHILE START
											BEGIN
												INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- �ΰǺ��ȹID
																	  PEB_BASE_ID     ,  -- �ΰǺ��ȹ����ID
																	  PEB_TYPE_CD     ,  -- �ΰǺ񱸺�
																	  ORG_ID          ,  -- �Ҽ�
																	  TYPE_01_CD      ,  -- �����ڵ�1
																	  TYPE_02_CD      ,  -- �����ڵ�2
																	  TYPE_03_CD      ,  -- �����ڵ�3
																	  PEB_ITEM_TYPE   ,  -- �ΰǺ񼼺α���
																	  BASE_AMT        ,  -- ���رݾ�
																	  EMP_CNT         ,  -- �����ο�
																	  AMT01           ,  -- 1��
																	  AMT02           ,  -- 2��
																	  AMT03           ,  -- 3��
																	  AMT04           ,  -- 4��
																	  AMT05           ,  -- 5��
																	  AMT06           ,  -- 6��
																	  AMT07           ,  -- 7��
																	  AMT08           ,  -- 8��
																	  AMT09           ,  -- 9��
																	  AMT10           ,  -- 10��
																	  AMT11           ,  -- 11��
																	  AMT12           ,  -- 12��
																	  MOD_USER_ID     ,  -- ������
																	  MOD_DATE        ,  -- �����Ͻ�
																	  TZ_CD           ,  -- Ÿ�����ڵ�
																	  TZ_DATE            -- Ÿ�����Ͻ�
																	  )
															  VALUES (NEXT VALUE FOR S_PEB_SEQUENCE,  -- �ΰǺ���رݾ�ID
																	  @an_plan_id              ,  -- �ΰǺ��ȹ����ID
																	  '09'                    ,  -- �ΰǺ񱸺�
																	  @ORM1_ORG_ID             ,  -- �Ҽ�
																	  @ORM1_TYPE_01_CD         ,  -- �����ڵ�1
																	  @ORM1_TYPE_02_CD         ,  -- �����ڵ�2
																	  @ORM1_TYPE_03_CD         ,  -- �����ڵ�3
																	  @ORM1_TYPE_03_CD         ,  -- �ΰǺ񼼺α���
																	  @n_base_amt              ,  -- ���رݾ�
																	  @BASE_EMP_CNT,  -- �����ο�
																	  @ORM1_EMP_CNT1,  -- 1��
																	  @ORM1_EMP_CNT2,
																	  @ORM1_EMP_CNT3,
																	  @ORM1_EMP_CNT4,
																	  @ORM1_EMP_CNT5,
																	  @ORM1_EMP_CNT6,
																	  @ORM1_EMP_CNT7,
																	  @ORM1_EMP_CNT8,
																	  @ORM1_EMP_CNT9,
																	  @ORM1_EMP_CNT10,
																	  @ORM1_EMP_CNT11,
																	  @ORM1_EMP_CNT12,
																	  @an_mod_user_id    ,  -- ������
																	  dbo.XF_SYSDATE(0)     ,  -- �����Ͻ�
																	  'KST'             ,  -- Ÿ�����ڵ�
																	  dbo.XF_SYSDATE(0)        -- Ÿ�����Ͻ�
																	 )
												IF @@ERROR <> 0
													BEGIN
														SET @av_ret_code    = 'FAILURE!' 
														SET @av_ret_message = dbo.F_FRM_ERRMSG('���������� �ٹ��ϼ�/�����ϼ� INSERT�� �����߻�', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
														RETURN  
													END
											END
											FETCH NEXT FROM ORM1 INTO @ORM1_ORG_ID, @ORM1_TYPE_01_CD, @ORM1_TYPE_02_CD, @ORM1_TYPE_03_CD, @ORM1_EMP_CNT1, @ORM1_EMP_CNT2, @ORM1_EMP_CNT3, @ORM1_EMP_CNT4, @ORM1_EMP_CNT5
																	, @ORM1_EMP_CNT6, @ORM1_EMP_CNT7, @ORM1_EMP_CNT8, @ORM1_EMP_CNT9, @ORM1_EMP_CNT10, @ORM1_EMP_CNT11, @ORM1_EMP_CNT12
										END  -- ORM1 WHILE END
										CLOSE ORM1 
										DEALLOCATE ORM1
-- 1000 �����۾���
-- 2000 ������η�

-- 1110 2����
-- 1120 3����
-- 1210 �ʰ��ٹ�

-- 1110 �ٹ��ϼ�
-- 1120 �����ϼ�
-- 1210 ������(1��)
-- 1220 ������(2��)
-- 1230 ������(3��)
-- 1310 �繫��(����)
-- 1320 ������۾���(����)
-- 3110 �ο�
-- 3120 �ݾ�
										-- �ο��Է�
										BEGIN
											INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- �ΰǺ��ȹID
																PEB_BASE_ID     ,  -- �ΰǺ��ȹ����ID
																PEB_TYPE_CD     ,  -- �ΰǺ񱸺�
																ORG_ID          ,  -- �Ҽ�
																TYPE_01_CD      ,  -- �����ڵ�1
																TYPE_02_CD      ,  -- �����ڵ�2
																TYPE_03_CD      ,  -- �����ڵ�3
																PEB_ITEM_TYPE   ,  -- �ΰǺ񼼺α���
																BASE_AMT        ,  -- ���رݾ�
																EMP_CNT         ,  -- �����ο�
																AMT01           ,  -- 1��
																AMT02           ,  -- 2��
																AMT03           ,  -- 3��
																AMT04           ,  -- 4��
																AMT05           ,  -- 5��
																AMT06           ,  -- 6��
																AMT07           ,  -- 7��
																AMT08           ,  -- 8��
																AMT09           ,  -- 9��
																AMT10           ,  -- 10��
																AMT11           ,  -- 11��
																AMT12           ,  -- 12��
																MOD_USER_ID     ,  -- ������
																MOD_DATE        ,  -- �����Ͻ�
																TZ_CD           ,  -- Ÿ�����ڵ�
																TZ_DATE            -- Ÿ�����Ͻ�
																)
															SELECT NEXT VALUE FOR S_PEB_SEQUENCE,  -- �ΰǺ���رݾ�ID
																@an_plan_id              ,  -- �ΰǺ��ȹ����ID
																'09'                    ,  -- �ΰǺ񱸺�
																ORG_ID             ,  -- �Ҽ�
																TYPE_01_CD         ,  -- �����ڵ�1
																TYPE_02_CD         ,  -- �����ڵ�2
																TYPE_03_CD         ,  -- �����ڵ�3
																'3110'             ,  -- �ΰǺ񼼺α���
																@n_base_amt         ,  -- ���رݾ�
																@BASE_EMP_CNT,  -- �����ο�
																EMP_CNT1,  -- 1��
																EMP_CNT2,  -- 2��
																EMP_CNT3,  -- 3��
																EMP_CNT4,  -- 4��
																EMP_CNT5,  -- 5��
																EMP_CNT6,  -- 6��
																EMP_CNT7,  -- 7��
																EMP_CNT8,  -- 8��
																EMP_CNT9,  -- 9��
																EMP_CNT10,  -- 10��
																EMP_CNT11,  -- 11��
																EMP_CNT12,  -- 12��
																@an_mod_user_id    ,  -- ������
																dbo.XF_SYSDATE(0)     ,  -- �����Ͻ�
																'KST'             ,  -- Ÿ�����ڵ�
																dbo.XF_SYSDATE(0)        -- Ÿ�����Ͻ�
															FROM ORM_ORG_PAY_PLAN
															WHERE ORG_ID = @BASE_ORG_ID
															AND TYPE_03_CD NOT IN ('1110', '1120')
															AND BASE_YY = @BASIC_YY
											IF @@ERROR <> 0
												BEGIN
													SET @av_ret_code    = 'FAILURE!' 
													SET @av_ret_message = dbo.F_FRM_ERRMSG('���������� �ο� INSERT�� �����߻�', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
													RETURN  
												END
										END


										BEGIN
											-- Ư�ټ��� �Է�
											-- �ο���ȸ
											DECLARE OT CURSOR LOCAL FOR(
												SELECT AMT01
													 , AMT02
													 , AMT03
													 , AMT04
													 , AMT05
													 , AMT06
													 , AMT07
													 , AMT08
													 , AMT09
													 , AMT10
													 , AMT11
													 , AMT12
													 , AVG_AMT
													 , BASE_AMT
													 , B_ORG_ID
													 , EMP_CNT
													 , ETC_CD1
													 , ETC_CD2
													 , G_ORG_ID
													 , J_AMT
													 , MOD_DATE
													 , MOD_USER_ID
													 , NOTE
													 , ORG_ID
													 , PEB_BASE_ID
													 , PEB_ITEM_TYPE
													 , PEB_PLAN_ID
													 , PEB_TYPE_CD
													 , TYPE_01_CD
													 , TYPE_02_CD
													 , TYPE_03_CD
												 FROM PEB_PLAN
												WHERE PEB_BASE_ID = @PEB_BASE_ID
												  AND ORG_ID = @BASE_ORG_ID
												  AND PEB_ITEM_TYPE = '3110'
											)

											OPEN OT

											DECLARE @OT_AMT01	numeric(15,0),
													@OT_AMT02	numeric(15,0),
													@OT_AMT03	numeric(15,0),
													@OT_AMT04	numeric(15,0),
													@OT_AMT05	numeric(15,0),
													@OT_AMT06	numeric(15,0),
													@OT_AMT07	numeric(15,0),
													@OT_AMT08	numeric(15,0),
													@OT_AMT09	numeric(15,0),
													@OT_AMT10	numeric(15,0),
													@OT_AMT11	numeric(15,0),
													@OT_AMT12	numeric(15,0),
													@OT_AVG_AMT	numeric(15,0),
													@OT_BASE_AMT	numeric(15,0),
													@OT_B_ORG_ID	numeric(18,0),
													@OT_EMP_CNT	numeric(15,0),
													@OT_ETC_CD1	nvarchar(50),
													@OT_ETC_CD2	nvarchar(50),
													@OT_G_ORG_ID	numeric(18,0),
													@OT_J_AMT	numeric(10,2),
													@OT_MOD_DATE	date,
													@OT_MOD_USER_ID	numeric(18,0),
													@OT_NOTE	nvarchar(4000),
													@OT_ORG_ID	numeric(18,0),
													@OT_PEB_BASE_ID	numeric(18,0),
													@OT_PEB_ITEM_TYPE	nvarchar(10),
													@OT_PEB_PLAN_ID	numeric(18,0),
													@OT_PEB_TYPE_CD	nvarchar(10),
													@OT_TYPE_01_CD	nvarchar(10),
													@OT_TYPE_02_CD	nvarchar(10),
													@OT_TYPE_03_CD	nvarchar(10)
											

											FETCH NEXT FROM OT INTO @OT_AMT01 , @OT_AMT02, @OT_AMT03, @OT_AMT04, @OT_AMT05, @OT_AMT06, @OT_AMT07, @OT_AMT08, @OT_AMT09, @OT_AMT10, @OT_AMT11, @OT_AMT12, @OT_AVG_AMT, @OT_BASE_AMT,
						                        @OT_B_ORG_ID, @OT_EMP_CNT, @OT_ETC_CD1, @OT_ETC_CD2, @OT_G_ORG_ID, @OT_J_AMT, @OT_MOD_DATE, @OT_MOD_USER_ID, @OT_NOTE, @OT_ORG_ID, @OT_PEB_BASE_ID, @OT_PEB_ITEM_TYPE,
												@OT_PEB_PLAN_ID, @OT_PEB_TYPE_CD, @OT_TYPE_01_CD, @OT_TYPE_02_CD, @OT_TYPE_03_CD	

											
											WHILE (@@FETCH_STATUS = 0)
												BEGIN	-- OT WHILE START
													-- �ʰ��ٹ��ΰ�� �ٹ��ϼ��� ���Ѵ�.
													-- �ñ� * �ο� * �ٹ��ϼ� * �λ���(3����������) * 1.5
													IF @OT_TYPE_02_CD = '1210' 
														BEGIN
															-- �ʰ��ٹ��ϰ�� �ο���ȸ[2������ ������������ ���� ����� �ο����� �Ѵ�.]
															BEGIN
																SELECT @t_peb_plan$AMT01 = AMT01
																	 , @t_peb_plan$AMT02 = AMT02
																	 , @t_peb_plan$AMT03 = AMT03
																	 , @t_peb_plan$AMT04 = AMT04
																	 , @t_peb_plan$AMT05 = AMT05
																	 , @t_peb_plan$AMT06 = AMT06
																	 , @t_peb_plan$AMT07 = AMT07
																	 , @t_peb_plan$AMT08 = AMT08
																	 , @t_peb_plan$AMT09 = AMT09
																	 , @t_peb_plan$AMT10 = AMT10
																	 , @t_peb_plan$AMT11 = AMT11
																	 , @t_peb_plan$AMT12 = AMT12
																  FROM PEB_PLAN
																 WHERE PEB_BASE_ID = @OT_PEB_BASE_ID
																   AND ORG_ID = @OT_ORG_ID
																   AND PEB_ITEM_TYPE = '3110'
																   AND TYPE_02_CD = '1110'
																   AND TYPE_03_CD = @OT_TYPE_03_CD
															END

															-- �η°�ȹ INSERT
															BEGIN
																INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- �ΰǺ��ȹID
																					  PEB_BASE_ID     ,  -- �ΰǺ��ȹ����ID
																					  PEB_TYPE_CD     ,  -- �ΰǺ񱸺�
																					  ORG_ID          ,  -- �Ҽ�
																					  TYPE_01_CD      ,  -- �����ڵ�1
																					  TYPE_02_CD      ,  -- �����ڵ�2
																					  TYPE_03_CD      ,  -- �����ڵ�3
																					  PEB_ITEM_TYPE   ,  -- �ΰǺ񼼺α���
																					  BASE_AMT        ,  -- ���رݾ�
																					  EMP_CNT         ,  -- �����ο�
																					  AMT01           ,  -- 1��
																					  AMT02           ,  -- 2��
																					  AMT03           ,  -- 3��
																					  AMT04           ,  -- 4��
																					  AMT05           ,  -- 5��
																					  AMT06           ,  -- 6��
																					  AMT07           ,  -- 7��
																					  AMT08           ,  -- 8��
																					  AMT09           ,  -- 9��
																					  AMT10           ,  -- 10��
																					  AMT11           ,  -- 11��
																					  AMT12           ,  -- 12��
																					  NOTE            ,  -- ���
																					  MOD_USER_ID     ,  -- ������
																					  MOD_DATE        ,  -- �����Ͻ�
																					  TZ_CD           ,  -- Ÿ�����ڵ�
																					  TZ_DATE            -- Ÿ�����Ͻ�
																					  )
																			   SELECT NEXT VALUE FOR S_PEB_SEQUENCE,  -- �ΰǺ���رݾ�ID
																					  @an_plan_id              ,  -- �ΰǺ��ȹ����ID
																					  '09'                    ,  -- �ΰǺ񱸺�
																					  @OT_ORG_ID             ,  -- �Ҽ�
																					  @OT_TYPE_01_CD         ,  -- �����ڵ�1
																					  @OT_TYPE_02_CD         ,  -- �����ڵ�2
																					  @OT_TYPE_03_CD         ,  -- �����ڵ�3
																					  '3120'                ,  -- �ΰǺ񼼺α���
																					  @n_base_amt              ,  -- ���رݾ�
																					  @BASE_EMP_CNT,  -- �����ο�
																					  dbo.XF_ROUND(@n_base_amt * @OT_AMT01 * AMT01 * @t_peb_plan$AMT01,0),  -- 1��
																					  dbo.XF_ROUND(@n_base_amt * @OT_AMT02 * AMT02 * @t_peb_plan$AMT02,0),  -- 2��
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT03 * AMT03 * @t_peb_plan$AMT03,0),  -- 3��
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT04 * AMT04 * @t_peb_plan$AMT04,0),  -- 4��
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT05 * AMT05 * @t_peb_plan$AMT05,0),  -- 5��
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT06 * AMT06 * @t_peb_plan$AMT06,0),  -- 6��
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT07 * AMT07 * @t_peb_plan$AMT07,0),  -- 7��
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT08 * AMT08 * @t_peb_plan$AMT08,0),  -- 8��
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT09 * AMT09 * @t_peb_plan$AMT09,0),  -- 9��
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT10 * AMT10 * @t_peb_plan$AMT10,0),  -- 10��
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT11 * AMT11 * @t_peb_plan$AMT11,0),  -- 11��
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT12 * AMT12 * @t_peb_plan$AMT12,0),  -- 12��
																					  '(�ñ�['+@n_base_amt+'] + �λ���(3����������)['+@n_base_amt*@BASE_PEB_RATE/100+']) * �ο� * �ð�[2�����ο�] * �ٹ��ϼ� * 1.5',
																					  @an_mod_user_id    ,  -- ������
																					  dbo.XF_SYSDATE(0)     ,  -- �����Ͻ�
																					  'KST'             ,  -- Ÿ�����ڵ�
																					  dbo.XF_SYSDATE(0)        -- Ÿ�����Ͻ�
																				 FROM PEB_PLAN
																				WHERE ORG_ID = @OT_ORG_ID
																				  AND PEB_ITEM_TYPE IN ('1110')  -- �ٹ��ϼ��� ���� �������
																				  AND PEB_BASE_ID = @PEB_BASE_ID
																IF @@ERROR <> 0
																	BEGIN
																		SET @av_ret_code    = 'FAILURE!' 
																		SET @av_ret_message = dbo.F_FRM_ERRMSG('���������� �ٹ��ϼ��� ���� ������� INSERT�� �����߻�', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
																		RETURN  
																	END
															END
														END

													-- �ʰ��ٹ��� ������ 2���� �� 3�����ΰ�� �����ϼ��� ����Ѵ�.
													-- �ñ� * 8 * �ο� * �����ϼ� * �λ���(3����������) * (2������ 2��, 3������ 3���ΰ�� 2, �ƴϸ� 1.5��)
													ELSE 
														BEGIN
															-- 2������ 2��, 3������ 3���ΰ�� * 2���Ѵ�.
															IF (@OT_TYPE_02_CD = '1110' AND @OT_TYPE_03_CD = '1220') OR (@OT_TYPE_02_CD = '1120' AND @OT_TYPE_03_CD = '1230') 
																BEGIN
																	INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- �ΰǺ��ȹID
																						  PEB_BASE_ID     ,  -- �ΰǺ��ȹ����ID
																						  PEB_TYPE_CD     ,  -- �ΰǺ񱸺�
																						  ORG_ID          ,  -- �Ҽ�
																						  TYPE_01_CD      ,  -- �����ڵ�1
																						  TYPE_02_CD      ,  -- �����ڵ�2
																						  TYPE_03_CD      ,  -- �����ڵ�3
																						  PEB_ITEM_TYPE   ,  -- �ΰǺ񼼺α���
																						  BASE_AMT        ,  -- ���رݾ�
																						  EMP_CNT         ,  -- �����ο�
																						  AMT01           ,  -- 1��
																						  AMT02           ,  -- 2��
																						  AMT03           ,  -- 3��
																						  AMT04           ,  -- 4��
																						  AMT05           ,  -- 5��
																						  AMT06           ,  -- 6��
																						  AMT07           ,  -- 7��
																						  AMT08           ,  -- 8��
																						  AMT09           ,  -- 9��
																						  AMT10           ,  -- 10��
																						  AMT11           ,  -- 11��
																						  AMT12           ,  -- 12��
																						  NOTE            ,  -- ���
																						  MOD_USER_ID     ,  -- ������
																						  MOD_DATE        ,  -- �����Ͻ�
																						  TZ_CD           ,  -- Ÿ�����ڵ�
																						  TZ_DATE            -- Ÿ�����Ͻ�
																						  )
																				   SELECT NEXT VALUE FOR S_PEB_SEQUENCE,  -- �ΰǺ���رݾ�ID
																						  @an_plan_id              ,  -- �ΰǺ��ȹ����ID
																						  '09'                    ,  -- �ΰǺ񱸺�
																						  @OT_ORG_ID             ,  -- �Ҽ�
																						  @OT_TYPE_01_CD         ,  -- �����ڵ�1
																						  @OT_TYPE_02_CD         ,  -- �����ڵ�2
																						  @OT_TYPE_03_CD         ,  -- �����ڵ�3
																						  '3120'                ,  -- �ΰǺ񼼺α���
																						  @n_base_amt              ,  -- ���رݾ�
																						  @BASE_EMP_CNT,  -- �����ο�
																						  dbo.XF_ROUND(@n_base_amt * 8 * @OT_AMT01 * AMT01 * 2 ,0),  -- 1��
																						  dbo.XF_ROUND(@n_base_amt * 8 * @OT_AMT02 * AMT02 * 2 ,0),  -- 2��
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT03 * AMT03 * 2,0),  -- 3��
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT04 * AMT04 * 2,0),  -- 4��
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT05 * AMT05 * 2,0),  -- 5��
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT06 * AMT06 * 2,0),  -- 6��
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT07 * AMT07 * 2,0),  -- 7��
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT08 * AMT08 * 2,0),  -- 8��
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT09 * AMT09 * 2,0),  -- 9��
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT10 * AMT10 * 2,0),  -- 10��
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT11 * AMT11 * 2,0),  -- 11��
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT12 * AMT12 * 2,0),  -- 12��
																						  '(�ñ�['+@n_base_amt+'] + �λ���(3����������)['+@n_base_amt*@BASE_PEB_RATE/100+'])* 8 * �ο� * �����ϼ� * 2 ',
																						  @an_mod_user_id    ,  -- ������
																						  dbo.XF_SYSDATE(0)     ,  -- �����Ͻ�
																						  'KST'             ,  -- Ÿ�����ڵ�
																						  dbo.XF_SYSDATE(0)        -- Ÿ�����Ͻ�
																					 FROM PEB_PLAN
																					WHERE ORG_ID = @OT_ORG_ID
																					  AND PEB_ITEM_TYPE IN ('1120')  -- �����ϼ��� ���� Ư�ټ���
																					  AND PEB_BASE_ID = @PEB_BASE_ID
																	IF @@ERROR <> 0
																		BEGIN
																			SET @av_ret_code    = 'FAILURE!' 
																			SET @av_ret_message = dbo.F_FRM_ERRMSG('���������� �����ϼ��� ���� 2������ 2��, 3������ 3���ΰ�� INSERT�� �����߻�', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
																			RETURN  
																		END
																END
															
															ELSE
															-- �������� 1.5���Ѵ�.
																BEGIN
																	  -- �η°�ȹ INSERT
																	BEGIN
																		INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- �ΰǺ��ȹID
																							  PEB_BASE_ID     ,  -- �ΰǺ��ȹ����ID
																							  PEB_TYPE_CD     ,  -- �ΰǺ񱸺�
																							  ORG_ID          ,  -- �Ҽ�
																							  TYPE_01_CD      ,  -- �����ڵ�1
																							  TYPE_02_CD      ,  -- �����ڵ�2
																							  TYPE_03_CD      ,  -- �����ڵ�3
																							  PEB_ITEM_TYPE   ,  -- �ΰǺ񼼺α���
																							  BASE_AMT        ,  -- ���رݾ�
																							  EMP_CNT         ,  -- �����ο�
																							  AMT01           ,  -- 1��
																							  AMT02           ,  -- 2��
																							  AMT03           ,  -- 3��
																							  AMT04           ,  -- 4��
																							  AMT05           ,  -- 5��
																							  AMT06           ,  -- 6��
																							  AMT07           ,  -- 7��
																							  AMT08           ,  -- 8��
																							  AMT09           ,  -- 9��
																							  AMT10           ,  -- 10��
																							  AMT11           ,  -- 11��
																							  AMT12           ,  -- 12��
																							  NOTE            ,  -- ���
																							  MOD_USER_ID     ,  -- ������
																							  MOD_DATE        ,  -- �����Ͻ�
																							  TZ_CD           ,  -- Ÿ�����ڵ�
																							  TZ_DATE            -- Ÿ�����Ͻ�
																							  )
																					   SELECT NEXT VALUE FOR S_PEB_SEQUENCE,  -- �ΰǺ���رݾ�ID
																							  @an_plan_id              ,  -- �ΰǺ��ȹ����ID
																							  '09'                    ,  -- �ΰǺ񱸺�
																							  @OT_ORG_ID             ,  -- �Ҽ�
																							  @OT_TYPE_01_CD         ,  -- �����ڵ�1
																							  @OT_TYPE_02_CD         ,  -- �����ڵ�2
																							  @OT_TYPE_03_CD         ,  -- �����ڵ�3
																							  '3120'                ,  -- �ΰǺ񼼺α���
																							  @n_base_amt              ,  -- ���رݾ�
																							  @BASE_EMP_CNT,  -- �����ο�
																							  dbo.XF_ROUND(@n_base_amt * 8 * @OT_AMT01 * AMT01 * 1.5 ,0),  -- 1��
																							  dbo.XF_ROUND(@n_base_amt * 8 * @OT_AMT02 * AMT02 * 1.5 ,0),  -- 2��
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT03 * AMT03 * 1.5,0),  -- 3��
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT04 * AMT04 * 1.5,0),  -- 4��
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT05 * AMT05 * 1.5,0),  -- 5��
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT06 * AMT06 * 1.5,0),  -- 6��
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT07 * AMT07 * 1.5,0),  -- 7��
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT08 * AMT08 * 1.5,0),  -- 8��
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT09 * AMT09 * 1.5,0),  -- 9��
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT10 * AMT10 * 1.5,0),  -- 10��
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT11 * AMT11 * 1.5,0),  -- 11��
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT12 * AMT12 * 1.5,0),  -- 12��
																							  '(�ñ�['+@n_base_amt+'] + �λ���(3����������)['+@n_base_amt*@BASE_PEB_RATE/100+']) * 8 * �ο� * �����ϼ� * 1.5',
																							  @an_mod_user_id    ,  -- ������
																							  dbo.XF_SYSDATE(0)     ,  -- �����Ͻ�
																							  'KST'             ,  -- Ÿ�����ڵ�
																							  dbo.XF_SYSDATE(0)        -- Ÿ�����Ͻ�
																						 FROM PEB_PLAN
																						WHERE ORG_ID = @OT_ORG_ID
																						  AND PEB_ITEM_TYPE IN ('1120')  -- �����ϼ��� ���� Ư�ټ���
																						  AND PEB_BASE_ID = @PEB_BASE_ID	
																		IF @@ERROR <> 0
																			BEGIN
																				SET @av_ret_code    = 'FAILURE!' 
																				SET @av_ret_message = dbo.F_FRM_ERRMSG('���������� �����ϼ��� 1.5 INSERT�� �����߻�', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
																				RETURN  
																			END
																	END
																END
														END	

													FETCH NEXT FROM OT INTO @OT_AMT01 , @OT_AMT02, @OT_AMT03, @OT_AMT04, @OT_AMT05, @OT_AMT06, @OT_AMT07, @OT_AMT08, @OT_AMT09, @OT_AMT10, @OT_AMT11, @OT_AMT12, @OT_AVG_AMT, @OT_BASE_AMT,
																	@OT_B_ORG_ID, @OT_EMP_CNT, @OT_ETC_CD1, @OT_ETC_CD2, @OT_G_ORG_ID, @OT_J_AMT, @OT_MOD_DATE, @OT_MOD_USER_ID, @OT_NOTE, @OT_ORG_ID, @OT_PEB_BASE_ID, @OT_PEB_ITEM_TYPE,
																	@OT_PEB_PLAN_ID, @OT_PEB_TYPE_CD, @OT_TYPE_01_CD, @OT_TYPE_02_CD, @OT_TYPE_03_CD	
												END	-- OT WHILE END

											CLOSE OT
											DEALLOCATE OT

										END --
										FETCH NEXT FROM BASE_AMT1 INTO @PEB_RATE_TYPE_CD, @PEB_ITEM_TYPE_CD, @PEB_RATE
								END  -- BASE_AMT1 WHILE END
							CLOSE BASE_AMT1
							DEALLOCATE BASE_AMT1
						END
					FETCH NEXT FROM C1 INTO @BASIC_YY, @COMPANY_CD, @ETC_CD1, @ETC_CD2, @MOD_DATE, @MOD_USER_ID, @NOTE, @PEB_BASE_ID, @STD_YMD, @TZ_CD, @TZ_DATE
				END  -- C1 WHILE BEGIN END

			CLOSE C1
			DEALLOCATE C1
		END -- BEGIN 1 END

		END

	END
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END
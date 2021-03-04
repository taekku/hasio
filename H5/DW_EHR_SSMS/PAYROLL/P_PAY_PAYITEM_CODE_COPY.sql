SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PAY_PAYITEM_CODE_COPY](
    @ad_base_ymd				DATETIME2,
    @av_s_company_cd			NVARCHAR(50),
    @av_s_pay_type_cd			NVARCHAR(50),
    @av_s_salary_type_cd		NVARCHAR(50),
    @av_s_pay_item_cd			NVARCHAR(50),
    @av_t_company_cd			NVARCHAR(50),
    @av_t_pay_type_cd			NVARCHAR(50),
    @av_t_salary_type_cd		NVARCHAR(50),
    @av_t_pay_item_cd			NVARCHAR(50),
    @av_locale_cd				NVARCHAR(50),
    @an_mod_user_id             NUMERIC,         -- ������
    @av_ret_code                NVARCHAR(4000) OUTPUT,       -- SUCCESS!/FAILURE!
    @av_ret_message             NVARCHAR(4000) OUTPUT       -- ����޽���
) AS
    -- ***************************************************************************
    --   TITLE       : �޿����ĺ���
    --   PROJECT     : ���λ������ý���
    --   AUTHOR      : ����
    --   PROGRAM_ID  : P_PAY_PAYITEM_CODE_COPY
    --   RETURN      : 1) SUCCESS!/FAILURE!
    --                 2) ��� �޽���
    --   COMMENT     :
    --   HISTORY     : �ۼ� : 2020.07.29
    -- ***************************************************************************

    /* ���� ���� (�����ڵ� ó���� ���) */
	DECLARE @v_program_id           NVARCHAR(30)
		   ,@v_program_nm           NVARCHAR(100)
		   ,@errornumber         	NUMERIC
           ,@errormessage        	NVARCHAR(4000) 
    
    -- PAY_PAYITEM_CODE cursor ����
    DECLARE  @cur1_AMT_REFER_TYPE			char(1)
			,@cur1_AUTO_COPY_PAY_ITEM_CD	nvarchar(10)
			,@cur1_AUTO_DAY_YN				char(1)
			,@cur1_CD_ORDER					numeric(5, 0)
			,@cur1_COMPANY_CD				nvarchar(10)
			,@cur1_DAY_YN					char(1)
			,@cur1_END_YMD					date
			,@cur1_FOREIGN_YN				char(1)
			,@cur1_LOCALE_CD				nvarchar(10)
			,@cur1_MOD_DATE					date
			,@cur1_MOD_USER_ID				numeric(18, 0)
			,@cur1_NET_YN					char(1)
			,@cur1_NOTE						nvarchar(60)
			,@cur1_ORG_DIV_YN				char(1)
			,@cur1_PAY_DAY_TYPE_CD			nvarchar(10)
			,@cur1_PAY_ITEM_CD				nvarchar(10)
			,@cur1_PAY_PAYITEM_CODE_ID		numeric(18, 0)
			,@cur1_PAY_SINGULAR_TYPE_CD		nvarchar(10)
			,@cur1_PAY_SINGULAR_UNIT_CD		nvarchar(10)
			,@cur1_PAY_TERM_TYPE_CD			nvarchar(10)
			,@cur1_PAY_TYPE_CD				nvarchar(10)
			,@cur1_RETRO_YN					char(1)
			,@cur1_SALARY_TYPE_CD			nvarchar(10)
			,@cur1_STA_YMD					date
			,@cur1_TZ_CD					nvarchar(10)
			,@cur1_TZ_DATE					date
			,@cur1_UNCOND_DEDUCT_YN			char(1)
		   
    -- PAY_CALC_SYNTAX cursor ����
    DECLARE  @cur2_PAY_CALC_SYNTAX_ID		numeric(38, 0)           	
			,@cur2_PAY_PAYITEM_CODE_ID		numeric(38, 0)
			,@cur2_STA_YMD					datetime2
			,@cur2_END_YMD					datetime2
			,@cur2_KOR_SYNTAX				nvarchar(4000)
			,@cur2_MOD_USER_ID				numeric(38, 0)
			,@cur2_MOD_DATE					datetime2
			,@cur2_TZ_CD					nvarchar(50)
			,@cur2_TZ_DATE					datetime2			
		   
    -- PAY_CALC_SYNTAX_MATRIX cursor ����
    DECLARE  @cur3_PAY_CALC_SYNTAX_MATRIX_ID	numeric(38, 0)
			,@cur3_PAY_CALC_SYNTAX_ID			numeric(38, 0)
			,@cur3_PAY_ITEM_CD					nvarchar(50)
			,@cur3_MOD_USER_ID                	numeric(38, 0)
			,@cur3_MOD_DATE						datetime2
			,@cur3_TZ_CD						nvarchar(50)
			,@cur3_TZ_DATE						datetime2	
		   
    -- �������� ����
    DECLARE @n_pay_payitem_code_id  		NUMERIC(38,0)   --PAY_PAYITEM_CODE OID
           ,@n_pay_calc_syntax_id			NUMERIC(38,0)   --PAY_CALC_SYNTAX OID
           ,@n_pay_calc_syntax_matrix_id	NUMERIC(38,0)   --PAY_CALC_SYNTAX_MATRIX OID
	        
BEGIN 	
	/* �⺻���� �ʱⰪ ���� */
    SET @v_program_id    = 'P_PAY_PAYITEM_CODE_COPY'   -- ���� ���ν����� ������
    SET @v_program_nm    = '�޿����ĺ���'              	-- ���� ���ν����� �ѱ۸�

    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = DBO.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null, @an_mod_user_id )
        
	--target PAY_PAYITEM_CODE ���������� ����
	BEGIN
		DELETE FROM PAY_PAYITEM_CODE
		 WHERE COMPANY_CD = @av_t_company_cd
		   AND LOCALE_CD = @av_locale_cd
		   AND PAY_TYPE_CD = @av_t_pay_type_cd
		   AND (@av_t_salary_type_cd IS NULL OR SALARY_TYPE_CD = @av_t_salary_type_cd)
		   AND (@av_t_pay_item_cd IS NULL OR PAY_ITEM_CD = @av_t_pay_item_cd)
		   --AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD --������ �����Ͽ� ���ԵǴ°͸� ����� �̻��� �ȸ��� �� �����Ƿ� �ش� �̷±��� �����ؼ� �� ������.
		IF @@ERROR <> 0
			BEGIN
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = dbo.F_FRM_ERRMSG('PAY_PAYITEM_CODE ���� ������ ���� �� ���� �߻�',
													@v_program_id , 0030 , ERROR_MESSAGE() ,  1
												)
				ROLLBACK
				RETURN
			END
	END	
		
	--target PAY_CALC_SYNTAX ���������� ����
	BEGIN
		DELETE FROM PAY_CALC_SYNTAX
		 --WHERE (PAY_PAYITEM_CODE_ID, STA_YMD) IN (SELECT PAY_PAYITEM_CODE_ID, STA_YMD
		 WHERE PAY_PAYITEM_CODE_ID IN (SELECT PAY_PAYITEM_CODE_ID
				 								    FROM PAY_PAYITEM_CODE
											  	   WHERE COMPANY_CD = @av_t_company_cd
												     AND LOCALE_CD = @av_locale_cd
												     AND PAY_TYPE_CD = @av_t_pay_type_cd
												     AND (@av_t_salary_type_cd IS NULL OR SALARY_TYPE_CD = @av_t_salary_type_cd)
												     AND (@av_t_pay_item_cd IS NULL OR PAY_ITEM_CD = @av_t_pay_item_cd)
												 )
		IF @@ERROR <> 0
			BEGIN
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = dbo.F_FRM_ERRMSG('PAY_CALC_SYNTAX ���� ������ ���� �� ���� �߻�',
													@v_program_id , 0030 , ERROR_MESSAGE() ,  1
												)
				IF @@TRANCOUNT > 0
				   ROLLBACK WORK
				RETURN
			END
	END
	
	--target PAY_CALC_SYNTAX_MATRIX ���������� ����
	BEGIN
		DELETE FROM PAY_CALC_SYNTAX_MATRIX
		--WHERE (PAY_CALC_SYNTAX_ID, PAY_ITEM_CD) IN (SELECT PAY_CALC_SYNTAX_ID, PAY_ITEM_CD 
		WHERE PAY_CALC_SYNTAX_ID IN (SELECT PAY_CALC_SYNTAX_ID
									  FROM PAY_CALC_SYNTAX
									 --WHERE (PAY_PAYITEM_CODE_ID, STA_YMD) IN (SELECT PAY_PAYITEM_CODE_ID, STA_YMD
									 WHERE PAY_PAYITEM_CODE_ID IN (SELECT PAY_PAYITEM_CODE_ID
								 								    FROM PAY_PAYITEM_CODE
															  	   WHERE COMPANY_CD = @av_t_company_cd
																     AND LOCALE_CD = @av_locale_cd
																     AND PAY_TYPE_CD = @av_t_pay_type_cd
																     AND (@av_t_salary_type_cd IS NULL OR SALARY_TYPE_CD = @av_t_salary_type_cd)
																     AND (@av_t_pay_item_cd IS NULL OR PAY_ITEM_CD = @av_t_pay_item_cd)
																 )
								   )
		IF @@ERROR <> 0
			BEGIN
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = dbo.F_FRM_ERRMSG('PAY_CALC_SYNTAX ���� ������ ���� �� ���� �߻�',
													@v_program_id , 0030 , ERROR_MESSAGE() ,  1
												)
				IF @@TRANCOUNT > 0
				   ROLLBACK WORK
				RETURN
			END
	END
			
	-- 1. PAY_PAYITEM_CODE ����.		
    DECLARE cur1 CURSOR LOCAL FOR 
            SELECT AMT_REFER_TYPE				
					,AUTO_COPY_PAY_ITEM_CD			
					,AUTO_DAY_YN					
					,CD_ORDER						
					,COMPANY_CD		
					,DAY_YN				
					,END_YMD				
					,FOREIGN_YN		
					,LOCALE_CD			
					,MOD_DATE			
					,MOD_USER_ID		
					,NET_YN				
					,NOTE					
					,ORG_DIV_YN		
					,PAY_DAY_TYPE_CD	
					,PAY_ITEM_CD			
					,PAY_PAYITEM_CODE_ID	
					,PAY_SINGULAR_TYPE_CD
					,PAY_SINGULAR_UNIT_CD
					,PAY_TERM_TYPE_CD
					,PAY_TYPE_CD			
					,RETRO_YN				
					,SALARY_TYPE_CD	
					,STA_YMD					
					,TZ_CD						
					,TZ_DATE					
					,UNCOND_DEDUCT_YN
			FROM PAY_PAYITEM_CODE
		 WHERE COMPANY_CD = @av_s_company_cd
		   AND LOCALE_CD = @av_locale_cd
		   AND PAY_TYPE_CD = @av_s_pay_type_cd
		   AND SALARY_TYPE_CD = @av_s_salary_type_cd
		   AND (@av_s_pay_item_cd IS NULL OR PAY_ITEM_CD = @av_s_pay_item_cd)
		   AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD
	OPEN cur1
	
	FETCH NEXT FROM cur1 INTO    @cur1_AMT_REFER_TYPE					
								,@cur1_AUTO_COPY_PAY_ITEM_CD		
								,@cur1_AUTO_DAY_YN			
								,@cur1_CD_ORDER				
								,@cur1_COMPANY_CD			
								,@cur1_DAY_YN					
								,@cur1_END_YMD					
								,@cur1_FOREIGN_YN			
								,@cur1_LOCALE_CD				
								,@cur1_MOD_DATE				
								,@cur1_MOD_USER_ID			
								,@cur1_NET_YN					
								,@cur1_NOTE						
								,@cur1_ORG_DIV_YN			
								,@cur1_PAY_DAY_TYPE_CD	
								,@cur1_PAY_ITEM_CD			
								,@cur1_PAY_PAYITEM_CODE_ID	
								,@cur1_PAY_SINGULAR_TYPE_CD
								,@cur1_PAY_SINGULAR_UNIT_CD
								,@cur1_PAY_TERM_TYPE_CD		
								,@cur1_PAY_TYPE_CD			
								,@cur1_RETRO_YN				
								,@cur1_SALARY_TYPE_CD	
								,@cur1_STA_YMD					
								,@cur1_TZ_CD						
								,@cur1_TZ_DATE					
								,@cur1_UNCOND_DEDUCT_YN

	--PRINT(ERROR_MESSAGE())
	--PRINT('@@FETCH_STATUS' + dbo.xf_to_char_n(@@FETCH_STATUS,null))
	WHILE @@FETCH_STATUS = 0
	
	BEGIN
		--target PAY_PAYITEM_CODE oid ����
		BEGIN		
			SELECT @n_pay_payitem_code_id = NEXT VALUE FOR dbo.S_PAY_SEQUENCE FROM DUAL
		END
		
        BEGIN
            INSERT INTO PAY_PAYITEM_CODE (
                     AMT_REFER_TYPE					
					,AUTO_COPY_PAY_ITEM_CD		
					,AUTO_DAY_YN			
					,CD_ORDER				
					,COMPANY_CD			
					,DAY_YN					
					,END_YMD					
					,FOREIGN_YN			
					,LOCALE_CD				
					,MOD_DATE				
					,MOD_USER_ID			
					,NET_YN					
					,NOTE						
					,ORG_DIV_YN			
					,PAY_DAY_TYPE_CD	
					,PAY_ITEM_CD			
					,PAY_PAYITEM_CODE_ID	
					,PAY_SINGULAR_TYPE_CD
					,PAY_SINGULAR_UNIT_CD
					,PAY_TERM_TYPE_CD		
					,PAY_TYPE_CD			
					,RETRO_YN				
					,SALARY_TYPE_CD	
					,STA_YMD					
					,TZ_CD						
					,TZ_DATE					
					,UNCOND_DEDUCT_YN
           ) VALUES (
           			 @cur1_AMT_REFER_TYPE					
					,@cur1_AUTO_COPY_PAY_ITEM_CD		
					,@cur1_AUTO_DAY_YN			
					,@cur1_CD_ORDER				
					,@av_t_company_cd		
					,@cur1_DAY_YN					
					,@cur1_END_YMD					
					,@cur1_FOREIGN_YN			
					,@av_locale_cd		
					,GETDATE()			
					,@an_mod_user_id	
					,@cur1_NET_YN					
					,@cur1_NOTE						
					,@cur1_ORG_DIV_YN			
					,@cur1_PAY_DAY_TYPE_CD	
					--,@av_t_pay_item_cd		
					,CASE WHEN @av_t_pay_item_cd IS NULL THEN @cur1_PAY_ITEM_CD ELSE @av_t_pay_item_cd END
					,@n_pay_payitem_code_id	
					,@cur1_PAY_SINGULAR_TYPE_CD
					,@cur1_PAY_SINGULAR_UNIT_CD
					,@cur1_PAY_TERM_TYPE_CD		
					,@av_t_pay_type_cd		
					,@cur1_RETRO_YN				
					--,@av_t_salary_type_cd
					,CASE WHEN @av_t_salary_type_cd IS NULL THEN @cur1_SALARY_TYPE_CD ELSE @av_t_salary_type_cd END
					,@cur1_STA_YMD					
					,'KST'					
					,GETDATE()				
					,@cur1_UNCOND_DEDUCT_YN
					)
			IF @@ERROR <> 0
				BEGIN
					SET @av_ret_code    = 'FAILURE!'
					SET @av_ret_message = dbo.F_FRM_ERRMSG('PAY_PAYITEM_CODE ���� �� ���� �߻�',
													 @v_program_id , 0030 , ERROR_MESSAGE() ,  1
													)
					ROLLBACK
					RETURN
				END
		END
				
			
		-------------------------------
		-- 2. PAY_CALC_SYNTAX ���� START.	
		-------------------------------
		
	    DECLARE cur2 CURSOR LOCAL FOR 
	    		SELECT PAY_CALC_SYNTAX_ID
						,PAY_PAYITEM_CODE_ID
						,STA_YMD																		
						,END_YMD																		
						,KOR_SYNTAX																		
						,MOD_USER_ID																		
						,MOD_DATE																		
						,TZ_CD																												
						,TZ_DATE
			  FROM PAY_CALC_SYNTAX		
			 WHERE PAY_PAYITEM_CODE_ID = @cur1_PAY_PAYITEM_CODE_ID
			   --AND STA_YMD = @cur1_STA_YMD
		OPEN cur2
		
		FETCH NEXT FROM cur2 INTO    @cur2_PAY_CALC_SYNTAX_ID  	
									,@cur2_PAY_PAYITEM_CODE_ID
									,@cur2_STA_YMD
									,@cur2_END_YMD
									,@cur2_KOR_SYNTAX
									,@cur2_MOD_USER_ID
									,@cur2_MOD_DATE
									,@cur2_TZ_CD
									,@cur2_TZ_DATE
	
		--PRINT(ERROR_MESSAGE())
		--PRINT('@@FETCH_STATUS' + dbo.xf_to_char_n(@@FETCH_STATUS,null))
		WHILE @@FETCH_STATUS = 0
	
			BEGIN
				
				--target PAY_CALC_SYNTAX oid ����
				BEGIN		
					SELECT @n_pay_calc_syntax_id = NEXT VALUE FOR dbo.S_PAY_SEQUENCE FROM DUAL
				END
				
		        BEGIN
		            INSERT INTO PAY_CALC_SYNTAX (
		                     PAY_CALC_SYNTAX_ID
							,PAY_PAYITEM_CODE_ID
							,STA_YMD																		
							,END_YMD																		
							,KOR_SYNTAX																		
							,MOD_USER_ID																		
							,MOD_DATE																		
							,TZ_CD																												
							,TZ_DATE
		           ) VALUES (
		           			 @n_pay_calc_syntax_id				
							,@n_pay_payitem_code_id
							,@cur2_STA_YMD
							,@cur2_END_YMD
							,@cur2_KOR_SYNTAX
							,@cur2_MOD_USER_ID
							,@cur2_MOD_DATE
							,@cur2_TZ_CD
							,@cur2_TZ_DATE
							)
					IF @@ERROR <> 0
						BEGIN
							SET @av_ret_code    = 'FAILURE!'
							SET @av_ret_message = dbo.F_FRM_ERRMSG('PAY_CALC_SYNTAX ���� �� ���� �߻�',
															 @v_program_id , 0030 , ERROR_MESSAGE() ,  1
															)
							ROLLBACK
							RETURN
						END
				END
				
				
				-------------------------------
				-- 3. PAY_CALC_SYNTAX_MATRIX ���� START.	
				-------------------------------		
				
			    DECLARE cur3 CURSOR LOCAL FOR 
			    		SELECT PAY_CALC_SYNTAX_MATRIX_ID
						      ,PAY_CALC_SYNTAX_ID
							  ,PAY_ITEM_CD
							  ,MOD_USER_ID
							  ,MOD_DATE
							  ,TZ_CD
							  ,TZ_DATE			
						  FROM PAY_CALC_SYNTAX_MATRIX
					     WHERE PAY_CALC_SYNTAX_ID = @cur2_PAY_CALC_SYNTAX_ID
				OPEN cur3
				
				FETCH NEXT FROM cur3 INTO    @cur3_PAY_CALC_SYNTAX_MATRIX_ID
											,@cur3_PAY_CALC_SYNTAX_ID
											,@cur3_PAY_ITEM_CD
											,@cur3_MOD_USER_ID
											,@cur3_MOD_DATE
											,@cur3_TZ_CD
											,@cur3_TZ_DATE
			
				--PRINT(ERROR_MESSAGE())
				--PRINT('@@FETCH_STATUS' + dbo.xf_to_char_n(@@FETCH_STATUS,null))
				WHILE @@FETCH_STATUS = 0
			
					BEGIN
						--target PAY_CALC_SYNTAX oid ����
						BEGIN		
							SELECT @n_pay_calc_syntax_matrix_id = NEXT VALUE FOR dbo.S_PAY_SEQUENCE FROM DUAL
						END
						
				        BEGIN
				            INSERT INTO PAY_CALC_SYNTAX_MATRIX (
				                     PAY_CALC_SYNTAX_MATRIX_ID
									,PAY_CALC_SYNTAX_ID
									,PAY_ITEM_CD
									,MOD_USER_ID
									,MOD_DATE
									,TZ_CD
									,TZ_DATE	
				           ) VALUES (
				           			 @n_pay_calc_syntax_matrix_id				
									,@n_pay_calc_syntax_id
									,@cur3_PAY_ITEM_CD
									,@cur3_MOD_USER_ID
									,@cur3_MOD_DATE
									,@cur3_TZ_CD
									,@cur3_TZ_DATE
									)
							IF @@ERROR <> 0
								BEGIN
									SET @av_ret_code    = 'FAILURE!'
									SET @av_ret_message = dbo.F_FRM_ERRMSG('PAY_CALC_SYNTAX_MATRIX ���� �� ���� �߻�',
																	 @v_program_id , 0030 , ERROR_MESSAGE() ,  1
																	)
									ROLLBACK
									RETURN
								END
						END
				
						FETCH NEXT FROM cur3 INTO  @cur3_PAY_CALC_SYNTAX_MATRIX_ID
												,@cur3_PAY_CALC_SYNTAX_ID
												,@cur3_PAY_ITEM_CD
												,@cur3_MOD_USER_ID
												,@cur3_MOD_DATE
												,@cur3_TZ_CD
												,@cur3_TZ_DATE
					END --while
							
					CLOSE cur3
					DEALLOCATE cur3
				-------------------------------
				-- 3. PAY_CALC_SYNTAX_MATRIX ���� END.
				-------------------------------
		
				FETCH NEXT FROM cur2 INTO  @cur2_PAY_CALC_SYNTAX_ID  	
										,@cur2_PAY_PAYITEM_CODE_ID
										,@cur2_STA_YMD
										,@cur2_END_YMD
										,@cur2_KOR_SYNTAX
										,@cur2_MOD_USER_ID
										,@cur2_MOD_DATE
										,@cur2_TZ_CD
										,@cur2_TZ_DATE
			END --while
					
			CLOSE cur2
			DEALLOCATE cur2
		-------------------------------
		-- 2. PAY_CALC_SYNTAX ���� END.
		-------------------------------
					
			
		FETCH NEXT FROM cur1 INTO @cur1_AMT_REFER_TYPE					
								,@cur1_AUTO_COPY_PAY_ITEM_CD		
								,@cur1_AUTO_DAY_YN			
								,@cur1_CD_ORDER				
								,@cur1_COMPANY_CD			
								,@cur1_DAY_YN					
								,@cur1_END_YMD					
								,@cur1_FOREIGN_YN			
								,@cur1_LOCALE_CD				
								,@cur1_MOD_DATE				
								,@cur1_MOD_USER_ID			
								,@cur1_NET_YN					
								,@cur1_NOTE						
								,@cur1_ORG_DIV_YN			
								,@cur1_PAY_DAY_TYPE_CD	
								,@cur1_PAY_ITEM_CD			
								,@cur1_PAY_PAYITEM_CODE_ID	
								,@cur1_PAY_SINGULAR_TYPE_CD
								,@cur1_PAY_SINGULAR_UNIT_CD
								,@cur1_PAY_TERM_TYPE_CD		
								,@cur1_PAY_TYPE_CD			
								,@cur1_RETRO_YN				
								,@cur1_SALARY_TYPE_CD	
								,@cur1_STA_YMD					
								,@cur1_TZ_CD						
								,@cur1_TZ_DATE					
								,@cur1_UNCOND_DEDUCT_YN
	END --while
			
	CLOSE cur1
	DEALLOCATE cur1
												 
    -- ***********************************************************
    -- �۾� �Ϸ�
    -- ***********************************************************
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = '�޿����ĺ��� �Ϸ�' --���ν��� ���� �Ϸ�'
    --SET @av_ret_message = '����Ǿ����ϴ�.' --���ν��� ���� �Ϸ�'

END --��

GO



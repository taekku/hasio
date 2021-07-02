SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_TBS_DEBIS_WITHHOLD](
		@av_company_cd			NVARCHAR(10),   -- ȸ���ڵ�
		@av_hrtype_cd			NVARCHAR(10),	-- �η�����
		@av_tax_kind_cd			NVARCHAR(10),	-- ��õ������ (�޿� : A1, �� : B1, �������� : E1, �������� : C1 ,�ߵ����� : D1)
		@av_close_ym			NVARCHAR(10),	-- �������
		@ad_proc_date			DATE,			-- ó������
		@an_emp_id				NUMERIC(38),	-- ó����
		@av_locale_cd			NVARCHAR(10),
		@av_tz_cd				NVARCHAR(10),    -- Ÿ�����ڵ�
		@an_mod_user_id			NUMERIC(18,0)  ,    -- ������ ID
		@av_ret_code			NVARCHAR(100)    OUTPUT,
		@av_ret_message			NVARCHAR(500)    OUTPUT
		)
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : ��õ������ - DEBIS
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_TBS_DEBIS_WITHHOLD
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - 
    --<DOCLINE>   HISTORY     : �ۼ� 2020.11.04
    --<DOCLINE> ***************************************************************************
SET NOCOUNT ON

DECLARE
	-- ��� ��������
	@v_emp_no					varchar(10),		 -- �۾��ڻ��
	@V_CO_CD                    VARCHAR(3),          -- ����ȸ���ڵ�
	@V_CLOSE_YM					VARCHAR(6),			 -- �������
	@V_YYYYMM   			    VARCHAR(6),			 -- ó�����
	@V_ACCT_DEPT_CD				VARCHAR(5),			 -- �ͼӺμ��ڵ�
	@V_WITHHOLD_CLS_CD			VARCHAR(2),			 -- ��õ�������ڵ�
	@V_PAY_DT				    VARCHAR(8),			 -- ��������
	@V_STAFF				    NUMERIC(5,0),		 -- �ο�
	@V_TOT_AMT					NUMERIC(20,0),		 -- �ѱݾ�
	@V_TAXN_AMT					NUMERIC(20,0),		 --	�����ݾ�
	@V_INCOME_TAX			    NUMERIC(20,0),		 --	�ҵ漼
	@V_MAN_TAX					NUMERIC(20,0),		 -- �ֹμ�
	@V_REPLY_CLS_CD				VARCHAR(1),			 --	���䱸���ڵ�
	@V_PROC_YN					NUMERIC(1,0),		 -- ó������
	@V_REG_ID					VARCHAR(8),			 -- �����ID
	@V_REG_DTM					DATETIME,			 -- ����Ͻ�
	@V_MOD_ID					VARCHAR(8),			 --	������ID
	@V_MOD_DTM					DATETIME,		     -- �����Ͻ�
	@V_PROC_CNT					NUMERIC(10,0),		 -- ó����

	@V_WITHHOLDING_ID			NUMERIC(10,0),		 -- ID       
	@V_DEPT_TYPE				VARCHAR(20),         -- ���籸��
	@V_WORK_SITE_CD				VARCHAR(10),          --  �ٹ���
	@V_COSTDPT_CD				VARCHAR(20),         -- �����μ�
	@V_SABUN_CNT				NUMERIC(10,0),        -- ���ο�
	@V_AOLWTOT_AMT				NUMERIC(20,0),       -- �޿��Ѿ�
	@V_TAXFREEALOW				NUMERIC(20,0),       -- �����
	@V_INCTAX					NUMERIC(20,0),       -- �ҵ漼
	@V_INGTAX					NUMERIC(20,0),       -- �ֹμ�
	@V_INCTAX_OLD				NUMERIC(20,0),       -- �ҵ漼
	@V_INGTAX_OLD				NUMERIC(20,0),       -- �ֹμ�  

	@V_CNT						NUMERIC(10,0),        -- ó���Ǽ�
	@V_USER1					VARCHAR(20),         -- �����μ������ڵ�
	@V_PAY_CD					VARCHAR(10),         -- �޿��ڵ�
	@V_PAY_CD1					VARCHAR(10),         -- �޿��ڵ�  
	
	@V_CNT_DUP                  NUMERIC(10),
	@OPENQUERY					nvarchar(4000), 
	@TSQL						nvarchar(4000), 
	@LinkedServer				nvarchar(20) = 'DEBIS',
	--@LinkedServer				nvarchar(20) = 'DEBIS_DEV',
	
	/* BEGIN CATCH ����� ���� ����  */
	@v_error_number				INT,
	@v_error_severity			INT,
	@v_error_state				INT,
	@v_error_procedure			VARCHAR(1000),
	@v_error_line				INT,
	@v_error_message			VARCHAR(3000),

	/* ERR_HANDLER ����� ���� ���� */
	@v_error_num			    INT,
	@v_row_count				INT,
	@v_error_code				VARCHAR(1000),										-- �����ڵ�
	@v_error_note				VARCHAR(3000)										-- ������Ʈ (exec : '���ڿ�A|���ڿ�B')

/* �⺻������ ���Ǵ� ���� */
DECLARE @v_program_id		NVARCHAR(30)
      , @v_program_nm		NVARCHAR(100)
      , @v_ret_code			NVARCHAR(100)
      , @v_ret_message		NVARCHAR(500)
    SET @v_program_id   = 'P_TBS_DEBIS_WITHHOLD'
    SET @v_program_nm   = 'DEBIS��õ������'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
	SELECT @v_emp_no = EMP_NO
	  FROM PHM_EMP
	 WHERE EMP_ID = @an_emp_id

    print('�η����� ���� ��' + ISNULL(@v_emp_no,''))
    -- �η������� �����ϴ� ����ȸ���ڵ�
	BEGIN
		SELECT @V_CO_CD = dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, 'KO', 'PAY', 'PAY_PBT_HRTYPE',
                              NULL, NULL, NULL, NULL, NULL,
                              @av_hrtype_cd, NULL, NULL, NULL, NULL,
                              @ad_proc_date,
                              'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,    'H3' :  �ڵ�3,    'H4' : �ڵ�4,    'H5' : �ڵ�5
							       -- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
                              )
    END
    print('�η����� ���� ��:' + @V_CO_CD)
	-- �������
    SET @V_CLOSE_YM = @av_close_ym

	--�ڵ屸��( �������� : E1) ���� 12��
    IF @av_tax_kind_cd = 'E1'
		BEGIN
			IF SUBSTRING(@V_CLOSE_YM,5,2) <> '02'  --2���� �ƴϸ� ����
				BEGIN
					SET @av_ret_code = 'FAILURE!';
					SET @av_ret_message = dbo.F_FRM_ERRMSG('���������� ��������� Ȯ���ϼ���.(2)' + '[ERR]',
													@v_program_id,  0901,  NULL, NULL)
					RETURN
				END
        END

    print('CNT_PROC ���� ��')
	PRINT('@V_CLOSE_YM : ' + @V_CLOSE_YM)
	PRINT('@V_CO_CD : ' + @V_CO_CD)
    SET @V_PROC_CNT = 0; 
  ----  BEGIN
		----SET @OPENQUERY = 'SELECT @V_PROC_CNT = CNT_PROC FROM OPENQUERY('+ @LinkedServer + ','''
		----SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_PROC FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
		----SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
		----SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
		----SET @OPENQUERY = @OPENQUERY + '   AND (PROC_YN = 1 OR REPLY_CLS_CD <> ''''D''''))'') '
		
		----PRINT @OPENQUERY

		------ ������
		----EXEC sp_executesql @OPENQUERY, N'@V_PROC_CNT NUMERIC(5) OUTPUT', @V_PROC_CNT output
   
		----IF @V_PROC_CNT > 0
		----	BEGIN
		----		SET @p_error_str = 'ERROR';
		----			GOTO ERR_HANDLER
		----	END
  ----  END 
    print('CNT_PROC ���� ��')

    --�ڵ屸��(�޿� : A1) �������������
	IF @av_tax_kind_cd = 'A1'
		BEGIN
			IF @av_company_cd = 'B'
				BEGIN
					SET @V_YYYYMM = @V_CLOSE_YM;
				END
			ELSE
				BEGIN
					--IF (SUBSTRING(@P_PROC_DATE,7,2) in ( '25'))
					IF (dbo.XF_TO_CHAR_D(@ad_proc_date, 'dd') in ( '25'))
						BEGIN
							SET @V_YYYYMM = @V_CLOSE_YM;
						END
					ELSE
						BEGIN
							-- TO_CHAR(ADD_MONTHS(TO_DATE(V_CLOSE_YM,'YYYYMM'),-1),'YYYYMM'); 
							SET @V_YYYYMM = SUBSTRING(CONVERT(VARCHAR(10), DATEADD(MONTH, -1, CONVERT(DATETIME, @V_CLOSE_YM + '01', 112)), 112), 1, 6)
							PRINT ('@V_YYYYMM = ' + @V_YYYYMM);
						END
				END
       END
    --�ڵ屸��( �� : B1) �������������
    IF @av_tax_kind_cd = 'B1'
		BEGIN
			SET @V_YYYYMM = @V_CLOSE_YM;
        END
    --�ڵ屸��( �������� : E1) ���� 12��
    IF @av_tax_kind_cd = 'E1'
		BEGIN
			SET @V_YYYYMM = SUBSTRING(CONVERT(VARCHAR(10), DATEADD(MONTH, -12, CONVERT(DATETIME, @V_CLOSE_YM + '01', 112)), 112), 1, 4) + '12'
		END
    --�ڵ屸��( �������� : C1 ) ��������������� ��ǥ�������
    IF @av_tax_kind_cd = 'C1'
		BEGIN
			SET @V_YYYYMM = @V_CLOSE_YM; 
		END
    --�ڵ屸��(�ߵ����� : D1)  �������������
    IF @av_tax_kind_cd = 'D1' OR @av_tax_kind_cd = 'P1'
		BEGIN
			SET @V_YYYYMM = @V_CLOSE_YM;
			
		END 
    
    --�ڵ屸��
    SET @V_WITHHOLD_CLS_CD = @av_tax_kind_cd;
    
    print('�ڵ屸�� ���� ��')
    PRINT(@av_tax_kind_cd)
	IF @av_tax_kind_cd = 'A1'
		BEGIN
        -- �޿�
			IF @av_company_cd = 'B'
				BEGIN
					SET @V_PAY_CD = '002';  --�޿�
					SET @V_PAY_CD1 = '002';  --�ұ޾�
					SET @V_WITHHOLD_CLS_CD = 'A1';  --�繫���޿�
					print(@V_PAY_CD + ', ' + @V_PAY_CD1 + ', ' + @V_WITHHOLD_CLS_CD)
				END
			ELSE

			BEGIN
				--IF (SUBSTRING(@P_PROC_DATE,7,2) in ( '25'))
				IF dbo.XF_TO_CHAR_D(@ad_proc_date,'dd') in ('25')
					BEGIN
						SET @V_PAY_CD = '03';  --�޿�
						SET @V_PAY_CD1 = '04';  --�ұ޾�
						SET @V_WITHHOLD_CLS_CD = 'A2';  --�繫���޿�
						print(@V_PAY_CD + ', ' + @V_PAY_CD1 + ', ' + @V_WITHHOLD_CLS_CD)
					END
				ELSE
					BEGIN
						SET @V_PAY_CD = '01';  --�޿�
						SET @V_PAY_CD1 = 'XXXXX';  --�ұ޾�
					END
			END
			
			BEGIN
				PRINT('DELETE���� ���� ��')
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''' AND (PROC_YN = 1 OR REPLY_CLS_CD <> ''''D''''))'') '
				
				PRINT(@OPENQUERY)
				exec (@OPENQUERY)
				PRINT('DELETE���� ���� ��')
			END
	        
	        PRINT('Ŀ������ ��')
	        PRINT('@av_company_cd : ' + @av_company_cd)
	        PRINT('@av_hrtype_cd : ' + @av_hrtype_cd)
	        PRINT('@V_YYYYMM : ' + @V_YYYYMM)
	        PRINT('@V_PAY_CD : ' + @V_PAY_CD)
	        PRINT('@V_PAY_CD : ' + @V_PAY_CD1)
			PRINT('@ad_proc_date : ' + dbo.XF_TO_CHAR_D(@ad_proc_date,'yyyyMMdd'))
	        
	        DECLARE C_PBT_WITHHOOD_E CURSOR FOR                       -- ��õ������ �����͸� �����´�. 
			SELECT A.RES_BIZ_CD                                       -- ����� - �ٹ��� 
				  ,ISNULL(MAPCOSTDPT_CD,'XXXXX')  MAPCOSTDPT_CD       -- �����μ�
				  ,COUNT(DISTINCT(A.EMP_ID)) AS SABUN_CNT             -- ���ο�
				  ,SUM(A.PSUM) AS AOLWTOT_AMT                         -- �޿��Ѿ�
				  ,SUM(A.C001_AMT) AS TAXFREEALOW                     -- �����
				  ,SUM(A.D001_AMT) AS INCTAX                          -- �ҵ漼
				  ,SUM(A.D002_AMT) AS INGTAX						  -- �ֹμ�
			  FROM (
					SELECT PAY.RES_BIZ_CD
						 , PRI.FROM_TYPE_CD 
						 , PAY.ACC_CD COST_CD
						 , PAY.EMP_ID
						 , PAY.PSUM
						 , (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD=YMD.COMPANY_CD AND COST_CD = PAY.ACC_CD AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD ) AS MAPCOSTDPT_CD
						 , D001_AMT -- ���ټ�
						 , D002_AMT -- �ֹμ�
						 , C001_AMT -- �����
					  FROM PAY_PAY_YMD YMD
					  JOIN PAY_PAYROLL PAY
						ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
					  JOIN PHM_PRIVATE PRI
						ON PAY.EMP_ID = PRI.EMP_ID
					  JOIN ORM_COST COST
						ON PAY.ACC_CD = COST.COST_CD
					   AND YMD.COMPANY_CD = COST.COMPANY_CD
					   AND YMD.PAY_YMD BETWEEN COST.STA_YMD AND COST.END_YMD
					  LEFT OUTER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) D001_AMT FROM PAY_PAYROLL_DETAIL DTL WHERE DTL.PAY_ITEM_CD='D001' GROUP BY PAY_PAYROLL_ID) DTL_D
						ON PAY.PAY_PAYROLL_ID = DTL_D.PAY_PAYROLL_ID
					  LEFT OUTER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) D002_AMT FROM PAY_PAYROLL_DETAIL DTL WHERE DTL.PAY_ITEM_CD='D002' GROUP BY PAY_PAYROLL_ID) DTL_D2
						ON PAY.PAY_PAYROLL_ID = DTL_D2.PAY_PAYROLL_ID
										-- C001	�Ĵ�����	AMT_TAX_EXEMPTION2	������ݾ�(�Ĵ�)
										-- C002	��������	AMT_TAX_EXEMPTION1	������ݾ�(����)
										-- C003	���������	AMT_TAX_EXEMPTION3	������ݾ�(��Ÿ)
										-- C004	���ܱٷκ����	AMT_TAX_EXEMPTION4	������ݾ�(���ܱٷ�)
					  LEFT OUTER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) C001_AMT FROM PAY_PAYROLL_DETAIL DTL WHERE DTL.PAY_ITEM_CD IN('C001','C002','C003','C004') GROUP BY PAY_PAYROLL_ID) DTL_D3
						ON PAY.PAY_PAYROLL_ID = DTL_D3.PAY_PAYROLL_ID
					 WHERE YMD.COMPANY_CD = @av_company_cd
					   AND YMD.PAY_YM = @v_yyyymm
					   AND PRI.FROM_TYPE_CD = @av_hrtype_cd
					   AND YMD.PAY_TYPE_CD IN (
												SELECT CD
												  FROM FRM_CODE
												 WHERE COMPANY_CD=@av_company_cd
												   AND CD_KIND = 'PAY_TYPE_CD'
												   AND SYS_CD IN (
														SELECT HIS.KEY_CD1 AS CD
														  FROM FRM_UNIT_STD_HIS HIS
																   , FRM_UNIT_STD_MGR MGR
														 WHERE HIS.FRM_UNIT_STD_MGR_ID = MGR.FRM_UNIT_STD_MGR_ID
														   AND MGR.UNIT_CD = 'TBS'
														   AND MGR.STD_KIND = 'TBS_DEBIS_PAY'
															  AND MGR.COMPANY_CD = @av_company_cd
														   AND MGR.LOCALE_CD = @av_locale_cd
														   AND HIS.CD1=@av_tax_kind_cd
														   AND dbo.XF_SYSDATE(0) BETWEEN HIS.STA_YMD AND HIS.END_YMD
														   )
												   )
					) A
			 GROUP BY A.RES_BIZ_CD		-- ����� - �ٹ��� 
					 ,MAPCOSTDPT_CD		-- �����μ�
			 ORDER BY RES_BIZ_CD		-- ����� - �ٹ��� 
					 ,MAPCOSTDPT_CD;	-- �����μ�  

			OPEN C_PBT_WITHHOOD_E  -- Ŀ�� ��ġ
			FETCH NEXT FROM C_PBT_WITHHOOD_E INTO   @V_WORK_SITE_CD,
													 @V_COSTDPT_CD,
													 @V_SABUN_CNT,
													 @V_AOLWTOT_AMT,
													 @V_TAXFREEALOW,
													 @V_INCTAX,
													 @V_INGTAX
			WHILE	@@fetch_status = 0
			BEGIN
				
				PRINT ('Ŀ������')
				PRINT(@@ROWCOUNT)
				
				--IF(@@ROWCOUNT < 1)
				--	BEGIN
				--		GOTO ERR_HANDLER
				--	END
	            
				-- ó���Ǽ�
				SET @V_CNT = @V_CNT +1;
	            
				-- �����μ�
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
	            
				-- �������� 
				SET @V_PAY_DT = dbo.XF_TO_CHAR_D( @ad_proc_date, 'yyyyMMdd')
				-- ���ο�
				SET @V_STAFF = @V_SABUN_CNT;
				-- �޿��Ѿ�
				SET @V_TOT_AMT = @V_AOLWTOT_AMT;
				-- �����(������� ������ ��ȯ)
				SET @V_TAXN_AMT = @V_AOLWTOT_AMT - @V_TAXFREEALOW;
				-- �������ҵ漼
				SET @V_INCOME_TAX = @V_INCTAX;
				-- �������ֹμ�
				SET @V_MAN_TAX = @V_INGTAX;
	            
	            PRINT('�ߺ�üũ ��')
				BEGIN
					SET @V_CNT_DUP = 0;
					SET @OPENQUERY = 'SELECT @V_CNT_DUP = CNT_DUP FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_DUP FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND PAY_DT = ''''' + @V_PAY_DT + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WORK_SITE_CD =  ''''' + @V_WORK_SITE_CD + ''''''') '
					EXEC sp_executesql @OPENQUERY, N'@V_CNT_DUP NUMERIC(3) OUTPUT', @V_CNT_DUP output
					PRINT(@OPENQUERY)
					PRINT('�ߺ�üũ ��')
					PRINT('@V_CNT_DUP : ' + CAST(@V_CNT_DUP AS VARCHAR))
					IF @V_CNT_DUP > 0 -- �ߺ�, ������Ʈ ����
						BEGIN
							PRINT('������Ʈ �� ����')
							SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT PAY_DT, STAFF, TOT_AMT, TAXN_AMT, INCOME_TAX, MAN_TAX '
							SET @OPENQUERY = @OPENQUERY + ' , REPLY_CLS_CD, PROC_YN, REG_ID, REG_DTM FROM TB_FI312 '
							SET @OPENQUERY = @OPENQUERY + 'WHERE ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WORK_SITE_CD = ''''' + @V_WORK_SITE_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''')' 
							SET @OPENQUERY = @OPENQUERY + ' SET PAY_DT = ''' + @V_PAY_DT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,STAFF = ' + CAST(@V_STAFF AS VARCHAR) + ''
							SET @OPENQUERY = @OPENQUERY + '    ,TOT_AMT = ' + CAST(@V_TOT_AMT AS VARCHAR) + ''
							SET @OPENQUERY = @OPENQUERY + '    ,TAXN_AMT = ' + CAST(@V_TAXN_AMT AS VARCHAR) + ''
							SET @OPENQUERY = @OPENQUERY + '    ,INCOME_TAX = ' + CAST(@V_INCOME_TAX AS VARCHAR) + ''
							SET @OPENQUERY = @OPENQUERY + '    ,MAN_TAX = ' + CAST(@V_MAN_TAX AS VARCHAR) + ''
							SET @OPENQUERY = @OPENQUERY + '    ,REPLY_CLS_CD = '''''
							SET @OPENQUERY = @OPENQUERY + '    ,PROC_YN = 0'
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @v_emp_no + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							PRINT(@OPENQUERY)
							EXECUTE(@OPENQUERY);	
						END
					ELSE
						BEGIN
							PRINT('�μ�Ʈ �� ����')
							PRINT('@V_CLOSE_YM : ' + CAST(@V_CLOSE_YM AS VARCHAR))
							PRINT('@V_ACCT_DEPT_CD : ' + CAST(@V_ACCT_DEPT_CD AS VARCHAR))
							PRINT('@V_WITHHOLD_CLS_CD : ' +CAST( @V_WITHHOLD_CLS_CD AS VARCHAR))
							PRINT('@V_WORK_SITE_CD : ' + CAST(@V_WORK_SITE_CD AS VARCHAR))
							PRINT('@V_PAY_DT : ' + CAST(@V_PAY_DT AS VARCHAR))
							PRINT('@V_STAFF : ' + CAST(@V_STAFF AS VARCHAR))
							PRINT('@V_TOT_AMT : ' + CAST(@V_TOT_AMT AS VARCHAR))
							PRINT('@V_TAXN_AMT : ' + CAST(@V_TAXN_AMT AS VARCHAR))
							PRINT('@V_INCOME_TAX : ' + CAST(@V_INCOME_TAX AS VARCHAR))
							PRINT('@V_MAN_TAX : ' + CAST(@V_MAN_TAX AS VARCHAR))
							PRINT('@P_SABUN : ' + CAST(@v_emp_no AS VARCHAR))
							--INSERT INTO TB_FI312
							INSERT OPENQUERY(DEBIS, 'SELECT CLOSE_YM      
															 ,ACCT_DEPT_CD   
															 ,WITHHOLD_CLS_CD
															 ,WORK_SITE_CD
															 ,PAY_DT         
															 ,STAFF          
															 ,TOT_AMT        
															 ,TAXN_AMT       
															 ,INCOME_TAX     
															 ,MAN_TAX        
															 ,REPLY_CLS_CD     
															 ,PROC_YN        
															 ,REG_ID         
															 ,REG_DTM
														 FROM TB_FI312') 
														 VALUES(    
														  @V_CLOSE_YM  
														 ,@V_ACCT_DEPT_CD   
														 ,@V_WITHHOLD_CLS_CD
														 ,@V_WORK_SITE_CD
														 ,@V_PAY_DT         
														 ,@V_STAFF          
														 ,@V_TOT_AMT        
														 ,@V_TAXN_AMT       
														 ,@V_INCOME_TAX     
														 ,@V_MAN_TAX        
														 ,''     
														 ,0       
														 ,@v_emp_no         
														 ,CONVERT(VARCHAR(10), GETDATE(), 112)  
														 );
						END
				
				END  
			FETCH NEXT FROM C_PBT_WITHHOOD_E INTO   @V_WORK_SITE_CD,
													@V_COSTDPT_CD,
													@V_SABUN_CNT,
													@V_AOLWTOT_AMT,
													@V_TAXFREEALOW,
													@V_INCTAX,
													@V_INGTAX
			END 
	           
			CLOSE C_PBT_WITHHOOD_E        
			DEALLOCATE C_PBT_WITHHOOD_E; 
		END
		
    ELSE IF @av_tax_kind_cd = 'B1'
		BEGIN
        --��
			SET @V_PAY_CD = '02';
			SET @V_PAY_CD1 = 'XXXXX';
			PRINT('@V_PAY_CD : ' + @V_PAY_CD);
			PRINT('@V_PAY_CD1 : ' + @V_PAY_CD1);
			BEGIN 
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @av_tax_kind_cd + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '
				
				EXEC (@OPENQUERY)      
			END
			
			PRINT('Ŀ�� ���� ��')
			DECLARE C_PBT_WITHHOOD_E CURSOR FOR                                     -- ��õ������ �����͸� �����´�. 
			SELECT A.RES_BIZ_CD                                       -- ����� - �ٹ��� 
				  ,ISNULL(MAPCOSTDPT_CD,'XXXXX')  MAPCOSTDPT_CD       -- �����μ�
				  ,COUNT(DISTINCT(A.EMP_ID)) AS SABUN_CNT             -- ���ο�
				  ,SUM(A.PSUM) AS AOLWTOT_AMT                         -- �޿��Ѿ�
				  ,SUM(A.C001_AMT) AS TAXFREEALOW                     -- �����
				  ,SUM(A.D001_AMT) AS INCTAX                          -- �ҵ漼
				  ,SUM(A.D002_AMT) AS INGTAX						  -- �ֹμ�
			  FROM (
					SELECT PAY.RES_BIZ_CD
						 , PRI.FROM_TYPE_CD 
						 , PAY.ACC_CD COST_CD
						 , PAY.EMP_ID
						 , PAY.PSUM
						 , (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD=YMD.COMPANY_CD AND COST_CD = PAY.ACC_CD AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD ) AS MAPCOSTDPT_CD
						 , D001_AMT -- ���ټ�
						 , D002_AMT -- �ֹμ�
						 , C001_AMT -- �����
					  FROM PAY_PAY_YMD YMD
					  JOIN PAY_PAYROLL PAY
						ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
					  JOIN PHM_EMP EMP
					    ON PAY.EMP_ID = EMP.EMP_ID
					  JOIN PHM_PRIVATE PRI
						ON PAY.EMP_ID = PRI.EMP_ID
					   AND CASE WHEN EMP.IN_OFFI_YN != 'Y' THEN EMP.RETIRE_YMD WHEN YMD.PAY_YMD < EMP.HIRE_YMD THEN EMP.HIRE_YMD ELSE YMD.PAY_YMD END BETWEEN PRI.STA_YMD AND PRI.END_YMD
					  JOIN ORM_COST COST
						ON PAY.ACC_CD = COST.COST_CD
					   AND YMD.COMPANY_CD = COST.COMPANY_CD
					   AND YMD.PAY_YMD BETWEEN COST.STA_YMD AND COST.END_YMD
					  LEFT OUTER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) D001_AMT FROM PAY_PAYROLL_DETAIL DTL WHERE DTL.PAY_ITEM_CD='D001' GROUP BY PAY_PAYROLL_ID) DTL_D
						ON PAY.PAY_PAYROLL_ID = DTL_D.PAY_PAYROLL_ID
					  LEFT OUTER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) D002_AMT FROM PAY_PAYROLL_DETAIL DTL WHERE DTL.PAY_ITEM_CD='D002' GROUP BY PAY_PAYROLL_ID) DTL_D2
						ON PAY.PAY_PAYROLL_ID = DTL_D2.PAY_PAYROLL_ID
										-- C001	�Ĵ�����	AMT_TAX_EXEMPTION2	������ݾ�(�Ĵ�)
										-- C002	��������	AMT_TAX_EXEMPTION1	������ݾ�(����)
										-- C003	���������	AMT_TAX_EXEMPTION3	������ݾ�(��Ÿ)
										-- C004	���ܱٷκ����	AMT_TAX_EXEMPTION4	������ݾ�(���ܱٷ�)
					  LEFT OUTER JOIN (SELECT PAY_PAYROLL_ID, SUM(CAL_MON) C001_AMT FROM PAY_PAYROLL_DETAIL DTL WHERE DTL.PAY_ITEM_CD IN('C001','C002','C003','C004') GROUP BY PAY_PAYROLL_ID) DTL_D3
						ON PAY.PAY_PAYROLL_ID = DTL_D3.PAY_PAYROLL_ID
					 WHERE YMD.COMPANY_CD = @av_company_cd
					   AND YMD.PAY_YM = @v_yyyymm
					   AND PRI.FROM_TYPE_CD = @av_hrtype_cd
					   AND YMD.PAY_TYPE_CD IN (
												SELECT CD
												  FROM FRM_CODE
												 WHERE COMPANY_CD=@av_company_cd
												   AND CD_KIND = 'PAY_TYPE_CD'
												   AND SYS_CD IN (
														SELECT HIS.KEY_CD1 AS CD
														  FROM FRM_UNIT_STD_HIS HIS
																   , FRM_UNIT_STD_MGR MGR
														 WHERE HIS.FRM_UNIT_STD_MGR_ID = MGR.FRM_UNIT_STD_MGR_ID
														   AND MGR.UNIT_CD = 'TBS'
														   AND MGR.STD_KIND = 'TBS_DEBIS_PAY'
															  AND MGR.COMPANY_CD = @av_company_cd
														   AND MGR.LOCALE_CD = @av_locale_cd
														   AND HIS.CD1=@av_tax_kind_cd
														   AND dbo.XF_SYSDATE(0) BETWEEN HIS.STA_YMD AND HIS.END_YMD
														   )
												   )
					) A
			 GROUP BY A.RES_BIZ_CD		-- ����� - �ٹ��� 
					 ,MAPCOSTDPT_CD		-- �����μ�
			 ORDER BY RES_BIZ_CD		-- ����� - �ٹ��� 
					 ,MAPCOSTDPT_CD;	-- �����μ�  

			OPEN C_PBT_WITHHOOD_E  -- Ŀ�� ��ġ
			FETCH NEXT FROM C_PBT_WITHHOOD_E INTO   @V_WORK_SITE_CD,
													@V_COSTDPT_CD,
													@V_SABUN_CNT,
													@V_AOLWTOT_AMT,
													@V_TAXFREEALOW,
													@V_INCTAX,
													@V_INGTAX
			WHILE	@@fetch_status = 0
			BEGIN
				--IF(@@ROWCOUNT < 1)
				--	BEGIN
				--		GOTO ERR_HANDLER
				--	END
				
				PRINT('Ŀ�� ������')
				-- ó���Ǽ�
				SET @V_CNT = @V_CNT+1;
				-- �����μ�
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
				-- �������� 
				SET @V_PAY_DT = dbo.XF_TO_CHAR_D(@ad_proc_date, 'yyyyMMdd')
				-- ���ο�
				SET @V_STAFF = @V_SABUN_CNT;
				-- �޿��Ѿ�
				SET @V_TOT_AMT = @V_AOLWTOT_AMT;
				-- �����(������� ������ ��ȯ)
				SET @V_TAXN_AMT = @V_AOLWTOT_AMT - @V_TAXFREEALOW;
				-- �������ҵ漼
				SET @V_INCOME_TAX = @V_INCTAX;
				-- �������ֹμ�
				SET @V_MAN_TAX = @V_INGTAX;
            
				BEGIN
					SET @V_CNT_DUP = 0;
					SET @OPENQUERY = 'SELECT @V_CNT_DUP = CNT_DUP FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_DUP FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WORK_SITE_CD =  ''''' + @V_WORK_SITE_CD + ''''''') '
					EXEC sp_executesql @OPENQUERY, N'@V_CNT_DUP NUMERIC(3) OUTPUT', @V_CNT_DUP output
					
					IF @V_CNT_DUP > 0 -- �ߺ�, ������Ʈ ����
						BEGIN
							SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT PAY_DT, STAFF, TOT_AMT, TAXN_AMT, INCOME_TAX, MAN_TAX '
							SET @OPENQUERY = @OPENQUERY + ' , REPLY_CLS_CD, PROC_YN, REG_ID, REG_DTM FROM TB_FI312 '
							SET @OPENQUERY = @OPENQUERY + 'WHERE ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WORK_SITE_CD = ''''' + @V_WORK_SITE_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''')' 
							SET @OPENQUERY = @OPENQUERY + ' SET PAY_DT = ''' + @V_PAY_DT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,STAFF = ''' + @V_STAFF + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TOT_AMT = ''' + @V_TOT_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TAXN_AMT = ''' + @V_TAXN_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,INCOME_TAX = ''' + @V_INCOME_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,MAN_TAX = ''' + @V_MAN_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REPLY_CLS_CD = '''''
							SET @OPENQUERY = @OPENQUERY + '    ,PROC_YN = 0'
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @v_emp_no + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC (@OPENQUERY);
						END
					ELSE
						BEGIN
						 --INSERT INTO TB_FI312
							INSERT OPENQUERY(DEBIS, 'SELECT CLOSE_YM   
															 ,ACCT_DEPT_CD   
															 ,WITHHOLD_CLS_CD
															 ,WORK_SITE_CD
															 ,PAY_DT         
															 ,STAFF          
															 ,TOT_AMT        
															 ,TAXN_AMT       
															 ,INCOME_TAX     
															 ,MAN_TAX        
															 ,REPLY_CLS_CD     
															 ,PROC_YN        
															 ,REG_ID         
															 ,REG_DTM
													     FROM TB_FI312')
													   VALUES(    
															  @V_CLOSE_YM    
															 ,@V_ACCT_DEPT_CD   
															 ,@V_WITHHOLD_CLS_CD
															 ,@V_WORK_SITE_CD
															 ,@V_PAY_DT         
															 ,@V_STAFF          
															 ,@V_TOT_AMT        
															 ,@V_TAXN_AMT       
															 ,@V_INCOME_TAX     
															 ,@V_MAN_TAX        
															 ,''     
															 ,0       
															 ,@v_emp_no         
															 ,CONVERT(VARCHAR(10), GETDATE(), 112)  
														 );      	
						END   
				END
				FETCH NEXT FROM C_PBT_WITHHOOD_E INTO   @V_WORK_SITE_CD,
													 @V_COSTDPT_CD,
													 @V_SABUN_CNT,
													 @V_AOLWTOT_AMT,
													 @V_TAXFREEALOW,
													 @V_INCTAX,
													 @V_INGTAX             
			END                                     
			CLOSE C_PBT_WITHHOOD_E;  -- ��õ������ ����
			DEALLOCATE C_PBT_WITHHOOD_E
		END
		
    ELSE IF @av_tax_kind_cd = 'C1'
		BEGIN
			--��������
			SET @V_PAY_CD = '';
			
			BEGIN
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @av_tax_kind_cd + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '
				
				EXEC (@OPENQUERY)  
			END
			
			--��������
			PRINT('CURSOR ����(��������)')
			                                           -- ��õ������ �����͸� �����´�. 
			DECLARE C_PBT_RET_RESULT CURSOR FOR    
			   SELECT A.REG_BIZ_CD
					 ,A.MAPCOSTDPT_CD  
					 ,COUNT(DISTINCT(A.EMP_ID)) AS SABUN_CNT      -- ���ο�
					 ,SUM(A.AMT_RETR_PAY) AS AOLWTOT_AMT          -- �޿��Ѿ�
					 ,0 AS TAXFREEALOW   -- �����
					 ,SUM(A.T01) AS INCTAX                -- �ҵ漼
					 ,SUM(A.T02) AS INGTAX                -- �ֹμ�  
					 ,SUM(A.INCTAX_OLD) AS INCTAX_OLD        -- �����ҵ漼
					 ,SUM(A.INHTAX_OLD) AS INHTAX_OLD        -- �����ֹμ�
				FROM ( 
					   SELECT DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',A.C1_END_YMD,'ORG_ID'),A.C1_END_YMD) AS REG_BIZ_CD,
							   dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.PAY_YMD, '1') AS COST_CD,
							   (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD = A.COMPANY_CD AND COST_CD = dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.PAY_YMD, '1')
															   AND A.C1_END_YMD BETWEEN STA_YMD AND END_YMD) AS MAPCOSTDPT_CD,
								A.EMP_ID,
								A.C_01 AS AMT_RETR_PAY, -- �޿��Ѿ�
								0 TAXFREEALOW,          -- �����
								A.R06_S AS INCTAX_OLD,                -- �ҵ漼
								A.CT02 AS INHTAX_OLD,                 -- �ֹμ�
								A.TRANS_INCOME_AMT INCTAX,     -- �����̿��ҵ漼
								A.TRANS_RESIDENCE_AMT INHTAX,   -- �����̿��ֹμ�
								A.T01, -- �����ҵ漼
								A.T02  -- �����ֹμ�
						  FROM REP_CALC_LIST A
						  JOIN PHM_PRIVATE PRI
							ON A.EMP_ID = PRI.EMP_ID
						   AND A.C1_END_YMD BETWEEN PRI.STA_YMD AND PRI.END_YMD
						 WHERE A.COMPANY_CD = @av_company_cd
						   AND PRI.FROM_TYPE_CD = @av_hrtype_cd -- �η�����
						   AND FORMAT(A.C1_END_YMD, 'yyyyMM') = @V_YYYYMM
						   AND A.CALC_TYPE_CD IN ('01','02') -- ����, �߰�����
						   AND A.REP_MID_YN != 'Y'
						   AND A.INS_TYPE_CD = '10' -- DB��
						   AND A.C_01 <> 0) A
				GROUP BY A.REG_BIZ_CD
						,A.MAPCOSTDPT_CD  
				ORDER BY A.REG_BIZ_CD
						,A.MAPCOSTDPT_CD
			OPEN C_PBT_RET_RESULT  -- Ŀ�� ��ġ
	        FETCH NEXT FROM C_PBT_RET_RESULT INTO    @V_WORK_SITE_CD,
													 @V_COSTDPT_CD,
													 @V_SABUN_CNT,
													 @V_AOLWTOT_AMT,
													 @V_TAXFREEALOW,
													 @V_INCTAX,
													 @V_INGTAX,
													 @V_INCTAX_OLD,
													 @V_INGTAX_OLD
			WHILE	@@fetch_status = 0
			BEGIN
				--IF(@@ROWCOUNT < 1)
				--	BEGIN
				--		GOTO ERR_HANDLER
				--	END
				
				PRINT('�׽�Ʈ')

				-- ó���Ǽ�
				SET @V_CNT = @V_CNT+1;
				-- �����μ�
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
				-- �������� 
				SET @V_PAY_DT = dbo.XF_TO_CHAR_D(@ad_proc_date, 'yyyyMMdd')
				-- ���ο�
				SET @V_STAFF = @V_SABUN_CNT;
				-- �޿��Ѿ�
				SET @V_TOT_AMT = @V_AOLWTOT_AMT;
				-- �����(������� ������ ��ȯ)
				SET @V_TAXN_AMT = @V_AOLWTOT_AMT - @V_TAXFREEALOW;
				-- �������ҵ漼
				SET @V_INCOME_TAX = @V_INCTAX;
				-- �������ֹμ�
				SET @V_MAN_TAX = @V_INGTAX;
	            
				BEGIN
					SET @V_CNT_DUP = 0;
					SET @OPENQUERY = 'SELECT @V_CNT_DUP = CNT_DUP FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_DUP FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WORK_SITE_CD =  ''''' + @V_WORK_SITE_CD + ''''''') '
					EXEC sp_executesql @OPENQUERY, N'@V_CNT_DUP NUMERIC(3) OUTPUT', @V_CNT_DUP output

					PRINT(@OPENQUERY)
					
					IF @V_CNT_DUP > 0 -- �ߺ�, ������Ʈ ����
						BEGIN
							SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT PAY_DT, STAFF, TOT_AMT, TAXN_AMT, INCOME_TAX, MAN_TAX '
							SET @OPENQUERY = @OPENQUERY + ' , REPLY_CLS_CD, PROC_YN, REG_ID, REG_DTM FROM TB_FI312 '
							SET @OPENQUERY = @OPENQUERY + 'WHERE ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WORK_SITE_CD = ''''' + @V_WORK_SITE_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''')' 
							SET @OPENQUERY = @OPENQUERY + ' SET PAY_DT = ''' + @V_PAY_DT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,STAFF = ''' + @V_STAFF + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TOT_AMT = ''' + @V_TOT_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TAXN_AMT = ''' + @V_TAXN_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,INCOME_TAX = ''' + @V_INCOME_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,MAN_TAX = ''' + @V_MAN_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REPLY_CLS_CD = '''''
							SET @OPENQUERY = @OPENQUERY + '    ,PROC_YN = 0'
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @v_emp_no + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC (@OPENQUERY);
						END
					ELSE
						BEGIN
							--INSERT INTO TB_FI312
							INSERT OPENQUERY(DEBIS, 'SELECT CLOSE_YM  
															 ,ACCT_DEPT_CD   
															 ,WITHHOLD_CLS_CD
															 ,WORK_SITE_CD
															 ,PAY_DT         
															 ,STAFF          
															 ,TOT_AMT        
															 ,TAXN_AMT       
															 ,INCOME_TAX     
															 ,MAN_TAX        
															 ,REPLY_CLS_CD     
															 ,PROC_YN        
															 ,REG_ID         
															 ,REG_DTM 
														 FROM TB_FI312 ')
													  VALUES(    
															  @V_CLOSE_YM     
															 ,@V_ACCT_DEPT_CD   
															 ,@V_WITHHOLD_CLS_CD
															 ,@V_WORK_SITE_CD
															 ,@V_PAY_DT         
															 ,@V_STAFF          
															 ,@V_TOT_AMT        
															 ,@V_TAXN_AMT       
															 ,@V_INCOME_TAX     
															 ,@V_MAN_TAX        
															 ,''     
															 ,0       
															 ,@v_emp_no         
															 ,CONVERT(VARCHAR(10), GETDATE(), 112)   
															 );
						END  
				END 
				FETCH NEXT FROM C_PBT_RET_RESULT INTO    @V_WORK_SITE_CD,
														 @V_COSTDPT_CD,
														 @V_SABUN_CNT,
														 @V_AOLWTOT_AMT,
														 @V_TAXFREEALOW,
														 @V_INCTAX,
														 @V_INGTAX,
														 @V_INCTAX_OLD,
														 @V_INGTAX_OLD
			END                                           
			CLOSE C_PBT_RET_RESULT  -- ���������õ������ ����
			DEALLOCATE C_PBT_RET_RESULT
		END

    ELSE IF @av_tax_kind_cd = 'E1'
		BEGIN
			--��������
			SET @V_PAY_CD = 'P2101';

			BEGIN
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @av_tax_kind_cd + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '
				print(@OPENQUERY)
				EXEC (@OPENQUERY)   
			END
        
            --�������� ��õ�� �Ű�
			
			PRINT('@P_COMPANY : ' + @av_company_cd);
			PRINT('@P_HRTYPE_GBN : ' + @av_hrtype_cd);
			PRINT('@V_YYYYMM : ' + @V_YYYYMM);


			-- CURSOR ����(��������)
		    DECLARE C_PBT_WITHHOOD_YETA CURSOR FOR    -- ��õ������ �����͸� �����´�. 
				SELECT   A.REG_BIZ_CD
					    ,A.MAPCOSTDPT_CD  
						,COUNT(DISTINCT(A.SABUN)) AS SABUN_CNT      -- ���ο�
						,SUM(A.INC_TOTAMT) AS AOLWTOT_AMT          -- �޿��Ѿ�
						,SUM(A.AMT_BITAX_TOT) AS TAXFREEALOW   -- �����
						,SUM(A.AMT_NEW_STAX) AS INCTAX                -- �ҵ漼
						,SUM(A.AMT_NEW_JTAX) AS INGTAX                -- �ֹμ�  
				  FROM (
						SELECT DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',A.IN_END_YMD,'ORG_ID'),A.IN_END_YMD) AS REG_BIZ_CD,
							   dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.IN_END_YMD, '1') AS COST_CD,
							   (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD = A.COMPANY_CD AND COST_CD = dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.IN_END_YMD, '1')
															   AND A.IN_END_YMD BETWEEN STA_YMD AND END_YMD) AS MAPCOSTDPT_CD
						   ,A.EMP_ID SABUN     -- ���ο�
						   ,(A.X01_SUM) AS INC_TOTAMT        -- �޿��Ѿ�
						   ,A.Y_SUM AMT_BITAX_TOT               -- �����
						   ,A.F0310 AMT_NEW_STAX                -- �ҵ漼
						   ,A.F0320 AMT_NEW_JTAX                -- �ֹμ�         
						  FROM INT_Y08_EC_DETAIL A
						  JOIN PHM_PRIVATE PRI
							ON A.EMP_ID = PRI.EMP_ID
						   AND A.IN_END_YMD BETWEEN PRI.STA_YMD AND PRI.END_YMD
						 WHERE A.COMPANY_CD = @av_company_cd
						   AND PRI.FROM_TYPE_CD = @av_hrtype_cd -- �η�����
						   AND A.EC_YY = SUBSTRING(@V_YYYYMM, 1, 4)
						   AND A.X01_SUM <> 0) A
			  GROUP BY  A.REG_BIZ_CD
					   ,A.MAPCOSTDPT_CD  
			  ORDER BY  A.REG_BIZ_CD
					   ,A.MAPCOSTDPT_CD;
		   OPEN C_PBT_WITHHOOD_YETA  -- Ŀ�� ��ġ
		   FETCH NEXT FROM C_PBT_WITHHOOD_YETA INTO    @V_WORK_SITE_CD,
													   @V_COSTDPT_CD,
													   @V_SABUN_CNT,
													   @V_AOLWTOT_AMT,
													   @V_TAXFREEALOW,
													   @V_INCTAX,
													   @V_INGTAX
			WHILE	@@fetch_status = 0
			BEGIN
				--PRINT('�ο��')
				--PRINT(@@ROWCOUNT);
				--IF(@@ROWCOUNT < 1)
				--	BEGIN
				--		GOTO ERR_HANDLER
				--	END
			
				-- ó���Ǽ�
				SET @V_CNT = @V_CNT+1;
				-- �����μ�
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
				-- �������� 
				SET @V_PAY_DT = dbo.XF_TO_CHAR_D(@ad_proc_date, 'yyyyMMdd') -- @P_PROC_DATE;
				-- ���ο�
				SET @V_STAFF = @V_SABUN_CNT;
				-- �޿��Ѿ�
				SET @V_TOT_AMT = @V_AOLWTOT_AMT;
				-- �����(������� ������ ��ȯ)
				SET @V_TAXN_AMT = @V_AOLWTOT_AMT - @V_TAXFREEALOW;
				-- �������ҵ漼
				SET @V_INCOME_TAX = @V_INCTAX;
				-- �������ֹμ�
				SET @V_MAN_TAX = @V_INGTAX;
	            
	            BEGIN
					SET @V_CNT_DUP = 0;
					SET @OPENQUERY = 'SELECT @V_CNT_DUP = CNT_DUP FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_DUP FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WORK_SITE_CD =  ''''' + @V_WORK_SITE_CD + ''''') '
					EXEC sp_executesql @OPENQUERY, N'@V_CNT_DUP NUMERIC(3) OUTPUT', @V_CNT_DUP output
					
					IF @V_CNT_DUP > 0 -- �ߺ�, ������Ʈ ����
						BEGIN
							print('������Ʈ���� ����')
							SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT PAY_DT, STAFF, TOT_AMT, TAXN_AMT, INCOME_TAX, MAN_TAX '
							SET @OPENQUERY = @OPENQUERY + ' , REPLY_CLS_CD, PROC_YN, REG_ID, REG_DTM FROM TB_FI312 '
							SET @OPENQUERY = @OPENQUERY + 'WHERE ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WORK_SITE_CD = ''''' + @V_WORK_SITE_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''')' 
							SET @OPENQUERY = @OPENQUERY + ' SET PAY_DT = ''' + @V_PAY_DT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,STAFF = ''' + @V_STAFF + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TOT_AMT = ''' + @V_TOT_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TAXN_AMT = ''' + @V_TAXN_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,INCOME_TAX = ''' + @V_INCOME_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,MAN_TAX = ''' + @V_MAN_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REPLY_CLS_CD = '''''
							SET @OPENQUERY = @OPENQUERY + '    ,PROC_YN = 0'
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @v_emp_no + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC (@OPENQUERY);
							
						END
					ELSE
						BEGIN
							print('�μ�Ʈ���� ����')
							--INSERT INTO TB_FI312
							INSERT OPENQUERY(DEBIS, 'SELECT CLOSE_YM   
															 ,ACCT_DEPT_CD   
															 ,WITHHOLD_CLS_CD
															 ,WORK_SITE_CD
															 ,PAY_DT         
															 ,STAFF          
															 ,TOT_AMT        
															 ,TAXN_AMT       
															 ,INCOME_TAX     
															 ,MAN_TAX        
															 ,REPLY_CLS_CD     
															 ,PROC_YN        
															 ,REG_ID         
															 ,REG_DTM  
													     FROM TB_FI312 ') 
													 VALUES(    
															  @V_CLOSE_YM      
															 ,@V_ACCT_DEPT_CD   
															 ,@V_WITHHOLD_CLS_CD
															 ,@V_WORK_SITE_CD
															 ,@V_PAY_DT         
															 ,@V_STAFF          
															 ,@V_TOT_AMT        
															 ,@V_TAXN_AMT       
															 ,@V_INCOME_TAX     
															 ,@V_MAN_TAX        
															 ,''     
															 ,0       
															 ,@v_emp_no         
															 ,CONVERT(VARCHAR(10), GETDATE(), 112)   
															)
						END
					
	            END       
			
			FETCH NEXT FROM C_PBT_WITHHOOD_YETA INTO   @V_WORK_SITE_CD,
													   @V_COSTDPT_CD,
													   @V_SABUN_CNT,
													   @V_AOLWTOT_AMT,
													   @V_TAXFREEALOW,
													   @V_INCTAX,
													   @V_INGTAX
			
			END                                       
			CLOSE C_PBT_WITHHOOD_YETA  -- ���������õ������ ����
			DEALLOCATE C_PBT_WITHHOOD_YETA
        END
    ELSE IF @av_tax_kind_cd = 'D1' 
		BEGIN
        --�ߵ�����
			SET @V_PAY_CD = 'P2102';
			
			BEGIN
				SET @OPENQUERY = 'DELETE FROM OPENQUERY('+ @LinkedServer + ','''
				SET @OPENQUERY = @OPENQUERY + 'SELECT * FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD IN (SELECT ACCT_DEPT_CD FROM TB_CO011 '
				SET @OPENQUERY = @OPENQUERY + ' WHERE ACCT_YEAR = ''''' + SUBSTRING(@V_CLOSE_YM,1,4) + ''''' AND CO_CD = ''''' + @V_CO_CD + ''''''
				SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @av_tax_kind_cd + ''''' AND (PROC_YN <> 1 OR REPLY_CLS_CD = ''''D''''))'') '

				EXEC (@OPENQUERY)     
				
			END
			
			
        
			-- �����ߵ�����
			-- CURSOR ����(�߰�����)
			DECLARE C_PBT_WITHHOOD_D1 CURSOR FOR    -- ��õ������ �����͸� �����´�. 
			  SELECT A.REG_BIZ_CD
					,A.MAPCOSTDPT_CD  
					 ,COUNT(DISTINCT(A.EMP_ID)) AS SABUN_CNT      -- ���ο�
					 ,SUM(A.AMT_RETR_PAY) AS AOLWTOT_AMT          -- �޿��Ѿ�
					 ,SUM(A.TAXFREEALOW) AS TAXFREEALOW   -- �����
					 ,SUM(A.T01) AS INCTAX                -- �ҵ漼
					 ,SUM(A.T02) AS INGTAX                -- �ֹμ�  
			  FROM (
					   SELECT DBO.F_TBS_EMP_BIZ(A.COMPANY_CD,A.EMP_ID,dbo.F_FRM_CAM_HISTORY(A.EMP_ID,'KO',A.C1_END_YMD,'ORG_ID'),A.C1_END_YMD) AS REG_BIZ_CD,
							   dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.PAY_YMD, '1') AS COST_CD,
							   (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD = A.COMPANY_CD AND COST_CD = dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.PAY_YMD, '1')
															   AND A.C1_END_YMD BETWEEN STA_YMD AND END_YMD) AS MAPCOSTDPT_CD,
								A.EMP_ID,
								A.C_01 AS AMT_RETR_PAY, -- �޿��Ѿ�
								0 TAXFREEALOW,          -- �����
								A.R06_S AS INCTAX_OLD,                -- �ҵ漼
								A.CT02 AS INHTAX_OLD,                 -- �ֹμ�
								A.TRANS_INCOME_AMT INCTAX,     -- �����̿��ҵ漼
								A.TRANS_RESIDENCE_AMT INHTAX,   -- �����̿��ֹμ�
								A.T01, -- �����ҵ漼
								A.T02  -- �����ֹμ�
						  FROM REP_CALC_LIST A
						  JOIN PHM_PRIVATE PRI
							ON A.EMP_ID = PRI.EMP_ID
						   AND A.C1_END_YMD BETWEEN PRI.STA_YMD AND PRI.END_YMD
						 WHERE A.COMPANY_CD = @av_company_cd
						   AND PRI.FROM_TYPE_CD = @av_hrtype_cd -- �η�����
						   AND FORMAT(A.C1_END_YMD, 'yyyyMM') = @V_YYYYMM
						   AND A.CALC_TYPE_CD IN ('01')--,'02') -- ����, �߰�����
						   AND A.REP_MID_YN = 'Y' -- �ߵ�����
						   AND A.INS_TYPE_CD = '10' -- DB��
						   AND A.C_01 <> 0) A
			  GROUP BY A.REG_BIZ_CD
					,A.MAPCOSTDPT_CD  
			  ORDER BY A.REG_BIZ_CD
					,A.MAPCOSTDPT_CD  ;
	        
			OPEN C_PBT_WITHHOOD_D1
	        FETCH NEXT FROM C_PBT_WITHHOOD_D1 INTO    @V_WORK_SITE_CD,
													   @V_COSTDPT_CD,
													   @V_SABUN_CNT,
													   @V_AOLWTOT_AMT,
													   @V_TAXFREEALOW,
													   @V_INCTAX,
													   @V_INGTAX
			WHILE	@@fetch_status = 0
			BEGIN
				--IF(@@ROWCOUNT < 1)
				--	BEGIN
				--		GOTO ERR_HANDLER
				--	END
			
            
				-- ó���Ǽ�
				SET @V_CNT = @V_CNT+1;
				-- �����μ�
				SET @V_ACCT_DEPT_CD = @V_COSTDPT_CD;
				-- �������� 
				SET @V_PAY_DT = dbo.XF_TO_CHAR_D(@ad_proc_date, 'yyyyMMdd')
				-- ���ο�
				SET @V_STAFF = @V_SABUN_CNT;
				-- �޿��Ѿ�
				SET @V_TOT_AMT = @V_AOLWTOT_AMT;
				-- �����(������� ������ ��ȯ)
				SET @V_TAXN_AMT = @V_AOLWTOT_AMT - @V_TAXFREEALOW;
				-- �������ҵ漼
				SET @V_INCOME_TAX = @V_INCTAX;
				-- �������ֹμ�
				SET @V_MAN_TAX = @V_INGTAX;
	            
				BEGIN
					SET @V_CNT_DUP = 0;
					SET @OPENQUERY = 'SELECT @V_CNT_DUP = CNT_DUP FROM OPENQUERY('+ @LinkedServer + ','''
					SET @OPENQUERY = @OPENQUERY + 'SELECT COUNT(*) CNT_DUP FROM TB_FI312 where CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
					SET @OPENQUERY = @OPENQUERY + '   AND WORK_SITE_CD =  ''''' + @V_WORK_SITE_CD + ''''''') '
					PRINT(@OPENQUERY)
					EXEC sp_executesql @OPENQUERY, N'@V_CNT_DUP NUMERIC(3) OUTPUT', @V_CNT_DUP output
					
					IF @V_CNT_DUP > 0 -- �ߺ�, ������Ʈ ����
						BEGIN
							PRINT('������Ʈ���� ����')
							SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
							SET @OPENQUERY = @OPENQUERY + 'SELECT PAY_DT, STAFF, TOT_AMT, TAXN_AMT, INCOME_TAX, MAN_TAX '
							SET @OPENQUERY = @OPENQUERY + ' , REPLY_CLS_CD, PROC_YN, REG_ID, REG_DTM FROM TB_FI312 '
							SET @OPENQUERY = @OPENQUERY + 'WHERE ACCT_DEPT_CD = ''''' + @V_ACCT_DEPT_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WITHHOLD_CLS_CD = ''''' + @V_WITHHOLD_CLS_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND WORK_SITE_CD = ''''' + @V_WORK_SITE_CD + ''''''
							SET @OPENQUERY = @OPENQUERY + '  AND CLOSE_YM = ''''' + @V_CLOSE_YM + ''''''')' 
							SET @OPENQUERY = @OPENQUERY + ' SET PAY_DT = ''' + @V_PAY_DT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,STAFF = ''' + @V_STAFF + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TOT_AMT = ''' + @V_TOT_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,TAXN_AMT = ''' + @V_TAXN_AMT + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,INCOME_TAX = ''' + @V_INCOME_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,MAN_TAX = ''' + @V_MAN_TAX + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REPLY_CLS_CD = '''''
							SET @OPENQUERY = @OPENQUERY + '    ,PROC_YN = 0'
							SET @OPENQUERY = @OPENQUERY + '    ,REG_ID = ''' + @v_emp_no + ''''
							SET @OPENQUERY = @OPENQUERY + '    ,REG_DTM = ''' + CONVERT(VARCHAR(10), GETDATE(), 112) + ''''
							EXEC @OPENQUERY;
							 
						END
					ELSE
						BEGIN
							PRINT('�μ�Ʈ���� ����')
							--INSERT INTO TB_FI312
							INSERT OPENQUERY(DEBIS, 'SELECT CLOSE_YM  
															 ,ACCT_DEPT_CD   
															 ,WITHHOLD_CLS_CD
															 ,WORK_SITE_CD
															 ,PAY_DT         
															 ,STAFF          
															 ,TOT_AMT        
															 ,TAXN_AMT       
															 ,INCOME_TAX     
															 ,MAN_TAX        
															 ,REPLY_CLS_CD     
															 ,PROC_YN        
															 ,REG_ID         
															 ,REG_DTM  
													     FROM TB_FI312 ')
												VALUES(    
														  @V_CLOSE_YM     
														 ,@V_ACCT_DEPT_CD   
														 ,@V_WITHHOLD_CLS_CD
														 ,@V_WORK_SITE_CD
														 ,@V_PAY_DT         
														 ,@V_STAFF          
														 ,@V_TOT_AMT        
														 ,@V_TAXN_AMT       
														 ,@V_INCOME_TAX     
														 ,@V_MAN_TAX        
														 ,''     
														 ,0       
														 ,@v_emp_no         
														 ,CONVERT(VARCHAR(10), GETDATE(), 112)   
													 );
						END      
				END    
	        FETCH NEXT FROM C_PBT_WITHHOOD_D1 INTO    @V_WORK_SITE_CD,
													   @V_COSTDPT_CD,
													   @V_SABUN_CNT,
													   @V_AOLWTOT_AMT,
													   @V_TAXFREEALOW,
													   @V_INCTAX,
													   @V_INGTAX             
			END                                       
			CLOSE C_PBT_WITHHOOD_D1  -- ��õ������ ����
			DEALLOCATE C_PBT_WITHHOOD_D1
	END
  SET @av_ret_code = 'SUCCESS!';
  SET @av_ret_message = dbo.F_FRM_ERRMSG('��õ���� �����Ͽ����ϴ�..[ERR]' + ISNULL(ERROR_MESSAGE(),''),
                                        @v_program_id,  0000,  NULL, NULL);
	RETURN;
 ----------------------------------------------------------------------------------------------------------------------- 
	SET @v_error_note = '����..!!!'
  ERR_HANDLER:
		PRINT('----------------------------------------------------')
		PRINT('ERR_HANDLER:')
		PRINT('V_CLOSE_YM:' + @V_CLOSE_YM)
		PRINT('V_YYYYMM:' + @V_YYYYMM)
		begin try
			CLOSE C_PBT_ACCNT_STD;
			CLOSE C_PBT_RET_RESULT;
			CLOSE C_PBT_WITHHOOD_D1;
			CLOSE C_PBT_WITHHOOD_YETA;
			
			DEALLOCATE	C_PBT_ACCNT_STD;
			DEALLOCATE	C_PBT_RET_RESULT;
			DEALLOCATE	C_PBT_WITHHOOD_D1;
			DEALLOCATE  C_PBT_WITHHOOD_YETA;
		end try
		
		begin catch
			print 'ERR_HANDLER:';
		end catch;

		SET @v_error_number = ERROR_NUMBER();
		SET @v_error_severity = ERROR_SEVERITY();
		SET @v_error_state = ERROR_STATE();
		SET @v_error_line = ERROR_LINE();
		SET @v_error_message = @v_error_note;
		SET @av_ret_code = 'FAILURE!';
		SET @av_ret_message = dbo.F_FRM_ERRMSG(@v_error_message + '[ERR]',
                                        @v_program_id,  0000,  NULL, NULL)
		PRINT('av_ret_message:' + @av_ret_message)
	RETURN

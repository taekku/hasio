SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_CNM_CNT_CREATE]
	@av_company_cd      nVARCHAR(10),       -- �λ翵��
    @av_locale_cd       nVARCHAR(10),       -- �����ڵ�
    @an_peb_base_id     numeric,         -- �ΰǺ����id
	@ad_base_ymd		DATE,
    @av_tz_cd           NVARCHAR(10),    -- Ÿ�����ڵ�
    @an_mod_user_id     NUMERIC(18,0)  ,    -- ������ ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ �������� ����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PHM_MST_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ ���������� ����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2020.09.08
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id		NVARCHAR(30)
      , @v_program_nm		NVARCHAR(100)
      , @v_ret_code			NVARCHAR(100)
      , @v_ret_message		NVARCHAR(500)
	  , @PEB_PHM_MST_ID		NUMERIC(38)
	  , @EMP_NO				NVARCHAR(50)
	  , @POS_GRD_CD			NVARCHAR(50)
	  , @POS_GRD_YMD		DATE
	  , @PEB_CNM_CNT_ID		NUMERIC(38)
	  , @n_peb_cnm_cnt_id	NUMERIC(38)
	  , @v_base_yyyy		NVARCHAR(04) -- �ΰǺ� �⵵
	  , @n_up_rate			NUMERIC(8,4) -- �λ���
	  , @v_peb_mm			NVARCHAR(02) -- �λ�ݿ���
	  , @d_first_sta_ymd	DATE -- ���ʽ�����
	  , @d_sta_ymd			DATE -- ������
	  , @d_end_ymd			DATE -- ������
	  , @d_cnm_sta_ymd		DATE -- ������
	  , @d_cnm_end_ymd		DATE -- ������
	  , @v_pay_group		NVARCHAR(50) -- �޿��׷�
	  , @n_year_limit		NUMERIC(02) -- ��������
	  , @v_next_pos_grd_cd	NVARCHAR(50) -- ��������
	  , @n_pos_grd_base_amt	NUMERIC(18) -- �����⺻����
	  , @v_prm_appl_ym		NVARCHAR(50) -- ���޽����ݿ���

	SET NOCOUNT ON;

    SET @v_program_id   = 'P_PEB_CNM_CNT_CREATE'
    SET @v_program_nm   = '�ΰǺ��ȹ �������� ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);

	/** �ΰǺ��ȹ �������� **/
	DELETE
	  FROM A
			FROM PEB_CNM_CNT A
			JOIN PEB_PHM_MST MST
				ON A.PEB_BASE_ID = MST.PEB_BASE_ID
				AND A.EMP_NO = MST.EMP_NO
			JOIN VI_FRM_PHM_EMP EMP
				ON MST.PEB_BASE_ID = @an_peb_base_id
				AND MST.EMP_NO = EMP.EMP_NO
				AND EMP.COMPANY_CD = @av_company_cd
				AND EMP.LOCALE_CD = @av_locale_cd
			JOIN CNM_CNT CNM
				ON CNM.EMP_ID = EMP.EMP_ID
				AND @ad_base_ymd BETWEEN CNM.STA_YMD AND CNM.END_YMD
			WHERE A.PEB_BASE_ID = @an_peb_base_id
	/** �ΰǺ��ȹ ����� **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID, EMP_NO, POS_GRD_CD, POS_YMD-- POS_GRD_YMD
		  FROM PEB_PHM_MST MST
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id

	-- �ΰǺ����
	SELECT @v_base_yyyy = BASE_YYYY
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id
	IF @@ROWCOUNT < 1
		BEGIN
				SET @av_ret_code    = 'FAILURE!'
				SET @av_ret_message = dbo.F_FRM_ERRMSG('�ΰǺ���� �о���� ����[ERR]',
																					@v_program_id,  120,  NULL, NULL);
				RETURN
		END
	-- �����λ���
	SELECT @n_up_rate = (PEB_RATE / 100.0) + 1 -- �����λ���
		    , @v_peb_mm = A.PEB_YM -- �����λ��
		FROM PEB_RATE A
		WHERE PEB_BASE_ID = @an_peb_base_id
		AND A.PEB_TYPE_CD = '110' -- 110:�����λ���, 120:ȣ���λ���
	IF @@ROWCOUNT < 1
		BEGIN
				--SET @av_ret_code    = 'FAILURE!'
				--SET @av_ret_message = dbo.F_FRM_ERRMSG('���� �λ��� �о���� ����[ERR]', @v_program_id,  120,  NULL, NULL);
				--RETURN
				SELECT @n_up_rate = NULL, @v_peb_mm = NULL
		END

	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST
				INTO @PEB_PHM_MST_ID, @EMP_NO, @POS_GRD_CD, @POS_GRD_YMD

    --<DOCLINE> ********************************************************
    --<DOCLINE> �ΰǺ� ����� ����
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			-- �޿��׷�
			set @v_pay_group = dbo.F_PEB_GET_PAY_GROUP(@PEB_PHM_MST_ID)
			-- ��������üũ
			select @n_year_limit = dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_POS_GRD_BASE',
								NULL, NULL, NULL, NULL, NULL,
								@v_pay_group, @POS_GRD_CD, NULL, NULL, NULL,
								@v_base_yyyy + '1231',
								'H1' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
								))
			
			IF @n_year_limit IS NOT NULL AND DATEPART(YEAR, GetDate()) - DATEPART(YEAR, @POS_GRD_YMD) > @n_year_limit
				BEGIN
				-- �����ݿ���
				select @v_prm_appl_ym = dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_MONTH',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, 'POS_GRD', NULL, NULL, NULL,
									@v_base_yyyy + '1231',
									'H1' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
									)
					-- ��������
					select @v_next_pos_grd_cd = dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_POS_GRD_BASE',
										NULL, NULL, NULL, NULL, NULL,
										@v_pay_group, @POS_GRD_CD, NULL, NULL, NULL,
										@v_base_yyyy + '1231',
										'H2' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
										)
					--IF @EMP_NO = '20130049'
					--print '�������1:' + @EMP_NO + ':' + ISNULL(@POS_GRD_CD,'NULL') + ':' + ISNULL(@v_prm_appl_ym, 'NULL')
					--		+ ':' + ISNULL(@v_next_pos_grd_cd, 'NULL')
					-- �����⺻����
					select @n_pos_grd_base_amt = dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_POS_GRD_BASE_AMT',
										NULL, NULL, NULL, NULL, NULL,
										@v_pay_group, @v_next_pos_grd_cd, NULL, NULL, NULL,
										@v_base_yyyy + '1231',
										'H1' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
										))
					SET @d_sta_ymd = @v_base_yyyy + @v_prm_appl_ym + '01'
					SET @d_end_ymd = dbo.XF_DATEADD(@d_sta_ymd, -1)
				END
			ELSE
				BEGIN
					-- �⺻����
					select @n_pos_grd_base_amt = dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_POS_GRD_BASE_AMT',
										NULL, NULL, NULL, NULL, NULL,
										@v_pay_group, @POS_GRD_CD, NULL, NULL, NULL,
										@v_base_yyyy + '1231',
										'H1' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
										))
					SET @d_end_ymd = NULL --dbo.XF_TO_DATE('29991231', 'yyyymmdd')
				END
			BEGIN Try
				INSERT INTO PEB_CNM_CNT(
						PEB_CNM_CNT_ID, --	�ΰǺ��ȹ����ID
						PEB_BASE_ID, --	�ΰǺ��ȹ����ID
						COMPANY_CD, --	�λ翵���ڵ�
						EMP_NO, --	���
						SALARY_TYPE_CD, --	�޿�����
						STA_YMD, --	����������
						END_YMD, --	�����������
						PRE_END_YMD, --	���������
						PAY_POS_GRD_CD, --	�޿������ڵ�[PAY_POS_GRD_CD]
						PAY_GRADE, --	�޿�ȣ��[PAY_GRADE]
						PAY_JOP_CD, --	�޿�����[PAY_JOP_CD]
						OLD_CNT_SALARY, --	����������
						CNT_SALARY, --	����������
						BASE_SALARY, --	�⺻��
						BP01, --	�����ݾ�
						BP02, --	����(����)
						BP03, --	����(�߰�)
						BP04, --	����(����)
						BP05, --	�����ٷνð�
						BP06, --	������������
						BP07, --	������������
						BP08, --	���󿩹����޿���
						BP09, --	��������������
						BP10, --	BP10
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	������
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE AS PEB_CNM_CNT_ID,
						   @an_peb_base_id PEB_BASE_ID, --	�ΰǺ��ȹ����ID
						@av_company_cd COMPANY_CD, --	�λ翵���ڵ�
						MST.EMP_NO, --	���
						CNM.SALARY_TYPE_CD SALARY_TYPE_CD, --	�޿�����
						CNM.STA_YMD	STA_YMD, --	����������
						ISNULL(@d_end_ymd, CNM.END_YMD)	END_YMD, --	�����������
						CNM.PRE_END_YMD	PRE_END_YMD, --	���������
						MST.POS_GRD_CD	PAY_POS_GRD_CD, --	�޿������ڵ�[PAY_POS_GRD_CD]
						CNM.PAY_GRADE	PAY_GRADE, --	�޿�ȣ��[PAY_GRADE]
						CNM.PAY_JOP_CD	PAY_JOP_CD, --	�޿�����[PAY_JOP_CD]
						CNM.CNT_SALARY	OLD_CNT_SALARY, --	����������
						--dbo.XF_CEIL(CNM.CNT_SALARY * @n_up_rate / 12, -1) * 12	AS CNT_SALARY, --	����������
						--dbo.XF_CEIL(CNM.CNT_SALARY * @n_up_rate / 12, -1)		AS BASE_SALARY, --	�⺻��
						CNM.CNT_SALARY	AS CNT_SALARY, --	����������
						CNM.BASE_SALARY	AS BASE_SALARY, --	�⺻��
						CNM.BP01	BP01, --	�����ݾ�
						CNM.BP02	BP02, --	����(����)
						CNM.BP03	BP03, --	����(�߰�)
						CNM.BP04	BP04, --	����(����)
						CNM.BP05	BP05, --	�����ٷνð�
						CNM.BP06	BP06, --	������������
						CNM.BP07	BP07, --	������������
						CNM.BP08	BP08, --	���󿩹����޿���
						CNM.BP09	BP09, --	��������������
						CNM.BP10	BP10, --	BP10
						CNM.NOTE	NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
				  FROM PEB_PHM_MST MST
				  INNER JOIN VI_FRM_PHM_EMP EMP
					  ON MST.PEB_BASE_ID = @an_peb_base_id
					 AND MST.EMP_NO = EMP.EMP_NO
					 AND EMP.COMPANY_CD = @av_company_cd
					 AND EMP.LOCALE_CD = @av_locale_cd
				  INNER JOIN CNM_CNT CNM
					  ON CNM.EMP_ID = EMP.EMP_ID
					 AND @ad_base_ymd BETWEEN CNM.STA_YMD AND CNM.END_YMD
				 WHERE MST.EMP_NO = @EMP_NO
				 IF @d_end_ymd IS NOT NULL -- ����
					BEGIN
						INSERT INTO PEB_CNM_CNT(
								PEB_CNM_CNT_ID, --	�ΰǺ��ȹ����ID
								PEB_BASE_ID, --	�ΰǺ��ȹ����ID
								COMPANY_CD, --	�λ翵���ڵ�
								EMP_NO, --	���
								SALARY_TYPE_CD, --	�޿�����
								STA_YMD, --	����������
								END_YMD, --	�����������
								PRE_END_YMD, --	���������
								PAY_POS_GRD_CD, --	�޿������ڵ�[PAY_POS_GRD_CD]
								PAY_GRADE, --	�޿�ȣ��[PAY_GRADE]
								PAY_JOP_CD, --	�޿�����[PAY_JOP_CD]
								OLD_CNT_SALARY, --	����������
								CNT_SALARY, --	����������
								BASE_SALARY, --	�⺻��
								BP01, --	�����ݾ�
								BP02, --	����(����)
								BP03, --	����(�߰�)
								BP04, --	����(����)
								BP05, --	�����ٷνð�
								BP06, --	������������
								BP07, --	������������
								BP08, --	���󿩹����޿���
								BP09, --	��������������
								BP10, --	BP10
								NOTE, --	���
								MOD_USER_ID, --	������
								MOD_DATE, --	������
								TZ_CD, --	Ÿ�����ڵ�
								TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE AS PEB_CNM_CNT_ID,
								@an_peb_base_id PEB_BASE_ID, --	�ΰǺ��ȹ����ID
								@av_company_cd COMPANY_CD, --	�λ翵���ڵ�
								MST.EMP_NO, --	���
								CNM.SALARY_TYPE_CD SALARY_TYPE_CD, --	�޿�����
								@d_sta_ymd STA_YMD, --	����������
								'29991231' END_YMD, --	�����������
								CNM.PRE_END_YMD	PRE_END_YMD, --	���������
								@v_next_pos_grd_cd	PAY_POS_GRD_CD, --	�޿������ڵ�[PAY_POS_GRD_CD]
								CNM.PAY_GRADE	PAY_GRADE, --	�޿�ȣ��[PAY_GRADE]
								CNM.PAY_JOP_CD	PAY_JOP_CD, --	�޿�����[PAY_JOP_CD]
								CNM.CNT_SALARY	OLD_CNT_SALARY, --	����������
								--dbo.XF_CEIL(CNM.CNT_SALARY * @n_up_rate / 12, -1) * 12	AS CNT_SALARY, --	����������
								--dbo.XF_CEIL(CNM.CNT_SALARY * @n_up_rate / 12, -1)		AS BASE_SALARY, --	�⺻��
								@n_pos_grd_base_amt	AS CNT_SALARY, --	����������
								dbo.XF_CEIL(@n_pos_grd_base_amt / 12, -1)	AS BASE_SALARY, --	�⺻��
								CNM.BP01	BP01, --	�����ݾ�
								CNM.BP02	BP02, --	����(����)
								CNM.BP03	BP03, --	����(�߰�)
								CNM.BP04	BP04, --	����(����)
								CNM.BP05	BP05, --	�����ٷνð�
								CNM.BP06	BP06, --	������������
								CNM.BP07	BP07, --	������������
								CNM.BP08	BP08, --	���󿩹����޿���
								CNM.BP09	BP09, --	��������������
								CNM.BP10	BP10, --	BP10
								CNM.NOTE	NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PHM_MST MST
						  INNER JOIN VI_FRM_PHM_EMP EMP
							  ON MST.PEB_BASE_ID = @an_peb_base_id
							 AND MST.EMP_NO = EMP.EMP_NO
							 AND EMP.COMPANY_CD = @av_company_cd
							 AND EMP.LOCALE_CD = @av_locale_cd
						  INNER JOIN CNM_CNT CNM
							  ON CNM.EMP_ID = EMP.EMP_ID
							 AND @ad_base_ymd BETWEEN CNM.STA_YMD AND CNM.END_YMD
						 WHERE MST.EMP_NO = @EMP_NO
					END
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� �������� INSERT ����[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_MST
						INTO @PEB_PHM_MST_ID, @EMP_NO, @POS_GRD_CD, @POS_GRD_YMD
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
	IF @n_up_rate IS NOT NULL
		BEGIN
			PRINT '�����λ��� �ݿ�'
			--@n_up_rate = (PEB_RATE / 100.0) + 1 -- �����λ���
		    --, @v_peb_mm = A.PEB_YM -- �����λ��
			SELECT @d_sta_ymd = dbo.XF_TO_DATE( @v_base_yyyy + @v_peb_mm + '01', 'yyyymmdd')
			     , @d_end_ymd = dbo.XF_DATEADD( dbo.XF_TO_DATE( @v_base_yyyy + @v_peb_mm + '01', 'yyyymmdd'), - 1)
			DECLARE CUR_PEB_CNM_CNT CURSOR LOCAL FOR
				SELECT PEB_CNM_CNT_ID, STA_YMD, END_YMD
				  FROM PEB_CNM_CNT
				 WHERE PEB_BASE_ID = @an_peb_base_id
				   AND @d_sta_ymd BETWEEN STA_YMD AND END_YMD
			OPEN CUR_PEB_CNM_CNT
			FETCH NEXT FROM CUR_PEB_CNM_CNT
						INTO @PEB_CNM_CNT_ID, @d_cnm_sta_ymd, @d_cnm_end_ymd
			WHILE @@FETCH_STATUS = 0
				BEGIN
					IF @d_cnm_sta_ymd < @d_sta_ymd
						BEGIN
							PRINT '�ɰ���'
							UPDATE PEB_CNM_CNT
							   SET END_YMD = @d_end_ymd
							 WHERE PEB_CNM_CNT_ID = @PEB_CNM_CNT_ID
							select @n_peb_cnm_cnt_id = NEXT VALUE FOR S_PEB_SEQUENCE
							INSERT INTO PEB_CNM_CNT(
								PEB_CNM_CNT_ID, --	�ΰǺ��ȹ����ID
								PEB_BASE_ID, --	�ΰǺ��ȹ����ID
								COMPANY_CD, --	�λ翵���ڵ�
								EMP_NO, --	���
								SALARY_TYPE_CD, --	�޿�����
								STA_YMD, --	����������
								END_YMD, --	�����������
								PRE_END_YMD, --	���������
								PAY_POS_GRD_CD, --	�޿������ڵ�[PAY_POS_GRD_CD]
								PAY_GRADE, --	�޿�ȣ��[PAY_GRADE]
								PAY_JOP_CD, --	�޿�����[PAY_JOP_CD]
								OLD_CNT_SALARY, --	����������
								CNT_SALARY, --	����������
								BASE_SALARY, --	�⺻��
								BP01, --	�����ݾ�
								BP02, --	����(����)
								BP03, --	����(�߰�)
								BP04, --	����(����)
								BP05, --	�����ٷνð�
								BP06, --	������������
								BP07, --	������������
								BP08, --	���󿩹����޿���
								BP09, --	��������������
								BP10, --	BP10
								NOTE, --	���
								MOD_USER_ID, --	������
								MOD_DATE, --	������
								TZ_CD, --	Ÿ�����ڵ�
								TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT @n_peb_cnm_cnt_id AS PEB_CNM_CNT_ID, --	�ΰǺ��ȹ����ID
								PEB_BASE_ID, --	�ΰǺ��ȹ����ID
								COMPANY_CD, --	�λ翵���ڵ�
								EMP_NO, --	���
								SALARY_TYPE_CD, --	�޿�����
								@d_sta_ymd STA_YMD, --	����������
								@d_cnm_end_ymd END_YMD, --	�����������
								PRE_END_YMD, --	���������
								PAY_POS_GRD_CD, --	�޿������ڵ�[PAY_POS_GRD_CD]
								PAY_GRADE, --	�޿�ȣ��[PAY_GRADE]
								PAY_JOP_CD, --	�޿�����[PAY_JOP_CD]
								OLD_CNT_SALARY, --	����������
								dbo.XF_CEIL(CNT_SALARY * @n_up_rate, -1) AS CNT_SALARY, --	����������
								dbo.XF_CEIL(BASE_SALARY * @n_up_rate, -1) AS BASE_SALARY, --	�⺻��
								BP01, --	�����ݾ�
								BP02, --	����(����)
								BP03, --	����(�߰�)
								BP04, --	����(����)
								BP05, --	�����ٷνð�
								BP06, --	������������
								BP07, --	������������
								BP08, --	���󿩹����޿���
								BP09, --	��������������
								BP10, --	BP10
								NOTE, --	���
								MOD_USER_ID, --	������
								MOD_DATE, --	������
								TZ_CD, --	Ÿ�����ڵ�
								TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_CNM_CNT
						 WHERE PEB_CNM_CNT_ID = @PEB_CNM_CNT_ID
						END
					ELSE
						BEGIN
							PRINT '�ɰ��� ����'
							UPDATE PEB_CNM_CNT
							   SET CNT_SALARY = dbo.XF_CEIL(CNT_SALARY * @n_up_rate, -1) --	����������
								 , BASE_SALARY = dbo.XF_CEIL(BASE_SALARY * @n_up_rate, -1) --	�⺻��
							 WHERE PEB_CNM_CNT_ID = @PEB_CNM_CNT_ID
						END
					FETCH NEXT FROM CUR_PEB_CNM_CNT
								INTO @PEB_CNM_CNT_ID, @d_cnm_sta_ymd, @d_cnm_end_ymd
				END
		END
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

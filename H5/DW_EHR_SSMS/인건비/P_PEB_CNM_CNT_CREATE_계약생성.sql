SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_PEB_CNM_CNT_CREATE]
	@av_company_cd      nVARCHAR(10),       -- �λ翵��
    @av_locale_cd       nVARCHAR(10),       -- �����ڵ�
    @an_peb_base_id     NUMERIC(38,0),      -- �ΰǺ����id
	@ad_base_ymd		DATE,
	@av_emp_no			NVARCHAR(10),		-- �����
    @av_tz_cd           NVARCHAR(10),		-- Ÿ�����ڵ�
    @an_mod_user_id     NUMERIC(38,0)  ,    -- ������ ID
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
			  AND (@av_emp_no IS NULL OR MST.EMP_NO = @av_emp_no)
	/** �ΰǺ��ȹ ����� **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID, EMP_NO, POS_GRD_CD, POS_YMD-- POS_GRD_YMD
		  FROM PEB_PHM_MST MST
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
		   AND (@av_emp_no IS NULL OR MST.EMP_NO = @av_emp_no)

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
			SELECT @n_up_rate = NULL, @v_peb_mm = NULL
		END
		
    --<DOCLINE> ********************************************************
    --<DOCLINE> �ΰǺ� ��� ����
    --<DOCLINE> ********************************************************
	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST
				INTO @PEB_PHM_MST_ID, @EMP_NO, @POS_GRD_CD, @POS_GRD_YMD
	WHILE @@FETCH_STATUS = 0
		BEGIN
			-- �޿��׷�
			set @v_pay_group = dbo.F_PEB_GET_PAY_GROUP(@PEB_PHM_MST_ID)
			BEGIN Try
				-- ��ູ��
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
						BP12, --	�⺻�޻�������[PAY_BAS_TYPE_CD]
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
						--ISNULL(@d_end_ymd, CNM.END_YMD)	END_YMD, --	�����������
						'29991231'	as END_YMD, --	�����������
						CNM.PRE_END_YMD	PRE_END_YMD, --	���������
						MST.POS_GRD_CD	PAY_POS_GRD_CD, --	�޿������ڵ�[PAY_POS_GRD_CD]
						CNM.PAY_GRADE	PAY_GRADE, --	�޿�ȣ��[PAY_GRADE]
						CNM.PAY_JOP_CD	PAY_JOP_CD, --	�޿�����[PAY_JOP_CD]
						CNM.CNT_SALARY	OLD_CNT_SALARY, --	����������
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
						CNM.BP12	BP12, --	�⺻�޻�������[PAY_BAS_TYPE_CD]
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
				-- �����λ��� �ݿ�
				IF @@ROWCOUNT > 0
					IF @n_up_rate IS NOT NULL
						BEGIN
							--PRINT '�����λ��� �ݿ�'
							SELECT @d_sta_ymd = dbo.XF_TO_DATE( @v_base_yyyy + @v_peb_mm + '01', 'yyyymmdd')
								 , @d_end_ymd = dbo.XF_DATEADD( dbo.XF_TO_DATE( @v_base_yyyy + @v_peb_mm + '01', 'yyyymmdd'), - 1)
							DECLARE CUR_PEB_CNM_CNT CURSOR LOCAL FOR
								SELECT PEB_CNM_CNT_ID, STA_YMD, END_YMD
								  FROM PEB_CNM_CNT
								 WHERE PEB_BASE_ID = @an_peb_base_id
								   AND EMP_NO = @EMP_NO
								   AND @d_sta_ymd BETWEEN STA_YMD AND END_YMD
							OPEN CUR_PEB_CNM_CNT
							FETCH NEXT FROM CUR_PEB_CNM_CNT
										INTO @PEB_CNM_CNT_ID, @d_cnm_sta_ymd, @d_cnm_end_ymd
							WHILE @@FETCH_STATUS = 0
								BEGIN
									IF @d_cnm_sta_ymd < @d_sta_ymd
										BEGIN
											--PRINT '�ɰ���-�λ�'
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
												BP12, --	�⺻�޻�������[PAY_BAS_TYPE_CD]
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
												BP12, --	�⺻�޻�������[PAY_BAS_TYPE_CD]
												NOTE, --	���
												MOD_USER_ID, --	������
												MOD_DATE, --	������
												TZ_CD, --	Ÿ�����ڵ�
												TZ_DATE --	Ÿ�����Ͻ�
										  FROM PEB_CNM_CNT
										 WHERE PEB_CNM_CNT_ID = @PEB_CNM_CNT_ID
										END
									FETCH NEXT FROM CUR_PEB_CNM_CNT
												INTO @PEB_CNM_CNT_ID, @d_cnm_sta_ymd, @d_cnm_end_ymd
								END
							
							CLOSE CUR_PEB_CNM_CNT
							DEALLOCATE CUR_PEB_CNM_CNT
						END
				-- ����ó��
				SET @n_peb_cnm_cnt_id = 0
				--PRINT '����ó��'
				--DECLARE CUR_PAYROLL CURSOR LOCAL FOR
				IF OBJECT_ID('tempdb..#TEMP_PAYROLL') IS NOT NULL
					DROP TABLE #TEMP_PAYROLL
					SELECT MST.EMP_NO, CNM.PEB_CNM_CNT_ID, CNM.STA_YMD, CNM.END_YMD, PAY.PEB_YM, CNM.PAY_POS_GRD_CD, PAY.POS_GRD_CD
					  INTO #TEMP_PAYROLL
					  FROM PEB_PHM_MST MST
					  JOIN PEB_CNM_CNT CNM
					    ON MST.PEB_BASE_ID = CNM.PEB_BASE_ID
					   AND MST.EMP_NO = CNM.EMP_NO
					  JOIN PEB_PAYROLL PAY
					    ON MST.PEB_PHM_MST_ID = PAY.PEB_PHM_MST_ID
					   AND PAY.PEB_YM BETWEEN FORMAT(CNM.STA_YMD,'yyyyMM') AND FORMAT(CNM.END_YMD, 'yyyyMM')
					 WHERE MST.PEB_BASE_ID = @an_peb_base_id
					   AND MST.EMP_NO = @EMP_NO
					   --AND 1 = 2
					   --AND CNM.PAY_POS_GRD_CD != PAY.POS_GRD_CD -- �����ڵ尡 Ʋ�����
					 ORDER BY MST.EMP_NO, PAY.PEB_YM
				DECLARE CUR_PAYROLL CURSOR LOCAL FOR
				  SELECT PEB_CNM_CNT_ID, STA_YMD, END_YMD, PEB_YM, PAY_POS_GRD_CD, POS_GRD_CD
				    FROM #TEMP_PAYROLL
				   ORDER BY EMP_NO, PEB_YM
				DECLARE @pay_n_peb_cnm_cnt_id numeric(38)
				      , @pay_d_sta_ymd date
					  , @pay_end_ymd date
					  , @pay_peb_ym nvarchar(6)
					  , @pay_pay_pos_grd_cd nvarchar(10)
					  , @pay_pos_grd_cd nvarchar(10)
					  , @work_pos_grd_cd nvarchar(10) = ''
					  , @work_pay_peb_ym nvarchar(10) = ''
					  , @work_sta_ymd date
					  , @work_end_ymd date
					  , @work_cnm_cnt_id numeric(38,0) = 0
				OPEN CUR_PAYROLL
				FETCH NEXT FROM CUR_PAYROLL
							INTO @pay_n_peb_cnm_cnt_id, @pay_d_sta_ymd
							  , @pay_end_ymd, @pay_peb_ym
							  , @pay_pay_pos_grd_cd, @pay_pos_grd_cd
				WHILE @@FETCH_STATUS = 0
					BEGIN
										--print ',pay_peb_ym='           + ISNULL(@pay_peb_ym , '')
										--    + ',pay_n_peb_cnm_cnt_id=' + ISNULL(format(@pay_n_peb_cnm_cnt_id,'')   , '')
										--    + ',pay_d_sta_ymd='        + ISNULL(format(@pay_d_sta_ymd, 'yyyyMMdd') , '')
										--    + ',pay_end_ymd='          + ISNULL(format(@pay_end_ymd, 'yyyyMMdd')   , '')
										--    + ',work_cnm_cnt_id='      + ISNULL(format(@work_cnm_cnt_id,'')		   , '')
										--    + ',work_sta_ymd='         + ISNULL(format(@work_sta_ymd, 'yyyyMMdd')  , '')
										--    + ',work_end_ymd='         + ISNULL(format(@work_end_ymd, 'yyyyMMdd')  , '')

						IF @work_pos_grd_cd != @pay_pay_pos_grd_cd
						OR @work_pos_grd_cd != @pay_pos_grd_cd
							BEGIN
								IF @pay_pay_pos_grd_cd != @pay_pos_grd_cd AND @work_pos_grd_cd != @pay_pos_grd_cd
									BEGIN	-- Ʋ���� �ɰ���.
										select @work_pos_grd_cd = @pay_pos_grd_cd
										-- �⺻����
					select @n_pos_grd_base_amt = dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_POS_GRD_BASE_AMT',
										NULL, NULL, NULL, NULL, NULL,
										@v_pay_group, @work_pos_grd_cd, NULL, NULL, NULL,
										@v_base_yyyy + '1231',
										'H1' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
										))
					set @n_pos_grd_base_amt = dbo.XF_CEIL(@n_pos_grd_base_amt / 12, -1);
					if @n_pos_grd_base_amt <= 0
						set @n_pos_grd_base_amt = NULL
										IF @work_cnm_cnt_id = 0
											set @work_cnm_cnt_id = @pay_n_peb_cnm_cnt_id
										set @work_sta_ymd = dbo.XF_TO_DATE(@pay_peb_ym + '01', 'yyyyMMdd')
										set @work_end_ymd = dbo.XF_DATEADD(@work_sta_ymd, -1)
										IF @pay_peb_ym > FORMAT(@pay_d_sta_ymd, 'yyyyMM')
											BEGIN
												--PRINT '�ɰ���1:' + @pay_peb_ym
												UPDATE PEB_CNM_CNT
												   SET END_YMD = @work_end_ymd
												 WHERE PEB_CNM_CNT_ID = @work_cnm_cnt_id
												--
												select @n_peb_cnm_cnt_id = NEXT VALUE FOR S_PEB_SEQUENCE
											END
										ELSE
											BEGIN
												--PRINT '����:' + @pay_peb_ym
												UPDATE PEB_CNM_CNT
												   SET BASE_SALARY = ISNULL(@n_pos_grd_base_amt, BASE_SALARY)
												     , PAY_POS_GRD_CD = @work_pos_grd_cd
													-- , END_YMD = @work_end_ymd
												 WHERE PEB_CNM_CNT_ID = @work_cnm_cnt_id
											END
										IF @pay_peb_ym > FORMAT(@pay_d_sta_ymd, 'yyyyMM')
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
												BP12, --	�⺻�޻�������[PAY_BAS_TYPE_CD]
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
												@work_sta_ymd STA_YMD, --	����������
												@pay_end_ymd END_YMD, --	�����������
												PRE_END_YMD, --	���������
												@work_pos_grd_cd PAY_POS_GRD_CD, --	�޿������ڵ�[PAY_POS_GRD_CD]
												PAY_GRADE, --	�޿�ȣ��[PAY_GRADE]
												PAY_JOP_CD, --	�޿�����[PAY_JOP_CD]
												OLD_CNT_SALARY, --	����������
												CNT_SALARY, --	����������
												ISNULL(@n_pos_grd_base_amt, BASE_SALARY) AS BASE_SALARY, --	�⺻��
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
												BP12, --	�⺻�޻�������[PAY_BAS_TYPE_CD]
												NOTE, --	���
												MOD_USER_ID, --	������
												MOD_DATE, --	������
												TZ_CD, --	Ÿ�����ڵ�
												TZ_DATE --	Ÿ�����Ͻ�
										  FROM PEB_CNM_CNT
										 WHERE PEB_CNM_CNT_ID = @work_cnm_cnt_id
											set @work_cnm_cnt_id = @n_peb_cnm_cnt_id
										END
										--print 'work_cnm_cnt_id=' + format(@work_cnm_cnt_id,'')
										--    + ',pay_peb_ym=' + @pay_peb_ym
										--    + ',work_sta_ymd=' + format(@work_sta_ymd, 'yyyyMMdd')
										--    + ',pay_end_ymd=' + format(@pay_end_ymd, 'yyyyMMdd')
									END
							END
							
						IF FORMAT(@pay_end_ymd, 'yyyyMM') = @pay_peb_ym
							set @work_cnm_cnt_id = 0
						set @work_pos_grd_cd = @pay_pos_grd_cd
						FETCH NEXT FROM CUR_PAYROLL
									INTO @pay_n_peb_cnm_cnt_id, @pay_d_sta_ymd
									  , @pay_end_ymd, @pay_peb_ym
									  , @pay_pay_pos_grd_cd, @pay_pos_grd_cd
					END
				CLOSE CUR_PAYROLL
				DEALLOCATE CUR_PAYROLL
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
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

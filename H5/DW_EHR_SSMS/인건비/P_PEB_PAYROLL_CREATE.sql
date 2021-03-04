USE [dwehrdev_H5]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_PEB_PAYROLL_CREATE]
		@an_peb_base_id			NUMERIC,
		@av_company_cd			NVARCHAR(10),
		@ad_base_ymd			DATE,
		@an_pay_org_id			NUMERIC,
		@av_emp_no				NVARCHAR(10),
		@av_locale_cd			NVARCHAR(10),
		@av_tz_cd				NVARCHAR(10),    -- Ÿ�����ڵ�
		@an_mod_user_id			NUMERIC(18,0)  ,    -- ������ ID
		@av_ret_code			NVARCHAR(100)    OUTPUT,
		@av_ret_message			NVARCHAR(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ ��������ܻ���
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PAYROLL_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ ����������� ����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2020.09.10
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
			, @PEB_PHM_MST_ID	 NUMERIC
			, @v_base_yyyy			NVARCHAR(04) -- ���س⵵
			, @d_peb_sta_ymd		DATE
			, @d_peb_end_ymd		DATE
			, @d_std_ymd			DATE
			, @v_company_cd			NVARCHAR(10)
			, @v_pay_group			NVARCHAR(50) -- �޿��׷�
			, @v_next_pos_grd_mm	NVARCHAR(06) -- ���� ���� ��������
			, @v_next_pos_mm		NVARCHAR(06) -- ���� ���� ��������
			, @v_next_pos_grd_cd	NVARCHAR(50) -- ���� ����
			, @v_next_pos_cd		NVARCHAR(50) -- ���� ����

    SET @v_program_id   = 'P_PEB_PAYROLL_CREATE'
    SET @v_program_nm   = '�ΰǺ��ȹ ��������� ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);

	SELECT @d_peb_sta_ymd = STA_YMD
	     , @d_peb_end_ymd = END_YMD
		 , @d_std_ymd     = STD_YMD
		 , @v_company_cd  = COMPANY_CD
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id
	IF @@ROWCOUNT < 1
		BEGIN
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� ��ȹ�� �����ϴ�.[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0100,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
		END
	/** �ΰǺ��ȹ ��������� **/
	DECLARE CUR_PHM_EMP CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID
			FROM PEB_PHM_MST MST
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
		   AND (@an_pay_org_id IS NULL OR MST.PAY_ORG_ID = @an_pay_org_id)
		   AND (ISNULL(@av_emp_no,'') = '' OR MST.EMP_NO = @av_emp_no)
	OPEN CUR_PHM_EMP
	FETCH NEXT FROM CUR_PHM_EMP INTO @PEB_PHM_MST_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> �ΰǺ� ��������� ����
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				DELETE FROM PEB_PAYROLL
				 WHERE PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				-- �޿��׷�
				set @v_pay_group = dbo.F_PEB_GET_PAY_GROUP(@PEB_PHM_MST_ID)
				-- �������üũ ( ����, ���� )
				select @v_next_pos_grd_mm = dbo.XF_TO_CHAR_D( DATEADD(YEAR, dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_POS_GRD_BASE',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, A.POS_GRD_CD, NULL, NULL, NULL,
									@d_peb_sta_ymd, 'H1' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
									)), A.POS_GRD_YMD), 'yyyy' + 
									-- �ݿ���
										dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_MONTH',
										NULL, NULL, NULL, NULL, NULL,
										@v_pay_group, 'POS_GRD', NULL, NULL, NULL,
										@d_peb_sta_ymd, 'H1' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
										)
									)
					 , @v_next_pos_grd_cd = dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_POS_GRD_BASE',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, A.POS_GRD_CD, NULL, NULL, NULL,
									@d_peb_sta_ymd, 'H2' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
									)
					 , @v_next_pos_mm = dbo.XF_TO_CHAR_D( DATEADD(YEAR, dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_POS_BASE',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, A.POS_GRD_CD, NULL, NULL, NULL,
									@d_peb_sta_ymd, 'H1' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
									)), A.POS_GRD_YMD), 'yyyy' + 
									-- �ݿ���
										dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_MONTH',
										NULL, NULL, NULL, NULL, NULL,
										@v_pay_group, 'POS', NULL, NULL, NULL,
										@d_peb_sta_ymd, 'H1' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
										)
									)
					 , @v_next_pos_cd = dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_POS_BASE',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, A.POS_CD, NULL, NULL, NULL,
									@d_peb_sta_ymd, 'H2' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
									)
				  FROM PEB_PHM_MST A
				 WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID

				INSERT INTO PEB_PAYROLL(
						PEB_PAYROLL_ID, --	������ȹ�ο�ID
						PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						PEB_YM, --	���
						JOB_POSITION_CD, -- �����ڵ�
						POS_GRD_CD, --	�����ڵ� [PHM_POS_GRD_CD]
						POS_CD, --	�����ڵ� [PHM_POS_CD]
						DUTY_CD, --	��å�ڵ� [PHM_DUTY_CD]
						YEARNUM_CD, --	ȣ���ڵ� [PHM_YEARNUM_CD]
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	������
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_ID,
						MST.PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						CALENDAR.MONTH_ID PEB_YM, --	���
						MST.JOB_POSITION_CD, -- �����ڵ�
						--MST.POS_GRD_CD, --	�����ڵ� [PHM_POS_GRD_CD]
						CASE WHEN @v_next_pos_grd_mm <= MONTH_ID AND SUBSTRING(@v_next_pos_grd_mm,5,2) <= MM THEN @v_next_pos_grd_cd
						     ELSE MST.POS_GRD_CD END,
						--MST.POS_CD, --	�����ڵ� [PHM_POS_CD]
						CASE WHEN @v_next_pos_mm <= MONTH_ID AND SUBSTRING(@v_next_pos_mm,5,2) <= MM THEN @v_next_pos_cd
						     ELSE MST.POS_CD END, -- ���� �����ڵ�
						MST.DUTY_CD, --	��å�ڵ� [PHM_DUTY_CD]
						CASE WHEN (SELECT SYS_CD FROM FRM_CODE WHERE COMPANY_CD=@v_company_cd AND CD_KIND='PAY_SALARY_TYPE_CD' AND CD=MST.SALARY_TYPE_CD AND @d_std_ymd BETWEEN STA_YMD AND END_YMD)
						          = '002' THEN -- ȣ�����̸�
								  CASE WHEN dbo.XF_TO_CHAR_D( MST.YEARNUM_YMD, 'MM') <= CALENDAR.MM THEN
								  RIGHT( dbo.XF_TO_CHAR_N( dbo.XF_TO_NUMBER( MST.YEARNUM_CD ) - 2, '0000') , LEN(MST.YEARNUM_CD))
								       ELSE MST.YEARNUM_CD END
							 ELSE MST.YEARNUM_CD END AS NEW_YEARNUM_CD, --	ȣ���ڵ� [PHM_YEARNUM_CD]
						NULL	NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
				  FROM PEB_PHM_MST MST
				  INNER JOIN (SELECT DISTINCT SUBSTRING(YMD,1,6) MONTH_ID, SUBSTRING(YMD, 5, 2) MM
									FROM FRM_CALENDAR C
									WHERE YMD BETWEEN @d_peb_sta_ymd and @d_peb_end_ymd) CALENDAR
				   ON dbo.XF_TO_CHAR_D( MST.HIRE_YMD, 'YYYYMM') <= MONTH_ID
				 WHERE MST.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� ��������ܻ����� ���� �߻��߽��ϴ�.[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_EMP INTO @PEB_PHM_MST_ID
		END
	CLOSE CUR_PHM_EMP
	DEALLOCATE CUR_PHM_EMP
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

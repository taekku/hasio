SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER     PROCEDURE [dbo].[P_PEB_PAYROLL_CALC]
	@an_peb_base_id		NUMERIC,
	@av_company_cd      NVARCHAR(10),
	@ad_base_ymd		DATE,
	@av_cal_emp_no		NVARCHAR(MAX),
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- Ÿ�����ڵ�
    @an_mod_user_id     NUMERIC(18,0)  ,    -- ������ ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ �ΰǺ���
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PAYROLL_CALC
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ �ΰǺ���
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2020.09.15
    --<DOCLINE> ***************************************************************************
BEGIN
	SET NOCOUNT ON;
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id		NVARCHAR(30)
      , @v_program_nm		NVARCHAR(100)
      , @v_ret_code			NVARCHAR(100)
      , @v_ret_message		NVARCHAR(500)

	  , @PEB_PHM_MST_ID		NUMERIC
	  , @EMP_NO				NVARCHAR(20)
	  , @d_peb_sta_ymd		DATE
	  , @d_peb_end_ymd		DATE
	  , @v_company_cd		NVARCHAR(10)
	  , @v_pay_item_cd		NVARCHAR(10)
	  , @v_salary_sys_cd	NVARCHAR(10)

	  , @n_base_salary		NUMERIC -- �⺻��
	  , @n_base_hour		NUMERIC -- �����ٷνð�
	  , @n_ordwage_hour		NUMERIC(18) -- ����ӱ�
	  , @n_ordwage_amt		NUMERIC(18) -- ����ӱ�
	  , @n_dtm_year_amt		NUMERIC(18) -- �����ݾ�
	  , @n_insur_rate		NUMERIC(5,3) -- �������
	  , @n_peb_rate			NUMERIC(18,2) -- �λ���/�ݾ�

	DECLARE @tmp_emp_no TABLE (
		EMP_NO NVARCHAR(20),
		PRIMARY KEY (EMP_NO)
	)

	SET @v_program_id   = 'P_PEB_PAYROLL_CALC'
	SET @v_program_nm   = '�ΰǺ��ȹ �ΰǺ���'
	SET @av_ret_code    = 'SUCCESS!'
	SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
										@v_program_id,  0000,  NULL, NULL);

	SELECT @d_peb_sta_ymd = STA_YMD
	     , @d_peb_end_ymd = END_YMD
		 , @v_company_cd = COMPANY_CD
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
	-- ����ڸ� ����
	INSERT INTO @tmp_emp_no(EMP_NO)
	SELECT ITEMS
	  FROM dbo.fn_split_array(@av_cal_emp_no, ',')
	IF @av_cal_emp_no IS NULL
		INSERT INTO @tmp_emp_no(EMP_NO)
		SELECT EMP_NO
		  FROM PEB_PHM_MST
		 WHERE PEB_BASE_ID = @an_peb_base_id
	-- �۾��� �ڷ� ����
	DELETE FROM A
	  FROM PEB_PAYROLL_DETAIL A
	  JOIN PEB_PAYROLL B
	    ON A.PEB_PAYROLL_ID = B.PEB_PAYROLL_ID
	  JOIN PEB_PHM_MST MST
	    ON B.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	  JOIN @tmp_emp_no EMP
	    ON MST.EMP_NO = EMP.EMP_NO

	/** �ΰǺ��ȹ ��������� **/
	DECLARE CUR_PHM_EMP CURSOR LOCAL FOR
		SELECT MST.PEB_PHM_MST_ID
		     , MST.EMP_NO
			 , (SELECT SYS_CD FROM FRM_CODE WHERE COMPANY_CD = @v_company_cd
											  AND CD_KIND='PAY_SALARY_TYPE_CD' AND CD = MST.SALARY_TYPE_CD)
				AS SALARY_SYS_CD --�޿����� type ���� (001(������),002(ȣ����),003(�ϱ���),004(�ñ���))
			FROM PEB_PHM_MST MST
			JOIN @tmp_emp_no EMP
			  ON MST.PEB_BASE_ID = @an_peb_base_id
			 AND MST.EMP_NO = EMP.EMP_NO
		 WHERE (1=1)
		   AND MST.PEB_BASE_ID = @an_peb_base_id
		 ORDER BY MST.PEB_PHM_MST_ID

	OPEN CUR_PHM_EMP
	FETCH NEXT FROM CUR_PHM_EMP INTO @PEB_PHM_MST_ID, @EMP_NO, @v_salary_sys_cd

    --<DOCLINE> ********************************************************
    --<DOCLINE> �ΰǺ� ��������� ����
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			PRINT 'START:' + @EMP_NO
			BEGIN TRY
				-- �⺻��
				SET @v_pay_item_cd = 'P001'
				-- @v_salary_sys_cd : 001(������),002(ȣ����),003(�ϱ���),004(�ñ���)
			PRINT '@v_salary_sys_cd:' + @v_salary_sys_cd
				IF @v_salary_sys_cd = '001' -- ������
					BEGIN
						-- �⺻��
						SET @v_pay_item_cd = 'P001'
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd	PAY_ITEM_CD, --	�޿��׸��ڵ� -- �⺻��
								C.BASE_SALARY AS	CAM_AMT, --	���ݾ�
								'����-�⺻��'	NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL A
						  JOIN PEB_CNM_CNT C
							ON A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						   AND C.PEB_BASE_ID = @an_peb_base_id
						   AND C.EMP_NO = @EMP_NO
						   AND A.PEB_YM BETWEEN dbo.XF_TO_CHAR_D(STA_YMD, 'yyyymm') AND dbo.XF_TO_CHAR_D( END_YMD, 'yyyymm')
						-- �����ݾ�
						SET @v_pay_item_cd = 'P003'
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd	PAY_ITEM_CD, --	�޿��׸��ڵ� -- �����ݾ�
								C.BP01 AS	CAM_AMT, --	���ݾ�
								'����-�����ݾ�'	NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL A
						  JOIN PEB_CNM_CNT C
							ON A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						   AND C.PEB_BASE_ID = @an_peb_base_id
						   AND C.EMP_NO = @EMP_NO
						   AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN STA_YMD AND END_YMD
						   AND ISNULL(C.BP01,0) <> 0
					END
				ELSE IF @v_salary_sys_cd = '002' -- ȣ����
					BEGIN
						-- �⺻��
						SET @v_pay_item_cd = 'P001'
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd	PAY_ITEM_CD, --	�޿��׸��ڵ� -- �⺻��
								B.PAY_AMT AS	CAM_AMT, --	���ݾ�
								'ȣ��-�⺻��'	NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL A
						  JOIN PEB_PHM_MST M
						    ON A.PEB_PHM_MST_ID = M.PEB_PHM_MST_ID
						  LEFT OUTER JOIN PAY_SHIP_RATE S
						               ON M.PAY_ORG_ID = S.PAY_ORG_ID
									  AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN S.STA_YMD AND S.END_YMD
						  JOIN PEB_PAY_HOBONG B
							ON B.PEB_BASE_ID = @an_peb_base_id
						   AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN B.STA_YMD AND B.END_YMD
						   AND M.PAY_BIZ_CD = B.BIZ_CD
						   AND A.POS_GRD_CD = B.PAY_POS_GRD_CD
						   AND A.YEARNUM_CD = B.PAY_GRADE
						   AND M.PAY_BIZ_CD = B.BIZ_CD
						   AND (A.POS_GRD_CD != '600'
						         OR     A.POS_CD = B.POS_CD
						            AND S.SHIP_CD = B.SHIP_CD -- ���ںз�
						            AND S.SHIP_CD_D = B.SHIP_CD_D -- ���ڻ󼼺з�
						       )
						 WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						   --AND 
						IF @@ROWCOUNT < 1
							BEGIN
								SET @av_ret_message = dbo.F_FRM_ERRMSG( '���[' + @EMP_NO + ']�� ���� �⺻���� �� �� �����ϴ�.[ERR]' ,
														@v_program_id,  1009,  null, null
													)
								SET @av_ret_code    = 'FAILURE!'
								RETURN
							END
					END
				--ELSE IF @v_salary_sys_cd = '003' -- �ϱ���
				--	BEGIN
				--	END
				--ELSE IF @v_salary_sys_cd = '002' -- �ñ���
				--	BEGIN
				--	END
				ELSE
					BEGIN
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '���[' + @EMP_NO + ']�� ���� �޿�����[' +ISNULL(@v_salary_sys_cd,'NULL')+ ']�� �⺻���� �� �� �����ϴ�.[ERR]' ,
												@v_program_id,  1009,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
					END
					
				---------------------------
				-- ����󿩱�
				---------------------------
				set @v_pay_item_cd = 'P300' -- �󿩱�
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
					PEB_PAYROLL_ID, --	������ȹ�ο�ID
					PAY_ITEM_CD, --	�޿��׸��ڵ�
					CAM_AMT, --	���ݾ�
					NOTE, --	���
					MOD_USER_ID, --	������
					MOD_DATE, --	������
					TZ_CD, --	Ÿ�����ڵ�
					TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
						@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
						CASE WHEN B.PEB_APP_BASE_CD='20' THEN
							B.PEB_RATE / 100 * (SELECT ISNULL(SUM(CAM_AMT),0) FROM PEB_PAYROLL_DETAIL
							                           WHERE PEB_PAYROLL_ID=A.PEB_PAYROLL_ID
													     AND PAY_ITEM_CD IN ('P001','P003'))
							ELSE 0 END AS	CAM_AMT, --	���ݾ�
						'����' NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
					FROM PEB_PAYROLL A
					JOIN PEB_RATE B
					  ON B.PEB_BASE_ID = @an_peb_base_id
					 AND B.PEB_TYPE_CD = '130' -- �󿩱�
					WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				---------------------------
				-- ������
				---------------------------
				set @v_pay_item_cd = 'P303' -- ������
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
					PEB_PAYROLL_ID, --	������ȹ�ο�ID
					PAY_ITEM_CD, --	�޿��׸��ڵ�
					CAM_AMT, --	���ݾ�
					NOTE, --	���
					MOD_USER_ID, --	������
					MOD_DATE, --	������
					TZ_CD, --	Ÿ�����ڵ�
					TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
						@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
						CASE WHEN B.PEB_APP_BASE_CD='20' THEN
							B.PEB_RATE / 100 * (SELECT ISNULL(SUM(CAM_AMT),0) FROM PEB_PAYROLL_DETAIL
							                           WHERE PEB_PAYROLL_ID=A.PEB_PAYROLL_ID
													     AND PAY_ITEM_CD IN ('P001','P003'))
							ELSE 0 END AS	CAM_AMT, --	���ݾ�
						'����' NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
					FROM PEB_PAYROLL A
					JOIN PEB_RATE B
					  ON B.PEB_BASE_ID = @an_peb_base_id
					 AND B.PEB_TYPE_CD = '131' -- Ÿ���
					 AND SUBSTRING(A.PEB_YM,5,2) = B.PEB_YM
					WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				---------------------------
				-- Ÿ���
				---------------------------
				/*
				140	����	P302	�����󿩱�
				141	���ͼ���	P550	�ͼ���
				150	�߼���	P302	�����󿩱�
				151	�߼��ͼ���	P550	�ͼ���
				160	�ް���	P530	�ް���
				220	Ÿ���	P111	Ÿ���
				 */
				set @v_pay_item_cd = 'P111' -- Ÿ���
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
					PEB_PAYROLL_ID, --	������ȹ�ο�ID
					PAY_ITEM_CD, --	�޿��׸��ڵ�
					CAM_AMT, --	���ݾ�
					NOTE, --	���
					MOD_USER_ID, --	������
					MOD_DATE, --	������
					TZ_CD, --	Ÿ�����ڵ�
					TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
						--@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
						CASE
						WHEN B.PEB_TYPE_CD IN ('140','150') THEN 'P302'
						WHEN B.PEB_TYPE_CD IN ('141','151') THEN 'P550'
						WHEN B.PEB_TYPE_CD IN ('160') THEN 'P530'
						WHEN B.PEB_TYPE_CD IN ('220') THEN 'P111'
						ELSE B.PEB_TYPE_CD END AS PAY_ITEM_CD, -- �޿��׸��ڵ�
						B.PEB_RATE AS	CAM_AMT, --	���ݾ�
						'����' NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
					FROM PEB_PAYROLL A
					JOIN PEB_RATE B
					  ON B.PEB_BASE_ID = @an_peb_base_id
					 --AND B.PEB_TYPE_CD = '220' -- Ÿ���
					 AND B.PEB_TYPE_CD in ('140','141','150','151','160','220')
					 AND SUBSTRING(A.PEB_YM,5,2) = B.PEB_YM
					WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				
				---------------------------
				-- �ΰǺ� - ��å����
				---------------------------
				set @v_pay_item_cd = 'P004' -- ��å����
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
					PEB_PAYROLL_ID, --	������ȹ�ο�ID
					PAY_ITEM_CD, --	�޿��׸��ڵ�
					CAM_AMT, --	���ݾ�
					NOTE, --	���
					MOD_USER_ID, --	������
					MOD_DATE, --	������
					TZ_CD, --	Ÿ�����ڵ�
					TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
						@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
						dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_BASE_DUTY',
								NULL, NULL, NULL, NULL, NULL,
								A.DUTY_CD, NULL, NULL, NULL, NULL,
								getDate(),
								'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
																		-- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
								) AS	CAM_AMT, --	���ݾ�
						'����' NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
					FROM PEB_PAYROLL A
					WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
					AND dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_BASE_DUTY',
								NULL, NULL, NULL, NULL, NULL,
								A.DUTY_CD, NULL, NULL, NULL, NULL,
								getDate(),
								'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
																		-- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
								) IS NOT NULL -- ��å�� ���� ���رݾ��� �ִ� ���
				
				
				---------------------------
				-- �ΰǺ� - ������
				---------------------------
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
					PEB_PAYROLL_ID, --	������ȹ�ο�ID
					PAY_ITEM_CD, --	�޿��׸��ڵ�
					CAM_AMT, --	���ݾ�
					NOTE, --	���
					MOD_USER_ID, --	������
					MOD_DATE, --	������
					TZ_CD, --	Ÿ�����ڵ�
					TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
						I.PAY_ITEM_CD PAY_ITEM_CD, --	�޿��׸��ڵ�
						I.BASE_AMT AS	CAM_AMT, --	���ݾ�
						I.NOTE NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
					FROM PEB_PAYROLL A
					JOIN PEB_PHM_ITEM I
					  ON A.PEB_PHM_MST_ID = I.PEB_PHM_MST_ID
				   WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				     AND NOT EXISTS (SELECT * FROM PEB_PAYROLL_DETAIL WHERE PEB_PAYROLL_ID = A.PEB_PAYROLL_ID AND PAY_ITEM_CD = I.PAY_ITEM_CD)
					 
				---------------------------
				-- �ΰǺ� - ��������Ʈ
				---------------------------
				set @v_pay_item_cd = 'P152' -- ��Ÿ����
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
					PEB_PAYROLL_ID, --	������ȹ�ο�ID
					PAY_ITEM_CD, --	�޿��׸��ڵ�
					CAM_AMT, --	���ݾ�
					NOTE, --	���
					MOD_USER_ID, --	������
					MOD_DATE, --	������
					TZ_CD, --	Ÿ�����ڵ�
					TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
						@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
						PNT.PAY_AMT AS	CAM_AMT, --	���ݾ�
						PNT.NOTE NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
					FROM PEB_PAYROLL A
					JOIN PEB_PNT_MNG PNT
					  ON A.PEB_PHM_MST_ID = PNT.PEB_PHM_MST_ID
					 AND A.PEB_YM = dbo.XF_TO_CHAR_D( PNT.PAY_YMD, 'YYYYMM')
				   WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				---------------------------
				-- �ΰǺ� - ���ڱ�
				---------------------------
				set @v_pay_item_cd = 'P500' -- ���ڱ�
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
					PEB_PAYROLL_ID, --	������ȹ�ο�ID
					PAY_ITEM_CD, --	�޿��׸��ڵ�
					CAM_AMT, --	���ݾ�
					NOTE, --	���
					MOD_USER_ID, --	������
					MOD_DATE, --	������
					TZ_CD, --	Ÿ�����ڵ�
					TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
						@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
						SUM(ISNULL(SCH.CNF_AMT,0)) AS	CAM_AMT, --	���ݾ�
						'' NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
					FROM PEB_PAYROLL A
					JOIN PEB_SCH_MNG SCH
					  ON A.PEB_PHM_MST_ID = SCH.PEB_PHM_MST_ID
					 --AND A.PEB_YM = dbo.XF_TO_CHAR_D( SCH.REQ_YMD, 'YYYYMM')
					 AND A.PEB_YM = FORMAT( SCH.REQ_YMD, 'yyyyMM')
				   WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				   GROUP BY A.PEB_PAYROLL_ID
					 
				---------------------------
				-- �ΰǺ� - ����OT
				---------------------------
				set @v_pay_item_cd = 'P002' -- ����OT
				INSERT INTO PEB_PAYROLL_DETAIL(
					PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
					PEB_PAYROLL_ID, --	������ȹ�ο�ID
					PAY_ITEM_CD, --	�޿��׸��ڵ�
					CAM_AMT, --	���ݾ�
					NOTE, --	���
					MOD_USER_ID, --	������
					MOD_DATE, --	������
					TZ_CD, --	Ÿ�����ڵ�
					TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
						@v_pay_item_cd	PAY_ITEM_CD, --	�޿��׸��ڵ� -- ����OT
						CONVERT(NUMERIC,C.BP02) * CONVERT(NUMERIC(5,1), 1.5) * (SELECT ISNULL(SUM(CAM_AMT) / CONVERT(NUMERIC(5), C.BP05), 0)
											  FROM PEB_PAYROLL_DETAIL
											 WHERE PEB_PAYROLL_ID = A.PEB_PAYROLL_ID
										   AND PAY_ITEM_CD IN (SELECT HIS.KEY_CD2 AS CD
																  FROM FRM_UNIT_STD_MGR MGR
																	   INNER JOIN FRM_UNIT_STD_HIS HIS
																			   ON MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
																			  AND MGR.UNIT_CD = 'PEB'
																			  AND MGR.STD_KIND = 'PEB_ORDWAGE_ITEM'
																 WHERE MGR.COMPANY_CD = 'E'
																   AND MGR.LOCALE_CD = 'KO'
																   AND GETDATE() BETWEEN HIS.STA_YMD AND HIS.END_YMD
																   AND HIS.KEY_CD1 = 'EA01'))
							AS	CAM_AMT, --	���ݾ�
						'����-����OT'	NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
					FROM PEB_PAYROLL A
					JOIN PEB_CNM_CNT C
					ON A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
					AND C.PEB_BASE_ID = @an_peb_base_id
					AND C.EMP_NO = @EMP_NO
					AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN  C.STA_YMD AND C.END_YMD
					AND ISNULL(C.BP02,0) <> 0
				---------------------------
				-- �ΰǺ� - �߰�OT
				---------------------------
				set @v_pay_item_cd = 'P021' -- �߰�OT
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
								OT.OT * 1.5 * (SELECT ISNULL(SUM(CAM_AMT) / CONVERT(NUMERIC, C.BP05) , 0)
											  FROM PEB_PAYROLL_DETAIL
											 WHERE PEB_PAYROLL_ID = A.PEB_PAYROLL_ID
										   AND PAY_ITEM_CD IN (SELECT HIS.KEY_CD2 AS CD
																  FROM FRM_UNIT_STD_MGR MGR
																	   INNER JOIN FRM_UNIT_STD_HIS HIS
																			   ON MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
																			  AND MGR.UNIT_CD = 'PEB'
																			  AND MGR.STD_KIND = 'PEB_ORDWAGE_ITEM'
																 WHERE MGR.COMPANY_CD = 'E'
																   AND MGR.LOCALE_CD = 'KO'
																   AND GETDATE() BETWEEN HIS.STA_YMD AND HIS.END_YMD
																   AND HIS.KEY_CD1 = 'EA01'))
									AS	CAM_AMT, --	���ݾ�
								NULL NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL A
						  JOIN PEB_PHM_MST M
						    ON A.PEB_PHM_MST_ID = M.PEB_PHM_MST_ID
						  JOIN PEB_CNM_CNT C
						    ON A.PEB_PHM_MST_ID = M.PEB_PHM_MST_ID
						   AND C.PEB_BASE_ID = M.PEB_BASE_ID
						   AND C.EMP_NO = M.EMP_NO
						   AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN  C.STA_YMD AND C.END_YMD
						  JOIN PEB_MON_OT OT
						    ON A.PEB_PAYROLL_ID = OT.PEB_PAYROLL_ID
						WHERE M.PEB_BASE_ID = @an_peb_base_id
						  AND M.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						  AND ISNULL(OT.OT, 0) <> 0
				---------------------------
				-- �ΰǺ� - ����
				---------------------------
				set @v_pay_item_cd = 'P050' -- ����
				select @n_dtm_year_amt = DTM.UN_USE_CNT * CASE WHEN M.MGR_TYPE_CD='O' THEN 1 -- ����
													  WHEN M.MGR_TYPE_CD='9' THEN 1.5
								                      ELSE 1 END --1.5
								            * (SELECT ISNULL(SUM(CAM_AMT) / CONVERT(NUMERIC, C.BP05) , 0) * 8
											  FROM PEB_PAYROLL_DETAIL
											 WHERE PEB_PAYROLL_ID = A.PEB_PAYROLL_ID
										   AND PAY_ITEM_CD IN (SELECT HIS.KEY_CD2 AS CD
																  FROM FRM_UNIT_STD_MGR MGR
																	   INNER JOIN FRM_UNIT_STD_HIS HIS
																			   ON MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
																			  AND MGR.UNIT_CD = 'PEB'
																			  AND MGR.STD_KIND = 'PEB_ORDWAGE_ITEM'
																 WHERE MGR.COMPANY_CD = 'E'
																   AND MGR.LOCALE_CD = 'KO'
																   AND GETDATE() BETWEEN HIS.STA_YMD AND HIS.END_YMD
																   AND HIS.KEY_CD1 = 'EA01'))
									--	�����ݾ�
						  FROM PEB_PAYROLL A
						  JOIN PEB_PHM_MST M
						    ON A.PEB_PHM_MST_ID = M.PEB_PHM_MST_ID
						  JOIN PEB_CNM_CNT C
						    ON A.PEB_PHM_MST_ID = M.PEB_PHM_MST_ID
						   AND C.PEB_BASE_ID = M.PEB_BASE_ID
						   AND C.EMP_NO = M.EMP_NO
						   AND dbo.XF_TO_DATE( A.PEB_YM + '01', 'yyyymmdd') BETWEEN  C.STA_YMD AND C.END_YMD
						  JOIN PEB_DTM_MNG DTM
						    ON M.PEB_PHM_MST_ID = DTM.PEB_PHM_MST_ID
						WHERE M.PEB_BASE_ID = @an_peb_base_id
						  AND M.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						  AND ISNULL(DTM.UN_USE_CNT, 0) <> 0
						  AND A.PEB_YM = (SELECT MAX(PEB_YM) FROM PEB_PAYROLL WHERE PEB_PHM_MST_ID = @PEB_PHM_MST_ID)
					IF @@ROWCOUNT > 0 
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								A.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
								@n_dtm_year_amt / (select COUNT(*) FROM PEB_PAYROLL WHERE PEB_PHM_MST_ID = @PEB_PHM_MST_ID)
									AS	CAM_AMT, --	���ݾ�
								NULL NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL A
						WHERE PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						  AND @n_dtm_year_amt > 0
				-- 4�뺸��
				set @v_pay_item_cd = 'D910' -- ���ο���ȸ��δ��
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * (SELECT COMP_RATE FROM PEB_STP_RATE WHERE COMPANY_CD=@av_company_cd AND PEB_YM + '01' BETWEEN STA_YMD AND END_YMD) / 100, -1)
									AS	CAM_AMT, --	���ݾ�
								NULL NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD NOT IN ('D910','D920','D925','D930','D940','D950')
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
				set @v_pay_item_cd = 'D920' -- �ǰ�����ȸ��δ��
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * (SELECT COMP_RATE FROM PEB_NHS_RATE WHERE COMPANY_CD=@av_company_cd AND INSURE_CD='01' AND PEB_YM + '01' BETWEEN STA_YMD AND END_YMD) / 100, -1)
									AS	CAM_AMT, --	���ݾ�
								NULL NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD NOT IN ('D910','D920','D925','D930','D940','D950')
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
				set @v_pay_item_cd = 'D925' -- ����纸��ȸ��δ��
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * (SELECT COMP_RATE FROM PEB_NHS_RATE WHERE COMPANY_CD=@av_company_cd AND INSURE_CD='02' AND PEB_YM + '01' BETWEEN STA_YMD AND END_YMD) / 100, -1)
									AS	CAM_AMT, --	���ݾ�
								NULL NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD = 'D920'
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
				set @v_pay_item_cd = 'D930' -- ��뺸��ȸ��δ��
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * (SELECT ISNULL(UNEMP_RATE_O,0) + ISNULL(EMP_RATE_O,0) + ISNULL(ABLILTY_RATE_O,0) FROM PEB_EMI_RATE WHERE COMPANY_CD=@av_company_cd AND PEB_YM + '01' BETWEEN STA_YMD AND END_YMD) / 100 , -1)
									AS	CAM_AMT, --	���ݾ�
								NULL NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD NOT IN ('D910','D920','D925','D930','D940','D950')
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
				set @v_pay_item_cd = 'D940' -- ���纸��ȸ��δ��
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * ISNULL(dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_IAI_RATE',
										NULL, NULL, NULL, NULL, NULL,
										MST.PHM_BIZ_CD, NULL, NULL, NULL, NULL,
										getDate(),
										'H1'),0 ) / 100 , -1)
									AS	CAM_AMT, --	���ݾ�
								NULL NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD NOT IN ('D910','D920','D925','D930','D940','D950')
						  JOIN PEB_PHM_MST MST
						    ON ROLL.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY MST.PHM_BIZ_CD, ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
				set @v_pay_item_cd = 'D950' -- ��������
				SELECT @n_peb_rate = PEB_RATE
				  FROM PEB_RATE
				 WHERE PEB_BASE_ID = @an_peb_base_id
				   AND PEB_TYPE_CD = '300'
				IF @@ROWCOUNT > 0 AND @n_peb_rate > 0
					BEGIN
						INSERT INTO PEB_PAYROLL_DETAIL(
							PEB_PAYROLL_DET_ID, --	�ΰǺ�����ID
							PEB_PAYROLL_ID, --	������ȹ�ο�ID
							PAY_ITEM_CD, --	�޿��׸��ڵ�
							CAM_AMT, --	���ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
						)
						SELECT NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
								ROLL.PEB_PAYROLL_ID, --	������ȹ�ο�ID
								@v_pay_item_cd PAY_ITEM_CD, --	�޿��׸��ڵ�
								--dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) / 12 * ISNULL(@n_peb_rate, 0) / 100 , -1)
								dbo.XF_TRUNC_N(SUM(DTL.CAM_AMT) * ISNULL(@n_peb_rate, 0) / 100 , -1)
									AS	CAM_AMT, --	���ݾ�
								NULL NOTE, --	���
								@an_mod_user_id	MOD_USER_ID, --	������
								SYSDATETIME()	MOD_DATE, --	������
								@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
								SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						  FROM PEB_PAYROLL_DETAIL DTL
						  JOIN PEB_PAYROLL ROLL
							ON ROLL.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
						   AND DTL.PAY_ITEM_CD NOT IN ('D910','D920','D925','D930','D940','D950')
						  JOIN PEB_PHM_MST MST
						    ON ROLL.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
						 WHERE ROLL.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
						 GROUP BY MST.PHM_BIZ_CD, ROLL.PEB_PAYROLL_ID, ROLL.PEB_YM
					END
			END TRY
			BEGIN Catch
					print 'Err' + error_message()
					SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ��ȹ �ΰǺ����� ������ �߻��߽��ϴ�.[ERR]' + ERROR_MESSAGE() + CONVERT(NVARCHAR(100), ERROR_LINE()),
											@v_program_id,  0150,  null, null
										)
					SET @av_ret_code    = 'FAILURE!'
					RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_EMP INTO @PEB_PHM_MST_ID, @EMP_NO, @v_salary_sys_cd
		END
	CLOSE CUR_PHM_EMP
	DEALLOCATE CUR_PHM_EMP
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_DTM_MNG_CREATE]
		@an_peb_base_id			NUMERIC,
		@av_company_cd      NVARCHAR(10),
		@ad_base_ymd				DATE,
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- Ÿ�����ڵ�
    @an_mod_user_id     NUMERIC(18,0)  ,    -- ������ ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ �����ڷ� ����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_DTM_MNG_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ �����ڷ� ����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2020.09.08
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @PEB_PHM_MST_ID		NUMERIC
	  , @v_base_yyyy		NVARCHAR(04) -- ���س⵵
	  , @d_peb_sta_ymd		DATE
	  , @d_peb_end_ymd		DATE
	  , @d_std_ymd			DATE
	  , @v_company_cd		NVARCHAR(10)
	  , @v_pay_group		NVARCHAR(50) -- �޿��׷�
	  , @n_year_gen_cnt		NUMERIC --	1��̸��߻�
	  , @n_gen_cnt			NUMERIC --	�߻�����
	  , @n_wk_gen_cnt		NUMERIC --	�ټӹ߻�����
	  , @n_use_cnt			NUMERIC --	����ϼ�
	  , @n_un_use_cnt		NUMERIC --	�̻���ϼ�

    SET @v_program_id   = 'P_PEB_DTM_MNG_CREATE'
    SET @v_program_nm   = '�ΰǺ��ȹ �����ڷ� ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
  -- �����ڷ� ����
	DELETE FROM PEB_DTM_MNG
		FROM PEB_DTM_MNG A
		JOIN PEB_PHM_MST MST
		  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id

	SELECT @d_peb_sta_ymd = STA_YMD
	     , @d_peb_end_ymd = END_YMD
		 , @d_std_ymd     = STD_YMD
		 , @v_company_cd  = COMPANY_CD
		 , @v_base_yyyy   = BASE_YYYY
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id

	/** �ΰǺ��ȹ ����� **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID
			FROM PEB_PHM_MST MST
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id

	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID
    --<DOCLINE> ********************************************************
    --<DOCLINE> �ΰǺ� �������� ����
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				SELECT @v_pay_group = dbo.F_PEB_GET_PAY_GROUP(@PEB_PHM_MST_ID)
				SELECT @n_year_gen_cnt = case when dbo.XF_TO_CHAR_D(dbo.XF_ADD_MONTH( A.ANNUAL_CAL_YMD, 12), 'yyyy') >= @v_base_yyyy THEN
											dbo.F_DTM_YY_NUM_FAKE(@v_company_cd, @av_locale_cd, A.ANNUAL_CAL_YMD,
												dbo.XF_TO_CHAR_D( dbo.XF_ADD_MONTH(A.ANNUAL_CAL_YMD, 11), 'yyyymm')
											)
											else 0 end
					 , @n_gen_cnt = dbo.F_DTM_YY_NUM_PURE(@v_company_cd, @av_locale_cd, A.ANNUAL_CAL_YMD, @v_base_yyyy)
					 , @n_wk_gen_cnt = 0
					 , @n_use_cnt = ISNULL( dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@v_company_cd, @av_locale_cd, 'PEB', 'PEB_DTM_USE',
									NULL, NULL, NULL, NULL, NULL,
									@v_pay_group, NULL, NULL, NULL, NULL,
									@d_peb_sta_ymd, 'H1' -- 'H1' : �ڵ�1,  'E1' : ��Ÿ�ڵ�1
									) ), 0)
				  FROM PEB_PHM_MST A
				 WHERE PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				IF @n_gen_cnt > 0
					set @n_year_gen_cnt = 0
				set @n_use_cnt = case
								 when @n_use_cnt > (@n_year_gen_cnt + @n_gen_cnt + @n_wk_gen_cnt) then
										(@n_year_gen_cnt + @n_gen_cnt + @n_wk_gen_cnt)
								 else @n_use_cnt end
				set @n_un_use_cnt = (@n_year_gen_cnt + @n_gen_cnt + @n_wk_gen_cnt) - @n_use_cnt
				INSERT INTO PEB_DTM_MNG(
						PEB_DTM_MNG_ID, --	�ΰǺ���ID
						PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						YEAR_GEN_CNT, --	1��̸��߻�
						GEN_CNT, --	�߻�����
						WK_GEN_CNT, --	�ټӹ߻�����
						USE_CNT, --	����ϼ�
						UN_USE_CNT, --	�̻���ϼ�
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	������
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
						A.PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						@n_year_gen_cnt YEAR_GEN_CNT, --	1��̸��߻�
						@n_gen_cnt GEN_CNT, --	�߻�����
						@n_wk_gen_cnt WK_GEN_CNT, --	�ټӹ߻�����
						@n_use_cnt USE_CNT, --	����ϼ�
						@n_un_use_cnt UN_USE_CNT, --	�̻���ϼ�
						NULL	NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
				  FROM PEB_PHM_MST A
				 WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� �λ��� INSERT ����[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

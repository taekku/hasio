SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_PNT_MNG_CREATE]
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
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ ��������Ʈ ����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PNT_MNG_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ ��������Ʈ ����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2020.09.14
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @PEB_PHM_MST_ID	NUMERIC
		, @STA_YMD DATE
		, @END_YMD DATE
		, @COMPANY_CD NVARCHAR(10)
		, @BASE_YYYY NVARCHAR(10)
		, @CAT_PAY_MGR_ID	NUMERIC

    SET @v_program_id   = 'P_PEB_SCH_MNG_CREATE'
    SET @v_program_nm   = '�ΰǺ��ȹ ��������Ʈ ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
  -- �����ڷ� ����
	DELETE FROM PEB_PNT_MNG
		FROM PEB_PNT_MNG A
		JOIN PEB_PHM_MST MST
		  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id
	SELECT @BASE_YYYY = BASE_YYYY
	     , @COMPANY_CD = COMPANY_CD
			 , @STA_YMD = STA_YMD
			 , @END_YMD = END_YMD
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id
	/** �ΰǺ��ȹ ����� **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID, CAT_PAY_MGR_ID
			FROM PEB_PHM_MST MST
			JOIN PHM_EMP EMP
			  ON EMP.COMPANY_CD = @COMPANY_CD
			 AND MST.EMP_NO = EMP.EMP_NO
			 AND MST.PEB_BASE_ID = @an_peb_base_id
			JOIN CAT_PAY_MGR CAT
			  ON EMP.EMP_ID = CAT.EMP_ID
			 --AND CAT.PAY_YMD BETWEEN @STA_YMD AND @END_YMD
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
		   AND DATEPART(YEAR, CAT.GIVE_YMD) = (@BASE_YYYY - 1)
		   AND CAT.CONF_CD = 'Y' -- ���޵���
	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @CAT_PAY_MGR_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> �ΰǺ� ��������Ʈ ����
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				INSERT INTO PEB_PNT_MNG(
						PEB_PNT_MNG_ID, --	�ΰǺ�������ƮID
						PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						PAY_YMD, --	��������
						PAY_AMT, --	����Ʈ�ݾ�
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	������
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
						@PEB_PHM_MST_ID	PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						dbo.XF_ADD_MONTH(A.GIVE_YMD, 12)	PAY_YMD, --	��������
						A.POINT + A.BIRTH_POINT	PAY_AMT, --	����Ʈ�ݾ�
						NULL	NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
				  FROM CAT_PAY_MGR A
				 WHERE CAT_PAY_MGR_ID = @CAT_PAY_MGR_ID
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� ��������Ʈ INSERT ����[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @CAT_PAY_MGR_ID
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

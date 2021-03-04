SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_SCH_MNG_CREATE]
	@an_peb_base_id		NUMERIC(38),
	@av_company_cd      NVARCHAR(10),
	@ad_base_ymd		DATE,
	@an_org_id			NUMERIC(38),
	@av_emp_no			NVARCHAR(10),
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- Ÿ�����ڵ�
    @an_mod_user_id     NUMERIC(38)  ,    -- ������ ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ ���ڱ� ����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_SCH_MNG_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ ���ڱ� ����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2020.09.08
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @PEB_PHM_MST_ID	NUMERIC(38)
		, @STA_YMD DATE
		, @END_YMD DATE
		, @COMPANY_CD NVARCHAR(10)
		, @BASE_YYYY NVARCHAR(10)
		, @SEC_EDU_ID	NUMERIC(38)

    SET @v_program_id   = 'P_PEB_SCH_MNG_CREATE'
    SET @v_program_nm   = '�ΰǺ��ȹ ���ڱ��ڷ� ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
	SELECT @BASE_YYYY = BASE_YYYY
	     , @COMPANY_CD = COMPANY_CD
			 , @STA_YMD = STA_YMD
			 , @END_YMD = END_YMD
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id

  -- �����ڷ� ����
	DELETE FROM A
		FROM PEB_SCH_MNG A
		JOIN PEB_PHM_MST MST
		  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id
	/** �ΰǺ��ȹ ����� **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID, SEC_EDU_ID
			FROM PEB_PHM_MST MST
			JOIN PHM_EMP EMP
			  ON EMP.COMPANY_CD = @COMPANY_CD
			 AND MST.EMP_NO = EMP.EMP_NO
			 AND MST.PEB_BASE_ID = @an_peb_base_id
			JOIN SEC_EDU SEC
			  ON EMP.EMP_ID = SEC.EMP_ID
			 AND DATEPART(YEAR, SEC.PAY_YMD) = (dbo.XF_TO_NUMBER( @BASE_YYYY ) - 1)
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @SEC_EDU_ID

 --   --<DOCLINE> ********************************************************
 --   --<DOCLINE> �ΰǺ� ���ڱ� ����
 --   --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			print @SEC_EDU_ID
			BEGIN Try
				INSERT INTO PEB_SCH_MNG(
						PEB_SCH_MNG_ID, --	�ΰǺ����ڱ�ID
						PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						REQ_YMD, --	��û����
						FAM_NM, --	�ڳ༺��
						SCH_GRD_CD, --	�з±���
						SCH_NM, --	�б���
						SCH_GRADE, --	�г�
						SCH_TERM, --	�б�
						ENT_AMT, --	���б�
						TUI_AMT, --	������
						OPE_SUP_AMT, --	�������
						PRAT_AMT, --	�ǽ���
						STD_UNI_AMT, --	�л�ȸ��
						BOOK_AMT, --	��������
						ENT_CON_AMT, --	�������ϱ�
						FOOD_AMT, --	�޽ĺ�
						REQ_AMT, --	��û�ݾ�
						CNF_AMT, --	Ȯ���ݾ�
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	������
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
						@PEB_PHM_MST_ID	PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						dbo.XF_ADD_MONTH(PAY_YMD, 12)	REQ_YMD, --	��û����
						A.FAM_NM	FAM_NM, --	�ڳ༺��
						A.SCH_GRD_CD	SCH_GRD_CD, --	�з±���
						A.SCH_NM	SCH_NM, --	�б���
						A.EDU_POS	SCH_GRADE, --	�г�
						A.SCE_EDU_TERM	SCH_TERM, --	�б�
						0	ENT_AMT, --	���б�
						0	TUI_AMT, --	������
						0	OPE_SUP_AMT, --	�������
						0	PRAT_AMT, --	�ǽ���
						0	STD_UNI_AMT, --	�л�ȸ��
						0	BOOK_AMT, --	��������
						0	ENT_CON_AMT, --	�������ϱ�
						0	FOOD_AMT, --	�޽ĺ�
						A.APPL_AMT	REQ_AMT, --	��û�ݾ�
						A.CONFIRM_AMT	CNF_AMT, --	Ȯ���ݾ�
						NULL	NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
				  FROM SEC_EDU A
				 WHERE SEC_EDU_ID = @SEC_EDU_ID
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� ���ڱ� INSERT ����[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @SEC_EDU_ID
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

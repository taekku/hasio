SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_MON_OT_CREATE]
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
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ ����OT����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_MON_OT_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ ����OT ����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2020.09.08
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @PEB_MON_OT_UPLOAD_ID	NUMERIC

    SET @v_program_id   = 'P_PEB_PHM_MST_CREATE'
    SET @v_program_nm   = '�ΰǺ��ȹ ����OT ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
  -- �����ڷ� ����
	DELETE FROM PEB_MON_OT
		FROM PEB_MON_OT A
		JOIN PEB_PAYROLL PAY
		  ON PAY.PEB_PAYROLL_ID = A.PEB_PAYROLL_ID
		JOIN PEB_PHM_MST MST
		  ON PAY.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id
	/** �ΰǺ��ȹ ����� **/
	DECLARE CUR_UPLOAD CURSOR LOCAL FOR
		SELECT PEB_MON_OT_UPLOAD_ID
			FROM PEB_MON_OT_UPLOAD A
			JOIN PEB_PHM_MST MST
			  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
	OPEN CUR_UPLOAD
	FETCH NEXT FROM CUR_UPLOAD INTO @PEB_MON_OT_UPLOAD_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> �ΰǺ� ����OT ����
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				--PRINT 'UPLOAD_ID ' + CONVERT(VARCHAR(100), @PEB_MON_OT_UPLOAD_ID)
				INSERT INTO PEB_MON_OT(
						PEB_MON_OT_ID, --	�ΰǺ����OT����ID
						PEB_PAYROLL_ID, --	������ȹ�ο�ID
						OT, --	OT�ð�
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	������
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
						A.PEB_PAYROLL_ID,
						OT.OT_TIME,
						NULL	NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
				  FROM (SELECT *
									FROM (SELECT MST.PEB_BASE_ID, T.*
													FROM PEB_PHM_MST MST
													JOIN PEB_MON_OT_UPLOAD T
								  					ON MST.PEB_PHM_MST_ID = T.PEB_PHM_MST_ID
												 WHERE T.PEB_MON_OT_UPLOAD_ID = @PEB_MON_OT_UPLOAD_ID
											 ) A
											 UNPIVOT ( OT_TIME FOR MON_COL IN (MON_01, MON_02, MON_03, MON_04, MON_05, MON_06, MON_07, MON_08, MON_09, MON_10, MON_11, MON_12) )  UNPVT1
										) OT
					JOIN PEB_PAYROLL A
						ON A.PEB_PHM_MST_ID = OT.PEB_PHM_MST_ID
					 AND RIGHT(A.PEB_YM,2) = RIGHT(MON_COL,2)
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� �λ��� INSERT ����[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_UPLOAD INTO @PEB_MON_OT_UPLOAD_ID
		END
	CLOSE CUR_UPLOAD
	DEALLOCATE CUR_UPLOAD
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

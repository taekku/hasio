SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_PEB_RATE_CREATE]
		@av_company_cd      NVARCHAR(10),
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- Ÿ�����ڵ�
    @an_mod_user_id     NUMERIC(18,0)  ,    -- ������ ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ �λ��� �⺻ ����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : �̵���
    --<DOCLINE>   PROGRAM_ID  : P_PEB_RATE_CREATE
    --<DOCLINE>   ARGUMENT    : P_PEB_RATE_CREATE('01', 'KO', 'KST', 11 )
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ ���ذ��� ���� �� �λ������� �⺻����
    --<DOCLINE>                 - �λ��������� �⺻���� ���� ��� ����
    --<DOCLINE>   HISTORY     : �ۼ� �̵��� 2013.12.10
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @CD				NVARCHAR(50)
	  , @PEB_BASE_ID	NUMERIC
	  , @myCd			NVARCHAR(50)

	/** �λ����� ���� ���ذ��� ��ȸ **/
	DECLARE CUR_LIST CURSOR LOCAL FOR
		SELECT PEB_BASE_ID
	      FROM PEB_BASE
		 WHERE PEB_BASE_ID NOT IN ( SELECT DISTINCT PEB_BASE_ID
									  FROM PEB_RATE )

	/** �ΰǺ� ���� �����ڵ� **/
	DECLARE CUR_CODE CURSOR LOCAL FOR
		SELECT CD
			FROM FRM_CODE
			WHERE CD_KIND = 'PEB_RATE_TYPE_CD'
			AND COMPANY_CD = @av_company_cd
			AND LOCALE_CD = @av_locale_cd
			AND GROUP_USE_YN = 'Y'
			AND dbo.XF_SYSDATE(0) BETWEEN STA_YMD AND END_YMD

    SET @v_program_id   = 'P_PEB_RATE_CREATE'
    SET @v_program_nm   = '�ΰǺ��ȹ �λ��� �⺻ ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
	OPEN CUR_LIST
	FETCH NEXT FROM CUR_LIST INTO @PEB_BASE_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> �λ��� �⺻ ����
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			OPEN CUR_CODE 
			FETCH NEXT FROM CUR_CODE INTO @CD
			--set @myCd = isnull(@CD,':') + @av_company_cd + @av_locale_cd + dbo.XF_TO_CHAR_N( @@FETCH_STATUS, default)
			--<DOCLINE> �ΰǺ� ���� �����ڵ� ��ȸ �� ����
			WHILE(@@FETCH_STATUS = 0)
				BEGIN Try
					INSERT INTO PEB_RATE( PEB_RATE_ID    -- �ΰǺ��λ�������ID
                                        , PEB_BASE_ID    -- �ΰǺ��ȹ����ID
                                        , PEB_TYPE_CD    -- �ΰǺ񱸺�
                                        , PEB_RATE       -- �λ���
                                        --, ETC_CD1        -- ��Ÿ1
                                        --, ETC_CD2        -- ��Ÿ2
                                        , NOTE           -- ���
                                        , MOD_USER_ID    -- ������
                                        , MOD_DATE       -- �����Ͻ�
                                        , TZ_CD          -- Ÿ�����ڵ�
                                        , TZ_DATE        -- Ÿ�����Ͻ�
                                 ) VALUES (
                                        NEXT VALUE FOR S_PEB_SEQUENCE
                                        , @PEB_BASE_ID    -- �ΰǺ��ȹ����ID
                                        , @CD        -- �ΰǺ񱸺�
                                        , 0                 -- �λ���
                                        --, NULL
                                        --, NULL
                                        , NULL
                                        , @an_mod_user_id
                                        , dbo.XF_SYSDATE(0)
                                        , @av_tz_cd
                                        , dbo.XF_SYSDATE(0)
									)
					IF @@ERROR <> 0
						BEGIN
							SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� �λ��� INSERT ����[ERR]',
													@v_program_id,  0150,  null, null
												)
							SET @av_ret_code    = 'FAILURE!'
							RETURN
						END
					FETCH NEXT FROM CUR_CODE INTO @CD
				END Try
				BEGIN Catch
							SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� �λ��� INSERT ����[ERR]' + ERROR_MESSAGE(),
													@v_program_id,  0150,  null, null
												)
							SET @av_ret_code    = 'FAILURE!'
							RETURN
				END CATCH
			CLOSE CUR_CODE
			--DEALLOCATE CUR_CODE

			FETCH NEXT FROM CUR_LIST INTO @PEB_BASE_ID
		END
	CLOSE CUR_LIST
	DEALLOCATE CUR_LIST
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

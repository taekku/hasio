SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PAY_MST_CHANGE_INSERT] (
    @av_company_cd              NVARCHAR(100),            -- �λ翵��
    @av_locale_cd               NVARCHAR(100),            -- ���
    @an_emp_id                  NUMERIC,                  -- ���id
    @av_pay_item_cd             NVARCHAR(10),            -- �޿��׸�����ڵ�
    @av_pay_item_value          NVARCHAR(50),            -- ����Ÿ
    @av_pay_item_value_text     NVARCHAR(100),            -- ����Ÿ ����
    @ad_sta_ymd                 DATE,                     -- ��������
    @ad_end_ymd                 DATE,                     -- ��������
    @an_pay_ymd_id              NUMERIC,                  -- ����޿�����ID(���κ��ұޱ޿����� ���̺� ���� �޿� ����)
    @an_in_pay_ymd_id           NUMERIC,                  -- �޿����� ID (���ʿ��忡 ���� ��쿡�� �ѱ�� �ƴϸ� NULL�� �ѱ�, ���ʿ��忡 ��ϵ� �޿�����)
    @av_salary_type_cd          NVARCHAR(50),            -- ������� �޿�����
    @av_retro_type              NVARCHAR(50),            -- �ұ� ���� [1 :��� �������� �ұ�, 2 : ���� ���������� �ұ�, 3: �ұ� ����]
    @av_pay_type_cd             NVARCHAR(50),            -- ��������
    @an_bel_org_id              NUMERIC,                  -- �ͼӺμ�id
    @av_tz_cd                   NVARCHAR(50),            -- Ÿ�����ڵ�
    @an_mod_user_id             NUMERIC,                  -- ������ ���id
    @av_ret_code                NVARCHAR(1000) OUTPUT,    -- SUCCESS!/FAILURE!
    @av_ret_message             NVARCHAR(1000) OUTPUT     -- ����޽���
) AS
    -- ***************************************************************************
    --   TITLE       : �޿����ʿ��� TABLE INSERT
    --   PROJECT     : ���λ������ý���
    --   AUTHOR      : ������
    --   PROGRAM_ID  : P_PAY_MST_CHANGE_INSERT
    --   ARGUMENT    :
    --   RETURN      :
    --   COMMENT     : **�޿����ʿ��� TABLE INSERT  (��������Ÿ�� ���,�޿��׸���غ��� ��¥�� ��ġ�� �ʴ°��� ��Ģ�̴�)
    --                   ��������Ÿ�� �Ⱓ�� ���� ���� ���� �׳� RETURN �Ѵ�.
    --                   ELSE ��������Ÿ�� �Ⱓ�� ���� ���� �ٸ��� ��������Ÿ��  �������� N �� �ϰ� ���ο� ����Ÿ�� INSERT �Ѵ�.
    --                   ELSE ��������Ÿ�� �Ⱓ�� ��ĥ ��� ��������Ÿ�� �������� N �� �ϰ� ��ġ�� ����Ÿ�� ���ο� ����Ÿ�� ��ġ��
    --                         �ʰ� INSERT �ϰ� ���ο� ����Ÿ�� INSERT �Ѵ�. (���ο� ����Ÿ�� ������ ������ ��������Ÿ��  insert ���� �ʴ´�.)
    --                 **�Ⱓ���ӿ��δ��� 'N' �̸� ��������Ÿ�� ���ο� ����Ÿ�� ��ġ�� �������� N ��  ���ο� ����Ÿ�� INSERT �Ѵ�.
    --                 **�޿� �Ƿڿ����� ������� ������
    --                 **  �ұ��Ҷ� ����Ⱓ�� �������ڸ� ������� üũ�ϱ� ���� ����Ⱓ�� ���� �޾ƾ� �ұ�? ������ �����ε�
    --                     �켱�� ���´� �˾Ƽ� �ұ����ڰ��� ���̺� �־���.
    --   HISTORY     : �ۼ� ������ 2006.08.30
    --               : 2020.03.30 - MS-SQL ��ȯ�۾� : ������
    -- ***************************************************************************
DECLARE

    /* ���� ���� (�����ڵ� ó���� ���) */
    @v_program_id            NVARCHAR(30),
    @v_program_nm            NVARCHAR(100),
    @n_cnt                   NUMERIC,
    @at_pay_mst_change       NUMERIC,
    @d_sta_ymd               DATE,
    @d_end_ymd               DATE,
    @d_mst_sta_ymd           DATE,
    @v_retro_chk_sta_ymd     DATE = NULL,
    @v_retro_check_yn        CHAR(1),
    @v_day_retro_yn          NVARCHAR(1),      -- ���Ұ��(������)���� �ұ�  ���� ���� Y/N
    @v_term_yn               CHAR(1),          -- �Ⱓ ���� ����
    @v_retro_type            NVARCHAR(1),      -- �ұ� ���� [1 :��� �������� �ұ�, 2 : ���� ���������� �ұ�, 3: �ұ� ����]
    @v_rest_cal_yn           CHAR(1),          -- �������� ��꿩��
    @v_cd_kind               NVARCHAR(50),     -- �ڵ�з� ( ����Ÿ �� �ֱ� ����)

    @errornumber             INT,
    @errormessage            NVARCHAR(4000)

BEGIN

    /* �⺻���� �ʱⰪ ���� */
    SET @v_program_id    = 'P_PAY_MST_CHANGE_INSERT'                 -- ���� ���ν����� ������
    SET @v_program_nm    = '[���ʿ��� TABLE INSERT]'                  -- ���� ���ν����� �ѱ۸�

    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = DBO.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null, @an_mod_user_id)

    SET @errornumber   = ERROR_NUMBER()
    SET @errormessage  = ERROR_MESSAGE()

    -- ������ ���Ұ�� ���Ϸ��� ������ ������ ��찡 �ִµ�.. ��������  ������ ���� ū�� ���� ��� �߻��ؼ� �׳� ����
    IF @ad_sta_ymd > @ad_end_ymd
        RETURN

    SET @d_mst_sta_ymd = @ad_sta_ymd
    SET @v_retro_type  = @av_retro_type

    -- ***********************************************************************************************************
    -- 1.�޿��Ƿ����ڰ� ������ ������ ����ϰ� ���ν����� ���� ������.
    --   ���ʿ��� ������ ó���� �޿��Ƿ����ڰ� ������ ��� �����ϱ� ����
    -- ***********************************************************************************************************

    IF @an_in_pay_ymd_id IS NOT NULL

        BEGIN

            -- ȭ�鿡�� ������ ��찡 �־ �������� 'N' ���� �ִ´�.
            BEGIN TRY

                UPDATE PAY_MST_CHANGE
                   SET LAST_YN = 'N'
                 WHERE EMP_ID          =  @an_emp_id           -- ���ID
                   AND PAY_ITEM_CD     =  @av_pay_item_cd      -- �޿��׸�����ڵ�[PAY_ITEM_CD]
                   AND SALARY_TYPE_CD  =  @av_salary_type_cd   -- �޿��׸�����ڵ�[PAY_ITEM_CD]
                   AND LAST_YN         =  'Y'                  -- ��������Ÿ����
                   AND PAY_YMD_ID      =  @an_in_pay_ymd_id

            END TRY
            BEGIN CATCH

                SET @errornumber    = ERROR_NUMBER()
                SET @errormessage   = ERROR_MESSAGE()
                
                SET @av_ret_code    = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('PAY_MST_CHANGE ������Ʈ ���� �߻� [ERR]', @v_program_id , 0128, @errormessage, @an_mod_user_id)
                
                IF @@TRANCOUNT > 0
                    ROLLBACK WORK
                RETURN

            END CATCH


            -- ���ʿ���(�޿���������)
            BEGIN TRY
                INSERT INTO PAY_MST_CHANGE
                (
                    PAY_MST_CHANGE_ID       ,  -- ���ʿ���ID
                    EMP_ID                  ,  -- ���ID
                    SALARY_TYPE_CD          ,  -- �޿�����
                    PAY_ITEM_CD             ,  -- �޿��׸�����ڵ�(PAY_ITEM_CD)
                    PAY_ITEM_VALUE          ,  -- �޿������׸�
                    PAY_ITEM_VALUE_TEXT     ,  -- �޿������׸� ����
                    STA_YMD                 ,  -- ��������
                    END_YMD                 ,  -- ��������
                    LAST_YN                 ,  -- ��������Ÿ����
                    PAY_YMD_ID              ,  -- �޿�����ID(�޿� �Ƿ� ����Ÿ��
                    MOD_USER_ID             ,  -- ������
                    MOD_DATE                ,  -- �����Ͻ�
                    TZ_CD                   ,  -- Ÿ�����ڵ�
                    TZ_DATE                 ,  -- Ÿ�����Ͻ�
                    BEL_ORG_ID              ,  -- �ͼӺμ�id
                    MAKE_PAY_YMD_ID         ,  -- �����ñ޿�����ID(�ұ�üũ�� ���� ����)
                    RETRO_CHK_STA_YMD          -- �ұ�����üũ����
                )
                VALUES
                (
                    NEXT VALUE FOR DBO.S_PAY_SEQUENCE   ,  -- ���ʿ���ID
                    @an_emp_id                  ,    -- ���ID
                    @av_salary_type_cd          ,    -- �޿�����
                    @av_pay_item_cd             ,    -- �޿��׸�����ڵ�(PAY_ITEM_CD)
                    @av_pay_item_value          ,    -- �޿������׸�
                    @av_pay_item_value_text     ,    -- �޿������׸� ����
                    @d_mst_sta_ymd              ,    -- ��������
                    @ad_end_ymd                 ,    -- ��������
                    'Y'                         ,    -- ��������Ÿ����
                    @an_in_pay_ymd_id           ,    -- �޿�����ID(�޿� �Ƿ� ����Ÿ��)
                    @an_mod_user_id             ,    -- ������
                    GETDATE()                   ,    -- �����Ͻ�
                    @av_tz_cd                   ,    -- Ÿ�����ڵ�
                    DBO.F_FRM_GETDATE(GETDATE(), @av_tz_cd)   , -- Ÿ�����Ͻ�
                    @an_bel_org_id              ,    -- �ͼӺμ�id
                    @an_pay_ymd_id              ,    -- �����ñ޿�����ID(�ұ�üũ�� ���� ����)
                    NULL                             -- �ұ�����üũ����
                )
            END TRY
            BEGIN CATCH

                SET @errornumber   = ERROR_NUMBER()
                SET @errormessage  = ERROR_MESSAGE()
                
                SET @av_ret_code    = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('PAY_MST_CHANGE INSERT�� ���� �߻� [ERR]', @v_program_id , 0180, @errormessage, @an_mod_user_id)
                
                IF @@TRANCOUNT > 0
                    ROLLBACK WORK
                
                RETURN

            END CATCH

            RETURN

        END --IF @an_in_pay_ymd_id IS NOT NULL

    -- ***********************************************************************************************************
    -- 2.�ߺ��ڷᰡ ������ �����ϴ��� üũ�Ѵ�
    -- �ߺ��ڷ��� ��� �޿������׸�, �޿������׸� ���� ������Ʈ ��.
    -- ***********************************************************************************************************
    BEGIN

        SELECT @n_cnt = COUNT(*)
          FROM PAY_MST_CHANGE
         WHERE EMP_ID                 =  @an_emp_id                 -- ���ID
           AND PAY_ITEM_CD            =  @av_pay_item_cd            -- �޿��׸�����ڵ�(PAY_ITEM_CD)
           --AND PAY_ITEM_VALUE         =  @av_pay_item_value         -- �޿������׸�
           AND STA_YMD                =  @ad_sta_ymd                -- ��������
           AND END_YMD                =  @ad_end_ymd                -- ��������
           AND LAST_YN                =  'Y'                        -- ��������Ÿ����
           AND SALARY_TYPE_CD         =  @av_salary_type_cd         -- �޿������ڵ�
           AND ISNULL(BEL_ORG_ID, -1) =  ISNULL(@an_bel_org_id, -1) -- �ͼӺμ��� üũ �ʿ�  null �̾��� ��� Ʋ�� ������ ������ ���� nvl ó��

        -- ���ʿ��忡 �������� ���� �� �������� ������ �� �ִ´�.
        -- �޿������׸� ���� UPDATE �Ѵ�
        IF @n_cnt > 0

            BEGIN
                BEGIN TRY
                    UPDATE PAY_MST_CHANGE
                       SET PAY_ITEM_VALUE_TEXT    =  @av_pay_item_value_text    -- �޿������׸� ����
					     , PAY_ITEM_VALUE         =  @av_pay_item_value         -- ��������Ÿ����
                         , MOD_USER_ID            =  @an_mod_user_id            -- ������
                         , MOD_DATE               =  GETDATE()                  -- �����Ͻ�

                     WHERE EMP_ID                 =  @an_emp_id                 -- ���ID
                       AND PAY_ITEM_CD            =  @av_pay_item_cd            -- �޿��׸�����ڵ�(PAY_ITEM_CD)
                       --AND PAY_ITEM_VALUE         =  @av_pay_item_value         -- �޿������׸�
                       AND STA_YMD                =  @ad_sta_ymd                -- ��������
                       AND END_YMD                =  @ad_end_ymd                -- ��������
                       AND LAST_YN                =  'Y'                        -- ��������Ÿ����
                       AND SALARY_TYPE_CD         =  @av_salary_type_cd
                       AND ISNULL(BEL_ORG_ID, -1) =  ISNULL(@an_bel_org_id, -1)
                END TRY
                BEGIN CATCH
                    SET @errornumber   = ERROR_NUMBER()
                    SET @errormessage  = ERROR_MESSAGE()
                    
                    SET @av_ret_code    = 'FAILURE!'
                    SET @av_ret_message = DBO.F_FRM_ERRMSG('PAY_MST_CHANGE UPDATE�� ���� �߻� [ERR]', @v_program_id , 0226, @errormessage, @an_mod_user_id)
                    
                    IF @@TRANCOUNT > 0
                        ROLLBACK WORK
                    RETURN
                END CATCH

                RETURN

            END --IF @n_cnt > 0
    END


    -- ***********************************************************************************************************
    -- 3. �Ⱓ�� ������ ���� Ʋ�� ��� �����ڷ� ���� UPDATE ó�� �ϰ� �����Ѵ�
    -- ***********************************************************************************************************
	/*
    BEGIN

        SELECT @at_pay_mst_change = PAY_MST_CHANGE_ID
          FROM PAY_MST_CHANGE
         WHERE EMP_ID                 =  @an_emp_id               -- ���ID
           AND SALARY_TYPE_CD         =  @av_salary_type_cd       -- �޿������ڵ�
           AND PAY_ITEM_CD            =  @av_pay_item_cd          -- �޿��׸�����ڵ�(PAY_ITEM_CD)
           AND PAY_ITEM_VALUE         <>  @av_pay_item_value      -- �޿������׸�
           AND STA_YMD                =  @ad_sta_ymd              -- ��������
           AND END_YMD                =  @ad_end_ymd              -- ��������
           AND LAST_YN                =  'Y'                      -- ��������Ÿ����
           AND ISNULL(BEL_ORG_ID, -1) = ISNULL(@an_bel_org_id, -1)

        --�ߺ��ڷ� �ڷᰡ ������ ��� �����ڷ� �������� UPDATE �� �ű��ڷ� ����ϰ� �����Ѵ�
        IF @at_pay_mst_change IS NOT NULL

            BEGIN

                BEGIN TRY

                    UPDATE PAY_MST_CHANGE
                    SET PAY_ITEM_VALUE          =  @av_pay_item_value   ,   -- ��������Ÿ����
                        MOD_USER_ID             =  @an_mod_user_id      ,   -- ������
                        MOD_DATE                =  GETDATE()                -- �����Ͻ�
                    WHERE PAY_MST_CHANGE_ID     =  @at_pay_mst_change

                END TRY

                BEGIN CATCH

                    SET @errornumber   = ERROR_NUMBER()
                    SET @errormessage  = ERROR_MESSAGE()

                    SET @av_ret_code = 'FAILURE!'
                    SET @av_ret_message = DBO.F_FRM_ERRMSG('[�Ⱓ�� ������ ���� Ʋ�� ���UPDATE] (' + DBO.F_FRM_CODE_NM(@av_company_cd , @av_locale_cd, 'PAY_ITEM_CD', @av_pay_item_cd, GETDATE(),'1') + ') INSERT �� �����߻� -' + @an_emp_id,
                                                            @v_program_id,  0259,  @errormessage, @an_mod_user_id)
                    RETURN

                END CATCH

                RETURN

            END

    END
	*/

    -- ***********************************************************************************************************
    -- 4.�ڷ� üũ�� ���� �޿���꼳���� �ش� �޿��׸��� ���������� �о�´�
    -- ***********************************************************************************************************

    BEGIN

        SELECT
            @v_term_yn          = CASE WHEN B.ETC_CD1 IS NULL THEN 'Y' ELSE B.ETC_CD1 END,  -- �Ⱓ���ӿ���
            @v_day_retro_yn     = CASE WHEN CD4 IS NULL THEN   'N' ELSE CD4 END,            -- ���Ұ�� ������ �ִ°��� ���Ұ�� ������ ���� rule �� ������ ���̴�.
            @v_retro_type       = CASE WHEN @av_pay_type_cd = 'P' AND B.ETC_CD2 = 'Y' THEN '3' ELSE @v_retro_type END,  -- �޿��� ��� �ұ� ���� üũ ���ΰ� Y �̸� �ұ� ����. ���� üũ�Ұű� ����
            @v_retro_check_yn   = CASE WHEN B.ETC_CD2 IS NULL THEN 'N' ELSE  B.ETC_CD2  END,   -- �޿��� ��� �ұ� ���� üũ ���ΰ� Y �̸� ���߿� �ұ� üũ �϶�� �ؾ� ��.
            @v_rest_cal_yn      = B.ETC_CD2,
            @v_cd_kind          = B.ETC_CD5
        FROM
            FRM_UNIT_STD_MGR A,    -- �������ذ���
            FRM_UNIT_STD_HIS B     -- ���ذ�������
        WHERE A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
        AND A.COMPANY_CD    = @av_company_cd
        AND A.UNIT_CD       = 'PAY'                --�����з��ڵ�(�޿�)
        AND A.STD_KIND      = 'PAY_ITEM_CD_BASE'   --���غз��ڵ�(�޿��׸�)
        AND @ad_end_ymd BETWEEN B.STA_YMD AND B.END_YMD
        AND B.KEY_CD1 = @av_pay_item_cd

        IF (@@ROWCOUNT < 1)

            BEGIN
				
				--ȸ�纰 �޿���꼳���� �ݿ����� ���� �׸��� SKIP �Ѵ�

                --SET @av_ret_code    = 'FAILURE!'
                --SET @av_ret_message = DBO.F_FRM_ERRMSG('���ʿ��� �ڵ� [' +  @av_pay_item_cd + '] �ڵ尡 �������� �ʽ��ϴ�.-' + CONVERT(NVARCHAR(50),@an_emp_id) + '-' + CONVERT(VARCHAR(10), @ad_end_ymd, 120),
                --                                        @v_program_id,  0142,  @errormessage,  @an_mod_user_id)

                RETURN
            END

         IF (@@ERROR > 0)
            BEGIN
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('[�Ⱓ���ӿ�����ȸ]���ʿ���  (' + DBO.F_FRM_CODE_NM(@av_company_cd , @av_locale_cd, 'PAY_ITEM_CD',@av_pay_item_cd,  GETDATE(),'1') + ') INSERT �� �����߻� -' + CONVERT(NVARCHAR(50),@an_emp_id),
                                                        @v_program_id,  0153,  @errormessage,  @an_mod_user_id)

                RETURN
            END
    END


    IF @v_retro_check_yn = 'Y'
        SET @v_retro_chk_sta_ymd = @ad_sta_ymd

    -- ***********************************************************************************************************
    -- 5.�Ⱓ����üũ �׸� �Ⱓ���Թ��÷� üũ�Ǿ� ���� ��� ä��
    --   �������ڰ� ���� �ű� �������ڸ� ������������ ���� Ŭ ��� �Ⱓ�� ���Ե� �ڷᰡ �̹� �����ϱ� ������ SKIP
    -- ***********************************************************************************************************


    IF @v_term_yn = 'M' -- �Ⱓ���Թ���(�����ϰ�����츸)

        BEGIN
            SELECT @n_cnt = COUNT(*)
              FROM PAY_MST_CHANGE  -- ���ʿ���(�޿���������)
             WHERE EMP_ID          =  @an_emp_id               -- ���ID
               AND PAY_ITEM_CD     =  @av_pay_item_cd          -- �޿��׸�����ڵ�(PAY_ITEM_CD)
               AND PAY_ITEM_VALUE  =  @av_pay_item_value       -- �޿������׸�
               AND STA_YMD         <= @ad_sta_ymd              -- ��������
               AND END_YMD         =  @ad_end_ymd              -- ��������
               AND LAST_YN         =  'Y'                      -- ��������Ÿ����
               AND SALARY_TYPE_CD  =  @av_salary_type_cd	   -- �޿�����
               AND ISNULL(BEL_ORG_ID, -1)  = ISNULL(@an_bel_org_id, -1)

            IF @n_cnt > 0
                RETURN
        END

    -- ***********************************************************************************************************
    -- 6. �űԵ���ڷ�� �Ⱓ�� ��ġ�� �������� �ڷḦ üũ�Ͽ� �Ⱓ�� ������Ѵ�
    -- ***********************************************************************************************************
    IF @av_pay_item_value IS NOT NULL

        BEGIN

            DECLARE @for_mst_chg_bel_org_id                    NUMERIC
                  , @for_mst_chg_emp_id                        NUMERIC
                  , @for_mst_chg_end_ymd                       DATE
                  , @for_mst_chg_last_yn                       CHAR(1)
                  , @for_mst_chg_make_pay_ymd_id               NUMERIC
                  , @for_mst_chg_mod_date                      DATE
                  , @for_mst_chg_mod_user_id                   NUMERIC
                  , @for_mst_chg_pay_item_cd                   NVARCHAR(10)
                  , @for_mst_chg_pay_item_value                NVARCHAR(50)
                  , @for_mst_chg_pay_item_value_text           NVARCHAR(100)
                  , @for_mst_chg_pay_mst_change_id             NUMERIC
                  , @for_mst_chg_pay_ymd_id                    NUMERIC
                  , @for_mst_chg_retro_chk_sta_ymd             DATE
                  , @for_mst_chg_salary_type_cd                NVARCHAR(10)
                  , @for_mst_chg_sta_ymd                       DATE
                  , @for_mst_chg_tz_cd                         NVARCHAR(10)
                  , @for_mst_chg_tz_date                       DATE

                --�Ⱓ�� ��ġ�� ��찡 ���� ���
            DECLARE for_mst_chg CURSOR LOCAL FORWARD_ONLY FOR
                SELECT EMP_ID
                     , PAY_ITEM_CD
                     , PAY_ITEM_VALUE
                     , PAY_ITEM_VALUE_TEXT
                     , PAY_MST_CHANGE_ID
                     , PAY_YMD_ID
                     , RETRO_CHK_STA_YMD
                     , SALARY_TYPE_CD
                     , STA_YMD
                     , END_YMD
                     , LAST_YN
                     , BEL_ORG_ID
                     , MAKE_PAY_YMD_ID
                     , MOD_DATE
                     , MOD_USER_ID
                     , TZ_CD
                     , TZ_DATE
                  FROM PAY_MST_CHANGE  -- ���ʿ���
                 WHERE EMP_ID         =  @an_emp_id            -- ���ID
                   AND SALARY_TYPE_CD =  @av_salary_type_cd    -- �޿�����
                   AND PAY_ITEM_CD    =  @av_pay_item_cd       -- �޿��׸�����ڵ�(PAY_ITEM_CD)
                   AND STA_YMD        <= @ad_end_ymd           -- ��������
                   AND END_YMD        >= @ad_sta_ymd           -- ��������
                   AND LAST_YN        =  'Y'                   -- ��������Ÿ����
                   AND ISNULL(BEL_ORG_ID, -1)    = ISNULL(@an_bel_org_id, -1)
								 ORDER BY STA_YMD DESC
                OPEN for_mst_chg

                FETCH NEXT FROM for_mst_chg INTO @for_mst_chg_emp_id
                                               , @for_mst_chg_pay_item_cd
                                               , @for_mst_chg_pay_item_value
                                               , @for_mst_chg_pay_item_value_text
                                               , @for_mst_chg_pay_mst_change_id
                                               , @for_mst_chg_pay_ymd_id
                                               , @for_mst_chg_retro_chk_sta_ymd
                                               , @for_mst_chg_salary_type_cd
                                               , @for_mst_chg_sta_ymd
                                               , @for_mst_chg_end_ymd
                                               , @for_mst_chg_last_yn
                                               , @for_mst_chg_bel_org_id
                                               , @for_mst_chg_make_pay_ymd_id
                                               , @for_mst_chg_mod_date
                                               , @for_mst_chg_mod_user_id
                                               , @for_mst_chg_tz_cd
                                               , @for_mst_chg_tz_date

                WHILE @@FETCH_STATUS = 0

                    BEGIN

                        IF @@FETCH_STATUS = -1
                            BREAK

                        -- ***********************************************************************************************************
                        -- 6.1 ������ �����ϴ� ���� ����ó�� �Ѵ�
                        -- ***********************************************************************************************************
                        BEGIN TRY

                            UPDATE PAY_MST_CHANGE
                               SET LAST_YN           = 'N'                 -- ��������Ÿ����
                                 , MOD_USER_ID       = @an_mod_user_id     -- ������
                                 , MOD_DATE          = GETDATE()           -- �����Ͻ�
                             WHERE PAY_MST_CHANGE_ID = @for_mst_chg_pay_mst_change_id

                        END TRY
                        BEGIN CATCH
                            --�ߺ������� ��� �����ڷḦ �����Ѵ�
                            IF ERROR_NUMBER() = 2627

                                BEGIN

                                    DELETE FROM PAY_MST_CHANGE
                                    WHERE PAY_MST_CHANGE_ID = (
                                                                SELECT PAY_MST_CHANGE_ID
                                                                FROM PAY_MST_CHANGE
                                                                WHERE EMP_ID        = @for_mst_chg_emp_id
                                                                AND SALARY_TYPE_CD  = @for_mst_chg_salary_type_cd
                                                                AND PAY_ITEM_CD     = @for_mst_chg_pay_item_cd
                                                                AND STA_YMD         = @for_mst_chg_sta_ymd
                                                                AND LAST_YN         = 'N'
                                                                )

                                    UPDATE PAY_MST_CHANGE
                                    SET PAY_ITEM_VALUE          =  @av_pay_item_value   ,   -- ��������Ÿ����
                                        MOD_USER_ID             =  @an_mod_user_id      ,   -- ������
                                        MOD_DATE                =  GETDATE()                -- �����Ͻ�
                                    WHERE PAY_MST_CHANGE_ID     =  @for_mst_chg_pay_mst_change_id

                                     IF (@@ERROR > 0)
                                        BEGIN
                                            SET @av_ret_code = 'FAILURE!'
                                            SET @av_ret_message = DBO.F_FRM_ERRMSG('���ʿ���  (' + DBO.F_FRM_CODE_NM(@av_company_cd , @av_locale_cd, 'PAY_ITEM_CD',@av_pay_item_cd,  GETDATE(),'1') + ') UPDATE �� �����߻� -' + @an_emp_id,
                                                                @v_program_id,  0153,  @errormessage,  @an_mod_user_id)
                                            RETURN
                                        END

                                END

                            ELSE

                                BEGIN

                                    SET @av_ret_code = 'FAILURE!'
                                    SET @av_ret_message = DBO.F_FRM_ERRMSG('���ʿ���  (' + DBO.F_FRM_CODE_NM(@av_company_cd , @av_locale_cd, 'PAY_ITEM_CD',@av_pay_item_cd,  GETDATE(),'1') + ') DELETE �� �����߻� -' + @an_emp_id,
                                                                    @v_program_id,  0153,  @errormessage,  @an_mod_user_id)
                                    RETURN

                                END

                        END CATCH

                        -- ***********************************************************************************************************
                        -- 6.2 ���������� �ڷ�� ���ں��� ������ ����� �Ѵ�
                        -- ***********************************************************************************************************
												print 'v_term_yn=' + @v_term_yn
                        IF @v_term_yn = 'Y' -- ����Ÿ�� ���Ӽ��� ���� ��쿡�� ��ġ�� �ʴ� �κ��� �ٽ� ����Ѵ�.

                            BEGIN
																PRINT 'ad_sta_ymd=' + convert(varchar(100),  @for_mst_chg_sta_ymd)
                                IF @ad_sta_ymd > @for_mst_chg_sta_ymd

                                    BEGIN

                                        SET @d_sta_ymd = @for_mst_chg_sta_ymd
                                        SET @d_end_ymd = DBO.XF_TO_CHAR_D(DATEADD(dd, -1, @ad_sta_ymd), 'YYYYMMDD')

                                        BEGIN TRY
                                            INSERT INTO PAY_MST_CHANGE
                                            (
                                                PAY_MST_CHANGE_ID       ,  -- ���ʿ���ID
                                                EMP_ID                  ,  -- ���ID
                                                SALARY_TYPE_CD          ,  -- �޿�����
                                                PAY_ITEM_CD             ,  -- �޿��׸�����ڵ�(PAY_ITEM_CD)
                                                PAY_ITEM_VALUE          ,  -- �޿������׸�
                                                PAY_ITEM_VALUE_TEXT     ,  -- �޿������׸� ����
                                                STA_YMD                 ,  -- ��������
                                                END_YMD                 ,  -- ��������
                                                LAST_YN                 ,  -- ��������Ÿ����
                                                PAY_YMD_ID              ,  -- �޿�����ID(�޿� �Ƿ� ����Ÿ��
                                                MOD_USER_ID             ,  -- ������
                                                MOD_DATE                ,  -- �����Ͻ�
                                                TZ_CD                   ,  -- Ÿ�����ڵ�
                                                TZ_DATE                 ,  -- Ÿ�����Ͻ�
                                                BEL_ORG_ID              ,  -- �ͼӺμ�id
                                                MAKE_PAY_YMD_ID         ,  --�����ñ޿�����ID(�ұ�üũ�� ���� ����)
                                                RETRO_CHK_STA_YMD          --�ұ�����üũ����
                                            )
                                            VALUES
                                            (
                                                NEXT VALUE FOR DBO.S_PAY_SEQUENCE   ,  -- ���ʿ���ID
                                                @for_mst_chg_emp_id                 ,  -- ���ID
                                                @av_salary_type_cd                  ,  -- �޿�����
                                                @for_mst_chg_pay_item_cd            ,  -- �޿��׸�����ڵ�(PAY_ITEM_CD)
                                                @for_mst_chg_pay_item_value         ,  -- �޿������׸�
                                                @for_mst_chg_pay_item_value_text    ,  -- �޿������׸� ����
                                                @d_sta_ymd                          ,  -- ��������
                                                @d_end_ymd                          ,  -- ��������
                                                'Y'                                 ,  -- ��������Ÿ����
                                                @for_mst_chg_pay_ymd_id             ,  -- �޿�����ID(�޿� �Ƿ� ����Ÿ��
                                                @an_mod_user_id                     ,  -- ������
                                                GETDATE()                           ,  -- �����Ͻ�
                                                @av_tz_cd                           ,  -- Ÿ�����ڵ�
                                                DBO.F_FRM_GETDATE(GETDATE(), @av_tz_cd)    ,   -- Ÿ�����Ͻ�
                                                @an_bel_org_id                      ,  -- �ͼӺμ�id
                                                @an_pay_ymd_id                      ,  -- �����ñ޿�����ID(�ұ�üũ�� ���� ����)
                                                @v_retro_chk_sta_ymd
                                            )
                                        END TRY

                                        BEGIN CATCH
                                            SET @errornumber   = ERROR_NUMBER()
                                            SET @errormessage  = ERROR_MESSAGE()

                                            SET @av_ret_code    = 'FAILURE!'
                                            SET @av_ret_message = DBO.F_FRM_ERRMSG('PAY_MST_CHANGE INSERT�� ���� �߻� [ERR]', @v_program_id , 0443, @errormessage, @an_mod_user_id)

                                            IF @@TRANCOUNT > 0
                                                ROLLBACK WORK
                                            RETURN

                                        END CATCH

                                    END --@ad_sta_ymd > @for_mst_chg_sta_ymd

                                IF @ad_end_ymd < @for_mst_chg_end_ymd

                                    BEGIN

                                        SET @d_sta_ymd = DBO.XF_TO_CHAR_D(DATEADD(dd, 1, @ad_end_ymd), 'YYYYMMDD')
                                        SET @d_end_ymd = @for_mst_chg_end_ymd

                                        BEGIN TRY
                                            INSERT INTO PAY_MST_CHANGE
                                                (
                                                    PAY_MST_CHANGE_ID       ,  -- ���ʿ���ID
                                                    EMP_ID                  ,  -- ���ID
                                                    SALARY_TYPE_CD          ,  -- �޿�����
                                                    PAY_ITEM_CD             ,  -- �޿��׸�����ڵ�(PAY_ITEM_CD)
                                                    PAY_ITEM_VALUE          ,  -- �޿������׸�
                                                    PAY_ITEM_VALUE_TEXT     ,  -- �޿������׸� ����
                                                    STA_YMD                 ,  -- ��������
                                                    END_YMD                 ,  -- ��������
                                                    LAST_YN                 ,  -- ��������Ÿ����
                                                    PAY_YMD_ID              ,  -- �޿�����ID(�޿� �Ƿ� ����Ÿ��
                                                    MOD_USER_ID             ,  -- ������
                                                    MOD_DATE                ,  -- �����Ͻ�
                                                    TZ_CD                   ,  -- Ÿ�����ڵ�
                                                    TZ_DATE                 ,  -- Ÿ�����Ͻ�
                                                    BEL_ORG_ID              ,  -- �ͼӺμ�id
                                                    MAKE_PAY_YMD_ID         ,  --�����ñ޿�����ID(�ұ�üũ�� ���� ����)
                                                    RETRO_CHK_STA_YMD          --�ұ�����üũ����
                                                )
                                            VALUES
                                            (
                                                    NEXT VALUE FOR DBO.S_PAY_SEQUENCE   ,  -- ���ʿ���ID
                                                    @for_mst_chg_emp_id                 ,  -- ���ID
                                                    @av_salary_type_cd                  ,  -- �޿�����
                                                    @for_mst_chg_pay_item_cd            ,  -- �޿��׸�����ڵ�(PAY_ITEM_CD)
                                                    @for_mst_chg_pay_item_value         ,  -- �޿������׸�
                                                    @for_mst_chg_pay_item_value_text    ,  -- �޿������׸� ����
                                                    @d_sta_ymd                          ,  -- ��������
                                                    @d_end_ymd                          ,  -- ��������
                                                    'Y'                                 ,  -- ��������Ÿ����
                                                    @for_mst_chg_pay_ymd_id             ,  -- �޿�����ID(�޿� �Ƿ� ����Ÿ��
                                                    @an_mod_user_id                     ,  -- ������
                                                    GETDATE()                           ,  -- �����Ͻ�
                                                    @av_tz_cd                           ,  -- Ÿ�����ڵ�
                                                    DBO.F_FRM_GETDATE(GETDATE(), @av_tz_cd) ,   -- Ÿ�����Ͻ�
                                                    @an_bel_org_id                      ,  -- �ͼӺμ�id
                                                    @an_pay_ymd_id                      ,  --�����ñ޿�����ID(�ұ�üũ�� ���� ����)
                                                    @v_retro_chk_sta_ymd
                                            )
                                        END TRY

                                        BEGIN CATCH
                                            SET @errornumber   = ERROR_NUMBER()
                                            SET @errormessage  = ERROR_MESSAGE()

                                            SET @av_ret_code    = 'FAILURE!'
                                            SET @av_ret_message = DBO.F_FRM_ERRMSG('PAY_MST_CHANGE INSERT�� ���� �߻� [ERR]', @v_program_id , 0443, @errormessage, @an_mod_user_id)

                                            IF @@TRANCOUNT > 0
                                                ROLLBACK WORK
                                            RETURN
                                        END CATCH

                                    END


                            END --IF v_term_yn = 'Y'


                        FETCH NEXT FROM for_mst_chg INTO
                                         @for_mst_chg_emp_id
                                        ,@for_mst_chg_pay_item_cd
                                        ,@for_mst_chg_pay_item_value
                                        ,@for_mst_chg_pay_item_value_text
                                        ,@for_mst_chg_pay_mst_change_id
                                        ,@for_mst_chg_pay_ymd_id
                                        ,@for_mst_chg_retro_chk_sta_ymd
                                        ,@for_mst_chg_salary_type_cd
                                        ,@for_mst_chg_sta_ymd
                                        ,@for_mst_chg_end_ymd
                                        ,@for_mst_chg_last_yn
                                        ,@for_mst_chg_bel_org_id
                                        ,@for_mst_chg_make_pay_ymd_id
                                        ,@for_mst_chg_mod_date
                                        ,@for_mst_chg_mod_user_id
                                        ,@for_mst_chg_tz_cd
                                        ,@for_mst_chg_tz_date
                    END --WHILE

            END --IF @av_pay_item_value IS NOT NULL

            INS:

            -- ���ʿ��忡 insert
            IF @av_pay_item_value IS NOT NULL  -- ���� NULL �̸� ������ ����Ÿ�� ���� ��¥ ������ ������ ���ʿ��忡 ���� �ʿ䰡 ����.
                BEGIN
                    INSERT INTO PAY_MST_CHANGE
                    (
                        PAY_MST_CHANGE_ID       ,  -- ���ʿ���ID
                        EMP_ID                  ,  -- ���ID
                        SALARY_TYPE_CD          ,  -- �޿�����
                        PAY_ITEM_CD             ,  -- �޿��׸�����ڵ�(PAY_ITEM_CD)
                        PAY_ITEM_VALUE          ,  -- �޿������׸�
                        PAY_ITEM_VALUE_TEXT     ,  -- �޿������׸� ����
                        STA_YMD                 ,  -- ��������
                        END_YMD                 ,  -- ��������
                        LAST_YN                 ,  -- ��������Ÿ����
                        PAY_YMD_ID              ,  -- �޿�����ID(�޿� �Ƿ� ����Ÿ��
                        MOD_USER_ID             ,  -- ������
                        MOD_DATE                ,  -- �����Ͻ�
                        TZ_CD                   ,  -- Ÿ�����ڵ�
                        TZ_DATE                 ,  -- Ÿ�����Ͻ�
                        BEL_ORG_ID              ,  -- �ͼӺμ�id
                        MAKE_PAY_YMD_ID         ,  -- �����ñ޿�����ID(�ұ�üũ�� ���� ����)
                        RETRO_CHK_STA_YMD          -- �ұ�����üũ����
                        )
                    VALUES
                    (
                        NEXT VALUE FOR DBO.S_PAY_SEQUENCE       ,  -- ���ʿ���ID
                        @an_emp_id                              ,  -- ���ID
                        @av_salary_type_cd                      ,  -- �޿�����
                        @av_pay_item_cd                         ,  -- �޿��׸�����ڵ�(PAY_ITEM_CD)
                        @av_pay_item_value                      ,  -- �޿������׸�
                        CASE WHEN @v_cd_kind IS NOT NULL AND @av_pay_item_value_text IS NULL
                            THEN DBO.F_FRM_CODE_NM(@av_company_cd, @av_locale_cd, @v_cd_kind, @av_pay_item_value, @ad_end_ymd, '1')
                            ELSE @av_pay_item_value_text
                        END                                     ,  -- �޿������׸� ����
                        @d_mst_sta_ymd                          ,  -- ��������
                        @ad_end_ymd                             ,  -- ��������
                        'Y'                                     ,  -- ��������Ÿ����
                        @an_in_pay_ymd_id                       ,  -- �޿�����ID(�޿� �Ƿ� ����Ÿ��
                        @an_mod_user_id                         ,  -- ������
                        GETDATE()                               ,  -- �����Ͻ�
                        @av_tz_cd                               ,  -- Ÿ�����ڵ�
                        DBO.F_FRM_GETDATE(GETDATE(), @av_tz_cd) ,  -- Ÿ�����Ͻ�
                        @an_bel_org_id                          ,  -- �ͼӺμ�id
                        @an_pay_ymd_id   ,                         --�����ñ޿�����ID(�ұ�üũ�� ���� ����)
                        @v_retro_chk_sta_ymd
                    )
                END --IF @av_pay_item_value IS NOT NULL

                SET @errornumber   = ERROR_NUMBER()
                SET @errormessage  = ERROR_MESSAGE()

                IF (@@ROWCOUNT < 1)
                    BEGIN
                        SET @av_ret_code    = 'FAILURE!'
                        SET @av_ret_message = DBO.F_FRM_ERRMSG('P_PAY_MST_CHANGE_INSERT ����',@v_program_id,  0249,  @errormessage,  @an_mod_user_id)
                        RETURN
                    END

                IF (@@ERROR > 0)
                    BEGIN
                        SET @av_ret_code = 'FAILURE!'
                        SET @av_ret_message = DBO.F_FRM_ERRMSG('[�Ⱓ�� ������ ���� Ʋ�� ��� ��ȸ]���ʿ��� (' + DBO.F_FRM_CODE_NM(@av_company_cd , @av_locale_cd, 'PAY_ITEM_CD', @av_pay_item_cd, GETDATE(),'1') + ') INSERT �� �����߻� -' + @an_emp_id,
                                                @v_program_id,  0259,  @errormessage, @an_mod_user_id
                                            )
                        RETURN
                    END

            IF @v_retro_type != '3' AND @v_retro_chk_sta_ymd IS NOT NULL
            BEGIN
                EXECUTE P_PAY_MST_CHANGE_RETRO_PAY
                                    @av_company_cd       ,       -- �λ翵��
                                    @av_locale_cd        ,       -- ���
                                    @an_emp_id           ,       -- ���id
                                    @av_pay_item_cd      ,       -- �޿��׸�����ڵ�
                                    @v_retro_chk_sta_ymd ,       -- ��������
                                    @ad_end_ymd          ,       -- ��������
                                    @an_pay_ymd_id       ,       -- ����޿����� ID(���κ��ұޱ޿����� ���̺� ���� �޿� ����, �ұ��� �� �ϸ� NULL�� �ѱ�)
                                    @av_salary_type_cd   ,       -- ������� �޿�����
                                    @v_day_retro_yn      ,       -- ���Ұ�� ������ ������ ��ϵ� ���Ұ�� ������ ��� Y, �ƴϸ� N
                                    @v_retro_type       ,        -- �ұ� ���� [1 :��� �������� �ұ�, 2 : ���� ���������� �ұ�, 3: �ұ� ����]
                                    @av_pay_type_cd      ,       -- ��������
                                    @av_tz_cd            ,
                                    @an_mod_user_id      ,       -- ������ ���id
                                    @av_ret_code         ,       -- SUCCESS!/FAILURE!
                                    @av_ret_message              -- ����޽���


                IF @av_ret_code = 'FAILURE!'
                        RETURN
            END --IF @v_retro_type != '3' AND v_retro_chk_sta_ymd IS NOT NULL

    -- ***********************************************************
    -- �۾� �Ϸ�
    -- ***********************************************************
    SET @av_ret_code   = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('���ν��� ���� �Ϸ�..', @v_program_id,  0900,  null, @an_mod_user_id)


END
GO

IF NOT EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'MS_SSMA_SOURCE' , N'SCHEMA',N'dbo', N'PROCEDURE',N'P_PAY_MST_CHANGE_INSERT', NULL,NULL))
	EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'H551.P_PAY_MST_CHANGE_INSERT' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'P_PAY_MST_CHANGE_INSERT'
ELSE
BEGIN
	EXEC sys.sp_updateextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'H551.P_PAY_MST_CHANGE_INSERT' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'P_PAY_MST_CHANGE_INSERT'
END
GO



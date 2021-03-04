SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[P_PEB_PAY_HOBONG_U_CREATE]
    @av_company_cd      NVARCHAR(10),       -- �λ翵��
    @av_locale_cd       NVARCHAR(10),       -- �����ڵ�
    @an_peb_base_id     NUMERIC,            -- �ΰǺ����id
    @av_pos_grd_cd      NVARCHAR(50),       -- �����ڵ�
    @an_mod_user_id     NUMERIC,            -- ������
    @av_ret_code        NVARCHAR(100) OUTPUT,
    @av_ret_message     NVARCHAR(500) OUTPUT
AS
    -- ***************************************************************************
    --   TITLE       : �ΰǺ� ȣ��ǥ ����(���)
    ---  PROJECT     : ���λ������ý���
    --   AUTHOR      : ���ñ�
    --   PROGRAM_ID  : P_PEB_PAY_HOBONG
    --   ARGUMENT    :
    --   RETURN      :
    --   HISTORY     :
    -- ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id       NVARCHAR(30)
      , @v_program_nm       NVARCHAR(100)
      , @v_ret_code         NVARCHAR(100)
      , @v_ret_message      NVARCHAR(500)
	  
      -- �ΰǺ��ȹ ��������
      , @v_base_yyyy        NVARCHAR(4)    -- ���س⵵
      , @d_std_ymd          DATE           -- ������
      , @d_std_sta_ymd      DATE           -- �ΰǺ��ȹ������
      , @d_std_end_ymd      DATE           -- �ΰǺ��ȹ������
	  
      -- �ΰǺ��ȹ �λ�������
      , @n_up_rate          NUMERIC(8,4)   -- �λ���
      , @v_peb_ym           NVARCHAR(2)    -- �ݿ���

      , @d_sta_ymd          DATE           -- ������
      , @d_end_ymd          DATE           -- ������
	  

    /*�⺻���� �ʱⰪ ����*/
    SET @v_program_id   = 'P_PEB_PAY_HOBONG_U_CREATE'
    SET @v_program_nm   = '�ΰǺ� ȣ��ǥ ����(���)'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
	
--=======================================================================
-- ȣ���λ��� ������ȸ
--=======================================================================
    BEGIN
        SELECT @v_base_yyyy   = A.BASE_YYYY
             , @d_std_ymd     = A.STD_YMD
             , @d_std_sta_ymd = A.STA_YMD
             , @d_std_end_ymd = A.END_YMD

             , @n_up_rate     = (ISNULL(B.PEB_RATE, 0) / 100.0) + 1
             , @d_std_ymd     = A.STD_YMD
             , @v_peb_ym      = B.PEB_YM
          FROM PEB_BASE A
               LEFT OUTER JOIN PEB_RATE B
                       ON A.PEB_BASE_ID = B.PEB_BASE_ID
                      AND B.PEB_TYPE_CD = '120' -- 110:�����λ���, 120:ȣ���λ���
         WHERE A.PEB_BASE_ID = @an_peb_base_id

        IF @@ERROR <> 0
            BEGIN
                SET @av_ret_code = 'FAILUERE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('ȣ���λ��� ���� ��ȸ �� �����߻�[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
                RETURN
            END

        -- �ΰǺ� �ݿ����� 1��~12������ ����, '�ſ�'�� ������ �� ����(�ΰǺ��׸����޿�[PEB_MONTH_CD])
        IF @v_peb_ym = '00'
            BEGIN
                SET @av_ret_code = 'FAILUERE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('�ΰǺ� �ݿ����� [�ſ�]�� ������ �� �����ϴ�.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
                RETURN
            END

        IF @@ROWCOUNT < 1
            BEGIN
                SET @v_peb_ym = NULL
            END
    END


--===========================================================
-- �����ڷ����
--===========================================================
    BEGIN TRY
        DELETE FROM PEB_PAY_HOBONG_U
         WHERE PEB_BASE_ID = @an_peb_base_id
           AND (PAY_POS_GRD_CD = @av_pos_grd_cd OR @av_pos_grd_cd IS NULL)
    END TRY
    BEGIN CATCH
        SET @av_ret_code = 'FAILURE!'
        SET @av_ret_message = DBO.F_FRM_ERRMSG('�ΰǺ� ȣ���ڷ� ���� �� �����߻�[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
        IF @@TRANCOUNT > 0
            ROLLBACK
        RETURN
    END CATCH


--===========================================================
-- ����/������ ����
--===========================================================
    -- �ΰǺ� �λ� ������ ���� ���
    IF @v_peb_ym IS NULL
        BEGIN
            SET @d_sta_ymd = NULL
            SET @d_end_ymd = @d_std_end_ymd
        END

    -- �ΰǺ� �λ� ������ ���� ���
    ELSE
        BEGIN
            SET @d_sta_ymd = CONVERT(DATE, @v_base_yyyy + @v_peb_ym + '01')
            SET @d_end_ymd = DATEADD(DD, -1, @d_sta_ymd)
        END


--===========================================================
-- ȣ������ ����(�޿����� > ���ذ��� > ��ȣ���̺����)
--===========================================================
    BEGIN TRY
        INSERT INTO PEB_PAY_HOBONG_U ( PEB_PAY_HOBONG_ID        -- �ΰǺ��ȹȣ��ID
                                     , PEB_BASE_ID              -- �ΰǺ��ȹ����ID
                                     , COMPANY_CD               -- �λ翵��
                                     , PAY_POS_GRD_CD           -- �����ڵ� [PHM_POS_GRD_CD]
                                     , PAY_GRADE                -- ȣ���ڵ� [PHM_YEARNUM_CD]
                                     , STA_YMD                  -- ������
                                     , END_YMD                  -- ������
                                     , OLD_PAY_AMT              -- �����⺻��
                                     , OLD_PAY_OFFICE_AMT       -- �����ð��ܼ���
                                     , OLD_BNS_AMT              -- ����������
                                     , PAY_AMT                  -- �⺻��
                                     , PAY_OFFICE_AMT           -- �ð��ܼ���
                                     , BNS_AMT                  -- ������
                                     , NOTE                     -- ���
                                     , MOD_USER_ID              -- ������
                                     , MOD_DATE                 -- �����Ͻ�
                                     , TZ_CD                    -- Ÿ�����ڵ�
                                     , TZ_DATE                  -- Ÿ�����Ͻ�
                                     )
                                SELECT NEXT VALUE FOR S_PEB_SEQUENCE   -- PEB_PAY_HOBONG_ID
                                     , @an_peb_base_id                 -- PEB_BASE_ID
                                     , COMPANY_CD                      -- COMPANY_CD
                                     , PAY_POS_GRD_CD                  -- PAY_POS_GRD_CD
                                     , PAY_GRADE                       -- PAY_GRADE
                                     , @d_std_sta_ymd                  -- STA_YMD
                                     , @d_end_ymd                      -- END_YMD
                                     , PAY_AMT                         -- OLD_PAY_AMT
                                     , PAY_OFFICE_AMT                  -- OLD_PAY_OFFICE_AMT
                                     , BNS_AMT                         -- OLD_BNS_AMT
                                     , PAY_AMT                         -- PAY_AMT
                                     , PAY_OFFICE_AMT                  -- PAY_OFFICE_AMT
                                     , BNS_AMT                         -- BNS_AMT
                                     , NOTE                            -- NOTE
                                     , @an_mod_user_id                 -- MOD_USER_ID
                                     , GETDATE()                       -- MOD_DATE
                                     , 'KST'                           -- TZ_CD
                                     , GETDATE()                       -- TZ_DATE
                                  FROM PAY_HOBONG_U
                                 WHERE COMPANY_CD = @av_company_cd
                                   AND @d_std_ymd BETWEEN STA_YMD AND END_YMD
                                   AND (PAY_POS_GRD_CD = @av_pos_grd_cd OR @av_pos_grd_cd IS NULL)
                                   AND ISNULL(PAY_AMT, 0) <> 0

    END TRY
    BEGIN CATCH
        SET @av_ret_code = 'FAILURE!'
        SET @av_ret_message = DBO.F_FRM_ERRMSG('�ΰǺ� ȣ���ڷ� ���� �� �����߻�[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
        IF @@TRANCOUNT > 0
            ROLLBACK
        RETURN
    END CATCH

--===========================================================
-- �ΰǺ� �λ����� ���� ��� �߰� INSERT
--===========================================================
    IF @v_peb_ym IS NOT NULL
        BEGIN
            BEGIN TRY
                INSERT INTO PEB_PAY_HOBONG_U ( PEB_PAY_HOBONG_ID        -- �ΰǺ��ȹȣ��ID
                                             , PEB_BASE_ID              -- �ΰǺ��ȹ����ID
                                             , COMPANY_CD               -- �λ翵��
                                             , PAY_POS_GRD_CD           -- �����ڵ� [PHM_POS_GRD_CD]
                                             , PAY_GRADE                -- ȣ���ڵ� [PHM_YEARNUM_CD]
                                             , STA_YMD                  -- ������
                                             , END_YMD                  -- ������
                                             , OLD_PAY_AMT              -- �����⺻��
                                             , OLD_PAY_OFFICE_AMT       -- �����ð��ܼ���
                                             , OLD_BNS_AMT              -- ����������
                                             , PAY_AMT                  -- �⺻��
                                             , PAY_OFFICE_AMT           -- �ð��ܼ���
                                             , BNS_AMT                  -- ������
                                             , NOTE                     -- ���
                                             , MOD_USER_ID              -- ������
                                             , MOD_DATE                 -- �����Ͻ�
                                             , TZ_CD                    -- Ÿ�����ڵ�
                                             , TZ_DATE                  -- Ÿ�����Ͻ�
                                             )
                                        SELECT NEXT VALUE FOR S_PEB_SEQUENCE   -- PEB_PAY_HOBONG_ID
                                             , @an_peb_base_id                 -- PEB_BASE_ID
                                             , COMPANY_CD                      -- COMPANY_CD
                                             , PAY_POS_GRD_CD                  -- PAY_POS_GRD_CD
                                             , PAY_GRADE                       -- PAY_GRADE
                                             , @d_sta_ymd                      -- STA_YMD
                                             , @d_std_end_ymd                  -- END_YMD
                                             , PAY_AMT                         -- OLD_PAY_AMT
                                             , PAY_OFFICE_AMT                  -- OLD_PAY_OFFICE_AMT
                                             , BNS_AMT                         -- OLD_BNS_AMT
                                             , DBO.XF_CEIL(@n_up_rate * PAY_AMT       , -2)    -- PAY_AMT
                                             , DBO.XF_CEIL(@n_up_rate * PAY_OFFICE_AMT, -2)    -- PAY_OFFICE_AMT
                                             , DBO.XF_CEIL(@n_up_rate * BNS_AMT       , -2)    -- BNS_AMT
                                             , NOTE                            -- NOTE
                                             , @an_mod_user_id                 -- MOD_USER_ID
                                             , GETDATE()                       -- MOD_DATE
                                             , 'KST'                           -- TZ_CD
                                             , GETDATE()                       -- TZ_DATE
                                          FROM PAY_HOBONG_U
                                         WHERE COMPANY_CD = @av_company_cd
                                           AND @d_std_ymd BETWEEN STA_YMD AND END_YMD
                                           AND (PAY_POS_GRD_CD = @av_pos_grd_cd OR @av_pos_grd_cd IS NULL)
                                           AND ISNULL(PAY_AMT, 0) <> 0

            END TRY
            BEGIN CATCH
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG('�λ����ݿ� ȣ���ڷ� ���� �� �����߻�[ERR]', @v_program_id,  0070, ERROR_MESSAGE(), @an_mod_user_id)
                IF @@TRANCOUNT > 0
                    ROLLBACK
                RETURN
            END CATCH
        END

--=========================================================
-- �۾��Ϸ�
--=========================================================
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = DBO.F_FRM_ERRMSG('ȣ�����簡 �Ϸ�Ǿ����ϴ�.[ERR]', @v_program_id, 0000, NULL, @an_mod_user_id)
END

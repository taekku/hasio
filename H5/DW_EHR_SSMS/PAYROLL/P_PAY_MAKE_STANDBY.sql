SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PAY_MAKE_STANDBY]
    @av_company_cd     NVARCHAR(10),     -- ȸ���ڵ�
    @av_locale_cd      NVARCHAR(10),     -- �����ڵ�
    @av_calc_type_cd   NVARCHAR(10),     -- ���걸�� ('01' : ������, '02' : �߰�����)
    @ad_sta_ymd        DATETIME2,        -- ������(�߰������ �����Ϸ� ��ġ��)
    @ad_end_ymd        DATETIME2,        -- ������
	@an_org_id         NUMERIC(38),     -- �Ҽ�ID
    @an_emp_id         NUMERIC(38),     -- ���ID
	@an_pay_group_id   NUMERIC(38),      -- �޿��׷�
    @an_mod_user_id    NUMERIC(38),     -- ������
    @av_ret_code       NVARCHAR(50)  OUTPUT,   -- SUCCESS!/FAILURE!
    @av_ret_message    NVARCHAR(2000) OUTPUT    -- ����޽���
 AS

    -- ***************************************************************************
    --   TITLE       : �������(����)
    --   PROJECT     :
    --   AUTHOR      :
    --   PROGRAM_ID  : P_PAY_MAKE_STANDBY
    --   RETURN      : 1) SUCCESS!/FAILURE!
    --                 2) ��� �޽���
    --   COMMENT     : �������(����)
    --   HISTORY     : �ۼ� ���ñ� 2020.07.31
    -- ***************************************************************************
BEGIN

    DECLARE @v_program_id          nvarchar(30),
            @v_program_nm          nvarchar(100),

            @d_mod_date            datetime2(0),
            @n_rep_calc_list_id    numeric(38),
            @n_emp_id              numeric(38),
            @n_org_id              numeric(38),
            @n_pay_org_id          numeric(38),
            @v_pos_grd_cd          nvarchar(50),
            @v_pos_cd              nvarchar(50),
            @v_duty_cd             nvarchar(50),
            @v_yearnum_cd          nvarchar(50),

            @d_group_ymd           datetime2,
            @d_retire_ymd          datetime2,
            @d_sta_ymd             datetime2,
            @d_end_ymd             datetime2,
            @v_cust_col3           nvarchar(50), -- �ٹ���(�߰��÷�)
            @n_retire_turn_mon     numeric(15)

    SET @v_program_id = 'P_PAY_MAKE_STANDBY';
    SET @v_program_nm = '�������(����)';

    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null,  @an_mod_user_id)

    SET @d_mod_date = dbo.XF_SYSDATE(0)

    BEGIN
        -- *************************************************************
        -- ������ ���� �������
        -- *************************************************************
		SET @av_ret_code = 'FAILURE!'
		SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ������.....[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)
		return
    END

    /*
    *    ***********************************************************
    *    �۾� �Ϸ�
    *    ***********************************************************
    */
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� �Ϸ�..[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)

END

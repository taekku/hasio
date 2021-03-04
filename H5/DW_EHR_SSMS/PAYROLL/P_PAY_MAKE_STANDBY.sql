SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PAY_MAKE_STANDBY]
    @av_company_cd     NVARCHAR(10),     -- 회사코드
    @av_locale_cd      NVARCHAR(10),     -- 국가코드
    @av_calc_type_cd   NVARCHAR(10),     -- 정산구분 ('01' : 퇴직금, '02' : 중간정산)
    @ad_sta_ymd        DATETIME2,        -- 시작일(중간정산시 정산일로 대치됨)
    @ad_end_ymd        DATETIME2,        -- 종료일
	@an_org_id         NUMERIC(38),     -- 소속ID
    @an_emp_id         NUMERIC(38),     -- 사원ID
	@an_pay_group_id   NUMERIC(38),      -- 급여그룹
    @an_mod_user_id    NUMERIC(38),     -- 변경자
    @av_ret_code       NVARCHAR(50)  OUTPUT,   -- SUCCESS!/FAILURE!
    @av_ret_message    NVARCHAR(2000) OUTPUT    -- 결과메시지
 AS

    -- ***************************************************************************
    --   TITLE       : 대기비산출(선원)
    --   PROJECT     :
    --   AUTHOR      :
    --   PROGRAM_ID  : P_PAY_MAKE_STANDBY
    --   RETURN      : 1) SUCCESS!/FAILURE!
    --                 2) 결과 메시지
    --   COMMENT     : 대기비산출(선원)
    --   HISTORY     : 작성 임택구 2020.07.31
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
            @v_cust_col3           nvarchar(50), -- 근무지(추가컬럼)
            @n_retire_turn_mon     numeric(15)

    SET @v_program_id = 'P_PAY_MAKE_STANDBY';
    SET @v_program_nm = '대기비산출(선원)';

    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)

    SET @d_mod_date = dbo.XF_SYSDATE(0)

    BEGIN
        -- *************************************************************
        -- 선원에 대한 대기비산출
        -- *************************************************************
		SET @av_ret_code = 'FAILURE!'
		SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 구현중.....[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)
		return
    END

    /*
    *    ***********************************************************
    *    작업 완료
    *    ***********************************************************
    */
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 완료..[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)

END

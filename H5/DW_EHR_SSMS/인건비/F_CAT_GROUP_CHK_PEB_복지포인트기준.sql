SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[F_CAT_GROUP_CHK_PEB]
    (  @an_cat_appl_cd_std_id   NUMERIC,         -- 복지포인트 적용기준ID
       @ad_base_ymd             DATE    ,         -- 기준일자
		@av_pay_biz_cd     NVARCHAR(50),	   -- 급여사업장 (10)
		@av_org_id         NUMERIC(18,0),   -- 소속ID (20)
		@av_pos_grd_cd     NVARCHAR(10),    -- 직급 (30)
		@av_mgr_type_cd    NVARCHAR(10),    -- 관리구분 (40)
		@av_emp_kind_cd    NVARCHAR(10)     -- 근로형태 (50)
    ) RETURNS INT
    -- ***************************************************************************
    --   TITLE       : 복지포인트그룹체크
	--   DESCRIPTION : 복지포인트 적용기준ID에 사원ID가 포함되는지 여부
    --   PROJECT     : H5
    --   AUTHOR      : 임택구
    --   PROGRAM_ID  : F_CAT_GROUP_CHK_PEB
    --   ARGUMENT    : an_cat_appl_cd_std_id    : 복지포인트 적용기준ID
	--                 an_emp_id				: 사원ID
    --                 ad_base_ymd				: 기준일자
    --   RETURN      : 0(false), @an_cat_appl_cd_std_id(true)
    --   HISTORY     :
    -- ***************************************************************************
AS
BEGIN
            
    DECLARE --@v_company_cd     NVARCHAR(50),    -- 회사코드
            @v_locale_cd      NVARCHAR(50),    -- 지역코드
            @v_pay_group      NVARCHAR(50),    -- 그룹코드
			@v_item_type      NVARCHAR(10),    -- 적용항목구분
			@v_item_cond      NVARCHAR(10),    -- 적용조건
			@v_item_vals      NVARCHAR(4000),  -- 적용항목상세
			@v_org_id         NUMERIC(18,0),   -- 소속ID
			--@v_org_cd         NVARCHAR(50),    -- 소속코드
			@v_pay_biz_cd     NVARCHAR(50),	   -- 급여사업장
			@v_pos_grd_cd     NVARCHAR(10),    -- 직급
			@v_pos_cd         NVARCHAR(10),    -- 직위
			@v_mgr_type_cd         NVARCHAR(10),    -- 관리구분
			@v_emp_kind_cd    NVARCHAR(10),    -- 근로형태
												  
            @n_cond_val       NUMERIC(1,0),    -- 조건 적용값
            @v_ret            INT              -- 결과값
/*
항목구분
10	사업장
20	부서
30	직급
40	관리구분
50	근로형태
*/
    DECLARE cursor_group CURSOR FOR
        SELECT ITEM_TYPE
             , ITEM_COND
             , ITEM_VALS
          FROM CAT_APPL_CD_STD WITH (NOLOCK)
          UNPIVOT ( ITEM_TYPE FOR ITEM_TYPE_COL IN (ITEM_TYPE1, ITEM_TYPE2, ITEM_TYPE3, ITEM_TYPE4, ITEM_TYPE5) )  UNPVT1
          UNPIVOT ( ITEM_COND FOR ITEM_COND_COL IN (ITEM_COND1, ITEM_COND2, ITEM_COND3, ITEM_COND4, ITEM_COND5) )  UNPVT2
          UNPIVOT ( ITEM_VALS FOR ITEM_VALS_COL IN (ITEM_VALS1, ITEM_VALS2, ITEM_VALS3, ITEM_VALS4, ITEM_VALS5) )  UNPVT3
         WHERE CAT_APPL_CD_STD_ID = @an_cat_appl_cd_std_id
           AND RIGHT(ITEM_TYPE_COL,1)  = RIGHT(ITEM_COND_COL, 1)
           AND RIGHT(ITEM_COND_COL,1)  = RIGHT(ITEM_VALS_COL, 1)
           AND RIGHT(ITEM_VALS_COL,1)  = RIGHT(ITEM_TYPE_COL, 1)

	SELECT @v_pay_biz_cd     = @av_pay_biz_cd     , -- 급여사업장 (10)
		   @v_org_id         = @av_org_id         , -- 소속ID (20)
		   @v_pos_grd_cd     = @av_pos_grd_cd     , -- 직급 (30)
		   @v_mgr_type_cd    = @av_mgr_type_cd         , -- 관리구분 (40)
		   @v_emp_kind_cd    = @av_emp_kind_cd      -- 근로형태 (50)

    SET @v_ret = @an_cat_appl_cd_std_id
    OPEN cursor_group
    FETCH NEXT FROM cursor_group INTO @v_item_type, @v_item_cond, @v_item_vals
	
    WHILE (@@FETCH_STATUS = 0 AND @v_ret = @an_cat_appl_cd_std_id)
        BEGIN
            SET @n_cond_val = CASE WHEN @v_item_cond = '10' THEN 1 ELSE -1 END

            -- 사업장
            IF @v_item_type = '10'
                BEGIN
                    IF @v_item_cond = '10'
                        BEGIN
                           SET @v_ret = CASE WHEN @v_pay_biz_cd IN (SELECT Items FROM DBO.FN_SPLIT_ARRAY(STUFF(@v_item_vals, 1, 1, ''), '|'))
                                             THEN @an_cat_appl_cd_std_id
                                             ELSE 0
                                        END
                        END
                    ELSE IF @v_item_cond = '20'
                        BEGIN
                           SET @v_ret = CASE WHEN @v_pay_biz_cd IN (SELECT Items FROM DBO.FN_SPLIT_ARRAY(STUFF(@v_item_vals, 1, 1, ''), '|'))
                                             THEN 0
                                             ELSE @an_cat_appl_cd_std_id
                                        END
                        END
            	END
            -- 부서
            IF @v_item_type = '20' 
                BEGIN
                    --IF ISNULL(NULLIF(CHARINDEX('|' + @v_org_cd + '|', @v_item_vals), 0), -1) * @v_cond_val < 0
                    IF ISNULL(NULLIF(CHARINDEX('|' + CAST(@v_org_id AS NVARCHAR(50)) + '|', @v_item_vals), 0), -1) * @n_cond_val < 0
                        BEGIN
        SET @v_ret = 0
                        END
                END
            -- 직급
            IF @v_item_type = '30' 
                BEGIN
                    IF ISNULL(NULLIF(CHARINDEX('|' + @v_pos_grd_cd + '|', @v_item_vals), 0), -1) * @n_cond_val < 0
                        BEGIN
                            SET @v_ret = 0
                        END
                END
            -- 관리구분
            IF @v_item_type = '40' 
                BEGIN
                    IF ISNULL(NULLIF(CHARINDEX('|' + @v_mgr_type_cd + '|', @v_item_vals), 0), -1) * @n_cond_val < 0
                        BEGIN
                            SET @v_ret = 0
                        END
                END
            -- 근로형태
            IF @v_item_type = '50'
                BEGIN
                    IF ISNULL(NULLIF(CHARINDEX('|' + @v_emp_kind_cd + '|', @v_item_vals), 0), -1) * @n_cond_val < 0
                        BEGIN
                            SET @v_ret = 0
                        END
                END

            FETCH NEXT FROM cursor_group INTO @v_item_type, @v_item_cond, @v_item_vals
        END;

    CLOSE cursor_group;
    DEALLOCATE cursor_group;

    RETURN @v_ret
    
END
GO



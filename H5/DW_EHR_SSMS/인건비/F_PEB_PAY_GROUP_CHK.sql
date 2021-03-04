USE [dwehrdev_H5]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[F_PEB_PAY_GROUP_CHK]
    (  @an_pay_group_id			NUMERIC,		-- 급여그룹ID
	   @an_peb_phm_mst_id		NUMERIC,        -- 사원ID
       @ad_base_ymd             DATE			-- 기준일자
    ) RETURNS INT
    -- ***************************************************************************
    --   TITLE       : 인건비 - 급여그룹체크
	--   DESCRIPTION : 급여그룹ID에 사원ID가 포함되는지 여부
    --   PROJECT     : H5
    --   AUTHOR      : 임택구
    --   PROGRAM_ID  : F_PEB_PAY_GROUP_CHK
    --   ARGUMENT    : an_pay_group_id      : 급여그룹ID
	--                 an_peb_phm_mst_id    : 사원ID
    --                 ad_base_ymd          : 기준일자
    --   RETURN      : 0(false), @an_pay_group_id(true)
    --   HISTORY     :
    -- ***************************************************************************
AS
BEGIN
    DECLARE @v_company_cd     NVARCHAR(50),    -- 회사코드
            @v_locale_cd      NVARCHAR(50),    -- 지역코드
            @v_pay_group      NVARCHAR(50),    -- 그룹코드
			@v_item_type      NVARCHAR(10),    -- 적용항목구분
			@v_item_cond      NVARCHAR(10),    -- 적용조건
			@v_item_vals      NVARCHAR(4000),  -- 적용항목상세
			@v_org_id         NUMERIC(18,0),   -- 소속ID
			--@v_org_cd         NVARCHAR(50),    -- 소속코드
			@v_pay_biz_cd     NVARCHAR(50),	   -- 급여사업장
			@v_pos_grade_cd   NVARCHAR(10),    -- 직급
			@v_pos_cd         NVARCHAR(10),    -- 직위
			@v_mgr_cd         NVARCHAR(10),    -- 관리구분
			@v_emp_kind_cd    NVARCHAR(10),    -- 근로형태
			--@v_group_kind	  NVARCHAR(10),    -- 그룹종류
												  
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
          FROM PAY_GROUP WITH (NOLOCK)
          UNPIVOT ( ITEM_TYPE FOR ITEM_TYPE_COL IN (ITEM_TYPE1, ITEM_TYPE2, ITEM_TYPE3, ITEM_TYPE4, ITEM_TYPE5) )  UNPVT1
          UNPIVOT ( ITEM_COND FOR ITEM_COND_COL IN (ITEM_COND1, ITEM_COND2, ITEM_COND3, ITEM_COND4, ITEM_COND5) )  UNPVT2
          UNPIVOT ( ITEM_VALS FOR ITEM_VALS_COL IN (ITEM_VALS1, ITEM_VALS2, ITEM_VALS3, ITEM_VALS4, ITEM_VALS5) )  UNPVT3
         WHERE PAY_GROUP_ID = @an_pay_group_id
           AND RIGHT(ITEM_TYPE_COL,1)  = RIGHT(ITEM_COND_COL, 1) -- RIGHT('ITEM_TYPE1',1) = RIGHT('ITEM_COND1',1)
           AND RIGHT(ITEM_COND_COL,1)  = RIGHT(ITEM_VALS_COL, 1)
           AND RIGHT(ITEM_VALS_COL,1)  = RIGHT(ITEM_TYPE_COL, 1)

    SELECT @v_company_cd = A.COMPANY_CD
         , @v_locale_cd  = A.LOCALE_CD
		 , @v_pay_group = A.PAY_GROUP
		 --, @v_group_kind = (SELECT SYS_CD FROM FRM_CODE WHERE COMPANY_CD=A.COMPANY_CD AND CD = A.PAY_GROUP
		 --                                                 AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD)
      FROM PAY_GROUP A WITH (NOLOCK)
     WHERE PAY_GROUP_ID = @an_pay_group_id--3597848
	IF @@ROWCOUNT < 1
		BEGIN
			set @v_ret = 0
			return @v_ret
		END;

	IF SUBSTRING(@v_pay_group, 2, 3) = 'XXX' -- 조회전용은 바로 리턴
		BEGIN
			set @v_ret = @an_pay_group_id
			RETURN @v_ret
		END

	SELECT @v_org_id       = EMP.PAY_ORG_ID,        -- 부서ID 20
	      -- @v_org_cd       = EMP.ORG_CD,        -- 부서 20
	       @v_pos_grade_cd = EMP.POS_GRD_CD,    -- 직급 30
	       @v_mgr_cd       = EMP.MGR_TYPE_CD,   -- 관리구분 40
	       @v_emp_kind_cd  = EMP.WK_TYPE_CD, -- emp.EMP_KIND_CD,    -- 근로형태 50
		   @v_pay_biz_cd   = dbo.F_ORM_ORG_BIZ(EMP.PAY_ORG_ID, @ad_base_ymd, 'PAY') -- 사업장 10
	  --FROM VI_FRM_PHM_EMP EMP WITH (NOLOCK)
	  FROM PEB_PHM_MST EMP WITH (NOLOCK)
	 WHERE EMP.PEB_PHM_MST_ID      = @an_peb_phm_mst_id

    IF @@ROWCOUNT < 1
        BEGIN
		    SET @v_ret = 0
            RETURN @v_ret
        END

    OPEN cursor_group
    FETCH NEXT FROM cursor_group INTO @v_item_type, @v_item_cond, @v_item_vals
	
    SET @v_ret = @an_pay_group_id
    WHILE (@@FETCH_STATUS = 0 AND @v_ret = @an_pay_group_id)
        BEGIN
            SET @n_cond_val = CASE WHEN @v_item_cond = '10' THEN 1 ELSE -1 END

            -- 사업장
            IF @v_item_type = '10'
                BEGIN
                    IF @v_item_cond = '10'
                        BEGIN
                           SET @v_ret = CASE WHEN @v_pay_biz_cd IN (SELECT Items FROM DBO.FN_SPLIT_ARRAY(STUFF(@v_item_vals, 1, 1, ''), '|'))
                                             THEN @an_pay_group_id
                                             ELSE 0
                                        END
                        END
                    ELSE IF @v_item_cond = '20'
                        BEGIN
                           SET @v_ret = CASE WHEN @v_pay_biz_cd IN (SELECT Items FROM DBO.FN_SPLIT_ARRAY(STUFF(@v_item_vals, 1, 1, ''), '|'))
                                             THEN 0
                                             ELSE @an_pay_group_id
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
                    IF ISNULL(NULLIF(CHARINDEX('|' + @v_pos_grade_cd + '|', @v_item_vals), 0), -1) * @n_cond_val < 0
                        BEGIN
                            SET @v_ret = 0
                        END
                END
            -- 관리구분
            IF @v_item_type = '40' 
                BEGIN
                    IF ISNULL(NULLIF(CHARINDEX('|' + @v_mgr_cd + '|', @v_item_vals), 0), -1) * @n_cond_val < 0
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

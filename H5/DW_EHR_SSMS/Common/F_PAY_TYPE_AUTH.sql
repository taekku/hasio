USE [dwehrdev_H5]
GO
/****** Object:  UserDefinedFunction [dbo].[F_PAY_GET_COST]    Script Date: 2020-10-19 오전 9:23:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER FUNCTION [dbo].[F_PAY_TYPE_AUTH]
(
    @av_company_cd    NVARCHAR(50),  -- 회사코드
	@av_locale_cd     NVARCHAR(50), -- 언어
    @av_pay_type      NVARCHAR(50),  -- 급여지급유형코드
    @an_emp_id        NUMERIC,        -- 사원ID
	@ad_base_ymd      DATE          -- 기준일자
)
RETURNS NVARCHAR(100)

    -- ***************************************************************************
    --   TITLE       : 급여지급유형코드 권한여부
    --   PROJECT     : H5
    --   AUTHOR      : 인사시스템
    --   PROGRAM_ID  : F_PAY_TYPE_AUTH
    --   ARGUMENT    : av_company_cd        : 회사코드
	--				   av_locale_cd			: 언어
    --                 av_pay_type			: 급여지급유형코드
    --                 an_emp_id            : 사원ID
    --                 ad_base_ymd          : 기준일자
    --   RETURN      : 'Y' : 사용권한이 있음
    --                 'N' : 없음
    --   COMMENT     : 
    -- ***************************************************************************
AS

BEGIN
    DECLARE @v_cost_cd               NVARCHAR(100)    ,      -- 코스트코드
			@v_cost_nm               NVARCHAR(100)    ,      -- 코스트명
			@v_acct_cd               NVARCHAR(100)    ,      -- 계정구분
			@v_cost_type             NVARCHAR(100)    ,      -- 사업부문

            @return_value            NVARCHAR(100)
	set @return_value = 'N'
		SELECT @return_value = 'Y'
		  FROM PAY_GROUP_TYPE A
		  INNER JOIN PAY_GROUP G
				  ON A.PAY_GROUP_ID = G.PAY_GROUP_ID
				 AND ISNULL(@ad_base_ymd, getDate()) BETWEEN G.STA_YMD AND G.END_YMD
		  INNER JOIN PAY_GROUP_USER U
				  ON G.PAY_GROUP_ID = U.PAY_GROUP_ID
				 AND G.LOCALE_CD = U.LOCALE_CD
				 AND ISNULL(@ad_base_ymd, getDate()) BETWEEN U.STA_YMD AND U.END_YMD
		 WHERE U.EMP_ID = @an_emp_id
		   AND A.PAY_TYPE_CD = @av_pay_type
		   AND G.COMPANY_CD = @av_company_cd
		   AND G.LOCALE_CD = @av_locale_cd
		   AND ISNULL(@ad_base_ymd, getDate()) BETWEEN A.STA_YMD AND A.END_YMD
	IF @@ROWCOUNT < 1
		set @return_value = 'N'

	RETURN @return_value

END

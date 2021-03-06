USE [dwehrdev_H5]
GO
/****** Object:  UserDefinedFunction [dbo].[F_REP_R04_DEDUCT]    Script Date: 2020-07-22 오후 3:01:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[F_REP_R04_DEDUCT]
    (  @av_company_cd   NVARCHAR(2),  -- 회사코드
       @ad_base_ymd     DATE,         -- 기준일자
       @an_r04_n_12     NUMERIC       -- 환산급여
    ) RETURNS NUMERIC AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 환산급여별공제 산정
    --<DOCLINE>   AUTHOR      : 화이트정보통신
    --<DOCLINE>   PROGRAM_ID  : F_REP_R04_DEDUCT
    --<DOCLINE> ***************************************************************************

BEGIN
    DECLARE
        @n_sta_mon       NUMERIC,
        @n_deduct_rate   NUMERIC,
        @n_deduct_mon    NUMERIC,
        @n_r04_deduct    NUMERIC

    BEGIN
        -- 환산급여공제관리 기준관리 조회
        SELECT @n_sta_mon     = dbo.XF_TO_NUMBER(KEY_CD1)   -- 환산급여(초과)
             , @n_deduct_rate = dbo.XF_TO_NUMBER(CD2)       -- 공제율(%)
             , @n_deduct_mon  = dbo.XF_TO_NUMBER(CD3)       -- 누진공제액
          FROM FRM_UNIT_STD_HIS A
         INNER JOIN FRM_UNIT_STD_MGR B
            ON A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
           AND B.COMPANY_CD = @av_company_cd
           AND B.UNIT_CD = 'REP'
           AND B.STD_KIND_NM = '환산급여공제관리'
         WHERE @ad_base_ymd BETWEEN A.STA_YMD AND A.END_YMD
           AND @an_r04_n_12 BETWEEN A.KEY_CD1 AND A.CD1
        ;

        -- 환산급여별공제 산정
        --SET @n_r04_deduct = dbo.XF_CEIL(@n_deduct_mon + ((@an_r04_n_12 - dbo.XF_GREATEST_N((@n_sta_mon-1),0,0,0)) * @n_deduct_rate/100), 0);
		SET @n_r04_deduct = dbo.XF_TRUNC_N(@n_deduct_mon + ((@an_r04_n_12 - dbo.XF_GREATEST_N((@n_sta_mon-1),0,0,0)) * @n_deduct_rate/100), 0);

        IF @@ROWCOUNT = 0
            BEGIN
                RETURN NULL;
            END
        IF @@ERROR <> 0
            BEGIN
                RETURN NULL;
            END
    END;

    RETURN @n_r04_deduct;
    
END;
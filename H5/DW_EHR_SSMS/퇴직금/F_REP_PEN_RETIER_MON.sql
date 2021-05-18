SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[F_REP_PEN_RETIRE_MON]
(
      @an_emp_id         NUMERIC(38),        -- 사원 ID
      @ad_base_ymd       DATETIME2           -- 기준일
)   RETURNS NUMERIC(10,0) 
AS

    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : 국민연금전환금 가져오기.
    --<DOCLINE>   PROJECT     : HR시스템
    --<DOCLINE>   AUTHOR      : 송재현
    --<DOCLINE>   PROGRAM_ID  : F_REP_PEN_RETIRE_MON
    --<DOCLINE>   ARGUMENT    :
    --<DOCLINE>
    --<DOCLINE>   RETURN      : ??:???/??:''
    --<DOCLINE>   COMMENT     : ???? return ??.
    --<DOCLINE>   HISTORY     : ?? ??? 2008-02-04
    --<DOCLINE> ***************************************************************************

BEGIN

    DECLARE
  
    @n_val         NUMERIC(10,0);

    BEGIN

		SELECT @n_val = dbo.XF_NVL_N(SUM(PEN_RETIRE_MON), 0) 
          FROM REP_PEN_RETIRE_MON X
		       --LEFT OUTER JOIN -- 왜 필요하지?
         --     (SELECT EMP_ID,
			      --    dbo.XF_NVL_N(SUM(AA.RETIRE_TURN), 0) AS RETIRE_TURN
         --        FROM REP_CALC_LIST AA
         --       WHERE AA.EMP_ID = @an_emp_id 
         --         AND AA.C1_END_YMD <= @ad_base_ymd
         --         AND AA.PAY_YMD IS NOT NULL
         --       GROUP BY EMP_ID
         --      ) Y
         --  ON X.EMP_ID = Y.EMP_ID
        WHERE X.EMP_ID = @an_emp_id 
         
     IF @@ERROR != 0  
            BEGIN
                SET @n_val     = 0
            END
    END
    
    RETURN @n_val

END
GO



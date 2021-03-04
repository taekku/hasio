SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	전환로그생성
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_LOG_H
	 @an_h_id   		numeric
	,@av_kind           nvarchar(1)
	,@av_program_nm		nvarchar(100)
	,@av_params			nvarchar(4000)
	,@av_title			nvarchar(100)
	,@av_t_table		nvarchar(100) = ''
	,@av_s_table		nvarchar(100) = ''
	,@an_cnt_try		numeric = NULL
	,@an_cnt_ok			numeric = NULL
	,@an_cnt_fail		numeric = NULL
AS
BEGIN
	DECLARE @n_cnv_pay_work_id	numeric
	SET NOCOUNT ON
	
	--SELECT @n_cnv_pay_work_id = CNV_PAY_WORK_ID
	--  FROM DBO.CNV_PAY_WORK
	-- WHERE PROGRAM_NM = @av_program_nm
	--   AND PARAMS = @av_params

	IF @av_kind = 'S'
		BEGIN
			--DELETE FROM CNV_PAY_WORK_LOG
			-- WHERE CNV_PAY_WORK_ID = @n_cnv_pay_work_id
			--DELETE FROM CNV_PAY_WORK
			-- WHERE CNV_PAY_WORK_ID = @n_cnv_pay_work_id
			--set @n_cnv_pay_work_id = 0
			--IF @n_cnv_pay_work_id > 0
			--	BEGIN
			--		UPDATE CNV_PAY_WORK
			--		   SET PROGRAM_NM = @av_program_nm
			--			 , PARAMS = @av_params
			--			 , TITLE = @av_title
			--			 , T_TABLE = @av_t_table
			--			 , S_TABLE = @av_s_table
			--			 , CNT_TRY = NULL
			--			 , CNT_OK = NULL
			--			 , CNT_FAIL = NULL
			--			 , STA_TIME = SYSDATETIME()
			--			 , END_TIME = NULL
			--		 WHERE CNV_PAY_WORK_ID = @n_cnv_pay_work_id
			--	END
			--ELSE
				BEGIN
					INSERT INTO CNV_PAY_WORK(
						 PROGRAM_NM
						,PARAMS
						,TITLE
						,T_TABLE
						,S_TABLE
						,NOTE
						,STA_TIME
					) VALUES (
						 @av_program_nm
						,@av_params
						,@av_title
						,@av_t_table
						,@av_s_table
						,''
						,SYSDATETIME()
					)
					set @n_cnv_pay_work_id = @@IDENTITY
				END
		END
	ELSE
		BEGIN
			set @n_cnv_pay_work_id = @an_h_id
			UPDATE CNV_PAY_WORK
			   set CNT_TRY = @an_cnt_try
			     , cnt_ok = @an_cnt_ok
				 , cnt_fail = @an_cnt_fail
				 , END_TIME = SYSDATETIME()
			 WHERE CNV_PAY_WORK_ID = @n_cnv_pay_work_id
		END
PRINT @av_program_nm + ' : ' + @av_kind + ':' + @av_params + ' : ' + @av_title + ' : ' + @av_t_table + ' <- ' + @av_s_table
	RETURN @n_cnv_pay_work_id
END
GO

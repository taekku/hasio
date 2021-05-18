DECLARE @RC int
DECLARE @av_company_cd nvarchar(10)
DECLARE @av_locale_cd nvarchar(10) = 'KO'
DECLARE @av_fr_pay_ym nvarchar(6) = '202101'
DECLARE @av_to_pay_ym nvarchar(6) = '202101'
DECLARE @av_tz_cd nvarchar(10) = 'KST'
DECLARE @an_mod_user_id numeric(18,0) = '0'
DECLARE @av_ret_code nvarchar(100)
DECLARE @av_ret_message nvarchar(500)

DECLARE @v_target_company_cd NVARCHAR(100) = 'A,B,C,E,F,H,I,M,R,S,T,W,X,Y'
--DECLARE @v_target_company_cd NVARCHAR(100) = 'H,I,M,R,S,T,W,X,Y'

--SET @av_fr_pay_ym = '202101'
--SET @av_to_pay_ym = '202105'
SET @v_target_company_cd = 'C '

DECLARE @TARGET_COMPANY TABLE(
	COMPANY_CD	NVARCHAR(10)
)
INSERT INTO @TARGET_COMPANY
SELECT ITEMS
FROM dbo.fn_split_array(@v_target_company_cd,',')

DECLARE @bundle TABLE (
	FR_MONTH NVARCHAR(6),
	TO_MONTH NVARCHAR(6)
)

insert into @bundle(FR_MONTH, TO_MONTH) values ('201501','201512')
insert into @bundle(FR_MONTH, TO_MONTH) values ('201601','201612')
insert into @bundle(FR_MONTH, TO_MONTH) values ('201701','201712')
----
insert into @bundle(FR_MONTH, TO_MONTH) values ('201801','201812')
insert into @bundle(FR_MONTH, TO_MONTH) values ('201901','201912') 
insert into @bundle(FR_MONTH, TO_MONTH) values ('202001','202012') 
insert into @bundle(FR_MONTH, TO_MONTH) values ('202101','202104')

DECLARE WORK_CUR CURSOR READ_ONLY FOR
	SELECT COMPANY_CD
		FROM @TARGET_COMPANY
OPEN WORK_CUR

	WHILE 1 = 1
		BEGIN
			FETCH NEXT FROM WORK_CUR
			      INTO @av_company_cd
			IF @@FETCH_STATUS <> 0 BREAK
			-- =============================================
			--  회사별로집계
			-- =============================================
			DECLARE TERM_CUR CURSOR READ_ONLY FOR
				SELECT FR_MONTH, TO_MONTH
				  FROM @bundle
				 ORDER BY FR_MONTH
			OPEN TERM_CUR
			WHILE 1 = 1
				BEGIN
					FETCH NEXT FROM TERM_CUR
							INTO @av_fr_pay_ym, @av_to_pay_ym
					IF @@FETCH_STATUS <> 0 BREAK
					EXECUTE @RC = [dbo].[P_PEB_GEN_PEB_EST_PAY] 
						@av_company_cd
						,@av_locale_cd
						,@av_fr_pay_ym
						,@av_to_pay_ym
						,@av_tz_cd
						,@an_mod_user_id
						,@av_ret_code OUTPUT
						,@av_ret_message OUTPUT
					PRINT @av_company_cd + ':' + @av_fr_pay_ym + '~' + @av_to_pay_ym + ':' + @av_ret_code + ':' + @av_ret_message
				END
			CLOSE TERM_CUR
			DEALLOCATE TERM_CUR
		END

	CLOSE WORK_CUR
	DEALLOCATE WORK_CUR
	PRINT ' 완료!' + @v_target_company_cd
GO



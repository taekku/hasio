DECLARE @v_cd_company nvarchar(10)
      , @v_auto_date nvarchar(8)
	  , @v_str_seq nvarchar(05)
	  , @v_source_type nvarchar(10)
select @v_cd_company ='H'
      , @v_auto_date ='20200902'
	  , @v_str_seq = '5'
	  , @v_source_type = 'E010'
select *
FROM dwehrdev.dbo.H_IF_SAPINTERFACE
		WHERE CD_COMPANY = @v_cd_company
		AND DRAW_DATE = @v_auto_date				-- 이관일자
		AND SEQ = @v_str_seq						-- 순번(varchar)
		AND ACCT_TYPE = @v_source_type				-- 구분E010급여, E011상여, E012, E017, E018
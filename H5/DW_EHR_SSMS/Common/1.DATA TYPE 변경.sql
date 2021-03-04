declare @my numeric(38,7)
declare @myT numeric(38,5)
declare @result numeric(38,5)

set @my = 123.0000001
select @result = dbo.xf_ceil(@my, default)
select @result

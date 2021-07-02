exec sp_lock 359

EXEC sp_lock 274

exec sp_lock2
exec sp_lock2 @SPID=758

DBCC inputbuffer (932)
SELECT db_name(), schema_name(), original_login()
EXEC sp_who
EXEC sp_who 557  

EXEC sp_who2
EXEC sp_who2 932
EXEC sp_who2 420
EXEC sp_who2 420
EXEC sp_who2 672
EXEC sp_who2 865

-- kill 420  

SELECT name, object_id
FROM sys.tables
where object_id=542273337
/*
Lock Mode
배타적 (X)
공유 (S)
업데이트 (U)
의도 (I)
스키마 (Sch)
대량 업데이트 (BU)

S : Shared Lock
IS : Intention Shared Lock
IX : Intent Exclusive Lock
IU : Intent Update Lock
X : Exclusive Lock
U : Update Lock
 */
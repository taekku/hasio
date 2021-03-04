exec sp_lock

exec sp_lock2

DBCC inputbuffer (178)

EXEC sp_who 178

kill 150

SELECT name, object_id
FROM sys.tables
where object_id=874798524
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
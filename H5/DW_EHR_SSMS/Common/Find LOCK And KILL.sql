exec sp_lock

exec sp_lock2

DBCC inputbuffer (465)-- 239

EXEC sp_who
EXEC sp_who 71

EXEC sp_who2
EXEC sp_who2 103

-- kill 71  

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
exec sp_lock

exec sp_lock2
exec sp_lock2 85

DBCC inputbuffer (185)-- 239

EXEC sp_who
EXEC sp_who 82

EXEC sp_who2
EXEC sp_who2 478


-- kill 488

SELECT name, object_id
FROM sys.tables
where object_id=542273337
/*
Lock Mode
��Ÿ�� (X)
���� (S)
������Ʈ (U)
�ǵ� (I)
��Ű�� (Sch)
�뷮 ������Ʈ (BU)

S : Shared Lock
IS : Intention Shared Lock
IX : Intent Exclusive Lock
IU : Intent Update Lock
X : Exclusive Lock
U : Update Lock
 */
exec sp_lock

exec sp_lock2

DBCC inputbuffer (465)

EXEC sp_who
EXEC sp_who 378

EXEC sp_who2
EXEC sp_who2 195

-- kill 150

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
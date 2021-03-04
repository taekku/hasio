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
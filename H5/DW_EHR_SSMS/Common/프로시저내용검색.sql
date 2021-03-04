SELECT OBJECT_NAME(object_id), A.type, A.type_desc, OBJECT_DEFINITION(object_id)
FROM sys.procedures A
WHERE OBJECT_DEFINITION(object_id) LIKE '%REP_ACCOUNT_NO%'
order by OBJECT_NAME(object_id)

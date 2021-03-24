SELECT OBJECT_NAME(object_id), A.type, A.type_desc, OBJECT_DEFINITION(object_id) objDefinition
FROM sys.procedures A
WHERE OBJECT_DEFINITION(object_id) LIKE '%PAY_HOBONG_%'
order by OBJECT_NAME(object_id)

select substring(b.QUERY_PARAM_NAME,4,80) NEWNAME, a.*, b.*
from FRM_QUERY_DEF_PARAM b
join FRM_QUERY_DEF a
on a.QUERY_DEF_ID = b.QUERY_DEF_ID
where QUERY_PARAM_NAME in ('av_ret_code','av_ret_message')
and QUERY_PARAM_INOUT_TYPE = 'out'
and a.QUERY_NAME like 'PAY%'
;

update b
set B.QUERY_PARAM_NAME = substring(b.QUERY_PARAM_NAME,4,80)
from FRM_QUERY_DEF_PARAM b
join FRM_QUERY_DEF A
ON A.QUERY_DEF_ID = B.QUERY_DEF_ID
AND A.QUERY_NAME like 'PAY%'
where QUERY_PARAM_NAME in ('av_ret_code','av_ret_message')
and QUERY_PARAM_INOUT_TYPE = 'out'

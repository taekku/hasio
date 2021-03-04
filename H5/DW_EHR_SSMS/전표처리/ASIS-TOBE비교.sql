select *
from (
select ROW_NUMBER() over(order by ACCNT_CD, TRDTYP_CD, COSTDPT_CD) tseq, 'A' tname, A.*
from PBT_BILL_CREATE A 
where HRTYPE_GBN ='H8301'
and BILL_GBN ='P5101'
and PROC_DT ='20200810'
and COMPANY_CD ='X'
--AND DEBSER_GBN='50'
--AND TRDTYP_CD='521'

union all

select ROW_NUMBER() over(order by ACCNT_CD, TRDTYP_CD, COSTDPT_CD) tseq, 'B' tname, A.*
from dwehrdev.dbo.PBT_BILL_CREATE A
where HRTYPE_GBN ='H8301'
and BILL_GBN ='P5101'
and PROC_DT ='20200810'
and COMPANY ='X'
--AND DEBSER_GBN='50'
--AND TRDTYP_CD='521'
) A
--WHERE COSTDPT_CD='E837'
order by tseq, tname
--- 866 867

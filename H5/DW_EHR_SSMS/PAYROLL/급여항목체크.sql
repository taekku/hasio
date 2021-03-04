select dtl.CD_COMPANY, dtl.CD_ALLOW
  from dwehrdev.dbo.H_MONTH_SUPPLY dtl
 where YM_PAY >= '201501'
except 
select COMPANY_CD, CD_ITEM
  from CNV_PAY_ITEM
  where TP_CODE='1'

select dtl.CD_COMPANY, dtl.CD_DEDUCT
  from dwehrdev.dbo.H_MONTH_DEDUCT dtl
 where YM_PAY >= '201501'
except 
select COMPANY_CD, CD_ITEM
  from CNV_PAY_ITEM
 where TP_CODE = '2'
-- ToBe코드를 Mapping없는 경우 : 지급
SELECT *
  FROM CNV_PAY_ITEM A
  JOIN (
	select dtl.CD_COMPANY, dtl.CD_ALLOW
	  from dwehrdev.dbo.H_MONTH_SUPPLY dtl
	 where YM_PAY >= '201501'
	   AND CD_COMPANY NOT IN ('O','D','L','Z')
	except 
	select COMPANY_CD, CD_ITEM
	  from CNV_PAY_ITEM
	 WHERE ITEM_CD > ' '
	   and TP_CODE='1') B
  ON A.COMPANY_CD = B.CD_COMPANY AND A.CD_ITEM = B.CD_ALLOW
ORDER BY A.COMPANY_CD, A.CD_ITEM

-- ToBe코드를 Mapping없는 경우 : 공제
SELECT *
  FROM CNV_PAY_ITEM A
  JOIN (
	select dtl.CD_COMPANY, dtl.CD_DEDUCT
	  from dwehrdev.dbo.H_MONTH_DEDUCT dtl
	 where YM_PAY >= '201501'
	   AND CD_COMPANY NOT IN ('O','D','L','Z')
	except 
	select COMPANY_CD, CD_ITEM
	  from CNV_PAY_ITEM
	 WHERE ITEM_CD > ' '
	   and TP_CODE='2') B
  ON A.COMPANY_CD = B.CD_COMPANY AND A.CD_ITEM = B.CD_DEDUCT
ORDER BY A.COMPANY_CD, A.CD_ITEM

select distinct NM_ITEM, ITEM_NM
from CNV_PAY_ITEM
where COMPANY_CD NOT IN ('O','D','L','Z')
and ISNULL(item_nm,'') != ''
and NM_ITEM != ISNULL(item_nm,'')
order by NM_ITEM, ITEM_NM

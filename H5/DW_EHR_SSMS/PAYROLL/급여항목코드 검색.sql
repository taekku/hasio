DECLARE @search_val nvarchar(10) = '½É¾ß'
	  , @company nvarchar(10) = 'I'
select *
from CNV_PAY_ITEM
where (
		NM_ITEM like '%' + @search_val + '%'
	OR ITEM_NM like '%' + @search_val + '%'
)
AND COMPANY_CD LIKE @company + '%'

SELECT *
FROM FRM_CODE
WHERE CD_KIND = 'PAY_ITEM_CD'
AND COMPANY_CD = 'E'
AND CD_NM like '%' + @search_val + '%'

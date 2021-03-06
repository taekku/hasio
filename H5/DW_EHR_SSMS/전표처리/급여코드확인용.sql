SELECT DISTINCT A.COMPANY_CD, ITEM_KIND, INCITEM, PAY_ITEM_CD, PAY.NM_ITEM, h.CD_ALLOW
FROM (
	SELECT M.COMPANY_CD, ITEM_CD ITEM_KIND, A.INCITEM, (
		SELECT ITEM_CD
		  FROM CNV_PAY_ITEM
		 WHERE TP_CODE = CASE WHEN A.ITEM_CD='G' THEN '1' ELSE '2' END
		   AND CD_ITEM = A.INCITEM
		   AND COMPANY_CD=M.COMPANY_CD
		) AS PAY_ITEM_CD
	FROM PBT_INCITEM A
	JOIN PBT_ACCNT_STD M
	  ON A.PBT_ACCNT_STD_ID = M.PBT_ACCNT_STD_ID
	WHERE ITEM_CD IN ('G','H') -- ����, ����
) A
LEFT OUTER JOIN CNV_PAY_ITEM PAY
ON A.COMPANY_CD = PAY.COMPANY_CD
AND A.INCITEM = PAY.CD_ITEM
LEFT OUTER JOIN (SELECT distinct CD_COMPANY, CD_ALLOW FROM dwehrdev.dbo.H_MONTH_SUPPLY) h
ON A.COMPANY_CD = h.CD_COMPANY
AND A.INCITEM = h.CD_ALLOW
WHERE PAY_ITEM_CD IS NULL
AND A.COMPANY_CD IN ('B')--,'X')

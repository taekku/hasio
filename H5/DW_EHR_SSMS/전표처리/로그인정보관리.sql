SELECT AUTH_ITEM_ID
     , AUTH_ITEM_NAME
     , NOTE
     , AUTH_ITEM_TYPE
     , COMPANY_CD
     , (SELECT COMPANY_NM FROM FRM_COMPANY WHERE COMPANY_CD = FAI.COMPANY_CD) AS COMPANY_NM
  FROM FRM_AUTH_ITEM FAI
 WHERE (NULL IS NULL OR AUTH_ITEM_NAME LIKE '%' + NULL + '%' OR NOTE LIKE '%' + NULL + '%')
ORDER BY COMPANY_CD

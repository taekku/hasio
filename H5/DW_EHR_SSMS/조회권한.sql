DECLARE @av_company_cd nvarchar(10) = 'E'
;
WITH CTE AS (
		SELECT A.PAY_VIEW_ID, B.PAY_VIEW_USER_ID, B.EMP_ID, B.STA_YMD, B.END_YMD
		  FROM PAY_VIEW A
		  JOIN PAY_VIEW_USER B
			ON A.PAY_VIEW_ID = B.PAY_VIEW_ID
		 WHERE A.COMPANY_CD = @av_company_cd)
	SELECT *
	  FROM CTE A
	  JOIN CTE B
	    ON A.EMP_ID = B.EMP_ID
	   AND A.STA_YMD <= B.END_YMD
	   AND A.END_YMD >= B.STA_YMD
	   AND A.PAY_VIEW_USER_ID != B.PAY_VIEW_USER_ID
	 --WHERE A.COMPANY_CD = @av_company_cd
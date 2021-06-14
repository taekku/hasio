declare @company_cd nvarchar(10) = 'F'
declare @locale_cd nvarchar(10) = 'KO'
declare @lang_cd nvarchar(10) = 'KO'
declare @appl_cd nvarchar(10) = 'ECC08'
declare @emp_id NUMERIC(38) = 55958

--SELECT *
--FROM VI_FRM_PHM_EMP
--WHERE COMPANY_CD='F' AND EMP_NM='김태호' AND IN_OFFI_YN='Y'
--신청서별 담당자
;
WITH P_ORG AS (
	SELECT 1 AS LVL
		 , ORG_ID
		 , SUPER_ORG_ID
		 , ORG_CD
	  FROM VI_FRM_ORM_ORG
	 WHERE ORG_ID = (
	 			SELECT ORG_ID
	 			  FROM PHM_EMP
	 			 WHERE EMP_ID =  @emp_id 
	 	   )
	   AND GETDATE() BETWEEN STA_YMD AND END_YMD
	 UNION ALL
	SELECT P_ORG.LVL + 1 AS LVL
		 , ORG.ORG_ID
		 , ORG.SUPER_ORG_ID
		 , ORG.ORG_CD
	  FROM VI_FRM_ORM_ORG ORG
		   INNER JOIN P_ORG
		      ON P_ORG.SUPER_ORG_ID = ORG.ORG_ID
	 WHERE GETDATE() BETWEEN STA_YMD AND END_YMD
)
SELECT A.*
	-- , NEXT VALUE FOR dbo.S_FRM_SEQUENCE OVER (ORDER BY ORD_NO) AS WORK_ID
  FROM (
		SELECT EEA.EMP_ID
			 , dbo.F_FRM_CODE_NM( EEA.COMPANY_CD,  @locale_cd , 'ELA_LINE_TYPE_CD', 'receiver', dbo.XF_SYSDATE(0), '1' ) AS LINE_NM
			 , dbo.F_FRM_CODE_NM( EEA.COMPANY_CD,  @locale_cd , 'ELA_NODE_TYPE_CD', EEA.NODE_TYPE_CD, dbo.XF_SYSDATE(0), '1' ) AS NODE_TYPE_LABEL
			 , EEA.NODE_TYPE_CD AS NODE_TYPE_CD
			 , dbo.F_ELA_WORKER_LABEL( EEA.EMP_ID,  @locale_cd , dbo.XF_SYSDATE(0),  @locale_cd ,  EEA.APPL_CD, 'receiver') AS WORKER_LABEL
			 , dbo.F_ELA_STATE_LABEL( '', EEA.EMP_ID,  @locale_cd , dbo.XF_SYSDATE(0),  @locale_cd ) AS STATE_LABEL
			 , EEA.ORD_NO
			 , COUNT(1) OVER(PARTITION BY EEA.ORD_NO ORDER BY EEA.ORD_NO,P_ORG.LVL) CNT
			 , P_ORG.LVL
			 , P_ORG.ORG_CD
			 , '' AS WORK_DATE
			 , '' AS STATE_CD
		  FROM P_ORG
			   INNER JOIN ELA_EMP_APPR EEA
				  ON P_ORG.ORG_ID = EEA.ORG_ID
		 WHERE EEA.COMPANY_CD =  @company_cd 
		   AND EEA.APPL_CD =  @appl_cd
	   ) A
 WHERE CNT = 1
 ORDER BY LVL, ORD_NO, EMP_ID
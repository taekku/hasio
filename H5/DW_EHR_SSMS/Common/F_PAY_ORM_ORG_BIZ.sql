SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[F_PAY_ORM_ORG_BIZ]
(
   @an_org_id       NUMERIC(38)	/* ����ID*/,
   @ad_base_ymd     date		/* ��������*/,
   @av_biz_type     nvarchar(10)
)
RETURNS NVARCHAR(10)
AS
--<DOCLINE> ***************************************************************************
--<DOCLINE>   TITLE       : �ش�μ��� ����� Ÿ�Կ� ���� ����� �ڵ带 ����
--<DOCLINE>   PROJECT     : H5
--<DOCLINE>   AUTHOR      : R5 ����
--<DOCLINE>   PROGRAM_ID  : [F_ORM_ORG_BIZ]
--<DOCLINE>   ARGUMENT    : an_org_id      - �μ��ڵ�
--<DOCLINE>                 ad_base_ymd    - ��������('yyyymmdd')
--<DOCLINE>                 @av_biz_type   -	PHM : �λ�����,
--<DOCLINE>										DTM : ���»����,
--<DOCLINE>										PAY : �޿������,
--<DOCLINE>										REG : �Ű�����
--<DOCLINE>   RETURN      : ����:�ڵ��/����:''
--<DOCLINE>   COMMENT     : �μ�ID�� ����� Ÿ�Կ� �´� ����� �ڵ� ����
--<DOCLINE>   HISTORY     : 
--<DOCLINE> ***************************************************************************
BEGIN
      DECLARE
		 @v_biz_cd	NVARCHAR(10)

      
    BEGIN
		WITH ORM_ORG_LVL
		AS
		(
			   SELECT 1 AS LEVEL,B.COMPANY_CD, A.ORG_ID,A.SUPER_ORG_ID,A.ORG_NM,A.STA_YMD,A.END_YMD 
				 FROM ORM_ORG_HIS A
				INNER JOIN ORM_ORG B
				   ON A.ORG_ID = B.ORG_ID
				WHERE @ad_base_ymd BETWEEN A.STA_YMD AND A.END_YMD
				  AND A.ORG_ID = @an_org_id
			    UNION ALL
			   SELECT LEVEL + 1,D.COMPANY_CD, C.ORG_ID,C.SUPER_ORG_ID,C.ORG_NM,C.STA_YMD,C.END_YMD
			     FROM dbo.ORM_ORG_HIS C
			    INNER JOIN ORM_ORG D
				   ON C.ORG_ID = D.ORG_ID
			    INNER JOIN ORM_ORG_LVL E 
				   ON E.SUPER_ORG_ID = C.ORG_ID
				  AND D.COMPANY_CD = E.COMPANY_CD
			  WHERE @ad_base_ymd BETWEEN C.STA_YMD AND C.END_YMD
		)
		SELECT @v_biz_cd  = X.BIZ_CD
		  FROM (
				SELECT LEVEL,B.*,MIN( CASE WHEN B.ORM_BIZ_ORG_MAP_ID IS NOT NULL THEN LEVEL ELSE NULL END ) OVER() MIN_LEVEL
				  FROM ORM_ORG_LVL A
				  LEFT OUTER JOIN (
									SELECT D.COMPANY_CD,B.ORM_BIZ_ORG_MAP_ID,B.ORG_ID,B.STA_YMD,B.END_YMD,D.BIZ_CD,D.BIZ_NM
									  FROM ORM_BIZ_ORG_MAP B
									 INNER JOIN ORM_BIZ_TYPE C
										ON B.ORM_BIZ_TYPE_ID = C.ORM_BIZ_TYPE_ID
									   AND C.BIZ_TYPE_CD = @av_biz_type
									 INNER JOIN ORM_BIZ_INFO D
										ON C.ORM_BIZ_INFO_ID = D.ORM_BIZ_INFO_ID
								  )B
					ON A.ORG_ID = B.ORG_ID
				   AND @ad_base_ymd BETWEEN B.STA_YMD AND B.END_YMD
				   AND A.COMPANY_CD = B.COMPANY_CD
			   ) X
		  WHERE LEVEL = MIN_LEVEL 
		;
	END

	RETURN  @v_biz_cd

END
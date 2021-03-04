USE dwehrdev
GO
DECLARE @P_COMPANY VARCHAR(10) = 'Y'
      , @P_HRTYPE_GBN VARCHAR(10) = 'H8306'
	  , @V_PAY_CD VARCHAR(10) = '03' -- 01:���޿�,02:��,03:�繫���޿�,04:�޿��ұ�,05:PI����,06:������
	  , @V_PAY_CD1 VARCHAR(10) = '04'
	  , @V_YYYYMM VARCHAR(6) = '202006'
	  --,@P_PROC_DATE VARCHAR(8) = '20200325'

SELECT A.WORK_SITE_CD
					 ,A.MAPCOSTDPT_CD  
					 ,COUNT(DISTINCT(A.SABUN)) AS SABUN_CNT      -- ���ο�
					 ,SUM(A.AMT_RETR_PAY) AS AOLWTOT_AMT          -- �޿��Ѿ�
					 ,0 AS TAXFREEALOW   -- �����
					 ,SUM(A.INCTAX) AS INCTAX                -- �ҵ漼
					 ,SUM(A.INHTAX) AS INGTAX                -- �ֹμ�  
					 ,SUM(A.INCTAX_OLD) AS INCTAX_OLD        -- �����ҵ漼
					 ,SUM(A.INHTAX_OLD) AS INHTAX_OLD        -- �����ֹμ�
				FROM ( 
					   SELECT ISNULL(C.CD_WORK_AREA, '') AS WORK_SITE_CD
							  ,CASE B.BIZ_ACCT WHEN '00689' THEN '00177' --���翵������
											   ELSE  B.BIZ_ACCT   --END    
								END AS      MAPCOSTDPT_CD 
							 ,A.NO_PERSON SABUN                      -- ���ο�
							 ,A.AMT_RETR_PAY                    -- �޿��Ѿ�
							 ,0 AS TAXFREEALOW                  -- �����
							 ,A.AMT_FIX_STAX  INCTAX_OLD              -- �ҵ漼
							 ,A.AMT_FIX_JTAX  INHTAX_OLD              -- �ֹμ�
							 /* �����̿� -�������ݴ���� */
							 ,CASE WHEN A.NO_PERSON = '20160325' THEN 0 
								   ELSE CASE WHEN SUBSTRING(dbo.fn_GetDongbuCode('HU010', A.LVL_PAY1), 1, 4) IN ('H120','H121') THEN 0 
											 ELSE CASE WHEN ISNULL(A.POSTPONE_TAX,0) = 0 THEN A.POSTPONE_TAX -- �ҵ漼
													   ELSE 0 
												   END 
										  END
								END INCTAX 
							 ,CASE WHEN A.NO_PERSON = '20160325' THEN 0
								   ELSE CASE WHEN SUBSTRING(dbo.fn_GetDongbuCode('HU010', A.LVL_PAY1), 1, 4) IN ('H120','H121') THEN 0 
											 ELSE CASE WHEN ISNULL(FLOOR(A.POSTPONE_TAX / 10),0) = 0  THEN FLOOR(A.POSTPONE_TAX / 10) -- �ֹμ�
													   ELSE 0 
												   END 
									     END
							   END INHTAX              
						 FROM H_RETIRE_DETAIL A
							  INNER JOIN H_HUMAN C
							     ON A.CD_COMPANY = C.CD_COMPANY
							    AND A.NO_PERSON = C.NO_PERSON
							  LEFT OUTER JOIN B_COST_CENTER B
							    ON B.CD_CC = C.CD_CC
							   AND B.CD_COMPANY = C.CD_COMPANY
						WHERE A.CD_COMPANY = @P_COMPANY
						  AND C.HRTYPE_GBN = @P_HRTYPE_GBN -- �η����� 
						  AND SUBSTRING(A.DT_BASE,1,6) = @V_YYYYMM
						  AND A.FG_RETR IN ('1','3')
						  AND A.YN_MID <> 'Y'
						  AND A.FG_RETPENSION_KIND = 'DB'
						  AND A.AMT_RETR_PAY <> 0) A
				GROUP BY A.WORK_SITE_CD
						,A.MAPCOSTDPT_CD  
				ORDER BY A.WORK_SITE_CD
						,A.MAPCOSTDPT_CD
			 
USE dwehrdev_H5
GO
DECLARE @av_company_cd varchar(10) = 'Y'
      , @av_locale_cd varchar(10) = 'KO'
      , @V_YYYYMM varchar(10)='202006'
	  , @av_hrtype_cd varchar(10) = 'H8306'
	  , @av_tax_kind_cd varchar(10) = 'A1'
SELECT DBO.F_ORM_ORG_BIZ(A.ORG_ID, A.PAY_YMD,'PAY') AS PAY_BIZ_CD,
       dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.PAY_YMD, '1') AS COST_CD,
	   (SELECT COST_TYPE FROM ORM_COST WHERE COMPANY_CD = A.COMPANY_CD AND COST_CD = dbo.F_ORM_ORG_COST(A.COMPANY_CD, A.EMP_ID, A.PAY_YMD, '1')
	                                   AND A.C1_END_YMD BETWEEN STA_YMD AND END_YMD) AS MAPCOSTDPT_CD,
		A.EMP_ID,
		A.C_01 AS AMT_RETR_PAY, -- �޿��Ѿ�
		0 TAXFREEALOW,          -- �����
		A.R06_S AS INCTAX_OLD,                -- �ҵ漼
		A.CT02 AS INHTAX_OLD,                 -- �ֹμ�
		A.TRANS_INCOME_AMT INCTAX,     -- �����̿��ҵ漼
		A.TRANS_RESIDENCE_AMT INHTAX,   -- �����̿��ֹμ�
		A.T01, -- �����ҵ漼
		A.T02  -- �����ֹμ�
  FROM REP_CALC_LIST A
  JOIN PHM_PRIVATE PRI
    ON A.EMP_ID = PRI.EMP_ID
   AND A.C1_END_YMD BETWEEN PRI.STA_YMD AND PRI.END_YMD
 WHERE A.COMPANY_CD = @av_company_cd
   AND PRI.FROM_TYPE_CD = @av_hrtype_cd -- �η�����
   AND FORMAT(A.C1_END_YMD, 'yyyyMM') = @V_YYYYMM
   AND A.CALC_TYPE_CD IN ('01','02') -- ����, �߰�����
   AND A.REP_MID_YN != 'Y'
   AND A.INS_TYPE_CD = '10' -- DB��
   AND A.C_01 <> 0

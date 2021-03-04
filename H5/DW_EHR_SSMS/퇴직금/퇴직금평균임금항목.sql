SELECT DISTINCT KEY_CD2 AS PAY_ITEM_CD  
                  FROM FRM_UNIT_STD_HIS  
                 WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
                                                FROM FRM_UNIT_STD_MGR  
                                               WHERE COMPANY_CD = 'E'--@av_company_cd  
                                                 AND UNIT_CD = 'REP'  
                                                 AND STD_KIND = 'REP_AVG_ITEM_CD' )  
                   AND '20191231' BETWEEN STA_YMD AND END_YMD  
                   --AND KEY_CD1 = @av_pay_type_cd  
;

SELECT SUM(dbo.XF_NVL_N(CAL_MON,0)) 
                              FROM VI_PAY_PAYROLL_DETAIL_ALL   A
							  INNER JOIN (SELECT DISTINCT KEY_CD2 AS PAY_ITEM_CD  
										  FROM FRM_UNIT_STD_HIS  
										 WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																		FROM FRM_UNIT_STD_MGR  
																	   WHERE COMPANY_CD = 'E'--@av_company_cd  
																		 AND UNIT_CD = 'REP'  
																		 AND STD_KIND = 'REP_AVG_ITEM_CD' )  
										   AND '20191231' BETWEEN STA_YMD AND END_YMD  ) B
								ON A.PAY_ITEM_CD = B.PAY_ITEM_CD
                             WHERE BEL_PAY_YM = '201911'-- @av_pay_ym  
                               AND COMPANY_CD = 'E'--@av_company_cd  
                               --AND EMP_ID = @n_emp_id  
                              -- AND PAY_ITEM_CD = @v_pay_item_cd  
							   --AND (@av_pay_type_cd !='10' OR  (@av_pay_type_cd = '10' AND PAY_TYPE_CD = '001')) 
;

(SELECT SUM(dbo.XF_NVL_N(CAL_MON,0)) 
                              FROM VI_PAY_PAYROLL_DETAIL_ALL t0
							  INNER JOIN (SELECT DISTINCT KEY_CD2 AS PAY_ITEM_CD  
										  FROM FRM_UNIT_STD_HIS  
										 WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																		FROM FRM_UNIT_STD_MGR  
																	   WHERE COMPANY_CD = :company_cd
																		 AND UNIT_CD = 'PAY'  
																		 AND STD_KIND = 'PAY_ITEM_CD_BASE' )  
										   AND :pay_ymd BETWEEN STA_YMD AND END_YMD
										   AND CD1='PAY_PAY') t1
								ON t0.PAY_ITEM_CD = t1.PAY_ITEM_CD
                             WHERE BEL_PAY_YM between dbo.xf_to_char_d(:pay_ymd, 'yyyy') + '01' AND dbo.xf_to_char_d(:pay_ymd, 'YYYYMM') -- '201911'-- @av_pay_ym  
                               AND COMPANY_CD = :company_cd
                               AND t0.EMP_ID = A.EMP_ID) AS base_year_salary
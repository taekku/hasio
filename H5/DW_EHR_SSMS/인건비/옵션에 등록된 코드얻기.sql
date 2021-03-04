--SELECT HIS.KEY_CD2 AS CD
--     , DBO.F_FRM_CODE_NM('E', 'KO', 'PAY_ITEM_CD', HIS.KEY_CD2, GETDATE(), '1') AS CD_NM
--		 , HIS.KEY_CD1 PAY_GROUP_CD
--  FROM FRM_UNIT_STD_MGR MGR
--       INNER JOIN FRM_UNIT_STD_HIS HIS
--               ON MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
--              AND MGR.UNIT_CD = 'PEB'
--              AND MGR.STD_KIND = 'PEB_ORDWAGE_ITEM'
-- WHERE MGR.COMPANY_CD = 'E'
--   AND MGR.LOCALE_CD = 'KO'
--   AND GETDATE() BETWEEN HIS.STA_YMD AND HIS.END_YMD
-- ORDER BY DBO.F_FRM_CODE_NM('E', 'KO', 'PAY_ITEM_CD', HIS.KEY_CD2, GETDATE(), 'O')
--GO

declare @av_company_cd nvarchar(10)
      , @av_locale_cd nvarchar(10)
set @av_company_cd = 'E'
set @av_locale_cd = 'KO'
select dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_BASE',
								NULL, NULL, NULL, NULL, NULL,
								'EA01','102', NULL, NULL, NULL,
								--getDate(),
								'20211231',
								'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
																		-- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
								)
								)
select dbo.XF_TO_NUMBER( dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_PROM_BASE',
								NULL, NULL, NULL, NULL, NULL,
								'EA01','102', NULL, NULL, NULL,
								--getDate(),
								'20211231',
								'H2' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
																		-- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
								)
								)
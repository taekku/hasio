-- 은행코드
INSERT INTO [dbo].[FRM_CODE]
           ([CD_ID]
           ,[LOCALE_CD]
           ,[COMPANY_CD]
           ,[CD_KIND]
           ,[CD]
           ,[CD_NM]
           ,[SHORT_NM]
           ,[FOR_NM]
           ,[PRINT_NM]
           ,[MAIN_CD]
           ,[SYS_CD]
           ,[STA_YMD]
           ,[END_YMD]
           ,[ORD_NO]
           ,[NOTE]
           ,[MOD_USER_ID]
           ,[MOD_DATE]
           ,[LABEL_CD])
    SELECT NEXT VALUE FOR S_FRM_SEQUENCE
           , 'KO'
           , 'E'
           , 'PAY_BANK_CD'
           , CD_BANK
           , NM_BANK
           , NM_BANK
           , NULL
           , NM_BANK
           , NULL
           , NULL
           , CONVERT(DATETIME2, '19000101')
           , CONVERT(DATE, '29991231')
           , CD_BANK
           , NULL
           , 0
           , GETDATE()
           , NULL
        FROM DWEHRDEV.DBO.B_BANK
GO
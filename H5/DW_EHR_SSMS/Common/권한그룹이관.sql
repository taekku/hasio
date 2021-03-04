
INSERT INTO [dbo].[FRM_CODE_KIND]
           ([CD_KIND_ID]
           ,[LOCALE_CD]
           ,[CD_KIND]
           ,[CD_KIND_NM]
           ,[STA_YMD]
           ,[END_YMD]
           ,[CHANGE_YN]
           ,[NOTE]
           ,[MOD_USER_ID]
           ,[MOD_DATE])
     VALUES
           (NEXT VALUE FOR S_FRM_SEQUENCE    --CD_KIND_ID
           ,'KO'                             --LOCALE_CD
           ,'PAY_GROUP_CD'                   --CD_KIND
           ,'급여그룹'                         --CD_KIND_NM
           , CONVERT(DATETIME2, '19000101')  --STA_YMD
           , CONVERT(DATETIME2, '29991231')  --END_YMD
           ,'Y'                              --CHANGE_YN
           ,NULL                             --NOTE
           ,0                                --MOD_USER_ID
           ,GETDATE()                        --MOD_DATE
		   )
GO

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
     SELECT
           NEXT VALUE FOR S_FRM_SEQUENCE --CD_ID
           ,'KO'                         --LOCALE_CD
           ,CD_COMPANY                   --COMPANY_CD
           ,'PAY_GROUP_CD'               --CD_KIND
           ,CD_DETAIL                    --CD
           ,NM_DETAIL                    --CD_NM
           ,NM_DETAIL                    --SHORT_NM
           ,NULL                         --FOR_NM
           ,NULL                         --PRINT_NM
           ,NULL                         --MAIN_CD
           ,CASE WHEN CD_DETAIL LIKE '%XXX%' THEN '02' ELSE '01' END                          --SYS_CD
           ,'19000101'                    --STA_YMD
           ,CASE WHEN YN_USE = 'Y' THEN CONVERT(DATE, '29991231') ELSE DT_UPDATE END --END_YMD
           ,SEQ_DISPLAY                  --ORD_NO
           ,TXT_DESC                     --NOTE
           ,0                            --MOD_USER_ID
           ,DT_INSERT                    --MOD_DATE
           ,NULL                         --LABEL_CD
       FROM DWEHRDEV.DBO.B_DETAIL_CODE_COMPANY WHERE CD_MASTER = 'HU187'
GO




INSERT INTO PAY_GROUP
     ( PAY_GROUP_ID
     , COMPANY_CD
	 , LOCALE_CD
	 , PAY_GROUP
	 , ITEM_TYPE1
	 , ITEM_VALS1
	 , ITEM_COND1
	 , ITEM_TYPE2
	 , ITEM_VALS2
	 , ITEM_COND2
	 , ITEM_TYPE3
	 , ITEM_VALS3
	 , ITEM_COND3
	 , ITEM_TYPE4
	 , ITEM_VALS4
	 , ITEM_COND4
	 , ITEM_TYPE5
	 , ITEM_VALS5
	 , ITEM_COND5
	 , STA_YMD
	 , END_YMD
	 , NOTE
	 , TZ_CD
	 , TZ_DATE
	 , MOD_USER_ID
	 , MOD_DATE
	 )
SELECT NEXT VALUE FOR S_PAY_SEQUENCE , 
	   AAA.CD_COMPANY AS COMPANY_CD
     , 'KO' AS LOCALE_CD
	 , AAA.CD_PAYGP AS PAY_GROUP
	 --, CASE WHEN AAA.CD_PAYGP = 'F99' THEN '전체(종전)'
	 --       WHEN AAA.CD_PAYGP = 'HXXX' THEN '조회전용'
	 --       WHEN AAA.CD_PAYGP = 'EB01' THEN '생산직급여' 
		--	ELSE BBB.NM_DETAIL END AS PAY_GROUP
     , CASE WHEN AAA.FIRST_IN = 1 THEN '10'  --사업장
            WHEN AAA.FIRST_IN = 2 THEN '20'  --부서
            WHEN AAA.FIRST_IN = 3 THEN '30'  --직급
            WHEN AAA.FIRST_IN = 4 THEN '40'  --관리구분
            WHEN AAA.FIRST_IN = 5 THEN '50'  --근로형태
       END AS ITEM_TYPE1
     , '|' +CASE WHEN AAA.FIRST_IN = 1 THEN REPLACE(REPLACE(AAA.CD_BIZ_AREA, '''', ''), ',', '|')
            --WHEN AAA.FIRST_IN = 2 THEN REPLACE(REPLACE(AAA.CD_DEPT, '''', ''), ',', '|')
            WHEN AAA.FIRST_IN = 2 THEN STUFF((SELECT '|' + ISNULL(CAST(DEPT2.ORG_ID AS NVARCHAR(50)), DEPT1.Items + '(X)')
                                                FROM DBO.FN_SPLIT_ARRAY(REPLACE(REPLACE(AAA.CD_DEPT, '''', ''), ',', '|'), '|') DEPT1
                                                     LEFT OUTER JOIN VI_FRM_ORM_ORG DEPT2
                                                             ON DEPT1.Items = DEPT2.ORG_CD
                                                            AND GETDATE() BETWEEN DEPT2.STA_YMD AND DEPT2.END_YMD
                                                 FOR XML PATH('')), 1, 1, '')
            WHEN AAA.FIRST_IN = 3 THEN REPLACE(REPLACE(AAA.LVL_PAY1, '''', ''), ',', '|')
            WHEN AAA.FIRST_IN = 4 THEN REPLACE(REPLACE(AAA.TP_DUTY, '''', ''), ',', '|')
            WHEN AAA.FIRST_IN = 5 THEN REPLACE(REPLACE(AAA.FG_PERSON, '''', ''), ',', '|')
       END + '|' AS ITEM_VALS1
     , CASE WHEN AAA.FIRST_IN = 1 THEN CASE WHEN AAA.CD_BIZ_AREA_EXP = '1' THEN '10' ELSE '20' END   --사업장
            WHEN AAA.FIRST_IN = 2 THEN CASE WHEN AAA.CD_DEPT_EXP = '1' THEN '10' ELSE '20' END   --부서
            WHEN AAA.FIRST_IN = 3 THEN CASE WHEN AAA.LVL_PAY1_EXP = '1' THEN '10' ELSE '20' END   --직급
            WHEN AAA.FIRST_IN = 4 THEN CASE WHEN AAA.TP_DUTY_EXP = '1' THEN '10' ELSE '20' END   --관리구분
            WHEN AAA.FIRST_IN = 5 THEN CASE WHEN AAA.FG_PERSON_EXP = '1' THEN '10' ELSE '20' END   --근로형태
       END AS ITEM_COND1
     , CASE WHEN AAA.SECOND_IN = 1 THEN '10'
            WHEN AAA.SECOND_IN = 2 THEN '20'
            WHEN AAA.SECOND_IN = 3 THEN '30'
            WHEN AAA.SECOND_IN = 4 THEN '40'
            WHEN AAA.SECOND_IN = 5 THEN '50'
       END AS ITEM_TYPE2
     , '|' +CASE WHEN AAA.SECOND_IN = 1 THEN REPLACE(REPLACE(AAA.CD_BIZ_AREA, '''', ''), ',', '|')
            --WHEN AAA.SECOND_IN = 2 THEN REPLACE(REPLACE(AAA.CD_DEPT, '''', ''), ',', '|')
            WHEN AAA.SECOND_IN = 2 THEN STUFF((SELECT '|' + ISNULL(CAST(DEPT2.ORG_ID AS NVARCHAR(50)), DEPT1.Items + '(X)')
                                                 FROM DBO.FN_SPLIT_ARRAY(REPLACE(REPLACE(AAA.CD_DEPT, '''', ''), ',', '|'), '|') DEPT1
                                                      LEFT OUTER JOIN VI_FRM_ORM_ORG DEPT2
                                                              ON DEPT1.Items = DEPT2.ORG_CD
                                                             AND GETDATE() BETWEEN DEPT2.STA_YMD AND DEPT2.END_YMD
                                                  FOR XML PATH('')), 1, 1, '')
            WHEN AAA.SECOND_IN = 3 THEN REPLACE(REPLACE(AAA.LVL_PAY1, '''', ''), ',', '|')
            WHEN AAA.SECOND_IN = 4 THEN REPLACE(REPLACE(AAA.TP_DUTY, '''', ''), ',', '|')
            WHEN AAA.SECOND_IN = 5 THEN REPLACE(REPLACE(AAA.FG_PERSON, '''', ''), ',', '|')
       END + '|' AS ITEM_VALS2
     , CASE WHEN AAA.SECOND_IN = 1 THEN CASE WHEN AAA.CD_BIZ_AREA_EXP = '1' THEN '10' ELSE '20' END   --사업장
            WHEN AAA.SECOND_IN = 2 THEN CASE WHEN AAA.CD_DEPT_EXP = '1' THEN '10' ELSE '20' END   --부서
            WHEN AAA.SECOND_IN = 3 THEN CASE WHEN AAA.LVL_PAY1_EXP = '1' THEN '10' ELSE '20' END   --직급
            WHEN AAA.SECOND_IN = 4 THEN CASE WHEN AAA.TP_DUTY_EXP = '1' THEN '10' ELSE '20' END   --관리구분
            WHEN AAA.SECOND_IN = 5 THEN CASE WHEN AAA.FG_PERSON_EXP = '1' THEN '10' ELSE '20' END   --근로형태
       END AS ITEM_COND2
     , CASE WHEN AAA.THIRD_IN = 1 THEN '10'
            WHEN AAA.THIRD_IN = 2 THEN '20'
            WHEN AAA.THIRD_IN = 3 THEN '30'
            WHEN AAA.THIRD_IN = 4 THEN '40'
            WHEN AAA.THIRD_IN = 5 THEN '50'
       END AS ITEM_TYPE3
     , '|' +CASE WHEN AAA.THIRD_IN = 1 THEN REPLACE(REPLACE(AAA.CD_BIZ_AREA, '''', ''), ',', '|')
            --WHEN AAA.THIRD_IN = 2 THEN REPLACE(REPLACE(AAA.CD_DEPT, '''', ''), ',', '|')
            WHEN AAA.THIRD_IN = 2 THEN STUFF((SELECT '|' + ISNULL(CAST(DEPT2.ORG_ID AS NVARCHAR(50)), DEPT1.Items + '(X)')
                                                FROM DBO.FN_SPLIT_ARRAY(REPLACE(REPLACE(AAA.CD_DEPT, '''', ''), ',', '|'), '|') DEPT1
                                                     LEFT OUTER JOIN VI_FRM_ORM_ORG DEPT2
                                                             ON DEPT1.Items = DEPT2.ORG_CD
                                                            AND GETDATE() BETWEEN DEPT2.STA_YMD AND DEPT2.END_YMD
                                                 FOR XML PATH('')), 1, 1, '')
            WHEN AAA.THIRD_IN = 3 THEN REPLACE(REPLACE(AAA.LVL_PAY1, '''', ''), ',', '|')
            WHEN AAA.THIRD_IN = 4 THEN REPLACE(REPLACE(AAA.TP_DUTY, '''', ''), ',', '|')
            WHEN AAA.THIRD_IN = 5 THEN REPLACE(REPLACE(AAA.FG_PERSON, '''', ''), ',', '|')
       END + '|' AS ITEM_VALS3
     , CASE WHEN AAA.THIRD_IN = 1 THEN CASE WHEN AAA.CD_BIZ_AREA_EXP = '1' THEN '10' ELSE '20' END   --사업장
            WHEN AAA.THIRD_IN = 2 THEN CASE WHEN AAA.CD_DEPT_EXP = '1' THEN '10' ELSE '20' END   --부서
            WHEN AAA.THIRD_IN = 3 THEN CASE WHEN AAA.LVL_PAY1_EXP = '1' THEN '10' ELSE '20' END   --직급
            WHEN AAA.THIRD_IN = 4 THEN CASE WHEN AAA.TP_DUTY_EXP = '1' THEN '10' ELSE '20' END   --관리구분
            WHEN AAA.THIRD_IN = 5 THEN CASE WHEN AAA.FG_PERSON_EXP = '1' THEN '10' ELSE '20' END   --근로형태
       END AS ITEM_COND3
     , CASE WHEN AAA.FOURTH_IN = 1 THEN '10'
            WHEN AAA.FOURTH_IN = 2 THEN '20'
            WHEN AAA.FOURTH_IN = 3 THEN '30'
            WHEN AAA.FOURTH_IN = 4 THEN '40'
            WHEN AAA.FOURTH_IN = 5 THEN '50'
       END AS ITEM_TYPE4
     , '|' +CASE WHEN AAA.FOURTH_IN = 1 THEN REPLACE(REPLACE(AAA.CD_BIZ_AREA, '''', ''), ',', '|')
            --WHEN AAA.FOURTH_IN = 2 THEN REPLACE(REPLACE(AAA.CD_DEPT, '''', ''), ',', '|')
            WHEN AAA.FOURTH_IN = 2 THEN STUFF((SELECT '|' + ISNULL(CAST(DEPT2.ORG_ID AS NVARCHAR(50)), DEPT1.Items + '(X)')
                                                 FROM DBO.FN_SPLIT_ARRAY(REPLACE(REPLACE(AAA.CD_DEPT, '''', ''), ',', '|'), '|') DEPT1
                                                      LEFT OUTER JOIN VI_FRM_ORM_ORG DEPT2
                                                              ON DEPT1.Items = DEPT2.ORG_CD
                                                             AND GETDATE() BETWEEN DEPT2.STA_YMD AND DEPT2.END_YMD
                                                  FOR XML PATH('')), 1, 1, '')
            WHEN AAA.FOURTH_IN = 3 THEN REPLACE(REPLACE(AAA.LVL_PAY1, '''', ''), ',', '|')
            WHEN AAA.FOURTH_IN = 4 THEN REPLACE(REPLACE(AAA.TP_DUTY, '''', ''), ',', '|')
            WHEN AAA.FOURTH_IN = 5 THEN REPLACE(REPLACE(AAA.FG_PERSON, '''', ''), ',', '|')
       END + '|' AS ITEM_VALS4
     , CASE WHEN AAA.FOURTH_IN = 1 THEN CASE WHEN AAA.CD_BIZ_AREA_EXP = '1' THEN '10' ELSE '20' END   --사업장
            WHEN AAA.FOURTH_IN = 2 THEN CASE WHEN AAA.CD_DEPT_EXP = '1' THEN '10' ELSE '20' END   --부서
            WHEN AAA.FOURTH_IN = 3 THEN CASE WHEN AAA.LVL_PAY1_EXP = '1' THEN '10' ELSE '20' END   --직급
            WHEN AAA.FOURTH_IN = 4 THEN CASE WHEN AAA.TP_DUTY_EXP = '1' THEN '10' ELSE '20' END   --관리구분
            WHEN AAA.FOURTH_IN = 5 THEN CASE WHEN AAA.FG_PERSON_EXP = '1' THEN '10' ELSE '20' END   --근로형태
       END AS ITEM_COND4
     , CASE WHEN AAA.FIFTH_IN = 1 THEN '10'
            WHEN AAA.FIFTH_IN = 2 THEN '20'
            WHEN AAA.FIFTH_IN = 3 THEN '30'
            WHEN AAA.FIFTH_IN = 4 THEN '40'
            WHEN AAA.FIFTH_IN = 5 THEN '50'
       END AS ITEM_TYPE5
     , '|' +CASE WHEN AAA.FIFTH_IN = 1 THEN REPLACE(REPLACE(AAA.CD_BIZ_AREA, '''', ''), ',', '|')
            --WHEN AAA.FIFTH_IN = 2 THEN REPLACE(REPLACE(AAA.CD_DEPT, '''', ''), ',', '|')
            WHEN AAA.FIFTH_IN = 2 THEN STUFF((SELECT '|' + ISNULL(CAST(DEPT2.ORG_ID AS NVARCHAR(50)), DEPT1.Items + '(X)')
                                                FROM DBO.FN_SPLIT_ARRAY(REPLACE(REPLACE(AAA.CD_DEPT, '''', ''), ',', '|'), '|') DEPT1
                                                     LEFT OUTER JOIN VI_FRM_ORM_ORG DEPT2
                                                             ON DEPT1.Items = DEPT2.ORG_CD
                                                            AND GETDATE() BETWEEN DEPT2.STA_YMD AND DEPT2.END_YMD
                                                 FOR XML PATH('')), 1, 1, '')
            WHEN AAA.FIFTH_IN = 3 THEN REPLACE(REPLACE(AAA.LVL_PAY1, '''', ''), ',', '|')
            WHEN AAA.FIFTH_IN = 4 THEN REPLACE(REPLACE(AAA.TP_DUTY, '''', ''), ',', '|')
            WHEN AAA.FIFTH_IN = 5 THEN REPLACE(REPLACE(AAA.FG_PERSON, '''', ''), ',', '|')
       END + '|' AS ITEM_VALS5
     , CASE WHEN AAA.FIFTH_IN = 1 THEN CASE WHEN AAA.CD_BIZ_AREA_EXP = '1' THEN '10' ELSE '20' END   --사업장
            WHEN AAA.FIFTH_IN = 2 THEN CASE WHEN AAA.CD_DEPT_EXP = '1' THEN '10' ELSE '20' END   --부서
            WHEN AAA.FIFTH_IN = 3 THEN CASE WHEN AAA.LVL_PAY1_EXP = '1' THEN '10' ELSE '20' END   --직급
            WHEN AAA.FIFTH_IN = 4 THEN CASE WHEN AAA.TP_DUTY_EXP = '1' THEN '10' ELSE '20' END   --관리구분
            WHEN AAA.FIFTH_IN = 5 THEN CASE WHEN AAA.FG_PERSON_EXP = '1' THEN '10' ELSE '20' END   --근로형태
       END AS ITEM_COND5
     , CONVERT(DATETIME2, '19000101' ) AS STA_YMD
	 , CASE WHEN BBB.YN_USE = 'N' THEN BBB.DT_UPDATE ELSE CONVERT(DATETIME2, '29991231' ) END AS END_YMD
	 , BBB.TXT_DESC AS NOTE
	 , 'KST' AS TZ_CD
	 , AAA.DT_INSERT AS TZ_DATE
	 , 0 AS MOD_USER_ID
	 , AAA.DT_UPDATE AS MOD_DATE
  FROM (
        SELECT CHARINDEX('Y', AA.ITEM_YN, 1) AS FIRST_IN
             , CASE WHEN AA.ITEM_CNT >= 2 THEN CHARINDEX('Y', AA.ITEM_YN, 1 + CHARINDEX('Y', AA.ITEM_YN, 1)) ELSE 0 END AS SECOND_IN
             , CASE WHEN AA.ITEM_CNT >= 3 THEN CHARINDEX('Y', AA.ITEM_YN, 1 + CHARINDEX('Y', AA.ITEM_YN, 1 + CHARINDEX('Y', AA.ITEM_YN, 1))) ELSE 0 END AS THIRD_IN
             , CASE WHEN AA.ITEM_CNT >= 4 THEN CHARINDEX('Y', AA.ITEM_YN, 1 + CHARINDEX('Y', AA.ITEM_YN, 1 + CHARINDEX('Y', AA.ITEM_YN, 1 + CHARINDEX('Y', AA.ITEM_YN, 1)))) ELSE 0 END AS FOURTH_IN
             , CASE WHEN AA.ITEM_CNT >= 5 THEN CHARINDEX('Y', AA.ITEM_YN, 1 + CHARINDEX('Y', AA.ITEM_YN, 1 + CHARINDEX('Y', AA.ITEM_YN, 1 + CHARINDEX('Y', AA.ITEM_YN, 1 + CHARINDEX('Y', AA.ITEM_YN, 1))))) ELSE 0 END AS FIFTH_IN
             , AA.*
          FROM (
                SELECT CASE WHEN CD_BIZ_AREA IS NOT NULL THEN '10'
                	        ELSE CASE WHEN CD_DEPT IS NOT NULL THEN '20'
                			          ELSE CASE WHEN LVL_PAY1 IS NOT NULL THEN '30'
                					            ELSE CASE WHEN TP_DUTY IS NOT NULL THEN '40'
                								          ELSE CASE WHEN FG_PERSON IS NOT NULL THEN '50' ELSE NULL END
                                                     END
                                           END
                				 END
                       END AS ITEM_TYPE1
                     , CASE WHEN ISNULL(A.CD_BIZ_AREA,'') <> '' THEN 'Y' ELSE 'N' END
                     + CASE WHEN ISNULL(A.CD_DEPT,'') <> '' THEN 'Y' ELSE 'N' END
                     + CASE WHEN ISNULL(A.LVL_PAY1,'') <> '' THEN 'Y' ELSE 'N' END
                     + CASE WHEN ISNULL(A.TP_DUTY,'') <> '' THEN 'Y' ELSE 'N' END
                     + CASE WHEN ISNULL(A.FG_PERSON,'') <> '' THEN 'Y' ELSE 'N' END ITEM_YN
                
                     , CASE WHEN ISNULL(CD_BIZ_AREA,'') <> '' THEN 1 ELSE 0 END
                     + CASE WHEN ISNULL(CD_DEPT,'') <> '' THEN 1 ELSE 0 END
                     + CASE WHEN ISNULL(LVL_PAY1,'') <> '' THEN 1 ELSE 0 END
                     + CASE WHEN ISNULL(TP_DUTY,'') <> '' THEN 1 ELSE 0 END
                     + CASE WHEN ISNULL(FG_PERSON,'') <> '' THEN 1 ELSE 0 END ITEM_CNT
                     , A.*
                  FROM DWEHRDEV.DBO.H_PAY_GROUP A
                ) AA
      ) AAA
      LEFT OUTER JOIN DWEHRDEV.DBO.B_DETAIL_CODE BBB
              ON AAA.CD_PAYGP = BBB.CD_DETAIL
             AND BBB.CD_MASTER = 'HU187'

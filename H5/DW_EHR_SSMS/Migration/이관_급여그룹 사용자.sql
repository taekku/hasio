INSERT INTO PAY_GROUP_USER
           ( PAY_GROUP_USER_ID
           , PAY_GROUP_ID
           , COMPANY_CD
           , LOCALE_CD
           , EMP_ID
           , STA_YMD
           , END_YMD
           , NOTE
           , MOD_USER_ID
           , MOD_DATE
           , TZ_CD
           , TZ_DATE)
     SELECT
             NEXT VALUE FOR S_PAY_SEQUENCE   --PAY_GROUP_USER_ID
           , D.PAY_GROUP_ID                  --PAY_GROUP_ID
           , C.COMPANY_CD                    --COMPANY_CD
           , 'KO'                            --LOCALE_CD
           , C.EMP_ID                        --EMP_ID
           , B.DT_INSERT                     --STA_YMD
           , CASE WHEN C.IN_OFFI_YN = 'N' THEN C.RETIRE_YMD ELSE CONVERT(DATE, '29991231') END  --END_YMD
           , B.REM_COMMENT                   --NOTE
           , 0                               --MOD_USER_ID
           , GETDATE()                       --MOD_DATE
           , 'KST'                           --TZ_CD
           , GETDATE()                       --TZ_DATE
        FROM DWEHRDEV.DBO.O_USER A
		     INNER JOIN DWEHRDEV.DBO.O_USER_COPY AA
			         ON A.ID_LOGIN = AA.ID_LOGIN
					AND A.CD_COMPANY = AA.CD_COMPANY                             
             INNER JOIN DWEHRDEV.DBO.H_PAY_GROUP_USER B
                     ON A.ID_LOGIN = B.NO_PERSON
             INNER JOIN VI_FRM_PHM_EMP C
                     ON A.CD_COMPANY = C.COMPANY_CD
                    AND A.NO_PERSON = C.EMP_NO
             INNER JOIN PAY_GROUP D
                     ON B.CD_COMPANY = D.COMPANY_CD
                    AND B.CD_PAYGP = D.PAY_GROUP
 WHERE AA.YN_USE <> 'N'
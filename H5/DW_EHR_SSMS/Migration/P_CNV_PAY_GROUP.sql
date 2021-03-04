SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion 급여그룹이관
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_PAY_GROUP
      @an_try_no         NUMERIC(4)       -- 시도회차
    , @av_company_cd     NVARCHAR(10)     -- 회사코드
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @s_company_cd nvarchar(10)
	      , @t_company_cd nvarchar(10)
		  -- 변환작업결과
		  , @v_proc_nm   nvarchar(50) -- 프로그램ID
		  , @v_pgm_title nvarchar(100) -- 프로그램Title
		  , @v_params       nvarchar(4000) -- 파라미터
		  , @n_total_record numeric
		  , @n_cnt_success  numeric
		  , @n_cnt_failure  numeric
		  , @v_s_table      nvarchar(50) -- source table
		  , @v_t_table      nvarchar(50) -- target table
		  , @n_log_h_id		  numeric
		  , @v_keys			nvarchar(2000)
		  , @n_err_cod		numeric
		  , @v_err_msg		nvarchar(4000)
		  -- AS-IS Table Key
		  , @cd_company		nvarchar(20) -- 회사코드
		  , @cd_paygp		nvarchar(20) -- PAY_GROUP_CD
		  -- 참조변수
		  , @pay_group_id	numeric -- PAY_GROUP_ID
	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- 프로그램명

	-- =============================================
	-- 전환프로그램설명
	-- =============================================
	set @v_pgm_title = '급여그룹이관'
	-- 파라미터를 합침(로그파일에 기록하기 위해서..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
	set @v_s_table = 'H_PAY_GROUP'   -- As-Is Table
	set @v_t_table = 'PAY_GROUP' -- To-Be Table
	-- =============================================
	-- 전환프로그램설명
	-- =============================================

	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	
	-- Conversion로그정보 Header
	EXEC @n_log_h_id = dbo.P_CNV_PAY_LOG_H 0, 'S', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table
	
	-- =============================================
	--   As-Is Key Column Select
	--   Source Table Key
	-- =============================================
    DECLARE CNV_CUR CURSOR READ_ONLY FOR
		SELECT A.CD_COMPANY
				 , A.CD_PAYGP
			  FROM dwehrdev.dbo.H_PAY_GROUP A
			 WHERE A.CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
	-- =============================================
	--   As-Is Key Column Select
	-- =============================================
	OPEN CNV_CUR

	WHILE 1 = 1
		BEGIN
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			FETCH NEXT FROM CNV_CUR
				INTO @cd_company
				   , @cd_paygp
			-- =============================================
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- 총 건수확인
				set @s_company_cd = @cd_company -- AS-IS 회사코드
				set @t_company_cd = @cd_company -- TO-BE 회사코드
				
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				SELECT @pay_group_id = NEXT VALUE FOR S_PAY_SEQUENCE
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
SELECT @pay_group_id S_PAY_SEQUENCE , 
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
				  WHERE A.CD_COMPANY = @s_company_cd
				    AND A.CD_PAYGP = @cd_paygp
                ) AA
      ) AAA
      LEFT OUTER JOIN DWEHRDEV.DBO.B_DETAIL_CODE BBB
              ON AAA.CD_PAYGP = BBB.CD_DETAIL
             AND BBB.CD_MASTER = 'HU187'
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================

				if @@ROWCOUNT > 0 
					begin
						set @n_cnt_success = @n_cnt_success + 1 -- 성공건수
					end
				else
					begin
						-- *** 로그에 실패 메시지 저장 ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',cd_paypg=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
						set @v_err_msg = '선택된 Record가 없습니다.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** 로그에 실패 메시지 저장 ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- 실패건수
					end
				-- 급여그룹 사용자등록
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
				   , @pay_group_id                   --PAY_GROUP_ID
				   , B.COMPANY_CD                    --COMPANY_CD
				   , 'KO'                            --LOCALE_CD
				   , B.EMP_ID                        --EMP_ID
				   , A.DT_INSERT                     --STA_YMD
				   , B.END_YMD  --END_YMD
				   , A.REM_COMMENT                   --NOTE
				   , dbo.F_CNV_GET_EMP_ID_FROM_ASIS_LOGINID(A.ID_UPDATE)                              --MOD_USER_ID
				   , DT_UPDATE                       --MOD_DATE
				   , 'KST'                           --TZ_CD
				   , DT_UPDATE                       --TZ_DATE
				FROM DWEHRDEV.DBO.H_PAY_GROUP_USER A
				JOIN PHM_EMP_NO_HIS B
				  ON A.CD_COMPANY = @s_company_cd
				 AND A.CD_PAYGP = @cd_paygp
				 AND dbo.F_CNV_GET_EMP_ID_FROM_ASIS_LOGINID(A.NO_PERSON) = B.EMP_ID
			END TRY
			BEGIN CATCH
				-- *** 로그에 실패 메시지 저장 ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',cd_paypg=' + ISNULL(CONVERT(nvarchar(100), @cd_paygp),'NULL')
						set @v_err_msg = ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
				-- *** 로그에 실패 메시지 저장 ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- 실패건수
			END CATCH
		END
	--print '종료 총건수 : ' + dbo.xf_to_char_n(@n_total_record, default)
	--print '성공 : ' + dbo.xf_to_char_n(@n_cnt_success, default)
	--print '실패 : ' + dbo.xf_to_char_n(@n_cnt_failure, default)
	-- Conversion 로그정보 - 전환건수저장
	EXEC [dbo].[P_CNV_PAY_LOG_H] @n_log_h_id, 'E', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table, @n_total_record, @n_cnt_success, @n_cnt_failure

	CLOSE CNV_CUR
	DEALLOCATE CNV_CUR
	PRINT @v_proc_nm + ' 완료!'
	PRINT 'CNT_PAY_WORK_ID = ' + CONVERT(varchar(100), @n_log_h_id)
	RETURN @n_log_h_id
END
GO

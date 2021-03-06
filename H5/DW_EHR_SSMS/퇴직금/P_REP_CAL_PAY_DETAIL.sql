USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_CAL_PAY_DETAIL]    Script Date: 2021-01-28 오후 12:17:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_CAL_PAY_DETAIL] (  
       @av_company_cd                 VARCHAR(10),             -- 인사영역  
       @an_rep_calc_list_id           NUMERIC(38),             -- 퇴직금대상ID  
       @an_rep_pay_std_id             NUMERIC(38),             -- 기준임금ID  
       @av_pay_ym                     VARCHAR(8),              -- 급여년월  
       @av_pay_type_cd                VARCHAR(10),             -- 급여지급구분(10:급여, 20:상여, 40: 연차)   
       @an_base_day                   NUMERIC(10),             -- 기준일수  
       @an_real_day                   NUMERIC(10),             -- 실일수  
       @av_flag                       VARCHAR(10),             -- 일할계산여부  
       @an_mod_user_id                NUMERIC(38),             -- 변경자 사번  
       @an_retrun_cal_mon             NUMERIC(38)      OUTPUT, -- 계산된금액  
       @av_ret_code                   VARCHAR(4000)    OUTPUT, -- 결과코드*/  
       @av_ret_message                VARCHAR(4000)    OUTPUT  -- 결과메시지*/  
    ) AS  
    -- ***************************************************************************  
    --   TITLE       : 퇴직금 기준임금항목 계산  
    --   PROJECT     : HR시스템  
    --   AUTHOR      :  박근한  
    --   PROGRAM_ID  : P_REP_CAL_PAY_DETAIL  
    --   RETURN      : 1) SUCCESS!/FAILURE!  
    --                 2) 결과 메시지  
    --   COMMENT     : 퇴직금 기준임금항목 계산  
    --   HISTORY     : 수정 조유진 2012.03.26  
    --               : 2016.06.24 Modified by 최성용 in KBpharma  
    -- ***************************************************************************  
BEGIN  
  
    /* 기본적으로 사용되는 변수 */  
    DECLARE @v_program_id              VARCHAR(30)  
          , @v_program_nm              VARCHAR(100)  
          , @ERRCODE                   VARCHAR(10)  
  
    DECLARE @n_emp_id                  NUMERIC(38)		-- 사원ID
          , @v_pay_item_cd             VARCHAR(10)		-- 평균임금대상항목 
          , @d_retire_ymd              DATE				-- 퇴직일
          , @n_cal_mon                 NUMERIC(38)		-- 지급내역 
		  , @v_exec_yn				   NVARCHAR(1)		-- 임원여부
  
    /* 기본변수 초기값 셋팅*/  
    SET @v_program_id    = 'P_REP_CAL_PAY_STD'   -- 현재 프로시져의 영문명  
    SET @v_program_nm    = '퇴직금 기준임금관리/임금항목관리'        -- 현재 프로시져의 한글문명  
    SET @av_ret_code     = 'SUCCESS!'  
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)  
	PRINT 'P_REP_CAL_PAY_STD'
	print @av_pay_ym + ':' + @av_pay_type_cd + ':' + convert(varchar(10), @an_base_day) + ':' + convert(varchar(10), @an_real_day)
	       + ':' + @av_flag
    BEGIN  
        -- ***************************************  
        -- 1. 퇴직금 대상자(내역) 조회  
        -- *************************************** 
		SET @v_exec_yn = 'N'
        BEGIN  
            SELECT @n_emp_id     = EMP_ID  
                 , @d_retire_ymd = C1_END_YMD  
				 , @v_exec_yn    = ISNULL(OFFICERS_YN, 'N')
              FROM REP_CALC_LIST  
             WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id  
        END  
        -- ***************************************  
        -- 2. 기준항목 기준 조회  
        -- ***************************************  
        SET @an_retrun_cal_mon = 0 

        BEGIN  
			DECLARE item CURSOR FOR  
				SELECT KEY_CD3 AS PAY_ITEM_CD  
				  FROM FRM_UNIT_STD_HIS  
				 WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
												FROM FRM_UNIT_STD_MGR  
											   WHERE COMPANY_CD = @av_company_cd  
												 AND UNIT_CD = 'REP'  
											  	 AND STD_KIND = CASE WHEN @v_exec_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
					AND @d_retire_ymd BETWEEN STA_YMD AND END_YMD  
					AND KEY_CD1 = @av_pay_type_cd  
			OPEN item  
				FETCH NEXT FROM item INTO @v_pay_item_cd  
				WHILE (@@FETCH_STATUS = 0)  
					BEGIN -- 커서루프  
						print '@v_pay_item_cd:' + @v_pay_item_cd + '/' + FORMAT(sysdatetime(),'HHmmss.fffff')
						SET @n_cal_mon = 0  
						-- ***************************************  
						-- 3. 기존 기준항목 삭제  
						-- ***************************************  
						BEGIN  
							DELETE FROM REP_PAYROLL_DETAIL  
								WHERE REP_PAY_STD_ID = @an_rep_pay_std_id  
								AND PAY_ITEM_CD = @v_pay_item_cd  
							IF @ERRCODE != 0  
								BEGIN  
									SET @av_ret_code    = 'FAILURE!'  
									SET @av_ret_message = dbo.F_FRM_ERRMSG('기준항목 삭제시 에러발생[ERR]', @v_program_id, 0010, null, @an_mod_user_id)   
									CLOSE item      -- 커서닫기  
									DEALLOCATE item -- 커서 할당해제  
									RETURN  
								END  
						END 
					
						-- ***************************************  
						-- 4. 기준항목 금액 조회  dbo.XF_TRUNC_N
						-- ***************************************  
						--BEGIN  
						--	SELECT @n_cal_mon = CASE WHEN @av_flag = 'Y' THEN dbo.XF_ROUND((CAST(SUM(dbo.XF_NVL_N(CAL_MON,0)) AS FLOAT) * (CAST(@an_real_day AS FLOAT) / @an_base_day)), -1)  
						--								ELSE SUM(dbo.XF_NVL_N(CAL_MON,0))                        
						--						END  
						--	  FROM VI_PAY_PAYROLL_DETAIL_ALL  								
						--	 WHERE BEL_PAY_YM = @av_pay_ym  
						--	   AND COMPANY_CD = @av_company_cd  
						--	   AND EMP_ID = @n_emp_id  
						--	   AND PAY_ITEM_CD = @v_pay_item_cd  
								
						--END 
						

						
						print '@v_pay_item_cd ss:' + @v_pay_item_cd + '/' + FORMAT(sysdatetime(),'HHmmss.fffff')
						BEGIN  
						  WITH CTE as (SELECT CD
								FROM FRM_CODE A
								JOIN (SELECT DISTINCT KEY_CD2 AS PAY_TYPE_SYS_CD  
												FROM FRM_UNIT_STD_HIS  
												WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																				FROM FRM_UNIT_STD_MGR  
																				WHERE COMPANY_CD = @av_company_cd  
																				AND UNIT_CD = 'REP'  
																				AND STD_KIND = (CASE WHEN 'N' = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
																			)
												AND @d_retire_ymd BETWEEN STA_YMD AND END_YMD  
												AND KEY_CD1 = @av_pay_type_cd
												AND KEY_CD3 = @v_pay_item_cd
										)B
									ON A.COMPANY_CD = @av_company_cd
								   AND A.CD_KIND = 'PAY_TYPE_CD'
								   AND @d_retire_ymd BETWEEN STA_YMD AND END_YMD 
								   AND (B.PAY_TYPE_SYS_CD IS NULL or A.SYS_CD=B.PAY_TYPE_SYS_CD)
								   AND A.SYS_CD != '100'
							)
							SELECT @n_cal_mon = CASE WHEN @av_flag = 'Y' THEN dbo.XF_ROUND((CAST(SUM(dbo.XF_NVL_N(CAL_MON,0)) AS FLOAT) * (CAST(@an_real_day AS FLOAT) / @an_base_day)), -1)  
														ELSE SUM(dbo.XF_NVL_N(CAL_MON,0))                        
												END  
							  FROM PAY_PAYROLL A
							     INNER JOIN PAY_PAY_YMD C 
								     ON A.PAY_YMD_ID = C.PAY_YMD_ID
							     INNER JOIN PAY_PAYROLL_DETAIL B
								     ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
								 INNER JOIN CTE
								     ON C.PAY_TYPE_CD = CTE.CD
							 WHERE C.CLOSE_YN = 'Y'
							   AND C.PAY_YN = 'Y'
							   AND B.BEL_PAY_YM = @av_pay_ym  
							   AND A.SUB_COMPANY_CD = @av_company_cd 
							   AND A.EMP_ID = @n_emp_id 
							   --AND C.PAY_TYPE_CD IN (SELECT CD FROM CTE)
							   --AND C.PAY_TYPE_CD IN (SELECT CD
										--			  FROM FRM_CODE
										--			 WHERE COMPANY_CD = @av_company_cd 
										--			   AND CD_KIND = 'PAY_TYPE_CD'
										--			   AND SYS_CD IN (SELECT DISTINCT KEY_CD2 AS PAY_ITEM_CD  
										--								FROM FRM_UNIT_STD_HIS  
										--							   WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
										--															  FROM FRM_UNIT_STD_MGR  
										--															 WHERE COMPANY_CD = @av_company_cd  
										--															   AND UNIT_CD = 'REP'  
										--															   AND STD_KIND = (CASE WHEN 'N' = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
										--															   AND @d_retire_ymd BETWEEN STA_YMD AND END_YMD  
										--															   AND KEY_CD1 = @av_pay_type_cd
										--															)
										--							 )
										--			  AND @d_retire_ymd BETWEEN STA_YMD AND END_YMD 
							   --                     )
							   AND B.PAY_ITEM_CD = @v_pay_item_cd  								
						END 
						
						print '@v_pay_item_cd ee:' + @v_pay_item_cd + '/' + FORMAT(sysdatetime(),'HHmmss.fffff')
						-- ***************************************  
						-- 5. 기준항목 저장  
						-- ***************************************  
						IF @n_cal_mon <> 0                                     -- 금액이 있으면 INSERT  
							BEGIN            
								INSERT INTO REP_PAYROLL_DETAIL                 -- 퇴직금기준임금항목관리  
											( REP_PAYROLL_DETAIL_ID              -- 퇴직금기준임금항목관리ID  
											, REP_PAY_STD_ID                     -- 퇴직금기준 임금 관리ID  
											, PAY_ITEM_CD                        -- 급여항목코드[PAY_ITEM_CD]  
											, CAL_MON                            -- 금액  
											, MOD_USER_ID                        -- 변경자  
											, MOD_DATE                           -- 변경일시  
											, TZ_CD                              -- 타임존코드  
											, TZ_DATE )                          -- 타임존일시  
										SELECT NEXT VALUE FOR dbo.S_REP_SEQUENCE  -- 퇴직금기준임금항목관리ID  
											, @an_rep_pay_std_id                 -- 퇴직금기준 임금 관리ID  
											, @v_pay_item_cd                     -- 급여항목코드[PAY_ITEM_CD]  
											, @n_cal_mon                         -- 금액  
											, @an_mod_user_id                    -- 변경자  
											, dbo.XF_SYSDATE(0)                  -- 변경일시  
											, 'KST'                              -- 타임존코드  
											, dbo.XF_SYSDATE(0)                  -- 타임존일시  
										FROM DUAL  
							SELECT @ERRCODE = @@ERROR  
							IF @ERRCODE != 0  
								BEGIN  
									SET @av_ret_code      = 'FAILURE!'  
									SET @av_ret_message   = dbo.F_FRM_ERRMSG('급여 기준임금항목 저장시 오류[ERR]', @v_program_id, 0020, null, @an_mod_user_id)  
									CLOSE item      -- 커서닫기  
									DEALLOCATE item -- 커서 할당해제  
									RETURN  
								END  
						END  
  
						SET @an_retrun_cal_mon = dbo.XF_NVL_N(@an_retrun_cal_mon,0) + dbo.XF_NVL_N(@n_cal_mon,0)  
  
						FETCH NEXT FROM item INTO @v_pay_item_cd  
					END -- 커서루프 종료  
			CLOSE item -- 커서닫기  
			DEALLOCATE item -- 커서 할당해제  
		END --  

    END -- 
    -- ***********************************************************  
    -- 작업 완료  
    -- ***********************************************************  
    SET @av_ret_code    = 'SUCCESS!'  
    SET @av_ret_message = dbo.F_FRM_ERRMSG('기준임금항목 저장이 완료되었습니다[ERR]', @v_program_id, 9999, null, @an_mod_user_id)  
END
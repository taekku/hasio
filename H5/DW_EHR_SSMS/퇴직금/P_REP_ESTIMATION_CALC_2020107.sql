USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_ESTIMATION_CALC]    Script Date: 2020-12-04 오후 3:00:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_REP_ESTIMATION_CALC]
    @av_company_cd     NVARCHAR(10),			-- 회사코드
    @av_locale_cd      NVARCHAR(10),			-- 국가코드
    @ad_std_ymd        DATE,					-- 기준일자
	@av_pay_group	   NVARCHAR(50),			-- 급여그룹
	@an_org_id         NUMERIC(38),				-- 소속ID
    @an_emp_id         NUMERIC(38),				-- 사원ID
    @an_mod_user_id    NUMERIC(38),				-- 변경자
    @av_ret_code                   VARCHAR(500)    OUTPUT, -- 결과코드*/    
    @av_ret_message                VARCHAR(4000)    OUTPUT  -- 결과메시지*/    
AS
    -- ***************************************************************************
    --   TITLE       : 퇴직충당금 생성
    --   PROJECT     : EHR
    --   AUTHOR      : 화이트정보통신
    --   PROGRAM_ID  : P_REP_ESTIMATION
    --   RETURN      : 1) SUCCESS!/FAILURE!
    --                 2) 결과 메시지
    --   COMMENT     : 퇴직추계액
    --   HISTORY     : 작성 2020.10.01
    -- ***************************************************************************
BEGIN
	SET NOCOUNT ON;
   DECLARE @v_program_id          NVARCHAR(30),		-- 프로그램ID
           @v_program_nm          NVARCHAR(100),	-- 프로그램명
		   @v_std_ym			  NVARCHAR(6),		-- 추계년월	
		   @d_pre_month_ymd		  DATE, -- 이전달말일
		   @d_pre_year_ymd		  DATE, -- 이전년 12월
           @d_mod_date            DATETIME2(0),		-- 수정일
		   @d_begin_date		  DATE,				-- 추계월 1일자
		   @v_bef_year12		  NVARCHAR(6),		-- 전년도 12월추계	
           @n_auto_yn_cnt		  INT,				-- 전표생성
		   @n_rep_calc_list_id    NUMERIC(38),		-- 퇴직정산ID
           @n_emp_id              NUMERIC(38),		-- 사원ID
           @n_org_id              NUMERIC(38),		-- 조직ID
		   @v_org_cd			  NVARCHAR(100),	-- 조직코드
		   @v_cost_cd			  NVARCHAR(50),		-- 코스트센터
		   @v_org_nm              NVARCHAR(100),	-- 조직명
		   @v_org_line            NVARCHAR(1000),	-- 조직라인
           @v_pos_grd_cd          NVARCHAR(50),		-- 직급 [PHM_POS_GRD_CD]
           @v_pos_cd              NVARCHAR(50),		-- 직위	[PHM_POS_CD]
           @v_duty_cd             NVARCHAR(50),		-- 직책 [PHM_DUTY_CD]
           @v_yearnum_cd          NVARCHAR(50),		-- 호봉
		   @v_mgr_type_cd		  NVARCHAR(50),		-- 관리구분 [PHM_MGR_TYPE_CD]
		   @v_job_position_cd	  NVARCHAR(50),		-- 직종 [PHM_JOB_POSTION_CD]
		   @v_job_cd			  NVARCHAR(50),		-- 직무
		   @v_emp_kind_cd		  NVARCHAR(50),		-- 근로구분코드 [PHM_EMP_KIND_CD]
		   @v_ins_type_cd		  NVARCHAR(50),		-- 퇴직연금구분
		   @n_amt_retr_amt		  NUMERIC(15,0),	-- 추계액
		   @n_old_retire_amt	  NUMERIC(15,0),	-- 이전퇴직추계액
		   @n_min_retire_amt	  NUMERIC(15,0),	-- 이전차액(퇴직추계액 - 이전퇴직추계액)
		   @n_new_retire_amt	  NUMERIC(15,0),	-- 당웡전입액
		   @n_bef_retire_amt	  NUMERIC(15,0),	-- 기초잔액
		   @n_mon_retire_amt	  NUMERIC(15,0),	-- 당월퇴직금
		   @n_add_retire_amt	  NUMERIC(15,0),	-- 추가퇴직금
		   @n_sum_retire_amt	  NUMERIC(15,0),    -- 합산퇴직금
		   @v_check				  NVARCHAR(1),		-- 생성여부
		   @v_pay_ym			  NVARCHAR(6)		-- 급여년월


   SET @v_program_id = '[P_REP_ESTIMATION_CALC]';
   SET @v_program_nm = '퇴직충당금 생성';

   SET @av_ret_code     = 'SUCCESS!'
   SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)
   SET @d_mod_date = dbo.xf_sysdate(0)
   SET @ad_std_ymd = dbo.XF_LAST_DAY(@ad_std_ymd)
   SET @v_pay_ym = dbo.XF_TO_CHAR_D(@ad_std_ymd,'YYYYMM')
   SET @d_pre_month_ymd = dbo.XF_LAST_DAY( DATEADD(MM, -1, @ad_std_ymd) )
   SET @d_pre_year_ymd = CONVERT(VARCHAR(4), (YEAR(@ad_std_ymd) - 1)) + '1231'
PRINT('마지막일 ===> ' + CONVERT(VARCHAR(20), @ad_std_ymd, 112))
PRINT('이전달 ===> ' + CONVERT(VARCHAR(20), @d_pre_month_ymd, 112))
PRINT('이전년도 ===> ' + CONVERT(VARCHAR(20), @d_pre_year_ymd, 112))
   SET @v_std_ym = dbo.XF_TO_CHAR_D(@ad_std_ymd, 'YYYYMM')		-- 충당금 년월
   SET @v_bef_year12 = dbo.XF_TO_CHAR_D(DATEADD(YYYY, -1, @ad_std_ymd), 'YYYY') + '12'
PRINT('시작 ===> ' + CONVERT(VARCHAR(100), sysdatetime(), 126))
   -- *************************************************************
   -- 전표마감 Check
   -- *************************************************************
   SET @n_auto_yn_cnt = 0
   BEGIN
      IF @av_company_cd <> 'I'
	     BEGIN
			SELECT @n_auto_yn_cnt = COUNT(*)
			  FROM REP_ESTIMATION A
			 WHERE A.COMPANY_CD = @av_company_cd
			   AND A.ESTIMATION_YMD = @ad_std_ymd
			   AND ISNULL(A.AUTO_YN, 'N') = 'Y'
			   AND (@an_emp_id IS NULL OR EMP_ID = @an_emp_id)
			   AND EXISTS (SELECT DISTINCT C.EMP_ID 
			                      FROM PAY_PAY_YMD B      
                                    INNER JOIN PAY_PAYROLL C      
                                       ON B.PAY_YMD_ID = C.PAY_YMD_ID
								 WHERE B.COMPANY_CD = @av_company_cd 
								   AND PAY_TYPE_CD IN (SELECT CD 
														 FROM FRM_CODE 
														WHERE CD_KIND = 'PAY_TYPE_CD'
														  AND COMPANY_CD = @av_company_cd 
														  AND SYS_CD = '001'
                                                      )
								   AND B.PAY_YM = @v_std_ym
								   AND B.CLOSE_YN = 'Y' 
								   AND C.EMP_ID = A.EMP_ID
								   AND (@av_pay_group is null or C.PAY_GROUP_CD = @av_pay_group)
                                  )
	     END
	  ELSE 
	     BEGIN
		    IF @av_pay_group = 'A'
			   BEGIN
				  SELECT @n_auto_yn_cnt = COUNT(*)
					FROM REP_ESTIMATION A
				   WHERE A.COMPANY_CD = @av_company_cd
					 AND A.ESTIMATION_YMD = @ad_std_ymd
					 AND ISNULL(A.AUTO_YN, 'N') = 'Y'
					 AND A.MGR_TYPE_CD IN ('A', '8')
			   END
            ELSE 
			   BEGIN
				  SELECT @n_auto_yn_cnt = COUNT(*)
					FROM REP_ESTIMATION A
				   WHERE A.COMPANY_CD = @av_company_cd
					 AND A.ESTIMATION_YMD = @ad_std_ymd
					 AND ISNULL(A.AUTO_YN, 'N') = 'Y'
					 AND (@av_pay_group is null or A.MGR_TYPE_CD = @av_pay_group)
			   END		 
		 END

	  IF @n_auto_yn_cnt > 0
		 BEGIN
			SET @av_ret_code = 'FAILURE!'
            SET @av_ret_message  = dbo.F_FRM_ERRMSG('이미 전표처리가 되었습니다. 전표 취소 후 작업하십시요!', @v_program_id,  0001,  null,  @an_mod_user_id)

            RETURN
		 END
   END

   -- *************************************************************
   -- 생성시 초기화
   -- *************************************************************
   BEGIN
      IF @av_company_cd <> 'I'
	     BEGIN
			DELETE FROM REP_ESTIMATION
			 WHERE COMPANY_CD = @av_company_cd
			   AND ESTIMATION_YMD = @ad_std_ymd
			   AND ISNULL(AUTO_YN, 'N') = 'N'
			   AND (@an_emp_id IS NULL OR EMP_ID = @an_emp_id)
			   AND EMP_ID IN (SELECT DISTINCT C.EMP_ID 
			                    FROM PAY_PAY_YMD B      
                                  INNER JOIN PAY_PAYROLL C      
                                     ON B.PAY_YMD_ID = C.PAY_YMD_ID
							   WHERE B.COMPANY_CD = @av_company_cd 
								 AND PAY_TYPE_CD IN (SELECT CD 
										 			   FROM FRM_CODE 
													  WHERE CD_KIND = 'PAY_TYPE_CD'
														AND COMPANY_CD = @av_company_cd 
														AND SYS_CD = '001'
                                                      )
								 AND B.PAY_YM = @v_std_ym
								 AND B.CLOSE_YN = 'Y' 
								   AND (@av_pay_group is null or C.PAY_GROUP_CD = @av_pay_group)
                              )
	     END
	  ELSE 
	     BEGIN
		    IF @av_pay_group = 'A'
			   BEGIN
				  DELETE FROM REP_ESTIMATION
				   WHERE COMPANY_CD = @av_company_cd
					 AND ESTIMATION_YMD = @ad_std_ymd
					 AND MGR_TYPE_CD IN ('A', '8')
					 AND (@an_emp_id IS NULL OR EMP_ID=@an_emp_id)
			   END
            ELSE 
			   BEGIN
				  DELETE FROM REP_ESTIMATION
				   WHERE COMPANY_CD = @av_company_cd
					 AND ESTIMATION_YMD = @ad_std_ymd
					 AND (@av_pay_group is null or MGR_TYPE_CD = @av_pay_group)
					 AND (@an_emp_id IS NULL OR EMP_ID=@an_emp_id)
			   END		 
		 END

	 IF @@ERROR <> 0
		BEGIN
			SET @av_ret_code    = 'FAILURE!'
			SET @av_ret_message = dbo.F_FRM_ERRMSG('기존 내역 삭제시 에러발생', @v_program_id , 0030 , null,  @an_mod_user_id)
			
			RETURN
		END

   END
PRINT('대상자 START 시작 ===> ' + CONVERT(VARCHAR(100), sysdatetime(), 126))
   -- *************************************************************
   -- 퇴직충당금 생성
   -- *************************************************************
   BEGIN
        DECLARE REP_CUR CURSOR LOCAL FORWARD_ONLY FOR
            SELECT B.EMP_ID							-- 사원ID
                  ,B.ORG_ID							-- 조직ID
				  ,B.POS_GRD_CD						-- 직급 [PHM_POS_GRD_CD]
                  ,B.POS_CD							-- 직위 [PHM_POS_CD]
                  ,B.DUTY_CD						-- 직책 [PHM_DUTY_CD]
                  ,B.YEARNUM_CD						-- 호봉
				  ,B.MGR_TYPE_CD					-- 관리구분코드[PHM_MGR_TYPE_CD]
				  ,B.JOB_POSITION_CD				-- 직종코드[PHM_JOB_POSTION_CD]
				  ,B.JOB_CD							-- 직무코드
				  ,B.EMP_KIND_CD					-- 근로구분코드 [PHM_EMP_KIND_CD]
				  ,A.INS_TYPE_CD                    -- 퇴직연금구분
				  ,dbo.F_PAY_GET_COST(@av_company_cd, @n_emp_id, @n_org_ID, @ad_std_ymd, '1') AS COST_CD
				  ,dbo.F_FRM_ORM_ORG_NM( B.ORG_ID, B.LOCALE_CD, dbo.XF_SYSDATE(0), '10' ) AS ORG_CD
				  ,A.C_01							-- 주(현)법정퇴직급여
				  ,c.mon_retire_amt -- 지급액
				  ,d.bef_retire_amt -- 기초잔액
             FROM REP_CALC_LIST A
			  INNER JOIN VI_PAY_PHM_EMP B 
			     ON A.COMPANY_CD = B.COMPANY_CD
                AND A.EMP_ID = B.EMP_ID
			  left outer join (
							SELECT EMP_ID,
							       ISNULL(SUM(C_01), 0) mon_retire_amt -- 지급액
							  FROM REP_CALC_LIST
							 WHERE COMPANY_CD = @av_company_cd
							   AND CALC_TYPE_CD IN ('01','02')
							   AND PAY_YMD > dbo.XF_LAST_DAY( DATEADD(MM, -1, @ad_std_ymd) )
							   AND PAY_YMD <= @ad_std_ymd
							 GROUP BY EMP_ID
							) C
			               on A.EMP_ID = C.EMP_ID
			  left outer join (
							SELECT EMP_ID,
							       ISNULL(SUM(C_01), 0) bef_retire_amt -- 기초잔액
							  FROM REP_CALC_LIST
							 WHERE COMPANY_CD = @av_company_cd
							   AND CALC_TYPE_CD IN ('03')
							   AND PAY_YMD = @d_pre_year_ymd -- 전년도 말일
							 GROUP BY EMP_ID
							) D
			               on A.EMP_ID = D.EMP_ID
            WHERE A.COMPANY_CD = @av_company_cd
			  AND A.CALC_TYPE_CD = '03'
			  AND A.PAY_YMD = @ad_std_ymd
			  AND (@an_emp_id IS NULL OR A.EMP_ID=@an_emp_id)
              

            OPEN REP_CUR

            FETCH REP_CUR INTO @n_emp_id , @n_org_id, @v_pos_grd_cd , @v_pos_cd, @v_duty_cd , @v_yearnum_cd , @v_mgr_type_cd , 
							   @v_job_position_cd, @v_job_cd , @v_emp_kind_cd , @v_ins_type_cd, @v_cost_cd, @v_org_cd,
							   @n_amt_retr_amt, @n_mon_retire_amt, @n_bef_retire_amt

            WHILE (@@FETCH_STATUS = 0)
			
			-- ***************************************   
			-- 1. 기본자료    
			-- *************************************** 

            BEGIN
						Print 'fetch Time S : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)
--PRINT('@n_emp_id ===> ' + CONVERT(VARCHAR, @n_emp_id))
				-- 퇴직연금구분
				--SET @v_ins_type_cd = NULL
				--BEGIN 
				--   SELECT @v_ins_type_cd = CALC_TYPE_CD
				--	 FROM dbo.REP_INSUR_MON
    --                WHERE EMP_ID = @n_emp_id
				--	  AND @ad_std_ymd BETWEEN STA_YMD AND END_YMD

    --               IF @@ERROR != 0
				--	  BEGIN
				--		 SET @v_ins_type_cd = NULL
				--	  END
				--END

				-- 코스트센터코드
				--SET @v_cost_cd = DBO.F_PAY_GET_COST(@av_company_cd, @n_emp_id, @n_org_ID, @ad_std_ymd, '1') --AS COST_CD
				--BEGIN
				--   SELECT @v_cost_cd = COST_CD
				--     FROM ORM_EMP_COST
    --                WHERE COMPANY_CD = @av_company_cd
				--	  AND EMP_ID = @n_emp_id
				--	  AND @ad_std_ymd BETWEEN STA_YMD AND END_YMD 
    --               IF @@ERROR != 0
				--	  BEGIN
				--		 SELECT @v_cost_cd = COST_ORG_CD
				--		   FROM ORM_ORG_HIS
    --                      WHERE ORG_ID = @n_ORG_ID
				--		    AND @ad_std_ymd BETWEEN STA_YMD AND END_YMD 
				--	  END

				--END

				-- 조직코드
				--BEGIN
				--   SELECT @v_org_cd = ORG_CD
				--	 FROM ORM_ORG
    --                WHERE ORG_ID = @n_org_ID
				--	  AND @ad_std_ymd BETWEEN STA_YMD AND END_YMD 
				--END

				-- 이전퇴직추계액
				SET @n_old_retire_amt = 0
						Print '이전퇴직추계액 Time S : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)
				BEGIN
				   SELECT @n_old_retire_amt = ISNULL(RETIRE_AMT, 0)
				     FROM REP_ESTIMATION
                    WHERE COMPANY_CD = @av_company_cd
					  AND EMP_ID = @n_emp_id
					  AND ESTIMATION_YMD = (SELECT MAX(ESTIMATION_YMD)
					                          FROM REP_ESTIMATION
                                             WHERE COMPANY_CD = @av_company_cd
					                           AND EMP_ID = @n_emp_id
											   AND ESTIMATION_YMD < @ad_std_ymd)

                   IF @@ERROR != 0
					  BEGIN
						 SET @n_old_retire_amt = 0 
					  END
				END
						Print '이전퇴직추계액 Time E : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)

				-- DC형의 경우 1월인 경우 0
				BEGIN
				   IF @v_ins_type_cd = '20' AND dbo.XF_SUBSTR(@v_std_ym,5,2) = '01' 
				      BEGIN
					     SET @n_old_retire_amt = 0
					  END
				END

				-- 기초잔액
				--SET @n_bef_retire_amt = 0
				--BEGIN
				--   SELECT @n_bef_retire_amt = ISNULL(SUM(C_01), 0)
				--     FROM REP_CALC_LIST
    --                WHERE COMPANY_CD = @av_company_cd
				--	  AND EMP_ID = @n_emp_id
				--	  AND CALC_TYPE_CD = '03'
				--	  AND PAY_YMD = @d_pre_year_ymd

    --               IF @@ERROR != 0
				--	  BEGIN
				--		 SET @n_bef_retire_amt = 0 
				--	  END
				--END

				-- 지급액
				--SET @n_mon_retire_amt = 0
				--BEGIN
				--   SELECT @n_mon_retire_amt = ISNULL(SUM(C_01), 0)
				--     FROM REP_CALC_LIST
    --                WHERE COMPANY_CD = @av_company_cd
				--	  AND EMP_ID = @n_emp_id
				--	  AND CALC_TYPE_CD IN ('01','02')
				--	  AND dbo.XF_TO_CHAR_D(PAY_YMD, 'YYYYMM') = @v_std_ym

    --               IF @@ERROR != 0
				--	  BEGIN
				--		 SET @n_mon_retire_amt = 0 
				--	  END
				--END

				-- 이전차액(퇴직추계액 - 이전퇴직추계액)
				SET @n_min_retire_amt = @n_amt_retr_amt - @n_old_retire_amt

				-- 당월전입액 : 지급액 + (당월-전월)
				SET @n_new_retire_amt = @n_mon_retire_amt + @n_min_retire_amt

				-- 추가퇴직금
				SET @n_add_retire_amt = 0

				-- 기말잔액 = 기초잔액 + 지급액
   				SET @n_sum_retire_amt = @n_bef_retire_amt + @n_mon_retire_amt

				-- 입력 대상자
				SET @v_check = 'N'
				BEGIN
				   IF @av_company_cd = 'I'
					  BEGIN
						 IF @av_pay_group = 'A'
							BEGIN
							   SET @v_check = CASE WHEN @v_mgr_type_cd IN ('A', '8') AND dbo.XF_SUBSTR(@v_org_cd,1,1) <> '5' THEN 'Y' ELSE 'N' END
							END
						 ELSE IF @av_pay_group = 'B'
							BEGIN
							   SET @v_check = CASE WHEN @v_mgr_type_cd = 'B' OR (dbo.XF_SUBSTR(@v_org_cd,1,1) = '5' AND @v_mgr_type_cd = 'A') THEN 'Y' ELSE 'N' END
							END
						 ELSE
							BEGIN
							   SET @v_check = 'Y'
							END
					  END
				   ELSE 
					  BEGIN
						Print '입력 대상자 Time S : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)
						 SELECT @v_check = CASE WHEN count(*) > 0 THEN 'Y' ELSE 'N' END
						   FROM PAY_PAY_YMD A      
							 INNER JOIN PAY_PAYROLL B      
								ON B.PAY_YMD_ID = A.PAY_YMD_ID      
						  WHERE A.COMPANY_CD = @av_company_cd
							AND B.EMP_ID = @n_emp_id    
							AND A.CLOSE_YN = 'Y'     
							AND A.PAY_YM = @v_pay_ym -- dbo.XF_TO_CHAR_D(@ad_std_ymd,'YYYYMM') 
						IF @@ERROR != 0
						   BEGIN
							  SET @n_bef_retire_amt = 0 
						   END
						Print '입력 대상자 Time E : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)

					  END
				END

				BEGIN -- 1
				   IF @v_check = 'Y'
					  BEGIN -- 2
						SET @n_rep_calc_list_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE

						BEGIN TRY
						Print 'Insert Time S : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)
								INSERT INTO dbo.REP_ESTIMATION (	-- 퇴직충당금
											REP_ESTIMATIN_ID		-- 퇴직충당금ID
										   ,COMPANY_CD				-- 인사영역
										   ,ESTIMATION_YMD			-- 퇴직충당금 기준일
										   ,EMP_ID					-- 사원ID
										   ,ORG_ID					-- 조직ID
										   ,MGR_TYPE_CD				-- 관리구분코드[PHM_MGR_TYPE_CD]
										   ,INS_TYPE_CD				-- 퇴직연금종류[RMP_INS_TYPE_CD]
										   ,ACC_CD					-- 코스트센터
										   ,RETIRE_AMT				-- 퇴직추계액
										   ,OLD_RETIRE_AMT			-- 이전퇴직추계액
										   ,MIN_RETIRE_AMT			-- 이전차액(퇴직추계액 - 이전퇴직추계액)
										   ,NEW_RETIRE_AMT			-- 당웡전입액
										   ,BEF_RETIRE_AMT			-- 기초잔액
										   ,MON_RETIRE_AMT			-- 당월퇴직금
										   ,ADD_RETIRE_AMT			-- 추가퇴직금
										   ,SUM_RETIRE_AMT			-- 합산퇴직금
										   ,AUTO_YN					-- 자동분개 여부
										   ,AUTO_YMD				-- 이관일자
										   ,AUTO_NO					-- 자동분개 일련번호
										   ,NOTE					-- 비고
										   ,MOD_USER_ID				-- 변경자
										   ,MOD_DATE				-- 변경일시
										   ,TZ_CD					-- 타임존코드
										   ,TZ_DATE					-- 타임존일시
										)
									VALUES (  
											@n_rep_calc_list_id     -- 퇴직충당금ID
										   ,@av_company_cd			-- 회사코드
						  				   ,@ad_std_ymd			    -- 퇴직충당금 기준일
										   ,@n_emp_id               -- 사원ID
										   ,@n_org_id				-- 조직ID 
										   ,@v_mgr_type_cd			-- 관리구분코드[PHM_MGR_TYPE_CD]
										   ,@v_ins_type_cd			-- 퇴직연금종류[RMP_INS_TYPE_CD]
										   ,@v_cost_cd				-- 코스트센터
										   ,@n_amt_retr_amt			-- 퇴직추계액
										   ,@n_old_retire_amt		-- 이전퇴직추계액
										   ,@n_min_retire_amt		-- 이전차액(퇴직추계액 - 이전퇴직추계액)
										   ,@n_new_retire_amt		-- 당월전입액
										   ,@n_bef_retire_amt		-- 기초잔액
										   ,@n_mon_retire_amt		-- 당월퇴직금
										   ,@n_add_retire_amt		-- 추가퇴직금
										   ,@n_sum_retire_amt		-- 합산퇴직금
										   ,'N'						-- 자동분개 여부
										   ,NULL					-- 이관일자
										   ,NULL				    -- 자동분개 일련번호
										   ,NULL					-- 비고
										   ,@an_mod_user_id			-- 변경자 	numeric(18, 0)
										   ,dbo.xf_sysdate(0)		-- 변경일시
										   ,'KST'					-- 타임존코드 	nvarchar(10)
										   ,dbo.xf_sysdate(0)		-- 타임존일시 	datetime2(7)
											)
							IF @@ROWCOUNT < 1
								BEGIN
									PRINT 'INSERT FAILURE!' + 'CONTINUE'
								END
						Print 'Insert Time E : ' + CONVERT(VARCHAR(100), sysdatetime(), 126)
						END TRY

						BEGIN CATCH
							BEGIN
								--print 'Error:' + Error_message()
								SET @av_ret_code = 'FAILURE!'
								SET @av_ret_message  = dbo.F_FRM_ERRMSG('퇴직금충담금 생성 에러' , @v_program_id,  0010,  ERROR_MESSAGE(),  @an_mod_user_id)
					
								--print 'Error:' + Error_message()
								IF @@TRANCOUNT > 0
									ROLLBACK WORK
								--print 'Error Rollback:' + Error_message()

								CLOSE REP_CUR
								DEALLOCATE REP_CUR
								RETURN
							END

						END CATCH
					  END -- 2
				END  --1

            FETCH REP_CUR INTO @n_emp_id , @n_org_id, @v_pos_grd_cd , @v_pos_cd, @v_duty_cd , @v_yearnum_cd , @v_mgr_type_cd , 
							   @v_job_position_cd, @v_job_cd , @v_emp_kind_cd , @v_ins_type_cd, @v_cost_cd, @v_org_cd,
							   @n_amt_retr_amt, @n_mon_retire_amt, @n_bef_retire_amt
        END
        CLOSE REP_CUR
        DEALLOCATE REP_CUR 
   END
PRINT('종료 ===> ' + CONVERT(VARCHAR(100), sysdatetime(), 126))
   /*
   *    ***********************************************************
   *    작업 완료
   *    ***********************************************************
   */
   SET @av_ret_code = 'SUCCESS!'
   SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 완료..[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)

END
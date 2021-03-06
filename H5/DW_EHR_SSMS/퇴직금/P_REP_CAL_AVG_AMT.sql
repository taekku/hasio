SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_CAL_AVG_AMT] (   
       @av_company_cd                 NVARCHAR(10),             -- 인사영역   
       @av_locale_cd                  NVARCHAR(10),             -- 지역코드   
       @an_rep_calc_list_id_list      NUMERIC(38),				-- 퇴직금대상ID   
       @an_mod_user_id                NUMERIC(38),				-- 변경자 사번   
       @av_ret_code                   NVARCHAR(4000)    OUTPUT, -- 결과코드   
       @av_ret_message                NVARCHAR(4000)    OUTPUT  -- 결과메시지   
    ) AS   
   
    -- ***************************************************************************   
    --   TITLE       : 퇴직금계산  - 평균임금산정.   
    --   PROJECT     : E-HR 시스템   
    --   AUTHOR      :   
    --   PROGRAM_ID  : P_REP_CAL_AVG_AMT   
    --   RETURN      : 1) SUCCESS!/FAILURE!   
    --                 2) 결과 메시지   
    --   COMMENT     : 퇴직금계산    
    --   HISTORY     : 작성 정순보  2006.09.26   
    --               : 수정 박근한  2009.01.16   
    --               : 2016.06.24 Modified by 최성용 in KBpharma   
    -- ***************************************************************************   
   
BEGIN   
    /* 기본적으로 사용되는 변수 */   
    DECLARE @v_program_id              NVARCHAR(30)   
          , @v_program_nm              NVARCHAR(100)   
          , @ERRCODE                   NVARCHAR(10)   
   
    DECLARE @n_rep_calc_list_id_list   NUMERIC(38)   
          , @n_rep_calc_id             NUMERIC(38) 
		  , @n_pay_tot				   NUMERIC(19,4)                   -- 급여합계
		  , @n_pay_mon3				   NUMERIC(19,4)                   -- 3개월급여
          , @n_avg_pay                 NUMERIC(19,4)                   -- 평균급여 
		  , @n_bonus_tot			   NUMERIC(19,4)				   -- 상여합계	
		  , @n_bonus_mon3			   NUMERIC(19,4)				   -- 3개월상여
          , @n_avg_bonus               NUMERIC(19,4)                   -- 평균정기상여  
		  , @n_yearmonth_tot		   NUMERIC(19,4)                   -- 연월차총액
		  , @n_yearmonth_tot3		   NUMERIC(19,4)				   -- 3개월연월차
          , @n_avg_day                 NUMERIC(19,4)                   -- 3개월평균연월차   
          , @n_avg_pay_amt             NUMERIC(19,4)                   -- 평균임금 
		  , @n_pay_sum_amt			   NUMERIC(19,4)				   -- 3개월총임금
		  , @n_comm_amt				   NUMERIC(19,4)				   -- 3개월 평균임금
		  , @n_avg_pay_amt_m		   NUMERIC(19,4)				   -- 월 평균임금(년평균임금/12)
		  , @n_avg_pay_amt_d		   NUMERIC(19,4)				   -- 일 평균임금
		  , @n_amt_retr_pay_y		   NUMERIC(19,4)				   -- 년 퇴직금
		  , @n_amt_retr_pay_m		   NUMERIC(19,4)				   -- 월 퇴직금
		  , @n_amt_retr_pay_d		   NUMERIC(19,4)				   -- 일 퇴직금
		  , @n_amt_retr_amt			   NUMERIC(19,4)				   -- 퇴직금
		  , @d_sta_ymd                 DATE                            -- 법정주(현)기산일   
          , @d_end_ymd                 DATE                            -- 주(현)정산일   
            
          , @n_work_yy                 NUMERIC(2)                      -- 실근속년수   
          , @n_work_mm                 NUMERIC(3)                      -- 실근속월수   
          , @n_work_dd                 NUMERIC(5)                      -- 실근속일수   
          , @n_work_day                NUMERIC(5)                      -- 실근속총일수   
          , @n_work_yy_pt              NUMERIC(10,1)                   -- 실근속년수(소수점) 
		  , @n_calc_yy				   NUMERIC(5)					   -- 산정년수
		  , @n_calc_mm				   NUMERIC(5)					   -- 산정월수
		  , @n_calc_dd				   NUMERIC(5)					   -- 산정일수
		  ,	@v_chk_sta_dd			   NVARCHAR(2)					   -- 홈푸드 근속산정 적용 기산일 일자
		  , @v_chk_end_dd			   NVARCHAR(2)					   -- 홈푸드 근속산정 적용 정산일 일자
		  , @v_chk_sta_ymd			   NVARCHAR(8)					   -- 홈푸드 근속산정 적용 시작일
		  , @v_chk_end_ymd			   NVARCHAR(8)					   -- 홈푸드 근속산정 적용 종료일
		  , @n_diff_day				   NUMERIC(5)					   -- 홈푸드 근속산정 적용 일수
		  , @n_gv_yy				   NUMERIC(5)					   
		  , @n_gv_mm				   NUMERIC(5)
          , @n_cal_work				   INT							   -- 선원산정근속일수
		  , @n_add_work_yy             NUMERIC(2)                      -- 추가근속년수   
          , @d_pay_ymd                 DATE                            -- 지급일자   
          , @n_emp_id                  NUMERIC(38)                     -- 사원ID 
		  , @n_org_id				   NUMERIC(38)					   -- 조직ID
		  , @v_org_nm				   NVARCHAR(100)				   -- 조직명
		  , @v_org_line                NVARCHAR(1000)				   -- 조직라인
		  , @v_pos_cd				   NVARCHAR(50)					   -- 직위
		  , @v_mgr_type_cd			   NVARCHAR(50)					   -- 관리구분
		  , @v_pos_grd_cd			   NVARCHAR(50)					   -- 직급
		  , @v_yearnum_cd			   NVARCHAR(50)					   -- 호봉
		  , @v_pay_group			   NVARCHAR(50)					   -- 급여그룹
          , @n_std_cnt                 NUMERIC                         -- 기준금관리 조회수 
		  ,	@v_biz_cd				   NVARCHAR(50)					   -- 사업장
		  , @v_reg_biz_cd			   NVARCHAR(50)					   -- 신고사업장 
		  , @v_ship_cd				   NVARCHAR(50)					   -- 선박업종[PAY_SHIP_KIND_CD]
		  , @v_ship_cd_d			   NVARCHAR(50)					   -- 선박세부업종[PAY_SHIP_KIND_D_CD]
		  , @n_rate_a				   NUMERIC(6,2)					   -- 평균임금율
		  , @n_ship_base_amt		   NUMERIC(19,4)				   -- 선원급호기본급
          , @n_retire_turn_mon		   NUMERIC(15)					   -- 국민연금퇴직전환금
		  , @v_pay_meth_cd			   NVARCHAR(50)					   -- 급여지급방식코드[PAY_METH_CD]
		  ,	@v_emp_cls_cd			   NVARCHAR(50)					   -- 고용유형코드[PAY_EMP_CLS_CD]
		  ,	@v_ins_type_yn			   NVARCHAR(1)					   -- 퇴직연금가입여부
		  ,	@v_ins_type_cd			   NVARCHAR(10)					   -- 퇴직연금구분
		  ,	@v_ins_nm				   NVARCHAR(80)					   -- 퇴직연금사업자명
		  ,	@v_ins_bizno			   NVARCHAR(50)					   -- 퇴직연금사업장등록번호
		  ,	@v_ins_account_no		   NVARCHAR(20)					   -- 퇴직연금계좌번호
		  , @v_officers_yn			   NVARCHAR(50)					   -- 임원여부
		  , @v_rep_mid_yn			   NVARCHAR(1)					   -- 중간정산여부
          , @d_exce_sta_ymd            DATE                            -- 제외시작일   
          , @d_exce_end_ymd            DATE                            -- 제외종료일   
          , @v_cam_type_cd             NVARCHAR(50)				       -- 제외발령타입 
		  , @n_sum_month_day3		   NUMERIC(3)                      -- 3개월 적용일수
          , @n_month_day3              NUMERIC(3)                      -- 3개월 평균일수
		  , @n_add_rate				   NUMERIC(5,2)					   -- 누진율
		  , @n_c1_work_yy			   NUMERIC(3,0)					   -- 최종 근속년수 
		  , @n_bc1_work_yy			   NUMERIC(3,0)					   -- 근속년수(법정)(현+종전 근속년수) 
		  , @n_sum_work_yy			   NUMERIC(3,0)					   -- 정산 근속년수 
		  , @n_c1_work_mm			   NUMERIC(5,0)					   -- 주(현)근속월수 
		  , @n_sum_work_mm			   NUMERIC(5,0)					   -- 정산 근속월 
   
      /* 기본변수 초기값 셋팅*/   
    SET @v_program_id    = 'P_REP_CAL_AVG_AMT'   -- 현재 프로시져의 영문명   
    SET @v_program_nm    = '퇴직금계산  - 평균임금산정'        -- 현재 프로시져의 한글문명   
    SET @av_ret_code     = 'SUCCESS!'   
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)   
PRINT('시작 ===> ')   
    BEGIN   
        -- ***************************************   
        -- 1. 퇴직금 대상자(내역) 조회   
        -- ***************************************   
        SET @n_rep_calc_id = @an_rep_calc_list_id_list  
		SET @n_sum_month_day3 = 0
		SET @n_month_day3 = 90		-- 전사공통
        BEGIN   
            SELECT @n_emp_id   = EMP_ID				-- 사원ID
			     , @n_org_id   = ORG_ID				-- 조직ID
                 , @d_sta_ymd  = C1_STA_YMD			-- 기산일(입사일)
                 , @d_end_ymd  = C1_END_YMD			-- 퇴직일(정산일)
				 , @v_mgr_type_cd = MGR_TYPE_CD		-- 관리구분
				 , @v_pos_cd   = POS_CD 			-- 직위
				 , @v_pos_grd_cd = POS_GRD_CD		-- 직급
				 , @v_yearnum_cd = YEARNUM_CD		-- 호봉
				 , @v_officers_yn = ISNULL(OFFICERS_YN, 'N')		-- 임원여부
				 , @n_add_rate = AMT_RATE_ADD       -- 지급율배수
                 , @n_rep_calc_list_id_list = REP_CALC_LIST_ID 
				 , @n_add_rate = AMT_RATE_ADD
				 , @n_sum_month_day3 = (CASE @av_company_cd
				                             WHEN 'A' THEN @n_month_day3
											 WHEN 'B' THEN @n_month_day3
											 WHEN 'C' THEN @n_month_day3
											 WHEN 'D' THEN @n_month_day3
											 WHEN 'E' THEN @n_month_day3
											 WHEN 'I' THEN @n_month_day3
											 WHEN 'M' THEN @n_month_day3
											 WHEN 'O' THEN @n_month_day3
											 WHEN 'T' THEN @n_month_day3
											 ELSE dbo.XF_DATEDIFF(C1_END_YMD, dbo.XF_DATEADD(dbo.XF_MONTHADD(C1_END_YMD, -3),1)) + 1
                                         END)                 
              FROM REP_CALC_LIST   
             WHERE REP_CALC_LIST_ID = @n_rep_calc_id   
        END 
PRINT('@v_officers_yn ====> ' + @v_officers_yn)
PRINT('@n_add_rate ====> ' + CONVERT(VARCHAR, @n_add_rate))
		-- 임원이면 누진율 반영
		BEGIN
			IF ISNULL(@n_add_rate, 0) = 0
			   BEGIN
				  IF @v_officers_yn = 'Y'
					 BEGIN
						SELECT @n_add_rate = dbo.XF_TO_NUMBER(CD1)
							FROM FRM_UNIT_STD_HIS  
						WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
														FROM FRM_UNIT_STD_MGR  
														WHERE COMPANY_CD = @av_company_cd  
														AND UNIT_CD = 'REP'  
														AND STD_KIND = 'REP_EXE_MUL')  
							AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
							AND KEY_CD1 = @v_pos_cd 
					 END
               END   
        END
PRINT('SEARCH @n_add_rate ====> ' + CONVERT(VARCHAR, @n_add_rate))
-----------------------------------------------------------------------------------------------------------------------------------------------------
        -- 조직명, 조직라인
		SET @v_org_nm = dbo.F_FRM_ORM_ORG_NM(@n_org_id, 'KO', @d_end_ymd, '1')				 -- 조직명
		SET @v_org_line = dbo.F_FRM_ORM_ORG_NM(@n_org_id, 'KO', @d_end_ymd, 'LL')			 -- 조직라인
		-- 급여마스터(PAY_PHM_EMP)에서 퇴직기산일, 급여지급방식, 고용유형정보를 가져온다.
		SET @v_pay_meth_cd = NULL
		SET @v_emp_cls_cd  = NULL
		BEGIN      
		   SELECT @v_pay_meth_cd = PAY_METH_CD		-- 급여지급방식코드[PAY_METH_CD] 
				, @v_emp_cls_cd  = EMP_CLS_CD		-- 고용유형코드[PAY_EMP_CLS_CD]   								     
			 FROM PAY_PHM_EMP      
			WHERE EMP_ID = @n_emp_id      
			IF @@ERROR != 0                       
				BEGIN      
					SET @v_pay_meth_cd = NULL
					SET @v_emp_cls_cd = NULL
				END      
		END

		-- 사업장 
		SET @v_biz_cd = dbo.F_ORM_ORG_BIZ(@n_org_id, @d_end_ymd, 'PAY')
		SET @v_biz_cd = ISNULL( @v_biz_cd, '001' )
		--BEGIN
		--   SELECT @v_biz_cd = BIZ_CD 
		--	 FROM ORM_BIZ_INFO 
		--    WHERE ORM_BIZ_INFO_ID = (SELECT ORM_BIZ_INFO_ID 
		--							   FROM ORM_BIZ_TYPE 
		--							  WHERE ORM_BIZ_TYPE_ID = (SELECT ORM_BIZ_TYPE_ID 
		--					    								 FROM ORM_BIZ_ORG_MAP 
		--														WHERE ORG_ID = @n_org_id
		--														  AND @d_end_ymd BETWEEN STA_YMD AND END_YMD)

		--							    AND @d_end_ymd BETWEEN STA_YMD AND END_YMD
		--							    AND BIZ_TYPE_CD = 'PAY') -- PAY, -- REG
  --         IF @@ERROR != 0                       
		--	  BEGIN      
		--		 SET @v_biz_cd = '001'     
		--	  END 
		--END

		-- 신고사업장 
		SET @v_reg_biz_cd = dbo.F_ORM_ORG_BIZ(@n_org_id, @d_end_ymd, 'REG')
		SET @v_reg_biz_cd = ISNULL(@v_reg_biz_cd, '001')
		--BEGIN
		--   SELECT @v_biz_cd = BIZ_CD 
		--	 FROM ORM_BIZ_INFO 
		--    WHERE ORM_BIZ_INFO_ID = (SELECT ORM_BIZ_INFO_ID 
		--							   FROM ORM_BIZ_TYPE 
		--							  WHERE ORM_BIZ_TYPE_ID = (SELECT ORM_BIZ_TYPE_ID 
		--					    								 FROM ORM_BIZ_ORG_MAP 
		--														WHERE ORG_ID = @n_org_id
		--														  AND @d_end_ymd BETWEEN STA_YMD AND END_YMD)

		--							    AND @d_end_ymd BETWEEN STA_YMD AND END_YMD
		--							    AND BIZ_TYPE_CD = 'REG') -- PAY, -- REG

  --         IF @@ERROR != 0                       
		--	  BEGIN      
		--		 SET @v_biz_cd = '001'     
		--	  END 
		--END

		-- 퇴직연금가입여부, 퇴직연금구분
		SET @v_ins_type_yn = 'N'
		SET @v_ins_type_cd = NULL
		SET @v_ins_nm = NULL
		SET @v_ins_bizno = NULL
		SET @v_ins_account_no = NULL

		BEGIN 
			SELECT @v_ins_type_yn = 'Y'
				  ,@v_ins_type_cd = CALC_TYPE_CD
				  ,@v_ins_nm = INSUR_NM
				  ,@v_ins_bizno = INSUR_BIZ_NO
				  ,@v_ins_account_no = IRP_ACCOUNT_NO
			 FROM dbo.REP_INSUR_MON
			WHERE EMP_ID = @n_emp_id
			  AND @d_end_ymd BETWEEN STA_YMD AND END_YMD
			IF @@ERROR != 0
				BEGIN
					SET @v_ins_type_yn = 'N'
					SET @v_ins_type_cd = NULL
				END
		END

		-- 중간정산여부
		SET @v_rep_mid_yn = 'N'
		BEGIN
			SELECT @v_rep_mid_yn = 'Y'
			  FROM REP_CALC_LIST
			 WHERE CALC_TYPE_CD = '02' --중간정산  ****회사마다 수정해야함    
			   AND END_YN = '1' --완료여부    
			   AND EMP_ID = @n_emp_id    
			   AND REP_CALC_LIST_ID <> @n_rep_calc_id 
			   AND C1_END_YMD < @d_end_ymd  

			IF @@ERROR != 0
				BEGIN
					SET @v_rep_mid_yn = 'N'
				END

		END

-----------------------------------------------------------------------------------------------------------------------------------------------------


        -- ***************************************   
        -- 2. 기초자료 확인 후 생성   
        -- ***************************************   
        BEGIN   
            SELECT @n_std_cnt = COUNT(*)   
              FROM REP_PAY_STD   
             WHERE REP_CALC_LIST_ID = @n_rep_calc_list_id_list   
            -- ***************************************   
            -- 2-1. 기초자료 생성   
            -- ***************************************   
            IF @n_std_cnt = 0       -- 기초자료가 존재하지 않으면   
                BEGIN   
                    EXEC dbo.P_REP_CAL_PAY_STD @av_company_cd, @av_locale_cd, @n_rep_calc_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT   
                    IF @av_ret_code = 'FAILURE!'   
                        BEGIN   
                            SET @av_ret_code     = 'FAILURE!'   
                            SET @av_ret_message  = @av_ret_message   
                            RETURN   
                        END   
                END   
        END   
        -- ***************************************   
        -- 3. 평균급여 조회   
        -- *************************************** 		
		SET @n_pay_tot = 0		-- 급여합계
		SET @n_pay_mon3 = 0		-- 3개월급여
		SET @n_avg_pay = 0		-- 3개월 평균급여
        BEGIN   
            SELECT @n_pay_tot = dbo.XF_TRUNC_N(dbo.XF_NVL_N(SUM(CAL_MON),0),0)   
              FROM REP_PAYROLL_DETAIL A   
                   INNER JOIN REP_PAY_STD B   
                                       ON A.REP_PAY_STD_ID = B.REP_PAY_STD_ID   
             WHERE B.REP_CALC_LIST_ID = @n_rep_calc_id   
               AND B.PAY_TYPE_CD = '10'   
            IF @@ERROR != 0     
                BEGIN   
                    SET @av_ret_code     = 'FAILURE!'   
                    SET @av_ret_message  = dbo.F_FRM_ERRMSG('평균급여 조회 에러발생[ERR]', @v_program_id,  0010,  null,  @an_mod_user_id)   
                    RETURN   
                END
					
			BEGIN
			   IF @v_emp_cls_cd = 'S'  -- 선원 ==> 급여 체크시 반영
			      BEGIN
				     SET @n_pay_mon3 = @n_pay_mon3
				  END
               ELSE IF @v_officers_yn = 'Y' -- 임원이면 누진율(임원배수 적용)
			      BEGIN
				     SET @n_pay_mon3 = @n_pay_tot
				  END
               ELSE
					BEGIN
					   IF @n_pay_tot > 0
						  BEGIN
							 SET @n_pay_mon3 = (CASE @av_company_cd
													 WHEN 'A' THEN @n_pay_tot
													 WHEN 'C' THEN @n_pay_tot
													 WHEN 'D' THEN @n_pay_tot
													 WHEN 'T' THEN @n_pay_tot
													 ELSE dbo.XF_CEIL(@n_pay_tot *  @n_month_day3 / @n_sum_month_day3, -1)
												END)
						  END
					END
			END

			BEGIN
			   IF @n_pay_mon3 > 0
			      BEGIN
				     SET @n_avg_pay = @n_pay_mon3
				  END
			END
        END 

        -- ***************************************   
        -- 4. 평균상여 조회   
        -- ***************************************
		SET @n_bonus_tot = 0	-- 상여총액
		SET @n_bonus_mon3 = 0	-- 3개월상여
		SET @n_avg_bonus = 0	-- 3개월 평균상여
		 
        BEGIN   
            SELECT @n_bonus_tot = dbo.XF_NVL_N(SUM(CAL_MON),0)
			       --@n_avg_bonus = dbo.XF_TRUNC_N(CAST(dbo.XF_NVL_N(SUM(CAL_MON),0) AS FLOAT) * 3 / 12, 0)   
              FROM REP_PAYROLL_DETAIL A   
                   INNER JOIN REP_PAY_STD B   
                                       ON A.REP_PAY_STD_ID = B.REP_PAY_STD_ID   
             WHERE B.REP_CALC_LIST_ID = @n_rep_calc_id   
               AND B.PAY_TYPE_CD = '20'   
            IF @@ERROR != 0     
                BEGIN   
                    SET @av_ret_code     = 'FAILURE!'   
                    SET @av_ret_message  = dbo.F_FRM_ERRMSG('평균상여 조회 에러발생[ERR]', @v_program_id,  0020,  null,  @an_mod_user_id)   
                    RETURN   
                END
				
             -- 3개월 상여는 모든 계열사 동일적용
			 BEGIN
			   IF @n_bonus_tot > 0
			      BEGIN
			         SET @n_bonus_mon3 = dbo.XF_TRUNC_N(CAST(dbo.XF_NVL_N(@n_bonus_tot,0) AS FLOAT) * 3 / 12, 0)
                  END
			 END

			 BEGIN
			    IF @n_bonus_mon3 > 0
				   BEGIN
				      SET @n_avg_bonus = (CASE @av_company_cd 
					                           WHEN 'H' THEN @n_bonus_mon3
											   WHEN 'Y' THEN @n_bonus_mon3
											   WHEN 'X' THEN @n_bonus_mon3
											   ELSE dbo.XF_CEIL(@n_bonus_mon3 *  @n_month_day3 / @n_sum_month_day3, -1)
                                          END)
				   END
			 END
        END 

        -- ***************************************   
        -- 5. 평균연차 조회   
        -- *************************************** 
		SET @n_yearmonth_tot = 0	-- 연월차총금액
		SET @n_yearmonth_tot3 = 0	-- 3개월연월차
		SET @n_avg_day = 0			-- 3개월평균연월차
        BEGIN   
            SELECT @n_yearmonth_tot = dbo.XF_NVL_N(SUM(CAL_MON),0)
			--@n_avg_day = dbo.XF_TRUNC_N(CAST(dbo.XF_NVL_N(SUM(CAL_MON),0) AS FLOAT) * 3 / 12, 0)   
              FROM REP_PAYROLL_DETAIL A   
                   INNER JOIN REP_PAY_STD B   
                                       ON A.REP_PAY_STD_ID = B.REP_PAY_STD_ID   
             WHERE B.REP_CALC_LIST_ID = @n_rep_calc_id   
               AND B.PAY_TYPE_CD = '30'    
           
             IF @@ERROR != 0    
                 BEGIN   
                     SET @av_ret_code     = 'FAILURE!'   
                     SET @av_ret_message  = dbo.F_FRM_ERRMSG('평균상여 조회 에러발생[ERR]', @v_program_id, 0030, null, @an_mod_user_id)   
                     RETURN   
                 END  
             -- 3개월 연차월산정
			 BEGIN
			   IF @n_yearmonth_tot > 0
			      BEGIN
			         SET @n_yearmonth_tot3 = (CASE @av_company_cd
			                                WHEN 'C' THEN dbo.XF_CEIL(@n_yearmonth_tot / 365,-1) * 90
									        WHEN 'D' THEN dbo.XF_CEIL(@n_yearmonth_tot / 365,-1) * 90
			                                ELSE dbo.XF_CEIL(dbo.XF_TRUNC_N(CAST(dbo.XF_NVL_N(@n_yearmonth_tot,0) AS FLOAT) / 12 * 3, 0), -1)
			                           END)
                  END
			 END

			 -- 3개월 평균연월차 산정
			 BEGIN
			    IF @n_yearmonth_tot3 > 0
				   BEGIN
				      SET @n_avg_day = (CASE @av_company_cd 
					                           WHEN 'H' THEN @n_yearmonth_tot3
											   WHEN 'Y' THEN @n_yearmonth_tot3
											   WHEN 'X' THEN @n_yearmonth_tot3
											   ELSE dbo.XF_CEIL(@n_yearmonth_tot3 *  @n_month_day3 / @n_sum_month_day3, -1)
                                          END)
				   END
			 END

			 BEGIN
			    IF @v_officers_yn = 'Y' -- 임원이면 연월차수당 0
				   BEGIN
				      SET @n_yearmonth_tot = 0
				      SET @n_yearmonth_tot3 = 0
					  SET @n_avg_day = 0
				   END
			 END


        END   

        -- ***************************************   
        -- 6. 근속년수 산정   
        -- ***************************************   
        BEGIN   
            EXEC dbo.P_REP_CAL_WORK_DAY @av_company_cd             -- 인사영역   
                                      , @n_emp_id                  -- 사원 ID   
                                      , @d_sta_ymd                 -- 퇴직기산일   
                                      , @d_end_ymd                 -- 퇴직정산일   
                                      , @an_mod_user_id            -- 변경자   
                                      , @n_work_yy      OUTPUT     -- 실근속년수   
                                      , @n_work_mm      OUTPUT     -- 실근속월수   
                                      , @n_work_dd      OUTPUT     -- 실근속일수   
                                      , @n_work_day     OUTPUT     -- 실근속총일수   
                                      , @n_work_yy_pt   OUTPUT     -- 실근속년수(소수점)   
                                      , @n_add_work_yy  OUTPUT     -- 추가근속년수   
                                      , @d_exce_sta_ymd OUTPUT     -- 제외시작일   
                                      , @d_exce_end_ymd OUTPUT     -- 제외종료일   
                                      , @v_cam_type_cd  OUTPUT     -- 제외발령타입   
                                      , @av_ret_code    OUTPUT     
                                      , @av_ret_message OUTPUT   
            IF @av_ret_code = 'FAILURE!'   
                BEGIN   
                    SET @av_ret_code     = 'FAILURE!'   
                    SET @av_ret_message  = @av_ret_message   
                    RETURN   
                END   
        END  
PRINT('@v_emp_cls_cd ====> ' + @v_emp_cls_cd)		
        -- ***************************************   
        -- 7. 평균임금 계산   
        -- ***************************************   
		-- 전사공통으로 평균일수는 90일 적용
		SET @n_pay_sum_amt = 0		-- 3개월 총임금
		SET @n_comm_amt = 0			-- 3개월 평균임금
		SET @n_avg_pay_amt = 0		-- 30일 평균임금(년평균임금)
        BEGIN  
		   -- 3개월 총임금
		   SET @n_pay_sum_amt = @n_pay_mon3 + @n_bonus_mon3 + @n_yearmonth_tot3
		   -- 3개월 평균임금
		   SET @n_comm_amt = dbo.XF_TRUNC_N(@n_avg_pay + @n_avg_bonus + @n_avg_day, -1)
		   IF ISNULL(@v_officers_yn, 'N') <> 'Y'  -- 임원 아니고 
		      BEGIN
			     IF @v_emp_cls_cd = 'S'  -- 선원  ==> 선원은 평균임금율 적용 
				    BEGIN --------------------------------------
					   -- 선박별 선원 평균임금율 조회
					   BEGIN
							SELECT @v_ship_cd	= SHIP_CD	-- 선박업종[PAY_SHIP_KIND_CD]    
								  ,@v_ship_cd_d = SHIP_CD_D	-- 선박세부업종[PAY_SHIP_KIND_D_CD]
								  ,@n_rate_a	= RATE_A	-- 평균임금율
							  FROM PAY_SHIP_RATE
							 WHERE COMPANY_CD = @av_company_cd
							   AND ORG_ID = @n_org_id
							   AND @d_end_ymd BETWEEN STA_YMD AND END_YMD
                  
							IF @@ERROR != 0    
							   BEGIN   
								  SET @av_ret_code     = 'FAILURE!'   
								  SET @av_ret_message  = dbo.F_FRM_ERRMSG('선박사항의 평균임금율 조회 에러발생[ERR]', @v_program_id, 0035, null, @an_mod_user_id)   
								  RETURN   
							   END 
					   END
PRINT('@n_rate_a ====> ' + CONVERT(VARCHAR, @n_rate_a))

PRINT('@v_mgr_type_cd ====> ' + @v_mgr_type_cd)
PRINT('@v_pos_grd_cd ====> ' + @v_pos_grd_cd)
PRINT('@v_yearnum_cd ====> ' + @v_yearnum_cd)
PRINT('@v_pos_cd ====> ' + @v_pos_cd)
PRINT('@v_ship_cd ====> ' + @v_ship_cd)
PRINT('@@v_ship_cd_d ====> ' + @v_ship_cd_d)

				       -- 선원 기본급 조회
				       SET @n_ship_base_amt = 0
					   BEGIN
						  SELECT @n_ship_base_amt = PAY_AMT
							FROM PAY_HOBONG
						   WHERE COMPANY_CD = @av_company_cd
							 AND MGR_TYPE_CD = @v_mgr_type_cd	-- 관리구분코드[PHM_MGR_TYPE_CD]
							 AND PAY_POS_GRD_CD = @v_pos_grd_cd	-- 직급
							 AND PAY_GRADE = @v_yearnum_cd		-- 호봉
							 AND POS_CD = @v_pos_cd				-- 직위
							 AND SHIP_CD = @v_ship_cd			-- 선박업종[PAY_SHIP_KIND_CD]
							 AND SHIP_CD_D = @v_ship_cd_d		-- 선박세부업종[PAY_SHIP_KIND_D_CD]
							 AND @d_end_ymd BETWEEN STA_YMD AND END_YMD 

						  IF @@ERROR != 0    
							 BEGIN   
								SET @av_ret_code     = 'FAILURE!'   
								SET @av_ret_message  = dbo.F_FRM_ERRMSG('해당 선원기본급 조회 에러발생[ERR]', @v_program_id, 0036, null, @an_mod_user_id)   
								RETURN   
							 END 
					   END
PRINT('@n_ship_base_amt ====> ' + CONVERT(VARCHAR, @n_ship_base_amt))
					   -- 3개월 평균임금
				       BEGIN
					      SET @n_comm_amt = dbo.XF_TRUNC_N(@n_ship_base_amt * @n_rate_a / 100, 0) 
				          IF @n_add_rate > 0
						     BEGIN
							     SET @n_comm_amt = dbo.XF_CEIL(@n_comm_amt * @n_add_rate, -1)
							 END
				       END
PRINT('@n_comm_amt ====> ' + CONVERT(VARCHAR, @n_comm_amt))				   
					END  ------------------------------------------------------------
				 ELSE
				   BEGIN
				      IF @n_add_rate > 0
					     BEGIN
						    SET @n_comm_amt = dbo.XF_TRUNC_N(@n_comm_amt *  @n_add_rate, -1)
						 END
				   END
			  END
		   ELSE
		      BEGIN
			     IF @n_add_rate > 0
				    BEGIN
					   SET @n_comm_amt = dbo.XF_TRUNC_N(@n_comm_amt *  @n_add_rate, -1)
					END
			  END

		   BEGIN
		      IF @v_emp_cls_cd = 'S'  -- 선원
                 SET @n_avg_pay_amt = @n_comm_amt
              ELSE
			     BEGIN
				    IF @v_officers_yn = 'Y'  -- 임원이면
					   BEGIN
					      SET @n_avg_pay_amt = dbo.XF_TRUNC_N(@n_comm_amt / 3, -1)
					   END
					ELSE
					   BEGIN
					      SET @n_avg_pay_amt = (CASE @av_company_cd
						                             WHEN 'X' THEN dbo.XF_TRUNC_N(@n_comm_amt / @n_sum_month_day3 * 30, -1)
													 ELSE dbo.XF_TRUNC_N(@n_comm_amt / 3, -1)
                                                END)
					   END
				 END
		   END
PRINT('@n_avg_pay_amt ====> ' + CONVERT(VARCHAR, @n_avg_pay_amt))		
		   -- 월 평균임금
		   BEGIN
		      SET @n_avg_pay_amt_m = dbo.XF_CEIL(@n_avg_pay_amt / 12, -1)	   -- 월 평균임금(년평균임금/12)
		   END
PRINT('@n_avg_pay_amt_m ====> ' + CONVERT(VARCHAR, @n_avg_pay_amt_m))	
		   -- 일 평균임금
		   BEGIN
		      SET @n_avg_pay_amt_d = dbo.XF_CEIL(@n_avg_pay_amt / 365, -1)	   -- 일 평균임금(년평균임금/365)
		   END
PRINT('@n_avg_pay_amt_d ====> ' + CONVERT(VARCHAR, @n_avg_pay_amt_d))	
		   -- 산정근속년수, 산정월수, 산정일수 산출
		   -- 홈푸드 근속산정 ==> 해당 Logic를 구현되는 사례가 없을 것 같음 ==> ASIS Logic에 있어 구현하였슴
		   BEGIN
              IF @av_company_cd = 'H'
                 BEGIN
                    if @n_work_mm > 0 AND @n_work_dd = 0
                    BEGIN
                        SET @v_chk_sta_dd = dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_sta_ymd,'YYYYMMDD'), 7,2)  -- dStrDt = strStrtDt.ToString().Substring(6, 2) 
                        SET @v_chk_end_dd = dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_end_ymd,'YYYYMMDD'), 7,2)  -- dEndDt = strEndDt.ToString().Substring(6, 2);

                        IF dbo.XF_TO_NUMBER(@v_chk_sta_ymd) > dbo.XF_TO_NUMBER(@v_chk_end_ymd)  
                           BEGIN
                              SET @n_work_mm = @n_work_mm - 1

                              SET @v_chk_sta_ymd = dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_end_ymd,'YYYYMMDD'), 1,4) + dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_sta_ymd,'YYYYMMDD'), 5,2) + dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_sta_ymd,'YYYYMMDD'), 7,2)	-- strEndDt.ToString().Substring(0, 4) + "-" + strStrtDt.ToString().Substring(4, 2) + "-" + strStrtDt.ToString().Substring(6, 2);

                              SET @v_chk_end_ymd = dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_end_ymd,'YYYYMMDD'), 1,4) + dbo.XF_LPAD(dbo.XF_TO_CHAR_N(@n_work_mm,'0'),2,'0') + dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_end_ymd,'YYYYMMDD'), 7,2)			-- dEndDt = strEndDt.ToString().Substring(0, 4) + "-" + idiff_mm + "-" + strEndDt.ToString().Substring(6, 2);
                            
							  SET @n_diff_day = dbo.XF_DATEDIFF(dbo.XF_TO_DATE(@v_chk_end_ymd,'YYYYMMDD'), dbo.XF_TO_DATE(@v_chk_sta_ymd,'YYYYMMDD')) + 1  -- diff_day = Convert.ToInt32(DateAndTime.DateDiff(DateInterval.Day, dteSDate, dteEDate, FirstDayOfWeek.Sunday, FirstWeekOfYear.Jan1)) + 1;

                              IF @n_diff_day > 29
                                 BEGIN
                                    SET @n_work_mm = @n_work_mm + 1			-- idiff_mm += 1;
                                    SET @n_diff_day = @n_diff_day - 30		-- diff_day -= 30;
                                 END

                              SET @n_work_dd = @n_diff_day --  idiff_dd = diff_day;
                           END
                    END
                 END
           END
		   SET @n_calc_yy = ISNULL(@n_work_yy, 0)  -- 산정년수
		   SET @n_calc_mm = ISNULL(@n_work_mm, 0)  -- 산정월수
		   SET @n_calc_dd = ISNULL(@n_work_dd, 0)  -- 산정일수
		   SET @n_gv_yy = 0
		   SET @n_gv_mm = 0

		   BEGIN
		      IF @v_emp_cls_cd = 'S'  -- 선원
			     BEGIN
				    IF (@n_calc_yy = 0 AND @n_calc_mm = 11)
					    BEGIN
                           SET @n_calc_dd = 0;
                        END
                    ELSE
                        BEGIN
                           IF @n_calc_dd > 0
                              BEGIN
                                 SET @n_calc_dd = 0;
                                 SET @n_calc_mm = @n_calc_mm + 1;
                              END
                           IF @n_calc_mm >= 12
                              BEGIN
                                 SET @n_calc_mm = @n_calc_mm - 12;
                                 SET @n_calc_yy = @n_calc_yy + 1;
                              END

                           -- 1년미만자는 실근속기간으로 계산
                           -- 1년이상자가 6개월단위 가산

                          IF @n_calc_mm >= 6 AND @n_calc_yy >= 1
                             BEGIN
                                SET @n_gv_yy = @n_calc_yy;
                                SET @n_gv_mm = @n_calc_mm;

                                SET @n_calc_mm = 0;
                                SET @n_calc_yy = @n_calc_yy + 1;

                                SET @n_work_yy = @n_work_yy + 1;
                                SET @n_work_mm = 0;
								SET @n_work_dd = 0;

						     END
                          ELSE IF @n_calc_mm > 0 AND @n_calc_mm < 7 AND @n_calc_yy >= 1
                             BEGIN
                                SET @n_calc_mm = 6;
                                SET @n_work_mm = 6;
                             END
                          ELSE
                             BEGIN
                                SET @n_work_mm = @n_calc_mm;
                             END

                          SET @n_cal_work = (@n_calc_yy + (@n_calc_mm / 12) + (@n_calc_dd / 360))         
				        END
				 END
              ELSE IF @v_officers_yn = 'Y'
			  		-- 임원급인경우 월할처리 ==> 일단위 있으면 월로 올림
		        BEGIN
                   IF @v_officers_yn = 'Y'
                      BEGIN
                         IF @n_calc_dd > 0
                            BEGIN
                               SET @n_calc_dd = 0
                               SET @n_calc_mm = @n_calc_mm + 1
                            END

                        IF @n_calc_mm > 12
                           BEGIN
                              SET @n_calc_mm = @n_calc_mm - 12
                              SET @n_calc_yy = @n_calc_yy + 1
                           END
                   END
		         END
			  ELSE
                 BEGIN
				    IF @av_company_cd IN ('E','F','I','M','R','Y')
					   BEGIN
					      IF @n_calc_dd > 0
						     BEGIN
							    SET @n_calc_dd = 0
								SET @n_calc_mm = @n_calc_mm + 1
							 END

							 IF @n_calc_mm >= 12
							    BEGIN
								   SET @n_calc_mm = @n_calc_mm - 12
								   SET @n_calc_yy = @n_calc_yy + 1
								END
					   END
                END
		   END
        END --  

		-- 최종(정산)근속년수, 최종(정산) 주(현)월수
		BEGIN
		   SET @n_c1_work_yy  = @n_calc_yy						-- 최종 근속년수
		   SET @n_bc1_work_yy = @n_calc_yy						-- 근속년수(법정)(현+종전 근속년수)
		   SET @n_sum_work_yy = @n_calc_yy						-- 정산 근속년수
		   SET @n_c1_work_mm  = (@n_calc_yy * 12) + @n_calc_mm	-- 주(현)근속월수
		   SET @n_sum_work_mm = @n_c1_work_mm					-- 정산 근속월

		   BEGIN
			  IF (@n_calc_mm + @n_calc_dd) > 0   
                BEGIN
                    SET @n_c1_work_yy = @n_calc_yy + 1
                END
 		   END

        END

		-- 년 퇴직금, 월 퇴직금, 일 퇴직금 산출, 퇴직금산출
		BEGIN
           -- 년 퇴직금 = 년 평균임금 * 산정년수
		   SET @n_amt_retr_pay_y = dbo.XF_CEIL(@n_avg_pay_amt * @n_calc_yy, -1) 
		   -- 월 퇴직금 = 월 평균임금 * 산정월수
		   SET @n_amt_retr_pay_m = dbo.XF_CEIL(@n_avg_pay_amt_m * @n_calc_mm, -1)
		   -- 일 퇴직금 = 일 평균임금 * 산정일수
		   SET @n_amt_retr_pay_d = dbo.XF_CEIL(@n_avg_pay_amt_d * @n_calc_dd, -1)

           IF @v_emp_cls_cd = 'S' 
		      BEGIN
			     IF @n_calc_yy < 1 AND @n_calc_mm > 6
                    BEGIN 
                       -- 년 퇴직금 = 년 평균임금 * 산정년수
                       SET @n_amt_retr_pay_y = dbo.XF_CEIL(@n_avg_pay_amt * @n_calc_yy, -1) 

                       -- 월 퇴직금 = 년 평균임금 * 20 / 30
                       SET @n_amt_retr_pay_y = dbo.XF_CEIL((@n_avg_pay_amt * 20 /30), -1) 

                       -- 일 퇴직금 = 일 평균임금 * 산정일수
		               SET @n_amt_retr_pay_d = dbo.XF_CEIL(@n_avg_pay_amt_d * @n_calc_dd, -1)
                    END
             END

			 -- 퇴직금계
  			 SET @n_amt_retr_amt = dbo.XF_ROUND(@n_amt_retr_pay_y + @n_amt_retr_pay_m + @n_amt_retr_pay_d, -1)
PRINT('@n_amt_retr_pay_y  ====> ' + CONVERT(VARCHAR, @n_amt_retr_pay_y ))	
PRINT('@n_amt_retr_pay_m  ====> ' + CONVERT(VARCHAR, @n_amt_retr_pay_m ))
PRINT('@n_amt_retr_pay_d  ====> ' + CONVERT(VARCHAR, @n_amt_retr_pay_d ))
		END
PRINT('@n_amt_retr_amt  ====> ' + CONVERT(VARCHAR, @n_amt_retr_amt ))			 
        -- ***************************************   
        -- 8. 평균임금, 근속년수 저장   
        -- ***************************************   
        BEGIN   
            UPDATE REP_CALC_LIST            -- 퇴직금계산대상자(내역)   
               SET BIZ_CD				= @v_biz_cd				-- 사업장
				 , REG_BIZ_CD			= @v_reg_biz_cd			-- 신고사업장
				 , ORG_NM				= @v_org_nm				-- 조직명
				 , ORG_LINE				= @v_org_line			-- 조직순차
	             , PAY_METH_CD			= @v_pay_meth_cd		-- 급여지급방식[PAY_METH_CD]
				 , CALCU_TPYE			= '2'					-- 계산구분
				 , EMP_CLS_CD			= @v_emp_cls_cd			-- 고용유형[PAY_EMP_CLS_CD]
				 , REP_MID_YN			= @v_rep_mid_yn			-- 중간정산포함여부
				 , INS_TYPE_YN			= @v_ins_type_yn		-- 퇴직연금가입여부
				 , INS_TYPE_CD			= @v_ins_type_cd		-- 퇴직연금종류[RMP_INS_TYPE_CD]								 
				 , REP_ANNUITY_BIZ_NM	= @v_ins_nm				-- 퇴직연금사업자명
				 , REP_ANNUITY_BIZ_NO	= @v_ins_bizno			-- 퇴직연금사업장등록번호
				 , REP_ACCOUNT_NO		= @v_ins_account_no		-- 퇴직연금계좌번호
				 , RETIRE_TURN			= ISNULL(dbo.F_REP_PEN_RETIRE_MON(EMP_ID, RETIRE_YMD), 0) 	-- 국민연금퇴직전환금
			     , WORK_YY				=  @n_work_yy          -- 실근속년수(년만)   
                 , WORK_MM				=  @n_work_mm          -- 실근속월수   
                 , WORK_DD				=  @n_work_dd          -- 실근속일수   
                 , WORK_DAY				=  @n_work_day         -- 실근속총일수   
                 , WORK_YY_PT			=  @n_calc_yy		   -- 산정근속년수  
				 , WORK_MM_PT			=  @n_calc_mm		   -- 산정근속월수
				 , WORK_DD_PT			=  @n_calc_dd		   -- 산정근속일수
                 --, WORK_YY_PT			=  @n_work_yy_pt       -- 실근속년수(소수점)   
                 , ADD_WORK_YY			=  @n_add_work_yy      -- 추가근속년수 
				 , PAY_MON				=  @n_pay_tot          -- 급여합계
				 , PAY_TOT_AMT			=  @n_pay_mon3		   -- 3개월급여
                 , AVG_PAY				=  @n_avg_pay          -- 평균급여 
				 , BONUS_MON			=  @n_bonus_tot		   -- 상여총액
				 , BONUS_TOT_AMT		=  @n_bonus_mon3       -- 3개월상여
                 , AVG_BONUS			=  @n_avg_bonus        -- 3개월평균상여
				 , DAY_TOT_AMT			=  @n_yearmonth_tot3   -- 3개월연월차 
                 , AVG_DAY				=  @n_avg_day          -- 평균연월차   
                 , MONTH_DAY3			=  @n_month_day3       -- 3개월근무일수
				 , PAY_SUM_AMT			=  @n_pay_sum_amt	   -- 3개월 총임금	 
				 , PAY_COMM_AMT			=  @n_comm_amt		   -- 3개월평균임금
				 , AVG_PAY_AMT			=  @n_avg_pay_amt      -- 30일 평균임금(년평균임금)   
				 , AVG_PAY_AMT_M		=  @n_avg_pay_amt_m	   -- 월 평균임금(년평균임금/12)
				 , AVG_PAY_AMT_D		=  @n_avg_pay_amt_d    -- 일 평균임금
				 , AMT_RETR_PAY_Y		=  @n_amt_retr_pay_y   -- 년 퇴직금
				 , AMT_RETR_PAY_M		=  @n_amt_retr_pay_m   -- 월 퇴직금
				 , AMT_RETR_PAY_D		=  @n_amt_retr_pay_d   -- 일 퇴직금
				 , SUM_MONTH_DAY3		=  @n_sum_month_day3   -- 근속일수
				 , AMT_RATE_ADD			=  @n_add_rate		   -- 임원누진율(지급배수)
				 , C_01					=  @n_amt_retr_amt	   -- 주(현)법정퇴직급여	
				 , C_01_1				=  @n_amt_retr_amt	   -- 주(현)법정퇴직금	
				 , C_SUM				=  @n_amt_retr_amt     -- 주(현)계
				 , R01					=  @n_amt_retr_amt	   -- 법정퇴직급여액	
				 , R01_S				=  @n_amt_retr_amt	   -- 퇴직급여액
				 , C1_WORK_YY			=  @n_c1_work_yy	   -- 최종 근속년수 
				 , BC1_WORK_YY			=  @n_bc1_work_yy	   -- 근속년수(법정)(현+종전 근속년수) 
				 , SUM_WORK_YY			=  @n_sum_work_yy	   -- 정산 근속년수 
				 , C1_WORK_MM			=  @n_c1_work_mm	   -- 주(현)근속월수 
				 , SUM_WORK_MM			=  @n_sum_work_mm	   -- 정산 근속월 
                 , MOD_USER_ID			=  @an_mod_user_id     -- 변경자   
                 , MOD_DATE				=  dbo.XF_SYSDATE(0)   -- 변경일시   
             WHERE REP_CALC_LIST_ID =  @n_rep_calc_id   
            SELECT @ERRCODE = @@ERROR   
            IF @ERRCODE != 0   
                BEGIN   
                    SET @av_ret_code    = 'FAILURE!'   
                    SET @av_ret_message = dbo.F_FRM_ERRMSG('평균임금 저장시 에러발생[ERR]', @v_program_id, 0040, null, @an_mod_user_id)   
                    RETURN   
                END   
        END---
    END   
   
PRINT('<<===== P_REP_CAL_AVG_AMT END')   
   -- ***********************************************************   
   -- 작업 완료   
   -- ***********************************************************   
    SET @av_ret_code    = 'SUCCESS!'   
    SET @av_ret_message = dbo.F_FRM_ERRMSG('평균임금 산정이 완료되었습니다[ERR]', @v_program_id, 9999, null, @an_mod_user_id)   
   
END
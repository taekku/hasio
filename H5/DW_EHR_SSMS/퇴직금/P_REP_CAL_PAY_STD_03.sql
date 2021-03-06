SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_CAL_PAY_STD_03] (      
       @av_company_cd                 NVARCHAR(10),             -- 인사영역      
       @av_locale_cd                  NVARCHAR(10),             -- 지역코드      
       @an_rep_calc_list_id_list      NUMERIC(38),				-- 퇴직금대상ID      
       @an_mod_user_id                NUMERIC(38),				-- 변경자 사번      
       @av_ret_code                   NVARCHAR(4000)    OUTPUT, -- 결과코드*/      
       @av_ret_message                NVARCHAR(4000)    OUTPUT  -- 결과메시지*/      
    ) AS      
    -- ***************************************************************************      
    --   TITLE       : 추계액 기준임금관리/임금항목관리      
    --   PROJECT     : HR 시스템      
    --   AUTHOR      :      
    --   PROGRAM_ID  : P_REP_CAL_PAY_STD      
    --   RETURN      : 1) SUCCESS!/FAILURE!      
    --                 2) 결과 메시지      
    --   COMMENT     : 추계액 기준임금정보/임금항목정보 insert      
    --   HISTORY     : 화이트정보통신 
    -- ***************************************************************************      
BEGIN      
    /* 기본적으로 사용되는 변수 */      
    DECLARE @v_program_id              NVARCHAR(30)     
          , @v_program_nm              NVARCHAR(100)      
          , @ERRCODE                   NVARCHAR(10)      
      
    DECLARE @n_emp_id                  NUMERIC(38)				-- 사원ID
		  , @v_in_offi_yn			   NVARCHAR(1)				-- 재직여부
		  , @d_retire_ymd			   DATE                     -- 퇴직일자
		  , @v_flag_yn				   NVARCHAR(1)				-- 1년미만
          , @v_base_pay_ym             NVARCHAR(6)				-- 급여지급년월
		  , @v_base_bns_ym             NVARCHAR(6)				-- 상여지급년월
		  , @v_base_yun_ym             NVARCHAR(6)				-- 연차지급년월
		  , @n_retire_turn_mon		   NUMERIC(15)				-- 국민연금퇴직전환금
		  , @v_rep_mid_yn			   NVARCHAR(6)				-- 중간정산여부
		  , @v_officers_yn			   NVARCHAR(1)				-- 임원여부
		  , @v_trans_yn				   NVARCHAR(1)				-- 과세이연대상여부
		  , @n_add_rate				   NUMERIC(5,2)				-- 누진율
		  , @n_org_id				   NUMERIC(38)				-- 조직ID
		  , @v_pos_cd				   NVARCHAR(50)				-- 직위
		  , @v_pay_group			   NVARCHAR(50)				-- 급여그룹
          , @n_std_cnt                 NUMERIC                  -- 기준금관리 조회수 
		  , @v_mgr_type_cd			   NVARCHAR(30)				-- 관리구분코드[PHM_MGR_TYPE_CD]
		  , @v_pay_meth_cd			   NVARCHAR(50)				-- 급여지급방식코드[PAY_METH_CD]
		  ,	@v_emp_cls_cd			   NVARCHAR(50)				-- 고용유형코드[PAY_EMP_CLS_CD]
          , @n_rep_id                  NUMERIC(38)				-- 대상금액 입력ID(Sequence)
          , @n_pay_cal_mon             NUMERIC(38)				-- 급여 평균임금 적용대상 기준금액
          , @n_bns_cal_mon             NUMERIC(38)				-- 상여 평균임금 적용대상 기준금액
          , @n_yun_cal_mon             NUMERIC(38)				-- 연차 평균임금 적용대상 기준금액
          , @d_end_ymd                 DATETIME2				-- 주(현)정산일 - 퇴직일
		  , @d_excep_ymd			   DATETIME2				-- 급여제외시작일
		  , @v_pay_excep_yn			   NVARCHAR(1)				= 'N' -- 급여산정제외여부
		  , @d_pay_end_ymd			   DATETIME2				-- 최종급여반영기준일
		  , @n_bef_ret_year			   NUMERIC					-- 퇴직전년도
          , @n_rep_calc_list_id_list   NUMERIC(38)				-- 퇴직금대상자 Pk 
          , @n_rep_calc_id             NUMERIC					-- 퇴직금대상ID
		  , @d_bns_s_ymd			   DATETIME2				-- 상여 적용대상 시작일
		  , @d_bns_e_ymd			   DATETIME2				-- 상여 적용대상 종료일
		  , @d_day_s_ymd			   DATETIME2				-- 연차 적용대상 시작일
		  , @d_day_e_ymd			   DATETIME2				-- 연차 적용대상 종료일
          , @d_base_s_ymd              DATETIME2				-- 평균임금 적용대상 시작일
		  , @n_base_s_ymd_cnt		   NUMERIC(3)				-- 평균임금 적용대상 시작일수
          , @d_base_e_ymd              DATETIME2				-- 평균임금 적용대상 종료일
          , @n_base_cnt                NUMERIC(3)				-- 기준일수      
          , @n_real_cnt                NUMERIC(3)				-- 대상일수       
          , @n_yy                      NUMERIC(3)				-- 근속년수

          , @n_roop_cnt                NUMERIC(3)				-- 반복(Looping)횟수_급여      
          , @n_pay_cnt                 NUMERIC(3)				-- 급여적용횟수 
		  , @n_bns_roop_cnt            NUMERIC(3)				-- 반복(Looping)횟수_급여
		  , @n_bns_cnt				   NUMERIC(3)				-- 상여적용횟수  
          , @n_p28_cnt                 NUMERIC(3)				-- 상여횟수
		  , @v_pay01_ym				   NVARCHAR(6)				-- 급여년월_01
		  ,	@v_pay02_ym				   NVARCHAR(6)				-- 급여년월_02
		  ,	@v_pay03_ym				   NVARCHAR(6)				-- 급여년월_03
		  ,	@v_pay04_ym				   NVARCHAR(6)				-- 급여년월_04
		  , @n_pay01_amt			   NUMERIC(18)				-- 급여금액_01
		  , @n_pay02_amt			   NUMERIC(18)				-- 급여금액_02
		  , @n_pay03_amt			   NUMERIC(18)				-- 급여금액_03
		  , @n_pay04_amt			   NUMERIC(18)				-- 급여금액_04
		  , @n_pay_mon				   NUMERIC(18)				-- 급여합계
		  ,	@n_pay_tot_amt			   NUMERIC(18)				-- 3개월급여합계
		  , @v_bonus01_ym			   NVARCHAR(6)				-- 상여년월_01
		  , @n_bonus01_amt			   NUMERIC(18)				-- 상여금액_01
		  , @v_bonus02_ym			   NVARCHAR(6)				-- 상여년월_02
		  , @n_bonus02_amt			   NUMERIC(18)				-- 상여금액_02
		  , @v_bonus03_ym			   NVARCHAR(6)				-- 상여년월_03
		  , @n_bonus03_amt			   NUMERIC(18)				-- 상여금액_03
		  , @v_bonus04_ym			   NVARCHAR(6)				-- 상여년월_04
		  , @n_bonus04_amt			   NUMERIC(18)				-- 상여금액_04
		  , @v_bonus05_ym			   NVARCHAR(6)				-- 상여년월_05
		  , @n_bonus05_amt			   NUMERIC(18)				-- 상여금액_05
		  , @v_bonus06_ym			   NVARCHAR(6)				-- 상여년월_06
		  , @n_bonus06_amt			   NUMERIC(18)				-- 상여금액_06
		  , @v_bonus07_ym			   NVARCHAR(6)				-- 상여년월_07
		  , @n_bonus07_amt			   NUMERIC(18)				-- 상여금액_07
		  , @v_bonus08_ym			   NVARCHAR(6)				-- 상여년월_08
		  , @n_bonus08_amt			   NUMERIC(18)				-- 상여금액_08
		  , @v_bonus09_ym			   NVARCHAR(6)				-- 상여년월_09
		  , @n_bonus09_amt			   NUMERIC(18)				-- 상여금액_09
		  , @v_bonus10_ym			   NVARCHAR(6)				-- 상여년월_10
		  , @n_bonus10_amt			   NUMERIC(18)				-- 상여금액_10
		  , @v_bonus11_ym			   NVARCHAR(6)				-- 상여년월_11
		  , @n_bonus11_amt			   NUMERIC(18)				-- 상여금액_11
		  , @v_bonus12_ym			   NVARCHAR(6)				-- 상여년월_12
		  , @n_bonus12_amt			   NUMERIC(18)				-- 상여금액_12
		  , @n_bonus_mon			   NUMERIC(18)				-- 상여총액
		  , @n_day_tot_amt			   NUMERIC(18)				-- 연월차총액
		  , @d_last_retire_date		   DATE						-- 퇴직월 말일자	
		  , @n_real_cnt_tmp			   NUMERIC(3)				-- 대상일수_TEMP	
		  , @n_real_cnt_tmp1		   NUMERIC(3)				-- 대상일수_TEMP1
		  , @n_real_cnt_tmp2		   NUMERIC(3)				-- 대상일수_TEMP2
		  , @n_real_cnt_tmp3		   NUMERIC(3)				-- 대상일수_TEMP3
		  , @n_real_cnt_tmp4		   NUMERIC(3)				-- 대상일수_TEMP4

      
      /* 기본변수 초기값 셋팅*/      
    SET @v_program_id    = 'P_REP_CAL_PAY_STD_03'   -- 현재 프로시져의 영문명      
    SET @v_program_nm    = '추계액 기준임금관리/임금항목관리'        -- 현재 프로시져의 한글문명      
    SET @av_ret_code     = 'SUCCESS!'      
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)      
      
    BEGIN      
        SET @n_rep_calc_id = @an_rep_calc_list_id_list      
        SET @n_yy = 0  
		
        -- ***************************************      
        -- 1. 대상자(내역) 조회      
        -- ***************************************      
        BEGIN      
            SELECT @n_emp_id                = EMP_ID								-- 사원ID 
			     , @n_org_id				= ORG_ID								-- 조직ID
				 , @v_pos_cd				= POS_CD								-- 직위
                 , @d_end_ymd               = C1_END_YMD							-- 주(현)정산일  
                 , @n_rep_calc_list_id_list = REP_CALC_LIST_ID						-- 대상자 퇴직금ID     
				 , @n_retire_turn_mon		= ISNULL(dbo.F_REP_PEN_RETIRE_MON(EMP_ID, RETIRE_YMD), 0) 	-- 국민연금퇴직전환금	
				 , @v_emp_cls_cd			= ISNULL(EMP_CLS_CD, 'Z')				-- 고용유형[PAY_EMP_CLS_CD]
				 , @v_mgr_type_cd			= ISNULL(MGR_TYPE_CD, '1')				-- 관리구분코드[PHM_MGR_TYPE_CD]
				 , @v_officers_yn			= ISNULL(OFFICERS_YN, 'N')				-- 임원여부
				 , @v_flag_yn				= CASE WHEN C1_STA_YMD <= DATEADD(MM, 1, DATEADD(YYYY, -1, C1_END_YMD)) THEN 'N' ELSE 'Y' END				-- 1년미만
              FROM REP_CALC_LIST      
             WHERE REP_CALC_LIST_ID = @n_rep_calc_id      
            IF @@ERROR != 0                       
                BEGIN      
                    SET @av_ret_code    = 'FAILURE!'      
                    SET @av_ret_message = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') 기준임금 대상자 조회 에러[ERR]', @v_program_id, 0010, null, @an_mod_user_id)      
                    RETURN      
                END      
        END 

		-- 현재 휴직중이거나 무급 휴직중에 퇴사하는 경우 CHECK
		BEGIN
		   SET @v_pay_excep_yn = 'N' -- 급여산정제외여부
		   SET @d_pay_end_ymd = @d_end_ymd
		   BEGIN
			  SELECT TOP 1 @v_pay_excep_yn = 'Y'
			             , @d_excep_ymd = T.STA_YMD
			  FROM (
					SELECT STA_YMD      
						 , END_YMD      
					  FROM CAM_TERM_MGR      
					 WHERE ITEM_NM = 'LEAVE_CD'      
					   AND VALUE IN (SELECT KEY_CD2 AS REASON_CD  
									   FROM FRM_UNIT_STD_HIS  
									  WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																	 FROM FRM_UNIT_STD_MGR  
																	WHERE COMPANY_CD = @av_company_cd  
																	  AND UNIT_CD = 'REP'  
																	  AND STD_KIND = 'REP_AVG_EXC_RSN_CD')  
										AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
										AND KEY_CD1 = '10')      
					   AND EMP_ID = @n_emp_id
					   AND @d_end_ymd BETWEEN STA_YMD AND END_YMD
					UNION
					SELECT STA_YMD
						 , END_YMD
					  FROM DTM_DAILY_APPL   --일근태내역
					 WHERE WORK_CD IN (SELECT KEY_CD2 AS REASON_CD  
									   FROM FRM_UNIT_STD_HIS  
									  WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																	 FROM FRM_UNIT_STD_MGR  
																	WHERE COMPANY_CD = @av_company_cd 
																	  AND UNIT_CD = 'REP'  
																	  AND STD_KIND = 'REP_AVG_EXC_RSN_CD')  
										AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
										AND KEY_CD1 = '20')
					   AND EMP_ID = @n_emp_id
					   AND STAT_CD = '132'
					   AND @d_end_ymd BETWEEN STA_YMD AND END_YMD	
				  ) T
				IF @@ERROR != 0
					BEGIN
						SET @v_pay_excep_yn = 'N'
						SET @d_pay_end_ymd = @d_end_ymd
					END
		   END

		   BEGIN
		      IF @v_pay_excep_yn = 'Y'
			     BEGIN
				    SET @d_pay_end_ymd = dbo.F_REP_LAST_PAY_YMD_DW(@av_company_cd, @n_emp_id, @d_excep_ymd, @d_end_ymd)
				 END
		   END
		END

        -- ***************************************      
        -- 1. 3개월치 급여 조회      
        -- ***************************************      
        BEGIN  
		    SET @d_last_retire_date = dbo.XF_LAST_DAY(@d_pay_end_ymd) -- 퇴직월 말일자
            SET @n_roop_cnt = CASE WHEN @d_pay_end_ymd = dbo.XF_LAST_DAY(@d_pay_end_ymd) THEN 3 ELSE 4 END     
            SET @n_pay_cnt = 1     
            SET @n_real_cnt_tmp  = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_pay_end_ymd, 'DD')) -- 퇴직월 일자 			
			
print '3개월급여시작:' + FORMAT(@d_pay_end_ymd, 'yyyyMM') + '<==' + convert(varchar(100), sysdatetime())
            DECLARE rep CURSOR FOR      
       --         SELECT DISTINCT A.PAY_YM AS BASE_YM      
       --           FROM PAY_PAY_YMD A      
       --                INNER JOIN PAY_PAYROLL B      
       --                    ON B.PAY_YMD_ID = A.PAY_YMD_ID 
       --          WHERE B.EMP_ID = @n_emp_id      
       --            AND A.CLOSE_YN = 'Y' 
				   --AND A.PAY_YN = 'Y'
       --            AND A.PAY_YM <= FORMAT(@d_pay_end_ymd, 'yyyyMM') -- dbo.XF_TO_CHAR_D(@d_end_ymd, 'YYYYMM')    
       --          ORDER BY A.PAY_YM DESC  
	   SELECT TOP 4 BEL_PAY_YM BASE_YM, A.CAL_MON --@n_cal_mon             -- 금액  										
									FROM (
										SELECT B.BEL_PAY_YM, SUM(dbo.XF_NVL_N(CAL_MON,0)) AS CAL_MON
										FROM PAY_PAYROLL A
											INNER JOIN PAY_PAY_YMD C 
												ON A.PAY_YMD_ID = C.PAY_YMD_ID
											INNER JOIN PAY_PAYROLL_DETAIL B
												ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
											INNER JOIN (
												SELECT PAY_TYPE_CD, PAY_ITEM_CD
												 FROM (
													   SELECT CD PAY_TYPE_CD, SYS_CD
														 FROM FRM_CODE
														WHERE COMPANY_CD = @av_company_cd
														  AND CD_KIND = 'PAY_TYPE_CD'
														  AND SYS_CD != '100' -- 시뮬레이션제외
													  ) A
													INNER JOIN (
																SELECT KEY_CD2 PAY_ITEM_SYS_CD, KEY_CD3 AS PAY_ITEM_CD  
																  FROM FRM_UNIT_STD_HIS  
																 WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																								FROM FRM_UNIT_STD_MGR  
																							   WHERE COMPANY_CD = @av_company_cd  
																								 AND UNIT_CD = 'REP'  
											  													 AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
																   AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
																   AND KEY_CD1 = '10'  
														) B
														ON (A.SYS_CD = B.PAY_ITEM_SYS_CD)-- OR B.PAY_ITEM_SYS_CD IS NULL)
													) T1
												ON C.PAY_TYPE_CD = T1.PAY_TYPE_CD
												AND B.PAY_ITEM_CD = T1.PAY_ITEM_CD
											WHERE C.CLOSE_YN = 'Y'
											AND C.PAY_YN = 'Y'
											--AND B.BEL_PAY_YM = @v_base_pay_ym  
											AND B.BEL_PAY_YM <= FORMAT(@d_pay_end_ymd, 'yyyyMM')
											AND C.COMPANY_CD = @av_company_cd 
											AND A.EMP_ID = @n_emp_id
											GROUP BY B.BEL_PAY_YM
											) A
										WHERE CAL_MON <> 0
										ORDER BY BEL_PAY_YM DESC
            OPEN rep      
                FETCH NEXT FROM rep INTO @v_base_pay_ym, @n_pay_cal_mon 
                WHILE (@@FETCH_STATUS = 0 AND @n_roop_cnt >= @n_pay_cnt)      
                    BEGIN -- 커서루프      
                        -- ***************************************      
                        -- 1-1. 날짜, 일수 세팅      
                        -- ***************************************  

                        BEGIN     

                            SET @d_base_s_ymd = CASE WHEN @n_roop_cnt = @n_pay_cnt THEN dbo.XF_TO_DATE(@v_base_pay_ym + dbo.XF_TO_CHAR_D(dbo.XF_DATEADD(dbo.XF_MONTHADD(@d_pay_end_ymd, -3), 1),'DD'),'YYYYMMDD')    
                                                     ELSE dbo.XF_TO_DATE(@v_base_pay_ym + '01','YYYYMMDD')     
                                                END     
                            SET @d_base_e_ymd = CASE WHEN @n_roop_cnt <> 3 AND @n_pay_cnt = 1 THEN @d_end_ymd     
                                                     ELSE dbo.XF_LAST_DAY(dbo.XF_TO_DATE(@v_base_pay_ym + '01','YYYYMMDD'))     
                                                END     
                            -- 패키지 적용 산정기준
							SET @n_base_cnt = CASE WHEN @n_pay_cnt = 1 THEN dbo.XF_DATEDIFF(@d_base_e_ymd, @d_base_s_ymd)+1    
                                                   ELSE dbo.XF_DATEDIFF(dbo.XF_LAST_DAY(dbo.XF_TO_DATE(@v_base_pay_ym + '01','YYYYMMDD')), dbo.XF_TO_DATE(@v_base_pay_ym + '01','YYYYMMDD'))+1   
                                              END      
                            SET @n_real_cnt = dbo.XF_DATEDIFF(@d_base_e_ymd, @d_base_s_ymd)+1  
							
							-- 동원그룹 산정기준(전계열사 공통)							
							BEGIN
							    SET @n_base_cnt = 30
							    SET @n_real_cnt = 30
							END

							IF (@d_last_retire_date != @d_pay_end_ymd)               -- 말일자 퇴직이 아니면
							   BEGIN
							      IF @n_roop_cnt = @n_pay_cnt  --- 적용 시작월 급여 
								     BEGIN
									    SET @n_real_cnt = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(dbo.XF_LAST_DAY(@d_base_s_ymd), 'DD')) - @n_real_cnt_tmp 
										BEGIN
										   IF (@v_emp_cls_cd = 'A' AND @av_company_cd = 'H')
										      BEGIN
											     SET @n_real_cnt = 30 - @n_real_cnt_tmp
                                    		  END
										   ELSE IF (@av_company_cd = 'C' OR 
										            @av_company_cd = 'A' OR
													@av_company_cd = 'B' OR 
													@av_company_cd = 'X' OR 
													@av_company_cd = 'Y')
                                                   BEGIN
												      SET @n_real_cnt = 30 - @n_real_cnt_tmp 
												   END
										   ELSE IF (@av_company_cd = 'T') -- 테크팩 평균 급여는 만근 한 최근 3개월치 급여 평균으로 계산
										           -- 퇴직월이 만근이 아니기 때문에 최초 산정월은 만근처리
										           BEGIN
												      IF (@v_mgr_type_cd = 'B' AND @n_real_cnt_tmp < 20)
													     BEGIN
                                                            SET @n_real_cnt = 30
														    SET @n_base_cnt = 30
														 END
                                                      ELSE IF (@v_mgr_type_cd <> 'B' AND @n_real_cnt_tmp < 30)
													     BEGIN
                                                            SET @n_real_cnt = 30
														    SET @n_base_cnt = 30
														 END                                                      
												   END
										   ELSE IF (@av_company_cd = 'J' OR
										            @av_company_cd = 'W')
                                                   BEGIN
												      SET @n_real_cnt = 30 - @n_real_cnt_tmp
												   END
										   ELSE IF (@av_company_cd = 'S')
										           BEGIN
												      SET @n_real_cnt = 30 - @n_real_cnt_tmp
												   END
                                           ELSE
										           BEGIN
												      SET @n_base_s_ymd_cnt = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(dbo.XF_LAST_DAY(@d_base_s_ymd), 'DD'))  -- 시작일의 마지막일자
                                                      SET @n_real_cnt = @n_base_s_ymd_cnt - @n_real_cnt_tmp;
												   END
										END
									 END
                                  ELSE IF @n_pay_cnt = 1 -- 퇴직월 급여
								     
								     BEGIN
									   SET @n_real_cnt = @n_real_cnt_tmp
									   SET @n_base_cnt = @n_real_cnt_tmp
									   IF (@av_company_cd = 'T')
									      BEGIN
										     IF (@v_mgr_type_cd = 'B' AND @n_real_cnt_tmp < 20)
											    BEGIN
												   SET @n_real_cnt = 0
												   SET @n_base_cnt = 0
												END
                                             ELSE IF (@v_mgr_type_cd <> 'B' AND @n_real_cnt_tmp < 30)
                                                BEGIN
												   SET @n_real_cnt = 0
												   SET @n_base_cnt = 0
												END
										  END
                                       ELSE IF (@av_company_cd = 'S')
									      BEGIN
									         IF (@n_real_cnt_tmp >= 10)
											    BEGIN
												   SET @n_real_cnt = @n_real_cnt_tmp
												END

										  END
									 END
							   END
                        END    
                        -- ***************************************      
                        -- 1-2. 임금항목 저장      
                        -- ***************************************  

						-- 선원은 해당 LOGIC 반영하지 않음
						--SET @n_pay_cal_mon = 0
						BEGIN
							IF @v_emp_cls_cd = 'S'
								SET @n_pay_cal_mon = 0
						/*
							IF @v_emp_cls_cd <> 'S'
							   BEGIN
								  SELECT @n_pay_cal_mon = A.CAL_MON --@n_cal_mon             -- 금액  										
									FROM (
										SELECT SUM(dbo.XF_NVL_N(CAL_MON,0)) AS CAL_MON
										FROM PAY_PAYROLL A
											INNER JOIN PAY_PAY_YMD C 
												ON A.PAY_YMD_ID = C.PAY_YMD_ID
											INNER JOIN PAY_PAYROLL_DETAIL B
												ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
											INNER JOIN (
												SELECT PAY_TYPE_CD, PAY_ITEM_CD
												 FROM (
													   SELECT CD PAY_TYPE_CD, SYS_CD
														 FROM FRM_CODE
														WHERE COMPANY_CD = @av_company_cd
														  AND CD_KIND = 'PAY_TYPE_CD'
														  AND SYS_CD != '100' -- 시뮬레이션제외
													  ) A
													INNER JOIN (
																SELECT KEY_CD2 PAY_ITEM_SYS_CD, KEY_CD3 AS PAY_ITEM_CD  
																  FROM FRM_UNIT_STD_HIS  
																 WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																								FROM FRM_UNIT_STD_MGR  
																							   WHERE COMPANY_CD = @av_company_cd  
																								 AND UNIT_CD = 'REP'  
											  													 AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
																   AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
																   AND KEY_CD1 = '10'  
														) B
														ON (A.SYS_CD = B.PAY_ITEM_SYS_CD OR B.PAY_ITEM_SYS_CD IS NULL)
													) T1
												ON C.PAY_TYPE_CD = T1.PAY_TYPE_CD
												AND B.PAY_ITEM_CD = T1.PAY_ITEM_CD
											WHERE C.CLOSE_YN = 'Y'
											AND C.PAY_YN = 'Y'
											AND B.BEL_PAY_YM = @v_base_pay_ym  
											AND C.COMPANY_CD = @av_company_cd 
											AND A.EMP_ID = @n_emp_id
											) A
										WHERE CAL_MON <> 0
							   END
							   */
--PRINT('@n_pay_cnt ===> ' + CONVERT(VARCHAR,  @n_pay_cnt) )
--PRINT('@v_base_pay_ym ===> ' + @v_base_pay_ym)
--PRINT('@n_pay_cal_mon ===> ' + CONVERT(VARCHAR,  @n_pay_cal_mon) )
							-- 급여년월 및 급여금액 적용(급여는 일할적용 시 최대 4개월 적용)
							BEGIN
								IF @n_pay_cnt = 1
									BEGIN
										SET @v_pay01_ym = @v_base_pay_ym
										SET @n_pay01_amt = @n_pay_cal_mon
									END
								ELSE IF @n_pay_cnt = 2
									BEGIN
										SET @v_pay02_ym = @v_base_pay_ym
										SET @n_pay02_amt = @n_pay_cal_mon
									END 
								ELSE IF @n_pay_cnt = 3
									BEGIN
										SET @v_pay03_ym = @v_base_pay_ym
										SET @n_pay03_amt = @n_pay_cal_mon
									END
								ELSE
									BEGIN
										SET @v_pay04_ym = @v_base_pay_ym
										SET @n_pay04_amt = @n_pay_cal_mon
									END
							END
                        END   
						
                        BEGIN 										
						   SET @n_pay_cnt = @n_pay_cnt + 1  -- 순차 증가처리
						END

                        FETCH NEXT FROM rep INTO @v_base_pay_ym, @n_pay_cal_mon
                    END       -- 커서루프 종료      
            CLOSE rep         -- 커서닫기      
            DEALLOCATE rep    -- 커서 할당해제      
        END -- 커서종료  

		-- 급여합계적용
		BEGIN
		   SET @n_pay_mon = ISNULL(@n_pay01_amt,0) + ISNULL(@n_pay02_amt,0) + ISNULL(@n_pay03_amt,0) + ISNULL(@n_pay04_amt,0)	-- 급여합계
		   SET @n_pay_tot_amt = @n_pay_mon -- 3개월급여합계
print '급여합계:' + convert(varchar(100), @n_pay_tot_amt) + '<==' + convert(varchar(100), sysdatetime())
		END

        -- ***************************************      
        -- 2. 1년치 정기상여 조회      
        -- ***************************************      
        SET @v_base_pay_ym = NULL      
        SET @d_bns_s_ymd = NULL      
        SET @d_bns_e_ymd = NULL      
		SET @n_bns_cal_mon = 0      
        SET @n_rep_id = NULL
		SET @n_bns_cnt = 1
		--SET @n_bns_roop_cnt = 12
		
		-- 상여 기간설정
		BEGIN
		   IF (@av_company_cd = 'A' AND @v_emp_cls_cd = 'A')
              BEGIN
			     -- 상여계산시작일
                 SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_pay_end_ymd, -12)     -- DateAndTime.DateAdd("m", -12, str_t_pay_date_tmp);
                 -- 상여계산종료일
                 SET @d_bns_e_ymd = dbo.XF_MONTHADD(@d_pay_end_ymd, -1)      -- DateAndTime.DateAdd("m", -1, str_t_pay_date_tmp);
			  END
           ELSE IF (@av_company_cd = 'I' ) -- 산업상여는 전월부터 12개월
		      BEGIN
			     -- 산업 관리구분 수산/유통 A,물류8, 생산B, 선원C
                 IF (@v_mgr_type_cd = 'A' OR @v_mgr_type_cd = '8')
                    BEGIN
                       -- 상여계산시작일
                       SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_pay_end_ymd, -12) -- DateAndTime.DateAdd("m", -12, str_t_pay_date_tmp);
                       -- 상여계산종료일
                       SET @d_bns_e_ymd = dbo.XF_MONTHADD(@d_pay_end_ymd, -1)  -- DateAndTime.DateAdd("m", -1, str_t_pay_date_tmp);
                    END
                 ELSE
                    BEGIN
                       -- 상여계산시작일
                       SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_pay_end_ymd, -11) -- DateAndTime.DateAdd("m", -11, str_t_pay_date_tmp);
                       -- 상여계산종료일
                       SET @d_bns_e_ymd = @d_pay_end_ymd						-- dte_t_bonus_date.ToString("yyyyMMdd");
                    END
			  END
           ELSE
              BEGIN
			     -- 상여계산시작일
                 SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_pay_end_ymd, -11)		-- DateAndTime.DateAdd("m", -11, str_t_pay_date_tmp);
                 -- 상여계산종료일
				 SET @d_bns_e_ymd = @d_pay_end_ymd								-- str_t_pay_date.Replace("-", "");
			  END
		END

        BEGIN        
            DECLARE sbpay CURSOR FOR      
        --        SELECT BASE_YM      
        --           FROM (SELECT BASE_YM    
        --                    -- , ROW_NUMBER() OVER (ORDER BY BASE_YM DESC) AS ROWNUM     
        --                  FROM (SELECT DISTINCT A.PAY_YM AS BASE_YM  
        --                          FROM PAY_PAY_YMD A      
        --                               INNER JOIN PAY_PAYROLL B      
								--			   ON B.PAY_YMD_ID = A.PAY_YMD_ID      
        --                               INNER JOIN PAY_PAYROLL_DETAIL C     
        --                                       ON C.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID     
        --                         WHERE B.EMP_ID = @n_emp_id      
        --                           AND C.CAL_MON > 0   
        --                           AND C.PAY_ITEM_CD IN (SELECT KEY_CD3 AS PAY_ITEM_CD  
					   --                                    FROM FRM_UNIT_STD_HIS  
					   --                                   WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
								--				                                         FROM FRM_UNIT_STD_MGR  
								--				                                        WHERE COMPANY_CD = @av_company_cd  
								--					                                      AND UNIT_CD = 'REP'  
								--					                                      AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END)  
					   --                                     AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
					   --                                     AND KEY_CD1 = '20')      
        --                           AND A.CLOSE_YN = 'Y'  
								--   AND A.PAY_YN = 'Y'
								--   AND B.PSUM > 0
								--   --AND A.PAY_YM BETWEEN dbo.XF_TO_CHAR_D(@d_bns_s_ymd,'YYYYMM') AND dbo.XF_TO_CHAR_D(@d_bns_e_ymd, 'YYYYMM')   
								--   AND A.PAY_YM BETWEEN FORMAT(@d_bns_s_ymd, 'yyyyMM') AND FORMAT(@d_bns_e_ymd, 'yyyyMM')
							 --  ) C3
							 --) C4               
        --         ORDER BY BASE_YM DESC      
		SELECT BEL_PAY_YM AS BASE_YM, A.CAL_MON --@n_cal_mon             -- 금액  										
							FROM (
								SELECT B.BEL_PAY_YM, SUM(dbo.XF_NVL_N(CAL_MON,0)) AS CAL_MON
								FROM PAY_PAYROLL A
									INNER JOIN PAY_PAY_YMD C 
										ON A.PAY_YMD_ID = C.PAY_YMD_ID
									INNER JOIN PAY_PAYROLL_DETAIL B
										ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
									INNER JOIN (
										SELECT PAY_TYPE_CD, PAY_ITEM_CD
											FROM (
												SELECT CD PAY_TYPE_CD, SYS_CD
													FROM FRM_CODE
												WHERE COMPANY_CD = @av_company_cd
													AND CD_KIND = 'PAY_TYPE_CD'
													AND SYS_CD != '100' -- 시뮬레이션제외
												) A
											INNER JOIN (
														SELECT KEY_CD2 PAY_ITEM_SYS_CD, KEY_CD3 AS PAY_ITEM_CD  
															FROM FRM_UNIT_STD_HIS  
															WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																						FROM FRM_UNIT_STD_MGR  
																						WHERE COMPANY_CD = @av_company_cd  
																							AND UNIT_CD = 'REP'  
											  												AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
															AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
															AND KEY_CD1 = '20'  
												) B
												ON (A.SYS_CD = B.PAY_ITEM_SYS_CD)-- OR B.PAY_ITEM_SYS_CD IS NULL)
											) T1
										ON C.PAY_TYPE_CD = T1.PAY_TYPE_CD
										AND B.PAY_ITEM_CD = T1.PAY_ITEM_CD
									WHERE C.CLOSE_YN = 'Y'
									AND C.PAY_YN = 'Y'
									--AND B.BEL_PAY_YM = @v_base_bns_ym  
									AND B.BEL_PAY_YM BETWEEN FORMAT(@d_bns_s_ymd, 'yyyyMM') AND FORMAT(@d_bns_e_ymd, 'yyyyMM')
									AND C.COMPANY_CD = @av_company_cd 
									AND A.EMP_ID = @n_emp_id
									GROUP BY B.BEL_PAY_YM
									) A
								--WHERE CAL_MON <> 0
								ORDER BY BEL_PAY_YM DESC
            OPEN sbpay      
                FETCH NEXT FROM sbpay INTO @v_base_bns_ym, @n_bns_cal_mon    
                WHILE (@@FETCH_STATUS = 0)      

                    BEGIN -- 커서루프  
                        -- ***************************************      
                        -- 2-1. 임금항목 저장      
                        -- *************************************** 
						--SET @n_base_cnt  = dbo.XF_DATEDIFF(dbo.XF_LAST_DAY(dbo.XF_TO_DATE(@v_base_pay_ym+'01', 'YYYYMMDD')), dbo.XF_TO_DATE(@v_base_pay_ym+'01', 'YYYYMMDD')) + 1
						-- 사용안함 @n_base_cnt -- 
						--SET @n_base_cnt = DATEPART(DD, EOMONTH(@v_base_pay_ym+'01'))
						--SET @n_bns_cal_mon = 0
print '상여:@v_base_ym=' + convert(varchar(100),@v_base_bns_ym) + '<==' + convert(varchar(100), sysdatetime())
/*
						BEGIN
							SELECT @n_bns_cal_mon = A.CAL_MON --@n_cal_mon             -- 금액  										
							FROM (
								SELECT SUM(dbo.XF_NVL_N(CAL_MON,0)) AS CAL_MON
								FROM PAY_PAYROLL A
									INNER JOIN PAY_PAY_YMD C 
										ON A.PAY_YMD_ID = C.PAY_YMD_ID
									INNER JOIN PAY_PAYROLL_DETAIL B
										ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
									INNER JOIN (
										SELECT PAY_TYPE_CD, PAY_ITEM_CD
											FROM (
												SELECT CD PAY_TYPE_CD, SYS_CD
													FROM FRM_CODE
												WHERE COMPANY_CD = @av_company_cd
													AND CD_KIND = 'PAY_TYPE_CD'
													AND SYS_CD != '100' -- 시뮬레이션제외
												) A
											INNER JOIN (
														SELECT KEY_CD2 PAY_ITEM_SYS_CD, KEY_CD3 AS PAY_ITEM_CD  
															FROM FRM_UNIT_STD_HIS  
															WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																						FROM FRM_UNIT_STD_MGR  
																						WHERE COMPANY_CD = @av_company_cd  
																							AND UNIT_CD = 'REP'  
											  												AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
															AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
															AND KEY_CD1 = '20'  
												) B
												ON (A.SYS_CD = B.PAY_ITEM_SYS_CD OR B.PAY_ITEM_SYS_CD IS NULL)
											) T1
										ON C.PAY_TYPE_CD = T1.PAY_TYPE_CD
										AND B.PAY_ITEM_CD = T1.PAY_ITEM_CD
									WHERE C.CLOSE_YN = 'Y'
									AND C.PAY_YN = 'Y'
									AND B.BEL_PAY_YM = @v_base_bns_ym  
									AND C.COMPANY_CD = @av_company_cd 
									AND A.EMP_ID = @n_emp_id
									) A
								WHERE CAL_MON <> 0
						END
						*/
                        -- ***************************************      
                        -- 2-2. 기준임금 저장      
                        -- ***************************************      

						    BEGIN
							   IF @n_bns_cnt = 1 
							      BEGIN
								     SET @v_bonus01_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus01_amt = @n_bns_cal_mon	-- 상여금액_01
								  END							   
							   ELSE IF @n_bns_cnt = 2 
							      BEGIN
								     SET @v_bonus02_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus02_amt = @n_bns_cal_mon	-- 상여금액_01
								  END							   
							   ELSE IF @n_bns_cnt = 3
							      BEGIN
								     SET @v_bonus03_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus03_amt = @n_bns_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 4
							      BEGIN
								     SET @v_bonus04_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus04_amt = @n_bns_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 5
							      BEGIN
								     SET @v_bonus05_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus05_amt = @n_bns_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 6 
							      BEGIN
								     SET @v_bonus06_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus06_amt = @n_bns_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 7
							      BEGIN
								     SET @v_bonus07_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus07_amt = @n_bns_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 8
							      BEGIN
								     SET @v_bonus08_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus08_amt = @n_bns_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 9
							      BEGIN
								     SET @v_bonus09_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus09_amt = @n_bns_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 10
							      BEGIN
								     SET @v_bonus10_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus10_amt = @n_bns_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 11
							      BEGIN
								     SET @v_bonus11_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus11_amt = @n_bns_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 12
							      BEGIN
								     SET @v_bonus12_ym = @v_base_bns_ym			-- 상여년월_01
		                             SET @n_bonus12_amt = @n_bns_cal_mon	-- 상여금액_01
								  END	
							END
						     

						BEGIN 										
						   SET @n_bns_cnt = @n_bns_cnt + 1  -- 순차 증가처리
						END		
    
                        FETCH NEXT FROM sbpay INTO @v_base_bns_ym  , @n_bns_cal_mon     
                    END         -- 커서루프 종료     

            CLOSE sbpay         -- 커서닫기      
            DEALLOCATE sbpay    -- 커서 할당해제      
        END                     -- 커서종료      

		-- 상여합계적용
		BEGIN
		   SET @n_bonus_mon = ISNULL(@n_bonus01_amt,0) + ISNULL(@n_bonus02_amt,0) + ISNULL(@n_bonus03_amt,0) + ISNULL(@n_bonus04_amt,0)	 + ISNULL(@n_bonus05_amt, 0) +  
		   					  ISNULL(@n_bonus06_amt,0) + ISNULL(@n_bonus07_amt,0) + ISNULL(@n_bonus08_amt,0) + ISNULL(@n_bonus09_amt,0)	 + ISNULL(@n_bonus10_amt, 0)	-- 상여합계	
		END
--PRINT(' @n_bef_ret_year ===> ' + CONVERT(VARCHAR, @n_bef_ret_year) )
print '상여합계적용:' + convert(varchar(100), @n_bonus_mon)
PRINT '상여:' + FORMAT(SYSDATETIME(), 'HH:mm:ss.fffff')
        -- ***************************************      
        -- 3. 1년치 연차 조회      
        -- ***************************************      
        SET @v_base_pay_ym = NULL
		SET @n_bef_ret_year = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_end_ymd, 'YYYY')) - 1
        SET @d_day_s_ymd = dbo.XF_TO_DATE(CONVERT(VARCHAR, @n_bef_ret_year) + dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_end_ymd,'YYYYMMDD'),5,2) + dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_end_ymd,'YYYYMMDD'),7,2), 'YYYYMMDD')
        SET @d_day_e_ymd = @d_end_ymd      
        SET @n_yun_cal_mon = 0      
        SET @n_rep_id = NULL   
		PRINT'연차:' + FORMAT(@d_day_s_ymd,'yyyyMMdd') + '~' + format(@d_end_ymd, 'yyyyMMdd')
		SELECT TOP 1 @n_yun_cal_mon = A.CAL_MON --@n_cal_mon             -- 금액  										
							FROM (
								SELECT BEL_PAY_YM, SUM(dbo.XF_NVL_N(CAL_MON,0)) AS CAL_MON
								FROM PAY_PAYROLL A
									INNER JOIN PAY_PAY_YMD C 
										ON A.PAY_YMD_ID = C.PAY_YMD_ID
									INNER JOIN PAY_PAYROLL_DETAIL B
										ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
									INNER JOIN (
										SELECT PAY_TYPE_CD, PAY_ITEM_CD
											FROM (
												SELECT CD PAY_TYPE_CD, SYS_CD
													FROM FRM_CODE
												WHERE COMPANY_CD = @av_company_cd
													AND CD_KIND = 'PAY_TYPE_CD'
													AND SYS_CD != '100' -- 시뮬레이션제외
												) A
											INNER JOIN (
														SELECT KEY_CD2 PAY_ITEM_SYS_CD, KEY_CD3 AS PAY_ITEM_CD  
															FROM FRM_UNIT_STD_HIS  
															WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
																						FROM FRM_UNIT_STD_MGR  
																						WHERE COMPANY_CD = @av_company_cd  
																							AND UNIT_CD = 'REP'  
											  												AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
															--AND @d_retire_ymd BETWEEN STA_YMD AND END_YMD  
															AND @d_end_ymd BETWEEN STA_YMD AND END_YMD
															AND KEY_CD1 = '30'  
												) B
												ON (A.SYS_CD = B.PAY_ITEM_SYS_CD)-- OR B.PAY_ITEM_SYS_CD IS NULL)
											) T1
										ON C.PAY_TYPE_CD = T1.PAY_TYPE_CD
										AND B.PAY_ITEM_CD = T1.PAY_ITEM_CD
									WHERE C.CLOSE_YN = 'Y'
									AND C.PAY_YN = 'Y'
									--AND B.BEL_PAY_YM = @v_base_yun_ym  
								   AND B.BEL_PAY_YM >= FORMAT(@d_day_s_ymd, 'yyyyMM') -- dbo.XF_TO_CHAR_D(@d_day_s_ymd,'YYYYMM') 
								   AND B.BEL_PAY_YM < FORMAT(@d_day_e_ymd, 'yyyyMM') --dbo.XF_TO_CHAR_D(@d_day_e_ymd, 'YYYYMM')   
									AND C.COMPANY_CD = @av_company_cd 
									AND A.EMP_ID = @n_emp_id
									GROUP BY BEL_PAY_YM
									) A
								WHERE CAL_MON <> 0
								ORDER BY BEL_PAY_YM DESC
			SET @n_day_tot_amt = @n_yun_cal_mon		-- 연월차총액
      --  BEGIN   
      --      DECLARE dtm CURSOR FOR 
      --          SELECT BASE_YM      
      --            FROM (SELECT BASE_YM      
      --                       --, STA_YMD      
      --                       --, END_YMD      
      --                       --, dbo.XF_DATEDIFF(END_YMD, STA_YMD)+1 AS BASE_DAY     
      --                       --, ROW_NUMBER() OVER (ORDER BY BASE_YM DESC) AS ROWNUM     
      --                    FROM (SELECT DISTINCT A.PAY_YM AS BASE_YM      
      --                                        , A.STA_YMD      
      --                                        , A.END_YMD      
      --                            FROM PAY_PAY_YMD A      
      --                                 INNER JOIN PAY_PAYROLL B      
      --                                                     ON B.PAY_YMD_ID = A.PAY_YMD_ID      
      --                                 INNER JOIN PAY_PAYROLL_DETAIL C     
      --                                                            ON C.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID     
      --                           WHERE B.EMP_ID = @n_emp_id      
      --                             AND C.CAL_MON > 0   
      --                             AND C.PAY_ITEM_CD IN (SELECT KEY_CD3 AS PAY_ITEM_CD  
					 --                                      FROM FRM_UNIT_STD_HIS  
					 --                                     WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
						--						                                         FROM FRM_UNIT_STD_MGR  
						--						                                        WHERE COMPANY_CD = @av_company_cd  
						--							                                      AND UNIT_CD = 'REP'  
						--							                                      AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END)  
					 --                                       AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
					 --                                       AND KEY_CD1 = '30')      
      --                             AND A.CLOSE_YN = 'Y'  
						--		   AND A.PAY_YN = 'Y'
						--		   AND A.PAY_YM >= FORMAT(@d_day_s_ymd, 'yyyyMM') -- dbo.XF_TO_CHAR_D(@d_day_s_ymd,'YYYYMM') 
						--		   AND A.PAY_YM < FORMAT(@d_day_e_ymd, 'yyyyMM') --dbo.XF_TO_CHAR_D(@d_day_e_ymd, 'YYYYMM')   
      --                             ) C3 
						--	) C4               
      --           ORDER BY BASE_YM ASC   			
        
      --      OPEN dtm      
      --          FETCH NEXT FROM dtm INTO @v_base_yun_ym
      --          WHILE (@@FETCH_STATUS = 0)      
      --              BEGIN      
      --                  -- ***************************************      
      --                  -- 3-1. 연차 임금항목 저장      
      --                  -- ***************************************     
						--BEGIN
						--	SELECT @n_yun_cal_mon = A.CAL_MON --@n_cal_mon             -- 금액  										
						--	FROM (
						--		SELECT SUM(dbo.XF_NVL_N(CAL_MON,0)) AS CAL_MON
						--		FROM PAY_PAYROLL A
						--			INNER JOIN PAY_PAY_YMD C 
						--				ON A.PAY_YMD_ID = C.PAY_YMD_ID
						--			INNER JOIN PAY_PAYROLL_DETAIL B
						--				ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID 
						--			INNER JOIN (
						--				SELECT PAY_TYPE_CD, PAY_ITEM_CD
						--					FROM (
						--						SELECT CD PAY_TYPE_CD, SYS_CD
						--							FROM FRM_CODE
						--						WHERE COMPANY_CD = @av_company_cd
						--							AND CD_KIND = 'PAY_TYPE_CD'
						--							AND SYS_CD != '100' -- 시뮬레이션제외
						--						) A
						--					INNER JOIN (
						--								SELECT KEY_CD2 PAY_ITEM_SYS_CD, KEY_CD3 AS PAY_ITEM_CD  
						--									FROM FRM_UNIT_STD_HIS  
						--									WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
						--																FROM FRM_UNIT_STD_MGR  
						--																WHERE COMPANY_CD = @av_company_cd  
						--																	AND UNIT_CD = 'REP'  
						--					  												AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END )  
						--									--AND @d_retire_ymd BETWEEN STA_YMD AND END_YMD  
						--									AND @d_end_ymd BETWEEN STA_YMD AND END_YMD
						--									AND KEY_CD1 = '30'  
						--						) B
						--						ON (A.SYS_CD = B.PAY_ITEM_SYS_CD OR B.PAY_ITEM_SYS_CD IS NULL)
						--					) T1
						--				ON C.PAY_TYPE_CD = T1.PAY_TYPE_CD
						--				AND B.PAY_ITEM_CD = T1.PAY_ITEM_CD
						--			WHERE C.CLOSE_YN = 'Y'
						--			AND C.PAY_YN = 'Y'
						--			AND B.BEL_PAY_YM = @v_base_yun_ym  
						--			AND C.COMPANY_CD = @av_company_cd 
						--			AND A.EMP_ID = @n_emp_id
						--			) A
						--		WHERE CAL_MON <> 0
						--END

			
      --                  -- ***************************************      
      --                  -- 3-2. 기준임금 저장      
      --                  -- ***************************************      
 					--    -- 연월차수당
						--BEGIN
						--   SET @n_day_tot_amt = @n_yun_cal_mon		-- 연월차총액
						--END 
   
      --                  FETCH NEXT FROM dtm INTO @v_base_yun_ym 
      --              END     -- 커서루프 종료  
      --      CLOSE dtm       -- 커서닫기      
      --      DEALLOCATE dtm  -- 커서 할당해제      
      --  END -- 커서종료  
PRINT '연차금액:' + CONVERT(VARCHAR(100), @n_yun_cal_mon) + ' -> ' + FORMAT(SYSDATETIME(), 'HH:mm:ss.fffff')
        -- ***************************************   
        -- 4. 3개월급여, 12개월상여 연차 저장   
        -- ***************************************   
        BEGIN   
            UPDATE REP_CALC_LIST            -- 퇴직금계산대상자(내역)  
               SET RETIRE_YMD			= @d_retire_ymd			-- 퇴직일자
			     , SUM_STA_YMD			= C1_STA_YMD			-- 정산 기산일
		         , FLAG					= @v_flag_yn			-- 1년미만
			     , AMT_RATE_ADD			= @n_add_rate			-- 임원누진율(지급배수)
			     , PAY01_YM				= @v_pay01_ym			-- 급여년월_01
				 , PAY02_YM				= @v_pay02_ym			-- 급여년월_02
				 , PAY03_YM				= @v_pay03_ym			-- 급여년월_03
				 , PAY04_YM				= @v_pay04_ym			-- 급여년월_04
				 , PAY01_AMT			= @n_pay01_amt			-- 급여금액_01
				 , PAY02_AMT			= @n_pay02_amt			-- 급여금액_02
				 , PAY03_AMT			= @n_pay03_amt			-- 급여금액_03
				 , PAY04_AMT			= @n_pay04_amt			-- 급여금액_04
				 , PAY_MON				= @n_pay_mon			-- 급여합계
				 , PAY_TOT_AMT			= @n_pay_tot_amt		-- 3개월급여합계
				 , BONUS01_YM			= @v_bonus01_ym			-- 상여년월_01
				 , BONUS02_YM			= @v_bonus02_ym			-- 상여년월_02
				 , BONUS03_YM			= @v_bonus03_ym			-- 상여년월_03
				 , BONUS04_YM			= @v_bonus04_ym			-- 상여년월_04
				 , BONUS05_YM			= @v_bonus05_ym			-- 상여년월_05
				 , BONUS06_YM			= @v_bonus06_ym			-- 상여년월_06
				 , BONUS07_YM			= @v_bonus07_ym			-- 상여년월_07
				 , BONUS08_YM			= @v_bonus08_ym			-- 상여년월_08
				 , BONUS09_YM			= @v_bonus09_ym			-- 상여년월_09
				 , BONUS10_YM			= @v_bonus10_ym			-- 상여년월_10
				 , BONUS11_YM			= @v_bonus11_ym			-- 상여년월_11
				 , BONUS12_YM			= @v_bonus12_ym			-- 상여년월_12
				 , BONUS01_AMT			= @n_bonus01_amt		-- 상여금액_01
				 , BONUS02_AMT			= @n_bonus02_amt		-- 상여금액_02
				 , BONUS03_AMT			= @n_bonus03_amt		-- 상여금액_03
				 , BONUS04_AMT			= @n_bonus04_amt		-- 상여금액_04
				 , BONUS05_AMT			= @n_bonus05_amt		-- 상여금액_05
				 , BONUS06_AMT			= @n_bonus06_amt		-- 상여금액_06
				 , BONUS07_AMT			= @n_bonus07_amt		-- 상여금액_07
				 , BONUS08_AMT			= @n_bonus08_amt		-- 상여금액_08
				 , BONUS09_AMT			= @n_bonus09_amt		-- 상여금액_09
				 , BONUS10_AMT			= @n_bonus10_amt		-- 상여금액_10
				 , BONUS11_AMT			= @n_bonus11_amt		-- 상여금액_11
				 , BONUS12_AMT			= @n_bonus12_amt		-- 상여금액_12
				 , BONUS_MON			= @n_bonus_mon			-- 상여총액
				 , YEAR_MONTH_AMT		= @n_day_tot_amt		-- 연월차총액
				 , ETC01_SUB_NM         = '퇴직전환금'			-- 기타공제1 제목 
				 , ETC02_SUB_NM         = '고용보험'			-- 기타공제2 제목
				 , ETC03_SUB_NM         = '건강보험'			-- 기타공제3 제목
				 , ETC01_SUB_AMT		= dbo.XF_NVL_N(@n_retire_turn_mon, 0) -- 기타공제1 금액
                 , MOD_USER_ID			= @an_mod_user_id		-- 변경자   
                 , MOD_DATE				= dbo.XF_SYSDATE(0)		-- 변경일시   
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
    -- ***********************************************************      
    -- 작업 완료      
    -- ***********************************************************      
    SET @av_ret_code    = 'SUCCESS!'      
    SET @av_ret_message = dbo.F_FRM_ERRMSG('기초자료 생성이 완료되었습니다[ERR]', @v_program_id, 9999, null, @an_mod_user_id)      
      
END
USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_CAL_PAY_STD]    Script Date: 2021-02-02 오후 6:19:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_CAL_PAY_STD] (      
       @av_company_cd                 NVARCHAR(10),             -- 인사영역      
       @av_locale_cd                  NVARCHAR(10),             -- 지역코드      
       @an_rep_calc_list_id_list      NUMERIC(38),				-- 퇴직금대상ID      
       @an_mod_user_id                NUMERIC(38),				-- 변경자 사번      
       @av_ret_code                   NVARCHAR(4000)    OUTPUT, -- 결과코드*/      
       @av_ret_message                NVARCHAR(4000)    OUTPUT  -- 결과메시지*/      
    ) AS      
    -- ***************************************************************************      
    --   TITLE       : 퇴직금 기준임금관리/임금항목관리      
    --   PROJECT     : HR 시스템      
    --   AUTHOR      :      
    --   PROGRAM_ID  : P_REP_CAL_PAY_STD      
    --   RETURN      : 1) SUCCESS!/FAILURE!      
    --                 2) 결과 메시지      
    --   COMMENT     : 퇴직금기준임금정보/임금항목정보 insert      
    --   HISTORY     : 작성 정순보 2006.09.18      
    --               : 수정 박근한 2009.01.16       
    --               : 2016.06.23 Modified by 최성용 in KBpharma      
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
		  , @n_retire_turn_mon		   NUMERIC(15)				-- 국민연금퇴직전환금
		  , @v_rep_mid_yn			   NVARCHAR(6)				-- 중간정산여부
		  , @v_officers_yn			   NVARCHAR(1)				-- 임원여부
		  , @n_add_rate				   NUMERIC(5,2)				-- 누진율
		  , @n_org_id				   NUMERIC(38)				-- 조직ID
		  , @v_org_nm				   NVARCHAR(100)			-- 조직명
		  , @v_org_line                NVARCHAR(1000)			-- 조직라인
		  , @v_pos_cd				   NVARCHAR(50)				-- 직위
		  , @v_pos_grd_cd			   NVARCHAR(50)				-- 직급
		  , @v_yearnum_cd			   NVARCHAR(50)				-- 호봉
		  , @v_pay_group			   NVARCHAR(50)				-- 급여그룹
          , @n_std_cnt                 NUMERIC                  -- 기준금관리 조회수 
		  ,	@v_biz_cd				   NVARCHAR(50)				-- 사업장
		  , @v_reg_biz_cd			   NVARCHAR(50)				-- 신고사업장 
		  , @v_mgr_type_cd			   NVARCHAR(30)				-- 관리구분코드[PHM_MGR_TYPE_CD]
		  , @v_pay_meth_cd			   NVARCHAR(50)				-- 급여지급방식코드[PAY_METH_CD]
		  ,	@v_emp_cls_cd			   NVARCHAR(50)				-- 고용유형코드[PAY_EMP_CLS_CD]
		  ,	@v_ins_type_yn			   NVARCHAR(1)				-- 퇴직연금가입여부
		  ,	@v_ins_type_cd			   NVARCHAR(10)				-- 퇴직연금구분
		  ,	@v_ins_nm				   NVARCHAR(80)				-- 퇴직연금사업자명
		  ,	@v_ins_bank_cd			   NVARCHAR(80)				-- 퇴직연금은행코드
		  ,	@v_ins_bizno			   NVARCHAR(50)				-- 퇴직연금사업장등록번호
		  ,	@v_ins_account_no		   NVARCHAR(150)			-- 퇴직연금계좌번호
          , @n_rep_id                  NUMERIC(38)				-- 대상금액 입력ID(Sequence)
          , @an_return_cal_mon         NUMERIC(38)				-- 평균임금 적용대상 기준금액
          , @d_end_ymd                 DATETIME2				-- 주(현)정산일 - 퇴직일
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
    SET @v_program_id    = 'P_REP_CAL_PAY_STD'   -- 현재 프로시져의 영문명      
    SET @v_program_nm    = '퇴직금 기준임금관리/임금항목관리'        -- 현재 프로시져의 한글문명      
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
        -- ***************************************      
        -- 2. 기존 임금항목 삭제      
        -- ***************************************      
        BEGIN      
            DELETE A
			  FROM REP_PAYROLL_DETAIL A
			  JOIN REP_PAY_STD B
			    ON A.REP_PAY_STD_ID = B.REP_PAY_STD_ID
             WHERE B.REP_CALC_LIST_ID = @n_rep_calc_list_id_list
            IF @ERRCODE != 0      
                 BEGIN      
				   SET @av_ret_code    = 'FAILURE!'      
                   SET @av_ret_message = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') 기준임금항목관리 삭제시 에러발생[ERR]', @v_program_id, 0020, null, @an_mod_user_id)       
                   RETURN      
                 END      
        END      
        -- ***************************************      
        -- 3. 기존 기준임금관리 삭제      
        -- ***************************************      
        BEGIN      
            DELETE FROM REP_PAY_STD      
             WHERE REP_CALC_LIST_ID = @n_rep_calc_list_id_list      
            IF @ERRCODE != 0      
                BEGIN      
                  SET @av_ret_code    = 'FAILURE!'      
                  SET @av_ret_message = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') 기준임금관리 삭제시 에러발생[ERR]', @v_program_id, 0030, null, @an_mod_user_id)       
                  RETURN      
                END      
        END 

	
		-- *************************************** 
		-- 기본사항 설정 및 기타공제 Title 입력
		-- ***************************************
---------------------------------------------------------------------------------------------------------------------------------
		BEGIN
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

-----------------------------------------------------------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------------------------------------------------------------------------
			-- 사업장 
			SET @v_biz_cd = dbo.F_ORM_ORG_BIZ(@n_org_id, @d_end_ymd, 'PAY')
			SET @v_biz_cd = ISNULL( @v_biz_cd, '001' )

			-- 신고사업장 
			SET @v_reg_biz_cd = dbo.F_ORM_ORG_BIZ(@n_org_id, @d_end_ymd, 'REG')
			SET @v_reg_biz_cd = ISNULL(@v_reg_biz_cd, '001')

			-- 퇴직연금가입여부, 퇴직연금구분
			SET @v_ins_type_yn = 'N'
			SET @v_ins_type_cd = NULL
			SET @v_ins_nm = NULL
			SET @v_ins_bizno = NULL
			SET @v_ins_account_no = NULL

			BEGIN 
				SELECT @v_ins_type_yn = CASE WHEN INS_TYPE_CD IN ('10', '20') THEN 'Y' ELSE 'N' END
					  ,@v_ins_type_cd = INS_TYPE_CD
					  ,@v_ins_nm = INSUR_NM
					  ,@v_ins_bank_cd = IRP_BANK_CD
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

			-- 재직여부
			BEGIN
			   SELECT @v_in_offi_yn = IN_OFFI_YN
					 ,@d_retire_ymd = ISNULL(RETIRE_YMD, @d_end_ymd)
				 FROM PHM_EMP
				WHERE EMP_ID = @n_emp_id 
			END
-----------------------------------------------------------------------------------------------------------------------------------

		END

        -- ***************************************      
        -- 4. 3개월치 급여 조회      
        -- ***************************************      
        BEGIN  
		    SET @d_last_retire_date = dbo.XF_LAST_DAY(@d_end_ymd) -- 퇴직월 말일자
            SET @n_roop_cnt = CASE WHEN @d_end_ymd = dbo.XF_LAST_DAY(@d_end_ymd) THEN 3 ELSE 4 END     
            SET @n_pay_cnt = 1     
            SET @n_real_cnt_tmp  = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_end_ymd, 'DD')) -- 퇴직월 일자 			
			
            DECLARE rep CURSOR FOR      
                SELECT DISTINCT A.PAY_YM AS BASE_YM      
                  FROM PAY_PAY_YMD A      
                       INNER JOIN PAY_PAYROLL B      
                           ON B.PAY_YMD_ID = A.PAY_YMD_ID 
                 WHERE B.EMP_ID = @n_emp_id      
                   AND A.CLOSE_YN = 'Y' 
				   AND A.PAY_YN = 'Y'
                   AND A.PAY_YM <= FORMAT(@d_end_ymd, 'yyyyMM') -- dbo.XF_TO_CHAR_D(@d_end_ymd, 'YYYYMM')      
                   AND A.PAY_YM NOT IN (SELECT Y.BASE_YM      
                                          FROM (SELECT dbo.XF_TO_CHAR_D(T.STA_YMD, 'YYYYMM') AS STA_YM     
                                                     , dbo.XF_TO_CHAR_D(T.END_YMD, 'YYYYMM') AS END_YM      
                                                  FROM (SELECT STA_YMD      
                                                             , END_YMD      
                                                          FROM CAM_TERM_MGR      
                                                         WHERE ITEM_NM = 'LEAVE_CD'      
                                                           AND VALUE IN (SELECT CD      
                                                                           FROM FRM_CODE      
                                                                          WHERE CD_KIND = 'REP_EXCE_TYPE_CD'        
                                                                            AND LOCALE_CD = @av_locale_cd      
                                                                            AND COMPANY_CD = @av_company_cd      
                                                                            AND @d_end_ymd BETWEEN STA_YMD AND END_YMD)      
                                                           AND EMP_ID = @n_emp_id) T) X      
                                               INNER JOIN (SELECT DISTINCT BASE_YM      
                                                             FROM (SELECT dbo.XF_TO_CHAR_D(YMD, 'YYYYMM') AS BASE_YM      
                                                                     FROM HPS_CALENDAR      
                                                                    WHERE COMPANY_CD = @av_company_cd      
                                                                      AND YMD <= @d_end_ymd) B1) Y      
                                                      ON Y.BASE_YM BETWEEN X.STA_YM AND X.END_YM )      
                 ORDER BY A.PAY_YM DESC  
            OPEN rep      
                FETCH NEXT FROM rep INTO @v_base_pay_ym     
                WHILE (@@FETCH_STATUS = 0 AND @n_roop_cnt >= @n_pay_cnt)      
                    BEGIN -- 커서루프      
                        -- ***************************************      
                        -- 4-1. 기준항목 시퀀스 채번      
                        -- ***************************************  
				
                        BEGIN      
                           SELECT @n_rep_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE      
                              FROM DUAL      
                        END      
                        -- ***************************************      
                        -- 4-2. 날짜, 일수 세팅      
                        -- ***************************************  

                        BEGIN     
                            IF @n_pay_cnt = 1 AND @v_base_pay_ym <> dbo.XF_TO_CHAR_D(@d_end_ymd, 'YYYYMM')     
                                BEGIN     
                                    SET @n_roop_cnt = 3     
                                END     

                            SET @d_base_s_ymd = CASE WHEN @n_roop_cnt = @n_pay_cnt THEN dbo.XF_TO_DATE(@v_base_pay_ym + dbo.XF_TO_CHAR_D(dbo.XF_DATEADD(dbo.XF_MONTHADD(@d_end_ymd, -3), 1),'DD'),'YYYYMMDD')    
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
							
							-- 동원그룹 산정기준
							SET @n_base_cnt = 30
							SET @n_real_cnt = 30

							IF (@d_last_retire_date != @d_end_ymd)               -- 말일자 퇴직이 아니면
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
										           BEGIN
												      IF (@v_mgr_type_cd = 'B' AND @n_real_cnt_tmp >= 20)
													     BEGIN
                                                            SET @n_real_cnt = 0
														    SET @n_base_cnt = 0
														 END
                                                      ELSE IF (@v_mgr_type_cd <> 'B' AND @n_real_cnt_tmp >= 30)
													     BEGIN
                                                            SET @n_real_cnt = 0
														    SET @n_base_cnt = 0
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
                        -- 4-2. 임금항목 저장      
                        -- ***************************************  

						-- 선원은 해당 LOGIC 반영하지 않음
						SET @an_return_cal_mon = 0

						BEGIN
							IF @v_emp_cls_cd <> 'S'
								BEGIN      
									--print 'P_REP_CAL_PAY_DETAIL 1 START ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')
									EXEC dbo.P_REP_CAL_PAY_DETAIL @av_company_cd      
																, @n_rep_calc_list_id_list      
																, @n_rep_id      
																, @v_base_pay_ym      
																, '10'                          -- 급여      
																, @n_base_cnt                   -- 기준일수      
																, @n_real_cnt                   -- 실일수      
																, 'Y'                           -- 일할계산여부      
																, @an_mod_user_id      
																, @an_return_cal_mon output      
																, @av_ret_code output      
																, @av_ret_message output      
									--print 'P_REP_CAL_PAY_DETAIL 1 END ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')
									IF @av_ret_code = 'FAILURE!'      
										BEGIN      
											SET @av_ret_code     = 'FAILURE!'      
											SET @av_ret_message  = @av_ret_message      
											CLOSE rep       -- 커서닫기      
											DEALLOCATE rep  -- 커서 할당해제      
											RETURN      
										END      
								END    
						END

                        -- ***************************************      
                        -- 4-3. 기준임금 저장      
                        -- ***************************************      
                        IF @an_return_cal_mon <> 0                                      -- 금액이 있는경우      
                           BEGIN  
				        
                                INSERT INTO REP_PAY_STD                                 -- 퇴직금기준 임금 관리      
                                          ( REP_PAY_STD_ID                              -- 퇴직금기준 임금 관리ID      
                                          , REP_CALC_LIST_ID                            -- 퇴직금대상ID      
                                          , PAY_TYPE_CD                                 -- 급여지급구분[PAY_TYPE_CD]      
                                          , PAY_YM                                      -- 급여년월      
                                          , SEQ                                         -- 순서      
                                          , STA_YMD                                     -- 시작일자      
                                          , END_YMD                                     -- 종료일자      
                                          , BASE_DAY                                    -- 기준일수      
                                          , MINUS_DAY                                   -- 차감일수      
                                          , REAL_DAY                                    -- 대상일수      
                                          , MOD_USER_ID                                 -- 변경자      
                                          , MOD_DATE                                    -- 변경일시      
                                          , TZ_CD                                       -- 타임존코드      
                                          , TZ_DATE)                                    -- 타임존일시      
                                    VALUES( @n_rep_id                                   -- 퇴직금기준 임금 관리ID      
                                          , @n_rep_calc_list_id_list                    -- 퇴직금대상ID      
                                          , '10'                                        -- 급여지급구분[REP_PAY_TYPE_CD]      
                                          , @v_base_pay_ym                              -- 급여년월      
                                          , @n_pay_cnt                                  -- 순서      
                                          , @d_base_s_ymd                               -- 시작일자      
                                          , @d_base_e_ymd                               -- 종료일자      
                                          , @n_base_cnt                                 -- 기준일수      
                                          , 0                                           -- 차감일수      
                                          , @n_real_cnt                                 -- 대상일수      
                                          , @an_mod_user_id                             -- 변경자      
                                          , dbo.XF_SYSDATE(0)                           -- 변경일시      
                                          , 'KST'                                       -- 타임존코드      
                                          , dbo.XF_SYSDATE(0) )                         -- 타임존일시      
                                SELECT @ERRCODE = @@ERROR      
                                    IF @ERRCODE != 0      
                                        BEGIN      
                                            SET @av_ret_code      = 'FAILURE!'      
                                            SET @av_ret_message   = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') 급여 기준임금 저장시 에러발생[ERR]', @v_program_id, 0040, null, @an_mod_user_id)      
                                            CLOSE rep       -- 커서닫기      
											DEALLOCATE rep  -- 커서 할당해제      
                                            RETURN      
                                        END 

								-- 급여년월 및 급여금액 적용(급여는 일할적용 시 최대 4개월 적용)
								BEGIN
									IF @n_pay_cnt = 1
									   BEGIN
										   SET @v_pay01_ym = @v_base_pay_ym
										   SET @n_pay01_amt = @an_return_cal_mon
									   END
									ELSE IF @n_pay_cnt = 2
									   BEGIN
										  SET @v_pay02_ym = @v_base_pay_ym
										  SET @n_pay02_amt = @an_return_cal_mon
									   END 
									ELSE IF @n_pay_cnt = 3
									   BEGIN
										  SET @v_pay03_ym = @v_base_pay_ym
										  SET @n_pay03_amt = @an_return_cal_mon
									   END
									ELSE
									   BEGIN
										  SET @v_pay04_ym = @v_base_pay_ym
										  SET @n_pay04_amt = @an_return_cal_mon
									   END
								END
                            END   
							
                        BEGIN 										
						   SET @n_pay_cnt = @n_pay_cnt + 1  -- 순차 증가처리
						END

                        FETCH NEXT FROM rep INTO @v_base_pay_ym      
                    END       -- 커서루프 종료      
            CLOSE rep         -- 커서닫기      
            DEALLOCATE rep    -- 커서 할당해제      
        END -- 커서종료  

		-- 급여합계적용
		BEGIN
		   SET @n_pay_mon = ISNULL(@n_pay01_amt,0) + ISNULL(@n_pay02_amt,0) + ISNULL(@n_pay03_amt,0) + ISNULL(@n_pay04_amt,0)	-- 급여합계
		   SET @n_pay_tot_amt = @n_pay_mon -- 3개월급여합계
		END
PRINT(' 급여 ===> ' + CONVERT(VARCHAR, @n_pay_tot_amt) + ' ' + FORMAT(SYSDATETIME(), 'HH:mm:ss.fffff'))
        -- ***************************************      
        -- 5. 1년치 정기상여 조회      
        -- ***************************************      
        SET @v_base_pay_ym = NULL      
        SET @d_bns_s_ymd = NULL      
        SET @d_bns_e_ymd = NULL      
		SET @an_return_cal_mon = 0      
        SET @n_rep_id = NULL
		SET @n_bns_cnt = 1
		--SET @n_bns_roop_cnt = 12
		
		-- 상여 기간설정
		BEGIN
		   IF (@av_company_cd = 'A' AND @v_emp_cls_cd = 'A')
              BEGIN
			     -- 상여계산시작일
                 SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_end_ymd, -12)     -- DateAndTime.DateAdd("m", -12, str_t_pay_date_tmp);
                 -- 상여계산종료일
                 SET @d_bns_e_ymd = dbo.XF_MONTHADD(@d_end_ymd, -1)      -- DateAndTime.DateAdd("m", -1, str_t_pay_date_tmp);
			  END
           ELSE IF (@av_company_cd = 'I' ) -- 산업상여는 전월부터 12개월
		      BEGIN
			     -- 산업 관리구분 수산/유통 A,물류8, 생산B, 선원C
                 IF (@v_mgr_type_cd = 'A' OR @v_mgr_type_cd = '8')
                    BEGIN
                       -- 상여계산시작일
                       SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_end_ymd, -12) -- DateAndTime.DateAdd("m", -12, str_t_pay_date_tmp);
                       -- 상여계산종료일
                       SET @d_bns_e_ymd = dbo.XF_MONTHADD(@d_end_ymd, -1)  -- DateAndTime.DateAdd("m", -1, str_t_pay_date_tmp);
                    END
                 ELSE
                    BEGIN
                       -- 상여계산시작일
                       SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_end_ymd, -11) -- DateAndTime.DateAdd("m", -11, str_t_pay_date_tmp);
                       -- 상여계산종료일
                       SET @d_bns_e_ymd = @d_end_ymd						-- dte_t_bonus_date.ToString("yyyyMMdd");
                    END
			  END
           ELSE
              BEGIN
			     -- 상여계산시작일
                 SET @d_bns_s_ymd = dbo.XF_MONTHADD(@d_end_ymd, -11)		-- DateAndTime.DateAdd("m", -11, str_t_pay_date_tmp);
                 -- 상여계산종료일
				 SET @d_bns_e_ymd = @d_end_ymd								-- str_t_pay_date.Replace("-", "");
			  END
		END

        BEGIN        
--PRINT('---->'+
--        '@n_emp_id=' + CONVERT(NVARCHAR(100), @n_emp_id)+
--      ',@av_company_cd=' + CONVERT(NVARCHAR(100), @av_company_cd)+
--	  ',@av_locale_cd=' + CONVERT(NVARCHAR(100), @av_locale_cd )+
--	  ',@v_exec_yn=' + CONVERT(NVARCHAR(100), @v_exec_yn)+
--	  ',@d_end_ymd=' + CONVERT(NVARCHAR(100), @d_end_ymd)+
--	  ',@d_bns_s_ymd=' + CONVERT(NVARCHAR(100), @d_bns_s_ymd)+
--	  ',@d_bns_e_ymd=' + CONVERT(NVARCHAR(100), @d_bns_e_ymd)
--	  )
            DECLARE sbpay CURSOR FOR      
                SELECT BASE_YM      
                     --, STA_YMD      
                     --, END_YMD     
                     --, BASE_DAY     
                  FROM (SELECT BASE_YM      
                             --, STA_YMD      
                             --, END_YMD      
                             --, dbo.XF_DATEDIFF(END_YMD, STA_YMD)+1 AS BASE_DAY     
                             , ROW_NUMBER() OVER (ORDER BY BASE_YM DESC) AS ROWNUM     
                          FROM (SELECT DISTINCT A.PAY_YM AS BASE_YM      
                                              --, A.STA_YMD      
                                              --, A.END_YMD      
                                  FROM PAY_PAY_YMD A      
                                       INNER JOIN PAY_PAYROLL B      
                                                           ON B.PAY_YMD_ID = A.PAY_YMD_ID      
                                       INNER JOIN PAY_PAYROLL_DETAIL C     
                                                                  ON C.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID     
                                 WHERE B.EMP_ID = @n_emp_id      
                                   AND C.CAL_MON > 0   
                                   AND C.PAY_ITEM_CD IN (SELECT KEY_CD3 AS PAY_ITEM_CD  
					                                       FROM FRM_UNIT_STD_HIS  
					                                      WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
												                                         FROM FRM_UNIT_STD_MGR  
												                                        WHERE COMPANY_CD = @av_company_cd  
													                                      AND UNIT_CD = 'REP'  
													                                      AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END)  
					                                        AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
					                                        AND KEY_CD1 = '20')      
                                   AND A.CLOSE_YN = 'Y'  
								   AND A.PAY_YN = 'Y'
								   --AND A.PAY_YM BETWEEN dbo.XF_TO_CHAR_D(@d_bns_s_ymd,'YYYYMM') AND dbo.XF_TO_CHAR_D(@d_bns_e_ymd, 'YYYYMM')   
								   AND A.PAY_YM BETWEEN FORMAT(@d_bns_s_ymd, 'yyyyMM') AND FORMAT(@d_bns_e_ymd, 'yyyyMM')
                                   AND A.PAY_YM NOT IN (SELECT Y.BASE_YM      
                                                          FROM (SELECT dbo.XF_TO_CHAR_D(T.STA_YMD, 'YYYYMM') AS STA_YM,      
                                                                       dbo.XF_TO_CHAR_D(T.END_YMD, 'YYYYMM') AS END_YM      
                                                                  FROM (SELECT STA_YMD      
                                                                             , END_YMD      
                                                                          FROM CAM_TERM_MGR      
                                                                         WHERE ITEM_NM = 'LEAVE_CD'      
                                                                           AND VALUE IN (SELECT CD      
                                                                                           FROM FRM_CODE      
                                                                                          WHERE CD_KIND = 'REP_EXCE_TYPE_CD'        
                                                                                            AND LOCALE_CD = @av_locale_cd       
                                                                                            AND COMPANY_CD = @av_company_cd      
                                                                                            AND @d_end_ymd BETWEEN STA_YMD AND END_YMD)      
																		   AND EMP_ID = @n_emp_id) T) X      
                                                               INNER JOIN (SELECT DISTINCT BASE_YM      
                                                                             FROM (SELECT dbo.XF_TO_CHAR_D(YMD, 'YYYYMM') AS BASE_YM      
                                                                                     FROM HPS_CALENDAR      
                                                                                    WHERE COMPANY_CD = @av_company_cd       
                                                                                      AND YMD <= @d_end_ymd) B1) Y      
                                                                   ON Y.BASE_YM BETWEEN X.STA_YM AND X.END_YM )) C3 ) C4               
                 ORDER BY BASE_YM ASC      
            OPEN sbpay      
                FETCH NEXT FROM sbpay INTO @v_base_pay_ym--, @d_base_s_ymd, @d_base_e_ymd, @n_base_cnt      
                WHILE (@@FETCH_STATUS = 0)      
                    BEGIN -- 커서루프  
                        -- ***************************************      
                        -- 5-1. 기준항목 시퀀스 채번      
                        -- ***************************************      
                        BEGIN      
                            SELECT @n_rep_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE      
                              FROM DUAL      
                        END      
                        -- ***************************************      
                        -- 5-2. 임금항목 저장      
                        -- *************************************** 
						SET @n_base_cnt  = dbo.XF_DATEDIFF(dbo.XF_LAST_DAY(dbo.XF_TO_DATE(@v_base_pay_ym+'01', 'YYYYMMDD')), dbo.XF_TO_DATE(@v_base_pay_ym+'01', 'YYYYMMDD')) + 1
                        BEGIN      
									--print 'P_REP_CAL_PAY_DETAIL 2 START ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')
                            EXEC dbo.P_REP_CAL_PAY_DETAIL @av_company_cd      
                                                        , @n_rep_calc_list_id_list      
                                                        , @n_rep_id      
                                                        , @v_base_pay_ym      
                                                        , '20'      
                                                        , @n_base_cnt      
                                                        , @n_base_cnt      
                                                        , 'N'      
                                                        , @an_mod_user_id      
                                                        , @an_return_cal_mon OUTPUT      
                                                        , @av_ret_code OUTPUT      
                                                        , @av_ret_message OUTPUT      
									--print 'P_REP_CAL_PAY_DETAIL 2 END ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')
                            IF @av_ret_code = 'FAILURE!'      
                                BEGIN      
                                    SET @av_ret_code     = 'FAILURE!'      
                                    SET @av_ret_message  = @av_ret_message      
                                    CLOSE sbpay      -- 커서닫기      
                                    DEALLOCATE sbpay -- 커서 할당해제      
                                    RETURN      
                                END      
                        END 

                        -- ***************************************      
                        -- 5-3. 기준임금 저장      
                        -- ***************************************      
                        IF @an_return_cal_mon <> 0  
						    BEGIN
							   IF @n_bns_cnt = 1 
							      BEGIN
								     SET @v_bonus01_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus01_amt = @an_return_cal_mon	-- 상여금액_01
								  END							   
							   ELSE IF @n_bns_cnt = 2 
							      BEGIN
								     SET @v_bonus02_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus02_amt = @an_return_cal_mon	-- 상여금액_01
								  END							   
							   ELSE IF @n_bns_cnt = 3
							      BEGIN
								     SET @v_bonus03_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus03_amt = @an_return_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 4
							      BEGIN
								     SET @v_bonus04_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus04_amt = @an_return_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 5
							      BEGIN
								     SET @v_bonus05_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus05_amt = @an_return_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 6 
							      BEGIN
								     SET @v_bonus06_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus06_amt = @an_return_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 7
							      BEGIN
								     SET @v_bonus07_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus07_amt = @an_return_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 8
							      BEGIN
								     SET @v_bonus08_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus08_amt = @an_return_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 9
							      BEGIN
								     SET @v_bonus09_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus09_amt = @an_return_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 10
							      BEGIN
								     SET @v_bonus10_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus10_amt = @an_return_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 11
							      BEGIN
								     SET @v_bonus11_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus11_amt = @an_return_cal_mon	-- 상여금액_01
								  END	
							   ELSE IF @n_bns_cnt = 12
							      BEGIN
								     SET @v_bonus12_ym = @v_base_pay_ym			-- 상여년월_01
		                             SET @n_bonus12_amt = @an_return_cal_mon	-- 상여금액_01
								  END	
							END
						     
--Print('asdfasd여기22222=>' + convert(nvarchar(100), @an_return_cal_mon))
--Print(
--		'@v_base_pay_ym =' + convert(nvarchar(100), @v_base_pay_ym) +
--	', @d_base_s_ymd =' + convert(nvarchar(100), @d_base_s_ymd) +
--	', @d_base_e_ymd =' + convert(nvarchar(100), @d_base_e_ymd) +
--	', @n_base_cnt =' + convert(nvarchar(100), @n_base_cnt) 
--)
                            BEGIN      
                                INSERT INTO REP_PAY_STD                             -- 퇴직금기준 임금 관리      
                                          ( REP_PAY_STD_ID                          -- 퇴직금기준 임금 관리ID      
                                          , REP_CALC_LIST_ID                        -- 퇴직금대상ID      
                                          , PAY_TYPE_CD                             -- 급여지급구분[PAY_TYPE_CD]      
                                          , PAY_YM									-- 급여년월      
										  , SEQ                                     -- 순서      
                                          , STA_YMD                                 -- 시작일자      
                                          , END_YMD                                 -- 종료일자      
										  , BASE_DAY                                -- 기준일수      
                                          , MINUS_DAY                               -- 차감일수      
                                          , REAL_DAY                                -- 대상일수      
                                          , MOD_USER_ID                             -- 변경자      
                                          , MOD_DATE                                -- 변경일시      
                                          , TZ_CD                                   -- 타임존코드      
                                          , TZ_DATE )                             -- 타임존일시      
                                    VALUES( @n_rep_id                               -- 퇴직금기준 임금 관리ID      
                                          , @n_rep_calc_list_id_list                -- 퇴직금대상ID      
                                          , '20'                                    -- 급여지급구분[REP_PAY_TYPE_CD]      
                                          , @v_base_pay_ym                          -- 급여년월      
                                          , @n_bns_cnt                              -- 순서      
                                          , dbo.XF_TO_DATE(@v_base_pay_ym+'01', 'YYYYMMDD') -- 시작일자      
                                          , dbo.XF_LAST_DAY(dbo.XF_TO_DATE(@v_base_pay_ym+'01', 'YYYYMMDD'))                           -- 종료일자      
                                          , @n_base_cnt                             -- 기준일수      
                                          , 0                                       -- 차감일수      
                                          , @n_base_cnt                             -- 대상일수      
                                          , @an_mod_user_id                         -- 변경자      
                                          , dbo.XF_SYSDATE(0)                       -- 변경일시      
                                          , 'KST'                                   -- 타임존코드      
                                          , dbo.XF_SYSDATE(0) )                     -- 타임존일시              
                                SELECT @ERRCODE = @@ERROR      
                                    IF @ERRCODE != 0      
                                        BEGIN      
                                            SET @av_ret_code      = 'FAILURE!'      
                                            SET @av_ret_message   = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') 상여 기준임금 저장시 에러발생', @v_program_id, 0050, null, @an_mod_user_id)      
                                            CLOSE sbpay      -- 커서닫기      
                                            DEALLOCATE sbpay -- 커서 할당해제      
                                            RETURN      
                                        END 
								BEGIN 										
								   SET @n_bns_cnt = @n_bns_cnt + 1  -- 순차 증가처리
								END		
                            END      
                        FETCH NEXT FROM sbpay INTO @v_base_pay_ym--, @d_base_s_ymd, @d_base_e_ymd, @n_base_cnt      
                    END         -- 커서루프 종료     

            CLOSE sbpay         -- 커서닫기      
            DEALLOCATE sbpay    -- 커서 할당해제      
        END                     -- 커서종료      

		-- 상여합계적용
		BEGIN
		   SET @n_bonus_mon = ISNULL(@n_bonus01_amt,0) + ISNULL(@n_bonus02_amt,0) + ISNULL(@n_bonus03_amt,0) + ISNULL(@n_bonus04_amt,0)	 + ISNULL(@n_bonus05_amt, 0) +  
		   					  ISNULL(@n_bonus06_amt,0) + ISNULL(@n_bonus07_amt,0) + ISNULL(@n_bonus08_amt,0) + ISNULL(@n_bonus09_amt,0)	 + ISNULL(@n_bonus10_amt, 0)	-- 상여합계	
		END
PRINT(' 상여KKK ===> ' + CONVERT(VARCHAR, @n_bonus_mon) )

PRINT(' @n_bef_ret_year ===> ' + CONVERT(VARCHAR, @n_bef_ret_year) )
        -- ***************************************      
        -- 6. 1년치 연차 조회      
        -- ***************************************      
        SET @v_base_pay_ym = NULL
		SET @n_bef_ret_year = dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_bns_e_ymd, 'YYYY')) - 1
        SET @d_day_s_ymd = dbo.XF_TO_DATE(CONVERT(VARCHAR, @n_bef_ret_year) + dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_bns_e_ymd,'YYYYMMDD'),5,2) + dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_bns_e_ymd,'YYYYMMDD'),7,2), 'YYYYMMDD')
        SET @d_day_e_ymd = @d_bns_e_ymd      
        SET @an_return_cal_mon = 0      
        SET @n_rep_id = NULL   
		
        BEGIN   

PRINT(' @n_bef_ret_year ===> ' + CONVERT(VARCHAR, @n_bef_ret_year) )		
PRINT(' @d_day_s_ymd ===> ' + CONVERT(VARCHAR, @d_day_s_ymd) )
PRINT(' @d_day_e_ymd ===> ' + CONVERT(VARCHAR, @d_day_e_ymd) )
PRINT('---->'+
        '@n_emp_id=' + CONVERT(NVARCHAR(100), @n_emp_id)+
      ',@av_company_cd=' + CONVERT(NVARCHAR(100), @av_company_cd)+
	  ',@av_locale_cd=' + CONVERT(NVARCHAR(100), @av_locale_cd )+
--	  ',@v_exec_yn=' + CONVERT(NVARCHAR(100), @v_exec_yn)+
	  ',@d_end_ymd=' + CONVERT(NVARCHAR(100), @d_end_ymd)+
	  ',@d_day_s_ymd=' + CONVERT(NVARCHAR(100), @d_day_s_ymd)+
	  ',@d_day_e_ymd=' + CONVERT(NVARCHAR(100), @d_day_e_ymd)
	  )
            DECLARE dtm CURSOR FOR 

                SELECT BASE_YM      
                     , STA_YMD      
                     , END_YMD     
                     , BASE_DAY     
                  FROM (SELECT BASE_YM      
                             , STA_YMD      
                             , END_YMD      
                             , dbo.XF_DATEDIFF(END_YMD, STA_YMD)+1 AS BASE_DAY     
                             , ROW_NUMBER() OVER (ORDER BY BASE_YM DESC) AS ROWNUM     
                          FROM (SELECT DISTINCT A.PAY_YM AS BASE_YM      
                                              , A.STA_YMD      
                                              , A.END_YMD      
                                  FROM PAY_PAY_YMD A      
                                       INNER JOIN PAY_PAYROLL B      
                                                           ON B.PAY_YMD_ID = A.PAY_YMD_ID      
                                       INNER JOIN PAY_PAYROLL_DETAIL C     
                                                                  ON C.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID     
                                 WHERE B.EMP_ID = @n_emp_id      
                                   AND C.CAL_MON > 0   
                                   AND C.PAY_ITEM_CD IN (SELECT KEY_CD3 AS PAY_ITEM_CD  
					                                       FROM FRM_UNIT_STD_HIS  
					                                      WHERE FRM_UNIT_STD_MGR_ID = (SELECT FRM_UNIT_STD_MGR_ID  
												                                         FROM FRM_UNIT_STD_MGR  
												                                        WHERE COMPANY_CD = @av_company_cd  
													                                      AND UNIT_CD = 'REP'  
													                                      AND STD_KIND = CASE WHEN @v_officers_yn = 'N' THEN 'REP_AVG_ITEM_CD' ELSE 'REP_AVG_MGR_ITEM_CD' END)  
					                                        AND @d_end_ymd BETWEEN STA_YMD AND END_YMD  
					                                        AND KEY_CD1 = '30')      
                                   AND A.CLOSE_YN = 'Y'  
								   AND A.PAY_YN = 'Y'
								   AND A.PAY_YM >= FORMAT(@d_day_s_ymd, 'yyyyMM') -- dbo.XF_TO_CHAR_D(@d_day_s_ymd,'YYYYMM') 
								   AND A.PAY_YM < FORMAT(@d_day_e_ymd, 'yyyyMM') --dbo.XF_TO_CHAR_D(@d_day_e_ymd, 'YYYYMM')   
                                   AND A.PAY_YM NOT IN (SELECT Y.BASE_YM      
                                                          FROM (SELECT dbo.XF_TO_CHAR_D(T.STA_YMD, 'YYYYMM') AS STA_YM,      
                                                                       dbo.XF_TO_CHAR_D(T.END_YMD, 'YYYYMM') AS END_YM      
                                                                  FROM (SELECT STA_YMD      
                                                                             , END_YMD      
                                                                          FROM CAM_TERM_MGR      
                                                                         WHERE ITEM_NM = 'LEAVE_CD'      
                                                                           AND VALUE IN (SELECT CD      
                                                                                           FROM FRM_CODE      
                                                                                          WHERE CD_KIND = 'REP_EXCE_TYPE_CD'        
                                                                                            AND LOCALE_CD = @av_locale_cd       
                                                                                            AND COMPANY_CD = @av_company_cd      
                                                                                            AND @d_end_ymd BETWEEN STA_YMD AND END_YMD)      
																		   AND EMP_ID = @n_emp_id) T) X      
                                                               INNER JOIN (SELECT DISTINCT BASE_YM      
                                                                             FROM (SELECT dbo.XF_TO_CHAR_D(YMD, 'YYYYMM') AS BASE_YM      
                                                                                     FROM HPS_CALENDAR      
                                                                                    WHERE COMPANY_CD = @av_company_cd       
                                                                                      AND YMD <= @d_end_ymd) B1) Y      
                                                                   ON Y.BASE_YM BETWEEN X.STA_YM AND X.END_YM )) C3 ) C4               
                 ORDER BY BASE_YM ASC   			
        
            OPEN dtm      
                FETCH NEXT FROM dtm INTO @v_base_pay_ym, @d_base_s_ymd, @d_base_e_ymd, @n_base_cnt      
                WHILE (@@FETCH_STATUS = 0)      
                    BEGIN      
                        -- ***************************************      
                        -- 6-1. 기준항목 시퀀스 채번      
                        -- ***************************************      
                        BEGIN      
                            SELECT @n_rep_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE      
                              FROM DUAL      
                        END      
                        -- ***************************************      
                        -- 6-2. 임금항목 저장      
                        -- ***************************************      
                        BEGIN      
									--print 'P_REP_CAL_PAY_DETAIL 3 START ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')
                            EXEC dbo.P_REP_CAL_PAY_DETAIL @av_company_cd      
                                                        , @n_rep_calc_list_id_list      
                                                        , @n_rep_id      
                                                        , @v_base_pay_ym      
                                                        , '30'      
                                                        , @n_base_cnt      
                                                        , @n_base_cnt      
                                                        , 'N'      
                                                        , @an_mod_user_id      
                                                        , @an_return_cal_mon OUTPUT      
                                                        , @av_ret_code OUTPUT      
                                                        , @av_ret_message OUTPUT  
									--print 'P_REP_CAL_PAY_DETAIL 3 END ' + FORMAT(sysdatetime(), 'HH:mm:ss.fffff')    
                            IF @av_ret_code = 'FAILURE!'      
                                BEGIN      
                                    SET @av_ret_code     = 'FAILURE!'      
                                    SET @av_ret_message  = @av_ret_message      
                                    CLOSE dtm      -- 커서닫기      
                                    DEALLOCATE dtm -- 커서 할당해제      
                                    RETURN      
                                END      
                        END 
			
                        -- ***************************************      
                        -- 5-3. 기준임금 저장      
                        -- ***************************************      
                        IF @an_return_cal_mon <> 0  
						
						    -- 연월차수당
							BEGIN
							   SET @n_day_tot_amt = @an_return_cal_mon		-- 연월차총액
							END 
PRINT(' 연차 ===> ' + CONVERT(VARCHAR, @n_day_tot_amt) )
                            BEGIN      
                                INSERT INTO REP_PAY_STD                             -- 퇴직금기준 임금 관리      
                                          ( REP_PAY_STD_ID                          -- 퇴직금기준 임금 관리ID      
                                          , REP_CALC_LIST_ID                        -- 퇴직금대상ID      
                                          , PAY_TYPE_CD                             -- 급여지급구분[PAY_TYPE_CD]      
                                          , PAY_YM                                  -- 급여년월      
                                          , SEQ                                     -- 순서      
                                          , STA_YMD                                 -- 시작일자      
                                          , END_YMD                                 -- 종료일자      
                                          , BASE_DAY                                -- 기준일수      
                                          , MINUS_DAY                               -- 차감일수      
                                          , REAL_DAY                                -- 대상일수      
										  , MOD_USER_ID                             -- 변경자      
                                          , MOD_DATE                                -- 변경일시      
                                          , TZ_CD                                   -- 타임존코드      
                                          , TZ_DATE )                               -- 타임존일시      
                                    VALUES( @n_rep_id                               -- 퇴직금기준 임금 관리ID      
                                          , @n_rep_calc_list_id_list                -- 퇴직금대상ID      
                                          , '30'                                    -- 급여지급구분[REP_PAY_TYPE_CD]      
                                          , @v_base_pay_ym                          -- 급여년월      
                                          , 3                                       -- 순서      
                                          , @d_base_s_ymd                           -- 시작일자      
                                          , @d_base_e_ymd                           -- 종료일자      
                                          , @n_base_cnt                             -- 기준일수      
                                          , 0                                       -- 차감일수      
                                          , @n_base_cnt                             -- 대상일수      
                                          , @an_mod_user_id                         -- 변경자      
                                          , dbo.XF_SYSDATE(0)                       -- 변경일시      
                                          , 'KST'                                   -- 타임존코드      
                                          , dbo.XF_SYSDATE(0) )                     -- 타임존일시              
                                SELECT @ERRCODE = @@ERROR      
                                    IF @ERRCODE != 0      
                                        BEGIN      
                                            SET @av_ret_code      = 'FAILURE!'      
                                            SET @av_ret_message   = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id, '1')+') 연차 기준임금 저장시 에러발생', @v_program_id, 0050, null, @an_mod_user_id)      
                                            CLOSE dtm      -- 커서닫기      
                                            DEALLOCATE dtm -- 커서 할당해제      
                                            RETURN      
                                        END 
									
                            END      
                        FETCH NEXT FROM dtm INTO @v_base_pay_ym, @d_base_s_ymd, @d_base_e_ymd, @n_base_cnt      
                    END     -- 커서루프 종료  
            CLOSE dtm       -- 커서닫기      
            DEALLOCATE dtm  -- 커서 할당해제      
        END -- 커서종료  

        -- ***************************************   
        -- 7. 3개월급여, 12개월상여 연차 저장   
        -- ***************************************   
        BEGIN   
            UPDATE REP_CALC_LIST            -- 퇴직금계산대상자(내역)  
               SET RETIRE_YMD			= @d_retire_ymd			-- 퇴직일자
		         , FLAG					= @v_flag_yn			-- 1년미만
		         , BIZ_CD				= @v_biz_cd				-- 사업장
				 , REG_BIZ_CD			= @v_reg_biz_cd			-- 신고사업장
				 , ORG_NM				= @v_org_nm				-- 조직명
				 , ORG_LINE				= @v_org_line			-- 조직순차
	             , PAY_METH_CD			= @v_pay_meth_cd		-- 급여지급방식[PAY_METH_CD]
				 , CALCU_TPYE			= '2'					-- 계산구분
				 , EMP_CLS_CD			= @v_emp_cls_cd			-- 고용유형[PAY_EMP_CLS_CD]
				 , INS_TYPE_YN			= @v_ins_type_yn		-- 퇴직연금가입여부
				 , INS_TYPE_CD			= @v_ins_type_cd		-- 퇴직연금종류[RMP_INS_TYPE_CD]								 
				 , REP_ANNUITY_BIZ_NM	= @v_ins_nm				-- 퇴직연금사업자명
				 , REP_ANNUITY_BIZ_NO	= @v_ins_bizno			-- 퇴직연금사업장등록번호
				 , REP_BANK_CD			= @v_ins_bank_cd		-- 퇴직연금은행코드
				 , REP_ACCOUNT_NO		= @v_ins_account_no		-- 퇴직연금계좌번호
			     , RETIRE_TURN          = @n_retire_turn_mon	-- 국민연금퇴직전환금
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
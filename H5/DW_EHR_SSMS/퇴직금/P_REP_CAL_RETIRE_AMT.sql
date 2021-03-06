SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_CAL_RETIRE_AMT] (     
       @av_company_cd                 NVARCHAR(10),             -- 인사영역     
       @av_locale_cd                  NVARCHAR(10),             -- 지역코드     
       @an_work_id                    NUMERIC(38),				-- 작업ID     
       @av_work_cd                    NVARCHAR(10),             -- 작업구분(1:기초자료생성,2:평균임금산정,3:퇴직금계산)     
       @an_mod_user_id                NUMERIC(38),				-- 변경자 사번     
       @av_ret_code                   NVARCHAR(4000)    OUTPUT, -- 결과코드     
       @av_ret_message                NVARCHAR(4000)    OUTPUT  -- 결과메시지     
) AS     
     
    -- ***************************************************************************     
    --   TITLE       : 퇴직금계산  - 일반.     
    --   PROJECT     : HR 시스템     
    --   AUTHOR      :     
    --   PROGRAM_ID  : P_REP_CAL_RETIRE_AMT     
    --   RETURN      : 1) SUCCESS!/FAILURE!     
    --                 2) 결과 메시지     
    --   COMMENT     : 퇴직금계산  - 일반. P_REP_PAY_CALC_MAIN 에서 호출.     
    --   HISTORY     : 작성 정순보  2006.09.26     
    --               : 수정 박근한  2009.01.16     
    --               : 2016-06-23 Modified by 최성용 in KBpharma      
    -- ***************************************************************************     
     
BEGIN     
   
    /* 기본적으로 사용되는 변수 */     
    DECLARE @v_program_id              NVARCHAR(30)     
          , @v_program_nm              NVARCHAR(100)     
          , @ERRCODE                   NVARCHAR(10)     
     
    DECLARE @n_emp_id                  NUMERIC(38)     
          , @d_sta_ymd                 DATE				-- 기산일     
          , @d_end_ymd                 DATE				-- 정산일     
          , @d_pay_ymd                 DATE				-- 지급일     
          , @n_rep_calc_id             NUMERIC			-- 퇴직금대상자                        
          , @v_pos_cd                  NVARCHAR(30)		-- 직위
		  , @v_officers_yn			   NVARCHAR(1)		-- 임원여부
          , @n_official_rate           NUMERIC(19,4)    -- 임원배수                 
          , @n_work_yy                 NUMERIC(5,0)		-- 실근속년수     
          , @n_work_mm                 NUMERIC(5,0)		-- 실근속월수     
          , @n_work_dd                 NUMERIC(5,0)		-- 실근속일수     
          , @n_work_day                NUMERIC(5,0)		-- 실근속총일수     
          , @n_work_yy_pt              NUMERIC(10,1)	-- 실근속년수(소수점)     
          , @n_add_work_yy             NUMERIC(10,1)	-- 추가근속년수 
		  , @n_c_01					   NUMERIC(19,4)	-- 주(현)법정퇴직급여
          , @n_c_01_1                  NUMERIC(19,4)	-- 법정퇴직금     
          , @n_c_02_2                  NUMERIC(19,4)	-- 추가퇴직금     
          , @n_avg_pay_amt             NUMERIC(19,4)	-- 평균임금
		  , @n_real_amt				   NUMERIC(19,4)	-- 실지급액 
		  , @n_comm_real_amt		   NUMERIC(19,4)	-- 당사지급액
		  , @n_chain_amt			   NUMERIC(19,4)	-- 차인지급액
          , @v_calc_type_cd            NVARCHAR(10)		-- 정산구분        
          , @v_rep_mid_yn              NVARCHAR(1)		-- 중간정산 포함여부     
          , @n_retire_turn             NUMERIC(19,4)	-- 국민연금전환금    
		  , @n_etc_deduct			   NUMERIC(19,4)	-- 기타공제    
		  , @n_etc_pay_amt			   NUMERIC(19,4)	-- 기타수당  
    
	/* 기본변수 초기값 셋팅*/     
    SET @v_program_id    = 'P_REP_CAL_RETIRE_AMT'    -- 현재 프로시져의 영문명     
    SET @v_program_nm    = '퇴직금계산'              -- 현재 프로시져의 한글문명     
    SET @av_ret_code     = 'SUCCESS!'     
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id, 0000, null, @an_mod_user_id)     
     
    BEGIN     
        -- ***************************************     
        -- 1. 대상자 조회     
        -- ***************************************     
        DECLARE calc CURSOR LOCAL FOR     
            SELECT A.TMP_LIST_ID rep_calc_list_id     
              --FROM REP_CALC_LIST A, REP_TMP_SAVE B     
			  FROM REP_TMP_SAVE A
			  INNER JOIN REP_CALC_LIST B
			          ON A.TMP_LIST_ID = B.REP_CALC_LIST_ID
             WHERE A.WORK_ID = @an_work_id     
        OPEN calc     
            FETCH NEXT FROM calc INTO @n_rep_calc_id     
            WHILE (@@FETCH_STATUS = 0)     
                BEGIN -- 커서루프     
                    -- ***************************************     
                    -- 1. 대상자(내역) 조회 및 지급일 완료 체크     
                    -- ***************************************     
                    BEGIN         
                       SELECT @d_pay_ymd               = PAY_YMD     
                            , @n_emp_id                = EMP_ID     
                            , @d_sta_ymd               = C1_STA_YMD     
                            , @d_end_ymd               = C1_END_YMD     
                            , @n_avg_pay_amt           = AVG_PAY_AMT     
                            , @v_calc_type_cd          = CALC_TYPE_CD     
                            , @n_retire_turn           = RETIRE_TURN     
                            , @v_rep_mid_yn            = REP_MID_YN     
                         FROM REP_CALC_LIST     
                        WHERE REP_CALC_LIST_ID = @n_rep_calc_id     
                    END     
                    IF @d_pay_ymd IS NOT NULL     
                        BEGIN     
                            SET @av_ret_code      = 'FAILURE!'     
                            SET @av_ret_message   = dbo.F_FRM_ERRMSG('('+dbo.F_PHM_EMP_NO(@n_emp_id,'1')+')님의 지급일이 있으므로 다시 생성할 수 없습니다[ERR]', @v_program_id, 0010, null, @an_mod_user_id)     
                            CLOSE calc      -- 커서닫기     
                            DEALLOCATE calc -- 커서 할당해제     
                            RETURN     
                        END     
                    -- ***************************************     
                    -- 2. 기초자료생성인경우 기초자료를 생성     
                    -- ***************************************     
                    IF @av_work_cd = '1'     
                        BEGIN
							PRINT 'REP_CAL_PAY_STD' + CONVERT(VARCHAR(100), @n_rep_calc_id)
                            EXEC dbo.P_REP_CAL_PAY_STD  @av_company_cd, @av_locale_cd, @n_rep_calc_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT     
							--EXEC dbo.P_REP_CAL_PAY_STD  @av_company_cd, @n_rep_calc_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT     
                            IF @av_ret_code = 'FAILURE!'     
                                BEGIN     
                                    SET @av_ret_code     = 'FAILURE!'     
                                    SET @av_ret_message  = @av_ret_message     
                                    CLOSE calc      -- 커서닫기     
                                    DEALLOCATE calc -- 커서 할당해제     
                                    RETURN     
                                END     
                        END       
                    -- ***************************************     
                    -- 3. 평균임금인 경우 평균임금을 생성     
                    -- ***************************************     
                    ELSE IF @av_work_cd = '2'     
                        BEGIN     
                            EXEC dbo.P_REP_CAL_AVG_AMT  @av_company_cd, @av_locale_cd, @n_rep_calc_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT     
                            IF @av_ret_code = 'FAILURE!'     
                                BEGIN     
                                    SET @av_ret_code     = 'FAILURE!'     
                                    SET @av_ret_message  = @av_ret_message     
                                    CLOSE calc      -- 커서닫기     
                                    DEALLOCATE calc -- 커서 할당해제     
                                    RETURN     
                                END     
                        END      
                    -- ***************************************     
                    -- 3. 퇴직금계산인 경우 퇴직금 & 세금 계산     
                    -- ***************************************     
                    ELSE     
                        BEGIN     
                            -- ***************************************     
                            -- 3-1. 평균임금이 산출 안 되어 있으면 평균임금을 산출     
                            -- ***************************************     
                            IF @n_avg_pay_amt IS NULL OR @n_avg_pay_amt = 0     
                                BEGIN     
                                    EXEC dbo.P_REP_CAL_AVG_AMT  @av_company_cd, @av_locale_cd, @n_rep_calc_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT     
                                    IF @av_ret_code = 'FAILURE!'     
                                        BEGIN     
											SET @av_ret_code     = 'FAILURE!'     
                                            SET @av_ret_message  = @av_ret_message     
                                            CLOSE calc      -- 커서닫기     
                                            DEALLOCATE calc -- 커서 할당해제     
                                            RETURN     
                                        END     
                                END 
								
                            -- ***************************************     
                            -- 3-2. 대상자(내역) 조회     
                            -- ***************************************     
                            BEGIN     
                                SELECT @n_emp_id        = EMP_ID			-- 사원ID
                                     , @d_sta_ymd       = C1_STA_YMD		-- 정산 시작(기산)일
                                     , @d_end_ymd       = C1_END_YMD        -- 정산 종료일
                                     , @n_avg_pay_amt   = AVG_PAY_AMT       -- 퇴직금
                                     , @v_calc_type_cd  = CALC_TYPE_CD      -- 정산구분
                                     , @v_pos_cd        = POS_CD			-- 직위
									 , @n_c_01			= C_01			    -- 법정퇴직금
									 , @v_officers_yn	= ISNULL(OFFICERS_YN, 'N')				-- 임원여부
									 , @n_etc_deduct    = ETC_DEDUCT        -- 기타공제-    
                                     , @n_etc_pay_amt   = ETC_PAY_AMT       -- 기타수당 
                                FROM REP_CALC_LIST     
                               WHERE REP_CALC_LIST_ID = @n_rep_calc_id     
                            END   
							
                            -- ***************************************     
                            -- 3-3. 퇴직금 계산     
                            -- ***************************************     
                            SET @n_c_01_1 = 0     
                            SET @n_c_02_2 = 0  -- 주(현)추가퇴직금
								                              
							SET @n_c_01_1 = @n_c_01
							SET @n_real_amt = ISNULL(@n_c_01, 0) + ISNULL(@n_etc_pay_amt, 0) - ISNULL(@n_etc_deduct, 0)
							SET @n_comm_real_amt = @n_real_amt
							SET @n_chain_amt = @n_real_amt  
							
							-- ***************************************     
                            -- 3-4 임원퇴직금한도     
                            -- *************************************** 
							BEGIN
							   IF @v_officers_yn = 'Y'
							      BEGIN
                                     --EXEC dbo.P_REP_CAL_INWON_LIMIT  @av_company_cd, @av_locale_cd, @n_rep_calc_id, @n_c_01, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT     
                                     IF @av_ret_code = 'FAILURE!'     
                                        BEGIN     
											SET @av_ret_code     = 'FAILURE!'     
                                            SET @av_ret_message  = @av_ret_message     
                                            CLOSE calc      -- 커서닫기     
                                            DEALLOCATE calc -- 커서 할당해제     
                                            RETURN     
                                        END     
								  END

							END


                            --****************************************     
                            -- 3-5. 퇴직금 입력     
                            --****************************************     
                            BEGIN     
                                UPDATE REP_CALC_LIST                                      -- 퇴직금계산대상자(내역)     
                                    SET C_01_1             = dbo.XF_NVL_N(@n_c_01_1,0)    -- 주(현)법정퇴직급여     
										, C_SUM			   = dbo.XF_NVL_N(@n_c_01_1,0)    -- 주(현)계
										, R01			   = dbo.XF_NVL_N(@n_c_01_1,0)    -- 법정퇴직급여액
                                        , R01_S            = dbo.XF_NVL_N(@n_c_01_1,0)    -- 퇴직급여액
										, REAL_AMT		   = @n_real_amt				  -- 실지급액
										, COMM_REAL_AMT	   = @n_comm_real_amt			  -- 당사지급액
										, CHAIN_AMT		   = @n_chain_amt				  -- 차인지급액(퇴직금)
                                        , MOD_USER_ID      = @an_mod_user_id              -- 변경자     
                                        , MOD_DATE         = dbo.XF_SYSDATE(0)            -- 변경일시     
                                    WHERE REP_CALC_LIST_ID = @n_rep_calc_id     
                            END     
                            --****************************************     
                            -- 3-5. 퇴직금세금 계산     
                            --****************************************    
                            IF @v_calc_type_cd <> '03' -- 퇴직추계는 세금제외  
                                BEGIN   
                                    EXEC dbo.P_REP_CAL_TAX @av_company_cd, @av_locale_cd, @n_rep_calc_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT     
                                    IF @av_ret_code = 'FAILURE!'     
                                        BEGIN     
                                            SET @av_ret_code     = 'FAILURE!'     
                                            SET @av_ret_message  = @av_ret_message     
                                            CLOSE calc      -- 커서닫기     
                                            DEALLOCATE calc -- 커서 할당해제     
                                            RETURN     
                                        END    
                                END   
                        END  -- 퇴직금계산 종료     
                        FETCH NEXT FROM calc INTO @n_rep_calc_id     
                END     -- 커서루프 종료     
        CLOSE calc      -- 커서닫기     
        DEALLOCATE calc -- 커서 할당해제     
    END -- 커서종료     
    -- ************************************     
    -- 4. 퇴직금 임시테이블 삭제     
    -- ************************************     
    BEGIN     
        DELETE FROM REP_TMP_SAVE     
              WHERE WORK_ID = @an_work_id     
                AND EMP_ID = @an_mod_user_id     
        IF @@ERROR != 0      
            BEGIN     
                SET @av_ret_code     = 'FAILURE!'     
                SET @av_ret_message  = dbo.F_FRM_ERRMSG('퇴직금임시테이블 삭제시 에러발생[ERR]', @v_program_id, 0000, null, @an_mod_user_id)     
                RETURN     
            END     
    END     
    -- ***********************************************************     
    -- 작업 완료     
    -- ***********************************************************     
    SET @av_ret_code    = 'SUCCESS!'     
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 완료[ERR]', @v_program_id, 9999, null, @an_mod_user_id)     
     
END
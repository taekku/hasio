USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_ESTIMATION_MAKE]    Script Date: 2021-01-28 오후 4:53:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_REP_ESTIMATION_MAKE]
    @av_company_cd     NVARCHAR(10),			-- 회사코드
    @av_locale_cd      NVARCHAR(10),			-- 국가코드
    @av_calc_type_cd   NVARCHAR(10),			-- 정산구분 ('03' : 퇴직추계)
	@ad_std_ymd        DATE,				-- 기준일자
	@an_pay_group_id   NUMERIC(38),				-- 급여그룹
	@an_org_id         NUMERIC(38),				-- 소속ID
    @an_emp_id         NUMERIC(38),				-- 사원ID
    @an_mod_user_id    NUMERIC(38),				-- 변경자
    @av_ret_code                   VARCHAR(500)    OUTPUT, -- 결과코드*/    
    @av_ret_message                VARCHAR(4000)    OUTPUT  -- 결과메시지*/    
AS
    -- ***************************************************************************
    --   TITLE       : 퇴직추계액
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
           @d_mod_date            DATETIME2(0),		-- 수정일
 
           @n_auto_yn_cnt		  INT,				-- 전표생성
		   @d_begin_date		  DATE,				-- 추계월 1일자
		   @n_rep_calc_list_id    NUMERIC(38),		-- 퇴직정산ID
           @n_emp_id              NUMERIC(38),		-- 사원ID
           @n_org_id              NUMERIC(38),		-- 조직ID
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
		   @v_officers_yn		  NVARCHAR(1),		-- 임원여부
		   @v_retire_type_cd	  NVARCHAR(50),		-- 퇴직구분코드 [CAM_CAU_CD]
		   @d_first_join_ymd	  DATETIME2,		-- 최초입사일
           @d_group_ymd           DATETIME2,		-- 그룹입사일
           @d_retire_ymd          DATETIME2,		-- 퇴직일
           @d_sta_ymd             DATETIME2,		-- 입사일(퇴직기산일)
           @d_end_ymd             DATETIME2,		-- 퇴직일
		   @v_pay_group			  NVARCHAR(50),		-- 급여그룹
		   @v_biz_cd			  NVARCHAR(50),		-- 사업장
		   @v_reg_biz_cd		  NVARCHAR(50),		-- 신고사업장 
           @n_retire_turn_mon     NUMERIC(15),		-- 국민연금퇴직전환금
		   @v_pay_meth_cd		  NVARCHAR(50),		-- 급여지급방식코드[PAY_METH_CD]
		   @v_emp_cls_cd		  NVARCHAR(50),		-- 고용유형코드[PAY_EMP_CLS_CD]
		   @v_ins_type_yn		  NVARCHAR(1),		-- 퇴직연금가입여부
		   @v_ins_type_cd		  NVARCHAR(10),		-- 퇴직연금구분
		   @v_ins_nm			  NVARCHAR(80),		-- 퇴직연금사업자명
		   @v_ins_bizno			  NVARCHAR(50),		-- 퇴직연금사업장등록번호
		   @v_ins_account_no	  NVARCHAR(150),		-- 퇴직연금계좌번호
		   @d_retr_ymd			  DATETIME2,		-- 퇴직금기산일자
		   @v_rep_mid_yn		  NVARCHAR(1)		-- 중간정산여부

   SET @v_program_id = '[P_REP_ESTIMATION_MAKE]';
   SET @v_program_nm = '퇴직추계액 대상자생성';

   SET @av_ret_code     = 'SUCCESS!'
   SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)
   SET @d_mod_date = dbo.xf_sysdate(0)
   SET @d_begin_date = dbo.XF_TO_DATE(dbo.XF_TO_CHAR_D(@ad_std_ymd, 'YYYYMM') + '01', 'YYYYMMDD')	-- 추계월 1일자
PRINT('시작 ===> ' + CONVERT(VARCHAR, dbo.XF_SYSDATE(0)))
   -- *************************************************************
   -- 전표마감 Check
   -- *************************************************************
   SET @n_auto_yn_cnt = 0
   BEGIN
      SELECT @n_auto_yn_cnt = COUNT(*)
	    FROM REP_CALC_LIST A
       WHERE A.COMPANY_CD = @av_company_cd
	     AND A.CALC_TYPE_CD = @av_calc_type_cd
		 AND A.PAY_YMD = @ad_std_ymd
		 AND A.C1_END_YMD = @ad_std_ymd
		 AND ISNULL(A.AUTO_YN, 'N') = 'Y'
		 AND (@an_pay_group_id is NULL OR
			 dbo.F_PAY_GROUP_CHK(@an_pay_group_id, A.EMP_ID, @ad_std_ymd) = @an_pay_group_id) -- 급여그룹확인
         AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)                                    -- 입력한 소속가 있다면 입력한 소속 아니면 전체
         AND (@an_emp_id IS NULL OR A.EMP_ID = @an_emp_id)                                    -- 입력한 사원이 있다면 입력한 사원 아니면 전체
	  
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
      DELETE FROM REP_CALC_LIST
	   WHERE COMPANY_CD = @av_company_cd
	     AND CALC_TYPE_CD = @av_calc_type_cd
		 AND PAY_YMD = @ad_std_ymd
		-- AND C1_END_YMD = @ad_std_ymd
		 AND (@an_pay_group_id is NULL OR
			 dbo.F_PAY_GROUP_CHK(@an_pay_group_id, EMP_ID, @ad_std_ymd) = @an_pay_group_id) -- 급여그룹확인
         AND (@an_org_id IS NULL OR ORG_ID = @an_org_id)                                    -- 입력한 소속가 있다면 입력한 소속 아니면 전체
         AND (@an_emp_id IS NULL OR EMP_ID = @an_emp_id)                                    -- 입력한 사원이 있다면 입력한 사원 아니면 전체

	 IF @@ERROR <> 0
		BEGIN
			SET @av_ret_code    = 'FAILURE!'
			SET @av_ret_message = dbo.F_FRM_ERRMSG('기존 내역 삭제시 에러발생', @v_program_id , 0030 , null,  @an_mod_user_id)
			
			RETURN
		END

   END
PRINT('대상자 START 시작 ===> ' + CONVERT(VARCHAR, dbo.XF_SYSDATE(0)))
   -- *************************************************************
   -- 추계액 대상자 생성
   -- *************************************************************
   BEGIN
        DECLARE REP_CUR CURSOR LOCAL FORWARD_ONLY FOR
            SELECT A.EMP_ID																	-- 사원ID
                  ,A.ORG_ID																	-- 조직ID
				  ,A.POS_GRD_CD																-- 직급 [PHM_POS_GRD_CD]
                  ,A.POS_CD																	-- 직위 [PHM_POS_CD]
                  ,A.DUTY_CD																-- 직책 [PHM_DUTY_CD]
                  ,A.YEARNUM_CD																-- 호봉
				  ,A.MGR_TYPE_CD															-- 관리구분코드[PHM_MGR_TYPE_CD]
				  ,A.JOB_POSITION_CD														-- 직종코드[PHM_JOB_POSTION_CD]
				  ,A.JOB_CD																	-- 직무코드
				  ,A.EMP_KIND_CD															-- 근로구분코드 [PHM_EMP_KIND_CD]
				  ,dbo.F_REP_EXECUTIVE_RETIRE_YN(@av_company_cd, @av_locale_cd, @ad_std_ymd, A.EMP_ID,'1')		-- 임원여부
				  ,A.FIRST_JOIN_YMD															-- 최초입사일
                  ,dbo.XF_NVL_D(A.GROUP_YMD,A.HIRE_YMD)   							        -- 그룹입사일
                  ,ISNULL(A.RETIRE_YMD, @ad_std_ymd)										-- 퇴직일 OR 기준일
                  ,dbo.XF_NVL_D((SELECT RETR_YMD
                                  FROM PAY_PHM_EMP
                                 WHERE EMP_ID = A.EMP_ID ), dbo.XF_NVL_D(A.GROUP_YMD, A.HIRE_YMD)) AS C1_STA_YMD -- 정산시작일
                  ,ISNULL(A.RETIRE_YMD, @ad_std_ymd) AS C1_END_YMD							-- 정상종료일
                  ,dbo.F_REP_PEN_RETIRE_MON(A.EMP_ID, A.RETIRE_YMD) AS RETIRE_TURN          -- 국민연금퇴직전환금
				  ,dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', @ad_std_ymd, '1') AS ORG_NM
				  ,dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', @ad_std_ymd, 'LL') AS ORG_LINE
             FROM VI_PAY_PHM_EMP A
            WHERE A.COMPANY_CD = @av_company_cd
              AND A.LOCALE_CD = @av_locale_cd                                               -- 팩키지 기본(KO)
              AND A.EMP_KIND_CD != '9'                                                      -- 미구분이 아닌 직원
			  AND A.DUTY_CD != '018'														-- 사외이사 제외
			  AND DBO.XF_SUBSTR(A.EMP_NO, 1, 1) != 'Z'										-- 'Z'시작하는 사원 제외
              AND (@an_org_id IS NULL OR A.ORG_ID = @an_org_id)                             -- 입력한 소속가 있다면 입력한 소속 아니면 전체
              AND (@an_emp_id IS NULL OR A.EMP_ID = @an_emp_id)                             -- 입력한 사원이 있다면 입력한 사원 아니면 전체
			  AND dbo.XF_NVL_D(A.GROUP_YMD, A.HIRE_YMD) <= @ad_std_ymd						-- 기준일 이전 입사자
              --AND dbo.XF_NVL_D(A.GROUP_YMD, A.HIRE_YMD) <= DATEADD(MM, 1, DATEADD(YYYY, -1, @ad_std_ymd))  -- 입사1년 이상된사원
			  AND (@an_pay_group_id is NULL OR
				  dbo.F_PAY_GROUP_CHK(@an_pay_group_id, A.EMP_ID, @ad_std_ymd) = @an_pay_group_id) -- 급여그룹확인
              AND (A.RETIRE_YMD IS NULL OR A.RETIRE_YMD >= @d_begin_date)					-- 퇴직일자 NULL OR 기준일자 이후 퇴직자

            OPEN REP_CUR

            FETCH REP_CUR INTO @n_emp_id , @n_org_id, @v_pos_grd_cd , @v_pos_cd, @v_duty_cd , @v_yearnum_cd , @v_mgr_type_cd , 
							   @v_job_position_cd, @v_job_cd , @v_emp_kind_cd , @v_officers_yn, @d_first_join_ymd ,
							   @d_group_ymd , @d_retire_ymd ,@d_sta_ymd , @d_end_ymd , @n_retire_turn_mon,
							   @v_org_nm, @v_org_line

            WHILE (@@FETCH_STATUS = 0)

			-- ***************************************   
			-- 1. 기본자료    
			-- *************************************** 

            BEGIN
--PRINT('@n_emp_id ===> ' + CONVERT(VARCHAR, @n_emp_id))
				BEGIN
				   IF @d_retire_ymd > @ad_std_ymd
				      BEGIN
					     SET @d_retire_ymd = @ad_std_ymd
						 SET @d_end_ymd = @ad_std_ymd
					  END
				END
				-- 조직명, 조직라인
				--SET @v_org_nm = dbo.F_FRM_ORM_ORG_NM(@n_org_id, 'KO', @ad_std_ymd, '1')				 -- 조직명
				--SET @v_org_line = dbo.F_FRM_ORM_ORG_NM(@n_org_id, 'KO', @ad_std_ymd, 'LL')			 -- 조직라인
					     
				-- 급여마스터(PAY_PHM_EMP)에서 퇴직기산일, 급여지급방식, 고용유형정보를 가져온다.
				SET @v_pay_meth_cd = NULL
				SET @v_emp_cls_cd  = NULL
				BEGIN      
				   SELECT @v_pay_meth_cd = PAY_METH_CD		-- 급여지급방식코드[PAY_METH_CD] 
						 ,@v_emp_cls_cd  = EMP_CLS_CD		-- 고용유형코드[PAY_EMP_CLS_CD]   								     
					 FROM PAY_PHM_EMP      
					WHERE EMP_ID = @n_emp_id      
				   IF @@ERROR != 0                       
					  BEGIN      
						 SET @d_retr_ymd = @d_retire_ymd      
					  END      
				END

				---- 사업장 
				SET @v_biz_cd = dbo.F_ORM_ORG_BIZ(@n_org_id, @ad_std_ymd, 'PAY')
				set @v_biz_cd = ISNULL( @v_biz_cd, '001' )

				-- 신고사업장 
				SET @v_reg_biz_cd = dbo.F_ORM_ORG_BIZ(@n_org_id, @ad_std_ymd, 'REG')

				-- 급여그룹코드
				SET @v_pay_group = NULL
				BEGIN 
				   SELECT @v_pay_group = PAY_GROUP
					 FROM dbo.PAY_GROUP
                    WHERE PAY_GROUP_ID = @an_pay_group_id
                   
				   IF @@ERROR != 0
					BEGIN
						SET @v_pay_group = NULL
					END

			    END
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
						 ,@v_ins_bizno = INSUR_BIZ_NO
						 ,@v_ins_account_no = IRP_ACCOUNT_NO
					 FROM dbo.REP_INSUR_MON
                    WHERE EMP_ID = @n_emp_id
					  AND @ad_std_ymd BETWEEN STA_YMD AND END_YMD

                   IF @@ERROR != 0
					  BEGIN
						 SET @v_ins_type_yn = 'N'
						 SET @v_ins_type_cd = NULL
					  END
				END

				-- 중간정산여부
				SET @v_rep_mid_yn = 'N'
				BEGIN
				   SELECT TOP 1 @v_rep_mid_yn = 'Y'
					FROM REP_CALC_LIST
					WHERE REP_MID_YN = 'Y'  -- CALC_TYPE_CD = '02' --중간정산  ****회사마다 수정해야함    
                    AND END_YN = '1' --완료여부    
                    AND EMP_ID = @n_emp_id    
                    AND REP_CALC_LIST_ID <> @n_rep_calc_list_id 
					AND CALC_TYPE_CD IN ('01','02')
					AND C1_END_YMD < @d_end_ymd  

				   IF @@ROWCOUNT < 1
					BEGIN
						SET @v_rep_mid_yn = 'N'
					END

				END
--PRINT('@d_group_ymd ===> ' + CONVERT(VARCHAR, @d_group_ymd))
--PRINT('1년전 ===> ' + CONVERT(VARCHAR, DATEADD(MM, 1, DATEADD(YYYY, -1, @ad_std_ymd))))
            SET @n_rep_calc_list_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE

            BEGIN TRY
                    INSERT INTO dbo.REP_CALC_LIST (		-- 퇴직금계산대상자
								REP_CALC_LIST_ID        -- 퇴직금계산대상자ID
								,COMPANY_CD				-- 회사코드
								,PAY_YMD				-- 지급일
								,EMP_ID                 -- 사원ID
								,CALC_TYPE_CD			-- 정산구분[REP_CALC_TYPE_CD] 
								,RETIRE_YMD				-- 퇴직일 
								,CALC_RETIRE_CD			-- 퇴직(정산)유형[REP_CALC_RETIRE_CD]
								,ORG_ID					-- 발령부서ID 
								,PAY_ORG_ID				-- 급여부서ID 
								,POS_GRD_CD				-- 직급코드 [PHM_POS_GRD_CD]
								,POS_CD					-- 직위코드 [PHM_POS_CD]
								,ORG_NM					-- 조직명
								,ORG_LINE				-- 조직순차
								,BIZ_CD					-- 사업장
								,REG_BIZ_CD				-- 신고사업장
								,DUTY_CD				-- 직책코드 [PHM_DUTY_CD]
								,YEARNUM_CD				-- 호봉코드 [PHM_YEARNUM_CD]
								,MGR_TYPE_CD			-- 관리구분코드[PHM_MGR_TYPE_CD]
								,JOB_POSITION_CD		-- 직종코드[PHM_JOB_POSTION_CD]
								,JOB_CD					-- 직무코드
								,PAY_METH_CD			-- 급여지급방식[PAY_METH_CD]
								,EMP_CLS_CD				-- 고용유형[PAY_EMP_CLS_CD]
								,EMP_KIND_CD			-- 근로구분코드 [PHM_EMP_KIND_CD]
								,OFFICERS_YN			-- 임원여부
								,RETIRE_TYPE_CD			-- 퇴직사유 
								,CAM_TYPE_CD			-- 발령유형 
								,ARMY_HIRE_YMD			-- 군경력감안(인정)입사일 
								,CALCU_TPYE				-- 계산구분
								,PAY_GROUP				-- 급여그룹
								,FIRST_HIRE_YMD			-- 최초입사일
								,REP_MID_YN				-- 중간정산포함여부
								,INS_TYPE_YN			-- 퇴직연금가입여부
								,INS_TYPE_CD			-- 퇴직연금종류[RMP_INS_TYPE_CD]
								,REP_ANNUITY_BIZ_NM		-- 퇴직연금사업자명
								,REP_ANNUITY_BIZ_NO		-- 퇴직연금사업장등록번호
								,REP_ACCOUNT_NO			-- 퇴직연금계좌번호
								,FLAG					-- 1년미만여부
								,FLAG2					-- 중간정산(임금피크Y보통N)
								,C1_STA_YMD				-- 법정주(현)기산일 
                                ,C1_END_YMD				-- 주(현)정산일
								,SUM_END_YMD			-- 정산 퇴직일
								,RETIRE_TURN			-- 국민연금퇴직전환금
								,MOD_DATE				-- 변경일시
								,MOD_USER_ID			-- 변경자
								,TZ_CD					-- 타임존코드(입력자)
								,TZ_DATE				-- 타임존일시(입력일시)
                            )
                        VALUES (  
                                @n_rep_calc_list_id     -- 퇴직금계산대상자ID
								,@av_company_cd			-- 회사코드
								,@ad_std_ymd			-- 지급일
								,@n_emp_id              -- 사원ID
								,@av_calc_type_cd       -- 정산구분[REP_CALC_TYPE_CD] 
								,@d_retire_ymd          -- 퇴직일 
								,'06'					-- 퇴직(정산)유형[REP_CALC_RETIRE_CD]
								,@n_org_id				-- 발령부서ID 
								,@n_org_id				-- 급여부서ID 
								,@v_pos_grd_cd			-- 직급코드 [PHM_POS_GRD_CD]
								,@v_pos_cd				-- 직위코드 [PHM_POS_CD]
								,@v_org_nm				-- 조직명
								,@v_org_line			-- 조직순차
								,@v_biz_cd				-- 사업장
								,@v_reg_biz_cd			-- 신고사업장
								,@v_duty_cd				-- 직책코드 [PHM_DUTY_CD]
								,@v_yearnum_cd			-- 호봉코드 [PHM_YEARNUM_CD]
								,@v_mgr_type_cd			-- 관리구분코드[PHM_MGR_TYPE_CD]
								,@v_job_position_cd		-- 직종코드[PHM_JOB_POSTION_CD]
								,@v_job_cd				-- 직무코드
								,@v_pay_meth_cd			-- 급여지급방식[PAY_METH_CD]
								,@v_emp_cls_cd			-- 고용유형[PAY_EMP_CLS_CD]
								,@v_emp_kind_cd         -- 근로구분코드 [PHM_EMP_KIND_CD]
								,@v_officers_yn			-- 임원여부
								,NULL					-- 퇴직사유 
								,NULL					-- 발령유형 
								,NULL					-- 군경력감안(인정)입사일 
								,'2'					-- 계산구분 ('1'직접입력,'2'퇴직금계산, '9'컨버젼)
								,@v_pay_group			-- 급여그룹
								,@d_first_join_ymd		-- 최초입사일
								,@v_rep_mid_yn			-- 중간정산포함여부
								,@v_ins_type_yn			-- 퇴직연금가입여부
								,@v_ins_type_cd			-- 퇴직연금종류[RMP_INS_TYPE_CD]
								,@v_ins_nm				-- 퇴직연금사업자명
								,@v_ins_bizno			-- 퇴직연금사업장등록번호
								,@v_ins_account_no		-- 퇴직연금계좌번호
								,CASE WHEN @d_sta_ymd <= DATEADD(MM, 1, DATEADD(YYYY, -1, @ad_std_ymd)) THEN 'N' ELSE 'Y' END					-- 1년미만여부
								,'N'					-- 중간정산(임금피크Y보통N)
								,@d_sta_ymd				-- 법정주(현)기산일 
                                ,@d_end_ymd				-- 주(현)정산일
								,@d_end_ymd				-- 정산 퇴직일
								,@n_retire_turn_mon		-- 국민연금퇴직전환금
								,dbo.xf_sysdate(0)		-- 변경일시
								,@an_mod_user_id		-- 변경자 	numeric(18, 0)
								,'KST'					-- 타임존코드 	nvarchar(10)
								,dbo.xf_sysdate(0)		-- 타임존일시 	datetime2(7)
                                )
				IF @@ROWCOUNT < 1
					BEGIN
						PRINT 'INSERT FAILURE!' + 'CONTINUE'
					END
            END TRY

            BEGIN CATCH
                BEGIN
					--print 'Error:' + Error_message()
                    SET @av_ret_code = 'FAILURE!'
                    SET @av_ret_message  = dbo.F_FRM_ERRMSG('퇴직금계산대상자생성 에러' , @v_program_id,  0010,  ERROR_MESSAGE(),  @an_mod_user_id)
					
					--print 'Error:' + Error_message()
                    IF @@TRANCOUNT > 0
                        ROLLBACK WORK
					--print 'Error Rollback:' + Error_message()

					CLOSE REP_CUR
					DEALLOCATE REP_CUR
                    RETURN
                END

            END CATCH

            FETCH REP_CUR INTO @n_emp_id , @n_org_id, @v_pos_grd_cd , @v_pos_cd, @v_duty_cd , @v_yearnum_cd , @v_mgr_type_cd , 
							   @v_job_position_cd, @v_job_cd , @v_emp_kind_cd , @v_officers_yn, @d_first_join_ymd ,
							   @d_group_ymd , @d_retire_ymd ,@d_sta_ymd , @d_end_ymd , @n_retire_turn_mon,
							   @v_org_nm, @v_org_line
        END
        CLOSE REP_CUR
        DEALLOCATE REP_CUR 
   END
PRINT('종료 ===> ' + CONVERT(VARCHAR, dbo.XF_SYSDATE(0)))
   /*
   *    ***********************************************************
   *    작업 완료
   *    ***********************************************************
   */
   SET @av_ret_code = 'SUCCESS!'
   SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 완료..[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)

END
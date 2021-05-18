SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_REP_ESTIMATION]
    @av_company_cd     NVARCHAR(10),			-- 회사코드
    @av_locale_cd      NVARCHAR(10),			-- 국가코드
    @av_calc_type_cd   NVARCHAR(10),			-- 정산구분 ('03' : 퇴직추계)
	@ad_std_ymd        DATE,					-- 기준일자
	@ad_calc_sta_ymd   DATE,					-- 산정기간 시작일
	@ad_calc_end_ymd   DATE,					-- 산정기간 종료일
	@ad_res_yn		   NVARCHAR(10),			-- 전년도 적립분포함여부
	@an_pay_group_id   NUMERIC(38),				-- 급여그룹
	@an_org_id         NUMERIC(38),				-- 소속ID
    @an_emp_id         NUMERIC(38),				-- 사원ID
    @an_mod_user_id    NUMERIC(38),				-- 변경자
    @av_ret_code       NVARCHAR(50)  OUTPUT,	-- SUCCESS!/FAILURE!
    @av_ret_message    NVARCHAR(2000) OUTPUT    -- 결과메시지
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
 
           @n_emp_id              NUMERIC(38),		-- 사원ID
           @d_sta_ymd             DATE,		        --  법정주(현)기산일 - 입사일(정산일)
           @d_end_ymd             DATE,		        -- 주(현)정산일 - 퇴직일
		   @n_rep_calc_list_id    NUMERIC(38),		-- 퇴직정산ID
           @d_retire_ymd          DATETIME2,		-- 퇴직일
           @n_retire_turn_mon     NUMERIC(15),		-- 국민연금퇴직전환금
		   @v_emp_cls_cd		  NVARCHAR(50),		-- 고용유형코드[PAY_EMP_CLS_CD]
		   @v_mgr_type_cd		  NVARCHAR(50),		-- 관리구분 [PHM_MGR_TYPE_CD]
		   @v_officers_yn		  NVARCHAR(1),		-- 임원여부
		   @v_rep_mid_yn		  NVARCHAR(1),		-- 중간정산여부
		   @v_ins_type_cd		  NVARCHAR(10),		-- 퇴직연금구분
		   @v_ins_type_yn		  NVARCHAR(1),		-- 퇴직연금가입여부
		   @v_calc_type_cd		 NVARCHAR(50)		-- 정산구분[CALC_TYPE_CD]

		   ,@v_pay_group_cd			nvarchar(10)


   SET @v_program_id = '[P_REP_ESTIMATION]';
   SET @v_program_nm = '퇴직추계액실행';

   SET @av_ret_code     = 'SUCCESS!'
   SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)

   SET @d_mod_date = dbo.xf_sysdate(0)
   select @v_pay_group_cd = PAY_GROUP
     from PAY_GROUP
	where PAY_GROUP_ID = @an_pay_group_id
PRINT('CHECK ===> 1 ')
   -- *************************************************************
   -- 추계액 대상자 생성
   -- *************************************************************
   BEGIN
        DECLARE REP_CUR CURSOR LOCAL FORWARD_ONLY FOR
		    SELECT *
			  FROM (
					SELECT EMP_ID								-- 사원ID
						 , C1_STA_YMD							-- 입사일(정산일)
						 , C1_END_YMD							-- 주(현)정산일  
						 , REP_CALC_LIST_ID						-- 대상자 퇴직금ID     
						 , RETIRE_TURN							-- 국민연금퇴직전환금
						 , EMP_CLS_CD							-- 고용유형[PAY_EMP_CLS_CD]
						 , MGR_TYPE_CD							-- 관리구분코드[PHM_MGR_TYPE_CD]
						 , ISNULL(OFFICERS_YN, 'N')	AS OFFICERS_YN			-- 임원여부
						 , REP_MID_YN							-- 중간정산포함여부
						 , INS_TYPE_CD							-- 퇴직연금구분
						 , INS_TYPE_YN							-- 퇴직연금가입여부
						 , CALC_TYPE_CD							-- 정산구분[CALC_TYPE_CD]
					--	 , dbo.F_PAY_GROUP_CHK(@an_pay_group_id, EMP_ID, @ad_std_ymd) AS PAY_GROUP_ID
					  FROM REP_CALC_LIST      
					 WHERE COMPANY_CD = @av_company_cd
					   AND CALC_TYPE_CD = @av_calc_type_cd
					   AND PAY_YMD = @ad_std_ymd
					   AND PAY_GROUP = @v_pay_group_cd
					  -- AND (@an_pay_group_id is NULL OR
							--dbo.F_PAY_GROUP_CHK(@an_pay_group_id, EMP_ID, @ad_std_ymd) = @an_pay_group_id) -- 급여그룹확인
					   AND (@an_org_id IS NULL OR ORG_ID = @an_org_id)                                     -- 입력한 소속가 있다면 입력한 소속 아니면 전체
					   AND (@an_emp_id IS NULL OR EMP_ID = @an_emp_id)                                     -- 입력한 사원이 있다면 입력한 사원 아니면 전체
					   ) A
				 --WHERE PAY_GROUP_ID = @an_pay_group_id
        OPEN REP_CUR

        FETCH REP_CUR INTO @n_emp_id , @d_sta_ymd, @d_end_ymd , @n_rep_calc_list_id , @n_retire_turn_mon ,
			                @v_emp_cls_cd , @v_mgr_type_cd , @v_officers_yn , @v_rep_mid_yn , @v_ins_type_cd ,
							@v_ins_type_yn, @v_calc_type_cd
        WHILE (@@FETCH_STATUS = 0)
		BEGIN

PRINT('기초자료 시작 ===> 1 ' + FORMAT(SYSDATETIME(), 'HH:mm:ss.fffff'))
PRINT('@v_ins_type_cd ===> ' + @v_ins_type_cd)
PRINT('@v_calc_type_cd ===> ' + @v_calc_type_cd)
PRINT CASE WHEN @v_ins_type_cd='20' then 'P_REP_CAL_PAY_STD_DC_03' else 'P_REP_CAL_PAY_STD_03' end
			-- ***************************************   
			-- 1. 기초자료 확인 후 생성    
			-- *************************************** 
		
            BEGIN 
				IF @v_ins_type_cd = '20' -- DC형
				   BEGIN
				      EXEC dbo.P_REP_CAL_PAY_STD_DC_03 @av_company_cd, @av_locale_cd, @n_rep_calc_list_id, @ad_calc_sta_ymd, @ad_calc_end_ymd, @ad_res_yn, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT   
						IF @av_ret_code = 'FAILURE!'   
							BEGIN   
								SET @av_ret_code     = 'FAILURE!'   
								SET @av_ret_message  = @av_ret_message   
								RETURN   
							END
				   END
				ELSE
				   BEGIN   
					  EXEC dbo.P_REP_CAL_PAY_STD_03 @av_company_cd, @av_locale_cd, @n_rep_calc_list_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT   
					  IF @av_ret_code = 'FAILURE!'   
							BEGIN   
								SET @av_ret_code     = 'FAILURE!'   
								SET @av_ret_message  = @av_ret_message   
								RETURN   
							END   
				  END 
            END 

PRINT('평균임금 시작 ===> 2 ' + FORMAT(SYSDATETIME(), 'HH:mm:ss.fffff'))
PRINT('@v_ins_type_cd ===> ' + @v_ins_type_cd)	
			---- ***************************************   
			---- 2. 평균임금 산정   
			---- ***************************************  
            BEGIN 
				IF @v_ins_type_cd = '20' -- DC형
					BEGIN   
						EXEC dbo.P_REP_CAL_AVG_AMT_DC_03 @av_company_cd, @av_locale_cd, @n_rep_calc_list_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT   
						IF @av_ret_code = 'FAILURE!'   
							BEGIN   
								SET @av_ret_code     = 'FAILURE!'   
								SET @av_ret_message  = @av_ret_message   
								RETURN   
							END   
					END 
				ELSE
					BEGIN   
						EXEC dbo.P_REP_CAL_AVG_AMT_03 @av_company_cd, @av_locale_cd, @n_rep_calc_list_id, @an_mod_user_id, @av_ret_code OUTPUT, @av_ret_message OUTPUT   
						IF @av_ret_code = 'FAILURE!'   
							BEGIN   
								SET @av_ret_code     = 'FAILURE!'   
								SET @av_ret_message  = @av_ret_message   
								RETURN   
							END   
					END 
            END 

PRINT('평균임금 종료 ===> 3 ' + FORMAT(SYSDATETIME(), 'HH:mm:ss.fffff'))

            FETCH REP_CUR INTO @n_emp_id , @d_sta_ymd, @d_end_ymd , @n_rep_calc_list_id , @n_retire_turn_mon ,
			                   @v_emp_cls_cd , @v_mgr_type_cd , @v_officers_yn , @v_rep_mid_yn , @v_ins_type_cd ,
							   @v_ins_type_yn, @v_calc_type_cd
		END
        CLOSE REP_CUR
        DEALLOCATE REP_CUR      

   END

   /*
   *    ***********************************************************
   *    작업 완료
   *    ***********************************************************
   */
   SET @av_ret_code = 'SUCCESS!'
   SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 완료..[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)


END

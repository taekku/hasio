SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_PEB_CALC]
	@av_company_cd      NVARCHAR,       -- 인사영역
    @av_locale_cd       NVARCHAR,       -- 지역코드
    @an_plan_id         NUMERIC,         -- 인건비기준id
    @av_type_cd         NVARCHAR,       -- 인건비구분
    @an_mod_user_id     NUMERIC,         -- 변경자
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    -- ***************************************************************************
    --   TITLE       : 인건비계획생성
    ---  PROJECT     : 신인사정보시스템
    --   AUTHOR      : 강정화
    --   PROGRAM_ID  : P_PEB_CALC
    --   ARGUMENT    :
    --   RETURN      :
    --   HISTORY     :
    -- ***************************************************************************
BEGIN
    DECLARE
        /* 기본적으로 사용되는 변수 */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)

	  , @n_base_amt      NUMERIC  -- 기준금액
      , @n_emp_cnt       NUMERIC  -- 현재인원

	DECLARE 
		@t_peb_plan$AMT01	NUMERIC(15,0),
		@t_peb_plan$AMT02	NUMERIC(15,0),
		@t_peb_plan$AMT03	NUMERIC(15,0),
		@t_peb_plan$AMT04	NUMERIC(15,0),
		@t_peb_plan$AMT05	NUMERIC(15,0),
		@t_peb_plan$AMT06	NUMERIC(15,0),
		@t_peb_plan$AMT07	NUMERIC(15,0),
		@t_peb_plan$AMT08	NUMERIC(15,0),
		@t_peb_plan$AMT09	NUMERIC(15,0),
		@t_peb_plan$AMT10	NUMERIC(15,0),
		@t_peb_plan$AMT11	NUMERIC(15,0),
		@t_peb_plan$AMT12	NUMERIC(15,0)

    BEGIN
        SET @v_program_id   = 'P_PEB_CALC'
        SET @v_program_nm   = '인건비계획생성'
        SET @av_ret_code    = 'SUCCESS!'
        SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 시작..[ERR]',
                                         @v_program_id,  0000,  NULL, NULL);
    END



	BEGIN
		-- 기존자료삭제
		BEGIN
			-- 데모라서 주석처리. 2015년도 인건비계획이 생성 안되 2014년 데이터를 수정.
			DELETE FROM PEB_PLAN
			 WHERE PEB_BASE_ID = @an_plan_id
               AND PEB_TYPE_CD LIKE @av_type_cd

			IF @@ERROR <> 0
				BEGIN
					SET @av_ret_code    = 'FAILURE!' 
					SET @av_ret_message = dbo.F_FRM_ERRMSG('인건비계획 DELETE시 오류발생', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
					RETURN  
				END
		END


		BEGIN  -- BEGIN 1 START

			-- 기준조회
			DECLARE C1 CURSOR LOCAL FOR(
				SELECT *
				  FROM PEB_BASE
				 WHERE PEB_BASE_ID = @an_plan_id
				   AND COMPANY_CD = @av_company_cd
			)

			OPEN C1
			DECLARE @BASIC_YY	nvarchar(4),
					@COMPANY_CD	nvarchar(10),
					@ETC_CD1	nvarchar(50),
					@ETC_CD2	nvarchar(50),
					@MOD_DATE	date,
					@MOD_USER_ID	numeric(18,0),
					@NOTE	nvarchar(1000),
					@PEB_BASE_ID	numeric(18,0),
					@STD_YMD	date,
					@TZ_CD	nvarchar(10),
					@TZ_DATE	date
			      
			FETCH NEXT FROM C1 INTO @BASIC_YY, @COMPANY_CD, @ETC_CD1, @ETC_CD2, @MOD_DATE, @MOD_USER_ID, @NOTE, @PEB_BASE_ID, @STD_YMD, @TZ_CD, @TZ_DATE

			
			WHILE (@@FETCH_STATUS = 0)
				BEGIN  -- C1 WHILE BEGIN START
					
					
					-- 기준금액조회
					DECLARE BASE_AMT CURSOR LOCAL FOR(
						SELECT COUNT(B.EMP_ID) EMP_CNT,
							   dbo.XF_ROUND(SUM(B.B_PAY_AMT)/COUNT(B.EMP_ID),0) B_PAY_AMT,
							   dbo.XF_ROUND(SUM(B_BONUS_AMT)/COUNT(B.EMP_ID),0) B_BONUS_AMT,
							   dbo.XF_ROUND(SUM(B_RETIRE_AMT)/COUNT(B.EMP_ID),0) B_RETIRE_AMT,
							   dbo.XF_ROUND(SUM(B_STP_AMT)/COUNT(B.EMP_ID),0) B_STP_AMT,
							   dbo.XF_ROUND(SUM(B_NHS_AMT)/COUNT(B.EMP_ID),0) B_NHS_AMT,
							   dbo.XF_ROUND(SUM(B_EMI_AMT)/COUNT(B.EMP_ID),0) B_EMI_AMT,
							   dbo.XF_ROUND(SUM(B_IAI_AMT)/COUNT(B.EMP_ID),0) B_IAI_AMT,
							   dbo.XF_ROUND(SUM(B_CHANGE_AMT)/COUNT(B.EMP_ID),0) B_CHANGE_AMT,
							   dbo.XF_ROUND(SUM(B_TIME_AMT)/COUNT(B.EMP_ID),0) B_TIME_AMT,
								B.TYPE_03_CD, --CASE WHEN B.TYPE_03_CD = '112' THEN '112' ELSE '111' END TYPE_03_CD,
								B.ORG_ID
							FROM PEB_BASE_AMT B
							LEFT OUTER JOIN	(SELECT TYPE_03_CD,
										ORG_ID
									FROM ORM_ORG_PLAN
									WHERE COMPANY_CD = @COMPANY_CD
									AND BASE_YY = @BASIC_YY) A
							  ON B.ORG_ID = A.ORG_ID
							 AND B.TYPE_03_CD = A.TYPE_03_CD
						   WHERE B.PEB_BASE_ID = @PEB_BASE_ID
							 AND B.PAY_POS_GRD_CD != '100'
						   GROUP BY B.ORG_ID, B.TYPE_03_CD --CASE WHEN B.TYPE_03_CD = '112' THEN '112' ELSE '111' END
					)

					OPEN BASE_AMT

					DECLARE @EMP_CNT NUMERIC
					      , @B_PAY_AMT NUMERIC
						  , @B_BONUS_AMT NUMERIC
						  , @B_RETIRE_AMT NUMERIC
						  , @B_STP_AMT NUMERIC
						  , @B_NHS_AMT NUMERIC
						  , @B_EMI_AMT NUMERIC
						  , @B_IAI_AMT NUMERIC
						  , @B_CHANGE_AMT NUMERIC
						  , @B_TIME_AMT NUMERIC
						  , @TYPE_03_CD NVARCHAR
						  , @ORG_ID		NUMERIC


					FETCH NEXT FROM BASE_AMT INTO @EMP_CNT, @B_PAY_AMT, @B_BONUS_AMT, @B_BONUS_AMT, @B_STP_AMT, @B_NHS_AMT, @B_EMI_AMT, @B_IAI_AMT, @B_CHANGE_AMT, @B_TIME_AMT, @TYPE_03_CD, @ORG_ID

					WHILE (@@FETCH_STATUS = 0)
						BEGIN  -- BASE_AMT WHILE START
							 
							--인력계획 조회[직접변동비제외]
							DECLARE ORM CURSOR LOCAL FOR(
								SELECT *
								  FROM ORM_ORG_PLAN
								 WHERE ORG_ID = @ORG_ID
								   AND TYPE_03_CD = @TYPE_03_CD --CASE WHEN TYPE_03_CD = '112' THEN '112' ELSE '111' END = BASE_AMT.TYPE_03_CD
								   AND BASE_YY = @BASIC_YY
								 --ORDER BY ORG_ID, TYPE_01_CD, TYPE_02_CD, TYPE_03_CD
							)

							OPEN ORM

							DECLARE @ORG_ID2	numeric(38,0),
									@TYPE_01_CD	nvarchar(10),
									@TYPE_02_CD	nvarchar(10),
									@TYPE_03_CD2	nvarchar(10),
									@EMP_CNT1	numeric(10,0),
									@EMP_CNT2	numeric(10,0),
									@EMP_CNT3	numeric(10,0),
									@EMP_CNT4	numeric(10,0),
									@EMP_CNT5	numeric(10,0),
									@EMP_CNT6	numeric(10,0),
									@EMP_CNT7	numeric(10,0),
									@EMP_CNT8	numeric(10,0),
									@EMP_CNT9	numeric(10,0),
									@EMP_CNT10	numeric(10,0),
									@EMP_CNT11	numeric(10,0),
									@EMP_CNT12	numeric(10,0)
									
							
							FETCH NEXT FROM ORM INTO @ORG_ID2, @TYPE_01_CD, @TYPE_02_CD, @TYPE_03_CD2, @EMP_CNT1, @EMP_CNT2, @EMP_CNT3, @EMP_CNT4, @EMP_CNT5, @EMP_CNT6, @EMP_CNT7, @EMP_CNT8, @EMP_CNT9, @EMP_CNT10, @EMP_CNT11, @EMP_CNT12

							WHILE (@@FETCH_STATUS = 0)
								BEGIN  -- ORM WHILE START
									
									SET @n_emp_cnt = 0
									
									-- 현재인원조회
									BEGIN
										SELECT @n_emp_cnt = COUNT(EMP_ID)
										  FROM PEB_BASE_AMT
										 WHERE PEB_BASE_ID = @PEB_BASE_ID
										   AND ORG_ID = @ORG_ID2
										   AND TYPE_01_CD = @TYPE_01_CD
										   AND TYPE_02_CD = @TYPE_02_CD
										   AND TYPE_03_CD = @TYPE_03_CD

										IF @@ROWCOUNT = 0
											BEGIN
												SET @n_emp_cnt = 0
											END
										ELSE 
											BEGIN
												SET @n_emp_cnt = 0
											END
									END


									DECLARE CODE CURSOR LOCAL FOR(
										SELECT A.CD AS PEB_RATE_TYPE_CD,
											  B.CD AS PEB_ITEM_TYPE_CD,
											  ISNULL(C.PEB_RATE,0) AS PEB_RATE
										 FROM FRM_CODE A
										INNER JOIN FRM_CODE B
										   ON A.COMPANY_CD = B.COMPANY_CD
										  AND A.LOCALE_CD = B.LOCALE_CD
										 LEFT OUTER JOIN(SELECT PEB_TYPE_CD,
													            PEB_RATE
												           FROM PEB_RATE
												          WHERE PEB_BASE_ID = @PEB_BASE_ID) C
										   ON A.CD = C.PEB_TYPE_CD
										WHERE A.CD_KIND = 'PEB_RATE_TYPE_CD'
										  AND @STD_YMD BETWEEN A.STA_YMD AND A.END_YMD
										  AND A.COMPANY_CD = @COMPANY_CD
										  AND A.LOCALE_CD = @av_locale_cd
										  AND B.CD_KIND = 'PEB_ITEM_TYPE_CD'
										  AND @STD_YMD BETWEEN B.STA_YMD AND B.END_YMD
										  AND A.CD LIKE @av_type_cd
										  AND A.CD != '09'  -- 직접변동비는 따로 구해야함.
									   --ORDER BY A.ORD_NO, B.ORD_NO
									)

									OPEN CODE

									DECLARE @PEB_RATE_TYPE_CD NVARCHAR
									      , @PEB_ITEM_TYPE_CD NVARCHAR
										  , @PEB_RATE NUMERIC

									
									FETCH NEXT FROM CODE INTO @PEB_RATE_TYPE_CD, @PEB_ITEM_TYPE_CD, @PEB_RATE

									WHILE (@@FETCH_STATUS = 0)
										BEGIN -- CODE WHILE START
											BEGIN
												SET @n_base_amt = 0
												-- 기준금액
												SET @n_base_amt = CASE @PEB_RATE_TYPE_CD WHEN '01' THEN @B_PAY_AMT    -- 급여
																						 WHEN '02' THEN @B_BONUS_AMT  -- 상여
																						 WHEN '03' THEN @B_RETIRE_AMT -- 퇴직금
																						 WHEN '04' THEN @B_STP_AMT    -- 국민연금
																						 WHEN '05' THEN @B_NHS_AMT    -- 건강보험
																						 WHEN '06' THEN @B_EMI_AMT    -- 고용보험
																						 WHEN '07' THEN @B_IAI_AMT    -- 산재보험
																						 WHEN '08' THEN @B_CHANGE_AMT -- 간접변동비
																						 WHEN '09' THEN @B_TIME_AMT   -- 직접변동비
											END

											-- 인력계획 INSERT											
											INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- 인건비계획ID
																	PEB_BASE_ID     ,  -- 인건비계획기준ID
																	PEB_TYPE_CD     ,  -- 인건비구분
																	ORG_ID          ,  -- 소속
																	TYPE_01_CD      ,  -- 유형코드1
																	TYPE_02_CD      ,  -- 유형코드2
																	TYPE_03_CD      ,  -- 유형코드3
																	PEB_ITEM_TYPE   ,  -- 인건비세부구분
																	BASE_AMT        ,  -- 기준금액
																	EMP_CNT         ,  -- 현재인원
																	AMT01           ,  -- 1월
																	AMT02           ,  -- 2월
																	AMT03           ,  -- 3월
																	AMT04           ,  -- 4월
																	AMT05           ,  -- 5월
																	AMT06           ,  -- 6월
																	AMT07           ,  -- 7월
																	AMT08           ,  -- 8월
																	AMT09           ,  -- 9월
																	AMT10           ,  -- 10월
																	AMT11           ,  -- 11월
																	AMT12           ,  -- 12월
																	MOD_USER_ID     ,  -- 변경자
																	MOD_DATE        ,  -- 변경일시
																	TZ_CD           ,  -- 타임존코드
																	TZ_DATE            -- 타임존일시
																	)
															VALUES (NEXT VALUE FOR S_PEB_SEQUENCE  ,  -- 인건비기준금액ID
																	@an_plan_id              ,  -- 인건비계획기준ID
																	@PEB_RATE_TYPE_CD   ,  -- 인건비구분
																	@ORG_ID2              ,  -- 소속
																	@TYPE_01_CD          ,  -- 유형코드1
																	@TYPE_02_CD         ,  -- 유형코드2
																	@TYPE_03_CD         ,  -- 유형코드3
																	@PEB_ITEM_TYPE_CD   ,  -- 인건비세부구분
																	@n_base_amt              ,  -- 기준금액
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @n_emp_cnt    -- 인원
																	ELSE @n_base_amt*@n_emp_cnt END,  -- 현재인원
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT1    -- 인원
																	ELSE @n_base_amt*@EMP_CNT1 END,  -- 1월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT2    -- 인원
																	ELSE @n_base_amt*@EMP_CNT2 END,  -- 2월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT3    -- 인원
																		WHEN '02' THEN @n_base_amt*@EMP_CNT3  -- 현재년도
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT3)+(@n_base_amt*@EMP_CNT3*@PEB_RATE/100),0) END,  -- 3월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT4    -- 인원
																		WHEN '02' THEN @n_base_amt*@EMP_CNT4  -- 현재년도
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT4)+(@n_base_amt*@EMP_CNT4*@PEB_RATE/100),0) END,  -- 4월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT5    -- 인원
																		WHEN '02' THEN @n_base_amt*@EMP_CNT5  -- 현재년도
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT5)+(@n_base_amt*@EMP_CNT5*@PEB_RATE/100),0) END,  -- 5월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT6    -- 인원
																		WHEN '02' THEN @n_base_amt*@EMP_CNT6  -- 현재년도
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT6)+(@n_base_amt*@EMP_CNT6*@PEB_RATE/100),0) END,  -- 6월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT7    -- 인원
																		WHEN '02' THEN @n_base_amt*@EMP_CNT7  -- 현재년도
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT7)+(@n_base_amt*@EMP_CNT7*@PEB_RATE/100),0) END,  -- 7월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT8    -- 인원
																		WHEN '02' THEN @n_base_amt*@EMP_CNT8  -- 현재년도
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT8)+(@n_base_amt*@EMP_CNT8*@PEB_RATE/100),0) END,  -- 8월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT9    -- 인원
																		WHEN '02' THEN @n_base_amt*@EMP_CNT9  -- 현재년도
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT9)+(@n_base_amt*@EMP_CNT9*@PEB_RATE/100),0) END,  -- 9월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT10    -- 인원
																		WHEN '02' THEN @n_base_amt*@EMP_CNT10  -- 현재년도
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT10)+(@n_base_amt*@EMP_CNT10*@PEB_RATE/100),0) END,  -- 10월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT11    -- 인원
																		WHEN '02' THEN @n_base_amt*@EMP_CNT11  -- 현재년도
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT11)+(@n_base_amt*@EMP_CNT11*@PEB_RATE/100),0) END,  -- 11월
																	CASE @PEB_ITEM_TYPE_CD WHEN '01' THEN @EMP_CNT12    -- 인원
																		WHEN '02' THEN @n_base_amt*@EMP_CNT12  -- 현재년도
																	ELSE dbo.XF_ROUND((@n_base_amt*@EMP_CNT12)+(@n_base_amt*@EMP_CNT12*@PEB_RATE/100),0) END,  -- 12월
																	@an_mod_user_id    ,  -- 변경자
																	dbo.XF_SYSDATE(0)     ,  -- 변경일시
																	'KST'             ,  -- 타임존코드
																	dbo.XF_SYSDATE(0)        -- 타임존일시
																	)
											IF @@ERROR <> 0
												BEGIN
													SET @av_ret_code    = 'FAILURE!' 
													SET @av_ret_message = dbo.F_FRM_ERRMSG('인건비계획 INSERT시 오류발생', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
													RETURN  
												END
											

											FETCH NEXT FROM CODE INTO @PEB_RATE_TYPE_CD, @PEB_ITEM_TYPE_CD, @PEB_RATE
										END -- CODE WHILE END

									CLOSE CODE
									DEALLOCATE CODE

									FETCH NEXT FROM ORM INTO @ORG_ID2, @TYPE_01_CD, @TYPE_02_CD, @TYPE_03_CD2, @EMP_CNT1, @EMP_CNT2, @EMP_CNT3, @EMP_CNT4, @EMP_CNT5, @EMP_CNT6, @EMP_CNT7, @EMP_CNT8, @EMP_CNT9, @EMP_CNT10, @EMP_CNT11, @EMP_CNT12
								END -- ORM WHILE END
								
								CLOSE ORM
								DEALLOCATE ORM

							FETCH NEXT FROM BASE_AMT INTO @EMP_CNT, @B_PAY_AMT, @B_BONUS_AMT, @B_BONUS_AMT, @B_STP_AMT, @B_NHS_AMT, @B_EMI_AMT, @B_IAI_AMT, @B_CHANGE_AMT, @B_TIME_AMT, @TYPE_03_CD, @ORG_ID
						END  -- BASE_AMT WHILE END

						CLOSE BASE_AMT
						DEALLOCATE BASE_AMT





						BEGIN
							-- 평균구하기
							UPDATE PEB_PLAN 
							   SET AVG_AMT =dbo.XF_ROUND((AMT01+AMT02+AMT03+AMT04+AMT05+AMT06+AMT07+AMT08+AMT09+AMT10+AMT11+AMT12)/12,0)
							 WHERE PEB_BASE_ID = @PEB_BASE_ID
							   AND PEB_TYPE_CD LIKE @av_type_cd
						END

						BEGIN
							-- 전년대비구하기
							UPDATE PEB_PLAN 
							   SET J_AMT = AVG_AMT-EMP_CNT
							 WHERE PEB_BASE_ID = @PEB_BASE_ID
							   AND PEB_TYPE_CD LIKE @av_type_cd
						END

						DECLARE CHA CURSOR LOCAL FOR(
							SELECT ORG_ID, PEB_TYPE_CD,TYPE_01_CD, TYPE_02_CD, TYPE_03_CD,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN BASE_AMT ELSE 0 END) J_BASE_AMT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN BASE_AMT ELSE 0 END) BASE_AMT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN EMP_CNT ELSE 0 END) J_EMP_CNT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN EMP_CNT ELSE 0 END) EMP_CNT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT01 ELSE 0 END) J_AMT01,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT01 ELSE 0 END)   AMT01,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT02 ELSE 0 END) J_AMT02,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT02 ELSE 0 END)   AMT02,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT03 ELSE 0 END) J_AMT03,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT03 ELSE 0 END)   AMT03,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT04 ELSE 0 END) J_AMT04,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT04 ELSE 0 END)   AMT04,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT05 ELSE 0 END) J_AMT05,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT05 ELSE 0 END)   AMT05,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT06 ELSE 0 END) J_AMT06,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT06 ELSE 0 END)   AMT06,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT07 ELSE 0 END) J_AMT07,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT07 ELSE 0 END)   AMT07,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT08 ELSE 0 END) J_AMT08,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT08 ELSE 0 END)   AMT08,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT09 ELSE 0 END) J_AMT09,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT09 ELSE 0 END)   AMT09,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT10 ELSE 0 END) J_AMT10,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT10 ELSE 0 END)   AMT10,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT11 ELSE 0 END) J_AMT11,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT11 ELSE 0 END)   AMT11,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AMT12 ELSE 0 END) J_AMT12,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AMT12 ELSE 0 END)   AMT12,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN AVG_AMT ELSE 0 END) J_AVG_AMT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN AVG_AMT ELSE 0 END)   AVG_AMT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '02' THEN J_AMT ELSE 0 END) J_J_AMT,
								  SUM(CASE WHEN PEB_ITEM_TYPE = '03' THEN J_AMT ELSE 0 END)   J_AMT
							 FROM PEB_PLAN
							WHERE PEB_ITEM_TYPE IN ('02','03')
							  AND PEB_BASE_ID = @PEB_BASE_ID
							  AND PEB_TYPE_CD LIKE @av_type_cd
						   GROUP BY  ORG_ID, PEB_TYPE_CD,TYPE_01_CD, TYPE_02_CD, TYPE_03_CD
						)


						OPEN CHA 

						DECLARE @CHA_ORG_ID numeric(18,0)
						      , @PEB_TYPE_CD nvarchar(10)
							  , @CHA_TYPE_01_CD nvarchar(10)
							  , @CHA_TYPE_02_CD nvarchar(10)
							  , @CHA_TYPE_03_CD  nvarchar(10)
							  , @J_BASE_AMT numeric(15,0)
							  , @BASE_AMT numeric(15,0)
							  , @J_EMP_CNT numeric(15,0)
							  , @CHA_EMP_CNT numeric(15,0)
							  , @J_AMT01 numeric(15,0)
							  , @AMT01 numeric(15,0)
							  , @J_AMT02 numeric(15,0)
							  , @AMT02 numeric(15,0)
							  , @J_AMT03 numeric(15,0)
							  , @AMT03 numeric(15,0)
							  , @J_AMT04 numeric(15,0)
							  , @AMT04 numeric(15,0)
							  , @J_AMT05 numeric(15,0)
							  , @AMT05 numeric(15,0)
							  , @J_AMT06 numeric(15,0)
							  , @AMT06 numeric(15,0)
							  , @J_AMT07 numeric(15,0)
							  , @AMT07 numeric(15,0)
							  , @J_AMT08 numeric(15,0)
							  , @AMT08 numeric(15,0)
							  , @J_AMT09 numeric(15,0)
							  , @AMT09 numeric(15,0)
							  , @J_AMT10 numeric(15,0)
							  , @AMT10 numeric(15,0)
							  , @J_AMT11 numeric(15,0)
							  , @AMT11 numeric(15,0)
							  , @J_AMT12 numeric(15,0)
							  , @AMT12 numeric(15,0)
							  , @J_AVG_AMT numeric(15,0)
							  , @AVG_AMT numeric(15,0)
							  , @J_J_AMT numeric(15,0)
							  , @J_AMT numeric(15,0)
						
						FETCH NEXT FROM CHA INTO @CHA_ORG_ID, @PEB_TYPE_CD, @CHA_TYPE_01_CD, @CHA_TYPE_02_CD, @CHA_TYPE_03_CD, @J_BASE_AMT, @BASE_AMT, @J_EMP_CNT, @CHA_EMP_CNT, @J_AMT01, @AMT01
						                       , @J_AMT02, @AMT02, @J_AMT03, @AMT03, @J_AMT04, @AMT04, @J_AMT05, @AMT05, @J_AMT06, @AMT06, @J_AMT07, @AMT07, @J_AMT08, @AMT08, @J_AMT09, @AMT09
											   , @J_AMT10, @AMT10, @J_AMT11, @AMT11, @J_AMT12, @AMT12, @J_AVG_AMT, @AVG_AMT, @J_J_AMT, @J_AMT


						WHILE (@@FETCH_STATUS = 0)
							BEGIN	-- CHA WHILE START
								 UPDATE PEB_PLAN
									SET BASE_AMT  = @BASE_AMT - @J_BASE_AMT,
										EMP_CNT   = @CHA_EMP_CNT - @J_EMP_CNT,
										AMT01     = @AMT01   - @J_AMT01,
										AMT02     = @AMT02   - @J_AMT02,
										AMT03     = @AMT03   - @J_AMT03,
										AMT04     = @AMT04   - @J_AMT04,
										AMT05     = @AMT05   - @J_AMT05,
										AMT06     = @AMT06   - @J_AMT06,
										AMT07     = @AMT07   - @J_AMT07,
										AMT08     = @AMT08   - @J_AMT08,
										AMT09     = @AMT09   - @J_AMT09,
										AMT10     = @AMT10   - @J_AMT10,
										AMT11     = @AMT11   - @J_AMT11,
										AMT12     = @AMT12   - @J_AMT12,
										AVG_AMT   = @AVG_AMT - @J_AVG_AMT,
										J_AMT     = @J_AMT   - @J_J_AMT
								  WHERE PEB_ITEM_TYPE = '04'
									AND PEB_BASE_ID = @PEB_BASE_ID
									AND ORG_ID = @CHA_ORG_ID
									AND PEB_TYPE_CD = @PEB_TYPE_CD
									AND TYPE_01_CD = @CHA_TYPE_01_CD
									AND TYPE_02_CD = @CHA_TYPE_02_CD
									AND TYPE_03_CD = @CHA_TYPE_03_CD
								
								IF @@ERROR <> 0
									BEGIN
										SET @av_ret_code    = 'FAILURE!' 
										SET @av_ret_message = dbo.F_FRM_ERRMSG('인건비계획 차액 UPDATE시 오류발생', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
										RETURN  
									END

								FETCH NEXT FROM CHA INTO @CHA_ORG_ID, @PEB_TYPE_CD, @CHA_TYPE_01_CD, @CHA_TYPE_02_CD, @CHA_TYPE_03_CD, @J_BASE_AMT, @BASE_AMT, @J_EMP_CNT, @CHA_EMP_CNT, @J_AMT01, @AMT01
													   , @J_AMT02, @AMT02, @J_AMT03, @AMT03, @J_AMT04, @AMT04, @J_AMT05, @AMT05, @J_AMT06, @AMT06, @J_AMT07, @AMT07, @J_AMT08, @AMT08, @J_AMT09, @AMT09
													   , @J_AMT10, @AMT10, @J_AMT11, @AMT11, @J_AMT12, @AMT12, @J_AVG_AMT, @AVG_AMT, @J_J_AMT, @J_AMT
							END	    -- CHA WHILE END
						      
							CLOSE CHA
							DEALLOCATE CHA

					-- 길은아대리와 협의[2013.12.18일 전화통화로 협의]
					-- 직접변동비인경우 기준시급 : 해당소속의 직접인력에 대한 기준시급을 구하여 현장작업자/비생산인력에 똑같이 기준시급을 적용한다.
					-- 인상율은 3월부터 기준시급에 반영하여 생성한다.
					-- 3교대근무의 정규직3조, 2교대근무의 정규직2조인경우 *2, 나머지는 *1.5배 지급한다.
					-- 기준금액조회[직접변동비기준 시급]

					IF @av_type_cd IN ('%', '09')
						BEGIN
							
							DECLARE BASE_AMT1 CURSOR LOCAL FOR(
								SELECT COUNT(B.EMP_ID) AS EMP_CNT,
										dbo.XF_ROUND(SUM(B_TIME_AMT)/COUNT(B.EMP_ID),0) AS B_TIME_AMT,
										B.ORG_ID,
										MAX(C.PEB_RATE) PEB_RATE
									FROM (SELECT DISTINCT ORG_ID
											FROM ORM_ORG_PAY_PLAN
											WHERE COMPANY_CD = @COMPANY_CD
											AND BASE_YY = @BASIC_YY) A
									LEFT OUTER JOIN PEB_BASE_AMT B
									ON B.ORG_ID = A.ORG_ID
									INNER JOIN PEB_RATE C
									ON B.PEB_BASE_ID = C.PEB_BASE_ID
									WHERE B.TYPE_03_CD = '112'  -- 직접직인원만으로 구한다.
									AND B.PEB_BASE_ID = @PEB_BASE_ID
									AND C.PEB_TYPE_CD = '09'
								GROUP BY B.ORG_ID
							)

							OPEN BASE_AMT1 

							DECLARE @BASE_EMP_CNT NUMERIC
									, @BASE_B_TIME_AMT NUMERIC
									, @BASE_ORG_ID NUMERIC
									, @BASE_PEB_RATE NUMERIC

							FETCH NEXT FROM BASE_AMT1 INTO @PEB_RATE_TYPE_CD, @PEB_ITEM_TYPE_CD, @PEB_RATE
							
							WHILE (@@FETCH_STATUS = 0)
								BEGIN  -- BASE_AMT1 WHILE START
									BEGIN
										SET @n_base_amt = 0
										SET @n_base_amt = @BASE_B_TIME_AMT
									END

									--인력계획 조회[근무일수,휴일일수]
									DECLARE ORM1 CURSOR LOCAL FOR(
										 SELECT ORG_ID,
												TYPE_01_CD,
												TYPE_02_CD,
												TYPE_03_CD,
												EMP_CNT1,
												EMP_CNT2,
												EMP_CNT3,
												EMP_CNT4,
												EMP_CNT5,
												EMP_CNT6,
												EMP_CNT7,
												EMP_CNT8,
												EMP_CNT9,
												EMP_CNT10,
												EMP_CNT11,
												EMP_CNT12
										   FROM ORM_ORG_PAY_PLAN
										  WHERE ORG_ID = @BASE_ORG_ID
											AND TYPE_03_CD IN ('1110', '1120')
											AND BASE_YY = @BASIC_YY
										 --ORDER BY ORG_ID
									)

									OPEN ORM1 

									DECLARE @ORM1_ORG_ID	numeric(38,0),
											@ORM1_TYPE_01_CD	nvarchar(10),
											@ORM1_TYPE_02_CD	nvarchar(10),
											@ORM1_TYPE_03_CD	nvarchar(10),
											@ORM1_EMP_CNT1	numeric(10,0),
											@ORM1_EMP_CNT2	numeric(10,0),
											@ORM1_EMP_CNT3	numeric(10,0),
											@ORM1_EMP_CNT4	numeric(10,0),
											@ORM1_EMP_CNT5	numeric(10,0),
											@ORM1_EMP_CNT6	numeric(10,0),
											@ORM1_EMP_CNT7	numeric(10,0),
											@ORM1_EMP_CNT8	numeric(10,0),
											@ORM1_EMP_CNT9	numeric(10,0),
											@ORM1_EMP_CNT10	numeric(10,0),
											@ORM1_EMP_CNT11	numeric(10,0),
											@ORM1_EMP_CNT12	numeric(10,0)
									
									FETCH NEXT FROM ORM1 INTO @ORM1_ORG_ID, @ORM1_TYPE_01_CD, @ORM1_TYPE_02_CD, @ORM1_TYPE_03_CD, @ORM1_EMP_CNT1, @ORM1_EMP_CNT2, @ORM1_EMP_CNT3, @ORM1_EMP_CNT4, @ORM1_EMP_CNT5
									                        , @ORM1_EMP_CNT6, @ORM1_EMP_CNT7, @ORM1_EMP_CNT8, @ORM1_EMP_CNT9, @ORM1_EMP_CNT10, @ORM1_EMP_CNT11, @ORM1_EMP_CNT12

									WHILE (@@FETCH_STATUS = 0 )
										 -- 인력계획 INSERT
										BEGIN  -- ORM1 WHILE START
											BEGIN
												INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- 인건비계획ID
																	  PEB_BASE_ID     ,  -- 인건비계획기준ID
																	  PEB_TYPE_CD     ,  -- 인건비구분
																	  ORG_ID          ,  -- 소속
																	  TYPE_01_CD      ,  -- 유형코드1
																	  TYPE_02_CD      ,  -- 유형코드2
																	  TYPE_03_CD      ,  -- 유형코드3
																	  PEB_ITEM_TYPE   ,  -- 인건비세부구분
																	  BASE_AMT        ,  -- 기준금액
																	  EMP_CNT         ,  -- 현재인원
																	  AMT01           ,  -- 1월
																	  AMT02           ,  -- 2월
																	  AMT03           ,  -- 3월
																	  AMT04           ,  -- 4월
																	  AMT05           ,  -- 5월
																	  AMT06           ,  -- 6월
																	  AMT07           ,  -- 7월
																	  AMT08           ,  -- 8월
																	  AMT09           ,  -- 9월
																	  AMT10           ,  -- 10월
																	  AMT11           ,  -- 11월
																	  AMT12           ,  -- 12월
																	  MOD_USER_ID     ,  -- 변경자
																	  MOD_DATE        ,  -- 변경일시
																	  TZ_CD           ,  -- 타임존코드
																	  TZ_DATE            -- 타임존일시
																	  )
															  VALUES (NEXT VALUE FOR S_PEB_SEQUENCE,  -- 인건비기준금액ID
																	  @an_plan_id              ,  -- 인건비계획기준ID
																	  '09'                    ,  -- 인건비구분
																	  @ORM1_ORG_ID             ,  -- 소속
																	  @ORM1_TYPE_01_CD         ,  -- 유형코드1
																	  @ORM1_TYPE_02_CD         ,  -- 유형코드2
																	  @ORM1_TYPE_03_CD         ,  -- 유형코드3
																	  @ORM1_TYPE_03_CD         ,  -- 인건비세부구분
																	  @n_base_amt              ,  -- 기준금액
																	  @BASE_EMP_CNT,  -- 현재인원
																	  @ORM1_EMP_CNT1,  -- 1월
																	  @ORM1_EMP_CNT2,
																	  @ORM1_EMP_CNT3,
																	  @ORM1_EMP_CNT4,
																	  @ORM1_EMP_CNT5,
																	  @ORM1_EMP_CNT6,
																	  @ORM1_EMP_CNT7,
																	  @ORM1_EMP_CNT8,
																	  @ORM1_EMP_CNT9,
																	  @ORM1_EMP_CNT10,
																	  @ORM1_EMP_CNT11,
																	  @ORM1_EMP_CNT12,
																	  @an_mod_user_id    ,  -- 변경자
																	  dbo.XF_SYSDATE(0)     ,  -- 변경일시
																	  'KST'             ,  -- 타임존코드
																	  dbo.XF_SYSDATE(0)        -- 타임존일시
																	 )
												IF @@ERROR <> 0
													BEGIN
														SET @av_ret_code    = 'FAILURE!' 
														SET @av_ret_message = dbo.F_FRM_ERRMSG('직접변동비 근무일수/휴일일수 INSERT시 오류발생', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
														RETURN  
													END
											END
											FETCH NEXT FROM ORM1 INTO @ORM1_ORG_ID, @ORM1_TYPE_01_CD, @ORM1_TYPE_02_CD, @ORM1_TYPE_03_CD, @ORM1_EMP_CNT1, @ORM1_EMP_CNT2, @ORM1_EMP_CNT3, @ORM1_EMP_CNT4, @ORM1_EMP_CNT5
																	, @ORM1_EMP_CNT6, @ORM1_EMP_CNT7, @ORM1_EMP_CNT8, @ORM1_EMP_CNT9, @ORM1_EMP_CNT10, @ORM1_EMP_CNT11, @ORM1_EMP_CNT12
										END  -- ORM1 WHILE END
										CLOSE ORM1 
										DEALLOCATE ORM1
-- 1000 현장작업자
-- 2000 비생산인력

-- 1110 2교대
-- 1120 3교대
-- 1210 초과근무

-- 1110 근무일수
-- 1120 휴일일수
-- 1210 정직원(1조)
-- 1220 정직원(2조)
-- 1230 정직원(3조)
-- 1310 사무직(정규)
-- 1320 현장비작업자(정규)
-- 3110 인원
-- 3120 금액
										-- 인원입력
										BEGIN
											INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- 인건비계획ID
																PEB_BASE_ID     ,  -- 인건비계획기준ID
																PEB_TYPE_CD     ,  -- 인건비구분
																ORG_ID          ,  -- 소속
																TYPE_01_CD      ,  -- 유형코드1
																TYPE_02_CD      ,  -- 유형코드2
																TYPE_03_CD      ,  -- 유형코드3
																PEB_ITEM_TYPE   ,  -- 인건비세부구분
																BASE_AMT        ,  -- 기준금액
																EMP_CNT         ,  -- 현재인원
																AMT01           ,  -- 1월
																AMT02           ,  -- 2월
																AMT03           ,  -- 3월
																AMT04           ,  -- 4월
																AMT05           ,  -- 5월
																AMT06           ,  -- 6월
																AMT07           ,  -- 7월
																AMT08           ,  -- 8월
																AMT09           ,  -- 9월
																AMT10           ,  -- 10월
																AMT11           ,  -- 11월
																AMT12           ,  -- 12월
																MOD_USER_ID     ,  -- 변경자
																MOD_DATE        ,  -- 변경일시
																TZ_CD           ,  -- 타임존코드
																TZ_DATE            -- 타임존일시
																)
															SELECT NEXT VALUE FOR S_PEB_SEQUENCE,  -- 인건비기준금액ID
																@an_plan_id              ,  -- 인건비계획기준ID
																'09'                    ,  -- 인건비구분
																ORG_ID             ,  -- 소속
																TYPE_01_CD         ,  -- 유형코드1
																TYPE_02_CD         ,  -- 유형코드2
																TYPE_03_CD         ,  -- 유형코드3
																'3110'             ,  -- 인건비세부구분
																@n_base_amt         ,  -- 기준금액
																@BASE_EMP_CNT,  -- 현재인원
																EMP_CNT1,  -- 1월
																EMP_CNT2,  -- 2월
																EMP_CNT3,  -- 3월
																EMP_CNT4,  -- 4월
																EMP_CNT5,  -- 5월
																EMP_CNT6,  -- 6월
																EMP_CNT7,  -- 7월
																EMP_CNT8,  -- 8월
																EMP_CNT9,  -- 9월
																EMP_CNT10,  -- 10월
																EMP_CNT11,  -- 11월
																EMP_CNT12,  -- 12월
																@an_mod_user_id    ,  -- 변경자
																dbo.XF_SYSDATE(0)     ,  -- 변경일시
																'KST'             ,  -- 타임존코드
																dbo.XF_SYSDATE(0)        -- 타임존일시
															FROM ORM_ORG_PAY_PLAN
															WHERE ORG_ID = @BASE_ORG_ID
															AND TYPE_03_CD NOT IN ('1110', '1120')
															AND BASE_YY = @BASIC_YY
											IF @@ERROR <> 0
												BEGIN
													SET @av_ret_code    = 'FAILURE!' 
													SET @av_ret_message = dbo.F_FRM_ERRMSG('직접변동비 인원 INSERT시 오류발생', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
													RETURN  
												END
										END


										BEGIN
											-- 특근수당 입력
											-- 인원조회
											DECLARE OT CURSOR LOCAL FOR(
												SELECT AMT01
													 , AMT02
													 , AMT03
													 , AMT04
													 , AMT05
													 , AMT06
													 , AMT07
													 , AMT08
													 , AMT09
													 , AMT10
													 , AMT11
													 , AMT12
													 , AVG_AMT
													 , BASE_AMT
													 , B_ORG_ID
													 , EMP_CNT
													 , ETC_CD1
													 , ETC_CD2
													 , G_ORG_ID
													 , J_AMT
													 , MOD_DATE
													 , MOD_USER_ID
													 , NOTE
													 , ORG_ID
													 , PEB_BASE_ID
													 , PEB_ITEM_TYPE
													 , PEB_PLAN_ID
													 , PEB_TYPE_CD
													 , TYPE_01_CD
													 , TYPE_02_CD
													 , TYPE_03_CD
												 FROM PEB_PLAN
												WHERE PEB_BASE_ID = @PEB_BASE_ID
												  AND ORG_ID = @BASE_ORG_ID
												  AND PEB_ITEM_TYPE = '3110'
											)

											OPEN OT

											DECLARE @OT_AMT01	numeric(15,0),
													@OT_AMT02	numeric(15,0),
													@OT_AMT03	numeric(15,0),
													@OT_AMT04	numeric(15,0),
													@OT_AMT05	numeric(15,0),
													@OT_AMT06	numeric(15,0),
													@OT_AMT07	numeric(15,0),
													@OT_AMT08	numeric(15,0),
													@OT_AMT09	numeric(15,0),
													@OT_AMT10	numeric(15,0),
													@OT_AMT11	numeric(15,0),
													@OT_AMT12	numeric(15,0),
													@OT_AVG_AMT	numeric(15,0),
													@OT_BASE_AMT	numeric(15,0),
													@OT_B_ORG_ID	numeric(18,0),
													@OT_EMP_CNT	numeric(15,0),
													@OT_ETC_CD1	nvarchar(50),
													@OT_ETC_CD2	nvarchar(50),
													@OT_G_ORG_ID	numeric(18,0),
													@OT_J_AMT	numeric(10,2),
													@OT_MOD_DATE	date,
													@OT_MOD_USER_ID	numeric(18,0),
													@OT_NOTE	nvarchar(4000),
													@OT_ORG_ID	numeric(18,0),
													@OT_PEB_BASE_ID	numeric(18,0),
													@OT_PEB_ITEM_TYPE	nvarchar(10),
													@OT_PEB_PLAN_ID	numeric(18,0),
													@OT_PEB_TYPE_CD	nvarchar(10),
													@OT_TYPE_01_CD	nvarchar(10),
													@OT_TYPE_02_CD	nvarchar(10),
													@OT_TYPE_03_CD	nvarchar(10)
											

											FETCH NEXT FROM OT INTO @OT_AMT01 , @OT_AMT02, @OT_AMT03, @OT_AMT04, @OT_AMT05, @OT_AMT06, @OT_AMT07, @OT_AMT08, @OT_AMT09, @OT_AMT10, @OT_AMT11, @OT_AMT12, @OT_AVG_AMT, @OT_BASE_AMT,
						                        @OT_B_ORG_ID, @OT_EMP_CNT, @OT_ETC_CD1, @OT_ETC_CD2, @OT_G_ORG_ID, @OT_J_AMT, @OT_MOD_DATE, @OT_MOD_USER_ID, @OT_NOTE, @OT_ORG_ID, @OT_PEB_BASE_ID, @OT_PEB_ITEM_TYPE,
												@OT_PEB_PLAN_ID, @OT_PEB_TYPE_CD, @OT_TYPE_01_CD, @OT_TYPE_02_CD, @OT_TYPE_03_CD	

											
											WHILE (@@FETCH_STATUS = 0)
												BEGIN	-- OT WHILE START
													-- 초과근무인경우 근무일수를 곱한다.
													-- 시급 * 인원 * 근무일수 * 인상율(3월부터적용) * 1.5
													IF @OT_TYPE_02_CD = '1210' 
														BEGIN
															-- 초과근무일경우 인원조회[2교대의 직간접구분이 같은 경우의 인원으로 한다.]
															BEGIN
																SELECT @t_peb_plan$AMT01 = AMT01
																	 , @t_peb_plan$AMT02 = AMT02
																	 , @t_peb_plan$AMT03 = AMT03
																	 , @t_peb_plan$AMT04 = AMT04
																	 , @t_peb_plan$AMT05 = AMT05
																	 , @t_peb_plan$AMT06 = AMT06
																	 , @t_peb_plan$AMT07 = AMT07
																	 , @t_peb_plan$AMT08 = AMT08
																	 , @t_peb_plan$AMT09 = AMT09
																	 , @t_peb_plan$AMT10 = AMT10
																	 , @t_peb_plan$AMT11 = AMT11
																	 , @t_peb_plan$AMT12 = AMT12
																  FROM PEB_PLAN
																 WHERE PEB_BASE_ID = @OT_PEB_BASE_ID
																   AND ORG_ID = @OT_ORG_ID
																   AND PEB_ITEM_TYPE = '3110'
																   AND TYPE_02_CD = '1110'
																   AND TYPE_03_CD = @OT_TYPE_03_CD
															END

															-- 인력계획 INSERT
															BEGIN
																INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- 인건비계획ID
																					  PEB_BASE_ID     ,  -- 인건비계획기준ID
																					  PEB_TYPE_CD     ,  -- 인건비구분
																					  ORG_ID          ,  -- 소속
																					  TYPE_01_CD      ,  -- 유형코드1
																					  TYPE_02_CD      ,  -- 유형코드2
																					  TYPE_03_CD      ,  -- 유형코드3
																					  PEB_ITEM_TYPE   ,  -- 인건비세부구분
																					  BASE_AMT        ,  -- 기준금액
																					  EMP_CNT         ,  -- 현재인원
																					  AMT01           ,  -- 1월
																					  AMT02           ,  -- 2월
																					  AMT03           ,  -- 3월
																					  AMT04           ,  -- 4월
																					  AMT05           ,  -- 5월
																					  AMT06           ,  -- 6월
																					  AMT07           ,  -- 7월
																					  AMT08           ,  -- 8월
																					  AMT09           ,  -- 9월
																					  AMT10           ,  -- 10월
																					  AMT11           ,  -- 11월
																					  AMT12           ,  -- 12월
																					  NOTE            ,  -- 비고
																					  MOD_USER_ID     ,  -- 변경자
																					  MOD_DATE        ,  -- 변경일시
																					  TZ_CD           ,  -- 타임존코드
																					  TZ_DATE            -- 타임존일시
																					  )
																			   SELECT NEXT VALUE FOR S_PEB_SEQUENCE,  -- 인건비기준금액ID
																					  @an_plan_id              ,  -- 인건비계획기준ID
																					  '09'                    ,  -- 인건비구분
																					  @OT_ORG_ID             ,  -- 소속
																					  @OT_TYPE_01_CD         ,  -- 유형코드1
																					  @OT_TYPE_02_CD         ,  -- 유형코드2
																					  @OT_TYPE_03_CD         ,  -- 유형코드3
																					  '3120'                ,  -- 인건비세부구분
																					  @n_base_amt              ,  -- 기준금액
																					  @BASE_EMP_CNT,  -- 현재인원
																					  dbo.XF_ROUND(@n_base_amt * @OT_AMT01 * AMT01 * @t_peb_plan$AMT01,0),  -- 1월
																					  dbo.XF_ROUND(@n_base_amt * @OT_AMT02 * AMT02 * @t_peb_plan$AMT02,0),  -- 2월
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT03 * AMT03 * @t_peb_plan$AMT03,0),  -- 3월
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT04 * AMT04 * @t_peb_plan$AMT04,0),  -- 4월
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT05 * AMT05 * @t_peb_plan$AMT05,0),  -- 5월
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT06 * AMT06 * @t_peb_plan$AMT06,0),  -- 6월
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT07 * AMT07 * @t_peb_plan$AMT07,0),  -- 7월
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT08 * AMT08 * @t_peb_plan$AMT08,0),  -- 8월
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT09 * AMT09 * @t_peb_plan$AMT09,0),  -- 9월
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT10 * AMT10 * @t_peb_plan$AMT10,0),  -- 10월
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT11 * AMT11 * @t_peb_plan$AMT11,0),  -- 11월
																					  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) *@OT_AMT12 * AMT12 * @t_peb_plan$AMT12,0),  -- 12월
																					  '(시급['+@n_base_amt+'] + 인상율(3월부터적용)['+@n_base_amt*@BASE_PEB_RATE/100+']) * 인원 * 시간[2교대인원] * 근무일수 * 1.5',
																					  @an_mod_user_id    ,  -- 변경자
																					  dbo.XF_SYSDATE(0)     ,  -- 변경일시
																					  'KST'             ,  -- 타임존코드
																					  dbo.XF_SYSDATE(0)        -- 타임존일시
																				 FROM PEB_PLAN
																				WHERE ORG_ID = @OT_ORG_ID
																				  AND PEB_ITEM_TYPE IN ('1110')  -- 근무일수에 대한 연장수당
																				  AND PEB_BASE_ID = @PEB_BASE_ID
																IF @@ERROR <> 0
																	BEGIN
																		SET @av_ret_code    = 'FAILURE!' 
																		SET @av_ret_message = dbo.F_FRM_ERRMSG('직접변동비 근무일수에 대한 연장수당 INSERT시 오류발생', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
																		RETURN  
																	END
															END
														END

													-- 초과근무를 제외한 2교대 및 3교대인경우 휴일일수로 계산한다.
													-- 시급 * 8 * 인원 * 휴일일수 * 인상율(3월부터적용) * (2교대의 2조, 3교대의 3조인경우 2, 아니면 1.5배)
													ELSE 
														BEGIN
															-- 2교대의 2조, 3교대의 3조인경우 * 2를한다.
															IF (@OT_TYPE_02_CD = '1110' AND @OT_TYPE_03_CD = '1220') OR (@OT_TYPE_02_CD = '1120' AND @OT_TYPE_03_CD = '1230') 
																BEGIN
																	INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- 인건비계획ID
																						  PEB_BASE_ID     ,  -- 인건비계획기준ID
																						  PEB_TYPE_CD     ,  -- 인건비구분
																						  ORG_ID          ,  -- 소속
																						  TYPE_01_CD      ,  -- 유형코드1
																						  TYPE_02_CD      ,  -- 유형코드2
																						  TYPE_03_CD      ,  -- 유형코드3
																						  PEB_ITEM_TYPE   ,  -- 인건비세부구분
																						  BASE_AMT        ,  -- 기준금액
																						  EMP_CNT         ,  -- 현재인원
																						  AMT01           ,  -- 1월
																						  AMT02           ,  -- 2월
																						  AMT03           ,  -- 3월
																						  AMT04           ,  -- 4월
																						  AMT05           ,  -- 5월
																						  AMT06           ,  -- 6월
																						  AMT07           ,  -- 7월
																						  AMT08           ,  -- 8월
																						  AMT09           ,  -- 9월
																						  AMT10           ,  -- 10월
																						  AMT11           ,  -- 11월
																						  AMT12           ,  -- 12월
																						  NOTE            ,  -- 비고
																						  MOD_USER_ID     ,  -- 변경자
																						  MOD_DATE        ,  -- 변경일시
																						  TZ_CD           ,  -- 타임존코드
																						  TZ_DATE            -- 타임존일시
																						  )
																				   SELECT NEXT VALUE FOR S_PEB_SEQUENCE,  -- 인건비기준금액ID
																						  @an_plan_id              ,  -- 인건비계획기준ID
																						  '09'                    ,  -- 인건비구분
																						  @OT_ORG_ID             ,  -- 소속
																						  @OT_TYPE_01_CD         ,  -- 유형코드1
																						  @OT_TYPE_02_CD         ,  -- 유형코드2
																						  @OT_TYPE_03_CD         ,  -- 유형코드3
																						  '3120'                ,  -- 인건비세부구분
																						  @n_base_amt              ,  -- 기준금액
																						  @BASE_EMP_CNT,  -- 현재인원
																						  dbo.XF_ROUND(@n_base_amt * 8 * @OT_AMT01 * AMT01 * 2 ,0),  -- 1월
																						  dbo.XF_ROUND(@n_base_amt * 8 * @OT_AMT02 * AMT02 * 2 ,0),  -- 2월
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT03 * AMT03 * 2,0),  -- 3월
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT04 * AMT04 * 2,0),  -- 4월
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT05 * AMT05 * 2,0),  -- 5월
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT06 * AMT06 * 2,0),  -- 6월
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT07 * AMT07 * 2,0),  -- 7월
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT08 * AMT08 * 2,0),  -- 8월
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT09 * AMT09 * 2,0),  -- 9월
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT10 * AMT10 * 2,0),  -- 10월
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT11 * AMT11 * 2,0),  -- 11월
																						  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT12 * AMT12 * 2,0),  -- 12월
																						  '(시급['+@n_base_amt+'] + 인상율(3월부터적용)['+@n_base_amt*@BASE_PEB_RATE/100+'])* 8 * 인원 * 휴일일수 * 2 ',
																						  @an_mod_user_id    ,  -- 변경자
																						  dbo.XF_SYSDATE(0)     ,  -- 변경일시
																						  'KST'             ,  -- 타임존코드
																						  dbo.XF_SYSDATE(0)        -- 타임존일시
																					 FROM PEB_PLAN
																					WHERE ORG_ID = @OT_ORG_ID
																					  AND PEB_ITEM_TYPE IN ('1120')  -- 휴일일수에 대한 특근수당
																					  AND PEB_BASE_ID = @PEB_BASE_ID
																	IF @@ERROR <> 0
																		BEGIN
																			SET @av_ret_code    = 'FAILURE!' 
																			SET @av_ret_message = dbo.F_FRM_ERRMSG('직접변동비 휴일일수에 대한 2교대의 2조, 3교대의 3조인경우 INSERT시 오류발생', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
																			RETURN  
																		END
																END
															
															ELSE
															-- 나머지는 1.5배한다.
																BEGIN
																	  -- 인력계획 INSERT
																	BEGIN
																		INSERT INTO PEB_PLAN( PEB_PLAN_ID     ,  -- 인건비계획ID
																							  PEB_BASE_ID     ,  -- 인건비계획기준ID
																							  PEB_TYPE_CD     ,  -- 인건비구분
																							  ORG_ID          ,  -- 소속
																							  TYPE_01_CD      ,  -- 유형코드1
																							  TYPE_02_CD      ,  -- 유형코드2
																							  TYPE_03_CD      ,  -- 유형코드3
																							  PEB_ITEM_TYPE   ,  -- 인건비세부구분
																							  BASE_AMT        ,  -- 기준금액
																							  EMP_CNT         ,  -- 현재인원
																							  AMT01           ,  -- 1월
																							  AMT02           ,  -- 2월
																							  AMT03           ,  -- 3월
																							  AMT04           ,  -- 4월
																							  AMT05           ,  -- 5월
																							  AMT06           ,  -- 6월
																							  AMT07           ,  -- 7월
																							  AMT08           ,  -- 8월
																							  AMT09           ,  -- 9월
																							  AMT10           ,  -- 10월
																							  AMT11           ,  -- 11월
																							  AMT12           ,  -- 12월
																							  NOTE            ,  -- 비고
																							  MOD_USER_ID     ,  -- 변경자
																							  MOD_DATE        ,  -- 변경일시
																							  TZ_CD           ,  -- 타임존코드
																							  TZ_DATE            -- 타임존일시
																							  )
																					   SELECT NEXT VALUE FOR S_PEB_SEQUENCE,  -- 인건비기준금액ID
																							  @an_plan_id              ,  -- 인건비계획기준ID
																							  '09'                    ,  -- 인건비구분
																							  @OT_ORG_ID             ,  -- 소속
																							  @OT_TYPE_01_CD         ,  -- 유형코드1
																							  @OT_TYPE_02_CD         ,  -- 유형코드2
																							  @OT_TYPE_03_CD         ,  -- 유형코드3
																							  '3120'                ,  -- 인건비세부구분
																							  @n_base_amt              ,  -- 기준금액
																							  @BASE_EMP_CNT,  -- 현재인원
																							  dbo.XF_ROUND(@n_base_amt * 8 * @OT_AMT01 * AMT01 * 1.5 ,0),  -- 1월
																							  dbo.XF_ROUND(@n_base_amt * 8 * @OT_AMT02 * AMT02 * 1.5 ,0),  -- 2월
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT03 * AMT03 * 1.5,0),  -- 3월
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT04 * AMT04 * 1.5,0),  -- 4월
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT05 * AMT05 * 1.5,0),  -- 5월
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT06 * AMT06 * 1.5,0),  -- 6월
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT07 * AMT07 * 1.5,0),  -- 7월
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT08 * AMT08 * 1.5,0),  -- 8월
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT09 * AMT09 * 1.5,0),  -- 9월
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT10 * AMT10 * 1.5,0),  -- 10월
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT11 * AMT11 * 1.5,0),  -- 11월
																							  dbo.XF_ROUND((@n_base_amt+(@n_base_amt*@BASE_PEB_RATE/100)) * 8 *@OT_AMT12 * AMT12 * 1.5,0),  -- 12월
																							  '(시급['+@n_base_amt+'] + 인상율(3월부터적용)['+@n_base_amt*@BASE_PEB_RATE/100+']) * 8 * 인원 * 휴일일수 * 1.5',
																							  @an_mod_user_id    ,  -- 변경자
																							  dbo.XF_SYSDATE(0)     ,  -- 변경일시
																							  'KST'             ,  -- 타임존코드
																							  dbo.XF_SYSDATE(0)        -- 타임존일시
																						 FROM PEB_PLAN
																						WHERE ORG_ID = @OT_ORG_ID
																						  AND PEB_ITEM_TYPE IN ('1120')  -- 휴일일수에 대한 특근수당
																						  AND PEB_BASE_ID = @PEB_BASE_ID	
																		IF @@ERROR <> 0
																			BEGIN
																				SET @av_ret_code    = 'FAILURE!' 
																				SET @av_ret_message = dbo.F_FRM_ERRMSG('직접변동비 휴일일수에 1.5 INSERT시 오류발생', @v_program_id,  1010, ERROR_MESSAGE() , @an_mod_user_id) 
																				RETURN  
																			END
																	END
																END
														END	

													FETCH NEXT FROM OT INTO @OT_AMT01 , @OT_AMT02, @OT_AMT03, @OT_AMT04, @OT_AMT05, @OT_AMT06, @OT_AMT07, @OT_AMT08, @OT_AMT09, @OT_AMT10, @OT_AMT11, @OT_AMT12, @OT_AVG_AMT, @OT_BASE_AMT,
																	@OT_B_ORG_ID, @OT_EMP_CNT, @OT_ETC_CD1, @OT_ETC_CD2, @OT_G_ORG_ID, @OT_J_AMT, @OT_MOD_DATE, @OT_MOD_USER_ID, @OT_NOTE, @OT_ORG_ID, @OT_PEB_BASE_ID, @OT_PEB_ITEM_TYPE,
																	@OT_PEB_PLAN_ID, @OT_PEB_TYPE_CD, @OT_TYPE_01_CD, @OT_TYPE_02_CD, @OT_TYPE_03_CD	
												END	-- OT WHILE END

											CLOSE OT
											DEALLOCATE OT

										END --
										FETCH NEXT FROM BASE_AMT1 INTO @PEB_RATE_TYPE_CD, @PEB_ITEM_TYPE_CD, @PEB_RATE
								END  -- BASE_AMT1 WHILE END
							CLOSE BASE_AMT1
							DEALLOCATE BASE_AMT1
						END
					FETCH NEXT FROM C1 INTO @BASIC_YY, @COMPANY_CD, @ETC_CD1, @ETC_CD2, @MOD_DATE, @MOD_USER_ID, @NOTE, @PEB_BASE_ID, @STD_YMD, @TZ_CD, @TZ_DATE
				END  -- C1 WHILE BEGIN END

			CLOSE C1
			DEALLOCATE C1
		END -- BEGIN 1 END

		END

	END
    /************************************************************
    *    작업 완료
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료'
END
USE [dwehrdev_H5]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_REP_MAKE_LIST]
    @av_company_cd     NVARCHAR(10),     -- 회사코드
    @av_locale_cd      NVARCHAR(10),     -- 국가코드
    @av_calc_type_cd   NVARCHAR(10),     -- 정산구분 ('01' : 퇴직금, '02' : 중간정산)
    @ad_sta_ymd        DATETIME2,        -- 시작일(중간정산시 정산일로 대치됨)
    @ad_end_ymd        DATETIME2,        -- 종료일
	@an_org_id         NUMERIC(38),     -- 소속ID
    @an_emp_id         NUMERIC(38),     -- 사원ID
	@an_pay_group_id   NUMERIC(38),      -- 급여그룹
    @an_mod_user_id    NUMERIC(38),     -- 변경자
    @av_ret_code       NVARCHAR(50)  OUTPUT,   -- SUCCESS!/FAILURE!
    @av_ret_message    NVARCHAR(2000) OUTPUT    -- 결과메시지
 AS

    -- ***************************************************************************
    --   TITLE       : 퇴직금대상자생성
    --   PROJECT     :
    --   AUTHOR      :
    --   PROGRAM_ID  : P_REP_MAKE_LIST
    --   RETURN      : 1) SUCCESS!/FAILURE!
    --                 2) 결과 메시지
    --   COMMENT     : 퇴직금대상자생성
    --   HISTORY     : 작성 송재현  2014.06.09
    -- ***************************************************************************
BEGIN

    DECLARE @v_program_id          nvarchar(30),
            @v_program_nm          nvarchar(100),

            @d_mod_date            datetime2(0),
            @n_rep_calc_list_id    numeric(38),
            @n_emp_id              numeric(38),
            @n_org_id              numeric(38),
            @n_pay_org_id          numeric(38),
            @v_pos_grd_cd          nvarchar(50),
            @v_pos_cd              nvarchar(50),
            @v_duty_cd             nvarchar(50),
            @v_yearnum_cd          nvarchar(50),

            @d_group_ymd           datetime2,
            @d_retire_ymd          datetime2,
            @d_sta_ymd             datetime2,
            @d_end_ymd             datetime2,
            @v_cust_col3           nvarchar(50), -- 근무지(추가컬럼)
            @n_retire_turn_mon     numeric(15)

    SET @v_program_id = 'P_REP_MAKE_LIST';
    SET @v_program_nm = '퇴직금대상자생성';

    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)

    SET @d_mod_date = dbo.xf_sysdate(0)

    BEGIN

        -- *************************************************************
        -- 정상구분이 퇴직일때 대상자 생성
        -- *************************************************************

       IF @av_calc_type_cd = '01'

            BEGIN

                  DECLARE REP_CUR CURSOR LOCAL FORWARD_ONLY FOR
                     SELECT A.EMP_ID                                                                 -- 사원ID
                           ,A.ORG_ID                                                                 -- 조직ID
                           ,dbo.XF_NVL_N(A.PAY_ORG_ID,A.ORG_ID) AS PAY_ORG_ID                        -- 지급조직ID
                           ,A.POS_GRD_CD                                                             -- 직급 [PHM_POS_GRD_CD]
                           ,A.POS_CD                                                                 -- 직급 [PHM_POS_CD]
                           ,A.DUTY_CD                                                                -- 직책 [PHM_DUTY_CD]
                           ,A.YEARNUM_CD                                 -- 호봉
                           ,dbo.XF_NVL_D(A.GROUP_YMD,A.HIRE_YMD)   GROUP_YMD                         -- 그룹입사일
                           ,A.RETIRE_YMD                                                             -- 퇴직일
                           ,dbo.XF_NVL_D((SELECT RETR_YMD
                                            FROM PAY_PHM_EMP
                                           WHERE EMP_ID = A.EMP_ID ), dbo.XF_NVL_D(A.GROUP_YMD, A.HIRE_YMD))
                            C1_STA_YMD -- 정산시작일
                            ,CASE WHEN @av_calc_type_cd = '01' THEN A.RETIRE_YMD
                              ELSE @ad_sta_ymd
                             END AS C1_END_YMD                                                           -- 정상종료일
                           ,A.CUST_COL3                                                                 -- 근무지
                           ,dbo.F_REP_PEN_RETIRE_MON(A.EMP_ID, A.RETIRE_YMD) RETIRE_TURN                -- 국민연금퇴직전환금
                      FROM VI_PAY_PHM_EMP A
                     WHERE A.IN_OFFI_YN = 'N'
                       AND A.LOCALE_CD = 'KO'                                                        -- 팩키지 기본(KO)
                       AND A.COMPANY_CD = @av_company_cd
					   AND A.EMP_KIND_CD != 'Z'                                                      -- 파견직이 아닌 직원
                       AND A.RETIRE_YMD BETWEEN @ad_sta_ymd AND @ad_end_ymd                          -- 퇴직일자에 해당되는 사원
                       AND (@an_org_id IS NULL OR A.EMP_ID = @an_org_id)                             -- 입력한 소속가 있다면 입력한 소속 아니면 전체
                       AND (@an_emp_id IS NULL OR A.EMP_ID = @an_emp_id)                             -- 입력한 사원이 있다면 입력한 사원 아니면 전체
                       AND A.HIRE_YMD <= DATEADD(MM, 1, DATEADD(YYYY, -1, A.RETIRE_YMD))             -- 입사1년 이상된사원
					   AND (@an_pay_group_id is NULL OR
					        dbo.F_PAY_GROUP_CHK(@an_pay_group_id, A.EMP_ID, A.RETIRE_YMD) = @an_pay_group_id) -- 급여그룹확인
                       AND A.EMP_ID NOT IN (SELECT EMP_ID                                            -- 이미 입력된 퇴직자는 제외
                                              FROM REP_CALC_LIST
                                             WHERE C1_END_YMD BETWEEN @ad_sta_ymd AND @ad_end_ymd
                                               AND (@an_emp_id IS NULL OR EMP_ID = @an_emp_id)
                                           )

                     OPEN REP_CUR

                     FETCH REP_CUR INTO @n_emp_id , @n_org_id ,@n_pay_org_id, @v_pos_grd_cd , @v_pos_cd, @v_duty_cd ,@v_yearnum_cd ,
                                        @d_group_ymd ,@d_retire_ymd ,@d_sta_ymd ,@d_end_ymd ,@v_cust_col3, @n_retire_turn_mon

                     WHILE (@@FETCH_STATUS = 0)
                       BEGIN
                         SET @n_rep_calc_list_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE

                         BEGIN TRY
                             INSERT INTO dbo.REP_CALC_LIST ( -- 퇴직금계산대상자
                                          REP_CALC_LIST_ID          -- 퇴직금계산대상자ID
                                         ,EMP_ID                    -- 사원ID
                                         ,ORG_ID                    -- 조직ID
                                         ,PAY_ORG_ID                -- 지급조직ID
                                         --,ACC_CD                    -- 코스트코드
                                         ,POS_GRD_CD                -- 직급코드
                                         ,POS_CD                -- 직위코드
                                         ,PAY_YMD                   -- 지급일
                                         ,RETIRE_TYPE_CD            -- 퇴직구분
                                         ,RETIRE_YMD                -- 퇴직일
										 ,CALC_RETIRE_CD            -- 퇴직정산유형
                                         ,CALC_TYPE_CD              -- 정산구분[REP_CALC_TYPE_CD]
                                         ,C1_STA_YMD                -- 정산시작일
                                         ,C1_END_YMD                -- 정산종료일
                                         ,END_YN                    -- 완료여부
                                         ,OFFICERS_YN               -- 임원여부
                                         ,RETIRE_TURN               -- 국민연금퇴직전환금
                                         ,MOD_USER_ID               -- 변경자
                                         ,MOD_DATE                  -- 변경일자
                                         ,TZ_CD                     -- 지역코드
                                         ,TZ_DATE                   -- 지역변경일
                                        )
                                 VALUES (
                                          @n_rep_calc_list_id     -- 퇴직금계산대상자ID
                                         ,@n_emp_id             -- 사원ID
                                         ,@n_org_id             -- 조직ID
                                         ,@n_pay_org_id         -- 지급조직ID
                                         --,dbo.F_ORM_ORG_COST(@av_company_cd, @n_emp_id , dbo.xf_sysdate(0),'1') --
                                         ,@v_pos_grd_cd         -- 직급코드
                                         ,@v_pos_cd         -- 직위코드
                                         ,NULL                    -- 직급일
                                         ,NULL                    -- 퇴직구분
                                         ,@d_retire_ymd         -- 퇴직일
										 ,'04'            -- 퇴직정산유형
                                         ,@av_calc_type_cd        -- 정산구분[REP_CALC_TYPE_CD]
                                         ,@d_sta_ymd         -- 정산시작일
                                         ,@d_end_ymd         -- 정산종료일
                                         ,'N'                     -- 완료여부
                                         , 'N' --dbo.F_REP_EXECUTIVE_RETIRE_YN(@av_company_cd,@av_locale_cd,@d_end_ymd,@n_emp_id,'1')  -- 임원여부
                                         ,@n_retire_turn_mon        -- 국민연금퇴직전환금
                                         ,@an_mod_user_id         -- 변경자
                                         ,dbo.xf_sysdate(0)               -- 변경일자
                                         ,'KST'                   -- 지역코드
                                         ,dbo.xf_sysdate(0)               -- 지역변경일
                                         )

                         END TRY

                         BEGIN CATCH
                            BEGIN
                              SET @av_ret_code = 'FAILURE!'
                              SET @av_ret_message  = dbo.F_FRM_ERRMSG('퇴직금계산대상자생성 에러' , @v_program_id,  0010,  ERROR_MESSAGE(),  @an_mod_user_id)

                              IF @@TRANCOUNT > 0
                                 ROLLBACK WORK

							  CLOSE REP_CUR
							  DEALLOCATE REP_CUR
                              RETURN
                            END

                         END CATCH


                       FETCH REP_CUR INTO @n_emp_id , @n_org_id , @n_pay_org_id, @v_pos_grd_cd ,@v_pos_cd, @v_duty_cd ,@v_yearnum_cd ,
                                          @d_group_ymd ,@d_retire_ymd ,@d_sta_ymd ,@d_end_ymd ,@v_cust_col3, @n_retire_turn_mon
                       END

                     CLOSE REP_CUR

                     DEALLOCATE REP_CUR
           END

       -- *************************************************************
       -- 정상구분이 중도정산일때 대상자 생성(연금관리 내역에서 조회함.)
       -- *************************************************************

       ELSE IF  @av_calc_type_cd = '02'

          BEGIN

              DECLARE RMP_CUR CURSOR LOCAL FORWARD_ONLY FOR

                    SELECT A.EMP_ID,                                                                   -- EMP_ID
                           A.ORG_ID,                                                                   -- ORG_ID
                           dbo.XF_NVL_N(A.PAY_ORG_ID, A.ORG_ID) AS PAY_ORG_ID ,                -- 급여ORG_ID
                           A.POS_GRD_CD,                                                               -- 직급
                           A.POS_CD,                                                               -- 직위
                           A.DUTY_CD,                                                                  -- 직책
                           A.YEARNUM_CD,                                                               -- 호봉
                           dbo.XF_NVL_D(A.GROUP_YMD,A.HIRE_YMD) GROUP_YMD,                             -- 그룹입사일
                           A.RETIRE_YMD ,                                                              -- 퇴직일
                           A.CUST_COL3  ,                                                              -- 근무지
                           dbo.F_REP_PEN_RETIRE_MON(A.EMP_ID, A.RETIRE_YMD) RETIRE_TURN                -- 국민연금퇴직전환금
                      FROM RMP_HISTORY R
                INNER JOIN VI_FRM_PHM_EMP A
                        ON R.EMP_ID = A.EMP_ID
                     WHERE INS_TYPE_CD = '20'
                       AND COMPANY_CD = @av_company_cd
                       AND LOCALE_CD = 'KO'
                       AND A.EMP_ID NOT IN (SELECT EMP_ID                                            -- 이미 입력된 퇴직자는 제외
                                              FROM REP_CALC_LIST
                                             WHERE C1_END_YMD BETWEEN @ad_sta_ymd AND @ad_end_ymd
                                               AND (@an_emp_id IS NULL OR EMP_ID = @an_emp_id)
                                            )

                     OPEN RMP_CUR

                     FETCH RMP_CUR INTO @n_emp_id , @n_org_id ,@n_pay_org_id, @v_pos_grd_cd ,@v_pos_cd, @v_duty_cd ,@v_yearnum_cd ,
                                        @d_group_ymd ,@d_retire_ymd, @v_cust_col3, @n_retire_turn_mon

                     WHILE (@@FETCH_STATUS = 0)
                       BEGIN
                         SET @n_rep_calc_list_id = NEXT VALUE FOR dbo.S_REP_SEQUENCE

                         BEGIN TRY
                             INSERT INTO dbo.REP_CALC_LIST ( -- 퇴직금계산대상자
                                          REP_CALC_LIST_ID          -- 퇴직금계산대상자ID
                                         ,EMP_ID                    -- 사원ID
                                         ,ORG_ID                    -- 조직ID
                                         ,PAY_ORG_ID                -- 지급조직ID
                                         --,ACC_CD                    -- 코스트코드(테이블에 없는 컬럼) 2014.06.16 바이엘 코리아 코스트센터 다중건 코스트 센터는 별도로 관리.
                                         ,POS_GRD_CD                -- 직급코드
                                         ,PAY_YMD                   -- 지급일
                                         ,RETIRE_TYPE_CD            -- 퇴직구분
                                         ,RETIRE_YMD                -- 퇴직일
                                         ,CALC_TYPE_CD              -- 정산구분[REP_CALC_TYPE_CD]
                                         ,C1_STA_YMD                -- 정산시작일
                                         ,C1_END_YMD                -- 정산종료일
                                         ,END_YN                    -- 완료여부
                                         ,OFFICERS_YN               -- 임원여부
                                         ,RETIRE_TURN               -- 국민연금퇴직전환금
                                         ,MOD_USER_ID               -- 변경자
                                         ,MOD_DATE                  -- 변경일자
                                         ,TZ_CD                     -- 지역코드
                                         ,TZ_DATE                   -- 지역변경일
                                        )
                               VALUES (
                                        @n_rep_calc_list_id     -- 퇴직금계산대상자ID
                                         ,@n_emp_id             -- 사원ID
                                         ,@n_org_id             -- 조직ID
                                         ,@n_pay_org_id         -- 지급조직ID
                                         --,dbo.F_ORM_ORG_COST(@av_company_cd, @n_emp_id , dbo.xf_sysdate(0),'1') --  2014.06.16 바이엘 코리아 코스트센터 다중건 코스트 센터는 별도로 관리.
                                         ,@v_pos_grd_cd         -- 직급코드
                                         ,NULL                  -- 직급일
                                         ,NULL                  -- 퇴직구분
                                         ,@d_retire_ymd         -- 퇴직일
                                         ,@av_calc_type_cd      -- 정산구분[REP_CALC_TYPE_CD]
                                         ,@ad_sta_ymd           -- 정산시작일
                                         ,@ad_end_ymd           -- 정산종료일
                                         ,'N'                   -- 완료여부
                                         , dbo.F_REP_EXECUTIVE_RETIRE_YN(@av_company_cd,@av_locale_cd,@d_end_ymd,@n_emp_id,'1')  -- 임원여부
                                         ,@n_retire_turn_mon      -- 국민연금퇴직전환금
                                         ,@an_mod_user_id         -- 변경자
                                         ,dbo.xf_sysdate(0)               -- 변경일자
                                         ,'KST'                   -- 지역코드
                                         ,dbo.xf_sysdate(0)               -- 지역변경일
                                         )

                         END TRY

                         BEGIN CATCH
                            BEGIN
                              SET @av_ret_code = 'FAILURE!'
                              SET @av_ret_message  = dbo.F_FRM_ERRMSG('중간정산 대상자생성 에러', @v_program_id,  0020,  null,  @an_mod_user_id)

                              IF @@TRANCOUNT > 0
                                 ROLLBACK WORK

                              RETURN
                            END

                         END CATCH

                       FETCH RMP_CUR INTO @n_emp_id , @n_org_id , @n_pay_org_id, @v_pos_grd_cd ,@v_pos_cd, @v_duty_cd ,@v_yearnum_cd ,
                                          @d_group_ymd ,@d_retire_ymd ,@v_cust_col3, @n_retire_turn_mon

                       END

                     CLOSE RMP_CUR

                     DEALLOCATE RMP_CUR

            END
	   ELSE
		  BEGIN
				SET @av_ret_code = 'FAILURE!'
				SET @av_ret_message  = dbo.F_FRM_ERRMSG('처리할 수 없는 정산 구분입니다', @v_program_id,  0030,  null,  @an_mod_user_id)

				IF @@TRANCOUNT > 0
					ROLLBACK WORK

				RETURN
		  END
   END

    /*
    *    ***********************************************************
    *    작업 완료
    *    ***********************************************************
    */
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('프로시져 실행 완료..[ERR]', @v_program_id, 0150, NULL, @an_mod_user_id)

END

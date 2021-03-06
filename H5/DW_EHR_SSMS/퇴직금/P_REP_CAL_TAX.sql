USE [dwehrdev_H5]
GO
/****** Object:  StoredProcedure [dbo].[P_REP_CAL_TAX]    Script Date: 2020-07-22 오전 11:22:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_CAL_TAX](    
         @av_company_cd                 VARCHAR(10),             -- 인사영역    
         @av_locale_cd                  VARCHAR(10),             -- 지역코드    
         @an_rep_calc_list_id_list      NUMERIC(38),             -- 퇴직금대상    
         @an_mod_user_id                NUMERIC(27),             -- 변경자 사번    
         @av_ret_code                   VARCHAR(4000)    OUTPUT, -- 결과코드*/    
         @av_ret_message                VARCHAR(4000)    OUTPUT  -- 결과메시지*/    
    ) AS    
    
BEGIN    
    
      SET @av_ret_code = NULL    
      SET @av_ret_message = NULL    
    
    -- ***************************************************************************    
    --   TITLE       : 퇴직금 세금계산    
    --   PROJECT     : HR 시스템    
    --   AUTHOR      :    
    --   PROGRAM_ID  : P_REP_CAL_TAX    
    --   RETURN      : 1) SUCCESS!/FAILURE!    
    --                       2) 결과 메시지7    
    --   COMMENT     : 퇴직금계산    
    --   HISTORY     : 작성 정순보  2006.09.26    
    --                      수정 박근한  2009.01.15    
    --  exec P_REP_CAL_TAX '01','48824,',263,null,null    
    -- ***************************************************************************    
     /*    
      *    기본적으로 사용되는 변수    
      */    
    
      DECLARE    
         @v_program_id varchar(30),    
         @v_program_nm varchar(100),    
		 @n_rep_calc_C1_END_YMD          DATETIME2,          -- 주(현)정산일    
		 @n_rep_calc_R01_S               numeric(15,3) ,     -- 퇴직급여액    
		 @n_rep_calc_BC1_WORK_YY         NUMERIC(5),         -- 근속년수(법정)(현+종전 근속년수)    
		 @n_rep_calc_R06_2012                NUMERIC(19,3),       -- 2012년까지 산출세액(법정)    
		 @n_rep_calc_R01                    numeric(15,3) ,        -- 법정퇴직급여액    
		 @n_rep_calc_R06                     NUMERIC(19,3),       -- 법정산출세액    
		 @n_rep_calc_R02_02                 numeric(15,3) ,        -- 법정퇴직소득공제(근속)    
         @n_rep_calc_C1_STA_YMD_2012        DATETIME2,             -- 2012년까지 시작일    
         @n_rep_calc_C1_END_YMD_2012        DATETIME2,             -- 2012년까지 종료일    
         @n_rep_calc_C1_WORK_MM_2012        NUMERIC(3),           -- 2012년까지 근속월    
         @n_rep_calc_C1_WORK_YY_2012        NUMERIC(3),          -- 2012년까지 근속년    
		 @n_rep_calc_EXCEPT_MM_2012      NUMERIC(5),        -- 2012년까지 제외월수(계산)    
         @n_rep_calc_EXCEPT_MM_2013      NUMERIC(5),        -- 2013년까지 제외월수(계산)    
         @n_rep_calc_C1_EXCEPT_MM_2012   NUMERIC(5),        -- 최종 2012년까지 제외월수(입력)    
         @n_rep_calc_C1_EXCEPT_MM_2013   NUMERIC(5),        -- 최종 2013년까지 제외월수(입력)    
		 @n_rep_calc_ADD_MM_2012         NUMERIC(5),        -- 2012년까지 가산월수(계산)    
         @n_rep_calc_ADD_MM_2013         NUMERIC(5),        -- 2013년까지 가산월수(계산)    
		 @n_rep_calc_C1_STA_YMD_2013        DATETIME2,             -- 2013년까지 시작일    
         @n_rep_calc_C1_END_YMD_2013        DATETIME2,             -- 2012년까지 종료일    
         @n_rep_calc_C1_WORK_MM_2013        NUMERIC(3),           -- 2013년까지 근속월    
         @n_rep_calc_C1_WORK_YY_2013        NUMERIC(5),           -- 2013년까지 근속년    
		 @n_rep_calc_R02_01                 numeric(15,3) ,        -- 법정퇴직소득공제(50%)    
         @n_rep_calc_R03_2012               numeric(15,6) ,        -- 2012년까지 과세표준    
         @n_rep_calc_R04_2012               numeric(15,6) ,        -- 2012년까지 연평균 과세표준(법정)    
         @n_rep_calc_R04_2013               numeric(15,6) ,        -- 2013년까지 연평균 과세표준(법정)    
         @n_rep_calc_R04                    numeric(15,6) ,        -- 법정연평균과세표준    
         @n_rep_calc_R05_2012                NUMERIC(19,3),       -- 2012년까지 연평균 산출세액(법정)    
         @n_rep_calc_R05_2013                NUMERIC(19,3),       -- 2013년까지 연평균 산출세액(법정)    
         @n_rep_calc_R05                     NUMERIC(19,3),       -- 법정연평균산출세액    
		 @n_rep_calc_R03_2013               numeric(15,6) ,        -- 2013년까지 과세표준    
         @n_rep_calc_R06_2013                NUMERIC(19,3)       -- 2013년까지 산출세액(법정)    
      DECLARE @ERRCODE                VARCHAR(10)    
      DECLARE @n_org_id               NUMERIC(38)    
      DECLARE @d_pay_ymd              DATE          -- 지급일    
      DECLARE @n_emp_id               NUMERIC(27,0)     -- 사원ID    
      DECLARE @n_c_01_1               NUMERIC(15)       -- 주(현)법정퇴직금    
      DECLARE @n_c_01_2               NUMERIC(15)       -- 주(현)퇴직보험금    
      DECLARE @d_c1_sta_ymd           DATE          -- 법정주(현)기산일    
      DECLARE @d_c1_end_ymd           DATE          -- 주(현)정산일    
      DECLARE @v_b1_tax_no            VARCHAR(20)       -- 전근무지사업자번호    
      DECLARE @n_b1_corp_nm           VARCHAR(50)       -- 전근무지지급처    
      DECLARE @n_b1_retire_amt        NUMERIC(15)       -- 전근무지퇴직급여    
      DECLARE @n_b1_retire_rep_amt    NUMERIC(15)       -- 전근무지명예퇴직금    
      DECLARE @d_b1_sta_ymd           DATE          -- 입사일자    
      DECLARE @d_b1_end_ymd           DATE          -- 퇴사일자    
      DECLARE @n_b1_work_mm           NUMERIC(2)        -- 근속월수    
      DECLARE @n_bc1_dup_mm           NUMERIC(2)        -- 중복월수    
      DECLARE @n_bt01                 NUMERIC(19,4)     -- 소득세    
      DECLARE @n_bt02                 NUMERIC(19,4)     -- 주민세    
      DECLARE @n_bt03                 NUMERIC(19,4)     -- 농특세    
    
      DECLARE @n_c1_work_mm           NUMERIC(2)          -- 주(현)근속월수    
      DECLARE @n_bc1_work_yy          NUMERIC(2)          -- 근속년수(법정)    
      DECLARE @n_c_01                 NUMERIC(19,4)     -- 주(현)법정퇴직급여    
      DECLARE @n_r01                  NUMERIC(19,4)     -- 법정퇴직급여액    
      DECLARE @n_r02_01               NUMERIC(19,4)     -- 법정퇴직소득공제(50%)    
      DECLARE @n_r02_02               NUMERIC(19,4)     -- 법정퇴직소득공제(근속)    
      DECLARE @n_r02                  NUMERIC(19,4)     -- 법정퇴직소득공제    
      DECLARE @n_r03                  NUMERIC(19,4)     -- 법정퇴직소득과표    
      DECLARE @n_r04                  NUMERIC(19,4)    
      DECLARE @n_r     NUMERIC(19,4)     -- 주(현)명예퇴직금    
      DECLARE @n_c_02_2               NUMERIC(19,4)     -- 주(현)추가퇴직금    
      DECLARE @n_c_02_1               NUMERIC(19,4)    
      DECLARE @n_c_02                 NUMERIC(19,4)     -- 주(현)명예퇴직수당등 (추가퇴직금)    
      DECLARE @d_c2_sta_ymd           DATE          -- 법정이외주(현)기산일    
      DECLARE @d_c2_end_ymd           DATE          -- 법정이외주(현)정산일    
      DECLARE @n_c2_work_mm           NUMERIC(3)        -- 법정이외주(현)근속월수    
      DECLARE @d_b2_sta_ymd           DATE          -- 법정이외종(전)기산일    
      DECLARE @d_b2_end_ymd           DATE          -- 법정이외종(전)정산일    
      DECLARE @n_bc2_work_yy          NUMERIC(2)        -- 법정이외근속년수    
      DECLARE @n_b2_work_mm           NUMERIC(2)        -- 법정이외근속월수    
      DECLARE @n_bc2_dup_mm           NUMERIC(2)        -- 법정이외중복월수    
      DECLARE @n_r01_a                NUMERIC(19,4)     -- 법정이외퇴직급여액    
      DECLARE @n_r02_b_01             NUMERIC(19,4)     -- 법정이외퇴직소득공제(50%)    
      DECLARE @n_r02_b_02             NUMERIC(19,4)     -- 법정이외퇴직소득공제(근속)    
      DECLARE @n_mid_work_yy          NUMERIC(2)    
      DECLARE @d_for_rep_year_sta_ymd DATE          -- 중간정산시 기산일    
      DECLARE @d_for_rep_year_end_ymd DATE          -- 중간정산시 정산일    
      DECLARE @n_r02_b                NUMERIC(19,4)     -- 법정이외퇴직소득공제    
      DECLARE @n_r03_c                NUMERIC(19,4)     -- 법정이외퇴직소득과표    
      DECLARE @n_r04_d                NUMERIC(19,4)     -- 법정이외연평균과세표준    
      DECLARE @n_r01_s                NUMERIC(19,4)     -- 퇴직급여액    
      DECLARE @n_r02_s                NUMERIC(19,4)     -- 퇴직소득공제    
      DECLARE @n_r03_s                NUMERIC(19,4)     -- 퇴직소득과표    
      DECLARE @n_r04_s                NUMERIC(19,4)     -- 연평균과세표준    
      DECLARE @n_tax_rate             NUMERIC(5,2)      -- 세율    
      DECLARE @n_r05_s                NUMERIC(19,4)     -- 연평균산출세액    
      DECLARE @n_r05                  NUMERIC(19,4)     -- 법정연평균산출세액    
      DECLARE @n_r06                  NUMERIC(19,4)     -- 법정산출세액    
      DECLARE @n_r07                  NUMERIC(19,4)     -- 법정세액공제    
      DECLARE @n_r08                  NUMERIC(19,4)     -- 법정결정세액    
      DECLARE @n_r05_e                NUMERIC(19,4)     -- 법정이외연평균산출세액    
      DECLARE @n_r06_f                NUMERIC(19,4)     -- 법정이외산출세액    
      DECLARE @n_r07_g              NUMERIC(19,4)     -- 법정이외세액공제    
      DECLARE @n_r08_h                NUMERIC(19,4)     -- 법정이외결정세액    
      DECLARE @n_r06_s                NUMERIC(19,4)     -- 산출세액    
      DECLARE @n_r07_s                NUMERIC(19,4)     -- 세액공제    
      DECLARE @n_r08_s                NUMERIC(19,4)     -- 결정세액    
      DECLARE @n_ct01                 NUMERIC(19,4)     -- 퇴직소득세    
      DECLARE @n_ct02                 NUMERIC(19,4)     -- 퇴직주민세    
      DECLARE @n_ct03                 NUMERIC(19,4)     -- 퇴직농특세    
      DECLARE @n_ct_sum               NUMERIC(19,4)     -- 퇴직세액계    
      DECLARE @n_bt_sum               NUMERIC(19,4)     -- 종(전)세액계    
      DECLARE @n_t01                  NUMERIC(19,4)     -- 차감소득세    
      DECLARE @n_t02                  NUMERIC(19,4)     -- 차감주민세    
      DECLARE @n_t03                  NUMERIC(19,4)     -- 차감농특세    
      DECLARE @n_t_sum                NUMERIC(19,4)     -- 차감세액계    
      DECLARE @n_c_sum                NUMERIC(19,4)     -- 주(현)계    
      DECLARE @n_chain_amt            NUMERIC(19,4)     -- 차인지급액(퇴직금)    
      DECLARE @n_retire_turn          NUMERIC(19,4)     -- 국민연금퇴직전환금    
      DECLARE @n_real_amt             NUMERIC(19,4)     -- 실지급액    
      DECLARE @n_etc_deduct           NUMERIC(19,4)     -- 기타공제    
      DECLARE @n_etc_pay_amt          NUMERIC(19,4)     -- 기타수당    
    
      DECLARE @n_work_yy              NUMERIC(2)        -- 실근속년수    
      DECLARE @n_work_mm              NUMERIC(3)        -- 실근속월수    
      DECLARE @n_work_dd              NUMERIC(5)        -- 실근속일수    
      DECLARE @n_work_day             NUMERIC(5)        -- 실근속총일수    
      DECLARE @n_work_yy_pt           NUMERIC(10,1)     -- 실근속년수(소수점)    
      DECLARE @n_add_work_yy          NUMERIC(10,1)     -- 추가근속년수    
    
      DECLARE @n_std_idx                 NUMERIC    SET @n_std_idx = 1    
      DECLARE @n_id_cnt                  NUMERIC    SET @n_id_cnt = 0    
      DECLARE @n_rep_calc_list_id_list   NUMERIC(38)    
      DECLARE @n_rep_calc_id             VARCHAR(1000)    
      DECLARE @v_cal_id                  VARCHAR(4000)    
    
      -- 2009.07.14 추가    
      DECLARE @n_de_amt1      NUMERIC    
      DECLARE @n_de_amt2      NUMERIC    
      DECLARE @n_de2_amt1     NUMERIC    
      DECLARE @n_de2_amt2     NUMERIC    
    
      DECLARE @n_calc_type_cd       NUMERIC    
      -- 2009.12.01    
      DECLARE @c_de_amt       NUMERIC(19,4)  -- 당해중간정산 후 퇴직시 주현의 공제금액    
      DECLARE @m_de_amt       NUMERIC(19,4) -- 당해중간정산 후 퇴직시 중간정산의 공제금액    
    
      DECLARE @n_de_amt3       NUMERIC(19,4)  -- 당해중간정산 후 퇴직시 명예퇴직의 공제금액    
      DECLARE @n_de_amt4       NUMERIC(19,4) -- 당해중간정산 후 퇴직시 명예퇴직의 공제금액    
    
      -- 2010.01.07    
      DECLARE @v_b_retire_tax_yn VARCHAR(10)            -- 퇴직소득세액공제여부(한시적)    
    
      /* 임시변수*/    
      DECLARE @t_c1_end_ymd      VARCHAR(1000)    
      DECLARE @t_c2_end_ymd      VARCHAR(1000)    
      DECLARE @t_c3_end_ymd      VARCHAR(1000)    
      DECLARE @t_c4_end_ymd      VARCHAR(1000)    
      DECLARE @t_gongje_amt      VARCHAR(10)            -- 공제액    
      DECLARE @t_nujin_amt       VARCHAR(10)            -- 누진공제액    
    
      DECLARE @from_work_yy       VARCHAR(10)             -- 퇴직소득공제관리에서의 from year    
    
      DECLARE @t_gongje_amt2     VARCHAR(10)            -- 공제액2    
      DECLARE @t_nujin_amt2      VARCHAR(10)            -- 누진공제액2    
      DECLARE @t_year_amt        VARCHAR(10)            -- 연평균과세표준    
      DECLARE @t_nujin_amt3      VARCHAR(10)            -- 누진공제액3    
      DECLARE @t_gongje_amt4     VARCHAR(10)            -- 공제액4    
      DECLARE @t_nujin_amt4      VARCHAR(10)            -- 누진공제액4    
    
      DECLARE @n_b1_add_mm       NUMERIC(3)        -- 2012.09.10 법정퇴직급여_종(전)근무지_가산월수    
      DECLARE @n_b2_add_mm       NUMERIC(3)        -- 2012.09.10 법정퇴직급여_종(전)근무지_가산월수    
    
      DECLARE @n_c1_add_mm       NUMERIC(3)        -- 2012.09.10 법정퇴직급여_주(현)근무지_가산월수    
      DECLARE @n_c2_add_mm       NUMERIC(3)        -- 2012.09.10 법정이외퇴직급여_주(현)근무지_가산월수    
    
      DECLARE @n_incom_sum_amt   NUMERIC(19,4)    -- 2012.09.10 과세이연 이체금액 합계    
    
      DECLARE @n_c1_except_mm   NUMERIC(3)        -- 2012.09.10 제외월수    
      DECLARE @n_c2_except_mm   NUMERIC(3)        -- 2012.09.10 제외월수    
      DECLARE @n_b1_except_mm   NUMERIC(3)        -- 2012.09.10 제외월수    
      DECLARE @n_b2_except_mm   NUMERIC(3)        -- 2012.09.10 제외월수    
      /* 2013.04.02 추가 */    
      DECLARE @n_recovery_mon   NUMERIC(3)        -- 2013.04.02 퇴직금 환수금    
      DECLARE @n_work_yy1          NUMERIC(2)   -- 2013.04.02    
      DECLARE @n_work_yy2          NUMERIC(2)   -- 2013.04.02    
    
      DECLARE @n_work_yy_C1      NUMERIC(3)   -- 2013.04.02    
      DECLARE @n_work_yy_C2      NUMERIC(3)   -- 2013.04.02    
    
      DECLARE @n_attach_mon       NUMERIC        -- 2013.04.02 압류금    
      DECLARE @n_r06_s_70       NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_r06_24       NUMERIC(19,5)   -- 2013.04.02    
    
      -- 2013.04.02 특별추가(변경된 산출세액 때문)    
      DECLARE @n_real_yy        NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_real_r02       NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_real_r03       NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_real_r04       NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_real_r05       NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_real_r06       NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_real_tax_rate  NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_bef_r06_s      NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_real_r06_f     NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_r06_f_70       NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_honor_limit    NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_rep_r06_f      NUMERIC(19,5)   -- 2013.04.02    
      DECLARE @n_rep_r06_s      NUMERIC(19,5)   -- 2013.04.02    
    
       /*2012 추가 사항 과세이연 금액 합*/    
      DECLARE @n_trans_amt           NUMERIC(19,5)    
      DECLARE @n_trans_other_amt     NUMERIC(19,5)    
      DECLARE @n_trans_income_amt    NUMERIC(19,5)    
      DECLARE @n_trans_residence_amt NUMERIC(19,5)    
    
      DECLARE @n_incom_c_01          NUMERIC(19,5) --2012.10.15    
      DECLARE @n_incom_c_02          NUMERIC(19,5) --2012.10.15    
    
      /*2013021 */    
      DECLARE @n_deferred_tax_01    NUMERIC(19,5)   -- 2013.04.02 법정과세이연세액    
      DECLARE @n_deferred_tax_02    NUMERIC(19,5)   -- 2013.04.02 법정이외과세이연세액    
      DECLARE @n_r06_base           NUMERIC(19,5)   -- 2013.04.02 산출세액 베이스    
      DECLARE @n_r06_f_base         NUMERIC(19,5)   -- 2013.04.02 법정이외 산출세액 베이스    
      DECLARE @n_deferred_rate      NUMERIC(19,5)   -- 2013.04.02 과세이연금액 % {퇴직급여액계(종전 포함)/과세이연이체금액}    
    
      /*20130227*/    
      DECLARE @n_c50              NUMERIC(19,5)   -- 2013.04.02 세액환산명세-법정퇴직급여    
    
      DECLARE @n_c1_work_yy_2012 NUMERIC(3)   -- 2013.04.02 2012년까지 근속년수(법정)    
      DECLARE @n_c1_work_yy_2013 NUMERIC(3)   -- 2013.04.02 2013년부터 근속년수(법정)    
    
      DECLARE @n_c2_work_yy_2012 NUMERIC(3)   -- 2013.04.02 2012년까지 근속년수(법정이외)    
      DECLARE @n_c2_work_yy_2013 NUMERIC(3)   -- 2013.04.02 2013년부터 근속년수(법정이외)    
    
      DECLARE @n_r04_2012       NUMERIC(22,7)   -- 2013.04.02 2012년까지 연평균 과세표준(법정)    
      DECLARE @n_r04_2013       NUMERIC(22,7)   -- 2013.04.02 2013년부터 연평균 과세표준(법정)    
    
      DECLARE @n_r05_2012       NUMERIC(22,7)   -- 2013.04.02 2012년까지 연평균 산출세액(법정)    
      DECLARE @n_r05_2013       NUMERIC(22,7)   -- 2013.04.02 2013년부터 연평균 산출세액(법정)    
    
      DECLARE @n_r06_2012       NUMERIC(22,7)   -- 2013.04.02 2012년까지 산출세액(법정)    
      DECLARE @n_r06_2013       NUMERIC(22,7)   -- 2013.04.02 2013년부터 산출세액(법정)    
    
      DECLARE @n_c1_tax_rate_2012  NUMERIC(5,2)   -- 2013.04.02 2012년까지 세율(법정)    
      DECLARE @n_c1_tax_rate_2013  NUMERIC(5,2)   -- 2013.04.02 2012년까지 세율(법정)    
    
      DECLARE @n_c2_tax_rate_2012  NUMERIC(5,2)   -- 2013.04.02 2012년까지 세율(법정이외)    
      DECLARE @n_c2_tax_rate_2013  NUMERIC(5,2)   -- 2013.04.02 2012년까지 세율(법정이외)    
    
      DECLARE @n_r04_d_2012       NUMERIC(22,7)   -- 2013.04.02 2012년까지 연평균 과세표준(법정이외)    
      DECLARE @n_r04_d_2013       NUMERIC(22,7)   -- 2013.04.02 2013년부터 연평균 과세표준(법정이외)    
    
    DECLARE @n_r05_e_2012       NUMERIC(22,7)   -- 2013.04.02 2012년까지 연평균 산출세액(법정이외)    
      DECLARE @n_r05_e_2013       NUMERIC(22,7)   -- 2013.04.02 2013년부터 연평균 산출세액(법정이외)    
    
      DECLARE @n_r06_f_2012       NUMERIC(22,7)   -- 2013.04.02 2012년까지 산출세액(법정이외)    
      DECLARE @n_r06_f_2013       NUMERIC(22,7)   -- 2013.04.02 2013년부터 산출세액(법정이외)    
    
      DECLARE @n_retire_mid_income_amt  NUMERIC(22,7)    
      DECLARE @n_retire_mid_amt         NUMERIC(22,7)    
      DECLARE @n_non_retire_mid_amt     NUMERIC(22,7)    
    
      DECLARE @d_retire_ymd       DATE           -- 2013.04.02 퇴사일자    
    
      DECLARE @t_rep_mid_calc_list_sta_ymd  DATE           -- 2013.06.04    
      DECLARE @t_rep_mid_calc_list_end_ymd  DATE           -- 2013.06.04    
    
      DECLARE @v_biz_nm           VARCHAR(50)    
      DECLARE @v_biz_no           VARCHAR(50)    
      DECLARE @v_account_no       VARCHAR(500)    
    
      DECLARE @n_r03_2012       NUMERIC(22,7)    
      DECLARE @n_r03_2013       NUMERIC(22,7)    
    
      DECLARE @d_c1_sta_ymd_2012        DATE    
      DECLARE @d_c1_sta_ymd_2013        DATE    
      DECLARE @d_c1_end_ymd_2012        DATE    
      DECLARE @d_c1_end_ymd_2013        DATE    
      DECLARE @n_c1_work_mm_2012        NUMERIC(3)    
      DECLARE @n_c1_work_mm_2013        NUMERIC(3)    
    
      DECLARE @v_rep_mid_yn           CHAR(1)    
      -- 2013.08.28 시작    
      DECLARE @d_sum_sta_ymd          DATE,    
              @d_sum_end_ymd          DATE,    
              @n_except_mm_2012       NUMERIC(3),    
              @n_except_mm_2013       NUMERIC(3),    
              @n_add_mm_2012          NUMERIC(3),    
              @n_add_mm_2013          NUMERIC(3),    
              @n_sum_work_mm          NUMERIC(3),    
              @n_sum_except_mm        NUMERIC(3),    
              @n_sum_add_mm           NUMERIC(3),    
              @n_c1_work_yy           NUMERIC(3),    
              @d_mid_sta_ymd          DATE,    
              @d_mid_end_ymd          DATE,    
              @d_mid_pay_ymd          DATE,    
              @n_mid_work_mm          NUMERIC(3),    
              @n_dup_mm               NUMERIC(3),    
              @n_mid_except_mm        NUMERIC(3),    
              @n_mid_add_mm           NUMERIC(3),    
              @n_etc_cd1              NUMERIC(5)  -- 2013.07.01 추가:근속연수공제 계산을 위한 기준근속년수    
    
      -- 2013.08.28 변수종료    
          
     -- 2016년 귀속 과세형평 개정안 시작    
     DECLARE    
        @n_rep_calc_R04_N_12    NUMERIC(22),  -- 환산급여(2016년 개정)    
        @n_rep_calc_R04_DEDUCT  NUMERIC(22),  -- 환산급여별공제(2016년 개정)    
        @n_rep_calc_R04_12      NUMERIC(22),  -- 퇴직소득과세표준(2016년 개정)    
        @n_rep_calc_R05_12      NUMERIC(22),  -- 환산산출세액(2016년 개정)    
        @n_rep_calc_R06_N       NUMERIC(22)   -- 산출세액(2016년 개정)    
     -- 2016년 귀속 과세형평 개정안 종료    
    
      /* 기본변수 초기값 셋팅*/    
      SET @v_program_id    = 'P_REP_CAL_TAX'       -- 현재 프로시져의 영문명    
      SET @v_program_nm    = '퇴직금 세금계산'     -- 현재 프로시져의 한글문명    
      SET @av_ret_code     = 'SUCCESS!'    
      SET @av_ret_message  = dbo.F_FRM_ERRMSG('프로시져 실행 시작..', @v_program_id,  0000,  null,  @an_mod_user_id)    
    
    
      BEGIN    
         --2009.02.18   초기화 추가 시작    
          SET @n_c1_work_mm      = NULL    
          SET @n_bc1_work_yy     = NULL    
          SET @n_c_01            = NULL    
          SET @n_r01             = NULL    
          SET @n_r02_01          = NULL    
          SET @n_r02_02          = NULL    
          SET @n_r02             = NULL    
          SET @n_r03             = NULL    
          SET @n_r04             = NULL    
          SET @n_c_02            = NULL    
          SET @d_c2_end_ymd      = NULL    
          SET @n_c2_work_mm      = NULL    
  SET @d_b2_sta_ymd      = NULL    
          SET @d_b2_end_ymd      = NULL    
          SET @n_b2_work_mm      = NULL    
          SET @n_bc2_dup_mm      = NULL    
          SET @n_bc2_work_yy     = NULL    
          SET @n_r01_a           = NULL    
          SET @n_r02_b_01        = NULL    
          SET @n_r02_b_02        = NULL    
          SET @n_r02_b           = NULL    
          SET @n_r03_c           = NULL    
          SET @n_r04_d           = NULL    
          SET @n_r01_s           = NULL    
          SET @n_r02_s           = NULL    
          SET @n_r03_s           = NULL    
          SET @n_r04_s           = NULL    
          SET @n_tax_rate        = NULL    
          SET @n_r05_s           = NULL    
          SET @n_r05             = NULL    
          SET @n_r06             = NULL    
          SET @n_r08             = NULL    
          SET @n_r07             = NULL    
          SET @n_r05_e           = NULL    
          SET @n_r06_f           = NULL    
          SET @n_r07_g           = NULL    
          SET @n_r08_h           = NULL    
          SET @n_r06_s           = NULL    
          SET @n_r07_s           = NULL    
          SET @n_r08_s           = NULL    
          SET @n_ct01            = NULL    
          SET @n_ct02            = NULL    
          SET @n_ct03            = NULL    
          SET @n_ct_sum          = NULL    
          SET @n_bt_sum          = NULL    
          SET @n_t01             = NULL    
          SET @n_t02             = NULL    
          SET @n_t03             = NULL    
          SET @n_t_sum           = NULL    
          SET @n_c_sum           = NULL    
          SET @n_chain_amt       = NULL    
          SET @n_retire_turn     = NULL    
          SET @n_real_amt        = NULL    
          --2009.02.18   초기화 추가 끝    
          -- 2009.07.14 추가    
          SET  @n_de_amt1       = NULL    
          SET  @n_de_amt2       = NULL    
          SET  @n_de2_amt1      = NULL    
          SET  @n_de2_amt2      = NULL    
    
          -- 2012.09.10 추가    
          SET @n_b1_add_mm        = 0    
          SET @n_b2_add_mm        = 0    
          SET @n_incom_sum_amt    = 0    
          SET @n_c1_except_mm     = 0    
          SET @n_bc1_dup_mm       = 0    
          SET @n_org_id           = NULL    
    
          -- 퇴직 대상자 아이디 조회    
          SET @n_rep_calc_id = @an_rep_calc_list_id_list --dbo.XF_TO_NUMBER(dbo.F_ARRAY_INSRT_VALUE(@an_rep_calc_list_id_list, ',', 'A'+CONVERT(VARCHAR,@n_std_idx)))    
    
              -- ************************************************************************    
              -- 퇴직대상자 데이터 조회    
              -- ************************************************************************    
              BEGIN    
                  SELECT @d_pay_ymd               = PAY_YMD             ,     -- 지급일    
                         @n_emp_id                = EMP_ID              ,     -- 사원ID    
                         @n_c_01_1                = C_01_1              ,     -- 주(현)법정퇴직금    
                         @n_c_01_2                = C_01_2              ,     -- 주(현)퇴직보험금    
                         @n_c_02_1                = C_02_1              ,     -- 주(현)명예퇴직금    
                         @n_c_02_2                = C_02_2              ,     -- 주(현)추가퇴직금    
                         @d_c1_sta_ymd            = C1_STA_YMD          ,     -- 법정주(현)기산일    
                         @d_c1_end_ymd            = C1_END_YMD          ,     -- 주(현)정산일    
                         @d_c2_sta_ymd            = C2_STA_YMD          ,     -- 법정이외주(현)기산일    
                         @n_etc_deduct            = ETC_DEDUCT          ,     -- 기타공제-    
                         @n_etc_pay_amt           = ETC_PAY_AMT         ,     -- 기타수당    
                         @n_calc_type_cd          = CALC_TYPE_CD        ,     -- 계산구분    
                         @v_b_retire_tax_yn       = B_RETIRE_TAX_YN     ,     -- 퇴직소득세액공제여부    
                         @n_rep_calc_list_id_list = REP_CALC_LIST_ID    ,    
                      @n_c1_except_mm          = C1_EXCEPT_MM    ,     -- 2012.09.10 추가:제외월수    
                         @n_bc1_dup_mm            = BC1_DUP_MM,           -- 2012.09.10 추가:제외월수    
                         @n_retire_mid_income_amt = RETIRE_MID_INCOME_AMT,    
                         -- 2013.08.28 시작    
                         @d_sum_sta_ymd           = C1_STA_YMD,    
                         @d_sum_end_ymd         = C1_END_YMD,    
                        -- @n_c1_work_mm            = dbo.XF_CEIL(dbo.XF_MONTHDIFF(dbo.XF_DATEADD(C1_END_YMD, 1), C1_STA_YMD),0),   2019.03.08 
						-- ☞ 바른 예시 : t_rep_calc_list.C1_WORK_MM := XF_TRUNC_N(XF_MONTHDIFF(t_rep_calc_list.C1_END_YMD, 
						 @n_c1_work_mm            = dbo.XF_TRUNC_N(dbo.XF_MONTHDIFF(C1_END_YMD, C1_STA_YMD)+1,0),    
                         @n_except_mm_2012        = C1_EXCEPT_MM_2012,    
                         @n_except_mm_2013        = C1_EXCEPT_MM_2013,    
                         @n_c1_except_mm          = dbo.XF_NVL_N(C1_EXCEPT_MM_2012,0) + dbo.XF_NVL_N(C1_EXCEPT_MM_2013,0),    
     @n_add_mm_2012           = C1_ADD_MM_2012,    
                         @n_add_mm_2013           = C1_ADD_MM_2013,    
                         @n_c1_add_mm             = dbo.XF_NVL_N(C1_ADD_MM_2012,0) + dbo.XF_NVL_N(C1_ADD_MM_2013,0),    
                         @n_sum_work_mm           = C1_WORK_MM,    
                         @n_sum_except_mm         = C1_EXCEPT_MM,    
                         @n_sum_add_mm            = C1_ADD_MM,    
                         @n_c1_work_yy            = dbo.XF_CEIL((dbo.XF_NVL_N(dbo.XF_CEIL(dbo.XF_MONTHDIFF(dbo.XF_DATEADD(C1_END_YMD, 1), C1_STA_YMD),0),0) - dbo.XF_NVL_N(C1_EXCEPT_MM,0) + dbo.XF_NVL_N(C1_ADD_MM,0)) / 12, 0),    
                         @v_rep_mid_yn            = REP_MID_YN,    
                         @n_org_id                = ORG_ID,    
    
                          -- 2016년 귀속 과세형평 개정안 시작    
                           @n_rep_calc_R04_N_12    = R04_N_12    -- 환산급여(2016년 개정)    
                          , @n_rep_calc_R04_DEDUCT  = R04_DEDUCT  -- 환산급여별공제(2016년 개정)    
                          , @n_rep_calc_R04_12      = R04_12      -- 퇴직소득과세표준(2016년 개정)    
                          , @n_rep_calc_R05_12      = R05_12      -- 환산산출세액(2016년 개정)    
                          , @n_rep_calc_R06_N       = R06_N       -- 산출세액(2016년 개정)    
                          -- 2016년 귀속 과세형평 개정안 종료    
                    FROM REP_CALC_LIST    
                   WHERE REP_CALC_LIST_ID = @n_rep_calc_id    
              /*IF @d_pay_ymd IS NOT NULL    
                    BEGIN    
                          SET @av_ret_code      = 'FAILURE!'    
                          SET @av_ret_message   = '사번 [' + dbo.F_PHM_EMP_NO(@n_emp_id, '1') + ']님의 지급일이 있으므로 다시 생성할 수 없습니다. [ERR]'    
                          --ROLLBACK TRAN    
                          RETURN    
                    END    */
              END     
              -- 2013.08.28 변수초기화    
              SET @n_bc1_work_yy = @n_c1_work_yy    
    
              SET @t_rep_mid_calc_list_sta_ymd = null    
              SET @t_rep_mid_calc_list_end_ymd = null    
              SET @d_mid_sta_ymd               = null    
              SET @d_mid_end_ymd               = null    
              SET @d_mid_pay_ymd               = null    
              SET @n_mid_work_mm               = null    
              SET @n_mid_work_yy               = null    
              SET @n_dup_mm                    = 0    
              SET @n_retire_mid_income_amt     = 0    
              SET @n_retire_mid_amt            = 0    
              SET @n_non_retire_mid_amt        = 0    
              SET @v_biz_nm                    = null    
              SET @v_biz_no                    = null    
              SET @v_account_no                = null    
              SET @n_mid_except_mm             = null    
              SET @n_mid_add_mm                = null    
    
              -- ************************************************************************    
              -- (종)현 근무지 데이터 조회    
              -- ************************************************************************    
              BEGIN    
                   SELECT @n_retire_mid_amt        = SUM(T.RETIRE_AMT),    
                          @n_retire_mid_income_amt = SUM(T.SODUK_MON),    
                          @n_non_retire_mid_amt    = SUM(T.NON_RETIRE_AMT),    
                          @t_rep_mid_calc_list_sta_ymd = MAX(T.STA_YMD),    
                          @t_rep_mid_calc_list_end_ymd = MAX(T.END_YMD),    
                          @d_mid_pay_ymd               = MAX(T.PAY_YMD),    
                          @n_except_mm_2012        = SUM(EXCEPT_MM_2012),    
                          @n_except_mm_2013        = SUM(EXCEPT_MM_2013),    
                          @n_mid_except_mm         = SUM(EXCEPT_MM_2012)+SUM(EXCEPT_MM_2013),    
                          @n_add_mm_2012           = SUM(ADD_MM_2012),    
                          @n_add_mm_2013           = SUM(ADD_MM_2013),    
                          @n_mid_add_mm            = SUM(ADD_MM_2012)+SUM(ADD_MM_2013)    
                   FROM  (    
                           SELECT EMP_ID     ,     -- 사원ID    
                                  C1_STA_YMD  STA_YMD  ,     -- 기산일    
                                  C1_END_YMD  END_YMD  ,     -- 정산일    
                                  PAY_YMD              ,     --지급일    
                                  dbo.XF_NVL_D(PAY_YMD, C1_END_YMD)  TAX_YMD  ,     -- 세금 기준일 =>  중간정산일 경우 지급일 기준으로 퇴직금 세금을 계산한다.    
                                  dbo.XF_NVL_N(C1_EXCEPT_MM_2012,0) AS EXCEPT_MM_2012      ,     -- 20121231이전제외월수    
                                  dbo.XF_NVL_N(C1_EXCEPT_MM_2013,0) AS EXCEPT_MM_2013    ,     -- 20130101이후제외월수    
                                  dbo.XF_NVL_N(C1_ADD_MM_2012,0) AS ADD_MM_2012        ,     -- 20121231이전가산월수    
                                  dbo.XF_NVL_N(C1_ADD_MM_2013,0) AS ADD_MM_2013        ,     -- 20130101이후가산월수    
                                  dbo.XF_NVL_N(C_SUM,0) AS RETIRE_AMT               ,     -- 퇴직금    
                                  dbo.XF_NVL_N(NON_RETIRE_AMT,0) AS NON_RETIRE_AMT  ,     -- 비과세퇴직금    
                                  dbo.XF_NVL_N(CT01,0) AS SODUK_MON         ,     -- 소득세           --(37)기납부(또는 기과세이연) 세액    
                                  dbo.XF_NVL_N(CT02,0) AS JUMIN_MON              -- 주민세    
                             FROM REP_CALC_LIST X    
                            WHERE CALC_TYPE_CD = '02' --중간정산  ****회사마다 수정해야함    
                              AND END_YN = '1' --완료여부    
                              AND EMP_ID = @n_emp_id    
                              AND REP_CALC_LIST_ID <> @n_rep_calc_id    
                              AND C1_END_YMD <= @d_c1_end_ymd    
                           UNION    
                           SELECT EMP_ID       ,     -- 사원ID    
                                  STA_YMD      ,     -- 입사일자    
                                  END_YMD      ,     -- 퇴사일자    
                                  PAY_YMD      ,         --지급일    
                                  END_YMD  TAX_YMD  ,     -- 세금 기준일    
                                  dbo.XF_NVL_N(EXCEPT_MM_2012,0)    ,     -- 20121231이전제외월수    
                                  dbo.XF_NVL_N(EXCEPT_MM_2013,0)    ,     -- 20130101이후제외월수    
                                  dbo.XF_NVL_N(ADD_MM_2012,0)       ,     -- 20121231이전가산월수    
                                  dbo.XF_NVL_N(ADD_MM_2013,0)       ,     -- 20130101이후가산월수    
                                  dbo.XF_NVL_N(RETIRE_MON,0) + dbo.XF_NVL_N(HONOR_MON,0)           ,     -- 전근무지퇴직금  + 근무지명예퇴직금    
                                  dbo.XF_NVL_N(NON_RETIRE_AMT,0)    ,     -- 비과세퇴직금    
                                  dbo.XF_NVL_N(INCOM_TAX,0)         ,     -- 소득세    
                                  dbo.XF_NVL_N(INHBT_TAX,0)                -- 주민세    
                             FROM REP_PRE_INCOME  -- 전근무지퇴직소득내역    
                            WHERE BASE_YEAR = dbo.XF_TO_CHAR_D(@d_c1_end_ymd,'YYYY')    
                              AND EMP_ID = @n_emp_id    
                              AND END_YMD <= @d_c1_end_ymd   -- 2009.03.02 추가    
                              AND END_YMD >= CASE WHEN @v_rep_mid_yn = 'Y' THEN dbo.XF_TO_DATE('10000101', 'YYYYMMDD') ELSE dbo.XF_TO_DATE(dbo.XF_TO_CHAR_D(@d_c1_end_ymd, 'YYYY')+'0101' , 'YYYYMMDD') END    
                      ) T    
    
                IF @@ERROR != 0  -- 에러 메세지 처리    
                    BEGIN    
                        SET @av_ret_code     = 'FAILURE!'    
                        SET @av_ret_message  = '(종)현 근무지 데이터 조회시 에러발생. [ERR]'    
                        RETURN    
    END    
              END    
--SET @av_ret_code      = 'FAILURE!'    
--SET @av_ret_message   = '@n_bc1_work_yy='+DBO.XF_TO_CHAR_N(@n_bc1_work_yy,NULL)-- +'@n_c1_work_yy ='+ DBO.XF_TO_CHAR_N(@n_c1_work_yy,NULL)--+'@n_bc1_work_yy ='+ DBO.XF_TO_CHAR_N(@n_bc1_work_yy,NULL)--+'@n_r05_2013 ='+ DBO.XF_TO_CHAR_N(@n_r05_2013,NULL)    
----ROLLBACK TRAN    
--RETURN    
              IF @t_rep_mid_calc_list_sta_ymd IS NOT NULL    
                BEGIN    
                  SET @d_mid_sta_ymd  = @t_rep_mid_calc_list_sta_ymd    
                  SET @d_mid_end_ymd  = @t_rep_mid_calc_list_end_ymd    
                  SET @n_mid_work_mm  = dbo.XF_CEIL(dbo.XF_MONTHDIFF(dbo.XF_DATEADD(@d_mid_end_ymd, 1), @d_mid_sta_ymd),0)    
                  SET @n_mid_work_yy  = dbo.XF_CEIL((dbo.XF_NVL_N(@n_mid_work_mm,0) - dbo.XF_NVL_N(@n_mid_except_mm,0) + dbo.XF_NVL_N(@n_mid_add_mm,0)) / 12, 0)    
                  IF @t_rep_mid_calc_list_end_ymd >= @d_c1_sta_ymd AND @t_rep_mid_calc_list_sta_ymd <= @d_c1_end_ymd    
                    BEGIN    
                      SET @n_dup_mm = dbo.XF_CEIL(dbo.XF_MONTHDIFF(dbo.XF_DATEADD(@d_mid_end_ymd, 1), @d_c1_sta_ymd),0)    
                    END    
                  ELSE    
                    BEGIN    
                      SET @n_dup_mm = 0    
                    END    
    
                  SET @d_sum_sta_ymd = @d_mid_sta_ymd    
    
                  /*- 2013.07.15 변경내용:    
                  1. 중간지급(종전)의 기산일이 최종의 기산일보다 늦을경우    
                  정산의 기산일 = 최종의 기산일 으로 변경    
                  */    
                  IF @d_c1_sta_ymd < @t_rep_mid_calc_list_sta_ymd    
                    BEGIN    
                      SET @d_sum_sta_ymd = @d_c1_sta_ymd    
                    END    
    
                  SET @n_sum_work_mm = dbo.XF_CEIL(dbo.XF_MONTHDIFF(dbo.XF_DATEADD(@d_sum_end_ymd, 1), @d_sum_sta_ymd),0)    
                  -- 국세청 엑셀에서 중간지급 퇴사일 과 최종 기산일과 연결 안되어 있으면 제외월수를 만들면서 계산데이타가 다 깨지므로 무시했음..    
                  -- 즉 중간지급 퇴사일과 최종기산일은 연결 되어야 함.    
                  SET @n_sum_except_mm = dbo.XF_NVL_N(@n_c1_except_mm,0) + dbo.XF_NVL_N(@n_mid_except_mm,0)    
                  SET @n_sum_add_mm    = dbo.XF_NVL_N(@n_c1_add_mm,0) + dbo.XF_NVL_N(@n_mid_add_mm,0)    
    
                  SET @n_bc1_work_yy = dbo.XF_CEIL((dbo.XF_NVL_N(@n_sum_work_mm,0) + dbo.XF_NVL_N(@n_sum_except_mm, 0) - dbo.XF_NVL_N(@n_sum_add_mm, 0))/12, 0)    
    
                  -- 중간정산 근무지 구하기    
                  IF @d_mid_end_ymd IS NOT NULL    
                    BEGIN    
                      SET @v_b1_tax_no = NULL    
                      SELECT @d_b1_sta_ymd = STA_YMD ,    
                             @v_b1_tax_no  = TAX_NO  ,     -- 사업자번호    
                             @n_b1_corp_nm = CORP_NM       -- 근무처명    
                        FROM REP_PRE_INCOME  -- 전근무지퇴직소득내역    
                       WHERE BASE_YEAR = dbo.XF_TO_CHAR_D(@d_c1_end_ymd,'YYYY')    
                         AND EMP_ID = @n_emp_id    
                         AND END_YMD = @d_mid_end_ymd    
    
                      IF @v_b1_tax_no IS NULL OR @v_b1_tax_no = ''    
                        BEGIN    
                          SELECT @d_b1_sta_ymd = HIRE_YMD ,  -- 중간정산 입사일    
                                 @v_b1_tax_no  = TAX_NO   ,     -- 사업자번호    
                                 @n_b1_corp_nm = CORP_NM               -- 근무처명    
                            FROM VE_ORM_BIZ E ,    
                                 VI_FRM_PHM_EMP P    
                          WHERE E.COMPANY_CD = @av_company_cd    
                            AND P.LOCALE_CD = @av_locale_cd    
                            AND @d_c1_end_ymd BETWEEN E.STA_YMD AND E.END_YMD    
                            AND dbo.F_INT_Y10_BIZ_CD_C( @av_company_cd, NULL, @n_emp_id,    
                                                        dbo.F_FRM_ORM_ORG_NM(@n_org_id, @av_locale_cd, @d_c1_end_ymd, '10' ),    
                                                        @d_c1_end_ymd) = E.BIZ_CD    
                            AND P.EMP_ID = @n_emp_id    
                        END    
    END    
                END    
                SET @n_b1_retire_amt          = 0           -- 전근무지퇴직급여    
                SET @n_b1_retire_rep_amt      = 0           -- 전근무지명예퇴직금    
                SET @d_b1_end_ymd             = NULL        -- 퇴사일자    
                SET @n_b1_work_mm             = 0           -- 근속월수    
                SET @n_bc1_dup_mm             = 0           -- 중복월수    
                SET @n_bt01                   = 0           -- 소득세    
                SET @n_bt02                   = 0           -- 주민세    
                SET @n_bt03                   = 0           -- 농특세    
            SET @v_b_retire_tax_yn        = NULL        -- 종(전)퇴직소득세액공제여부 -- 20090511    
                SET @n_b1_except_mm           = NULL        -- 종(전)제외월수    --2009.12.01 제외월수 적용    
                SET @n_b2_except_mm           = NULL    
        --  2013.08.28 끝    
    
         -- ***************************************************************************    
         -- (법정)퇴직급여액 계산    
         -- (법정)퇴직급여액 = 퇴직법정급여 + 퇴직보험금등 + 종(전)지급계    
         -- ※ 종(전)지급계 = 종(전)근무처의 퇴직급여총액 + 종(전)근무처의 퇴직보험금등 총액    
         -- ***************************************************************************    
    
         /*================================================================*/    
          --2013.05.10 KSY 수정    
          -- 법정이외의 금액(명예퇴직금) 주석처리    
          --명예퇴직금산정시    
          -- 1. 기존 : 기산일자를 입사일자로 처리    
          -- 2. 변경 : 기산일자를 중간정산이 있는경우 중간정산일 다음일자로 처리    
          --           (법정방식으로 변경됨)    
          -- 명예퇴직, 추가퇴직금을 법정퇴직급여에 포함하여 계산    
         /*================================================================*/    
         --주(현)법정퇴직급여 = 주(현)법정퇴직금 + 주(현)퇴직보험금    
         SET @n_c_01 =  dbo.XF_NVL_N(@n_c_01_1,0) + dbo.XF_NVL_N(@n_c_01_2,0)    
    
    --PRINT(' @@n_c_01==='+ convert(varchar,@n_c_01) +'='+ convert(varchar,@n_c_01_1) )
         -- ***********************************************************    
         -- 명예퇴직.    
         -- ***********************************************************    
         SET @n_c_02_1 = dbo.XF_NVL_N(@n_C_02_1, 0)    
         SET @n_c_02_2 = dbo.XF_NVL_N(@n_C_02_2, 0)    
         -- 명예퇴직, 추가퇴직금    
         SET @n_c_02 = dbo.XF_NVL_N(@n_c_02_1,0) + dbo.XF_NVL_N(@n_c_02_2,0)    
         /*================================================================*/    
         --2013.05.10  KSY 수정시작    
         --중간정산 금액 포함 처리    
         /*================================================================*/    
       -- (법정)퇴직급여액 = 주(현)법정퇴직급여 + 종(전)지급계 + 명예퇴직(추가퇴직금) + 중간정산퇴직금 - 비과세중간정산퇴직금    
          SET @n_r01 = dbo.XF_NVL_N(@n_c_01, 0) + dbo.XF_NVL_N(@n_b1_retire_amt, 0) +    
                             dbo.XF_NVL_N(@n_c_02, 0) + dbo.XF_NVL_N(@n_retire_mid_amt, 0) - dbo.XF_NVL_N(@n_non_retire_mid_amt, 0)    
                               - dbo.XF_NVL_N(@n_non_retire_mid_amt, 0) --2013.08.28 추가    
    
       /*================================================================*/    
       --2013.05.10  KSY 수정 종료    
       --중간정산 금액 포함 처리    
       /*================================================================*/    
    
       /*================================================================*/    
       --2013.05.10  KSY 수정시작    
       --법정이외 주석처리    
      /*================================================================*/    
        -- 2009.02.26 추가 수정분 start    
        -- ***********************************************************    
        -- 명예퇴직.    
        -- ***********************************************************    
        /*    
        SET @n_c_02_1 = dbo.XF_NVL_N(@n_c_02_1, 0)    
        SET @n_c_02_2 = dbo.XF_NVL_N(@n_c_02_2, 0)    
        SET @n_c_02   = @n_c_02_1 + @n_c_02_2    
        SET @n_r01 = @n_r01    
    
        IF @n_c_02 > 0  AND @d_c1_sta_ymd = @d_c2_sta_ymd  -- 중간정산 안 한 명예퇴직일 경우    
         BEGIN    
            SET @n_r01_a = dbo.XF_NVL_N(@n_c_02, 0) + dbo.XF_NVL_N(@n_b1_retire_amt, 0) ;   -- 2009.03.02 추가    
            SET @n_r01 = @n_r01+ dbo.XF_NVL_N(@n_r01_a, 0)   -- 2009.03.02 C_02 를 R01_A 로 수정    
         END    
    
        -- 2009.02.26 추가 수정분 end    
      */    
      /*================================================================*/    
      --2013.05.10  KSY 수정종료    
      /*================================================================*/    
    
         --*****************************************************************************************    
         -- 1. 퇴직소득공제 : 정률공제(40%) + 근속년수공제(누진공제공제액*(근속년수-차감근속년수))    
         --*****************************************************************************************    
         -- 법정퇴직소득공제 -> 정률소득공제(40%)    
         --t_rep_calc_list.R02_01   := XF_TRUNC_N(NVL(t_rep_calc_list.R01,0) * 0.40, 0);    -- 법정    
         --SET @n_r02_01 = dbo.XF_ROUND(@n_r01 * 0.40, 0)    -- 법정    
		 SET @n_r02_01 = dbo.XF_TRUNC_N(@n_r01 * 0.40, 0)    -- 법정		-- 소수점 이하절사로 패치적용(2017.02.01)
         /*================================================================*/    
          --2013.05.10  KSY 수정    
          --근속연수공제 함수로 대체처리함 --F_REP_BASIC_INFO    
        /*================================================================*/    
    
        --누진공제+공제액*(근속년수-차감근속년수))    
        /* 근속년수공제(공제액*근속년수 + 누진공제) => 누진공제법 : 기본공제금액 * 근속년수 - 누진공제액*/    
        -- 2013.07.01 수정시작 : (29)근속연수공제(누진공제액+(근속년수-기준근속년수(n_etc_cd1))*기본공제금액)    
        --SET @n_r02_02 = dbo.XF_TO_NUMBER(@t_gongje_amt) * @n_bc1_work_yy - dbo.XF_TO_NUMBER(@t_nujin_amt)             -- 법정    
        SET @n_r02_02 =  dbo.XF_TO_NUMBER(dbo.F_REP_TAX_RETURN(@av_company_cd,@av_locale_cd,'REP_INCOME_GONGJE',@d_c1_end_ymd,@n_bc1_work_yy,'1'))    
                        + dbo.XF_TO_NUMBER(dbo.F_REP_TAX_RETURN(@av_company_cd,@av_locale_cd,'REP_INCOME_GONGJE',@d_c1_end_ymd,@n_bc1_work_yy,'2'))    
    
    
/*    
          t_rep_calc_list.R02_02   := XF_TO_NUMBER(F_FRM_BASE_SQL(av_company_cd, 'REP', '퇴직소득공제관리',  t_rep_calc_list.BC1_WORK_YY, 'XF_TO_DATE(''' || XF_TO_CHAR_D(t_rep_calc_list.tax_ymd, 'YYYY-MM-DD') ||''', ''YYYY-MM-DD'')', '1'))    
                                      * (t_rep_calc_list.BC1_WORK_YY-NVL(XF_TO_NUMBER(F_FRM_BASE_SQL(av_company_cd, 'REP', '퇴직소득공제관리',  t_rep_calc_list.BC1_WORK_YY, 'XF_TO_DATE(''' || XF_TO_CHAR_D(t_rep_calc_list.tax_ymd, 'YYYY-MM-DD') ||''', ''YYYY-MM-DD'')', '3')),0))    
                                      + XF_TO_NUMBER(F_FRM_BASE_SQL(av_company_cd, 'REP', '퇴직소득공제관리',  t_rep_calc_list.BC1_WORK_YY, 'XF_TO_DATE(''' || XF_TO_CHAR_D(t_rep_calc_list.tax_ymd, 'YYYY-MM-DD') ||''', ''YYYY-MM-DD'')', '2'));             -- 법정    -- 20090320 t_rep_calc_list.c1_end_ymd -> t_rep_calc_list.tax_ymd로 변경    
*/    
    
         --법정퇴직소득공제액 : 법정퇴직소득공제 + 근속년수공제    
         SET @n_r02 = dbo.XF_NVL_N(@n_r02_01,0)   + dbo.XF_NVL_N(@n_r02_02,0)   -- 법정    
    
          --  2013.08.28  시작    
          -- 한도액 적용 2013.08.28 삭제  =>  국세청 2013.05.28 변경내용으로 막고 아래 추가    
          /* IF t_rep_calc_list.R02 > t_rep_calc_list.R01 THEN    
             t_rep_calc_list.R02 := t_rep_calc_list.R01;    
           END IF;    */    
    
          --IF @n_r02 > (dbo.XF_NVL_N(@n_r01,0) - dbo.XF_NVL_N(@n_r02_01,0))    
          --      BEGIN    
          --          SET @n_r02 = dbo.XF_NVL_N(@n_r01,0) - dbo.XF_NVL_N(@n_r02_01,0)    
          --      END    
          -- 2013.09.11 수정       근속연수 공제 한도 올류 수정    
          IF @n_r02_02 > (dbo.XF_NVL_N(@n_r01,0) - dbo.XF_NVL_N(@n_r02_01,0))    
            BEGIN    
               SET @n_r02_02 = dbo.XF_NVL_N(@n_r01,0) - dbo.XF_NVL_N(@n_r02_01,0)    
               SET @n_r02 = dbo.XF_NVL_N(@n_r02_01,0) + dbo.XF_NVL_N(@n_r02_02,0)  -- 법정    
            END    
    
          --*****************************************************************************************    
          -- 2. 과세표준 : 퇴직급여액 - 퇴직소득공제    
          --*****************************************************************************************    
          SET @n_r03 = dbo.XF_NVL_N(@n_r01,0) - dbo.XF_NVL_N(@n_r02,0) -- 법정    
         /*================= 2013 추가 ===========================================================*/    
         -- n_work_yy_2012 = 기산일 ~ 2012.12.31 까지의 근속년수(1일 이라도 1년으로 계산)    
         -- n_work_yy_2013 = 현근속년수 - n_work_yy_2012    
         -- 2003.3.1 입사하여 2013.1.31 퇴사 시 근속연수 계산    
         --    1. 전체 근속연수 : 119월 → 9년 11월 → 10년    
         --    2. 2012년 12월 31일까지의 근속연수 : 118월 → 9년 10월 → 10년    
         --    3. 2013년 1월 1일 이후 근속연수 : 10년 - 10년 = 0    
         -- 2004.4.1 입사하여 2013.1.31 퇴사 시 근속연수 계산    
         --    1. 전체 근속연수 : 109월 → 9년 1개월 → 10년    
         --    2. 2012년 12월 31일까지의 근속연수 : 108월 → 9년 0월 → 9년    
         --    3. 2013년 1월 1일 이후 근속연수 : 10년 - 9년 = 1    
    
         /*================================================================*/    
          --2013.05.10  KSY 추가    
         /*================================================================*/    
         --2012년까지 시작일    
         /* 2013.06.04 수정:주석처리    
         IF t_rep_calc_list.C1_STA_YMD <= TO_DATE('20121231','YYYYMMDD') THEN    
            t_rep_calc_list.C1_STA_YMD_2012 := t_rep_calc_list.C1_STA_YMD ;    
         ELSE    
            t_rep_calc_list.C1_STA_YMD_2012 := NULL;    
         END IF ;    
         */    
    
         --  2013.08.28  시작    
        /*    
         -- 2013.06.04 추가:2012년까지 시작일 시작    
IF xf_nvl_c(t_rep_calc_list.REP_MID_YN,'N') = 'Y' THEN    
            IF t_rep_mid_calc_list_sta_ymd <= TO_DATE('20121231','YYYYMMDD') THEN    
              t_rep_calc_list.C1_STA_YMD_2012 := t_rep_mid_calc_list_sta_ymd;    
            ELSE    
              t_rep_calc_list.C1_STA_YMD_2012 := NULL;    
            END IF;    
         ELSE    
            IF t_rep_calc_list.C1_STA_YMD <= TO_DATE('20121231','YYYYMMDD') THEN    
                t_rep_calc_list.C1_STA_YMD_2012 := t_rep_calc_list.C1_STA_YMD ;    
            ELSE    
                t_rep_calc_list.C1_STA_YMD_2012 := NULL;    
            END IF ;    
         END IF ;    
         -- 2013.06.04 추가:2012년까지 시작일 끝    
         */    
         IF @d_sum_sta_ymd  <= dbo.XF_TO_DATE('20121231','YYYYMMDD')    
           BEGIN    
             SET @d_c1_sta_ymd_2012 = @d_sum_sta_ymd    
           END    
         ELSE    
           BEGIN    
             SET @d_c1_sta_ymd_2012 = NULL    
           END    
         --  2013.08.28 끝    
         IF @d_c1_sta_ymd_2012 IS NULL    
           BEGIN    
             SET @d_c1_end_ymd_2012 = NULL    
           END    
         ELSE    
           BEGIN    
             IF @d_sum_end_ymd >= dbo.XF_TO_DATE('20121231','YYYYMMDD')    
               BEGIN    
                 SET @d_c1_end_ymd_2012 = dbo.XF_TO_DATE('20121231','YYYYMMDD')    
               END    
             ELSE    
               BEGIN    
                 SET @d_c1_end_ymd_2012 = @d_sum_end_ymd    
               END    
           END    
         --  2013.08.28 끝    
    
    
        --2012년까지 근속월    
        SET @n_c1_work_mm_2012 = dbo.XF_CEIL(dbo.XF_MONTHDIFF(dbo.XF_DATEADD(@d_c1_end_ymd_2012,1), @d_c1_sta_ymd_2012),0)    
    
        SET @n_c1_work_yy_2012 = dbo.XF_CEIL((dbo.XF_NVL_N(@n_c1_work_mm_2012,0) - dbo.XF_NVL_N(@n_except_mm_2012,0)+dbo.XF_NVL_N(@n_add_mm_2012,0)) / 12,0)    
    
      -- 2013년부터 시작일 시작    
         IF @d_sum_sta_ymd  < dbo.XF_TO_DATE('20130101','YYYYMMDD')    
           BEGIN    
             IF @d_sum_end_ymd <= dbo.XF_TO_DATE('20130101','YYYYMMDD')    
               BEGIN    
                 SET @d_c1_sta_ymd_2013 = NULL    
               END    
             ELSE    
               BEGIN    
                 SET @d_c1_sta_ymd_2013 = dbo.XF_TO_DATE('20130101','YYYYMMDD')    
               END    
           END    
         ELSE    
           BEGIN    
             SET @d_c1_sta_ymd_2013 = @d_sum_sta_ymd    
           END    
         --2013년부터 종료일    
        SET @d_c1_end_ymd_2013 = @d_sum_end_ymd    
    
        --  2013.08.28 끝    
    
         --2013년부터 근속월    
         --t_rep_calc_list.C1_WORK_MM_2013 := XF_NVL_N(t_rep_calc_list.C1_WORK_MM,0) - XF_NVL_N(t_rep_calc_list.C1_WORK_MM_2012,0); -- 2013.06.04 수정:주석처리    
    
         --  2013.08.28  시작    
         /*-- 2013.06.04 추가:2013년부터 근속월 시작    
         IF xf_nvl_c(t_rep_calc_list.REP_MID_YN,'N') = 'Y' THEN    
             t_rep_calc_list.C1_WORK_MM_2013 := XF_CEIL(XF_MONTHDIFF(t_rep_calc_list.C1_END_YMD_2013 + 1, t_rep_calc_list.C1_STA_YMD_2013), 0) ;    
         ELSE    
             t_rep_calc_list.C1_WORK_MM_2013 := XF_NVL_N(t_rep_calc_list.C1_WORK_MM,0) - XF_NVL_N(t_rep_calc_list.C1_WORK_MM_2012,0) ;    
         END IF;    
         -- 2013.06.04 추가:2013년부터 근속월 끝    
         */    
    
    
       --  SET @n_c1_work_mm_2013 = dbo.XF_CEIL(dbo.XF_MONTHDIFF(dbo.XF_DATEADD(@d_c1_end_ymd_2013,1), @d_c1_sta_ymd_2013),0)    
		 SET @n_c1_work_mm_2013 = dbo.XF_NVL_N(@n_sum_work_mm,0) - dbo.XF_NVL_N(@n_c1_work_mm_2012,0) --2017년 개정 : [2013.01.01 이후 근속월수] = [정산 근속월수] - [2012.12.31 이전 근속월수]

         -- 2013.06.04 추가:2013년부터 근속월 끝    
    
         -- 2013.01.01부터 근속년수    
         SET @n_c1_work_yy_2013 = dbo.XF_NVL_N(@n_bc1_work_yy,0) - dbo.XF_NVL_N(@n_c1_work_yy_2012,0)    
--SET @av_ret_code      = 'FAILURE!'    
--SET @av_ret_message   = '@n_r03='+DBO.XF_TO_CHAR_N(@n_r03,NULL) +'@n_c1_work_yy_2012 ='+ DBO.XF_TO_CHAR_N(@n_c1_work_yy_2012,NULL)+'@n_bc1_work_yy ='+ DBO.XF_TO_CHAR_N(@n_bc1_work_yy,NULL)--+'@n_r05_2013 ='+ DBO.XF_TO_CHAR_N(@n_r05_2013,NULL)    
----ROLLBACK TRAN    
--RETURN    
      /*================================================*/    
       --과세표준    
      /*================================================*/    
      --2012년까지 과세표준 : 퇴직소득과세표준 * 2012년까지의 근속년수 / 정산근속년수    
      --SET @n_r03_2012 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_r03,0) * dbo.XF_NVL_N(@n_c1_work_yy_2012,0),0) / dbo.XF_NVL_N(@n_bc1_work_yy,1)    
	  SET @n_r03_2012 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_r03,0) * dbo.XF_NVL_N(@n_c1_work_yy_2012,0) / dbo.XF_NVL_N(@n_bc1_work_yy,1) ,0) -- 소수점이하절사 패치적용(2017.02.01)
	    
    
      --2013년부터 과세표준 : 퇴직소득과세표준 - 2012년까지 과세표준    
      SET @n_r03_2013 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_r03,0)- dbo.XF_NVL_N(@n_r03_2012,0),0)    
    
      --  2013.08.28  시작    과세표준안분 정산(합산) 값 추가.    
      SET @n_r03_s = dbo.XF_NVL_N(@n_r03_2012,0) + dbo.XF_NVL_N(@n_r03_2013,0)    
      /*================================================================*/    
      --2013.05.10  KSY 추가 종료    
      /*================================================================*/    
    
      /* 2013 추가 */    
      -- 연평균 과세표준(2012) = 과세표준 * (2012년수/총년수) / 2012년수    
      -- 연평균 과세표준(2013) = 과세표준 * (2013년수/총년수) / 2013년수    
--SET @av_ret_code      = 'FAILURE!'    
--SET @av_ret_message   = '@n_c1_work_yy_2012='+DBO.XF_TO_CHAR_N(@n_c1_work_yy_2012,NULL) +'@n_r03_2012 ='+ DBO.XF_TO_CHAR_N(@n_r03_2012,NULL)--+'@n_r05_2012 ='+ DBO.XF_TO_CHAR_N(@n_r05_2012,NULL)+'@n_r05_2013 ='+ DBO.XF_TO_CHAR_N(@n_r05_2013,NULL)    
----ROLLBACK TRAN    
--RETURN    
      IF @n_c1_work_yy_2012 > 0 -- 법정이외(2013.01.01 ~)    
       --SET @n_r04_2012 = dbo.XF_TRUNC_N(@n_r03*(@n_c1_work_yy_2012/@n_work_yy_C1)/(@n_c1_work_yy_2012),0)-- 법정이외(~ 2012.12.31)    
       SET @n_r04_2012 = dbo.XF_TRUNC_N(@n_r03_2012/@n_c1_work_yy_2012,0)-- 법정이외(~ 2012.12.31)    
      ELSE    
       SET @n_r04_2012 = 0    
    
      IF @n_c1_work_yy_2013 > 0  -- 법정이외(2013.01.01 ~)    
       --SET @n_r04_2013 = dbo.XF_TRUNC_N(@n_r03*(@n_c1_work_yy_2013/@n_work_yy_C1)/(@n_c1_work_yy_2013),0)    
       SET @n_r04_2013 = dbo.XF_TRUNC_N(@n_r03_2013/@n_c1_work_yy_2013,0)    
      ELSE    
       SET @n_r04_2013 = 0    
    
      --SET @n_r04 = @n_r04_2012 + @n_r04_2013    
      --  2013.08.28  시작    
      SET @n_r04 = dbo.XF_TRUNC_N(@n_r03_s/@n_bc1_work_yy,0)    
      /* 2013 추가 끝*/    
    
          -- t_rep_calc_list.R04   := XF_TRUNC_N(t_rep_calc_list.R03/t_rep_calc_list.BC1_WORK_YY, 0); -- 법정, 2013년 comment 처리, 2013년 추가모듈로 대체    
    
      /*================================================================*/    
      --2013.05.10  KSY 수정시작    
      --법정이외 주석처리    
      /*================================================================*/    
      -- 주석처리 삭제하였음.    
      /*================================================================*/    
       --2013.05.10  KSY 수정종료    
      --법정이외 주석처리    
      /*================================================================*/    
    
      -- ***************************************************************************    
      -- (계)퇴직급여액 계산    
      -- (계)퇴직급여액 = (법정)퇴직급여액 + (법정이외)퇴직급여액    
      -- ***************************************************************************    
      --SET @n_r01_s = dbo.XF_NVL_N(@n_r01, 0) + dbo.XF_NVL_N(@n_r01_a, 0)    
      SET @n_r01_s =  dbo.XF_NVL_N(@n_r01, 0)    
    
      -- ***************************************************************************    
      -- (계)퇴직소득공제 계산    
      -- (계)퇴직소득공제 = (법정)법정퇴직소득공제 + (법정이외)법정퇴직소득공제    
      -- ***************************************************************************    
      --SET @n_r02_s = dbo.XF_NVL_N(@n_r02, 0) + dbo.XF_NVL_N(@n_r02_b, 0)    
      SET @n_r02_s = dbo.XF_NVL_N(@n_r02, 0)    
    
      -- ***************************************************************************    
      -- (계)퇴직소득과표 계산    
      -- (계)퇴직소득과표 = (법정)퇴직소득과표 + (법정이외)퇴직소득과표    
      -- ***************************************************************************    
      --SET @n_r03_s  = dbo.XF_NVL_N(@n_r03, 0) + dbo.XF_NVL_N(@n_r03_c, 0)    
      --  2013.08.28  시작   위에서 계산해서 주석 처리    
      --SET @n_r03_s  = dbo.XF_NVL_N(@n_r03, 0)    
      --PRINT(' @n_r03_s==='+ convert(varchar,@n_r03_s) +'='+ convert(varchar,@n_r03) +'+ '+ convert(varchar,@n_r03_c) )    
      -- ***************************************************************************    
      -- (계)연평균과세표준 계산    
      -- (계)연평균과세표준 = (법정)연평균과세표준 + (법정이외)연평균과세표준    
      -- ***************************************************************************    
      -- SET @n_r04_s = dbo.XF_NVL_N(@n_r04, 0) + dbo.XF_NVL_N(@n_r04_d, 0)    
      SET @n_r04_s = dbo.XF_NVL_N(@n_r04, 0)    
      --PRINT('P_REP_CAL_TAX   ===dbo.XF_NVL_N(@n_r04, 0) + dbo.XF_NVL_N(@n_r04_d, 0)>>>>'+ convert(varchar,@n_r04) +'+ '+ convert(varchar,@n_r04_d) )    
      --*****************************************************************************************    
      --  (계) 연평균 산출세액 :  연평균과세표준*기본세율 - 누진공제    
      --*****************************************************************************************    
      --SET @t_c3_end_ymd = 'dbo.XF_TO_DATE(''' + dbo.XF_TO_CHAR_D(@d_c1_end_ymd, 'YYYY-MM-DD') +''', ''YYYY-MM-DD'')'    
    
    
    
          /* 2013 Comment 처리    
          --수정 20090309 퇴직금은 퇴직일 기준. 중간정산은 정산일 기준으로 산정    
          IF t_rep_calc_list.CALC_TYPE_CD = '01' THEN    
          t_rep_calc_list.TAX_RATE :=XF_TO_NUMBER(F_FRM_BASE_SQL(av_company_cd, 'REP', '퇴직소득세율',  t_rep_calc_list.R04_S, 'XF_TO_DATE(''' || XF_TO_CHAR_D(XF_NVL_D(t_rep_calc_list.RETIRE_YMD,XF_SYSDATE(0)), 'YYYY-MM-DD') ||''', ''YYYY-MM-DD'')', '1'));    
    
          t_rep_calc_list.R05_S :=  XF_TRUNC_N(t_rep_calc_list.R04_S    
                             *  t_rep_calc_list.TAX_RATE/100    
                             - XF_TO_NUMBER(F_FRM_BASE_SQL(av_company_cd, 'REP', '퇴직소득세율',  t_rep_calc_list.R04_S, 'XF_TO_DATE(''' || XF_TO_CHAR_D(t_rep_calc_list.C1_END_YMD, 'YYYY-MM-DD') ||''', ''YYYY-MM-DD'')', '2')),0);    
          ELSE    
          t_rep_calc_list.TAX_RATE :=XF_TO_NUMBER(F_FRM_BASE_SQL(av_company_cd, 'REP', '퇴직소득세율',  t_rep_calc_list.R04_S, 'XF_TO_DATE(''' || XF_TO_CHAR_D(XF_NVL_D(t_rep_calc_list.RETIRE_YMD,XF_SYSDATE(0)), 'YYYY-MM-DD') ||''', ''YYYY-MM-DD'')', '1'));    
    
          t_rep_calc_list.R05_S :=  XF_TRUNC_N(t_rep_calc_list.R04_S    
                             *  t_rep_calc_list.TAX_RATE/100    
                             - XF_TO_NUMBER(F_FRM_BASE_SQL(av_company_cd, 'REP', '퇴직소득세율',  t_rep_calc_list.R04_S, 'XF_TO_DATE(''' || XF_TO_CHAR_D(XF_NVL_D(t_rep_calc_list.RETIRE_YMD,XF_SYSDATE(0)), 'YYYY-MM-DD') ||''', ''YYYY-MM-DD'')', '2')),0);    
          END IF;    
          2013 Comment 처리 끝*/    
    
          /* 2013 추가 시작 */    
          /* 연평균 산출세액    
           2012년 이전 : 2012년 이전 연평균 과세표준 * 세율 - 누적공제    
           2013년 이후 : ((2013년 이후 연평균 과세표준 * 5) * 세율 - 누적공제)    
          */    
    
          /*================================================================*/    
          --2013.05.10  KSY 수정    
            --퇴직소득세율 함수로 대체처리함 -- F_FRM_BASE_SQL -> F_REP_BASIC_INFO    
         /*================================================================*/    
--SET @av_ret_code      = 'FAILURE!'    
--SET @av_ret_message   = '@n_r04_2012='+DBO.XF_TO_CHAR_N(@n_r04_2012,NULL)-- +'@n_r04_2013 ='+ DBO.XF_TO_CHAR_N(@n_r04_2013,NULL)--+'@n_r05_2012 ='+ DBO.XF_TO_CHAR_N(@n_r05_2012,NULL)+'@n_r05_2013 ='+ DBO.XF_TO_CHAR_N(@n_r05_2013,NULL)    
----ROLLBACK TRAN    
--RETURN    
          -- 2012 소득세율(2012 연평균 과세표준 기준)    
          --SET @n_c1_tax_rate_2012 = dbo.XF_TO_NUMBER(dbo.F_FRM_BASE_SQL(@av_company_cd, 'REP', '퇴직소득세율',  @n_r04_2012,  dbo.XF_TO_CHAR_D(dbo.XF_NVL_D(@d_retire_ymd, dbo.XF_SYSDATE(0)), 'YYYY-MM-DD'), '1'))    
          SET @n_c1_tax_rate_2012 = dbo.XF_TO_NUMBER(dbo.F_REP_TAX_RETURN(@av_company_cd, @av_locale_cd,  'REP_INCOME_TAX_RATE', dbo.XF_NVL_D(@d_retire_ymd, dbo.XF_SYSDATE(0)),@n_r04_2012, '1'))    
    
          -- 2013 소득세율(2013 연평균 과세표준 5배수 기준)    
          --SET @n_c1_tax_rate_2013 =dbo.XF_TO_NUMBER(dbo.F_FRM_BASE_SQL(@av_company_cd, 'REP', '퇴직소득세율',  @n_r04_2013 * 5,  dbo.XF_TO_CHAR_D(dbo.XF_NVL_D(@d_retire_ymd, dbo.XF_SYSDATE(0)), 'YYYY-MM-DD'), '1'))    
          SET @n_c1_tax_rate_2013 = dbo.XF_TO_NUMBER(dbo.F_REP_TAX_RETURN(@av_company_cd, @av_locale_cd,  'REP_INCOME_TAX_RATE', dbo.XF_NVL_D(@d_retire_ymd, dbo.XF_SYSDATE(0)),@n_r04_2013 * 5, '1'))    
    
    
          -- 2012 연평균산출세액    
            /*    
          SET @n_r05_2012 =  dbo.XF_TRUNC_N(@n_r04_2012 *  @n_c1_tax_rate_2012/100    
                             - dbo.XF_TO_NUMBER(dbo.F_FRM_BASE_SQL(@av_company_cd, 'REP', '퇴직소득세율',  @n_r04_2012, dbo.XF_TO_CHAR_D(@d_c1_end_ymd, 'YYYY-MM-DD'), '2')),0)    
          */    
          SET @n_r05_2012 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_r04_2012,0) * dbo.XF_NVL_N(@n_c1_tax_rate_2012,0) / 100    
                            --- dbo.XF_TO_NUMBER(dbo.F_REP_TAX_RETURN(@av_company_cd, @av_locale_cd,  'REP_INCOME_TAX_RATE', dbo.XF_NVL_D(@d_retire_ymd, dbo.XF_SYSDATE(0)),@n_r04_2013 * 5, '2'))    
                                      - dbo.XF_TO_NUMBER(dbo.F_REP_TAX_RETURN(@av_company_cd, @av_locale_cd,  'REP_INCOME_TAX_RATE', dbo.XF_NVL_D(@d_retire_ymd, dbo.XF_SYSDATE(0)),@n_r04_2012, '2')),0)    
    
          -- 2013 연평균산출세액    
          /*    
          SET @n_r05_2013 =  dbo.XF_TRUNC_N(@n_r04_2013 * 5 *  @n_c1_tax_rate_2013/100    
                             - dbo.XF_TO_NUMBER(dbo.F_FRM_BASE_SQL(@av_company_cd, 'REP', '퇴직소득세율',  @n_r04_2013 * 5,  dbo.XF_TO_CHAR_D(@d_c1_end_ymd, 'YYYY-MM-DD'), '2')),0)    
    
          */    
          SET @n_r05_2013 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_r04_2013 *5, 0) * dbo.XF_NVL_N(@n_c1_tax_rate_2013,0) / 100    
                                      - dbo.XF_TO_NUMBER(dbo.F_REP_TAX_RETURN(@av_company_cd, @av_locale_cd,  'REP_INCOME_TAX_RATE', dbo.XF_NVL_D(@d_retire_ymd, dbo.XF_SYSDATE(0)),@n_r04_2013 * 5, '2')),0)    
    
          -- 연평균산출세액    
          SET @n_r05 = dbo.XF_NVL_N(@n_r05_2012,0) + dbo.XF_NVL_N(@n_r05_2013,0)    
            
           --*****************************************************************************************  
             --  법정 퇴직금 연평균 산출세액 :  연평균 산출세액 * 법정퇴직금연평균과세표준/ 연평균과세표준의 합계 (법정+명예)  
             --****************************************************************************************  
             /*================================== 2013 추가 시작 ====================================================================*/  
             -- 2012 연평균산출세액(연평균 산출세액 * 2012 근속년수)  
             SET @n_rep_calc_R06_2012 = dbo.XF_NVL_N(@n_r05_2012,0) * dbo.XF_NVL_N(@n_c1_work_yy_2012,0)  
  
             --SET @av_ret_message = '산출세액 2012  : ' + dbo.xf_to_char_n(@n_rep_calc_R06_2012,null)  
  
             --RAISERROR (@av_ret_message, -- Message text.  
             --           11, -- Severity(10을 초과하면 DB가 죽음)  
             --           1 -- State.  
             --           );  
  
             -- 2013 연평균산출세액(연평균 산출세액 * 2013 근속년수) / 5 (연평균산출세액 계산 시 5배수로 계산 하였으므로 다시 나눔)  
             -- 2013.09.11   주석  
             -- t_rep_calc_list.R06_2013 := XF_NVL_N(t_rep_calc_list.R05_2013,0) * XF_NVL_N(t_rep_calc_list.C1_WORK_YY_2013 ,0) / 5;  
             -- 2013.09.11  단수처리 엑셀과 동일하게 수정  
             SET @n_rep_calc_R06_2013 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_r05_2013,0)/ 5,0) * dbo.XF_NVL_N(@n_c1_work_yy_2013 ,0)  
  
            --SET @av_ret_message = '산출세액 2013 : ' + dbo.xf_to_char_n(@n_rep_calc_R05_2013,null)  
  
            -- RAISERROR (@av_ret_message, -- Message text.  
            --            11, -- Severity(10을 초과하면 DB가 죽음)  
            --            1 -- State.  
            --            );  
             SET @n_rep_calc_R06 = dbo.XF_NVL_N(@n_rep_calc_R06_2012,0) + dbo.XF_NVL_N(@n_rep_calc_R06_2013,0)           -- ??  
  
             --SET @av_ret_message = '환산 산출세액 : ' + dbo.xf_to_char_n(@n_rep_calc_R06,null)  
  
             --RAISERROR (@av_ret_message, -- Message text.  
             --           11, -- Severity(10을 초과하면 DB가 죽음)  
             --           1 -- State.  
             --           );  
             /* ===================================2013 추가 끝 ======================================================================*/  
  
    
          /* 2013 추가 끝 */    
    
                /*########################################################################################################################    
                # 2016년 귀속 과세형평 개정안 시작                                                                                       #    
                ########################################################################################################################*/    
                -- 과세기간에 따른 산출세액 산정 
                IF dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_c1_end_ymd, 'YYYY')) >= 2016    
                    BEGIN    
                        -- 환산급여    
                        --SET @n_rep_calc_R04_N_12 = dbo.XF_TRUNC_N((dbo.XF_NVL_N(@n_rep_calc_R01,0) - @n_rep_calc_R02_02) / @n_rep_calc_BC1_WORK_YY, 0) * 12  
                        --SET @n_rep_calc_R04_N_12 = dbo.XF_TRUNC_N(((dbo.XF_NVL_N(@n_r01,0) - @n_r02_01) * 12) / @n_bc1_work_yy, 0)  2016.09.23 
						SET @n_rep_calc_R04_N_12 = dbo.XF_TRUNC_N(((dbo.XF_NVL_N(@n_r01,0) - @n_r02_02) * 12) / @n_bc1_work_yy, 0)
                        
						
                        -- 환산급여별공제    
                        --SET @n_rep_calc_R04_DEDUCT = dbo.F_REP_R04_DEDUCT(@av_company_cd, dbo.XF_NVL_D(@n_rep_calc_C1_END_YMD,dbo.XF_SYSDATE(0)), @n_rep_calc_R04_N_12)   
                        SET @n_rep_calc_R04_DEDUCT = dbo.F_REP_R04_DEDUCT(@av_company_cd, dbo.XF_NVL_D(@d_c1_end_ymd,dbo.XF_SYSDATE(0)), @n_rep_calc_R04_N_12)
    
                        -- 퇴직소득과세표준 = 환산급여 - 환산급여별공제    
                        SET @n_rep_calc_R04_12 = @n_rep_calc_R04_N_12 - @n_rep_calc_R04_DEDUCT    
    
                        -- 환산산출세액    
--                        SET @n_rep_calc_R05_12 = dbo.XF_TRUNC_N(@n_rep_calc_R04_12    
--                                               * dbo.F_REP_TAX_RETURN(@av_company_cd, 'KO', 'REP_INCOME_TAX_RATE', dbo.XF_NVL_D(@n_rep_calc_C1_END_YMD,dbo.XF_SYSDATE(0)), @n_rep_calc_R04_12, '1') / 100    
--                                               - dbo.F_REP_TAX_RETURN(@av_company_cd, 'KO', 'REP_INCOME_TAX_RATE', dbo.XF_NVL_D(@n_rep_calc_C1_END_YMD,dbo.XF_SYSDATE(0)), @n_rep_calc_R04_12, '2'), 0)  
                        SET @n_rep_calc_R05_12 = dbo.XF_TRUNC_N(@n_rep_calc_R04_12    
                                               * dbo.XF_TO_NUMBER(dbo.F_REP_TAX_RETURN(@av_company_cd, 'KO', 'REP_INCOME_TAX_RATE', dbo.XF_NVL_D(@d_c1_end_ymd,dbo.XF_SYSDATE(0)), @n_rep_calc_R04_12, '1')) / 100    
                                               - dbo.XF_TO_NUMBER(dbo.F_REP_TAX_RETURN(@av_company_cd, 'KO', 'REP_INCOME_TAX_RATE', dbo.XF_NVL_D(@d_c1_end_ymd,dbo.XF_SYSDATE(0)), @n_rep_calc_R04_12, '2')), 0)                           
    
                        -- 산출세액 = 연평균산출세액 * 정산근속년수    
                        --SET @n_rep_calc_R06_N = dbo.XF_TRUNC_N(@n_rep_calc_R05_12 / 12, 0) * @n_rep_calc_BC1_WORK_YY    
                        --SET @n_rep_calc_R06_N = dbo.XF_TRUNC_N(@n_rep_calc_R05_12 / 12, 0) * @n_bc1_work_yy  
                        SET @n_rep_calc_R06_N = dbo.XF_TRUNC_N(@n_rep_calc_R05_12 / 12 * @n_bc1_work_yy , 0)
    
                        -- 과세기간에 따른 산출세액 산정    
                        IF      dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_c1_end_ymd, 'YYYY')) = 2016  -- 2016년 한해 산출세액 = (개정전_산출세액 * 80%) + (개정후_산출세액 * 20%)    
                            BEGIN    
                                SET @n_rep_calc_R06 = dbo.XF_TRUNC_N(@n_rep_calc_R06 * 0.8 + @n_rep_calc_R06_N * 0.2, 0)    
                            END    
                        ELSE IF dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_c1_end_ymd, 'YYYY')) = 2017  -- 2017년 한해 산출세액 = (개정전_산출세액 * 60%) + (개정후_산출세액 * 40%)    
                            BEGIN    
                                SET @n_rep_calc_R06 = dbo.XF_TRUNC_N(@n_rep_calc_R06 * 0.6 + @n_rep_calc_R06_N * 0.4, 0)    
                            END    
                        ELSE IF dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_c1_end_ymd, 'YYYY')) = 2018  -- 2018년 한해 산출세액 = (개정전_산출세액 * 40%) + (개정후_산출세액 * 60%)    
                            BEGIN    
                                SET @n_rep_calc_R06 = dbo.XF_TRUNC_N(@n_rep_calc_R06 * 0.4 + @n_rep_calc_R06_N * 0.6, 0)    
                            END    
                        ELSE IF dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_c1_end_ymd, 'YYYY')) = 2019  -- 2019년 한해 산출세액 = (개정전_산출세액 * 20%) + (개정후_산출세액 * 80%)    
                            BEGIN    
                                SET @n_rep_calc_R06 = dbo.XF_TRUNC_N(@n_rep_calc_R06 * 0.2 + @n_rep_calc_R06_N * 0.8, 0)    
                            END    
                        ELSE IF dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_c1_end_ymd, 'YYYY')) > 2019  -- 2020년 이후 산출세액 = (개정후_산출세액 * 100%)    
                            BEGIN    
                                SET @n_rep_calc_C1_STA_YMD_2012    = NULL    
                                SET @n_rep_calc_C1_END_YMD_2012    = NULL    
                                SET @n_rep_calc_C1_WORK_MM_2012    = NULL    
                                SET @n_rep_calc_EXCEPT_MM_2012     = NULL    
                                SET @n_rep_calc_ADD_MM_2012        = NULL    
                                SET @n_rep_calc_C1_WORK_YY_2012    = NULL    
                                SET @n_rep_calc_C1_STA_YMD_2013    = NULL    
                                SET @n_rep_calc_C1_END_YMD_2013    = NULL    
                                SET @n_rep_calc_C1_WORK_MM_2013    = NULL    
                                SET @n_rep_calc_EXCEPT_MM_2013     = NULL    
                                SET @n_rep_calc_ADD_MM_2013        = NULL    
                                SET @n_rep_calc_C1_WORK_YY_2013    = NULL    
                                SET @n_rep_calc_R02_01             = NULL    
                                SET @n_rep_calc_R03_2012           = NULL    
                                SET @n_rep_calc_R03_2013           = NULL    
                                SET @n_rep_calc_R04                = NULL    
                                SET @n_rep_calc_R04_2012           = NULL    
                                SET @n_rep_calc_R04_2013           = NULL    
                                SET @n_rep_calc_R05                = NULL    
                                SET @n_rep_calc_R05_2012           = NULL    
                                SET @n_rep_calc_R05_2013           = NULL    
                                SET @n_rep_calc_R06                = @n_rep_calc_R06_N    
                                SET @n_rep_calc_R06_2012           = NULL    
                                SET @n_rep_calc_R06_2013           = NULL    
                            END    
                    END    
                 /*########################################################################################################################    
                 # 2016년 귀속 과세형평 개정안 종료                       #    
                 ########################################################################################################################*/    
    
                  --*****************************************************************************************    
                  --  법정 퇴직금 연평균 산출세액 :  연평균 산출세액 * 법정퇴직금연평균과세표준/ 연평균과세표준의 합계 (법정+명예)    
                  --****************************************************************************************    
              /* 2013 Comment 처리    
            t_rep_calc_list.R05   := XF_TRUNC_N(t_rep_calc_list.R05_S * t_rep_calc_list.R04/t_rep_calc_list.R04_S,0)   ;-- 법정    
          2013 Comment 처리 끝    
    
                  IF @n_r04_s > 0    
                     BEGIN    
                         SET @n_r05 = dbo.XF_TRUNC_N(@n_r05_s * @n_r04/@n_r04_s,0)   -- 법정    
                     END    
    
                  ELSE    
                     BEGIN    
                         SET @n_r05 = 0    
                     END    
           */    
    
                  --*****************************************************************************************    
      -- 법정 산출세액 :   연평균산출세액 * 근속년수    
                  --              OR 환산연평균산출세액 * 근속년수 * (퇴직급여계 / 수령가능퇴직급여액)    
                  --*****************************************************************************************    
              /* 2013 Comment 시작    
          t_rep_calc_list.R06   := t_rep_calc_list.R05   * t_rep_calc_list.BC1_WORK_YY;             -- 법정    
          2013 Comment 끝    
    
                  SET @n_r06 = @n_r05  * @n_bc1_work_yy             -- 법정    
                  --PRINT('P_REP_CAL_TAX  START ===@n_r05 *@n_bc1_work_yy>>>>'+ convert(varchar,@n_r05) +' '+ convert(varchar,@n_bc1_work_yy) )    
          */    
    
           /* 2013 추가 시작 */    
          -- 2012 산출세액(연평균 산출세액 * 2012 근속년수)    
          SET @n_r06_2012 = dbo.XF_NVL_N(@n_r05_2012,0) * dbo.XF_NVL_N(@n_c1_work_yy_2012,0)    
    
          -- 2013 산출세액(연평균 산출세액 * 2013 근속년수) / 5 (연평균산출세액 계산 시 5배수로 계산 하였으므로 다시 나눔)    
          --SET @n_r06_2013 = dbo.XF_NVL_N(@n_r05_2013,0) * dbo.XF_NVL_N(@n_c1_work_yy_2013,0) / 5 
          SET @n_r06_2013 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_r05_2013,0) / 5, 0) * dbo.XF_NVL_N(@n_c1_work_yy_2013,0) --MODIFIED BY NICKY 2016.09.23   
    
         -- SET @n_r06  = dbo.XF_NVL_N(@n_r06_2012,0) + dbo.XF_NVL_N(@n_r06_2013,0)             -- 법정    
          SET @n_r06  =  @n_rep_calc_R06         --MODIFIED BY NICKY 2016.09.23 
          /* 2013 추가 끝 */    
    
              /* 2013 추가 시작 */    
          SET @n_r06_base = @n_r06  --산출세액 베이스    
         -- ***************************************************************************    
         -- (계)산출세액 계산    
         -- (계)산출세액 = (법정)산출세액 + (법정이외)산출세액    
         -- ***************************************************************************    
          SET @n_r06_s = @n_r06    
          /* 2013 추가 끝 */    
--    
--        --2. 근속년수    
--         SET @n_real_yy = dbo.XF_CEIL(@n_c1_work_mm/12, 0)    
--    
--          /*================================================================*/    
--          --2013.05.10  KSY 수정    
--          --퇴직소득공제관리 함수로 대체처리함 --F_REP_BASIC_INFO    
--         /*================================================================*/    
--         --3. 기본공제 + 근속년수공제    
--         SET @n_real_r02 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_c_01, 0) * 0.40,0) +    
--                 (dbo.F_REP_BASIC_INFO(@av_company_cd,@n_real_yy, dbo.XF_NVL_D(@d_c1_end_ymd, dbo.XF_SYSDATE(0)),'퇴직소득공제관리', '2')    
--                 *  @n_real_yy    
--                 - dbo.F_REP_BASIC_INFO(@av_company_cd,@n_real_yy, dbo.XF_NVL_D(@d_c1_end_ymd,dbo.XF_SYSDATE(0)),'퇴직소득공제관리', '1') )    
--    
--         --4. 과세표준    
--         SET @n_real_r03 = dbo.XF_NVL_N(@n_c_01, 0) - dbo.XF_NVL_N(@n_real_r02,0)    
--    
--        --5. 연평균과세표준    
--         SET @n_real_r04 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_real_r03,0) / dbo.XF_NVL_N(@n_real_yy,0),0)    
--    
--          /*================================================================*/    
--          --2013.05.10  KSY 수정    
--          --퇴직소득세율 함수로 대체처리함 --F_REP_BASIC_INFO    
--         /*================================================================*/    
--         --6. 산출세액    
--         SET @n_real_tax_rate = dbo.F_REP_BASIC_INFO(@av_company_cd, @n_real_r04, dbo.XF_NVL_D(@d_retire_ymd, dbo.XF_SYSDATE(0)),'퇴직소득세율', '2')    
--    
--         SET @n_real_r05 = @n_real_r04 * dbo.XF_NVL_N(@n_real_tax_rate,0) / 100    
--               - dbo.F_REP_BASIC_INFO(@av_company_cd, @n_real_r04, dbo.XF_NVL_D(@d_c1_end_ymd, dbo.XF_SYSDATE(0)),'퇴직소득세율', '1')    
--    
--        -- ***************************************************************************    
                  -- (계)산출세액 계산    
                  -- (계)산출세액 = (법정)산출세액 + (법정이외)산출세액    
                  -- ***************************************************************************    
                  --SET @n_r06_s = dbo.XF_NVL_N(@n_r06, 0) + dbo.XF_NVL_N(@n_r06_f, 0)    
                   --SET @n_r06_s = CEILING(dbo.XF_NVL_N(@n_r06, 0) + dbo.XF_NVL_N(@n_r06_f, 0) )    
           SET @n_r06_s = dbo.XF_NVL_N(@n_r06, 0)    
    
          -- ***************************************************************************    
                  -- (계)세액공제 계산    
                  -- (계)세액공제 = 0    
                  -- ***************************************************************************    
                  --SET @n_r07_s = 0    
          --SET @n_r07_s = dbo.XF_NVL_N(@n_r07, 0) + dbo.XF_NVL_N(@n_r07_g, 0) -- 이택원 수정 2009.11.23    
          SET @n_r07_s = dbo.XF_NVL_N(@n_r07, 0)    
    
        -- ***************************************************************************    
                  -- (계)결정세액 계산    
                  -- (계)결정세액 = (법정)결정세액 + (법정이외)결정세액    
                  -- ***************************************************************************    
          SET @n_r08 = dbo.XF_NVL_N(@n_r06,0) - dbo.XF_NVL_N(@n_r07,0) - dbo.XF_NVL_N(@n_retire_mid_income_amt, 0)    
                  --SET @n_r08_s = dbo.XF_NVL_N(@n_r08, 0) + dbo.XF_NVL_N(@n_r08_h, 0)    
          SET @n_r08_s = dbo.XF_NVL_N(@n_r06_s,0) - dbo.XF_NVL_N(@n_r07_s,0) - dbo.XF_NVL_N(@n_retire_mid_income_amt, 0)    
    
    
    
          /*=============================    
           -- 2012 추가 사항 과세이연    
           ===============================*/    
           --2013.05.10  KSY 수정    
          IF EXISTS (SELECT EMP_ID    
                       FROM REP_INCOME_TAX    
                      WHERE WORK_YMD = @d_c1_end_ymd    
                        AND EMP_ID = @n_emp_id)    
           BEGIN    
            SELECT @n_incom_sum_amt = sum(dbo.XF_NVL_N(TRANS_ALLOWANCE_COURT,0)) + sum(dbo.XF_NVL_N(TRANS_ALLOWANCE_COURT_OTHER,0)),    
                 @n_incom_c_01 = sum(TRANS_ALLOWANCE_COURT),    
                 @n_incom_c_02 = sum(TRANS_ALLOWANCE_COURT_OTHER),    
                 @v_biz_nm = MAX(REP_ANNUITY_BIZ_NM),    
                 @v_biz_no = MAX(REP_ANNUITY_BIZ_NO),    
                 @v_account_no = MAX(REP_ACCOUNT_NO)    
              FROM REP_INCOME_TAX  -- 과세이연테이블    
             WHERE  -- 2013.08.28  시작    
             -- 중간정산이 있을 수 있으므로 퇴직정산일이 맞는거 같은데 사이트에 맞쳐서 수정 해야 할 거 같음    
             --dbo.XF_TO_CHAR_D(WORK_YMD,'YYYY') = dbo.XF_TO_CHAR_D(@d_c1_end_ymd,'YYYY')    
               WORK_YMD = @d_c1_end_ymd    
               AND EMP_ID = @n_emp_id    
           END    
         ELSE    
           BEGIN    
            SET @n_incom_sum_amt    = 0    
            SET @n_incom_c_01    = 0    
            SET @n_incom_c_02    = 0    
            SET @v_biz_nm    = NULL    
            SET @v_biz_no    = NULL    
            SET @v_account_no    = NULL    
           END    
    
          /*2012 추가 사항    
          거주자가 퇴직으로 인하여 지급받는 퇴직급여액(명예퇴직수당과 단체퇴직보험금을 포함)의 100분의 80에 해당하는 금액 이상을 퇴직을 날부터    
                  60일이내에 확정기여향퇴직연금 또는 개인퇴직계좌(이하 "과세이연계좌"라 함)로 이체 또는 입금하는 경우 당해 퇴직급여액은 실제로 지급받기 전까지    
                  퇴직소득으로 보지 아니함    
    
                  납부해야할 세액 = 퇴직금 전액에 부과될 퇴직소득산출 세액 * 과세이연계좌에 이체되지 않은 퇴직금 / 퇴직금 전액    
                  */    
    
          /* 2013 Comment 시작    
        IF n_incom_sum_amt >= (t_rep_calc_list.R01_S * 0.8) THEN    
          t_rep_calc_list.CT01 := t_rep_calc_list.CT01 * (t_rep_calc_list.R01_S - n_incom_sum_amt) / t_rep_calc_list.R01_S;    
        END IF;    
        2013 Comment 끝 */    
    
        /*    
          IF @n_incom_sum_amt >= (@n_r01_s * 0.8)    
          BEGIN    
            SET @n_ct01 = @n_ct01 * ( @n_r01_s - @n_incom_sum_amt ) / @n_r01_s   -- 2012.09.10 추가    
          END    
        */    
    
        /*================================================================*/    
          --2013.05.10  KSY 수정    
          --과세이연 퇴직소득세 계산    
         /*================================================================*/    
         IF dbo.XF_NVL_N(@n_incom_sum_amt,0) > 0    
            BEGIN    
              --과세이연금    
              SET @n_trans_amt = dbo.XF_NVL_N(@n_incom_c_01,0)    
              SET @n_trans_other_amt = dbo.XF_NVL_N(@n_incom_c_02,0)    
    
              --**************************************************************    
              -- 과세이연 퇴직소득세 = 결정세액 * (과세이연금액) / 퇴직급여    
              --**************************************************************    
              --SET @n_trans_income_amt = dbo.XF_NVL_N(@n_r08_s,0) * dbo.XF_NVL_N(@n_incom_sum_amt,0) / (dbo.XF_NVL_N(@n_c_01,0) + dbo.XF_NVL_N(@n_c_02, 0))    
			  SET @n_trans_income_amt = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_r08_s,0) * dbo.XF_NVL_N(@n_incom_sum_amt,0) / (dbo.XF_NVL_N(@n_c_01,0) + dbo.XF_NVL_N(@n_c_02, 0)) ,0)   --원단위절사 패치적용(2017.02.01)
              SET @n_trans_residence_amt = dbo.XF_TRUNC_N(@n_trans_income_amt / 10,0)    
               --  2013.08.28  시작    
               /*  2013.08.28 추가    
               2013.07.09 변경내용:    
               1. (42) 과세이연세액이 (-)음수 발생시((39)신고대상세액이 (-) 인 경우)    
                  (42) 과세이연세액 0으로 표기되도록 변경.    
                  ※ (45) 차감원천징수세액 (-) 음수. 환급발생.*/    
              IF @n_trans_income_amt < 0    
                BEGIN    
                  SET @n_trans_income_amt = 0    
                  SET @n_trans_residence_amt = 0    
                END    
              --  2013.08.28 끝    
            END    
         ELSE    -- 2013.07.01 추가:과세이연계좌 금액이 없을경우 0을 반영한다.    
            BEGIN    
              SET @n_trans_amt = 0    
              SET @n_trans_other_amt = 0    
              SET @n_trans_income_amt = 0    
              SET @n_trans_residence_amt = 0    
            END    
    
    
        -- ***************************************************************************    
        -- 소득세 계산    
        -- 소득세 = (계)결정세액    
        -- ***************************************************************************    
        --SET @n_ct01 = dbo.XF_TRUNC_N(@n_r08_s, -1)    
        SET @n_ct01 = dbo.XF_TRUNC_N(@n_r08_s, 0)    
        -- ***************************************************************************    
        -- 주민세 계산    
        -- 주민세 = 소득세 / 10    
        -- ***************************************************************************    
        --SET @n_ct02 = dbo.XF_TRUNC_N(@n_ct01 / 10, -1)    
        SET @n_ct02 = dbo.XF_TRUNC_N(@n_ct01 / 10, 0)    
        -- ***************************************************************************    
        -- 농특세 계산    
        -- 농특세 = 0    
        -- ***************************************************************************    
        SET @n_ct03 = 0    
    
        -- ***************************************************************************    
        -- 세액계 계산    
        -- 세액계 = 소득세 + 주민세 + 농특세    
        -- ***************************************************************************    
        SET @n_ct_sum = dbo.XF_NVL_N(@n_ct01, 0) + dbo.XF_NVL_N(@n_ct02, 0) + dbo.XF_NVL_N(@n_ct03, 0)    
    
        --*****************************************************************************************    
        -- 기납부세액 : 종전근무지에서 납부된 세액의 합.    
        --*****************************************************************************************    
    
        -- ***************************************************************************    
        -- 종(전)세액계 계산    
        -- 종(전)세액계 = 종(전)소득세 + 종(전)주민세 + 종(전)농특세    
        -- ***************************************************************************    
        SET @n_bt_sum = dbo.XF_NVL_N(@n_bt01, 0) + dbo.XF_NVL_N(@n_bt02, 0) + dbo.XF_NVL_N(@n_bt03, 0)    
    
        -- ***************************************************************************    
        -- 차감소득세 계산    
        -- 차감소득세 = 소득세 - 종(전)소득세    
        -- ***************************************************************************    
        SET @n_t01 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_ct01, 0) - dbo.XF_NVL_N(@n_bt01, 0) - dbo.XF_NVL_N(@n_trans_income_amt,0) ,-1)   
    
        -- ***************************************************************************    
        -- 차감주민세 계산    
        -- 차감주민세 = 주민세 - 종(전)주민세    
        -- ***************************************************************************    
        SET @n_t02 = dbo.XF_TRUNC_N(dbo.XF_NVL_N(@n_ct02, 0) - dbo.XF_NVL_N(@n_bt02, 0) - dbo.XF_NVL_N(@n_trans_residence_amt,0) ,-1)    
    
        -- ***************************************************************************    
        -- 차감농특세 계산    
        -- 차감농특세 = 농특세 - 종(전)농특세    
        -- ***************************************************************************    
        SET @n_t03 = dbo.XF_NVL_N(@n_ct03, 0) - dbo.XF_NVL_N(@n_bt03, 0)    
    
        -- ***************************************************************************    
        -- 차감세액계 계산    
        -- 차감세액계 = 차감소득세 + 차감주민세 + 차감농특세    
        -- ***************************************************************************    
        SET @n_t_sum = dbo.XF_NVL_N(@n_t01, 0) + dbo.XF_NVL_N(@n_t02, 0) + dbo.XF_NVL_N(@n_t03, 0)    
    
        SET @n_c_sum = dbo.XF_NVL_N(@n_c_01, 0) + dbo.XF_NVL_N(@n_c_02, 0)    
    
        SET @n_chain_amt = dbo.XF_NVL_N(@n_c_sum, 0) - dbo.XF_NVL_N(@n_t_sum, 0)  -- 차인지급액    
    
        SET @n_retire_turn = 0 --dbo.F_REP_PEN_RETIRE_MON(@n_emp_id, @d_c1_end_ymd) -- 국민연금퇴직전환금    
    
    
         -- 실지급액    
        SET @n_real_amt = @n_chain_amt -  dbo.XF_NVL_N(@n_retire_turn, 0)    
           -  dbo.XF_NVL_N(@n_c_01_2, 0)    
                                       -  dbo.XF_NVL_N(@n_etc_deduct, 0)    
                                       +  dbo.XF_NVL_N(@n_etc_pay_amt, 0)    
                                           
        -- 2014.08.20 롯데시네마에서추가    
        -- 퇴직연금가입자(DB/DC)인경우 퇴직연금,과세이연소득세, 과세이연주민세에 추가하고 실지급액은 소득세/주민세 차감하지 않는다.    
        -- 퇴직금인경우    
        /*IF @n_calc_type_cd = '01'    
          BEGIN    
            DECLARE @v_rep_yn           CHAR(1)    
            SET @v_rep_yn = 'N'    
            BEGIN    
              SELECT @v_rep_yn = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END    
                FROM (SELECT EMP_ID    
                        FROM REP_INSUR_MON    
                       WHERE EMP_ID = @n_emp_id    
                         AND @d_c1_end_ymd BETWEEN STA_YMD AND END_YMD    
--                      UNION ALL    
--                      SELECT EMP_ID    
--                        FROM VI_FRM_PHM_EMP    
--                       WHERE EMP_ID = @n_emp_id    
--                         AND EMP_KIND_CD != '30700004'    
--                         AND COMPANY_CD = @av_company_cd    
--                         AND LOCALE_CD = @av_locale_cd   
                     ) A    
            END    
        
            IF @v_rep_yn = 'Y'    
              BEGIN    
                SET @n_trans_amt = @n_c_sum    
                SET @n_trans_income_amt = @n_t01    
                SET @n_trans_residence_amt = @n_t02    
                SET @n_real_amt = @n_c_sum    
              END    
          END  */  
         -- 테이블에 저장    
         BEGIN    
            UPDATE REP_CALC_LIST  -- 퇴직금계산대상자(내역)    
               SET --ADD_WORK_YY              =  @n_add_work_yy             ,--추가근속년수    
                   C_01                     =  @n_c_01                    ,  -- 주(현)법정퇴직급여 =>  주(현)    
                   C_02                     =  @n_c_02                    ,  -- 주(현)명예퇴직수당등 (추가퇴직    
                   C_SUM                    =  @n_c_sum                   ,  -- 주(현)계    
                   B1_CORP_NM               =  @n_b1_corp_nm              ,  -- 종(전)지급처명   2013.08.28  -- 중간정산 근무처명 으로    
                   B1_TAX_NO              =  @v_b1_tax_no               ,  -- 종(전)사업자번호   2013.08.28  -- 중간정산 사업자번호 로    
                   B1_RETIRE_REP_AMT        =  @n_b1_retire_rep_amt       ,  -- 종(전)명예/희망퇴직금    
                   B1_RETIRE_AMT            =  @n_b1_retire_amt           ,  -- 종(전)퇴직금    
                   C1_STA_YMD               =  @d_c1_sta_ymd              ,  -- 법정주(현)기산일    
                   C1_END_YMD               =  @d_c1_end_ymd              ,  -- 주(현)정산일    
                   C1_WORK_MM               =  @n_c1_work_mm              ,  -- 주(현)근속월수    
                   B1_STA_YMD               =  @d_b1_sta_ymd              ,  -- 종(전)기산일 2013.08.28  -- 중간정산 입사일 로    
                   B1_END_YMD               =  @d_b1_end_ymd              ,  -- 종(전)정산일    
                   B1_WORK_MM               =  @n_b1_work_mm              ,  -- 종(전)근속월수    
                   BC1_DUP_MM               =  @n_bc1_dup_mm                ,  -- 중복월수(법정)    
                   BC1_WORK_YY              =  @n_bc1_work_yy               ,  -- 근속년수(법정)(현+종전 근속년    
                   -- 2013.05.10  KSY 수정시작    
                   --C2_STA_YMD               =  @d_c2_sta_ymd              ,  -- 법정이외주(현)기산일    
                   --C2_END_YMD               =  @d_c2_end_ymd              ,  -- 법정이외주(현)정산일    
                   --C2_WORK_MM               =  @n_c2_work_mm              ,  -- 법정이외주(현)근속월수    
                   --B2_STA_YMD               =  @d_b2_sta_ymd              ,  -- 법정이외종(전)기산일    
                   --B2_END_YMD               =  @d_b2_end_ymd              ,  -- 법정이외종(전)정산일    
                   --B2_WORK_MM               =  @n_b2_work_mm              ,  -- 법정이외종(전)근속월수    
                   --BC2_DUP_MM               =  @n_bc2_dup_mm                ,  -- 법정이외중복월수    
                   --BC2_WORK_YY              =  @n_bc2_work_yy               ,  -- 법정이외근속년수    
                   -- 2013.05.10  KSY 수정종료    
                   R01                      =  @n_r01                     ,  -- 법정퇴직급여액    
                   R02_01                   =  @n_r02_01                  ,  -- 법정퇴직소득공제(50%)    
                   R02_02        =  @n_r02_02                  ,  -- 법정퇴직소득공제(근속)    
                   R02                      =  @n_r02                     ,  -- 법정퇴직소득공제(01+02)    
                   R03                      =  @n_r03                     ,  -- 법정퇴직소득과표    
                   R04                      =  @n_r04                     ,  -- 법정연평균과세표준    
                   R05                      =  @n_r05                     ,  -- 법정연평균산출세액    
                   R06                      =  @n_r06                     ,  -- 법정산출세액    
                   R07                      =  @n_r07                     ,  -- 법정세액공제    
                   R08                      =  @n_r08                     ,  -- 법정결정세액    
                   -- 2013.05.10  KSY 수정시작    
                   --R01_A                    =  @n_r01_a                   ,  -- 법정이외퇴직급여액    
                   --R02_B_01                 =  @n_r02_b_01                ,  -- 법정이외퇴직소득공제(50%)    
                   --R02_B_02                 =  @n_r02_b_02                ,  -- 법정이외퇴직소득공제(근속)    
                   --R02_B                    =  @n_r02_b                   ,  -- 법정이외퇴직소득공제(01+02)    
                   --R03_C                    =  @n_r03_c                   ,  -- 법정이외퇴직소득과표    
                   --R04_D                    =  @n_r04_d                   ,  -- 법정이외연평균과세표준    
                   --R05_E                    =  @n_r05_e                   ,  -- 법정이외연평균산출세액    
                   --R06_F                    =  @n_r06_f                   ,  -- 법정이외산출세액    
                   --R07_G                    =  @n_r07_g                   ,  -- 법정이외세액공제    
                   --R08_H                    =  @n_r08_h                   ,  -- 법정이외결정세액    
                   -- 2013.05.10  KSY 수정종료    
                   TAX_RATE                 =  @n_tax_rate                ,  -- 세율    
         R01_S                    =  @n_r01_s                   ,  -- 퇴직급여액    
                   R02_S                    =  @n_r02_s                   ,  -- 퇴직소득공제    
                   R03_S                    =  @n_r03_s                   ,  -- 퇴직소득과표    
                   R04_S                    =  @n_r04_s                   ,  -- 연평균과세표준    
                   R05_S                    =  @n_r05_s                   ,  -- 연평균산출세액    
                   R06_S                    =  @n_r06_s                   ,  -- 산출세액    
                   R07_S                    =  @n_r07_s                   ,  -- 세액공제    
                   R08_S             =  @n_r08_s                   ,  -- 결정세액    
                   CT01                     =  @n_ct01                    ,  -- 퇴직소득세    
                   CT02                     =  @n_ct02                    ,  -- 퇴직주민세    
                   CT03                     =  @n_ct03                    ,  -- 퇴직농특세    
                   CT_SUM                   =  @n_ct_sum                  ,  -- 퇴직세액계    
                   BT01                     =  @n_bt01                    ,  -- 종(전)소득세    
                   BT02                     =  @n_bt02                    ,  -- 종(전)주민세    
                   BT03                     =  @n_bt03                    ,  -- 종(전)농특세    
                   BT_SUM                   =  @n_bt_sum                  ,  -- 종(전)세액계    
                   T01                      =  @n_t01                     ,  -- 차감소득세    
                   T02                      =  @n_t02                     ,  -- 차감주민세    
                   T03                      =  @n_t03                     ,  -- 차감농특세    
                   T_SUM                    =  @n_t_sum                   ,  -- 차감세액계    
                   CHAIN_AMT                =  @n_chain_amt               ,  -- 차인지급액(퇴직금)    
                  -- ETC_ATTACH_AMT           =  dbo.XF_NVL_N(@n_attach_mon,0)                            ,  -- 압류금    
                   ETC_DEDUCT               =  dbo.XF_NVL_N(@n_etc_deduct,0),  --기타공제(대여금+대여금이자+미수금+압류금+지사공제)    
                   ETC_PAY_AMT              = dbo.XF_NVL_N(@n_etc_pay_amt, 0),    
                   REAL_AMT                 =  @n_real_amt                ,  -- 실지급액    
                  -- CALC_YMD                 =  dbo.XF_SYSDATE(0)                           ,  -- 처리일자    
                   MOD_USER_ID              =  @an_mod_user_id            ,  -- 변경자    
                   MOD_DATE                 =  dbo.XF_SYSDATE(0)             ,     -- 변경일시    
                   /* 2013 추가 시작 */    
                   C1_WORK_YY_2012          = @n_c1_work_yy_2012 ,  -- 2012년까지 근속년수(법정)    
                   C1_WORK_YY_2013          = @n_c1_work_yy_2013 ,  -- 2013년부터 근속년수(법정)    
                   R04_2012                 = @n_r04_2012        ,  -- 2012년까지 연평균 과세표준(법정)    
                   R04_2013                 = @n_r04_2013        ,  -- 2013년부터 연평균 과세표준(법정)    
                   R05_2012                 = @n_r05_2012        ,  -- 2012년까지 연평균 산출세액(법정)    
                   R05_2013                 = @n_r05_2013        ,  -- 2013년부터 연평균 산출세액 (법정)    
                   R06_2012                 = @n_r06_2012        ,  -- 2012년까지 산출세액(법정)    
                   R06_2013                 = @n_r06_2013        ,  -- 2013년부터 산출세액(법정)    
                   C1_TAX_RATE_2012         = @n_c1_tax_rate_2012,  -- 2012년까지 세율(법정)    
                   C1_TAX_RATE_2013         = @n_c1_tax_rate_2013,  -- 2013년부터 세율(법정)    
                   C2_WORK_YY_2012          = @n_c1_work_yy_2012 ,  -- 2012년까지 근속년수(법정이외)    
                   C2_WORK_YY_2013          = @n_c1_work_yy_2013 ,  -- 2013년부터 근속년수(법정이외)    
                   R04_D_2012               = @n_r04_2012        ,  -- 2012년까지 연평균 과세표준(법정이외)    
                   R04_D_2013               = @n_r04_2013        ,  -- 2013년부터 연평균 과세표준(법정이외)    
                   R05_E_2012               = @n_r05_2012        ,  -- 2012년까지 연평균 산출세액(법정이외)    
                R05_E_2013               = @n_r05_2013      ,  -- 2013년부터 연평균 산출세액 (법정이외)    
                   R06_F_2012               = @n_r06_2012        ,  -- 2012년까지 산출세액(법정이외)    
                   R06_F_2013               = @n_r06_2013        ,  -- 2013년부터 산출세액(법정이외)    
                   C2_TAX_RATE_2012         = @n_c1_tax_rate_2012,  -- 2012년까지 세율(법정이외)    
                   C2_TAX_RATE_2013         = @n_c1_tax_rate_2013,   -- 2013년부터 세율(법정이외)    
                   /* 2013 추가 끝 */    
                   -- 2013.05.10  KSY 수정시작    
                   TRANS_AMT               = @n_trans_amt,            --과세이연금    
                   TRANS_OTHER_AMT         = @n_trans_other_amt,      --법정이외과세이연금액    
                   TRANS_INCOME_AMT        = @n_trans_income_amt ,    --과세이연 퇴직소득세    
                   TRANS_RESIDENCE_AMT     = @n_trans_residence_amt,  --과세이연 퇴직주민세    
                   C1_STA_YMD_2012         = @d_c1_sta_ymd_2012,      --2012년까지 시작일    
                   C1_END_YMD_2012         = @d_c1_end_ymd_2012,      --2012년까지 종료일    
                   C1_WORK_MM_2012         = @n_c1_work_mm_2012,      --2012년까지 근속월    
                   C1_STA_YMD_2013         = @d_c1_sta_ymd_2013,      --2013년부터 시작일    
                   C1_END_YMD_2013         = @d_c1_end_ymd_2013,      --2013년부터 종료일    
                   C1_WORK_MM_2013         = @n_c1_work_mm_2013,      --2013년부터 근속월    
                   R03_2012                = @n_r03_2012,             --2012년까지 과세표준    
                   R03_2013                = @n_r03_2013,             --2013년부터 과세표준    
                   REP_ANNUITY_BIZ_NM      = @v_biz_nm,   --퇴직연금사업자명    
                   REP_ANNUITY_BIZ_NO      = @v_biz_no,   --퇴직연금사업장등록번호    
                   REP_ACCOUNT_NO          = @v_account_no,        --퇴직연금계좌번호    
                   -- 2013.05.10  KSY 수정종료    
                   --  2013.08.28  시작    
                   MID_STA_YMD             = @d_mid_sta_ymd,            --중간지급 기산일    
                   MID_END_YMD             = @d_mid_end_ymd,            --중간지급 퇴직일    
                   MID_PAY_YMD             = @d_mid_pay_ymd,            --중간지급 지급일    
                   MID_WORK_MM             = @n_mid_work_mm,            --중간지급 근속월    
                   MID_EXCEPT_MM           = @n_mid_except_mm,            --중간지급 제외월    
                   MID_ADD_MM              = @n_mid_add_mm,      --중간지급  가산월    
                   MID_WORK_YY             = @n_mid_work_yy,            --중간지급 근속년수    
                   SUM_STA_YMD             = @d_sum_sta_ymd,            --정산 기산일    
                   SUM_END_YMD             = @d_sum_end_ymd,            --정산  퇴직일    
                   SUM_WORK_MM             = @n_sum_work_mm,            --정산 근속월    
                   SUM_EXCEPT_MM           = @n_sum_except_mm,            --정산  제외월    
                   SUM_ADD_MM              = @n_sum_add_mm,              --정산  가산월    
                   DUP_MM                  = @n_dup_mm,                  --정산 중복월    
                   C1_EXCEPT_MM            = @n_c1_except_mm,             --최종분제외월수    
                   EXCEPT_MM_2012          = @n_except_mm_2012,            --2012년까지 제외월수(계산)    
                   EXCEPT_MM_2013          = @n_except_mm_2013,            --2013년부터 제외월수(계산)    
                   ADD_MM_2012             = @n_add_mm_2012,            --2012년까지 가산월수(계산)    
                   ADD_MM_2013             = @n_add_mm_2013 ,           --2013년부터  가산월수(계산)    
                   C1_ADD_MM               = @n_c1_add_mm,             --최종분 가산월수    
                   C1_WORK_YY              = @n_c1_work_yy ,           --최종 근속년수    
                   RETIRE_MID_AMT          =  @n_retire_mid_amt                          ,  -- 중간정산퇴직금    
                   NON_RETIRE_MID_AMT      =  @n_non_retire_mid_amt                      ,  -- 비과세중간정산퇴직금    
                   RETIRE_MID_INCOME_AMT   =  @n_retire_mid_income_amt                           -- 중간정산퇴직소득세    
                   --  2013.08.28 끝    
    
                   -- 2016년 귀속 과세형평 개정안 시작    
                  , R04_N_12     = @n_rep_calc_R04_N_12    -- 환산급여(2016년 개정)    
                  , R04_DEDUCT   = @n_rep_calc_R04_DEDUCT  -- 환산급여별공제(2016년 개정)    
                  , R04_12       = @n_rep_calc_R04_12      -- 퇴직소득과세표준(2016년 개정)    
                  , R05_12       = @n_rep_calc_R05_12      -- 환산산출세액(2016년 개정)    
                  , R06_N        = @n_rep_calc_R06_N       -- 산출세액(2016년 개정)    
                    -- 2016년 귀속 과세형평 개정안 종료    
            WHERE REP_CALC_LIST_ID         = @n_rep_calc_id    
    
            SELECT @ERRCODE = @@ERROR    
                  IF @ERRCODE != 0    
                      BEGIN    
                          SET @av_ret_code      = 'FAILURE!'    
                          SET @av_ret_message   = '퇴직금 계산대상자(내역) 업데이트시 에러발생. [ERR]' + ' ['+convert(nvarchar(10),@errcode)+'] '    
                          --ROLLBACK TRAN    
                          RETURN    
                      END    
    
          END    
    
   END    
--PRINT('<<====  P_REP_CAL_TAX  END')    
    -- ***********************************************************    
    -- 작업 완료    
    -- ***********************************************************    
    IF @av_ret_code = 'SUCCESS!'    
        SET @av_ret_message = '프로시져 실행 완료..'    
    
END
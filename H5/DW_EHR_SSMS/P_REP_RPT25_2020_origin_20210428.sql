USE [dwehrdev_H5]
GO

/****** Object:  StoredProcedure [dbo].[P_REP_RPT25_2020]    Script Date: 2021-04-28 오전 10:17:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/**********************************************************************************************************************************
기존의 퇴직소득지급조서생성화면에서 실행버튼 클릭시 연결된 프로시저 [P_REP_RPT25_2016]을 [P_REP_RPT25_2020]으로 연결변경하여 사용해주세요.
**********************************************************************************************************************************/
CREATE PROCEDURE [dbo].[P_REP_RPT25_2020]
(@av_company_cd varchar(10), @av_biz_cd varchar(10), @av_sub_biz_cd varchar(10), @av_adjust_yy varchar(4), @av_release_ymd varchar(8), @av_object_term varchar(10), @an_work_emp_id numeric(27, 0), @av_ret_code varchar(4000) OUTPUT, @av_ret_message varchar(4000) OUTPUT, @av_file_nm varchar(4000) OUTPUT)
WITH 
EXECUTE AS CALLER
AS
BEGIN      -- START BEGIN
    --- ***************************************************************************
    ---   TITLE       : 퇴직소득지급조서 전산매체 생성
    ---   PROJECT     : 신인사정보시스템
    ---   AUTHOR      : 화이트정보통신
    ---   PROGRAM_ID  : P_REP_RPT25_2016
    ---   ARGUMENT    : 기준일자, 제출일자
    ---   RETURN      : SUCCESS!/FAILURE!
    ---                 결과 메시지
    ---   COMMENT     : 국세청 신고파일(퇴직금) 전산매체 생성
    ---   HISTORY     : 작성 2016-11-16 작성
    --- ***************************************************************************
     /*
      *    기본적으로 사용되는 변수
      */
         
    DECLARE
    @v_program_id varchar(30), 
    @v_program_nm varchar(100)
    DECLARE @ERRCODE          VARCHAR(10) 
    -- 기타변수
    DECLARE @sBiz_cd                    VARCHAR(10) SET @sBiz_cd = @av_biz_cd
    DECLARE @sEmp_id          VARCHAR(10)
    DECLARE @d_tax_ymd          DATETIME
    DECLARE @sText_C          VARCHAR(2000)
    DECLARE @sText_D          VARCHAR(2000)
    DECLARE @nLoop            NUMERIC(5) SET @nLoop = 1
    DECLARE @nLoop_B          NUMERIC(5) SET @nLoop_B = 0
    DECLARE @nLoop_C          NUMERIC(5) SET @nLoop_C = 0
    DECLARE @nLoop_D          NUMERIC(5) SET @nLoop_D = 0   
    DECLARE @nRecord          VARCHAR(2)
    
        DECLARE @p_biz_cd         VARCHAR(10)
    DECLARE @p_tax_office_cd      VARCHAR(3)
    DECLARE @p_home_tax_id          VARCHAR(20)
    DECLARE @p_tax_no         VARCHAR(20)
    DECLARE @p_ctz_no         VARCHAR(15)
    DECLARE @p_corp_nm            VARCHAR(50)
    DECLARE @p_int_org_nm         VARCHAR(50)
    DECLARE @p_int_charge_nm        VARCHAR(50)
    DECLARE @p_int_charge_tel_no      VARCHAR(20)
    DECLARE @p_corp_no            VARCHAR(20)
    DECLARE @p_ceo_nm         VARCHAR(50)
    DECLARE @p_biz_nm         VARCHAR(50)
    DECLARE @t_biz$orm_biz_id               NUMERIC(27,0),  
        @t_biz$COMPANY_CD             VARCHAR(6), 
        @t_biz$BIZ_CD               VARCHAR(10), 
        @t_biz$BIZ_NM               VARCHAR(50), 
        @t_biz$TAX_NO               VARCHAR(20), 
        @t_biz$CORP_NO                VARCHAR(20), 
        @t_biz$CORP_NM                VARCHAR(50), 
        @t_biz$CORP_ENG_NM              VARCHAR(100), 
        @t_biz$CEO_NM               VARCHAR(20), 
        @t_biz$CEO_ENG_NM             VARCHAR(20), 
        @t_biz$CEO_CTZ_NO             VARCHAR(13), 
        @t_biz$TEL_NO               VARCHAR(20), 
        @t_biz$FAX_NO               VARCHAR(20), 
        @t_biz$ZIP_NO               CHAR(6), 
        @t_biz$ADDR1                VARCHAR(100), 
        @t_biz$ADDR2                VARCHAR(100), 
        @t_biz$ENG_ADDR               VARCHAR(200), 
        @t_biz$TAX_OFFICE_CD            VARCHAR(3), 
        @t_biz$HOME_TAX_ID              VARCHAR(20), 
        @t_biz$INT_ORG_NM             VARCHAR(50), 
        @t_biz$INT_CHARGE_NM            VARCHAR(50),          
        @t_biz$INT_CHARGE_TEL_NO          VARCHAR(20), 
        @t_biz$EMI_BIZ_MNG_NO           VARCHAR(11), 
        @t_biz$STP_BIZ_MNG_NO           VARCHAR(11), 
        @t_biz$STP_CHARGE_NM            VARCHAR(50), 
        @t_biz$STP_CHARGE_TEL_NO          VARCHAR(20), 
        @t_biz$STP_CHARGE_HAND_PHONE_NO       VARCHAR(20), 
        @t_biz$NHS_BIZ_MNG_NO           VARCHAR(11), 
        @t_biz$NHS_UNIT_BIZ_MARK          VARCHAR(3), 
        @t_biz$NHS_CHARGE_NM            VARCHAR(50), 
        @t_biz$NHS_CHARGE_TEL_NO          VARCHAR(20), 
        @t_biz$NHS_CHARGE_HAND_PHONE_NO       VARCHAR(20), 
        @t_biz$STA_YMD                DATETIME, 
        @t_biz$END_YMD                DATETIME, 
        @t_biz$MOD_USER_ID              NUMERIC(27,0), 
        @t_biz$MOD_DATE               DATETIME
  
      /* 기본변수 초기값 셋팅*/
    SET @v_program_id    = 'EHR.REP_REPORT_FILE'       -- 현재 프로시져의 영문명
    SET @v_program_nm    = '퇴직 전산매체 생성'        -- 현재 프로시져의 한글문명
    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = dbo.F_FRM_ERRMSG_C('프로시져 실행 시작..', @v_program_id,  0000,  null,  NULL)
      
      SET @nRecord = '25';
      -- ************************************************************************
    -- 기존 자료 삭제
    -- ************************************************************************  
    BEGIN 
    DELETE FROM REP_REPORT_FILE
                   
    SELECT @ERRCODE = @@ERROR
        IF @ERRCODE != 0 
          BEGIN 
            SET @av_ret_code      = 'FAILURE!' 
            SET @av_ret_message   = '삭제작업 - 퇴직 전산매체 파일 삭제시 에러발생.' + ' ['+convert(nvarchar(10),@errcode)+'] '
            --ROLLBACK TRAN
            RETURN 
            END 
    END 
     /*==================*/
     /*  제출 사업장 코드가 있을 경우 값을 셋팅    */
     /*==================*/
     IF @av_sub_biz_cd IS NOT NULL
      BEGIN
        SET @sBiz_cd =  @av_sub_biz_cd
      END
        BEGIN
        SELECT --@t_biz$orm_biz_id          = orm_biz_id              
             @t_biz$COMPANY_CD        = COMPANY_CD                
           , @t_biz$BIZ_CD          = BIZ_CD                    
           , @t_biz$BIZ_NM          = BIZ_NM                    
           , @t_biz$TAX_NO          = TAX_NO                    
           , @t_biz$CORP_NO         = CORP_NO                   
           , @t_biz$CORP_NM         = CORP_NM                   
           --, @t_biz$CORP_ENG_NM       = CORP_ENG_NM               
           , @t_biz$CEO_NM          = CEO_NM                    
           --, @t_biz$CEO_ENG_NM        = CEO_ENG_NM                
           --, @t_biz$CEO_CTZ_NO        = CEO_CTZ_NO                
           --, @t_biz$TEL_NO          = TEL_NO                    
           --, @t_biz$FAX_NO          = FAX_NO                    
           --, @t_biz$ZIP_NO          = ZIP_NO                    
           --, @t_biz$ADDR1           = ADDR1                     
           --, @t_biz$ADDR2           = ADDR2                     
           --, @t_biz$ENG_ADDR          = ENG_ADDR                  
           , @t_biz$TAX_OFFICE_CD       = TAX_OFFICE_CD             
           , @t_biz$HOME_TAX_ID       = HOME_TAX_ID               
           , @t_biz$INT_ORG_NM        = INT_ORG_NM                
           , @t_biz$INT_CHARGE_NM       = INT_CHARGE_NM             
           , @t_biz$INT_CHARGE_TEL_NO     = INT_CHARGE_TEL_NO         
           --, @t_biz$EMI_BIZ_MNG_NO      = EMI_BIZ_MNG_NO            
           --, @t_biz$STP_BIZ_MNG_NO      = STP_BIZ_MNG_NO            
           --, @t_biz$STP_CHARGE_NM       = STP_CHARGE_NM             
           --, @t_biz$STP_CHARGE_TEL_NO     = STP_CHARGE_TEL_NO         
           --, @t_biz$STP_CHARGE_HAND_PHONE_NO  = STP_CHARGE_HAND_PHONE_NO  
           --, @t_biz$NHS_BIZ_MNG_NO      = NHS_BIZ_MNG_NO            
           --, @t_biz$NHS_UNIT_BIZ_MARK     = NHS_UNIT_BIZ_MARK         
           --, @t_biz$NHS_CHARGE_NM       = NHS_CHARGE_NM             
           --, @t_biz$NHS_CHARGE_TEL_NO     = NHS_CHARGE_TEL_NO         
           --, @t_biz$NHS_CHARGE_HAND_PHONE_NO  = NHS_CHARGE_HAND_PHONE_NO  
           , @t_biz$STA_YMD         = STA_YMD                   
           , @t_biz$END_YMD         = END_YMD                   
           , @t_biz$MOD_USER_ID       = MOD_USER_ID               
           , @t_biz$MOD_DATE          = MOD_DATE                
          FROM V_ORM_BIZ
         WHERE BIZ_CD = @sBiz_cd
           and dbo.XF_TO_DATE(@av_adjust_yy +'1231', 'yyyymmdd') BETWEEN STA_YMD AND END_YMD
           AND COMPANY_CD = @av_company_cd
           ;
        END
      
      
      SET @av_file_nm = dbo.XF_REPLACE(@t_biz$tax_no, '-', '')
      SET @av_file_nm = 'EA' + dbo.XF_SUBSTR(@av_file_nm, 1, 7) + '.' + dbo.XF_SUBSTR(@av_file_nm, 8, 3)
  
    /***************************************************************/
    /* B 레코드                                                    */
    /* 사업장별로 작성 --> WORK_BIZ_CD 를 PARAMETER 로 받아서 처리 */
    /***************************************************************/
      
    
      DECLARE cur_B CURSOR FOR 
                SELECT BIZ_CD 
               , TAX_OFFICE_CD 
           , HOME_TAX_ID
           , TAX_NO
           , CORP_NM
           , INT_ORG_NM
           , INT_CHARGE_NM 
           , INT_CHARGE_TEL_NO
           , CORP_NO 
           , CEO_NM 
           , BIZ_NM
                  FROM V_ORM_BIZ
                 WHERE dbo.XF_TO_DATE(@av_adjust_yy +'1231', 'yyyymmdd') BETWEEN sta_ymd AND end_ymd
                   AND COMPANY_CD = @av_company_cd
                   AND (@av_biz_cd IS NULL OR BIZ_CD = @av_biz_cd )
                   AND BIZ_CD IN (SELECT distinct BIZ_CD
                                    FROM V_REP_CALC_LIST_RPT_2014
                                   WHERE dbo.XF_TO_CHAR_D(TAX_YMD,'YYYY') = @av_adjust_yy )
    BEGIN -- B레코드 시작.
      OPEN cur_B -- 커서열기
      FETCH NEXT FROM cur_B -- 커서에서 데이타 가져오기
          INTO @p_biz_cd 
             , @p_tax_office_cd 
           , @p_home_tax_id
           , @p_tax_no
           , @p_corp_nm
           , @p_int_org_nm
           , @p_int_charge_nm
           , @p_int_charge_tel_no
           , @p_corp_no
           , @p_ceo_nm
           , @p_biz_nm
      
        WHILE @@FETCH_STATUS = 0 -- 데이타 가져오기 성공(0), -1은 실패, -2는 반입된 행이 없다.   
        BEGIN -- cur_B BEGIN
          
        SET @nLoop  = @nLoop+ 1
        SET @nLoop_B = @nLoop_B + 1
          BEGIN -- B : INSERT BEGIN
            INSERT INTO REP_REPORT_FILE
                SELECT @av_adjust_yy, 'B', @nLoop, 0, NULL,  
                     'B'+                                                 -- 1. 레코드구분                X(1)
                     @nRecord+                                              -- 2. 자료구분                  9(2)
                     TAX_OFFICE_CD+                                           -- 3. 세무서                    X(3)
                     dbo.XF_LPAD(@nLoop_B,6,'0')+                                     -- 4. 일련번호                  9(6)
                     dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(TAX_NO,' '),'-',''),10, ' ')+                -- 5. 사업자등록번호            X(10)
                     dbo.XF_RPAD(dbo.XF_NVL_C(COM_NM,' '),40,' ')+                            -- 6. 법인명(상호)              X(40)
                     dbo.XF_RPAD(dbo.XF_NVL_C(OWNER_NM,' '),30,' ')+                            -- 7. 대표자성명                X(30)
                     dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(COM_NO, ' '),'-',''),13,' ')+                -- 8. 법인번호                  X(13)
                     dbo.XF_NVL_C(@av_object_term, '1')+                                  -- 9. 제출대상기간코드          9(1)
                     dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(SUM(dbo.XF_NVL_N(c_rec_cnt,0)),NULL)),7,'0')+       -- 10.퇴직소득자수(c 레코드수)  9(7)
                     dbo.XF_RPAD(' ',7, ' ')+                                       -- 11.공란                      X(7)
                     dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(SUM(dbo.XF_NVL_N(R01,0)),NULL)),14,'0')+          -- 12.정산-과세대상퇴직급여합계 9(14)
                     CHK_CT01+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(SUM(dbo.XF_NVL_N(CT01,0))),NULL)),13,'0')+   -- 13.신고대상소득세합계(부호+절대값) 9(1) + 9(13)
                     dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(SUM(dbo.XF_NVL_N(TRANS_INCOME_AMT,0)),NULL)),13,'0')+   -- 14.이연퇴직소득세액합계      9(13)
                     CHK_T01+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(SUM(dbo.XF_NVL_N(T01,0))),NULL)),13,'0')+   -- 15.차감원천징수 소득세액 합계(부호+절대값) 9(1) + 9(13)
                     CHK_T02+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(SUM(dbo.XF_NVL_N(T02,0))),NULL)),13,'0')+   -- 16.차감원천징수 지방소득세액 합계(부호+절대값) 9(1) + 9(13)
                     CHK_T03+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(SUM(dbo.XF_NVL_N(T03,0))),NULL)),13,'0')+   -- 17.차감원천징수 농어촌특별세액 합계(부호+절대값) 9(1) + 9(13)
                     CHK_TSUM+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(SUM(dbo.XF_NVL_N(T_SUM,0))),NULL)),13,'0')+  -- 18.차감원천징수 계 합계(부호+절대값) 9(1) + 9(13)
                     dbo.XF_RPAD(' ',544, ' ') TEXT,                                    -- 19.공란                      X(893)    2016변경 X(873) → X(893) 2020년변경 X(893) - X(544)
                     @an_work_emp_id
                  FROM (SELECT @p_tax_no TAX_NO,
                         @p_corp_nm COM_NM,
                         @p_ceo_nm OWNER_NM,
                         @p_corp_no COM_NO,
                         @p_tax_office_cd TAX_OFFICE_CD,
                         1 c_rec_cnt,
                         A.R01,
                         CASE WHEN A.CT01 < 0 THEN '1' ELSE '0' END CHK_CT01,
                         A.CT01,
                         A.TRANS_INCOME_AMT,
                         CASE WHEN A.T01 < 0 THEN '1' ELSE '0' END CHK_T01,
                         CASE WHEN A.T02 < 0 THEN '1' ELSE '0' END CHK_T02,
                         CASE WHEN A.T03 < 0 THEN '1' ELSE '0' END CHK_T03,
                         CASE WHEN A.T_SUM < 0 THEN '1' ELSE '0' END CHK_TSUM,
                         A.T01,
                         A.T02,
                         A.T03,
                         A.T_SUM
                      FROM  V_REP_CALC_LIST_RPT_2014 A
                      WHERE A.COMPANY_CD = @av_company_cd
                       AND dbo.XF_TO_CHAR_D(A.TAX_YMD,'YYYY') = @av_adjust_yy
                       AND A.BIZ_CD = @p_biz_cd
                   ) BB
                GROUP BY TAX_NO, COM_NM, OWNER_NM, COM_NO, TAX_OFFICE_CD, CHK_CT01, CHK_T01, CHK_T02, CHK_T03, CHK_TSUM
                
              SELECT @ERRCODE = @@ERROR
                  IF @ERRCODE != 0 
                    BEGIN --
                      SET @av_ret_code      = 'FAILURE!' 
                      SET @av_ret_message   = 'RP_REPORT_FILE INSERT Error [B] ' + ' ['+convert(nvarchar(10),@errcode)+'] '
                      --ROLLBACK TRAN
                      RETURN 
                    END --
      
            END -- B : INSERT END
        
    /***************************************************************/
    /* C 레코드                                                    */
    /***************************************************************/
    BEGIN -- C레코드【퇴직소득자 레코드】
       SET @nLoop_C = 0
          
      DECLARE cur_C CURSOR  FOR
         SELECT A.EMP_ID,
            A.TAX_YMD,
            dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(A.CTZ_NO, ' '),'-',''),13,' ') AS CTZ_NO,
            -- 【원천징수의무자】
            dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(@p_tax_no,' '),'-',''),10, ' ')+                            --  5. 사업자등록번호                        X(10)
            -- 【소득자】
            '1'+                                                              --  6. 징수의무자구분                        9(1)
            dbo.XF_NVL_C(A.RESIDENT_CD, '1')+                                               --  7. 거주자구분코드                        9(1)
            dbo.XF_NVL_C(A.FOREIGN_CD, '1')+                                                --  8. 내/외국인구분코드                     9(1)
            dbo.XF_NVL_C(A.RELIGIOUS_YN, '2')+                                                          --  9. 종교관련종사자여부                    9(1)   2020추가
            dbo.XF_RPAD(dbo.XF_NVL_C(A.NATION_CD, ' '), 2, ' ')+                                      -- 10. 거주지국코드                          X(2)
            dbo.XF_RPAD(A.EMP_NM, 30, ' ')+                                                 -- 11. 성명                                  X(30)
            dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(A.CTZ_NO, ' '),'-',''),13,' ')+                             -- 12. 주민등록번호                          X(13)
            dbo.XF_NVL_C(A.OFFICERS_YN, '2')+                                               -- 13. 임원여부                              9(1)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.PENSION_YMD,'YYYYMMDD'),0), 8, '0')+                        -- 14. 확정급여형 퇴직연금제도 가입일        9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.PENSION_AMT,0),NULL)), 11, '0')+                    -- 15. 2011.12.31 퇴직금                     9(11)
            CASE WHEN dbo.XF_TO_CHAR_D(A.C1_STA_YMD, 'YYYYMMDD') > dbo.XF_TO_CHAR_D(@av_adjust_yy +'0101', 'YYYYMMDD') THEN dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_STA_YMD,'YYYYMMDD'),0), 8, '0')
            ELSE dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(dbo.XF_TO_DATE(@av_adjust_yy +'0101', 'yyyymmdd'),'YYYYMMDD'),'0'), 8, '0') END+ -- 16. 귀속년도 시작연월일                   9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_END_YMD,'YYYYMMDD'),'0'), 8, '0')+                       -- 17. 귀속년도 종료연월일                   9(8)
            dbo.XF_NVL_C(dbo.XF_SUBSTR(A.RETIRE_TYPE_CD,2,1), '6')+                                     -- 18. 퇴직사유                              9(1)
            -- 【퇴직급여현황 - 중간지급등】
            -- 현 근무처의 퇴직 전 중간지급, 퇴직금의 분할지급 또는 퇴직으로 해당연도에 이미 발생한 퇴직금이 있는 경우 이거나,
            -- 해당연도에 발생한 종(전)근무지의 퇴직금이 있는 경우 작성
            dbo.XF_RPAD(dbo.XF_NVL_C(A.B1_CORP_NM, ' '), 40, ' ')+                                      -- 19. 근무처명                              X(40)
            dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(A.B1_TAX_NO,' '),'-',''),10, ' ')+                                                      -- 20. 사업자등록번호                        X(10)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_MID_AMT,0),NULL)), 11, '0')+                   -- 21. 퇴직급여                              9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.NON_RETIRE_MID_AMT,0),NULL)), 11, '0')+                 -- 22. 비과세 퇴직급여                       9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_MID_SUM,0),NULL)), 11, '0')+                   -- 23. 과세대상 퇴직급여                     9(11)
            -- 【퇴직급여현황 - 최종분】
            dbo.XF_RPAD(dbo.XF_NVL_C(@p_corp_nm, ' '), 40, ' ')+                                      -- 24. 근무처명                              X(40)
            dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(@p_tax_no,' '),'-',''),10, ' ')+                            -- 25. 사업자등록번호                        X(10)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C_SUM,0),NULL)), 11, '0')+                        -- 26. 퇴직급여                              9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.NON_RETIRE_AMT,0),NULL)), 11, '0')+                   -- 27. 비과세 퇴직급여                       9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_C_SUM,0),NULL)), 11, '0')+                   -- 28. 과세대상 퇴직급여                     9(11)
            -- 【퇴직급여현황 - 정산】
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_MID_AMT,0) + dbo.XF_NVL_N(A.C_SUM,0),NULL)), 11, '0')+     -- 29. 퇴직급여                              9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.NON_RETIRE_MID_AMT,0) + dbo.XF_NVL_N(NON_RETIRE_AMT,0),NULL)), 11, '0')+-- 30. 비과세 퇴직급여                       9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R01,0),NULL)), 11, '0')+                        -- 31. 과세대상 퇴직급여                     9(11)
            -- 【근속연수-중산지급 등】
            -- 현 근무처의 퇴직 전 중간지급, 퇴직금의 분할지급 또는 퇴직으로 해당연도에 이미 발생한 퇴직금이 있는 경우 이거나,
            -- 해당연도에 발생한 종(전)근무지의 퇴직금이 있는 경우 작성
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.B1_STA_YMD,'YYYYMMDD'),'0'), 8, '0')+                                               -- 32. 입사일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.MID_STA_YMD,'YYYYMMDD'),'0'), 8, '0')+                                              -- 33. 기산일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.MID_END_YMD,'YYYYMMDD'),'0'), 8, '0')+                                              -- 34. 퇴사일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.MID_PAY_YMD,'YYYYMMDD'),'0'), 8, '0')+                                              -- 35. 지급일                                 9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.MID_WORK_MM,0),NULL)),   4, '0')+                   -- 36. 근속월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.MID_EXCEPT_MM,0),NULL)),   4, '0')+                   -- 37. 제외월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.MID_ADD_MM,0),NULL)),   4, '0')+                    -- 38. 가산월수                               9(4)
            '0000'+                                                             -- 39. 중복월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.MID_WORK_YY,0),NULL)),   4, '0')+                   -- 40. 근속연수                               9(4)
            -- 【근속연수-최종】
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.HIRE_YMD,'YYYYMMDD'),'0'), 8, '0')+                                                 -- 41. 입사일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_STA_YMD,'YYYYMMDD'),'0'), 8, '0')+                                               -- 42. 기산일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_END_YMD,'YYYYMMDD'),'0'), 8, '0')+                                               -- 43. 퇴사일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.PAY_YMD,'YYYYMMDD'),'0'), 8, '0')+                                                  -- 44. 지급일                                 9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_MM,0),NULL)),   4, '0')+                    -- 45. 근속월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_EXCEPT_MM,0),NULL)),   4, '0')+                    -- 46. 제외월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_ADD_MM,0),NULL)),   4, '0')+                     -- 47. 가산월수                               9(4)
            '0000'+                                                             -- 48. 중복월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_YY,0),NULL)),   4, '0')+                    -- 49. 근속연수                               9(4)
            -- 【근속연수-정산】
            '00000000'+                                                           -- 50. 입사일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.SUM_STA_YMD,'YYYYMMDD'),'0'), 8, '0')+                                              -- 51. 기산일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.SUM_END_YMD,'YYYYMMDD'),'0'), 8, '0')+                                              -- 52. 퇴사일                                 9(8)
            '00000000'+                                                           -- 53. 지급일                                 9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.SUM_WORK_MM,0),NULL)),   4, '0')+                   -- 54. 근속월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.SUM_EXCEPT_MM,0),NULL)),   4, '0')+                   -- 55. 제외월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.SUM_ADD_MM,0),NULL)),   4, '0')+                    -- 56. 가산월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.DUP_MM,0),NULL)),   4, '0')+                      -- 57. 중복월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.BC1_WORK_YY,0),NULL)),   4, '0')+                   -- 58. 근속연수                               9(4)
/*2020년삭제
            -- 【근속연수-안분-2012.12.31이전】
            -- 정산분 근무기간에 2012.12.31이전분이 있는 경우에만 작성
            '00000000'+                                                           -- 58. 입사일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_STA_YMD_2012,'YYYYMMDD'),'0'), 8, '0')+                                          -- 59. 기산일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_END_YMD_2012,'YYYYMMDD'),'0'), 8, '0')+                                          -- 60. 퇴사일                                 9(8)
            '00000000'+                                                           -- 61. 지급일                                 9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_MM_2012,0),NULL)),   4, '0')+                 -- 62. 근속월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.EXCEPT_MM_2012,0),NULL)),   4, '0')+                  -- 63. 제외월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.ADD_MM_2012,0),NULL)),   4, '0')+                   -- 64. 가산월수                               9(4)
            '0000'+                                                             -- 65. 중복월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_YY_2012,0),NULL)),   4, '0')+                 -- 66. 근속연수                               9(4)               
            -- 【근속연수-안분-2013.1.1이후】
            -- 정산분 근무기간에 2013.1.1이후분이 있는 경우에만 작성
            '00000000'+                                                           -- 67. 입사일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_STA_YMD_2013,'YYYYMMDD'),'0'), 8, '0')+                                          -- 68. 기산일                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_END_YMD_2013,'YYYYMMDD'),'0'), 8, '0')+                                          -- 69. 퇴사일                                 9(8)
            '00000000'+                                                           -- 70. 지급일                                 9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_MM_2013,0),NULL)),   4, '0')+                 -- 71. 근속월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.EXCEPT_MM_2013,0),NULL)),   4, '0')+                  -- 72. 제외월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.ADD_MM_2013,0),NULL)),   4, '0')+                   -- 73. 가산월수                               9(4)
            '0000'+                                                             -- 74. 중복월수                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_YY_2013,0),NULL)),   4, '0')+                 -- 75. 근속연수                               9(4)
*/
            -- 【개정규정에 따른 계산 방법 - 과세표준계산】 -- 2016년 귀속 추가부분
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R01,0),NULL)), 11, '0')+                        -- 59. 퇴직소득                               9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R02_02,0),NULL)), 11, '0')+                     -- 60. 근속연수공제                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_N_12,0),NULL)), 11, '0')+                     -- 61. 환산급여                               9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_DEDUCT,0),NULL)), 11, '0')+                     -- 62. 환산급여별공제                         9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_12,0),NULL)), 11, '0')+                       -- 63. 퇴직소득과세표준                       9(11)
               
            -- 【개정 규정에 따른 계산 방법 - 세액계산】 -- 2016년귀속 추가부분
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_12,0),NULL)), 11, '0')+                       -- 64. 환산산출세액                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R06_N,0),NULL)), 11, '0')+                        -- 65. 퇴직소득 산출세액                      9(11)   2020년 title변경
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TAX_DED,0),NULL)), 11, '0')+                      -- 66. 세액공제                               9(11)   2020년추가
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_MID_INCOME_AMT,0),NULL)) , 11, '0')+               -- 67. 기납부(또는 기과세이연) 세액          9(11)
            CASE WHEN A.R08_S < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R08_S,0),NULL)) , 11, '0')+ -- 68. 신고대상세액(부호 + 절대값)           9(11)
/* 2020년삭제
            -- 【종전규정에 따른 계산 방법 - 과세표준계산】 -- 2016년귀속 변경
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R01,0),NULL)), 11, '0')+                        -- 83. 퇴직소득                               9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R02_01,0),NULL)), 11, '0')+                       -- 84. 퇴직소득정률공제                       9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R02_02,0),NULL)), 11, '0')+                       -- 85. 근속연수공제                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R03,0),NULL)), 11, '0')+                        -- 86. 퇴직소득과세표준                       9(11)
               
            --【종전 규정에 따른 계산 방법 - 세액계산 - 2012.12.31이전】 -- 2016년귀속 변경
            -- 정산분 근무기간에 2012.12.31이전분이 있는 경우에만 작성
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R03_2012,0),NULL)), 11, '0')+                     -- 87. 과세표준안분                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_2012,0),NULL)), 11, '0')+                     -- 88. 연평균과세표준                         9(11)
            '00000000000'+                                                          -- 89. 환산과세표준                           9(11)
            '00000000000'+                                                          -- 90. 환산산출세액                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_2012,0),NULL)), 11, '0')+                     -- 91. 연평균산출세액                         9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R06_2012,0),NULL)), 11, '0')+                     -- 92. 산출세액                               9(11)
            -- 【종전 규정에 따른 계산 방법 - 세액계산 - 2013.1.1이후】 -- 2016년귀속 변경
            -- 정산분 근무기간에 2013.1.1이후분이 있는 경우에만 작성
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R03_2013,0),NULL)), 11, '0')+                     -- 93. 과세표준안분                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_2013,0),NULL)), 11, '0')+                     -- 94. 연평균과세표준                         9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_2013_5,0),NULL)), 11, '0')+                     -- 95. 환산과세표준                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_2013,0),NULL)), 11, '0')+                     -- 96. 환산산출세액                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_2013_5,0),NULL)), 11, '0')+                     -- 97. 연평균산출세액                         9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R06_2013,0),NULL)), 11, '0')+                     -- 98. 산출세액                               9(11)
         
            -- 【종전 규정에 따른 계산 방법 - 세액계산 - 합계】 -- 2016년귀속 변경
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R03_S,0),NULL)), 11, '0')+                        -- 99. 과세표준안분                           9(11)
            --dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_2012,0) + dbo.XF_NVL_N(A.R04_2013,0),NULL)), 11, '0')+        -- 100. 연평균과세표준                        9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_TRUNC_N(dbo.XF_NVL_N(A.R03_S,0) / dbo.XF_NVL_N(A.BC1_WORK_YY,0), 0) ,NULL)), 11, '0') + -- 100. 연평균과세표준                9(11) 2017.02.14 수정
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_2013_5,0),NULL)), 11, '0')+                     -- 101. 환산과세표준                          9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_2013,0),NULL)), 11, '0')+                     -- 102. 환산산출세액                          9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_2012,0) + dbo.XF_NVL_N(A.R05_2013_5,0),NULL)), 11, '0')+      -- 103. 연평균산출세액                        9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R06_2012,0) + dbo.XF_NVL_N(A.R06_2013,0),NULL)) , 11, '0')+       -- 104. 산출세액                              9(11)
               
            -- 【퇴직소득세액계산】 -- 2016년귀속 변경
            dbo.XF_TO_CHAR_D(C1_END_YMD, 'YYYY')+                                             -- 105. 퇴직일이 속하는 과세연도              9(4)         -- 2016년 귀속 추가부분    
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R06,0),NULL)) , 11, '0')+                       -- 106. 퇴직소득세산출세액                    9(11)        -- 2016년 귀속 추가부분 
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_MID_INCOME_AMT,0),NULL)) , 11, '0')+               -- 107. 기납부(또는 기과세이연) 세액          9(11)
            CASE WHEN A.R08_S < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R08_S,0),NULL)) , 11, '0')+-- 108. 신고대상세액(부호 + 절대값)           9(11)
*/
            -- 【이연퇴직소득세액계산】 -- 2016년귀속 변경
            -- 「소득세법」 제146조제2항에 따라 퇴직급여액을 연금계좌에 입금(이체)하여 퇴직소득세 징수를 하지 아니한 경우 작성(거주자인 경우만 작성가능)
            CASE WHEN (CASE WHEN TRANS_IN_AMT =0 THEN 0  ELSE A.R08_S END) < 0 THEN '1' ELSE '0' END+                   -- 109. 신고대상세액(부호)                    9(1)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(CASE WHEN TRANS_IN_AMT =0 THEN 0  ELSE A.R08_S END),NULL)), 11, '0')+        -- 69. 신고대상세액(절대값)                  9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_IN_AMT,0),NULL)), 11, '0')+                   -- 70. 계좌입금금액_합계                     9(11)
            dbo.XF_LPAD((CASE WHEN TRANS_IN_AMT =0 THEN 0 ELSE dbo.XF_NVL_N(A.RETIRE_C_SUM,0) END), 11, '0')+                               -- 71. 퇴직급여                              9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_INCOME_AMT,0),NULL)), 11, '0')+                 -- 72. 이연퇴직소득세                        9(11)
            --【납부명세-신고대상세액】
            CASE WHEN A.CT01 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.CT01,0)),NULL)), 11, '0')+                     -- 73. 소득세(부호+절대값)                   9(1) + 9(11)
            CASE WHEN A.CT02 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.CT02,0)),NULL)), 11, '0')+                     -- 74. 지방소득세(부호+절대값)               9(1) + 9(11)
            CASE WHEN A.CT03 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.CT03,0)),NULL)), 11, '0')+                     -- 75. 농어촌특별세(부호+절대값)             9(1) + 9(11)
            CASE WHEN A.CT_SUM < 0 THEN '' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.CT_SUM,0)),NULL)), 11, '0')+                    -- 76. 계(부호+절대값)                       9(1) + 9(11)
            --【납부명세-이연퇴직소득세】
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_INCOME_AMT,0),NULL)), 11, '0')+                                       -- 77. 소득세                                9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_RESIDENCE_AMT,0),NULL)), 11, '0')+                                      -- 78. 지방소득세                            9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_N_TAX_AMT,0),NULL)), 11, '0')+                                        -- 79. 농어촌특별세                          9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_INCOME_AMT,0) + dbo.XF_NVL_N(A.TRANS_RESIDENCE_AMT,0) + dbo.XF_NVL_N(A.TRANS_N_TAX_AMT,0),NULL)) , 11, '0')+  -- 80. 계                                    9(11)
            --【납부명세-신고대상세액】
            CASE WHEN A.T01 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.T01,0)),NULL)), 11, '0')+                       -- 81. 소득세(부호+절대값)                   9(1) + 9(11)
            CASE WHEN A.T02 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.T02,0)),NULL)), 11, '0')+                       -- 82. 지방소득세(부호+절대값)               9(1) + 9(11)
            CASE WHEN A.T03 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.T03,0)),NULL)), 11, '0')+                       -- 83. 농어촌특별세(부호+절대값)             9(1) + 9(11)
            CASE WHEN A.T_SUM < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.T_SUM,0)),NULL)), 11, '0')+                     -- 84. 계(부호+절대값)                       9(1) + 9(11)
            dbo.XF_LPAD(' ',2,' ')                                                                            -- 85. 공란                                 X(2)   2016변경 X(8) → X(2)
            FROM V_REP_CALC_LIST_RPT_2014 A
            WHERE A.COMPANY_CD = @av_company_cd
            AND dbo.XF_TO_CHAR_D(A.TAX_YMD,'YYYY') = @av_adjust_yy
            AND A.BIZ_CD = @p_biz_cd
  
          OPEN cur_C
          FETCH NEXT FROM cur_C -- 커서에서 데이타 가져오기
              INTO @sEmp_id, @d_tax_ymd, @p_ctz_no, @sText_C;
            
              WHILE @@FETCH_STATUS = 0 -- 데이타 가져오기 성공(0), -1은 실패, -2는 반입된 행이 없다.   
              BEGIN -- cur_c BEGIN
              SET @nLoop  = @nLoop+ 1
              SET @nLoop_C = @nLoop_C + 1
              
              BEGIN -- C INSERT BEGIN 
                  INSERT INTO REP_REPORT_FILE
                     VALUES (@av_adjust_yy, 'C', @nLoop, 0, @sEmp_id, 
                         'C'+@nRecord+@p_tax_office_cd+dbo.XF_REPLACE(dbo.XF_LPAD(@nLoop_C,6,'0'),' ','0')+@sText_C, @an_work_emp_id);   
              
                      
                  SELECT @ERRCODE = @@ERROR
                      IF @ERRCODE != 0 
                        BEGIN  --
                          SET @av_ret_code      = 'FAILURE!' 
                          SET @av_ret_message   = 'RP_REPORT_FILE INSERT Error [C] ' + ' ['+convert(nvarchar(10),@errcode)+'] '
                          --ROLLBACK TRAN
                          RETURN 
                        END --    
              
                END-- C INSERT END
                
                BEGIN
                    SET @nLoop_D = 1
                    -- 연금계좌 입금명세 (D 레코드)
                    DECLARE cur_d CURSOR FOR -- 2015.02.02 추가
              
                      SELECT  -- 【원천징수의무자】
                          dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(@p_tax_no,' '),'-',''),10, ' ')+                -- 5.사업자번호          X(10)
                          dbo.XF_RPAD(' ',50,' ')+                                        -- 6.공란           X(50)               
                          --【소득자】
                          dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(@p_ctz_no, ' '),'-',''),13,' ')+                -- 7.소득자 주민등록번호     X(13)
                          --【연금계좌 입금명세】
                          dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(@nLoop_D,NULL)),2,'0') +                   -- 8.연금계좌 일련번호      9(2)
                          dbo.XF_RPAD(dbo.XF_NVL_C(A.REP_ANNUITY_BIZ_NM, ' '), 30, ' ')+                      -- 9.연금계좌취급자        X(30)
                          dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(A.REP_ANNUITY_BIZ_NO,' '),'-',''),10, ' ')+           -- 10.연금계좌_사업자등록번호  X(10)
                          dbo.XF_RPAD(dbo.XF_NVL_C(A.REP_ACCOUNT_NO, ' '), 20, ' ')+                        -- 11.연금계좌_계좌번호     X(20)    
                          dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.REP_TRANS_YMD,'YYYYMMDD'),'00000000'), 8, '00000000')+      -- 12.연금계좌_입금일      9(8)
                          dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_ALLOWANCE_COURT_SUM,0),NULL)), 11, '0')+  -- 13.연금계좌_계좌입금금액   9(11)
                          dbo.XF_RPAD(' ',595, ' ') AS TEXT                                   -- 14. 공란                     X(944)  2016변경 X(924) → X(944)  2020변경 X(944) → X(595)
                        FROM V_REP_INCOME_TAX_RPT_2014 A 
                      WHERE A.EMP_ID = @sEmp_id
                        AND A.WORK_YMD = @d_tax_ymd
                    
                    OPEN cur_d -- 커서열기
                    FETCH NEXT FROM cur_d -- 커서에서 데이타 가져오기                                                    
                        INTO @sText_D;
                    WHILE @@FETCH_STATUS = 0 -- 데이타 가져오기 성공(0), -1은 실패, -2는 반입된 행이 없다. 
                    BEGIN -- cur_d BEGIN
                    SET @nLoop  = @nLoop+ 1
                    SET @nLoop_D = @nLoop_D + 1
                      BEGIN
                        INSERT INTO REP_REPORT_FILE
                        VALUES (@av_adjust_yy, 'D', @nLoop, 0, @sEmp_id,
                            'D'+@nRecord+@p_tax_office_cd+dbo.XF_REPLACE(dbo.XF_LPAD(@nLoop_C,6,'0'),' ','0')+@sText_D, @an_work_emp_id);    -- 2015.02.02 추가(an_work_emp_id)                         
                        SELECT @ERRCODE = @@ERROR
                          IF @ERRCODE != 0 
                            BEGIN  --
                              SET @av_ret_code      = 'FAILURE!' 
                              SET @av_ret_message   = 'RP_REPORT_FILE INSERT Error [D] ' + ' ['+convert(nvarchar(10),@errcode)+'] '
                              --ROLLBACK TRAN
                              RETURN 
                            END --    
                      END -- D INSERT END
                    FETCH NEXT FROM cur_D -- 커서에서 데이타 가져오기
                    INTO @sText_D;
                    END -- cur_D END
                CLOSE cur_d -- 2015.02.04 수정:커서닫기
                DEALLOCATE cur_d -- 2015.02.04 수정:커서 할당해제
                END -- D 레코드 끝.
              
              FETCH NEXT FROM cur_C -- 커서에서 데이타 가져오기
                    --INTO @sEmp_id, @d_tax_ymd, @sText_C;
                    INTO  @sEmp_id, @d_tax_ymd, @p_ctz_no, @sText_C; -- 2015.02.04 수정
              END -- cur_c END
              
              CLOSE cur_C -- 커서닫기
              DEALLOCATE cur_C -- 커서 할당해제
    END -- C 레코드 끝.                       
        
    FETCH NEXT FROM cur_B -- 커서에서 데이타 가져오기
          INTO @p_biz_cd ,@p_tax_office_cd ,@p_home_tax_id, @p_tax_no, @p_corp_nm, @p_int_org_nm, @p_int_charge_nm, 
                          @p_int_charge_tel_no, @p_corp_no, @p_ceo_nm, @p_biz_nm
    
    END -- cur_B END
    CLOSE cur_B -- 커서닫기
    DEALLOCATE cur_B -- 커서 할당해제
      END  -- B 레코드 끝. 
      
         /***************************************************************/
        /* A 레코드                                                    */
        /***************************************************************/
        BEGIN -- A레코드 BEGIN
          INSERT INTO REP_REPORT_FILE
            SELECT @av_adjust_yy,
                 'A',
                 1,  
                 0,  
                 NULL,
                 'A'+                               -- 1. 레코드구분                      X(1)
                 @nRecord+                            -- 2. 자료구분                        9(2)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$TAX_OFFICE_CD,' '),3, ' ')+    -- 3. 세무서코드                      X(3)
                 dbo.XF_LPAD(dbo.XF_NVL_C(@av_release_ymd,'0'),8, '0')+           -- 4. 제출년월일                      9(8)
                 '2'+                               -- 5. 제출자(대리인구분)              9(1): 2-법인
                 dbo.XF_RPAD(' ',6, ' ')+                     -- 6. 세무대리인관리번호              X(6)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$HOME_TAX_ID,' '),20, ' ')+   -- 7. 홈택스ID                        X(20)
                 '9000'+                              -- 8. 세무프로그램 코드               X(4)
                 dbo.XF_RPAD(dbo.XF_REPLACE(@t_biz$TAX_NO,'-',''),10, ' ')+       -- 9. 사업자등록번호                  X(10)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$CORP_NM,' '),40, ' ')+           -- 10.법인명(상호)                    X(40)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$INT_ORG_NM,' '),30, ' ')+        -- 11.담당자 부서                     X(30)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$INT_CHARGE_NM,' '),30, ' ')+     -- 12.담당자성명                      X(30)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$INT_CHARGE_TEL_NO,' '),15, ' ')+ -- 13.담당자전화번호                  X(15)
                 dbo.XF_LPAD(@nLoop_B,5,'0')+                   -- 14.신고의무자수                    9(5)
                 '101'+                             -- 15.사용한글코드(KSC-5601)          9(3)
                 dbo.XF_RPAD(' ',583, ' ') text,                  -- 16.공란                            X(932)  2016변경 X(912) → X(932)  2020변경 X(932) → X(583)
                 @an_work_emp_id
              FROM DUAL
            ;
            SELECT @ERRCODE = @@ERROR
                      IF @ERRCODE != 0 
                        BEGIN --
                          SET @av_ret_code      = 'FAILURE!' 
                          SET @av_ret_message   = 'RP_REPORT_FILE INSERT Error [A] ' + ' ['+convert(nvarchar(10),@errcode)+'] '
                          --ROLLBACK TRAN
                          RETURN 
                        END --      
        END -- A레코드 END
  -- ***********************************************************
    -- 작업 완료
    -- ***********************************************************
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = '프로시져 실행 완료..'
    
END -- START END
GO



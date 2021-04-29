USE [dwehrdev_H5]
GO

/****** Object:  StoredProcedure [dbo].[P_REP_RPT25_2020]    Script Date: 2021-04-28 ���� 10:17:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/**********************************************************************************************************************************
������ �����ҵ�������������ȭ�鿡�� �����ư Ŭ���� ����� ���ν��� [P_REP_RPT25_2016]�� [P_REP_RPT25_2020]���� ���ắ���Ͽ� ������ּ���.
**********************************************************************************************************************************/
CREATE PROCEDURE [dbo].[P_REP_RPT25_2020]
(@av_company_cd varchar(10), @av_biz_cd varchar(10), @av_sub_biz_cd varchar(10), @av_adjust_yy varchar(4), @av_release_ymd varchar(8), @av_object_term varchar(10), @an_work_emp_id numeric(27, 0), @av_ret_code varchar(4000) OUTPUT, @av_ret_message varchar(4000) OUTPUT, @av_file_nm varchar(4000) OUTPUT)
WITH 
EXECUTE AS CALLER
AS
BEGIN      -- START BEGIN
    --- ***************************************************************************
    ---   TITLE       : �����ҵ��������� �����ü ����
    ---   PROJECT     : ���λ������ý���
    ---   AUTHOR      : ȭ��Ʈ�������
    ---   PROGRAM_ID  : P_REP_RPT25_2016
    ---   ARGUMENT    : ��������, ��������
    ---   RETURN      : SUCCESS!/FAILURE!
    ---                 ��� �޽���
    ---   COMMENT     : ����û �Ű�����(������) �����ü ����
    ---   HISTORY     : �ۼ� 2016-11-16 �ۼ�
    --- ***************************************************************************
     /*
      *    �⺻������ ���Ǵ� ����
      */
         
    DECLARE
    @v_program_id varchar(30), 
    @v_program_nm varchar(100)
    DECLARE @ERRCODE          VARCHAR(10) 
    -- ��Ÿ����
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
  
      /* �⺻���� �ʱⰪ ����*/
    SET @v_program_id    = 'EHR.REP_REPORT_FILE'       -- ���� ���ν����� ������
    SET @v_program_nm    = '���� �����ü ����'        -- ���� ���ν����� �ѱ۹���
    SET @av_ret_code     = 'SUCCESS!'
    SET @av_ret_message  = dbo.F_FRM_ERRMSG_C('���ν��� ���� ����..', @v_program_id,  0000,  null,  NULL)
      
      SET @nRecord = '25';
      -- ************************************************************************
    -- ���� �ڷ� ����
    -- ************************************************************************  
    BEGIN 
    DELETE FROM REP_REPORT_FILE
                   
    SELECT @ERRCODE = @@ERROR
        IF @ERRCODE != 0 
          BEGIN 
            SET @av_ret_code      = 'FAILURE!' 
            SET @av_ret_message   = '�����۾� - ���� �����ü ���� ������ �����߻�.' + ' ['+convert(nvarchar(10),@errcode)+'] '
            --ROLLBACK TRAN
            RETURN 
            END 
    END 
     /*==================*/
     /*  ���� ����� �ڵ尡 ���� ��� ���� ����    */
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
    /* B ���ڵ�                                                    */
    /* ����庰�� �ۼ� --> WORK_BIZ_CD �� PARAMETER �� �޾Ƽ� ó�� */
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
    BEGIN -- B���ڵ� ����.
      OPEN cur_B -- Ŀ������
      FETCH NEXT FROM cur_B -- Ŀ������ ����Ÿ ��������
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
      
        WHILE @@FETCH_STATUS = 0 -- ����Ÿ �������� ����(0), -1�� ����, -2�� ���Ե� ���� ����.   
        BEGIN -- cur_B BEGIN
          
        SET @nLoop  = @nLoop+ 1
        SET @nLoop_B = @nLoop_B + 1
          BEGIN -- B : INSERT BEGIN
            INSERT INTO REP_REPORT_FILE
                SELECT @av_adjust_yy, 'B', @nLoop, 0, NULL,  
                     'B'+                                                 -- 1. ���ڵ屸��                X(1)
                     @nRecord+                                              -- 2. �ڷᱸ��                  9(2)
                     TAX_OFFICE_CD+                                           -- 3. ������                    X(3)
                     dbo.XF_LPAD(@nLoop_B,6,'0')+                                     -- 4. �Ϸù�ȣ                  9(6)
                     dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(TAX_NO,' '),'-',''),10, ' ')+                -- 5. ����ڵ�Ϲ�ȣ            X(10)
                     dbo.XF_RPAD(dbo.XF_NVL_C(COM_NM,' '),40,' ')+                            -- 6. ���θ�(��ȣ)              X(40)
                     dbo.XF_RPAD(dbo.XF_NVL_C(OWNER_NM,' '),30,' ')+                            -- 7. ��ǥ�ڼ���                X(30)
                     dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(COM_NO, ' '),'-',''),13,' ')+                -- 8. ���ι�ȣ                  X(13)
                     dbo.XF_NVL_C(@av_object_term, '1')+                                  -- 9. ������Ⱓ�ڵ�          9(1)
                     dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(SUM(dbo.XF_NVL_N(c_rec_cnt,0)),NULL)),7,'0')+       -- 10.�����ҵ��ڼ�(c ���ڵ��)  9(7)
                     dbo.XF_RPAD(' ',7, ' ')+                                       -- 11.����                      X(7)
                     dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(SUM(dbo.XF_NVL_N(R01,0)),NULL)),14,'0')+          -- 12.����-������������޿��հ� 9(14)
                     CHK_CT01+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(SUM(dbo.XF_NVL_N(CT01,0))),NULL)),13,'0')+   -- 13.�Ű���ҵ漼�հ�(��ȣ+���밪) 9(1) + 9(13)
                     dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(SUM(dbo.XF_NVL_N(TRANS_INCOME_AMT,0)),NULL)),13,'0')+   -- 14.�̿������ҵ漼���հ�      9(13)
                     CHK_T01+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(SUM(dbo.XF_NVL_N(T01,0))),NULL)),13,'0')+   -- 15.������õ¡�� �ҵ漼�� �հ�(��ȣ+���밪) 9(1) + 9(13)
                     CHK_T02+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(SUM(dbo.XF_NVL_N(T02,0))),NULL)),13,'0')+   -- 16.������õ¡�� ����ҵ漼�� �հ�(��ȣ+���밪) 9(1) + 9(13)
                     CHK_T03+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(SUM(dbo.XF_NVL_N(T03,0))),NULL)),13,'0')+   -- 17.������õ¡�� �����Ư������ �հ�(��ȣ+���밪) 9(1) + 9(13)
                     CHK_TSUM+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(SUM(dbo.XF_NVL_N(T_SUM,0))),NULL)),13,'0')+  -- 18.������õ¡�� �� �հ�(��ȣ+���밪) 9(1) + 9(13)
                     dbo.XF_RPAD(' ',544, ' ') TEXT,                                    -- 19.����                      X(893)    2016���� X(873) �� X(893) 2020�⺯�� X(893) - X(544)
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
    /* C ���ڵ�                                                    */
    /***************************************************************/
    BEGIN -- C���ڵ塼�����ҵ��� ���ڵ塽
       SET @nLoop_C = 0
          
      DECLARE cur_C CURSOR  FOR
         SELECT A.EMP_ID,
            A.TAX_YMD,
            dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(A.CTZ_NO, ' '),'-',''),13,' ') AS CTZ_NO,
            -- ����õ¡���ǹ��ڡ�
            dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(@p_tax_no,' '),'-',''),10, ' ')+                            --  5. ����ڵ�Ϲ�ȣ                        X(10)
            -- ���ҵ��ڡ�
            '1'+                                                              --  6. ¡���ǹ��ڱ���                        9(1)
            dbo.XF_NVL_C(A.RESIDENT_CD, '1')+                                               --  7. �����ڱ����ڵ�                        9(1)
            dbo.XF_NVL_C(A.FOREIGN_CD, '1')+                                                --  8. ��/�ܱ��α����ڵ�                     9(1)
            dbo.XF_NVL_C(A.RELIGIOUS_YN, '2')+                                                          --  9. �������������ڿ���                    9(1)   2020�߰�
            dbo.XF_RPAD(dbo.XF_NVL_C(A.NATION_CD, ' '), 2, ' ')+                                      -- 10. ���������ڵ�                          X(2)
            dbo.XF_RPAD(A.EMP_NM, 30, ' ')+                                                 -- 11. ����                                  X(30)
            dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(A.CTZ_NO, ' '),'-',''),13,' ')+                             -- 12. �ֹε�Ϲ�ȣ                          X(13)
            dbo.XF_NVL_C(A.OFFICERS_YN, '2')+                                               -- 13. �ӿ�����                              9(1)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.PENSION_YMD,'YYYYMMDD'),0), 8, '0')+                        -- 14. Ȯ���޿��� ������������ ������        9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.PENSION_AMT,0),NULL)), 11, '0')+                    -- 15. 2011.12.31 ������                     9(11)
            CASE WHEN dbo.XF_TO_CHAR_D(A.C1_STA_YMD, 'YYYYMMDD') > dbo.XF_TO_CHAR_D(@av_adjust_yy +'0101', 'YYYYMMDD') THEN dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_STA_YMD,'YYYYMMDD'),0), 8, '0')
            ELSE dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(dbo.XF_TO_DATE(@av_adjust_yy +'0101', 'yyyymmdd'),'YYYYMMDD'),'0'), 8, '0') END+ -- 16. �ͼӳ⵵ ���ۿ�����                   9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_END_YMD,'YYYYMMDD'),'0'), 8, '0')+                       -- 17. �ͼӳ⵵ ���Ῥ����                   9(8)
            dbo.XF_NVL_C(dbo.XF_SUBSTR(A.RETIRE_TYPE_CD,2,1), '6')+                                     -- 18. ��������                              9(1)
            -- �������޿���Ȳ - �߰����޵
            -- �� �ٹ�ó�� ���� �� �߰�����, �������� �������� �Ǵ� �������� �ش翬���� �̹� �߻��� �������� �ִ� ��� �̰ų�,
            -- �ش翬���� �߻��� ��(��)�ٹ����� �������� �ִ� ��� �ۼ�
            dbo.XF_RPAD(dbo.XF_NVL_C(A.B1_CORP_NM, ' '), 40, ' ')+                                      -- 19. �ٹ�ó��                              X(40)
            dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(A.B1_TAX_NO,' '),'-',''),10, ' ')+                                                      -- 20. ����ڵ�Ϲ�ȣ                        X(10)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_MID_AMT,0),NULL)), 11, '0')+                   -- 21. �����޿�                              9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.NON_RETIRE_MID_AMT,0),NULL)), 11, '0')+                 -- 22. ����� �����޿�                       9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_MID_SUM,0),NULL)), 11, '0')+                   -- 23. ������� �����޿�                     9(11)
            -- �������޿���Ȳ - �����С�
            dbo.XF_RPAD(dbo.XF_NVL_C(@p_corp_nm, ' '), 40, ' ')+                                      -- 24. �ٹ�ó��                              X(40)
            dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(@p_tax_no,' '),'-',''),10, ' ')+                            -- 25. ����ڵ�Ϲ�ȣ                        X(10)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C_SUM,0),NULL)), 11, '0')+                        -- 26. �����޿�                              9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.NON_RETIRE_AMT,0),NULL)), 11, '0')+                   -- 27. ����� �����޿�                       9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_C_SUM,0),NULL)), 11, '0')+                   -- 28. ������� �����޿�                     9(11)
            -- �������޿���Ȳ - ���꡽
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_MID_AMT,0) + dbo.XF_NVL_N(A.C_SUM,0),NULL)), 11, '0')+     -- 29. �����޿�                              9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.NON_RETIRE_MID_AMT,0) + dbo.XF_NVL_N(NON_RETIRE_AMT,0),NULL)), 11, '0')+-- 30. ����� �����޿�                       9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R01,0),NULL)), 11, '0')+                        -- 31. ������� �����޿�                     9(11)
            -- ���ټӿ���-�߻����� �
            -- �� �ٹ�ó�� ���� �� �߰�����, �������� �������� �Ǵ� �������� �ش翬���� �̹� �߻��� �������� �ִ� ��� �̰ų�,
            -- �ش翬���� �߻��� ��(��)�ٹ����� �������� �ִ� ��� �ۼ�
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.B1_STA_YMD,'YYYYMMDD'),'0'), 8, '0')+                                               -- 32. �Ի���                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.MID_STA_YMD,'YYYYMMDD'),'0'), 8, '0')+                                              -- 33. �����                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.MID_END_YMD,'YYYYMMDD'),'0'), 8, '0')+                                              -- 34. �����                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.MID_PAY_YMD,'YYYYMMDD'),'0'), 8, '0')+                                              -- 35. ������                                 9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.MID_WORK_MM,0),NULL)),   4, '0')+                   -- 36. �ټӿ���                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.MID_EXCEPT_MM,0),NULL)),   4, '0')+                   -- 37. ���ܿ���                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.MID_ADD_MM,0),NULL)),   4, '0')+                    -- 38. �������                               9(4)
            '0000'+                                                             -- 39. �ߺ�����                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.MID_WORK_YY,0),NULL)),   4, '0')+                   -- 40. �ټӿ���                               9(4)
            -- ���ټӿ���-������
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.HIRE_YMD,'YYYYMMDD'),'0'), 8, '0')+                                                 -- 41. �Ի���                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_STA_YMD,'YYYYMMDD'),'0'), 8, '0')+                                               -- 42. �����                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_END_YMD,'YYYYMMDD'),'0'), 8, '0')+                                               -- 43. �����                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.PAY_YMD,'YYYYMMDD'),'0'), 8, '0')+                                                  -- 44. ������                                 9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_MM,0),NULL)),   4, '0')+                    -- 45. �ټӿ���                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_EXCEPT_MM,0),NULL)),   4, '0')+                    -- 46. ���ܿ���                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_ADD_MM,0),NULL)),   4, '0')+                     -- 47. �������                               9(4)
            '0000'+                                                             -- 48. �ߺ�����                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_YY,0),NULL)),   4, '0')+                    -- 49. �ټӿ���                               9(4)
            -- ���ټӿ���-���꡽
            '00000000'+                                                           -- 50. �Ի���                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.SUM_STA_YMD,'YYYYMMDD'),'0'), 8, '0')+                                              -- 51. �����                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.SUM_END_YMD,'YYYYMMDD'),'0'), 8, '0')+                                              -- 52. �����                                 9(8)
            '00000000'+                                                           -- 53. ������                                 9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.SUM_WORK_MM,0),NULL)),   4, '0')+                   -- 54. �ټӿ���                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.SUM_EXCEPT_MM,0),NULL)),   4, '0')+                   -- 55. ���ܿ���                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.SUM_ADD_MM,0),NULL)),   4, '0')+                    -- 56. �������                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.DUP_MM,0),NULL)),   4, '0')+                      -- 57. �ߺ�����                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.BC1_WORK_YY,0),NULL)),   4, '0')+                   -- 58. �ټӿ���                               9(4)
/*2020�����
            -- ���ټӿ���-�Ⱥ�-2012.12.31������
            -- ����� �ٹ��Ⱓ�� 2012.12.31�������� �ִ� ��쿡�� �ۼ�
            '00000000'+                                                           -- 58. �Ի���                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_STA_YMD_2012,'YYYYMMDD'),'0'), 8, '0')+                                          -- 59. �����                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_END_YMD_2012,'YYYYMMDD'),'0'), 8, '0')+                                          -- 60. �����                                 9(8)
            '00000000'+                                                           -- 61. ������                                 9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_MM_2012,0),NULL)),   4, '0')+                 -- 62. �ټӿ���                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.EXCEPT_MM_2012,0),NULL)),   4, '0')+                  -- 63. ���ܿ���                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.ADD_MM_2012,0),NULL)),   4, '0')+                   -- 64. �������                               9(4)
            '0000'+                                                             -- 65. �ߺ�����                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_YY_2012,0),NULL)),   4, '0')+                 -- 66. �ټӿ���                               9(4)               
            -- ���ټӿ���-�Ⱥ�-2013.1.1���ġ�
            -- ����� �ٹ��Ⱓ�� 2013.1.1���ĺ��� �ִ� ��쿡�� �ۼ�
            '00000000'+                                                           -- 67. �Ի���                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_STA_YMD_2013,'YYYYMMDD'),'0'), 8, '0')+                                          -- 68. �����                                 9(8)
            dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.C1_END_YMD_2013,'YYYYMMDD'),'0'), 8, '0')+                                          -- 69. �����                                 9(8)
            '00000000'+                                                           -- 70. ������                                 9(8)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_MM_2013,0),NULL)),   4, '0')+                 -- 71. �ټӿ���                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.EXCEPT_MM_2013,0),NULL)),   4, '0')+                  -- 72. ���ܿ���                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.ADD_MM_2013,0),NULL)),   4, '0')+                   -- 73. �������                               9(4)
            '0000'+                                                             -- 74. �ߺ�����                               9(4)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.C1_WORK_YY_2013,0),NULL)),   4, '0')+                 -- 75. �ټӿ���                               9(4)
*/
            -- ������������ ���� ��� ��� - ����ǥ�ذ�꡽ -- 2016�� �ͼ� �߰��κ�
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R01,0),NULL)), 11, '0')+                        -- 59. �����ҵ�                               9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R02_02,0),NULL)), 11, '0')+                     -- 60. �ټӿ�������                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_N_12,0),NULL)), 11, '0')+                     -- 61. ȯ��޿�                               9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_DEDUCT,0),NULL)), 11, '0')+                     -- 62. ȯ��޿�������                         9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_12,0),NULL)), 11, '0')+                       -- 63. �����ҵ����ǥ��                       9(11)
               
            -- ������ ������ ���� ��� ��� - ���װ�꡽ -- 2016��ͼ� �߰��κ�
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_12,0),NULL)), 11, '0')+                       -- 64. ȯ����⼼��                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R06_N,0),NULL)), 11, '0')+                        -- 65. �����ҵ� ���⼼��                      9(11)   2020�� title����
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TAX_DED,0),NULL)), 11, '0')+                      -- 66. ���װ���                               9(11)   2020���߰�
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_MID_INCOME_AMT,0),NULL)) , 11, '0')+               -- 67. �ⳳ��(�Ǵ� ������̿�) ����          9(11)
            CASE WHEN A.R08_S < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R08_S,0),NULL)) , 11, '0')+ -- 68. �Ű��󼼾�(��ȣ + ���밪)           9(11)
/* 2020�����
            -- ������������ ���� ��� ��� - ����ǥ�ذ�꡽ -- 2016��ͼ� ����
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R01,0),NULL)), 11, '0')+                        -- 83. �����ҵ�                               9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R02_01,0),NULL)), 11, '0')+                       -- 84. �����ҵ���������                       9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R02_02,0),NULL)), 11, '0')+                       -- 85. �ټӿ�������                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R03,0),NULL)), 11, '0')+                        -- 86. �����ҵ����ǥ��                       9(11)
               
            --������ ������ ���� ��� ��� - ���װ�� - 2012.12.31������ -- 2016��ͼ� ����
            -- ����� �ٹ��Ⱓ�� 2012.12.31�������� �ִ� ��쿡�� �ۼ�
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R03_2012,0),NULL)), 11, '0')+                     -- 87. ����ǥ�ؾȺ�                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_2012,0),NULL)), 11, '0')+                     -- 88. ����հ���ǥ��                         9(11)
            '00000000000'+                                                          -- 89. ȯ�����ǥ��                           9(11)
            '00000000000'+                                                          -- 90. ȯ����⼼��                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_2012,0),NULL)), 11, '0')+                     -- 91. ����ջ��⼼��                         9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R06_2012,0),NULL)), 11, '0')+                     -- 92. ���⼼��                               9(11)
            -- ������ ������ ���� ��� ��� - ���װ�� - 2013.1.1���ġ� -- 2016��ͼ� ����
            -- ����� �ٹ��Ⱓ�� 2013.1.1���ĺ��� �ִ� ��쿡�� �ۼ�
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R03_2013,0),NULL)), 11, '0')+                     -- 93. ����ǥ�ؾȺ�                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_2013,0),NULL)), 11, '0')+                     -- 94. ����հ���ǥ��                         9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_2013_5,0),NULL)), 11, '0')+                     -- 95. ȯ�����ǥ��                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_2013,0),NULL)), 11, '0')+                     -- 96. ȯ����⼼��                           9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_2013_5,0),NULL)), 11, '0')+                     -- 97. ����ջ��⼼��                         9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R06_2013,0),NULL)), 11, '0')+                     -- 98. ���⼼��                               9(11)
         
            -- ������ ������ ���� ��� ��� - ���װ�� - �հ衽 -- 2016��ͼ� ����
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R03_S,0),NULL)), 11, '0')+                        -- 99. ����ǥ�ؾȺ�                           9(11)
            --dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_2012,0) + dbo.XF_NVL_N(A.R04_2013,0),NULL)), 11, '0')+        -- 100. ����հ���ǥ��                        9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_TRUNC_N(dbo.XF_NVL_N(A.R03_S,0) / dbo.XF_NVL_N(A.BC1_WORK_YY,0), 0) ,NULL)), 11, '0') + -- 100. ����հ���ǥ��                9(11) 2017.02.14 ����
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R04_2013_5,0),NULL)), 11, '0')+                     -- 101. ȯ�����ǥ��                          9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_2013,0),NULL)), 11, '0')+                     -- 102. ȯ����⼼��                          9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R05_2012,0) + dbo.XF_NVL_N(A.R05_2013_5,0),NULL)), 11, '0')+      -- 103. ����ջ��⼼��                        9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R06_2012,0) + dbo.XF_NVL_N(A.R06_2013,0),NULL)) , 11, '0')+       -- 104. ���⼼��                              9(11)
               
            -- �������ҵ漼�װ�꡽ -- 2016��ͼ� ����
            dbo.XF_TO_CHAR_D(C1_END_YMD, 'YYYY')+                                             -- 105. �������� ���ϴ� ��������              9(4)         -- 2016�� �ͼ� �߰��κ�    
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R06,0),NULL)) , 11, '0')+                       -- 106. �����ҵ漼���⼼��                    9(11)        -- 2016�� �ͼ� �߰��κ� 
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.RETIRE_MID_INCOME_AMT,0),NULL)) , 11, '0')+               -- 107. �ⳳ��(�Ǵ� ������̿�) ����          9(11)
            CASE WHEN A.R08_S < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.R08_S,0),NULL)) , 11, '0')+-- 108. �Ű��󼼾�(��ȣ + ���밪)           9(11)
*/
            -- ���̿������ҵ漼�װ�꡽ -- 2016��ͼ� ����
            -- ���ҵ漼���� ��146����2�׿� ���� �����޿����� ���ݰ��¿� �Ա�(��ü)�Ͽ� �����ҵ漼 ¡���� ���� �ƴ��� ��� �ۼ�(�������� ��츸 �ۼ�����)
            CASE WHEN (CASE WHEN TRANS_IN_AMT =0 THEN 0  ELSE A.R08_S END) < 0 THEN '1' ELSE '0' END+                   -- 109. �Ű��󼼾�(��ȣ)                    9(1)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(CASE WHEN TRANS_IN_AMT =0 THEN 0  ELSE A.R08_S END),NULL)), 11, '0')+        -- 69. �Ű��󼼾�(���밪)                  9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_IN_AMT,0),NULL)), 11, '0')+                   -- 70. �����Աݱݾ�_�հ�                     9(11)
            dbo.XF_LPAD((CASE WHEN TRANS_IN_AMT =0 THEN 0 ELSE dbo.XF_NVL_N(A.RETIRE_C_SUM,0) END), 11, '0')+                               -- 71. �����޿�                              9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_INCOME_AMT,0),NULL)), 11, '0')+                 -- 72. �̿������ҵ漼                        9(11)
            --�����θ�-�Ű��󼼾ס�
            CASE WHEN A.CT01 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.CT01,0)),NULL)), 11, '0')+                     -- 73. �ҵ漼(��ȣ+���밪)                   9(1) + 9(11)
            CASE WHEN A.CT02 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.CT02,0)),NULL)), 11, '0')+                     -- 74. ����ҵ漼(��ȣ+���밪)               9(1) + 9(11)
            CASE WHEN A.CT03 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.CT03,0)),NULL)), 11, '0')+                     -- 75. �����Ư����(��ȣ+���밪)             9(1) + 9(11)
            CASE WHEN A.CT_SUM < 0 THEN '' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.CT_SUM,0)),NULL)), 11, '0')+                    -- 76. ��(��ȣ+���밪)                       9(1) + 9(11)
            --�����θ�-�̿������ҵ漼��
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_INCOME_AMT,0),NULL)), 11, '0')+                                       -- 77. �ҵ漼                                9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_RESIDENCE_AMT,0),NULL)), 11, '0')+                                      -- 78. ����ҵ漼                            9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_N_TAX_AMT,0),NULL)), 11, '0')+                                        -- 79. �����Ư����                          9(11)
            dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_INCOME_AMT,0) + dbo.XF_NVL_N(A.TRANS_RESIDENCE_AMT,0) + dbo.XF_NVL_N(A.TRANS_N_TAX_AMT,0),NULL)) , 11, '0')+  -- 80. ��                                    9(11)
            --�����θ�-�Ű��󼼾ס�
            CASE WHEN A.T01 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.T01,0)),NULL)), 11, '0')+                       -- 81. �ҵ漼(��ȣ+���밪)                   9(1) + 9(11)
            CASE WHEN A.T02 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.T02,0)),NULL)), 11, '0')+                       -- 82. ����ҵ漼(��ȣ+���밪)               9(1) + 9(11)
            CASE WHEN A.T03 < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.T03,0)),NULL)), 11, '0')+                       -- 83. �����Ư����(��ȣ+���밪)             9(1) + 9(11)
            CASE WHEN A.T_SUM < 0 THEN '1' ELSE '0' END+dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(ABS(dbo.XF_NVL_N(A.T_SUM,0)),NULL)), 11, '0')+                     -- 84. ��(��ȣ+���밪)                       9(1) + 9(11)
            dbo.XF_LPAD(' ',2,' ')                                                                            -- 85. ����                                 X(2)   2016���� X(8) �� X(2)
            FROM V_REP_CALC_LIST_RPT_2014 A
            WHERE A.COMPANY_CD = @av_company_cd
            AND dbo.XF_TO_CHAR_D(A.TAX_YMD,'YYYY') = @av_adjust_yy
            AND A.BIZ_CD = @p_biz_cd
  
          OPEN cur_C
          FETCH NEXT FROM cur_C -- Ŀ������ ����Ÿ ��������
              INTO @sEmp_id, @d_tax_ymd, @p_ctz_no, @sText_C;
            
              WHILE @@FETCH_STATUS = 0 -- ����Ÿ �������� ����(0), -1�� ����, -2�� ���Ե� ���� ����.   
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
                    -- ���ݰ��� �Աݸ� (D ���ڵ�)
                    DECLARE cur_d CURSOR FOR -- 2015.02.02 �߰�
              
                      SELECT  -- ����õ¡���ǹ��ڡ�
                          dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(@p_tax_no,' '),'-',''),10, ' ')+                -- 5.����ڹ�ȣ          X(10)
                          dbo.XF_RPAD(' ',50,' ')+                                        -- 6.����           X(50)               
                          --���ҵ��ڡ�
                          dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(@p_ctz_no, ' '),'-',''),13,' ')+                -- 7.�ҵ��� �ֹε�Ϲ�ȣ     X(13)
                          --�����ݰ��� �Աݸ���
                          dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(@nLoop_D,NULL)),2,'0') +                   -- 8.���ݰ��� �Ϸù�ȣ      9(2)
                          dbo.XF_RPAD(dbo.XF_NVL_C(A.REP_ANNUITY_BIZ_NM, ' '), 30, ' ')+                      -- 9.���ݰ��������        X(30)
                          dbo.XF_RPAD(dbo.XF_REPLACE(dbo.XF_NVL_C(A.REP_ANNUITY_BIZ_NO,' '),'-',''),10, ' ')+           -- 10.���ݰ���_����ڵ�Ϲ�ȣ  X(10)
                          dbo.XF_RPAD(dbo.XF_NVL_C(A.REP_ACCOUNT_NO, ' '), 20, ' ')+                        -- 11.���ݰ���_���¹�ȣ     X(20)    
                          dbo.XF_LPAD(dbo.XF_NVL_C(dbo.XF_TO_CHAR_D(A.REP_TRANS_YMD,'YYYYMMDD'),'00000000'), 8, '00000000')+      -- 12.���ݰ���_�Ա���      9(8)
                          dbo.XF_LPAD(dbo.XF_TRIM(dbo.XF_TO_CHAR_N(dbo.XF_NVL_N(A.TRANS_ALLOWANCE_COURT_SUM,0),NULL)), 11, '0')+  -- 13.���ݰ���_�����Աݱݾ�   9(11)
                          dbo.XF_RPAD(' ',595, ' ') AS TEXT                                   -- 14. ����                     X(944)  2016���� X(924) �� X(944)  2020���� X(944) �� X(595)
                        FROM V_REP_INCOME_TAX_RPT_2014 A 
                      WHERE A.EMP_ID = @sEmp_id
                        AND A.WORK_YMD = @d_tax_ymd
                    
                    OPEN cur_d -- Ŀ������
                    FETCH NEXT FROM cur_d -- Ŀ������ ����Ÿ ��������                                                    
                        INTO @sText_D;
                    WHILE @@FETCH_STATUS = 0 -- ����Ÿ �������� ����(0), -1�� ����, -2�� ���Ե� ���� ����. 
                    BEGIN -- cur_d BEGIN
                    SET @nLoop  = @nLoop+ 1
                    SET @nLoop_D = @nLoop_D + 1
                      BEGIN
                        INSERT INTO REP_REPORT_FILE
                        VALUES (@av_adjust_yy, 'D', @nLoop, 0, @sEmp_id,
                            'D'+@nRecord+@p_tax_office_cd+dbo.XF_REPLACE(dbo.XF_LPAD(@nLoop_C,6,'0'),' ','0')+@sText_D, @an_work_emp_id);    -- 2015.02.02 �߰�(an_work_emp_id)                         
                        SELECT @ERRCODE = @@ERROR
                          IF @ERRCODE != 0 
                            BEGIN  --
                              SET @av_ret_code      = 'FAILURE!' 
                              SET @av_ret_message   = 'RP_REPORT_FILE INSERT Error [D] ' + ' ['+convert(nvarchar(10),@errcode)+'] '
                              --ROLLBACK TRAN
                              RETURN 
                            END --    
                      END -- D INSERT END
                    FETCH NEXT FROM cur_D -- Ŀ������ ����Ÿ ��������
                    INTO @sText_D;
                    END -- cur_D END
                CLOSE cur_d -- 2015.02.04 ����:Ŀ���ݱ�
                DEALLOCATE cur_d -- 2015.02.04 ����:Ŀ�� �Ҵ�����
                END -- D ���ڵ� ��.
              
              FETCH NEXT FROM cur_C -- Ŀ������ ����Ÿ ��������
                    --INTO @sEmp_id, @d_tax_ymd, @sText_C;
                    INTO  @sEmp_id, @d_tax_ymd, @p_ctz_no, @sText_C; -- 2015.02.04 ����
              END -- cur_c END
              
              CLOSE cur_C -- Ŀ���ݱ�
              DEALLOCATE cur_C -- Ŀ�� �Ҵ�����
    END -- C ���ڵ� ��.                       
        
    FETCH NEXT FROM cur_B -- Ŀ������ ����Ÿ ��������
          INTO @p_biz_cd ,@p_tax_office_cd ,@p_home_tax_id, @p_tax_no, @p_corp_nm, @p_int_org_nm, @p_int_charge_nm, 
                          @p_int_charge_tel_no, @p_corp_no, @p_ceo_nm, @p_biz_nm
    
    END -- cur_B END
    CLOSE cur_B -- Ŀ���ݱ�
    DEALLOCATE cur_B -- Ŀ�� �Ҵ�����
      END  -- B ���ڵ� ��. 
      
         /***************************************************************/
        /* A ���ڵ�                                                    */
        /***************************************************************/
        BEGIN -- A���ڵ� BEGIN
          INSERT INTO REP_REPORT_FILE
            SELECT @av_adjust_yy,
                 'A',
                 1,  
                 0,  
                 NULL,
                 'A'+                               -- 1. ���ڵ屸��                      X(1)
                 @nRecord+                            -- 2. �ڷᱸ��                        9(2)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$TAX_OFFICE_CD,' '),3, ' ')+    -- 3. �������ڵ�                      X(3)
                 dbo.XF_LPAD(dbo.XF_NVL_C(@av_release_ymd,'0'),8, '0')+           -- 4. ��������                      9(8)
                 '2'+                               -- 5. ������(�븮�α���)              9(1): 2-����
                 dbo.XF_RPAD(' ',6, ' ')+                     -- 6. �����븮�ΰ�����ȣ              X(6)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$HOME_TAX_ID,' '),20, ' ')+   -- 7. Ȩ�ý�ID                        X(20)
                 '9000'+                              -- 8. �������α׷� �ڵ�               X(4)
                 dbo.XF_RPAD(dbo.XF_REPLACE(@t_biz$TAX_NO,'-',''),10, ' ')+       -- 9. ����ڵ�Ϲ�ȣ                  X(10)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$CORP_NM,' '),40, ' ')+           -- 10.���θ�(��ȣ)                    X(40)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$INT_ORG_NM,' '),30, ' ')+        -- 11.����� �μ�                     X(30)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$INT_CHARGE_NM,' '),30, ' ')+     -- 12.����ڼ���                      X(30)
                 dbo.XF_RPAD(dbo.XF_NVL_C(@t_biz$INT_CHARGE_TEL_NO,' '),15, ' ')+ -- 13.�������ȭ��ȣ                  X(15)
                 dbo.XF_LPAD(@nLoop_B,5,'0')+                   -- 14.�Ű��ǹ��ڼ�                    9(5)
                 '101'+                             -- 15.����ѱ��ڵ�(KSC-5601)          9(3)
                 dbo.XF_RPAD(' ',583, ' ') text,                  -- 16.����                            X(932)  2016���� X(912) �� X(932)  2020���� X(932) �� X(583)
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
        END -- A���ڵ� END
  -- ***********************************************************
    -- �۾� �Ϸ�
    -- ***********************************************************
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�..'
    
END -- START END
GO



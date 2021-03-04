SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE dbo.P_REP_APP_SAIP_INTERFACE (
		@av_company_cd		nvarchar(10),			-- ȸ���ڵ�
		@av_locale_cd		nvarchar(10),			-- �����ڵ�   
		@ad_std_date		date ,					-- ��������
		@av_pay_group		nvarchar(10),			-- �޿��׷�
       @an_mod_user_id                NUMERIC(38),				-- ������ ���
       @av_ret_code                   NVARCHAR(4000)    OUTPUT, -- ����ڵ�   
       @av_ret_message                NVARCHAR(4000)    OUTPUT  -- ����޽���   
    ) AS   
   
    -- ***************************************************************************   
    --   TITLE       : �������� �а�ó��
    --   PROJECT     : E-HR �ý���   
    --   AUTHOR      :   
    --   PROGRAM_ID  : P_REP_APP_SAIP_INTERFACE   
    --   RETURN      : 1) SUCCESS!/FAILURE!   
    --                 2) ��� �޽���   
    --   COMMENT     : �����ݰ��    
    --   HISTORY     : 
    -- ***************************************************************************   
   
BEGIN
-- �ӽ� ���̺� ����(�����߰�� ���� ����)
IF OBJECT_ID('tempdb..#TEMP_HUMAN') IS NOT NULL
	DROP TABLE #TEMP_HUMAN
CREATE TABLE #TEMP_HUMAN
	(
	COMPANY_CD [nvarchar](10) NULL,						--* ȸ���ڵ�
	ORG_CD [nvarchar](10) NULL,						--* �μ��ڵ�
	EMP_NO [nvarchar](10) NULL,						--* ���
	EMP_NM [nvarchar](20) NULL,						--* ����
	POS_GRD_CD  [nvarchar](10) NULL,						--* ����
	INS_TYPE_YN [nvarchar](2) NULL,					--* ���ݰ��Կ���
	INS_TYPE_CD [nvarchar](10) NULL,				--* ��������
	AMT_NEW_RETR_PAY [numeric](18,0) NULL,					--* ������Ա�.
	ACNT_TYPE_CD [nvarchar](10) NULL,						--* ��������
	COST_CD [nvarchar](10) NULL,							--* �ڽ�Ʈ����
    PAY_GROUP [nvarchar](10) NULL						--* �޿��׷�
)
    /* �⺻������ ���Ǵ� ���� */   
    DECLARE @v_program_id              NVARCHAR(30)   
          , @v_program_nm              NVARCHAR(100)   
          , @ERRCODE                   NVARCHAR(10)   

DECLARE
	@v_company_cd				NVARCHAR(10),		-- ȸ���ڵ�
	@n_pay_group_id				NUMERIC(38),		-- �޿��׷�ID
   /* ���ν��� ������ ����� ���� ����  */
	@v_cd_company				NVARCHAR(10),		-- ȸ���ڵ�
	@v_cd_dept					NVARCHAR(20),		-- �μ��ڵ�
	----
	@v_company_code				NVARCHAR(20),		-- ȸ���ڵ�
	@v_cost_type				NVARCHAR(20),		-- �ڽ�Ʈ���� ����κ� ORM_COST.COST_TYPE
	@v_pos_grd_cd				NVARCHAR(20),		-- �����ڵ�
    @n_seqno_s                  INT = 0,			-- ��������
	@v_dt_dian					NVARCHAR(08),		-- �̰�����
	@v_dt_gian					NVARCHAR(06),		-- ���ؿ�
	@v_emp_no					NVARCHAR(20),		-- ���
	@v_emp_nm					NVARCHAR(20),		-- �����
	@v_cost_cd					NVARCHAR(20),		-- �ڽ�Ʈ���� �ڵ� ORM_COST.COST_CD
	@v_acnt_cd					NVARCHAR(20),		-- �����ڵ�
	@v_rel_cd					NVARCHAR(20),		-- ���°���
	@v_amt_new_retr_pay			NUMERIC(15),		-- ������Ծ�
	@v_dbcr_cd					NVARCHAR(20),		-- ���뱸��
    @v_seq                      NVARCHAR(10),			-- ��������
    @v_seq_h                    NVARCHAR(20),			-- ��ǥ��ȣ
    @v_acct_type                NVARCHAR(20) = 'E012',	-- �̰����� - ��������
    @v_pay_group                NVARCHAR(20),			-- �޿��׷�
    @v_ifc_sort                 NVARCHAR(20),			-- ��õ����
    --@v_bill_type                NVARCHAR(20),			-- ��������

	/* BEGIN CATCH ����� ���� ����  */
	@v_error_number				INT,
	@v_error_severity			INT,
	@v_error_state				INT,
	@v_error_procedure			VARCHAR(1000),
	@v_error_line				INT,
	@v_error_message			VARCHAR(3000),

	/* ERR_HANDLER ����� ���� ���� */
	@v_error_num			    INT,
	@v_row_count				INT,
	@v_error_code				VARCHAR(1000),										-- �����ڵ�
	@v_error_note				VARCHAR(3000)										-- ������Ʈ (exec : '���ڿ�A|���ڿ�B')


DECLARE @MSEQ INT;

      /* �⺻���� �ʱⰪ ����*/   
    SET @v_program_id    = 'P_REP_APP_SAIP_INTERFACE'   -- ���� ���ν����� ������   
    SET @v_program_nm    = '�������� �а�ó��'        -- ���� ���ν����� �ѱ۹���   
    SET @av_ret_code     = 'SUCCESS!'   
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null,  @an_mod_user_id)   
PRINT('���� ===> ')   

	--//***************************************************************************
	--//*****************		 �������� �а� ó��				 **************
	--//***************************************************************************

	/* �Ķ���͸� ���ú����� ó���ϸ� �̶� NULL�� ��쿡 �ʿ��� ó���� �Ѵ�. */
	SET @v_dt_dian		= dbo.XF_TO_CHAR_D(@ad_std_date, 'yyyymmdd')
	SET @v_dt_gian      = LEFT(@v_dt_dian, 6)
	SET @v_ifc_sort		= @v_acct_type
	--SET @v_id_user		= @p_id_user;		-- �α��λ����
--===========================================================================================================
-- ��ǥ �������� �� ��ǥ��ȣ ���ϱ�
-------------------------------------------------------------------------------------------------------------
-- �������� : �ش� ��ǥ�����Ͽ� ������ �������� �������� 1���� 1�� ���������� ����(1,2,3....)
-- ��ǥ��ȣ : e-HRȸ���ڵ� + ǰ������ + ���������� 0�� ä�� 4�ڸ� ���ڿ�
--      ex) ������������ 2020�� 8�� 30�� ǰ�����ڷ� �ش����ڿ� �ι�°�� ��ǥ������ ��� ( E + 20200830 + 0002 )
--===========================================================================================================
    BEGIN

        SELECT @v_seq = ISNULL(MAX(SEQ), 0) + 1
          FROM H_IF_SAPINTERFACE
         WHERE CD_COMPANY = @av_company_cd
           AND DRAW_DATE  = @v_dt_dian

        SET @v_seq_h = @av_company_cd + @v_dt_dian + dbo.XF_LPAD(@v_seq, 4, '0')
    END
	PRINT '@v_seq ' + @v_seq + ' ' + @av_company_cd + @v_dt_dian


	BEGIN
		-- SAP I/F ���̺� ����
		if ISNULL(@av_pay_group,'') = ''
			begin
				DELETE FROM H_IF_SAPINTERFACE
				WHERE CD_COMPANY = @av_company_cd
				  AND DRAW_DATE = @v_dt_dian					-- �̰�����		
				  AND ACCT_TYPE = @v_acct_type
				  AND FLAG = 'N'	
			end
		else
			begin
				DELETE FROM H_IF_SAPINTERFACE
				WHERE CD_COMPANY = @av_company_cd
				  AND DRAW_DATE = @v_dt_dian					-- �̰�����		
				  AND ACCT_TYPE = @v_acct_type
                  AND PAYGP_CODE = @av_pay_group		
				  AND FLAG = 'N'	
			end
		--------------------------------------------------------------------------------------------------------------------
		-- Message Setting Block 
		--------------------------------------------------------------------------------------------------------------------
		IF @@error <> 0
			BEGIN
				SET @v_error_number = @@error;
				SET @v_error_code = 'p_at_app_sap_interface';
				SET @v_error_note = 'H_IF_SAPINTERFACE TABLE ���� ���� �� ������ �߻��Ͽ����ϴ�.'
				GOTO ERR_HANDLER
			END
		-- �޿��׷� ���� ��������
		IF @av_pay_group <> ''
			BEGIN
				SELECT @n_pay_group_id = PAY_GROUP_ID
				  FROM PAY_GROUP WITH(NOLOCK)
				 WHERE COMPANY_CD = @av_company_cd
				   AND PAY_GROUP = @av_pay_group
			END 
		----------------------------------
		-- �����߰�� ����, �ӽ����̺� ����
		----------------------------------
		--SET @v_sql = '';
                         --, DBO.F_PAY_GET_COST(YMD.COMPANY_CD, ROLL.EMP_ID, ROLL.ORG_ID, YMD.PAY_YMD, '1') AS COST_CD
                         --, DBO.F_PAY_GET_COST(YMD.COMPANY_CD, ROLL.EMP_ID, ROLL.ORG_ID, YMD.PAY_YMD, '2') AS COST_NM
                         --, DBO.F_PAY_GET_COST(YMD.COMPANY_CD, ROLL.EMP_ID, ROLL.ORG_ID, YMD.PAY_YMD, '3') AS ACCT_CD
                         --, DBO.F_PAY_GET_COST(YMD.COMPANY_CD, ROLL.EMP_ID, ROLL.ORG_ID, YMD.PAY_YMD, '4') AS COST_TYPE
		INSERT INTO #TEMP_HUMAN
			(COMPANY_CD, ORG_CD, EMP_NO, EMP_NM,
			 POS_GRD_CD, INS_TYPE_YN, INS_TYPE_CD, AMT_NEW_RETR_PAY,
			 ACNT_TYPE_CD, COST_CD, PAY_GROUP)
		SELECT A.COMPANY_CD,
				dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', A.ESTIMATION_YMD, '10') AS ORG_CD,
				EMP.EMP_NO, EMP.EMP_NM,
				B.POS_GRD_CD, B.INS_TYPE_YN, ISNULL(A.INS_TYPE_CD,'00'), A.NEW_RETIRE_AMT,
				'E012', A.ACC_CD, B.PAY_GROUP
		  FROM REP_ESTIMATION A
		  INNER JOIN REP_CALC_LIST B
		          ON A.COMPANY_CD = B.COMPANY_CD
				 AND A.ESTIMATION_YMD = B.PAY_YMD
				 AND A.EMP_ID = B.EMP_ID
				 AND B.CALC_TYPE_CD = '03'
		  INNER JOIN VI_FRM_PHM_EMP EMP
				  ON A.EMP_ID = EMP.EMP_ID AND EMP.LOCALE_CD = @av_locale_cd
		 WHERE A.COMPANY_CD = @av_company_cd
		   AND A.ESTIMATION_YMD = @ad_std_date
		   AND CASE WHEN A.COMPANY_CD IN ('A','B','C') THEN
		                 CASE WHEN dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', A.ESTIMATION_YMD, '10') <> 'Z999' -- �Ͽ�¡ ����
						           AND A.INS_TYPE_CD = '20' -- DC����
								THEN 1
							ELSE 0 END
					ELSE 1 END = 1
		----------------------------------
		-- �����߰�� ����, �ӽ����̺� ����
		----------------------------------
		--DECLARE PER_CUR	CURSOR	FOR
			--SELECT A.COMPANY_CD
			--	  ,CC.COST_TYPE
			--	  ,A.POS_GRD_CD
			--	  ,A.EMP_NO
			--	  ,A.EMP_NM
			--	  ,A.COST_CD
			--	  ,CASE WHEN A.INS_TYPE_CD='10' THEN AC.INS_DB_ACNT_CD
			--			WHEN A.INS_TYPE_CD='20' THEN AC.INS_DC_ACNT_CD
			--			ELSE AC.INS_NO_ACNT_CD END AS ACNT_CD -- 
			--	  ,CASE WHEN A.INS_TYPE_CD='10' THEN AC.INS_DB_REL_CD
			--			WHEN A.INS_TYPE_CD='20' THEN AC.INS_DC_REL_CD
			--			ELSE AC.INS_NO_REL_CD END AS REL_CD -- 
			--	  ,A.AMT_NEW_RETR_PAY
			--	  ,AC.DBCR_CD
   --               ,A.PAY_GROUP
			--	  , AC.REP_BILL_TYPE_CD BILL_TYPE_CD
			--	  ,A.ORG_CD
			--	  ,A.INS_TYPE_YN
			--	  ,A.INS_TYPE_CD
   --               ,A.ACNT_TYPE_CD
			--	  FROM #TEMP_HUMAN A
			--	  JOIN ORM_COST CC
			--	    ON A.COMPANY_CD = CC.COMPANY_CD
			--	   AND A.COST_CD = CC.COST_CD
			--	   AND @ad_std_date BETWEEN CC.STA_YMD AND CC.END_YMD
			--	  JOIN REP_ACNT_MNG AC
			--	    ON A.COMPANY_CD = AC.COMPANY_CD
			--	   AND CC.ACCT_CD = AC.PAY_ACNT_TYPE_CD
			--	   AND AC.REP_BILL_TYPE_CD = @v_acct_type
			--	   AND @ad_std_date BETWEEN AC.STA_YMD AND AC.END_YMD
			--	 WHERE A.AMT_NEW_RETR_PAY <> 0

		DECLARE PER_CUR	CURSOR	FOR
			SELECT A.COMPANY_CD
				  ,CC.COST_TYPE
				  ,A.POS_GRD_CD
				  ,A.EMP_NO
				  ,A.EMP_NM
				  ,A.COST_CD
				  ,CASE WHEN A.INS_TYPE_CD='10' THEN AC.INS_DB_ACNT_CD
						WHEN A.INS_TYPE_CD='20' THEN AC.INS_DC_ACNT_CD
						ELSE AC.INS_NO_ACNT_CD END AS ACNT_CD -- 
				  ,CASE WHEN A.INS_TYPE_CD='10' THEN AC.INS_DB_REL_CD
						WHEN A.INS_TYPE_CD='20' THEN AC.INS_DC_REL_CD
						ELSE AC.INS_NO_REL_CD END AS REL_CD -- 
				  ,A.AMT_NEW_RETR_PAY
				  ,AC.DBCR_CD
                  ,A.PAY_GROUP
				  --, AC.REP_BILL_TYPE_CD BILL_TYPE_CD
				  --,A.ORG_CD
				  --,A.INS_TYPE_YN
				  --,A.INS_TYPE_CD
      --            ,A.ACNT_TYPE_CD
				  FROM #TEMP_HUMAN A
				  JOIN ORM_COST CC
				    ON A.COMPANY_CD = CC.COMPANY_CD
				   AND A.COST_CD = CC.COST_CD
				   AND @ad_std_date BETWEEN CC.STA_YMD AND CC.END_YMD
				  JOIN REP_ACNT_MNG AC
				    ON A.COMPANY_CD = AC.COMPANY_CD
				   AND CC.ACCT_CD = AC.PAY_ACNT_TYPE_CD
				   AND AC.REP_BILL_TYPE_CD = @v_acct_type
				   AND @ad_std_date BETWEEN AC.STA_YMD AND AC.END_YMD
				 WHERE A.AMT_NEW_RETR_PAY <> 0
		OPEN PER_CUR
		WHILE 1=1
		BEGIN
			FETCH NEXT FROM PER_CUR INTO @v_company_code, @v_cost_type, @v_pos_grd_cd, @v_emp_no, @v_emp_nm,
										@v_cost_cd, @v_acnt_cd, @v_rel_cd, @v_amt_new_retr_pay, @v_dbcr_cd,
										@v_pay_group
			IF @@FETCH_STATUS <> 0 BREAK
			SET @n_seqno_s = @n_seqno_s + 1
            BEGIN TRY
                INSERT INTO H_IF_SAPINTERFACE ( CD_COMPANY        -- ȸ���ڵ�
                                              , MANDT_S           -- ��������
                                              , GSBER_S           -- �ͼӺμ�
                                              , LIFNR_S           -- ����ó�ڵ�
                                              , ZPOSN_S           -- ����
                                              , SEQNO_S           -- ��������
                                              , DRAW_DATE         -- �̰�����
                                              , SNO               -- ���
                                              , SNM               -- �����
                                              , COST_CENTER       -- �ڽ�Ʈ����
                                              , SAP_ACCTCODE      -- ȸ�����
                                              , AMT               -- �ݾ�
                                              , DBCR_GU           -- ���뱸��
                                              , SEQ               -- ����
                                              , ACCT_TYPE         -- �̰�����
                                              , FLAG              -- FLAG
                                              , PAY_YM            -- �޿����
                                              , PAY_DATE          -- ��������
                                              , PAY_SUPP          -- ���ޱ���
                                              , ITEM_CODE         -- �����׸�
                                              , PAYGP_CODE        -- �޿��׷�
                                              , IFC_SORT          -- ��õ����
                                              , SLIP_DATE         -- ǰ������
                                              , REMARK            -- ���
                                              , ID_INSERT         -- �Է���
                                              , DT_INSERT         -- �Է���
                                              , ID_UPDATE         -- ������
                                              , DT_UPDATE         -- ������
                                              , XNEGP             -- -������
                                              , ACCNT_CD          -- ������
                                              , SEQ_H             -- ��ǥ��ȣ
                                              , GUBUN
                                              , COMPANY_CD        -- EHRȸ���ڵ�
                                              , PAY_TYPE_CD       -- ���ޱ���
                                              , PAY_ACNT_TYPE_CD  -- �����з�
                                              , PAY_ITEM_NM       -- �޿��׸��
                                     ) VALUES (
                                                @v_company_code      -- CD_COMPANY(ȸ���ڵ�)
                                              , NULL                 -- MANDT_S(��������)
                                              , @v_cost_type         -- GSBER_S(�ͼӺμ�)
                                              , NULL                 -- LIFNR_S(����ó�ڵ�)
                                              , @v_pos_grd_cd        -- ZPOSN_S(����)
                                              , dbo.XF_LPAD(@n_seqno_s, 10, '0')          -- SEQNO_S(��������)
                                              , @v_dt_dian           -- DRAW_DATE(�̰�����)
                                              , @v_emp_no			 -- SNO(���)
                                              , @v_emp_nm            -- SNM(�����)
                                              , dbo.XF_LPAD(@v_cost_cd, 10, '0')		-- COST_CENTER(�ڽ�Ʈ����)
                                              , dbo.XF_LPAD(@v_acnt_cd, 10, '0')        -- SAP_ACCTCODE(ȸ�����)
                                              , @v_amt_new_retr_pay  -- AMT(�ݾ�)
                                              , @v_dbcr_cd			 -- DBCR_GU(���뱸��)
                                              , @v_seq               -- SEQ(����)
                                              , @v_acct_type         -- ACCT_TYPE(�̰�����)
                                              , 'N'                  -- FLAG(FLAG)
                                              , @v_dt_gian           -- PAY_YM(�޿����)
                                              , @v_dt_dian           -- PAY_DATE(��������)
                                              , '��������'           -- PAY_SUPP(���ޱ���)
                                              , ''				     -- ITEM_CODE(�����׸�)
                                              , @v_pay_group		 -- PAYGP_CODE(�޿��׷�)
                                              , @v_ifc_sort          -- IFC_SORT(��õ����)
                                              , @v_dt_dian           -- SLIP_DATE(ǰ������)
                                              , '��������(' + @v_acct_type + ')'   -- REMARK(���)
                                              , @an_mod_user_id      -- ID_INSERT(�Է���)
                                              , GETDATE()            -- DT_INSERT(�Է���)
                                              , @an_mod_user_id      -- ID_UPDATE(������)
                                              , GETDATE()            -- DT_UPDATE(������)
                                              , ''                 -- XNEGP(-������)
                                              , dbo.XF_LPAD(@v_rel_cd, 10, '0')  -- ACCNT_CD(������)
                                              , @v_seq_h             -- SEQ_H(��ǥ��ȣ)
                                              , NULL                 -- GUBUN
                                              , @av_company_cd       -- COMPANY_CD(EHRȸ���ڵ�)
                                              , ''     -- PAY_TYPE_CD(���ޱ���)
                                              , @v_acct_type         -- PAY_ACNT_TYPE_CD(�����з�)
                                              , '��������'     -- PAY_ITEM_NM(�޿��׸��)
                                              )

            END TRY
            BEGIN CATCH
                SET @av_ret_code = 'FAILURE!'
                SET @av_ret_message = DBO.F_FRM_ERRMSG(@v_emp_no + '[' + @v_emp_nm + ']��ǥ���� �� �����߻�[ERR]', @v_program_id,  0060, ERROR_MESSAGE(), @an_mod_user_id)
                IF @@TRANCOUNT > 0
                    ROLLBACK
                RETURN
            END CATCH
		END -- End Of Cursor
		CLOSE	PER_CUR
		DEALLOCATE	PER_CUR
--=========================================================================================
-- ������ ����(����)
--=========================================================================================
        BEGIN TRY
            INSERT INTO H_IF_SAPINTERFACE (   CD_COMPANY           -- ȸ���ڵ�
                                            , MANDT_S              -- ��������
                                            , GSBER_S              -- �ͼӺμ�
                                            , LIFNR_S              -- ����ó�ڵ�
                                            , ZPOSN_S              -- ����
                                            , SEQNO_S              -- ��������
                                            , DRAW_DATE            -- �̰�����
                                            , SNO                  -- ���
                                            , SNM                  -- �����
                                            , COST_CENTER          -- �ڽ�Ʈ����
                                            , SAP_ACCTCODE         -- ȸ�����
                                            , AMT                  -- �ݾ�
                                            , DBCR_GU              -- ���뱸��
                                            , SEQ                  -- ����
                                            , ACCT_TYPE            -- �̰�����
                                            , FLAG                 -- FLAG
                                            , PAY_YM               -- �޿����
                                            , PAY_DATE             -- ��������
                                            , PAY_SUPP             -- ���ޱ���
                                            , ITEM_CODE            -- �����׸�
                                            , PAYGP_CODE           -- �޿��׷�
                                            , IFC_SORT             -- ��õ����
                                            , SLIP_DATE            -- ǰ������
                                            , REMARK               -- ���
                                            , ID_INSERT            -- �Է���
                                            , DT_INSERT            -- �Է���
                                            , ID_UPDATE            -- ������
                                            , DT_UPDATE            -- ������
                                            , XNEGP                -- -������
                                            , ACCNT_CD             -- ������
                                            , SEQ_H                -- ��ǥ��ȣ
                                            , GUBUN			     
                                            , COMPANY_CD           -- EHRȸ���ڵ�
                                            , PAY_TYPE_CD          -- ���ޱ���
                                              , PAY_ACNT_TYPE_CD  -- �����з�
                                            , PAY_ITEM_NM          -- �޿��׸��
                                            )
                                       SELECT @v_company_code      -- CD_COMPANY(ȸ���ڵ�)
                                            , NULL                 -- MANDT_S(��������)
                                            , GSBER_S              -- @v_ifc_sort          -- GSBER_S(�ͼӺμ�)
                                            , NULL                 -- LIFNR_S(����ó�ڵ�)
                                            , ''                 -- ZPOSN_S(����)
                                            , dbo.XF_LPAD(RANK() OVER(ORDER BY ACCNT_CD, GSBER_S) + @n_seqno_s, 10, '0')
                                            , DRAW_DATE            -- DRAW_DATE(�̰�����)
                                            , ''            -- SNO(���)
                                            , ''                   -- SNM(�����)
                                            , ''           -- COST_CENTER(�ڽ�Ʈ����)
                                            , ACCNT_CD       -- SAP_ACCTCODE(ȸ�����)
                                            , SUM(CASE WHEN DBCR_GU = '40' THEN AMT ELSE -AMT END)         -- AMT(�ݾ�)
                                            , '50'           -- DBCR_GU(���뱸��)
                                            , SEQ                  -- SEQ(����)
                                            , ACCT_TYPE            -- ACCT_TYPE(�̰�����)
                                            , 'N'                  -- FLAG(FLAG)
                                            , MAX(PAY_YM)          -- PAY_YM(�޿����)
                                            , MAX(PAY_DATE)        -- PAY_DATE(��������)
                                              , '��������'           -- PAY_SUPP(���ޱ���)
                                            , ''             -- ITEM_CODE(�����׸�)
                                            , PAYGP_CODE               -- PAYGP_CODE(�޿��׷�)
                                            , @v_ifc_sort          -- IFC_SORT(��õ����)
                                            , DRAW_DATE                 -- SLIP_DATE(ǰ������)
                                            , '��������(' + @v_acct_type + ')����'        -- REMARK(���)
                                            , @an_mod_user_id      -- ID_INSERT(�Է���)
                                            , GETDATE()            -- DT_INSERT(�Է���)
                                            , @an_mod_user_id      -- ID_UPDATE(������)
                                            , GETDATE()            -- DT_UPDATE(������)
                                            , ''                 -- XNEGP(-������)
                                            , ''                 -- ACCNT_CD(������)
                                            , @v_seq_h             -- SEQ_H(��ǥ��ȣ)
                                            , NULL                 -- GUBUN
                                            , @av_company_cd       -- COMPANY_CD(EHRȸ���ڵ�)
                                              , ''     -- PAY_TYPE_CD(���ޱ���)
                                              , @v_acct_type         -- PAY_ACNT_TYPE_CD(�����з�)
                                              , '��������'     -- PAY_ITEM_NM(�޿��׸��)
                                         FROM H_IF_SAPINTERFACE
                                        WHERE CD_COMPANY  = @v_company_code
                                          AND ACCT_TYPE   = @v_acct_type
                                          AND DRAW_DATE    = @v_dt_dian
										  AND (ISNULL(@av_pay_group,'')='' OR PAYGP_CODE = @av_pay_group)
                                        GROUP BY CD_COMPANY, DRAW_DATE, SEQ, PAYGP_CODE, ACCT_TYPE, ACCNT_CD, GSBER_S

        END TRY
        BEGIN CATCH
            SET @av_ret_code = 'FAILURE!'
            SET @av_ret_message = DBO.F_FRM_ERRMSG('���� �Ѿ� ��ǥ���� �� �����߻�[ERR]', @v_program_id,  0090, ERROR_MESSAGE(), @an_mod_user_id)
            IF @@TRANCOUNT > 0
                ROLLBACK
            RETURN
        END CATCH
	END
  -----------------------------------------------------------------------------------------------------------------------
  -- END Message Setting Block 
  ----------------------------------------------------------------------------------------------------------------------- 

  --SELECT *
  --FROM H_IF_SAPINTERFACE
		--		WHERE CD_COMPANY = @av_company_cd
		--		  AND DRAW_DATE = @v_dt_dian					-- �̰�����		
		--		  AND ACCT_TYPE = @v_acct_type
  --                AND (ISNULL(@av_pay_group,'')='' OR PAYGP_CODE = @av_pay_group)

PRINT('<<===== P_REP_APP_SAIP_INTERFACE END')   
   -- ***********************************************************   
   -- �۾� �Ϸ�   
   -- ***********************************************************   
--SELECT dbo.F_FRM_CODE_NM( A.COMPANY_CD, @av_locale_cd, 'PHM_POS_GRD_CD', A.POS_GRD_CD, dbo.XF_SYSDATE(0), '1') AS POS_GRD_NM, -- ����
--	A.*
--  FROM #TEMP_HUMAN A
-- WHERE A.AMT_NEW_RETR_PAY <> 0
--   AND EMP_NO IN (SELECT EMP_NO
--			  FROM #TEMP_HUMAN
--			 WHERE AMT_NEW_RETR_PAY <> 0
--			EXCEPT
--			SELECT A.EMP_NO
--				  FROM #TEMP_HUMAN A
--				  JOIN ORM_COST CC
--				    ON A.COMPANY_CD = CC.COMPANY_CD
--				   AND A.COST_CD = CC.COST_CD
--				   AND @ad_std_date BETWEEN CC.STA_YMD AND CC.END_YMD
--				  JOIN REP_ACNT_MNG AC
--				    ON A.COMPANY_CD = AC.COMPANY_CD
--				   AND CC.ACCT_CD = AC.PAY_ACNT_TYPE_CD
--				   AND AC.REP_BILL_TYPE_CD = 'E012'
--				   AND @ad_std_date BETWEEN AC.STA_YMD AND AC.END_YMD
--				 WHERE A.AMT_NEW_RETR_PAY <> 0)
--ORDER BY EMP_NO

    SET @av_ret_code    = 'SUCCESS!'   
    SET @av_ret_message = dbo.F_FRM_ERRMSG('�������� �а�ó���� �Ϸ�Ǿ����ϴ�[ERR]', @v_program_id, 9999, null, @an_mod_user_id)   
	RETURN
  ERR_HANDLER:
  
--SELECT * FROM #TEMP_HUMAN
	DEALLOCATE	PER_CUR
--	DROP TABLE #TEMP_HUMAN
	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;

    SET @av_ret_code    = 'FAILURE!'   
    SET @av_ret_message = dbo.F_FRM_ERRMSG(@v_error_message, @v_program_id, 9999, null, @an_mod_user_id)

	RETURN
END

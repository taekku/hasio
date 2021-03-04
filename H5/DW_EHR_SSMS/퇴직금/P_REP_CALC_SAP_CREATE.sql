SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_REP_CALC_SAP_CREATE] (
		@av_company_cd			nvarchar(10),		-- ȸ���ڵ�
		@av_locale_cd			nvarchar(10),		-- �����ڵ�   
		@an_rep_calc_list_id	numeric(38) ,		-- ������
		@an_mod_user_id         NUMERIC(38),		-- ������ ���
		@av_ret_code            NVARCHAR(4000)    OUTPUT, -- ����ڵ�   
		@av_ret_message         NVARCHAR(4000)    OUTPUT  -- ����޽���   
    ) AS   
   
    -- ***************************************************************************   
    --   TITLE       : ��������ǥ �а�ó��
    --   PROJECT     : E-HR �ý���   
    --   AUTHOR      :   
    --   PROGRAM_ID  : P_REP_CALC_SAP_CREATE   
    --   RETURN      : 1) SUCCESS!/FAILURE!   
    --                 2) ��� �޽���   
    --   COMMENT     : �����ݰ��    
    --   HISTORY     : 
    -- ***************************************************************************   
   
BEGIN
-- �ӽ� ���̺� ����(�����߰�� ���� ����)
--IF OBJECT_ID('tempdb..#TEMP_HUMAN') IS NOT NULL
--	DROP TABLE #TEMP_HUMAN
DECLARE @TEMP_HUMAN TABLE(
	COMPANY_CD [nvarchar](10) NULL,						--* ȸ���ڵ�
	REP_CALC_LIST_ID [numeric](38) NULL,						--* ������ID
	ORG_CD [nvarchar](10) NULL,						--* �μ��ڵ�
	EMP_NO [nvarchar](10) NULL,						--* ���
	EMP_NM [nvarchar](20) NULL,						--* ����
	POS_GRD_CD  [nvarchar](10) NULL,						--* ����
	INS_TYPE_YN [nvarchar](2) NULL,					--* ���ݰ��Կ���
	INS_TYPE_CD [nvarchar](10) NULL,				--* ��������
	C_01 [numeric](18,0) NULL,					--* ������
	CT01 [numeric](18,0) NULL, -- �����ҵ漼 
	CT02 [numeric](18,0) NULL, -- �����ֹμ� 
	PENSION_RESERVE [numeric](18,0) NULL, -- ���������� 
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
	@d_std_date					DATE,				-- ��ǥ����
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
	@v_stax_acnt_cd				NVARCHAR(20),		-- �����ڵ�-�ҵ漼
	@v_jtax_acnt_cd				NVARCHAR(20),		-- �����ڵ�-�ֹμ�
	@v_rel_cd					NVARCHAR(20),		-- ������
	@v_tmp_acnt_cd				NVARCHAR(20),		-- �����ޱݰ���
	@n_c_01						NUMERIC(18),		-- ������
	@n_ct01						NUMERIC(18),		-- �ҵ漼
	@n_ct02						NUMERIC(18),		-- �ֹμ�
	@n_pension_reserve			NUMERIC(18),		-- ����������
	@n_tmp_amt					NUMERIC(18),		-- �����ޱ�
	@v_dbcr_cd					NVARCHAR(20),		-- ���뱸��
    @v_seq                      NVARCHAR(10),			-- ��������
    @v_seq_h                    NVARCHAR(20),			-- ��ǥ��ȣ
    @v_acct_type                NVARCHAR(20) = 'E017',	-- �̰����� - ��������
    @v_pay_group                NVARCHAR(20),			-- �޿��׷�
    @v_ifc_sort                 NVARCHAR(20),			-- ��õ����
    @n_rep_calc_list_id         NUMERIC(38,0),			-- ������ID
	@v_filldt					NVARCHAR(8),
	@n_fillno					NUMERIC(18),
	@n_auto_yn					NVARCHAR(10),
	@d_auto_ymd					DATE,
	@n_auto_no					NUMERIC(18),

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
    SET @v_program_id    = 'P_REP_CALC_SAP_CREATE'   -- ���� ���ν����� ������   
    SET @v_program_nm    = '������ �а�ó��'        -- ���� ���ν����� �ѱ۹���   
    SET @av_ret_code     = 'SUCCESS!'   
    SET @av_ret_message  = dbo.F_FRM_ERRMSG('���ν��� ���� ����..', @v_program_id,  0000,  null,  @an_mod_user_id)   
PRINT('���� ===> ')   

	--//***************************************************************************
	--//*****************		 �������� �а� ó��				 **************
	--//***************************************************************************
	SELECT @d_std_date = GETDATE()
	     , @v_filldt = FILLDT
		 , @n_fillno = FILLNO
		 , @n_auto_yn = AUTO_YN
		 , @d_auto_ymd = AUTO_YMD
		 , @n_auto_no = AUTO_NO
	  FROM REP_CALC_LIST
	 WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id

	/* �Ķ���͸� ���ú����� ó���ϸ� �̶� NULL�� ��쿡 �ʿ��� ó���� �Ѵ�. */
	SET @v_dt_dian		= dbo.XF_TO_CHAR_D(@d_std_date, 'yyyyMMdd')
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
		DELETE FROM H_IF_SAPINTERFACE
		WHERE CD_COMPANY = @av_company_cd
			AND DRAW_DATE = @v_filldt					-- �̰�����
			AND SEQ = @n_fillno
			AND ACCT_TYPE = @v_acct_type
			AND ISNULL(FLAG,'N') = 'N'
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
		----------------------------------
		-- �����߰�� ����, �ӽ����̺� ����
		----------------------------------
		INSERT INTO @TEMP_HUMAN
			(COMPANY_CD, REP_CALC_LIST_ID, ORG_CD, EMP_NO, EMP_NM,
			 POS_GRD_CD, INS_TYPE_YN, INS_TYPE_CD, C_01, CT01, CT02, PENSION_RESERVE,
			 ACNT_TYPE_CD,
			 COST_CD)
		SELECT A.COMPANY_CD, A.REP_CALC_LIST_ID,
				dbo.F_FRM_ORM_ORG_NM(A.ORG_ID, 'KO', A.PAY_YMD, '10') AS ORG_CD,
				EMP.EMP_NO, EMP.EMP_NM,
				A.POS_GRD_CD, A.INS_TYPE_YN, ISNULL(A.INS_TYPE_CD,'00'),
				A.C_01, A.CT01, A.CT02, A.PENSION_RESERVE,
				@v_acct_type,
				dbo.F_PAY_GET_COST( @av_company_cd, A.EMP_ID, A.ORG_ID, @d_std_date, '1') AS COST_CD -- �ڽ�Ʈ����
		  FROM REP_CALC_LIST A
		  INNER JOIN VI_FRM_PHM_EMP EMP
				  ON A.EMP_ID = EMP.EMP_ID AND EMP.LOCALE_CD = @av_locale_cd
				 AND A.CALC_TYPE_CD IN ('01','02','04')
		 WHERE A.REP_CALC_LIST_ID = @an_rep_calc_list_id
		 print '��������ǥĿ�� ��'
		----------------------------------
		-- ��������ǥ
		----------------------------------
		DECLARE PER_CUR	CURSOR	FOR
			SELECT A.COMPANY_CD
			      ,A.REP_CALC_LIST_ID
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
				  ,A.C_01, A.CT01, A.CT02, A.PENSION_RESERVE
				  ,AC.DBCR_CD
				  ,AC.STAX_ACNT_CD
				  ,AC.JTAX_ACNT_CD
				  ,AC.TMP_ACNT_CD
				  FROM @TEMP_HUMAN A
				  JOIN ORM_COST CC
				    ON A.COMPANY_CD = CC.COMPANY_CD
				   AND A.COST_CD = CC.COST_CD
				   AND @d_std_date BETWEEN CC.STA_YMD AND CC.END_YMD
				  JOIN REP_ACNT_MNG AC
				    ON A.COMPANY_CD = AC.COMPANY_CD
				   AND CC.ACCT_CD = AC.PAY_ACNT_TYPE_CD
				   AND AC.REP_BILL_TYPE_CD = @v_acct_type
				   AND @d_std_date BETWEEN AC.STA_YMD AND AC.END_YMD
		OPEN PER_CUR
		WHILE 1=1
		BEGIN
			FETCH NEXT FROM PER_CUR INTO @v_company_code, @n_rep_calc_list_id, @v_cost_type, @v_pos_grd_cd, @v_emp_no, @v_emp_nm,
										@v_cost_cd, @v_acnt_cd, @v_rel_cd,
										@n_c_01, @n_ct01, @n_ct02, @n_pension_reserve,
										@v_dbcr_cd, @v_stax_acnt_cd, @v_jtax_acnt_cd, @v_tmp_acnt_cd
			IF @@FETCH_STATUS <> 0 BREAK
			SET @n_seqno_s = @n_seqno_s + 1
			print 'n_seqno_s:' + convert(varchar(10), @n_seqno_s)
            BEGIN TRY
				-- �����ݱݾ�
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
                                              , @v_cost_cd--dbo.XF_LPAD(@v_cost_cd, 10, '0')		-- COST_CENTER(�ڽ�Ʈ����)
                                              , @v_acnt_cd--dbo.XF_LPAD(@v_acnt_cd, 10, '0')        -- SAP_ACCTCODE(ȸ�����)
                                              , @n_c_01				 -- AMT(�ݾ�)
                                              , @v_dbcr_cd			 -- DBCR_GU(���뱸��)
                                              , @v_seq               -- SEQ(����)
                                              , @v_acct_type         -- ACCT_TYPE(�̰�����)
                                              , 'N'                  -- FLAG(FLAG)
                                              , @v_dt_gian           -- PAY_YM(�޿����)
                                              , @v_dt_dian           -- PAY_DATE(��������)
                                              , '������'           -- PAY_SUPP(���ޱ���)
                                              , ''				     -- ITEM_CODE(�����׸�)
                                              , @v_pay_group		 -- PAYGP_CODE(�޿��׷�)
                                              , @v_ifc_sort          -- IFC_SORT(��õ����)
                                              , NULL           -- SLIP_DATE(ǰ������)
                                              , '������(' + @v_acct_type + ')'   -- REMARK(���)
                                              , @an_mod_user_id      -- ID_INSERT(�Է���)
                                              , GETDATE()            -- DT_INSERT(�Է���)
                                              , @an_mod_user_id      -- ID_UPDATE(������)
                                              , GETDATE()            -- DT_UPDATE(������)
                                              , ''                 -- XNEGP(-������)
                                              , ''--dbo.XF_LPAD(@v_rel_cd, 10, '0')  -- ACCNT_CD(������)
                                              , @v_seq_h             -- SEQ_H(��ǥ��ȣ)
                                              , NULL                 -- GUBUN
                                              , @av_company_cd       -- COMPANY_CD(EHRȸ���ڵ�)
                                              , ''     -- PAY_TYPE_CD(���ޱ���)
                                              , @v_acct_type         -- PAY_ACNT_TYPE_CD(�����з�)
                                              , '������'     -- PAY_ITEM_NM(�޿��׸��)
                                              )
				-- ������ - �������ݿ���ڻ�
				-- ����������
				IF @n_pension_reserve <> 0 and @v_rel_cd > ' '
				BEGIN
					set @n_seqno_s = @n_seqno_s + 1
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
                                              , @v_cost_cd--dbo.XF_LPAD(@v_cost_cd, 10, '0')		-- COST_CENTER(�ڽ�Ʈ����)
                                              , @v_rel_cd--dbo.XF_LPAD(@v_acnt_cd, 10, '0')        -- SAP_ACCTCODE(ȸ�����)
                                              , @n_pension_reserve				 -- AMT(�ݾ�)
                                              , '50'			 -- DBCR_GU(���뱸��)
                                              , @v_seq               -- SEQ(����)
                                              , @v_acct_type         -- ACCT_TYPE(�̰�����)
                                              , 'N'                  -- FLAG(FLAG)
                                              , @v_dt_gian           -- PAY_YM(�޿����)
                                              , @v_dt_dian           -- PAY_DATE(��������)
                                              , '������'           -- PAY_SUPP(���ޱ���)
                                              , ''				     -- ITEM_CODE(�����׸�)
                                              , @v_pay_group		 -- PAYGP_CODE(�޿��׷�)
                                              , @v_ifc_sort          -- IFC_SORT(��õ����)
                                              , NULL           -- SLIP_DATE(ǰ������)
                                              , '������(' + @v_acct_type + ')'   -- REMARK(���)
                                              , @an_mod_user_id      -- ID_INSERT(�Է���)
                                              , GETDATE()            -- DT_INSERT(�Է���)
                                              , @an_mod_user_id      -- ID_UPDATE(������)
                                              , GETDATE()            -- DT_UPDATE(������)
                                              , ''                 -- XNEGP(-������)
                                              , ''--dbo.XF_LPAD(@v_rel_cd, 10, '0')  -- ACCNT_CD(������)
                                              , @v_seq_h             -- SEQ_H(��ǥ��ȣ)
                                              , NULL                 -- GUBUN
                                              , @av_company_cd       -- COMPANY_CD(EHRȸ���ڵ�)
                                              , ''     -- PAY_TYPE_CD(���ޱ���)
                                              , @v_acct_type         -- PAY_ACNT_TYPE_CD(�����з�)
                                              , '������'     -- PAY_ITEM_NM(�޿��׸��)
                                              )
				END
				-- �ҵ漼
				IF @n_ct01 <> 0
				BEGIN
					set @n_seqno_s = @n_seqno_s + 1
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
												  , @v_cost_cd--dbo.XF_LPAD(@v_cost_cd, 10, '0')		-- COST_CENTER(�ڽ�Ʈ����)
												  , @v_stax_acnt_cd--dbo.XF_LPAD(@v_acnt_cd, 10, '0')        -- SAP_ACCTCODE(ȸ�����)
												  , @n_ct01				 -- AMT(�ݾ�)
												  , '50'				 -- DBCR_GU(���뱸��)
												  , @v_seq               -- SEQ(����)
												  , @v_acct_type         -- ACCT_TYPE(�̰�����)
												  , 'N'                  -- FLAG(FLAG)
												  , @v_dt_gian           -- PAY_YM(�޿����)
												  , @v_dt_dian           -- PAY_DATE(��������)
												  , '������'           -- PAY_SUPP(���ޱ���)
												  , ''				     -- ITEM_CODE(�����׸�)
												  , @v_pay_group		 -- PAYGP_CODE(�޿��׷�)
												  , @v_ifc_sort          -- IFC_SORT(��õ����)
												  , NULL           -- SLIP_DATE(ǰ������)
												  , '������(' + @v_acct_type + ')'   -- REMARK(���)
												  , @an_mod_user_id      -- ID_INSERT(�Է���)
												  , GETDATE()            -- DT_INSERT(�Է���)
												  , @an_mod_user_id      -- ID_UPDATE(������)
												  , GETDATE()            -- DT_UPDATE(������)
												  , ''                 -- XNEGP(-������)
												  , ''--dbo.XF_LPAD(@v_rel_cd, 10, '0')  -- ACCNT_CD(������)
												  , @v_seq_h             -- SEQ_H(��ǥ��ȣ)
												  , NULL                 -- GUBUN
												  , @av_company_cd       -- COMPANY_CD(EHRȸ���ڵ�)
												  , ''     -- PAY_TYPE_CD(���ޱ���)
												  , @v_acct_type         -- PAY_ACNT_TYPE_CD(�����з�)
												  , '������'     -- PAY_ITEM_NM(�޿��׸��)
												  )
					END
				-- �ҵ漼
				IF @n_ct02 <> 0
				BEGIN
					set @n_seqno_s = @n_seqno_s + 1
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
												  , @v_cost_cd--dbo.XF_LPAD(@v_cost_cd, 10, '0')		-- COST_CENTER(�ڽ�Ʈ����)
												  , @v_jtax_acnt_cd--dbo.XF_LPAD(@v_acnt_cd, 10, '0')        -- SAP_ACCTCODE(ȸ�����)
												  , @n_ct02				 -- AMT(�ݾ�)
												  , '50'				 -- DBCR_GU(���뱸��)
												  , @v_seq               -- SEQ(����)
												  , @v_acct_type         -- ACCT_TYPE(�̰�����)
												  , 'N'                  -- FLAG(FLAG)
												  , @v_dt_gian           -- PAY_YM(�޿����)
												  , @v_dt_dian           -- PAY_DATE(��������)
												  , '������'           -- PAY_SUPP(���ޱ���)
												  , ''				     -- ITEM_CODE(�����׸�)
												  , @v_pay_group		 -- PAYGP_CODE(�޿��׷�)
												  , @v_ifc_sort          -- IFC_SORT(��õ����)
												  , NULL           -- SLIP_DATE(ǰ������)
												  , '������(' + @v_acct_type + ')'   -- REMARK(���)
												  , @an_mod_user_id      -- ID_INSERT(�Է���)
												  , GETDATE()            -- DT_INSERT(�Է���)
												  , @an_mod_user_id      -- ID_UPDATE(������)
												  , GETDATE()            -- DT_UPDATE(������)
												  , ''                 -- XNEGP(-������)
												  , ''--dbo.XF_LPAD(@v_rel_cd, 10, '0')  -- ACCNT_CD(������)
												  , @v_seq_h             -- SEQ_H(��ǥ��ȣ)
												  , NULL                 -- GUBUN
												  , @av_company_cd       -- COMPANY_CD(EHRȸ���ڵ�)
												  , ''     -- PAY_TYPE_CD(���ޱ���)
												  , @v_acct_type         -- PAY_ACNT_TYPE_CD(�����з�)
												  , '������'     -- PAY_ITEM_NM(�޿��׸��)
												  )
					END
					-- �����ޱ�(31)
					SELECT @n_tmp_amt = SUM(CASE WHEN DBCR_GU = '40' THEN AMT
					            WHEN DBCR_GU = '50' THEN -AMT
								ELSE 0 END)
					  FROM H_IF_SAPINTERFACE
					 WHERE COMPANY_CD = @av_company_cd
					   AND DRAW_DATE = @d_std_date
					   AND SEQ = @v_seq
					IF @n_tmp_amt <> 0
					BEGIN
					set @n_seqno_s = @n_seqno_s + 1
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
												  , @v_cost_cd--dbo.XF_LPAD(@v_cost_cd, 10, '0')		-- COST_CENTER(�ڽ�Ʈ����)
												  , @v_tmp_acnt_cd--dbo.XF_LPAD(@v_acnt_cd, 10, '0')        -- SAP_ACCTCODE(ȸ�����)
												  , @n_tmp_amt			 -- AMT(�ݾ�)
												  , '31'				 -- DBCR_GU(���뱸��)
												  , @v_seq               -- SEQ(����)
												  , @v_acct_type         -- ACCT_TYPE(�̰�����)
												  , 'N'                  -- FLAG(FLAG)
												  , @v_dt_gian           -- PAY_YM(�޿����)
												  , @v_dt_dian           -- PAY_DATE(��������)
												  , '������'           -- PAY_SUPP(���ޱ���)
												  , ''				     -- ITEM_CODE(�����׸�)
												  , @v_pay_group		 -- PAYGP_CODE(�޿��׷�)
												  , @v_ifc_sort          -- IFC_SORT(��õ����)
												  , NULL           -- SLIP_DATE(ǰ������)
												  , '������(' + @v_acct_type + ')'   -- REMARK(���)
												  , @an_mod_user_id      -- ID_INSERT(�Է���)
												  , GETDATE()            -- DT_INSERT(�Է���)
												  , @an_mod_user_id      -- ID_UPDATE(������)
												  , GETDATE()            -- DT_UPDATE(������)
												  , ''                 -- XNEGP(-������)
												  , ''--dbo.XF_LPAD(@v_rel_cd, 10, '0')  -- ACCNT_CD(������)
												  , @v_seq_h             -- SEQ_H(��ǥ��ȣ)
												  , NULL                 -- GUBUN
												  , @av_company_cd       -- COMPANY_CD(EHRȸ���ڵ�)
												  , ''     -- PAY_TYPE_CD(���ޱ���)
												  , @v_acct_type         -- PAY_ACNT_TYPE_CD(�����з�)
												  , '������'     -- PAY_ITEM_NM(�޿��׸��)
												  )
					END

					UPDATE REP_CALC_LIST
					   SET FILLDT = FORMAT(@d_std_date, 'yyyyMMdd')
					     , FILLNO = @v_seq
						 , AUTO_YN = 'Y'
						 , AUTO_YMD = @d_std_date
						 , AUTO_NO = @v_seq
					 WHERE REP_CALC_LIST_ID = @n_rep_calc_list_id
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

PRINT('<<===== P_REP_CALC_SAP_CREATE END')   
   -- ***********************************************************   
   -- �۾� �Ϸ�   
   -- ***********************************************************   
--SELECT dbo.F_FRM_CODE_NM( A.COMPANY_CD, @av_locale_cd, 'PHM_POS_GRD_CD', A.POS_GRD_CD, dbo.XF_SYSDATE(0), '1') AS POS_GRD_NM, -- ����
--	A.*
--  FROM @TEMP_HUMAN A
-- WHERE A.AMT_NEW_RETR_PAY <> 0
--   AND EMP_NO IN (SELECT EMP_NO
--			  FROM @TEMP_HUMAN
--			 WHERE AMT_NEW_RETR_PAY <> 0
--			EXCEPT
--			SELECT A.EMP_NO
--				  FROM @TEMP_HUMAN A
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
    SET @av_ret_message = dbo.F_FRM_ERRMSG('������ �а�ó���� �Ϸ�Ǿ����ϴ�[ERR]', @v_program_id, 9999, null, @an_mod_user_id)   
	RETURN
  ERR_HANDLER:
  
--SELECT * FROM @TEMP_HUMAN
	DEALLOCATE	PER_CUR
--	DROP TABLE @TEMP_HUMAN
	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;

    SET @av_ret_code    = 'FAILURE!'   
    SET @av_ret_message = dbo.F_FRM_ERRMSG(@v_error_message, @v_program_id, 9999, null, @an_mod_user_id)

	RETURN
END

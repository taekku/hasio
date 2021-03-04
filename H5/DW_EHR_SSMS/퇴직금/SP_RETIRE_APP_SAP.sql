USE [dwehrdev]
GO
/****** Object:  StoredProcedure [dbo].[SP_RETIRE_APP_SAP]    Script Date: 2020-11-30 ���� 3:11:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Create date: <Create Date,,2014.04>
-- Description:	<Description,,�������� �а�ó�� >
-- 
-- =============================================
/* Execute Sample
H_ERRORLOG

 DECLARE 
      @p_error_code VARCHAR(30), 
      @p_error_str VARCHAR(500) 
 BEGIN
      SET @p_error_code = ''; 
      SET @p_error_str = ''; 
      EXECUTE SP_SAPFI_IF_RETRAPP
      'I',
      '20100131',
      '',
      '',
      '',
      'newikim',
      @p_error_code OUTPUT,		-- @p_error_code      VARCHAR(30) 
      @p_error_str OUTPUT 		-- @p_error_str       VARCHAR(500) 
 END
          --  @P_retr_annu       VARCHAR(10),                       -- ��������
                           --   @p_tp_duty         VARCHAR(2),                        -- ��������
                          --    @p_fr_Dept         VARCHAR(10),                       -- �μ��ڵ�(From)
                          --    @p_to_Dept         VARCHAR(10),                       -- �μ��ڵ�(To)
*/
ALTER PROCEDURE [dbo].[SP_RETIRE_APP_SAP] (
							  @p_cd_company		 VARCHAR(10),						-- ȸ���ڵ�
							  @p_dt_gian		 VARCHAR(8) ,						-- ǰ������
                              @p_pay_group		 VARCHAR(10),						-- �޿��׷�
                              @p_cd_biz_area	 VARCHAR(10),						-- �����
                              @p_cd_person       VARCHAR(10),                       -- ���
							  @p_id_user		 VARCHAR(20) ,						-- �����ID
                              @p_error_code      VARCHAR(1000) OUTPUT,				-- �����ڵ� ����
                              @p_error_str       VARCHAR(3000) OUTPUT				-- �����޽��� ����
                              )                                                                              
AS
SET NOCOUNT ON
-- �ӽ� ���̺� ����(�����߰�� ���� ����)
--DROP TABLE #TEMP_HUMAN
CREATE TABLE #TEMP_HUMAN
	(
	CD_COMPANY [nvarchar](10) NULL,						--* ȸ���ڵ�
	CD_DEPT [nvarchar](10) NULL,						--* �μ��ڵ�
	NO_PERSON [nvarchar](10) NULL,						--* ���
	NM_PERSON [nvarchar](20) NULL,						--* ����
	--LVL_PAY1  [nvarchar](10) NULL,						--* ����
	--YN_RETPENSION [nvarchar](2) NULL,					--* ���ݰ��Կ���
	TP_DUTY [nvarchar](2) NULL,					--* ��������
	FG_RETPENSION_KIND [nvarchar](10) NULL,				--* ��������
	AMT_RETR_PAY [numeric](18,0) NULL,					--* ����
	ACCT_GU [nvarchar](10) NULL,						--* ��������
	CD_CC [nvarchar](10) NULL,							--* �ڽ�Ʈ����
    PAY_GROUP [nvarchar](10) NULL						--* �޿��׷�
)

DECLARE
   /* ���ν��� ������ ����� ���� ����  */
	@v_cd_company				VARCHAR(10),										-- ȸ���ڵ�
	@v_cd_dept					VARCHAR(20),										-- �μ��ڵ�
	@v_no_person				VARCHAR(10),										-- ���
	@v_nm_person				VARCHAR(20),										-- ����
	@v_yn_retpension			VARCHAR(1), 										-- ���ݰ��Կ���
	@v_fg_retpension_kind		VARCHAR(10),										-- ��������
	@v_amt_retr_pay				NUMERIC(18,0),										-- ����
	@v_fg_drcr					VARCHAR(4),											-- ��/�뺯
    @v_cd_accnt_dr              VARCHAR(20),										-- �����ڵ�(����)
    @v_cd_accnt_cr              VARCHAR(20),										-- �����ڵ�(������)
	@v_cd_accnt1				VARCHAR(20),										-- �����ڵ�(���ݹ̰�����)
	@v_cd_accnt2				VARCHAR(20),										-- �����ڵ�(���ݹ̰�����-������)
	@v_cd_accnt3				VARCHAR(20),										-- �����ڵ�(����DB��������)
	@v_cd_accnt4				VARCHAR(20),										-- �����ڵ�(����DB��������-������)
	@v_cd_accnt5				VARCHAR(20),										-- �����ڵ�(����DC��������)
	@v_cd_accnt6				VARCHAR(20),										-- �����ڵ�(����DC��������-������)
    @v_acct_gu					VARCHAR(10),										-- ��������
    @v_cd_cc                    VARCHAR(20),										-- �ڽ�Ʈ����
    @v_pay_group                VARCHAR(10),                                        -- �޿��׷�
    @v_tp_duty                  VARCHAR(2),                                        -- ��������


	--@v_id_user					VARCHAR(20),										-- �����ID
    @v_dt_gian					VARCHAR(6) ,										-- �޿���� PK : 1	
	@v_auto_sno					VARCHAR(20) ,
	--@p_dt_gian					VARCHAR(8) ,			-- ǰ������
	@v_seq						NUMERIC(18,0),			-- ���� numeric
	@v_str_seq					VARCHAR(10),			-- ���� varchar

	@v_seq_h					VARCHAR(10),		-- SEQNO_S dp�� �� ��
    @v_gsbers					VARCHAR(20),		-- ����ι�
	@v_zposn_s					VARCHAR(10),		-- ����
	@v_slip_nbr					VARCHAR(20),

	@v_rsn_paygp_where			VARCHAR(MAX),
	@v_sql						VARCHAR(MAX),

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

	DECLARE @BUKRS char(4);   --sap ȸ���ڵ�
    DECLARE @MSEQ INT;


BEGIN TRY
	/* ������ ���� �ʱ�ȭ ó�� */
	SET @v_error_code = '';
	SET @v_error_note = '';
	SET @v_seq_h	  = 0;

	/* �Ķ���͸� ���ú����� ó���ϸ� �̶� NULL�� ��쿡 �ʿ��� ó���� �Ѵ�. */
	
	--select DATEADD(MONTH, 1,LEFT(@p_dt_gian,6)+'01') - DAY(LEFT(@p_dt_gian,6)+'01')
	--SET @p_dt_gian = convert(varchar(8),DATEADD(MONTH, 1,@p_dt_gian+'01') - DAY(@p_dt_gian+'01') ,112)
	
	--SET @v_dt_gian      = left(@p_dt_gian,6);
	--SET @v_id_user		= @p_id_user;		-- �α��λ����
	--print @p_dt_gian
	--print @p_dt_gian
	IF @p_cd_company IN ('A','B','C','H')
		RETURN;
	

	set @BUKRS = case @p_cd_company when 'E' then 'ET02' when 'Q' then 'DA01' when 'J' then 'SJ01' when 'M' then 'NS01' when 'I' then 'DR01'
		when 'S' then 'FS01' when 'Y' then 'DY01'  when 'O' then 'OL01' when 'L' then 'DWCS' when 'Z' then 'DY01'  
	 else @p_cd_company end;

	-- ����TABLE����
	DELETE FROM H_ERRORLOG
	WHERE CD_COMPANY = @p_cd_company
	AND ERROR_PROCEDURE = 'SP_SAPFI_IF_RETRAPP'

	--------------------------------------------------------------------------------------------------------------------
	-- Message Setting Block 
	--------------------------------------------------------------------------------------------------------------------      
	/* ���� �߻��� ���� �ڵ鷯�� �б� ó�� */ 
	IF @@error <> 0
	BEGIN
		SET @v_error_number = @@error;
		SET @v_error_code = 'SP_SAPFI_IF_RETRAPP';
		SET @v_error_note = '����TABLE���� �� ������ �߻��Ͽ����ϴ�.'
		GOTO ERR_HANDLER
	END

	--//***************************************************************************
	--//*****************		 �������� �а� ó��				 **************
	--//***************************************************************************
	BEGIN
		
	
		DELETE FROM FIIF_F02_ZFITPA01
		WHERE BUKRS = @BUKRS AND PAYDT = @p_dt_gian AND GUBUN = 'E012'+@p_pay_group AND DFLAG = 'N'
		
		
		
		--SELECT * FROM FIIF_F02_ZFITPA01 WHERE BUKRS='DR01' AND PAYDT='20140630' AND GUBUN = 'E012' AND DFLAG = 'N'
	
		---- SAP I/F ���̺� ����
		--if @p_pay_group = ''
		--	begin
		--		DELETE FROM FIIF_F02_ZFITPA01
		--		WHERE CD_COMPANY = @p_cd_company
		--		  AND DRAW_DATE = @p_dt_gian					-- �̰�����		
		--		  AND ACCT_TYPE = 'E012'	
		--		  AND FLAG = 'N'	
		--	end
		--else
		--	begin
		--		DELETE FROM FIIF_F02_ZFITPA01
		--		WHERE CD_COMPANY = @p_cd_company
		--		  AND DRAW_DATE = @p_dt_gian					-- �̰�����		
		--		  AND ACCT_TYPE = 'E012'
  --                AND PAYGP_CODE = @p_pay_group		
		--		  AND FLAG = 'N'	
		--	end
	
		----------------------------------------------------------------------------------------------------------------------
		---- Message Setting Block 
		----------------------------------------------------------------------------------------------------------------------      
		/* ���� �߻��� ���� �ڵ鷯�� �б� ó�� */ 
		IF @@error <> 0
		BEGIN
			SET @v_error_number = @@error;
			SET @v_error_code = 'SP_SAPFI_IF_RETRAPP';
			SET @v_error_note = 'H_IF_SAPINTERFACE TABLE ���� ���� �� ������ �߻��Ͽ����ϴ�.'
			GOTO ERR_HANDLER
		END

		-- �޿��׷� ���� ��������
		IF @p_pay_group <> '' AND @p_cd_company <> 'I'
			BEGIN
				SELECT @v_rsn_paygp_where = (CASE WHEN ISNULL(LTRIM(H_PAY_GROUP.RSN_PAYGP_WHERE),'') = '' THEN '' ELSE LTRIM(H_PAY_GROUP.RSN_PAYGP_WHERE) END)
				FROM H_PAY_GROUP WITH(NOLOCK)
				WHERE H_PAY_GROUP.CD_COMPANY = @p_cd_company
				AND H_PAY_GROUP.CD_PAYGP = @p_pay_group;
			END 

		-- �����߰�� ����, �ӽ����̺� ����
		SET @v_sql = '';
		-- �ణ���� 
		SET @v_sql = ' INSERT INTO #TEMP_HUMAN ' + CHAR(13)
		
		SET @v_sql = @v_sql + ' SELECT A.CD_COMPANY ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,A.CD_DEPT ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,A.NO_PERSON ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,A.NM_PERSON ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  ,A.TP_DUTY ' + CHAR(13) 
				
		SET @v_sql = @v_sql + ' 		  ,C.CD_RETR_ANNU, ' + CHAR(13)			--��������
		SET @v_sql = @v_sql + '           A.AMT_NEW_RETR_PAY,  ' + CHAR(13)		--������Ծ�
		SET @v_sql = @v_sql + '           F.FG_ACCT AS ACCT_GU,  ' + CHAR(13)
		SET @v_sql = @v_sql + ' 		  A.CD_COST AS CD_CC, ' + CHAR(13)
	--	SET @v_sql = @v_sql + ' 		  ISNULL(C.CD_PAYGP,'''')  AS PAY_GROUP ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 		  '''+@p_pay_group+'''  AS PAY_GROUP ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 	FROM H_RETIRE_APP A WITH(NOLOCK) ' + CHAR(13)  
		SET @v_sql = @v_sql + ' 		  INNER JOIN H_HUMAN WITH(NOLOCK) ON ( A.CD_COMPANY = H_HUMAN.CD_COMPANY AND A.NO_PERSON = H_HUMAN.NO_PERSON ) ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 		  INNER JOIN H_PAY_MASTER C WITH(NOLOCK) ON ( A.CD_COMPANY = C.CD_COMPANY AND A.NO_PERSON = C.NO_PERSON ) ' + CHAR(13) 
	--	SET @v_sql = @v_sql + ' 		  left outer join H_PER_MATCH D on D.CD_COMPANY = A.CD_COMPANY AND D.NO_PERSON = A.NO_PERSON ' + CHAR(13) 
		SET @v_sql = @v_sql + ' 		  left outer join B_COST_CENTER F on A.CD_COMPANY = F.CD_COMPANY AND A.CD_COST = F.CD_CC ' + CHAR(13) 
	
		SET @v_sql = @v_sql + ' 	WHERE A.CD_COMPANY = ''' +  @p_cd_company + '''' + CHAR(13)
		SET @v_sql = @v_sql + ' 	  AND A.DT_BASE = ''' + @p_dt_gian + '''' + CHAR(13)

		IF @v_rsn_paygp_where <> ''-- �޿��׷�
			SET @v_sql = @v_sql + ' 	  AND ' + @v_rsn_paygp_where + '' + CHAR(13)
		IF @p_cd_biz_area <> ''-- �����
			SET @v_sql = @v_sql + ' 	  AND H_HUMAN.CD_BIZ_AREA = ''' + @p_cd_biz_area + '''' + CHAR(13)
		IF @p_cd_person <> ''-- ���
			SET @v_sql = @v_sql + ' 	  AND A.NO_PERSON = ''' + @p_cd_person + '''' + CHAR(13)
		
		IF @p_pay_group <> '' AND @p_cd_company = 'I'
		BEGIN
			IF @p_pay_group = 'A'
				SET @v_sql = @v_sql +'
				and A.TP_DUTY in (''A'',''8'') AND A.CD_DEPT NOT LIKE ''5%'' ';
			ELSE IF @p_pay_group = 'B'  
				SET @v_sql = @v_sql +'
				and (A.TP_DUTY = ''B'' OR ( A.CD_DEPT LIKE ''5%'' AND A.TP_DUTY =''A'')) ';
			ELSE
				SET @v_sql = @v_sql +'
				and A.TP_DUTY = '''+@p_pay_group+'''';
		END				
			
		
		print (@v_sql)
		EXEC(@v_sql);


		IF EXISTS(SELECT 1 FROM #TEMP_HUMAN WHERE CD_CC = '')
		begin
			raiserror ('�ڽ�Ʈ���Ͱ� ������ ����� �ֽ��ϴ�.',11,1);
			return;
		end
		
--/* ��ǥ��ȣ ������ ���� ã�ƿ��� �κ�*/
---- �����ϱ������� �����Ѵ�.
--SELECT @MSEQ = MAX(cast(SEQNO as int))
--FROM FIIF_F02_ZFITPA01
--WHERE BUKRS = @BUKRS
--AND PAYDT = @P_DT_GIAN;

--select @MSEQ = isnull(@MSEQ,0) + 1;

--select * from H_IF_SAPINTERFACE where cd_company='c' and acct_type='e012'
--select * from FIIF_F02_ZFITPA01 where bukrs='DR01' AND PAYDT='20140531'


--select @MSEQ;


--print 1
		-- ������ �����߰���� �̿��Ͽ� �������� ����
		DECLARE	PER_CUR	CURSOR	FOR
			SELECT CD_COMPANY
				  ,CD_DEPT
				  ,NO_PERSON
				  ,NM_PERSON
				--  ,LVL_PAY1
				--  ,YN_RETPENSION	
				  ,TP_DUTY
				  ,FG_RETPENSION_KIND
				  ,AMT_RETR_PAY
                  ,ACCT_GU
				  ,ISNULL(CD_CC,'')
                  ,PAY_GROUP                  
			FROM #TEMP_HUMAN
            WHERE AMT_RETR_PAY <> 0
			OPEN	PER_CUR

			-- Ŀ�� ��ġ
			FETCH	NEXT	FROM	PER_CUR	INTO		@v_cd_company,
														@v_cd_dept,
														@v_no_person,
														@v_nm_person,
													--	@v_zposn_s,
													--	@v_yn_retpension,
													    @v_tp_duty,
														@v_fg_retpension_kind,
														@v_amt_retr_pay,
                                                        @v_acct_gu,
                                                        @v_cd_cc,
                                                        @v_pay_group
				-- ���κ� ó��
				WHILE	@@fetch_status	=	0

				BEGIN
					-------------------------------------------------------------------------------------------------------------------
					--  �� �� �� ǥ ó�� SELECT * FROM H_ACCNT_MATRIX_2 WHERE CD_COMPANY='I' AND CD_ITEM='E012'
					--FG_ACCNT : 51,81,86,87, 82
				
					--SELECT * FROM H_ACCNT_PAY_ITEM_2 WHERE CD_COMPANY='I'
					-------------------------------------------------------------------------------------------------------------------
					SET @v_fg_drcr = '';
					SET @v_cd_accnt1 = '';
					SET @v_cd_accnt2 = '';
					SET @v_cd_accnt3 = '';
					SET @v_cd_accnt4 = '';
					SET @v_cd_accnt5 = '';
					SET @v_cd_accnt6 = '';

					SELECT @v_fg_drcr = FG_DRCR
                          ,@v_cd_accnt1 = ISNULL(CD_ACCNT1,''), @v_cd_accnt2 = ISNULL(CD_ACCNT2,'')	-- ���ݹ̰�����
                          ,@v_cd_accnt3 = ISNULL(CD_ACCNT3,''), @v_cd_accnt4 = ISNULL(CD_ACCNT4,'')	-- DB��
                          ,@v_cd_accnt5 = ISNULL(CD_ACCNT5,''), @v_cd_accnt6 = ISNULL(CD_ACCNT6,'')	-- DC��
					FROM H_ACCNT_MATRIX_2
					WHERE CD_COMPANY = @v_cd_company
                      AND FG_ACCNT = @v_acct_gu
                      AND CD_ITEM = 'E012'

					BEGIN
						-- ���ݰ��Կ���(�̰���/DB/DC)							
						if @v_fg_retpension_kind = 'DB'			-- DB��
							begin
								set @v_cd_accnt_dr = @v_cd_accnt3	-- SAP �����ڵ忡
								set @v_cd_accnt_cr = @v_cd_accnt4
							end
						else if @v_fg_retpension_kind = 'DC'	-- DC��
							begin
								set @v_cd_accnt_dr = @v_cd_accnt5
								set @v_cd_accnt_cr = @v_cd_accnt6
							end
						else									-- �̰���
							begin
								set @v_cd_accnt_dr = @v_cd_accnt1
								set @v_cd_accnt_cr = @v_cd_accnt2
							end

						IF @v_cd_accnt_dr = '00'
							begin
								set @v_cd_accnt_dr = '00000000'
								set @v_cd_accnt_cr = '22030100'
								set @v_fg_drcr = '40'
							end
						
						SELECT @v_gsbers = BIZ_ACCT 
						  FROM B_COST_CENTER 
						 WHERE CD_COMPANY = @v_cd_company
						   AND CD_CC = @v_cd_cc -- �������
						
						--SET @v_cd_cc = RIGHT('0000000000' + @v_cd_cc,10)
						
						
						SET @v_seq_h = @v_seq_h + 1 
						
						--����/����A + ����8
						if @v_tp_duty = '8' 
							select @v_tp_duty ='A'
							--�λ���� -> ����B
						ELSE IF @v_tp_duty = 'A' AND @v_cd_dept LIKE '5%'
							select @v_tp_duty ='B'
							
											
							

						INSERT INTO FIIF_F02_ZFITPA01(
													BUKRS,PAYDT,SEQNO,EMPNO,KOSTL,HKONT,
													PABTR,BSCHL,BKTXT,GUBUN,ITCODE,GJAHR,
													BELNR,DFLAG,CHUSER,CHDATE
													)
						VALUES(@BUKRS, @p_dt_gian , @v_seq_h,@v_cd_company+@v_no_person, @v_cd_cc, @v_cd_accnt_dr,
								@v_amt_retr_pay, @v_fg_drcr,'��������('+@v_nm_person+')', 'E012'+@v_tp_duty, '', '',
								'', 'N', @p_id_user, CONVERT(VARCHAR(8),getdate(),112)
						)--@v_cd_accnt_cr
						
						--SET @MSEQ = @MSEQ + 1;
						
						
						/* ���� �߻��� ���� �ڵ鷯�� �б� ó�� */ 
						IF @@error <> 0
						BEGIN
							SET @v_error_number = @@error;
							SET @v_error_code = 'SP_SAPFI_IF_RETRAPP';
							SET @v_error_note = 'H_IF_SAPINTERFACE TABLE ���� ���� �� ������ �߻��Ͽ����ϴ�.'
							GOTO ERR_HANDLER
						END
					END

					------------------------------------------------------------------------------------------------------------------
					-- Message Setting Block 
					------------------------------------------------------------------------------------------------------------------      
					/* ���� �߻��� ���� �ڵ鷯�� �б� ó�� */ 
					IF @@error <> 0
					BEGIN
						SET @v_error_number = @@error;
						SET @v_error_code = 'SP_SAPFI_IF_RETRAPP';
						SET @v_error_note = 'H_IF_SAPINTERFACE TABLE ���� ���� �� ������ �߻��Ͽ����ϴ�.'
						GOTO ERR_HANDLER
					END


					-- ���� Ŀ�� ��ġ
					FETCH	NEXT	FROM	PER_CUR INTO	@v_cd_company,
															@v_cd_dept,
															@v_no_person,
															@v_nm_person,
														--	@v_zposn_s,
														--	@v_yn_retpension,
															@v_tp_duty,
															@v_fg_retpension_kind,
															@v_amt_retr_pay,
                                                            @v_acct_gu,
                                                            @v_cd_cc,
                                                            @v_pay_group
				END

				--SET @v_seq_h = @v_seq_h + 1 
				--@v_seq_h + RANK() OVER (ORDER BY SUM(PABTR) ASC)	
				
				
				INSERT INTO FIIF_F02_ZFITPA01(
											BUKRS,PAYDT,SEQNO,
											EMPNO,KOSTL,HKONT,
											PABTR,BSCHL,BKTXT,GUBUN,ITCODE,GJAHR,
											BELNR,DFLAG,CHUSER,CHDATE
											)
				 SELECT @BUKRS, @p_dt_gian, 10000- RANK() OVER (ORDER BY SUM(PABTR) DESC),
						'999999999','0000',@v_cd_accnt_cr, 
						SUM(PABTR), '50','��������('+GUBUN+')-����',GUBUN,'','',
						'','N',@p_id_user, CONVERT(VARCHAR(8),getdate(),112)
				FROM FIIF_F02_ZFITPA01 
				WHERE GUBUN = 'E012'+@v_tp_duty
					AND BUKRS = @BUKRS
					AND PAYDT = @p_dt_gian
					
				GROUP BY GUBUN 
				
				
				--select * from SAPIF_I..DWTEMP.FIIF_F02_ZFITPA01 where bukrs='DR01' and paydt='20140401' and gubun='e012'
				
				

			-- Ŭ����
			CLOSE	PER_CUR
			-- Ŀ�� ����
			DEALLOCATE	PER_CUR
			-- �ӽ����̺� ����
			DROP TABLE #TEMP_HUMAN
	END

	RETURN			/* �� */
	
  -----------------------------------------------------------------------------------------------------------------------
  -- END Message Setting Block 
  ----------------------------------------------------------------------------------------------------------------------- 
  ERR_HANDLER:

	DEALLOCATE	PER_CUR
	DROP TABLE #TEMP_HUMAN

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;

	EXECUTE p_ba_errlib_getusererrormsg @v_cd_company, 'SP_SAPFI_IF_RETRAPP',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

	RETURN
END TRY

  ----------------------------------------------------------------------------------------------------------------------- 
  -- Error CATCH Process Block 
  ----------------------------------------------------------------------------------------------------------------------- 
BEGIN CATCH

	DEALLOCATE	PER_CUR
	DROP TABLE #TEMP_HUMAN

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line =  ERROR_LINE();
	SET @v_error_message = ERROR_MESSAGE()+ ' ' + @v_error_note;
select @v_error_message
	--EXECUTE p_ba_errlib_getusererrormsg @v_cd_company, 'SP_SAPFI_IF_RETRAPP',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

	RETURN
END CATCH
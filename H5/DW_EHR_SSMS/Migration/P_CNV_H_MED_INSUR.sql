SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Conversion �ǰ�����/���ο���
-- �ǰ�����/���ο��� ���ε� --> �ǰϺ��谡������
                        --> ���ο��ݰ�������
-- =============================================
CREATE OR ALTER PROCEDURE P_CNV_H_MED_INSUR
      @an_try_no         NUMERIC(4)       -- �õ�ȸ��
    , @av_company_cd     NVARCHAR(10)     -- ȸ���ڵ�
    , @av_fg_insur	     NVARCHAR(10)     -- ����(1)/�ǰ�(2)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @s_company_cd nvarchar(10)
	      , @t_company_cd nvarchar(10)
		  -- ��ȯ�۾����
		  , @v_proc_nm   nvarchar(50) -- ���α׷�ID
		  , @v_pgm_title nvarchar(100) -- ���α׷�Title
		  , @v_params       nvarchar(4000) -- �Ķ����
		  , @n_total_record numeric
		  , @n_cnt_success  numeric
		  , @n_cnt_failure  numeric
		  , @v_s_table      nvarchar(50) -- source table
		  , @v_t_table      nvarchar(50) -- target table
		  , @n_log_h_id		  numeric
		  , @v_keys			nvarchar(2000)
		  , @n_err_cod		numeric
		  , @v_err_msg		nvarchar(4000)
		  -- AS-IS Table Key
		  , @cd_company   nvarchar(20) -- ȸ���ڵ�
		  , @fg_insur		nvarchar(20) -- 
		  , @init_ym_insur		nvarchar(20)
		  , @ym_insur		nvarchar(20)
		  , @no_person		nvarchar(20)
		  -- ��������
		  , @emp_id			numeric -- ���ID
		  , @person_id		numeric -- ����ID
		  , @hire_ymd		date
		  , @insert_ok		numeric

	set @v_proc_nm = OBJECT_NAME(@@PROCID) -- ���α׷���

	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================
	set @v_pgm_title = '�ǰ�����/���ο���'
	-- �Ķ���͸� ��ħ(�α����Ͽ� ����ϱ� ���ؼ�..)
	set @v_params = CONVERT(nvarchar(100), @an_try_no)
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_company_cd),'NULL')
				+ ',' + ISNULL(CONVERT(nvarchar(100), @av_fg_insur),'NULL')
	set @v_s_table = 'H_MED_INSUR'   -- As-Is Table
	IF @av_fg_insur = '1'
		begin
			set @v_pgm_title = '���ο��ݰ�������'
			set @v_t_table = 'STP_JOIN_INFO' -- To-Be Table(���ο��ݰ�������)
		end
	else
		begin
			set @v_pgm_title = '�ǰ����谡������'
			set @v_t_table = 'NHS_JOIN_INFO' -- To-Be Table(�ǰ����谡������)
		end
	-- =============================================
	-- ��ȯ���α׷�����
	-- =============================================

	set @n_total_record = 0
	set @n_cnt_failure = 0
	set @n_cnt_success = 0
	
	-- Conversion�α����� Header
	EXEC @n_log_h_id = dbo.P_CNV_PAY_LOG_H 0, 'S', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table
	
	-- =============================================
	--   As-Is Key Column Select
	--   Source Table Key
	-- =============================================
    DECLARE CNV_CUR CURSOR READ_ONLY FOR
		SELECT CD_COMPANY
				 , FG_INSUR
				 , MIN(YM_INSUR) AS INIT_YM_INSUR
				 , MAX(YM_INSUR) AS YM_INSUR
				 , NO_PERSON
			  FROM dwehrdev.dbo.H_MED_INSUR
			 WHERE CD_COMPANY LIKE ISNULL(@av_company_cd,'') + '%'
			   AND FG_INSUR = @av_fg_insur -- > ���ο���
			 GROUP BY CD_COMPANY, FG_INSUR, NO_PERSON
	-- =============================================
	--   As-Is Key Column Select
	-- =============================================
	OPEN CNV_CUR

	WHILE 1 = 1
		BEGIN
			-- =============================================
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			FETCH NEXT FROM CNV_CUR
			      INTO @cd_company
				     , @fg_insur, @init_ym_insur, @ym_insur, @no_person
			-- =============================================
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				set @n_total_record = @n_total_record + 1 -- �� �Ǽ�Ȯ��
				set @s_company_cd = @cd_company -- AS-IS ȸ���ڵ�
				set @t_company_cd = UPPER(@cd_company) -- TO-BE ȸ���ڵ�
				
				-- =======================================================
				--  EMP_ID ã��
				-- =======================================================
				SELECT @emp_id = EMP_ID, @person_id = PERSON_ID, @hire_ymd = STA_YMD
				  FROM PHM_EMP_NO_HIS
				 WHERE COMPANY_CD = @cd_company
				   AND EMP_NO = @no_person
				IF @@ROWCOUNT < 1
					BEGIN
						-- *** �α׿� ���� �޽��� ���� ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @cd_company),'NULL')
							  + ',no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = 'PHM_EMP_NO_HIS���� ����� ã�� �� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
						CONTINUE;
					END
				-- =======================================================
				--  To-Be Table Insert Start
				-- =======================================================
				IF @fg_insur = '1' -- ���ο���
					begin
						INSERT INTO dwehrdev_H5.dbo.STP_JOIN_INFO(
								STP_JOIN_INFO_ID, --	���ο��ݰ�������ID
								EMP_ID, --	���ID
								REPORT_TYPE, --	�Ű���[STP_STAT_TYPE_CD]
								STA_YMD, --	��������
								END_YMD, --	��������
								SUB_COMPANY_CD, --	����ȸ���ڵ�
								REPORT_YMD, --	���Ű���
								REPORT_CD, --	�������ο���(STP_REPORT_CD)
								CAUSE_CD, --	������ȣ
								NATION_CD, --	�����ڵ�[STP_NATIVE_TYPE_CD)
								STAY_CD, --	�ܱ���ü���ڰ�[STP_STAY_CAPA_CD]
								SIN_YN, --	�Ű���
								STAND_AMT, --	��������
								INSU_AMT, --	�����
								SPECIAL_CD, --	Ư��������ȣ[STP_SPEC_TYPE_CD]
								EXCEP_CD, --	���ο��ܺ�ȣ(STP_EXCE_CD)
								EXP_YMD, --	����(�簳)������
								RE_STA_YMD, --	�����簳������
								STATUS, --	���λ���[STP_SUBT_TYPE_CD]
								RATE, --	������
								NOTE,--	���
								MOD_USER_ID, --	������
								MOD_DATE, --	�����Ͻ�
								TZ_CD, --	Ÿ�����ڵ�
								TZ_DATE  --	Ÿ�����Ͻ�
							   )
						SELECT NEXT VALUE FOR S_STP_SEQUENCE as STP_JOIN_INFO_ID, --	���ο��ݰ�������ID
								@emp_id	EMP_ID, --	���ID
								'01' REPORT_TYPE, --	�Ű���[STP_STAT_TYPE_CD] '01':���
								@hire_ymd, --(SELECT HIRE_YMD FROM PHM_EMP WHERE EMP_ID=@emp_id), -- ��������
								case  when @init_ym_insur < @ym_insur then
										dbo.XF_DATEADD( dbo.XF_TO_DATE(@ym_insur + '01', 'yyyymmdd') , -1)
									  else
										dbo.XF_TO_DATE('29991231','yyyymmdd') end END_YMD, --	��������
								'' SUB_COMPANY_CD, --	����ȸ���ڵ�
								@hire_ymd, --(SELECT HIRE_YMD FROM PHM_EMP WHERE EMP_ID=@emp_id) REPORT_YMD, --	���Ű���
								'1' REPORT_CD, --	�������ο���(STP_REPORT_CD) 1:���
								NULL CAUSE_CD, --	������ȣ
								'1' NATION_CD, --	�����ڵ�[STP_NATIVE_TYPE_CD) 1:������, 9:�ܱ���
								NULL	STAY_CD, --	�ܱ���ü���ڰ�[STP_STAY_CAPA_CD]
								'Y'	SIN_YN, --	�Ű���
								AMT_STANDARD	STAND_AMT, --	��������
								AMT_INSUR	INSU_AMT, --	�����
								NULL	SPECIAL_CD, --	Ư��������ȣ[STP_SPEC_TYPE_CD]
								NULL	EXCEP_CD, --	���ο��ܺ�ȣ(STP_EXCE_CD)
								NULL	EXP_YMD, --	����(�簳)������
								NULL	RE_STA_YMD, --	�����簳������
								'01'	STATUS, --	���λ���[STP_SUBT_TYPE_CD] 01:����, 02:������, 03:����
								100 RATE-- RATE_INSUR	RATE --	������
								,  REM_COMMENT
								, 0 AS MOD_USER_ID
								, ISNULL(DT_UPDATE,'1900-01-01')
								, 'KST'
								, ISNULL(DT_UPDATE,'1900-01-01')
						  FROM dwehrdev.dbo.H_MED_INSUR A
						 WHERE CD_COMPANY = @s_company_cd
						   AND FG_INSUR = @fg_insur
						   AND YM_INSUR = @init_ym_insur
						   AND NO_PERSON = @no_person
						IF @@ROWCOUNT > 0
							set @insert_ok = 1
						ELSE
							set @insert_ok = 0

						IF @init_ym_insur < @ym_insur
							BEGIN
								-- ����
								INSERT INTO dwehrdev_H5.dbo.STP_JOIN_INFO(
										STP_JOIN_INFO_ID, --	���ο��ݰ�������ID
										EMP_ID, --	���ID
										REPORT_TYPE, --	�Ű���[STP_STAT_TYPE_CD]
										STA_YMD, --	��������
										END_YMD, --	��������
										SUB_COMPANY_CD, --	����ȸ���ڵ�
										REPORT_YMD, --	���Ű���
										REPORT_CD, --	�������ο���(STP_REPORT_CD)
										CAUSE_CD, --	������ȣ
										NATION_CD, --	�����ڵ�[STP_NATIVE_TYPE_CD)
										STAY_CD, --	�ܱ���ü���ڰ�[STP_STAY_CAPA_CD]
										SIN_YN, --	�Ű���
										STAND_AMT, --	��������
										INSU_AMT, --	�����
										SPECIAL_CD, --	Ư��������ȣ[STP_SPEC_TYPE_CD]
										EXCEP_CD, --	���ο��ܺ�ȣ(STP_EXCE_CD)
										EXP_YMD, --	����(�簳)������
										RE_STA_YMD, --	�����簳������
										STATUS, --	���λ���[STP_SUBT_TYPE_CD]
										RATE, --	������
										NOTE,--	���
										MOD_USER_ID, --	������
										MOD_DATE, --	�����Ͻ�
										TZ_CD, --	Ÿ�����ڵ�
										TZ_DATE  --	Ÿ�����Ͻ�
											)
								SELECT NEXT VALUE FOR S_STP_SEQUENCE as STP_JOIN_INFO_ID, --	���ο��ݰ�������ID
										@emp_id	EMP_ID, --	���ID
										'12' REPORT_TYPE, --	�Ű���[STP_STAT_TYPE_CD] '12':�������׺���
										@ym_insur + '01', -- -- ��������
										'29991231'	END_YMD, --	��������
										'' SUB_COMPANY_CD, --	����ȸ���ڵ�
										NULL REPORT_YMD, --	���Ű���
										'1' REPORT_CD, --	�������ο���(STP_REPORT_CD) 1:���
										NULL CAUSE_CD, --	������ȣ
										'1' NATION_CD, --	�����ڵ�[STP_NATIVE_TYPE_CD) 1:������, 9:�ܱ���
										NULL	STAY_CD, --	�ܱ���ü���ڰ�[STP_STAY_CAPA_CD]
										'Y'	SIN_YN, --	�Ű���
										AMT_STANDARD	STAND_AMT, --	��������
										AMT_INSUR	INSU_AMT, --	�����
										NULL	SPECIAL_CD, --	Ư��������ȣ[STP_SPEC_TYPE_CD]
										NULL	EXCEP_CD, --	���ο��ܺ�ȣ(STP_EXCE_CD)
										NULL	EXP_YMD, --	����(�簳)������
										NULL	RE_STA_YMD, --	�����簳������
										'01'	STATUS, --	���λ���[STP_SUBT_TYPE_CD] 01:����, 02:������, 03:����
										100 RATE--RATE_INSUR	RATE --	������
										,  REM_COMMENT
										, 0 AS MOD_USER_ID
										, ISNULL(DT_UPDATE,'1900-01-01')
										, 'KST'
										, ISNULL(DT_UPDATE,'1900-01-01')
									FROM dwehrdev.dbo.H_MED_INSUR A
									WHERE CD_COMPANY = @s_company_cd
										AND FG_INSUR = @fg_insur
										AND YM_INSUR = @ym_insur
										AND NO_PERSON = @no_person
								IF @@ROWCOUNT > 0
									set @insert_ok = 1
								ELSE
									set @insert_ok = 0
							END
					end
				ELSE IF @fg_insur = '2' -- �ǰ�����
					begin
						INSERT INTO dwehrdev_H5.dbo.NHS_JOIN_INFO(
								NHS_JOIN_INFO_ID,--	�ǰ����谡������ID
								EMP_ID,--	���ID
								REPORT_TYPE,--	�Ű���(NHS_STAT_TYPE_CD)
								STA_YMD,--	��������
								END_YMD,--	��������
								SUB_COMPANY_CD,--	����ȸ���ڵ�
								REPORT_YMD,--	�Ű�����
								CAUSE_CD,--	������ȣ
								NATION_CD,--	�����ڵ�[NHS_NATIVE_TYPE_CD)
								STAY_CD,--	�ܱ���ü���ڰ�[NHS_STAY_CAPA_CD]
								RED_AMT_CD,--	�����ȣ(NHS_RED_AMT_CD)
								HNDCP_CD,--	��������ں�ȣ(NHS_INJURY_CD)
								HNDCP_GRADE,--	��������ڵ��(PHM_HANDICAP_GRD_CD)
								HNDCP_YMD,--	��������ڵ������
								SIN_YN,--	�Ű���
								NHS_NO,--	����ȣ
								SEND_YN,--	������߼ۿ���
								STAND_AMT,--	��������
								INSU_AMT,--	�����
								LONG_INSU_AMT,--	����纸���
								EXP_YMD,--	���ο�����
								RE_STA_YMD,--	�����簳������
								EXEC_CD,--	���������ڵ�
								STATUS,--	�޿��������[NHS_JOIN_STATE_CD]
								RATE,--	������
								RETIRE_YN,--	������������
								ACCNT_CD,--	ȸ��(���������)
								JOB_CD,--	����
								NOTE,--	���
								MOD_USER_ID, --	������
								MOD_DATE, --	�����Ͻ�
								TZ_CD, --	Ÿ�����ڵ�
								TZ_DATE  --	Ÿ�����Ͻ�
							   )
						SELECT NEXT VALUE FOR S_NHS_SEQUENCE as NHS_JOIN_INFO_ID,--	�ǰ����谡������ID
								@emp_id	EMP_ID,--	���ID
								'01'	REPORT_TYPE,--	�Ű���(NHS_STAT_TYPE_CD) 01:���
								@hire_ymd, --(SELECT HIRE_YMD FROM PHM_EMP WHERE EMP_ID=@emp_id), -- ��������
								case  when @init_ym_insur < @ym_insur then
										dbo.XF_DATEADD( dbo.XF_TO_DATE(@ym_insur + '01', 'yyyymmdd') , -1)
									  else
										dbo.XF_TO_DATE('29991231','yyyymmdd') end END_YMD, --	��������
								''	SUB_COMPANY_CD,--	����ȸ���ڵ�
								@hire_ymd, --(SELECT HIRE_YMD FROM PHM_EMP WHERE EMP_ID=@emp_id)	REPORT_YMD,--	�Ű�����
								NULL	CAUSE_CD,--	������ȣ
								'1'	NATION_CD,--	�����ڵ�[NHS_NATIVE_TYPE_CD) 1:������, 9:�ܱ���
								NULL	STAY_CD,--	�ܱ���ü���ڰ�[NHS_STAY_CAPA_CD]
								NULL	RED_AMT_CD,--	�����ȣ(NHS_RED_AMT_CD)
								NULL	HNDCP_CD,--	��������ں�ȣ(NHS_INJURY_CD)
								NULL	HNDCP_GRADE,--	��������ڵ��(PHM_HANDICAP_GRD_CD)
								NULL	HNDCP_YMD,--	��������ڵ������
								'Y'	SIN_YN,--	�Ű���
								NULL	NHS_NO,--	����ȣ
								'Y'	SEND_YN,--	������߼ۿ���
								AMT_STANDARD	STAND_AMT,--	��������
								AMT_INSUR	INSU_AMT,--	�����
								0	LONG_INSU_AMT,--	����纸���
								NULL	EXP_YMD,--	���ο�����
								NULL	RE_STA_YMD,--	�����簳������
								NULL	EXEC_CD,--	���������ڵ�
								'01'	STATUS,--	�޿��������[NHS_JOIN_STATE_CD] 01:����
								100 RATE, --RATE_INSUR	RATE,--	������
								NULL	RETIRE_YN,--	������������
								NULL	ACCNT_CD,--	ȸ��(���������)
								NULL	JOB_CD--	����
								,  REM_COMMENT
								, 0 AS MOD_USER_ID
								, ISNULL(DT_UPDATE,'1900-01-01')
								, 'KST'
								, ISNULL(DT_UPDATE,'1900-01-01')
						  FROM dwehrdev.dbo.H_MED_INSUR A
						 WHERE CD_COMPANY = @s_company_cd
						   AND FG_INSUR = @fg_insur
						   AND YM_INSUR = @init_ym_insur
						   AND NO_PERSON = @no_person
						IF @@ROWCOUNT > 0
							set @insert_ok = 1
						ELSE
							set @insert_ok = 0
						IF @init_ym_insur < @ym_insur
							BEGIN
								INSERT INTO dwehrdev_H5.dbo.NHS_JOIN_INFO(
										NHS_JOIN_INFO_ID,--	�ǰ����谡������ID
										EMP_ID,--	���ID
										REPORT_TYPE,--	�Ű���(NHS_STAT_TYPE_CD)
										STA_YMD,--	��������
										END_YMD,--	��������
										SUB_COMPANY_CD,--	����ȸ���ڵ�
										REPORT_YMD,--	�Ű�����
										CAUSE_CD,--	������ȣ
										NATION_CD,--	�����ڵ�[NHS_NATIVE_TYPE_CD)
										STAY_CD,--	�ܱ���ü���ڰ�[NHS_STAY_CAPA_CD]
										RED_AMT_CD,--	�����ȣ(NHS_RED_AMT_CD)
										HNDCP_CD,--	��������ں�ȣ(NHS_INJURY_CD)
										HNDCP_GRADE,--	��������ڵ��(PHM_HANDICAP_GRD_CD)
										HNDCP_YMD,--	��������ڵ������
										SIN_YN,--	�Ű���
										NHS_NO,--	����ȣ
										SEND_YN,--	������߼ۿ���
										STAND_AMT,--	��������
										INSU_AMT,--	�����
										LONG_INSU_AMT,--	����纸���
										EXP_YMD,--	���ο�����
										RE_STA_YMD,--	�����簳������
										EXEC_CD,--	���������ڵ�
										STATUS,--	�޿��������[NHS_JOIN_STATE_CD]
										RATE,--	������
										RETIRE_YN,--	������������
										ACCNT_CD,--	ȸ��(���������)
										JOB_CD,--	����
										NOTE,--	���
										MOD_USER_ID, --	������
										MOD_DATE, --	�����Ͻ�
										TZ_CD, --	Ÿ�����ڵ�
										TZ_DATE  --	Ÿ�����Ͻ�
										 )
								SELECT NEXT VALUE FOR S_NHS_SEQUENCE as NHS_JOIN_INFO_ID,--	�ǰ����谡������ID
										@emp_id	EMP_ID,--	���ID
										'16'	REPORT_TYPE,--	�Ű���(NHS_STAT_TYPE_CD) 16:�������׺���
										@ym_insur + '01' , -- ��������
										'29991231'	END_YMD,--	��������
										''	SUB_COMPANY_CD,--	����ȸ���ڵ�
										NULL	REPORT_YMD,--	�Ű�����
										NULL	CAUSE_CD,--	������ȣ
										'1'	NATION_CD,--	�����ڵ�[NHS_NATIVE_TYPE_CD) 1:������, 9:�ܱ���
										NULL	STAY_CD,--	�ܱ���ü���ڰ�[NHS_STAY_CAPA_CD]
										NULL	RED_AMT_CD,--	�����ȣ(NHS_RED_AMT_CD)
										NULL	HNDCP_CD,--	��������ں�ȣ(NHS_INJURY_CD)
										NULL	HNDCP_GRADE,--	��������ڵ��(PHM_HANDICAP_GRD_CD)
										NULL	HNDCP_YMD,--	��������ڵ������
										'Y'	SIN_YN,--	�Ű���
										NULL	NHS_NO,--	����ȣ
										'Y'	SEND_YN,--	������߼ۿ���
										AMT_STANDARD	STAND_AMT,--	��������
										AMT_INSUR	INSU_AMT,--	�����
										0	LONG_INSU_AMT,--	����纸���
										NULL	EXP_YMD,--	���ο�����
										NULL	RE_STA_YMD,--	�����簳������
										NULL	EXEC_CD,--	���������ڵ�
										'01'	STATUS,--	�޿��������[NHS_JOIN_STATE_CD] 01:����
										100 RATE,--RATE_INSUR	RATE,--	������
										NULL	RETIRE_YN,--	������������
										NULL	ACCNT_CD,--	ȸ��(���������)
										NULL	JOB_CD--	����
										,  REM_COMMENT
										, 0 AS MOD_USER_ID
										, ISNULL(DT_UPDATE,'1900-01-01')
										, 'KST'
										, ISNULL(DT_UPDATE,'1900-01-01')
									FROM dwehrdev.dbo.H_MED_INSUR A
								 WHERE CD_COMPANY = @s_company_cd
									 AND FG_INSUR = @fg_insur
									 AND YM_INSUR = @ym_insur
									 AND NO_PERSON = @no_person
								IF @@ROWCOUNT > 0
									set @insert_ok = 1
								ELSE
									set @insert_ok = 0
							END
					end
				IF @fg_insur not in ('1','2')
					print 'fg_insur=[' + @fg_insur + ']'
				-- =======================================================
				--  To-Be Table Insert End
				-- =======================================================

				if @insert_ok > 0 
					begin
						-- *** �����޽��� �α׿� ���� ***
						--set @v_keys = ISNULL(CONVERT(nvarchar(100), @@cd_company),'NULL')
						--      + ',' + ISNULL(CONVERT(nvarchar(100), @cd_accnt),'NULL')
						--set @v_err_msg = '���õ� Record�� �����ϴ�.!'
						--EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �����޽��� �α׿� ���� ***
						set @n_cnt_success = @n_cnt_success + 1 -- �����Ǽ�
					end
				else
					begin
						-- *** �α׿� ���� �޽��� ���� ***
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @s_company_cd),'NULL')
							  + ',' + ISNULL(CONVERT(nvarchar(100), @fg_insur),'NULL')
							  + ',' + ISNULL(CONVERT(nvarchar(100), @ym_insur),'NULL')
							  + ',' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
						set @v_err_msg = '���õ� Record�� �����ϴ�.!' -- ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @@ERROR, @v_err_msg
						-- *** �α׿� ���� �޽��� ���� ***
						set @n_cnt_failure = @n_cnt_failure + 1 -- ���аǼ�
					end
			END TRY
			BEGIN CATCH
				-- *** �α׿� ���� �޽��� ���� ***
						set @n_err_cod = ERROR_NUMBER()
						set @v_keys = ISNULL(CONVERT(nvarchar(100), @s_company_cd),'NULL')
							  + ',@fg_insur=' + ISNULL(CONVERT(nvarchar(100), @fg_insur),'NULL')
							  + ',@init_ym_insur=' + ISNULL(CONVERT(nvarchar(100), @init_ym_insur),'NULL')
							  + ',@ym_insur=' + ISNULL(CONVERT(nvarchar(100), @ym_insur),'NULL')
							  + ',@no_person=' + ISNULL(CONVERT(nvarchar(100), @no_person),'NULL')
							  + ',@emp_id=' + ISNULL(CONVERT(nvarchar(100), @emp_id),'NULL')
						set @v_err_msg = ERROR_MESSAGE()
						EXEC [dbo].[P_CNV_PAY_LOG_D] @n_log_h_id, @v_keys, @n_err_cod, @v_err_msg
				-- *** �α׿� ���� �޽��� ���� ***
				set @n_cnt_failure =  @n_cnt_failure + 1 -- ���аǼ�
			END CATCH
		END
	--print '���� �ѰǼ� : ' + dbo.xf_to_char_n(@n_total_record, default)
	--print '���� : ' + dbo.xf_to_char_n(@n_cnt_success, default)
	--print '���� : ' + dbo.xf_to_char_n(@n_cnt_failure, default)
	-- Conversion �α����� - ��ȯ�Ǽ�����
	EXEC [dbo].[P_CNV_PAY_LOG_H] @n_log_h_id, 'E', @v_proc_nm, @v_params, @v_pgm_title, @v_t_table, @v_s_table, @n_total_record, @n_cnt_success, @n_cnt_failure

	CLOSE CNV_CUR
	DEALLOCATE CNV_CUR
	PRINT @v_proc_nm + ' �Ϸ�!'
	PRINT 'CNT_PAY_WORK_ID = ' + CONVERT(varchar(100), @n_log_h_id)
	RETURN @n_log_h_id
END
GO

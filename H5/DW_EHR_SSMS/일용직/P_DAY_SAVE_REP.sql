SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[P_DAY_SAVE_REP]
		@an_rep_calc_list_id	NUMERIC(38),
		@an_day_emp_mst_id		NUMERIC(38),
		@av_payroll_ids			NVARCHAR(max),
		@av_locale_cd			NVARCHAR(10),
		@av_tz_cd				NVARCHAR(10),    -- Ÿ�����ڵ�
		@an_mod_user_id			NUMERIC(18,0)  ,    -- ������ ID
		@av_ret_code			NVARCHAR(100)    OUTPUT,
		@av_ret_message			NVARCHAR(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �Ͽ��� �޿����޳��� ����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_DAY_SAVE_REP
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �Ͽ��� �޿����޳��� ����
    --<DOCLINE>   HISTORY     : �ۼ� 2020.10.29
    --<DOCLINE> ***************************************************************************
BEGIN
	SET NOCOUNT ON;
	DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id		NVARCHAR(30)
      , @v_program_nm		NVARCHAR(100)
      , @v_ret_code			NVARCHAR(100)
      , @v_ret_message		NVARCHAR(500)
	  , @REP_PAY_STD_ID		NUMERIC(38)
	
    SET @v_program_id   = 'P_DAY_SAVE_REP'
    SET @v_program_nm   = '�Ͽ��� �޿����޳��� ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);

    -- �����ڷ� ����
	DELETE A
	  FROM REP_PAYROLL_DETAIL A
	 WHERE REP_PAY_STD_ID IN (SELECT REP_PAY_STD_ID
	                            FROM REP_PAY_STD
							   WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id)
	DELETE A
	  FROM REP_PAY_STD A
	 WHERE REP_CALC_LIST_ID = @an_rep_calc_list_id
	
	-- =============================================
	--   As-Is Key Column Select
	--   Source Table Key
	-- =============================================
	SELECT Items as DAY_PAY_PAYROLL_ID
	  INTO #SAVE
	  FROM dbo.fn_split_array(@av_payroll_ids,',') A

	DECLARE @revert_ym		nvarchar(6)
		  , @sta_ymd		date
		  , @end_ymd		date
		  , @rd_appl_s		numeric(5,0)
		  , @pay_total		numeric(18,0)
    DECLARE PAY_CUR CURSOR READ_ONLY FOR
		SELECT YMD.REVERT_YM, YMD.STA_YMD, YMD.END_YMD,
				SUM(PAY.RD_APPL_S) AS RD_APPL_S,	-- �ٹ������ϼ�
				SUM(PAY.PAY_TOTAL) AS PAY_TOTAL		-- �����հ�
		  FROM #SAVE A
		  INNER JOIN DAY_PAY_PAYROLL PAY
		          ON A.DAY_PAY_PAYROLL_ID = PAY.DAY_PAY_PAYROLL_ID
				  INNER JOIN DAY_PHM_EMP EMP
						  ON PAY.EMP_ID = EMP.EMP_ID
				  INNER JOIN DAY_EMP_MST MST
						  ON EMP.DAY_EMP_MST_ID = MST.DAY_EMP_MST_ID
				  INNER JOIN DAY_PAY_YMD YMD
						  ON PAY.DAY_PAY_YMD_ID = YMD.DAY_PAY_YMD_ID
						 AND YMD.CLOSE_YN = 'Y'
		GROUP BY YMD.REVERT_YM, YMD.STA_YMD, YMD.END_YMD
	OPEN PAY_CUR

	WHILE 1 = 1
	BEGIN
		BEGIN TRY
			-- =============================================
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			FETCH NEXT FROM PAY_CUR
			      INTO @revert_ym, @sta_ymd, @end_ymd, @rd_appl_s, @pay_total
			IF @@FETCH_STATUS <> 0 BREAK
			SET @REP_PAY_STD_ID = NEXT VALUE FOR S_REP_SEQUENCE
				INSERT INTO REP_PAY_STD(
						REP_PAY_STD_ID, --	�����ݱ��� �ӱ� ����ID
						REP_CALC_LIST_ID, --	�����ݴ��ID
						PAY_TYPE_CD, --	�޿����ޱ���[PAY_TYPE_CD]
						PAY_YM, --	�޿�����
						SEQ, --	����
						STA_YMD, --	��������
						END_YMD, --	��������
						BASE_DAY, --	�����ϼ�
						MINUS_DAY, --	�����ϼ�
						REAL_DAY, --	����ϼ�
						MOD_USER_ID, --	������
						MOD_DATE, --	�����Ͻ�
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT @REP_PAY_STD_ID AS REP_PAY_STD_ID, --	�����ݱ��� �ӱ� ����ID
						@an_rep_calc_list_id	REP_CALC_LIST_ID, --	�����ݴ��ID
						'10'	PAY_TYPE_CD, --	�޿����ޱ���[REP_PAY_TYPE_CD] 10:�޿�, 20:��, 30:����
						@revert_ym	PAY_YM, --	�޿�����
						--ROW_NUMBER() OVER(ORDER BY (SELECT 1))	SEQ, --	����
						1	SEQ, -- ����
						@sta_ymd	STA_YMD, --	��������
						@end_ymd	END_YMD, --	��������
						@rd_appl_s	BASE_DAY, --	�����ϼ�
						0	MINUS_DAY, --	�����ϼ�
						dbo.XF_TO_CHAR_D(@end_ymd, 'DD')	REAL_DAY, --	����ϼ�
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	�����Ͻ�
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�

				INSERT INTO REP_PAYROLL_DETAIL(
						REP_PAYROLL_DETAIL_ID, --	�����ݱ����ӱ��׸����ID
						REP_PAY_STD_ID, --	�����ݱ��� �ӱ� ����ID
						PAY_ITEM_CD, --	�޿��׸��ڵ�[PAY_ITEM_CD]
						CAL_MON, --	�ݾ�
						MOD_USER_ID, --	������
						MOD_DATE, --	�����Ͻ�
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE  --	Ÿ�����Ͻ�
				)
				SELECT  NEXT VALUE FOR S_REP_SEQUENCE AS REP_PAYROLL_DETAIL_ID, --	�����ݱ����ӱ��׸����ID
						@REP_PAY_STD_ID	AS REP_PAY_STD_ID, --	�����ݱ��� �ӱ� ����ID
						'P001'	AS PAY_ITEM_CD, --	�޿��׸��ڵ�[PAY_ITEM_CD] �⺻��
						@pay_total	CAL_MON, --	�ݾ�
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	�����Ͻ�
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
		END TRY
		BEGIN Catch
					SET @av_ret_message = dbo.F_FRM_ERRMSG( '�Ͽ��� �޿����޳��� ���� ����[ERR]' + ERROR_MESSAGE(),
											@v_program_id,  0150,  null, null
										)
					SET @av_ret_code    = 'FAILURE!'
					RETURN
		END CATCH
	END
	CLOSE PAY_CUR
	DEALLOCATE PAY_CUR
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

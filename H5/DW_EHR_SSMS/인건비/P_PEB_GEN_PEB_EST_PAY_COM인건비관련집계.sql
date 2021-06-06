SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_GEN_PEB_EST_PAY_COM]
		@av_company_cd      NVARCHAR(10),
		@av_locale_cd       NVARCHAR(10),
		@av_type_nm			NVARCHAR(10),
		@av_fr_pay_ym		nvarchar(06),
		@av_to_pay_ym		nvarchar(06),
    @av_tz_cd           NVARCHAR(10),    -- Ÿ�����ڵ�
    @an_mod_user_id     NUMERIC(18,0)  ,    -- ������ ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �޿��������� �ΰǺ�����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_GEN_PEB_EST_PAY_COM
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �޿��������� �ΰǺ�����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2021.01.07
    --<DOCLINE> ***************************************************************************
BEGIN
	DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
		, @v_plan_cd		nvarchar(10) = '20' -- ����
		, @v_type_nm		nvarchar(50) = @av_type_nm
		, @v_hrs_std_mgr	numeric(38,0)

	DECLARE @TEMP_EST_PAY TABLE (
		BASE_YM		nvarchar(10),
		ORG_ID		numeric(38,0),
		VIEW_CD		nvarchar(10),
		PHM_CNT		numeric(18),
		PAY_CNT		numeric(18),
		PAY_AMT		numeric(18),
		PAY_ETC_AMT	numeric(18)
	)
	SET NOCOUNT ON;

    SET @v_program_id   = 'P_PEB_GEN_PEB_EST_PAY_COM'
    SET @v_program_nm   = '�޿����� �ΰǺ� ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
  -- �����ڷ� ����
	DELETE
	  FROM A
	  FROM PEB_EST_PAY A
	  WHERE A.BASE_YM BETWEEN @av_fr_pay_ym AND @av_to_pay_ym
	  AND COMPANY_CD = @av_company_cd
	  AND PLAN_CD = @v_plan_cd
	  AND TYPE_NM = @v_type_nm
	BEGIN TRY
		INSERT INTO @TEMP_EST_PAY(
			  BASE_YM
			, ORG_ID
			, VIEW_CD
			, PHM_CNT
			, PAY_CNT
			, PAY_AMT
			, PAY_ETC_AMT
		)
		SELECT YMD.PAY_YM BASE_YM
			 , PAY.ORG_ID
			 , dbo.F_PEB_GET_VIEW_CD(@v_type_nm, PAY.POS_GRD_CD, PAY.POS_CD, PAY.DUTY_CD, PAY.JOB_POSITION_CD
					, PAY.MGR_TYPE_CD, PAY.JOB_CD, PAY.EMP_KIND_CD) AS VIEW_CD
			 , COUNT(DISTINCT PAY.EMP_ID) AS PHM_CNT
			 , COUNT(DISTINCT PAY.EMP_ID) AS PAY_CNT
			 , SUM(CASE WHEN PEB.PAY_ITEM_CD IS NULL AND ITEM.CD1 = 'PAY_PAY' THEN DTL.CAL_MON
						ELSE 0 END) PAY_AMT
			 , SUM(CASE WHEN PEB.PAY_ITEM_CD IS NULL THEN 0
						ELSE DTL.CAL_MON END) PAY_ETC_AMT
		  FROM PAY_PAY_YMD YMD
		  INNER JOIN PAY_PAYROLL PAY
					ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
					-- �ùķ��̼�����
				   AND YMD.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE WHERE COMPANY_CD = @av_company_cd AND CD_KIND = 'PAY_TYPE_CD'
																	 AND YMD.PAY_YMD BETWEEN STA_YMD AND END_YMD
																	 AND SYS_CD != '100')
				   AND YMD.COMPANY_CD = @av_company_cd
				   AND YMD.PAY_YN = 'Y'
				   AND YMD.CLOSE_YN = 'Y'
				   AND YMD.PAY_YM BETWEEN @av_fr_pay_ym AND @av_to_pay_ym
			--INNER JOIN PHM_EMP EMP
			--        ON PAY.EMP_ID = EMP.EMP_ID
		  INNER JOIN (select KEY_CD1 ITEM_CD, CD1, HIS.STA_YMD, HIS.END_YMD
						  FROM FRM_UNIT_STD_HIS HIS
								   , FRM_UNIT_STD_MGR MGR
						 WHERE HIS.FRM_UNIT_STD_MGR_ID = MGR.FRM_UNIT_STD_MGR_ID
						   AND MGR.UNIT_CD = 'PAY'
						   AND MGR.STD_KIND = 'PAY_ITEM_CD_BASE'
							  AND MGR.COMPANY_CD = @av_company_cd
						   AND MGR.LOCALE_CD = 'KO'
						   AND CD1 IN ('PAY_PAY', 'PAY_G', 'PAY_GN')) ITEM
					ON YMD.PAY_YMD BETWEEN ITEM.STA_YMD AND ITEM.END_YMD
		  INNER JOIN PAY_PAYROLL_DETAIL DTL
					ON PAY.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID
				   AND DTL.PAY_ITEM_CD = ITEM.ITEM_CD
		  LEFT OUTER JOIN PEB_EST_ITEM PEB
		            ON DTL.PAY_ITEM_CD = PEB.PAY_ITEM_CD
					AND YMD.PAY_YMD BETWEEN PEB.STA_YMD AND PEB.END_YMD
					AND YMD.COMPANY_CD = PEB.COMPANY_CD
		 GROUP BY YMD.PAY_YM, PAY.ORG_ID
			 , dbo.F_PEB_GET_VIEW_CD(@v_type_nm, PAY.POS_GRD_CD, PAY.POS_CD, PAY.DUTY_CD, PAY.JOB_POSITION_CD
					, PAY.MGR_TYPE_CD, PAY.JOB_CD, PAY.EMP_KIND_CD)
	IF @v_type_nm IN ('�ΰǺ�')
		BEGIN
		----------------
		-- �Ͽ����޿� ����
		----------------
				INSERT INTO @TEMP_EST_PAY(
					  BASE_YM
					, ORG_ID
					, VIEW_CD
					, PHM_CNT
					, PAY_CNT
					, PAY_AMT
					, PAY_ETC_AMT
				)
				 SELECT YMD.REVERT_YM BASE_YM       -- ���޳��
				, EMP.ORG_ID
				, '50' AS VIEW_CD -- �Ͽ�/����
				, 0-- COUNT(DISTINCT MST.DAY_EMP_MST_ID) PHM_CNT
				, 0-- COUNT(DISTINCT MST.DAY_EMP_MST_ID) PAY_CNT
				 , SUM(PAY.RD_PAY_S)                                 AS RD_PAY_S       --�⺻�޿�
				 , SUM(PAY.EDU_AMT + PAY.ETC_PAY_AMT)                AS ETC_PAY_AMT    -- ������ + ��Ÿ����
		  FROM DAY_PAY_PAYROLL PAY
			   INNER JOIN DAY_PHM_EMP EMP
					   ON PAY.EMP_ID = EMP.EMP_ID
			   INNER JOIN DAY_EMP_MST MST
					   ON EMP.DAY_EMP_MST_ID = MST.DAY_EMP_MST_ID
			   INNER JOIN DAY_PAY_YMD YMD
					   ON PAY.DAY_PAY_YMD_ID = YMD.DAY_PAY_YMD_ID
					  AND YMD.CLOSE_YN = 'Y'
		 WHERE MST.COMPANY_CD =  @av_company_cd
		   AND YMD.REVERT_YM BETWEEN  @av_fr_pay_ym AND @av_to_pay_ym
		 GROUP BY YMD.REVERT_YM , EMP.ORG_ID
		----------------
		-- �Ͽ����޿� ��
		----------------
		----------------
		-- �������޿� ����
		----------------
				INSERT INTO @TEMP_EST_PAY(
					  BASE_YM
					, ORG_ID
					, VIEW_CD
					, PHM_CNT
					, PAY_CNT
					, PAY_AMT
					, PAY_ETC_AMT
				)
				SELECT PAY_YM
					 , ORG_ID
					 , '50' AS VIEW_CD -- �Ͽ�/����
					 , 0 AS PHM_CNT
					 , 0 AS PAY_CNT
					 , PAY_AMT
					 , 0 PAY_ETC_AMT
				  FROM (
						SELECT DAY_CNT_DEPT_ID ORG_ID
							, YYYY + SUBSTRING(AMT_COL,5,2) AS PAY_YM
							, PAY_AMT
						  FROM DAY_CNT_DATA A
							   --   UNPIVOT ( PAY_CNT FOR PHM_COL IN (CNT_01, CNT_02, CNT_03, CNT_04, CNT_05, CNT_06, CNT_07, CNT_08, CNT_09, CNT_10, CNT_11, CNT_12) )  UNPVT1
								  UNPIVOT ( PAY_AMT FOR AMT_COL IN (AMT_01, AMT_02, AMT_03, AMT_04, AMT_05, AMT_06, AMT_07, AMT_08, AMT_09, AMT_10, AMT_11, AMT_12) )  UNPVT2
						 WHERE COMPANY_CD = @av_company_cd
						   AND YYYY BETWEEN SUBSTRING(@av_fr_pay_ym, 1, 4) AND SUBSTRING(@av_to_pay_ym, 1, 4)
				  ) A
				  WHERE PAY_YM BETWEEN @av_fr_pay_ym AND @av_to_pay_ym
		----------------
		-- �������޿� ��
		----------------
		END
		INSERT INTO PEB_EST_PAY(
			PEB_EST_PAY_ID,--	�ΰǺ����ID
			COMPANY_CD,--	ȸ���ڵ�
			BASE_YM,--	���س��
			PLAN_CD,--	�ΰǺ��ȹ����[PEB_PLAN_CD]
			ORG_ID,--	�μ�ID
			TYPE_NM,--	��豸��
			VIEW_CD,--	ǥ���ڵ�
			PHM_CNT,--	�����ο�
			PAY_CNT,--	������ο�(�޿�����)
			PAY_AMT,--	�ӱ�
			PAY_ETC_AMT,--	��Ÿ��ǰ
			MOD_USER_ID,--	������
			MOD_DATE,--	������
			TZ_CD,--	Ÿ�����ڵ�
			TZ_DATE --	Ÿ�����Ͻ�
		)
		 SELECT NEXT VALUE FOR S_PEB_SEQUENCE
			 , @av_company_cd COMPANY_CD
			 , BASE_YM
			 , @v_plan_cd PLAN_CD
			 , ORG_ID
			 , @v_type_nm TYPE_NM
			 , VIEW_CD
			 , SUM(PHM_CNT) AS PHM_CNT
			 , SUM(PAY_CNT) AS PAY_CNT
			 , SUM(PAY_AMT) AS PAY_AMT
			 , SUM(PAY_ETC_AMT) AS PAY_ETC_AMT
			 , @an_mod_user_id MOD_USER_ID --MOD_USER_ID,--	������
			 , SYSDATETIME() -- MOD_DATE,--	������
			 , @av_tz_cd -- TZ_CD,--	Ÿ�����ڵ�
			 , SYSDATETIME() --TZ_DATE --	Ÿ�����Ͻ�
		   FROM @TEMP_EST_PAY
		   GROUP BY BASE_YM, ORG_ID, VIEW_CD
		 IF @@ROWCOUNT < 1
		 BEGIN
			SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ���� ������ ����[ERR]���賻���� �����ϴ�.',
									@v_program_id,  0110,  null, null
								)
			SET @av_ret_code    = 'FAILURE!'
			RETURN
		 END
	END TRY
	BEGIN CATCH
		SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ���� ������ ����[ERR]' + ISNULL(ERROR_MESSAGE(),''),
								@v_program_id,  0150,  null, null
							)
		SET @av_ret_code    = 'FAILURE!'
		RETURN
	END CATCH
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END
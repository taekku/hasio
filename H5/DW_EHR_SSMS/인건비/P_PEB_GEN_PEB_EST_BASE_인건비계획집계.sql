SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_GEN_PEB_EST_BASE]
		@av_company_cd      NVARCHAR(10),
		@av_locale_cd       NVARCHAR(10),
		@an_peb_base_id		NUMERIC(38,0),
		@av_fr_pay_ym		nvarchar(06),
		@av_to_pay_ym		nvarchar(06),
    @av_tz_cd           NVARCHAR(10),    -- Ÿ�����ڵ�
    @an_mod_user_id     NUMERIC(18,0)  ,    -- ������ ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ �ΰǺ�����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_GEN_PEB_EST_BASE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ���� �ΰǺ�����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2021.01.07
    --<DOCLINE> ***************************************************************************
BEGIN
	DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)

	  , @v_base_yyyy	nvarchar(10)
	  , @v_plan_cd		nvarchar(10) = '10'
	  , @v_type_nm		nvarchar(50) = '�ΰǺ�'

	SET @v_program_id   = 'P_PEB_GEN_PEB_EST_BASE'
	SET @v_program_nm   = '�ΰǺ��ȹ ��ȹ����'
	SET @av_ret_code    = 'SUCCESS!'
	SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
										@v_program_id,  0000,  NULL, NULL);
	BEGIN TRY
		 SELECT @v_base_yyyy = BASE_YYYY
		   FROM PEB_BASE
		  WHERE PEB_BASE_ID = @an_peb_base_id
		    AND COMPANY_CD = @av_company_cd
		IF @@ROWCOUNT < 1
		BEGIN
			SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ���� ������(��ȹ) - �ΰǺ��ȹ�� �о�� �� �����ϴ�.[ERR]',
									@v_program_id,  0100,  null, null
								)
			SET @av_ret_code    = 'FAILURE!'
			RETURN
		END
  -- �����ڷ� ����
		DELETE
		  FROM A
		  FROM PEB_EST_PAY A
		  WHERE A.BASE_YM LIKE @v_base_yyyy + '%'
		  AND COMPANY_CD = @av_company_cd
		  AND PLAN_CD = @v_plan_cd
		  AND TYPE_NM = @v_type_nm
		  AND A.BASE_YM BETWEEN @av_fr_pay_ym AND @av_to_pay_ym
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
			 , COMPANY_CD, BASE_YM, PLAN_CD, ORG_ID, TYPE_NM, VIEW_CD
			 , COUNT(DISTINCT PEB_PHM_MST_ID) AS PHM_CNT
			 , COUNT(DISTINCT PEB_PHM_MST_ID) AS PAY_CNT
			 , SUM(PAY_AMT) AS PAY_AMT
			 , SUM(PAY_ETC_AMT) AS PAY_ETC_AMT
			 , @an_mod_user_id --MOD_USER_ID,--	������
			 , SYSDATETIME() -- MOD_DATE,--	������
			 , @av_tz_cd -- TZ_CD,--	Ÿ�����ڵ�
			 , SYSDATETIME() --TZ_DATE --	Ÿ�����Ͻ�
		  FROM (
				SELECT @av_company_cd AS COMPANY_CD
					 , PEB_YM BASE_YM
					 , @v_plan_cd AS PLAN_CD -- 10:��ȹ/20:����
					 , MST.PAY_ORG_ID AS ORG_ID
					 , @v_type_nm AS TYPE_NM
					 , dbo.F_PEB_GET_VIEW_CD(@v_type_nm, PAY.POS_GRD_CD, PAY.POS_CD, PAY.DUTY_CD, PAY.JOB_POSITION_CD
								, MST.MGR_TYPE_CD, MST.JOB_CD, MST.EMP_KIND_CD) AS VIEW_CD
					 , MST.PEB_PHM_MST_ID
					, CASE when PEB.PAY_ITEM_CD IS NULL AND ITEM.CD1 = 'PAY_PAY' THEN DTL.CAM_AMT
							ELSE 0 END AS PAY_AMT
					, CASE when PEB.PAY_ITEM_CD IS NULL THEN 0
							ELSE DTL.CAM_AMT END AS PAY_ETC_AMT
					, DTL.PAY_ITEM_CD
				  FROM PEB_PHM_MST MST
				  JOIN PEB_PAYROLL PAY
					ON MST.PEB_PHM_MST_ID = PAY.PEB_PHM_MST_ID
		  INNER JOIN (select KEY_CD1 ITEM_CD, CD1, HIS.STA_YMD, HIS.END_YMD
						  FROM FRM_UNIT_STD_HIS HIS
								   , FRM_UNIT_STD_MGR MGR
						 WHERE HIS.FRM_UNIT_STD_MGR_ID = MGR.FRM_UNIT_STD_MGR_ID
						   AND MGR.UNIT_CD = 'PAY'
						   AND MGR.STD_KIND = 'PAY_ITEM_CD_BASE'
							  AND MGR.COMPANY_CD = @av_company_cd
						   AND MGR.LOCALE_CD = 'KO'
						   AND CD1 IN ('PAY_PAY', 'PAY_G', 'PAY_GN')) ITEM
					ON dbo.XF_LAST_DAY(PAY.PEB_YM + '01') BETWEEN ITEM.STA_YMD AND ITEM.END_YMD
				  JOIN PEB_PAYROLL_DETAIL DTL
					ON PAY.PEB_PAYROLL_ID = DTL.PEB_PAYROLL_ID
				   AND ITEM.ITEM_CD = DTL.PAY_ITEM_CD
				  LEFT OUTER JOIN PEB_EST_ITEM PEB
							ON DTL.PAY_ITEM_CD = PEB.PAY_ITEM_CD
							AND dbo.XF_LAST_DAY(PAY.PEB_YM + '01')  BETWEEN PEB.STA_YMD AND PEB.END_YMD
							AND PEB.COMPANY_CD = @av_company_cd
				 WHERE MST.PEB_BASE_ID = @an_peb_base_id
				 AND PAY.PEB_YM BETWEEN @av_fr_pay_ym AND @av_to_pay_ym
				 AND CAM_AMT <> 0
				 AND DTL.PAY_ITEM_CD LIKE 'P%'
				 ) A
		 GROUP BY COMPANY_CD, BASE_YM, PLAN_CD, ORG_ID, TYPE_NM, VIEW_CD
		 IF @@ROWCOUNT < 1
		 BEGIN
			SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ��ȹ�� ���� �޿������� �����ϴ�.[ERR]',
									@v_program_id,  0110,  null, null
								)
			SET @av_ret_code    = 'FAILURE!'
			RETURN
		 END
	END TRY
	BEGIN CATCH
		SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ���� ������(��ȹ) ����[ERR]' + ISNULL(ERROR_MESSAGE(), ''),
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
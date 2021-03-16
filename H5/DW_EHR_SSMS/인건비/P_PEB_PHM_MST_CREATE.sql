SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER     PROCEDURE [dbo].[P_PEB_PHM_MST_CREATE]
		@an_peb_base_id			NUMERIC,
		@av_company_cd      NVARCHAR(10),
		@ad_base_ymd				DATE,
		@an_org_id				NUMERIC,
		@av_emp_no				NVARCHAR(50),
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- Ÿ�����ڵ�
    @an_mod_user_id     NUMERIC(18,0)  ,    -- ������ ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ ����ܻ���
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PHM_MST_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ ������� ����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2020.09.08
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @CD				NVARCHAR(50)
	  , @EMP_ID		NUMERIC
	  , @EMP_NO		NVARCHAR(50)
	  , @PEB_PHM_MST_ID	NUMERIC(38,0)

    SET @v_program_id   = 'P_PEB_PHM_MST_CREATE'
    SET @v_program_nm   = '�ΰǺ��ȹ ����� ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
	-- ����ID���
	SELECT A.PEB_PHM_MST_ID, A.EMP_NO
	  INTO #phm_mst_back
	  FROM PEB_PHM_MST A
		JOIN PHM_EMP EMP
		  ON EMP.COMPANY_CD = @av_company_cd
		 AND A.EMP_NO = EMP.EMP_NO
	   WHERE A.PEB_BASE_ID = @an_peb_base_id
	     AND (@an_org_id IS NULL OR EMP.ORG_ID = @an_org_id)
		 AND (@av_emp_no IS NULL OR EMP.EMP_NO = @av_emp_no)
	-- �����ڷ����
	DELETE FROM PEB_PHM_MST
	  FROM PEB_PHM_MST A
		JOIN PHM_EMP EMP
		  ON EMP.COMPANY_CD = @av_company_cd
		 AND A.EMP_NO = EMP.EMP_NO
	   WHERE A.PEB_BASE_ID = @an_peb_base_id
	     AND (@an_org_id IS NULL OR EMP.ORG_ID = @an_org_id)
		 AND (@av_emp_no IS NULL OR EMP.EMP_NO = @av_emp_no)
--RETURN
	/** �ΰǺ��ȹ ����� **/
	DECLARE CUR_PHM_EMP CURSOR LOCAL FOR
		SELECT EMP.EMP_ID, EMP.EMP_NO, B.PEB_PHM_MST_ID
			FROM PHM_EMP EMP
			LEFT OUTER JOIN #phm_mst_back B
			             ON EMP.EMP_NO = B.EMP_NO
		 WHERE EMP.COMPANY_CD = @av_company_cd
		   --AND @ad_base_ymd BETWEEN EMP.HIRE_YMD AND ISNULL(EMP.RETIRE_YMD, '2999-12-31')
			 AND @ad_base_ymd >= EMP.HIRE_YMD
			 AND @ad_base_ymd > ISNULL(EMP.RETIRE_YMD, '1900-01-01')
			 AND IN_OFFI_YN = 'Y'
			 AND (@an_org_id IS NULL OR EMP.ORG_ID = @an_org_id)
			 AND (@av_emp_no IS NULL OR EMP.EMP_NO = @av_emp_no)
	OPEN CUR_PHM_EMP
	FETCH NEXT FROM CUR_PHM_EMP INTO @EMP_ID, @EMP_NO, @PEB_PHM_MST_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> �ΰǺ� ����� ����
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				IF @PEB_PHM_MST_ID IS NULL
					SET @PEB_PHM_MST_ID = NEXT VALUE FOR S_PEB_SEQUENCE
				INSERT INTO PEB_PHM_MST(
						PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						PEB_BASE_ID, --	�ΰǺ��ȹ����ID
						EMP_NO, --	���
						EMP_NM, --	����
						HIRE_YMD, --	�Ի�����
						ANNUAL_CAL_YMD, --	���������
						BIRTH_YMD, -- �������
						WK_TYPE_CD, --	�ٹ������ڵ�
						MGR_TYPE_CD, --	��������
						JOB_POSITION_CD, -- �����ڵ�
						SALARY_TYPE_CD, --	�޿������ڵ�
						PAY_ORG_ID, --	�޿��μ�ID
						PHM_BIZ_CD, --	�Ҽӻ����
						PAY_BIZ_CD, --	�޿������
						PAY_GROUP_CD, -- �޿��׷��ڵ�
						POS_CD, --	�����ڵ� [PHM_POS_CD]
						POS_YMD, --	�����ӿ�����
						DUTY_CD, --	��å�ڵ� [PHM_DUTY_CD]
						POS_GRD_CD, --	�����ڵ� [PHM_POS_GRD_CD]
						POS_GRD_YMD, --	���޽�������
						YEARNUM_CD, --	ȣ���ڵ� [PHM_YEARNUM_CD]
						YEARNUM_YMD, --	ȣ���±�����
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	������
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT @PEB_PHM_MST_ID,
						   @an_peb_base_id, --	�ΰǺ��ȹ����ID
						EMP.EMP_NO, --	���
						EMP.EMP_NM, --	����
						EMP.HIRE_YMD, --	�Ի�����
						(SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=EMP.EMP_ID AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD AND BASE_TYPE_CD='ANNUAL_CAL_YMD'), -- ���������
						EMP.BIRTH_YMD, -- �������
						CAM.EMP_KIND_CD WK_TYPE_CD, --	�ٹ������ڵ�
						CAM.MGR_TYPE_CD, --	��������
						CAM.JOB_POSITION_CD, -- �����ڵ�
						(select salary_type_cd from CNM_CNT where EMP_ID=EMP.EMP_ID and @ad_base_ymd between STA_YMD AND END_YMD) SALARY_TYPE_CD, --	�޿������ڵ�
						CAM.ORG_ID PAY_ORG_ID, --	�޿��μ�ID
						dbo.F_ORM_ORG_BIZ(CAM.ORG_ID, GETDATE(), 'PAY') PHM_BIZ_CD, --	�Ҽӻ����
						dbo.F_ORM_ORG_BIZ(CAM.ORG_ID, GETDATE(), 'PAY') PAY_BIZ_CD, --	�޿������
						dbo.F_PAY_GROUP_CD(EMP.EMP_ID), -- �޿��׷��ڵ�
						CAM.POS_CD	POS_CD, --	�����ڵ� [PHM_POS_CD]
						--EMP.POS_YMD	POS_YMD, --	�����ӿ�����
						(SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=EMP.EMP_ID AND BASE_TYPE_CD='POS_YMD' AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD) AS POS_YMD,
						CAM.DUTY_CD	DUTY_CD, --	��å�ڵ� [PHM_DUTY_CD]
						CAM.POS_GRD_CD	POS_GRD_CD, --	�����ڵ� [PHM_POS_GRD_CD]
						-- ���޽�������
						CASE WHEN @av_company_cd in ('E') THEN -- ������ ��� ���������� ���޽����Ϸ� Setting
						          (SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=EMP.EMP_ID AND BASE_TYPE_CD='POS_YMD' AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD)
						     ELSE (SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=EMP.EMP_ID AND BASE_TYPE_CD='POS_GRD_YMD' AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD)
						     END AS POS_GRD_YMD,
						EMP.YEARNUM_CD	YEARNUM_CD, --	ȣ���ڵ� [PHM_YEARNUM_CD]
						(SELECT BASE_YMD FROM PHM_BASE_DAY WHERE EMP_ID=EMP.EMP_ID AND BASE_TYPE_CD='YEARNUM_YMD' AND @ad_base_ymd BETWEEN STA_YMD AND END_YMD) AS YEARNUM_YMD,
						NULL	NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
				  FROM VI_FRM_CAM_HISTORY CAM
				  JOIN VI_FRM_PHM_EMP EMP
				    ON CAM.EMP_ID = EMP.EMP_ID
				   AND @ad_base_ymd BETWEEN CAM.STA_YMD AND CAM.END_YMD
				 WHERE EMP.EMP_ID = @EMP_ID
				   AND EMP.LOCALE_CD = @av_locale_cd
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� �λ��� INSERT ����[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_EMP INTO @EMP_ID, @EMP_NO, @PEB_PHM_MST_ID
		END
	CLOSE CUR_PHM_EMP
	DEALLOCATE CUR_PHM_EMP
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

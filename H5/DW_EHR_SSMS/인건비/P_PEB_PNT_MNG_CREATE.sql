SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_PEB_PNT_MNG_CREATE]
		@av_company_cd      NVARCHAR(10),
		@av_locale_cd       NVARCHAR(10),
		@an_peb_base_id		NUMERIC(38),
		@ad_base_ymd		DATE,
		@av_emp_no			NVARCHAR(10),	 -- Ư�����
		@av_tz_cd           NVARCHAR(10),    -- Ÿ�����ڵ�
		@an_mod_user_id     NUMERIC(38,0),   -- ������ ID
		@av_ret_code        nvarchar(100)    OUTPUT,
		@av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ ��������Ʈ ����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PNT_MNG_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ ��������Ʈ ����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2020.09.14
    --<DOCLINE> ***************************************************************************
BEGIN
	SET NOCOUNT ON;
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	
	  , @PEB_PHM_MST_ID	NUMERIC
		, @STA_YMD DATE
		, @END_YMD DATE
		, @COMPANY_CD NVARCHAR(10)
		, @BASE_YYYY NVARCHAR(10)
		, @BIRTH_YMD	DATE
		, @PHM_BIZ_CD	NVARCHAR(50)
		, @PAY_ORG_ID	NUMERIC(38, 0)
		, @POS_GRD_CD	NVARCHAR(50)
		, @MGR_TYPE_CD	NVARCHAR(50)
		, @EMP_KIND_CD	NVARCHAR(50)
		, @GIVE_YMD	DATE
		, @CAT_POINT_TYPE	NVARCHAR(50)
		, @POINT		NUMERIC(18)
		, @BIRTH_POINT	NUMERIC(18)
		, @EMP_NO		NVARCHAR(20)
		, @v_POINT_YN	NVARCHAR(10)

    SET @v_program_id   = 'P_PEB_SCH_MNG_CREATE'
    SET @v_program_nm   = '�ΰǺ��ȹ ��������Ʈ ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
  -- �����ڷ� ����
	DELETE FROM PEB_PNT_MNG
		FROM PEB_PNT_MNG A
		JOIN PEB_PHM_MST MST
		  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id
	  AND (@av_emp_no IS NULL OR MST.EMP_NO = @av_emp_no)
	SELECT @BASE_YYYY = BASE_YYYY
	     , @COMPANY_CD = COMPANY_CD
		 , @STA_YMD = STA_YMD
		 , @END_YMD = END_YMD
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id
	/** �ΰǺ��ȹ ����� **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT MST.PEB_PHM_MST_ID
		     , MST.PHM_BIZ_CD -- �����
			 , MST.PAY_ORG_ID -- �޿��μ�ID
			 , MST.POS_GRD_CD -- �����ڵ�
			 , MST.MGR_TYPE_CD -- ��������
			 , MST.EMP_KIND_CD -- �ٷ�����
			 , dbo.XF_TO_DATE(@BASE_YYYY + B.GIVE_MMDD,'yyyyMMdd') AS GIVE_YMD
			 , B.CAT_POINT_TYPE -- ���ޱ���[CAT_POINT_TYPE]
			 , POINT -- ��������Ʈ
			 , CASE WHEN ISNULL(BIRTH_YN,'N') = 'Y'
			         AND B.BIRTH_STA_MMDD > ' ' AND B.BIRTH_END_MMDD > ' '
			         AND FORMAT(MST.BIRTH_YMD, 'MMdd') BETWEEN B.BIRTH_STA_MMDD AND B.BIRTH_END_MMDD
						THEN BIRTH_POINT
					ELSE 0 END BIRTH_POINT
			 , MST.EMP_NO
		  FROM PEB_PHM_MST MST
		  JOIN CAT_POINT_BASE B
			ON B.COMPANY_CD = @COMPANY_CD
		   AND @BASE_YYYY + B.GIVE_MMDD BETWEEN B.STA_YMD AND B.END_YMD
		   AND @BASE_YYYY + B.GIVE_MMDD >= MST.HIRE_YMD
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
		   AND (@av_emp_no IS NULL OR MST.EMP_NO = @av_emp_no)
	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @PHM_BIZ_CD, @PAY_ORG_ID, @POS_GRD_CD, @MGR_TYPE_CD, @EMP_KIND_CD
	                               , @GIVE_YMD, @CAT_POINT_TYPE, @POINT, @BIRTH_POINT, @EMP_NO

    --<DOCLINE> ********************************************************
    --<DOCLINE> �ΰǺ� ��������Ʈ ����
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			-- ���޽ñ�
			--SELECT dbo.XF_TO_DATE(@BASE_YYYY + GIVE_MMDD, 'yyyyMMdd') AS GIVE_YMD
			--	 , CAT_POINT_TYPE -- ���ޱ���[CAT_POINT_TYPE]
			--	 , POINT
			--	 , BIRTH_YN
			--	 , BIRTH_STA_MMDD
			--	 , BIRTH_END_MMDD
			--	 , BIRTH_POINT
			--	 , STA_YMD
			--	 , END_YMD
			--FROM CAT_POINT_BASE
			--WHERE @BASE_YYYY + GIVE_MMDD BETWEEN STA_YMD AND END_YMD
			-- ���ޱ׷�
			SELECT TOP 1 @POINT = CASE WHEN ISNULL(EXCE_POINT,0) > 0 THEN EXCE_POINT ELSE @POINT END
			  FROM CAT_APPL_CD_STD A
			 WHERE COMPANY_CD = @COMPANY_CD
			   AND @GIVE_YMD BETWEEN STA_YMD AND END_YMD
			   AND dbo.F_CAT_GROUP_CHK_PEB(A.CAT_APPL_CD_STD_ID, @GIVE_YMD, @PHM_BIZ_CD, @PAY_ORG_ID, @POS_GRD_CD, @MGR_TYPE_CD, @EMP_KIND_CD)
			       = A.CAT_APPL_CD_STD_ID
			 ORDER BY A.SEQ DESC
			IF @@ROWCOUNT > 0
				SET @v_POINT_YN = 'Y'
			ELSE
				SET @v_POINT_YN = 'N'
			IF @v_POINT_YN = 'N'
				PRINT '�̻�����:GIVE_YMD=' + FORMAT(@GIVE_YMD,'yyyyMMdd') + ':BIZ_CD=' + ISNULL(@PHM_BIZ_CD,'N/A')
				        + ':ORG_ID=' + CONVERT(VARCHAR(100), @PAY_ORG_ID)
						+ ':POS_GRD_CD=' + ISNULL(@POS_GRD_CD,'N/A')
						+ ':MGT_TYPE_CD' + ISNULL(@MGR_TYPE_CD,'N/A')
						+ ':EMP_KIND_CD' + ISNULL(@EMP_KIND_CD,'N/A')
						+ ':EMP_NO' + ISNULL(@EMP_NO,'N/A')

			IF @v_POINT_YN = 'Y'
				BEGIN
					-- �������ΰ��(�����ΰ��)
					SELECT @v_POINT_YN = 'N'
					  FROM CAT_POINT_EXC
					 WHERE EMP_ID IN (SELECT EMP_ID FROM PHM_EMP WHERE COMPANY_CD = @COMPANY_CD AND EMP_NO=@EMP_NO)
					   AND @GIVE_YMD BETWEEN STA_YMD AND END_YMD
					   AND EXC_TYPE = '20' -- ����
					-- �������ΰ��(�����ΰ��)
					SELECT @POINT = POINT -- ��������Ʈ����
						 , @v_POINT_YN = 'Y'
					  FROM CAT_POINT_EXC
					 WHERE EMP_ID IN (SELECT EMP_ID FROM PHM_EMP WHERE COMPANY_CD = @COMPANY_CD AND EMP_NO=@EMP_NO)
					   AND @GIVE_YMD BETWEEN STA_YMD AND END_YMD
					   AND EXC_TYPE = '10' -- ��������
				END
			IF @v_POINT_YN = 'Y' -- ����Ʈ������ ���
				BEGIN Try
					INSERT INTO PEB_PNT_MNG(
							PEB_PNT_MNG_ID, --	�ΰǺ�������ƮID
							PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
							PAY_YMD, --	��������
							PAY_AMT, --	����Ʈ�ݾ�
							NOTE, --	���
							MOD_USER_ID, --	������
							MOD_DATE, --	������
							TZ_CD, --	Ÿ�����ڵ�
							TZ_DATE --	Ÿ�����Ͻ�
					)
					SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
							@PEB_PHM_MST_ID	PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
							@GIVE_YMD	PAY_YMD, --	��������
							@POINT + @BIRTH_POINT	PAY_AMT, --	����Ʈ�ݾ�
							NULL	NOTE, --	���
							@an_mod_user_id	MOD_USER_ID, --	������
							SYSDATETIME()	MOD_DATE, --	������
							@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
							SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
					  FROM DUAL
					 WHERE @POINT + @BIRTH_POINT > 0
				END Try
				BEGIN Catch
							SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� ��������Ʈ INSERT ����[ERR]' + ERROR_MESSAGE(),
													@v_program_id,  0150,  null, null
												)
							SET @av_ret_code    = 'FAILURE!'
							RETURN
				END CATCH
			
			FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @PHM_BIZ_CD, @PAY_ORG_ID, @POS_GRD_CD, @MGR_TYPE_CD, @EMP_KIND_CD
	                               , @GIVE_YMD, @CAT_POINT_TYPE, @POINT, @BIRTH_POINT, @EMP_NO
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER   PROCEDURE [dbo].[P_PEB_PHM_ITEM_CREATE]
		@an_peb_base_id			NUMERIC,
		@av_company_cd      NVARCHAR(10),
		@ad_base_ymd				DATE,
    @av_locale_cd       NVARCHAR(10),
    @av_tz_cd           NVARCHAR(10),    -- Ÿ�����ڵ�
    @an_mod_user_id     NUMERIC(18,0)  ,    -- ������ ID
    @av_ret_code        nvarchar(100)    OUTPUT,
    @av_ret_message     nvarchar(500)    OUTPUT
AS
    --<DOCLINE> ***************************************************************************
    --<DOCLINE>   TITLE       : �ΰǺ��ȹ �ΰǺ������� ����
    --<DOCLINE>   PROJECT     : DONGWON
    --<DOCLINE>   AUTHOR      : ���ñ�
    --<DOCLINE>   PROGRAM_ID  : P_PEB_PHM_ITEM_CREATE
    --<DOCLINE>   ARGUMENT    : 
    --<DOCLINE>   RETURN      : SUCCESS!/FAILURE!
    --<DOCLINE>                 ��� �޽���
    --<DOCLINE>   COMMENT     :
    --<DOCLINE>                 - �ΰǺ��ȹ �ΰǺ������� ����
    --<DOCLINE>   HISTORY     : �ۼ� ���ñ� 2020.09.14
    --<DOCLINE> ***************************************************************************
BEGIN
    DECLARE
        /* �⺻������ ���Ǵ� ���� */
        @v_program_id    NVARCHAR(30)
      , @v_program_nm    NVARCHAR(100)
      , @v_ret_code      NVARCHAR(100)
      , @v_ret_message   NVARCHAR(500)
	  , @v_pay_ym		NVARCHAR(10) -- �޿����
	  , @PEB_PHM_MST_ID	NUMERIC
		, @STD_YMD DATE -- ��������
		, @STA_YMD DATE -- ���������
		, @END_YMD DATE -- ����������
		, @COMPANY_CD NVARCHAR(10)
		, @BASE_YYYY NVARCHAR(10)
		, @EMP_ID       NUMERIC

    SET @v_program_id   = 'P_PEB_PHM_ITEM_CREATE'
    SET @v_program_nm   = '�ΰǺ��ȹ �ΰǺ������� ����'
    SET @av_ret_code    = 'SUCCESS!'
    SET @av_ret_message = dbo.F_FRM_ERRMSG('���ν��� ���� ����..[ERR]',
                                        @v_program_id,  0000,  NULL, NULL);
  -- �����ڷ� ����
	DELETE FROM PEB_PHM_ITEM
		FROM PEB_PHM_ITEM A
		JOIN PEB_PHM_MST MST
		  ON A.PEB_PHM_MST_ID = MST.PEB_PHM_MST_ID
	WHERE MST.PEB_BASE_ID = @an_peb_base_id
	SELECT @BASE_YYYY = BASE_YYYY
	     , @COMPANY_CD = COMPANY_CD
			 , @STD_YMD = STD_YMD
			 , @STA_YMD = STA_YMD
			 , @END_YMD = END_YMD
			 , @v_pay_ym = dbo.XF_TO_CHAR_D(@ad_base_ymd, 'yyyyMM')
	  FROM PEB_BASE
	 WHERE PEB_BASE_ID = @an_peb_base_id
	/** �ΰǺ��ȹ ����� **/
	DECLARE CUR_PHM_MST CURSOR LOCAL FOR
		SELECT PEB_PHM_MST_ID, EMP.EMP_ID
			FROM PEB_PHM_MST MST
			LEFT OUTER JOIN PHM_EMP EMP
			  ON EMP.COMPANY_CD = @COMPANY_CD
			 AND MST.EMP_NO = EMP.EMP_NO
			 AND MST.PEB_BASE_ID = @an_peb_base_id
		 WHERE MST.PEB_BASE_ID = @an_peb_base_id
	OPEN CUR_PHM_MST
	FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @EMP_ID

    --<DOCLINE> ********************************************************
    --<DOCLINE> �ΰǺ� ��������Ʈ ����
    --<DOCLINE> ********************************************************
	WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN Try
				-- �޿��������� �������׸��� ����
				INSERT INTO PEB_PHM_ITEM(
						PEB_PHM_ITEM_ID, --	�ΰǺ�������ID
						PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						PAY_ITEM_CD, --	�޿��׸��ڵ�
						BASE_AMT, --	���رݾ�
						NOTE, --	���
						MOD_USER_ID, --	������
						MOD_DATE, --	������
						TZ_CD, --	Ÿ�����ڵ�
						TZ_DATE --	Ÿ�����Ͻ�
				)
				SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
						@PEB_PHM_MST_ID	PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
						B.PAY_ITEM_CD, --	�޿��׸��ڵ� 
						sum(B.CAL_MON) AS	BASE_AMT, --	���رݾ�
						'����-' + @v_pay_ym as	NOTE, --	���
						@an_mod_user_id	MOD_USER_ID, --	������
						SYSDATETIME()	MOD_DATE, --	������
						@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
						SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
						--A.EMP_ID, B.PAY_ITEM_CD, B.CAL_MON
					FROM PAY_PAYROLL A
					JOIN PAY_PAYROLL_DETAIL B
						ON A.PAY_PAYROLL_ID = B.PAY_PAYROLL_ID
					JOIN PAY_PAY_YMD P
					 ON A.PAY_YMD_ID = P.PAY_YMD_ID
					JOIN (SELECT HIS.KEY_CD2 AS PAY_ITEM_CD
										 --, DBO.F_FRM_CODE_NM('E', 'KO', 'PAY_ITEM_CD', HIS.KEY_CD2, GETDATE(), '1') AS CD_NM
										 , HIS.KEY_CD1 PAY_GROUP_CD
									FROM FRM_UNIT_STD_MGR MGR
											 INNER JOIN FRM_UNIT_STD_HIS HIS
															 ON MGR.FRM_UNIT_STD_MGR_ID = HIS.FRM_UNIT_STD_MGR_ID
															AND MGR.UNIT_CD = 'PEB'
															AND MGR.STD_KIND = 'PEB_ETC_SUPPLY'
								 WHERE MGR.COMPANY_CD = @COMPANY_CD
									 AND MGR.LOCALE_CD = @av_locale_cd
									 AND GETDATE() BETWEEN HIS.STA_YMD AND HIS.END_YMD) B_ITEM
						ON B.PAY_ITEM_CD = B_ITEM.PAY_ITEM_CD
					 AND A.PAY_GROUP_CD = B_ITEM.PAY_GROUP_CD
				 WHERE P.COMPANY_CD = @COMPANY_CD
					 AND PAY_YM = @v_pay_ym
					 AND P.PAY_TYPE_CD IN (SELECT CD FROM FRM_CODE
											WHERE COMPANY_CD=@COMPANY_CD
											AND CD_KIND='PAY_TYPE_CD'
											AND SYS_CD !='100')
					 AND P.CLOSE_YN = 'Y'
					 AND P.PAY_YN = 'Y'
					 AND A.EMP_ID = @EMP_ID
				 group by B.PAY_ITEM_CD
				-- ��å����( BP017 )
				--INSERT INTO PEB_PHM_ITEM(
				--		PEB_PHM_ITEM_ID, --	�ΰǺ�������ID
				--		PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
				--		PAY_ITEM_CD, --	�޿��׸��ڵ�
				--		BASE_AMT, --	���رݾ�
				--		NOTE, --	���
				--		MOD_USER_ID, --	������
				--		MOD_DATE, --	������
				--		TZ_CD, --	Ÿ�����ڵ�
				--		TZ_DATE --	Ÿ�����Ͻ�
				--)
				--SELECT NEXT VALUE FOR S_PEB_SEQUENCE,
				--		@PEB_PHM_MST_ID	PEB_PHM_MST_ID, --	�ΰǺ��ȹ�����ID
				--		'BP017'	PAY_ITEM_CD, --	�޿��׸��ڵ� 
				--		dbo.F_FRM_UNIT_STD_VALUE (@COMPANY_CD, @av_locale_cd, 'PEB', 'PEB_BASE_DUTY',
    --                          NULL, NULL, NULL, NULL, NULL,
    --                          A.DUTY_CD, NULL, NULL, NULL, NULL,
    --                          getdATE(),
    --                          'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
				--														-- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
    --                          ) AS	BASE_AMT, --	���رݾ�
				--		'����-' + ISNULL(dbo.F_FRM_CODE_NM(@COMPANY_CD, @av_locale_cd, 'PHM_DUTY_CD', A.DUTY_CD, @ad_base_ymd, '1'),'') as	NOTE, --	���
				--		@an_mod_user_id	MOD_USER_ID, --	������
				--		SYSDATETIME()	MOD_DATE, --	������
				--		@av_tz_cd	TZ_CD, --	Ÿ�����ڵ�
				--		SYSDATETIME()	TZ_DATE --	Ÿ�����Ͻ�
				--  FROM PEB_PHM_MST A
				-- WHERE A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				--   AND dbo.F_FRM_UNIT_STD_VALUE (@COMPANY_CD, @av_locale_cd, 'PEB', 'PEB_BASE_DUTY',
    --                          NULL, NULL, NULL, NULL, NULL,
    --                          A.DUTY_CD, NULL, NULL, NULL, NULL,
    --                          getdATE(),
    --                          'H1' -- 'H1' : �ڵ�1,     'H2' : �ڵ�2,     'H3' :  �ڵ�3,     'H4' : �ڵ�4,     'H5' : �ڵ�5
				--														-- 'E1' : ��Ÿ�ڵ�1, 'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
    --                          ) IS NOT NULL -- ��å�� ���� ���رݾ��� �ִ� ���
			END Try
			BEGIN Catch
						SET @av_ret_message = dbo.F_FRM_ERRMSG( '�ΰǺ� ��������Ʈ INSERT ����[ERR]' + ERROR_MESSAGE(),
												@v_program_id,  0150,  null, null
											)
						SET @av_ret_code    = 'FAILURE!'
						RETURN
			END CATCH

			FETCH NEXT FROM CUR_PHM_MST INTO @PEB_PHM_MST_ID, @EMP_ID
		END
	CLOSE CUR_PHM_MST
	DEALLOCATE CUR_PHM_MST
    /************************************************************
    *    �۾� �Ϸ�
    ************************************************************/
    SET @av_ret_code = 'SUCCESS!'
    SET @av_ret_message = '���ν��� ���� �Ϸ�'
END
GO

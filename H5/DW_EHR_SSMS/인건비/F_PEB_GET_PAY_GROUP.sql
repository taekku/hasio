USE [dwehrdev_H5]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[F_PEB_GET_PAY_GROUP]
    (  @an_peb_phm_mst_id		NUMERIC         -- ���ID
    ) RETURNS NVARCHAR(50)
    -- ***************************************************************************
    --   TITLE       : �ΰǺ� - �޿��׷���
	--   DESCRIPTION : �޿��׷�ID�� ���ID�� ���ԵǴ��� ����
    --   PROJECT     : H5
    --   AUTHOR      : ���ñ�
    --   PROGRAM_ID  : F_PEB_PAY_GROUP_CHK
    --   ARGUMENT    : an_peb_phm_mst_id    : ���ID
    --   RETURN      : PAY_GROUP
    --   HISTORY     :
    -- ***************************************************************************
AS
BEGIN
    DECLARE @v_company_cd     NVARCHAR(50),    -- ȸ���ڵ�
            @v_locale_cd      NVARCHAR(50),    -- �����ڵ�
            @v_pay_group      NVARCHAR(50),    -- �׷��ڵ�
			@n_peb_base_id		NUMERIC(38),
			@d_std_ymd			DATE, -- ������
			@d_sta_ymd			DATE, -- ������
			@d_end_ymd			DATE, -- ������

            @v_ret            NVARCHAR(50)              -- �����

	SELECT @n_peb_base_id = PEB_BASE_ID
	     , @v_company_cd = COMPANY_CD
	     , @d_std_ymd = STD_YMD
	     , @d_sta_ymd = STA_YMD
	     , @d_end_ymd = END_YMD
	  FROM PEB_BASE WITH (NOLOCK)
	 WHERE PEB_BASE_ID = (SELECT PEB_BASE_ID FROM PEB_PHM_MST WHERE PEB_PHM_MST_ID = @an_peb_phm_mst_id)
	if @@ROWCOUNT < 1
		BEGIN
			return ''
		END

	SELECT top 1 @v_pay_group = PAY_GROUP
	  FROM PAY_GROUP A
	  INNER JOIN (SELECT CD FROM FRM_CODE WITH (NOLOCK)
	               WHERE COMPANY_CD=@v_company_cd
				     AND CD_KIND='PAY_GROUP_CD'
					 AND SYS_CD = '01' -- ��� �޿��׷�
				     AND @d_sta_ymd BETWEEN STA_YMD AND END_YMD) B
	          ON A.PAY_GROUP = B.CD
	 WHERE COMPANY_CD = @v_company_cd
	   AND @d_sta_ymd BETWEEN STA_YMD AND END_YMD
	   AND PAY_GROUP_ID = dbo.F_PEB_PAY_GROUP_CHK(PAY_GROUP_ID, @an_peb_phm_mst_id, @d_sta_ymd)
	IF @@ROWCOUNT < 1
		set @v_pay_group = ''
    RETURN @v_pay_group
END

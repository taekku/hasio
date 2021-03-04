DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
DECLARE @results TABLE (
    log_id	numeric(38)
)
SET NOCOUNT ON;

set @an_try_no = 2 -- �õ�ȸ��( ���� [��ȣ + �Ķ����]�� �α׸� ���� )
-- TODO: ���⿡�� �Ű� ���� ���� �����մϴ�.
set @av_company_cd = 'E'
	IF OBJECT_ID('tempdb.dbo.#PAY_GROUP_TYPE')IS NOT NULL
		DROP TABLE #PAY_GROUP_TYPE
	CREATE TABLE #PAY_GROUP_TYPE (
    --PAY_GROUP_TYPE_ID	numeric	(18,0),
		COMPANY_CD	nvarchar(10),
		PAY_GROUP	nvarchar(10),
		PAY_TYPE_CD	nvarchar(10),
		STA_YMD	date	,
		END_YMD	date	,
		NOTE	nvarchar(200),
		MOD_USER_ID	numeric(	38,0),
		MOD_DATE	datetime2	,
		TZ_CD	nvarchar(	10),
		TZ_DATE	datetime2	
		)
-- ==============================================
-- PAY_GROUP_USER
-- ==============================================
	--
	insert into #PAY_GROUP_TYPE (
    --PAY_GROUP_TYPE_ID	numeric	(18,0),
		COMPANY_CD,
		PAY_GROUP,
		PAY_TYPE_CD,
		STA_YMD,
		END_YMD,
		NOTE,
		MOD_USER_ID,
		MOD_DATE,
		TZ_CD,
		TZ_DATE
		)
	SELECT 
		A.COMPANY_CD,
		B.PAY_GROUP,
		A.PAY_TYPE_CD,
		A.STA_YMD,
		A.END_YMD,
		A.NOTE,
		A.MOD_USER_ID,
		A.MOD_DATE,
		A.TZ_CD,
		A.TZ_DATE
	  FROM PAY_GROUP_TYPE A
	  JOIN PAY_GROUP B
	    ON A.PAY_GROUP_ID = B.PAY_GROUP_ID
	 WHERE B.COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
	-- �޿��׷�����
	DELETE FROM PAY_GROUP_USER
	 WHERE PAY_GROUP_ID IN (SELECT PAY_GROUP_ID FROM PAY_GROUP WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%')
	DELETE FROM PAY_GROUP
	 WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
	-- �ڷ���ȯ
	EXECUTE @n_log_h_id = dbo.P_CNV_PAY_GROUP
			   @an_try_no
			  ,@av_company_cd
	INSERT INTO @results (log_id) VALUES (@n_log_h_id)
	DELETE PAY_GROUP_TYPE
	 WHERE COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
	INSERT INTO PAY_GROUP_TYPE (
        PAY_GROUP_TYPE_ID,
		COMPANY_CD,
		PAY_GROUP_ID,
		PAY_TYPE_CD,
		STA_YMD,
		END_YMD,
		NOTE,
		MOD_USER_ID,
		MOD_DATE,
		TZ_CD,
		TZ_DATE
		)
	SELECT
        NEXT VALUE FOR S_PAY_SEQUENCE AS PAY_GROUP_TYPE_ID,
		A.COMPANY_CD,
		B.PAY_GROUP_ID,
		A.PAY_TYPE_CD,
		A.STA_YMD,
		A.END_YMD,
		A.NOTE,
		A.MOD_USER_ID,
		A.MOD_DATE,
		A.TZ_CD,
		A.TZ_DATE
	  FROM #PAY_GROUP_TYPE A
	  JOIN PAY_GROUP B
	    ON A.COMPANY_CD = B.COMPANY_CD
	   AND A.PAY_GROUP = B.PAY_GROUP
	 WHERE B.COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
-- ==============================================

-- ==============================================
-- �α����Ϻ���
-- ==============================================
SELECT *
  FROM CNV_PAY_WORK A
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)
SELECT *
  FROM CNV_PAY_WORK_LOG B
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)
 --and ERR_MSG not like '%�����ڵ�%'

GO
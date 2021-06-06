/*
 * HRD�� ���� ��ȯ�մϴ�.
 */
DECLARE @n_log_h_id numeric
DECLARE @an_try_no int
DECLARE @av_company_cd nvarchar(10)
	, @av_fr_month		NVARCHAR(6)		-- ���۳��
	, @av_to_month		NVARCHAR(6)		-- ������
	, @av_fg_supp		NVARCHAR(2)		-- �޿�����
	, @av_dt_prov		NVARCHAR(08)	-- �޿�������
	, @v_work_kind		nvarchar(10)    -- D:������
DECLARE @results TABLE (
    log_id	numeric(38)
)
DECLARE @bundle TABLE (
	FR_MONTH NVARCHAR(6),
	TO_MONTH NVARCHAR(6)
)
SET NOCOUNT ON;

set @an_try_no = 3 -- �õ�ȸ��( ���� [��ȣ + �Ķ����]�� �α׸� ���� )
-- TODO: ���⿡�� �Ű� ���� ���� �����մϴ�.
-- M(��������):201501 ~ �����
set @av_company_cd = 'M'
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201501','201512')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201601','201612')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201701','201712')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201801','201812')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('201901','201912')
--insert into @bundle(FR_MONTH, TO_MONTH) values ('202001','202012')
insert into @bundle(FR_MONTH, TO_MONTH) values ('202101','202105')

DECLARE CNV_PAY_CUR CURSOR READ_ONLY FOR
SELECT FR_MONTH, TO_MONTH
  FROM @bundle
;

OPEN CNV_PAY_CUR
WHILE 1=1
	BEGIN
		FETCH NEXT FROM CNV_PAY_CUR
			      INTO @av_fr_month, @av_to_month
		IF @@FETCH_STATUS <> 0 BREAK
		BEGIN TRY
	
		--set @av_dt_prov = '20200125'
		--set @v_work_kind = 'D' -- ������ ó�� Yes!
		-- ==============================================
		-- �޿������̰�(�޿�����(�����))
		-- ==============================================
			-- �ڷ����
			DELETE FROM PAY_PAYROLL_DETAIL
			 WHERE BEL_PAY_YMD_ID in (select PAY_YMD_ID from PAY_PAY_YMD t
								   where company_cd like ISNULL(@av_company_cd,'') + '%'
									 and t.PAY_YM between @av_fr_month and @av_to_month
								 )
			-- �ڷ����
			DELETE FROM PAY_PAYROLL
			 WHERE PAY_YMD_ID in (select PAY_YMD_ID from PAY_PAY_YMD
								   where company_cd like ISNULL(@av_company_cd,'') + '%'
									 and PAY_YM between @av_fr_month and @av_to_month
								 )
			-- �޿����ڻ���
			DELETE
			from PAY_PAY_YMD
			where company_cd like ISNULL(@av_company_cd,'') + '%'
				and PAY_YM between @av_fr_month and @av_to_month
			-- �ڷ���ȯ
			IF ISNULL(@v_work_kind, '') <> 'D'
				BEGIN
					EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PAYROLL_NEW
					  @an_try_no		-- �õ�ȸ��
					, @av_company_cd	-- ȸ���ڵ�
					, @av_fr_month		-- ���۳��
					, @av_to_month		-- ������
					, @av_fg_supp		-- �޿�����
					, @av_dt_prov		-- �޿�������
					INSERT INTO @results (log_id) VALUES (@n_log_h_id)
					-- DWEHR_HRD�� ���� �޿��̰�
					EXECUTE @n_log_h_id = dbo.P_CNV_PAY_PAYROLL_HRD
					  @an_try_no		-- �õ�ȸ��
					, @av_company_cd	-- ȸ���ڵ�
					, @av_fr_month		-- ���۳��
					, @av_to_month		-- ������
					, @av_fg_supp		-- �޿�����
					, @av_dt_prov		-- �޿�������
					INSERT INTO @results (log_id) VALUES (@n_log_h_id)
				END
		-- ==============================================
		-- DSUM , TSUM ����
		UPDATE PAY
		   SET DSUM = DTL.DAMT, TSUM = DTL.TAMT
		  FROM PAY_PAYROLL PAY
		  JOIN PAY_PAY_YMD YMD
			ON YMD.PAY_YMD_ID = PAY.PAY_YMD_ID
		  JOIN (SELECT PAY_PAYROLL_ID
					 , ISNULL(SUM(CASE WHEN PAY_ITEM_TYPE_CD='DEDUCT' THEN CAL_MON ELSE 0 END),0) AS DAMT
					 , ISNULL(SUM(CASE WHEN PAY_ITEM_TYPE_CD='TAX' THEN CAL_MON ELSE 0 END),0) AS TAMT
				 FROM PAY_PAYROLL_DETAIL  GROUP BY PAY_PAYROLL_ID) DTL
			ON PAY.PAY_PAYROLL_ID = DTL.PAY_PAYROLL_ID
		 WHERE YMD.COMPANY_CD like ISNULL(@av_company_cd,'') + '%'
		   AND YMD.PAY_YM BETWEEN @av_fr_month AND @av_to_month
		END TRY
		BEGIN CATCH
			PRINT ERROR_NUMBER()
			PRINT ERROR_MESSAGE()
		END CATCH
	END
CLOSE CNV_PAY_CUR
DEALLOCATE CNV_PAY_CUR
-- ==============================================
-- �α����Ϻ���
-- ==============================================
SELECT *
  FROM CNV_PAY_WORK A
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)
SELECT CNV_PAY_WORK_ID, KEYS, ERR_MSG, LOG_DATE
  FROM CNV_PAY_WORK_LOG B
 WHERE CNV_PAY_WORK_ID IN (SELECT log_id FROM @results)

GO

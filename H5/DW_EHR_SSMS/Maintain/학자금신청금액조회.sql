DECLARE @company_cd nvarchar(10) = 'H'
DECLARE @emp_id numeric(38)
DECLARE @appl_id numeric(38)=0
DECLARE @sch_grd_cd nvarchar(10) = '10'
DECLARE @fam_nm nvarchar(10) = '���Ͽ�'
DECLARE @group_ymd date = '19980801'
DECLARE @hire_ymd date = '19980801'
DECLARE @appl_year nvarchar(10) = '2021'
DECLARE @edu_pos nvarchar(10) = '1'
DECLARE @sce_edu_term nvarchar(10) = '1'

select @emp_id = EMP_ID
from VI_FRM_PHM_EMP
where COMPANY_CD='H'
--and EMP_NO='20160576'
and EMP_NM='����ö'
and LOCALE_CD='KO'

SELECT TOT_APPL_CNT		--������Ƚ��
      ,TOT_APPL_AMT
	  ,TOT_CONFIRM_AMT
	  ,YEAR_APPL_AMT	--�������û�ݾ�
	  ,TERM_APPL_AMT	--�б��û�ݾ�
	  ,CONG_EXIST_YN	--�������ϱ� ����ɿ���
	  ,ALLOW_POINT		--������������
 	  ,(SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	      FROM SEC_EDU
	     WHERE COMPANY_CD = @company_cd
	       AND EMP_ID = @emp_id
	       AND SCH_GRD_CD = @sch_grd_cd
	       --AND dbo.F_FRM_DECRYPT_C(FAM_CTZ_NO) = fam_ctz_no 
	       AND dbo.XF_TRIM(FAM_NM) = @fam_nm
	       AND PAY_YN = 'Y' 
	       AND ISNULL(RETURN_YN,'N') <> 'Y'
	       AND ISNULL(POINT,0) < T2.ALLOW_POINT  --3
	       --AND (EDU_POS <> '1' AND SCE_EDU_TERM <> '1') --1�г�1�б� ������������
	       AND EDU_POS + SCE_EDU_TERM <> '11' --1�г�1�б� ������������
	   ) AS ALLOW_POINT_SKIP_YN --�����������ع̸� ��û�ǿ���(1ȸ�̻�������(Y) ������������üũ�ϰ� ������ 1ȸ�� ���Ͽ� ��û����)
	  ,ISNULL(SCH_LIMIT_CNT,99999) as SCH_LIMIT_CNT	--�����ο�����
	  ,SCH_TOT_CNT		--������ο�
	  ,CASE WHEN SCH_TOT_CNT >= ISNULL(SCH_LIMIT_CNT,99999) THEN 'N' ELSE 'Y' END AS SCH_LIMIT_YN --�����ο����� �ʰ�����(Y->��û����)
	  ,ISNULL(ALLOW_PERIOD,99999) as ALLOW_PERIOD		--�����б����
	  ,ALLOW_TOT_PERIOD --�б����к� �����ڳ� ���û�б�
	  ,CASE WHEN ALLOW_TOT_PERIOD >= ISNULL(ALLOW_PERIOD,99999) THEN 'N' ELSE 'Y' END AS ALLOW_PERIOD_LIMIT_YN --�����б���� �ʰ�����(Y->��û����)
	  ,WORK_YEAR		--�ټӳ������
	  ,WORK_STD_MD		--�ټӱ��ؿ���
	  ,DATEDIFF(YEAR,@group_ymd,ISNULL(WORK_STD_MD,GETDATE())) + 1 AS WORK_YY --�ټӳ��
	  ,CASE WHEN DATEDIFF(YEAR,@group_ymd,ISNULL(WORK_STD_MD,GETDATE())) + 1 >= WORK_YEAR THEN 'Y' ELSE 'N' END AS WORK_YY_YN --�ټӳ�� ��������(Y->��û����)
	  ,HIRE_STD_YMD		--�Ի����������
	  ,CASE WHEN HIRE_STD_YMD IS NULL THEN 'Y' ELSE CASE WHEN @hire_ymd > HIRE_STD_YMD THEN 'N' ELSE 'Y' END END AS HIRE_STD_YN --�Ի���������� ���� ��û���ɿ���(Y->��û����)
	  ,(SELECT CASE WHEN COUNT(RET_VAL) > 0 THEN 'Y' ELSE 'N' END
		  FROM (
				SELECT dbo.F_SEC_GROUP_CHK(SEC_APPL_CD_STD_ID, @emp_id, GETDATE()) as RET_VAL
				  FROM SEC_APPL_CD_STD 
				 WHERE COMPANY_CD = @company_cd
				   AND SCH_GRD_CD = @sch_grd_cd
		   	   ) A
		 WHERE RET_VAL <> 0) AS SEC_GROUP_CHK_YN --������ ���� (Y->��û����)
  FROM (
		SELECT TOT_APPL_CNT
				,TOT_APPL_AMT
				,TOT_CONFIRM_AMT
				,YEAR_APPL_AMT		--�������û�ݾ�
				,TERM_APPL_AMT		--�б��û�ݾ�
				,(SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
					FROM SEC_EDU_DET A
						INNER JOIN SEC_STD_ITEM B ON A.ITEM_CD = B.ITEM_CD
					WHERE A.SEC_EDU_ID IN (SELECT A.SEC_EDU_ID
											FROM SEC_EDU A 
											     INNER JOIN SEC_EDU_APPL B 
											     ON A.SEC_EDU_APPL_ID = B.SEC_EDU_APPL_ID
											WHERE A.COMPANY_CD = @company_cd
											AND A.EMP_ID = @emp_id
											--AND dbo.F_FRM_DECRYPT_C(A.FAM_CTZ_NO) = fam_ctz_no
	       									AND dbo.XF_TRIM(A.FAM_NM) = @fam_nm
											AND A.SCH_GRD_CD = @sch_grd_cd
											--AND B.STAT_CD = '132'
											AND A.PAY_YN = 'Y' 
											AND ISNULL(A.RETURN_YN,'N') <> 'Y'
										) 
					AND B.CONG_YN = 'Y'
				) AS CONG_EXIST_YN	--�������ϱ� ����ɿ���
				,(SELECT ISNULL(ALLOW_POINT,0) FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS ALLOW_POINT		--������������
				,(SELECT SCH_LIMIT_CNT FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS SCH_LIMIT_CNT		--�����ο�����
				
				--,(SELECT COUNT(*) FROM (SELECT A.FAM_CTZ_NO FROM SEC_EDU A INNER JOIN SEC_EDU_APPL B ON A.SEC_EDU_APPL_ID = B.SEC_EDU_APPL_ID WHERE A.COMPANY_CD = company_cd AND A.EMP_ID = emp_id AND A.SCH_GRD_CD = sch_grd_cd AND dbo.F_FRM_DECRYPT_C(A.FAM_CTZ_NO) <> fam_ctz_no  AND B.STAT_CD = '132' GROUP BY A.FAM_CTZ_NO) D) AS SCH_TOT_CNT   -- ������ο�
				,(SELECT COUNT(*) FROM (SELECT FAM_CTZ_NO FROM SEC_EDU WHERE COMPANY_CD = @company_cd AND EMP_ID = @emp_id AND SCH_GRD_CD = @sch_grd_cd AND dbo.XF_TRIM(FAM_NM) <> @fam_nm  AND PAY_YN = 'Y' AND ISNULL(RETURN_YN,'N') <> 'Y' GROUP BY FAM_CTZ_NO) D) AS SCH_TOT_CNT   -- ������ο�
				
				,(SELECT ALLOW_PERIOD FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS ALLOW_PERIOD		--�����б����
				
				--,(SELECT COUNT(*) FROM (SELECT DISTINCT A.SCH_GRD_CD, A.APPL_YEAR, A.SCE_EDU_TERM FROM SEC_EDU A INNER JOIN SEC_EDU_APPL B ON A.SEC_EDU_APPL_ID = B.SEC_EDU_APPL_ID WHERE A.COMPANY_CD = company_cd AND A.EMP_ID = emp_id AND A.SCH_GRD_CD = sch_grd_cd AND dbo.F_FRM_DECRYPT_C(A.FAM_CTZ_NO) = fam_ctz_no  AND B.STAT_CD = '132') A) AS ALLOW_TOT_PERIOD   -- ���û�б�(�б�����,�⵵,�б� �������� ���ҽ�û���� �Ѱ����� ����)
				,(SELECT COUNT(*) FROM (SELECT DISTINCT SCH_GRD_CD, APPL_YEAR, SCE_EDU_TERM FROM  SEC_EDU WHERE COMPANY_CD = @company_cd AND EMP_ID = @emp_id AND SCH_GRD_CD = @sch_grd_cd AND dbo.XF_TRIM(FAM_NM) = @fam_nm  AND PAY_YN = 'Y' AND ISNULL(RETURN_YN,'N') <> 'Y') A) AS ALLOW_TOT_PERIOD   -- ���û�б�(�б�����,�⵵,�б� �������� ���ҽ�û���� �Ѱ����� ����)
				
				,(SELECT ISNULL(WORK_YEAR,0) FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS WORK_YEAR		--�ټӳ������
				,(SELECT dbo.XF_TO_DATE(dbo.XF_TO_CHAR_N(datepart(year,GETDATE()),null) + WORK_STD_MD,'YYYYMMDD') FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS WORK_STD_MD		--�ټӱ��ؿ���
				,(SELECT HIRE_STD_YMD FROM SEC_STD WHERE COMPANY_CD = @company_cd AND SCH_GRD_CD = @sch_grd_cd AND GETDATE() BETWEEN STA_YMD AND END_YMD) AS HIRE_STD_YMD		--�Ի����������
			FROM (
				SELECT ISNULL(SUM(CASE WHEN B.APPL_ID != @appl_id AND (A.PAY_YN = 'Y' OR B.STAT_CD NOT IN ('131','132','133')) AND ISNULL(A.RETURN_YN,'N') <> 'Y' THEN 1 ELSE 0 END),0) AS TOT_APPL_CNT
						,ISNULL(SUM(CASE WHEN B.APPL_ID != @appl_id AND (A.PAY_YN = 'Y' OR B.STAT_CD NOT IN ('131','132','133')) AND ISNULL(A.RETURN_YN,'N') <> 'Y' THEN A.APPL_AMT ELSE 0 END),0) AS TOT_APPL_AMT
						,ISNULL(SUM(CASE WHEN B.APPL_ID != @appl_id AND A.PAY_YN = 'Y' AND ISNULL(A.RETURN_YN,'N') <> 'Y' THEN A.CONFIRM_AMT ELSE 0 END),0) AS TOT_CONFIRM_AMT
						,ISNULL(SUM(CASE WHEN B.APPL_ID != @appl_id AND (A.PAY_YN = 'Y' OR B.STAT_CD NOT IN ('131','132','133')) AND ISNULL(A.RETURN_YN,'N') <> 'Y' AND A.APPL_YEAR = @appl_year THEN APPL_AMT ELSE 0 END),0) AS YEAR_APPL_AMT	--������û�ݾ�
						,ISNULL(SUM(CASE WHEN B.APPL_ID != @appl_id AND (A.PAY_YN = 'Y' OR B.STAT_CD NOT IN ('131','132','133')) AND ISNULL(A.RETURN_YN,'N') <> 'Y' AND A.APPL_YEAR = @appl_year AND A.EDU_POS = @edu_pos AND A.SCE_EDU_TERM=@sce_edu_term THEN APPL_AMT ELSE 0 END),0) AS TERM_APPL_AMT	--�б��û�ݾ�
					FROM SEC_EDU A 
					     INNER JOIN SEC_EDU_APPL B 
					     ON A.SEC_EDU_APPL_ID = B.SEC_EDU_APPL_ID
					WHERE A.COMPANY_CD = @company_cd
					AND A.EMP_ID = @emp_id
					--AND dbo.F_FRM_DECRYPT_C(A.FAM_CTZ_NO) = fam_ctz_no
					AND dbo.XF_TRIM(A.FAM_NM) = @fam_nm
					AND A.SCH_GRD_CD = @sch_grd_cd
				) T1
		) T2
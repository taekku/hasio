SELECT CD, CD_NM
     , (SELECT PAY_GROUP_ID FROM PAY_GROUP WHERE COMPANY_CD=CODE.COMPANY_CD AND PAY_GROUP=CODE.CD) PAY_GROUP_ID
  FROM FRM_CODE CODE
 WHERE COMPANY_CD='I'
   AND CD_KIND='PAY_GROUP_CD'
   AND CD LIKE 'IB%'

DECLARE @company_cd nvarchar(10)
      , @pay_ymd date
select @company_cd = 'I'
     , @pay_ymd = '20200121'
SELECT NULL PAY_STANDBY_ID -- �������ID
     , @pay_ymd AS PAY_YMD -- ��������
	 , EMP_NO
	 , ORG_CD
	 , ORG_NM
	 , POS_CD
	 , HIRE_YMD
	 , SHIP_STA_YMD
	 , SHIP_END_YMD
	 , BASE_AMT
	 , STAN_F_YMD
	 , STAN_T_YMD
	 , DATEDIFF(day, STAN_F_YMD, STAN_T_YMD) + 1 STAN_CNT -- ����ϼ�
	 , PAY_RATE
	 , PAY_AMT
	 , NOTE
  FROM (SELECT EMP.EMP_ID -- ���ID
		 , EMP.EMP_NO -- �����ȣ
		 , EMP.EMP_NM -- ����
		 , EMP.ORG_CD -- �μ�
		 , dbo.F_FRM_ORM_ORG_NM( ORG_ID, LOCALE_CD, dbo.XF_SYSDATE(0), '11' ) AS ORG_NM
		 , EMP.POS_CD -- ����
		 , EMP.HIRE_YMD -- �Ի�����
		 , SHIP_STA_YMD -- �¼�����
		 , SHIP_END_YMD -- �ϼ�����
		 -- ������� : ������ ���� ��/ȣ���� ���� �⺻�� ���� �������� �޿�����Ÿ�� �⺻������ �˻�
		 , (SELECT TOP 1 PAY_AMT
			  FROM PAY_HOBONG H
			  INNER JOIN PAY_SHIP_RATE S
					  ON H.SHIP_CD = S.SHIP_CD -- ����
					 AND H.SHIP_CD_D = S.SHIP_CD_D
					 AND H.COMPANY_CD = S.COMPANY_CD
					 AND @pay_ymd BETWEEN S.STA_YMD AND S.END_YMD
					 AND @pay_ymd BETWEEN H.STA_YMD AND H.END_YMD
			 WHERE H.COMPANY_CD = EMP.COMPANY_CD
			   AND S.ORG_ID = EMP.ORG_ID
			   AND H.STA_YMD <= @pay_ymd
			   AND H.PAY_POS_GRD_CD = EMP.POS_GRD_CD -- ����
			   AND H.POS_CD = EMP.POS_CD -- ����
			   AND H.PAY_GRADE = EMP.YEARNUM_CD
			 ORDER BY H.STA_YMD DESC) BASE_AMT -- ���رݾ�
		 -- �Ի��ϰ� �����ش�� 1���� ū ��¥
		 , CASE WHEN dbo.XF_TO_DATE(dbo.XF_TO_CHAR_D(@pay_ymd, 'yyyymm01'), 'yyyymmdd') > EMP.HIRE_YMD
				THEN dbo.XF_TO_DATE(dbo.XF_TO_CHAR_D(@pay_ymd, 'yyyymm01'), 'yyyymmdd')
				ELSE EMP.HIRE_YMD END AS STAN_F_YMD -- ����������
		 -- �¼��߷��� �ִ°�� �߷��� ���ϱ���
		 -- �¼��߷��� ���°�� �����ش�� ���ϱ���
		 --, CASE WHEN SHIP_STA_YMD IS NOT NULL THEN SHIP_STA_YMD - 1
			--	ELSE dbo.XF_LAST_DAY(@pay_ymd) END AS STAN_T_YMD -- �븮��������
		 , CASE WHEN SHIP_STA_YMD IS NULL OR dbo.XF_TO_CHAR_D(SHIP_STA_YMD,'yyyymm') > dbo.XF_TO_CHAR_D(@pay_ymd, 'yyyymm')
					THEN dbo.XF_LAST_DAY(@pay_ymd)
				ELSE SHIP_STA_YMD - 1 END STAN_T_YMD -- �����������
		 --, DATEDIFF(day, STAN_F_YMD, STAN_E_YMD) STAN_CNT -- ����ϼ�
		 , CAST(100 AS NUMERIC(5,2)) PAY_RATE -- ������
		 , 0 PAY_AMT -- ���ޱݾ�
		 , NULL NOTE -- ���
	  FROM VI_FRM_PHM_EMP EMP
	  INNER JOIN PAY_PHM_EMP PAY
			  ON EMP.EMP_ID = PAY.EMP_ID
			 AND EMP.COMPANY_CD = PAY.COMPANY_CD
			 AND EMP.COMPANY_CD = @company_cd
	  LEFT OUTER JOIN (SELECT EMP_ID, MAX(CAM_YMD) AS SHIP_STA_YMD
						 FROM CAM_HISTORY
						WHERE COMPANY_CD = @company_cd
						  AND TYPE_CD = '11' -- �����¼�
						GROUP BY EMP_ID
						) HIS_S
					ON EMP.EMP_ID = HIS_S.EMP_ID
	  LEFT OUTER JOIN (SELECT EMP_ID, MAX(CAM_YMD) AS SHIP_END_YMD
						 FROM CAM_HISTORY
						WHERE COMPANY_CD = @company_cd
						  AND TYPE_CD = '1A' -- �����ϼ�
						GROUP BY EMP_ID
						) HIS_E
					ON EMP.EMP_ID = HIS_E.EMP_ID
	 WHERE EMP.IN_OFFI_YN = 'Y' -- ��������
	   AND SHIP_END_YMD IS NULL -- �ϼ���������
		   -- 20100118 �¼����ڰ� ���ų� �������ں��� ũ�ų�������츸 ���
	   AND (SHIP_STA_YMD IS NULL OR SHIP_STA_YMD >= @pay_ymd)
	   AND EMP.HIRE_YMD <= @pay_ymd -- ���� ����ϴ´� ���� ���� �Ի��ڸ�
	   AND EMP.COMPANY_CD = @company_cd --* �����ڵ�
	   AND PAY.EMP_CLS_CD = 'S' --* �������(������ ���Ͽ�)
	  -- AND (
	) M
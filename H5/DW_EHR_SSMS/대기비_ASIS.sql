select H_HUMAN.NO_PERSON, H_HUMAN.NM_PERSON, DT_RETIRE, TP_CALC_INS, DT_JOIN, DT_F_SHIP, DT_T_SHIP,
-- ������� : ������ ���� ��/ȣ���� ���� �⺻�� ���� �������� �޿�����Ÿ�� �⺻������ �˻�
        (CASE WHEN H_PAY_MASTER.TP_CALC_INS = 'S' AND H_HUMAN.CD_COMPANY = 'I' THEN
                 ISNULL(( SELECT TOP 1 H_PAY_LEVEL_V.AMT_ALLOW      
                          FROM H_PAY_LEVEL_V WITH (NOLOCK)
                               INNER JOIN  H_SHIP_BASE_RULE1  WITH (NOLOCK)
                                  ON H_PAY_LEVEL_V.CD_COMPANY = H_SHIP_BASE_RULE1.CD_COMPANY
                                 AND H_PAY_LEVEL_V.TP_SHIP    = H_SHIP_BASE_RULE1.TP_SHIP
                                 AND H_PAY_LEVEL_V.TP_SHIP_D  = H_SHIP_BASE_RULE1.TP_SHIP_D
                          WHERE H_PAY_LEVEL_V.CD_COMPANY = 'I'    -- ȸ���ڵ�
                          AND H_PAY_LEVEL_V.CD_ALLOW = '001'      -- �⺻��
                          AND H_PAY_LEVEL_V.DT_APPLY <= '20200930'     -- param�����Ѿ�� ��������
                          AND H_PAY_LEVEL_V.LVL_PAY1 = H_HUMAN.LVL_PAY1
                          AND H_PAY_LEVEL_V.LVL_PAY2 = H_HUMAN.LVL_PAY2
                          AND H_PAY_LEVEL_V.CD_POSITION = H_HUMAN.CD_POSITION
                          AND H_SHIP_BASE_RULE1.CD_SHIP = H_HUMAN.CD_DEPT
                          ORDER BY H_PAY_LEVEL_V.DT_APPLY DESC), 0) 
        ELSE 0 END) AS AMT_BASE
  FROM  H_HUMAN INNER JOIN H_PAY_MASTER
                        ON H_HUMAN.CD_COMPANY = H_PAY_MASTER.CD_COMPANY
                       AND H_HUMAN.NO_PERSON = H_PAY_MASTER.NO_PERSON
 WHERE  ( ISNULL(H_HUMAN.DT_RETIRE, '') = '' OR H_HUMAN.DT_RETIRE = '00000000' ) -- ��������
   AND  ISNULL(H_HUMAN.DT_T_SHIP, '') = '' -- �ϼ���������
   --��� ������
   --�Ի��ϰ� �����ش�� 1���� ū ��¥
   AND  (ISNULL(H_HUMAN.DT_F_SHIP, '') = '' OR ISNULL(H_HUMAN.DT_F_SHIP, '') >= '20200930') -- �¼����ڰ� �����Ϻ��� ū
   AND  ISNULL(H_HUMAN.DT_JOIN, '') <= '20200930' -- ���� ����ϴ´� ���� ���� �Ի��ڸ�
   AND  H_HUMAN.CD_COMPANY = 'I'              --* �����ڵ�
   -- �μ�
   AND  H_PAY_MASTER.TP_CALC_INS = 'S'       --* �������(������ ���Ͽ�)
   
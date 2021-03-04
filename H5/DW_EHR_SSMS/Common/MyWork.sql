USE [dwehrdev_H5]
GO

SELECT mgr.FRM_UNIT_STD_MGR_ID,
       mgr.LOCALE_CD,
       mgr.COMPANY_CD,
       mgr.UNIT_CD,
       mgr.KEY1,
       mgr.KEY2,
       mgr.KEY3,
       mgr.KEY4,
       mgr.KEY5,
       mgr.STD_KIND,
       mgr.STD_KIND_NM,
       mgr.FUNCTION_CM,
       mgr.SQL,
       mgr.CHANGE_YN,
       mgr.NOTE AS MGR_NOTE
  FROM FRM_UNIT_STD_MGR mgr
 WHERE mgr.UNIT_CD = 'REP'
  AND mgr.STD_KIND_NM LIKE concat('%', '�ӿ�' , '%')
  AND mgr.LOCALE_CD = 'KO'
  AND mgr.COMPANY_CD = 'E'
;

select dbo.F_FRM_UNIT_STD_HIS ('E',
                              'KO',
                              'REP', -- 
                              'REP_EXE_MUL',
                              '001',
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              getdATE(),
                              '6'
    --                          '1'  : Ű�ڵ�1,   '2'  : Ű�ڵ�2,   '3'  : Ű�ڵ�3,    '4'  : Ű�ڵ�4,   '5'  : Ű�ڵ�5
    --                          '6'  : �ڵ�1,     '7'  : �ڵ�2,     '8'  :  �ڵ�3,     '9'  : �ڵ�4,     '10' : �ڵ�5
    --                          '11' : ��Ÿ�ڵ�1, '12' : ��Ÿ�ڵ�2, '13' :  ��Ÿ�ڵ�3, '14' : ��Ÿ�ڵ�4, '15' : ��Ÿ�ڵ�5
                              ) AS REP_OFFICER_RATE
select dbo.F_FRM_UNIT_STD_VALUE('E',
                              'KO',
                              'REP',
                              'REP_EXE_MUL',
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              '001',
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              getdATE(),
                              'H1'
    --                          'H1'  : �ڵ�1,     'H2'  : �ڵ�2,     'H3'  :  �ڵ�3,     'H4'  : �ڵ�4,     'H5' : �ڵ�5
    --                          'E1' : ��Ÿ�ڵ�1,   'E2' : ��Ÿ�ڵ�2, 'E3' :  ��Ÿ�ڵ�3, 'E4' : ��Ÿ�ڵ�4, 'E5' : ��Ÿ�ڵ�5
                              ) AS REP_OFFICER_RATE
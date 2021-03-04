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
  AND mgr.STD_KIND_NM LIKE concat('%', '임원' , '%')
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
    --                          '1'  : 키코드1,   '2'  : 키코드2,   '3'  : 키코드3,    '4'  : 키코드4,   '5'  : 키코드5
    --                          '6'  : 코드1,     '7'  : 코드2,     '8'  :  코드3,     '9'  : 코드4,     '10' : 코드5
    --                          '11' : 기타코드1, '12' : 기타코드2, '13' :  기타코드3, '14' : 기타코드4, '15' : 기타코드5
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
    --                          'H1'  : 코드1,     'H2'  : 코드2,     'H3'  :  코드3,     'H4'  : 코드4,     'H5' : 코드5
    --                          'E1' : 기타코드1,   'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
                              ) AS REP_OFFICER_RATE
select dbo.F_FRM_UNIT_STD_HIS ('E', 'KO', 'REP', 'REP_EXE_MUL',
                              '001', NULL, NULL, NULL, NULL,
                              getdATE(),
                              '2'
    --                          '1'  : 키코드1,   '2'  : 키코드2,   '3'  : 키코드3,    '4'  : 키코드4,   '5'  : 키코드5
    --                          '6'  : 코드1,     '7'  : 코드2,     '8'  :  코드3,     '9'  : 코드4,     '10' : 코드5
    --                          '11' : 기타코드1, '12' : 기타코드2, '13' :  기타코드3, '14' : 기타코드4, '15' : 기타코드5
                              ) AS REP_OFFICER_RATE
;
select dbo.F_FRM_UNIT_STD_VALUE ('E', 'KO', 'REP', 'REP_EXE_MUL',
                              NULL, NULL, NULL, NULL, NULL,
                              '001', NULL, NULL, NULL, NULL,
                              getdATE(),
                              'H1' -- 'H1' : 코드1,     'H2' : 코드2,     'H3' :  코드3,     'H4' : 코드4,     'H5' : 코드5
							       -- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
                              ) AS REP_OFFICER_RATE
;
-- 급여항목유형
select dbo.F_FRM_UNIT_STD_VALUE ('E', 'KO', 'PAY', 'PAY_ITEM_CD_BASE',
                              NULL, NULL, NULL, NULL, NULL,
                              'C01', NULL, NULL, NULL, NULL,
                              getdATE(),
                              'H1' -- 'H1' : 코드1,     'H2' : 코드2,    'H3' :  코드3,    'H4' : 코드4,    'H5' : 코드5
							       -- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
                              ) AS PAY_ITEM_TYPE_CD
;

declare @av_company_cd nvarchar(10)
      , @av_locale_cd nvarchar(10)
set @av_company_cd = 'E'
set @av_locale_cd = 'KO'
select dbo.F_FRM_UNIT_STD_VALUE (@av_company_cd, @av_locale_cd, 'PEB', 'PEB_BASE_POS',
								NULL, NULL, NULL, NULL, NULL,
								'EA01', '421', NULL, NULL, NULL,
								--getDate(),
								'20210922',
								'H1' -- 'H1' : 코드1,     'H2' : 코드2,     'H3' :  코드3,     'H4' : 코드4,     'H5' : 코드5
																		-- 'E1' : 기타코드1, 'E2' : 기타코드2, 'E3' :  기타코드3, 'E4' : 기타코드4, 'E5' : 기타코드5
								)
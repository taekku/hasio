DELETE FROM REP_INSUR_MON ;

INSERT INTO REP_INSUR_MON (
						   REP_INSUR_MON_ID,		-- 퇴직보험금ID
						   EMP_ID,					-- 사원ID
						   INS_TYPE_CD,				-- 퇴직연금구분
						   MIX_YN,					-- 혼합형여부
						   HEADE_YN,				-- 임원여부
						   EMP_MON,					-- 사용자부담금
						   BASE_MON,				-- 산출기준금액
						   INSUR_NM,				-- 연금회사
						   IRP_BANK_CD,				-- 연금은행코드[PAY_BANK_CD]
						   IRP_ACCOUNT_NO,			-- 계좌번호
						   INSUR_BIZ_NO,			-- 사업자번호
						   IRP_EXPIRATION_YMD,		-- 만료일자
						   STA_YMD,					-- 시작일
						   END_YMD,					-- 종료일
						   NOTE,					-- 비고
						   MOD_USER_ID,				-- 변경자
						   MOD_DATE,				-- 변경일
						   TZ_CD,					-- 타임존코드
						   TZ_DATE					-- 타임존일시
						  )
                    SELECT NEXT VALUE FOR dbo.S_REP_SEQUENCE AS REP_INSUR_MON_ID,		-- 퇴직보험금ID
						   B.EMP_ID,					-- 사원ID
						   CASE WHEN A.CD_RETR_ANNU = 'DB' THEN '10'
						        WHEN A.CD_RETR_ANNU = 'DC' THEN '20'
								ELSE '00'
						   END AS CALC_TYPE_CD,			-- 정산구분
						   'N' AS MIX_YN,				-- 혼합형여부
						   'N' AS HEADE_YN,				-- 임원여부
						   0 AS EMP_MON,				-- 사용자부담금
						   0 AS BASE_MON,				-- 산출기준금액
						   A.NM_BANK_IRP AS INSUR_NM,		-- 연금회사
						   CASE A.CD_BANK_IRP WHEN '002' THEN '002' -- 산업은행002 	산업은행
											  WHEN '003' THEN '003' -- 기업은행003 	NULL
											  WHEN '004' THEN '004' -- 국민은행004 	국민은행
                                              WHEN '005' THEN '005' -- 외환은행005	KEB하나은행
											  WHEN '011' THEN '011' -- 중앙농협011	농협중앙회
											  WHEN '012' THEN '012' -- 단위농협012  단위농협
                                              WHEN '020' THEN '020' -- 우리은행020	우리
											  WHEN '023' THEN '023' -- SC은행023	SC제일은행(제일은행)023
											  WHEN '026' THEN '026' -- 신한은행026	신한은행
											  WHEN '03' THEN '03'   -- 중소기업은행03 기업은행
											  WHEN '031' THEN '031' -- 대구은행031	대구은행
											  WHEN '032' THEN '032' -- 부산은행032	부산은행
											  WHEN '034' THEN '034' -- 광주은행034	광주은행
											  WHEN '039' THEN '039' -- 경남은행039	경남은행
											  WHEN '04' THEN '04'   -- 국민은행04	KB국민은행
											  WHEN '05' THEN '05'   -- 외환은행05	외환은행
											  WHEN '071' THEN '071' -- 우체국(정보통신부)071
											  WHEN '081' THEN '081' -- 하나은행     KEB하나은행
											  WHEN '088' THEN '088' -- 신한은행(신한조흥)088	신한은행(신한조흥)088
											  WHEN '090' THEN '090' -- 카카오뱅크090	카카오뱅크
											  WHEN '11' THEN '11'   -- 중앙농협11
											  WHEN '190' THEN '11'  -- 중앙농협11
											  WHEN '12' THEN '12'   -- 단위농협12
										      WHEN '20' THEN '20'	-- 우리은행(한빛은행)20
											  WHEN '304' THEN '20'  -- 우리은행(한빛은행)20
											  WHEN '209' THEN '209' -- 동양종합금융증권209
											  WHEN '218' THEN '218' -- KB증권	KB증권
											  WHEN '230' THEN '230' -- 미래에셋증권230	미래에셋증권
											  WHEN '240' THEN '240' -- 삼성증권240	삼성증권
											  WHEN '243' THEN '243' -- 한국투자증권243 한국투자증권
											  WHEN '510' THEN '243' -- 한국투자증권243 한국투자증권
											  WHEN '26' THEN '26'   -- 신한은행26	신한
											  WHEN '262' THEN '262' -- 하이투자증권262	한국투자증권
											  WHEN '269' THEN '269' -- 한화증권269	한화생명
											  WHEN '31' THEN '31'   -- 대구은행31	대구은행
											  WHEN '311' THEN '34'  -- 광주은행341	광주은행34
											  WHEN '32' THEN '32'   -- 부산은행32	부산은행
											  WHEN '34' THEN '34'   -- 광주은행34	광주
											  WHEN '35' THEN '35'   -- 제주은행35	제주은행
											  WHEN '39' THEN '39'   -- 경남은행39	경남은행
											  WHEN '71' THEN '71'   -- 우체국(정보통신부)71
											  WHEN '81' THEN '81'   -- 하나은행81
											  WHEN '88' THEN '88'   -- 신한은행(신한조흥)88
											  ELSE NULL
						   END AS IRP_BANK_CD,		-- 연금은행코드[PAY_BANK_CD]
						   A.NO_BANK_ACCNT_IRP AS IRP_ACCOUNT_NO,	-- 계좌번호
						   A.BIZ_NO_IRP AS INSUR_BIZ_NO,			-- 사업자번호
						   NULL AS IRP_EXPIRATION_YMD,		-- 만료일자
						   dbo.XF_TO_DATE('19000101', 'YYYYMMDD') AS STA_YMD,	-- 시작일
						   dbo.XF_TO_DATE('29991231', 'YYYYMMDD') AS END_YMD,	-- 종료일
						   NULL AS NOTE,					-- 비고
						   0 AS MOD_USER_ID,				-- 변경자
						   dbo.XF_SYSDATE(0) AS MOD_DATE,	-- 변경일
						   'KST' AS TZ_CD,					-- 타임존코드
						   dbo.XF_SYSDATE(0) AS TZ_DATE		-- 타임존일시
					  FROM [DWEHRDEV].DBO.H_PAY_MASTER A
						INNER JOIN PHM_EMP B
						   ON A.CD_COMPANY = B.COMPANY_CD
						  AND A.NO_PERSON = B.EMP_NO ;  
						  

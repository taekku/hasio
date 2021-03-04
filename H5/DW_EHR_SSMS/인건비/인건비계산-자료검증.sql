DECLARE @tmp_emp_no TABLE (
			EMP_NO NVARCHAR(20),
			PRIMARY KEY (EMP_NO)
		)
DECLARE @an_peb_base_id numeric
	  , @av_cal_emp_no nvarchar(10)
	  , @v_pay_item_cd nvarchar(10)
	  , @an_mod_user_id numeric
	  , @av_tz_cd nvarchar(10)
	  , @PEB_PHM_MST_ID	numeric
	  , @EMP_NO nvarchar(10)
-- 값지정
set @an_peb_base_id = 107123
set @av_cal_emp_no = '20140002'

INSERT INTO @tmp_emp_no(EMP_NO)
	SELECT ITEMS
	  FROM dbo.fn_split_array(@av_cal_emp_no, ',')

--select *
--from @tmp_emp_no

SELECT MST.PEB_PHM_MST_ID
		     , MST.EMP_NO
				 , MST.SALARY_TYPE_CD
			FROM PEB_PHM_MST MST
			JOIN @tmp_emp_no EMP
			  ON MST.PEB_BASE_ID = @an_peb_base_id
			 AND MST.EMP_NO = EMP.EMP_NO
		 WHERE (1=1)
		   AND MST.PEB_BASE_ID = @an_peb_base_id
		 ORDER BY MST.PEB_PHM_MST_ID--, PAY.PEB_YM

set @PEB_PHM_MST_ID = 127361
set @EMP_NO = '20140002'
set @v_pay_item_cd = 'P001'

SELECT --NEXT VALUE FOR S_PEB_SEQUENCE PEB_PAYROLL_DET_ID,
						A.PEB_PAYROLL_ID, --	인건비계획대상자ID
						@v_pay_item_cd	PAY_ITEM_CD, --	급여항목코드
						C.BASE_SALARY AS	CAM_AMT, --	계산금액
						NULL	NOTE, --	비고
						@an_mod_user_id	MOD_USER_ID, --	변경자
						SYSDATETIME()	MOD_DATE, --	변경일
						@av_tz_cd	TZ_CD, --	타임존코드
						SYSDATETIME()	TZ_DATE --	타임존일시
				  FROM PEB_PAYROLL A
				  JOIN PEB_CNM_CNT C
					ON A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID
				   AND C.PEB_BASE_ID = @an_peb_base_id
				   AND C.EMP_NO = @EMP_NO
				   AND A.PEB_YM BETWEEN dbo.XF_TO_CHAR_D(STA_YMD, 'yyyymm') AND dbo.XF_TO_CHAR_D( END_YMD, 'yyyymm')
--select *
--from PEB_PHM_MST MST
--where PEB_PHM_MST_ID = @PEB_PHM_MST_ID

--select *
--from PEB_PAYROLL A
--where A.PEB_PHM_MST_ID = @PEB_PHM_MST_ID

--select *
--from PEB_CNM_CNT C
--where C.PEB_BASE_ID = @an_peb_base_id
--				   AND C.EMP_NO = @EMP_NO
--				   AND '202101' BETWEEN dbo.XF_TO_CHAR_D(STA_YMD, 'yyyymm') AND dbo.XF_TO_CHAR_D( END_YMD, 'yyyymm')

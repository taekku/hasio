DECLARE @av_company_cd nvarchar(10) = 'E'
      , @av_locale_cd nvarchar(10) = 'KO'
	  , @ad_pay_ymd date = '20200930'
	  , @av_pay_grd_cd nvarchar(10) = 'EA01'
	  , @n_emp_id	numeric(38)
	  , @v_emp_no	nvarchar(10) = '20140002'--'20125540' /*연숙자*/
	  , @n_pay_group_id numeric(38)
	  , @v_work_ym	nvarchar(10) = '202009'
set @ad_pay_ymd = dbo.XF_LAST_DAY( @v_work_ym + '01' )
select @n_pay_group_id = PAY_GROUP_ID
  FROM PAY_GROUP
 WHERE PAY_GROUP = @av_pay_grd_cd
   AND GETDATE() BETWEEN STA_YMD AND END_YMD
   AND COMPANY_CD = @av_company_cd

select @n_emp_id = EMP_ID
  FROM PHM_EMP EMP
 WHERE EMP.COMPANY_CD = @av_company_cd
   AND EMP.EMP_NO = @v_emp_no
--SELECT *
--FROM VI_FRM_PHM_EMP EMP
--WHERE EMP.EMP_ID=@n_emp_id
--PRINT 'pay_group_id= ' + convert(varchar(100), @n_pay_group_id)
--PRINT 'emp_id= ' + convert(varchar(100), @n_emp_id)
	  --SELECT 
			--					   A.KEY_CD1 AS PAY_GRPCD,
			--					   A.KEY_CD2 AS PAY_DTM_CD,
			--					   A.KEY_CD3 AS DTM_ITEM_CD
			--			  FROM FRM_UNIT_STD_HIS A,
			--				   FRM_UNIT_STD_MGR B
			--			 WHERE A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
			--			   AND B.LOCALE_CD  = @av_locale_cd
			--			   AND B.COMPANY_CD = @av_company_cd
			--			   AND B.UNIT_CD    = 'PAY'
			--			   AND B.STD_KIND   = 'PAY_DTM_MST_MAP'   
			--			   AND A.KEY_CD1	= @av_pay_grd_cd
			--			   AND @ad_pay_ymd BETWEEN A.STA_YMD AND A.END_YMD

select A.*, A.WORK_YM, A.EMP_ID, PAY_GRPCD
    , PAY_DTM_CD
	, dbo.F_FRM_CODE_NM(@av_company_cd, @av_locale_cd, 'PAY_ITEM_CD', PAY_DTM_CD, GETDATE(), '1') ITEM_NM
	, DTM_ITEM_CD
	, dbo.F_FRM_CODE_NM(@av_company_cd, @av_locale_cd, 'DTM_MONTH_ITEM_CD', DTM_ITEM_CD, GETDATE(), '1') DTM_ITEM_NM
	, B.ITEM_VAL
	, B.*
	-- , SUM(B.ITEM_VAL) ITEM_VAL
FROM DTM_MONTH A --JOIN PHM_EMP EMP ON (A.EMP_ID=EMP.EMP_ID AND EMP.COMPANY_CD = @av_company_cd)
INNER JOIN DTM_MONTH_DTL B ON (B.DTM_MONTH_ID = A.DTM_MONTH_ID) 
				INNER JOIN (SELECT 
								   A.KEY_CD1 AS PAY_GRPCD,
								   A.KEY_CD2 AS PAY_DTM_CD,
								   A.KEY_CD3 AS DTM_ITEM_CD
						  FROM FRM_UNIT_STD_HIS A,
							   FRM_UNIT_STD_MGR B
						 WHERE A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
						   AND B.LOCALE_CD  = @av_locale_cd
						   AND B.COMPANY_CD = @av_company_cd
						   AND B.UNIT_CD    = 'PAY'
						   AND B.STD_KIND   = 'PAY_DTM_MST_MAP'   
						   AND A.KEY_CD1	= @av_pay_grd_cd
						   AND @ad_pay_ymd BETWEEN A.STA_YMD AND A.END_YMD
						   ) C ON C.DTM_ITEM_CD = B.MONTH_ITEM_CD
WHERE WORK_YM = @v_work_ym
AND dbo.F_PAY_GROUP_CHK(@n_pay_group_id, A.EMP_ID, GETDATE()) = @n_pay_group_id
AND A.EMP_ID = @n_emp_id
--AND B.ITEM_VAL != 0
--GROUP BY A.WORK_YM, A.EMP_ID, PAY_GRPCD, PAY_DTM_CD

--SELECT *
--FROM PHM_EMP
--WHERE EMP_ID=56584
;

--select A.*, B.*
--	-- , SUM(B.ITEM_VAL) ITEM_VAL
--FROM DTM_MONTH A JOIN PHM_EMP EMP ON (A.EMP_ID=EMP.EMP_ID AND EMP.COMPANY_CD = @av_company_cd)
--INNER JOIN DTM_MONTH_DTL B ON (B.DTM_MONTH_ID = A.DTM_MONTH_ID) 
--where 1=1
----and A.EMP_ID = @n_emp_id
--and A.WORK_YM = @v_work_ym
--order by WORK_YM
--SELECT A.*
--     , B.DTM_MONTH_CD
--	 , B.MONTH_ITEM_CD
--	 , dbo.F_FRM_CODE_NM(@av_company_cd, @av_locale_cd, 'DTM_MONTH_ITEM_CD', MONTH_ITEM_CD, GETDATE(), '1') DTM_ITEM_NM
--	 , B.ITEM_VAL, B.PUSH_PATH
--FROM DTM_MONTH A --JOIN PHM_EMP EMP ON (A.EMP_ID=EMP.EMP_ID AND EMP.COMPANY_CD = @av_company_cd)
--INNER JOIN DTM_MONTH_DTL B ON (B.DTM_MONTH_ID = A.DTM_MONTH_ID) 
--WHERE A.EMP_ID = @n_emp_id
--AND A.WORK_YM = @v_work_ym
--AND ITEM_VAL != 0

-- 기초원장
--SELECT *
--FROM PAY_MST_CHANGE A
--JOIN PAY_PAY_YMD YMD
--ON A.PAY_YMD_ID = YMD.PAY_YMD_ID
--WHERE YMD.PAY_YM = @v_work_ym

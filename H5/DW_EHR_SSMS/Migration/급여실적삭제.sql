DECLARE @av_company_cd varchar(10) = 'E'
      , @av_fr_month varchar(10) = '200801'
	  , @av_to_month varchar(10) = '201412'
			-- 자료삭제
			DELETE FROM PAY_PAYROLL_DETAIL
			 WHERE BEL_PAY_YMD_ID in (select PAY_YMD_ID from PAY_PAY_YMD t
								   where company_cd like ISNULL(@av_company_cd,'') + '%'
									 and t.PAY_YM between @av_fr_month and @av_to_month
								 )
			-- 자료삭제
			DELETE FROM PAY_PAYROLL
			 WHERE PAY_YMD_ID in (select PAY_YMD_ID from PAY_PAY_YMD
								   where company_cd like ISNULL(@av_company_cd,'') + '%'
									 and PAY_YM between @av_fr_month and @av_to_month
								 )
			-- 급여일자삭제
			DELETE
			from PAY_PAY_YMD
			where company_cd like ISNULL(@av_company_cd,'') + '%'
				and PAY_YM between @av_fr_month and @av_to_month
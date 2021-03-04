
DECLARE	@av_company_cd               VARCHAR(10) = 'E',   -- 인사영역
       @an_emp_id                   NUMERIC(38) = 55109,   -- 사원id
       @ad_base_ymd                 DATE = '20190602',     -- 기준일자
       @ad_retire_ymd               DATE  = '20200601'    -- 퇴직일자
-- dbo.F_REP_LAST_PAY_YMD_DW('E', 55109, dbo.XF_TO_DATE('20190602', 'YYYYMMDD'), dbo.XF_TO_DATE('20200601', 'YYYYMMDD')) AS CHK_4
BEGIN
   DECLARE
         @return_ymd		DATE,
		 @return_n		NUMERIC(38),
		 @d_pay_ymd			DATE,
		 @d_chk_ymd			DATE,
		 @d_base_ymd		DATE = @ad_base_ymd,
		 @d_pay_end_ymd		DATE,
		 @v_pay_excep_yn	NVARCHAR(1) = 'N',
		 @d_pay_excep_ymd	DATE,
         @n_seq				NUMERIC(38) = 0
PRINT 'Function Start: ' + CONVERT(VARCHAR(100), @n_seq) + ' : ' + CONVERT(VARCHAR(100), @ad_base_ymd)
      WHILE 1 = 1
      
         BEGIN
		    SET @n_seq = @n_seq + 1
PRINT '' + CONVERT(VARCHAR(100), @n_seq) + ' : ' + CONVERT(VARCHAR(100), @ad_base_ymd)
            BEGIN
			   SELECT TOP 1 @d_pay_ymd = A.PAY_YMD -- MAX(A.PAY_YMD)
				 FROM PAY_PAY_YMD A
					INNER JOIN PAY_PAYROLL B ON (A.PAY_YMD_ID = B.PAY_YMD_ID)
					INNER JOIN PAY_PAYROLL_DETAIL C ON (B.PAY_PAYROLL_ID = C.PAY_PAYROLL_ID)
			    WHERE PAY_TYPE_CD IN (SELECT CD
							   		   FROM FRM_CODE
									  WHERE COMPANY_CD = 'E'
										AND CD_KIND = 'PAY_TYPE_CD'
										AND SYS_CD = '001' 
									 )
				  AND B.EMP_ID = @an_emp_id
				  AND C.PAY_ITEM_CD IN ('P001')
				  AND C.CAL_MON > 0
				  AND A.PAY_YMD < @d_base_ymd
				ORDER BY A.PAY_YMD DESC

                  IF @@ERROR <> 0 OR @@ROWCOUNT = 0 OR @d_pay_ymd IS NULL
                     BEGIN
                        SET @return_ymd = @ad_retire_ymd  -- 퇴직일자로 설정
						print 'RETURN1 - 급여일읽기 :' + convert(varchar(100), @return_ymd)
						      + '/' + CASE WHEN @d_pay_ymd is NULL then 'Null' else convert(varchar(100), @d_pay_ymd) end
						goto endFunction
						--RETURN @return_ymd
                     END 
PRINT '급여일(' + CONVERT(VARCHAR(100), @n_seq) + ') : ' + CONVERT(VARCHAR(100), isnull(@d_pay_ymd,'19000101'))
            END

            
			SET @v_pay_excep_yn = 'N'

			-- 해당 급여일자가 휴직중에 반영된 급여내역인지 확인
			PRINT @v_pay_excep_yn
			BEGIN
			  SELECT TOP 1 @v_pay_excep_yn = 'Y'
			        ,@d_pay_excep_ymd = T.STA_YMD
			    FROM (
					  SELECT STA_YMD      
						   , END_YMD      
					    FROM CAM_TERM_MGR      
					   WHERE ITEM_NM = 'LEAVE_CD'      
					     AND VALUE IN (SELECT CD      
									     FROM FRM_CODE      
									    WHERE CD_KIND = 'REP_EXCE_TYPE_CD'        
										  AND LOCALE_CD = 'KO'      
										  AND COMPANY_CD = 'E'  
										  AND SYS_CD = '10'
										  AND @d_pay_ymd BETWEEN STA_YMD AND END_YMD)      
					     AND EMP_ID = @an_emp_id
					     AND @d_pay_ymd BETWEEN STA_YMD AND END_YMD
					UNION
					  SELECT STA_YMD
						   , END_YMD
					    FROM DTM_DAILY_APPL   --일근태내역
					   WHERE WORK_CD IN (SELECT CD      
									       FROM FRM_CODE      
									      WHERE CD_KIND = 'REP_EXCE_TYPE_CD'        
										    AND LOCALE_CD = 'KO'      
										    AND COMPANY_CD = 'E'  
										    AND SYS_CD = '20'
										    AND @d_pay_ymd BETWEEN STA_YMD AND END_YMD)
					     AND EMP_ID = @an_emp_id
					     AND @d_pay_ymd BETWEEN STA_YMD AND END_YMD	
				  ) T

				IF @@ERROR != 0  --OR @@ROWCOUNT = 0
					BEGIN
						SET @return_ymd = @ad_retire_ymd  -- 퇴직일자로 설정
						print 'RETURN2 - CAM_TERM_MGR OR DTM_DAILY_APPL :' + convert(varchar(100), @return_ymd)
						goto endFunction
						--RETURN @return_ymd
					END
			END

			IF @v_pay_excep_yn = 'Y'
			   BEGIN
			      SET @d_base_ymd = dbo.XF_DATEADD(@d_pay_excep_ymd, - 1)
				  --SET @d_chk_ymd = dbo.XF_DATEADD(@d_pay_excep_ymd, - 1)
			   END
			ELSE
			   BEGIN
			      IF dbo.XF_TO_NUMBER(dbo.XF_TO_CHAR_D(@d_base_ymd, 'DD')) >= 1
				     BEGIN
					    SET @d_pay_end_ymd = dbo.XF_DATEADD(dbo.XF_TO_DATE(dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_base_ymd,'YYYYMMDD'),1,6) + '01', 'YYYYMMDD'), - 1)
						print 'RETURN3 - @v_pay_excep_yn = ' + isnull(@v_pay_excep_yn,'Null') + ':' + convert(varchar(100), @d_pay_end_ymd)
						goto endFunction
						--RETURN @d_pay_end_ymd
						--SET @d_chk_ymd = dbo.XF_DATEADD(dbo.XF_TO_DATE(dbo.XF_SUBSTR(dbo.XF_TO_CHAR_D(@d_base_ymd,'YYYYMMDD'),1,6) + '01', 'YYYYMMDD'), - 1)
					 END
			   END
			 

            IF @n_seq >= 10  -- 10횟 초과면 강제 종료
               BEGIN
			      /* 무한 loop 방지*/
                  --RETURN @ad_retire_ymd
						print 'RETURN3 - 횟수초과'
						goto endFunction
				  --RETURN dbo.XF_TO_DATE('19000101', 'YYYYMMDD')
               END

        END

		 IF @v_pay_excep_yn = 'N'
		    BEGIN
			   SET @return_ymd = @d_pay_end_ymd
			END
			
         print 'RETURN not Reach -  '  + @v_pay_excep_yn
		 --RETURN @return_ymd
		 --RETURN @v_pay_excep_yn

		 endFunction:
		 print '끝 @n_seq=' + convert(varchar(100), @n_seq)
END
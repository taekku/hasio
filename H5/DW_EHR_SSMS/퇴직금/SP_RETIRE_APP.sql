USE [dwehrdev]
GO
/****** Object:  StoredProcedure [dbo].[SP_RETIRE_APP]    Script Date: 2020-11-30 오전 10:54:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Create date: <Create Date,,2014.04>
-- Description:	<Description,,개인별퇴직충당금현황 >
-- 
-- =============================================
/* Execute Sample 
H_ERRORLOG

 DECLARE 
      @p_error_code VARCHAR(30), 
      @p_error_str VARCHAR(500) 
 BEGIN
      SET @p_error_code = ''; 
      SET @p_error_str = ''; 
      EXECUTE SP_RETIRE_APP
      'I',
      '20140331',
      '',		
      '',
      '',
      'kgw0329',
      @p_error_code OUTPUT,		-- @p_error_code      VARCHAR(30) 
      @p_error_str OUTPUT 		-- @p_error_str       VARCHAR(500) 
 END

select * from h_retire_app 
ORDER BY CD_DEPT, NO_PERSON

*/
ALTER PROCEDURE [dbo].[SP_RETIRE_APP] (
							  @p_cd_company		 VARCHAR(10),						-- 회사코드
							  @p_dt_base		 VARCHAR(8) ,						-- 품의일자  
                              @p_pay_group		 VARCHAR(10),						-- 급여ith(그룹
                              @p_cd_biz_area     VARCHAR(8),						-- 신고사업장
                              
                              --@P_retr_annu       VARCHAR(10),                       -- 연급종류
                              --@p_tp_duty         VARCHAR(2),                        -- 관리구분
                              --@p_fr_Dept         VARCHAR(10),                       -- 부서코드(From)
                              --@p_to_Dept         VARCHAR(10),                       -- 부서코드(To)
                              @p_no_person       VARCHAR(10),                       -- 사원
							  @p_id_user		 VARCHAR(20) ,						-- 사용자ID
                              @p_error_code      VARCHAR(1000) OUTPUT,				-- 에러코드 리턴
                              @p_error_str       VARCHAR(3000) OUTPUT				-- 에러메시지 리턴
                              )                                                                              
AS
SET NOCOUNT ON


DECLARE 
--	@p_cd_company	NVARCHAR(10),
--	@p_dt_base		NVARCHAR(8),
--	@p_dt_base6		NVARCHAR(6),
	--@V_CD_PAY_GP	NVARCHAR(8),
	--@V_CD_BIZ_AREA	NVARCHAR(8),
	--@V_NO_PERSON	NVARCHAR(10),
	--@p_id_user		NVARCHAR(20),
	@v_RSN_PAYGP_WHERE nvarchar(2000),
	@v_sql			VARCHAR(MAX),


/* BEGIN CATCH 사용할 변수 정의  */
	@v_error_number				INT,
	@v_error_severity			INT,
	@v_error_state				INT,
	@v_error_procedure			VARCHAR(1000),
	@v_error_line				INT,
	@v_error_message			VARCHAR(3000),

	/* ERR_HANDLER 사용할 변수 정의 */
	@v_error_num			    INT,
	@v_row_count				INT,
	@v_error_code				VARCHAR(1000),										-- 에러코드
	@v_error_note				VARCHAR(3000)										-- 에러노트 (exec : '문자열A|문자열B')

BEGIN TRY


	--if @p_pay_group <> ''
	-- select @v_RSN_PAYGP_WHERE = RSN_PAYGP_WHERE from H_PAY_GROUP where CD_COMPANY=@p_cd_company and CD_PAYGP=@p_pay_group

 
 --Select no_person from h_month_pay_bonus where cd_company = 'I'
	--						 and ym_pay='201406' and cd_paygp ='IA01'

--IF @p_pay_group <>''
--	 SET @v_sql = @v_sql +'
--			and H_HUMAN.no_person in (select no_person from h_month_pay_bonus where cd_company = '''+@p_cd_company+'''
--							 and ym_pay='''+LEFT(@p_dt_base,6)+''' and cd_paygp ='''+@p_pay_group+')'''
						SELECT * FROM H_RETIRE_APP WHERE CD_COMPANY='I' AND DT_BASE='20140630'	
--IF NOT EXISTS (
--	SELECT * FROM H_RETIRE_APP 
--	WHERE CD_COMPANY = @p_cd_company
--		AND DT_BASE = @p_dt_base )
--BEGIN
	 SET @v_sql = 'DELETE FROM H_RETIRE_APP 
				  WHERE CD_COMPANY = '''+@p_cd_company+'''
				  AND DT_BASE  = '''+@p_dt_base+'''';
			  	  
	IF @p_pay_group <> '' AND @p_cd_company <> 'I'
	 SET @v_sql = @v_sql +'
			and no_person in (select no_person from h_month_pay_bonus where cd_company = '''+@p_cd_company+'''
							 and ym_pay='''+LEFT(@p_dt_base,6)+''' and cd_paygp ='''+@p_pay_group+''') ';
							 
	IF @p_pay_group <> '' AND @p_cd_company = 'I'
	BEGIN
		IF @p_pay_group = 'A'
			SET @v_sql = @v_sql +'
			and TP_DUTY in (''A'',''8'') AND CD_DEPT NOT LIKE ''5%'' ';
		ELSE IF @p_pay_group = 'B'  
			SET @v_sql = @v_sql +'
			and TP_DUTY = ''B'' OR ( CD_DEPT LIKE ''5%'' AND TP_DUTY =''A'') ';
		ELSE
			SET @v_sql = @v_sql +'
			and TP_DUTY = '''+@p_pay_group+'''';
	END					 					 
	--PRINT(	@v_sql);				 				 	
	--EXEC(@v_sql);

	SET @v_sql = @v_sql + '
	INSERT H_RETIRE_APP([CD_COMPANY]      ,[DT_BASE]      ,[CD_DEPT]      ,[NM_DEPT]
				  ,[CD_COST]      ,[NM_COST]      ,[NO_PERSON]      ,[NM_PERSON]
				  ,[TP_DUTY]      ,[CD_RETR_ANNU]      ,[AMT_RETR_PAY]      ,[OLD_AMT_RETR_PAY]
				  ,[AMT_MINUS_RETR_PAY]      ,[AMT_NEW_RETR_PAY]      ,[AMT_F_JANAK]      ,[AMT_PAY]
				  ,[AMT_ADD]      ,[AMT_T_JANAK]
				  ,[ID_INSERT]      ,[DT_INSERT]      ,[ID_UPDATE]      ,[DT_UPDATE])
				  SELECT  H_HUMAN.CD_COMPANY,
							H_RET.DT_BASE,
   							H_HUMAN.CD_DEPT,
   							H_HUMAN.NM_DEPT,
   							-- 코스트
   							X.CD_COST,
   							X.NM_COST,
   							H_HUMAN.NO_PERSON,
   							H_HUMAN.NM_PERSON,
   							H_HUMAN.TP_DUTY,
   							-- 연금종류 H_PAY_MASTER
   							Y.CD_RETR_ANNU,
   							-- 당월퇴직추계액
   							H_RET.AMT_RETR_PAY,';
   							
   IF (@p_cd_company in( 'A','B','C') AND SUBSTRING(@p_dt_base,5,2) = '12' ) OR (@p_cd_company NOT IN ( 'A','B','C') AND SUBSTRING(@p_dt_base,5,2) = '01' )
   BEGIN
 
		 SET @v_sql = @v_sql +'	-- abc전월퇴직추계액
                       			--CASE WHEN Y.CD_RETR_ANNU = ''DC'' and left(isnull(H_HUMAN.DT_RETIRE,''''),6) <> ''' + LEFT(@p_dt_base,6) + ''' THEN 0 ELSE H_RET.OLD_AMT_RETR_PAY END AS OLD_AMT_RETR_PAY,
                       			H_RET.OLD_AMT_RETR_PAY,
                       			-- 당월-전월
                       			--(H_RET.AMT_RETR_PAY - CASE WHEN Y.CD_RETR_ANNU = ''DC'' and left(isnull(H_HUMAN.DT_RETIRE,''''),6) <> ''' + LEFT(@p_dt_base,6) + ''' THEN 0 ELSE H_RET.OLD_AMT_RETR_PAY END) AS AMT_MINUS_RETR_PAY,
                       			(H_RET.AMT_RETR_PAY -  H_RET.OLD_AMT_RETR_PAY ) AS AMT_MINUS_RETR_PAY,
                       			-- 당월전입액 = 지급액 + (당월-전월)
                       			--H_RET.AMT_PAY + (H_RET.AMT_RETR_PAY - CASE WHEN Y.CD_RETR_ANNU = ''DC'' and left(isnull(H_HUMAN.DT_RETIRE,''''),6) <> ''' + LEFT(@p_dt_base,6) + ''' THEN 0 ELSE H_RET.OLD_AMT_RETR_PAY END) AS AMT_NEW_RETR_PAY,
                       			H_RET.AMT_PAY  + (H_RET.AMT_RETR_PAY- H_RET.OLD_AMT_RETR_PAY) AS AMT_NEW_RETR_PAY, '
               	
   
   END
   ELSE
   BEGIN
	   SET @v_sql = @v_sql +' -- 전월퇴직추계액
   							 H_RET.OLD_AMT_RETR_PAY,
   							-- 당월-전월
   							(H_RET.AMT_RETR_PAY -  H_RET.OLD_AMT_RETR_PAY) AS AMT_MINUS_RETR_PAY,
   							-- 당월전입액 = 지급액 + (당월-전월)
   							H_RET.AMT_PAY + (H_RET.AMT_RETR_PAY - H_RET.OLD_AMT_RETR_PAY) AS AMT_NEW_RETR_PAY,'
   							
   END								

   							
   	SET @v_sql = @v_sql +'-- 기초잔액(전년도12월)
   							H_RET.AMT_F_JANAK,
   							-- 지급액(퇴직금,추계액모두합산)
   							H_RET.AMT_PAY,
   							-- 증가액은 0
   							0 AS AMT_ADD,
   							-- 기말잔액 = 기초잔액 + 지급액
   							( H_RET.AMT_F_JANAK + H_RET.AMT_PAY ) AS AMT_T_JANAK,
   							'''+@p_id_user+''',
   							GETDATE(),
   							'''+@p_id_user+''',
   							GETDATE()
				   			
 					FROM H_HUMAN WITH (NOLOCK) INNER JOIN
						   ( SELECT	M.CD_COMPANY,
               						M.NO_PERSON, M.FG_RETPENSION_KIND, 
               						-- 전월퇴직추계액
               						ISNULL(
               						case when M.FG_RETPENSION_KIND=''DC'' and  substring(M.DT_BASE, 5,2)=''01'' then 0 
               						else
               						(SELECT SUM(N.AMT_RETR_PAY)
             									  FROM H_RETIRE_APP N WITH(NOLOCK)
             									 WHERE N.CD_COMPANY = '''+@p_cd_company+'''  
             									   AND LEFT(N.DT_BASE, 6) = LEFT(CONVERT(VARCHAR(8), DATEADD(MM, -1,'''+LEFT(@p_dt_base,6)+'''+''01''), 112),6)--(당해년도의 전월)' 
	--if @p_cd_biz_area <> ''
	--	SET @v_sql = @v_sql +'     									   AND N.CD_BIZ_AREA = '''+@p_cd_biz_area+'';
	if @p_no_person <> ''
		SET @v_sql = @v_sql +'
		     									   AND N.NO_PERSON = '''+@p_no_person+'''';
		
     SET @v_sql = @v_sql +' 
         									   AND N.NO_PERSON = M.NO_PERSON)
         									   end, 0) AS OLD_AMT_RETR_PAY,
             					 -- 당월퇴직추계액
             					 ISNULL(SUM(M.AMT_RETR_PAY), 0) AS AMT_RETR_PAY,
             					 -- 기초잔액
             					 ISNULL((SELECT SUM(N.AMT_RETR_PAY)
           	 						   FROM H_RETIRE_DETAIL N WITH(NOLOCK)
            							  WHERE N.CD_COMPANY = '''+@p_cd_company+'''
           								AND LEFT(N.DT_RETR, 6) = LEFT(CONVERT(VARCHAR(8), DATEADD(YY, -1,'''+LEFT(@p_dt_base,4)+'''+''1201''), 112),6) -- (현재년도의 전년도의 12월) ' 
   
  --  if @p_cd_biz_area <> ''
		--SET @v_sql = @v_sql +'     									   AND N.CD_BIZ_AREA = '''+@p_cd_biz_area+'';
	if @p_no_person <> ''
		SET @v_sql = @v_sql +' 
		    									   AND N.NO_PERSON = '''+@p_no_person+'''';
		
		      								
     SET @v_sql = @v_sql +'
           								AND N.NO_PERSON = M.NO_PERSON), 0) AS AMT_F_JANAK,
             					 -- 지급액
             					 ISNULL((SELECT SUM(N.AMT_RETR_PAY)
               						   FROM H_RETIRE_DETAIL N WITH(NOLOCK)
               						  WHERE N.CD_COMPANY = '''+@p_cd_company+'''
               							AND N.FG_RETR IN (''1'',''4'')
               							AND LEFT(N.DT_RETR, 6) = '''+LEFT(@p_dt_base,6)+'''  -- (기준일자)'
               							
  --  if @p_cd_biz_area <> ''
		--SET @v_sql = @v_sql +'     									   AND N.CD_BIZ_AREA = '''+@p_cd_biz_area+'';
	if @p_no_person <> ''
		SET @v_sql = @v_sql +' 
		    									   AND N.NO_PERSON = '''+@p_no_person+'''';           							
    
               							
    SET @v_sql = @v_sql +' 
              							AND N.NO_PERSON = M.NO_PERSON), 0) AS AMT_PAY,
							 -- 증가액 0
							 0 AS AMT_ADD
							 , M.DT_BASE
						   FROM H_RETIRE_DETAIL M WITH (NOLOCK) 
						  WHERE M.CD_COMPANY = '''+@p_cd_company+''' 
							AND M.FG_RETR = ''2''  -- 퇴직추계액
							AND LEFT(M.DT_RETR, 6) = '''+LEFT(@p_dt_base,6)+'''  -- 당월퇴직추계액
				            
					   GROUP BY M.CD_COMPANY, M.NO_PERSON, M.FG_RETPENSION_KIND ,M.DT_BASE ) H_RET 
				   ON ( H_HUMAN.CD_COMPANY = H_RET.CD_COMPANY
				  AND H_HUMAN.NO_PERSON    = H_RET.NO_PERSON )
				 LEFT OUTER JOIN H_PER_MATCH X WITH (NOLOCK) 
				   ON H_HUMAN.CD_COMPANY = X.CD_COMPANY
				  AND H_HUMAN.NO_PERSON  = X.NO_PERSON
				 LEFT OUTER JOIN H_PAY_MASTER Y WITH (NOLOCK) 
				   ON H_HUMAN.CD_COMPANY = Y.CD_COMPANY
				  AND H_HUMAN.NO_PERSON  = Y.NO_PERSON
				WHERE H_HUMAN.CD_COMPANY =  '''+@p_cd_company+'''' 
				
	IF @p_pay_group <> '' AND @p_cd_company <> 'I'
	 SET @v_sql = @v_sql +'
						and H_HUMAN.no_person in (select no_person from h_month_pay_bonus where cd_company = '''+@p_cd_company+'''
							 and ym_pay='''+LEFT(@p_dt_base,6)+''' and cd_paygp ='''+@p_pay_group+''')';			
	
	IF @p_pay_group <> '' AND @p_cd_company = 'I'
	BEGIN
		IF @p_pay_group = 'A'
			SET @v_sql = @v_sql +'
			and H_HUMAN.TP_DUTY in (''A'',''8'') AND H_HUMAN.CD_DEPT NOT LIKE ''5%'' ';
		ELSE IF @p_pay_group = 'B'  
			SET @v_sql = @v_sql +'
			and H_HUMAN.TP_DUTY = ''B'' OR ( H_HUMAN.CD_DEPT LIKE ''5%'' AND H_HUMAN.TP_DUTY =''A'') ';
		ELSE
			SET @v_sql = @v_sql +'
			and H_HUMAN.TP_DUTY = '''+@p_pay_group+'''';
	END		
	

	SET @v_sql = @v_sql +' 
	SELECT * FROM H_RETIRE_APP A WITH(NOLOCK) 
				  INNER JOIN H_HUMAN 
					ON  A.CD_COMPANY = H_HUMAN.CD_COMPANY 
						AND A.NO_PERSON = H_HUMAN.NO_PERSON
	WHERE A.CD_COMPANY = '''+@p_cd_company+'''
		AND A.DT_BASE = '''+@p_dt_base+'''';
		
	--if @p_cd_biz_area <> ''
	--	SET @v_sql = @v_sql +'  AND H_HUMAN.CD_BIZ_AREA = '''+@p_cd_biz_area+'';
	if @p_no_person <> ''
		SET @v_sql = @v_sql +'
		  AND A.NO_PERSON = '''+@p_no_person+'''';         	

	--if @p_pay_group <> ''
	--	SET @v_sql = @v_sql +'  AND '+@v_RSN_PAYGP_WHERE
	
	IF @p_pay_group <>'' AND @p_cd_company <> 'I'
	 SET @v_sql = @v_sql +'
						and H_HUMAN.no_person in (select no_person from h_month_pay_bonus where cd_company = '''+@p_cd_company+'''
							 and ym_pay='''+LEFT(@p_dt_base,6)+''' and cd_paygp ='''+@p_pay_group+''')';
	
	IF @p_pay_group <> '' AND @p_cd_company = 'I'
	BEGIN
		IF @p_pay_group = 'A'
			SET @v_sql = @v_sql +'
			and H_HUMAN.TP_DUTY in (''A'',''8'') AND H_HUMAN.CD_DEPT NOT LIKE ''5%'' ';
		ELSE IF @p_pay_group = 'B'  
			SET @v_sql = @v_sql +'
			and H_HUMAN.TP_DUTY = ''B'' OR ( H_HUMAN.CD_DEPT LIKE ''5%'' AND H_HUMAN.TP_DUTY =''A'') ';
		ELSE
				SET @v_sql = @v_sql +'
			and H_HUMAN.TP_DUTY = '''+@p_pay_group+'''';
	END							 
		
	SET @v_sql = @v_sql +'
				 ORDER BY A.CD_DEPT, A.NO_PERSON';
	
	
--	print(@v_sql)
	EXEC(@v_sql);


	---- 전월퇴직추계액
	--	ISNULL((SELECT SUM(N.AMT_RETR_PAY)
	--				  FROM H_RETIRE_DETAIL N WITH(NOLOCK)
	--				 WHERE N.CD_COMPANY = '''+@p_cd_company+'''
	--				   AND N.FG_RETR = ''2''
	--				   AND LEFT(N.DT_RETR, 6) = LEFT(CONVERT(VARCHAR(8), DATEADD(MM, -1,'''+@p_dt_base6+'''+''01''), 112),6)--(당해년도의 전월) 
	--				   AND N.NO_PERSON = M.NO_PERSON), 0) AS OLD_AMT_RETR_PAY,



--END
--ELSE 
--BEGIN 
--	SELECT * FROM H_RETIRE_APP 
--	WHERE CD_COMPANY = @p_cd_company
--		AND DT_BASE = @p_dt_base
--	ORDER BY CD_DEPT, NO_PERSON
--END
	IF @p_cd_company = 'I'
	BEGIN
       	 EXEC dbo.SP_RETIRE_APP_SAP @p_cd_company, @p_dt_base, @p_pay_group, @p_cd_biz_area, @p_no_person,@p_id_user,
         @p_error_code OUTPUT, @p_error_str OUTPUT
        RETURN		
	END
	



RETURN
  -----------------------------------------------------------------------------------------------------------------------
  -- END Message Setting Block 
  ----------------------------------------------------------------------------------------------------------------------- 
  ERR_HANDLER:

	--DEALLOCATE	PER_CUR
	--DROP TABLE #TEMP_HUMAN

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line = ERROR_LINE();
	SET @v_error_message = @v_error_note;

	EXECUTE p_ba_errlib_getusererrormsg @p_cd_company, 'SP_RETIRE_APP',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

	RETURN
END TRY

  ----------------------------------------------------------------------------------------------------------------------- 
  -- Error CATCH Process Block 
  ----------------------------------------------------------------------------------------------------------------------- 
BEGIN CATCH

	--DEALLOCATE	PER_CUR
	--DROP TABLE #TEMP_HUMAN

	SET @p_error_code = @v_error_code;
	SET @p_error_str = @v_error_note;

	SET @v_error_number = ERROR_NUMBER();
	SET @v_error_severity = ERROR_SEVERITY();
	SET @v_error_state = ERROR_STATE();
	SET @v_error_line =  ERROR_LINE();
	SET @v_error_message = ERROR_MESSAGE()+ ' ' + @v_error_note;
select @v_error_message
	--EXECUTE p_ba_errlib_getusererrormsg @p_cd_company, 'SP_SAPFI_IF_RETRAPP',  @v_error_number , @v_error_severity, @v_error_state, @v_error_line, @v_error_message

	RETURN
END CATCH
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[P_REP_ADD_AMT_SEND_MAIL]  
   @av_company_cd nvarchar(10),
   @av_locale_cd nvarchar(10),
   @av_to_nm varchar(100),
   @av_to_email varchar(250),
   @av_from_nm varchar(100),
   @av_from_email varchar(250),
   @av_email_subject varchar(250),
   @av_rem_comment varchar(max),
   @av_list_ids varchar(max),
   @an_mod_user_id numeric(38),
   @av_ret_code nvarchar(100) OUTPUT,
   @av_ret_message nvarchar(1000) OUTPUT
AS 
   BEGIN
      SET @av_ret_code = NULL
      SET @av_ret_message = NULL
      /*
      *   <DOCLINE> ***************************************************************************
      *   <DOCLINE>   TITLE       : 추가부담금명세서  메일 발송
      *   <DOCLINE>   PROJECT     : H5 5.0
      *   <DOCLINE>   AUTHOR      :
      *   <DOCLINE>   PROGRAM_ID  : P_REP_ADD_AMT_SEND_MAIL
      *   <DOCLINE>   ARGUMENT    :
      *   <DOCLINE>   RETURN      : 결과코드   : av_ret_code    SUCCESS!       / FAILURE!
      *   <DOCLINE>                 결과메시지 : av_ret_message null, 알림내용 / 오류메세지
      *   <DOCLINE>   COMMENT     :
      *   <DOCLINE>   HISTORY     :
      *   <DOCLINE> ***************************************************************************
      *    기본 변수
      */
      DECLARE
         @v_program_id nvarchar(30), 
         @v_program_nm nvarchar(100), 
         @v_title nvarchar(200) = NULL, 
         @v_contents nvarchar(4000) = NULL, 
         @v_from_emp_no nvarchar(20), 
         @v_from_emp_nm nvarchar(40), 
         @v_from_mail_id nvarchar(100), 
         @v_to_emp_no nvarchar(20), 
         @v_to_emp_nm nvarchar(40), 
         @v_to_mail_id nvarchar(100),
		 @n_cnt numeric(18,0),
		 @n_frm_mail_list_id numeric(38,0)

      /*<DOCLINE> 기본변수 초기값 셋팅*/
      SET @v_program_id = 'P_REP_ADD_AMT_SEND_MAIL'/* 현재 프로시져의 영문명*/

      SET @v_program_nm = '퇴직자 추가부담금 메일발송'/* 현재 프로시져의 한글문명*/

      SET @av_ret_code = 'SUCCESS!'

      SET @av_ret_message = dbo.F_FRM_ERRMSG( '프로시져 실행 시작..', @v_program_id,  0000, NULL, @an_mod_user_id)

      /*<DOCLINE> 메일제목 가져오기*/
      SET @v_title = @av_email_subject

      DECLARE
         @for_cur$RowNum numeric(38),
		 @for_cur$REP_CALC_LIST_ID numeric(38),
         @for_cur$EMP_ID numeric(38), 
         @for_cur$EMP_NO nvarchar(10),
		 @for_cur$EMP_NM nvarchar(50),
		 @for_cur$CTZ_NO nvarchar(100),
		 @for_cur$C1_STA_YMD date,
		 @for_cur$C1_END_YMD date,
		 @for_cur$RETIRE_YMD date,
		 @for_cur$PAY_MON numeric(15),
		 @for_cur$R01_S numeric(15),
		 @v_mail_content nvarchar(max) = ''

      DECLARE
          REP_CUR CURSOR LOCAL FORWARD_ONLY FOR 
            SELECT ROW_NUMBER() OVER(ORDER BY EMP.EMP_NO), A.REP_CALC_LIST_ID
			     , A.EMP_ID, EMP.EMP_NO, EMP.EMP_NM, dbo.F_FRM_DECRYPT_C(EMP.CTZ_NO) AS CTZ_NO
			     , A.C1_STA_YMD, A.C1_END_YMD, A.RETIRE_YMD, A.PAY_MON, A.R01_S
            FROM REP_CALC_LIST AS A
			JOIN dbo.fn_split_array(@av_list_ids,',') B
			  on A.REP_CALC_LIST_ID = CONVERT(NUMERIC(38),B.Items)
			JOIN VI_FRM_PHM_EMP EMP
			  ON A.COMPANY_CD = EMP.COMPANY_CD
			  AND A.EMP_ID = EMP.EMP_ID
			  AND EMP.LOCALE_CD = @av_locale_cd
      OPEN REP_CUR
	  set @n_frm_mail_list_id = NEXT VALUE FOR dbo.S_FRM_SEQUENCE
      WHILE 1 = 1
         BEGIN
            FETCH REP_CUR
                INTO @for_cur$RowNum, @for_cur$REP_CALC_LIST_ID
				 , @for_cur$EMP_ID, @for_cur$EMP_NO, @for_cur$EMP_NM, @for_cur$CTZ_NO
			     , @for_cur$C1_STA_YMD, @for_cur$C1_END_YMD, @for_cur$RETIRE_YMD, @for_cur$PAY_MON, @for_cur$R01_S
            IF @@FETCH_STATUS = -1
               BREAK

            BEGIN
				set @v_mail_content += '<tr>'
				set @v_mail_content += '	<td width="5%" BGCOLOR="#FFFBE6" align="center">' + CONVERT(VARCHAR(100), @for_cur$RowNum) + '<br/></td>'
				set @v_mail_content += '	<td width="5%" BGCOLOR="#FFFBE6" align="center">' + @for_cur$EMP_NM + '<br/></td>'
				set @v_mail_content += '	<td width="5%" BGCOLOR="#FFFBE6" align="center">' + SUBSTRING(@for_cur$CTZ_NO, 1, 6) + '-' + SUBSTRING(@for_cur$CTZ_NO, 7, 7) + '<br/></td>'
				set @v_mail_content += '	<td width="5%" BGCOLOR="#FFFBE6" align="center">' + dbo.XF_TO_CHAR_D(@for_cur$C1_STA_YMD, 'YYYY.MM.DD') + '<br/></td>'
				set @v_mail_content += '	<td width="5%" BGCOLOR="#FFFBE6" align="center">' + dbo.XF_TO_CHAR_D(@for_cur$C1_END_YMD, 'YYYY.MM.DD') + '<br/></td>'
				set @v_mail_content += '	<td width="5%" BGCOLOR="#FFFBE6" align="center">' + dbo.XF_TO_CHAR_D(@for_cur$RETIRE_YMD, 'YYYY.MM.DD') + '<br/></td>'
				set @v_mail_content += '	<td width="5%" BGCOLOR="#FFFBE6" align="center">' + FORMAT(@for_cur$PAY_MON, '#,##0') + '<br/></td>'
				set @v_mail_content += '	<td width="5%" BGCOLOR="#FFFBE6" align="center">' + FORMAT(@for_cur$R01_S, '#,##0') + '<br/></td>'
				set @v_mail_content += '</tr>' 
            END
			SELECT @n_cnt = COUNT(*)
			  FROM REP_CALC_LIST_MAIL
			 WHERE REP_CALC_LIST_ID = @for_cur$REP_CALC_LIST_ID
			IF @n_cnt > 0
				BEGIN
					UPDATE REP_CALC_LIST_MAIL
					   SET SEND_YMD = GETDATE()
						 , TO_NM = @av_to_nm
						 , TO_EMAIL = @av_to_email
						 , FROM_NM = @av_from_nm
						 , FROM_EMAIL = @av_from_email
						 , EMAIL_SUBJECT = @av_email_subject
						 , REM_COMMENT = @av_rem_comment
						 , FRM_MAIL_LIST_ID = @n_frm_mail_list_id
						 , MOD_USER_ID = @an_mod_user_id
						 , MOD_DATE = sysdatetime()
						 , TZ_CD = 'KST'
						 , TZ_DATE = sysdatetime()
					WHERE REP_CALC_LIST_ID = @for_cur$REP_CALC_LIST_ID
				END
			Else
				BEGIN
					INSERT REP_CALC_LIST_MAIL(
							REP_CALC_LIST_MAIL_ID, --	추가부담금명세서이메일ID
							REP_CALC_LIST_ID, --	퇴직금대상ID 
							EMP_ID, --	사원ID
							SEND_YMD, --	전송일자
							TO_NM, --	수신인
							TO_EMAIL, --	수신인이메일
							FROM_NM, --	발신인
							FROM_EMAIL, --	발신인이메일
							EMAIL_SUBJECT, --	제목
							REM_COMMENT, --	내용
							FRM_MAIL_LIST_ID, -- 메일전송ID
							NOTE, --	비고
							MOD_USER_ID, --	변경자
							MOD_DATE, --	변경일시
							TZ_CD, --	타임존코드
							TZ_DATE --	타임존일시
					)
					SELECT NEXT VALUE FOR S_REP_SEQUENCE REP_CALC_LIST_MAIL_ID, --	추가부담금명세서이메일ID
							@for_cur$REP_CALC_LIST_ID REP_CALC_LIST_ID, --	퇴직금대상ID 
							@for_cur$EMP_ID EMP_ID, --	사원ID
							GETDATE() SEND_YMD, --	전송일자
							@av_to_nm	TO_NM, --	수신인
							@av_to_email	TO_EMAIL, --	수신인이메일
							@av_from_nm	FROM_NM, --	발신인
							@av_from_email	FROM_EMAIL, --	발신인이메일
							@av_email_subject	EMAIL_SUBJECT, --	제목
							@av_rem_comment	REM_COMMENT, --	내용
							@n_frm_mail_list_id,
							''	NOTE, --	비고
							@an_mod_user_id	MOD_USER_ID, --	변경자
							SYSDATETIME()	MOD_DATE, --	변경일시
							'KST'	TZ_CD, --	타임존코드
							SYSDATETIME()	TZ_DATE --	타임존일시
				END
         END

      CLOSE REP_CUR

      DEALLOCATE REP_CUR
	  
	  SET @v_title = @av_email_subject
	  SET @v_from_emp_nm = @av_from_nm
	  SET @v_from_mail_id = @av_from_email
	  SET @v_to_emp_nm = @av_to_nm
	  SET @v_to_mail_id = @av_to_email
	  SET @v_contents = ''
	  SET @v_contents += '<html> <head><title>퇴직자 추가부담금 명세서</title></head>'
	  SET @v_contents += '<style MEDIA="screen">	BODY  {font-family:"맑은 고딕", "Arial"; font-size:8pt; color: #000000; background: #FFFFFF; margin: 0em  }  	TABLE {font-size:9pt;font-color:black;}	input {font-size:9pt;border-width:1px; border-style:solid;}	select {font-size:9pt;border-width:1px; border-style:solid;}    td {height:20}    .over{color:blue; cursor:hand;}    .out{color:black}</style>'
	  SET @v_contents += '<style MEDIA="print">	BODY  {font-family:"맑은 고딕", "Arial"; font-size:8pt; color: #000000; background: #FFFFFF; margin: 0em  }  	TABLE {font-size:8pt;font-color:black;width:650;}	input {font-size:9pt;border-width:1px; border-style:solid;}	select {font-size:9pt;border-width:1px; border-style:solid;}    td {height:20}	.hide {display: none}</style>'
	  SET @v_contents += '<body bgcolor="white" text="black" link="blue" vlink="purple" alink="red">'
	  SET @v_contents += '<!--PAY--> <table border="0" cellpadding="1" cellspacing="0" width="660" style="font-size=16"><br>'
	  SET @v_contents += '<tr>	<td><center><u><b><font color="#6868A8">퇴직자 추가부담금 명세서<br></font></b></u></center></td></tr>'
	  SET @v_contents += '</table><br>'
	  SET @v_contents += '<table border="1" cellpadding="1" cellspacing="0" width="660" bordercolor="white">'
	  SET @v_contents += '<tr>'
	  SET @v_contents += '	<td BGCOLOR="C8C5A2" colspan="8" align="center"><font color="black"><b></b></font></td>'
	  SET @v_contents += '</tr>'
	  SET @v_contents += '<tr>'
	  SET @v_contents += '	<td width="5%" BGCOLOR="#C0CCB8" align="center">No<br></td>'   
	  SET @v_contents += '	<td width="12%" BGCOLOR="#C0CCB8" align="center">성명<br></td>'    
	  SET @v_contents += '	<td width="12%" BGCOLOR="#C0CCB8" align="center">주민번호<br></td>'  
	  SET @v_contents += '	<td width="12%" BGCOLOR="#C0CCB8" align="center">납입금해당기간<br>(시작)</td>'  
	  SET @v_contents += '	<td width="12%" BGCOLOR="#C0CCB8" align="center">납입금해당기간<br>(종료)</td>'  
	  SET @v_contents += '	<td width="12%" BGCOLOR="#C0CCB8" align="center">퇴사일자<br></td>'  
	  SET @v_contents += '	<td width="15%" BGCOLOR="#C0CCB8" align="center">퇴사일까지<br>기준급여</td>'  
	  SET @v_contents += '	<td width="12%" BGCOLOR="#C0CCB8" align="center">추가부담금액<br></td>'  
	  SET @v_contents += '</tr>'
	  SET @v_contents += @v_mail_content
	  SET @v_contents += '</tr>'
	  SET @v_contents += '</table>'
	  SET @v_contents += '<table border="1" cellpadding="1" cellspacing="0" width="660" bordercolor="white">'
	  SET @v_contents += '<tr>'
	  SET @v_contents += '	<td width="5%" align="Left">' + @av_rem_comment + '<br></td>'
	  SET @v_contents += '</tr>'
	  SET @v_contents += '</table>'
	  SET @v_contents += '<br><br> <!--BONUS-->'
	  SET @v_contents += '<!--COMMENT-->'
	  SET @v_contents += '</body>'
	  SET @v_contents += '</html>'

            /*<DOCLINE> DB 메일 발송*/
       BEGIN TRY    
          INSERT FRM_MAIL_LIST( FRM_MAIL_LIST_ID    
                               ,WRITE_DATE      
                               ,SEND_TYPE_CD      
                               ,SENDER_ID     
                               ,SENDER_MAIL    
                               ,SENDER_NAME       
                               ,MAIL_TITLE    
                               ,TYPE_CD    
                               ,SEND_YN )    
          VALUES ( @n_frm_mail_list_id      
                  ,dbo.XF_SYSDATE(0)    
                  ,'0'                      --전송유형(즉시전송:0, 예약전송:1)    
                  ,@an_mod_user_id    
                  ,@v_from_mail_id    
                  ,@v_from_emp_nm  
                  ,@v_title
                  ,'M'                           --전송타입(S:SMS, M:Mail)    
                  ,'N'                                  --전송여부    
                 )
				 INSERT FRM_MAIL_LIST_DETAIL( FRM_MAIL_LIST_DETAIL_ID     
                                                ,FRM_MAIL_LIST_ID    
                                                ,RECEIVER_ID    
                                                ,RECEIVER_MAIL    
                                                ,RECEIVER_NAME    
                                                ,MAIL_CONTENTS )      
                    VALUES ( NEXT VALUE FOR dbo.S_FRM_SEQUENCE     
						    ,@n_frm_mail_list_id      
							,@an_mod_user_id    
                            ,@v_to_mail_id
							,@v_to_emp_nm
							,@v_contents )    
       END TRY    
       BEGIN CATCH      
          BEGIN      
             SET @av_ret_code = 'FAILURE!'       
             SET @av_ret_message = dbo.F_FRM_ERRMSG( 'Insert error. frm_mail_list[ERR]'      
                                                    ,@v_program_id       
                                                    ,0030      
                                                    ,ERROR_MESSAGE()       
                                                    ,@an_mod_user_id)      
             IF @@TRANCOUNT > 0      
                ROLLBACK WORK       
             RETURN       
          END      
       END CATCH   
      
      /*
      *    ***********************************************************
      *    작업 완료
      *    ***********************************************************
      *    COMMIT;
      */
      SET @av_ret_code = 'SUCCESS!'

      SET @av_ret_message = dbo.F_FRM_ERRMSG(
         '메일전송완료[ERR]', 
         @v_program_id, 
         0900, 
         NULL, 
         @an_mod_user_id)

   END

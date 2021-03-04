SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[P_REP_CALC_SEND_MAIL]  
   @av_company_cd nvarchar(10),/* ȸ���ڵ�*/
   @av_locale_cd nvarchar(10),/* �����ڵ�*/
   @an_rep_calc_list_id numeric(38),/*���ID*/
   @av_in_offi_yn nvarchar(10), -- ����/����
   @av_email_addr nvarchar(200), -- �̸����ּ�
   @av_reason nvarchar(200), -- ��û����
   @av_emp_id numeric(38), -- ��û��
   @an_mod_user_id numeric(38)/* ������ID*/,
   @av_ret_code nvarchar(100)/* ����ڵ�*/  OUTPUT,
   @av_ret_message nvarchar(4000)/* ����޽���*/  OUTPUT
AS 
   BEGIN
      SET @av_ret_code = NULL
      SET @av_ret_message = NULL
      /*
      *   <DOCLINE> ***************************************************************************
      *   <DOCLINE>   TITLE       : ������  ���� �߼�
      *   <DOCLINE>   PROJECT     : H5 5.0
      *   <DOCLINE>   AUTHOR      :
      *   <DOCLINE>   PROGRAM_ID  : P_REP_SEND_MAIL
      *   <DOCLINE>   ARGUMENT    :
      *   <DOCLINE>   RETURN      : ����ڵ�   : av_ret_code    SUCCESS!       / FAILURE!
      *   <DOCLINE>                 ����޽��� : av_ret_message null, �˸����� / �����޼���
      *   <DOCLINE>   COMMENT     :
      *   <DOCLINE>   HISTORY     :
      *   <DOCLINE> ***************************************************************************
      *    �⺻ ����
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
		 @n_c_01		numeric(18,0),
		 @v_link_url	nvarchar(1000)

      /*<DOCLINE> �⺻���� �ʱⰪ ����*/
      SET @v_program_id = 'P_REP_CALC_SEND_MAIL'/* ���� ���ν����� ������*/

      SET @v_program_nm = '������ ���Ϲ߼�'/* ���� ���ν����� �ѱ۹���*/

      SET @av_ret_code = 'SUCCESS!'

      SET @av_ret_message = dbo.F_FRM_ERRMSG( '���ν��� ���� ����..',  @v_program_id,  0000,  NULL,  @an_mod_user_id)

      /*<DOCLINE> �������� ��������*/
      --SET @v_title = dbo.F_FRM_GET_MAIL_MSG(
      --   @av_company_cd, 
      --   @av_locale_cd, 
      --   sysdatetime(), 
      --   'REP', 
      --   'MT', 
      --   'REP_INFO_MAIL', 
      --   dbo.F_FRM_PHM_EMP_NM(@an_mod_user_id, @av_locale_cd, '1'), 
      --   NULL, 
      --   NULL, 
      --   NULL, 
      --   NULL)
	  SET @v_title = '������ �ȳ�'

      IF @v_title IS NULL
         BEGIN

            SET @av_ret_code = 'FAILURE!'

            SET @av_ret_message = dbo.F_FRM_ERRMSG(
               '���������� ���������� ��ϵ��� �ʾҽ��ϴ�.[ERR]', 
               @v_program_id, 
               0100, 
               NULL, 
               @an_mod_user_id)

            IF @@TRANCOUNT > 0
               ROLLBACK WORK
            RETURN 

         END

      /*<DOCLINE> ������ ���� ���� select*/
      BEGIN

         BEGIN TRY
            SELECT @v_from_emp_no = dbo.F_FRM_PHM_EMP_NO(@an_mod_user_id, 'KO', '1'),
			       @v_from_emp_nm = dbo.F_FRM_PHM_EMP_NM(@an_mod_user_id, 'KO', '1'),
				   @v_from_mail_id = ISNULL(dbo.F_PHM_EMAIL( @av_company_cd, @av_locale_cd, @an_mod_user_id, '12', sysdatetime()), '') + '@com'
         END TRY

         BEGIN CATCH
            DECLARE @errormessage nvarchar(4000)
            SET @errormessage = ERROR_MESSAGE()
            BEGIN
               SET @av_ret_code = 'FAILURE!'
               SET @av_ret_message = dbo.F_FRM_ERRMSG(
                  '������ ������ ���� select �� DB ������ �߻��Ͽ����ϴ�.[ERR]', 
                  @v_program_id, 
                  0200, 
                  @errormessage, 
                  @an_mod_user_id)
               IF @@TRANCOUNT > 0
                  ROLLBACK WORK 
               RETURN
            END
         END CATCH

      END

      DECLARE
         @for_cur$EMP_ID numeric(38),
         @for_cur$EMP_NO nvarchar(50),
         @for_cur$EMP_NM nvarchar(50),
		 @for_cur$C_01	 numeric(18,0)

      DECLARE
          DB_IMPLICIT_CURSOR_FOR_for_cur CURSOR LOCAL FORWARD_ONLY FOR 
            SELECT A.EMP_ID,
			       dbo.F_FRM_PHM_EMP_NO(A.EMP_ID, 'KO', '1') AS EMP_NO,
			       dbo.F_FRM_PHM_EMP_NM(A.EMP_ID, 'KO', '1') AS EMP_NM,
				   A.C_01
            FROM dbo.REP_CALC_LIST  AS A
            WHERE A.REP_CALC_LIST_ID = @an_rep_calc_list_id

      OPEN DB_IMPLICIT_CURSOR_FOR_for_cur

      
      /*
      *   <DOCLINE> ***************************************************************************
      *   <DOCLINE> �迭�� ���� Setting
      *   <DOCLINE> ***************************************************************************
      */
      WHILE 1 = 1
         BEGIN
            FETCH DB_IMPLICIT_CURSOR_FOR_for_cur
                INTO @for_cur$EMP_ID, @for_cur$EMP_NO, @for_cur$EMP_NM, @for_cur$C_01
            IF @@FETCH_STATUS = -1
               BREAK

            /*<DOCLINE> ������ ���� ���� select*/
            SELECT @v_to_emp_no = @for_cur$EMP_NO,
				    @v_to_emp_nm = @for_cur$EMP_NM,
					@v_to_mail_id = @av_email_addr,
					@n_c_01 = @for_cur$C_01

            /*<DOCLINE> ���Ϲ��� ��������*/
			SET @v_link_url = 'C=' + @av_company_cd
			                + '&N=' + @v_to_emp_no
							+ '&D=' + @av_in_offi_yn
							+ '&R=' + @av_email_addr
							+ '&F=' + @av_reason
            SET @v_contents = @for_cur$EMP_NM + '���� �������� �� ' + FORMAT(@for_cur$C_01, '#,##0') + '�� �Դϴ�. <p>'
				+ '�ڼ��� ������ �Ʒ� ��ũ�� ���� Ȯ�� �� �ּ���.<br/>'
				+ '<a href="https://ehr.dongwon.com/EssGate/RetPrint.aspx?' + @v_link_url + '" target="_blank">
    <img src="https://ehr.dongwon.com/images/btn/btn_link.png" alt="�ڼ�������" style="border:none">
</a> <p>'

            IF @v_contents IS NULL
               BEGIN
                  SET @av_ret_code = 'FAILURE!'
                  SET @av_ret_message = dbo.F_FRM_ERRMSG(
                     '���������� ���Ϲ����� ��ϵ��� �ʾҽ��ϴ�.[ERR]', 
                     @v_program_id, 
                     0130, 
                     NULL, 
                     @an_mod_user_id)

                  IF @@TRANCOUNT > 0
                     ROLLBACK WORK 

                  RETURN 

               END

            /*<DOCLINE> DB ���� �߼�*/
            EXECUTE dbo.P_FRM_MSG_SEND 
               @AN_SENDER_ID = @an_mod_user_id, 
               @AV_SENDER_NM = @v_from_emp_nm, 
               @AV_SENDER = @v_from_mail_id, 
               @AN_RECEIVER_ID = @for_cur$EMP_ID, 
               @AV_RECEIVER_NM = @v_to_emp_nm, 
               @AV_RECEIVER = @v_to_mail_id, 
               @AV_TITLE = @v_title, 
               @AV_CONTENTS = @v_contents, 
               @AV_RET_CODE = @av_ret_code  OUTPUT, 
               @AV_RET_MESSAGE = @av_ret_message  OUTPUT

            IF @av_ret_code <> 'SUCCESS!'
               BEGIN

                  /* ���� �߻�*/
                  SET @av_ret_code = 'FAILURE!'

                  SET @av_ret_message = dbo.F_FRM_ERRMSG(
                     'DB ���� �߼� �� DB ������ �߻��Ͽ����ϴ�.[ERR]', 
                     @v_program_id, 
                     0230, 
                     @av_ret_message, 
                     @an_mod_user_id)

                  IF @@TRANCOUNT > 0
                     ROLLBACK WORK 

                  RETURN 

               END

         END

      CLOSE DB_IMPLICIT_CURSOR_FOR_for_cur

      DEALLOCATE DB_IMPLICIT_CURSOR_FOR_for_cur

      
      /*
      *    ***********************************************************
      *    �۾� �Ϸ�
      *    ***********************************************************
      *    COMMIT;
      */
      SET @av_ret_code = 'SUCCESS!'

      SET @av_ret_message = dbo.F_FRM_ERRMSG(
         '�������ۿϷ�[ERR]', 
         @v_program_id, 
         0900, 
         NULL, 
         @an_mod_user_id)

   END

GO



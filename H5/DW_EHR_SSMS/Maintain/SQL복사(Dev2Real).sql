USE [dwehr_H5]
/*
 * ����(Dev) -> �(Real)�� SQL ����
 */
DECLARE @av_query_nm        nvarchar(300) -- ������ �ҽ� SQL �̸� LIKE
      , @v_query_nm			nvarchar(80)
	  , @n_frm_query_id		numeric(38)
	  , @v_err_msg			nvarchar(1000)
	SET @av_query_nm = 'PAY0036' -- LIKE�� ����-
	DECLARE @SOURCE_QUERY TABLE(
		QUERY_NAME	NVARCHAR(80)
	);
	INSERT INTO @SOURCE_QUERY(
		QUERY_NAME
	)
	SELECT QUERY_NAME
      FROM [172.20.16.40].[dwehrdev_H5].[dbo].[FRM_QUERY_DEF]
	 WHERE QUERY_NAME LIKE + @av_query_nm + '%';

    DECLARE COPY_CUR CURSOR READ_ONLY FOR
		SELECT QUERY_NAME
			  FROM @SOURCE_QUERY
	-- =============================================
	--   As-Is Key Column Select
	-- =============================================
	OPEN COPY_CUR
	WHILE 1 = 1
		BEGIN
			-- =============================================
			--  As-Is ���̺��� KEY SELECT
			-- =============================================
			FETCH NEXT FROM COPY_CUR
			      INTO @v_query_nm
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				-- ==============================================================================
				-- PARAM ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_QUERY_DEF_PARAM A
				  JOIN FRM_QUERY_DEF B
				    ON A.QUERY_DEF_ID = B.QUERY_DEF_ID
				 WHERE B.QUERY_NAME = @v_query_nm
				-- ==============================================================================
				-- BODY ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_QUERY_DEF_BODY A
				  JOIN FRM_QUERY_DEF B
				    ON A.QUERY_DEF_ID = B.QUERY_DEF_ID
				 WHERE B.QUERY_NAME = @v_query_nm
				-- ==============================================================================
				-- DEF ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_QUERY_DEF A
				 WHERE A.QUERY_NAME = @v_query_nm
			
				SET @n_frm_query_id = NEXT VALUE FOR S_FRM_SEQUENCE
				-- ==============================================================================
				-- SQL ���� ����
				-- ==============================================================================
				INSERT FRM_QUERY_DEF (        -- SQL Invoker�� ���� ����
						QUERY_DEF_ID                   -- ���� ID
						, WORKSPACE_ID                   -- ��ũ�����̽�ID
						, COMPANY_CD                     -- �λ翵��
						, QUERY_NAME                     -- ������
						, DISPLAY_NAME                   -- ȭ��ǥ�ø�
						, USE_YN                         -- ��뿩��
						, STATUS                         -- ����
						, VERSION                        -- ����
						, DATA_SOURCE                    -- ��뵥���ͼҽ�
						, NOTE                           -- ���
						, CREATE_TIME                    -- ������
						, BIZ_AUTH_YN                    -- ��������üũ����
						, ORG_AUTH_YN                    -- ��������üũ����
						, DECORATORS                     -- ��뵥�ڷ�����
				)
				SELECT @n_frm_query_id                    -- ���� ID
						, WORKSPACE_ID                   -- ��ũ�����̽�ID
						, COMPANY_CD                     -- �λ翵��
						, QUERY_NAME                     -- ������
						, DISPLAY_NAME                   -- ȭ��ǥ�ø�
						, USE_YN                         -- ��뿩��
						, STATUS                         -- ����
						, VERSION                        -- ����
						, DATA_SOURCE                    -- ��뵥���ͼҽ�
						, NOTE                           -- ���
						, DBO.XF_SYSDATE(0)              -- ������
						, BIZ_AUTH_YN                    -- ��������üũ����
						, ORG_AUTH_YN                    -- ��������üũ����
						, DECORATORS                     -- ��뵥�ڷ�����
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_QUERY_DEF        -- SQL Invoker�� ���� ����
					WHERE QUERY_NAME = @v_query_nm;
				-- ==============================================================================
				-- SQL�� BODY ����
				-- ==============================================================================
				INSERT FRM_QUERY_DEF_BODY (        -- ���� ����
						QUERY_BODY_ID                  -- ���� �� ID
						, QUERY_DEF_ID                   -- ���� ID
						, QUERY_STRING                   -- ������
						, CREATE_TIME                    -- ������
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- ���� �� ID
						, @n_frm_query_id                    -- ���� ID
						, A.QUERY_STRING                 -- ������
						, DBO.XF_SYSDATE(0)              -- ������
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_QUERY_DEF_BODY A       -- ���� ����
						, [172.20.16.40].[dwehrdev_H5].[dbo].FRM_QUERY_DEF B
					WHERE A.QUERY_DEF_ID = B.QUERY_DEF_ID
					AND B.QUERY_NAME = @v_query_nm;
					
				-- ==============================================================================
				-- SQL�� PARAM ����
				-- ==============================================================================
				INSERT FRM_QUERY_DEF_PARAM (        -- ���� �Ķ����
					   QUERY_PARAM_ID                 -- �Ķ���� ID
					 , QUERY_DEF_ID                   -- ���� �� ID
					 , QUERY_PARAM_NAME               -- �Ķ���� ��
					 , QUERY_PARAM_SEQ                -- �Ķ���� ����
					 , QUERY_PARAM_TYPE               -- �Ķ���� ����
					 , QUERY_PARAM_INOUT_TYPE         -- �ξƿ� ����
					 , CREATE_TIME                    -- ������
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- �Ķ���� ID
					 , @n_frm_query_id                    -- ���� �� ID
					 , QUERY_PARAM_NAME               -- �Ķ���� ��
					 , QUERY_PARAM_SEQ                -- �Ķ���� ����
					 , QUERY_PARAM_TYPE               -- �Ķ���� ����
					 , QUERY_PARAM_INOUT_TYPE         -- �ξƿ� ����
					 , DBO.XF_SYSDATE(0)              -- ������
				  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_QUERY_DEF_PARAM A       -- ���� �Ķ����
					 , [172.20.16.40].[dwehrdev_H5].[dbo].FRM_QUERY_DEF B
				WHERE A.QUERY_DEF_ID = B.QUERY_DEF_ID
				  AND B.QUERY_NAME = @v_query_nm
				PRINT '����Ϸ�:' + @v_query_nm
			END TRY
			BEGIN CATCH
				set @v_err_msg = ERROR_MESSAGE()
				PRINT 'ERROR ' + @v_err_msg
				RETURN
			END CATCH
		END
	CLOSE COPY_CUR
	DEALLOCATE COPY_CUR
	PRINT 'SQL COPY COMPLETE: ' + @av_query_nm + '%'
GO
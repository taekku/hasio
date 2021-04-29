USE [dwehr_H5]
/*
 * ����(Dev) -> �(Real)�� ���� ����
 */
DECLARE @av_service_nm        nvarchar(300) -- ������ �ҽ� SQL �̸� LIKE
      , @v_service_nm			nvarchar(300)
	  , @n_temp_oid			numeric(38)
	  , @n_source_oid		numeric(38)
	  , @v_err_msg			nvarchar(1000)
	SET @av_service_nm = 'REP0018' -- LIKE�� ����

	DECLARE @SOURCE_SERVICE TABLE(
		SV_DEF_ID	NUMERIC(38),
		SV_DEF_NM	NVARCHAR(300)
	);
	INSERT INTO @SOURCE_SERVICE(
		SV_DEF_ID,
		SV_DEF_NM
	)
	SELECT SV_DEF_ID,
		   SV_DEF_NM
      FROM [172.20.16.40].[dwehrdev_H5].[dbo].[FRM_SERVICE_DEF]
	 WHERE SV_DEF_NM LIKE + @av_service_nm + '%';
	--IF @@ROWCOUNT > 100
	--	BEGIN
	--		PRINT '�ʹ����� ���縦 �����մϴ�. �ڷḦ �ٽ� Ȯ���ϼ���.[' + @av_service_nm + ']'
	--		return
	--	END

    DECLARE COPY_CUR CURSOR READ_ONLY FOR
		SELECT SV_DEF_ID, SV_DEF_NM
			  FROM @SOURCE_SERVICE
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
			      INTO @n_source_oid, @v_service_nm
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				-- ==============================================================================
				-- ���� ��ó�� ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_OPT A
				  JOIN FRM_SERVICE_DEF B
				    ON A.SV_DEF_ID = B.SV_DEF_ID
				 WHERE B.SV_DEF_NM = @v_service_nm
				-- ==============================================================================
				-- ���� ��ȿ�� �˻�� ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_VAL_DEF A
				  JOIN FRM_SERVICE_DEF B
				    ON A.SV_DEF_ID = B.SV_DEF_ID
				 WHERE B.SV_DEF_NM = @v_service_nm
				-- ==============================================================================
				-- ���� ��ɸ��� ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_FUNC_MAP A
				  JOIN FRM_SERVICE_DEF B
				    ON A.SV_DEF_ID = B.SV_DEF_ID
				 WHERE B.SV_DEF_NM = @v_service_nm
				-- ==============================================================================
				-- ���� �Ӽ� ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_ATTR A
				  JOIN FRM_SERVICE_DEF B
				    ON A.SV_DEF_ID = B.SV_DEF_ID
				 WHERE B.SV_DEF_NM = @v_service_nm
				-- ==============================================================================
				-- ���� �������� ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_AUTH_GROUP A
				  JOIN FRM_SERVICE_DEF B
				    ON A.SV_DEF_ID = B.SV_DEF_ID
				 WHERE B.SV_DEF_NM = @v_service_nm
				-- ==============================================================================
				-- DEF ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_DEF A
				 WHERE A.SV_DEF_NM = @v_service_nm
			Print '����:' + @v_service_nm
				SET @n_temp_oid = NEXT VALUE FOR S_FRM_SEQUENCE
				
				-- ==============================================================================
				-- ���� ���� ����
				-- ==============================================================================
				INSERT FRM_SERVICE_DEF (        -- ���� ����
					   SV_DEF_ID                      -- Ʈ�����ID
					 , SV_DEF_NM                      -- Ʈ����Ǹ�
					 , CMD_CLASS_NM                   -- Ŀ�ǵ�Ŭ������
					 , TX_SUPPORT_YN                  -- 2PC ��������
					 , VERSION                        -- ����
					 , NOTE                           -- ����
					 , MOD_USER_ID                    -- ������ID
					 , MOD_DATE                       -- �����Ͻ�
					 , ASYNC_YN                       -- �񵿱�ó������
					 , OBJECT_ID                      -- ������ƮID
					 , USE_LOG_YN                     -- �α׻�뿩��
				)
				SELECT @n_temp_oid                    -- Ʈ�����ID
					 , SV_DEF_NM          -- Ʈ����Ǹ�
					 , CMD_CLASS_NM                   -- Ŀ�ǵ�Ŭ������
					 , TX_SUPPORT_YN                  -- 2PC ��������
					 , VERSION                        -- ����
					 , NOTE                           -- ����
					 , MOD_USER_ID                    -- ������ID
					 , MOD_DATE                       -- �����Ͻ�
					 , ASYNC_YN                       -- �񵿱�ó������
					 , OBJECT_ID                      -- ������ƮID
					 , USE_LOG_YN                     -- �α׻�뿩��
				  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_DEF        -- ���� ����
					WHERE SV_DEF_NM = @v_service_nm;

				-- ==============================================================================
				-- ���� �Ӽ� ����
				-- ==============================================================================
				INSERT FRM_SERVICE_ATTR (        -- Ʈ���� �Ӽ� ����
					   SV_ATTR_ID                     -- Ʈ����� �Ӽ� ID
					 , SV_DEF_ID                      -- Ʈ�����ID
					 , SV_ATTR_NM                     -- Ʈ����� �Ӽ� ��
					 , NOTE                           -- ���
					 , SV_ATTR_TYPE                   -- �Ӽ� Ÿ�� ( ATTR | MSG | EVENT ...)
					 , DEFAULT_VALUE                  -- �⺻ ��
					 , MOD_USER_ID                    -- ������
					 , MOD_DATE                       -- �����Ͻ�
					 , VALUE_TYPE                     -- ��Ÿ��
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- Ʈ����� �Ӽ� ID
					 , @n_temp_oid                    -- Ʈ�����ID
					 , SV_ATTR_NM                     -- Ʈ����� �Ӽ� ��
					 , NOTE                           -- ���
					 , SV_ATTR_TYPE                   -- �Ӽ� Ÿ�� ( ATTR | MSG | EVENT ...)
					 , DEFAULT_VALUE                  -- �⺻ ��
					 , MOD_USER_ID                    -- ������
					 , MOD_DATE                       -- �����Ͻ�
					 , VALUE_TYPE                     -- ��Ÿ��
				  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_ATTR        -- Ʈ���� �Ӽ� ����
				 WHERE SV_DEF_ID = @n_source_oid
				-- ==============================================================================
				-- ���� ��ɸ��� ����
				-- ==============================================================================
				INSERT FRM_SERVICE_FUNC_MAP (        -- ��ɸ���
						SV_MAP_ID                      -- ��ɸ��� ID
						, SV_DEF_ID                      -- Ʈ�����ID
						, SV_MAP_TYPE_CD                 -- ��ɱ��� �ڵ� ( SQL | ENTITY |  ETC)
						, FUNC_NM                        -- ��ɸ�
						, SEQ_ORDER                      -- �������
						, REQ_MSG_NM                     -- ��û�޽��� �̸�
						, RES_MSG_NM                     -- ��ȯ �޽��� �̸�
						, MOD_DATE                       -- ������
						, MOD_USER_ID                    -- �����Ͻ�
						, USE_TREE_RESULT                -- �����Ʈ���ι�ȯ
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- ��ɸ��� ID
						, @n_temp_oid                    -- Ʈ�����ID
						, SV_MAP_TYPE_CD                 -- ��ɱ��� �ڵ� ( SQL | ENTITY |  ETC)
						, FUNC_NM                        -- ��ɸ�
						, SEQ_ORDER                      -- �������
						, REQ_MSG_NM                     -- ��û�޽��� �̸�
						, RES_MSG_NM                     -- ��ȯ �޽��� �̸�
						, MOD_DATE                       -- ������
						, MOD_USER_ID                    -- �����Ͻ�
						, USE_TREE_RESULT                -- �����Ʈ���ι�ȯ
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_FUNC_MAP           -- ��ɸ���
					WHERE SV_DEF_ID = @n_source_oid

				-- ==============================================================================
				-- ���� ��ȿ�� �˻�� ����
				-- ==============================================================================
				INSERT FRM_SERVICE_VAL_DEF (        -- Ʈ����� ��ȿ�� �˻�� ����
						SV_VAL_DEF_ID                  -- ��ȿ�� �˻�� ���� ID
						, SV_DEF_ID                      -- Ʈ�����ID
						, VAL_TYPE_CD                    -- �˻� ó�� ���� �ڵ�
						, SEQ_ORDER                      -- �������
						, VAL_LC_TYPE_CD                 -- �˻�����ڵ�
						, VALIDATOR_NM                   -- ��ȿ�� �˻�� �̸�
						, MSG_NM                         -- ��� �޽��� �̸�
						, MOD_USER_ID                    -- ������
						, MOD_DATE                       -- �����Ͻ�
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- ��ȿ�� �˻�� ���� ID
						, @n_temp_oid                    -- Ʈ�����ID
						, VAL_TYPE_CD                    -- �˻� ó�� ���� �ڵ�
						, SEQ_ORDER                      -- �������
						, VAL_LC_TYPE_CD                 -- �˻�����ڵ�
						, VALIDATOR_NM                   -- ��ȿ�� �˻�� �̸�
						, MSG_NM                         -- ��� �޽��� �̸�
						, MOD_USER_ID                    -- ������
						, MOD_DATE                       -- �����Ͻ�
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_VAL_DEF            -- Ʈ����� ��ȿ�� �˻�� ����
					WHERE SV_DEF_ID = @n_source_oid
					
				-- ==============================================================================
				-- ���� ��������
				-- ==============================================================================
				INSERT FRM_SERVICE_AUTH_GROUP ( 
						SV_AUTH_ID, -- ���Ѹ��� ID
						SV_DEF_ID, -- Ʈ�����ID
						USERGROUP_ID, -- FRM_USER_GROUP ����
						MOD_DATE, -- ������
						MOD_USER_ID, -- �����Ͻ�
						COMPANY_CD -- �迭���ڵ�
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- ��ȿ�� �˻�� ���� ID
						, @n_temp_oid                    -- Ʈ�����ID
							,C.USERGROUP_ID, -- FRM_USER_GROUP ����
							A.MOD_DATE, -- ������
							A.MOD_USER_ID, -- �����Ͻ�
							A.COMPANY_CD  -- �迭���ڵ�
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_AUTH_GROUP A
					JOIN [172.20.16.40].[dwehrdev_H5].[dbo].FRM_USER_GROUP B
					  ON A.USERGROUP_ID = B.USERGROUP_ID
					JOIN FRM_USER_GROUP C
					  ON B.COMPANY_CD = C.COMPANY_CD
					 AND B.GROUP_TYPE = C.GROUP_TYPE
					 AND B.USERGROUP_NM = C.USERGROUP_NM
					WHERE A.SV_DEF_ID = @n_source_oid

				-- ==============================================================================
				-- ���� ��ó�� ����
				-- ==============================================================================
				INSERT FRM_SERVICE_OPT (        -- ���� ��ó��
						SV_OPT_ID, -- ��ó�� ID
						SV_DEF_ID, -- Ʈ�����ID
						OPT_CD, -- �ɼ��ڵ�[FRM_SV_OPT_CD]
						OPT_VALUE, -- �ɼǰ�[FRM_SV_OPT_VALUE_CD]
						MOD_DATE, -- ������
						MOD_USER_ID, -- �����Ͻ�
						NOTE -- ���
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- ��ó�� ID
						, @n_temp_oid                    -- Ʈ�����ID
						, OPT_CD -- �ɼ��ڵ�[FRM_SV_OPT_CD]
						, OPT_VALUE -- �ɼǰ�[FRM_SV_OPT_VALUE_CD]
						, MOD_DATE -- ������
						, MOD_USER_ID -- �����Ͻ�
						, NOTE -- ���
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_OPT            -- Ʈ����� ��ȿ�� �˻�� ����
					WHERE SV_DEF_ID = @n_source_oid
				PRINT '����Ϸ�:' + @v_service_nm
			END TRY
			BEGIN CATCH
				set @v_err_msg = ERROR_MESSAGE()
				PRINT 'ERROR ' + @v_err_msg
				RETURN
			END CATCH
		END
	CLOSE COPY_CUR
	DEALLOCATE COPY_CUR
	PRINT 'SQL COPY COMPLETE: ' + @av_service_nm + '%'
GO
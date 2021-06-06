USE [dwehr_H5]
SET NOCOUNT ON
/*
 * ����(Dev) -> �(Real)�� Entity ����
 */
DECLARE @av_entity_nm        nvarchar(300) -- 
      , @v_entity_nm			nvarchar(300)
	  , @n_temp_oid			numeric(38)
	  , @n_source_oid		numeric(38)
	  , @n_origin_column_id		numeric(38)
	  , @n_target_column_id		numeric(38)
	  , @v_err_msg			nvarchar(1000)
	SET @av_entity_nm = 'EN_FRM_FILE_BIZ_GUIDE' -- LIKE�� ����

	DECLARE @SOURCE_TABLE TABLE(
		ENTITY_ID	NUMERIC(38),
		ENTITY_NM	NVARCHAR(300)
	);
	INSERT INTO @SOURCE_TABLE(
		ENTITY_ID,
		ENTITY_NM
	)
	SELECT ENTITY_ID,
			ENTITY_NM
      FROM [172.20.16.40].[dwehrdev_H5].[dbo].[FRM_ENTITY]
	 WHERE ENTITY_NM LIKE + @av_entity_nm + '%';
	IF @@ROWCOUNT > 100
		BEGIN
			PRINT '�ʹ����� ���縦 �����մϴ�. �ڷḦ �ٽ� Ȯ���ϼ���.[' + @av_entity_nm + ']'
			return
		END

    DECLARE COPY_CUR CURSOR READ_ONLY FOR
		SELECT ENTITY_ID, ENTITY_NM
			  FROM @SOURCE_TABLE
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
			      INTO @n_source_oid, @v_entity_nm
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				-- ==============================================================================
				-- ����Ͻ� �÷� ���� ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_ENTITY_COLUMN_MAPPING A
				  JOIN FRM_ENTITY_COLUMN B
				    ON A.COLUMN_ID = B.COLUMN_ID
				  JOIN FRM_ENTITY C
				    ON B.ENTITY_ID = C.ENTITY_ID
				 WHERE C.ENTITY_NM = @v_entity_nm
				-- ==============================================================================
				-- ���� ��ȿ�� �˻�� ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_ENTITY_COLUMN A
				  JOIN FRM_ENTITY B
				    ON A.ENTITY_ID = B.ENTITY_ID
				 WHERE B.ENTITY_NM = @v_entity_nm
				-- ==============================================================================
				-- DEF ����
				-- ==============================================================================
				DELETE A
				  FROM FRM_ENTITY A
				 WHERE A.ENTITY_NM = @v_entity_nm
			Print '����:' + @v_entity_nm
				
				-- ==============================================================================
				-- ENTITY ���� ����
				-- ==============================================================================
				SET @n_temp_oid = NEXT VALUE FOR S_FRM_SEQUENCE
				INSERT FRM_ENTITY (
						ENTITY_ID, -- ����Ƽ ID
						ENTITY_NM, -- ����Ƽ �̸�
						DISPLAY_NM, -- ȭ��ǥ�ø�
						HISTORY_TYPE_CD, -- �̷� ���� �����ڵ�
						LOG_YN, -- �α׻�� ����
						NOTE, -- ����
						UNIT_CD, -- ���������ڵ�
						CREATOR_CD, -- ������ ���� �ڵ� (pkg | site)
						MOD_USER_ID, -- ������ ID
						MOD_DATE -- �����Ͻ�
				)
				SELECT @n_temp_oid ENTITY_ID,   -- ����Ƽ ID
						ENTITY_NM, -- ����Ƽ �̸�
						DISPLAY_NM, -- ȭ��ǥ�ø�
						HISTORY_TYPE_CD, -- �̷� ���� �����ڵ�
						LOG_YN, -- �α׻�� ����
						NOTE, -- ����
						UNIT_CD, -- ���������ڵ�
						CREATOR_CD, -- ������ ���� �ڵ� (pkg | site)
						MOD_USER_ID, -- ������ ID
						MOD_DATE -- �����Ͻ�
				  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_ENTITY -- ENTITY ����
					WHERE ENTITY_ID = @n_source_oid

				-- ==============================================================================
				-- ����Ͻ� ����Ƽ �÷�  ����
				-- ==============================================================================
				DECLARE DTL_CUR CURSOR READ_ONLY FOR
					SELECT COLUMN_ID
						  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_ENTITY_COLUMN -- ENTITY COLUMN
							WHERE ENTITY_ID = @n_source_oid
				OPEN DTL_CUR
				WHILE 1 = 1
				BEGIN
					FETCH NEXT FROM DTL_CUR
							INTO @n_origin_column_id
					IF @@FETCH_STATUS <> 0 BREAK
					BEGIN TRY
					-- ==============================================================================
					-- ENTITY_COLUMN ����
					-- ==============================================================================
						SET @n_target_column_id = NEXT VALUE FOR S_FRM_SEQUENCE
						INSERT INTO FRM_ENTITY_COLUMN(
								COLUMN_ID, -- �÷� ID
								ENTITY_ID, -- ����Ƽ ID
								COLUMN_NM, -- �÷� �̸�
								DISPLAY_NM, -- �÷� ǥ�ø�
								KEY_YN, -- Ű ����
								USE_AUTO_INSERT_YN, -- �Է½� �ڵ��� ��� ����
								USE_AUTO_UPDATE_YN, -- ������ �ڵ��� ��� ��
								START_DATE_COL_YN, -- ������ �÷� ����
								END_DATE_COL_YN, -- ������ �÷� ����
								HK_YN, -- �����丮 Ű ����
								AUTO_INSERT_VALUE, -- �Է½� �ڵ��Ҵ� ��
								AUTO_UPDATE_VALUE, -- ������ �ڵ��Ҵ� ��
								CREATOR_CD, -- �ۼ��� ����
								MOD_USER_ID, -- ������ ID
								MOD_DATE -- �����Ͻ�
						)
						SELECT @n_target_column_id COLUMN_ID, -- �÷� ID
								@n_temp_oid ENTITY_ID, -- ����Ƽ ID
								COLUMN_NM, -- �÷� �̸�
								DISPLAY_NM, -- �÷� ǥ�ø�
								KEY_YN, -- Ű ����
								USE_AUTO_INSERT_YN, -- �Է½� �ڵ��� ��� ����
								USE_AUTO_UPDATE_YN, -- ������ �ڵ��� ��� ��
								START_DATE_COL_YN, -- ������ �÷� ����
								END_DATE_COL_YN, -- ������ �÷� ����
								HK_YN, -- �����丮 Ű ����
								AUTO_INSERT_VALUE, -- �Է½� �ڵ��Ҵ� ��
								AUTO_UPDATE_VALUE, -- ������ �ڵ��Ҵ� ��
								CREATOR_CD, -- �ۼ��� ����
								MOD_USER_ID, -- ������ ID
								MOD_DATE -- �����Ͻ�
						  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_ENTITY_COLUMN
						 WHERE COLUMN_ID = @n_origin_column_id
					-- ==============================================================================
					-- FRM_ENTITY_COLUMN_MAPPING ����
					-- ==============================================================================
						INSERT INTO FRM_ENTITY_COLUMN_MAPPING(
								COLUMN_MAPPING_ID, -- ���� ID
								COLUMN_ID, -- �÷� ID
								TARGET_OBJECT_NM, -- ��� ������Ʈ �̸�
								TARGET_OBJECT_TYPE_CD, -- ��� ������Ʈ �����ڵ�
								TARGET_COLUMN_NM, -- ��� �÷� �̸�
								CREATOR_CD, -- �ۼ��� ���� �ڵ�
								MOD_USER_ID, -- ������ID
								MOD_DATE -- �����Ͻ�
						)
						SELECT NEXT VALUE FOR S_FRM_SEQUENCE COLUMN_MAPPING_ID, -- ���� ID
								@n_target_column_id COLUMN_ID, -- �÷� ID
								TARGET_OBJECT_NM, -- ��� ������Ʈ �̸�
								TARGET_OBJECT_TYPE_CD, -- ��� ������Ʈ �����ڵ�
								TARGET_COLUMN_NM, -- ��� �÷� �̸�
								CREATOR_CD, -- �ۼ��� ���� �ڵ�
								MOD_USER_ID, -- ������ID
								MOD_DATE -- �����Ͻ�
						  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_ENTITY_COLUMN_MAPPING
						 WHERE COLUMN_ID = @n_origin_column_id
					END TRY
					BEGIN CATCH
						set @v_err_msg = ERROR_MESSAGE()
						PRINT 'ERROR ' + @v_err_msg
						RETURN
					END CATCH
				END
				CLOSE DTL_CUR
				DEALLOCATE DTL_CUR
				PRINT '����Ϸ�:' + @v_entity_nm
			END TRY
			BEGIN CATCH
				set @v_err_msg = ERROR_MESSAGE()
				PRINT 'ERROR ' + @v_err_msg
				RETURN
			END CATCH
		END
	CLOSE COPY_CUR
	DEALLOCATE COPY_CUR
	PRINT 'ENTITY COPY COMPLETE: ' + @av_entity_nm + '%'
GO
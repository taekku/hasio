USE [dwehr_H5]
SET NOCOUNT ON
/*
 * 개발(Dev) -> 운영(Real)로 Entity 복사
 */
DECLARE @av_entity_nm        nvarchar(300) -- 
      , @v_entity_nm			nvarchar(300)
	  , @n_temp_oid			numeric(38)
	  , @n_source_oid		numeric(38)
	  , @n_origin_column_id		numeric(38)
	  , @n_target_column_id		numeric(38)
	  , @v_err_msg			nvarchar(1000)
	SET @av_entity_nm = 'EN_FRM_FILE_BIZ_GUIDE' -- LIKE를 수행

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
			PRINT '너무많은 복사를 수행합니다. 자료를 다시 확인하세요.[' + @av_entity_nm + ']'
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
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			FETCH NEXT FROM COPY_CUR
			      INTO @n_source_oid, @v_entity_nm
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				-- ==============================================================================
				-- 비즈니스 컬럼 매핑 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_ENTITY_COLUMN_MAPPING A
				  JOIN FRM_ENTITY_COLUMN B
				    ON A.COLUMN_ID = B.COLUMN_ID
				  JOIN FRM_ENTITY C
				    ON B.ENTITY_ID = C.ENTITY_ID
				 WHERE C.ENTITY_NM = @v_entity_nm
				-- ==============================================================================
				-- 서비스 유효성 검사기 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_ENTITY_COLUMN A
				  JOIN FRM_ENTITY B
				    ON A.ENTITY_ID = B.ENTITY_ID
				 WHERE B.ENTITY_NM = @v_entity_nm
				-- ==============================================================================
				-- DEF 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_ENTITY A
				 WHERE A.ENTITY_NM = @v_entity_nm
			Print '삭제:' + @v_entity_nm
				
				-- ==============================================================================
				-- ENTITY 정의 복사
				-- ==============================================================================
				SET @n_temp_oid = NEXT VALUE FOR S_FRM_SEQUENCE
				INSERT FRM_ENTITY (
						ENTITY_ID, -- 엔터티 ID
						ENTITY_NM, -- 엔터티 이름
						DISPLAY_NM, -- 화면표시명
						HISTORY_TYPE_CD, -- 이력 관리 유형코드
						LOG_YN, -- 로그사용 여부
						NOTE, -- 설명
						UNIT_CD, -- 단위업무코드
						CREATOR_CD, -- 생성자 유형 코드 (pkg | site)
						MOD_USER_ID, -- 변경자 ID
						MOD_DATE -- 변경일시
				)
				SELECT @n_temp_oid ENTITY_ID,   -- 엔터티 ID
						ENTITY_NM, -- 엔터티 이름
						DISPLAY_NM, -- 화면표시명
						HISTORY_TYPE_CD, -- 이력 관리 유형코드
						LOG_YN, -- 로그사용 여부
						NOTE, -- 설명
						UNIT_CD, -- 단위업무코드
						CREATOR_CD, -- 생성자 유형 코드 (pkg | site)
						MOD_USER_ID, -- 변경자 ID
						MOD_DATE -- 변경일시
				  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_ENTITY -- ENTITY 정의
					WHERE ENTITY_ID = @n_source_oid

				-- ==============================================================================
				-- 비즈니스 엔터티 컬럼  복사
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
					-- ENTITY_COLUMN 복사
					-- ==============================================================================
						SET @n_target_column_id = NEXT VALUE FOR S_FRM_SEQUENCE
						INSERT INTO FRM_ENTITY_COLUMN(
								COLUMN_ID, -- 컬럼 ID
								ENTITY_ID, -- 엔터티 ID
								COLUMN_NM, -- 컬럼 이름
								DISPLAY_NM, -- 컬럼 표시명
								KEY_YN, -- 키 여부
								USE_AUTO_INSERT_YN, -- 입력시 자동값 사용 여부
								USE_AUTO_UPDATE_YN, -- 수정시 자동값 사용 여
								START_DATE_COL_YN, -- 시작일 컬럼 여부
								END_DATE_COL_YN, -- 종료일 컬럼 여부
								HK_YN, -- 히스토리 키 여부
								AUTO_INSERT_VALUE, -- 입력시 자동할당 값
								AUTO_UPDATE_VALUE, -- 수정시 자동할당 값
								CREATOR_CD, -- 작성자 유형
								MOD_USER_ID, -- 변경자 ID
								MOD_DATE -- 변경일시
						)
						SELECT @n_target_column_id COLUMN_ID, -- 컬럼 ID
								@n_temp_oid ENTITY_ID, -- 엔터티 ID
								COLUMN_NM, -- 컬럼 이름
								DISPLAY_NM, -- 컬럼 표시명
								KEY_YN, -- 키 여부
								USE_AUTO_INSERT_YN, -- 입력시 자동값 사용 여부
								USE_AUTO_UPDATE_YN, -- 수정시 자동값 사용 여
								START_DATE_COL_YN, -- 시작일 컬럼 여부
								END_DATE_COL_YN, -- 종료일 컬럼 여부
								HK_YN, -- 히스토리 키 여부
								AUTO_INSERT_VALUE, -- 입력시 자동할당 값
								AUTO_UPDATE_VALUE, -- 수정시 자동할당 값
								CREATOR_CD, -- 작성자 유형
								MOD_USER_ID, -- 변경자 ID
								MOD_DATE -- 변경일시
						  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_ENTITY_COLUMN
						 WHERE COLUMN_ID = @n_origin_column_id
					-- ==============================================================================
					-- FRM_ENTITY_COLUMN_MAPPING 복사
					-- ==============================================================================
						INSERT INTO FRM_ENTITY_COLUMN_MAPPING(
								COLUMN_MAPPING_ID, -- 맵핑 ID
								COLUMN_ID, -- 컬럼 ID
								TARGET_OBJECT_NM, -- 대상 오브젝트 이름
								TARGET_OBJECT_TYPE_CD, -- 대상 오브젝트 유형코드
								TARGET_COLUMN_NM, -- 대상 컬럼 이름
								CREATOR_CD, -- 작성자 유형 코드
								MOD_USER_ID, -- 변경자ID
								MOD_DATE -- 변경일시
						)
						SELECT NEXT VALUE FOR S_FRM_SEQUENCE COLUMN_MAPPING_ID, -- ？핑 ID
								@n_target_column_id COLUMN_ID, -- 컬럼 ID
								TARGET_OBJECT_NM, -- 대상 오브젝트 이름
								TARGET_OBJECT_TYPE_CD, -- 대상 오브젝트 유형코드
								TARGET_COLUMN_NM, -- 대상 컬럼 이름
								CREATOR_CD, -- 작성자 유형 코드
								MOD_USER_ID, -- 변경자ID
								MOD_DATE -- 변경일시
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
				PRINT '복사완료:' + @v_entity_nm
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
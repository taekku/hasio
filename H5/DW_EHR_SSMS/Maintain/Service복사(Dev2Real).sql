USE [dwehr_H5]
/*
 * 개발(Dev) -> 운영(Real)로 서비스 복사
 */
DECLARE @av_service_nm        nvarchar(300) -- 복사할 소스 SQL 이름 LIKE
      , @v_service_nm			nvarchar(300)
	  , @n_temp_oid			numeric(38)
	  , @n_source_oid		numeric(38)
	  , @v_err_msg			nvarchar(1000)
	SET @av_service_nm = 'REP0018' -- LIKE를 수행

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
	--		PRINT '너무많은 복사를 수행합니다. 자료를 다시 확인하세요.[' + @av_service_nm + ']'
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
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			FETCH NEXT FROM COPY_CUR
			      INTO @n_source_oid, @v_service_nm
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				-- ==============================================================================
				-- 서비스 전처리 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_OPT A
				  JOIN FRM_SERVICE_DEF B
				    ON A.SV_DEF_ID = B.SV_DEF_ID
				 WHERE B.SV_DEF_NM = @v_service_nm
				-- ==============================================================================
				-- 서비스 유효성 검사기 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_VAL_DEF A
				  JOIN FRM_SERVICE_DEF B
				    ON A.SV_DEF_ID = B.SV_DEF_ID
				 WHERE B.SV_DEF_NM = @v_service_nm
				-- ==============================================================================
				-- 서비스 기능매핑 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_FUNC_MAP A
				  JOIN FRM_SERVICE_DEF B
				    ON A.SV_DEF_ID = B.SV_DEF_ID
				 WHERE B.SV_DEF_NM = @v_service_nm
				-- ==============================================================================
				-- 서비스 속성 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_ATTR A
				  JOIN FRM_SERVICE_DEF B
				    ON A.SV_DEF_ID = B.SV_DEF_ID
				 WHERE B.SV_DEF_NM = @v_service_nm
				-- ==============================================================================
				-- 서비스 권한제어 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_AUTH_GROUP A
				  JOIN FRM_SERVICE_DEF B
				    ON A.SV_DEF_ID = B.SV_DEF_ID
				 WHERE B.SV_DEF_NM = @v_service_nm
				-- ==============================================================================
				-- DEF 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_SERVICE_DEF A
				 WHERE A.SV_DEF_NM = @v_service_nm
			Print '삭제:' + @v_service_nm
				SET @n_temp_oid = NEXT VALUE FOR S_FRM_SEQUENCE
				
				-- ==============================================================================
				-- 서비스 정의 복사
				-- ==============================================================================
				INSERT FRM_SERVICE_DEF (        -- 서비스 정의
					   SV_DEF_ID                      -- 트랜잭션ID
					 , SV_DEF_NM                      -- 트랜잭션명
					 , CMD_CLASS_NM                   -- 커맨드클래스명
					 , TX_SUPPORT_YN                  -- 2PC 지원여부
					 , VERSION                        -- 버전
					 , NOTE                           -- 설명
					 , MOD_USER_ID                    -- 변경자ID
					 , MOD_DATE                       -- 변경일시
					 , ASYNC_YN                       -- 비동기처리여부
					 , OBJECT_ID                      -- 오브젝트ID
					 , USE_LOG_YN                     -- 로그사용여부
				)
				SELECT @n_temp_oid                    -- 트랜잭션ID
					 , SV_DEF_NM          -- 트랜잭션명
					 , CMD_CLASS_NM                   -- 커맨드클래스명
					 , TX_SUPPORT_YN                  -- 2PC 지원여부
					 , VERSION                        -- 버전
					 , NOTE                           -- 설명
					 , MOD_USER_ID                    -- 변경자ID
					 , MOD_DATE                       -- 변경일시
					 , ASYNC_YN                       -- 비동기처리여부
					 , OBJECT_ID                      -- 오브젝트ID
					 , USE_LOG_YN                     -- 로그사용여부
				  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_DEF        -- 서비스 정의
					WHERE SV_DEF_NM = @v_service_nm;

				-- ==============================================================================
				-- 서비스 속성 복사
				-- ==============================================================================
				INSERT FRM_SERVICE_ATTR (        -- 트랜잭 속성 정의
					   SV_ATTR_ID                     -- 트랜잭션 속성 ID
					 , SV_DEF_ID                      -- 트랜잭션ID
					 , SV_ATTR_NM                     -- 트랜잭션 속성 명
					 , NOTE                           -- 비고
					 , SV_ATTR_TYPE                   -- 속성 타입 ( ATTR | MSG | EVENT ...)
					 , DEFAULT_VALUE                  -- 기본 값
					 , MOD_USER_ID                    -- 변경자
					 , MOD_DATE                       -- 변경일시
					 , VALUE_TYPE                     -- 값타입
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- 트랜잭션 속성 ID
					 , @n_temp_oid                    -- 트랜잭션ID
					 , SV_ATTR_NM                     -- 트랜잭션 속성 명
					 , NOTE                           -- 비고
					 , SV_ATTR_TYPE                   -- 속성 타입 ( ATTR | MSG | EVENT ...)
					 , DEFAULT_VALUE                  -- 기본 값
					 , MOD_USER_ID                    -- 변경자
					 , MOD_DATE                       -- 변경일시
					 , VALUE_TYPE                     -- 값타입
				  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_ATTR        -- 트랜잭 속성 정의
				 WHERE SV_DEF_ID = @n_source_oid
				-- ==============================================================================
				-- 서비스 기능매핑 복사
				-- ==============================================================================
				INSERT FRM_SERVICE_FUNC_MAP (        -- 기능매핑
						SV_MAP_ID                      -- 기능매핑 ID
						, SV_DEF_ID                      -- 트랜잭션ID
						, SV_MAP_TYPE_CD                 -- 기능구분 코드 ( SQL | ENTITY |  ETC)
						, FUNC_NM                        -- 기능명
						, SEQ_ORDER                      -- 적용순서
						, REQ_MSG_NM                     -- 요청메시지 이름
						, RES_MSG_NM                     -- 반환 메시지 이름
						, MOD_DATE                       -- 변경자
						, MOD_USER_ID                    -- 변경일시
						, USE_TREE_RESULT                -- 결과를트리로반환
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- 기능매핑 ID
						, @n_temp_oid                    -- 트랜잭션ID
						, SV_MAP_TYPE_CD                 -- 기능구분 코드 ( SQL | ENTITY |  ETC)
						, FUNC_NM                        -- 기능명
						, SEQ_ORDER                      -- 적용순서
						, REQ_MSG_NM                     -- 요청메시지 이름
						, RES_MSG_NM                     -- 반환 메시지 이름
						, MOD_DATE                       -- 변경자
						, MOD_USER_ID                    -- 변경일시
						, USE_TREE_RESULT                -- 결과를트리로반환
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_FUNC_MAP           -- 기능매핑
					WHERE SV_DEF_ID = @n_source_oid

				-- ==============================================================================
				-- 서비스 유효성 검사기 복사
				-- ==============================================================================
				INSERT FRM_SERVICE_VAL_DEF (        -- 트랜잭션 유효성 검사기 정의
						SV_VAL_DEF_ID                  -- 유효성 검사기 정의 ID
						, SV_DEF_ID                      -- 트랜잭션ID
						, VAL_TYPE_CD                    -- 검사 처리 유형 코드
						, SEQ_ORDER                      -- 적용순서
						, VAL_LC_TYPE_CD                 -- 검사시점코드
						, VALIDATOR_NM                   -- 유효성 검사기 이름
						, MSG_NM                         -- 사용 메시지 이름
						, MOD_USER_ID                    -- 변경자
						, MOD_DATE                       -- 변경일시
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- 유효성 검사기 정의 ID
						, @n_temp_oid                    -- 트랜잭션ID
						, VAL_TYPE_CD                    -- 검사 처리 유형 코드
						, SEQ_ORDER                      -- 적용순서
						, VAL_LC_TYPE_CD                 -- 검사시점코드
						, VALIDATOR_NM                   -- 유효성 검사기 이름
						, MSG_NM                         -- 사용 메시지 이름
						, MOD_USER_ID                    -- 변경자
						, MOD_DATE                       -- 변경일시
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_VAL_DEF            -- 트랜잭션 유효성 검사기 정의
					WHERE SV_DEF_ID = @n_source_oid
					
				-- ==============================================================================
				-- 서비스 권한제어
				-- ==============================================================================
				INSERT FRM_SERVICE_AUTH_GROUP ( 
						SV_AUTH_ID, -- 권한매핑 ID
						SV_DEF_ID, -- 트랜잭션ID
						USERGROUP_ID, -- FRM_USER_GROUP 맵핑
						MOD_DATE, -- 변경자
						MOD_USER_ID, -- 변경일시
						COMPANY_CD -- 계열사코드
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- 유효성 검사기 정의 ID
						, @n_temp_oid                    -- 트랜잭션ID
							,C.USERGROUP_ID, -- FRM_USER_GROUP 맵핑
							A.MOD_DATE, -- 변경자
							A.MOD_USER_ID, -- 변경일시
							A.COMPANY_CD  -- 계열사코드
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_AUTH_GROUP A
					JOIN [172.20.16.40].[dwehrdev_H5].[dbo].FRM_USER_GROUP B
					  ON A.USERGROUP_ID = B.USERGROUP_ID
					JOIN FRM_USER_GROUP C
					  ON B.COMPANY_CD = C.COMPANY_CD
					 AND B.GROUP_TYPE = C.GROUP_TYPE
					 AND B.USERGROUP_NM = C.USERGROUP_NM
					WHERE A.SV_DEF_ID = @n_source_oid

				-- ==============================================================================
				-- 서비스 전처리 복사
				-- ==============================================================================
				INSERT FRM_SERVICE_OPT (        -- 서비스 전처리
						SV_OPT_ID, -- 전처리 ID
						SV_DEF_ID, -- 트랜잭션ID
						OPT_CD, -- 옵션코드[FRM_SV_OPT_CD]
						OPT_VALUE, -- 옵션값[FRM_SV_OPT_VALUE_CD]
						MOD_DATE, -- 변경자
						MOD_USER_ID, -- 변경일시
						NOTE -- 비고
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- 전처리 ID
						, @n_temp_oid                    -- 트랜잭션ID
						, OPT_CD -- 옵션코드[FRM_SV_OPT_CD]
						, OPT_VALUE -- 옵션값[FRM_SV_OPT_VALUE_CD]
						, MOD_DATE -- 변경자
						, MOD_USER_ID -- 변경일시
						, NOTE -- 비고
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_SERVICE_OPT            -- 트랜잭션 유효성 검사기 정의
					WHERE SV_DEF_ID = @n_source_oid
				PRINT '복사완료:' + @v_service_nm
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
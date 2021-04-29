USE [dwehr_H5]
/*
 * 개발(Dev) -> 운영(Real)로 SQL 복사
 */
DECLARE @av_query_nm        nvarchar(300) -- 복사할 소스 SQL 이름 LIKE
      , @v_query_nm			nvarchar(80)
	  , @n_frm_query_id		numeric(38)
	  , @v_err_msg			nvarchar(1000)
	SET @av_query_nm = 'PAY0036' -- LIKE를 수행-
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
			--  As-Is 테이블에서 KEY SELECT
			-- =============================================
			FETCH NEXT FROM COPY_CUR
			      INTO @v_query_nm
			IF @@FETCH_STATUS <> 0 BREAK
			BEGIN TRY
				-- ==============================================================================
				-- PARAM 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_QUERY_DEF_PARAM A
				  JOIN FRM_QUERY_DEF B
				    ON A.QUERY_DEF_ID = B.QUERY_DEF_ID
				 WHERE B.QUERY_NAME = @v_query_nm
				-- ==============================================================================
				-- BODY 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_QUERY_DEF_BODY A
				  JOIN FRM_QUERY_DEF B
				    ON A.QUERY_DEF_ID = B.QUERY_DEF_ID
				 WHERE B.QUERY_NAME = @v_query_nm
				-- ==============================================================================
				-- DEF 삭제
				-- ==============================================================================
				DELETE A
				  FROM FRM_QUERY_DEF A
				 WHERE A.QUERY_NAME = @v_query_nm
			
				SET @n_frm_query_id = NEXT VALUE FOR S_FRM_SEQUENCE
				-- ==============================================================================
				-- SQL 정의 복사
				-- ==============================================================================
				INSERT FRM_QUERY_DEF (        -- SQL Invoker용 쿼리 정의
						QUERY_DEF_ID                   -- 쿼리 ID
						, WORKSPACE_ID                   -- 워크스페이스ID
						, COMPANY_CD                     -- 인사영역
						, QUERY_NAME                     -- 쿼리명
						, DISPLAY_NAME                   -- 화면표시명
						, USE_YN                         -- 사용여부
						, STATUS                         -- 상태
						, VERSION                        -- 버전
						, DATA_SOURCE                    -- 사용데이터소스
						, NOTE                           -- 비고
						, CREATE_TIME                    -- 생성일
						, BIZ_AUTH_YN                    -- 사업장권한체크여부
						, ORG_AUTH_YN                    -- 조직권한체크여부
						, DECORATORS                     -- 허용데코레이터
				)
				SELECT @n_frm_query_id                    -- 쿼리 ID
						, WORKSPACE_ID                   -- 워크스페이스ID
						, COMPANY_CD                     -- 인사영역
						, QUERY_NAME                     -- 쿼리명
						, DISPLAY_NAME                   -- 화면표시명
						, USE_YN                         -- 사용여부
						, STATUS                         -- 상태
						, VERSION                        -- 버전
						, DATA_SOURCE                    -- 사용데이터소스
						, NOTE                           -- 비고
						, DBO.XF_SYSDATE(0)              -- 생성일
						, BIZ_AUTH_YN                    -- 사업장권한체크여부
						, ORG_AUTH_YN                    -- 조직권한체크여부
						, DECORATORS                     -- 허용데코레이터
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_QUERY_DEF        -- SQL Invoker용 쿼리 정의
					WHERE QUERY_NAME = @v_query_nm;
				-- ==============================================================================
				-- SQL의 BODY 복사
				-- ==============================================================================
				INSERT FRM_QUERY_DEF_BODY (        -- 쿼리 문장
						QUERY_BODY_ID                  -- 쿼리 문 ID
						, QUERY_DEF_ID                   -- 쿼리 ID
						, QUERY_STRING                   -- 쿼리문
						, CREATE_TIME                    -- 변경일
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- 쿼리 문 ID
						, @n_frm_query_id                    -- 쿼리 ID
						, A.QUERY_STRING                 -- 쿼리문
						, DBO.XF_SYSDATE(0)              -- 변경일
					FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_QUERY_DEF_BODY A       -- 쿼리 문장
						, [172.20.16.40].[dwehrdev_H5].[dbo].FRM_QUERY_DEF B
					WHERE A.QUERY_DEF_ID = B.QUERY_DEF_ID
					AND B.QUERY_NAME = @v_query_nm;
					
				-- ==============================================================================
				-- SQL의 PARAM 복사
				-- ==============================================================================
				INSERT FRM_QUERY_DEF_PARAM (        -- 쿼리 파라미터
					   QUERY_PARAM_ID                 -- 파라미터 ID
					 , QUERY_DEF_ID                   -- 쿼리 문 ID
					 , QUERY_PARAM_NAME               -- 파라미터 명
					 , QUERY_PARAM_SEQ                -- 파라미터 순서
					 , QUERY_PARAM_TYPE               -- 파라미터 유형
					 , QUERY_PARAM_INOUT_TYPE         -- 인아웃 유형
					 , CREATE_TIME                    -- 생성일
				)
				SELECT NEXT VALUE FOR S_FRM_SEQUENCE           -- 파라미터 ID
					 , @n_frm_query_id                    -- 쿼리 문 ID
					 , QUERY_PARAM_NAME               -- 파라미터 명
					 , QUERY_PARAM_SEQ                -- 파라미터 순서
					 , QUERY_PARAM_TYPE               -- 파라미터 유형
					 , QUERY_PARAM_INOUT_TYPE         -- 인아웃 유형
					 , DBO.XF_SYSDATE(0)              -- 생성일
				  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_QUERY_DEF_PARAM A       -- 쿼리 파라미터
					 , [172.20.16.40].[dwehrdev_H5].[dbo].FRM_QUERY_DEF B
				WHERE A.QUERY_DEF_ID = B.QUERY_DEF_ID
				  AND B.QUERY_NAME = @v_query_nm
				PRINT '복사완료:' + @v_query_nm
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
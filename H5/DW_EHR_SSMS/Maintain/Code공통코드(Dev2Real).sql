USE [dwehr_H5]
BEGIN
	DECLARE @v_cd_kind nvarchar(150)	-- 코드분류
	      , @v_target_company_cd nvarchar(150)  -- 회사
		, @b_master_copy char(1) -- 마스터 복사여부
		, @b_code_copy char(1) -- 회사별코드 복사여부
		, @b_code_sys_copy char(1) -- 시스템코드 복사여부

	SET @v_cd_kind = 'PEB_POS_CLS_CD' -- 코드분류
	SET @v_target_company_cd = 'A,B,C,E,F,H,I,M,R,S,T,U,W,X,Y' -- 복사할 회사 -- 콤마로 구분
	-----------------------------------------------------
	SET @b_master_copy = 'Y' -- Y/N  마스터 복사여부
	SET @b_code_copy = 'Y' -- Y/N 회사별코드 복사여부
	SET @b_code_sys_copy = 'Y' -- Y/N 시스템코드 복사여부

	DECLARE @TARGET_COMPANY TABLE(
		COMPANY_CD	NVARCHAR(10)
	)
	
	-- ==============================================================================
	-- 마스터 복사여부
	-- ==============================================================================
	IF @b_master_copy = 'Y'
		BEGIN
			DELETE A
			  FROM FRM_CODE_KIND A
			 WHERE CD_KIND = @v_cd_kind
			INSERT INTO FRM_CODE_KIND(
				CD_KIND_ID, -- 코드분류ID
				LOCALE_CD, -- 지역코드
				CD_KIND, -- 코드분류
				CD_KIND_NM, -- 코드분류명
				STA_YMD, -- 생성일자
				END_YMD, -- 종료일자
				CHANGE_YN, -- 자료변경여부(자료수정,추가 가능여부)
				NOTE, -- 비고
				MOD_USER_ID, -- 변경자
				MOD_DATE, -- 변경일시
				GROUP_YN  -- 그룹여부 ( Y:하단탭내용편집불가-사용여부제외 / N:하단탭편집가능 )
			)
			SELECT 
				NEXT VALUE FOR S_FRM_SEQUENCE	CD_KIND_ID, -- 코드분류ID
				LOCALE_CD, -- 지역코드
				CD_KIND, -- 코드분류
				CD_KIND_NM, -- 코드분류명
				STA_YMD, -- 생성일자
				END_YMD, -- 종료일자
				CHANGE_YN, -- 자료변경여부(자료수정,추가 가능여부)
				NOTE, -- 비고
				MOD_USER_ID, -- 변경자
				MOD_DATE, -- 변경일시
				GROUP_YN  -- 그룹여부 ( Y:하단탭내용편집불가-사용여부제외 / N:하단탭편집가능 )
			  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_CODE_KIND
			  WHERE CD_KIND = @v_cd_kind
		END

	-- ==============================================================================
	-- 회사별코드 복사여부
	-- ==============================================================================
	IF @b_code_copy = 'Y'
		BEGIN
			INSERT INTO @TARGET_COMPANY
			SELECT ITEMS
			  FROM dbo.fn_split_array(@v_target_company_cd,',')

			DELETE A
			  FROM FRM_CODE A
			  JOIN @TARGET_COMPANY T
			    ON A.COMPANY_CD = T.COMPANY_CD
			   AND A.CD_KIND = @v_cd_kind
			INSERT INTO FRM_CODE(
					CD_ID, -- 코드id
					LOCALE_CD, -- 지역코드
					COMPANY_CD, -- 회사코드(인사영역)
					CD_KIND, -- 코드분류
					CD, -- 코드
					CD_NM, -- 코드명
					SHORT_NM, -- 코드약명
					FOR_NM, -- 외국어명
					PRINT_NM, -- 출력명
					MAIN_CD, -- 주코드
					SYS_CD, -- 시스템코드
					STA_YMD, -- 생성일자
					END_YMD, -- 종료일자
					ORD_NO, -- 정렬순서
					NOTE, -- 비고
					MOD_USER_ID, -- 변경자
					MOD_DATE, -- 변경일시
					LABEL_CD, -- 어휘관리 항목명 2016.07.13 추가
					GROUP_USE_YN -- 그룹사용여부( Y / N )
			)
			SELECT NEXT VALUE FOR S_FRM_SEQUENCE CD_ID, -- 코드id
					A.LOCALE_CD, -- 지역코드
					A.COMPANY_CD, -- 회사코드(인사영역)
					A.CD_KIND, -- 코드분류
					A.CD, -- 코드
					A.CD_NM, -- 코드명
					A.SHORT_NM, -- 코드약명
					A.FOR_NM, -- 외국어명
					A.PRINT_NM, -- 출력명
					A.MAIN_CD, -- 주코드
					A.SYS_CD, -- 시스템코드
					A.STA_YMD, -- 생성일자
					A.END_YMD, -- 종료일자
					A.ORD_NO, -- 정렬순서
					A.NOTE, -- 비고
					A.MOD_USER_ID, -- 변경자
					A.MOD_DATE, -- 변경일시
					A.LABEL_CD, -- 어휘관리 항목명 2016.07.13 추가
					A.GROUP_USE_YN -- 그룹사용여부( Y / N )
			  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_CODE A
			  JOIN @TARGET_COMPANY T
			    ON A.COMPANY_CD = T.COMPANY_CD
			   AND A.CD_KIND = @v_cd_kind
		END
	-- ==============================================================================
	-- 시스템코드 복사여부
	-- ==============================================================================
	IF @b_code_sys_copy = 'Y'
		BEGIN
			DELETE A
			  FROM FRM_CODE_SYS A
			 WHERE CD_KIND = @v_cd_kind
			INSERT INTO FRM_CODE_SYS(
					SYS_CD_ID, -- 시스템코드ID
					LOCALE_CD, -- 지역코드
					CD_KIND, -- 코드분류
					SYS_CD, -- 시스템코드
					SYS_CD_NM, -- 시스템코드명
					NOTE, -- 비고
					MOD_USER_ID, -- 변경자
					MOD_DATE, -- 변경일시
					LABEL_CD -- 어휘관리 항목명 2016.07.13 추가
			)
			SELECT
					NEXT VALUE FOR S_FRM_SEQUENCE	SYS_CD_ID, -- 시스템코드ID
					LOCALE_CD, -- 지역코드
					CD_KIND, -- 코드분류
					SYS_CD, -- 시스템코드
					SYS_CD_NM, -- 시스템코드명
					NOTE, -- 비고
					MOD_USER_ID, -- 변경자
					MOD_DATE, -- 변경일시
					LABEL_CD -- 어휘관리 항목명 2016.07.13 추가
			  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_CODE_SYS
			 WHERE CD_KIND = @v_cd_kind
		END
END
GO
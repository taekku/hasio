BEGIN
	 DECLARE @v_source_company_cd NVARCHAR(100) = 'X'
	       , @v_target_company_cd NVARCHAR(100) = 'A,B,C,E,F,H,I,M,R,S,T,U,W,X,Y'
		   , @v_unit_cd NVARCHAR(100) = 'TBS'
		   , @v_std_kind	NVARCHAR(100) = 'TBS_DEBIS_PAY'
	DECLARE @TARGET_COMPANY TABLE(
		COMPANY_CD	NVARCHAR(10)
	)
	INSERT INTO @TARGET_COMPANY
	SELECT ITEMS
	FROM dbo.fn_split_array(@v_target_company_cd,',')
	WHERE Items != @v_source_company_cd

--설정값 삭제
DELETE FROM FRM_UNIT_STD_HIS
WHERE FRM_UNIT_STD_MGR_ID IN (
															SELECT FRM_UNIT_STD_MGR_ID
															FROM FRM_UNIT_STD_MGR 
															WHERE COMPANY_CD IN (SELECT COMPANY_CD FROM @TARGET_COMPANY)
															AND UNIT_CD = @v_unit_cd
															AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
															)

--업무기준관리 분류키
DELETE FROM FRM_UNIT_ETC
WHERE FRM_UNIT_STD_MGR_ID IN (
															SELECT FRM_UNIT_STD_MGR_ID 
															FROM FRM_UNIT_STD_MGR 
															WHERE COMPANY_CD IN (SELECT COMPANY_CD FROM @TARGET_COMPANY)
															AND UNIT_CD = @v_unit_cd
															AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
															)

--업무기준관리 코드키
DELETE FROM FRM_UNIT_STD_ETC
WHERE FRM_UNIT_STD_MGR_ID IN (
															SELECT FRM_UNIT_STD_MGR_ID 
															FROM FRM_UNIT_STD_MGR 
															WHERE COMPANY_CD IN (SELECT COMPANY_CD FROM @TARGET_COMPANY)
															AND UNIT_CD = @v_unit_cd
															AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
															)

DELETE FROM FRM_UNIT_STD_MGR 
							WHERE COMPANY_CD IN (SELECT COMPANY_CD FROM @TARGET_COMPANY)
							AND UNIT_CD = @v_unit_cd
							AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))


/*=============================================================================================================
업무기준 FRM_UNIT_STD_MGR 생성
=============================================================================================================*/
	BEGIN
		INSERT INTO FRM_UNIT_STD_MGR
		SELECT 
				next VALUE FOR S_FRM_SEQUENCE ,    --기준관리ID
				A.LOCALE_CD,    --지역코드
				T.COMPANY_CD,    --인사영역코드
				A.UNIT_CD,    --단위업무코드
				A.KEY1,    --분류키1
				A.KEY2,    --분류키2
				A.KEY3,    --분류키3
				A.KEY4,    --분류키4
				A.KEY5,    --분류키5
				A.STD_KIND,    --기준분류
				A.STD_KIND_NM,    --기준분류명
				A.FUNCTION_CM,    --FUNCTION설명
				A.SQL,    --SQL
				A.CHANGE_YN,    --자료변경여부
				A.NOTE,    --비고
				A.MOD_USER_ID,    --변경자
				A.MOD_DATE,    --변경일시
				A.LABEL_CD    --어휘코드
		  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_MGR A
		  JOIN @TARGET_COMPANY T
		    ON 1=1
		  WHERE A.COMPANY_CD = @v_source_company_cd
							AND UNIT_CD = @v_unit_cd
							AND STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
	END  
  
/*=============================================================================================================
업무기준 FRM_UNIT_STD_HIS 생성
=============================================================================================================*/
	BEGIN
		INSERT INTO FRM_UNIT_STD_HIS
		SELECT 
				next VALUE FOR S_FRM_SEQUENCE FRM_UNIT_STD_HIS_ID,    --기준관리내역ID
				C.FRM_UNIT_STD_MGR_ID,    --기준관리ID
				B.KEY_CD1,    --키코드1
				B.KEY_CD2,    --키코드2
				B.KEY_CD3,    --키코드3
				B.KEY_CD4,    --키코드4
				B.KEY_CD5,    --키코드5
				B.CD1,    --코드1
				B.CD2,    --코드2
				B.CD3,    --코드3
				B.CD4,    --코드4
				B.CD5,    --코드5
				B.ETC_CD1,    --기타코드1
				B.ETC_CD2,    --기타코드2
				B.ETC_CD3,    --기타코드3
				B.ETC_CD4,    --기타코드4
				B.ETC_CD5,    --기타코드5
				B.STA_YMD,    --시작일자
				B.END_YMD,    --종료일자
				B.NOTE,    --비고
				B.MOD_USER_ID,    --변경자
				B.MOD_DATE    --변경일시
		  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_MGR A
		 INNER JOIN [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_HIS B
		    ON A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
		 INNER JOIN FRM_UNIT_STD_MGR C
		    ON A.UNIT_CD = C.UNIT_CD
		   AND A.STD_KIND = C.STD_KIND
		   AND A.LOCALE_CD = C.LOCALE_CD
		   AND ISNULL(A.KEY1,'') = ISNULL(C.KEY1,'')
		   AND ISNULL(A.KEY2,'') = ISNULL(C.KEY2,'')
		   AND ISNULL(A.KEY3,'') = ISNULL(C.KEY3,'')
		   AND ISNULL(A.KEY4,'') = ISNULL(C.KEY4,'')
		   AND ISNULL(A.KEY5,'') = ISNULL(C.KEY5,'')
		 INNER JOIN @TARGET_COMPANY T
		   ON C.COMPANY_CD = T.COMPANY_CD
		  -- AND C.COMPANY_CD = @v_target_company_cd
		 WHERE A.COMPANY_CD = @v_source_company_cd
		AND A.UNIT_CD = @v_unit_cd
		AND A.STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
	END

/*=============================================================================================================
업무기준 FRM_UNIT_STD_ETC 생성
=============================================================================================================*/
	BEGIN
			INSERT INTO FRM_UNIT_STD_ETC
			SELECT 
					C.FRM_UNIT_STD_MGR_ID FRM_UNIT_STD_MGR_ID,    --기준관리ID
					B.TITLE_NM_K1,    --키코드1_타이틀명
					B.EDIT_FORMAT_K1,    --키코드1_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_K1,    --키코드1_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_K1,    --키코드1_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_K1,    --키코드1_필수여부
					B.SQLS_K1,    --키코드1_검색SQL문장
					B.CD_KIND_K1,    --키코드1_분류
					B.TITLE_NM_K2,    --키코드2_타이틀명
					B.EDIT_FORMAT_K2,    --키코드2_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_K2,    --키코드2_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_K2,    --키코드2_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_K2,    --키코드2_필수여부
					B.SQLS_K2,    --키코드2_검색SQL문장
					B.CD_KIND_K2,    --키코드2_분류
					B.TITLE_NM_K3,    --키코드3_타이틀명
					B.EDIT_FORMAT_K3,    --키코드3_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_K3,    --키코드3_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_K3,    --키코드3_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_K3,    --키코드3_필수여부
					B.SQLS_K3,    --키코드3_검색SQL문장
					B.CD_KIND_K3,    --키코드3_분류
					B.TITLE_NM_K4,    --키코드4_타이틀명
					B.EDIT_FORMAT_K4,    --키코드4_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_K4,    --키코드4_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_K4,    --키코드4_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_K4,    --키코드4_필수여부
					B.SQLS_K4,    --키코드4_검색SQL문장
					B.CD_KIND_K4,    --키코드4_분류
					B.TITLE_NM_K5,    --키코드5_타이틀명
					B.EDIT_FORMAT_K5,    --키코드5_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_K5,    --키코드5_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_K5,    --키코드5_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_K5,    --키코드5_필수여부
					B.SQLS_K5,    --키코드5_검색SQL문장
					B.CD_KIND_K5,    --키코드5_분류
					B.TITLE_NM_H1,    --코드1_타이틀명
					B.EDIT_FORMAT_H1,    --코드1_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_H1,    --코드1_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_H1,    --코드1_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_H1,    --코드1_필수여부
					B.SQLS_H1,    --코드1_검색SQL문장
					B.CD_KIND_H1,    --코드1_분류
					B.TITLE_NM_H2,    --코드2_타이틀명
					B.EDIT_FORMAT_H2,    --코드2_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_H2,    --코드2_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_H2,    --코드2_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_H2,    --코드2_필수여부
					B.SQLS_H2,    --코드2_검색SQL문장
					B.CD_KIND_H2,    --코드2_분류
					B.TITLE_NM_H3,    --코드3_타이틀명
					B.EDIT_FORMAT_H3,    --코드3_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_H3,    --코드3_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_H3,    --코드3_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_H3,    --코드3_필수여부
					B.SQLS_H3,    --코드3_검색SQL문장
					B.CD_KIND_H3,    --코드3_분류
					B.TITLE_NM_H4,    --코드4_타이틀명
					B.EDIT_FORMAT_H4,    --코드4_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_H4,    --코드4_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_H4,    --코드4_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_H4,    --코드4_필수여부
					B.SQLS_H4,    --코드4_검색SQL문장
					B.CD_KIND_H4,    --코드4_분류
					B.TITLE_NM_H5,    --코드5_타이틀명
					B.EDIT_FORMAT_H5,    --코드5_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_H5,    --코드5_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_H5,    --코드5_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_H5,    --코드5_필수여부
					B.SQLS_H5,    --코드5_검색SQL문장
					B.CD_KIND_H5,    --코드5_분류
					B.TITLE_NM_U1,    --기타코드1_타이틀명1
					B.EDIT_FORMAT_U1,    --기타코드1_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_U1,    --기타코드1_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_U1,    --기타코드1_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_U1,    --기타코드1_필수여부
					B.SQLS_U1,    --기타코드1_검색SQL문장
					B.CD_KIND_U1,    --기타코드1_분류
					B.TITLE_NM_U2,    --기타코드2_타이틀명
					B.EDIT_FORMAT_U2,    --기타코드2_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_U2,    --기타코드2_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_U2,    --기타코드2_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_U2,    --기타코드2_필수여부
					B.SQLS_U2,    --기타코드2_검색SQL문장
					B.CD_KIND_U2,    --기타코드2_분류
					B.TITLE_NM_U3,    --기타코드3_타이틀명1
					B.EDIT_FORMAT_U3,    --기타코드3_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_U3,    --기타코드3_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_U3,    --기타코드3_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_U3,    --기타코드3_필수여부
					B.SQLS_U3,    --기타코드3_검색SQL문장
					B.CD_KIND_U3,    --기타코드3_분류
					B.TITLE_NM_U4,    --기타코드4_타이틀명1
					B.EDIT_FORMAT_U4,    --기타코드4_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_U4,    --기타코드4_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_U4,    --기타코드4_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_U4,    --기타코드4_필수여부
					B.SQLS_U4,    --기타코드4_검색SQL문장
					B.CD_KIND_U4,    --기타코드4_분류
					B.TITLE_NM_U5,    --기타코드5_타이틀명1
					B.EDIT_FORMAT_U5,    --기타코드5_EDIT포맷(1:텍스트/2:숫자/3:일자/4:금액)
					B.ALIGN_U5,    --기타코드5_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
					B.FORM_EDIT_U5,    --기타코드5_검색유형(1:직접입력/2:콤보/3:팝업)
					B.MAN_YN_U5,    --기타코드5_필수여부
					B.SQLS_U5,    --기타코드5_검색SQL문장
					B.CD_KIND_U5,    --기타코드5_분류
					B.NOTE,    --비고
					B.MOD_USER_ID,    --변경자
					B.MOD_DATE,    --변경일시
					B.LABEL_CD_K1,    --키코드1_어휘코드
					B.LABEL_CD_K2,    --키코드2_어휘코드
					B.LABEL_CD_K3,    --키코드3_어휘코드
					B.LABEL_CD_K4,    --키코드4_어휘코드
					B.LABEL_CD_K5,    --키코드5_어휘코드
					B.LABEL_CD_H1,    --코드1_어휘코드
					B.LABEL_CD_H2,    --코드2_어휘코드
					B.LABEL_CD_H3,    --코드3_어휘코드
					B.LABEL_CD_H4,    --코드4_어휘코드
					B.LABEL_CD_H5,    --코드5_어휘코드
					B.LABEL_CD_U1,    --기타코드1_어휘코드
					B.LABEL_CD_U2,    --기타코드2_어휘코드
					B.LABEL_CD_U3,    --기타코드3_어휘코드
					B.LABEL_CD_U4,    --기타코드4_어휘코드
					B.LABEL_CD_U5    --기타코드5_어휘코드
			  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_MGR A
			 INNER JOIN [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_ETC B
			    ON A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
			 INNER JOIN FRM_UNIT_STD_MGR C
			    ON A.UNIT_CD = C.UNIT_CD
			   AND A.STD_KIND = C.STD_KIND
			   AND A.LOCALE_CD = C.LOCALE_CD
			   AND ISNULL(A.KEY1,'') = ISNULL(C.KEY1,'')
			   AND ISNULL(A.KEY2,'') = ISNULL(C.KEY2,'')
			   AND ISNULL(A.KEY3,'') = ISNULL(C.KEY3,'')
			   AND ISNULL(A.KEY4,'') = ISNULL(C.KEY4,'')
			   AND ISNULL(A.KEY5,'') = ISNULL(C.KEY5,'')
			 INNER JOIN @TARGET_COMPANY T
			   ON C.COMPANY_CD = T.COMPANY_CD
			  -- AND C.COMPANY_CD = @v_target_company_cd
			 WHERE A.COMPANY_CD = @v_source_company_cd
		AND A.UNIT_CD = @v_unit_cd
		AND A.STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
	END

	
	BEGIN
		INSERT FRM_UNIT_ETC  -- 업무별분류키정의  
		(       
		   FRM_UNIT_STD_MGR_ID            -- 기준관리ID
		 , TITLE_NM1                      -- 분류키1_타이틀명
		 , EDIT_FORMAT1                   -- 분류키1_EDIT포멧(1:텍스트/2:숫자/3:일자/4:금액)
		 , ALIGN1                         -- 분류키1_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
		 , FORM_EDIT1                     -- 분류키1_검색유형(1:직접입력/2:콤보/3:팝업)
		 , MAN_YN1                        -- 분류키1_필수여부
		 , SQLS1                          -- 분류키1_검색SQL문장
		 , TITLE_NM2                      -- 분류키2_타이틀명
		 , EDIT_FORMAT2                   -- 분류키2_EDIT포멧(1:텍스트/2:숫자/3:일자/4:금액)
		 , ALIGN2                         -- 분류키2_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
		 , FORM_EDIT2                     -- 분류키2_검색유형(1:직접입력/2:콤보/3:팝업)
		 , MAN_YN2                        -- 분류키2_필수여부
		 , SQLS2                          -- 분류키2_검색SQL문장
		 , TITLE_NM3                      -- 분류키3_타이틀명
		 , EDIT_FORMAT3                   -- 분류키3_EDIT포멧(1:텍스트/2:숫자/3:일자/4:금액)
		 , ALIGN3                         -- 분류키3_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
		 , FORM_EDIT3                     -- 분류키3_검색유형(1:직접입력/2:콤보/3:팝업)
		 , MAN_YN3                        -- 분류키3_필수여부
		 , SQLS3                          -- 분류키3_검색SQL문장
		 , TITLE_NM4                      -- 분류키4_타이틀명
		 , EDIT_FORMAT4                   -- 분류키4_EDIT포멧(1:텍스트/2:숫자/3:일자/4:금액)
		 , ALIGN4                         -- 분류키4_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
		 , FORM_EDIT4                     -- 분류키4_검색유형(1:직접입력/2:콤보/3:팝업)
		 , MAN_YN4                        -- 분류키4_필수여부
		 , SQLS4                          -- 분류키4_검색SQL문장
		 , TITLE_NM5                      -- 분류키5_타이틀명
		 , EDIT_FORMAT5                   -- 분류키5_EDIT포멧(1:텍스트/2:숫자/3:일자/4:금액)
		 , ALIGN5                         -- 분류키5_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
		 , FORM_EDIT5                     -- 분류키5_검색유형(1:직접입력/2:콤보/3:팝업)
		 , MAN_YN5                        -- 분류키5_필수여부
		 , SQLS5                          -- 분류키5_검색SQL문장
		 , NOTE                           -- 비고
		 , MOD_USER_ID                    -- 변경자
		 , MOD_DATE                       -- 변경일시
		 , TZ_CD                          -- 타임존코드
		 , TZ_DATE                        -- 타임존일시
		 , LABEL_CD1                      -- 분류키1_어휘코드
		 , LABEL_CD2                      -- 분류키2_어휘코드
		 , LABEL_CD3                      -- 분류키3_어휘코드
		 , LABEL_CD4                      -- 분류키4_어휘코드
		 , LABEL_CD5                      -- 분류키5_어휘코드
		) 
		SELECT 
				   C.FRM_UNIT_STD_MGR_ID
		     , B.TITLE_NM1                      -- 분류키1_타이틀명
		     , B.EDIT_FORMAT1                   -- 분류키1_EDIT포멧(1:텍스트/2:숫자/3:일자/4:금액)
		     , B.ALIGN1                         -- 분류키1_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
		     , B.FORM_EDIT1                     -- 분류키1_검색유형(1:직접입력/2:콤보/3:팝업)
		     , B.MAN_YN1                        -- 분류키1_필수여부
		     , B.SQLS1                          -- 분류키1_검색SQL문장
		     , B.TITLE_NM2                      -- 분류키2_타이틀명
		     , B.EDIT_FORMAT2                   -- 분류키2_EDIT포멧(1:텍스트/2:숫자/3:일자/4:금액)
		     , B.ALIGN2                         -- 분류키2_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
		     , B.FORM_EDIT2                     -- 분류키2_검색유형(1:직접입력/2:콤보/3:팝업)
		     , B.MAN_YN2                        -- 분류키2_필수여부
		     , B.SQLS2                          -- 분류키2_검색SQL문장
		     , B.TITLE_NM3                      -- 분류키3_타이틀명
		     , B.EDIT_FORMAT3                   -- 분류키3_EDIT포멧(1:텍스트/2:숫자/3:일자/4:금액)
		     , B.ALIGN3                         -- 분류키3_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
		     , B.FORM_EDIT3                     -- 분류키3_검색유형(1:직접입력/2:콤보/3:팝업)
		     , B.MAN_YN3                        -- 분류키3_필수여부
		     , B.SQLS3                          -- 분류키3_검색SQL문장
		     , B.TITLE_NM4                      -- 분류키4_타이틀명
		     , B.EDIT_FORMAT4                   -- 분류키4_EDIT포멧(1:텍스트/2:숫자/3:일자/4:금액)
		     , B.ALIGN4                         -- 분류키4_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
		     , B.FORM_EDIT4                     -- 분류키4_검색유형(1:직접입력/2:콤보/3:팝업)
		     , B.MAN_YN4                        -- 분류키4_필수여부
		     , B.SQLS4                          -- 분류키4_검색SQL문장
		     , B.TITLE_NM5                      -- 분류키5_타이틀명
		     , B.EDIT_FORMAT5                   -- 분류키5_EDIT포멧(1:텍스트/2:숫자/3:일자/4:금액)
		     , B.ALIGN5                         -- 분류키5_좌우정렬(L:왼쪽/C:중앙/R:오른쪽)
		     , B.FORM_EDIT5                     -- 분류키5_검색유형(1:직접입력/2:콤보/3:팝업)
		     , B.MAN_YN5                        -- 분류키5_필수여부
		     , B.SQLS5                          -- 분류키5_검색SQL문장
		     , B.NOTE                           -- 비고
		     , B.MOD_USER_ID                    -- 변경자
		     , B.MOD_DATE                       -- 변경일시
		     , B.TZ_CD                          -- 타임존코드
		     , B.TZ_DATE                        -- 타임존일시
		     , B.LABEL_CD1                      -- 분류키1_어휘코드
		     , B.LABEL_CD2                      -- 분류키2_어휘코드
		     , B.LABEL_CD3                      -- 분류키3_어휘코드
		     , B.LABEL_CD4                      -- 분류키4_어휘코드
		     , B.LABEL_CD5                      -- 분류키5_어휘코드
		  FROM [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_STD_MGR A
		 INNER JOIN [172.20.16.40].[dwehrdev_H5].[dbo].FRM_UNIT_ETC B
		    ON A.FRM_UNIT_STD_MGR_ID = B.FRM_UNIT_STD_MGR_ID
		 INNER JOIN FRM_UNIT_STD_MGR C
		    ON A.UNIT_CD = C.UNIT_CD
		   AND A.STD_KIND = C.STD_KIND
		   AND A.LOCALE_CD = C.LOCALE_CD
		   AND ISNULL(A.KEY1,'') = ISNULL(C.KEY1,'')
		   AND ISNULL(A.KEY2,'') = ISNULL(C.KEY2,'')
		   AND ISNULL(A.KEY3,'') = ISNULL(C.KEY3,'')
		   AND ISNULL(A.KEY4,'') = ISNULL(C.KEY4,'')
		   AND ISNULL(A.KEY5,'') = ISNULL(C.KEY5,'')
		 INNER JOIN @TARGET_COMPANY T
		   ON C.COMPANY_CD = T.COMPANY_CD
		  -- AND C.COMPANY_CD = @v_target_company_cd
		 WHERE A.COMPANY_CD = @v_source_company_cd
		AND A.UNIT_CD = @v_unit_cd
		AND A.STD_KIND IN (SELECT ITEMS FROM dbo.fn_split_array(@v_std_kind,','))
	END
  

END   
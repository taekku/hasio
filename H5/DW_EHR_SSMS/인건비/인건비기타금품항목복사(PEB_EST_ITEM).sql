/*
 * PEB_EST_ITEM 
 * 인건비기타금품항목복사
 */
BEGIN
	 DECLARE @v_source_company_cd NVARCHAR(100) = 'E'
	       , @v_target_company_cd NVARCHAR(100) = 'A,B,C,E,F,H,I,M,R,S,T,U,W,X,Y'
	DECLARE @TARGET_COMPANY TABLE(
		COMPANY_CD	NVARCHAR(10)
	)
	INSERT INTO @TARGET_COMPANY
	SELECT ITEMS
	FROM dbo.fn_split_array(@v_target_company_cd,',')
	WHERE Items != @v_source_company_cd

	DELETE A
	  FROM PEB_EST_ITEM A
	  WHERE EXISTS (SELECT * FROM @TARGET_COMPANY WHERE COMPANY_CD = A.COMPANY_CD)
	INSERT INTO PEB_EST_ITEM(
	PEB_EST_ITEM_ID, -- 인건비통계ID
	COMPANY_CD, -- 회사코드
	PAY_ITEM_CD, -- 급여항목코드
	STA_YMD, -- 시작일자
	END_YMD, -- 종료일자
	NOTE, -- 비고
	MOD_USER_ID, -- 변경자
	MOD_DATE, -- 변경일
	TZ_CD, -- 타임존코드
	TZ_DATE -- 타임존일시
	)
	SELECT NEXT VALUE FOR S_PEB_SEQUENCE -- A.PEB_EST_ITEM_ID -- 인건비통계ID
		 , B.COMPANY_CD -- 회사코드
		 , A.PAY_ITEM_CD -- 급여항목코드
		 , A.STA_YMD -- 시작일자
		 , A.END_YMD -- 종료일자
		 , A.NOTE -- 비고
		 , A.MOD_USER_ID
		 , A.MOD_DATE
		 , A.TZ_CD
		 , A.TZ_DATE
	  FROM PEB_EST_ITEM A
	  JOIN @TARGET_COMPANY B
		ON 1 = 1
	 WHERE A.COMPANY_CD = @v_source_company_cd
END
GO
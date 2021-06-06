DECLARE @s_type_nm nvarchar(50) = '인력통계 직종'
DECLARE @t_type_nm nvarchar(50) = '인건비 직종'
--SELECT *
--FROM HRS_STD_MGR
--WHERE TYPE_NM = @s_type_nm
------ 통계집계기준(HRS_STD_MGR) 복사
INSERT INTO HRS_STD_MGR(
	HRS_STD_MGR, -- 통계집계기준id
	TYPE_NM, -- 통계구분
	VIEW_CD, -- 표시코드
	VIEW_NM, -- 표시형식
	NOTE, -- 비고
	MOD_USER_ID, -- 변경자
	MOD_DATE, -- 변경일시
	TZ_CD, -- 타임존코드
	TZ_DATE  -- 타임존일시
)
SELECT NEXT VALUE FOR S_HRS_SEQUENCE,
       @t_type_nm AS TYPE_NM
     , VIEW_CD
	 , VIEW_NM
	 , NOTE
	 , 0 MOD_USER_ID
	 , SYSDATETIME() MOD_DATE
	 , 'KST' TZ_CD
	 , SYSDATETIME() TZ_DATE
  FROM (
		SELECT VIEW_CD, VIEW_NM, NOTE--, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE
		FROM HRS_STD_MGR
		WHERE TYPE_NM = @s_type_nm

		except

		SELECT VIEW_CD, VIEW_NM, NOTE--, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE
		FROM HRS_STD_MGR
		WHERE TYPE_NM = @t_type_nm
	) A

--SELECT *
--FROM HRS_STD_MGR
--WHERE TYPE_NM = @t_type_nm

---- 통계집계항목
INSERT INTO HRS_STD_ITEM (HRS_STD_ITEM_ID, -- 통계집계항목ID
		HRS_STD_MGR, -- 통계집계기준id
		ITEM_TYPE_CD, -- 항목구분
		ITEM_CD, -- 항목
		NOTE, -- 비고
		MOD_USER_ID, -- 변경자
		MOD_DATE, -- 변경일시
		TZ_CD, -- 타임존코드
		TZ_DATE  -- 타임존일시
)
SELECT  NEXT VALUE FOR S_HRS_SEQUENCE AS HRS_STD_ITEM_ID, -- 통계집계항목ID
		T.HRS_STD_MGR, -- 통계집계기준id
		A.ITEM_TYPE_CD, -- 항목구분
		A.ITEM_CD, -- 항목
		'' NOTE, -- 비고
		0 MOD_USER_ID, -- 변경자
		SYSDATETIME() MOD_DATE, -- 변경일시
		'KST' TZ_CD, -- 타임존코드
		SYSDATETIME() TZ_DATE -- 타임존일시
		--, T.TYPE_NM, S.HRS_STD_MGR
--SELECT A.HRS_STD_MGR, A.ITEM_TYPE_CD, A.ITEM_CD, A.NOTE, S.HRS_STD_MGR, S.VIEW_CD, S.VIEW_NM,
--       T.HRS_STD_MGR, T.VIEW_CD, T.VIEW_NM
  FROM HRS_STD_ITEM A
  JOIN HRS_STD_MGR S
    ON A.HRS_STD_MGR = S.HRS_STD_MGR
   AND S.TYPE_NM = @s_type_nm
  JOIN HRS_STD_MGR T
    ON T.TYPE_NM = @t_type_nm
   AND S.VIEW_CD = T.VIEW_CD
 WHERE NOT EXISTS (SELECT 1 FROM HRS_STD_ITEM WHERE HRS_STD_MGR = T.HRS_STD_MGR AND ITEM_CD = A.ITEM_CD) 
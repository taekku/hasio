DECLARE @av_company_cd nvarchar(10) = 'X'
      , @v_bill_gbn nvarchar(10) = 'P5108'--'P5103', 'P5107', 'P5104', 'P5108'
	  , @v_bill_gbn_to nvarchar(10) = 'R5108'--'R5103','R5107', 'R5104', 'R5108'
-- PBT_ACCNT_STD 로엑스_계정마스터

INSERT INTO PBT_ACCNT_STD(PBT_ACCNT_STD_ID, -- 계정마스터ID
		COMPANY_CD, -- 인사영역
		HRTYPE_GBN, -- 직원유형
		WRTDPT_CD, -- 작성부서
		TRDTYP_CD, -- 거래유형
		BILL_GBN, -- 전표구분
		ACCNT_CD, -- 계정코드
		COST_ACCTCD, -- 비용계정코드
		MGNT_ACCTCD, -- 관리계정코드
		TRDTYP_NM, -- 거래유형명칭
		CUST_CD, -- 거래처코드
		DEBSER_GBN, -- 차대구분
		SUMMARY, -- 적요사항
		CSTDPAT_CD, -- CSTDPAT_CD
		AGGR_GBN, -- AGGR_GBN
		USE_YN, -- 사용여부
		MOD_USER_ID, -- 변경자
		MOD_DATE, -- 변경일시
		TZ_CD, -- 타임존코드
		TZ_DATE -- 타임존일시
)
select NEXT VALUE FOR S_PBT_SEQUENCE PBT_ACCNT_STD_ID, -- 계정마스터ID
		COMPANY_CD, -- 인사영역
		HRTYPE_GBN, -- 직원유형
		WRTDPT_CD, -- 작성부서
		TRDTYP_CD, -- 거래유형
		@v_bill_gbn_to	BILL_GBN, -- 전표구분
		ACCNT_CD, -- 계정코드
		COST_ACCTCD, -- 비용계정코드
		MGNT_ACCTCD, -- 관리계정코드
		TRDTYP_NM, -- 거래유형명칭
		CUST_CD, -- 거래처코드
		DEBSER_GBN, -- 차대구분
		SUMMARY, -- 적요사항
		CSTDPAT_CD, -- CSTDPAT_CD
		AGGR_GBN, -- AGGR_GBN
		USE_YN, -- 사용여부
		MOD_USER_ID, -- 변경자
		MOD_DATE, -- 변경일시
		'KKK' TZ_CD, -- 타임존코드
		TZ_DATE -- 타임존일시
  from PBT_ACCNT_STD
 where COMPANY_CD=@av_company_cd
   and BILL_GBN=@v_bill_gbn
   
-- PBT_INCITEM 로엑스_포함항목
INSERT INTO PBT_INCITEM(
		PBT_INCITEM_ID, -- 포함항목ID
		PBT_ACCNT_STD_ID, -- 계정마스터ID
		ITEM_CD, -- 포함항목유형코드
		SEQ, -- 순서
		INCITEM_FR, -- 포함항목시작코드
		INCITEM_TO, -- 포함항목종료코드
		INCITEM, -- 포함항목코드
		MOD_USER_ID, -- 변경자
		MOD_DATE, -- 변경일시
		TZ_CD, -- 타임존코드
		TZ_DATE -- 타임존일시
)
SELECT NEXT VALUE FOR S_PBT_SEQUENCE AS PBT_INCITEM_ID, -- 포함항목ID
		T.PBT_ACCNT_STD_ID, -- 계정마스터ID
		B.ITEM_CD, -- 포함항목유형코드
		B.SEQ, -- 순서
		B.INCITEM_FR, -- 포함항목시작코드
		B.INCITEM_TO, -- 포함항목종료코드
		B.INCITEM, -- 포함항목코드
		B.MOD_USER_ID, -- 변경자
		B.MOD_DATE, -- 변경일시
		--B.TZ_CD, -- 타임존코드
		'KKK',
		B.TZ_DATE -- 타임존일시
  FROM PBT_ACCNT_STD A
  JOIN PBT_ACCNT_STD T
    ON A.COMPANY_CD = T.COMPANY_CD 
   AND A.HRTYPE_GBN = T.HRTYPE_GBN -- 직원유형
   AND A.WRTDPT_CD = T.WRTDPT_CD   -- 작성부서
   AND A.TRDTYP_CD = T.TRDTYP_CD   -- 거래유형
   AND A.BILL_GBN = @v_bill_gbn	   -- 전표구분
   AND @v_bill_gbn_to = T.BILL_GBN	   -- 전표구분
   AND A.ACCNT_CD = T.ACCNT_CD	   -- 계정코드
  JOIN PBT_INCITEM B
    ON A.PBT_ACCNT_STD_ID = B.PBT_ACCNT_STD_ID
 WHERE A.COMPANY_CD = @av_company_cd
   AND A.BILL_GBN = @v_bill_gbn
-- PBT_EXCITEM 로엑스_제외항목
INSERT INTO PBT_EXCITEM(
		PBT_EXCITEM_ID, -- 제외항목ID
		PBT_ACCNT_STD_ID, -- 계정마스터ID
		ITEM_CD, -- 제외항목유형코드
		SEQ, -- 순서
		EXCITEM_FR, -- 제외항목시작코드
		EXCITEM_TO, -- 제외항목종료코드
		EXCITEM, -- 제외항목코드
		MOD_USER_ID, -- 변경자
		MOD_DATE, -- 변경일시
		TZ_CD, -- 타임존코드
		TZ_DATE  -- 타임존일시
)
SELECT NEXT VALUE FOR S_PBT_SEQUENCE PBT_EXCITEM_ID, -- 제외항목ID
		T.PBT_ACCNT_STD_ID, -- 계정마스터ID
		B.ITEM_CD, -- 제외항목유형코드
		B.SEQ, -- 순서
		B.EXCITEM_FR, -- 제외항목시작코드
		B.EXCITEM_TO, -- 제외항목종료코드
		B.EXCITEM, -- 제외항목코드
		B.MOD_USER_ID, -- 변경자
		B.MOD_DATE, -- 변경일시
		--B.TZ_CD, -- 타임존코드
		'KKK',
		B.TZ_DATE  -- 타임존일시
  FROM PBT_ACCNT_STD A
  JOIN PBT_ACCNT_STD T
    ON A.COMPANY_CD = T.COMPANY_CD 
   AND A.HRTYPE_GBN = T.HRTYPE_GBN -- 직원유형
   AND A.WRTDPT_CD = T.WRTDPT_CD   -- 작성부서
   AND A.TRDTYP_CD = T.TRDTYP_CD   -- 거래유형
   AND A.BILL_GBN = @v_bill_gbn	   -- 전표구분
   AND @v_bill_gbn_to = T.BILL_GBN	   -- 전표구분
   AND A.ACCNT_CD = T.ACCNT_CD	   -- 계정코드
  JOIN PBT_EXCITEM B
    ON A.PBT_ACCNT_STD_ID = B.PBT_ACCNT_STD_ID
 WHERE A.COMPANY_CD = @av_company_cd
   AND A.BILL_GBN = @v_bill_gbn
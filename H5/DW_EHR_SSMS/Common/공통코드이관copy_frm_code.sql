DECLARE 
    @cd_master VARCHAR(MAX),
	@nm_master varchar(max),
    @cd_kind VARCHAR(MAX),
	@cd_kind_id NUMERIC,
	@txt_desc varchar(max),
	@cnt_new NUMERIC,
	@dt_update datetime2
	
--	set @cd_master = 'HU110' -- 고용유형코드
--	set @cd_kind = 'PAY_EMP_CLS_CD'
--	set @cd_master = 'HU132' -- 급여지급방식코드
--	set @cd_kind = 'PAY_METH_CD'
--	set @cd_master = 'HU014' -- 직종
--	set @cd_kind = 'PHM_JOB_POSITION_CD'
--	set @cd_master = 'HU157' -- 퇴직연금종류
--	set @cd_kind = 'REP_JOIN_TYPE_CD'
	--set @cd_master = 'HU109' -- 급여구분
	--set @cd_kind = 'PAY_ITEM_CLS_CD'
	--set @cd_master = 'HU011' -- 호봉
	--set @cd_kind = 'PHM_YEARNUM_CD'
	--set @cd_master = 'HU430' -- 퇴직출력구분
	--set @cd_kind = 'REP_REPORT_TYPE'
	--set @cd_master = 'HU416' -- 퇴직영수증구분
	--set @cd_kind = 'REP_RECEIPT_TYPE'
	--set @cd_master = 'HU187' -- 급여그룹
	--set @cd_kind = 'PAY_GROUP_CD'
	set @cd_master = 'HU513' -- 인력유형
	set @cd_kind = 'PHM_FROM_TYPE_CD'

select @nm_master = nm_master, @txt_desc = A.TXT_DESC, @dt_update = DT_UPDATE
  from dwehrdev.dbo.B_MASTER_CODE A
where CD_MASTER = @cd_master

if @@ROWCOUNT <> 1
	begin
		print 'AsIs[' + @cd_master + '] 코드없음!'
		return
	end

select top 1 @cd_kind_id = CD_KIND_ID
from frm_code_kind
where cd_kind = @cd_kind
if @@ROWCOUNT > 0
	begin
		print 'ToBe에 [' + @cd_kind + ']있음'
		--return
	end 
else
	begin
		SET @cd_kind_id = NEXT VALUE FOR dbo.S_FRM_SEQUENCE
		insert into FRM_CODE_KIND(CD_KIND_ID, LOCALE_CD, CD_KIND, CD_KIND_NM, STA_YMD, END_YMD, CHANGE_YN, NOTE, MOD_USER_ID, MOD_DATE,GROUP_YN)
		SELECT @cd_kind_id, 'KO', @cd_kind, @nm_master, '19000101', '29991231', 'Y', @cd_master, 0, @dt_update, 'Y'
	end
insert into FRM_CODE(CD_ID, LOCALE_CD, COMPANY_CD, CD_KIND, CD, CD_NM, SHORT_NM, STA_YMD, END_YMD, ORD_NO, NOTE, MOD_USER_ID, MOD_DATE,GROUP_USE_YN)
SELECT NEXT VALUE FOR dbo.S_FRM_SEQUENCE
     , 'KO', CD_COMPANY, @cd_kind, CD_DETAIL, NM_DETAIL, NM_DETAIL, '19000101', '29991231', SEQ_DISPLAY, TXT_DESC, 0, DT_UPDATE,'Y'
  FROM dwehrdev.dbo.B_DETAIL_CODE_COMPANY
where CD_MASTER = @cd_master
  and YN_USE = 'Y'
--  AND CD_COMPANY = 'I'
GO

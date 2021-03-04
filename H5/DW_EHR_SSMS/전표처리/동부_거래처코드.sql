DECLARE 
    @cd_master VARCHAR(MAX),
	@nm_master varchar(max),
    @cd_kind VARCHAR(MAX),
	@cd_kind_id NUMERIC,
	@txt_desc varchar(max),
	@cnt_new NUMERIC,
	@dt_update datetime2,
	@cd_company nvarchar(10)
	
	set @cd_master = 'HU514' -- 거래처코드
	set @cd_kind = 'PBT_CUST_CD'
	set @cd_company = 'B'

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
--else
--	begin
--		SET @cd_kind_id = NEXT VALUE FOR dbo.S_FRM_SEQUENCE
--		insert into FRM_CODE_KIND(CD_KIND_ID, LOCALE_CD, CD_KIND, CD_KIND_NM, STA_YMD, END_YMD, CHANGE_YN, NOTE, MOD_USER_ID, MOD_DATE)
--		SELECT @cd_kind_id, 'KO', @cd_kind, @nm_master, '19000101', '29991231', 'Y', @cd_master, 0, @dt_update
--	end
insert into FRM_CODE(CD_ID, LOCALE_CD, COMPANY_CD, CD_KIND, CD, CD_NM, SHORT_NM, STA_YMD, END_YMD, MAIN_CD, GROUP_USE_YN, ORD_NO, NOTE, MOD_USER_ID, MOD_DATE)
SELECT NEXT VALUE FOR dbo.S_FRM_SEQUENCE
     , 'KO', CD_COMPANY, @cd_kind, CD_DETAIL, NM_DETAIL, NM_DETAIL, '19000101', '29991231', USER1, YN_USE, SEQ_DISPLAY, TXT_DESC, 0, DT_UPDATE
  FROM dwehrdev.dbo.B_DETAIL_CODE_COMPANY
where CD_MASTER = @cd_master
  --and YN_USE = 'Y'
  and CD_COMPANY = @cd_company
  --and ISNULL(CD_DONGBU, ' ' ) > ' '
GO
DECLARE 
    @cd_master VARCHAR(MAX),
	@nm_master varchar(max),
    @cd_kind VARCHAR(MAX),
	@cd_kind_id NUMERIC,
	@txt_desc varchar(max),
	@cnt_new NUMERIC,
	@dt_update datetime2
	
	--set @cd_master = 'HU110' -- 고용유형코드
	--set @cd_kind = 'PAY_EMP_CLS_CD'
	set @cd_master = 'HU132' -- 급여지급방식코드
	set @cd_kind = 'PAY_METH_CD'

select *
from frm_code_kind
where cd_kind_nm like '%고용%'
;

SELECT *
FROM FRM_CODE
WHERE CD_KIND='PAY_EMP_CLS_CD'
;
DELETE
FROM FRM_CODE
WHERE CD_KIND='PAY_EMP_CLS_CD'

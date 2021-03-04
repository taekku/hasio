alter table dbo.PAY_ADV add constraint PK_PAY_ADV PRIMARY KEY (PAY_ADV_ID);
alter table dbo.PAY_ADV add constraint AK_PAY_ADV UNIQUE NONCLUSTERED (EMP_ID, ADV_DT);
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '출어가불금관리', 'User', dbo, 'TABLE', PAY_ADV
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', PAY_ADV_ID END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '출어가불금ID', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', PAY_ADV_ID
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', EMP_ID END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '사원ID', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', EMP_ID
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', ADV_DT END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '가불일자', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', ADV_DT
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', ADV_AMT END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '가불금액', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', ADV_AMT
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', DED_S_YMD END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '공제시작일자', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', DED_S_YMD
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', DED_E_YMD END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '공제종료일자', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', DED_E_YMD
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', MOD_USER_ID END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '변경자', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', MOD_USER_ID
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', MOD_DATE END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '변경일시', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', MOD_DATE
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', TZ_CD END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '타임존코드', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', TZ_CD
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', TZ_DATE END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '타임존일시', 'User', dbo, 'TABLE', PAY_ADV, 'COLUMN', TZ_DATE
GO
alter table dbo.PAY_SHIP_ADV_DTL add constraint PK_PAY_SHIP_ADV_DTL PRIMARY KEY (PAY_SHIP_ADV_DTL_ID);
alter table dbo.PAY_SHIP_ADV_DTL add constraint AK_PAY_SHIP_ADV_DTL UNIQUE NONCLUSTERED (PAY_ADV_ID, DED_REQ_YM);
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '출어가불금공제관리', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', PAY_SHIP_ADV_DTL_ID END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '출어가불금공제관리ID', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', PAY_SHIP_ADV_DTL_ID
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', PAY_ADV_ID END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '출어가불금ID', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', PAY_ADV_ID
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', DED_REQ_YM END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '공제의뢰월', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', DED_REQ_YM
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', DED_REQ_AMT END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '공제의뢰금액', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', DED_REQ_AMT
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', DED_PAY_YMD_ID END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '공제급여일자', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', DED_PAY_YMD_ID
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', DED_AMT END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '공제금액', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', DED_AMT
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', NOTE END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '비고', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', NOTE
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', MOD_USER_ID END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '변경자', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', MOD_USER_ID
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', MOD_DATE END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '변경일시', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', MOD_DATE
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', TZ_CD END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '타임존코드', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', TZ_CD
GO
BEGIN TRY EXEC sys.sp_dropextendedproperty 'MS_Description', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', TZ_DATE END TRY BEGIN CATCH END CATCH
GO
EXEC sys.sp_addextendedproperty 'MS_Description', '타임존일시', 'User', dbo, 'TABLE', PAY_SHIP_ADV_DTL, 'COLUMN', TZ_DATE
GO
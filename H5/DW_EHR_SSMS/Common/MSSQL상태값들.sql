@@FETCH_STATUS -- FETCH�� ���°� 0�� ������
@@TRANCOUNT -- ��������� BEGIN TRANSACTION�� ��
   -- COMMIT�� TRANSCTION�� �� -1
   -- ROLLBACK�� @@TRANCOUNT = 0�� ����� ����
@@ROWCOUNT -- �ֱ� ����� ���� ������� ���� ��, 20�ﺸ�� ������ ROWCOUNT_BIG()���
@@IDENTITY
@@ERROR
ERROR_NUMBER()
ERROR_MESSAGE()
ERROR_LINE()
ERROR_PROCEDURE()
sysdatetime()
ISNULL(CAST(@for_cur$EMP_ID AS nvarchar(max)), '')
SELECT ISNUMERIC('123'),ISNUMERIC(123),ISNUMERIC('A')

SELECT GETANSINULL(), HOST_ID(), HOST_NAME()
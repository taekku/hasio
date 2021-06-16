<%@ page language="java" contentType="text/html; charset=UTF-8"    pageEncoding="UTF-8" isELIgnored ="false"%>
<%@ taglib prefix="h5" uri="/WEB-INF/h5-ui-core.tld"%>
<%@ taglib prefix="biz" uri="/WEB-INF/h5-biz-core.tld"%>

<%
/************************************************************@@
 * Program ID		: pay0007_02.jsp
 * Version			: H5_5.1
 * Program Name		: 급여기본사항 - 급여계좌
 * Description		: 급여기본사항 - 급여계좌
 * Company			: 화이트정보통신
 * Author			: 김경준
 * Create Date		: 2013.08.26
 * History			: 2012.02.08 Initial created by 정채운
 @@************************************************************/
%>

<h5:H5View>
	<h5:Service>
		<h5:Data>
			<h5:Codes>
				<!-- 계좌유형 -->
				<h5:Code name="payAccountTypeCd" type="COMMON_CODE" target="PAY_ACCOUNT_TYPE_CD" />
				<!-- 은행코드 -->
				<h5:Code name="payBankCd" type="COMMON_CODE" target="PAY_BANK_CD" />
			</h5:Codes>
			
			<h5:Messages>
				<!-- 부모창에서 받음 -->
				<h5:Message type="MT_PHM0001_02" id="ME_PHM0001_02">
				</h5:Message>
				
				<!-- GRID -->
				<h5:Message type="MT_PAY0007_02_01"  id="ME_PAY0007_02_01">
				</h5:Message>
			</h5:Messages>
		</h5:Data>
		
		<h5:PageEvents>
			<h5:Event name="init" isInitEvent="true">
				<h5:EventAction type="RUN_ACTION" target="retrieve">
					<h5:Message id="ME_PHM0001_02">
					</h5:Message>
				</h5:EventAction>
			</h5:Event>
		</h5:PageEvents>
		
		<h5:Actions>
			<!-- 조회 -->
			<h5:Action name="retrieve" type="SERVICE_CALL" target="PAY0007_02_R01" useContainerMessage="false">
				<h5:Message id="ME_PHM0001_02">
					<h5:Column id="locale_cd" value="${sessionScope.session_locale_cd }"/>
					<h5:Column id="company_cd" value="${sessionScope.session_company_cd }"/>
				</h5:Message>
				
				<h5:ResultEvent>
					<h5:Action type="BIND_DATA">
						<h5:Message id="ME_PAY0007_02_01">
						</h5:Message>
					</h5:Action>
				</h5:ResultEvent>
				
				<h5:FaultEvent> <!-- 해당 기능의 수행이 실패 한 후 수행하는 결과 처리 -->
					<h5:Action type="ALERT"></h5:Action>
				</h5:FaultEvent>
			</h5:Action>
		</h5:Actions>
	</h5:Service>
	
	<h5:ContentBox>
		<h5:TitleBox label="급여계좌" labelCode="PAY.PAY0007_02.TITLE">
		</h5:TitleBox>
		
		<h5:DataGrid id="list" dataProvider="ME_PAY0007_02_01" showDelete="false" showSeq="true" showStatus="false" 
					width="100%" height="100%" useExtendLastCol="false">
			<h5:DataGridHeaderRow>
				<h5:DataGridHeaderColumn>
					<h5:Label label="급여계좌ID" labelCode="PAY.PAY0007_02.PAY_ACCOUNT_ID" />
				</h5:DataGridHeaderColumn>
				<h5:DataGridHeaderColumn>
					<h5:Label label="사원ID" labelCode="EMP_ID" />
				</h5:DataGridHeaderColumn>
				
				<h5:DataGridHeaderColumn>
					<h5:Label label="계좌유형" labelCode="ACCOUNT_TYPE_NM" />
				</h5:DataGridHeaderColumn>
				<h5:DataGridHeaderColumn>
					<h5:Label label="은행" labelCode="BANK_NM" />
				</h5:DataGridHeaderColumn>
				<h5:DataGridHeaderColumn>
					<h5:Label label="계좌번호" labelCode="ACCOUNT_NO" />
				</h5:DataGridHeaderColumn>
				<h5:DataGridHeaderColumn>
					<h5:Label label="시작일자" labelCode="STA_YMD" />
				</h5:DataGridHeaderColumn>
				<h5:DataGridHeaderColumn>
					<h5:Label label="종료일자" labelCode="END_YMD" />
				</h5:DataGridHeaderColumn>
				<h5:DataGridHeaderColumn>
					<h5:Label label="비고" labelCode="NOTE" />
				</h5:DataGridHeaderColumn>
			</h5:DataGridHeaderRow>
			
			<h5:DataGridBodyRow>
				<!-- 급여계좌ID -->
				<h5:DataGridColumn align="center" hidden="true">
					<h5:TextInput id="pay_account_id" bindingColumn="pay_account_id" editable="false" />
				</h5:DataGridColumn>
				<!-- 사원ID -->
				<h5:DataGridColumn align="center" hidden="true">
					<h5:TextInput id="emp_id" bindingColumn="emp_id" editable="false" />
				</h5:DataGridColumn>
				
				<!-- 계좌유형 -->
				<h5:DataGridColumn align="center" width="150">
					<h5:ComboBox id="account_type_cd" bindingColumn="account_type_cd" listProvider="payAccountTypeCd" editable="false" />
				</h5:DataGridColumn>
				<!-- 은행 -->
				<h5:DataGridColumn align="center" width="150">
					<h5:ComboBox id="bank_cd" bindingColumn="bank_cd" listProvider="payBankCd" editable="false" />
				</h5:DataGridColumn>
				<!-- 계좌번호 -->
				<h5:DataGridColumn align="center" width="150">
					<h5:TextInput id="account_no" bindingColumn="account_no" editable="false" />
				</h5:DataGridColumn>
				<!-- 시작일자 -->
				<h5:DataGridColumn align="center" width="100">
					<h5:DateInput id="sta_ymd" bindingColumn="sta_ymd" editable="false" />
				</h5:DataGridColumn>
				<!-- 종료일자 -->
				<h5:DataGridColumn align="center" width="100">
					<h5:DateInput id="end_ymd" bindingColumn="end_ymd" editable="false" />
				</h5:DataGridColumn>
				<!-- 비고 -->
				<h5:DataGridColumn align="left" width="200">
					<h5:TextInput id="note" bindingColumn="note" editable="false" />
				</h5:DataGridColumn>
			</h5:DataGridBodyRow>
		</h5:DataGrid>
	</h5:ContentBox>
</h5:H5View>
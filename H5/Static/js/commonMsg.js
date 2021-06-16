/**
 * 2017.04.21. JS파일의 메시지 다국어 처리를 위해 추가함.
 */
var msgLangCd = typeof(top.getLangCd) === 'function' ? top.getLangCd() : "KO";

/* var commonMsg : 메시지 JSON 객체
 * 다음과 같이 사용
 * alert( commonMsg.REQUIRED_CHECK[msgLangCd] );
 */
var commonMsg = {
				  "KEYIN_DISALLOW" : { "KO" : "허용되지 않는 입력입니다."
					  				 , "EN" : "It's Unacceptable input." }
				, "REQUIRED_CHECK" : { "KO" : "은(는) 필수입니다."
							   , "EN" : " is required." }
				, "SUBJECT_LENGTH" : { "KO" : "의 길이는 "
									 , "EN" : " must be at least " }
				, "MIN_LENGTH" : { "KO" : "자리 이상이어야 합니다."
								 , "EN" : "digits long." }
				, "MAX_SUBJECT" : { "KO" : "의 길이는 "
	 				 			  , "EN" : " can not exceed " }
				, "MAX_LENGTH" : { "KO" : "자리를 초과할 수 없습니다."
					 			 , "EN" : "digits." }
				, "NOTFOUND_FRAME" : { "KO" : "iframe를 찾을수 없습니다."
		 			 				 , "EN" : "Could not find iframe." }
				, "INVALID_DATE" : { "KO" : "올바른 날짜가 아닙니다."
	 				 			   , "EN" : "Date is invalid." }
				, "STARTDATE_CHECK" : { "KO" : "시작일이 "
		 			   				  , "EN" : "Start Date is " }
				, "ENDDATE_CHECK" : { "KO" : "종료일이 "
	   				  				, "EN" : "End Date is " }
				, "STARTENDDATE_CHECK" : { "KO" : "시작일이 종료일보다 큽니다."
		  								 , "EN" : "Start date is greater than end date." }
				};

/* var commonElaMsg : 메시지 JSON 객체
 * 다음과 같이 사용
 * alert( commonElaMsg.REQUIRED_CHECK[msgLangCd] );
 */
var commonElaMsg = {
		  "CONFIRM_APPR_REQ" : { "KO" : "작성요청 하시겠습니까?"
			  				 , "EN" : "Would you request approval?" }
		, "ELA0010_SAVE_02" : { "KO" : "임시저장 하시겠습니까?"
					   , "EN" : "Would you temporarily store it ?" }
		, "ELA0010_SAVE_05" : { "KO" : "회수 하시겠습니까? "
							 , "EN" : "Would you collect it?" }
		, "CONFIRM_APPROVAL" : { "KO" : "승인하겠습니까?"
						 , "EN" : "Do you want to approve it?" }
		, "CONFIRM_CANCEL" : { "KO" : "반려하겠습니까? "
			 			  , "EN" : "Do you want to return it?" }
		, "CONFIRM_APPR_DEL" : { "KO" : "삭제하시겠습니까?"
			 			 , "EN" : "Do you want to delete it?" }
		, "EAL_MESSAGE_01" : { "KO" : "반려건 재신청 하시겠습니까?."
			 				 , "EN" : "Would you like to re-request for the returned case?" }
		, "EAL_MESSAGE_02" : { "KO" : "반려건 재신청이 완료 되었습니다."
			 			   , "EN" : "Re-request for the returned case has been complete." }
		, "EAL_MESSAGE_03" : { "KO" : "의견은 1000Byte까지만 입력가능합니다. "
			   				  , "EN" : "Comments Limited Size 1000Byte." }
		, "ELA_010" : { "KO" : "작성상태조회 "
				  				, "EN" : "Payment Status Lookup" }
		};




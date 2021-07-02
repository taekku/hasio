SELECT *
FROM openquery(DEBIS,'select SAL_PAY_DT
												 ,SAL_PAY_CLS_CD   
												 ,PERS_CLS_CD      
												 ,DRAW_ACCT_DEPT_CD
												 ,DRCR_CLS_CD      
												 ,ACCT_DEPT_CD     
												 ,ACCT_CD          
												 ,SEQ              
												 ,PAY_BANK_CD      
												 ,PCOST_DIV        
												 ,ACCT_NM          
												 ,AMT              
												 ,CLNT_NO          
												 ,SUMMARY          
												 ,REQ_PAY_MTHD_CD  
												 ,PAY_DT           
												 ,OUTBR_SLIP_NO    
												 ,PAY_SLIP_NO      
												 ,SND_CLS_CD       
												 ,REPLY_CLS_CD     
												 ,SND_DT           
												 ,SND_HH
											 from TB_FI403 WHERE SAL_PAY_DT=''20210625''')

insert openquery(DEBIS,'select SAL_PAY_DT
												 ,SAL_PAY_CLS_CD   
												 ,PERS_CLS_CD      
												 ,DRAW_ACCT_DEPT_CD
												 ,DRCR_CLS_CD      
												 ,ACCT_DEPT_CD     
												 ,ACCT_CD          
												 ,SEQ              
												 ,PAY_BANK_CD      
												 ,PCOST_DIV        
												 ,ACCT_NM          
												 ,AMT              
												 ,CLNT_NO          
												 ,SUMMARY          
												 ,REQ_PAY_MTHD_CD  
												 ,PAY_DT           
												 ,OUTBR_SLIP_NO    
												 ,PAY_SLIP_NO      
												 ,SND_CLS_CD       
												 ,REPLY_CLS_CD     
												 ,SND_DT           
												 ,SND_HH
											 from TB_FI403')
				 select    '20210625' --@V_SAL_PAY_DT 
						  ,'P'--@V_SAL_PAY_CLS_CD             
						  ,'AA'--@V_PERS_CLS_CD      
						  ,'A001'--@V_DRAW_ACCT_DEPT_CD
						  ,'D'--@V_DRCR_CLS_CD      
						  ,''--@V_ACCT_DEPT_CD     
						  ,'5000110'--@V_ACCT_CD          
						  ,1--@V_SEQ              
						  ,''--@V_PAY_BANK_CD      
						  ,'01047'--@V_PCOST_DIV        
						  ,'판)급료와임금-본봉'--CASE WHEN ISNULL(@V_ACCT_NM, '') = '' THEN '' ELSE SUBSTRING(@V_ACCT_NM,1,50) END     
						  ,40719020--@V_AMT              
						  ,'999917'--CASE WHEN ISNULL(@V_CLNT_NO, '') = '' THEN '' ELSE SUBSTRING(@V_CLNT_NO,1,6) END          
						  ,'06월 본봉(판관비)'--@V_SUMMARY          
						  ,''--@V_REQ_PAY_MTHD_CD  
						  ,''--@V_PAY_DT           
						  ,''--@V_OUTBR_SLIP_NO    
						  ,''--@V_PAY_SLIP_NO      
						  ,'0'--@V_SND_CLS_CD       
						  ,''--@V_REPLY_CLS_CD     
						  ,'20210625'--@V_SND_DT           
						  ,'142239'--@V_SND_HH   
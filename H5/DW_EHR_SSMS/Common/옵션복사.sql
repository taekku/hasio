 BEGIN
	 
	 DECLARE @v_source_company_cd NVARCHAR(100) = 'E'
	       --, @v_target_company_cds NVARCHAR(100) = 'A,B,C,E,F,H,I,M,R,S,T,U,W,X,Y'
			, @v_target_company_cds NVARCHAR(100) = 'A,C,E,F,H,I,M,R,S,T,U,W'
		   , @v_start_option_key nvarchar(100) = 'PAY_GRP_DTM_DAILY'--,PAY_YEAR_MIN_PAY' --'REP_STD'

	DECLARE @TARGET_COMPANY TABLE(
		COMPANY_CD	NVARCHAR(10)
	)
	INSERT INTO @TARGET_COMPANY
	SELECT ITEMS
	FROM dbo.fn_split_array(@v_target_company_cds,',')
	WHERE Items != @v_source_company_cd
		   ;
	 
	WITH CTE_E AS (
		       SELECT K.*
		            , 1 AS LVL1
		         FROM FRM_OPTION_ITEM K 
		         JOIN @TARGET_COMPANY T-- COMPANY_CD = @v_target_company_cd
				   ON K.COMPANY_CD = T.COMPANY_CD
				  AND OPTION_KEY = @v_start_option_key
		        UNION ALL  
		       SELECT B.* 
		            , LVL1 + 1 AS LVL1
		         FROM CTE_E A  
		              INNER JOIN FRM_OPTION_ITEM B ON ( A.OPTION_ITEM_ID = B.PARENT_ITEM_ID )
		   )
	DELETE A
	  FROM FRM_OPTION_ITEM A
	  JOIN CTE_E B
	    ON A.OPTION_ITEM_ID = B.OPTION_ITEM_ID

	DECLARE mm CURSOR LOCAL FOR
		   WITH CTE_E AS (
		       SELECT K.*
		            , 1 AS LVL1
		            , CONVERT(NVARCHAR(4000), '/' + CONCAT( K.SEQ_ORDER , K.OPTION_ITEM_ID) ) AS SORT 
		         FROM FRM_OPTION_ITEM K 
		        WHERE COMPANY_CD = @v_source_company_cd
				  AND OPTION_KEY = @v_start_option_key
		        UNION ALL  
		       SELECT B.* 
		            , LVL1 + 1 AS LVL1
		            , CONVERT(NVARCHAR(4000), A.SORT + '/' + CONCAT(B.SEQ_ORDER , B.OPTION_ITEM_ID) ) AS  SORT 
		         FROM CTE_E A  
		              INNER JOIN FRM_OPTION_ITEM B ON ( A.OPTION_ITEM_ID = B.PARENT_ITEM_ID 
		                                            AND B.COMPANY_CD = @v_source_company_cd )
		   )
		     SELECT    OPTION_ITEM_ID                 -- �ɼǾ�����ID
				     , ITEM_TYPE                      -- �ɼǾ�����Ÿ��
				     , PARENT_ITEM_ID                 -- ����������ID
				     , PERSONALIZE_YN                 -- ����ȭ���ɿ���
				     , OPTION_KEY                     -- �ɼ�Ű
				     , OPTION_LABEL                   -- �ɼǷ��̺�
				     , OPTION_LABEL_CD                -- �ɼǷ��̺��ڵ�
				     , OPTION_GROUP_TAG               -- �ɼǱ׷����±�
				     , OPTION_VALUE                   -- �ɼ� ��
				     , SEQ_ORDER                      -- ���ļ���
				     , COMPANY_CD                     -- �λ翵���ڵ�
				     , STA_YMD                        -- ������
				     , END_YMD                        -- ������
				     , MOD_USER_ID                    -- ������ID
				     , MOD_DATE                       -- �����Ͻ�
				     , TZ_CD                          -- Ÿ�����ڵ�
				     , TZ_DATE                        -- Ÿ�����ڵ�
		       FROM CTE_E 
		       ORDER BY SORT

	OPEN mm
	 
	DECLARE @n_option_item_id                NUMERIC(38,0)                  -- �ɼǾ�����ID
	      , @v_item_type                     NVARCHAR(20)                   -- �ɼǾ�����Ÿ��
	      , @n_parent_item_id                NUMERIC(38,0)                  -- ����������ID
	      , @v_personalize_yn                CHAR(1)                        -- ����ȭ���ɿ���
	      , @v_option_key                    NVARCHAR(600)                  -- �ɼ�Ű
	      , @v_option_label                  NVARCHAR(1500)                 -- �ɼǷ��̺�
	      , @v_option_label_cd               NVARCHAR(100)                  -- �ɼǷ��̺��ڵ�
	      , @v_option_group_tag              NVARCHAR(1500)                 -- �ɼǱ׷����±�
	      , @v_option_value                  NVARCHAR(4000)                 -- �ɼ� ��
	      , @n_seq_order                     NUMERIC(38,0)                  -- ���ļ���
	      , @v_company_cd                    NVARCHAR(100)                  -- �λ翵���ڵ�
	      , @d_sta_ymd                       DATETIME2                      -- ������
	      , @d_end_ymd                       DATETIME2                      -- ������
	      , @n_mod_user_id                   NUMERIC(38,0)                  -- ������ID
	      , @d_mod_date                      DATETIME2                      -- �����Ͻ�
	      , @v_tz_cd                         NVARCHAR(20)                   -- Ÿ�����ڵ�
	      , @d_tz_date                       DATETIME2                      -- Ÿ�����ڵ�

	FETCH NEXT FROM mm INTO	    @n_option_item_id  
						      , @v_item_type       
						      , @n_parent_item_id  
						      , @v_personalize_yn  
						      , @v_option_key      
						      , @v_option_label    
						      , @v_option_label_cd 
						      , @v_option_group_tag
						      , @v_option_value    
						      , @n_seq_order       
						      , @v_company_cd      
						      , @d_sta_ymd         
						      , @d_end_ymd         
						      , @n_mod_user_id     
						      , @d_mod_date        
						      , @v_tz_cd           
						      , @d_tz_date         
	 
	WHILE(@@FETCH_STATUS = 0)
		BEGIN
			
			INSERT FRM_OPTION_ITEM (        -- �ɼǾ�����  
			       OPTION_ITEM_ID                 -- �ɼǾ�����ID
			     , ITEM_TYPE                      -- �ɼǾ�����Ÿ��
			     , PARENT_ITEM_ID                 -- ����������ID
			     , PERSONALIZE_YN                 -- ����ȭ���ɿ���
			     , OPTION_KEY                     -- �ɼ�Ű
			     , OPTION_LABEL                   -- �ɼǷ��̺�
			     , OPTION_LABEL_CD                -- �ɼǷ��̺��ڵ�
			     , OPTION_GROUP_TAG               -- �ɼǱ׷����±�
			     , OPTION_VALUE                   -- �ɼ� ��
			     , SEQ_ORDER                      -- ���ļ���
			     , COMPANY_CD                     -- �λ翵���ڵ�
			     , STA_YMD                        -- ������
			     , END_YMD                        -- ������
			     , MOD_USER_ID                    -- ������ID
			     , MOD_DATE                       -- �����Ͻ�
			     , TZ_CD                          -- Ÿ�����ڵ�
			     , TZ_DATE                        -- Ÿ�����ڵ�
			)-- VALUES (
			SELECT
			       NEXT VALUE FOR dbo.S_FRM_SEQUENCE                 -- �ɼǾ�����ID
			     , @v_item_type                      -- �ɼǾ�����Ÿ��
			     , CASE WHEN @n_parent_item_id IS NULL THEN NULL 
			            ELSE (
			                SELECT OPTION_ITEM_ID
			                  FROM FRM_OPTION_ITEM 
			                 WHERE COMPANY_CD = T.COMPANY_CD -- @v_target_company_cd
			                   AND OPTION_KEY = (
			                       SELECT OPTION_KEY 
			                         FROM FRM_OPTION_ITEM
			                        WHERE OPTION_ITEM_ID = @n_parent_item_id
			                   )
			                   AND ITEM_TYPE = (
			                       SELECT ITEM_TYPE 
			                         FROM FRM_OPTION_ITEM
			                        WHERE OPTION_ITEM_ID = @n_parent_item_id
			                   )
			                   AND STA_YMD = (
			                       SELECT STA_YMD 
			                         FROM FRM_OPTION_ITEM
			                        WHERE OPTION_ITEM_ID = @n_parent_item_id
			                   )
			            ) END                  -- ����������ID
			     , @v_personalize_yn                 -- ����ȭ���ɿ���
			     , @v_option_key                     -- �ɼ�Ű
			     , @v_option_label                   -- �ɼǷ��̺�
			     , @v_option_label_cd                -- �ɼǷ��̺��ڵ�
			     , @v_option_group_tag               -- �ɼǱ׷����±�
			     , @v_option_value                   -- �ɼ� ��
			     , @n_seq_order                      -- ���ļ���
			     , T.COMPANY_CD -- @v_target_company_cd                     -- �λ翵���ڵ�
			     , @d_sta_ymd                        -- ������
			     , @d_end_ymd                        -- ������
			     , @n_mod_user_id                    -- ������ID
			     , GETDATE()                       -- �����Ͻ�
			     , @v_tz_cd                          -- Ÿ�����ڵ�
			     , GETDATE()                        -- Ÿ�����ڵ�
			FROM @TARGET_COMPANY T
			
			FETCH NEXT FROM mm INTO     @n_option_item_id  
								      , @v_item_type       
								      , @n_parent_item_id  
								      , @v_personalize_yn  
								      , @v_option_key      
								      , @v_option_label    
								      , @v_option_label_cd 
								      , @v_option_group_tag
								      , @v_option_value    
								      , @n_seq_order       
								      , @v_company_cd      
								      , @d_sta_ymd         
								      , @d_end_ymd         
								      , @n_mod_user_id     
								      , @d_mod_date        
								      , @v_tz_cd           
								      , @d_tz_date         
		END
	 
	CLOSE mm
	DEALLOCATE mm


END
GO
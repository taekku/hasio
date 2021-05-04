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
		     SELECT    OPTION_ITEM_ID                 -- 옵션아이템ID
				     , ITEM_TYPE                      -- 옵션아이템타입
				     , PARENT_ITEM_ID                 -- 상위아이템ID
				     , PERSONALIZE_YN                 -- 개인화가능여부
				     , OPTION_KEY                     -- 옵션키
				     , OPTION_LABEL                   -- 옵션레이블
				     , OPTION_LABEL_CD                -- 옵션레이블코드
				     , OPTION_GROUP_TAG               -- 옵션그룹핑태그
				     , OPTION_VALUE                   -- 옵션 값
				     , SEQ_ORDER                      -- 정렬순서
				     , COMPANY_CD                     -- 인사영역코드
				     , STA_YMD                        -- 시작일
				     , END_YMD                        -- 종료일
				     , MOD_USER_ID                    -- 변경자ID
				     , MOD_DATE                       -- 변경일시
				     , TZ_CD                          -- 타임존코드
				     , TZ_DATE                        -- 타임존코드
		       FROM CTE_E 
		       ORDER BY SORT

	OPEN mm
	 
	DECLARE @n_option_item_id                NUMERIC(38,0)                  -- 옵션아이템ID
	      , @v_item_type                     NVARCHAR(20)                   -- 옵션아이템타입
	      , @n_parent_item_id                NUMERIC(38,0)                  -- 상위아이템ID
	      , @v_personalize_yn                CHAR(1)                        -- 개인화가능여부
	      , @v_option_key                    NVARCHAR(600)                  -- 옵션키
	      , @v_option_label                  NVARCHAR(1500)                 -- 옵션레이블
	      , @v_option_label_cd               NVARCHAR(100)                  -- 옵션레이블코드
	      , @v_option_group_tag              NVARCHAR(1500)                 -- 옵션그룹핑태그
	      , @v_option_value                  NVARCHAR(4000)                 -- 옵션 값
	      , @n_seq_order                     NUMERIC(38,0)                  -- 정렬순서
	      , @v_company_cd                    NVARCHAR(100)                  -- 인사영역코드
	      , @d_sta_ymd                       DATETIME2                      -- 시작일
	      , @d_end_ymd                       DATETIME2                      -- 종료일
	      , @n_mod_user_id                   NUMERIC(38,0)                  -- 변경자ID
	      , @d_mod_date                      DATETIME2                      -- 변경일시
	      , @v_tz_cd                         NVARCHAR(20)                   -- 타임존코드
	      , @d_tz_date                       DATETIME2                      -- 타임존코드

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
			
			INSERT FRM_OPTION_ITEM (        -- 옵션아이템  
			       OPTION_ITEM_ID                 -- 옵션아이템ID
			     , ITEM_TYPE                      -- 옵션아이템타입
			     , PARENT_ITEM_ID                 -- 상위아이템ID
			     , PERSONALIZE_YN                 -- 개인화가능여부
			     , OPTION_KEY                     -- 옵션키
			     , OPTION_LABEL                   -- 옵션레이블
			     , OPTION_LABEL_CD                -- 옵션레이블코드
			     , OPTION_GROUP_TAG               -- 옵션그룹핑태그
			     , OPTION_VALUE                   -- 옵션 값
			     , SEQ_ORDER                      -- 정렬순서
			     , COMPANY_CD                     -- 인사영역코드
			     , STA_YMD                        -- 시작일
			     , END_YMD                        -- 종료일
			     , MOD_USER_ID                    -- 변경자ID
			     , MOD_DATE                       -- 변경일시
			     , TZ_CD                          -- 타임존코드
			     , TZ_DATE                        -- 타임존코드
			)-- VALUES (
			SELECT
			       NEXT VALUE FOR dbo.S_FRM_SEQUENCE                 -- 옵션아이템ID
			     , @v_item_type                      -- 옵션아이템타입
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
			            ) END                  -- 상위아이템ID
			     , @v_personalize_yn                 -- 개인화가능여부
			     , @v_option_key                     -- 옵션키
			     , @v_option_label                   -- 옵션레이블
			     , @v_option_label_cd                -- 옵션레이블코드
			     , @v_option_group_tag               -- 옵션그룹핑태그
			     , @v_option_value                   -- 옵션 값
			     , @n_seq_order                      -- 정렬순서
			     , T.COMPANY_CD -- @v_target_company_cd                     -- 인사영역코드
			     , @d_sta_ymd                        -- 시작일
			     , @d_end_ymd                        -- 종료일
			     , @n_mod_user_id                    -- 변경자ID
			     , GETDATE()                       -- 변경일시
			     , @v_tz_cd                          -- 타임존코드
			     , GETDATE()                        -- 타임존코드
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
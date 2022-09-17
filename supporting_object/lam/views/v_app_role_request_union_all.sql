CREATE OR REPLACE VIEW v_app_role_request_union_all AS 
SELECT 
	'?' req_source
	,'?' app_name      
	,'?' user_name     
	,'?' status        
	,sysdate created       
	,'?' created_by    
	,sysdate updated       
	,'?' updated_by
FROM dual WHERE 1=0
UNION ALL 
SELECT 
	'CSTSKM'
	 , app_name      
	,  user_uniq_name     
	,  req_status        
	, req_created       
	,  req_created_by    
	, req_updated       
	,  req_updated_by
FROM v_apex_cstskm_app_role_request 
WHERE 1=1
UNION ALL 
SELECT 
	'APEX'
	 ,	app_name      
	,  apex_user_name     
	,  status        
	, created       
	,  created_by    
	, updated       
	,  updated_by
FROM apex_wkspauth_app_role_request 
WHERE 1=1
;

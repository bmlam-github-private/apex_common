CREATE OR REPLACE VIEW v_apex_cstskm_app_role_request
AS
SELECT 
	u.id user_id 
	,u.user_uniq_name
	,req.app_name
	,req.role_name
	,req.status req_status 
	,req.created req_created
	,req.created_by req_created_by
	,req.updated req_updated
	,req.updated_by req_updated_by
FROM apex_cstskm_app_role_request req 
JOIN apex_cstskm_user u ON u.id = req.user_id
;

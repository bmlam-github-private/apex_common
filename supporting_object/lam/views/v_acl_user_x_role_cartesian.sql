CREATE OR REPLACE VIEW v_acl_user_x_role_cartesian
AS
select ro.workspace_id, ro.workspace workspace_name
	, u.application_id app_num
    , u.application_name, u.user_name
    , ro.role_static_id role_name
,( select count(1) 
	from APEX_APPL_ACL_USER_ROLES x 
	where x.application_name = u.application_name AND x.role_static_id = ro.role_static_id AND x.user_name = u.user_name )
	AS role_granted
FROM APEX_APPL_ACL_USERS u JOIN APEX_APPL_ACL_ROLES ro
ON ro.application_name = u.application_name
;

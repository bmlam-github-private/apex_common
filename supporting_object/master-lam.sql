PROMPT tables 
@./lam/tables/apex_cstskm_user_x_app_role.sql
@./lam/tables/apex_cstskm_app_role_lkup.sql
@./lam/tables/apex_wkspauth_app_role_request.sql
@./lam/tables/apex_cstskm_app_role_request.sql
@./lam/tables/apex_cstskm_user.sql
@./lam/tables/seed-apex_cstskm_app_role_lkup.sql
@./lam/tables/apex_wkspauth_acc_req_token.sql

PROMPT package specifications
@./lam/packages/cstskm_util-def.sql
@./lam/packages/cstskm_user_api-def.sql

PROMPT package bodies
@./lam/packages/cstskm_user_api-impl.sql
@./lam/packages/cstskm_util-impl.sql

PROMPT functions 
@./lam/functions/split_by_string.sql 

PROMPT procedures
@./lam/procedures/enforce_strong_password.sql
@./lam/procedures/loop_create_user_reqs.sql
@./lam/procedures/pymail_send.sql
@./lam/procedures/cre_job_add_wrksp_user.sql
@./lam/procedures/change_app_user_pwd.sql

PROMPT views 
@./lam/views/v_acl_user_x_role_cartesian.sql
@./lam/views/v_app_role_request_union_all.sql
@./lam/views/v_apex_cstskm_app_role_request.sql

PROMPT jobs 
@./lam/jobs/acc_req_looper_job.sql
@./lam/jobs/loop_create_user_reqs.sql
@./lam/jobs/acc_req_looper_job_autodrop.sql

PROMPT compiling invalid objects 
exec dbms_utility.compile_schema( user, FALSE);

SELECT systimestamp, object_name, object_type, status 
FROM user_objects
WHERE status != 'VALID'
ORDER BY  object_name, object_type
;

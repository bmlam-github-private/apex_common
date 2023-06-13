CREATE OR REPLACE PROCEDURE loop_create_user_reqs
AS 
/* NOt in a package because we would need to stop and resume (or worse drop and recreate)
* the job each time we need to compile this procedure
*
*/

       l_workspace_id      number;
       l_session_user varchar2(30);
BEGIN 
	SELECT workspace_id INTO l_workspace_id
	FROM apex_workspaces
	where workspace = 'LAM';
  pck_std_log.inf('l_workspace_id:'|| l_workspace_id );
  l_session_user := sys_context( 'USERENV', 'session_user');
  pck_std_log.inf('l_session_user:'|| l_session_user );

  apex_util.set_security_group_id (p_security_group_id => l_workspace_id);
  -- loop over create-user-requests in status OK_PENDING_CREATE
  FOR lr_req IN ( 
              SELECT req.id AS req_id
                , req.apex_user_name
                , tok.my_token 
              FROM apex_wkspauth_app_role_request req 
              JOIN apex_wkspauth_acc_req_token tok ON ( tok.req_id = req.id )
              WHERE req.role_name = cstskm_util. gc_dummy_role_for_account_request
                AND req.status = 'OK_PENDING_CREATE'
  	) 
  LOOP 
  pck_std_log.inf('lr_req.apex_user_name:'|| lr_req.apex_user_name );
  	apex_util.create_user ( p_user_name => lr_req.apex_user_name
  		, p_web_password => cstskm_util.decrypted( lr_req.my_token )
  		); 
    UPDATE apex_wkspauth_app_role_request 
    SET status = 'APPROVED'
    WHERE id = lr_req.req_id
    ;
    COMMIT;
  -- add an error handler. 
  END LOOP;

END;
/

show errors

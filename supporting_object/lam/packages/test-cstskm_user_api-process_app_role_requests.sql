define pi_request_ids=&1
define pi_request_source=&2

DECLARE 
BEGIN
    cstskm_user_api.process_app_role_requests 
    ( p_req_ids_csv => '&pi_request_ids' 
     ,p_action => 'GRANT' -- GRANT or REJECT 
     ,p_req_source => '&pi_request_source'
    )
    ;
END;
/

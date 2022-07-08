CREATE OR REPLACE PACKAGE cstskm_user_api
AS


PROCEDURE add_access 
( p_user_uniq_name VARCHAR2
 ,p_password VARCHAR2
 ,p_target_app VARCHAR2    DEFAULT NULL 
 ,p_strict_checks BOOLEAN DEFAULT FALSE -- raise error on possible dupes, locked account, reactivation etc 
) ;

PROCEDURE replace_password 
( p_user_uniq_name VARCHAR2
 ,p_password VARCHAR2
) ;

FUNCTION my_authentication 
( p_username VARCHAR2  -- name is hardcoded by APEX
 ,p_password VARCHAR2 -- name is hardcoded by APEX
) RETURN BOOLEAN 
;

PROCEDURE my_invalid_session_basic_auth;

FUNCTION my_sentry_basic_auth
RETURN BOOLEAN;

PROCEDURE my_post_logout
;


PROCEDURE request_account
(  p_user_uniq_name               VARCHAR2                         
  ,p_password                     VARCHAR2                          
  ,p_target_app                   VARCHAR2   DEFAULT NULL              
) 
/*
        This procedure will add a row to the user table in status REQUEST, the same applies to table App-user-role relation. Somewhere there is a lookup table for configured app-specific roles and one of the row will have the flag BASIC. 
*/
;

PROCEDURE request_app_roles
 ( p_user_uniq_name               VARCHAR2                         
  ,p_target_app                   VARCHAR2        DEFAULT NULL                    
  ,p_role_csv                     VARCHAR2                           
 ) 
 /*
        This procedure will  add rows in the request table for App-user-role relation in PENDING status 
*/
 ;

PROCEDURE set_app_roles
 ( p_user_uniq_name               VARCHAR2                         
  ,p_target_app                   VARCHAR2                           
  ,p_role_csv                     VARCHAR2     
  ,p_role_csv_flag                VARCHAR2                       
 ) 
 ;

FUNCTION audit_user 
RETURN VARCHAR2;

PROCEDURE process_app_role_requests
    ( p_req_ids_csv VARCHAR2 
     ,p_action VARCHAR2 -- GRANT or REJECT 
    )
;

FUNCTION user_has_role 
( p_role_name  VARCHAR2 
) RETURN BOOLEAN
;

END;
/

SHOW ERRORS 

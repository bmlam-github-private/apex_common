CREATE OR REPLACE PACKAGE cstskm_user_api
AS

-- following is a prototype procedure to quickly give application access to a new user.
-- it bypasses the request and approval workflow!
PROCEDURE add_access 
( p_user_uniq_name VARCHAR2
 ,p_password VARCHAR2
 ,p_target_app VARCHAR2    DEFAULT NULL 
 ,p_strict_checks BOOLEAN DEFAULT FALSE -- raise error on possible dupes, locked account, reactivation etc 
) ;

-- Following is intended to handle user's password change action in case of custom authentication 
PROCEDURE replace_password 
( p_user_uniq_name VARCHAR2
 ,p_password VARCHAR2
) ;

-- callback for custom authentication 
FUNCTION my_authentication 
( p_username VARCHAR2  -- name is hardcoded by APEX
 ,p_password VARCHAR2 -- name is hardcoded by APEX
) RETURN BOOLEAN 
;

-- callback for custom authentication 
PROCEDURE my_invalid_session_basic_auth;

-- callback for custom authentication 
FUNCTION my_sentry_basic_auth
RETURN BOOLEAN;

-- callback for custom authentication 
PROCEDURE my_post_logout
;

-- Following is a convenience AP for use to implement in an app a public access request page when does not have any account yet
-- or when the account does not have any ACL role yet. Should work for both APEX workspace and custom authentication
PROCEDURE request_account
(  p_user_uniq_name               VARCHAR2                         
  ,p_password                     VARCHAR2                          
  ,p_target_app                   VARCHAR2   DEFAULT NULL              
  ,p_is_new_user                  BOOLEAN    DEFAULT FALSE               
) 
;

-- Following will  add rows in the request table for App-user-role relation in PENDING status 
PROCEDURE request_app_roles
 ( p_user_uniq_name               VARCHAR2                         
  ,p_target_app                   VARCHAR2        DEFAULT NULL                    
  ,p_role_csv                     VARCHAR2 
  ,p_action                       VARCHAR2        DEFAULT 'GRANT'                 
 ) 
 ;

PROCEDURE set_app_roles
 ( p_user_uniq_name               VARCHAR2                         
  ,p_target_app                   VARCHAR2                           
  ,p_role_csv                     VARCHAR2     
  ,p_role_csv_flag                VARCHAR2    
  ,p_auth                         VARCHAR2                   
 ) 
 ;

-- Following provide a user name for use in SQL statements
FUNCTION audit_user 
RETURN VARCHAR2;

-- Following reads rows from the request table and process the ADD, DELETE or REPLACE requests, sort of
PROCEDURE process_app_role_requests
    ( p_req_ids_csv VARCHAR2 
     ,p_action VARCHAR2 -- GRANT or REJECT 
     ,p_req_source VARCHAR2 
    )
;

-- following is a shorthand for a query on the user app role table 
FUNCTION user_has_role 
( p_role_name  VARCHAR2 
) RETURN BOOLEAN
;

-- Following checks if the given password is correct, should work for both APEX workspace and custom authentication
PROCEDURE verify_password (
     p_user_uniq_name IN VARCHAR2
    ,p_password IN VARCHAR2 
    ,po_password_ok     OUT BOOLEAN 
) ;

PROCEDURE init;

PROCEDURE submit_app_role_requests_by_json 
( p_app_name VARCHAR2 DEFAULT NULL 
 ,p_json     VARCHAR2
) ;

PROCEDURE process_app_role_requests_by_json
( p_app_name VARCHAR2 DEFAULT NULL 
 ,p_json     VARCHAR2
) ; 


FUNCTION get_dummy_app_for_account_req 
/* allow APEX App to filter on requests which are not targeted for a specific app, but targeted for an
  workspace account, the report query shall filter to requests for the dummy role 
  The motivation is that app admin can process both app role and account request.
  supposing the app is allowed to have account request feature 
*/
RETURN VARCHAR2
;


END;
/

SHOW ERRORS 

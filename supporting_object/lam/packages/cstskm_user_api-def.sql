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

END;
/

SHOW ERRORS 

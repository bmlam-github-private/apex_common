CREATE OR REPLACE PACKAGE cstskm_user_api
AS


PROCEDURE add_access 
( p_user_uniq_name VARCHAR2
 ,p_password VARCHAR2
 ,p_target_app VARCHAR2    DEFAULT NULL 
 ,p_strict_checks BOOLEAN DEFAULT FALSE -- raise error on possible dupes, locked account, reactivation etc 
) ;

function sentry_basic_auth
RETURN BOOLEAN;

FUNCTION check_credential -- can be used for custom scheme
( p_user_uniq_name VARCHAR2
 ,p_password VARCHAR2
 ,p_target_app VARCHAR2 DEFAULT NULL 
) RETURN BOOLEAN 
;

PROCEDURE invalid_session_basic_auth;

END;
/

SHOW ERRORS 

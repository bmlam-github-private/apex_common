CREATE OR REPLACE PACKAGE BODY cstskm_user_api
AS

PROCEDURE add_access 
( pi_user_id VARCHAR2
 ,pi_password VARCHAR2
 ,pi_target_app VARCHAR2 NULL 
 ,pi_strict_checks BOOLEAN FALSE -- check for possible dupes, locked account, reactivation etc 
) AS
-- Two use cases:
-- 1. account does not yet exists. INSERT row in user table, optionally check password complexity. Add row to user app releation table in status Requested 
--    if p_target_app is given 
-- 2. account already exists, verify password and add row to relation table.
BEGIN 
NULL;
END check_account;

FUNCTION check_credential -- can be used for custom scheme
( pi_user_id VARCHAR2
 ,pi_password VARCHAR2
 ,pi_target_app VARCHAR2 NULL 
) RETURN BOOLEAN 
AS
BEGIN 
	RETURN FALSE;
END;
/

SHOW ERRORS 

CREATE OR REPLACE PACKAGE cstskm_util
AS

    gc_dummy_app_for_account_request CONSTANT VARCHAR2(100) := 'DUMMY_APP(REQUEST ACCOUNT)';
    gc_dummy_role_for_account_request  CONSTANT VARCHAR2(100) := 'DUMMY_ROLE(REQUEST ACCOUNT)';

FUNCTION encrypted
( string VARCHAR2
) RETURN RAW
;

FUNCTION decrypted
( encrypted RAW 
) RETURN VARCHAR2 
;

END;
/
show errors 

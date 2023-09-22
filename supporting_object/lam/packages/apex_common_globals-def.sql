CREATE OR REPLACE PACKAGE apex_common_globals 
AS 
	gc_dummy_app_for_account_request CONSTANT VARCHAR2(100) := 'DUMMY_APP(REQUEST ACCOUNT)';
	gc_dummy_role_for_account_request  CONSTANT VARCHAR2(100) := 'DUMMY_ROLE(REQUEST ACCOUNT)';
	gc_status_ok_pending_create CONSTANT VARCHAR2(100) := 'OK_PENDING_CREATE';
END;
/

CREATE OR REPLACE PACKAGE BODY cstskm_util
AS 

FUNCTION encrypted
( string VARCHAR2
) RETURN RAW
AS
	l_key_raw RAW(128) := UTL_RAW.CAST_TO_RAW( sys_context( 'userenv', 'dbid' )  ); -- use something more secret if needed 
	l_return  RAW(2000);
	l_decrypted VARCHAR2(2000);
BEGIN
		  l_return  := DBMS_CRYPTO.ENCRYPT(UTL_RAW.CAST_TO_RAW( string ), DBMS_CRYPTO.DES_CBC_PKCS5, l_key_raw);
		  -- l_decrypted := UTL_RAW.CAST_TO_VARCHAR2(DBMS_CRYPTO.DECRYPT(l_encrypted, DBMS_CRYPTO.DES_CBC_PKCS5, l_key_raw));
		  return l_return;
END encrypted;

FUNCTION decrypted
( encrypted RAW 
) RETURN VARCHAR2 
AS
	l_key_raw RAW(128) := UTL_RAW.CAST_TO_RAW( sys_context( 'userenv', 'dbid' )  ); -- use something more secret if needed 
	l_return  VARCHAR2(2000);
BEGIN
	l_return := UTL_RAW.CAST_TO_VARCHAR2(DBMS_CRYPTO.DECRYPT( encrypted, DBMS_CRYPTO.DES_CBC_PKCS5, l_key_raw));
	RETURN l_return;
END decrypted;

PROCEDURE cre_wrksp_user_scheduler_job
( user_uniq_name VARCHAR2
 ,encrypted_password RAW 
) AS 
/* create a scheduler job to run instanenously. Since create_user only works if the session runs as the workspace owner 
  An app admin clicks some button in an APEX page which eventually will run this procedure. Calling create_user from the
  APEX session would not work!
*/ 
	--l_raw_password_as_varchar2 VARCHAR2(1000) ;
	l_job_action VARCHAR2(32000);
	l_job_action_template VARCHAR2(32000) :=
    	q'{
DECLARE 
       l_workspace_id      number;
BEGIN 
  l_workspace_id := apex_util.find_security_group_id (p_workspace => 'LAM');
  apex_util.set_security_group_id (p_security_group_id => l_workspace_id);
	apex_util.create_user ( p_user_name => '<user_name>'
		, p_web_password => cstskm_util.decrypted( '<raw_password_as_varchar2>' )
		);
END;}'
    	 ;
BEGIN 
	-- we cannot imbed a raw value (the encrypted password) in the anonymous PLSQL block, therefore we need to convert it 
	-- to VARCHAR2  
	--l_raw_password_as_varchar2 := utl_raw.CAST_TO_VARCHAR2 (encrypted_password);
	l_job_action := replace( 
	    	replace( l_job_action_template, '<user_name>', user_uniq_name )
	    		, '<raw_password_as_varchar2>', encrypted_password -- l_raw_password_as_varchar2
    		);
	pck_std_log.inf ( $$plsql_unit||':'||$$plsql_line ||' '||l_job_action );
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'create_'||user_uniq_name,
    job_type        => 'PLSQL_BLOCK',
    job_action      => l_job_action,
    start_date      => SYSTIMESTAMP,
    repeat_interval => NULL,
    end_date        => NULL,
    enabled         => TRUE,
    auto_drop         => TRUE,
    comments        => 'create an APEX workspace user'
  );
END cre_wrksp_user_scheduler_job;

END;
/

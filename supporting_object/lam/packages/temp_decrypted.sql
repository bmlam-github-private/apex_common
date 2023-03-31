CREATE OR REPLACE FUNCTION temp_decrypted
( encrypted RAW 
) RETURN VARCHAR2 
AS
	l_key_raw RAW(128) := UTL_RAW.CAST_TO_RAW( sys_context( 'userenv', 'dbid' )  ); -- use something more secret if needed 
	l_return  VARCHAR2(2000);
BEGIN
	l_return := UTL_RAW.CAST_TO_VARCHAR2(DBMS_CRYPTO.DECRYPT( encrypted, DBMS_CRYPTO.DES_CBC_PKCS5, l_key_raw));
	RETURN l_return;
END;
/
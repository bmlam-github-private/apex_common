CREATE OR REPLACE FUNCTION temp_encrypted
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
END;
/
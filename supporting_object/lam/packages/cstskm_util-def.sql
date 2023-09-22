CREATE OR REPLACE PACKAGE cstskm_util
AS

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

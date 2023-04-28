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

PROCEDURE cre_wrksp_user_scheduler_job
( user_uniq_name VARCHAR2
 ,encrypted_password RAW 
);

END;
/
show errors 

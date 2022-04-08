BEGIN
  cstskm_user_api.add_access 
( pi_user_id => 'TESTER'||to_char( sysdate , 'yyyymmdd_hh24mi')
 ,pi_password => 'PASS'||to_char( sysdate , 'yyyymmdd_hh24mi')
 --,pi_target_app VARCHAR2 NULL 
 --,pi_strict_checks BOOLEAN FALSE -- check for possible dupes, locked account, reactivation etc 
) ;
END;
/

SELECT id, user_id, hashed
FROM apex_cstskm_user
ORDER BY created DESC FETCH FIRST 2 ROWS ONLY
;
SELECT id, user_id, app_name, created 
FROM apex_cstskm_user_x_app 
ORDER BY created DESC FETCH FIRST 2 ROWS ONLY
;

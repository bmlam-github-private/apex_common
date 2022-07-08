define pi_user_uniq_name=&1

DECLARE 
  l_user_uniq_name VARCHAR2(30) := trim( '&pi_user_uniq_name' ) ;
BEGIN
  l_user_uniq_name := coalesce( l_user_uniq_name, 'TESTER_'||to_char( sysdate , 'yyyymmdd_hh24mi'));
  cstskm_user_api.add_access 
( p_user_uniq_name => l_user_uniq_name
 ,p_password => 'PASS_'||to_char( sysdate , 'yyyymmdd_hh24mi')
 --,pi_target_app VARCHAR2 NULL 
 --,pi_strict_checks BOOLEAN FALSE -- check for possible dupes, locked account, reactivation etc 
) ;
END;
/

SELECT id, user_uniq_name, created_by, hashed
FROM apex_cstskm_user
ORDER BY created DESC FETCH FIRST 2 ROWS ONLY
;
/*
SELECT id, user_id, app_name, created 
FROM apex_cstskm_user_x_app 
ORDER BY created DESC FETCH FIRST 2 ROWS ONLY
;
*/ 
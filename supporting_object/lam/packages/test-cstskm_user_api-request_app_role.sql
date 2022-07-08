undefine l_test_user
define l_test_user=&1

DECLARE 
  l_test_user apex_cstskm_user.user_uniq_name%TYPE := upper( '&pi_user_uniq_name' ) ;
BEGIN
  IF trim( l_test_user ) IS NULL THEN 
    SELECT user_uniq_name
    INTO l_test_user
    FROM apex_cstskm_user
    WHERE user_uniq_name LIKE 'TESTER_2022%'
    ORDER BY user_uniq_name 
    FETCH FIRST 1 ROWS ONLY
    ;
  END IF;

  IF FALSE THEN 
    cstskm_user_api.request_app_roles
    ( p_user_uniq_name => 'no such user'
     ,p_target_app => 'no such app'
     ,p_role_csv =>  'role1,role2'
    ) ;
  END IF;

  IF FALSE THEN 
    cstskm_user_api.request_app_roles
    ( p_user_uniq_name => l_test_user
     ,p_target_app => 'no such app'
     ,p_role_csv =>  'role1,role2'
    ) ;
  END IF;

  IF TRUE THEN 
    cstskm_user_api.request_app_roles
    ( p_user_uniq_name => l_test_user
     ,p_target_app => 'A_FINE_APP'
     ,p_role_csv =>  'BASIC,JUNIOR,SENIOR'
    ) ;
  END IF;
END;
/
SELECT id, user_id, app_name, role_name, created 
FROM apex_cstskm_app_role_request 
ORDER BY created DESC FETCH FIRST 2 ROWS ONLY
;

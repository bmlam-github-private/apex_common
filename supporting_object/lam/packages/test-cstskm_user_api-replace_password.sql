BEGIN
  cstskm_user_api.replace_password 
( p_user_uniq_name => 'TESTER_20220414_1613'
 ,p_password       => 'TESTER_20220414_1613'
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
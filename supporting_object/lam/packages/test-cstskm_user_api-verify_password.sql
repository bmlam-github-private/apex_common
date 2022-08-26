define pi_user_uniq_name=&1

var test_user_id VARCHAR2(100)
var test_password VARCHAR2(100)

PROMPT Create the account 
DECLARE
  l_user_uniq_name VARCHAR2(30) := trim( '&pi_user_uniq_name' ) ;
BEGIN
  l_user_uniq_name := coalesce( l_user_uniq_name, 'TESTER_'||to_char( sysdate , 'yyyymmdd_hh24mi'));
  :test_user_id := l_user_uniq_name;
  :test_password := 'PASS_'||to_char( sysdate , 'yyyymmdd_hh24mi');

  cstskm_user_api.add_access
    ( p_user_uniq_name => l_user_uniq_name
     ,p_password => :test_password 
     --,pi_target_app VARCHAR2 NULL
     --,pi_strict_checks BOOLEAN FALSE -- check for possible dupes, locked account, reactivation etc
    ) ;
END;
/

PRINT :test_user_id
PRINT :test_password

BEGIN
  cstskm_user_api.replace_password 
( p_user_uniq_name => 'TESTER_20220414_1613'
 ,p_password       => 'TESTER_20220414_1613'
) ;
END;
/

SET SERVEROUT ON 

PROMPT test  credential success and error case 
DECLARE 
  l_password_ok BOOLEAN;
BEGIN
  dbms_output.put_line( 'Shoud succeed');
  cstskm_user_api.verify_password ( p_user_uniq_name => :test_user_id
     , p_password => :test_password
     , po_password_ok => l_password_ok 
    );
  dbms_output.put_line( 'l_password_ok: '|| sys.diutil.bool_to_int(l_password_ok));
  
  dbms_output.put_line( 'Shoud fail');
  cstskm_user_api.verify_password ( p_user_uniq_name => :test_user_id
     , p_password => 'wrong password'
     , po_password_ok => l_password_ok 
    );
  dbms_output.put_line( 'l_password_ok: '|| sys.diutil.bool_to_int(l_password_ok));
  
END;
/

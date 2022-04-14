SET SERVEROUT ON 

DECLARE   
  rc BOOLEAN;
BEGIN
  rc := cstskm_user_api.my_authentication  
( p_username => 'TESTER_20220414_1613'
 ,p_password => 'TESTER_20220414_1613'
) ;
dbms_output.put_line ( 'passord ok: ' ||sys.diutil.bool_to_int(rc));
END;
/

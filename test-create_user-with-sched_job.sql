begin
dbms_scheduler.create_job (
   job_name           =>  'TEST_CREATE_WORKSPACE_USER',
   job_type           =>  'PLSQL_BLOCK',
   job_action         =>  
      q'{DECLARE
    l_workspace_id      number;
BEGIN
    l_workspace_id := apex_util.find_security_group_id (p_workspace => 'LAM');
    apex_util.set_security_group_id (p_security_group_id => l_workspace_id);    
    apex_util.create_user ( p_user_name => 'TEST_2023_03_01', p_web_password => 'silly-password' );
end;
}'
   ,
   start_date         =>  sysdate,
   repeat_interval    =>  NULL,
   enabled            =>  TRUE);
   dbms_scheduler.create_job (
      job_name           =>  'TEST_CREATE_WORKSPACE_USER',
      job_type           =>  'PLSQL_BLOCK',
      job_action         =>  
         q'{DECLARE
       l_workspace_id      number;
   BEGIN
       l_workspace_id := apex_util.find_security_group_id (p_workspace => 'LAM');
       apex_util.set_security_group_id (p_security_group_id => l_workspace_id);    
       apex_util.create_user ( p_user_name => 'TEST_2023_03_01', p_web_password => 'silly-password' );
   end;
   }'
      ,
      start_date         =>  sysdate,
      repeat_interval    =>  NULL,
      enabled            =>  TRUE);
      dbms_scheduler.create_job (
            job_name           =>  'TEST_CREATE_WORKSPACE_USER',
            job_type           =>  'PLSQL_BLOCK',
            job_action         =>  
               q'{DECLARE
             l_workspace_id      number;
         BEGIN
             l_workspace_id := apex_util.find_security_group_id (p_workspace => 'LAM');
             apex_util.set_security_group_id (p_security_group_id => l_workspace_id);    
             apex_util.create_user ( p_user_name => 'TEST_2023_03_01', p_web_password => 'silly-password' );
         end;
         }'
            ,
            start_date         =>  sysdate,
            repeat_interval    =>  NULL,
            enabled            =>  TRUE);
END;
/
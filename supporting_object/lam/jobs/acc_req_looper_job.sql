BEGIN
  -- Create the job
  DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'acc_req_looper_job',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN loop_create_user_reqs(); END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY;BYHOUR=1;BYMINUTE=0;BYSECOND=0',
    enabled         => false
  );

  -- to show how to change the scheduler - Set the job to run at 1 pm as well
  DBMS_SCHEDULER.SET_ATTRIBUTE(
    name     => 'acc_req_looper_job',
    attribute => 'repeat_interval',
    value    => 'FREQ=DAILY;BYHOUR=1,13;BYMINUTE=0;BYSECOND=0'
  );
  
  -- Enable the job
  DBMS_SCHEDULER.ENABLE('acc_req_looper_job');
END;
/

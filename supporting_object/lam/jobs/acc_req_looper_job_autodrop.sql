BEGIN
  -- Create the job
  DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'acc_req_looper_job_autodrop',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN loop_create_user_reqs(); END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => null,
    enabled         => true
  );

END;
/

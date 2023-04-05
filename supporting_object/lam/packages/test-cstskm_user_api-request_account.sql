begin 
	cstskm_user_api.request_account
	(  p_user_uniq_name               => 'TEST_20230405'
	  ,p_password                     => 'TEST_20230405xx'
	 -- ,p_target_app                   => 'A_FINE_APP'
	 -- ,p_target_app                   => 'FINANCEDB2'
	  ,p_target_app                   => 'PLAY WITH ACL'
	  ,p_is_new_user                  => true
	);
	COMMIT;
END;
/
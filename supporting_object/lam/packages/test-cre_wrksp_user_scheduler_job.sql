begin
	cstskm_util.cre_wrksp_user_scheduler_job
		( user_uniq_name => '&new_user'
		 ,encrypted_password --RAW 
		 	=> xxx
		) ;
end;
/
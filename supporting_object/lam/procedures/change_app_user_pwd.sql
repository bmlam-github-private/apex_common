CREATE OR REPLACE PROCEDURE change_app_user_pwd
( pi_old_password VARCHAR2
 ,pi_new_passowrd VARCHAR2
) AS
/* can only be used from an APEX app since a valid logged-in, APEX workspace authentication based user is assumed.
*/ 
	l_is_apex_ws_auth BOOLEAN;
	l_username VARCHAR2(30);
	l_error_msg VARCHAR2(1000);
BEGIN 
	l_username := v( 'APP_USER');
	IF l_username IS NULL THEN 
		RAISE_APPLICATION_ERROR( -20001, 'Action can only be applied to a logged-in, APEX workspace authentication-based user');
	END IF;
	l_is_apex_ws_auth := TRUE ; -- for now
-- we lack a way to check which authentication scheme is currently in effect.
-- wouuld be bad idea to guess because pi_old_password could be wrong:  if the current user can be authenticated with pi_old_password
-- using the APEX API, likely APEX WS authentication scheme is in effect 
-- Consider using context 
	IF l_is_apex_ws_auth THEN 
		enforce_strong_password( p_old_password => pi_old_password, p_new_password => pi_new_passowrd, p_username=> l_username
			, po_errors => l_error_msg
			);

		IF l_error_msg IS NULL THEN 
			-- by default the following procedure does not enforce password complexity!
			APEX_UTIL.RESET_PASSWORD (
			    p_user_name    => l_username --  IN VARCHAR2 DEFAULT WWW_FLOW_SECURITY.G_USER,
			    ,p_old_password  => pi_old_password -- IN VARCHAR2 DEFAULT NULL,
			    ,p_new_password  => pi_new_passowrd --  IN VARCHAR2,
			    ,p_change_password_on_first_use => FALSE -- IN BOOLEAN DEFAULT TRUE
		    );
		ELSE
		
			RAISE_APPLICATION_ERROR( -20001, l_error_msg );
		END IF;

	END IF;
END;
/

show errors

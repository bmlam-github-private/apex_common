CREATE TABLE apex_wkspauth_acc_req_token 
( req_id NUMBER NOT NULL 
	REFERENCES apex_wkspauth_app_role_request(id)  ON DELETE  CASCADE
 ,my_token RAW(2000) -- 
)
/

ALTER TABLE apex_wkspauth_acc_req_token 
	ADD origin_app_name VARCHAR2( 30 ) 
/


ALTER TABLE apex_wkspauth_acc_req_token 
ADD UNIQUE( req_id)
/

COMMENT ON TABLE apex_wkspauth_acc_req_token IS 'temporary stores the web passowrd for workspace account request '
/
CREATE TABLE apex_wkspauth_app_role_request 
( id NUMBER(10) GENERATED ALWAYS AS IDENTITY NOT NULL 
  ,apex_user_name VARCHAR(30) NOT NULL CHECK ( trim( upper(apex_user_name) ) = apex_user_name ) 
  ,app_name  VARCHAR2(30) NOT NULL 
  ,role_name  VARCHAR2(30) NOT NULL 
  ,status  VARCHAR2(30) NOT NULL  
  ,created  DATE NOT NULL 
  ,created_by  VARCHAR2(30) NOT NULL 
  ,updated  DATE  NULL 
  ,updated_by  VARCHAR2(30)  NULL 
  ,UNIQUE ( apex_user_name, app_name, role_name )
  ,FOREIGN KEY ( app_name, role_name ) REFERENCES apex_cstskm_app_role_lkup (app_name, role_name )
    ON DELETE CASCADE
  , constraint apex_wkspauth_app_role_req_stat_ck CHECK ( status IN ( 'PENDING', 'APPROVED', 'REJECTED') )
)
;


COMMENT ON TABLE apex_wkspauth_app_role_request IS 
'Since we are extending the functionality of role request to APEX, we use this table to manage the requests '
;
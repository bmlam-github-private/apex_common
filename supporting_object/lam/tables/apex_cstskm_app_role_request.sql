CREATE TABLE apex_cstskm_app_role_request 
( id NUMBER(10) GENERATED ALWAYS AS IDENTITY NOT NULL 
  ,user_id NUMBER(10) NOT NULL  REFERENCES apex_cstskm_user(id)
  ,app_name  VARCHAR2(30) NOT NULL 
  ,role_name  VARCHAR2(30) NOT NULL 
  ,status  VARCHAR2(30) NOT NULL 
  ,created  DATE NOT NULL 
  ,created_by  VARCHAR2(30) NOT NULL 
  ,updated  DATE  NULL 
  ,updated_by  VARCHAR2(30)  NULL 
  ,UNIQUE ( user_id, app_name, role_name )
  ,FOREIGN KEY ( app_name, role_name ) REFERENCES apex_cstskm_app_role_lkup (app_name, role_name )
  , constraint apex_cstskm_app_role_req_stat_ck CHECK ( status IN ( 'PENDING', 'APPROVED', 'REJECTED') )
)
;


COMMENT ON TABLE apex_cstskm_app_role_request IS 
'A kind of request history. There shall be a clean up job to remove old rows'
;


ALTER TABLE apex_cstskm_app_role_request ADD ( action VARCHAR2(10) DEFAULT 'GRANT')
;
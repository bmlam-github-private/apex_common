CREATE TABLE apex_cstskm_app_role_lkup
( id NUMBER(10)  GENERATED ALWAYS AS IDENTITY NOT NULL 
  ,app_name VARCHAR2(30) NOT NULL CHECK ( app_name = UPPER( app_name ))
  ,role_name VARCHAR2(30) NOT NULL CHECK ( role_name = UPPER( role_name ))
  ,basic_flg VARCHAR2(15) NOT NULL CHECK ( regexp_instr( basic_flg, '^YES|DUMMY\d+$' ) > 0 )
  ,created  DATE NOT NULL 
  ,created_by  VARCHAR2(30) NOT NULL 
  ,updated  DATE  NULL 
  ,updated_by  VARCHAR2(30)  NULL 
  ,PRIMARY KEY (id)
  ,UNIQUE( app_name, role_name )
  ,UNIQUE( app_name, basic_flg )
)
;

COMMENT ON TABLE apex_cstskm_app_role_lkup IS 
'to server as list of values to set relations between user and app roles.
The entry with basic_flg YES will the the default role when granting user access to an app.
'
;


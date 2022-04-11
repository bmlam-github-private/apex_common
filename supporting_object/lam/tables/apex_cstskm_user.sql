CREATE TABLE apex_cstskm_user
( id NUMBER(10)  GENERATED ALWAYS AS IDENTITY NOT NULL 
  ,user_uniq_name   VARCHAR2(30) NOT NULL CHECK ( user_uniq_name = UPPER( user_uniq_name ))
  ,hashed   VARCHAR2(40) NOT NULL 
  ,created  DATE NOT NULL 
  ,created_by  VARCHAR2(30) NOT NULL 
  ,updated  DATE  NULL 
  ,updated_by  VARCHAR2(30)  NULL 
  ,PRIMARY KEY (id)
)
;

COMMENT ON TABLE apex_cstskm_user IS 
'Users in the sense of Custom authentication scheme. This table stores the credential of a user, informaiton 
that is shared by all apps for the same unique user
'
;


CREATE TABLE apex_cstskm_user_x_app_role 
( id NUMBER(10) GENERATED ALWAYS AS IDENTITY NOT NULL 
  ,user_id NUMBER(10) NOT NULL  REFERENCES apex_cstskm_user(id)
  ,app_name  VARCHAR2(30) NOT NULL 
  ,role_name  VARCHAR2(30) NOT NULL 
  ,created  DATE NOT NULL DEFAULT SYSDATE 
  ,created_by  VARCHAR2(30) NOT NULL 
  ,updated  DATE  NULL 
  ,updated_by  VARCHAR2(30)  NULL 
  ,UNIQUE ( user_id, app_name, role_name )
  ,FOREIGN KEY ( app_name, role_name ) REFERENCES apex_cstskm_app_role_lkup (app_name, role_name )
)
;


COMMENT ON TABLE apex_cstskm_user_x_app_role IS 
'This table stores the roles of a user in relation to a given application.
It is envisioned that each application will have login page which is also a request-login page.
These use cases exist:
* A user who has never had any access to the system can access the entry page of the target app to request an account, a new password must be provided.
* A user who has got access to at least one app in the system can access the entry page of the target app to request access for another app, providing the existing password
* change of password from any app entry page 
Each app can have an admin page to grant or revoke access to the particular app.
'
;
PROMPT tables
REM ********** imbedding script ./lam/tables/apex_cstskm_user_x_app_role.sql********** 
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
REM ********** imbedding script ./lam/tables/apex_cstskm_app_role_lkup.sql********** 
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

REM ********** imbedding script ./lam/tables/apex_wkspauth_app_role_request.sql********** 
CREATE TABLE apex_wkspauth_app_role_request
( id NUMBER(10) GENERATED ALWAYS AS IDENTITY NOT NULL
  ,apex_user_name VARCHAR(30) NOT NULL CHECK ( trim( upper(apex_user_name) ) = apex_user_name )
  ,app_name  VARCHAR2(30) NOT NULL
  ,role_name  VARCHAR2(30) NOT NULL
  ,action  VARCHAR2(30) NOT NULL
  ,status  VARCHAR2(30) NOT NULL
  ,created  DATE NOT NULL
  ,created_by  VARCHAR2(30) NOT NULL
  ,updated  DATE  NULL
  ,updated_by  VARCHAR2(30)  NULL
  ,UNIQUE ( apex_user_name, app_name, role_name, action )
  ,FOREIGN KEY ( app_name, role_name ) REFERENCES apex_cstskm_app_role_lkup (app_name, role_name )
    ON DELETE CASCADE
  , constraint apex_wkspauth_app_role_req_stat_ck CHECK ( status IN ( 'PENDING', 'APPROVED', 'REJECTED') )
)
;


COMMENT ON TABLE apex_wkspauth_app_role_request IS
'Since we are extending the functionality of role request to APEX, we use this table to manage the requests
Entries in this table are supposed to be archived to a history table once the request has reached a "final"
status. This should facilitate this sequence of events: request GRANT, request granted, request REVOKE, request granted , request GRANT again.
The archival should be performed by a regular job.
'
;

ALTER TABLE apex_wkspauth_app_role_request ADD ( PRIMARY KEY (id))
;
ALTER TABLE apex_wkspauth_app_role_request ADD ( action VARCHAR2(10) DEFAULT 'GRANT')
;
ALTER TABLE apex_wkspauth_app_role_request DROP CONSTRAINT apex_wkspauth_app_role_req_stat_ck
;
ALTER TABLE apex_wkspauth_app_role_request ADD CONSTRAINT apex_wkspauth_app_role_req_stat_ck
  CHECK ( status IN ( 'PENDING', 'APPROVED', 'REJECTED', 'OK_PENDING_CREATE') )
;
REM ********** imbedding script ./lam/tables/apex_cstskm_app_role_request.sql********** 
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
REM ********** imbedding script ./lam/tables/apex_cstskm_user.sql********** 
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

REM ********** imbedding script ./lam/tables/seed-apex_cstskm_app_role_lkup.sql********** 
INSERT INTO apex_cstskm_app_role_lkup
(  app_name,		role_name,					basic_flg
  ,created,			created_by
)
SELECT
	'A_FINE_APP', 'BASIC',   'YES'
   ,sysdate,		coalesce( sys_context('userenv', 'os_user'), user)
FROM dual
WHERE 1=0
;
INSERT INTO apex_cstskm_app_role_lkup
(  app_name,		role_name,					basic_flg
  ,created,			created_by
)
SELECT
	'A_FINE_APP', 'JUNIOR',   'DUMMY1'
   ,sysdate,		coalesce( sys_context('userenv', 'os_user'), user)
FROM dual
;
INSERT INTO apex_cstskm_app_role_lkup
(  app_name,		role_name,					basic_flg
  ,created,			created_by
)
SELECT
	'A_FINE_APP', 'SENIOR',   'DUMMY2'
   ,sysdate,		coalesce( sys_context('userenv', 'os_user'), user)
FROM dual
;

COMMIT;
REM ********** imbedding script ./lam/tables/apex_wkspauth_acc_req_token.sql********** 
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

PROMPT package specifications
REM ********** imbedding script ./lam/packages/cstskm_util-def.sql********** 
CREATE OR REPLACE PACKAGE cstskm_util
AS

    gc_dummy_app_for_account_request CONSTANT VARCHAR2(100) := 'DUMMY_APP(REQUEST ACCOUNT)';
    gc_dummy_role_for_account_request  CONSTANT VARCHAR2(100) := 'DUMMY_ROLE(REQUEST ACCOUNT)';

FUNCTION encrypted
( string VARCHAR2
) RETURN RAW
;

FUNCTION decrypted
( encrypted RAW
) RETURN VARCHAR2
;

END;
/
show errors
REM ********** imbedding script ./lam/packages/cstskm_user_api-def.sql********** 
CREATE OR REPLACE PACKAGE cstskm_user_api
AS

-- following is a prototype procedure to quickly give application access to a new user.
-- it bypasses the request and approval workflow!
PROCEDURE add_access
( p_user_uniq_name VARCHAR2
 ,p_password VARCHAR2
 ,p_target_app VARCHAR2    DEFAULT NULL
 ,p_strict_checks BOOLEAN DEFAULT FALSE -- raise error on possible dupes, locked account, reactivation etc
) ;

-- Following is intended to handle user's password change action in case of custom authentication
PROCEDURE replace_password
( p_user_uniq_name VARCHAR2
 ,p_password VARCHAR2
) ;

-- callback for custom authentication
FUNCTION my_authentication
( p_username VARCHAR2  -- name is hardcoded by APEX
 ,p_password VARCHAR2 -- name is hardcoded by APEX
) RETURN BOOLEAN
;

-- callback for custom authentication
PROCEDURE my_invalid_session_basic_auth;

-- callback for custom authentication
FUNCTION my_sentry_basic_auth
RETURN BOOLEAN;

-- callback for custom authentication
PROCEDURE my_post_logout
;

-- Following is a convenience AP for use to implement in an app a public access request page when does not have any account yet
-- or when the account does not have any ACL role yet. Should work for both APEX workspace and custom authentication
PROCEDURE request_account
(  p_user_uniq_name               VARCHAR2
  ,p_password                     VARCHAR2
  ,p_target_app                   VARCHAR2   DEFAULT NULL
  ,p_is_new_user                  BOOLEAN    DEFAULT FALSE
)
;

-- Following will  add rows in the request table for App-user-role relation in PENDING status
PROCEDURE request_app_roles
 ( p_user_uniq_name               VARCHAR2
  ,p_target_app                   VARCHAR2        DEFAULT NULL
  ,p_role_csv                     VARCHAR2
  ,p_action                       VARCHAR2        DEFAULT 'GRANT'
 )
 ;

PROCEDURE set_app_roles
 ( p_user_uniq_name               VARCHAR2
  ,p_target_app                   VARCHAR2
  ,p_role_csv                     VARCHAR2
  ,p_role_csv_flag                VARCHAR2
  ,p_auth                         VARCHAR2
 )
 ;

-- Following provide a user name for use in SQL statements
FUNCTION audit_user
RETURN VARCHAR2;

-- Following reads rows from the request table and process the ADD, DELETE or REPLACE requests, sort of
PROCEDURE process_app_role_requests
    ( p_req_ids_csv VARCHAR2
     ,p_action VARCHAR2 -- GRANT or REJECT
     ,p_req_source VARCHAR2
    )
;

-- following is a shorthand for a query on the user app role table
FUNCTION user_has_role
( p_role_name  VARCHAR2
) RETURN BOOLEAN
;

-- Following checks if the given password is correct, should work for both APEX workspace and custom authentication
PROCEDURE verify_password (
     p_user_uniq_name IN VARCHAR2
    ,p_password IN VARCHAR2
    ,po_password_ok     OUT BOOLEAN
) ;

PROCEDURE init;

PROCEDURE submit_app_role_requests_by_json
( p_app_name VARCHAR2 DEFAULT NULL
 ,p_json     VARCHAR2
) ;

PROCEDURE process_app_role_requests_by_json
( p_app_name VARCHAR2 DEFAULT NULL
 ,p_json     VARCHAR2
) ;


FUNCTION get_dummy_app_for_account_req
/* allow APEX App to filter on requests which are not targeted for a specific app, but targeted for an
  workspace account, the report query shall filter to requests for the dummy role
  The motivation is that app admin can process both app role and account request.
  supposing the app is allowed to have account request feature
*/
RETURN VARCHAR2
;


END;
/

SHOW ERRORS

PROMPT package bodies
REM ********** imbedding script ./lam/packages/cstskm_user_api-impl.sql********** 
CREATE OR REPLACE PACKAGE BODY cstskm_user_api
AS
    g_basic_auth_done BOOLEAN;
    c_nl CONSTANT VARCHAR2(10) := chr(10);

/* based on a context definition, most routine in this package need to decide if the customer data model applies
   or should be ignored. For example to request access to an app, in case 1, we need to make sure a row will be
   in table apex_cstskm_user. In case 2, we just need to call the APEX APIs
*/
/* common internal routine which which can both
   1. compute the hash based for given new usernamne and password to add a new user entry
   2. validates the given password against the username
*/
err_parent_not_found  EXCEPTION;
PRAGMA EXCEPTION_INIT(err_parent_not_found,-02291);

c_auth_method_apex CONSTANT VARCHAR2(10)   := 'APEX';
c_auth_method_custom CONSTANT VARCHAR2(10) := 'CUSTOM';

c_fixed_workspace CONSTANT VARCHAR2(10) := 'LAM';

g_auth_method VARCHAR2(10) := c_auth_method_apex; -- should be retreived from APEX!


PROCEDURE request_app_roles_return_req_ids
 ( p_user_uniq_name               VARCHAR2
  ,p_target_app                   VARCHAR2        DEFAULT NULL
  ,p_role_csv                     VARCHAR2
  ,p_action                       VARCHAR2        DEFAULT 'GRANT'
  ,po_out_req_id        OUT    dbms_sql.number_table
 ) ;

PROCEDURE oops( p_line NUMBER ) AS BEGIN RAISE_APPLICATION_ERROR( -20001, 'oops called from line '||p_line|| ' of '||$$plsql_unit ) ;
END oops
;
PROCEDURE apex_auth_app_role_action
( p_user_uniq_name                VARCHAR2
  ,p_app_id                       NUMBER
  ,p_role                         VARCHAR2
  ,p_action                       VARCHAR2
) ;


PROCEDURE cst_auth_app_role_action
( p_user_id                       NUMBER
  ,p_target_app                   VARCHAR2
  ,p_role                         VARCHAR2
  ,p_action                       VARCHAR2
);

FUNCTION audit_user
RETURN VARCHAR2
AS
BEGIN
    RETURN coalesce( V('APP_USER'), user );
END audit_user;

PROCEDURE check_or_create_credential (
     p_user_uniq_name IN VARCHAR2
    ,p_password IN VARCHAR2
    ,p_create_new IN BOOLEAN
    ,p_replace_password IN BOOLEAN
    ,po_password_ok     OUT BOOLEAN
) AS
-- this routine is used internally both for storing a new password or verifying it since
-- the algorithm to compute the hash value must be identical
    l_user apex_cstskm_user.user_uniq_name%type := trim( upper(p_user_uniq_name) );
    l_id   apex_cstskm_user.id%type;
    l_hash_computed apex_cstskm_user.hashed%type;
    l_hash_retrieved apex_cstskm_user.hashed%type;
BEGIN
    pck_std_log.inf( 'p_user_uniq_name: '||p_user_uniq_name
        ||' p_create_new: '||sys.diutil.bool_to_int( p_create_new)
        ||' p_replace_password: '||sys.diutil.bool_to_int( p_replace_password)
        );

    IF p_create_new AND p_replace_password THEN
        RAISE_APPLICATION_ERROR( -20001, 'Cannot create new account and replace password in one call!');
    END IF;
    CASE
    WHEN p_create_new THEN
        BEGIN
            INSERT INTO apex_cstskm_user
            ( user_uniq_name, hashed
                , created
                , created_by
            ) VALUES
            ( l_user, 'xxx'
                , sysdate
                , audit_user()
            ) RETURNING id INTO l_id
            ;
        EXCEPTION
            WHEN dup_val_on_index THEN
                RAISE_APPLICATION_ERROR( -20001, 'Username '||l_user||' is already taken!' );
        END;
    ELSE
        BEGIN
            select id  , hashed
              into l_id, l_hash_retrieved
              from apex_cstskm_user
             where user_uniq_name = l_user
             ;
            pck_std_log.inf( 'l_hash_retrieved: '||l_hash_retrieved );
        exception when no_data_found then
            l_hash_retrieved := '-invalid-';
        END;
    END CASE;

    l_hash_computed := rawtohex(sys.dbms_crypto.hash (
                        sys.utl_raw.cast_to_raw (
                            p_password||l_id||l_user ),
                        sys.dbms_crypto.hash_sh512 )
    );
    pck_std_log.inf( 'l_hash_computed: '||l_hash_computed );

    CASE
    WHEN p_create_new OR p_replace_password THEN
        UPDATE apex_cstskm_user
        SET hashed = l_hash_computed
        WHERE id = l_id
        ;
        COMMIT;
    ELSE
        po_password_ok := l_hash_computed = l_hash_retrieved;
    END CASE;

END check_or_create_credential;


PROCEDURE add_access
( p_user_uniq_name VARCHAR2
 ,p_password VARCHAR2
 ,p_target_app VARCHAR2    DEFAULT NULL
 ,p_strict_checks BOOLEAN DEFAULT FALSE -- raise error on possible dupes, locked account, reactivation etc
) AS
-- Two use cases:
-- 1. account does not yet exists. INSERT row in user table, optionally check password complexity. Add row to user app releation table in status Requested
--    if p_target_app is given
-- 2. account already exists, verify password and add row to relation table.
    l_password_ok BOOLEAN;
BEGIN
    pck_std_log.inf( 'p_user_uniq_name: '||p_user_uniq_name);
    check_or_create_credential (
     p_user_uniq_name => p_user_uniq_name
    ,p_password => p_password
    ,p_create_new => TRUE
    ,p_replace_password => FALSE
    ,po_password_ok  => l_password_ok
    ) ;


END add_access;


PROCEDURE replace_password
( p_user_uniq_name VARCHAR2
 ,p_password VARCHAR2
)
AS
    l_password_ok BOOLEAN;
BEGIN
    pck_std_log.inf( 'got here ');
    check_or_create_credential (
     p_user_uniq_name => p_user_uniq_name
    ,p_password => p_password
    ,p_create_new => FALSE
    ,p_replace_password => TRUE
    ,po_password_ok  => l_password_ok
    );
    pck_std_log.inf( ' l_password_ok: '||sys.diutil.bool_to_int( l_password_ok));

END replace_password;


FUNCTION my_sentry_basic_auth
return boolean
-- what has this one got to do with apex_cstskm__user ?
is
    c_auth_header   constant varchar2(4000) := owa_util.get_cgi_env('AUTHORIZATION');
    l_user_pass     varchar2(4000);
    l_separator_pos pls_integer;
begin
    pck_std_log.inf( 'auth_header: '||c_auth_header||' g_user: '||apex_application.g_user
            ||' g_basic_auth_done: '||sys. diutil. bool_to_int(g_basic_auth_done )
        );
    --return false;
    if apex_application.g_user <> 'nobody' then
        g_basic_auth_done := TRUE;
        pck_std_log.inf( ' g_basic_auth_done: '||sys. diutil. bool_to_int(g_basic_auth_done )
            );
        return true;
    end if;

    IF g_basic_auth_done IS NOT NULL
    THEN
        RETURN g_basic_auth_done;
    END IF;

    if c_auth_header like 'Basic %' then
            pck_std_log.inf( 'got here ');
        l_user_pass := utl_encode.text_decode (
                           buf      => substr(c_auth_header, 7),
                           encoding => utl_encode.base64 );
        pck_std_log.inf( ' l_user_pass: '||l_user_pass);
        l_separator_pos := instr(l_user_pass, ':');
        if l_separator_pos > 0 then
            pck_std_log.inf( 'got here ');
            apex_authentication.login (
                p_username => substr(l_user_pass, 1, l_separator_pos-1),
                p_password => substr(l_user_pass, l_separator_pos+1) );
            g_basic_auth_done := TRUE;
            return true;
        end if;
    end if;

    pck_std_log.inf( 'got here ');
    g_basic_auth_done := FALSE;
    return false;
end my_sentry_basic_auth;

FUNCTION my_authentication -- can be used for custom scheme
( p_username VARCHAR2
 ,p_password VARCHAR2
) RETURN BOOLEAN
AS
    l_password_ok BOOLEAN;
BEGIN
    pck_std_log.inf( 'got here ');
    check_or_create_credential (
     p_user_uniq_name => p_username
    ,p_password => p_password
    ,p_create_new => FALSE
    ,p_replace_password => FALSE
    ,po_password_ok  => l_password_ok
    );
    pck_std_log.inf( ' l_password_ok: '||sys.diutil.bool_to_int( l_password_ok));

	RETURN l_password_ok;
END my_authentication;

PROCEDURE my_invalid_session_basic_auth
is
begin
    pck_std_log.inf( 'gotz here ');

    owa_util.status_line (
        nstatus       => 401,
        creason       => 'Basic Authentication required',
        bclose_header => false);
    htp.p('WWW-Authenticate: Basic realm="protected realm"');
    apex_application.stop_apex_engine;
end my_invalid_session_basic_auth;

PROCEDURE my_post_logout
is
begin
    -- v( 'APPSESSION') is empty when we come here
    pck_std_log.inf( 'User '||v( 'APP_USER') ||' logged out from '||v( 'APP_NAME')||' session: "'|| wwv_flow.g_instance  ||'"');
    apex_session.delete_session( ); -- default to v( 'APPSESSION')
end my_post_logout;

PROCEDURE request_account
(  p_user_uniq_name               VARCHAR2
  ,p_password                     VARCHAR2
  ,p_target_app                   VARCHAR2   DEFAULT NULL
  ,p_is_new_user                  BOOLEAN    DEFAULT FALSE
) AS
/*
        This procedure will
        * if p_is_new_user is TRUE, verify that p_user_uniq_name is new indeed, add a row to APEX_CSTSKM_USER with p_password.
        * if p_is_new_user is FALSE, verify that p_password is correct.
        * add a row to the table APEX_CSTSKM_APP_ROLE_REQUEST using the most basic role of the app. This role is looked up from APEX_CSTSKM_APP_ROLE_LKUP
*/
    l_user_exists NUMBER;
    l_req_id_exist NUMBER;
    l_app_name_used apex_cstskm_app_role_request.app_name%TYPE;
    l_user_name_used VARCHAR2(100);
    l_basic_role apex_cstskm_app_role_request.role_name%TYPE;
    l_password_ok BOOLEAN;
    lt_req_id dbms_sql.number_table;
    l_dist_pw_cnt  NUMBER;
    l_acc_request_rejected  NUMBER;
BEGIN
    l_user_name_used := upper( p_user_uniq_name );
    l_app_name_used := upper( coalesce( p_target_app, v('APP_NAME')) );
    pck_std_log.inf( 'p_user_uniq_name:'|| p_user_uniq_name
        ||' p_is_new_user:'     || sys. diutil. bool_to_int(p_is_new_user)
        ||' app_name:'     || v( 'APP_NAME')
        ||' app name used:'     || l_app_name_used
        ||' user name used:'     || l_user_name_used
     );

    BEGIN
        SELECT role_name
        INTO l_basic_role
        FROM apex_cstskm_app_role_lkup
        WHERE app_name =  l_app_name_used
          AND basic_flg = 'YES'
        ;
    EXCEPTION
        WHEN no_data_found THEN
            RAISE_APPLICATION_ERROR( -20001, 'No basic role has been defined or this app does not exist: "'|| l_app_name_used ||'"');
    END;

    CASE g_auth_method
    WHEN c_auth_method_custom THEN
        SELECT count(*)
        INTO l_user_exists
        FROM apex_cstskm_user
        WHERE user_uniq_name = l_user_name_used
        ;
        pck_std_log.inf( 'user_uniq_name:'|| l_user_name_used||' exists: '|| l_user_exists);

        IF p_is_new_user
        THEN
            IF l_user_exists > 0 THEN
                RAISE_APPLICATION_ERROR( -20001, 'This custom-scheme user already exists and therefore cannot be created!');
            END IF;
            RAISE_APPLICATION_ERROR( -20001, 'not yet ready at '||$$plsql_unit||':'||$$plsql_line);

        ELSE
            IF l_user_exists > 0 THEN
                RAISE_APPLICATION_ERROR( -20001, 'This workspace user already exists and therefore cannot be created!');
            END IF;

            verify_password ( p_user_uniq_name => l_user_name_used
                , p_password => p_password
                , po_password_ok => l_password_ok
                );
            IF NOT l_password_ok
            THEN
                RAISE_APPLICATION_ERROR( -20001, 'Incorrect username or password!'||$$plsql_unit||':'||$$plsql_line);
            END IF;

            request_app_roles
            ( p_user_uniq_name => l_user_name_used
             ,p_target_app => l_app_name_used
             ,p_role_csv => l_basic_role
            );

        END IF; -- p_is_new_user

    WHEN c_auth_method_apex THEN
        SELECT count(1)
        INTO l_user_exists
        FROM apex_workspace_apex_users u
        WHERE u.user_name = l_user_name_used
        ;
        IF  p_is_new_user
        THEN
            --
            -- we also need to guard against multiple request from different apps for the same account !
            --

            IF l_user_exists > 0 THEN
                RAISE_APPLICATION_ERROR( -20001, 'This user already exists and therefore cannot be created!');
            END IF;

            -- Do not Create user account just yet, add item to request table
            --    RAISE_APPLICATION_ERROR( -20001, 'The current Authentication method is '|| g_auth_method
            --        ||', new user must be created by the workspace admin!');
            -- to fix above error, we may need a background job , but lets try it here anyway

            -- Make sure no request exist in status REJECTED
            SELECT count(1)
            INTO l_acc_request_rejected
            FROM v_app_role_request_union_all
            WHERE role_name = 'DUMMY_ROLE(REQUEST ACCOUNT)'
                AND user_name = l_user_name_used
                AND status LIKE 'REJECT%' -- fix later
            ;
            IF l_acc_request_rejected > 0
            THEN
                RAISE_APPLICATION_ERROR( -20001, 'At least one request for the given username has been rejected!');
            END IF;

            -- add the request record
            request_app_roles_return_req_ids
            ( p_user_uniq_name       => l_user_name_used
              ,p_target_app                  => l_app_name_used
              ,p_role_csv                    => cstskm_util.gc_dummy_role_for_account_request
              ,p_action                      => 'GRANT'
              ,po_out_req_id => lt_req_id
             );

            IF lt_req_id.count = 0 THEN

                RAISE_APPLICATION_ERROR( -20001, 'Oops, no request ids returned');
            END IF;
            pck_std_log.inf ( 'req_id: '|| lt_req_id(1));
            SELECT count(1)
            INTO l_req_id_exist
            FROM apex_wkspauth_acc_req_token
            WHERE req_id = lt_req_id(1)
            ;
            IF l_req_id_exist > 0
            THEN
                RAISE_APPLICATION_ERROR( -20001, 'Oops, the request id already exists!');
            END IF;
            INSERT INTO apex_wkspauth_acc_req_token
            ( req_id,   origin_app_name
             ,my_token
            ) VALUES
            ( lt_req_id(1),   l_app_name_used
            , temp_encrypted ( p_password )
            );
            SELECT COUNT(DISTINCT tok.my_token )
            INTO l_dist_pw_cnt
            FROM apex_wkspauth_app_role_request req
            JOIN apex_wkspauth_acc_req_token tok
            ON tok.req_id = req.id
            WHERE req.apex_user_name = l_user_name_used
            GROUP BY req.apex_user_name
            ;
            IF l_dist_pw_cnt > 1
            THEN
                RAISE_APPLICATION_ERROR( -20001, 'There is another account request for the same user but with a different password hash!');
            END IF;

        ELSE
            l_password_ok := APEX_UTIL.IS_LOGIN_PASSWORD_VALID
                (  p_username => l_user_name_used -- APEX workspace username is case-insensitive!
                 , p_password => p_password
                );
            IF NOT l_password_ok
            THEN
                RAISE_APPLICATION_ERROR( -20001, 'Incorrect username or password!'||$$plsql_unit||':'||$$plsql_line);
            END IF;
--            RAISE_APPLICATION_ERROR( -20001, 'not yet ready at '||$$plsql_unit||':'||$$plsql_line);

            request_app_roles
             ( p_user_uniq_name =>   l_user_name_used
              --,p_target_app =>        DEFAULT NULL
              ,p_role_csv =>    l_basic_role
             ) ;
        END IF; -- p_is_new_user
    END CASE --g_auth_method
    ;

END request_account;

PROCEDURE request_app_roles
 ( p_user_uniq_name               VARCHAR2
  ,p_target_app                   VARCHAR2        DEFAULT NULL
  ,p_role_csv                     VARCHAR2
  ,p_action                       VARCHAR2        DEFAULT 'GRANT'
 ) AS
   lt_dummy_req_id dbms_sql.number_table ;
 BEGIN
     request_app_roles_return_req_ids
     ( p_user_uniq_name               => p_user_uniq_name
      ,p_target_app                   => p_target_app
      ,p_role_csv                     => p_role_csv
      ,p_action                       => p_action
      ,po_out_req_id => lt_dummy_req_id
     ) ;
 END request_app_roles;

PROCEDURE request_app_roles_return_req_ids
 ( p_user_uniq_name               VARCHAR2
  ,p_target_app                   VARCHAR2        DEFAULT NULL
  ,p_role_csv                     VARCHAR2
  ,p_action                       VARCHAR2        DEFAULT 'GRANT'
  ,po_out_req_id        OUT    dbms_sql.number_table
 ) AS
 /*
        This procedure will  add rows in the request table for App-user-role relation in PENDING status
*/
    l_user_id apex_cstskm_user.id%TYPE;
    l_app_name_used apex_cstskm_app_role_request.app_name%TYPE := upper( coalesce( p_target_app, v('APP_NAME')) );
    l_merge_cnt NUMBER;
    l_req_id NUMBER;


BEGIN
    IF g_auth_method = c_auth_method_custom THEN
        BEGIN
            SELECT id INTO l_user_id
            FROM apex_cstskm_user
            WHERE user_uniq_name = p_user_uniq_name
            ;
        EXCEPTION
                WHEN no_data_found THEN
                    RAISE_APPLICATION_ERROR( -20001, 'User '||p_user_uniq_name||' not found in customer user table!' );
        END;
    END IF;

    pck_std_log.inf( ' MERGE using User_id:' ||l_user_id ||' p_user_uniq_name:' ||p_user_uniq_name||' roles:' ||p_role_csv ||' action:' ||p_action );
    FOR rec IN (
        SELECT column_value AS role_name
        FROM TABLE( split_by_string ( p_role_csv, ',') )
    ) LOOP
        BEGIN
            CASE
            WHEN g_auth_method = c_auth_method_apex
            THEN
                MERGE INTO apex_wkspauth_app_role_request z
                USING (
                    SELECT rec.role_name AS role_name
                        , l_app_name_used AS app_name
                        , p_user_uniq_name AS apex_user_name
                        , p_action AS action
                    FROM dual
                ) q
                ON (  q.apex_user_name = z.apex_user_name
                  AND q.app_name = z.app_name
                  AND q.role_name = z.role_name
                  AND q.action = z.action
                )
                WHEN NOT MATCHED THEN
                    INSERT ( created , created_by
                        , app_name,     role_name,   apex_user_name
                        , status, action
                    ) VALUES ( sysdate, audit_user()
                        , q.app_name, q.role_name, q.apex_user_name
                        , 'PENDING', p_action
                    )
                WHEN MATCHED THEN
                    UPDATE
                    SET updated = sysdate, updated_by = audit_user()
                    WHERE status = 'PENDING'
-- this does not compile. will have to select from the table!                RETURNING z.id INTO lt_out_req_id( lt_out_req_id.count + 1)
                ;
              SELECT id
              INTO l_req_id
              FROM apex_wkspauth_app_role_request
              WHERE role_name = rec.role_name
                AND apex_user_name = p_user_uniq_name
                AND app_name = l_app_name_used
                AND action = p_action
              ;
              pck_std_log.inf( ' MERGEd rows:' ||sql%rowcount );

              po_out_req_id( po_out_req_id.count + 1) := l_req_id;
            WHEN g_auth_method = c_auth_method_custom
            THEN
                MERGE INTO apex_cstskm_app_role_request z
                USING (
                    SELECT rec.role_name AS role_name
                        , l_app_name_used AS app_name
                        , l_user_id AS user_id
                    FROM dual
                ) q
                ON (  q.user_id = z.user_id
                  AND q.app_name = z.app_name
                  AND q.role_name = z.role_name
                )
                WHEN NOT MATCHED THEN
                    INSERT ( created , created_by
                        , app_name,     role_name,   user_id
                        , status, action
                    ) VALUES ( sysdate, audit_user()
                        , q.app_name, q.role_name, q.user_id
                        , 'PENDING', p_action
                    )
                WHEN MATCHED THEN
                    UPDATE
                    SET updated = sysdate, updated_by = audit_user()
                    WHERE status = 'PENDING'
                ;
                l_merge_cnt := sql%rowcount;
                IF l_merge_cnt = 0
                THEN
                    RAISE_APPLICATION_ERROR( -20001, 'The request could not be submitted. Maybe an equivalent request exists and has been approved or rejected?');
                END IF;
            END CASE;
        EXCEPTION
        /*
            WHEN err_parent_not_found THEN
                pck_std_log.inf( ' MERGE failed on User_id:' ||l_user_id
                    ||' app:' ||p_target_app
                    ||' role:' ||rec.role_name
                    );
                RAISE_APPLICATION_ERROR( -20001, 'Either the pair of app name and role or the beneficial user is unknown!');
                */
            WHEN OTHERS THEN
                pck_std_log.inf( ' MERGE failed on User_id:' ||l_user_id
                    ||' app:' ||p_target_app
                    ||' role:' ||rec.role_name
                    );
                pck_std_log.inf ( 'ORA-'||sqlcode||' '||dbms_utility.format_error_stack );
                RAISE;
        END;
    END LOOP;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        pck_std_log.err( a_errno=> sqlcode, a_text=>  sqlerrm ||c_nl||dbms_utility.format_call_stack);
        RAISE;
END request_app_roles_return_req_ids;


PROCEDURE set_app_roles -- this procedure is being phased out! replacements are the more granular/atomic procedures
 ( p_user_uniq_name               VARCHAR2
  ,p_target_app                   VARCHAR2
  ,p_role_csv                     VARCHAR2
  ,p_role_csv_flag                VARCHAR2
  ,p_auth                         VARCHAR2
 ) AS
 /*
        the Flag has these meanings
            INS: add roles in the CSV
            DEL: remove roles in the CSV
            UPD: replace roles with CSV. If CSV is empty, all roles are removed.
    For INS/UPD, corresponding rows in the request table will be set up APPROVED
*/
    l_user_id apex_cstskm_user.id%TYPE;
    l_apex_app_num NUMBER;
BEGIN
    pck_std_log.inf ( 'uname: '||p_user_uniq_name ||' app:'||p_target_app ||' csv:'||p_role_csv
        );
    CASE p_auth
    WHEN 'APEX'
    THEN
        SELECT
            ( SELECT DISTINCT application_id
                FROM apex_applications
                WHERE upper( application_name ) = p_target_app
            )
        INTO l_apex_app_num
            FROM dual
        ;
        IF l_apex_app_num IS NULL
        THEN
            RAISE_APPLICATION_ERROR( -20001, $$plsql_unit||': '||$$plsql_line ||'application_id could not be found!');
        END IF;
        IF p_role_csv_flag IN ( 'INS', 'DEL')
        THEN
            -- here we need to call APEX USER API methods
            -- for now no check if the call is indeed necessary
            FOR lr IN (
                SELECT column_value AS role_name
                FROM TABLE ( split_by_string (p_role_csv , ',' ) )
            ) LOOP
                pck_std_log.inf ( 'l_apex_app_num: '||l_apex_app_num ||' role_name:'||lr.role_name          );
                CASE p_role_csv_flag
                WHEN 'INS'       THEN
                    apex_acl.add_user_role
                    ( p_application_id => l_apex_app_num
                     ,p_user_name => p_user_uniq_name
                     ,p_role_static_id => lr.role_name
                    );
                WHEN 'DEL'       THEN
                    apex_acl.remove_user_role
                    ( p_application_id => l_apex_app_num
                     ,p_user_name => p_user_uniq_name
                     ,p_role_static_id => lr.role_name
                    );
                END CASE;
            END LOOP;
        ELSE
            RAISE_APPLICATION_ERROR( -20001, 'p_role_csv_flag= '||p_role_csv_flag ||' is not yet supported');
        END IF; -- action
    WHEN 'CUSTOM'
    THEN
        SELECT id
        INTO l_user_id
        FROM apex_cstskm_user
        WHERE user_uniq_name = p_user_uniq_name
        ;

        FOR lr IN (
            SELECT column_value AS role_name
            FROM TABLE ( split_by_string (p_role_csv , ',' ) )
        ) LOOP
            pck_std_log.inf ( 'l_apex_app_num: '||l_apex_app_num ||' role_name:'||lr.role_name          );
            cst_auth_app_role_action
                ( p_user_id  => l_user_id
                 ,p_target_app => p_target_app
                 ,p_role =>  lr.role_name
                 ,p_action => p_role_csv_flag
                );
        END LOOP;


    END CASE; -- authentication
EXCEPTION
    WHEN OTHERS THEN
        pck_std_log.err( a_errno=> sqlcode, a_text=> substr( sqlerrm ||' '|| 'uname: '||p_user_uniq_name ||' app:'||p_target_app ||' csv:'||p_role_csv, 1, 1000) );
        RAISE;
END set_app_roles;

/* Grant or Revoke an ACL user-role
*/
PROCEDURE apex_auth_app_role_action
( p_user_uniq_name                VARCHAR2
  ,p_app_id                       NUMBER
  ,p_role                         VARCHAR2
  ,p_action                       VARCHAR2
) AS
BEGIN
    pck_std_log.inf( ' p_user_uniq_name:'||p_user_uniq_name
        ||' p_app_id:'||p_app_id
        ||' p_role:'||p_role
        ||' p_action:'||p_action
        );
    CASE p_action
    WHEN 'GRANT'
    THEN
        IF p_role = cstskm_util.gc_dummy_role_for_account_request
        THEN
            NULL; -- nothing to do? probably the call should not come here at all
        ELSE
            apex_acl.add_user_role
                    ( p_application_id => p_app_id
                     ,p_user_name => p_user_uniq_name
                     ,p_role_static_id => p_role
                    );
        END IF;
    WHEN  'REVOKE'
    THEN
        apex_acl.remove_user_role
                ( p_application_id => p_app_id
                 ,p_user_name => p_user_uniq_name
                 ,p_role_static_id => p_role
                );
    END CASE;
EXCEPTION
    WHEN OTHERS THEN
        pck_std_log.err( a_errno=> sqlcode, a_text=>  sqlerrm ||c_nl||dbms_utility.format_call_stack );
        RAISE;
END apex_auth_app_role_action;

/* Insert or delete a user-x-app_role entry
*/
PROCEDURE cst_auth_app_role_action
( p_user_id                       NUMBER
  ,p_target_app                   VARCHAR2
  ,p_role                         VARCHAR2
  ,p_action                       VARCHAR2

) AS
BEGIN

        CASE p_action
        WHEN 'INS'
        THEN
            MERGE INTO apex_cstskm_user_x_app_role z
            USING (
                SELECT p_user_id user_id
                    , p_target_app app_name
                    , p_role AS role_name
                FROM dual
                ) q
            ON ( q.user_id = z.user_id
              AND q.app_name = z.app_name
              AND q.role_name = z.role_name
              )
            WHEN NOT MATCHED
            THEN INSERT ( user_id,   app_name,   role_name
                    ,  created_by
                    )
                VALUES ( q.user_id,   q.app_name,   q.role_name
                    , audit_user()
                    )
            ;
        WHEN 'DEL'
        THEN
            DELETE apex_cstskm_user_x_app_role
            WHERE user_id = p_user_id
              AND app_name = p_target_app
              AND role_name = p_role
              ;
            pck_std_log.inf( 'deleted: '||sql%rowcount );
        END CASE; -- action
EXCEPTION
    WHEN OTHERS THEN
        pck_std_log.err( a_errno=> sqlcode, a_text=>  sqlerrm||c_nl||dbms_utility.format_call_stack );
        RAISE;
END cst_auth_app_role_action;

PROCEDURE process_app_role_requests
    ( p_req_ids_csv VARCHAR2
     ,p_action VARCHAR2 -- GRANT or REJECT
     ,p_req_source VARCHAR2
    )
 AS
    l_distinct_user_x_app NUMBER;
    l_distinct_app NUMBER;
    l_role_csv VARCHAR2(1000);
    l_app_name v_app_role_request_union_all.app_name%TYPE;
    l_user_uniq_name v_app_role_request_union_all.user_name%TYPE;
    l_process_mode  VARCHAR2(10);
    l_encrypted_password apex_wkspauth_acc_req_token.my_token%TYPE;
BEGIN
    IF upper( p_action ) NOT IN ( 'GRANT', 'REJECT')
    THEN

        RAISE_APPLICATION_ERROR( -20001, 'p_action ' ||p_action ||' is invalid');
    END IF;

    SELECT COUNT(DISTINCT app_name ||'<#>' || user_name )
        ,  COUNT(DISTINCT app_name )
    INTO l_distinct_user_x_app
        ,l_distinct_app
    FROM v_app_role_request_union_all
    WHERE req_id IN (
        SELECT column_value as id
        FROM TABLE( split_by_string (p_req_ids_csv, ','))
        )
      AND req_source = p_req_source
      AND status = 'PENDING'
    ;
    CASE
    WHEN l_distinct_user_x_app = 0
    THEN
        RAISE_APPLICATION_ERROR ( -20001, 'It seems the request_id values are either non-existing or have improper status for this processing!');
    WHEN l_distinct_app > 1
    THEN
        RAISE_APPLICATION_ERROR ( -20001, 'FOR safety reason this procedure must not process for more than 1 app!');
    ELSE NULL;
    END CASE; -- check l_distinct_user_x_app

    -- following code just for lookup, MUST be removed later !
    SELECT listagg( req.role_name, ',') WITHIN GROUP (ORDER BY req.app_name)
        , req.app_name, req.user_name
    INTO l_role_csv
        , l_app_name, l_user_uniq_name
    FROM v_app_role_request_union_all req
    WHERE req.req_id IN (
        SELECT column_value as id
        FROM TABLE( split_by_string (p_req_ids_csv, ',')) )
      AND req_source = p_req_source
      AND status = 'PENDING'
    GROUP BY   req.app_name, req.user_name
    ;
    -- For auth mode APEX and CUSTOM , the approval translates to INS
    --                                 for reject, we are not sure yet if we should revoke the "access" when it DOES exist
    CASE WHEN p_action IN ('GRANT' , 'REVOKE' ) THEN
        set_app_roles
         ( p_user_uniq_name               => l_user_uniq_name
          ,p_target_app                   => l_app_name
          ,p_role_csv                     => l_role_csv
          ,p_role_csv_flag                =>  CASE p_action WHEN 'GRANT' THEN 'INS'   WHEN 'REVOKE' THEN 'DEL' END
          ,p_auth                => p_req_source
         ) ;
    END CASE; -- p_action

    FOR lr IN (
        SELECT app_name, user_name, role_name, req_action
            ,(select id FROM apex_cstskm_user u WHERE u.user_uniq_name = req.user_name) AS cstskm_user_id
            , req.req_id
        FROM v_app_role_request_union_all req
        WHERE req.req_id IN (
            SELECT column_value as id
            FROM TABLE( split_by_string (p_req_ids_csv, ',')) )
          AND req_source = p_req_source
          AND status = 'PENDING'
          AND req_action = CASE WHEN p_action = 'REJECT' THEN 'REVOKE' ELSE p_action END -- fixme: need to rethink about this
    ) LOOP
        CASE p_req_source
        WHEN c_auth_method_apex
        THEN

            IF lr.role_name = cstskm_util.gc_dummy_role_for_account_request
            THEN
                NULL; -- nothing to do here, special status will be updated later
            ELSE
                apex_auth_app_role_action
                ( p_user_uniq_name                => lr.user_name
                  --,p_target_app                   => lr.app_name
                  ,p_app_id                       => lr.app_name
                  ,p_role                         => lr.role_name
                  ,p_action                       => p_action
                );
            END IF;
        WHEN c_auth_method_custom
        THEN
oops( $$plsql_line )                ;

        END CASE; -- auth

        -- by now we have "delivered" on the requests, Update the request records
        CASE p_req_source
        WHEN c_auth_method_apex
        THEN
            IF lr.role_name = cstskm_util.gc_dummy_role_for_account_request
            THEN
                            -- would be good to wait and check result and update status!

                UPDATE apex_wkspauth_app_role_request
                SET status = CASE p_action
                            WHEN 'GRANT' THEN 'OK_PENDING_CREATE'
                            WHEN 'REJECT' THEN 'REJECTED'
                            END
                , updated_by = audit_user()
                , updated = sysdate
                WHERE id = lr.req_id
                ;
            ELSE
                UPDATE apex_wkspauth_app_role_request
                SET status = CASE p_action
                            WHEN 'GRANT' THEN 'APPROVED'
                            WHEN 'REJECT' THEN 'REJECTED'
                            END
                , updated_by = audit_user()
                , updated = sysdate
                WHERE id = lr.req_id
                ;
            END IF;
        WHEN c_auth_method_custom
        THEN
                UPDATE apex_cstskm_app_role_request
                SET status = CASE p_action
                            WHEN 'GRANT' THEN 'APPROVED'
                            WHEN 'REJECT' THEN 'REJECTED'
                            END
                , updated_by = audit_user()
                , updated = sysdate
                WHERE id = lr.req_id
                ;
        END CASE; -- auth

    END LOOP;

    -- COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        pck_std_log.err( a_errno=> sqlcode, a_text=>  sqlerrm ||c_nl||dbms_utility.format_call_stack);
        RAISE;
END process_app_role_requests;

FUNCTION user_has_role
( p_role_name  VARCHAR2
) RETURN BOOLEAN
AS
    l_count NUMBER;
BEGIN
    SELECT count(1) INTO l_count
    FROM apex_cstskm_user_x_app_role x
    JOIN apex_cstskm_user u ON u.user_uniq_name = upper( v('APP_USER') )
    WHERE x.role_name = p_role_name
      AND x.app_name = upper( v( 'APP_NAME') )
      AND u.user_uniq_name <> 'NOBODY'
    ;
    RETURN l_count > 0;
EXCEPTION
    WHEN OTHERS THEN
        pck_std_log.err( a_errno=> sqlcode, a_text=>  sqlerrm ||c_nl||dbms_utility.format_call_stack);
        RAISE;
END user_has_role;

PROCEDURE verify_password (
     p_user_uniq_name IN VARCHAR2
    ,p_password IN VARCHAR2
    ,po_password_ok     OUT BOOLEAN
) AS
BEGIN
    check_or_create_credential
    (p_user_uniq_name => p_user_uniq_name
    ,p_password => p_password
    ,p_create_new => FALSE
    ,p_replace_password => FALSE
    ,po_password_ok     => po_password_ok
    );
EXCEPTION
    WHEN OTHERS THEN
        pck_std_log.err( a_errno=> sqlcode, a_text=>  sqlerrm ||c_nl||dbms_utility.format_call_stack);
        RAISE;

END verify_password;

PROCEDURE submit_app_role_requests_by_json
( p_app_name VARCHAR2 DEFAULT NULL
 ,p_json     VARCHAR2
) AS
BEGIN
/* example to extract values from  a JSON array of records , demonstrating the beauty of flexible schema:

SELECT *
FROM JSON_TABLE(
      '[{a:1, b:2, x:3}, {a:4, b:5, y:6}, {a:7, bbb:8, z:9}]'
      , '$[*]'
        COLUMNS(a, b)
    );

A    B
____ ____
1    2
4    5
7

*/
    pck_std_log.inf ( 'json: '|| p_json );
    FOR rec IN (
        WITH json_data AS (
            SELECT role
                , gr AS grant_priv
                , CASE gr
                    WHEN 'Y' THEN 'GRANT'
                    WHEN 'N' THEN 'REVOKE'
                  END
                  AS action
                , app_user AS app_user
            FROM JSON_TABLE( p_json , '$[*]'
                    COLUMNS(role,  gr, app_user)
                    )
        )
        SELECT app_user , action
            ,listagg( role, ',' ) WITHIN GROUP (ORDER BY role) as role_csv
        FROM json_data
        GROUP BY app_user, action
    ) LOOP
        pck_std_log.inf ( ' role_csv: '|| rec.role_csv|| ' action: '|| rec.action|| ' app_user: '|| rec.app_user  );
        request_app_roles
                ( p_user_uniq_name       => rec.app_user
          ,p_target_app                  => p_app_name
          ,p_role_csv                    => rec.role_csv
          ,p_action                      => rec.action
         );
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        pck_std_log.err( a_errno=> sqlcode, a_text=>  sqlerrm ||c_nl||dbms_utility.format_call_stack );
        RAISE;
END submit_app_role_requests_by_json;

PROCEDURE process_app_role_requests_by_json
( p_app_name VARCHAR2 DEFAULT NULL
 ,p_json     VARCHAR2
)
AS
    l_app_id NUMBER;
BEGIN
    SELECT application_id
    INTO l_app_id
    FROM apex_applications
    WHERE upper( application_name ) = p_app_name
    ;

    pck_std_log.inf ( 'p_app_bname: '|| p_app_name|| ' json: '|| p_json );
    NULL;

    FOR rec IN (
        WITH json_data AS (
                SELECT req_id
                    , approve
                FROM JSON_TABLE( p_json , '$[*]'
                        COLUMNS( req_id, approve )
                        )
            )
        , db_x_json AS (
            SELECT
                db.app_name ,
                db.req_id,
                db.user_name           app_user             ,
                db.role_name           role             ,
                db.req_action          action             ,
                coalesce(updated_by, created_by) req_by,
                coalesce(updated, created)       req_time,
                js.approve                              js_approve,
                req_source
            FROM v_app_role_request_union_all db
            JOIN json_data js ON js.req_id = db.req_id
            WHERE  1 = 1
                AND upper(db.app_name) = p_app_name
                AND status = 'PENDING'
        )
        SELECT
              req_id, app_user , role , action , js_approve , req_source
            , CASE
                WHEN action = 'GRANT'  AND js_approve = 'Y' THEN 'GRANT'
                WHEN action = 'REVOKE' AND js_approve = 'Y' THEN 'REVOKE'
                WHEN action = 'GRANT'  AND js_approve = 'N' THEN 'NO_GRANT'
                WHEN action = 'REVOKE' AND js_approve = 'N' THEN 'NO_REVOKE'
                ELSE 'NO_ACTION'
                END AS to_do
        FROM db_x_json
    ) LOOP
        pck_std_log.inf ( ' role: '|| rec.role|| ' action: '|| rec.action|| ' app_user: '|| rec.app_user|| ' js_approve: '|| rec.js_approve  );
        CASE rec.req_source
        WHEN c_auth_method_apex
        THEN
            IF rec.to_do IN ( 'GRANT', 'REVOKE')
            THEN
                apex_auth_app_role_action(
                    p_user_uniq_name => rec.app_user
                    ,p_app_id => l_app_id
                    ,p_role => rec.role
                    ,p_action => rec.to_do
                    );
            END IF;
            UPDATE apex_wkspauth_app_role_request req
            SET status = CASE rec.to_do
                        WHEN 'GRANT'  THEN 'APPROVED'
                        WHEN 'REVOKE' THEN 'APPROVED'
                        WHEN 'NO_GRANT'  THEN 'REJECTED'
                        WHEN 'NO_REVOKE' THEN 'REJECTED'
                        END
            , updated_by = audit_user()
            , updated = sysdate
            WHERE req.id = rec.req_id
            ;
        WHEN c_auth_method_custom
        THEN
                UPDATE apex_cstskm_app_role_request        req
                SET status = CASE rec.to_do
                            WHEN 'GRANT' THEN 'APPROVED'
                            WHEN 'REJECT' THEN 'REJECTED'
                            END
                , updated_by = audit_user()
                , updated = sysdate
                WHERE req.id = rec.req_id
                ;
        END CASE;
    END LOOP;
    -- before calling process_app_role_requests, the consent Y/N must be translated to GRANT OR REJECT !


    -- COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        pck_std_log.err( a_errno=> sqlcode, a_text=>  sqlerrm ||c_nl||dbms_utility.format_call_stack );
        RAISE;

END process_app_role_requests_by_json;

FUNCTION get_dummy_app_for_account_req -- probably APEX app need this?
RETURN VARCHAR2
AS
BEGIN
    RETURN cstskm_util.gc_dummy_app_for_account_request;
END get_dummy_app_for_account_req;

PROCEDURE init
AS
BEGIN
    NULL; -- just run package body code
    dbms_output.put_line( $$plsql_unit||':'||$$plsql_line );
END init;

BEGIN
    apex_util.set_workspace( c_fixed_workspace );

END; -- PACKAGE
/

--SHOW ERRORS
REM ********** imbedding script ./lam/packages/cstskm_util-impl.sql********** 
CREATE OR REPLACE PACKAGE BODY cstskm_util
AS

FUNCTION encrypted
( string VARCHAR2
) RETURN RAW
AS
	l_key_raw RAW(128) := UTL_RAW.CAST_TO_RAW( sys_context( 'userenv', 'dbid' )  ); -- use something more secret if needed
	l_return  RAW(2000);
	l_decrypted VARCHAR2(2000);
BEGIN
		  l_return  := DBMS_CRYPTO.ENCRYPT(UTL_RAW.CAST_TO_RAW( string ), DBMS_CRYPTO.DES_CBC_PKCS5, l_key_raw);
		  -- l_decrypted := UTL_RAW.CAST_TO_VARCHAR2(DBMS_CRYPTO.DECRYPT(l_encrypted, DBMS_CRYPTO.DES_CBC_PKCS5, l_key_raw));
		  return l_return;
END encrypted;

FUNCTION decrypted
( encrypted RAW
) RETURN VARCHAR2
AS
	l_key_raw RAW(128) := UTL_RAW.CAST_TO_RAW( sys_context( 'userenv', 'dbid' )  ); -- use something more secret if needed
	l_return  VARCHAR2(2000);
BEGIN
	l_return := UTL_RAW.CAST_TO_VARCHAR2(DBMS_CRYPTO.DECRYPT( encrypted, DBMS_CRYPTO.DES_CBC_PKCS5, l_key_raw));
	RETURN l_return;
END decrypted;

--PROCEDURE cre_wrksp_user_scheduler_job
--( user_uniq_name VARCHAR2
-- ,encrypted_password RAW
--) AS
--/* create a scheduler job to run instanenously. Since create_user only works if the session runs as the workspace owner
--  An app admin clicks some button in an APEX page which eventually will run this procedure. Calling create_user from the
--  APEX session would not work!
--*/
--	--l_raw_password_as_varchar2 VARCHAR2(1000) ;
--	l_job_action VARCHAR2(32000);
--	l_job_action_template VARCHAR2(32000) :=
--    	q'{
--DECLARE
--       l_workspace_id      number;
--       l_session_user varchar2(30);
--BEGIN
--  -- returns NULL in job! l_workspace_id := apex_util.find_security_group_id (p_workspace => 'LAM');
--	SELECT workspace_id INTO l_workspace_id
--	FROM apex_workspaces
--	where workspace = 'LAM';
--  pck_std_log.inf('l_workspace_id:'|| l_workspace_id );
--  l_workspace_id := 9014456970641719;
--  SELECT username INTO l_session_user
--  FROM v$session
--  WHERE  sid = sys_context('USERENV','SID')
--  ;
--  pck_std_log.inf('l_session_user:'|| l_session_user );
--
--  apex_util.set_security_group_id (p_security_group_id => l_workspace_id);
--	apex_util.create_user ( p_user_name => '<user_name>'
--		, p_web_password => cstskm_util.decrypted( '<raw_password_as_varchar2>' )
--		);
--END;}'
--    	 ;
--BEGIN
--	-- we cannot imbed a raw value (the encrypted password) in the anonymous PLSQL block, therefore we need to convert it
--	-- to VARCHAR2
--	--l_raw_password_as_varchar2 := utl_raw.CAST_TO_VARCHAR2 (encrypted_password);
--	l_job_action := replace(
--	    	replace( l_job_action_template, '<user_name>', user_uniq_name )
--	    		, '<raw_password_as_varchar2>', encrypted_password -- l_raw_password_as_varchar2
--    		);
--	pck_std_log.inf ( $$plsql_unit||':'||$$plsql_line ||' '||l_job_action );
--  DBMS_SCHEDULER.CREATE_JOB (
--    job_name        => 'create_'||user_uniq_name,
--    job_type        => 'PLSQL_BLOCK',
--    job_action      => l_job_action,
--    start_date      => SYSTIMESTAMP,
--    repeat_interval => NULL,
--    end_date        => NULL,
--    enabled         => TRUE,
--    auto_drop         => TRUE,
--    comments        => 'create an APEX workspace user'
--  );
--END cre_wrksp_user_scheduler_job;

END;
/

PROMPT functions
REM ********** imbedding script ./lam/functions/split_by_string.sql********** 
create or replace FUNCTION split_by_string
( pi_text VARCHAR2
 ,pi_sep_str   VARCHAR2 DEFAULT '[^ ]+'
) RETURN sys.re$name_array
/* to replace the function SPLIT_BY_REGEXP which does not work when there is leading or trailing separator
*/
AS
  l_return  sys.re$name_array := sys.re$name_array();

BEGIN
/* how the hell does following code work? NOTA BENE: with leading separator, the first NULL element is returned at the end i.e. in the wrong order!
SQL> with str as ( SELECT 'Bcc,Aaaa,E,' as pi_text, ',' as pi_sep_str FROM dual )
  2  SELECT
  3      REGEXP_SUBSTR(pi_text,'[^'||pi_sep_str||']+', 1, LEVEL) COL1
  4  FROM str
  5  CONNECT BY LEVEL <= REGEXP_COUNT(pi_text, pi_sep_str) + 1
  6  ;

COL1
-----------
Bcc
Aaaa
E
NULL

4 rows selected.
*/
	CASE
	WHEN pi_sep_str IS NULL
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'separator must not be empty!');
	WHEN pi_sep_str NOT IN ( ',', ';', '#', ':' )
	THEN
		RAISE_APPLICATION_ERROR( -20001, 'Currently only some basic simple separator is supported. RE special character is not allowed!');
	ELSE
		NULL;
	END CASE;
	FOR rec IN (
		SELECT
		    REGEXP_SUBSTR(pi_text,'[^'||pi_sep_str||']+', 1, LEVEL) tok
		FROM dual
		CONNECT BY LEVEL <= REGEXP_COUNT(pi_text, pi_sep_str) + 1
	) LOOP
		l_return.extend();
		l_return( l_return.count) := rec.tok;
	END LOOP;

	RETURN l_return;
END;
/
show errors

PROMPT procedures
REM ********** imbedding script ./lam/procedures/enforce_strong_password.sql********** 
CREATE OR REPLACE PROCEDURE enforce_strong_password
(   p_username VARCHAR2
   ,p_new_password VARCHAR2
   ,p_old_password VARCHAR2
   ,po_errors OUT VARCHAR2
)
AS
    l_username                    VARCHAR2(30);
    l_new_password                VARCHAR2(30);
    l_old_password                VARCHAR2(30);
    l_workspace_name              VARCHAR2(30);
    l_min_length_err              BOOLEAN;
    l_new_differs_by_err          BOOLEAN;
    l_one_alpha_err               BOOLEAN;
    l_one_numeric_err             BOOLEAN;
    l_one_punctuation_err         BOOLEAN;
    l_one_upper_err               BOOLEAN;
    l_one_lower_err               BOOLEAN;
    l_not_like_username_err       BOOLEAN;
    l_not_like_workspace_name_err BOOLEAN;
    l_not_like_words_err          BOOLEAN;
    l_not_reusable_err            BOOLEAN;
    l_password_history_days       pls_integer;

    PROCEDURE add_error ( p_error VARCHAR2)
    AS
    BEGIN
        po_errors := coalesce( po_errors, 'Following error(s) occured: ' )
            ||chr(10)||'* '||p_error;
    END add_error;

BEGIN
    l_username := p_username;
    l_new_password := p_new_password;
    l_old_password := p_old_password;
    l_workspace_name := 'XYX_WS';
    l_password_history_days := 0;
        -- apex_instance_admin.get_parameter ('PASSWORD_HISTORY_DAYS');

    APEX_UTIL.STRONG_PASSWORD_CHECK(
        p_username                    => l_username,
        p_password                    => l_new_password,
        p_old_password                => l_old_password,
        p_workspace_name              => l_workspace_name,
        p_use_strong_rules            => false,
        p_min_length_err              => l_min_length_err,
        p_new_differs_by_err          => l_new_differs_by_err,
        p_one_alpha_err               => l_one_alpha_err,
        p_one_numeric_err             => l_one_numeric_err,
        p_one_punctuation_err         => l_one_punctuation_err,
        p_one_upper_err               => l_one_upper_err,
        p_one_lower_err               => l_one_lower_err,
        p_not_like_username_err       => l_not_like_username_err,
        p_not_like_workspace_name_err => l_not_like_workspace_name_err,
        p_not_like_words_err          => l_not_like_words_err,
        p_not_reusable_err            => l_not_reusable_err);

    IF l_min_length_err THEN
        add_error('Password is too short');
    END IF;

    IF l_new_differs_by_err THEN
        add_error('Password is too similar to the old password');
    END IF;

    IF l_one_alpha_err THEN
        add_error('Password must contain at least one alphabetic character');
    END IF;

    IF l_one_numeric_err THEN
        add_error('Password  must contain at least one numeric character');
    END IF;

    IF l_one_punctuation_err THEN
        add_error('Password  must contain at least one punctuation character');
    END IF;

    IF l_one_upper_err THEN
        add_error('Password must contain at least one upper-case character');
    END IF;

    IF l_one_lower_err THEN
        add_error('Password must contain at least one lower-case character');
    END IF;

    IF l_not_like_username_err THEN
        add_error('Password may not contain the username');
    END IF;

    IF l_not_like_workspace_name_err THEN
        add_error('Password may not contain the workspace name');
    END IF;

    IF l_not_like_words_err THEN
        add_error('Password contains one or more prohibited common words');
    END IF;

    IF l_not_reusable_err THEN
        add_error('Password cannot be used because it has been used for the account within the last '||l_password_history_days||' days.');
    END IF;
END;
/

show errors
REM ********** imbedding script ./lam/procedures/loop_create_user_reqs.sql********** 
CREATE OR REPLACE PROCEDURE loop_create_user_reqs
AS
/* NOt in a package because we would need to stop and resume (or worse drop and recreate)
* the job each time we need to compile this procedure
*
*/

       l_workspace_id      number;
       l_session_user varchar2(30);
BEGIN
	SELECT workspace_id INTO l_workspace_id
	FROM apex_workspaces
	where workspace = 'LAM';
  pck_std_log.inf('l_workspace_id:'|| l_workspace_id );
  l_session_user := sys_context( 'USERENV', 'session_user');
  pck_std_log.inf('l_session_user:'|| l_session_user );

  apex_util.set_security_group_id (p_security_group_id => l_workspace_id);
  -- loop over create-user-requests in status OK_PENDING_CREATE
  FOR lr_req IN (
              SELECT req.id AS req_id
                , req.apex_user_name
                , tok.my_token
              FROM apex_wkspauth_app_role_request req
              JOIN apex_wkspauth_acc_req_token tok ON ( tok.req_id = req.id )
              LEFT JOIN APEX_WORKSPACE_APEX_USERS wu ON wu.user_name = req.apex_user_name -- Workspace name ignored for now!
              WHERE req.role_name = cstskm_util. gc_dummy_role_for_account_request
                AND req.status = 'OK_PENDING_CREATE'
                AND wu.user_name IS NULL
  	)
  LOOP
  pck_std_log.inf('lr_req.apex_user_name:'|| lr_req.apex_user_name );
  	apex_util.create_user ( p_user_name => lr_req.apex_user_name
  		, p_web_password => cstskm_util.decrypted( lr_req.my_token )
  		);
    UPDATE apex_wkspauth_app_role_request
    SET status = 'APPROVED'
    WHERE id = lr_req.req_id
    ;
    COMMIT;
  -- add an error handler.
  END LOOP;

END;
/

show errors
REM ********** imbedding script ./lam/procedures/pymail_send.sql********** 
import json
import smtplib
from email.mime.text import MIMEText

def send_email(metadata, content):
    # Replace these values with your actual IMAP server settings
    smtp_server = 'your_smtp_server'
    smtp_port = 587  # or the appropriate port for your SMTP server
    smtp_username = 'your_smtp_username'
    smtp_password = 'your_smtp_password'

    # Prepare the email message
    msg = MIMEText(content)
    msg['Subject'] = metadata["subject"]
    msg['From'] = metadata["from"]
    msg['To'] = metadata["to"]

    try:
        # Connect to the SMTP server and send the email
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()  # Use TLS encryption
            server.login(smtp_username, smtp_password)
            server.send_message(msg)

        print("Email sent successfully.")
    except Exception as e:
        print("Failed to send the email:", str(e))

""" example json
{
  "metadata": {
    "to": "recipient@example.com",
    "from": "sender@example.com",
    "subject": "Test Email"
  },
  "content": "This is the email content."
}

"""
if __name__ == "__main__":
    with open("email_data.json") as json_file:
        data = json.load(json_file)
        metadata = data["metadata"]
        content = data["content"]

        send_email(metadata, content)
REM ********** imbedding script ./lam/procedures/cre_job_add_wrksp_user.sql********** 
-- maybe not needed after all
REM ********** imbedding script ./lam/procedures/change_app_user_pwd.sql********** 
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

PROMPT views
REM ********** imbedding script ./lam/views/v_acl_user_x_role_cartesian.sql********** 
CREATE OR REPLACE VIEW v_acl_user_x_role_cartesian
AS
select ro.workspace_id, ro.workspace workspace_name
	, u.application_id app_num
    , u.application_name, u.user_name
    , ro.role_static_id role_name
,( select count(1)
	from APEX_APPL_ACL_USER_ROLES x
	where x.application_name = u.application_name AND x.role_static_id = ro.role_static_id AND x.user_name = u.user_name )
	AS role_granted
FROM APEX_APPL_ACL_USERS u JOIN APEX_APPL_ACL_ROLES ro
ON ro.application_name = u.application_name
;
REM ********** imbedding script ./lam/views/v_app_role_request_union_all.sql********** 
CREATE OR REPLACE VIEW v_app_role_request_union_all AS
SELECT
	'?' req_source
	, 0 AS req_id
	,'?' app_name
	,'?' user_name
	,'?' role_name
	,'?' status
	,sysdate created
	,'?' created_by
	,sysdate updated
	,'?' updated_by
	,'?' req_action
FROM dual WHERE 1=0
UNION ALL
SELECT
	'CUSTOM'
	,req_id
	 , app_name
	,  user_uniq_name
	, role_name
	,  req_status
	, req_created
	,  req_created_by
	, req_updated
	, req_updated_by
	, req_action
FROM v_apex_cstskm_app_role_request
WHERE 1=1
UNION ALL
SELECT
	'APEX'
	,id
	 ,	app_name
	,  apex_user_name
	, role_name
	,  status
	, created
	,  created_by
	, updated
	,  updated_by
	, action
FROM apex_wkspauth_app_role_request
WHERE 1=1
;
REM ********** imbedding script ./lam/views/v_apex_cstskm_app_role_request.sql********** 
CREATE OR REPLACE VIEW v_apex_cstskm_app_role_request
AS
SELECT
	req.id req_id
	,u.id user_id
	,u.user_uniq_name
	,req.app_name
	,req.role_name
	,req.status req_status
	,req.created req_created
	,req.created_by req_created_by
	,req.updated req_updated
	,req.updated_by req_updated_by
	,req.action req_action
FROM apex_cstskm_app_role_request req
JOIN apex_cstskm_user u ON u.id = req.user_id
;

PROMPT jobs
REM ********** imbedding script ./lam/jobs/acc_req_looper_job.sql********** 
BEGIN
  -- Create the job
  DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'acc_req_looper_job',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN loop_create_user_reqs(); END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY;BYHOUR=1;BYMINUTE=0;BYSECOND=0',
    enabled         => false
  );

  -- to show how to change the scheduler - Set the job to run at 1 pm as well
  DBMS_SCHEDULER.SET_ATTRIBUTE(
    name     => 'acc_req_looper_job',
    attribute => 'repeat_interval',
    value    => 'FREQ=DAILY;BYHOUR=1,13;BYMINUTE=0;BYSECOND=0'
  );

  -- Enable the job
  DBMS_SCHEDULER.ENABLE('acc_req_looper_job');
END;
/
REM ********** imbedding script ./lam/jobs/loop_create_user_reqs.sql********** 
-- this file can be deleted. what we need is a script to create the job which will run the loop procedure!
REM ********** imbedding script ./lam/jobs/acc_req_looper_job_autodrop.sql********** 
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

PROMPT compiling invalid objects
exec dbms_utility.compile_schema( user, FALSE);

SELECT systimestamp, object_name, object_type, status
FROM user_objects
WHERE status != 'VALID'
ORDER BY  object_name, object_type
;
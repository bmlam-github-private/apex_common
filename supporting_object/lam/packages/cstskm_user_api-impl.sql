CREATE OR REPLACE PACKAGE BODY cstskm_user_api
AS
    g_basic_auth_done BOOLEAN;
    c_nl CONSTANT VARCHAR2(10) := chr(10);
    gc_dummy_app_for_account_request VARCHAR2(100) := 'DUMMY_APP(REQUEST ACCOUNT)';
    gc_dummy_role_for_account_request  VARCHAR2(100) := 'DUMMY_ROLE(REQUEST ACCOUNT)';

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
    l_dist_pw_cnt NUMBER; 
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

            request_app_roles_return_req_ids
            ( p_user_uniq_name       => l_user_name_used
              ,p_target_app                  => l_app_name_used
              ,p_role_csv                    => gc_dummy_role_for_account_request
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
        apex_acl.add_user_role
                ( p_application_id => p_app_id 
                 ,p_user_name => p_user_uniq_name
                 ,p_role_static_id => p_role 
                );
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
            apex_auth_app_role_action
            ( p_user_uniq_name                => lr.user_name
              --,p_target_app                   => lr.app_name
              ,p_app_id                       => lr.app_name
              ,p_role                         => lr.role_name
              ,p_action                       => p_action 
            );
        WHEN c_auth_method_custom
        THEN 
oops( $$plsql_line )                ;
/*cst_auth_app_role_action
( p_user_id                       NUMBER
  ,p_target_app                   VARCHAR2
  ,p_role                         VARCHAR2
  ,p_action                       VARCHAR2
  );
  */
        END CASE; -- auth  
    END LOOP;

    -- by now we have "delivered" on the requests, Update the request records 
    CASE p_req_source
    WHEN c_auth_method_apex
    THEN 
            UPDATE apex_wkspauth_app_role_request 
            SET status = CASE p_action 
                        WHEN 'GRANT' THEN 'APPROVED'
                        WHEN 'REJECT' THEN 'REJECTED'
                        END
            , updated_by = audit_user()   
            , updated = sysdate
            WHERE id IN ( 
                SELECT column_value as id 
                FROM TABLE( split_by_string (p_req_ids_csv, ',')) 
                )
            ;
    WHEN c_auth_method_custom
    THEN 
            UPDATE apex_cstskm_app_role_request 
            SET status = CASE p_action 
                        WHEN 'GRANT' THEN 'APPROVED'
                        WHEN 'REJECT' THEN 'REJECTED'
                        END
            , updated_by = audit_user()   
            , updated = sysdate
            WHERE id IN ( 
                SELECT column_value as id 
                FROM TABLE( split_by_string (p_req_ids_csv, ',')) 
                )
            ;
    END CASE; -- auth  
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

PROCEDURE process_wrksp_account_req_by_job 
( p_user_uniq_name VARCHAR2
 ,p_web_password_encrypted   VARCHAR2 
 ,p_request_id NUMBER 
) /* create the scheduler job which will call APEX_UTIL.create_user 
* will busy await a bit to check if the job has updated the request status 
*/
AS 
    l_plsql_block VARCHAR2(10000) := 
    q'[ DECLARE
             l_workspace_id      number;
         BEGIN
             l_workspace_id := apex_util.find_security_group_id (p_workspace => 'LAM');
             apex_util.set_security_group_id (p_security_group_id => l_workspace_id);    
             apex_util.create_user ( p_user_name => 'TEST_2023_03_01', p_web_password => 'silly-password' );
         end;
    ]'; 
BEGIN   
    l_plsql_block := 'not yet ready';
    dbms_scheduler.create_job (
            job_name           =>  'CRE_WRKSP_ACCOUNT_'||to_char( systimestamp ),
            job_type           =>  'PLSQL_BLOCK',
            job_action         =>  
               q'{
         }'
            ,
            start_date         =>  sysdate,
            repeat_interval    =>  NULL,
            enabled            =>  TRUE);

END process_wrksp_account_req_by_job;

PROCEDURE create_wrkspc_account_for_req 
( p_user_uniq_name VARCHAR2
 ,p_web_password_encrypted   VARCHAR2 
 ,p_request_id NUMBER 
) /* call APEX_UTIL.create_user and update the request status 
*/
AS 
    l_workspace_id      number;
    l_success BOOLEAN := TRUE;
    BEGIN
             l_workspace_id := apex_util.find_security_group_id (p_workspace => 'LAM');
             apex_util.set_security_group_id (p_security_group_id => l_workspace_id);    

    FOR rec IN (
            SELECT id 
            FROM apex_wkspauth_app_role_request
            WHERE id = p_request_id
        ) LOOP 
            BEGIN 
                apex_util.create_user ( p_user_name => p_user_uniq_name, p_web_password => p_web_password_encrypted );
             -- 
            EXCEPTION
            WHEN others THEN 
                l_success := FALSE;
            END;

--            UPDATE apex_wkspauth_app_role_request 
--          SET status = CASE l_success WHEN TRUE 
    END LOOP;
END create_wrkspc_account_for_req;

FUNCTION get_dummy_app_for_account_req 
RETURN VARCHAR2
AS 
BEGIN
    RETURN gc_dummy_app_for_account_request;
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

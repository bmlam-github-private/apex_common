CREATE OR REPLACE PACKAGE BODY cstskm_user_api
AS
    g_basic_auth_done BOOLEAN;

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

g_auth_method VARCHAR2(10) := c_auth_method_apex; -- should be retreived from APEX! 


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
    l_app_name_used apex_cstskm_app_role_request.app_name%TYPE;
    l_user_name_used VARCHAR2(100);
    l_basic_role apex_cstskm_app_role_request.role_name%TYPE;
    l_password_ok BOOLEAN;
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
            IF l_user_exists > 0 THEN 
                RAISE_APPLICATION_ERROR( -20001, 'This user already exists and therefore cannot be created!');
            END IF;

            -- Create user account 
                RAISE_APPLICATION_ERROR( -20001, 'The current Authentication method is '|| g_auth_method
                    ||', new user must be created by the workspace admin!');
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
 ) AS 
 /*
        This procedure will  add rows in the request table for App-user-role relation in PENDING status 
*/
    l_user_id apex_cstskm_user.id%TYPE;
    l_app_name_used apex_cstskm_app_role_request.app_name%TYPE := upper( coalesce( p_target_app, v('APP_NAME')) );
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

    pck_std_log.inf( ' MERGE using User_id:' ||l_user_id ||' roles:' ||p_role_csv );
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
                    FROM dual
                ) q
                ON (  q.apex_user_name = z.apex_user_name
                  AND q.app_name = z.app_name
                  AND q.role_name = z.role_name
                )
                WHEN NOT MATCHED THEN 
                    INSERT ( created , created_by 
                        , app_name,     role_name,   apex_user_name 
                        , status
                    ) VALUES ( sysdate, audit_user()
                        , q.app_name, q.role_name, q.apex_user_name  
                        , 'PENDING'
                    )
                WHEN MATCHED THEN 
                    UPDATE 
                    SET updated = sysdate, updated_by = audit_user()
                    WHERE status = 'PENDING'
                ;
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
                        , status
                    ) VALUES ( sysdate, audit_user()
                        , q.app_name, q.role_name, q.user_id 
                        , 'PENDING'
                    )
                WHEN MATCHED THEN 
                    UPDATE 
                    SET updated = sysdate, updated_by = audit_user()
                    WHERE status = 'PENDING'
                ;
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
END request_app_roles;

   
PROCEDURE set_app_roles
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
BEGIN
    pck_std_log.inf ( 'uname: '||p_user_uniq_name ||' app:'||p_target_app ||' csv:'||p_role_csv 
        );
    CASE p_auth
    WHEN 'APEX'
    THEN 
        SELECT DISTINCT application_id
        INTO l_apex_app_num
        FROM APEX_APPL_ACL_USER_ROLES -- we should replace this view with something more consolidated
        WHERE upper( application_name = p_target_app )
        ;
        CASE p_role_csv_flag
        WHEN 'INS'
        THEN 
            -- here we need to call APEX USER API methods 
            -- for now no check if the call is indeed necessary
            FOR lr IN (                    
                SELECT column_value AS role_name
                FROM TABLE ( split_by_string (p_role_csv , ',' ) ) 
            ) LOOP 
                apex_acl.add_user_role
                ( p_application_id => l_apex_app_num
                 ,p_user_name => p_user_uniq_name
                 ,p_role_static_id => lr.role_name
                );
            END LOOP;
        WHEN 'UPD'
        THEN 
            RAISE_APPLICATION_ERROR( -20001, 'p_role_csv_flag= '||p_role_csv_flag ||' is not yet supported');
        WHEN 'DEL'
        THEN 
            RAISE_APPLICATION_ERROR( -20001, 'p_role_csv_flag= '||p_role_csv_flag ||' is not yet supported');
        END CASE; -- action
    WHEN 'CUSTOM'
    THEN 
        SELECT id
        INTO l_user_id
        FROM apex_cstskm_user
        WHERE user_uniq_name = p_user_uniq_name
        ;
        CASE p_role_csv_flag
        WHEN 'INS'
        THEN 
            MERGE INTO apex_cstskm_user_x_app_role z
            USING (
                SELECT l_user_id user_id
                    , p_target_app app_name
                    , column_value AS role_name
                FROM TABLE ( split_by_string (p_role_csv , ',' ) ) 
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
        WHEN 'UPD'
        THEN 
            RAISE_APPLICATION_ERROR( -20001, 'p_role_csv_flag= '||p_role_csv_flag ||' is not yet supported');
        WHEN 'DEL'
        THEN 
            RAISE_APPLICATION_ERROR( -20001, 'p_role_csv_flag= '||p_role_csv_flag ||' is not yet supported');
        END CASE; -- action
    END CASE; -- authentication 
END set_app_roles;

PROCEDURE process_app_role_requests
    ( p_req_ids_csv VARCHAR2 
     ,p_action VARCHAR2 -- GRANT or REJECT 
     ,p_req_source VARCHAR2 
    )
 AS
    l_distinct_user_x_app NUMBER;
    l_role_csv VARCHAR2(1000);
    l_app_name apex_cstskm_user_x_app_role.app_name%TYPE; 
    l_user_uniq_name apex_cstskm_user.user_uniq_name%TYPE; 
    l_process_mode  VARCHAR2(10);
BEGIN   
    IF upper( p_action ) NOT IN ( 'GRANT', 'REJECT')
    THEN 

        RAISE_APPLICATION_ERROR( -20001, 'p_action ' ||p_action ||' is invalid');
    END IF;

    SELECT COUNT(DISTINCT app_name ||'<#>' || user_id )
    INTO l_distinct_user_x_app
    FROM apex_cstskm_app_role_request
    WHERE id IN ( 
        SELECT column_value as id 
        FROM TABLE( split_by_string (p_req_ids_csv, ',')) 
        )
        AND status = 'PENDING'
    ;
    IF l_distinct_user_x_app > 1 
    THEN 
        RAISE_APPLICATION_ERROR ( -20001, 'FOR safety reason this procedure must not process for more than 1 app and 1 user!');
    END IF; -- check l_distinct_user_x_app

    SELECT listagg( req.role_name, ',') WITHIN GROUP (ORDER BY req.app_name)
        , req.app_name, req.user_name
    INTO l_role_csv
        , l_app_name, l_user_uniq_name
    FROM v_app_role_request_union_all req
    WHERE req.req_id IN ( 
        SELECT column_value as id 
        FROM TABLE( split_by_string (p_req_ids_csv, ',')) )
      AND req_source = p_req_source
    GROUP BY   req.app_name, req.user_name
    ;
    l_process_mode :=
        CASE upper( p_action )
        WHEN 'GRANT'
        THEN 'INS'
        WHEN 'REJECT'
        THEN 'DEL'
        END ;
    set_app_roles
     ( p_user_uniq_name               => l_user_uniq_name                     
      ,p_target_app                   => l_app_name                          
      ,p_role_csv                     => l_role_csv
      ,p_role_csv_flag                => l_process_mode                   
     ) ;
    CASE p_action 
    WHEN 'GRANT'
    THEN 
        UPDATE apex_cstskm_app_role_request 
        SET status = 'APPROVED'
        , updated_by = audit_user()   
        , updated = sysdate
        WHERE id IN ( 
            SELECT column_value as id 
            FROM TABLE( split_by_string (p_req_ids_csv, ',')) 
            )
        ;
    WHEN 'REJECT'
    THEN 
        DELETE apex_cstskm_app_role_request 
        WHERE id IN ( 
            SELECT column_value as id 
            FROM TABLE( split_by_string (p_req_ids_csv, ',')) 
            )
        ;
    END CASE;
    -- delete rows from request table !!! 
     -- COMMIT; 
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

END verify_password;


END; -- PACKAGE 
/

SHOW ERRORS 

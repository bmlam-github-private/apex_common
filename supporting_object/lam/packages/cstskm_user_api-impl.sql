CREATE OR REPLACE PACKAGE BODY cstskm_user_api
AS
    g_basic_auth_done BOOLEAN;

/* common internal routine which which can both
   1. compute the hash based for given new usernamne and password to add a new user entry
   2. validates the given password against the username
*/
PROCEDURE check_or_create_credential (
     p_user_uniq_name IN VARCHAR2
    ,p_password IN VARCHAR2 
    ,p_create_new IN BOOLEAN 
    ,p_replace_password IN BOOLEAN 
    ,po_password_ok     OUT BOOLEAN 
) AS
    l_user apex_cstskm_user.user_uniq_name%type := trim( upper(p_user_uniq_name) );
    l_id   apex_cstskm_user.id%type;
    l_hash_computed apex_cstskm_user.hashed%type;
    l_hash_retrieved apex_cstskm_user.hashed%type;
BEGIN
    pck_std_log.inf( 'p_user_uniq_name: '||p_user_uniq_name
        ||' p_create_new: '||sys.diutil.bool_to_int( p_create_new)
        ||' p_replace_password: '||sys.diutil.bool_to_int( p_replace_password)
        );
    pck_std_log.inf( 'p_password: '||p_password);

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
                , coalesce( V('APP_USER'), user )
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
    if apex_application.g_user <> 'nobody' then
        g_basic_auth_done := TRUE;
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
    pck_std_log.inf( 'User '||v( 'APP_USER') ||' logged out from '||v( 'APP_NAME')||' session '||v( 'APPSESSION'));
end my_post_logout;

END; -- PACKAGE 
/

SHOW ERRORS 

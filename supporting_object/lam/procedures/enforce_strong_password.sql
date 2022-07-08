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
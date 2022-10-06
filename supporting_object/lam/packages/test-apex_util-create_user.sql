DEF pi_user_name=&1

DELCARE

BEGIN 

HTMLDB_UTIL.CREATE_USER( 
--P_USER_ID=> '&pi_user_name' --IN is defaulted 
 P_USER_NAME=> '&pi_user_name' --IN
-- ,P_FIRST_NAME=> P_FIRST_NAME --IN is defaulted 
-- ,P_LAST_NAME=> P_LAST_NAME --IN is defaulted 
-- ,P_DESCRIPTION=> P_DESCRIPTION --IN is defaulted 
-- ,P_EMAIL_ADDRESS=> P_EMAIL_ADDRESS --IN is defaulted 
 ,P_WEB_PASSWORD=> '&pi_user_name'||'_secret' --IN
-- ,P_WEB_PASSWORD_FORMAT=> P_WEB_PASSWORD_FORMAT --IN is defaulted 
-- ,P_GROUP_IDS=> P_GROUP_IDS --IN is defaulted 
-- ,P_DEVELOPER_PRIVS=> P_DEVELOPER_PRIVS --IN is defaulted 
-- ,P_DEFAULT_SCHEMA=> P_DEFAULT_SCHEMA --IN is defaulted 
-- ,P_DEFAULT_DATE_FORMAT=> P_DEFAULT_DATE_FORMAT --IN is defaulted 
-- ,P_ALLOW_ACCESS_TO_SCHEMAS=> P_ALLOW_ACCESS_TO_SCHEMAS --IN is defaulted 
 ,P_ACCOUNT_EXPIRY=> sysdate + 100 --IN is defaulted 
 ,P_ACCOUNT_LOCKED=> 'N' --IN is defaulted 
-- ,P_FAILED_ACCESS_ATTEMPTS=> P_FAILED_ACCESS_ATTEMPTS --IN is defaulted 
 ,P_CHANGE_PASSWORD_ON_FIRST_USE=> 'N' --IN is defaulted 
-- ,P_FIRST_PASSWORD_USE_OCCURRED=> P_FIRST_PASSWORD_USE_OCCURRED --IN is defaulted 
-- ,P_ATTRIBUTE_01=> P_ATTRIBUTE_01 --IN is defaulted 
-- ,P_ATTRIBUTE_02=> P_ATTRIBUTE_02 --IN is defaulted 
-- ,P_ATTRIBUTE_03=> P_ATTRIBUTE_03 --IN is defaulted 
-- ,P_ATTRIBUTE_04=> P_ATTRIBUTE_04 --IN is defaulted 
-- ,P_ATTRIBUTE_05=> P_ATTRIBUTE_05 --IN is defaulted 
-- ,P_ATTRIBUTE_06=> P_ATTRIBUTE_06 --IN is defaulted 
-- ,P_ATTRIBUTE_07=> P_ATTRIBUTE_07 --IN is defaulted 
-- ,P_ATTRIBUTE_08=> P_ATTRIBUTE_08 --IN is defaulted 
-- ,P_ATTRIBUTE_09=> P_ATTRIBUTE_09 --IN is defaulted 
-- ,P_ATTRIBUTE_10=> P_ATTRIBUTE_10 --IN is defaulted 
-- ,P_ALLOW_APP_BUILDING_YN=> P_ALLOW_APP_BUILDING_YN --IN is defaulted 
-- ,P_ALLOW_SQL_WORKSHOP_YN=> P_ALLOW_SQL_WORKSHOP_YN --IN is defaulted 
-- ,P_ALLOW_WEBSHEET_DEV_YN=> P_ALLOW_WEBSHEET_DEV_YN --IN is defaulted 
	);
END;
/

prompt COMMIT if ok
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

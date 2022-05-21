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

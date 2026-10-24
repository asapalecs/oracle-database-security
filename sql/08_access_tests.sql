DEFINE db = localhost/FREEPDB1

CONNECT u_fin/"Fin#2026"@&db
SET SERVEROUTPUT ON
PROMPT u_fin: salariu prin procedura (permis)
DECLARE
  v_sal VARCHAR2(200);
  v_bon VARCHAR2(200);
BEGIN
  dev_dba.afiseaza_salariu_bonus(1, v_sal, v_bon);
  DBMS_OUTPUT.PUT_LINE('salariu=' || v_sal || ' bonus=' || v_bon);
END;
/
PROMPT u_fin: date medicale (refuzat)
DECLARE
  v_med VARCHAR2(400);
BEGIN
  dev_dba.afiseaza_medical(1, v_med);
END;
/

CONNECT u_med/"Med#2026"@&db
SET SERVEROUTPUT ON
PROMPT u_med: date medicale prin procedura (permis)
DECLARE
  v_med VARCHAR2(400);
BEGIN
  dev_dba.afiseaza_medical(4, v_med);
  DBMS_OUTPUT.PUT_LINE('medical=' || v_med);
END;
/
PROMPT u_med: contracte (refuzat)
SELECT COUNT(*) FROM dev_dba.contract;

CONNECT u_ant/"Ant#2026"@&db
SET SERVEROUTPUT ON
PROMPT u_ant: view mascat (permis)
SELECT nume, nr_tricou, telefon_mascat, medical_mascat FROM dev_dba.v_jucatori_mascati WHERE ROWNUM <= 3;
PROMPT u_ant: tabela jucator (refuzat)
SELECT COUNT(*) FROM dev_dba.jucator;
PROMPT u_ant: contracte (refuzat)
SELECT COUNT(*) FROM dev_dba.contract;
PROMPT u_ant: decriptare salariu (refuzat)
DECLARE
  v_sal VARCHAR2(200);
  v_bon VARCHAR2(200);
BEGIN
  dev_dba.afiseaza_salariu_bonus(1, v_sal, v_bon);
END;
/
PROMPT u_ant: tabela cu chei (refuzat)
SELECT COUNT(*) FROM dev_dba.crypto_keys;

CONNECT u_admin/"Admin#2026"@&db
SET SERVEROUTPUT ON
PROMPT u_admin: salariu si medical (permis prin ierarhia de roluri)
DECLARE
  v_sal VARCHAR2(200);
  v_bon VARCHAR2(200);
  v_med VARCHAR2(400);
BEGIN
  dev_dba.afiseaza_salariu_bonus(1, v_sal, v_bon);
  dev_dba.afiseaza_medical(4, v_med);
  DBMS_OUTPUT.PUT_LINE('salariu=' || v_sal || ' medical=' || v_med);
END;
/

CONNECT dev_dba/"Dev#2026"@&db
SET SERVEROUTPUT ON
PROMPT citiri auditate prin FGA, pe utilizator
SELECT dbusername, fga_policy_name, COUNT(*) AS citiri
FROM unified_audit_trail
WHERE audit_type = 'FineGrainedAudit'
GROUP BY dbusername, fga_policy_name
ORDER BY dbusername, fga_policy_name;

GRANT SELECT, INSERT, UPDATE, DELETE ON jucator  TO rol_admin_barca;
GRANT SELECT, INSERT, UPDATE, DELETE ON contract TO rol_admin_barca;
GRANT SELECT, INSERT, UPDATE, DELETE ON meci     TO rol_admin_barca;
GRANT SELECT ON staff     TO rol_admin_barca;
GRANT SELECT ON audit_log TO rol_admin_barca;

GRANT SELECT ON jucator TO rol_financiar_barca;
GRANT SELECT, INSERT, UPDATE, DELETE ON contract TO rol_financiar_barca;
GRANT SELECT ON staff TO rol_financiar_barca;
GRANT SELECT ON meci  TO rol_financiar_barca;

GRANT SELECT ON staff TO rol_antrenor_barca;
GRANT SELECT, INSERT, UPDATE, DELETE ON meci TO rol_antrenor_barca;

GRANT SELECT ON jucator TO rol_medic_barca;
GRANT SELECT ON staff   TO rol_medic_barca;
GRANT SELECT ON meci    TO rol_medic_barca;

CREATE OR REPLACE PROCEDURE afiseaza_salariu_bonus (
    p_id_contract IN  NUMBER,
    p_salariu     OUT VARCHAR2,
    p_bonus       OUT VARCHAR2
)
IS
    v_sal_raw   RAW(256);
    v_bonus_raw RAW(256);
BEGIN
    SELECT salariu_criptat, bonus_criptat
    INTO v_sal_raw, v_bonus_raw
    FROM contract
    WHERE id_contract = p_id_contract;

    decriptare(v_sal_raw, p_salariu);
    decriptare(v_bonus_raw, p_bonus);
END;
/

CREATE OR REPLACE PROCEDURE afiseaza_medical (
    p_id_jucator IN  NUMBER,
    p_medical    OUT VARCHAR2
)
IS
    v_med_raw RAW(512);
BEGIN
    SELECT observatii_medicale_criptat
    INTO v_med_raw
    FROM jucator
    WHERE id_jucator = p_id_jucator;

    decriptare(v_med_raw, p_medical);
END;
/

GRANT EXECUTE ON afiseaza_salariu_bonus TO rol_financiar_barca;
GRANT EXECUTE ON afiseaza_medical       TO rol_medic_barca;

SELECT grantee, table_name, privilege
FROM user_tab_privs_made
ORDER BY grantee, table_name, privilege;

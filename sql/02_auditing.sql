CREATE AUDIT POLICY pol_barca_logon ACTIONS LOGON;

CREATE AUDIT POLICY pol_barca_dml
  ACTIONS INSERT ON jucator,  UPDATE ON jucator,  DELETE ON jucator,
          INSERT ON contract, UPDATE ON contract, DELETE ON contract;

AUDIT POLICY pol_barca_logon;
AUDIT POLICY pol_barca_dml;

SELECT policy_name, enabled_option, entity_name
FROM audit_unified_enabled_policies
WHERE policy_name LIKE 'POL_BARCA%';

CREATE OR REPLACE TRIGGER trg_audit_jucator
AFTER INSERT OR UPDATE OR DELETE ON jucator
FOR EACH ROW
DECLARE
    v_actiune  VARCHAR2(10);
    v_pk       VARCHAR2(200);
    v_detalii  CLOB;
BEGIN
    IF INSERTING THEN
        v_actiune := 'INSERT';
        v_pk := 'id_jucator=' || :NEW.id_jucator;
        v_detalii := 'Inserare jucator: nume=' || :NEW.nume || ', prenume=' || :NEW.prenume
                  || ', nr_tricou=' || :NEW.nr_tricou;

    ELSIF UPDATING THEN
        v_actiune := 'UPDATE';
        v_pk := 'id_jucator=' || :NEW.id_jucator;

        v_detalii := 'Update jucator. ';
        IF NVL(:OLD.nr_tricou,-1) != NVL(:NEW.nr_tricou,-1) THEN
            v_detalii := v_detalii || 'nr_tricou: ' || :OLD.nr_tricou || ' -> ' || :NEW.nr_tricou || '; ';
        END IF;

        IF NVL(:OLD.nationalitate,'-') != NVL(:NEW.nationalitate,'-') THEN
            v_detalii := v_detalii || 'nationalitate: ' || :OLD.nationalitate || ' -> ' || :NEW.nationalitate || '; ';
        END IF;

        IF :OLD.telefon_criptat != :NEW.telefon_criptat THEN
            v_detalii := v_detalii || 'telefon_criptat modificat; ';
        END IF;
        IF :OLD.observatii_medicale_criptat != :NEW.observatii_medicale_criptat THEN
            v_detalii := v_detalii || 'observatii_medicale_criptat modificat; ';
        END IF;

    ELSE
        v_actiune := 'DELETE';
        v_pk := 'id_jucator=' || :OLD.id_jucator;
        v_detalii := 'Stergere jucator: nume=' || :OLD.nume || ', prenume=' || :OLD.prenume
                  || ', nr_tricou=' || :OLD.nr_tricou;
    END IF;

    INSERT INTO audit_log(db_user, actiune, obiect, pk_text, detalii)
    VALUES (SYS_CONTEXT('USERENV','SESSION_USER'), v_actiune, 'JUCATOR', v_pk, v_detalii);
END;
/

CREATE OR REPLACE TRIGGER trg_audit_contract
AFTER INSERT OR UPDATE OR DELETE ON contract
FOR EACH ROW
DECLARE
    v_actiune  VARCHAR2(10);
    v_pk       VARCHAR2(200);
    v_detalii  CLOB;
BEGIN
    IF INSERTING THEN
        v_actiune := 'INSERT';
        v_pk := 'id_contract=' || :NEW.id_contract;
        v_detalii := 'Inserare contract: id_jucator=' || :NEW.id_jucator || ', id_staff=' || :NEW.id_staff
                  || ', perioada=' || TO_CHAR(:NEW.data_start,'YYYY-MM-DD')
                  || ' -> ' || TO_CHAR(:NEW.data_final,'YYYY-MM-DD');

    ELSIF UPDATING THEN
        v_actiune := 'UPDATE';
        v_pk := 'id_contract=' || :NEW.id_contract;

        v_detalii := 'Update contract. ';
        IF :OLD.data_start != :NEW.data_start OR :OLD.data_final != :NEW.data_final THEN
            v_detalii := v_detalii || 'perioada modificata; ';
        END IF;

        IF NVL(:OLD.clauza_reziliere,-1) != NVL(:NEW.clauza_reziliere,-1) THEN
            v_detalii := v_detalii || 'clauza_reziliere: ' || :OLD.clauza_reziliere || ' -> ' || :NEW.clauza_reziliere || '; ';
        END IF;

        IF :OLD.salariu_criptat != :NEW.salariu_criptat THEN
            v_detalii := v_detalii || 'salariu_criptat modificat; ';
        END IF;
        IF :OLD.bonus_criptat != :NEW.bonus_criptat THEN
            v_detalii := v_detalii || 'bonus_criptat modificat; ';
        END IF;

    ELSE
        v_actiune := 'DELETE';
        v_pk := 'id_contract=' || :OLD.id_contract;
        v_detalii := 'Stergere contract: id_jucator=' || :OLD.id_jucator || ', id_staff=' || :OLD.id_staff;
    END IF;

    INSERT INTO audit_log(db_user, actiune, obiect, pk_text, detalii)
    VALUES (SYS_CONTEXT('USERENV','SESSION_USER'), v_actiune, 'CONTRACT', v_pk, v_detalii);
END;
/

BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema   => 'DEV_DBA',
    object_name     => 'CONTRACT',
    policy_name     => 'pol_select_salariu_bonus',
    audit_column    => 'SALARIU_CRIPTAT,BONUS_CRIPTAT',
    statement_types => 'SELECT');

  DBMS_FGA.ADD_POLICY(
    object_schema   => 'DEV_DBA',
    object_name     => 'JUCATOR',
    policy_name     => 'pol_select_medical',
    audit_column    => 'OBSERVATII_MEDICALE_CRIPTAT',
    statement_types => 'SELECT');
END;
/

UPDATE jucator SET nationalitate = 'ES' WHERE nr_tricou = 9;
UPDATE contract SET clauza_reziliere = 125000000
WHERE id_jucator = (SELECT id_jucator FROM jucator WHERE nr_tricou = 1);
COMMIT;

SELECT COUNT(*) FROM contract;
SELECT COUNT(salariu_criptat) FROM contract;
SELECT COUNT(observatii_medicale_criptat) FROM jucator;

SELECT id_audit, db_user, actiune, obiect, pk_text, detalii
FROM audit_log
WHERE actiune = 'UPDATE'
ORDER BY id_audit;

SELECT dbusername, action_name, object_name, unified_audit_policies
FROM unified_audit_trail
WHERE object_schema = 'DEV_DBA' AND audit_type = 'Standard'
ORDER BY event_timestamp;

SELECT dbusername, object_name, fga_policy_name, sql_text
FROM unified_audit_trail
WHERE audit_type = 'FineGrainedAudit'
ORDER BY event_timestamp;

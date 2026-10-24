CREATE TABLE crypto_keys (
  key_id      VARCHAR2(30)  PRIMARY KEY,
  key_value   RAW(32)       NOT NULL,
  created_at  TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
  retired_at  TIMESTAMP
);

CREATE OR REPLACE PROCEDURE genereaza_cheie (
    p_key_id IN VARCHAR2 DEFAULT 'ACTIVE'
)
IS
    v_key RAW(32);
BEGIN
    v_key := DBMS_CRYPTO.RANDOMBYTES(32);

    MERGE INTO crypto_keys k
    USING (SELECT p_key_id AS key_id FROM dual) src
       ON (k.key_id = src.key_id)
    WHEN NOT MATCHED THEN
      INSERT (key_id, key_value) VALUES (p_key_id, v_key);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cheia "' || p_key_id || '" este pregatita.');
END;
/

CREATE OR REPLACE PROCEDURE criptare_aes (
    sir_clar    IN  VARCHAR2,
    sir_criptat OUT RAW,
    p_key_id    IN  VARCHAR2 DEFAULT 'ACTIVE'
)
IS
    v_key   RAW(32);
    v_iv    RAW(16);
    v_raw   RAW(2000);
    v_mode  PLS_INTEGER;
BEGIN
    IF sir_clar IS NULL THEN
        sir_criptat := NULL;
        RETURN;
    END IF;

    SELECT key_value INTO v_key
      FROM crypto_keys
     WHERE key_id = p_key_id
       AND retired_at IS NULL;

    v_iv  := DBMS_CRYPTO.RANDOMBYTES(16);
    v_raw := UTL_I18N.STRING_TO_RAW(sir_clar, 'AL32UTF8');

    v_mode := DBMS_CRYPTO.ENCRYPT_AES256
            + DBMS_CRYPTO.CHAIN_CBC
            + DBMS_CRYPTO.PAD_PKCS5;

    sir_criptat := UTL_RAW.CONCAT(
        v_iv,
        DBMS_CRYPTO.ENCRYPT(src => v_raw, typ => v_mode, key => v_key, iv => v_iv)
    );
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Cheia de criptare "' || p_key_id || '" nu exista sau este retrasa.');
END;
/

CREATE OR REPLACE PROCEDURE decriptare_aes (
    sir_criptat   IN  RAW,
    sir_decriptat OUT VARCHAR2,
    p_key_id      IN  VARCHAR2 DEFAULT 'ACTIVE'
)
IS
    v_key    RAW(32);
    v_iv     RAW(16);
    v_cipher RAW(2000);
    v_mode   PLS_INTEGER;
BEGIN
    IF sir_criptat IS NULL THEN
        sir_decriptat := NULL;
        RETURN;
    END IF;

    SELECT key_value INTO v_key
      FROM crypto_keys
     WHERE key_id = p_key_id;

    v_iv     := UTL_RAW.SUBSTR(sir_criptat, 1, 16);
    v_cipher := UTL_RAW.SUBSTR(sir_criptat, 17);

    v_mode := DBMS_CRYPTO.ENCRYPT_AES256
            + DBMS_CRYPTO.CHAIN_CBC
            + DBMS_CRYPTO.PAD_PKCS5;

    sir_decriptat := UTL_RAW.CAST_TO_VARCHAR2(
        DBMS_CRYPTO.DECRYPT(src => v_cipher, typ => v_mode, key => v_key, iv => v_iv)
    );
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Cheia de decriptare "' || p_key_id || '" nu exista.');
END;
/

BEGIN
    genereaza_cheie('ACTIVE');
END;
/

DECLARE
    v_d1 RAW(2000);
    v_d2 RAW(2000);
    v_a1 RAW(2000);
    v_a2 RAW(2000);
    v_back VARCHAR2(200);
BEGIN
    criptare('1500000', v_d1);
    criptare('1500000', v_d2);
    criptare_aes('1500000', v_a1);
    criptare_aes('1500000', v_a2);

    DBMS_OUTPUT.PUT_LINE('DES/ECB  aceeasi intrare -> acelasi rezultat: ' || CASE WHEN v_d1 = v_d2 THEN 'DA' ELSE 'NU' END);
    DBMS_OUTPUT.PUT_LINE('AES/CBC  aceeasi intrare -> acelasi rezultat: ' || CASE WHEN v_a1 = v_a2 THEN 'DA' ELSE 'NU' END);

    decriptare_aes(v_a1, v_back);
    DBMS_OUTPUT.PUT_LINE('AES criptare-decriptare: ' || v_back);
END;
/

DECLARE
    v_clar VARCHAR2(2000);
    v_sal  RAW(256);
    v_bon  RAW(256);
    v_act  RAW(256);
    v_tel  RAW(256);
    v_med  RAW(512);

    FUNCTION des_clar(p RAW) RETURN VARCHAR2 IS
        v VARCHAR2(2000);
    BEGIN
        decriptare(p, v);
        RETURN v;
    END;
BEGIN
    FOR c IN (SELECT id_contract, salariu_criptat, bonus_criptat FROM contract) LOOP
        criptare_aes(des_clar(c.salariu_criptat), v_sal);
        criptare_aes(des_clar(c.bonus_criptat), v_bon);
        UPDATE contract SET salariu_criptat = v_sal, bonus_criptat = v_bon
        WHERE id_contract = c.id_contract;
    END LOOP;

    FOR j IN (SELECT id_jucator, act_id_criptat, telefon_criptat, observatii_medicale_criptat FROM jucator) LOOP
        criptare_aes(des_clar(j.act_id_criptat), v_act);
        criptare_aes(des_clar(j.telefon_criptat), v_tel);
        criptare_aes(des_clar(j.observatii_medicale_criptat), v_med);
        UPDATE jucator
        SET act_id_criptat = v_act, telefon_criptat = v_tel, observatii_medicale_criptat = v_med
        WHERE id_jucator = j.id_jucator;
    END LOOP;
    COMMIT;
END;
/

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

    decriptare_aes(v_sal_raw, p_salariu);
    decriptare_aes(v_bonus_raw, p_bonus);
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

    decriptare_aes(v_med_raw, p_medical);
END;
/

SELECT id_contract, RAWTOHEX(salariu_criptat) AS salariu_aes FROM contract ORDER BY id_contract;

-- Vulnerabilitate intentionata, pentru comparatie cu varianta sigura.
CREATE OR REPLACE PROCEDURE cauta_jucator_vulnerabil (
    p_text IN VARCHAR2
)
IS
    v_sql   VARCHAR2(4000);
    v_nr    NUMBER;
BEGIN
    v_sql := 'SELECT COUNT(*) FROM jucator ' ||
             'WHERE UPPER(nume) LIKE UPPER(''%' || p_text || '%'') ' ||
             '   OR UPPER(prenume) LIKE UPPER(''%' || p_text || '%'')';

    DBMS_OUTPUT.PUT_LINE('SQL executat: ' || v_sql);

    EXECUTE IMMEDIATE v_sql INTO v_nr;

    DBMS_OUTPUT.PUT_LINE('Numar rezultate=' || v_nr);
END;
/

CREATE OR REPLACE PROCEDURE cauta_jucator_sigur (
    p_text IN VARCHAR2
)
IS
    v_pattern VARCHAR2(200);
    v_nr      NUMBER;
BEGIN
    v_pattern := '%' || p_text || '%';

    SELECT COUNT(*)
    INTO v_nr
    FROM jucator
    WHERE UPPER(nume) LIKE UPPER(v_pattern)
       OR UPPER(prenume) LIKE UPPER(v_pattern);

    DBMS_OUTPUT.PUT_LINE('Numar rezultate=' || v_nr);
END;
/

GRANT EXECUTE ON cauta_jucator_vulnerabil TO rol_antrenor_barca;
GRANT EXECUTE ON cauta_jucator_sigur      TO rol_antrenor_barca;

BEGIN
  cauta_jucator_vulnerabil('PEDRI');
  cauta_jucator_sigur('PEDRI');
END;
/

BEGIN
  cauta_jucator_vulnerabil(''') OR 1=1 -- ');
  cauta_jucator_sigur(''') OR 1=1 -- ');
END;
/

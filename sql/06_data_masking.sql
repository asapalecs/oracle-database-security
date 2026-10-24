CREATE OR REPLACE VIEW v_jucatori_mascati AS
SELECT
  id_jucator,
  nume,
  prenume,
  data_nasterii,
  nationalitate,
  nr_tricou,
  CASE WHEN act_id_criptat IS NULL THEN NULL ELSE '***ID-ASCUNS***' END AS act_id_mascat,
  CASE WHEN telefon_criptat IS NULL THEN NULL ELSE '***TEL-ASCUNS***' END AS telefon_mascat,
  CASE WHEN observatii_medicale_criptat IS NULL THEN NULL ELSE '***MEDICAL-ASCUNS***' END AS medical_mascat
FROM jucator;

GRANT SELECT ON v_jucatori_mascati TO rol_antrenor_barca;
GRANT SELECT ON v_jucatori_mascati TO rol_financiar_barca;
GRANT SELECT ON v_jucatori_mascati TO rol_medic_barca;

SELECT * FROM v_jucatori_mascati ORDER BY nr_tricou;

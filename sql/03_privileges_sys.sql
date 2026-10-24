CREATE PROFILE prof_barca_limitat LIMIT
  SESSIONS_PER_USER     2
  CPU_PER_SESSION       20000
  CONNECT_TIME          60
  IDLE_TIME             15
  FAILED_LOGIN_ATTEMPTS 5
  PASSWORD_LIFE_TIME    90;

CREATE PROFILE prof_barca_admin LIMIT
  SESSIONS_PER_USER     5
  CPU_PER_SESSION       UNLIMITED
  CONNECT_TIME          UNLIMITED
  IDLE_TIME             30
  FAILED_LOGIN_ATTEMPTS 10
  PASSWORD_LIFE_TIME    180;

CREATE ROLE rol_admin_barca;
CREATE ROLE rol_financiar_barca;
CREATE ROLE rol_antrenor_barca;
CREATE ROLE rol_medic_barca;

GRANT rol_financiar_barca TO rol_admin_barca;
GRANT rol_antrenor_barca  TO rol_admin_barca;
GRANT rol_medic_barca     TO rol_admin_barca;

CREATE USER u_admin IDENTIFIED BY "Admin#2026" PROFILE prof_barca_admin;
CREATE USER u_fin   IDENTIFIED BY "Fin#2026"   PROFILE prof_barca_limitat;
CREATE USER u_ant   IDENTIFIED BY "Ant#2026"   PROFILE prof_barca_limitat;
CREATE USER u_med   IDENTIFIED BY "Med#2026"   PROFILE prof_barca_limitat;

GRANT CREATE SESSION TO u_admin, u_fin, u_ant, u_med;

GRANT rol_admin_barca     TO u_admin;
GRANT rol_financiar_barca TO u_fin;
GRANT rol_antrenor_barca  TO u_ant;
GRANT rol_medic_barca     TO u_med;

SELECT profile, resource_name, limit
FROM dba_profiles
WHERE profile LIKE 'PROF_BARCA%' AND limit <> 'DEFAULT'
ORDER BY profile, resource_name;

SELECT grantee, granted_role
FROM dba_role_privs
WHERE grantee IN ('U_ADMIN','U_FIN','U_ANT','U_MED','ROL_ADMIN_BARCA')
ORDER BY grantee, granted_role;

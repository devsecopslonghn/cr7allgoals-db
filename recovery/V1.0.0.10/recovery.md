# V1.0.0.10 recovery and verification

## Scope and compatibility

- Migration: `migrations/V1.0.0.10-create_e2e_20261022_poc_ddl.sql`.
- Target: `projects/cr7-allgoal-kvi1`, instance `oracle-cloud-free-sge0`,
  database/schema `CR7ALLGOALS_APP`, stage `environments/develop`.
- Adds only the new `BB_POC_E2E_20261022_A` table and its generated primary-key
  index, using the `BB_POC_` prefix for the constraint as well.
- Creates no rows and changes no application objects or existing migrations.
  Applications do not depend on this table, so an application rollback does
  not require reversing this migration.
- V1.0.0.10 follows the target's observed Bytebase revisions V1.0.0.0 through
  V1.0.0.9. The initial master checkout contains only V1.0.0.0 through
  V1.0.0.5; open PR #8 contains V1.0.0.6 through V1.0.0.9. This change does
  not merge PR #8, repair revision history, or change any existing checksum.

## Before rollout

1. Review the exact PR head SHA and the Jenkins SQL Review result. Resolve
   errors in this new migration before merge; do not weaken policy or bypass
   release validation. Record any warnings and review their actual severity.
2. Confirm the target identity, that V1.0.0.10 is unused, and that the POC
   table name does not already exist. Check live Oracle metadata where the
   permitted query path supports it; a cached catalog alone is insufficient.
3. Check the master/revision discrepancy above using the existing release
   validation. If it blocks release creation, stop and record the finding;
   do not rerun earlier versions, edit applied migrations, import revisions,
   or reset history to make the demonstration pass.
4. Confirm that the actual master build deploys only the approved POC change
   to develop. Do not promote it to another environment.

## Failure handling

Oracle DDL may commit independently of the surrounding task. A failed task
does not establish that all statements were undone: the table may exist even
if a later comment statement fails. Record the first failing statement and
inspect the target before deciding on recovery. Do not automatically retry,
repair history, or recreate the object.

Prefer fix-forward through a later reviewed migration after the DBA has
compared the live object, task trace and Bytebase revision. Keep an unused
empty POC table in place until that decision is reviewed. No automatic
destructive reverse script is supplied; any future removal requires a
separate dependency/data review and explicit DBA authorization. Existing
Oracle backup, Flashback or PITR procedures remain under DBA control if
needed; this change does not configure or execute them.

## Read-only verification

Use the existing approved connection to the exact target. Do not display
application rows. The following queries inspect only the new POC metadata
and its empty row count; record the execution time and result, not just a
successful Bytebase task.

```sql
SELECT OWNER, TABLE_NAME
FROM ALL_TABLES
WHERE OWNER = 'CR7ALLGOALS_APP'
  AND TABLE_NAME = 'BB_POC_E2E_20261022_A';

SELECT COLUMN_ID, COLUMN_NAME, DATA_TYPE, NULLABLE
FROM ALL_TAB_COLUMNS
WHERE OWNER = 'CR7ALLGOALS_APP'
  AND TABLE_NAME = 'BB_POC_E2E_20261022_A'
ORDER BY COLUMN_ID;

SELECT COUNT(*) AS POC_ROW_COUNT
FROM CR7ALLGOALS_APP.BB_POC_E2E_20261022_A
WHERE ID IS NOT NULL;
```

Expected after a complete rollout: one matching table, three columns
(`ID`, `DEMO_LABEL`, `CREATED_AT`) with `NULLABLE = 'N'`, a primary key
on `ID`, comments matching the migration, and zero rows. Confirm
V1.0.0.10 in Bytebase revisions and link PR/source SHA, merge SHA, Jenkins
build and Bytebase Plan/task in the evidence report.

If SQL Editor rejects dictionary queries in its masking/metadata layer,
record the exact error and use another already authorized read-only path if
one is available. Do not change masking policy, connection privileges or
database grants to work around it. If no path is available, explicitly mark
live verification incomplete.

# CR7 All Goals Database

Database change source for CR7 All Goals Oracle, operated through Bytebase Community migration-based GitOps.

## Developer: change the database in one minute

1. Create a new file in `migrations/` using `YYYYMMDDHHmmss_description_ddl.sql` or `_dml.sql`.
2. Put one logical change in it. Use Oracle SQL and prefix POC objects with `BB_POC_`.
3. Add recovery notes under `recovery/<version>/recovery.md`.
4. Commit on a feature branch and open a GitLab MR.
5. SQL Review runs against the changed migration files. Fix failures before merge.
6. After approval, merge. CI creates a Bytebase database release and rolls it out to DEV.
7. The DBA/governance gate promotes that same release to later environments.

An applied migration is immutable. If it needs changing, create a later migration. Do not edit, rename, or delete the applied file. Developers do not need an Oracle password, `sqlplus`, or direct database access.

## DBA: review and operate

Review the MR and Bytebase release for SQL, risk, locking, table size, compatibility, data loss, timing, backup/PITR requirements, and recovery classification. Bytebase provides SQL Review, release/rollout control, execution status, and revision/change history. The Oracle credential is owned and rotated by DBA/platform; it is stored in Bytebase, never in Git or GitLab CI.

The promoted unit is a Bytebase database release: Git commit SHA plus the ordered migration set. The same bytes and SHA move DEV → SIT → STAGING → UAT → PROD. Environment-specific database data is an exception and must be an explicitly scoped, separately reviewed artifact; application/Kubernetes configuration belongs outside this repository.

## Identity and recovery

These are different identifiers:

| Identity | Meaning |
|---|---|
| Migration version | Numeric timestamp at the start of a filename |
| Git SHA | Immutable source commit |
| Database release | Bytebase release containing one Git SHA and migration set |
| Bytebase revision | Applied-history record for a target database |
| Application release | Application image/version and its declared DB compatibility |

Application rollback is not database rollback. Prefer expand → deploy app → migrate usage → contract later. Use fix-forward by default. A reverse script exists only when safe; unsafe recovery uses Oracle backup, Flashback, or PITR under DBA control.

## POC contents

The migrations demonstrate:

- `20260909143000`: create `BB_POC_RELEASE_FLOW` (DDL)
- `20260909150000`: add `STATUS` without modifying migration 1 (DDL)
- `20260909153000`: seed one row (DML)
- `20260909160000`: create `BB_POC_RELEASE_FLOW_V` (programmable object, DDL)
- `20260909163000`: update the view using `CREATE OR REPLACE` (new DDL revision)

The current CR7 application runner in `cr7allgoals-be/packages/db` is existing application-owned infrastructure and is not altered by this POC. It remains a migration path to reconcile before production cutover; two authorities must not apply the same schema changes.

## Evidence status

`PROMOTION MODEL DESIGNED` / `MULTI-ENV EXECUTION NOT YET DEMONSTRATED`.

The workspace has Bytebase platform manifests and the DEV endpoint, but no authenticated Bytebase service account/Oracle target evidence was available to this implementation. No rollout or Oracle object creation is claimed by this repository. Record actual release, rollout, task, executor, timestamp, SQL, revision, and schema snapshot links in `docs/POC-EVIDENCE.md` after an authorized run.

See [DATABASE-SOURCE-DECISION.md](../DATABASE-SOURCE-DECISION.md) for the gate and [OPERATING-MODEL.md](docs/OPERATING-MODEL.md) for the end-to-end model.

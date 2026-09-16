# CR7 All Goals Database

Database change source for CR7 All Goals Oracle, operated through Bytebase Community migration-based GitOps.

## Developer: change the database in one minute

1. Create a new file in `migrations/` using `V1.0.0.N-description_ddl.sql` or `_dml.sql`, increasing `N` by one for every new migration.
2. Put one logical change in it. Use Oracle SQL and prefix POC objects with `BB_POC_`.
3. Add recovery notes under `recovery/<version>/recovery.md`.
4. Commit on a feature branch and open a GitHub pull request.
5. Jenkins runs Bytebase SQL Review against the changed migration files. Fix failures before merge.
6. After approval, merge. Jenkins creates a Bytebase database release and rolls it out to DEV.
7. The DBA/governance gate promotes that same release to later environments.

An applied migration is immutable. If it needs changing, create a later migration. Do not edit, rename, or delete the applied file. Developers do not need an Oracle password, `sqlplus`, or direct database access.

## DBA: review and operate

Review the pull request and Bytebase release for SQL, risk, locking, table size, compatibility, data loss, timing, backup/PITR requirements, and recovery classification. Bytebase provides SQL Review, release/rollout control, execution status, and revision/change history. The Oracle credential is owned and rotated by DBA/platform; it is stored in Bytebase, never in Git or Jenkins.

The promoted unit is a Bytebase database release: Git commit SHA plus the ordered migration set. The same bytes and SHA move DEV → SIT → STAGING → UAT → PROD. Environment-specific database data is an exception and must be an explicitly scoped, separately reviewed artifact; application/Kubernetes configuration belongs outside this repository.

## Identity and recovery

These are different identifiers:

| Identity | Meaning |
|---|---|
| Migration version | Semantic version at the start of a filename, for example `V1.0.0.0` |
| Git SHA | Immutable source commit |
| Database release | Bytebase release containing one Git SHA and migration set |
| Bytebase revision | Applied-history record for a target database |
| Application release | Application image/version and its declared DB compatibility |

Application rollback is not database rollback. Prefer expand → deploy app → migrate usage → contract later. Use fix-forward by default. A reverse script exists only when safe; unsafe recovery uses Oracle backup, Flashback, or PITR under DBA control.

## POC contents

The migrations demonstrate:

- `V1.0.0.0`: create `BB_POC_V1_RELEASE_FLOW` (DDL)
- `V1.0.0.1`: add `STATUS` without modifying migration 1 (DDL)
- `V1.0.0.2`: seed one row (DML)
- `V1.0.0.3`: create `BB_POC_V1_RELEASE_FLOW_V` (programmable object, DDL)
- `V1.0.0.4`: update the view using `CREATE OR REPLACE` (new DDL revision)

The current CR7 application runner in `cr7allgoals-be/packages/db` is existing application-owned infrastructure and is not altered by this POC. It remains a migration path to reconcile before production cutover; two authorities must not apply the same schema changes.

## Evidence status

`PROMOTION MODEL DESIGNED` / `DEV EXECUTION DEMONSTRATED` / `MULTI-ENV EXECUTION NOT YET DEMONSTRATED`.

The DEV rollout is recorded in `docs/POC-EVIDENCE.md`. Multi-environment promotion remains untested. Record the Bytebase revision and schema verification query output there after reviewing the completed task.

See [DATABASE-SOURCE-DECISION.md](../DATABASE-SOURCE-DECISION.md) for the gate and [OPERATING-MODEL.md](docs/OPERATING-MODEL.md) for the end-to-end model.

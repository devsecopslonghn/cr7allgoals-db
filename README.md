# CR7 All Goals Database

Bytebase Community migration-based GitOps POC for CR7 All Goals Oracle.

**Current application:** [CR7 All Goals](https://cr7allgoals.com/) is a public
website with no login or VPN dependency. Application schema migrations remain
owned by the [backend migration authority](https://github.com/devsecopslonghn/cr7allgoals-harness/blob/master/docs/adr/008-backend-migration-authority.md).
This repository exercises separate `BB_POC_` objects; it does not replace the
application migration authority or run during an application rollout.

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

The initial POC release contains only schema changes that can be checked
against the current target database:

- `V1.0.0.0`: create `BB_POC_V1_RELEASE_FLOW` (DDL)
- `V1.0.0.1`: add `STATUS` without modifying migration 1 (DDL)

After the initial table release is deployed, subsequent migrations may add
seed DML and programmable objects. This lets the SQL Review DML dry-run
validate against an existing target object.

The current CR7 application runner in `cr7allgoals-be/packages/db` is existing application-owned infrastructure and is not altered by this POC. It remains a migration path to reconcile before production cutover; two authorities must not apply the same schema changes.

## Evidence status

`PROMOTION MODEL DESIGNED` / `DEV EXECUTION DEMONSTRATED` / `MULTI-ENV EXECUTION NOT YET DEMONSTRATED`.

The DEV rollout is recorded in `docs/POC-EVIDENCE.md`. Multi-environment promotion remains untested. Record the Bytebase revision and schema verification query output there after reviewing the completed task.

See [SQL review guidance](.bytebase/sql-review.md) for this POC. The application migration authority linked above governs application schema changes.

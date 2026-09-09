# CR7 Database Delivery Operating Model — Final Report

## 1. Discovery

The existing CR7 database workflow is application-owned: the backend package
contains foundation/provider SQL and a Node migration runner with checksums,
status, statement progress, and `DBMS_LOCK`; the Helm chart has an opt-in
migration Job using an external Oracle Secret. No existing Flyway/Liquibase source
was found. Existing CR7 repositories are GitHub repositories on `master`.

## 2. Architecture decisions

The POC selects a dedicated `cr7allgoals-db` source repository, migration-based
Bytebase workflow, flat `migrations/*.sql` layout, numeric UTC timestamps, and
explicit `_ddl`/`_dml` suffixes. This is documented in the [decision gate](../DATABASE-SOURCE-DECISION.md).

Bytebase's official migration-based documentation defines `<Version>_<Description>.sql`,
supports timestamp versions, and documents `ddl`/`dml` suffixes. Its GitHub
tutorial documents the three stages develop → review → release.
Oracle is listed as supported for GitOps and SQL review. State-based SDL is not
selected because the documented current fit is PostgreSQL-oriented and does not
cover DML as an imperative migration source.

References: [Bytebase migration workflow](https://docs.bytebase.com/gitops/migration-based-workflow/overview),
[file naming](https://docs.bytebase.com/gitops/migration-based-workflow/develop),
[GitHub Actions tutorial](https://docs.bytebase.com/tutorials/gitops-github-workflow),
[supported databases](https://docs.bytebase.com/introduction/supported-databases),
[change history](https://docs.bytebase.com/change-database/change-history).

## 3. POC source and identities

The repository contains five immutable-by-policy migrations:

| Version | Change |
|---|---|
| 20260909143000 | `BB_POC_RELEASE_FLOW` table |
| 20260909150000 | `STATUS` column |
| 20260909153000 | POC seed row |
| 20260909160000 | initial `BB_POC_RELEASE_FLOW_V` view |
| 20260909163000 | later `CREATE OR REPLACE VIEW` revision adding `IS_ACTIVE` |

Migration version, Git SHA, Bytebase database release, Bytebase revision, and
application release remain distinct. The promotion artifact is the Bytebase
release that carries a Git SHA and ordered migration set.

## 4. Operating model

Developers author source and recovery notes, open a pull request, and fix SQL Review
failures. DBA reviews risk and controls governed rollout. Platform owns Bytebase,
connectivity, service account and protected variables. Bytebase executes against
Oracle and records release/rollout/task/revision history. Oracle remains the live
state; backup/PITR/Flashback remains the recovery state.

The same migration bytes, version, and Git SHA are promoted DEV → SIT → STAGING →
UAT → PROD. Environment-specific DB data is an exception; application/config
values belong in Kubernetes/application configuration where possible.

## 5. Recovery, emergency changes, and gaps

Expand/contract and fix-forward are the defaults. Application rollback does not
automatically reverse database changes. Reverse SQL is only added when safe;
otherwise DBA-led backup/Flashback/PITR is required. A direct incident change is
recorded, reconciled into a new Git migration, reviewed, then managed through
Bytebase. Automatic out-of-band drift reconciliation remains a gap and is
explicitly not fabricated here.

## 6. Actual execution status

Bytebase platform manifests are present in GitOps and pin chart `1.1.5` with
Bytebase image `3.22.1`; the endpoint is configured as
`https://bytebase.apps.drgdevlab.com`. No authenticated service account, Oracle
target, MR, release, rollout, task, executor, revision, or Oracle object creation
was available to verify in this workspace. Therefore:

```text
PROMOTION MODEL DESIGNED
MULTI-ENV EXECUTION NOT YET DEMONSTRATED
```

The [evidence register](POC-EVIDENCE.md) is ready for the authorized run and
forbids filling in invented execution evidence.

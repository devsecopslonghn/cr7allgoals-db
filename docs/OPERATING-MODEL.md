# Recommended CR7 Database Operating Model

## Source and evidence boundaries

| Concern | System of record |
|---|---|
| Database change intent/source | Git (`cr7allgoals-db`) |
| Review and release decision | GitHub pull request + Bytebase SQL Review/release |
| Applied migration history | Bytebase revision/change history |
| Actual database state | Oracle schema `CR7ALLGOALS_APP` |
| Recovery state | Oracle backup/Flashback/PITR and DBA recovery process |

There is no single universal “source of truth”: source, applied history, live state,
release metadata, and recovery state answer different questions.

## Developer experience

Create one timestamped migration, add recovery notes, run/test locally when
available, open a pull request, and respond to SQL Review. Merge is the hand-off point to
the database release process. An applied file is immutable forever. A developer
does not use `sqlplus`, ask a DBA to copy a chat attachment, or receive an Oracle
password.

## DBA experience

The DBA reviews the pull request and Bytebase plan/release: exact SQL, target, ordering,
locks, table size, compatibility, data loss, destructive impact, timing, backup
and recovery. The DBA approves governed rollouts and owns Oracle credentials,
backup/recovery, and emergency operations. Bytebase performs the controlled
execution and exposes release, rollout, task, executor, timestamps, SQL and
revision history.

## Platform experience

Platform owns Bytebase availability, GitHub integration, service account lifecycle,
network connectivity, protected variables, environment/target mapping, and
observability. GitHub Actions calls Bytebase; GitHub Actions does not connect to Oracle.

## Version and promotion

Migration version is the 14-digit UTC timestamp prefix. It is not the Git SHA,
application version, Bytebase release, or Oracle revision. A release manifest
should record all of them, plus the application release compatibility statement.

The promotion unit is the same Bytebase release containing the same Git SHA and
migration bytes. Desired path: DEV → SIT → STAGING → UAT → PROD. Only Bytebase
target/stage and approval change; SQL does not.

If environment-specific DB data is unavoidable, use a separately versioned and
reviewed artifact scoped to that environment. First classify whether the value
belongs in Kubernetes/application configuration instead.

## Application compatibility and rollback

Application and database releases are independent. Example: app `1.8.0` declares
`DB >= 20260909143000`; later app patches may use the same DB revision. Use
expand/contract: expand schema, deploy compatible app, migrate usage, contract in
a later change. App rollback from `1.8` to `1.7` does not automatically drop a
column. Fix-forward is the default; reverse SQL is exceptional and must be proven
safe. Oracle restore/PITR/Flashback is a DBA recovery action, not an application
rollback.

## Emergency change and drift

For an incident-time direct Oracle change: record the incident/change ID and exact
SQL, assess the live state, create a reconciliation migration, review it, then
apply/manage it through Bytebase. Never use “already executed manually” as a
reason to omit Git. Bytebase records managed history but Community does not remove
the need for an external reconciliation process for every out-of-band change;
automatic drift detection and remediation is a remaining gap.

## Minimum new-starter rules

1. Every DB change is a new timestamped SQL file in Git.
2. One logical change per file; use `_ddl` or `_dml` accurately.
3. Never edit an applied migration; create a follow-up migration.
4. Review happens in the pull request and risk approval in Bytebase.
5. Promote the same release/SHA; do not copy or alter SQL per environment.
6. Never put Oracle credentials in GitHub Actions or source control.
7. Application rollback and database recovery are separate decisions.
8. Emergency direct SQL always gets reconciled back into Git and Bytebase history.

## End-to-end view

```text
DEVELOPER                         DBA / GOVERNANCE
change needed                     database release
    ↓                                  ↓
versioned SQL                     risk / approval
    ↓                                  ↓
GitHub pull request               controlled rollout
    ↓                                  ↓
SQL Review                        DEV → SIT → UAT → PROD
    ↓
merge → database release

EXECUTION                         TRACEABILITY
Bytebase                          Git migration
    ↓                                  ↓
Oracle                            Git SHA
                                       ↓
                                  Bytebase Release
                                       ↓
                                  Rollout / Task
                                       ↓
                                  Oracle Revision
```

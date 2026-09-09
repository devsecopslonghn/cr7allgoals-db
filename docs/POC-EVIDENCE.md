# Bytebase POC Evidence Register

This register must contain observed values after an authorized execution. Blank
fields are intentional; they are not evidence.

| Step | Status | Evidence to record |
|---|---|---|
| Bytebase target configured | OBSERVED | project `projects/cr7goal-9xbo`; target `projects/cr7goal-9xbo/instances/oracle-rvdu/databases/CR7ALLGOALS_APP`; current schema `CR7ALLGOALS_APP` |
| SQL Review pull request | PASSED | Temporary PR #2; result count 5; authentication and PR annotation passed |
| Release after merge | OBSERVED | `release_20260909-RC05`; Git SHA `c30008ac5263d21897ab530f56153425ac7d4dc0`; 5 migration files |
| DEV plan | OBSERVED | Plan `106`; target stage `environments/test`; target `oracle / CR7ALLGOALS_APP` |
| DEV rollout | SUCCEEDED | [GitHub Actions run 34332877516](https://github.com/devsecopslonghn/cr7allgoals-db/actions/runs/34332877516); one task; Bytebase stage completed |
| Oracle revision/history | NOT RUN | revision ID, checksum/content link, schema snapshot if exposed |
| Oracle objects | ROLLOUT SUCCEEDED; QUERY NOT CAPTURED | `BB_POC_RELEASE_FLOW`, `BB_POC_RELEASE_FLOW_V` and verification query output |
| Second environment | NOT DEMONSTRATED | same release/SHA and target; no SQL mutation |

## Evidence rule

Do not write a release, rollout, executor, timestamp, revision, or Oracle object
as “successful” unless it is copied from Bytebase/Oracle after the run. Current
scope is `DEV EXECUTION DEMONSTRATED` and `MULTI-ENV EXECUTION NOT YET DEMONSTRATED`.

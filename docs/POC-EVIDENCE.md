# Bytebase POC Evidence Register

This register must contain observed values after an authorized execution. Blank
fields are intentional; they are not evidence.

| Step | Status | Evidence to record |
|---|---|---|
| Bytebase target configured | NOT RUN | project, instance, database, schema, environment |
| SQL Review pull request | NOT RUN | PR URL, workflow run ID, review result, reviewer |
| Release after merge | NOT RUN | release name/ID, Git SHA, migration set |
| DEV plan | NOT RUN | plan ID, target, rendered SQL |
| DEV rollout | NOT RUN | rollout/task IDs, executor, start/end, status |
| Oracle revision/history | NOT RUN | revision ID, checksum/content link, schema snapshot if exposed |
| Oracle objects | NOT RUN | `BB_POC_RELEASE_FLOW`, `BB_POC_RELEASE_FLOW_V` and verification query output |
| Second environment | NOT DEMONSTRATED | same release/SHA and target; no SQL mutation |

## Evidence rule

Do not write a release, rollout, executor, timestamp, revision, or Oracle object
as “successful” unless it is copied from Bytebase/Oracle after the run. Current
scope is `PROMOTION MODEL DESIGNED` and `MULTI-ENV EXECUTION NOT YET DEMONSTRATED`.

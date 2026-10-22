# V1.0.0.11 review-only negative test

Never merge or deploy this branch. It is separate from the positive V1.0.0.10
demonstration and intentionally omits a primary key on the new
`BB_POC_REVIEW_20261022_A` table. Only Jenkins PR SQL Review should process it.
No Oracle DDL or DML is authorized for this negative test.

Record the source SHA, PR number, Jenkins build and the actual advice code,
severity and exit/build status. Confirm the current Oracle policy before
claiming that the missing-primary-key rule caused failure. Other baseline
release-validation findings must be reported separately.

A failed CI check, an enforced Git merge restriction and a reviewer's choice
not to merge are different observations. Do not infer any of them solely
from a PR comment. Do not change policy or waive errors to obtain a result.

Because this migration must remain unapplied, there is no automatic recovery
script. If any unexpected rollout is observed, stop, record the exact target
and Plan/task, and request DBA assessment; do not retry, delete objects or
repair revision history.

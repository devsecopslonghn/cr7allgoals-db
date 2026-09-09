# CR7 SQL Review policy inputs

The Bytebase project must attach its SQL Review policy to DEV and production-like
targets. At minimum require human review for destructive DDL, large-table locks,
unbounded UPDATE/DELETE, missing WHERE clauses, unsafe NOT NULL changes, and
production DML. The exact rule names are configured in the installed Bytebase
workspace; this file is guidance for the DBA policy owner, not a replacement for
the server-side policy.

<!-- Temporary integration verification; no migration content changed. -->

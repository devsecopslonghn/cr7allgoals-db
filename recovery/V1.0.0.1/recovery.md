# Recovery: V1.0.0.1

Recovery classification: FIX_FORWARD  
Application rollback compatible: YES  
Data loss: NO  
DBA intervention: required before any column removal

The `STATUS` column is additive with a default. Keep it during app rollback; remove it only through a separately reviewed contract migration.

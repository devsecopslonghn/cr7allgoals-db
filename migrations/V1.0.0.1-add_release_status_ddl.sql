-- CR7 All Goals POC migration V1.0.0.1.
-- Additive DDL: add the release status column.
ALTER TABLE BB_POC_V1_RELEASE_FLOW
ADD STATUS VARCHAR2(30) DEFAULT 'ACTIVE' NOT NULL;

COMMENT ON COLUMN BB_POC_V1_RELEASE_FLOW.STATUS IS
    'Current lifecycle status of the release-flow record.';

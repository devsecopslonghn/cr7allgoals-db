-- REVIEW-ONLY NEGATIVE TEST. Never merge or deploy this branch.
-- Intentionally violates the Oracle rule requiring a table primary key.
-- Target metadata for review: CR7ALLGOALS_APP / develop.
CREATE TABLE BB_POC_REVIEW_20261022_A (
    ID NUMBER DEFAULT 1 NOT NULL,
    DEMO_LABEL VARCHAR2(40) DEFAULT 'REVIEW_ONLY' NOT NULL
);

COMMENT ON TABLE BB_POC_REVIEW_20261022_A IS
    'Review-only synthetic POC; intentionally missing a primary key; never deploy.';
COMMENT ON COLUMN BB_POC_REVIEW_20261022_A.ID IS
    'Synthetic ID for the primary-key review test.';
COMMENT ON COLUMN BB_POC_REVIEW_20261022_A.DEMO_LABEL IS
    'Synthetic marker for an unmerged review-only negative test.';

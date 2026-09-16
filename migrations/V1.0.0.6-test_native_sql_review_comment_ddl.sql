-- CR7 All Goals POC migration V1.0.0.6.
-- Intentional SQL Review test: this should produce both errors and warnings.
-- Do not manually roll out this migration to a real environment.
CREATE TABLE BB_POC_V1_REVIEW_TEST (
    ID NUMBER,
    NAME VARCHAR2(100)
);

-- CR7 All Goals POC migration V1.0.0.3.
-- Create the initial programmable-object view after its source table exists.
CREATE OR REPLACE VIEW BB_POC_V1_RELEASE_FLOW_V AS
SELECT RELEASE_ID, RELEASE_NAME, STATUS, CREATED_AT
FROM BB_POC_V1_RELEASE_FLOW
WHERE STATUS IS NOT NULL;

Run these queries sequentially in Google Cloud's BigQuery.
It will provide all the necessary tables to go from PhysioNet's eICU tables to the sepsis cohort.
Replace "db_name" by your project_id.database name, like "project_id.icu_elos".
14_cohort.sql provides the final cohort of patients, which will then be enriched.
# How to get data from BigQuery:
1) Got to Google Cloud's BigQuery.
2) Replace "db_name" by your project ID and the subfolder icu_elos, eg. "project_id.icu_elos"
3) Run these queries sequentially in Google Cloud's BigQuery.
4) If you run into quota limits, split the jobs over a couple of days.
5) 14_cohort.sql query will provide the final cohort of patients.

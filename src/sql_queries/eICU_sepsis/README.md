# How to get data from BigQuery:
1) Got to Google Cloud's BigQuery.
2) Copy relevant tables from the physionet-data project into your own project folder 
3) Make sure names are matching, e.g., physionet-data.eicu-crd.patient -> yourproject_id.eicu-crd.patient
4) Replace "db_name" by your project_id.database name, like "project_id.icu_elos."
5) Run these queries sequentially in Google Cloud's BigQuery.
6) If you run into quota limits, split the jobs over a couple of days.


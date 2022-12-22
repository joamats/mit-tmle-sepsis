
-- ------------------------------------------------------------------
-- Title: Oxford Acute Severity of Illness Score (OASIS)
-- This query extracts the Oxford acute severity of illness score.
-- This score is a measure of severity of illness for patients in the ICU.
-- The score is calculated on the first day of each ICU patients' stay.
-- OASIS score was originally created for MIMIC
-- This script creates a pivoted table containing the OASIS score in eICU 
-- ------------------------------------------------------------------

-- Reference for OASIS:
--    Johnson, Alistair EW, Andrew A. Kramer, and Gari D. Clifford.
--    "A new severity of illness scale using a subset of acute physiology and chronic health evaluation data elements shows comparable predictive accuracy*."
--    Critical care medicine 41, no. 7 (2013): 1711-1718.
-- https://alistairewj.github.io/project/oasis/

-- Variables used in OASIS (first 24h only):
--  Heart rate, MAP, Temperature, Respiratory rate
--  (sourced FROM `physionet-data.eicu_crd_derived.pivoted_vital`)
--  GCS
--  (sourced FROM `physionet-data.eicu_crd_derived.pivoted_vital` and `physionet-data.eicu_crd_derived.physicalexam`)
--  Urine output 
--  (sourced  FROM `physionet-data.eicu_crd_derived.pivoted_uo`)
--  Pre-ICU in-hospital length of stay 
--  (sourced FROM `physionet-data.eicu_crd.patient`)
--  Age 
--  (sourced FROM `physionet-data.eicu_crd.patient`)
--  Elective surgery 
--  (sourced FROM `physionet-data.eicu_crd.patient`, `physionet-data.eicu_crd.admissiondx` and `physionet-data.eicu_crd.apachepredvar`)
--  Ventilation status 
--  (sourced FROM `physionet-data.eicu_crd_derived.ventilation_events`, `physionet-data.eicu_crd_derived.debug_vent_tags`, `physionet-data.eicu_crd.apacheapsvar`, 
--   `physionet-data.eicu_crd.apachepredvar`, and `physionet-data.eicu_crd.respiratorycare`)


-- Regarding missing values:
-- Elective stay: If there is no information on surgery in an elective stay, we assumed all cases to be -> "no elective surgery"
-- There are a lot of missing values, especially for urine output. Hence, we have created 3 OASIS summary scores:
-- 1) No imputation, values as is with missings. 2) Imputation by assuming a Best Case scenario. 3) Imputation by assuming a Worst Case scenario. 

-- Note:
--  The score is calculated for *all* ICU patients, with the assumption that the user will subselect appropriate patientunitstayid.

DROP TABLE IF EXISTS pivoted_OASIS; --CASCADE;
CREATE TABLE pivoted_OASIS AS

--WITH pivoted_gcs_OASIS AS (
--    WITH pivoted_vent_OASIS AS (
--      WITH admission_OASIS AS (
SELECT pivoted_OASIS.*,
pivoted_OASIS.patientunitstayid as pid,

-- newly added 
  vent_1, vent_2, vent_3, vent_4, vent_5, vent_6,
  pre_ICU_LOS_OASIS,
  GCS_OASIS,
  heartrate_OASIS,
  MAP_OASIS,
  respiratoryrate_OASIS,
  temperature_OASIS,
  urineoutput_OASIS,
  electivesurgery_OASIS

-- Pre-ICU stay LOS -> directly convert from minutes to hours
 ,CASE
    WHEN COUNT(hospitaladmitoffset) < (0.17*60) THEN 5
    WHEN (COUNT(hospitaladmitoffset) >= (0.17*60) OR COUNT(hospitaladmitoffset) <= (4.94*60) ) THEN 3
    WHEN (COUNT(hospitaladmitoffset) >= (4.94*60) OR COUNT(hospitaladmitoffset) <= (24*60) ) THEN 0
    WHEN (COUNT(hospitaladmitoffset) >= (24.01*60) OR COUNT(hospitaladmitoffset) <= (311.80*60) ) THEN 2
    WHEN COUNT(hospitaladmitoffset) > (311.80*60) THEN 1
    ELSE NULL
    END AS pre_ICU_LOS_OASIS
    GROUP BY pid

-- Age 
-- Change age from string to integer
  ,CASE 
  WHEN pivoted_OASIS.age = "> 89" THEN 91
  ELSE CAST(pivoted_OASIS.age AS INT64) 
  END AS age_OASIS,

  , CASE
    WHEN CAST(age AS INT64) < 24 THEN 0
    WHEN CAST(age AS INT64) (age >= 24 OR age <= 53) THEN 3
    WHEN CAST(age AS INT64) (age >= 54 OR age <= 77) THEN 6
    WHEN CAST(age AS INT64) (age >= 78 OR age <= 89) THEN 9
    WHEN CAST(age AS INT64) age > 89 THEN 7
    ELSE NULL
    END AS age_OASIS

-- Elective admission

-- Mapping
-- Assume emergency admission if patient came from
-- Emergency Department, Direct Admit, Chest Pain Center, Other Hospital, Observation
-- Assume elective admission if patient from other place, e.g. operating room, floor, etc.

  , CASE
  WHEN 
    unitAdmitSource  LIKE "Emergency Department"
    OR unitAdmitSource LIKE "Direct Admit"
    OR unitAdmitSource LIKE "Chest Pain Center"
    OR unitAdmitSource LIKE "Other Hospital"
    OR unitAdmitSource LIKE "Observation"
    THEN 0
  ELSE 1
  END AS adm_elective

FROM `physionet-data.eicu_crd.patient` as pivoted_OASIS 


-------------------------

-- GCS -> 1st Source: eicu_crd_derived.pivoted_gcs
LEFT JOIN(
  SELECT patientunitstayid AS pid
  , CASE
    WHEN COUNT(gcs) < 8 THEN 10
    WHEN (COUNT(gcs) >=8 OR COUNT(gcs) <=13) THEN 4
    WHEN COUNT(gcs) =14 THEN 3
    WHEN COUNT(gcs) =15 THEN 0
    ELSE NULL
    END AS gcs_OASIS

  FROM `physionet-data.eicu_crd_derived.pivoted_gcs`
  GROUP BY pid
)
AS pivoted_gcs
ON pivoted_gcs.pid = pivoted_OASIS.pid

-- GCS -> 2nd Source: eicu_crd.physicalexam
LEFT JOIN(
  SELECT patientunitstayid AS pid, MIN(CAST(physicalexamvalue AS NUMERIC)) AS gcs
  FROM `physionet-data.eicu_crd.physicalexam`
  WHERE  (
  (physicalExamPath LIKE "notes/Progress Notes/Physical Exam/Physical Exam/Neurologic/GCS/_" OR
  physicalExamPath LIKE "notes/Progress Notes/Physical Exam/Physical Exam/Neurologic/GCS/__")
  AND
  (chartoffset > 0 AND chartoffset <= 1440 ) -- convert hours to minutes -> 60*24=1440
  )
)
AS gcs_exam
ON gcs_exam.pid = pivoted_OASIS.pid

-- Heart rate 
LEFT JOIN(
  SELECT patientunitstayid AS pid
  , CASE
    WHEN COUNT(heartrate) < 33 THEN 4
    WHEN (COUNT(heartrate) >=33 OR COUNT(heartrate) <=88) THEN 0
    WHEN (COUNT(heartrate) >=89 OR COUNT(heartrate) <=106) THEN 1
    WHEN (COUNT(heartrate) >=107 OR COUNT(heartrate) <=125) THEN 3
    WHEN COUNT(heartrate) >125 THEN 6
    ELSE NULL
    END AS heartrate_OASIS

  FROM `physionet-data.eicu_crd_derived.pivoted_vital`
  WHERE (chartoffset > 0 AND chartoffset <= 1440 ) -- convert hours to minutes -> 60*24=1440
  GROUP BY pid
)
AS heartrateO
ON heartrateO.pid = pivoted_OASIS.pid

-- Mean arterial pressure
LEFT JOIN(
  SELECT patientunitstayid AS pid
  , CASE
    WHEN COUNT(ibp_mean) < 20.65 THEN 4
    WHEN (COUNT(ibp_mean) >=20.65 OR COUNT(ibp_mean) <=50.99) THEN 3
    WHEN (COUNT(ibp_mean) >=51 OR COUNT(ibp_mean) <=61.32) THEN 2
    WHEN (COUNT(ibp_mean) >=61.33 OR COUNT(ibp_mean) <=143.44) THEN 0
    WHEN COUNT(ibp_mean) >143.44 THEN 3
    
    WHEN COUNT(nibp_mean) < 20.65 THEN 4
    WHEN (COUNT(nibp_mean) >=20.65 OR COUNT(nibp_mean) <=50.99) THEN 3
    WHEN (COUNT(nibp_mean) >=51 OR COUNT(nibp_mean) <=61.32) THEN 2
    WHEN (COUNT(nibp_mean) >=61.33 OR COUNT(nibp_mean) <=143.44) THEN 0
    WHEN COUNT(nibp_mean) >143.44 THEN 3
    ELSE NULL
    END AS MAP_OASIS

  FROM `physionet-data.eicu_crd_derived.pivoted_vital`
  WHERE (chartoffset > 0 AND chartoffset <= 1440 ) -- convert hours to minutes -> 60*24=1440
  GROUP BY pid
)
AS MAP
ON MAP.pid = pivoted_OASIS.pid


-- Respiratory rate
LEFT JOIN(
  SELECT patientunitstayid AS pid
  , CASE
    WHEN COUNT(respiratoryrate) < 6 THEN 10
    WHEN (COUNT(respiratoryrate) >=6 OR COUNT(respiratoryrate) <=12) THEN 1
    WHEN (COUNT(respiratoryrate) >=13 OR COUNT(respiratoryrate) <=22) THEN 0
    WHEN (COUNT(respiratoryrate) >=23 OR COUNT(respiratoryrate) <=30) THEN 1
    WHEN (COUNT(respiratoryrate) >=31 OR COUNT(respiratoryrate) <=44) THEN 6
    WHEN COUNT(respiratoryrate) >44 THEN 9
    ELSE NULL
    END AS respiratoryrate_OASIS

  FROM `physionet-data.eicu_crd_derived.pivoted_vital`
  WHERE (chartoffset > 0 AND chartoffset <= 1440 ) -- convert hours to minutes -> 60*24=1440
  GROUP BY pid
)
AS respiratoryrateO
ON respiratoryrateO.pid = pivoted_OASIS.pid

-- Temperature first 24h -> Mapping according to OASIS
LEFT JOIN(
  SELECT patientunitstayid AS pid
  , CASE
    WHEN COUNT(temperature) < 33.22 THEN 3
    WHEN (COUNT(temperature) >=33.22 OR COUNT(temperature) <=35.93) THEN 4
    WHEN (COUNT(temperature) >=35.94 OR COUNT(temperature) <=36.39) THEN 2
    WHEN (COUNT(temperature) >=36.40 OR COUNT(temperature) <=36.88) THEN 0
    WHEN (COUNT(temperature) >=36.89 OR COUNT(temperature) <=39.88) THEN 2
    WHEN COUNT(temperature) >39.88 THEN 6
    ELSE NULL
    END AS temperature_OASIS

  FROM `physionet-data.eicu_crd_derived.pivoted_vital`
  WHERE (chartoffset > 0 AND chartoffset <= 1440 ) -- convert hours to minutes -> 60*24=1440
  GROUP BY pid
)
AS temperatureO
ON temperatureO.pid = pivoted_OASIS.pid

-- Urine output first 24h -> Mapping according to OASIS
LEFT JOIN(
  SELECT patientunitstayid AS pid
  , CASE
    WHEN COUNT(urineoutput) <671 THEN 10
    WHEN (COUNT(urineoutput) >=671 OR COUNT(urineoutput) <=1426.99) THEN 5
    WHEN (COUNT(urineoutput) >=1427 OR COUNT(urineoutput) <=2543.99) THEN 1
    WHEN (COUNT(urineoutput) >=2544 OR COUNT(urineoutput) <=6896) THEN 0
    WHEN COUNT(urineoutput) >6896 THEN 8
    ELSE NULL
    END AS urineoutput_OASIS

  FROM `physionet-data.eicu_crd_derived.pivoted_uo`
  WHERE (chartoffset > 0 AND chartoffset <= 1440 ) -- convert hours to minutes -> 60*24=1440
  GROUP BY pid
)
AS urineoutputO
ON urineoutputO.pid = pivoted_OASIS.pid

/*
-- Ventilation -> Mapping according to OASIS, see below -> No 0, Yes 9

-- Elective surgery and admissions -> Mapping according to OASIS
LEFT JOIN(
  SELECT patientunitstayid, adm_elective
  , CASE
    WHEN new_elective_surgery = 1 THEN 0
    WHEN new_elective_surgery = 0 THEN 6
    ELSE 0
    -- Analysed admission table -> In most cases -> if elective surgery is NULL -> there was no surgery or emergency surgery
    END AS electivesurgery_OASIS

  FROM `db_name.my_eICU.pivoted_elective`
)
AS electivesurgeryO
ON electivesurgeryO.patientunitstayid = yug.patientunitstayid


-- ventilation events
LEFT JOIN (
  SELECT patientunitstayid, COUNT(event) as vent_1
  FROM `physionet-data.eicu_crd_derived.ventilation_events` 
  WHERE (event = "mechvent start" OR event = "mechvent end")
  GROUP BY patientunitstayid
  )

AS vent_events
ON vent_events.patientunitstayid = yug.patientunitstayid

-- apache aps vars
LEFT JOIN(
  SELECT patientunitstayid, COUNT(intubated) as vent_2
  FROM `physionet-data.eicu_crd.apacheapsvar`
  WHERE intubated = 1
  GROUP BY patientunitstayid
)
AS apachepsvar
ON apachepsvar.patientunitstayid = yug.patientunitstayid

-- apache pred vars
LEFT JOIN(
  SELECT patientunitstayid, COUNT(oobintubday1) as vent_3
  FROM `physionet-data.eicu_crd.apachepredvar`
  WHERE oobintubday1 = 1
  GROUP BY patientunitstayid
)
AS apachepredvar
ON apachepredvar.patientunitstayid = yug.patientunitstayid

-- debug vent tags
LEFT JOIN(
  SELECT patientunitstayid, COUNT(intubated) as vent_4, COUNT(extubated) as vent_5
  FROM `physionet-data.eicu_crd_derived.debug_vent_tags`
  WHERE intubated = 1 OR extubated = 1
  GROUP BY patientunitstayid
)
AS debug_vent_tags
ON debug_vent_tags.patientunitstayid = yug.patientunitstayid

-- respiratory care table
LEFT JOIN(
  SELECT patientunitstayid, CASE
    WHEN COUNT(airwaytype) >= 1 THEN 1
    WHEN COUNT(airwaysize) >= 1 THEN 1
    WHEN COUNT(airwayposition) >= 1 THEN 1
    WHEN COUNT(cuffpressure) >= 1 THEN 1
    WHEN COUNT(setapneatv) >= 1 THEN 1
    ELSE NULL
    END AS vent_6

  FROM `physionet-data.eicu_crd.respiratorycare`
  GROUP BY patientunitstayid
)
AS respiratorycare
ON respiratorycare.patientunitstayid = yug.patientunitstayid



SELECT *

    , CASE
    WHEN vent_1 = 1 THEN 9
    WHEN vent_2 = 1 THEN 9
    WHEN vent_3 = 1 THEN 9
    WHEN vent_4 = 1 THEN 9
    WHEN vent_5 = 1 THEN 9
    WHEN vent_6 = 1 THEN 9
    ELSE 0
    END AS vent_OASIS,

  IFNULL(gcs_OASIS, 10) AS gcs_OASIS_W, 
  IFNULL(urineoutput_OASIS, 10) AS urineoutput_OASIS_W, 
  IFNULL(electivesurgery_OASIS, 6) AS electivesurgery_OASIS_W, 
  IFNULL(temperature_OASIS, 6) AS temperature_OASIS_W, 
  IFNULL(respiratoryrate_OASIS, 10) AS respiratoryrate_OASIS_W,
  IFNULL(heartrate_OASIS, 6) AS heartrate_OASIS_W,
  IFNULL(ibp_mean_oasis, 4) AS ibp_mean_oasis_W,

  IFNULL(gcs_OASIS, 0) AS gcs_OASIS_B, 
  IFNULL(urineoutput_OASIS, 0) AS urineoutput_OASIS_B, 
  IFNULL(electivesurgery_OASIS, 0) AS electivesurgery_OASIS_B, 
  IFNULL(temperature_OASIS, 0) AS temperature_OASIS_B, 
  IFNULL(respiratoryrate_OASIS, 0) AS respiratoryrate_OASIS_B,
  IFNULL(heartrate_OASIS, 0) AS heartrate_OASIS_B,
  IFNULL(ibp_mean_oasis, 0) AS ibp_mean_oasis_B

FROM tt)

--Compute overall scores -> Fist Worst, then Best Case Scenario
 SELECT *,

    (hospitaladmitoffset_OASIS + gcs_OASIS + heartrate_OASIS +
    ibp_mean_OASIS + respiratoryrate_OASIS + temperature_OASIS +
    urineoutput_OASIS + electivesurgery_OASIS + age_OASIS + vent_OASIS) AS score_OASIS_Nulls,

    (hospitaladmitoffset_OASIS + gcs_OASIS_W + heartrate_OASIS_W +
    ibp_mean_OASIS_W + respiratoryrate_OASIS_W + temperature_OASIS_W +
    urineoutput_OASIS_W + electivesurgery_OASIS_W + age_OASIS + vent_OASIS) AS score_OASIS_W

FROM tt2)

 SELECT *,
 
    (hospitaladmitoffset_OASIS + gcs_OASIS_B + heartrate_OASIS_B +
    ibp_mean_OASIS_B + respiratoryrate_OASIS_B + temperature_OASIS_B +
    urineoutput_OASIS_B + electivesurgery_OASIS_B + age_OASIS + vent_OASIS) AS score_OASIS_B

FROM tt3

*/

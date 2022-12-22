
WITH tt3 AS (
    WITH tt2 AS (
      WITH tt AS (

SELECT yug.*,
yug.patientunitstayid as pid, 
-- to match MIMIC's names
yug.Charlson as charlson_comorbidity_index,
yug.ethnicity as race,

CASE 
WHEN yug.age = "> 89" THEN 91
ELSE CAST(yug.age AS INT64) 
END AS anchor_age,

yug.sofa_admit as SOFA, 
yug.hospitaldischargeyear as anchor_year_group,

-- newly added 
vent_1, vent_2, vent_3, vent_4, vent_5, vent_6,
rrt_1,
pressor_1, pressor_2, pressor_3, pressor_4, 
apachepatientresultO.apachescore, apachepatientresultO.acutephysiologyscore, apachepatientresultO.apache_pred_hosp_mort,
hospitaladmitoffset_OASIS,
gcs_OASIS,
heartrate_OASIS,
ibp_mean_OASIS,
respiratoryrate_OASIS,
temperature_OASIS,
urineoutput_OASIS,
adm_elective,
electivesurgery_OASIS

FROM `db_name.my_eICU.yugang` as yug 

-- Pre-ICU stay LOS -> Mapping according to OASIS -> convert from hours to minutes
LEFT JOIN(
  SELECT patientunitstayid, CASE
    WHEN COUNT(hospitaladmitoffset) < (0.17*60) THEN 5
    WHEN (COUNT(hospitaladmitoffset) >= (0.17*60) OR COUNT(hospitaladmitoffset) <= (4.94*60) ) THEN 3
    WHEN (COUNT(hospitaladmitoffset) >= (4.94*60) OR COUNT(hospitaladmitoffset) <= (24*60) ) THEN 0
    WHEN (COUNT(hospitaladmitoffset) >= (24.01*60) OR COUNT(hospitaladmitoffset) <= (311.80*60) ) THEN 2
    WHEN COUNT(hospitaladmitoffset) > (311.80*60) THEN 1
    ELSE NULL
    END AS hospitaladmitoffset_OASIS

  FROM `physionet-data.eicu_crd.patient`
  GROUP BY patientunitstayid
)
AS hospitaladmitoffsetO
ON hospitaladmitoffsetO.patientunitstayid = yug.patientunitstayid

-- Age -> Mapping according to OASIS below
-- <24 = 0, 24-53 = 3, 54-77 = 6, 78-89 =9 ,>90 =7

-- GCS -> Mapping according to OASIS
LEFT JOIN(
  SELECT patientunitstayid, CASE
    WHEN COUNT(gcs) < 8 THEN 10
    WHEN (COUNT(gcs) >=8 OR COUNT(gcs) <=13) THEN 4
    WHEN COUNT(gcs) =14 THEN 3
    WHEN COUNT(gcs) =15 THEN 0
    ELSE NULL
    END AS gcs_OASIS

  FROM `db_name.my_eICU.OASIS_GCS`
  GROUP BY patientunitstayid
)
AS gcsO
ON gcsO.patientunitstayid = yug.patientunitstayid

-- Heart rate -> Mapping according to OASIS
LEFT JOIN(
  SELECT patientunitstayid, CASE
    WHEN COUNT(heartrate) < 33 THEN 4
    WHEN (COUNT(heartrate) >=33 OR COUNT(heartrate) <=88) THEN 0
    WHEN (COUNT(heartrate) >=89 OR COUNT(heartrate) <=106) THEN 1
    WHEN (COUNT(heartrate) >=107 OR COUNT(heartrate) <=125) THEN 3
    WHEN COUNT(heartrate) >125 THEN 6
    ELSE NULL
    END AS heartrate_OASIS

  FROM `physionet-data.eicu_crd_derived.pivoted_vital`
  WHERE (chartoffset > 0 AND chartoffset <= 1440 ) -- convert hours to minutes -> 60*24=1440
  GROUP BY patientunitstayid
)
AS heartrateO
ON heartrateO.patientunitstayid = yug.patientunitstayid

-- Mean arterial pressure -> Mapping according to OASIS
LEFT JOIN(
  SELECT patientunitstayid, CASE
    WHEN COUNT(ibp_mean) < 20.65 THEN 4
    WHEN (COUNT(ibp_mean) >=20.65 OR COUNT(ibp_mean) <=50.99) THEN 3
    WHEN (COUNT(ibp_mean) >=51 OR COUNT(ibp_mean) <=61.32) THEN 2
    WHEN (COUNT(ibp_mean) >=61.33 OR COUNT(ibp_mean) <=143.44) THEN 0
    WHEN COUNT(ibp_mean) >143.44 THEN 3
    ELSE NULL
    END AS ibp_mean_OASIS

  FROM `physionet-data.eicu_crd_derived.pivoted_vital`
  WHERE (chartoffset > 0 AND chartoffset <= 1440 ) -- convert hours to minutes -> 60*24=1440
  GROUP BY patientunitstayid
)
AS ibp_meanO
ON ibp_meanO.patientunitstayid = yug.patientunitstayid


-- Respiratory rate -> Mapping according to OASIS
LEFT JOIN(
  SELECT patientunitstayid, CASE
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
  GROUP BY patientunitstayid
)
AS respiratoryrateO
ON respiratoryrateO.patientunitstayid = yug.patientunitstayid

-- Temperature first 24h -> Mapping according to OASIS
LEFT JOIN(
  SELECT patientunitstayid, CASE
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
  GROUP BY patientunitstayid
)
AS temperatureO
ON temperatureO.patientunitstayid = yug.patientunitstayid

-- Urine output first 24h -> Mapping according to OASIS
LEFT JOIN(
  SELECT patientunitstayid, CASE
    WHEN COUNT(urineoutput) <671 THEN 10
    WHEN (COUNT(urineoutput) >=671 OR COUNT(urineoutput) <=1426.99) THEN 5
    WHEN (COUNT(urineoutput) >=1427 OR COUNT(urineoutput) <=2543.99) THEN 1
    WHEN (COUNT(urineoutput) >=2544 OR COUNT(urineoutput) <=6896) THEN 0
    WHEN COUNT(urineoutput) >6896 THEN 8
    ELSE NULL
    END AS urineoutput_OASIS

  FROM `db_name.icu_elos.pivoted_uo_24h`
  GROUP BY patientunitstayid
)
AS urineoutputO
ON urineoutputO.patientunitstayid = yug.patientunitstayid

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


-- APACHE IV
LEFT JOIN(
  SELECT patientunitstayid, 
  apachescore,
  acutephysiologyscore,
  predictedhospitalmortality as apache_pred_hosp_mort
  FROM `physionet-data.eicu_crd.apachepatientresult`
  WHERE apacheversion = "IVa"
)
AS apachepatientresultO
ON apachepatientresultO.patientunitstayid = yug.patientunitstayid


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


-- treatment table to get RRT
LEFT JOIN(
  SELECT patientunitstayid, COUNT(treatmentstring) as rrt_1
  FROM `physionet-data.eicu_crd.treatment` 
  WHERE (
    treatmentstring LIKE "renal|dialysis|C%" OR 
    treatmentstring LIKE "renal|dialysis|hemodialysis|emergent%" OR 
    treatmentstring LIKE "renal|dialysis|hemodialysis|for acute renal failure" OR
    treatmentstring LIKE "renal|dialysis|hemodialysis"
    )
  GROUP BY patientunitstayid
)
AS treatment
ON treatment.patientunitstayid = yug.patientunitstayid


-- pivoted infusions table to get vasopressors
LEFT JOIN(
  SELECT patientunitstayid, CASE
    WHEN COUNT(dopamine) >= 1 THEN 1
    WHEN COUNT(dobutamine) >= 1 THEN 1
    WHEN COUNT(norepinephrine) >= 1 THEN 1
    WHEN COUNT(phenylephrine) >= 1 THEN 1
    WHEN COUNT(epinephrine) >= 1 THEN 1
    WHEN COUNT(vasopressin) >= 1 THEN 1
    WHEN COUNT(milrinone) >= 1 THEN 1
    ELSE NULL
    END AS pressor_1  

  FROM `physionet-data.eicu_crd_derived.pivoted_infusion`
  GROUP BY patientunitstayid
)
AS pivoted_infusion
ON pivoted_infusion.patientunitstayid = yug.patientunitstayid

-- infusions table to get vasopressors
LEFT JOIN(
  SELECT patientunitstayid, COUNT(drugname) as pressor_2
  FROM `physionet-data.eicu_crd.infusiondrug`
  WHERE(
    LOWER(drugname) LIKE '%dopamine%' OR
    LOWER(drugname) LIKE '%dobutamine%' OR
    LOWER(drugname) LIKE '%norepinephrine%' OR
    LOWER(drugname) LIKE '%phenylephrine%' OR
    LOWER(drugname) LIKE '%epinephrine%' OR
    LOWER(drugname) LIKE '%vasopressin%' OR
    LOWER(drugname) LIKE '%milrinone%' OR
    LOWER(drugname) LIKE '%dobutrex%' OR
    LOWER(drugname) LIKE '%neo synephrine%' OR
    LOWER(drugname) LIKE '%neo-synephrine%' OR
    LOWER(drugname) LIKE '%neosynephrine%' OR
    LOWER(drugname) LIKE '%neosynsprine%'
  )
  GROUP BY patientunitstayid
)
AS infusiondrug
ON infusiondrug.patientunitstayid = yug.patientunitstayid

-- medication
LEFT JOIN(
  SELECT patientunitstayid, COUNT(drugname) as pressor_3
  FROM `physionet-data.eicu_crd.medication`
  WHERE(
    LOWER(drugname) LIKE '%dopamine%' OR
    LOWER(drugname) LIKE '%dobutamine%' OR
    LOWER(drugname) LIKE '%norepinephrine%' OR
    LOWER(drugname) LIKE '%phenylephrine%' OR
    LOWER(drugname) LIKE '%epinephrine%' OR
    LOWER(drugname) LIKE '%vasopressin%' OR
    LOWER(drugname) LIKE '%milrinone%' OR
    LOWER(drugname) LIKE '%dobutrex%' OR
    LOWER(drugname) LIKE '%neo synephrine%' OR
    LOWER(drugname) LIKE '%neo-synephrine%' OR
    LOWER(drugname) LIKE '%neosynephrine%' OR
    LOWER(drugname) LIKE '%neosynsprine%'
  )
  GROUP BY patientunitstayid
)
AS medication
ON medication.patientunitstayid = yug.patientunitstayid

-- pivoted med
LEFT JOIN(
  SELECT patientunitstayid, CASE
    WHEN SUM(dopamine) >= 1 THEN 1
    WHEN SUM(dobutamine) >= 1 THEN 1
    WHEN SUM(norepinephrine) >= 1 THEN 1
    WHEN SUM(phenylephrine) >= 1 THEN 1
    WHEN SUM(epinephrine) >= 1 THEN 1
    WHEN SUM(vasopressin) >= 1 THEN 1
    WHEN SUM(milrinone) >= 1 THEN 1
    ELSE NULL
    END AS pressor_4

  FROM `physionet-data.eicu_crd_derived.pivoted_med`
  GROUP BY patientunitstayid
)
AS pivoted_med
ON pivoted_med.patientunitstayid = yug.patientunitstayid

-- exclude non-first stays
LEFT JOIN(
  SELECT patientunitstayid, unitvisitnumber
  FROM `physionet-data.eicu_crd_derived.icustay_detail`
) 
AS icustay_detail
ON icustay_detail.patientunitstayid = yug.patientunitstayid

WHERE icustay_detail.unitvisitnumber = 1
AND yug.ethnicity != "Other/Unknown"
AND yug.age != "16" AND yug.age != "17"
)


SELECT *

    , CASE
    WHEN anchor_age < 24 THEN 0
    WHEN (anchor_age >= 24 OR anchor_age <= 53) THEN 3
    WHEN (anchor_age >= 54 OR anchor_age <= 77) THEN 6
    WHEN (anchor_age >= 78 OR anchor_age <= 89) THEN 9
    WHEN anchor_age > 90 THEN 7
    ELSE NULL
    END AS age_OASIS

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


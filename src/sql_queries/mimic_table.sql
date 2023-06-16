WITH 
  fio2_table AS (

  SELECT
    icu.subject_id
  , icu.stay_id
  , AVG(COALESCE(fio2,fio2_chartevents, NULL)) AS FiO2_mean_24h

  FROM `db_name.mimiciv_derived.icustay_detail` icu

  LEFT JOIN `physionet-data.mimiciv_derived.bg` 
  AS fio2_table
  ON fio2_table.subject_id = icu.subject_id
  WHERE TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) <= 1440 
  AND TIMESTAMP_DIFF(fio2_table.charttime, icu.admittime, MINUTE) >= 0
  GROUP BY subject_id, stay_id
),
  fluids_table AS (
    SELECT ce.stay_id
    , SUM(amount) AS fluids_volume
    , SUM(amount)/MAX(icu.los_icu) AS fluids_volume_norm_by_los_icu
    , MAX(icu.los_icu) AS los_icu
    FROM  `physionet-data.mimiciv_icu.inputevents` ce
    LEFT JOIN `db_name.mimiciv_derived.icustay_detail` icu
    ON icu.stay_id = ce.stay_id
    WHERE itemid IN (220952,225158,220954,220955,220958,220960,220961,220962,221212,221213,220861,220863)
    AND amount is NOT NULL
    AND amount > 0 
    AND icu.los_icu > 0
    GROUP BY stay_id
)

SELECT sepsis3, icu.*
  , CASE 
      WHEN (
         LOWER(icu.race) LIKE "%white%"
      OR LOWER(icu.race) LIKE "%portuguese%" 
      OR LOWER(icu.race) LIKE "%caucasian%" 
      ) THEN "White"
      WHEN (
         LOWER(icu.race) LIKE "%black%"
      OR LOWER(icu.race) LIKE "%african american%"
      ) THEN "Black"
      WHEN (
         LOWER(icu.race) LIKE "%hispanic%"
      OR LOWER(icu.race) LIKE "%south american%" 
      ) THEN "Hispanic"
      WHEN (
         LOWER(icu.race) LIKE "%asian%"
      ) THEN "Asian"
      ELSE "Other"
    END AS race_group
  
  , CASE WHEN icu.gender = "F" THEN 1 ELSE 0 END AS sex_female,


fluids_table.los_icu, adm.adm_type, adm.adm_elective
, ad.language
, CASE WHEN ad.language = "ENGLISH" THEN 1 ELSE 0 END AS eng_prof
, ad.insurance
, CASE WHEN ad.insurance = "Other" THEN 1 ELSE 0 END AS private_insurance
, pat.anchor_age,pat.anchor_year_group,sf.SOFA,
sf.respiration, sf.coagulation, sf.liver, sf.cardiovascular, sf.cns, sf.renal,
rrt.rrt, weight.weight_admit,fd_uo.urineoutput,
charlson.charlson_comorbidity_index, (pressor.stay_id = icu.stay_id) as pressor,ad.discharge_location as discharge_location, pat.dod,
InvasiveVent.InvasiveVent_hr,Oxygen.Oxygen_hr,HighFlow.HighFlow_hr,NonInvasiveVent.NonInvasiveVent_hr,Trach.Trach_hr, FiO2_mean_24h,

-- Treatment durations
MV_time_hr/24 AS mv_time_d, vp_time_hr/24 AS vp_time_d, rrt_time_hr/24 AS rrt_time_d,
MV_time_hr/24/icu.los_icu AS MV_time_perc_of_stay, vp_time_hr/24/icu.los_icu AS VP_time_perc_of_stay,

-- MV as offset as fraction of LOS
CASE
  WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) >= 0
  THEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR)/24/icu.los_icu
  WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) < 0
  THEN 0
  ELSE NULL
END AS MV_init_offset_perc,

-- MV as offset absolut in days
CASE
  WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) >= 0
  THEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR)/24
  WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) < 0
  THEN 0
  ELSE NULL
END AS MV_init_offset_d_abs,

-- RRT as offset as fraction of LOS
CASE
  WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) >= 0
  THEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR)/24/icu.los_icu
  WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) < 0
  THEN 0
  ELSE NULL
END AS RRT_init_offset_perc,

-- RRT as offset absolut in days
CASE
  WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) >= 0
  THEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR)/24
  WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) < 0
  THEN 0
  ELSE NULL
END AS RRT_init_offset_d_abs,

-- VP as offset as fraction of LOS
CASE
  WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) >= 0
  THEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR)/24/icu.los_icu
  WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) < 0
  THEN 0
  ELSE NULL
END AS VP_init_offset_perc,

-- VP as offset absolut in days
CASE
  WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) >= 0
  THEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR)/24
  WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) < 0
  THEN 0
  ELSE NULL
END AS VP_init_offset_d_abs,

oa.oasis, oa.oasis_prob,
fluids_volume, fluids_volume_norm_by_los_icu,
transfusion_yes, insulin_yes, major_surgery, resp_rate_mean, mbp_mean, heart_rate_mean, temperature_mean, spo2_mean, first_code, last_code,
001 AS hospitalid, -- dummy variable for hospitalid in eICU
">= 500" AS numbedscategory, -- dummy variable for numbedscategory in eICU
"true" AS teachingstatus, -- is boolean in eICU
"Northeast" AS region, -- dummy variable for US census region in eICU

-- lab values 
po2_min, pco2_max, ph_min, lactate_max, glucose_max, sodium_min, potassium_max, cortisol_min, hemoglobin_min, fibrinogen_min, inr_max, 
hypertension_present, heart_failure_present, copd_present, asthma_present, cad_present, ckd_stages, diabetes_types, connective_disease,
pneumonia, uti, biliary, skin, clabsi, cauti, ssi, vap,

ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) as dod_icuout_offset

  , CASE
      WHEN codes.first_code IS NULL
        OR codes.first_code = "Full code" 
      THEN 1
      ELSE 0
    END AS is_full_code_admission
  
  , CASE
      WHEN codes.last_code IS NULL
        OR codes.last_code = "Full code" 
      THEN 1
      ELSE 0
    END AS is_full_code_discharge


  , CASE WHEN (
         discharge_location = "DIED"
      OR discharge_location = "HOSPICE"
  ) THEN 1
    ELSE 0
  END AS mortality_in

  , CASE WHEN (
         discharge_location = "DIED"
      OR discharge_location = "HOSPICE"
      OR ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) <= 90
  ) THEN 1
    ELSE 0
  END AS mortality_90

from `physionet-data.mimiciv_derived.icustay_detail` as icu 

-- Start of Left Joins
left join `physionet-data.mimiciv_derived.sepsis3` as s3
on s3.stay_id = icu.stay_id

left join `physionet-data.mimiciv_hosp.patients` as pat
on icu.subject_id = pat.subject_id

left join `physionet-data.mimiciv_hosp.admissions` as ad
on icu.hadm_id = ad.hadm_id

left join `physionet-data.mimiciv_derived.first_day_sofa` as sf
on icu.stay_id = sf.stay_id 

left join `physionet-data.mimiciv_derived.first_day_weight` as weight
on icu.stay_id = weight.stay_id 

left join `physionet-data.mimiciv_derived.charlson` as charlson
on icu.hadm_id = charlson.hadm_id 

left join `physionet-data.mimiciv_derived.first_day_urine_output` as fd_uo
on icu.stay_id = fd_uo.stay_id 

-- rrt
left join (select distinct stay_id, dialysis_present as rrt  from `physionet-data.mimiciv_derived.rrt` where dialysis_present = 1) as rrt
on icu.stay_id = rrt.stay_id 

-- RRT initiation offset
left join (
  SELECT dia.stay_id,
  MAX(dialysis_present) AS rrt,
  MIN(charttime) AS charttime,
  TIMESTAMP_DIFF(MAX(charttime), MIN(charttime), HOUR) AS rrt_time_hr
  FROM `physionet-data.mimiciv_derived.rrt` dia

  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = dia.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, charttime, HOUR) > 0 -- to make sure it's within the ICU stay
  AND TIMESTAMP_DIFF(charttime, icu.icu_intime, HOUR) > 0
  WHERE dialysis_type like "C%" OR dialysis_type like "IHD" -- only consider hemodialyisis
  GROUP BY stay_id
) AS rrt_time
ON icu.stay_id = rrt_time.stay_id 

-- vasopressors
left join (select distinct stay_id from  `physionet-data.mimiciv_derived.epinephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.norepinephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.phenylephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.vasopressin`) as pressor
on icu.stay_id = pressor.stay_id 

-- for VP percentage of stay
LEFT JOIN(
  SELECT
    nor.stay_id
    , SUM(TIMESTAMP_DIFF(endtime, starttime, HOUR)) AS vp_time_hr
  FROM `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose` nor
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = nor.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  GROUP BY stay_id
) AS vp_time
ON vp_time.stay_id = icu.stay_id

-- VPs offset initiation
LEFT JOIN(
  SELECT
    nor.stay_id
    , MIN(starttime) AS starttime
  FROM `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose` nor
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = nor.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  GROUP BY stay_id
) AS vp_mtime
ON vp_mtime.stay_id = icu.stay_id

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as InvasiveVent_hr
FROM `physionet-data.mimiciv_derived.ventilation` where ventilation_status = "InvasiveVent" group by stay_id) as InvasiveVent
on InvasiveVent.stay_id = icu.stay_id

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as Oxygen_hr
FROM `physionet-data.mimiciv_derived.ventilation` where ventilation_status = "Oxygen" group by stay_id) as Oxygen
on Oxygen.stay_id = icu.stay_id

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as HighFlow_hr
FROM `physionet-data.mimiciv_derived.ventilation` where ventilation_status = "HighFlow" group by stay_id) as HighFlow
on HighFlow.stay_id = icu.stay_id

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as NonInvasiveVent_hr
FROM `physionet-data.mimiciv_derived.ventilation` where ventilation_status = "NonInvasiveVent" group by stay_id) as NonInvasiveVent
on NonInvasiveVent.stay_id = icu.stay_id

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as Trach_hr
FROM `physionet-data.mimiciv_derived.ventilation` where ventilation_status = "Trach" group by stay_id) as Trach
on Trach.stay_id = icu.stay_id

-- for MV perc of stay
left join (
  SELECT vent.stay_id,
  SUM(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as MV_time_hr
  FROM `physionet-data.mimiciv_derived.ventilation` vent
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = vent.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  WHERE (ventilation_status = "Trach" OR ventilation_status = "InvasiveVent")
  GROUP BY stay_id
) AS mv_time
ON mv_time.stay_id = icu.stay_id

-- for MV initation offset 
LEFT JOIN (
  SELECT vent.stay_id, MIN(starttime) as starttime
  FROM `physionet-data.mimiciv_derived.ventilation` vent
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = vent.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  WHERE (ventilation_status = "Trach" OR ventilation_status = "InvasiveVent")
  GROUP BY stay_id
)
AS mv_mtime
ON mv_mtime.stay_id = icu.stay_id

-- FiO2 table
LEFT JOIN fio2_table
ON fio2_table.stay_id = icu.stay_id

-- Add admission type
-- Mapping: 
-- Emergency: ‘AMBULATORY OBSERVATION’, ‘DIRECT EMER.’, ‘URGENT’, ‘EW EMER.’, ‘DIRECT OBSERVATION’, ‘EU OBSERVATION’, ‘OBSERVATION ADMIT’
-- Elective: ‘ELECTIVE’, ‘SURGICAL SAME DAY ADMISSION’

LEFT JOIN (SELECT hadm_id, admission_type as adm_type,
CASE
    WHEN (admission_type LIKE "%ELECTIVE%" OR
     admission_type LIKE "%SURGICAL SAME DAY ADMISSION%") 
     THEN 1
     ELSE 0
     END AS adm_elective
FROM `physionet-data.mimiciv_hosp.admissions`) as adm
on adm.hadm_id = icu.hadm_id

-- Add OASIS Score
LEFT JOIN (SELECT stay_id, oasis, oasis_prob
FROM `physionet-data.mimiciv_derived.oasis`) as oa
on oa.stay_id = icu.stay_id

-- Add Transfusions
LEFT JOIN (
SELECT ce.stay_id --, amount --, valueuom --itemid
, max(
    CASE
    WHEN ce.itemid IN ( 226368, 227070, 220996, 221013,226370) THEN 1
    ELSE 0
    END) AS transfusion_yes
FROM  `physionet-data.mimiciv_icu.inputevents` ce
WHERE itemid IN (226368, 227070, 220996, 221013, 226370) 
and amount is NOT NULL and amount >0 
GROUP BY stay_id
)
AS ce
ON ce.stay_id = icu.stay_id

-- Add insulin treatment as negative control
LEFT JOIN (
  SELECT cee.stay_id --, amount --, valueuom --itemid
  , max(
      CASE
      WHEN cee.itemid IN (223257, 223258, 223259, 223260, 223261, 223262, 229299, 229619) THEN 1
      ELSE 0
      END) AS insulin_yes
  FROM  `physionet-data.mimiciv_icu.inputevents` cee
  
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = cee.stay_id

  WHERE itemid IN (223257, 223258, 223259, 223260, 223261, 223262, 229299, 229619)
  AND amount IS NOT NULL 
  AND amount > 0 
  AND TIMESTAMP_DIFF(icu.icu_outtime, cee.starttime, HOUR) >= 0 -- to make sure it's first 1 ICU day
  AND TIMESTAMP_DIFF(cee.starttime, icu.icu_intime, HOUR) <= 24

  GROUP BY stay_id
)
AS cee
ON cee.stay_id = icu.stay_id


-- Add Lab from original table
-- minimal whole stay cortisol and hemoglobin
LEFT JOIN (
SELECT hadm_id,
MIN(
    CASE
    WHEN lab.itemid IN (50909) THEN valuenum
    ELSE NULL
    END) AS cortisol_min,

MIN(
    CASE
    WHEN lab.itemid IN (50811, 51222) THEN valuenum
    ELSE NULL
    END) AS hemoglobin_min

FROM `physionet-data.mimiciv_hosp.labevents` AS lab
where itemid IN (50909, 50811, 51222)
GROUP BY hadm_id
)
AS lab
ON lab.hadm_id = icu.hadm_id

-- Add Lab values from derived tables
LEFT JOIN (
SELECT stay_id,
glucose_max, sodium_min, potassium_max,
fibrinogen_min, inr_max
FROM `physionet-data.mimiciv_derived.first_day_lab` AS dl
)
AS dl
ON dl.stay_id = icu.stay_id

LEFT JOIN (
SELECT stay_id,
ph_min, lactate_max 

FROM `physionet-data.mimiciv_derived.first_day_bg` AS bg
)
AS bg
ON bg.stay_id = icu.stay_id

LEFT JOIN (
SELECT stay_id,
po2_min, pco2_max

FROM `physionet-data.mimiciv_derived.first_day_bg_art` AS bgart
)
AS bgart
ON bgart.stay_id = icu.stay_id

-- Add Vital Signs
LEFT JOIN(
  SELECT
      stay_id
    , resp_rate_mean
    , mbp_mean
    , heart_rate_mean
    , temperature_mean
    , spo2_mean
  FROM `db_name.mimiciv_derived.first_day_vitalsign`
) AS vs
ON vs.stay_id = icu.stay_id

-- Add Code
LEFT JOIN (
  SELECT
      stay_id
    , first_code
    , last_code
  FROM `db_name.my_MIMIC.pivoted_codes`
) AS codes
ON codes.stay_id = icu.stay_id

-- Add major surgery based on Alistair's OASIS implementation
LEFT JOIN (
 
 WITH surgflag as (
 SELECT ie.stay_id
        , MAX(CASE
            WHEN LOWER(curr_service) LIKE '%surg%' THEN 1
            WHEN curr_service = 'ORTHO' THEN 1
            ELSE NULL END) AS major_surgery
        
        , MAX(CASE
            WHEN first_careunit LIKE  "%SICU%" AND
            first_careunit NOT LIKE "%MICU/SICU%"  THEN 1
            ELSE NULL END) AS surgical_icu

    FROM mimiciv_icu.icustays ie

    LEFT JOIN mimiciv_hosp.services se
        ON ie.hadm_id = se.hadm_id
        AND se.transfertime < DATETIME_ADD(ie.intime, INTERVAL '2' DAY)
    GROUP BY ie.stay_id
 )  
  SELECT *
  FROM surgflag
  WHERE major_surgery = 1 OR surgical_icu = 1
) 
AS ms
ON ms.stay_id = icu.stay_id

-- Add comorbidities, conditions present on admission, and complications
LEFT JOIN `db_name.my_MIMIC.pivoted_comorbidities` AS com
ON com.hadm_id = icu.hadm_id

-- Add fluids' volume
LEFT JOIN fluids_table
ON fluids_table.stay_id = icu.stay_id

WHERE icu.los_icu > 0

order by icu.subject_id, icu.hadm_id, icu.stay_id, icu.hospstay_seq, icu.icustay_seq

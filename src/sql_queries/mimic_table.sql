WITH 
  bg AS (

  SELECT
    icu.subject_id
  , icu.stay_id
  , AVG(COALESCE(fio2,fio2_chartevents, NULL)) AS FiO2_mean_24h

  FROM `protean-chassis-368116.mimiciv_derived.icustay_detail` icu

  LEFT JOIN `physionet-data.mimiciv_derived.bg` 
  AS bg
  ON bg.subject_id = icu.subject_id
  WHERE TIMESTAMP_DIFF(bg.charttime, icu.admittime, MINUTE) <= 1440 
  AND TIMESTAMP_DIFF(bg.charttime, icu.admittime, MINUTE) >= 0
  GROUP BY subject_id, stay_id
)

SELECT icu.*, adm.adm_type, adm.adm_elective, pat.anchor_age,pat.anchor_year_group,sf.SOFA,
sf.respiration, sf.coagulation, sf.liver, sf.cardiovascular, sf.cns, sf.renal,
rrt.rrt, weight.weight_admit,fd_uo.urineoutput,
charlson.charlson_comorbidity_index, (pressor.stay_id = icu.stay_id) as pressor,ad.discharge_location as discharge_location, pat.dod,
InvasiveVent.InvasiveVent_hr,Oxygen.Oxygen_hr,HighFlow.HighFlow_hr,NonInvasiveVent.NonInvasiveVent_hr,Trach.Trach_hr, FiO2_mean_24h,
MV_time_hr/24/icu.los_icu AS MV_time_perc_of_stay, vp_time_hr/24/icu.los_icu AS VP_time_perc_of_stay,
CASE
  WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.admittime, MINUTE) >= 0
  THEN TIMESTAMP_DIFF(rrt_time.charttime, icu.admittime, MINUTE)
  WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.admittime, MINUTE) < 0
  THEN 0
  ELSE NULL
END AS RRT_init_offset_minutes,
oa.oasis, oa.oasis_prob,
transfusion_yes, resp_rate_mean, mbp_mean, heart_rate_mean, temperature_mean, spo2_mean, first_code, last_code,
ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) as dod_icuout_offset

from `physionet-data.mimiciv_derived.icustay_detail` as icu 
inner join `physionet-data.mimiciv_derived.sepsis3` as s3
on s3.stay_id = icu.stay_id
and s3.sepsis3 is true

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

left join (select stay_id, max(dialysis_present) as rrt, min(charttime) as charttime
from `physionet-data.mimiciv_derived.rrt`
where dialysis_present = 1
group by stay_id)
as rrt_time
on icu.stay_id = rrt_time.stay_id 

-- vasopressors
left join (select distinct stay_id from  `physionet-data.mimiciv_derived.epinephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.norepinephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.phenylephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.vasopressin`) as pressor
on icu.stay_id = pressor.stay_id 

LEFT JOIN(
  SELECT
    stay_id
    , SUM(TIMESTAMP_DIFF(endtime, starttime, HOUR)) AS vp_time_hr
  FROM `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose`
  GROUP BY stay_id
) AS vp_time
ON vp_time.stay_id = icu.stay_id

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

left join (SELECT stay_id, sum(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as MV_time_hr
FROM `physionet-data.mimiciv_derived.ventilation` where (ventilation_status = "Trach" or ventilation_status = "InvasiveVent") group by stay_id) as mv_time
on mv_time.stay_id = icu.stay_id

-- FiO2 table
LEFT JOIN bg
ON bg.stay_id = icu.stay_id

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
            WHEN ce.itemid IN ( 226368, 227070, 220996, 221013,226370
                              ) THEN 1
            ELSE 0
          END ) AS transfusion_yes
FROM  `physionet-data.mimiciv_icu.inputevents` ce
WHERE itemid IN (226368, 227070, 220996, 221013,226370) 
and amount is NOT NULL and amount >0 
GROUP BY stay_id
)
AS ce
ON ce.stay_id = icu.stay_id

-- Add Vital Signs
LEFT JOIN(
  SELECT
      stay_id
    , resp_rate_mean
    , mbp_mean
    , heart_rate_mean
    , temperature_mean
    , spo2_mean
  FROM `protean-chassis-368116.mimiciv_derived.first_day_vitalsign`
) AS vs
ON vs.stay_id = icu.stay_id

-- Add Code
LEFT JOIN (
  SELECT
      stay_id
    , first_code
    , last_code
  FROM `protean-chassis-368116.my_MIMIC.pivoted_codes`
) AS codes
ON codes.stay_id = icu.stay_id


WHERE (icu.first_icu_stay IS TRUE AND icu.first_hosp_stay IS TRUE)
AND (discharge_location is not null OR abs(timestamp_diff(pat.dod,icu.icu_outtime,DAY)) < 4)
AND (icu.race != "UNKNOWN")
AND (icu.race != "UNABLE TO OBTAIN")
AND (icu.race != "PATIENT DECLINED TO ANSWER")
AND (icu.race != "OTHER")


order by icu.hadm_id
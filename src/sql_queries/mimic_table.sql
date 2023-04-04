select icu.*, adm.adm_type, adm.adm_elective, pat.anchor_age,pat.anchor_year_group,sf.SOFA,rrt.rrt, weight.weight_admit,fd_uo.urineoutput,
charlson.charlson_comorbidity_index, (pressor.stay_id = icu.stay_id) as pressor,ad.discharge_location as discharge_location, ad.insurance, pat.dod,
InvasiveVent.InvasiveVent_hr,Oxygen.Oxygen_hr,HighFlow.HighFlow_hr, NonInvasiveVent.NonInvasiveVent_hr,Trach.Trach_hr, oa.oasis, oa.oasis_prob,
transfusion_yes,
001 AS hospitalid, -- dummy variable for hospitalid in eICU
">= 500" AS numbedscategory, -- dummy variable for numbedscategory in eICU
"true" AS teachingstatus, -- is boolean in eICU
"Northeast" AS region, -- dummy variable for US census region in eICU
-- lab values 
po2_min, pco2_max, ph_min, lactate_max, glucose_max, sodium_min, potassium_max, cortisol_min, hemoglobin_min, fibrinogen_min, inr_max, 

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

left join (select distinct stay_id, dialysis_present as rrt  from `physionet-data.mimiciv_derived.rrt` where dialysis_present = 1) as rrt
on icu.stay_id = rrt.stay_id 

left join (select distinct stay_id from  `physionet-data.mimiciv_derived.epinephrine`
union distinct 
-- select distinct stay_id from  `physionet-data.mimiciv_derived.dobutamine`
-- union distinct 
-- select distinct stay_id from  `physionet-data.mimiciv_derived.dopamine`
-- union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.norepinephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.phenylephrine`
union distinct 
select distinct stay_id from  `physionet-data.mimiciv_derived.vasopressin`) as pressor
on icu.stay_id = pressor.stay_id 

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

WHERE (icu.first_icu_stay IS TRUE AND icu.first_hosp_stay IS TRUE)
AND (discharge_location is not null OR abs(timestamp_diff(pat.dod,icu.icu_outtime,DAY)) < 4)
AND (icu.race != "UNKNOWN")
AND (icu.race != "UNABLE TO OBTAIN")
AND (icu.race != "PATIENT DECLINED TO ANSWER")
AND (icu.race != "OTHER")


order by icu.hadm_id
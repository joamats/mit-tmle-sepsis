select icu.*, pat.anchor_age,pat.anchor_year_group,sf.SOFA,rrt.rrt, weight.weight_admit,fd_uo.urineoutput,
charlson.charlson_comorbidity_index, (pressor.stay_id = icu.stay_id) as pressor,ad.discharge_location as discharge_location, pat.dod,
InvasiveVent.InvasiveVent_hr,Oxygen.Oxygen_hr,HighFlow.HighFlow_hr,NonInvasiveVent.NonInvasiveVent_hr,Trach.Trach_hr,
ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) as dod_icuout_offset,
icd.icd_codes

from physionet-data.mimiciv_derived.icustay_detail as icu 
inner join physionet-data.mimiciv_derived.sepsis3 as s3
on s3.stay_id = icu.stay_id
and icu.first_icu_stay is true 
and s3.sepsis3 is true

left join physionet-data.mimiciv_hosp.patients as pat
on icu.subject_id = pat.subject_id
left join physionet-data.mimiciv_hosp.admissions as ad
on icu.hadm_id = ad.hadm_id

left join physionet-data.mimiciv_derived.first_day_sofa as sf
on icu.stay_id = sf.stay_id 

left join physionet-data.mimiciv_derived.first_day_weight as weight
on icu.stay_id = weight.stay_id 

left join physionet-data.mimiciv_derived.charlson as charlson
on icu.hadm_id = charlson.hadm_id 

left join `physionet-data.mimiciv_derived.first_day_urine_output` as fd_uo
on icu.stay_id = fd_uo.stay_id 

left join (select distinct stay_id, dialysis_present as rrt  from physionet-data.mimiciv_derived.rrt where dialysis_present = 1) as rrt
on icu.stay_id = rrt.stay_id 

left join (select distinct stay_id from  physionet-data.mimiciv_derived.epinephrine
union distinct 
select distinct stay_id from  physionet-data.mimiciv_derived.dobutamine
union distinct 
select distinct stay_id from  physionet-data.mimiciv_derived.dopamine
union distinct 
select distinct stay_id from  physionet-data.mimiciv_derived.norepinephrine
union distinct 
select distinct stay_id from  physionet-data.mimiciv_derived.phenylephrine
union distinct 
select distinct stay_id from  physionet-data.mimiciv_derived.vasopressin)as pressor
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

-- only include cancer patients
inner join (
  SELECT subject_id, STRING_AGG(icd_code, ",") AS icd_codes
  FROM `physionet-data.mimiciv_hosp.diagnoses_icd`
  WHERE icd_code LIKE "C%"
  AND icd_code NOT LIKE "C76%"
  AND icd_code NOT LIKE "C77%"
  AND icd_code NOT LIKE "C78%"
  AND icd_code NOT LIKE "C79%"
  AND icd_code NOT LIKE "C80%"
  AND icd_code NOT LIKE "C97%"
  AND icd_code NOT LIKE "C98%"
  AND icd_code NOT LIKE "C099%"
  GROUP BY subject_id) AS icd
on icd.subject_id = icu.subject_id

where (discharge_location is not null or abs(timestamp_diff(pat.dod,icu.icu_outtime,DAY)) < 4)

-- Race is not

and (icu.race != "UNKNOWN")
and (icu.race != "UNABLE TO OBTAIN")
and (icu.race != "PATIENT DECLINED TO ANSWER")
and (icu.race != "OTHER")

order by icu.hadm_id
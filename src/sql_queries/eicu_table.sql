select pt.*,
sf.sofa_admit,
(s3.patientunitstayid = vaso.patientunitstayid) as vasopressor,
(s3.patientunitstayid = rrtid.patientunitstayid) as rrt,
(s3.patientunitstayid = ventid.patientunitstayid) as vent,
cci.final_charlson_score as Charlson

from `icu-elos.eicu_sepsis.sepsis_adult_eicu` s3

left join `physionet-data.eicu_crd.patient` pt
on s3.patientunitstayid = pt.patientunitstayid

left join (select distinct patientunitstayid, sofa_resp as resp_24,sofa_gcs as cns_24,sofa_circ as cv_24,sofa_liver as liver_24,sofa_hematology as coag_24, sofa_renal as renal_24, sofa as sofa_admit  from `icu-elos.eicu_sepsis.itu_sofa_day` where day = 1 ) sf
on s3.patientunitstayid = sf.patientunitstayid 

left join (select distinct patientunitstayid from `physionet-data.eicu_crd_derived.pivoted_treatment_vasopressor` ) vaso
on s3.patientunitstayid = vaso.patientunitstayid

left join (select distinct patientunitstayid from `physionet-data.eicu_crd.intakeoutput` where dialysistotal<>0) as rrtid
on s3.patientunitstayid = rrtid.patientunitstayid 

left join (select distinct patientunitstayid from `icu-elos.eicu_sepsis.invasive`) as ventid
on s3.patientunitstayid = ventid.patientunitstayid 

left join (select patientunitstayid,final_charlson_score from `icu-elos.eicu_sepsis.charlson_comorbidity_index`) as cci
on  s3.patientunitstayid = cci.patientunitstayid 
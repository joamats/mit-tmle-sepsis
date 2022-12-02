SELECT DISTINCT icd.*

FROM physionet-data.mimiciv_derived.icustay_detail AS icu 
INNER JOIN physionet-data.mimiciv_derived.sepsis3 AS s3
ON s3.stay_id = icu.stay_id
AND s3.sepsis3 IS TRUE

LEFT JOIN physionet-data.mimiciv_hosp.patients AS pat
ON icu.subject_id = pat.subject_id

LEFT JOIN physionet-data.mimiciv_hosp.admissions as ad
ON icu.hadm_id = ad.hadm_id

INNER JOIN (
  SELECT subject_id, icd_code, icd_version
  FROM `physionet-data.mimiciv_hosp.diagnoses_icd`
  )
AS icd

ON icd.subject_id = icu.subject_id

WHERE (icu.first_icu_stay IS TRUE AND icu.first_hosp_stay IS TRUE)
AND (discharge_location is not null OR abs(timestamp_diff(pat.dod,icu.icu_outtime,DAY)) < 4)
AND (icu.race != "UNKNOWN")
AND (icu.race != "UNABLE TO OBTAIN")
AND (icu.race != "PATIENT DECLINED TO ANSWER")
AND (icu.race != "OTHER")
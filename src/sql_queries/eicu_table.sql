SELECT yug.*, 
-- to match MIMIC's names
yug.Charlson as charlson_comorbidity_index,
yug.ethnicity as race,
yug.age as anchor_age,
yug.sofa_admit as SOFA, 
yug.hospitaldischargeyear as anchor_year_group,

-- newly added 
vent_1, vent_2, vent_3, vent_4, vent_5, vent_6,
rrt_1,
pressor_1, pressor_2, pressor_3, pressor_4

FROM `matos-334518.my_eICU.yugang` as yug

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


WHERE yug.ethnicity != "Other/Unknown"
AND icustay_detail.unitvisitnumber = 1
DROP TABLE IF EXISTS `db_name.my_eICU.pivoted_treatments`;
CREATE TABLE `db_name.my_eICU.pivoted_treatments` AS

WITH tr_aux AS (
  SELECT 
    yug.patientunitstayid,
    vent, rrt, vasopressor, -- original ones from yug
    vent_1, vent_2, vent_3, vent_4, -- new vent 
    rrt_1,  -- new rrt
    pressor_1, pressor_2, pressor_3, pressor_4, -- new vasopressor

FROM `db_name.my_eICU.yugang` as yug 

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

-- respiratory care table
LEFT JOIN(
    WITH respcare AS (

      SELECT patientunitstayid, 
      COUNT(CASE
      WHEN (airwaytype LIKE "ETT" 
      OR airwaytype LIKE "Tracheostomy" 
      OR airwaytype LIKE "Double-Lumen Tube") THEN 1
      WHEN cuffpressure BETWEEN 10 and 80 THEN 1
      ELSE NULL
      END) AS vent_4

      FROM `physionet-data.eicu_crd.respiratorycare`
      GROUP BY patientunitstayid
    )
  
  SELECT patientunitstayid, 
  
  CASE
    WHEN COUNT(vent_4) >=1 THEN 1
    ELSE NULL
    END AS vent_4

    FROM respcare
    where vent_4 > 0
    GROUP BY patientunitstayid
)
AS respiratorycare
ON respiratorycare.patientunitstayid = yug.patientunitstayid

-- treatment table to get RRT
LEFT JOIN(
  SELECT patientunitstayid, COUNT(treatmentstring) as rrt_1
  FROM `physionet-data.eicu_crd.treatment` 
  WHERE (
    treatmentstring LIKE "renal|dialysis|C V%" OR 
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
    -- WHEN COUNT(dopamine) >= 1 THEN 1
    -- WHEN COUNT(dobutamine) >= 1 THEN 1
    WHEN COUNT(norepinephrine) >= 1 THEN 1
    WHEN COUNT(phenylephrine) >= 1 THEN 1
    WHEN COUNT(epinephrine) >= 1 THEN 1
    WHEN COUNT(vasopressin) >= 1 THEN 1
    -- WHEN COUNT(milrinone) >= 1 THEN 1
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
    -- LOWER(drugname) LIKE '%dopamine%' OR
    -- LOWER(drugname) LIKE '%dobutamine%' OR
    LOWER(drugname) LIKE '%norepinephrine%' OR
    LOWER(drugname) LIKE '%phenylephrine%' OR
    LOWER(drugname) LIKE '%epinephrine%' OR
    LOWER(drugname) LIKE '%vasopressin%' OR
    -- LOWER(drugname) LIKE '%milrinone%' OR
    -- LOWER(drugname) LIKE '%dobutrex%' OR
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
    -- LOWER(drugname) LIKE '%dopamine%' OR
    -- LOWER(drugname) LIKE '%dobutamine%' OR
    LOWER(drugname) LIKE '%norepinephrine%' OR
    LOWER(drugname) LIKE '%phenylephrine%' OR
    LOWER(drugname) LIKE '%epinephrine%' OR
    LOWER(drugname) LIKE '%vasopressin%' OR
    -- LOWER(drugname) LIKE '%milrinone%' OR
    -- LOWER(drugname) LIKE '%dobutrex%' OR
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
    -- WHEN SUM(dopamine) >= 1 THEN 1
    -- WHEN SUM(dobutamine) >= 1 THEN 1
    WHEN SUM(norepinephrine) >= 1 THEN 1
    WHEN SUM(phenylephrine) >= 1 THEN 1
    WHEN SUM(epinephrine) >= 1 THEN 1
    WHEN SUM(vasopressin) >= 1 THEN 1
    -- WHEN SUM(milrinone) >= 1 THEN 1
    ELSE NULL
    END AS pressor_4

  FROM `physionet-data.eicu_crd_derived.pivoted_med`
  GROUP BY patientunitstayid
)
AS pivoted_med
ON pivoted_med.patientunitstayid = yug.patientunitstayid

)

  SELECT 

    patientunitstayid,

    CASE WHEN (vent IS NOT NULL
           OR vent_1 IS NOT NULL
           OR vent_2 IS NOT NULL
           OR vent_3 IS NOT NULL
           OR vent_4 IS NOT NULL)
         THEN 1
         ELSE 0
         END AS mech_vent

  , CASE WHEN (rrt IS NOT NULL
           OR rrt_1 IS NOT NULL)
         THEN 1
         ELSE 0
         END AS rrt
         
  , CASE WHEN (vasopressor IS NOT NULL
           OR pressor_1 IS NOT NULL
           OR pressor_2 IS NOT NULL
           OR pressor_3 IS NOT NULL
           OR pressor_4 IS NOT NULL)
         THEN 1
         ELSE 0
         END AS pressor

  FROM tr_aux

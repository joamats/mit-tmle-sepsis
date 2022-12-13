DROP TABLE IF EXISTS `db_name.my_eICU.pivoted_elective`;
CREATE TABLE `db_name.my_eICU.pivoted_elective` AS

SELECT apache.patientunitstayid, apache.electivesurgery, adm.admit_text1, adm.admit_text2, adm.admit_text3, new_elective_surgery, adm_elective, adm_elective_pat
FROM `physionet-data.eicu_crd.apachepredvar` AS apache

FULL JOIN(

WITH tt as (
  
  SELECT patientunitstayid, string_agg(admitdxpath, ';') AS admit_text1, string_agg(admitdxname, ';') AS admit_text2, string_agg(admitdxtext, ';') AS admit_text3
  FROM `physionet-data.eicu_crd.admissiondx`
  GROUP BY patientunitstayid

)

SELECT patientunitstayid, admit_text1, admit_text2, admit_text3
, CASE 
WHEN admit_text1 LIKE "%admission diagnosis|Elective|No%" 
  THEN 0

WHEN admit_text1  LIKE "%admission diagnosis|Elective|Yes%" 
  AND ( 
    (LOWER(admit_text1) LIKE "%surgery%" OR LOWER(admit_text2) LIKE "%surgery%" OR LOWER(admit_text3) LIKE "%surgery%")
  OR 
  (LOWER(admit_text1) LIKE "%operative%" OR LOWER(admit_text2) LIKE "%operative%" OR LOWER(admit_text3) LIKE "%operative%") )
  THEN 1

ELSE NULL
END AS new_elective_surgery

, CASE 
WHEN admit_text1 LIKE "%admission diagnosis|Elective|No%" 
  THEN 0

WHEN admit_text1  LIKE "%admission diagnosis|Elective|Yes%" 
  THEN 1

ELSE NULL
END AS adm_elective

FROM tt
)
AS adm
ON adm.patientunitstayid = apache.patientunitstayid

-- Mapping
-- Assume emergency admission if patient came from
-- Emergency Department, Direct Admit, Chest Pain Center, Other Hospital, Observation
-- if patient from other place, e.g. operating room, floor, etc., assume elective admission

FULL JOIN(

SELECT patientunitstayid, unitAdmitSource
, CASE
WHEN 
  unitAdmitSource  LIKE "Emergency Department"
  OR unitAdmitSource LIKE "Direct Admit"
  OR unitAdmitSource LIKE "Chest Pain Center"
  OR unitAdmitSource LIKE "Other Hospital"
  OR unitAdmitSource LIKE "Observation"
  THEN 0
ELSE 1
END AS adm_elective_pat

FROM `physionet-data.eicu_crd.patient`

)
AS pat
ON pat.patientunitstayid = apache.patientunitstayid AND adm_elective IS NULL

WHERE adm.patientunitstayid IS NOT NULL
AND apache.patientunitstayid IS NOT NULL
ORDER BY apache.patientunitstayid;

-- Update information in columns stemming from apache table with information from patient table
UPDATE `db_name.my_eICU.pivoted_elective`
SET adm_elective = adm_elective_pat, new_elective_surgery = adm_elective_pat
WHERE adm_elective IS NULL
AND new_elective_surgery IS NULL;


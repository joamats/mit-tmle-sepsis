DROP TABLE IF EXISTS `protean-chassis-368116.my_eICU.pivoted_control_outcomes`;
CREATE TABLE `protean-chassis-368116.my_eICU.pivoted_control_outcomes` AS

WITH ins_inf AS (

SELECT patientunitstayid,

CASE WHEN MIN(drugamount) >0 THEN 1
ELSE 0
END AS insulin_yes

FROM `physionet-data.eicu_crd.infusiondrug` 

WHERE LOWER(drugname) LIKE "%insulin%"

GROUP BY patientunitstayid
)

, ins_med AS (

SELECT patientunitstayid,

CASE WHEN MIN(dosage) IS NOT NULL THEN 1
ELSE 0
END AS insulin_yes

FROM `physionet-data.eicu_crd.medication` 

WHERE LOWER(drugname) LIKE "%insulin%"

GROUP BY patientunitstayid
)


, transf AS (
  SELECT
    patientunitstayid
    , count(cellvaluenumeric) as transfusion_yes

  FROM `physionet-data.eicu_crd.intakeoutput`

  WHERE celllabel = "Volume (ml)-Transfuse - Leukoreduced Packed RBCs"
     OR celllabel = "Volume-Transfuse red blood cells"
     OR LOWER(celllabel) LIKE "%rbc%"

    GROUP BY patientunitstayid
)


SELECT pt.patientunitstayid,
COALESCE(ins_med.insulin_yes, ins_inf.insulin_yes) AS insulin_yes,
transfusion_yes

FROM `physionet-data.eicu_crd.patient` AS pt

LEFT JOIN ins_med
ON ins_med.patientunitstayid = pt.patientunitstayid

LEFT JOIN ins_inf
ON ins_inf.patientunitstayid = pt.patientunitstayid

LEFT JOIN transf
ON transf.patientunitstayid = pt.patientunitstayid
SELECT icd.patientunitstayid, yug.unitvisitnumber,  icd.ICD9Code

FROM `db_name.my_eICU.yugang` as yug

INNER JOIN (
  SELECT patientunitstayid, ICD9Code
  FROM `db_name.eicu_crd.diagnosis`
  )
AS icd

ON icd.patientunitstayid = yug.patientunitstayid

WHERE yug.unitvisitnumber = 1
AND yug.ethnicity != "Other/Unknown"
AND yug.age != "16" AND yug.age != "17"

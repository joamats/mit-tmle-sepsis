--DROP TABLE IF EXISTS `protean-chassis-368116.my_eICU.pivoted_elective`;

--CREATE TABLE `protean-chassis-368116.my_eICU.pivoted_elective` AS

SELECT apache.patientunitstayid, apache.electivesurgery, adm.admitdxpath, adm.admitdxname, adm.admitdxtext, adm.new_elective
FROM `physionet-data.eicu_crd.apachepredvar` AS apache

FULL JOIN(
SELECT patientunitstayid, admitdxpath, admitdxname, admitdxtext, CAST(admitdxtext AS NUMERIC) ,

CASE 
WHEN admitdxtext = "No" 
  OR admitdxpath LIKE "admission diagnosis|Elective|%" 
  OR LOWER(admitdxname) LIKE "%surgery%"
  THEN 0

WHEN admitdxtext = "Yes" 
  OR admitdxpath LIKE "admission diagnosis|Elective|%" 
  OR LOWER(admitdxname) LIKE "%surgery%"
  THEN 1

ELSE NULL
END AS new_elective

FROM `physionet-data.eicu_crd.admissiondx`
GROUP BY patientunitstayid, admitdxpath, admitdxname, admitdxtext

)
AS adm
ON adm.patientunitstayid = apache.patientunitstayid

WHERE adm.patientunitstayid IS NOT NULL
AND apache.patientunitstayid IS NOT NULL
ORDER BY apache.patientunitstayid




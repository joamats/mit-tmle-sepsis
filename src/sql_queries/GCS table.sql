DROP TABLE IF EXISTS `protean-chassis-368116.my_eICU.pivoted_gcs2`;

CREATE TABLE `protean-chassis-368116.my_eICU.pivoted_gcs2` AS

with nc as
(
select
  patientunitstayid
  , nursingchartoffset as chartoffset
  , min(case
      when nursingchartcelltypevallabel = 'Glasgow coma score'
       and nursingchartcelltypevalname = 'GCS Total'
       and REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$')
       and nursingchartvalue not in ('-','.')
          then cast(nursingchartvalue as numeric)
      when nursingchartcelltypevallabel = 'Score (Glasgow Coma Scale)'
       and nursingchartcelltypevalname = 'Value'
       and REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$')
       and nursingchartvalue not in ('-','.')
          then cast(nursingchartvalue as numeric)
      else null end)
    as gcs
  , min(case
      when nursingchartcelltypevallabel = 'Glasgow coma score'
       and nursingchartcelltypevalname = 'Motor'
       and REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$')
       and nursingchartvalue not in ('-','.')
          then cast(nursingchartvalue as numeric)
      else null end)
    as gcsmotor
  , min(case
      when nursingchartcelltypevallabel = 'Glasgow coma score'
       and nursingchartcelltypevalname = 'Verbal'
       and REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$')
       and nursingchartvalue not in ('-','.')
          then cast(nursingchartvalue as numeric)
      else null end)
    as gcsverbal
  , min(case
      when nursingchartcelltypevallabel = 'Glasgow coma score'
       and nursingchartcelltypevalname = 'Eyes'
       and REGEXP_CONTAINS(nursingchartvalue, '^[-]?[0-9]+[.]?[0-9]*$')
       and nursingchartvalue not in ('-','.')
          then cast(nursingchartvalue as numeric)
      else null end)
    as gcseyes
  from `physionet-data.eicu_crd.nursecharting`
  -- speed up by only looking at a subset of charted data
  where nursingchartcelltypecat in
  (
    'Scores', 'Other Vital Signs and Infusions'
  )
  group by patientunitstayid, nursingchartoffset
)
-- apply some preprocessing to fields
, ncproc AS
(
  select
    patientunitstayid
  , chartoffset
  , case when gcs > 2 and gcs < 16 then gcs else null end as gcs
  , gcsmotor, gcsverbal, gcseyes
  from nc
)

select
  ncproc.patientunitstayid
  , chartoffset
  , ncproc.gcs
  , ncproc.gcsmotor, ncproc.gcsverbal, ncproc.gcseyes
FROM ncproc

FULL JOIN(
SELECT patientunitstayid, MIN(CAST(physicalexamvalue AS NUMERIC)) AS gcs
  
FROM `physionet-data.eicu_crd.physicalexam`
WHERE  (
(physicalExamPath LIKE "notes/Progress Notes/Physical Exam/Physical Exam/Neurologic/GCS/_" OR
physicalExamPath LIKE "notes/Progress Notes/Physical Exam/Physical Exam/Neurologic/GCS/__")
)
GROUP BY patientunitstayid
)
AS gcs_physical
ON gcs_physical.patientunitstayid = ncproc.patientunitstayid

FULL JOIN(
SELECT patientunitstayid, MIN(CAST(physicalexamvalue AS NUMERIC)) AS gcsmotor
  
FROM `physionet-data.eicu_crd.physicalexam`
WHERE  (
(physicalExamPath LIKE "notes/Progress Notes/Physical Exam/Physical Exam/Neurologic/GCS/Motor Score/_" OR
physicalExamPath LIKE "notes/Progress Notes/Physical Exam/Physical Exam/Neurologic/GCS/Motor Score/__")
)
GROUP BY patientunitstayid
)
AS gcsmotor_physical
ON gcsmotor_physical.patientunitstayid = ncproc.patientunitstayid

FULL JOIN(
SELECT patientunitstayid, MIN(CAST(physicalexamvalue AS NUMERIC)) AS gcsverbal
  
FROM `physionet-data.eicu_crd.physicalexam`
WHERE  (
(physicalExamPath LIKE "notes/Progress Notes/Physical Exam/Physical Exam/Neurologic/GCS/Verbal Score/_" OR
physicalExamPath LIKE "notes/Progress Notes/Physical Exam/Physical Exam/Neurologic/GCS/Verbal Score/__")
)
GROUP BY patientunitstayid
)
AS gcsverbal_physical
ON gcsverbal_physical.patientunitstayid = ncproc.patientunitstayid

FULL JOIN(
SELECT patientunitstayid, MIN(CAST(physicalexamvalue AS NUMERIC)) AS gcseyes
  
FROM `physionet-data.eicu_crd.physicalexam`
WHERE  (
(physicalExamPath LIKE "notes/Progress Notes/Physical Exam/Physical Exam/Neurologic/GCS/Eyes Score/_" OR
physicalExamPath LIKE "notes/Progress Notes/Physical Exam/Physical Exam/Neurologic/GCS/Eyes Score/__")
)
GROUP BY patientunitstayid
)
AS gcseyes_physical
ON gcseyes_physical.patientunitstayid = ncproc.patientunitstayid


WHERE ncproc.gcs IS NOT NULL
OR ncproc.gcsmotor IS NOT NULL
OR ncproc.gcsverbal IS NOT NULL
OR ncproc.gcseyes IS NOT NULL
ORDER BY patientunitstayid;


-- Create second table for our project only -> minimum value in first 24h
DROP TABLE IF EXISTS `protean-chassis-368116.my_eICU.OASIS_GCS`;

CREATE TABLE `protean-chassis-368116.my_eICU.OASIS_GCS` AS

SELECT patientunitstayid, min(gcs) as gcs
  
FROM `protean-chassis-368116.my_eICU.pivoted_gcs2`
WHERE chartoffset > 0 AND chartoffset <= 1440
GROUP BY patientunitstayid
ORDER BY patientunitstayid
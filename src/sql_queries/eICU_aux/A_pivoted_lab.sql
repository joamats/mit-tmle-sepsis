-- Blood Values for adjustment
/*
pCO2	Max 24h --> not affected by venous or arterial blood, take every measurement
pO2	Min 24h --> affect by source, use arterial BG only
cortisol min whole stay
hemoglobin	min whole stay
Glucose	max 24h
Sodium	min 24h
Potassium	max 24h
pH min 24h --> not affected by venous or arterial blood, take every measurement
Lactate	max 24h --> not affected by venous or arterial blood, take every measurement
Fibrinogen	min 24h
INR	max 24h
*/

DROP TABLE IF EXISTS `db_name.my_eICU.pivoted_lab`;
CREATE TABLE `db_name.my_eICU.pivoted_lab` AS

-- remove duplicate labs if they exist at the same time
WITH vw0 as
(
  select
      patientunitstayid
    , labname
    , labresultoffset
    , labresultrevisedoffset
  FROM `physionet-data.eicu_crd.lab` AS lab
  where labname in
  (
      'Hgb'
    , 'PT - INR'
    , 'Total CO2'
    , 'bedside glucose', 'glucose'
    , 'lactate'
    , 'potassium'
    , 'sodium'
    , 'fibrinogen'
    , 'cortisol'
    , 'pH'
    , 'paO2'
    , 'paCO2'
    , 'FiO2'
  )
  group by patientunitstayid, labname, labresultoffset, labresultrevisedoffset
  having count(distinct labresult)<=1
)


-- get the last lab to be revised
, vw1 as
(
  select
      lab.patientunitstayid
    , lab.labname
    , lab.labresultoffset
    , lab.labresultrevisedoffset
    , lab.labresult
    , ROW_NUMBER() OVER
        (
          PARTITION BY lab.patientunitstayid, lab.labname, lab.labresultoffset
          ORDER BY lab.labresultrevisedoffset DESC
        ) as rn
  FROM `physionet-data.eicu_crd.lab` AS lab
  inner join vw0
    ON  lab.patientunitstayid = vw0.patientunitstayid
    AND lab.labname = vw0.labname
    AND lab.labresultoffset = vw0.labresultoffset
    AND lab.labresultrevisedoffset = vw0.labresultrevisedoffset
  -- only valid lab values
  WHERE
       (lab.labname = 'Hgb' and lab.labresult >  0 and lab.labresult <= 9999)
    OR (lab.labname in ('bedside glucose', 'glucose') and lab.labresult >= 25 and lab.labresult <= 1500)
    OR (lab.labname = 'Total CO2' and lab.labresult >= 0 and lab.labresult <= 9999)
    OR (lab.labname = 'PT - INR' and lab.labresult >= 0.5 and lab.labresult <= 15)
    OR (lab.labname = 'lactate' and lab.labresult >= 0.1 and lab.labresult <= 30)
    OR (lab.labname = 'potassium' and lab.labresult >= 0.05 and lab.labresult <= 12)
    OR (lab.labname = 'sodium' and lab.labresult >= 90 and lab.labresult <= 215)
    OR (lab.labname = 'fibrinogen' and lab.labresult IS NOT NULL)
    OR (lab.labname = 'cortisol' and lab.labresult IS NOT NULL)
    OR (lab.labname = 'pH' and lab.labresult >= 6.5 and lab.labresult <= 8.5)
    OR (lab.labname = 'paO2' and lab.labresult >= 15 and lab.labresult <= 720)
    OR (lab.labname = 'paCO2' and lab.labresult >= 5 and lab.labresult <= 250)
    OR (lab.labname = 'FiO2' and lab.labresult >= 0.2 and lab.labresult <= 1.0)
    -- we will fix fio2 units later
    OR (lab.labname = 'FiO2' and lab.labresult >= 20 and lab.labresult <= 100)
)

 , pivoted_fio2 AS (
        SELECT 
        patientunitstayid,
        chartoffset,
        o2_device,
        CASE WHEN o2_device IN(
                'ventilator',
                'vent',
                'VENT'
            ) AND o2_flow > 20 THEN o2_flow/100
            WHEN o2_device IN(
                'ventilator',
                'vent',
                'VENT'
            ) AND o2_flow BETWEEN 0.2 AND 1.0 THEN o2_flow
            WHEN o2_device IN(
                'BiPAP/CPAP',
                'NIV'
            ) AND o2_flow > 20 THEN o2_flow/100
            WHEN o2_device IN(
                'BiPAP/CPAP',
                'NIV'
            ) AND o2_flow BETWEEN 0.2 AND 1.0 THEN o2_flow
            WHEN o2_device IN(
                'HFNC'
            ) THEN 1.0
            WHEN o2_device IN(
                'non-rebreather'
            ) THEN 1.0
            WHEN o2_device IN(
                'venturi mask'
            ) AND o2_flow BETWEEN 12 AND 15 THEN 0.6
            WHEN o2_device IN(
                'venturi mask'
            ) AND o2_flow BETWEEN 10 AND 12 THEN 0.4    
            WHEN o2_device IN(
                'venturi mask'
            ) AND o2_flow BETWEEN 8 AND 10 THEN 0.35
            WHEN o2_device IN(
                'trach collar',
                'cool aerosol mask'
            ) AND o2_flow BETWEEN 5 AND 8 THEN (30 + CEIL(o2_flow/5)*10)/100
            WHEN o2_device IN(
                'nasal cannula',
                'NC',
                'nc'
            ) AND o2_flow BETWEEN 1 AND 6 THEN (20 + o2_flow*4)/100
            WHEN o2_device IN(
                'RA',
                'ra'
            ) THEN 0.21
            ELSE NULL END AS fio2
        FROM `physionet-data.eicu_crd_derived.pivoted_o2`
        WHERE o2_flow IS NOT NULL
        AND o2_device IN(
            'ventilator',
            'vent',
            'VENT',
            'BiPAP/CPAP',
            'NIV',
            'HFNC',
            'non-rebreather',
            'venturi mask',
            'trach collar',
            'cool aerosol mask',
            'nasal cannula',
            'NC',
            'nc',
            'RA',
            'ra'
        )
    )

, aggr_fio2 AS (
  SELECT 
  patientunitstayid AS imp_pid
  , AVG(fio2) AS fio2_imp_avg
  FROM pivoted_fio2
  WHERE fio2 IS NOT NULL  
  AND chartoffset < 1440
  GROUP BY patientunitstayid
)

-- Get FiO2 data from respiratorycharting
, temp_1 AS (

  SELECT patientunitstayid, respchartvaluelabel, respchartvalue, 
  respchartoffset as chartoffset,
  cast(respchartvalue as numeric) as result
  FROM `physionet-data.eicu_crd.respiratorycharting` 

  where lower(respchartvaluelabel) like "%fio2%"
  and REGEXP_CONTAINS(respchartvalue, "%") = FALSE
  and respchartoffset < 1440

)

-- Filter to only 0-100% and 0.21 to 1
, temp_2 AS (

  SELECT *

  ,CASE WHEN 
  (result <=100 and result >=21) THEN result/100
  WHEN 
  (result <=1 and result >=0.21) THEN result
  END AS result_fract

  FROM temp_1

  WHERE 
  (result <=100 and result >=21)
  OR
  (result <=1 and result >=0.21)

)

, resp_fio2 AS (
  SELECT patientunitstayid AS resp_pid
  , AVG(result_fract) as fio2_avg

  FROM temp_2

  GROUP BY patientunitstayid
  ORDER BY patientunitstayid desc
)

-- JOINING
, joining AS (
  
  SELECT
    patientunitstayid
  , labresultoffset as chartoffset
  , MAX(case when labname in ('bedside glucose', 'glucose') then labresult else null end) as glucose
  , MAX(case when labname = 'Total CO2' then labresult else null end) as pCO2
  , MAX(case when labname = 'Hgb' then labresult else null end) as hemoglobin
  , MAX(case when labname = 'PT - INR' then labresult else null end) as INR
  , MAX(case when labname = 'lactate' then labresult else null end) as lactate
  , MAX(case when labname = 'potassium' then labresult else null end) as potassium
  , MAX(case when labname = 'sodium' then labresult else null end) as sodium
  , MAX(case when labname = 'fibrinogen' then labresult else null end) as fibrinogen
  , MAX(case when labname = 'cortisol' then labresult else null end) as cortisol
  , MAX(case when labname != 'FiO2' then null
             when labresult >= 20 then labresult/100.0 else labresult end) as fio2
  , MAX(case when labname = 'paO2' then labresult else null end) as pao2
  , MAX(case when labname = 'paCO2' then labresult else null end) as paco2
  , MAX(case when labname = 'pH' then labresult else null end) as pH

  ,MAX(fio2_imp_avg) AS fio2_imp_avg
  ,MAX(fio2_avg) AS fio2_avg

from vw1

LEFT JOIN aggr_fio2 
ON aggr_fio2.imp_pid = vw1.patientunitstayid

LEFT JOIN resp_fio2
ON resp_fio2.resp_pid = vw1.patientunitstayid

where rn = 1

group by patientunitstayid, labresultoffset
order by patientunitstayid, labresultoffset
)

-- FINAL SELECT AND MERGING OF FiO2 columns
SELECT 
patientunitstayid, chartoffset
, glucose, hemoglobin
, INR, lactate, potassium, sodium
, fibrinogen, cortisol, pao2, pH
, COALESCE(fio2, fio2_avg, fio2_imp_avg) AS fio2
, COALESCE(paco2, pCO2) AS pco2 
FROM joining

;
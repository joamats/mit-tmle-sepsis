WITH temp_table AS(

  SELECT yug.patientunitstayid as pid, yug.unitvisitnumber, 
  dx.*, ph.*

  FROM `db_name.my_eICU.yugang` as yug

  -- get missing values from diagnosistring
  LEFT JOIN(
    SELECT patientunitstayid

    , MAX(
      CASE
        WHEN LOWER(diagnosisstring) LIKE "%hypertension%"
        AND LOWER(diagnosisstring) NOT LIKE "%pulmonary hypertension%" THEN 1
        ELSE NULL
      END)
      AS hypertension_1

    ,MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%heart fail%" THEN 1
      ELSE NULL
    END)
    AS heart_failure_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%stage 1%" THEN 1
      ELSE NULL
    END)
    AS renal_11

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%stage 2%" THEN 2
      ELSE NULL
    END)
    AS renal_12

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%stage 3%" THEN 3
      ELSE NULL
    END)
    AS renal_13

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%stage 4%" THEN 4
      ELSE NULL
    END)
    AS renal_14

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%stage 5%" THEN 5
      WHEN LOWER(diagnosisstring) LIKE "%renal%"
      AND LOWER(diagnosisstring) LIKE "%esrd%" THEN 5
      ELSE NULL
    END)
    AS renal_15

    , MAX( 
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%copd%" THEN 1
      ELSE NULL
    END)
    AS copd_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%asthma%" THEN 1
      ELSE NULL
    END)
    AS asthma_1

    FROM `physionet-data.eicu_crd.diagnosis`
    GROUP BY patientunitstayid
  )
  AS dx
  ON dx.patientunitstayid = yug.patientunitstayid


  -- get missing values from past history
  LEFT JOIN(
    SELECT patientunitstayid
    
    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%hypertension%"
      AND LOWER(pasthistorypath) NOT LIKE "%pulmonary hypertension%" THEN 1
      ELSE NULL
    END)
    AS hypertension_2
    
    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%heart fail%" THEN 1
      ELSE NULL
    END)
    AS heart_failure_2
    
    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%renal%"
      AND LOWER(pasthistorypath) LIKE "%creatinine 1-2%" THEN 2
      ELSE NULL
    END)
    AS renal_22

    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%renal%"
      AND LOWER(pasthistorypath) LIKE "%creatinine 2-3%" THEN 3
      WHEN LOWER(pasthistorypath) LIKE "%renal%"
      AND LOWER(pasthistorypath) LIKE "%creatinine 3-4%" THEN 3
      ELSE NULL
    END)
    AS renal_23

    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%renal%"
      AND LOWER(pasthistorypath) LIKE "%creatinine 4-5%" THEN 4
      ELSE NULL
    END)
    AS renal_24

    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%renal%"
      AND LOWER(pasthistorypath) LIKE "%creatinine > 5%" THEN 5
      WHEN LOWER(pasthistorypath) LIKE "%renal failure%" THEN 5
      ELSE NULL
    END)
    AS renal_25
    
    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%copd%" THEN 1
      ELSE NULL
    END)
    AS copd_2

    ,MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%asthma%" THEN 1
      ELSE NULL
    END)
    AS asthma_2

    FROM `physionet-data.eicu_crd.pasthistory`
    GROUP BY patientunitstayid
  )
  AS ph
  ON ph.patientunitstayid = yug.patientunitstayid


  WHERE yug.unitvisitnumber = 1
  AND yug.ethnicity != "Other/Unknown"
  AND yug.age != "16" AND yug.age != "17"
)

SELECT pid

  , CASE
    WHEN hypertension_1 IS NOT NULL
    OR hypertension_2 IS NOT NULL THEN 1
    ELSE NULL
    END AS hypertension

  , CASE 
    WHEN heart_failure_1 IS NOT NULL
    OR heart_failure_2 IS NOT NULL THEN 1
    ELSE NULL
    END AS heart_failure

  , CASE 
    WHEN asthma_1 IS NOT NULL
    OR asthma_2 IS NOT NULL THEN 1
    ELSE NULL
    END AS asthma

  , CASE 
    WHEN copd_1 IS NOT NULL
    OR copd_2 IS NOT NULL THEN 1
    ELSE NULL
    END AS copd

  , CASE 
    WHEN renal_11 IS NOT NULL THEN 1
    WHEN renal_12 IS NOT NULL OR renal_22 IS NOT NULL THEN 2
    WHEN renal_13 IS NOT NULL OR renal_23 IS NOT NULL THEN 3
    WHEN renal_14 IS NOT NULL OR renal_24 IS NOT NULL THEN 4
    WHEN renal_15 IS NOT NULL OR renal_25 IS NOT NULL THEN 5
    ELSE NULL
    END AS ckd

  FROM temp_table

DROP TABLE IF EXISTS `db_name.my_eICU.pivoted_comorbidities`;
CREATE TABLE `db_name.my_eICU.pivoted_comorbidities` AS
  
  
  WITH temp_table AS (

  SELECT icu.patientunitstayid, 
  dx.*, ph.*

  FROM `db_name.eicu_crd_derived.icustay_detail` as icu

  -- get missing values from diagnosistring
  LEFT JOIN(
    SELECT patientunitstayid AS patientunitstayid_dx

    , STRING_AGG(icd9code) AS icd_codes

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
      WHEN LOWER(diagnosisstring) LIKE "%coronary%" THEN 1
      ELSE NULL
    END)
    AS cad_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%asthma%" THEN 1
      ELSE NULL
    END)
    AS asthma_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%diabetes mellitus|Type I%" THEN 1
      ELSE NULL
    END)
    AS diabetes_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%diabetes mellitus|Type II%" THEN 1
      ELSE NULL
    END)
    AS diabetes_2

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%immunological%" 
      AND 
      (LOWER(diagnosisstring) NOT LIKE "%amyloidosis%" OR LOWER(diagnosisstring) NOT LIKE "%pulmonary%") THEN 1
      ELSE NULL
    END)
    AS connective_disease_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%pneumonia%" 
      AND LOWER(diagnosisstring) NOT LIKE "%|ventilator-associated%" THEN 1
      ELSE NULL
    END)
    AS pneumonia_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%urinary tract%" 
      AND LOWER(diagnosisstring) LIKE "%infection%" THEN 1
      ELSE NULL
    END)
    AS uti_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%cholangitis%" 
      OR LOWER(diagnosisstring) LIKE "%cholecystitis%" 
      OR LOWER(diagnosisstring) LIKE "%pancreatitis|acute%" THEN 1
      ELSE NULL
    END)
    AS biliary_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%skin%" 
      AND LOWER(diagnosisstring) LIKE "infectio%" THEN 1
      ELSE NULL
    END)
    AS skin_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%vascular catheter%" 
      AND LOWER(diagnosisstring) LIKE "%infectio%" THEN 1
      ELSE NULL
    END)
    AS clabsi_1

    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%catheter%" 
      AND LOWER(diagnosisstring) LIKE "%infectio%" 
      AND (LOWER(diagnosisstring) like "%with in%" OR LOWER(diagnosisstring) like "%with foley%") 
      THEN 1
      ELSE NULL
    END)
    AS cauti_1
    
    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) LIKE "%pneumonia%" 
      AND LOWER(diagnosisstring) LIKE "%|ventilator-associated%" THEN 1
      ELSE NULL
    END)
    AS vap_1
    
    , MAX(
    CASE
      WHEN LOWER(diagnosisstring) like "%wound%" 
      AND LOWER(diagnosisstring) like "%infectio%"  THEN 1
      WHEN LOWER(diagnosisstring) like "%surgical%" 
      AND LOWER(diagnosisstring) like "%infectio%"  THEN 1
      ELSE NULL
    END)
    AS ssi_1

    FROM `physionet-data.eicu_crd.diagnosis`
    GROUP BY patientunitstayid
  )
  AS dx
  ON dx.patientunitstayid_dx = icu.patientunitstayid

  -- get missing values from past history
  LEFT JOIN(
    SELECT patientunitstayid AS patientunitstayid_ph
    
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

    , MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%coronary%" THEN 1
      ELSE NULL
    END)
    AS cad_2

    ,MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%asthma%" THEN 1
      ELSE NULL
    END)
    AS asthma_2

    ,MAX(
    CASE
      WHEN LOWER(pasthistorypath) LIKE "%diabetes%" THEN 1
      ELSE NULL
    END)
    AS diabetes_3

    FROM `physionet-data.eicu_crd.pasthistory`
    GROUP BY patientunitstayid
  )
  AS ph
  ON ph.patientunitstayid_ph = icu.patientunitstayid

)

SELECT temp_table.patientunitstayid

  , CASE
    WHEN hypertension_1 IS NOT NULL
    OR hypertension_2 IS NOT NULL 
    OR icd_codes LIKE "%I10%"
    OR icd_codes LIKE "%I11%"
    OR icd_codes LIKE "%I12%"
    OR icd_codes LIKE "%I13%"
    OR icd_codes LIKE "%I14%"
    OR icd_codes LIKE "%I15%"
    OR icd_codes LIKE "%I16%"
    OR icd_codes LIKE "%I70%"
    THEN 1
    ELSE NULL
    END AS hypertension_present

  , CASE 
    WHEN heart_failure_1 IS NOT NULL
    OR heart_failure_2 IS NOT NULL 
    OR icd_codes LIKE "%I50%"
    OR icd_codes LIKE "%I110%"
    OR icd_codes LIKE "%I27%"
    OR icd_codes LIKE "%I42%"
    OR icd_codes LIKE "%I43%"
    OR icd_codes LIKE "%I517%"
    THEN 1
    ELSE NULL
    END AS heart_failure_present

  , CASE 
    WHEN asthma_1 IS NOT NULL
    OR asthma_2 IS NOT NULL
    OR icd_codes LIKE "%J841%"
    THEN 1
    ELSE NULL
    END AS asthma_present

  , CASE 
    WHEN copd_1 IS NOT NULL
    OR copd_2 IS NOT NULL
    OR icd_codes LIKE "%J41%"
    OR icd_codes LIKE "%J42%"
    OR icd_codes LIKE "%J43%"
    OR icd_codes LIKE "%J44%"
    OR icd_codes LIKE "%J45%"
    OR icd_codes LIKE "%J46%"
    OR icd_codes LIKE "%J47%"
    THEN 1
    ELSE NULL
    END AS copd_present

  , CASE 
    WHEN cad_1 IS NOT NULL
    OR cad_2 IS NOT NULL
    OR icd_codes LIKE "%I20%"
    OR icd_codes LIKE "%I21%"
    OR icd_codes LIKE "%I22%"
    OR icd_codes LIKE "%I23%"
    OR icd_codes LIKE "%I24%"
    OR icd_codes LIKE "%I25%"
    THEN 1
    ELSE NULL
    END AS cad_present

  , CASE 
    WHEN renal_11 IS NOT NULL
      OR icd_codes LIKE "%N181%" 
    THEN 1
    WHEN renal_12 IS NOT NULL
      OR renal_22 IS NOT NULL
      OR icd_codes LIKE "%N182%"
    THEN 2
    WHEN renal_13 IS NOT NULL
      OR renal_23 IS NOT NULL
      OR icd_codes LIKE "%N183%"
    THEN 3
    WHEN renal_14 IS NOT NULL
      OR renal_24 IS NOT NULL
      OR icd_codes LIKE "%N184%"
    THEN 4
    WHEN renal_15 IS NOT NULL
      OR renal_25 IS NOT NULL
      OR icd_codes LIKE "%N185%"
      OR icd_codes LIKE "%N186%"
    THEN 5
    ELSE NULL
    END AS ckd_stages

  , CASE 
    WHEN diabetes_1 IS NOT NULL
      OR icd_codes LIKE "%E08%" 
      OR icd_codes LIKE "%E09%"
      OR icd_codes LIKE "%E10%"
      OR icd_codes LIKE "%E13%"
    THEN 1
    WHEN diabetes_2 IS NOT NULL
      OR diabetes_3 IS NOT NULL
      OR icd_codes LIKE "%E11%"
    THEN 2
    ELSE NULL
    END AS diabetes_types

-- connective tissue disease as defined in Elixhauser comorbidity score
  , CASE 
      WHEN connective_disease_1 IS NOT NULL THEN 1
      WHEN icd_codes LIKE "%L940" THEN 1
      WHEN icd_codes LIKE "%L941" THEN 1
      WHEN icd_codes LIKE "%L943%" THEN 1
      WHEN icd_codes LIKE "%M05%" THEN 1
      WHEN icd_codes LIKE "%M06%" THEN 1
      WHEN icd_codes LIKE "%M08%" THEN 1
      WHEN icd_codes LIKE "%M120" THEN 1
      WHEN icd_codes LIKE "%M123" THEN 1
      WHEN icd_codes LIKE "%M30%" THEN 1
      WHEN icd_codes LIKE "%M310%" THEN 1
      WHEN icd_codes LIKE "%M311%" THEN 1
      WHEN icd_codes LIKE "%M312%" THEN 1
      WHEN icd_codes LIKE "%M313%" THEN 1
      WHEN icd_codes LIKE "%M32%" THEN 1
      WHEN icd_codes LIKE "%M33%" THEN 1
      WHEN icd_codes LIKE "%M34%" THEN 1
      WHEN icd_codes LIKE "%M35%" THEN 1
      WHEN icd_codes LIKE "%M45%" THEN 1
      WHEN icd_codes LIKE "%M461%" THEN 1
      WHEN icd_codes LIKE "%M468%" THEN 1
      WHEN icd_codes LIKE "%M469%" THEN 1
    ELSE NULL
  END AS connective_disease
-- connective tissue disease as defined in Elixhauser comorbidity score  

  ,CASE 
      WHEN pneumonia_1 IS NOT NULL THEN 1
      WHEN icd_codes LIKE "%J09%" THEN 1
      WHEN icd_codes LIKE "%J1%" THEN 1
      WHEN icd_codes LIKE "%J85%" THEN 1
      WHEN icd_codes LIKE "%J86%" THEN 1
      ELSE NULL
  END AS pneumonia  

  ,CASE 
      WHEN uti_1 IS NOT NULL THEN 1
      WHEN icd_codes LIKE "%N300%" THEN 1
      WHEN icd_codes LIKE "%N390%" THEN 1       
      ELSE NULL
  END AS uti

  ,CASE 
      WHEN biliary_1 IS NOT NULL THEN 1
      WHEN icd_codes LIKE "%K81%" THEN 1
      WHEN icd_codes LIKE "%K830%" THEN 1
      WHEN icd_codes LIKE "%K851%" THEN 1  
      ELSE NULL
  END AS biliary

  ,CASE      
      WHEN skin_1 IS NOT NULL THEN 1
      WHEN icd_codes LIKE "%L0%" THEN 1       
      ELSE NULL
  END AS skin

-- hospital acquired infections 
   , CASE 
      WHEN clabsi_1 IS NOT NULL THEN 1
      WHEN icd_codes LIKE "%T80211%" THEN 1
      ELSE NULL
  END AS hospital_clabsi

 , CASE 
      WHEN cauti_1 IS NOT NULL THEN 1
      WHEN icd_codes LIKE "%T83511%" THEN 1
      ELSE NULL
  END AS hospital_cauti

 , CASE 
      WHEN ssi_1 IS NOT NULL THEN 1
      WHEN icd_codes LIKE "%T814%" THEN 1
      ELSE NULL
  END AS hospital_ssi

 , CASE 
      WHEN vap_1 IS NOT NULL THEN 1
      WHEN icd_codes LIKE "%J95851%" THEN 1
      ELSE NULL
  END AS hospital_vap 


  FROM temp_table
  ORDER BY patientunitstayid

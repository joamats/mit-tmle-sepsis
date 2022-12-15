import argparse
from tqdm import tqdm
import pandas as pd
import numpy as np
tqdm.pandas()

# Combine the info from multiple columns into 3 distinct columns for each of the 3 treatments in eICU data
def cat_rrt(rrt):  
    if rrt['rrt'] == True:
        return 1
    elif rrt['rrt_1'] > 0:
        return 1
    else: 
        return np.NaN

def cat_vent(vent): 
    if vent['vent'] == True:
        return 1
    elif vent['vent_1'] > 0:
        return 1
    elif vent['vent_2'] > 0:
        return 1
    elif vent['vent_3'] > 0:
        return 1
    elif vent['vent_4'] > 0:
        return 1
    elif vent['vent_5'] > 0:
        return 1
    elif vent['vent_6'] > 0:
        return 1
    else: 
        return np.NaN

def cat_pressor(pressor): 
    if pressor['vasopressor'] == True:
        return 1
    elif pressor['pressor_1'] > 0:
        return 1
    elif pressor['pressor_2'] > 0:
        return 1
    elif pressor['pressor_2'] > 0:
        return 1
    elif pressor['pressor_3'] > 0:
        return 1
    elif pressor['pressor_4'] > 0:
        return 1
    else: 
        return np.NaN

# Apply the functions and save the CSV
def combine_treatment_eICU(df):

    df['RRT_final'] = df.apply(lambda rrt: cat_rrt(rrt), axis=1)
    df['VENT_final'] = df.apply(lambda vent: cat_vent(vent), axis=1)
    df['PRESSOR_final'] = df.apply(lambda pressor: cat_pressor(pressor), axis=1)

    return df

# Conversion using MIMIC's format
def mimic_conversion(row, mapping):

    if row.icd_version == 9:
        try:
            return mapping[row.icd_code]
        except:
            return np.nan

    elif row.icd_version == 10:
        return row.icd_code
    
    else: 
        return np.nan


# Conversion using eICU's data format
def eicu_conversion(row, mapping):

    if isinstance(row.ICD9Code, str):
        codes = row.ICD9Code.split(", ")
    else: # empty
        return np.nan

    # first column is ICD-9 and second is ICD-10, let's keep the second
    if len(codes) == 2:
        return codes[1]
    
    # only one code is present
    elif len(codes) == 1:
        # if the code is ICD-9, let's convert it
        try:
            return mapping[codes[0]]
        
        except:
            # if it fails, code can be ICD-10 
            if codes[0] in mapping.values():
                return codes[0]
            # or a mismatch
            else: 
                return np.nan


def icd_9_to_10(original_file, dataset):

    df = pd.read_csv(original_file)

    conversions = pd.read_csv("data/ICD_codes/ICD10_Formatted.csv")[['ICD-9', 'ICD-10']]

    mapping = dict(zip(conversions['ICD-9'], conversions['ICD-10']))

    n = len(df)
    i = 0

    if dataset == "MIMIC":

        df['icd_10'] = df.progress_apply(lambda row: mimic_conversion(row, mapping), axis=1)
    
    elif dataset == "eICU":

        df = df[['patientunitstayid','ICD9Code']]
        df['icd_10'] = df.progress_apply(lambda row: eicu_conversion(row, mapping), axis=1)


    df.dropna(inplace=True)      
                
    print(f"Inital length: {n}\nFinal Length: {len(df)}")

    return df

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--original_file",
                        default="data/ICD_codes/eICU/raw_icd_codes.csv",
                        help="Insert your original file with ICD codes")

    parser.add_argument("--result_file",
                        default="data/eICU_data.csv",
                        help="Insert your target path for the disease ICD 10 codes only file")

    parser.add_argument("--dataset",
                    default="eICU",
                    help="Insert the dataset to work with")

    return parser.parse_args()

if __name__ == '__main__':

    args = parse_args()

    # 1. Convert ICD-9 to ICD-10 codes

    # Read the file to process with disease patients
    df = icd_9_to_10(args.original_file, args.dataset)

    # 2. Encode ICD codes into columns

    # Get the mapping ICD codes - disease type
    disease_map = pd.read_csv("data/ICD_codes/map_icd_codes.csv")

    # First let's create a column for each disease
    for index, row in disease_map.iterrows():
        df[row.disease_type] = np.nan
    
    # Go over each ICD code for disease type, make true if our code matches
    for index, row in tqdm(disease_map.iterrows(), total=len(disease_map)):

        df[row.disease_type] = df.apply(lambda x: 1 if row.icd_10 in x.icd_10 else x[row.disease_type], axis=1)

    # Get unique disease types names
    unique_disease_types = disease_map.disease_type.unique()

    print(f"Before groupping by patient, N = {len(df)}")

    # Group by patient
    if args.dataset == "MIMIC":
        df = df.groupby("subject_id").sum()

    elif args.dataset == "eICU":
        df = df.groupby("patientunitstayid").sum()

    # Convert these sums into 0 or 1 (anything >= 1)
    for index, row in disease_map.iterrows():

        df[row.disease_type] = df[row.disease_type].apply(lambda x: 1 if x >= 1 else np.nan)
    
    # Encode CKD as categorial
    ckds = ["ckd1","ckd2","ckd3","ckd4","ckd5"]

    # if several CKD, takes the highest one
    df['ckd'] = df.ckd1
    for i, c in enumerate(ckds):
        df.ckd = df.apply(lambda row: i if row[c] == 1 else row.ckd, axis=1)


    print(f"After groupping by patient, N = {len(df)}")

    df = df.loc[:, ~df.columns.str.contains('^Unnamed')]
    
    if args.dataset == "MIMIC":
        df.drop(["icd_version"], axis=1, inplace=True)
    

    # 3. Combine existing dataset with ICD codes

    if args.dataset == "MIMIC":
        df_sepsis = pd.read_csv("data/MIMIC_data.csv")

        df.to_csv("data/ICD_codes/MIMIC/processed_icd_codes.csv")
        df = pd.read_csv("data/ICD_codes/MIMIC/processed_icd_codes.csv")

        key = "subject_id"

        df_all = df_sepsis.join(df, rsuffix="_")


    elif args.dataset == "eICU":
        df_sepsis = pd.read_csv("data/eICU_data.csv")
        # Combine vent, rrt, vasopressor columns into one of each only
        df_sepsis = combine_treatment_eICU(df_sepsis)

        key = "patientunitstayid"

        df.to_csv("data/ICD_codes/eICU/processed_icd_codes.csv")
        df1 = pd.read_csv("data/ICD_codes/eICU/processed_icd_codes.csv")
        df2 = pd.read_csv("data/ICD_codes/eICU/dx_ph_diseases.csv")

        # Join with the missing data csv
        df = df1.set_index(key).join(df2.set_index("pid").drop("Unnamed: 0", axis=1), rsuffix='_')
        
        df.hypertension = df.apply(lambda row: 1 if ((row.hypertension == 1) | (row.hypertension_ == 1)) else np.nan, axis=1)
        df.heart_failure = df.apply(lambda row: 1 if ((row.heart_failure == 1) | (row.heart_failure_ == 1)) else np.nan, axis=1)
        df.ckd = df.ckd_ # vlues are all in ckd_
        df.copd = df.apply(lambda row: 1 if ((row.copd == 1) | (row.copd_ == 1)) else np.nan, axis=1)
        df.asthma = df.apply(lambda row: 1 if ((row.asthma == 1) | (row.asthma_ == 1)) else np.nan, axis=1)

        # Get together
        df_all = df_sepsis.set_index(key).join(df, rsuffix="_")


    print(f"Patients with Past Disease: {len(df)}")
    print(f"Sepsis patients: {len(df_sepsis)}")
    print(f"Final patients: {len(df_all)}")

    # Save DataFrame
    df_all.to_csv(args.result_file)
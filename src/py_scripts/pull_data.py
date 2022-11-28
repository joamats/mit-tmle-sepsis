import argparse
import pandas as pd
import numpy as np

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sql_query_path", help="Insert your SQL query's path")
    parser.add_argument("--destination_path", help="Insert your pulled data's destination path")

    return parser.parse_args()

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
def combine_treatment_eICU(df, destination_path):

    df['RRT_final'] = df.apply(lambda rrt: cat_rrt(rrt), axis=1)
    df['VENT_final'] = df.apply(lambda vent: cat_vent(vent), axis=1)
    df['PRESSOR_final'] = df.apply(lambda pressor: cat_pressor(pressor), axis=1)

    return df


# Run Query to get a DataFrame from BigQuery
def run_query(sql_query_path):

    # Access data using Google BigQuery.
    import os
    from dotenv import load_dotenv

    # Load env file 
    load_dotenv()

    # Get GCP's secrets
    KEYS_FILE = os.getenv("KEYS_FILE")
    PROJECT_ID = os.getenv("PROJECT_ID")

    # Set environment variables
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = KEYS_FILE

    # Establish connection with BigQuery
    from google.cloud import bigquery
    BigQuery_client = bigquery.Client()

    # Read query
    with open(sql_query_path, 'r') as fd:
        query = fd.read()

    # Replace the project id by the coder's project id in GCP
    my_query = query.replace("physionet-data", PROJECT_ID).replace("db_name", PROJECT_ID, -1)

    # Make request to BigQuery with our query
    df = BigQuery_client.query(my_query).to_dataframe()

    return df

if __name__ == '__main__':

    args = parse_args()
    df = run_query(sql_query_path = args.sql_query_path)

    if "eICU" in args.destination_path:
        df = combine_treatment_eICU(df, args.destination_path)
    
    df.to_csv(args.destination_path)
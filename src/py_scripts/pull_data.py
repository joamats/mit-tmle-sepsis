import argparse

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sql_query_path", help="Insert your SQL query's path")
    parser.add_argument("--destination_path", help="Insert your pulled data's destination path")

    return parser.parse_args()


def main(sql_query_path, destination_path):

    # Access data using Google BigQuery.
    import os
    from dotenv import load_dotenv

    # Load env
    load_dotenv()

    # Get GCP's secrets
    KEYS_FILE = os.getenv("KEYS_FILE")
    PROJECT_ID = os.getenv("PROJECT_ID")

    # Set environment variables
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = KEYS_FILE

    # Stablish connection with BigQuery
    from google.cloud import bigquery
    BigQuery_client = bigquery.Client()

    # Read query
    with open(sql_query_path, 'r') as fd:
        query = fd.read()

    my_query = query.replace("physionet-data", PROJECT_ID, -1)

    # Make request to BigQuery with our query
    df = BigQuery_client.query(my_query).to_dataframe()

    # Save query to CSV file
    df.to_csv(destination_path)


if __name__ == '__main__':

    args = parse_args()
    main(sql_query_path = args.sql_query_path, destination_path = args.destination_path)
# Disparities in Use of Interventions across Races in ICU Sepsis Patients

Many interventions in healthcare are still not based on hard evidence and care might differ between races, especially in the Intensive Care Unit (ICU).

The goal of this project is to investigate disparities between races in critically ill sepsis patients in regard to in-hospital mortality, renal replacement therapy (RRT), vasopressor use (VP), or mechanical ventilation (MV), in cohorts curated from MIMIC IV (2008-2019) and eICU (2014-2015) datasets.


## How to run this project 

### 1. Clone this repository

Run the following command in your terminal.

```sh
git clone https://github.com/joamats/mit-tmle.git
```

### 2. Install required Packages
#### R scripts

Run the following command:

```sh
source('src\r_scripts\setup\install_packages.R')
```

#### Python scripts

Run the following command:
```sh
pip install --r src/py_scripts/setup/requirements.txt
```

### 3. Fetch the data
Both MIMIC and eICU data can be found in [PhysioNet](https://physionet.org/), a repository of freely-available medical research data, managed by the MIT Laboratory for Computational Physiology. Due to its sensitive nature, credentialing is required to access both datasets.

Documentation for MIMIC-IV's can be found [here](https://mimic.mit.edu/) and for eICU [here](https://eicu-crd.mit.edu/).

#### Integration with Google Cloud Platform (GCP)

In this section, we explain how to set up GCP and your environment in order to run SQL queries through GCP right from your local Python setting. Follow these steps: 

1) Create a Google account if you don't have one and go to [Google Cloud Platform](https://console.cloud.google.com/bigquery)

2) Enable the [BigQuery API](https://console.cloud.google.com/apis/api/bigquery.googleapis.com)

3) Create a [Service Account](https://console.cloud.google.com/iam-admin/serviceaccounts), where you can download your JSON keys

4) Place your JSON keys in the parent folder (for example) of your project

5) Create a .env file with the command `cp env.example env `

6) Update your .env file with your ***JSON keys*** path and the ***id*** of your project in BigQuery


#### MIMIC-IV

After getting credentialing at PhysioNet, you must sign the data use agreement and connect the database with GCP, either asking for permission or uploading the data to your project.

Having all the necessary tables for the cohort generation query in your project, run the following command to fetch the data as a dataframe that will be saved as CSV in your local project. Make sure you have all required files and folders.

```sh
python3 src/py_scripts/pull_data.py --sql_query_path src/sql_queries/mimic_table.sql --destination_path data/MIMIC_data.csv
```

#### eICU

The generation of the eICU cohort is a bit more complex. 

First, you must run all the queries present in the folder **src/sql_queries/eICU_sepsis** sequentially, in your GCP project. More detailed instructions can be found in that folder. The generated tables will be necessary to run the final query. This can take a while.

Finally, run:

```sh
python3 src/py_scripts/pull_data.py --sql_query_path src/sql_queries/eICU_table.sql --destination_path data/eICU_data.csv
```


### 4. Run the different analyses
#### 4.1 Logistic Regression
Fit a logistic regression with the treatment as outcome to assess odd ratios' disparities amongst different ethnicities. Results can be replicated by:

1) Generating CSV files ready for the Stata script, by runnning the command:

```sh
source("src/r_scripts/log_reg/create_csv.R")
```

2) Running all the commands of the file **src/stata_scripts/logistic_regression.do** in a licensed version of [Stata](https://www.stata.com/).

#### 4.2 TMLE
Targetted Maximum Likelihood Estimation was used to delineate the average treatment effect for one of the interventions. Data was stratified by race and SOFA category. Running the following command allows to replicate the obtained results.

```sh
source("src/r_scripts/tmle/run_analyses.R")
```

#### 4.3 LTMLE
Longitudinal Targetted Maximum Likelihood Estimation was applied as sensitivity analysis method, reporting an ATE as if all patients were randomly assigned to a treatment. Running the following command allows to replicate the obtained results.

```sh
source("src/r_scripts/ltmle/run_analyses.R")
```
#### 4.4 Create Forest Plot
Forest plot is created with the Stata commands present in the file **src\stata_scripts\forest_plots.do**.

## How to contribute
We are actively working on this project.
Feel free to raise questions opening an issue, to fork this project and submit pull requests!




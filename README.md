# Disparities in Use of Interventions across Races in ICU Sepsis Patients

Many interventions in healthcare are still not based on hard evidence and care might differ between races, especially in Intensive Care Units (ICU).

To investigate disparities between races in critically ill sepsis patients in regard to in-hospital mortality, renal replacement therapy (RRT), vasopressor use (VP), or mechanical ventilation (MV) in cohorts curated from MIMIC IV (2008-2019) and eICU (2014-2015) datasets.


## How to run this project 

### 1. Clone this repository

```
git clone https://github.com/joamats/mit-tmle.git
```

### 2. Install required Packages
#### R scripts

Run the following command:

```
source('src\r_scripts\setup\install_packages.R')
```

#### Stata scripts

Run the following command:
```
source('src\stata_scripts\......')
```

### 3. Fetch the data
Both MIMIC and eICU data can be found in [PhysioNet](https://physionet.org/), a repository of freely-available medical research data, managed by the MIT Laboratory for Computational Physiology. Due to its sensitive nature, credentialing is required to access both datasets.

Documentation for MIMIC-IV's can be found [here](https://mimic.mit.edu/) and for eICU [here](https://eicu-crd.mit.edu/).

The selected cohorts can be reproduced using the SQL queries under ` src/sql_queries `.


### 4. Run the different analyses
#### 4.1 Logistic Regression
Fit a logistic regression with the treatment as outcome to assess odd ratios' disparities amongst different ethnicities

```
run stata code, ideally a main script under the correct folder
```

#### 4.2 TMLE
Targetted Maximum Likelihood Estimation was used to delineate the average treatment effect for one of the interventions. Data was stratified by race and SOFA category.

```
run tmle, ideally a main script under the correct folder
```

#### 4.3 LTMLE
Longitudinal Targetted Maximum Likelihood Estimation was applied as sensitivity analysis method, reporting an ATE as if all patients were randomly assigned to a treatment.

```
run tmle, ideally a main script under the correct folder 
```

The results' logs can be found under ` src/r_scripts/log `.


## Contributing
We encourage users to fork this project and submit pull requests!




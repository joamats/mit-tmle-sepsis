from tableone import TableOne
import pandas as pd

data = pd.read_csv('data/MIMIC_eICU.csv', low_memory=False)

# Continuous Variables
data['los_d'] = data[data.death_bin == 1].los
data['los_s'] = data[data.death_bin == 0].los

#data['no_pairs'] = data.groupby('subject_id')['subject_id'].transform('count')

data['race'] = data['race'].map({1: 'White',
                                             2: 'Hispanic',
                                             3: 'Asian',
                                             4: 'Other',
                                             5: 'Black'})

data['SOFA_cat'] = data['SOFA'].map({0: -1,
                                     1: 0-3,
                                     2: 4-6,
                                     3: 7-10,
                                     4: 11-100})


data['gender'] = data['gender'].map({0: 'Female', 1: 'Male'})
data['pressor'] = data['pressor'].map({1: 'Received', 0: 'No'})
data['ethnicity_white'] = data['ethnicity_white'].map({1: 'White', 0: 'Non-White'})

data['rrt'] = data['rrt'].map({1: 'Received', 0: 'No'})
data['ventilation_bin'] = data['ventilation_bin'].map({1: 'Received', 0: 'No'})
data['death_bin'] = data['death_bin'].map({1: 'Died', 0: 'Survived'})
                               
order_s = {"gender": ["Female", "Male"],
           "death_bin": ["Died", "Survived"]
          }

limit_s = {"gender": 1,
           "death_bin": 1
           }

labls_s = {'pressor': 'Vasopressor(s)',
           'rrt': "RRT",
           'ventilation_bin': "Invasive Ventilation",
            'death_bin': "In-Hospital Mortality",
           'ethnicity_white': "Race"
          }

categ_s = ['death_bin','SOFA_cat', 'ventilation_bin', 'rrt', 'pressor']


data_s = data
#.groupby("subject_id").first().reset_index()

# Groupby Variable
groupby = ['death_bin', 'SOFA_cat']

# Create a TableOne 
table1_s = TableOne(data_s, columns=categ_s,
                    rename=labls_s, limit=limit_s, order=order_s, 
                    groupby=groupby, categorical=categ_s,
                    missing=False, overall=False,
                    row_percent = True)

table1_s.to_excel('results/table1/table_sanity.xlsx')

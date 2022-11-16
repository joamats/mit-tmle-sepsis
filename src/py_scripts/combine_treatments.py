import pandas as pd
import numpy as np

df = pd.read_csv('data/eICU_data.csv')

# Combine the info from multiple columns into 3 distinct columns for each of the 3 treatments
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

# Apply the functions
df['RRT_final'] = df.apply(lambda rrt: cat_rrt(rrt), axis=1)
df['VENT_final'] = df.apply(lambda vent: cat_vent(vent), axis=1)
df['PRESSOR_final'] = df.apply(lambda pressor: cat_pressor(pressor), axis=1)

# Save as csv
df.to_csv('data/eICU_final.csv')
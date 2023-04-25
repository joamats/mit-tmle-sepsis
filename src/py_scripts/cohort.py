import pandas as pd
import numpy as np
import os
from utils import get_demography, print_demo

df0 = pd.read_csv('data/MIMIC_data.csv')
print(f"\n{len(df0)} stays in the ICU")

# Remove patients without sepsis
df1 = df0[df0.sepsis3 == True]
print(f"Removed {len(df0) - len(df1)} stays without sepsis")
demo1 = print_demo(get_demography(df1))
print(f"{len(df1)} sepsis stays \n({demo1})\n")

# Remove patients with LoS < 1 day and > 30 days
df2 = df1[(df1.los_icu >= 1) & (df1.los_icu <= 30)]
print(f"Removed {len(df1) - len(df2)} stays with LoS < 1 day or > 30 days")
demo2 = print_demo(get_demography(df2))
print(f"{len(df2)} stays with sepsis and LoS between 1 and 30 days \n({demo2})\n")

# Remove patients with recurrent stays
df3 = df2.sort_values(by=["subject_id", "hadm_id", "hospstay_seq","icustay_seq"], ascending=True) \
         .groupby('subject_id') \
         .apply(lambda group: group.iloc[0, 1:])

print(f"Removed {len(df2) - len(df3)} recurrent stays")
demo3 = print_demo(get_demography(df3))
print(f"{len(df3)} stays with sepsis, 1 day <= ICU LoS <= 30 days \n({demo3})\n")

# Remove patients with race "Other"
df4 = df3[df3.race_group != "Other"]
print(f"Removed {len(df3) - len(df4)} patients with no race information or other")
demo4 = print_demo(get_demography(df4))
print(f"{len(df4)} ICU stays with sepsis, 1d <= ICU LoS <= 30d, and race known \n({demo4})\n")

df4.to_csv('data/MIMIC_coh.csv')


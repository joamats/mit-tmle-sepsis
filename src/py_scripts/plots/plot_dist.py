import pandas as pd
from matplotlib import pyplot as plt
import numpy as np
from tqdm import tqdm

import matplotlib
matplotlib.use('TKAgg')

plot_name = "TMLE"
df = pd.read_csv(f"data\MIMIC_eICU.csv")

sofas_start = [0., 4., 7., 11.]
sofas_end = [3., 6., 10., 100.]

# initialize column
df['sofa_start'] = np.nan

# create column mapping sofa ranges
for s,e in zip(sofas_start, sofas_end):
    df['sofa_start'] = df.apply(lambda row: s \
                                     if ((row.SOFA >= s) & (row.SOFA <= e)) \
                                     else row.sofa_start,
                                     axis=1)

t_dict = dict(zip(["ventilation_bin", "rrt", "pressor"],
                  ["Mechanical Ventilation", "RRT", "Vasopressor(s)"]))

r_dict = dict(zip(range(2), ["Non-White", "White"]))

fig, axes = plt.subplots(1, 3,
                         sharex=True, sharey=True,
                         figsize=(8.25,3),
                         constrained_layout=True)

fig.suptitle('Distribution of Patients, across SOFA ranges and treatment\n')

w = [-.7, .7] 

colors1 = ['dimgray', 'firebrick']
colors2 = ['silver', 'salmon']


for i, t in enumerate(t_dict.keys()):

    # iterating over races
    for j, r in r_dict.items():

        df_temp = df[df.ethnicity_white == j]


        axes[i].bar(x=[i + w[j]/2 for i in sofas_start],
                    height=df_temp[df_temp[t]==0].groupby('sofa_start')[t].count()/1000,
                    width=w[1],
                    label=f"{r}\nNot Treated",
                    color=colors1[j],
                    edgecolor='white'
                    )

        axes[i].bar(x=[i + w[j]/2 for i in sofas_start],
                    height=df_temp[df_temp[t]==1].groupby('sofa_start')[t].count()/1000,
                    width=w[1],
                    label=f"{r}\nTreated",
                    bottom=df_temp[df_temp[t]==0].groupby('sofa_start')[t].count()/1000,
                    color=colors2[j],
                    hatch="//",
                    edgecolor='white'
                    )
            
    axes[i].set(xlabel=None)
    axes[i].set(ylabel=None)

    axes[i].set_title(t_dict[t])
    axes[i].set_xticklabels(["0-3", "4-6", "7-10", ">10"])
    axes[i].set_xticks([0., 4., 7., 11.])
    axes[0].set(ylabel="Number of Patients\n(thousands)")
    axes[2].legend(bbox_to_anchor=(1.05, 1.02), loc='upper left')

fig.supxlabel('\nSOFA Range              ')

fig.savefig(f"results/paper/fig4_TMLE_dist.png", dpi=200)
import pandas as pd
from matplotlib import pyplot as plt
import seaborn as sb

import matplotlib
matplotlib.use('TKAgg')

plot_name = "TMLE"
df = pd.read_csv(f"results\{plot_name}.csv")

# Remove overall result
df = df[~((df.sofa_start == 0) & (df.sofa_end == 100))]

# Transform into percentages
df.psi = df.psi * 100
df.i_ci = df.i_ci * 100
df.s_ci = df.s_ci * 100

treatments = df.treatment.unique()
races = df.race.unique()

t_dict = dict(zip(["ventilation_bin", "rrt", "pressor"],
                  ["Mechanical Ventilation", "RRT", "Vasopressor(s)"]))

fig, axes = plt.subplots(1, len(treatments),
                         sharex=True, sharey=True,
                         figsize=(8.5,2.5),
                         constrained_layout=True)

fig.suptitle('Distribution of Patients, across SOFA ranges and treatment')

w = .7

for i, t in enumerate(treatments):

    df_temp1 = df[(df.treatment == t) & (df.race == "non-white")]
    df_temp2 = df[(df.treatment == t) & (df.race == "white")]

    axes[i].set(xlabel=None)
    axes[i].set(ylabel=None)

    axes[i].bar(x=df_temp1.sofa_start + w/2,
                height=df_temp1.n/1000,
                width=w, label='Non-White', color='black')

    axes[i].bar(x=df_temp2.sofa_start - w/2,
                height=df_temp2.n/1000,
                width=w, label='White', color='tab:orange')

    axes[i].set_title(t_dict[t])
    axes[i].set_xticklabels(["0-3", "4-6", "7-10", ">10"])
    axes[i].set_xticks([0, 4, 7, 11])
    axes[0].set(ylabel="Number of Patients\n(thousands)")
    axes[2].legend(bbox_to_anchor=(1.05, 0.7), loc='upper left')


fig.supxlabel('SOFA Range')

fig.savefig(f"results/paper/fig4_TMLE_dist.png", dpi=1000)
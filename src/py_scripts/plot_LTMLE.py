import pandas as pd
from matplotlib import pyplot as plt

import matplotlib
matplotlib.use('TKAgg')


df = pd.read_csv("results\LTMLE.csv")

# Remove overall result
df = df[~((df.sofa_start == 0) & (df.sofa_end == 100))]

# Transform into percentages
df.psi = df.psi * 100
df.iCI = df.iCI * 100
df.sCI = df.sCI * 100

treatments = df.treatment.unique()
analyses = df.analysis.unique()

t_dict = dict(zip(["ventilation_bin", "rrt", "pressor"],
                  ["Mechanical Ventilation", "RRT", "Vasopressor(s)"]))

a_dict = {
    "Yes-Treatment": "Everyone is treated\nWhite vs. Non-White",
    "Non-Treatment": "Everyone is not treated\nWhite vs. Non-White",
    "White": "Everyone is White\nTreated vs. Not Treated",
    "Non-white": "Everyone is Non-white\nTreated vs. Not Treated"
}

colors = ["tab:orange", "tab:green", "tab:blue"]


fig, axes = plt.subplots(len(analyses), len(treatments), sharex=True, sharey=True, figsize=(7,7.5), constrained_layout=True)

fig.suptitle('Longitudinal TMLE')

for i, a in enumerate(analyses):
    for j, t in enumerate(treatments):

        df_temp = df[(df.treatment == t) & (df.analysis == a)]
        axes[i,j].set(xlabel=None)
        axes[i,j].set(ylabel=None)
        axes[i,j].errorbar(x=df_temp.sofa_start, y=df_temp.psi,
                           yerr=((df_temp.psi- df_temp.iCI), (df_temp.sCI-df_temp.psi)),
                           fmt='-o', c=colors[j], ecolor="tab:gray", elinewidth=.7, linewidth=2)
        axes[i,j].axhline(y=0, xmin=0, xmax=1, c="black", linewidth=.7, linestyle='--')
        axes[i,j].set_ylim([-12, 12])
        axes[0,j].set_title(t_dict[t])
        axes[i,0].set(ylabel=a_dict[a])
        
        axes[-1,j].set_xticklabels(["0 - 3", "4 - 6", "7 - 10", "> 10"])
        axes[-1,j].set_xticks([0, 4, 7, 11])


fig.supxlabel('SOFA Range')
fig.supylabel('ATE (%)')
    

fig.savefig("results/Paper/LTMLE.png", dpi=700)
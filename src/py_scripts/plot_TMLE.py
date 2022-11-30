import pandas as pd
from matplotlib import pyplot as plt
import seaborn as sb

import matplotlib
matplotlib.use('TKAgg')

df = pd.read_csv("results\TMLE.csv")

# Remove overall result
df = df[~((df.sofa_start == 0) & (df.sofa_end == 100))]

# Transform into percentages
df.psi = df.psi * 100
df.i_ci = df.i_ci * 100
df.s_ci = df.s_ci * 100

treatments = df.treatment.unique()
t_dict = dict(zip(["ventilation_bin", "rrt", "pressor"],
                  ["Mechanical Ventilation", "RRT", "Vasopressor(s)"]))
colors = ["tab:orange", "tab:green", "tab:blue"]

fig, axes = plt.subplots(1, len(treatments), sharex=True,  figsize=(10,3.5), constrained_layout=True)

fig.suptitle('TMLE for each Invasive Treatment, across different SOFA ranges')

for i, t in enumerate(treatments):

    df_temp = df[df.treatment == t]
    axes[i].set(xlabel=None)
    axes[i].set(ylabel=None)
    axes[i].errorbar(x=df_temp.sofa_start, y=df_temp.psi, yerr=((df_temp.psi- df_temp.i_ci), (df_temp.s_ci-df_temp.psi)), fmt='-o', c=colors[i], ecolor='black', elinewidth=.7, linewidth=2)
    axes[i].axhline(y=0, xmin=0, xmax=1, c="tab:red", linewidth=.5, linestyle='--')
    axes[i].set_ylim([-30, 30])
    axes[i].set_title(t_dict[t])
    axes[i].set_xticklabels(["", "0 - 5", " 6 - 10", "11 - 15", "> 15"])

fig.supxlabel('SOFA Range')
fig.supylabel('ATE (%)')
    

fig.savefig("results/Paper/TMLE.png", dpi=2000)
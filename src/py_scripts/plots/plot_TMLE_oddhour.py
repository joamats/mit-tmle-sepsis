import pandas as pd
from matplotlib import pyplot as plt
import seaborn as sb

import matplotlib

matplotlib.use("TKAgg")

plot_name = "MIMIC/odd_hour"
# plot_name = "MIMIC/blood_yes"
title = "TMLE for odd hour vs. even hour of discharge or death\n"
df = pd.read_csv(f"results/prob_mort/{plot_name}.csv")

# discard data from prob_mort range 0 to 1
# concatenate prob_mort_start and prob_mort_end as string
df["probconcat"] = (
    df["prob_mort_start"].astype(str) + "-" + df["prob_mort_end"].astype(str)
)
df = df.loc[(df.probconcat != "0.0-1.0")]

conversion_dict = dict(zip(df.prob_mort_start.unique(), range(4)))
df.prob_mort_start = df.prob_mort_start.apply(lambda x: conversion_dict[x])


# Transform into percentages
df.psi = df.psi * 100
df.i_ci = df.i_ci * 100
df.s_ci = df.s_ci * 100

treatments = df.treatment.unique()
races = df.race.unique()

t_dict = dict(
    zip(
        ["mv_elig", "rrt_elig", "vp_elig"],
        ["Mechanical Ventilation", "RRT", "Vasopressor(s)"],
    )
)

fig, axes = plt.subplots(
    1,
    len(treatments),
    sharex=True,
    sharey=True,
    figsize=(8.25, 3),
    constrained_layout=True,
)

fig.suptitle(title)

for i, t in enumerate(treatments):

    df_temp1 = df[(df.treatment == t) & (df.race == "all")]
    df_temp2 = df[(df.treatment == t) & (df.race == "all")]

    axes[i].set(xlabel=None)
    axes[i].set(ylabel=None)

    # axes[i].errorbar(x=df_temp1.prob_mort_start,
    #                  y=df_temp1.psi,
    #                  yerr=((df_temp1.psi- df_temp1.i_ci), (df_temp1.s_ci-df_temp1.psi)),
    #                  fmt='-o', c='dimgray', ecolor='dimgray',
    #                  elinewidth=.4, linewidth=1.5, capsize=4, markeredgewidth=.4,
    #                  label="All races")

    axes[i].errorbar(
        x=df_temp2.prob_mort_start,
        y=df_temp2.psi,
        yerr=((df_temp2.psi - df_temp2.i_ci), (df_temp2.s_ci - df_temp2.psi)),
        fmt="-o",
        c="firebrick",
        ecolor="firebrick",
        elinewidth=0.4,
        linewidth=1.5,
        capsize=4,
        markeredgewidth=0.4,
        label="All races",
    )

    axes[i].axhline(y=0, xmin=0, xmax=1, c="black", linewidth=0.7, linestyle="--")
    axes[i].set_ylim([-25, 25])
    axes[i].set_title(t_dict[t])
    axes[0].set(ylabel="ATE change in mortality (%)\nTreated vs. Not Treated")
    axes[2].legend(bbox_to_anchor=(1.05, 0.7), loc="upper left")
    axes[i].set_xticklabels(["0-6", "7-11", "12-21", ">21"])
    axes[i].set_xticks(range(4))

fig.supxlabel("\nPredicted mortality (%)")

# fig.savefig(f"results/prob_mort/{plot_name}.png", dpi=1000)
fig.savefig(f"results/prob_mort/{plot_name}.tif", dpi=200)

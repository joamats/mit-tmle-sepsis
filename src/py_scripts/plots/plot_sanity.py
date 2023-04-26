import pandas as pd
from matplotlib import pyplot as plt
import numpy as np
from tqdm import tqdm

import matplotlib
matplotlib.use('TKAgg')

# Read in the CSV file
data = pd.read_csv(f"data/MIMIC.csv")

# Subset data according to ethnicity_white
#data = data.loc[data['ethnicity_white'] == 0] # non-whites
#data = data.loc[data['ethnicity_white'] == 1] # whites

# Define the bins for prob_mort
bins = [0, 0.06, 0.11, 0.21, 1]

# Define the treatment options
treatments = ["mv_elig", "rrt_elig", "vp_elig"]
treat_names = ["Mechanical Ventilation", "RRT", "Vasopressor(s)"]

# Define the colors for survived and died
colors = ["dimgray", "firebrick"]

# Set the figure and axes
fig, ax = plt.subplots(1, 3,
                       sharex=True, sharey=True,
                       figsize=(8.25,3),
                       constrained_layout=True)

fig.suptitle('Likelihood of Receiving a Treatment, per Outcome\n')


# Loop over the treatments
for i, treatment in enumerate(treatments):

    # Get the data for the current treatment
    treat_data = data[data[treatment] == 1]
    non_treat_data = data[data[treatment] == 0]

    # Loop over the bins
    for j in range(len(bins)-1):

        # Get the data for the current bin
        bin_treat_data = treat_data[(treat_data["prob_mort"] >= bins[j]) & (treat_data["prob_mort"] < bins[j+1])]
        bin_non_treat_data = non_treat_data[(non_treat_data["prob_mort"] >= bins[j]) & (non_treat_data["prob_mort"] < bins[j+1])]

        # Get the number of people in the bin with each outcome
        num_survived = len(bin_treat_data[bin_treat_data["mortality_in"] == 0]) + len(bin_non_treat_data[bin_non_treat_data["mortality_in"] == 0])
        num_died = len(bin_treat_data[bin_treat_data["mortality_in"] == 1]) + len(bin_non_treat_data[bin_non_treat_data["mortality_in"] == 1])

        # Get the number of people in the bin with each outcome and the treatment
        num_survived_treat = len(bin_treat_data[(bin_treat_data["mortality_in"] == 0)])
        num_died_treat = len(bin_treat_data[(bin_treat_data["mortality_in"] == 1)])

        # Calculate the probability of surviving or dying given that they received the treatment, normalized by outcome
        prob_survived_treat = num_survived_treat / num_survived * 100
        prob_died_treat = num_died_treat / num_died * 100

        # just for the last iteration of this loop
        if j == len(bins)-2:
            # Plot the bar for the current bin and outcome
            ax[i].bar(j-.16, prob_survived_treat, width=.3, color=colors[0], label="Survived")
            ax[i].bar(j+.16, prob_died_treat, width=.3, color=colors[1], label="Died")
        else:
            # Plot the bar for the current bin and outcome
            ax[i].bar(j-.16, prob_survived_treat, width=.3, color=colors[0])
            ax[i].bar(j+.16, prob_died_treat, width=.3, color=colors[1])


    # Set the x-axis tick labels and the y-axis label
    ax[i].set_xticks(range(len(bins)-1))
    ax[i].set_xticklabels(["0-6", "7-11", "12-21", "> 21"])
    ax[i].set_ylim([0,100])
    ax[0].set(ylabel="Probability of Receiving Treatment (%)")
    ax[i].set_title(treat_names[i])
    ax[2].legend(bbox_to_anchor=(1.05, 0.65), loc='upper left')

fig.supxlabel('\nMortality Probability (%)               ')

# Save the figure
fig.savefig(f"results/sanity_check_all.png", dpi=300, bbox_inches="tight")
#fig.savefig(f"results/sanity_check_non-whites.png", dpi=300, bbox_inches="tight")
#fig.savefig(f"results/sanity_check_whites.png", dpi=300, bbox_inches="tight")
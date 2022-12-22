import pandas as pd
import numpy as np
from matplotlib import pyplot as plt
import seaborn as sb
import matplotlib
matplotlib.use('TKAgg')

df = pd.read_csv("data/MIMIC_eICU.csv")[['SOFA', 'OASIS_W', 'OASIS_N', 'OASIS_B', 'source']]
df.source = df.source.apply(lambda x: "MIMIC" if x==1 else "eICU")

methods = ['OASIS_W', 'OASIS_N', 'OASIS_B']
titles = ['Pessimistic Scenario', 'With Missing Patients', 'Optimistic Scenario' ]

fig, axes = plt.subplots(1, 3,
                         sharex=True, sharey=True,
                         figsize=(10, 3.5),
                         constrained_layout=True)

fig.suptitle('OASIS vs. SOFA mappings')

for i, m in enumerate(methods):

    sb.scatterplot(data=df,
                   y="SOFA",
                   x=m, 
                   hue="source",
                   ax=axes[i],
                   alpha=.8)

    axes[i].set_xlim([-5, 75])
    axes[i].set_ylim([-2, 24])
    axes[i].set(ylabel='SOFA')
    axes[i].set(xlabel=methods[i])
    axes[i].set_title(titles[i])
    axes[i].legend()


#fig.savefig('results/OASIS/sofa_oasis.png', dpi=700)


# We're taking OASIS best from now, after looking at the plots generated above

fig = plt.figure()

sb.histplot(data=df,
            x='OASIS_B', bins=10)

fig.savefig('results/OASIS/oasis_dist.png', dpi=300)

def oasis_ranges(oasis):
    if oasis <= 37:
        return 0
    elif (oasis >= 38) & (oasis <= 45):
        return 1
    elif (oasis >= 46) & (oasis <=51):
        return 2
    elif oasis >= 52:
        return 3

def sofa_ranges(oasis):
    if oasis <= 3:
        return 0
    elif (oasis >= 4) & (oasis <= 6):
        return 1
    elif (oasis >= 7) & (oasis <=10):
        return 2
    elif oasis >= 11:
        return 3

def addlabels(x,y):
    for i in range(len(x)):
        plt.text(i, y[i], f"{y[i]:.2f}", ha = 'center')


df['OASIS_range'] = df.OASIS_B.apply(lambda x: oasis_ranges(x))

n = len(df['OASIS_range'])
val_counts = df['OASIS_range'].value_counts() / n * 100
val_counts = val_counts.sort_index()
fig = plt.figure()

x=range(4)

plt.bar(x=x,
        height=val_counts)

addlabels(x,val_counts)

plt.xticks(range(4), ["0-37", "38-45", "46-51", ">51"])
plt.title("OASIS Ranges")
plt.ylabel("Counts (%)")

fig.savefig('results/OASIS/oasis_ranges.png', dpi=300)



df['SOFA_range'] = df.SOFA.apply(lambda x: sofa_ranges(x))

n = len(df['SOFA_range'])
val_counts = df['SOFA_range'].value_counts() / n * 100
val_counts = val_counts.sort_index()

fig = plt.figure()

plt.bar(x=x,
        height=val_counts)

addlabels(x,val_counts)

plt.xticks(range(4), ["0-3", "4-6", "7-10", ">11"])
plt.title("SOFA Ranges")
plt.ylabel("Counts (%)")

fig.savefig('results/OASIS/sofa_ranges.png', dpi=300)


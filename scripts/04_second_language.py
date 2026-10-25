"""
04_second_language.py - Question 5: recompute the band table of Question 3 and
redraw the Question 3 figure in Python. Run from the repository root:

    python scripts/04_second_language.py

Needs: pandas, numpy, matplotlib   (pip install pandas numpy matplotlib)
"""
import os
import re

import matplotlib
matplotlib.use("Agg")                      # draw to file, no window needed
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import FixedLocator, FuncFormatter, NullLocator

if not os.path.exists("data/pslm_person_subset.csv"):
    raise SystemExit("Run this script from the repository root (the folder containing data/ and scripts/).")
os.makedirs("figures", exist_ok=True)
os.makedirs("results", exist_ok=True)

# ---- 1. Variant: last two digits of the registration number, mod 8 ----------
REG = open("reg.txt").read().strip()
DIGITS = int(re.search(r"(\d{2})$", REG).group(1))
VARIANT = DIGITS % 8
PROV, AREA, LABEL = {
    0: (2, 1, "Punjab rural"),   1: (2, 2, "Punjab urban"),
    2: (3, 1, "Sindh rural"),    3: (3, 2, "Sindh urban"),
    4: (1, 1, "KP rural"),       5: (1, 2, "KP urban"),
    6: (4, 1, "Balochistan rural"), 7: (4, 2, "Balochistan urban"),
}[VARIANT]

# ---- 2. Sample: earners aged 15-64, earn_annual > 0, in my variant ----------
person = pd.read_csv("data/pslm_person_subset.csv", usecols=["hhid", "age", "earn_annual"])
hh = pd.read_csv("data/pslm_hh_subset.csv", usecols=["hhid", "hhweight", "prov_code", "urban_rural"])
assert hh["hhid"].is_unique
d = person.merge(hh, on="hhid", how="inner")
assert len(d) == len(person)
d = d[(d.prov_code == PROV) & (d.urban_rural == AREA) &
      d.age.between(15, 64) & (d.earn_annual > 0)].copy()      # NaN > 0 is False -> dropped

# ---- 3. Five-year bands. pd.cut defaults to right-closed (a, b]; the assignment
#         needs [a, b), so right=False must be set ----------------------------
labels = [f"{a}-{a + 4}" for a in range(15, 65, 5)]
d["band"] = pd.cut(d["age"], bins=list(range(15, 70, 5)), right=False, labels=labels)
d["mid"] = d["band"].cat.codes * 5 + 17
d["wx"] = d["hhweight"] * d["earn_annual"]

# ---- 4. Band table: n and weighted mean = sum(w*x) / sum(w) -----------------
tab = (d.groupby(["band", "mid"], observed=True)
         .agg(n=("age", "size"), sw=("hhweight", "sum"), swx=("wx", "sum"))
         .reset_index())
tab["wmean"] = tab["swx"] / tab["sw"]
tab["thin"] = tab["n"] < 30
tab["wmean_rs"] = tab["wmean"].round().astype(int)
print(tab[["band", "mid", "n", "wmean_rs", "thin"]].to_string(index=False))
tab[["band", "mid", "n", "wmean", "thin", "wmean_rs"]].to_csv("results/band_table_python.csv", index=False)

# ---- 5. Compare with the R band table (must agree to the rupee) -------------
if os.path.exists("results/band_table_R.csv"):
    r = pd.read_csv("results/band_table_R.csv")
    same_n = (r["n"].values == tab["n"].values).all()
    same_rs = (r["wmean_rs"].values == tab["wmean_rs"].values).all()
    print("\nR vs Python: n identical =", same_n, "| weighted means identical to the rupee =", same_rs)
    band_25 = int(tab.loc[tab.band == "25-29", "wmean_rs"].iloc[0])
    print("25-29 band mean  R:", int(r.loc[r.band == "25-29", "wmean_rs"].iloc[0]), " Python:", band_25)
else:
    print("\n(results/band_table_R.csv not found - run scripts/03_relationship.R first to compare.)")

top = tab.loc[tab["wmean"].idxmax()]

# ---- 6. Figure (matching the R figure) --------------------------------------
fig, ax = plt.subplots(figsize=(9, 5.5))
rng = np.random.default_rng(1)
jit = d["age"] + rng.uniform(-0.4, 0.4, len(d))                 # horizontal jitter, at most 0.4
ax.scatter(jit, d["earn_annual"], s=9, alpha=0.15, color="#404040", linewidths=0, zorder=2)
ax.plot(tab["mid"], tab["wmean"], color="firebrick", lw=1.8, zorder=3)
solid, hollow = tab[~tab["thin"]], tab[tab["thin"]]
ax.scatter(solid["mid"], solid["wmean"], s=75, color="firebrick", zorder=4)
ax.scatter(hollow["mid"], hollow["wmean"], s=75, facecolors="white", edgecolors="firebrick",
           linewidths=1.6, zorder=4)
ax.text(min(top["mid"], 58), top["wmean"] * 2.1, f"Highest: ages {top['band']}\nmean Rs {int(top['wmean_rs']):,}",
        color="firebrick", fontweight="bold", ha="center", va="center")

ax.set_yscale("log")
ax.set_ylim(1e4, 1e7)
ax.set_xlim(14, 65)
ax.yaxis.set_major_locator(FixedLocator([1e4, 1e5, 1e6, 1e7]))   # matplotlib adds minor ticks by default
ax.yaxis.set_minor_locator(NullLocator())
ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"Rs {v:,.0f}"))
ax.set_xticks(range(15, 66, 10))
ax.grid(True, color="#e5e5e5", lw=0.8, zorder=0)
for s in ax.spines.values():
    s.set_visible(False)
ax.set_xlabel("Age (years)")
ax.set_ylabel("Annual earnings (log scale)")
fig.suptitle(f"Average earnings in {LABEL} peak at ages {top['band']} (Rs {int(top['wmean_rs']):,})",
             x=0.01, ha="left", fontsize=13, fontweight="bold")
caption = (f"Source: PSLM 2019-20. Sample: {len(d):,} earners aged 15-64 in {LABEL}.\n"
           "Points: individual earners (jittered, transparent).\n"
           "Markers: weighted mean of each five-year band (weights: hhweight).\n"
           "Hollow markers = bands with fewer than 30 observations.")
fig.text(0.01, 0.01, caption, ha="left", va="bottom", fontsize=8)
fig.subplots_adjust(top=0.90, bottom=0.24, left=0.19, right=0.97)
plt.savefig("figures/relationship_py.svg")
print("Saved figures/relationship_py.svg")

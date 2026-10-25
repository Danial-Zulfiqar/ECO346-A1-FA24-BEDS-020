#!/bin/bash
set -e
git add data reg.txt ECO346-A1.Rproj
git commit -m "Add PSLM data files and project setup"
git add scripts/00_helpers.R scripts/01_default.R figures/default.svg
git commit -m "Add default scatterplot of earnings against age"
git add scripts/02_distribution.R figures/distribution.svg results/q2_numbers.csv
git commit -m "Add weighted log-scale histogram of earnings"
git add scripts/03_relationship.R figures/relationship.svg results/band_table_R.csv
git commit -m "Add redesigned figure with weighted band means"
git add scripts/04_second_language.py figures/relationship_py.svg results/band_table_python.csv
git commit -m "Reproduce band table and figure in Python"
git add README.md
git commit -m "Add README with variant, figures, band table and interpretation"
git add slides
git commit -m "Add presentation slides"
git add -A
git diff --cached --quiet || git commit -m "Add remaining files"
git push
git log --oneline

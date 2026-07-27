# Rehoboth Transportation — Logistics Operations EDA

SQL-based exploratory data analysis on a simulated 14-table Class 8 trucking/logistics dataset (~85,000+ trip records), branded here as "Rehoboth Transportation" for portfolio purposes.

*Note: this is illustrative synthetic data (Kaggle/GitHub-sourced logistics dataset), not real operational data from an active company.*

## What's in this repo

- **`findings.md`** — full write-up of findings: data quality audit, driver fuel efficiency, hiring trends, route profitability, and predictive maintenance analysis.
- **`sql-reference.md`** — every SQL query used in the project, labeled by section (data cleaning, each analysis question).
- **Dashboard screenshot** — Excel dashboard summarizing the three key findings visually.

## Tools used

MySQL (data cleaning, exploratory SQL queries) → Excel (dashboard: pivot-style summary tables and charts)

## Key finding

Charlotte → Portland is the highest-value route in the network — not by volume, but by revenue per load — outperforming routes with significantly more shipments. Full breakdown in `findings.md`.

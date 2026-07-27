# Rehoboth Transportation — Logistics Operations EDA

**Dataset:** Simulated Class 8 trucking/logistics dataset (14 tables, ~85,000+ trip records, 2022-2024 trip activity), branded here as "Rehoboth Transportation" for portfolio purposes. *Note: this is illustrative synthetic data, not real operational data from an active company.*
**Tools:** MySQL (data cleaning, SQL queries) → Excel (dashboard)

## 1. Data Quality Audit

Before analysis, all tables were checked for duplicates, NULLs/blank values, referential integrity, out-of-range values, date logic, and category consistency.

- **Duplicates:** None found across `drivers`, `loads`, `trips`, `routes`.
- **Date columns:** Imported as TEXT rather than DATE type by the MySQL import wizard; converted via `ALTER TABLE ... MODIFY ... DATE` after cleaning empty-string values to NULL.
- **Missing driver assignment:** 1,714 of ~85,000 "Completed" trips (≈2%) have no `driver_id` recorded. 1,672 (≈2%) separately have no `truck_id` recorded. Only 37 trips have both missing — close to what independent, unrelated gaps would produce by chance, ruling out a single shared cause. No clustering by year (evenly split 2022-2024) or by vehicle (spread across dozens of trucks, no concentration). **Conclusion:** random data-entry gaps, not a systemic operational failure. Both fields excluded from their respective entity-level analysis; all rows retained for trip/route-level analysis where the missing field isn't relevant.

## 2. Driver Fuel Efficiency (MPG)

Each driver's trips were ranked by `average_mpg` to identify their best and worst performance within their own trip history (not compared across drivers, since route/distance differences make cross-driver comparisons unfair without controlling for those factors).

Each trip was also compared against that driver's own average MPG to flag below-average performance days — a per-driver benchmark rather than a single company-wide cutoff, so drivers on harder routes aren't unfairly flagged next to drivers on easier ones.

*Open question for further analysis: normalizing underperformance counts as a percentage of each driver's total trips, since drivers with more trips will naturally accumulate more flagged trips in raw-count terms.*

## 3. Driver Hiring Trend

Hiring by year (2012-2021, based on `drivers.hire_date`) ranged from 8 to 21 drivers/year, averaging roughly 15/year, with no unusual spikes or freezes. **Note:** this hiring-history range (2012-2021) is separate from and predates the trip-activity window analyzed elsewhere in this report (2022-2024, based on `trips.dispatch_date`) — drivers hired years earlier can still appear in the more recent trip data. **Conclusion:** hiring has been steady and organic, consistent with normal turnover-driven replacement hiring rather than aggressive fleet expansion or contraction.

## 4. Route Profitability

Top 5 routes by total revenue (completed loads only):

| Route | Total Loads | Total Revenue | Avg Revenue/Load |
|---|---|---|---|
| Charlotte → Portland | 1,410 | $11,127,353.42 | $7,891.74 |
| Seattle → Charlotte | 1,467 | $10,824,377.65 | $7,378.58 |
| Columbus → Portland | 1,525 | $10,795,678.90 | $7,079.13 |
| Philadelphia → Seattle | 1,465 | $10,748,711.67 | $7,337.00 |
| Phoenix → Philadelphia | 1,507 | $10,441,579.75 | $6,928.72 |

**Key finding:** Charlotte → Portland is the #1 route by both total revenue *and* average revenue per load, despite having the *fewest* loads of the top 5 (1,410 vs. 1,465-1,525 on the other four). This means it isn't winning on volume — it's winning on per-unit value, suggesting premium freight or a favorable rate structure on this lane, worth protecting or replicating on other routes.

## 5. Truck Mileage & Predictive Maintenance

**Dataset period:** confirmed via `DATEDIFF(MAX(dispatch_date), MIN(dispatch_date))` — the trip data spans approximately 3 years.

Total distance driven, active years, and miles/year were calculated per **truck** (not per driver, since mileage accumulates on the equipment regardless of who drives it). Semi trucks typically reach end-of-life between 1M-1.5M miles, so each truck's lifetime average miles/year was used to project when it will cross the 1M-mile threshold — flagging which trucks should be prioritized for replacement planning.

**Limitation/caveat:** this projection uses each truck's *lifetime* average miles/year, which smooths out year-to-year variation from breakdowns, driver turnover, and demand shifts — a deliberate choice, since a single year's mileage isn't a reliable base rate on its own. However, a lifetime average can mask a *recent* slowdown or acceleration in usage (e.g. a truck nearing retirement may show reduced recent mileage that a lifetime average wouldn't fully capture). A more refined version of this analysis would compare lifetime average against a trailing 12-month average to catch that kind of trend shift.

**Additional caveat — sanity check on scale:** calculated annual mileage for this fleet runs roughly 450,000-470,000 miles/year per truck, well above typical real-world long-haul averages of ~100,000-125,000 miles/year. This suggests the dataset simulates unusually high utilization rather than reflecting typical real-world fleet operations. As a result, nearly the entire fleet (92 of 93 trucks) appears to approach the 1.5M-mile threshold within the same narrow window — a pattern that would be unusual for a real fleet acquired over time. This finding should be read as a demonstration of the predictive-maintenance methodology rather than a literal, actionable fleet crisis, given the underlying data's scale doesn't match typical industry benchmarks.

---
*Next: dashboard build in Excel visualizing route revenue and driver/truck performance.*

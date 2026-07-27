# SQL Reference — Rehoboth Transportation EDA Project

Every query built so far, labeled for quick lookup. Add new ones to the bottom as we go.

## 1. Data Quality Audit

**Duplicate check (pattern — swap table/column):**
```sql
SELECT driver_id, COUNT(*) FROM drivers_backup GROUP BY driver_id HAVING COUNT(*) > 1;
```

**NULL/blank check (pattern — swap table/column):**
```sql
SELECT COUNT(*) FROM trips_backup WHERE driver_id IS NULL;
SELECT COUNT(*) FROM trips_backup WHERE driver_id = '';
SELECT COUNT(*) FROM trips_backup WHERE TRIM(driver_id) = '' AND driver_id IS NOT NULL;
```

**Referential integrity (orphan check):**
```sql
SELECT t.driver_id
FROM trips_backup t
LEFT JOIN drivers_backup d ON t.driver_id = d.driver_id
WHERE d.driver_id IS NULL;
```

**Fixing text-stored dates:**
```sql
UPDATE drivers_backup SET termination_date = NULL WHERE termination_date = '';
ALTER TABLE drivers_backup MODIFY termination_date DATE;
```

**Duplicating a table safely (structure + data):**
```sql
CREATE TABLE trips_backup LIKE trips;
INSERT INTO trips_backup SELECT * FROM trips;
```

## 2. Drill 1 — Driver MPG Ranking (window function, no GROUP BY)
```sql
SELECT driver_id, trip_id, average_mpg,
       RANK() OVER (PARTITION BY driver_id ORDER BY average_mpg DESC) AS mpg_rank
FROM trips_backup
WHERE driver_id != '' AND driver_id IS NOT NULL
ORDER BY driver_id, mpg_rank;
```

## 3. Drill 2 — Drivers Hired Per Year (aggregate)
```sql
SELECT YEAR(hire_date), COUNT(*)
FROM drivers_backup
WHERE driver_id != '' AND driver_id IS NOT NULL
GROUP BY YEAR(hire_date)
ORDER BY YEAR(hire_date);
```

## 4. Drill 3 — Top 5 Routes by Revenue (aggregate + load count)
```sql
SELECT r.route_id, origin_city, destination_city, COUNT(*) AS Total_loads_per_routes,
       ROUND(SUM(revenue + fuel_surcharge), 2) AS Total_revenue
FROM routes_backup AS r
INNER JOIN loads_backup AS l ON r.route_id = l.route_id
WHERE r.route_id != '' AND l.load_status = 'Completed'
GROUP BY r.route_id, origin_city, destination_city
ORDER BY Total_revenue DESC
LIMIT 5;
```

## 5. Drill 4 — Underperforming Trips vs. Driver's Own Average (CTE + window)
```sql
WITH driver_mpg_avg AS (
    SELECT trip_id, driver_id, average_mpg,
           ROUND(AVG(average_mpg) OVER (PARTITION BY driver_id), 2) AS driver_avg_mpg
    FROM trips_backup
    WHERE driver_id != '' AND trip_status = 'Completed'
)
SELECT trip_id, driver_id, average_mpg, driver_avg_mpg
FROM driver_mpg_avg
WHERE average_mpg < driver_avg_mpg
ORDER BY driver_id, average_mpg ASC;
```

## 6. Drill 5 — Running Total Miles Per Driver (window, chronological)
```sql
SELECT driver_id, trip_id, actual_distance_miles,
       SUM(actual_distance_miles) OVER (PARTITION BY driver_id ORDER BY dispatch_date) AS running_total
FROM trips_backup
WHERE driver_id != '' AND trip_status = 'Completed';
```

**Grand total per driver (aggregate version, CEO scorecard):**
```sql
SELECT driver_id, SUM(actual_distance_miles) AS Total_miles_driven
FROM trips_backup
WHERE driver_id != '' AND trip_status = 'Completed'
GROUP BY driver_id
ORDER BY Total_miles_driven DESC;
```

## 7. Truck Predictive Maintenance Projection (aggregate + date math)
```sql
SELECT truck_id,
       SUM(actual_distance_miles) AS total_miles,
       MIN(dispatch_date) AS first_trip,
       MAX(dispatch_date) AS last_trip,
       DATEDIFF(MAX(dispatch_date), MIN(dispatch_date)) / 365.0 AS years_active,
       ROUND(SUM(actual_distance_miles) / (DATEDIFF(MAX(dispatch_date), MIN(dispatch_date)) / 365.0), 0) AS miles_per_year,
       ROUND((1500000 - SUM(actual_distance_miles)) / (SUM(actual_distance_miles) / (DATEDIFF(MAX(dispatch_date), MIN(dispatch_date)) / 365.0)), 1) AS est_years_to_1_5M_miles
FROM trips_backup
WHERE truck_id != '' AND truck_id IS NOT NULL
GROUP BY truck_id
ORDER BY est_years_to_1_5M_miles ASC;
```
*Note: swap 1500000 back to 1000000 if comparing against the 1M threshold instead.*

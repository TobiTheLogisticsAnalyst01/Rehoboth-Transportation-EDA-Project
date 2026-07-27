SHOW TABLES;

SELECT *
FROM drivers;

SELECT *
FROM loads;

SELECT*
FROM trips;

SELECT *
FROM routes;

CREATE TABLE drivers_backup
LIKE drivers;
INSERT INTO drivers_backup
SELECT *
FROM drivers;

CREATE TABLE loads_backup
LIKE loads;
INSERT INTO loads_backup
SELECT *
FROM loads;

CREATE TABLE trips_backup
LIKE trips;
INSERT INTO trips_backup
SELECT *
FROM trips;

CREATE TABLE routes_backup
LIKE routes;
INSERT INTO routes_backup
SELECT *
FROM routes;

-- DATA CLEANING --
ALTER TABLE drivers_backup
MODIFY hire_date DATE;

SELECT COUNT(*)
FROM drivers_backup
WHERE termination_date = '';

SELECT COUNT(*)
FROM drivers_backup
WHERE date_of_birth = '';

SELECT COUNT(*)
FROM loads_backup
WHERE load_date = '';

SELECT COUNT(*)
FROM trips_backup
WHERE dispatch_date = '';

UPDATE drivers_backup
SET termination_date = NULL
WHERE termination_date = '';

ALTER TABLE drivers_backup
MODIFY termination_date DATE;

ALTER TABLE loads_backup
MODIFY load_date DATE;

ALTER TABLE trips_backup
MODIFY dispatch_date DATE;

-- CHECKING FOR DUPLICATES --
SELECT driver_id, COUNT(*)
FROM drivers_backup
GROUP BY driver_id
HAVING COUNT(*) > 1;


SELECT *
FROM drivers_backup;

WITH duplicate_records AS (
SELECT driver_id, first_name, last_name, hire_date, license_number, date_of_birth,
ROW_NUMBER() OVER(PARTITION BY driver_id, license_number) AS row_num
FROM drivers_backup
)
SELECT *
FROM duplicate_records
WHERE row_num >1;


SELECT* FROM loads_backup;
SELECT load_id, COUNT(*)
FROM loads_backup
GROUP BY load_id
HAVING COUNT(*) > 1;

SELECT* FROM trips_backup;
SELECT trip_id, COUNT(*)
FROM trips_backup
GROUP BY trip_id
HAVING COUNT(*) > 1;

SELECT* FROM routes_backup;
SELECT route_id, COUNT(*)
FROM routes_backup
GROUP BY route_id
HAVING COUNT(*) > 1;

-- CHECKING FOR NULL VVALUES OR EMPTY STRING --
SELECT COUNT(*)
FROM trips_backup
WHERE actual_distance_miles IS NULL OR actual_distance_miles = '';

SELECT* FROM trips_backup;
SELECT COUNT(*)
FROM trips_backup
WHERE fuel_gallons_used IS NULL OR average_mpg = '';

SELECT* FROM routes_backup;
SELECT COUNT(*)
FROM routes_backup
WHERE typical_distance_miles IS NULL OR fuel_surcharge_rate = '';

SELECT* FROM loads_backup;
SELECT COUNT(*)
FROM loads_backup
WHERE revenue IS NULL OR fuel_surcharge = '';

-- Checking for referential integrity between tables --
SELECT t.driver_id
FROM trips_backup AS t
	 LEFT JOIN drivers_backup AS d ON t.driver_id = d.driver_id
WHERE d.driver_id IS NULL;

SELECT t.trip_id
FROM trips_backup AS t
	LEFT JOIN loads_backup AS l ON t.load_id = l.load_id
WHERE t.trip_id IS NULL;
SELECT* FROM loads_backup;
SELECT l.load_id
FROM loads_backup AS l
	LEFT JOIN trips_backup AS t ON l.load_id = t.load_id
WHERE l.load_id IS NULL;
	
SELECT * FROM routes_backup;
SELECT r.route_id
FROM routes_backup AS r
	LEFT JOIN loads_backup AS l ON r.route_id = l.route_id
WHERE r.route_id IS NULL;

-- Check for impossible or out-of-range values or Anomaly --
SELECT *
FROM trips_backup;

SELECT *
FROM trips_backup
WHERE average_mpg < 0 OR average_mpg > 12;

SELECT *
FROM loads_backup;

SELECT revenue, fuel_surcharge
FROM loads_backup
WHERE revenue < 0 OR fuel_surcharge < 0;

SELECT *
FROM routes_backup;

SELECT *
FROM drivers_backup;

-- Checking date logic makes sense --
SELECT *
FROM drivers_backup
WHERE termination_date IS NOT NULL
	AND termination_date < hire_date;
    
SELECT *
FROM trips_backup;

-- Check categorical columns for inconsistent spelling/casing --
SELECT *
FROM trips_backup;

SELECT DISTINCT trip_status
FROM trips_backup;

SELECT *
FROM loads_backup;

SELECT DISTINCT load_status
FROM loads_backup;


SELECT *
FROM drivers_backup;

SELECT DISTINCT employment_status
FROM drivers_backup;


SELECT *
FROM drivers_backup;
SELECT *
FROM trips_backup;

SELECT COUNT(*) FROM trips_backup WHERE driver_id IS NULL;
SELECT COUNT(*) FROM trips_backup WHERE driver_id = '';
SELECT COUNT(*) FROM trips_backup WHERE TRIM(driver_id) = '' AND driver_id IS NOT NULL;

SELECT COUNT(*)
FROM trips_backup;

SELECT trip_status, COUNT(*)
FROM trips_backup
WHERE driver_id = ''
GROUP BY trip_status;

SELECT COUNT(*)
FROM trips_backup
WHERE driver_id = ''
	AND trip_status = 'Completed'
    AND (truck_id = '' OR trailer_id = '' 
    OR fuel_gallons_used IS NULL OR actual_distance_miles IS NULL);
    
SELECT YEAR(dispatch_date), COUNT(*)
FROM trips_backup
WHERE driver_id = '' AND trip_status = 'Completed'
GROUP BY YEAR(dispatch_date)
ORDER BY 1;

SELECT truck_id, COUNT(*)
FROM trips_backup
WHERE driver_id = '' AND trip_status = 'Completed'
GROUP BY truck_id
ORDER BY COUNT(*) DESC
LIMIT 10;

SELECT COUNT(*)
FROM trips_backup
WHERE truck_id = '';

SELECT COUNT(*) 
FROM trips_backup 
WHERE driver_id = '' AND truck_id = '';

SELECT *
FROM trips_backup;

-- FINDING HOW MANY TRIPS WERE COMPLETED EACH YEAR --
SELECT YEAR(dispatch_date), COUNT(*)
FROM trips_backup
WHERE trip_status = 'Completed'
	AND driver_id IS NOT NULL
    AND truck_id IS NOT NULL
    AND trailer_id IS NOT NULL
GROUP BY YEAR(dispatch_date);

SELECT LENGTH(driver_id) FROM trips_backup WHERE driver_id = '';

-- EXPLORATORY DATA ANALYSIS(EDA) AND BUSINESS QUESTIONS --
-- 1. Driver MPG ranking — For each driver, rank their trips by average_mpg, best first.--
SELECT *
FROM trips_backup;

SELECT trip_id,  driver_id, average_mpg, 
RANK() OVER(PARTITION BY driver_id ORDER BY average_mpg DESC) AS Mpg_ranking
FROM trips_backup
WHERE driver_id != '' AND driver_id IS NOT NULL
ORDER BY Mpg_ranking;

-- 2 Hiring trend — find how many drivers were hired each year. --
SELECT *
FROM drivers_backup;

SELECT YEAR(hire_date), COUNT(*)
FROM drivers_backup
WHERE driver_id != '' AND driver_id IS NOT NULL
GROUP BY YEAR(hire_date)
ORDER BY YEAR(hire_date);


SELECT *
FROM loads_backup;

SELECT *
FROM routes_backup;

-- 3. Top 5 routes by revenue --
SELECT *
FROM routes_backup;

SELECT *
FROM loads_backup;

SELECT DISTINCT load_status
FROM loads_backup;

SELECT r.route_id,origin_city, destination_city, COUNT(*) AS Total_loads_per_routes,
ROUND(SUM(revenue + fuel_surcharge),2) AS Total_revenue
FROM routes_backup AS r
	INNER JOIN loads_backup AS l ON r.route_id = l.route_id
WHERE r.route_id != '' AND l.load_status = 'Completed'
GROUP BY r.route_id, origin_city, destination_city
ORDER BY Total_revenue DESC 
LIMIT 5;

-- 3b. Finding Average revenue per load --
SELECT r.route_id, origin_city, destination_city,
ROUND(SUM(revenue + fuel_surcharge)/ COUNT(*),2) AS Average_revenue_per_load
FROM routes_backup AS r
	INNER JOIN loads_backup AS l ON r.route_id = l.route_id
WHERE r.route_id != '' AND l.load_status = 'Completed'
GROUP BY r.route_id, origin_city, destination_city
ORDER BY Average_revenue_per_load DESC 
LIMIT 5;

-- 4. 'Underperforming trips --
SELECT *
FROM trips_backup;

SELECT trip_id, driver_id,average_mpg,
ROUND(AVG(average_mpg) OVER(PARTITION BY driver_id),2) AS Driver_average_mpg
FROM trips_backup
WHERE driver_id != '' AND trip_status = 'Completed'
ORDER BY driver_id, average_mpg ASC;

WITH Driver_average_mpg AS (
SELECT trip_id, driver_id,average_mpg,
ROUND(AVG(average_mpg) OVER(PARTITION BY driver_id),2) AS Driver_average_mpg
FROM trips_backup
WHERE driver_id != '' AND trip_status = 'Completed'
)
SELECT trip_id, driver_id, average_mpg, Driver_average_mpg
FROM Driver_average_mpg
WHERE average_mpg < Driver_average_mpg
ORDER BY driver_id, average_mpg;

-- 5. Running distance total --
SELECT *
FROM trips_backup;

SELECT driver_id, trip_id, actual_distance_miles,
SUM(actual_distance_miles) 
OVER(PARTITION BY driver_id ORDER BY dispatch_date) AS Driver_running_total_miles
FROM trips_backup
WHERE driver_id != '' AND trip_status = 'Completed';

SELECT driver_id,
SUM(actual_distance_miles) AS Grand_total_miles, COUNT(*)
FROM trips_backup
WHERE driver_id != '' AND trip_status = 'Completed'
GROUP BY  driver_id
ORDER BY Grand_total_miles DESC;

-- FINDING DRIVERS WITH MORE THAN 10 YEARS EXPERIENCE --
SELECT driver_id, employment_status, years_experience
FROM drivers_backup
WHERE employment_status = 'Active'
GROUP BY driver_id, employment_status, years_experience
HAVING years_experience > 10;

SELECT *
FROM trips_backup;

SELECT MAX(dispatch_date), MIN(dispatch_date)
FROM trips_backup;

-- FINDING HOW MANY MILES IN TOTAL FOR EACH TRUCK AND TO KNOW WHEN TO REPLACE THE EQUIPMENT--
SELECT truck_id, SUM(actual_distance_miles) AS Total_miles_per_truck,
MAX(dispatch_date) AS first_trip, MIN(dispatch_date) AS last_trip,
DATEDIFF (MAX(dispatch_date), MIN(dispatch_date)) / 365.0 AS years_active,
ROUND((1500000 - SUM(actual_distance_miles)) / (SUM(actual_distance_miles) / (DATEDIFF(MAX(dispatch_date), MIN(dispatch_date)) / 365.0)), 1) AS est_years_to_1M_miles
FROM trips_backup
WHERE truck_id != '' AND truck_id IS NOT NULL
GROUP BY truck_id
ORDER BY Total_miles_per_truck DESC;

-- Corrected versions of the 15 recovered queries (MySQL).
-- The recovered originals are unchanged in queries.sql. Only the queries marked CORRECTED or PORTABILITY differ;
-- each correction is explained in its comment and tested in tests/test_queries.py.

-- Query 1: Average Used Car Price by Fuel Type
SELECT v.fuel_type, AVG(u.price) AS avg_price
FROM UsedCarListing u
JOIN Vehicle v ON u.vehicle_id = v.vehicle_id
GROUP BY v.fuel_type
ORDER BY avg_price DESC;

-- Query 2: Average Price by Brand and Model Year
SELECT m.name AS brand, u.model_year, ROUND(AVG(u.price), 2) AS avg_price
FROM UsedCarListing u
JOIN Vehicle v ON u.vehicle_id = v.vehicle_id
JOIN Manufacturer m ON v.manufacturer_id = m.manufacturer_id
GROUP BY m.name, u.model_year
ORDER BY m.name, u.model_year;

-- Query 3: Vehicles with Above-Average Fuel Economy
-- CORRECTED: join Manufacturer on the manufacturer_id foreign key instead of v.make = m.name, which silently
-- dropped vehicles whose make text differs from the manufacturer's name.
SELECT DISTINCT m.name AS manufacturer, v.model, v.year, v.combined_mpg_ft1 AS mpg
FROM Vehicle v
JOIN Manufacturer m ON v.manufacturer_id = m.manufacturer_id
WHERE v.combined_mpg_ft1 IS NOT NULL
  AND v.combined_mpg_ft1 > (
    SELECT AVG(combined_mpg_ft1)
    FROM Vehicle
    WHERE combined_mpg_ft1 IS NOT NULL
)
ORDER BY v.combined_mpg_ft1 DESC
LIMIT 20;

-- Query 4: Most Common Transmission Types by Fuel Type
SELECT v.fuel_type, u.transmission, COUNT(*) AS total
FROM UsedCarListing u
JOIN Vehicle v ON u.vehicle_id = v.vehicle_id
GROUP BY v.fuel_type, u.transmission
ORDER BY v.fuel_type, total DESC;

-- Query 5: Lowest Price per Mile Driven
-- CORRECTED: exclude zero-mileage listings (price / NULLIF(0) is NULL, and MySQL sorts NULL first, so a
-- zero-mileage car would rank as the "best" deal), and sort on the unrounded ratio so that ties in the rounded
-- column are ordered correctly.
SELECT
    u.listing_id,
    m.name AS brand,
    v.model,
    u.model_year,
    u.milage,
    u.price,
    ROUND(u.price / NULLIF(u.milage, 0), 2) AS price_per_mile
FROM UsedCarListing u
JOIN Vehicle v ON u.vehicle_id = v.vehicle_id
JOIN Manufacturer m ON v.manufacturer_id = m.manufacturer_id
WHERE u.milage > 0 AND u.price IS NOT NULL
ORDER BY u.price / u.milage ASC, u.listing_id
LIMIT 15;

-- Query 6: Vehicles with the Highest CO₂ Emissions
-- CORRECTED: join on the manufacturer_id foreign key, as in Query 3.
SELECT DISTINCT m.name AS brand, v.model, v.year, v.co2_emissions AS "Tailpipe CO₂ Emissions (grams per mile)"
FROM Vehicle v
JOIN Manufacturer m ON v.manufacturer_id = m.manufacturer_id
WHERE v.co2_emissions IS NOT NULL
ORDER BY v.co2_emissions DESC
LIMIT 10;

-- Query 7: Most Expensive Listings with Accidents
-- PORTABILITY: compare in lower case. MySQL's default collation ignores case, but most other databases do not.
SELECT u.listing_id, m.name AS brand, v.model, u.price, c.accident_history
FROM UsedCarListing u
JOIN Vehicle v ON u.vehicle_id = v.vehicle_id
JOIN Manufacturer m ON v.manufacturer_id = m.manufacturer_id
JOIN ListingCondition c ON u.condition_id = c.condition_id
WHERE LOWER(c.accident_history) LIKE '%accident%'
ORDER BY u.price DESC
LIMIT 10;

-- Query 8: Average Price by Transmission Type
SELECT u.transmission, ROUND(AVG(u.price), 2) AS avg_price
FROM UsedCarListing u
GROUP BY u.transmission
ORDER BY avg_price DESC;

-- Query 9: Price vs. Mileage Brackets
-- CORRECTED: a listing with unknown mileage fell through to ELSE and was counted as 'Over 100k'.
SELECT
  CASE
    WHEN u.milage IS NULL THEN 'Unknown'
    WHEN u.milage < 30000 THEN 'Under 30k'
    WHEN u.milage BETWEEN 30000 AND 60000 THEN '30k–60k'
    WHEN u.milage BETWEEN 60001 AND 100000 THEN '60k–100k'
    ELSE 'Over 100k'
  END AS mileage_bracket,
  ROUND(AVG(u.price), 2) AS avg_price
FROM UsedCarListing u
GROUP BY mileage_bracket
ORDER BY avg_price DESC;

-- Query 10: Number of Listings per Brand
SELECT m.name AS brand, COUNT(*) AS total_listings
FROM UsedCarListing u
JOIN Vehicle v ON u.vehicle_id = v.vehicle_id
JOIN Manufacturer m ON v.manufacturer_id = m.manufacturer_id
GROUP BY m.name
ORDER BY total_listings DESC;

-- Query 11: Low Mileage used listing
SELECT u.listing_id, m.name AS brand, v.model, u.milage, u.price
FROM UsedCarListing u
JOIN Vehicle v ON u.vehicle_id = v.vehicle_id
JOIN Manufacturer m ON v.manufacturer_id = m.manufacturer_id
WHERE u.milage <= 60000
ORDER BY u.price ASC
LIMIT 10;

-- Query 12: Average Price By Exterior Color
SELECT u.ext_color, ROUND(AVG(u.price), 2) AS avg_price
FROM UsedCarListing u
WHERE u.price IS NOT NULL AND u.ext_color IS NOT NULL
GROUP BY u.ext_color
ORDER BY avg_price DESC;

-- Query 13: Listings by Interior Color Preference
SELECT int_color, COUNT(*) AS total_listings
FROM UsedCarListing
GROUP BY int_color
ORDER BY total_listings DESC;

-- Query 14: Oldest Used Listings by Model Year
SELECT m.name AS brand, v.model, u.model_year, u.price
FROM UsedCarListing u
JOIN Vehicle v ON u.vehicle_id = v.vehicle_id
JOIN Manufacturer m ON v.manufacturer_id = m.manufacturer_id
ORDER BY u.model_year ASC
LIMIT 10;

-- Query 15: Listings With a Clean Title
SELECT c.clean_title, COUNT(*) AS total_listings
FROM UsedCarListing u
JOIN ListingCondition c ON u.condition_id = c.condition_id
GROUP BY c.clean_title;


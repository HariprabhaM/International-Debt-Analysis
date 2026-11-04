CREATE DATABASE international_debt_analysis;

USE international_debt_analysis;

SHOW TABLES;

DESCRIBE dim_indicator;

SELECT COUNT(*) AS indicator_count
FROM dim_indicator;

SELECT
    series_code,
    kpi,
    series_name
FROM dim_indicator;

SELECT COUNT(*)
FROM fact_debt;

SELECT COUNT(*) AS total_records
FROM fact_debt;

SELECT
    COUNT(*) AS total_rows,
    COUNT(value) AS rows_with_value,
    SUM(value IS NULL) AS rows_with_null
FROM fact_debt;

SELECT
    MIN(year) AS min_year,
    MAX(year) AS max_year,
    COUNT(DISTINCT country_code) AS countries,
    COUNT(DISTINCT series_code) AS indicators
FROM fact_debt;

TRUNCATE TABLE fact_debt;

SELECT COUNT(*) AS total_records
FROM fact_debt;

DROP TABLE IF EXISTS stg_fact_debt;

CREATE TABLE stg_fact_debt (
    country_code VARCHAR(10),
    series_code VARCHAR(50),
    year VARCHAR(10),
    value VARCHAR(100)
);

DESCRIBE stg_fact_debt;

SELECT COUNT(*) AS total_records
FROM stg_fact_debt;

SELECT
    COUNT(*) AS total_rows,
    SUM(value IS NULL) AS actual_null,
    SUM(TRIM(IFNULL(value, '')) = '') AS blank_values
FROM stg_fact_debt;

SELECT *
FROM stg_fact_debt
WHERE TRIM(IFNULL(value, '')) = ''
LIMIT 20;

TRUNCATE TABLE fact_debt;
SELECT COUNT(*)
FROM fact_debt;

# Insert staging data into fact_debt

INSERT INTO fact_debt
(
    country_code,
    series_code,
    year,
    value
)
SELECT
    TRIM(country_code),
    TRIM(series_code),
    CAST(year AS UNSIGNED),
    CASE
        WHEN TRIM(IFNULL(value, '')) = ''
            THEN NULL
        ELSE CAST(value AS DECIMAL(30,6))
    END
FROM stg_fact_debt;

SELECT
    COUNT(*) AS total_rows,
    COUNT(value) AS rows_with_value,
    SUM(value IS NULL) AS rows_with_null,
    COUNT(DISTINCT country_code) AS countries,
    COUNT(DISTINCT series_code) AS indicators,
    MIN(year) AS min_year,
    MAX(year) AS max_year
FROM fact_debt;

# Specifically verify the missing records

SELECT
    i.kpi,
    COUNT(*) AS missing_records
FROM fact_debt f
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE f.value IS NULL
GROUP BY i.kpi
ORDER BY missing_records DESC;

# Check 2025 and 2026
SELECT
    i.kpi,
    f.year,
    COUNT(*) AS total_records,
    COUNT(f.value) AS available_values,
    SUM(f.value IS NULL) AS missing_values
FROM fact_debt f
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE f.year IN (2024, 2025, 2026)
GROUP BY
    i.kpi,
    f.year
ORDER BY
    i.kpi,
    f.year;
    
# Reproduce Top 10 countries in SQL
SELECT
    c.country_name,
    c.country_code,
    c.region,
    c.income_group,
    ROUND(f.value / 1000000000, 2)
        AS external_debt_usd_billion
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE i.kpi = 'External Debt Stock'
  AND f.year = 2024
  AND f.value IS NOT NULL
ORDER BY f.value DESC
LIMIT 10;    

# Regional debt comparison
SELECT
    c.region,
    ROUND(
        SUM(f.value) / 1000000000,
        2
    ) AS external_debt_usd_billion
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE i.kpi = 'External Debt Stock'
  AND f.year = 2024
  AND f.value IS NOT NULL
GROUP BY c.region
ORDER BY external_debt_usd_billion DESC;

# Income-group comparison
SELECT
    c.income_group,
    ROUND(
        SUM(f.value) / 1000000000,
        2
    ) AS external_debt_usd_billion
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE i.kpi = 'External Debt Stock'
  AND f.year = 2024
  AND f.value IS NOT NULL
GROUP BY c.income_group
ORDER BY external_debt_usd_billion DESC;

# Historical external debt trend
SELECT
    f.year,
    ROUND(
        SUM(f.value) / 1000000000,
        2
    ) AS external_debt_usd_billion
FROM fact_debt f
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE i.kpi = 'External Debt Stock'
  AND f.year <= 2024
  AND f.value IS NOT NULL
GROUP BY f.year
ORDER BY f.year;

# Add the 2015 → 2024 growth analysis in SQL
SELECT
    c.country_name,
    c.region,
    c.income_group,

    ROUND(f2015.value / 1000000000, 2)
        AS debt_2015_usd_billion,

    ROUND(f2024.value / 1000000000, 2)
        AS debt_2024_usd_billion,

    ROUND(
        (f2024.value - f2015.value)
        / 1000000000,
        2
    ) AS absolute_change_usd_billion,

    ROUND(
        ((f2024.value - f2015.value)
        / f2015.value) * 100,
        2
    ) AS growth_percent

FROM fact_debt f2015

JOIN fact_debt f2024
    ON f2015.country_code = f2024.country_code
    AND f2015.series_code = f2024.series_code

JOIN dim_country c
    ON f2015.country_code = c.country_code

JOIN dim_indicator i
    ON f2015.series_code = i.series_code

WHERE i.kpi = 'External Debt Stock'
  AND f2015.year = 2015
  AND f2024.year = 2024
  AND f2015.value > 0
  AND f2024.value IS NOT NULL

ORDER BY absolute_change_usd_billion DESC
LIMIT 10;

# Create the Power BI view
CREATE OR REPLACE VIEW vw_debt_analysis AS

SELECT
    c.country_code,
    c.country_name,
    c.region,
    c.income_group,
    c.lending_category,

    i.series_code,
    i.series_name,
    i.kpi,
    i.topic,
    i.periodicity,
    i.aggregation_method,

    f.year,
    f.value,

    f.value / 1000000000
        AS value_usd_billion

FROM fact_debt f

JOIN dim_country c
    ON f.country_code = c.country_code

JOIN dim_indicator i
    ON f.series_code = i.series_code;
    
# Validate
SELECT COUNT(*)
FROM vw_debt_analysis;    

SELECT *
FROM vw_debt_analysis
LIMIT 20;

# Identify which country/countries create that US$36.55 billion:
SELECT
    c.country_code,
    c.country_name,
    c.region,
    c.income_group,
    ROUND(f.value / 1000000000, 2)
        AS external_debt_usd_billion
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE i.kpi = 'External Debt Stock'
  AND f.year = 2024
  AND f.value IS NOT NULL
  AND (
        c.income_group IS NULL
        OR TRIM(c.income_group) = ''
      )
ORDER BY f.value DESC;

# updating as Unclassified for the blank coutny field to be on safer side - preserve the source data and label the blank as Unclassified only in the analytical SQL view.
CREATE OR REPLACE VIEW vw_debt_analysis AS
SELECT
    c.country_code,
    c.country_name,
    c.region,

    COALESCE(
        NULLIF(TRIM(c.income_group), ''),
        'Unclassified'
    ) AS income_group,

    c.lending_category,

    i.series_code,
    i.series_name,
    i.kpi,
    i.topic,
    i.periodicity,
    i.aggregation_method,

    f.year,
    f.value,

    f.value / 1000000000 AS value_usd_billion

FROM fact_debt f

JOIN dim_country c
    ON f.country_code = c.country_code

JOIN dim_indicator i
    ON f.series_code = i.series_code;
    
# Confirm Ethiopia

SELECT
    country_code,
    country_name,
    region,
    income_group
FROM vw_debt_analysis
WHERE country_code = 'ETH'
LIMIT 5;    

# To check 
SELECT
    income_group,
    ROUND(
        SUM(value) / 1000000000,
        2
    ) AS external_debt_usd_billion
FROM vw_debt_analysis
WHERE kpi = 'External Debt Stock'
  AND year = 2024
  AND value IS NOT NULL
GROUP BY income_group
ORDER BY external_debt_usd_billion DESC;

# Final validation of the view
SELECT
    COUNT(*) AS total_rows,
    COUNT(value) AS available_values,
    SUM(value IS NULL) AS missing_values,
    COUNT(DISTINCT country_code) AS countries,
    COUNT(DISTINCT series_code) AS indicators,
    MIN(year) AS min_year,
    MAX(year) AS max_year
FROM vw_debt_analysis;

# Dropping stg_fact_debt as the issue resolved
DROP TABLE stg_fact_debt;

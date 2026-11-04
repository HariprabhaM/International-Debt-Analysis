-- ==================================================
-- INTERNATIONAL DEBT ANALYSIS
-- BASIC SQL QUESTIONS
-- ==================================================

# Q1. Retrieve all distinct country names
SELECT DISTINCT country_name
FROM dim_country
ORDER BY country_name;

# Q2. Count the total number of countries
SELECT COUNT(DISTINCT country_code) AS total_countries
FROM dim_country;

# Q3. Find total number of indicators
SELECT COUNT(DISTINCT series_code) AS total_indicators
FROM dim_indicator;

# Q4. Display first 10 records
SELECT *
FROM vw_debt_analysis
ORDER BY country_code, series_code, year
LIMIT 10;

# Q5. Calculate total global debt
SELECT 
    ROUND(SUM(value) / 1000000000, 2) AS total_value_usd_billion
FROM fact_debt
WHERE value IS NOT NULL;

-- External Debt Stock 2024
SELECT
    ROUND(SUM(value) / 1000000000, 2) AS global_external_debt_2024_usd_billion
FROM vw_debt_analysis
WHERE kpi = 'External Debt Stock'
  AND year = 2024
  AND value IS NOT NULL;
  
  # Q6. List unique indicator names
  SELECT DISTINCT
    series_code,
    series_name,
    kpi
FROM dim_indicator
ORDER BY kpi;

# Q7. Number of records for each country
SELECT
    c.country_name,
    COUNT(*) AS record_count
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
GROUP BY
    c.country_code,
    c.country_name
ORDER BY record_count DESC,
         c.country_name;
         
# Q8. Records where debt exceeds US$1 billion
SELECT
    country_name,
    kpi,
    year,
    ROUND(value / 1000000000, 2) AS value_usd_billion
FROM vw_debt_analysis
WHERE value > 1000000000
ORDER BY value DESC;        

# Q9. Minimum, maximum and average debt values
SELECT
    ROUND(MIN(value) / 1000000000, 2) AS min_usd_billion,
    ROUND(MAX(value) / 1000000000, 2) AS max_usd_billion,
    ROUND(AVG(value) / 1000000000, 2) AS avg_usd_billion
FROM fact_debt
WHERE value IS NOT NULL; 

# Q10. Count total records
SELECT COUNT(*) AS total_records
FROM fact_debt;

-- INTERMEDIATE SQL QUESTIONS

# Q11. Total debt/value for each country
SELECT
    c.country_name,
    ROUND(SUM(f.value) / 1000000000, 2) AS total_value_usd_billion
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
WHERE f.value IS NOT NULL
GROUP BY
    c.country_code,
    c.country_name
ORDER BY total_value_usd_billion DESC;

# Q12. Top 10 countries with highest total debt/value
SELECT
    c.country_name,
    ROUND(SUM(f.value) / 1000000000, 2) AS total_value_usd_billion
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
WHERE f.value IS NOT NULL
GROUP BY
    c.country_code,
    c.country_name
ORDER BY total_value_usd_billion DESC
LIMIT 10;

# Q13. Average debt/value per country
SELECT
    c.country_name,
    ROUND(AVG(f.value) / 1000000000, 2) AS average_value_usd_billion
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
WHERE f.value IS NOT NULL
GROUP BY
    c.country_code,
    c.country_name
ORDER BY average_value_usd_billion DESC;

# Q14. Total value for each indicator
SELECT
    i.kpi,
    i.series_name,
    ROUND(SUM(f.value) / 1000000000, 2) AS total_value_usd_billion
FROM fact_debt f
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE f.value IS NOT NULL
GROUP BY
    i.series_code,
    i.kpi,
    i.series_name
ORDER BY total_value_usd_billion DESC;

# Q15. Indicator contributing highest total value
SELECT
    i.kpi,
    i.series_name,
    ROUND(SUM(f.value) / 1000000000, 2) AS total_value_usd_billion
FROM fact_debt f
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE f.value IS NOT NULL
GROUP BY
    i.series_code,
    i.kpi,
    i.series_name
ORDER BY total_value_usd_billion DESC
LIMIT 1;

# Q16. Country with lowest total value
SELECT
    c.country_name,
    ROUND(SUM(f.value) / 1000000000, 2) AS total_value_usd_billion
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
WHERE f.value IS NOT NULL
GROUP BY
    c.country_code,
    c.country_name
ORDER BY total_value_usd_billion ASC
LIMIT 1;

# Q17. Total debt/value for each country-indicator combination
SELECT
    c.country_name,
    i.kpi,
    ROUND(SUM(f.value) / 1000000000, 2) AS total_value_usd_billion
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE f.value IS NOT NULL
GROUP BY
    c.country_code,
    c.country_name,
    i.series_code,
    i.kpi
ORDER BY
    c.country_name,
    total_value_usd_billion DESC;
    
# Q18. Number of indicators available for each country
SELECT
c.country_name,
COUNT(DISTINCT f.series_code) AS indicator_count
FROM fact_debt f
JOIN dim_country c
ON f.country_code = c.country_code
WHERE f.value IS NOT NULL
GROUP BY
c.country_code,
c.country_name
ORDER BY indicator_count DESC,
c.country_name;    

# Q19. Countries whose total is above the average country total
WITH country_totals AS (
    SELECT
        country_code,
        SUM(value) AS total_value
    FROM fact_debt
    WHERE value IS NOT NULL
    GROUP BY country_code
)
SELECT
    c.country_name,
    ROUND(ct.total_value / 1000000000, 2)
        AS total_value_usd_billion
FROM country_totals ct
JOIN dim_country c
    ON ct.country_code = c.country_code
WHERE ct.total_value >
      (SELECT AVG(total_value)
       FROM country_totals)
ORDER BY ct.total_value DESC;

# Q20. Rank countries from highest to lowest
WITH country_totals AS (
    SELECT
        country_code,
        SUM(value) AS total_value
    FROM fact_debt
    WHERE value IS NOT NULL
    GROUP BY country_code
)
SELECT
    c.country_name,
    ROUND(ct.total_value / 1000000000, 2)
        AS total_value_usd_billion,
    DENSE_RANK() OVER (
        ORDER BY ct.total_value DESC
    ) AS debt_rank
FROM country_totals ct
JOIN dim_country c
    ON ct.country_code = c.country_code
ORDER BY debt_rank;

-- ADVANCED SQL QUESTIONS

# Q21. Top 5 indicators contributing the most
SELECT
    i.kpi,
    i.series_name,
    ROUND(SUM(f.value) / 1000000000, 2)
        AS total_value_usd_billion
FROM fact_debt f
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE f.value IS NOT NULL
GROUP BY
    i.series_code,
    i.kpi,
    i.series_name
ORDER BY total_value_usd_billion DESC
LIMIT 5;

# Q22. Percentage contribution of each country
WITH country_totals AS (
    SELECT
        country_code,
        SUM(value) AS country_total
    FROM fact_debt
    WHERE value IS NOT NULL
    GROUP BY country_code
),
global_total AS (
    SELECT SUM(value) AS total_value
    FROM fact_debt
    WHERE value IS NOT NULL
)
SELECT
    c.country_name,
    ROUND(ct.country_total / 1000000000, 2)
        AS country_total_usd_billion,
    ROUND(
        ct.country_total / gt.total_value * 100,
        2
    ) AS contribution_percentage
FROM country_totals ct
CROSS JOIN global_total gt
JOIN dim_country c
    ON ct.country_code = c.country_code
ORDER BY contribution_percentage DESC;

# Q23. Top 3 countries for each indicator
WITH country_indicator_totals AS (
    SELECT
        f.series_code,
        f.country_code,
        SUM(f.value) AS total_value
    FROM fact_debt f
    WHERE f.value IS NOT NULL
    GROUP BY
        f.series_code,
        f.country_code
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY series_code
            ORDER BY total_value DESC
        ) AS indicator_rank
    FROM country_indicator_totals
)
SELECT
    i.kpi,
    c.country_name,
    ROUND(r.total_value / 1000000000, 2)
        AS total_value_usd_billion,
    r.indicator_rank
FROM ranked r
JOIN dim_country c
    ON r.country_code = c.country_code
JOIN dim_indicator i
    ON r.series_code = i.series_code
WHERE indicator_rank <= 3
ORDER BY
    i.kpi,
    indicator_rank;
    
# Q24. Difference between maximum and minimum value per country
SELECT
    c.country_name,
    ROUND(MAX(f.value) / 1000000000, 2)
        AS maximum_usd_billion,
    ROUND(MIN(f.value) / 1000000000, 2)
        AS minimum_usd_billion,
    ROUND(
        (MAX(f.value) - MIN(f.value))
        / 1000000000,
        2
    ) AS difference_usd_billion
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
WHERE f.value IS NOT NULL
GROUP BY
    c.country_code,
    c.country_name
ORDER BY difference_usd_billion DESC;    

# Q25. Create a view for Top 10 countries
CREATE OR REPLACE VIEW vw_top_10_countries AS
SELECT
    c.country_code,
    c.country_name,
    SUM(f.value) AS total_value
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
WHERE f.value IS NOT NULL
GROUP BY
    c.country_code,
    c.country_name
ORDER BY total_value DESC
LIMIT 10;

# TEST RESULT
SELECT
    country_name,
    ROUND(total_value / 1000000000, 2)
        AS total_value_usd_billion
FROM vw_top_10_countries;

# Q26. Categorize countries as High / Medium / Low
WITH country_totals AS (
    SELECT
        country_code,
        SUM(value) AS country_total
    FROM fact_debt
    WHERE value IS NOT NULL
    GROUP BY country_code
),
global_total AS (
    SELECT SUM(value) AS total_value
    FROM fact_debt
    WHERE value IS NOT NULL
)
SELECT
    c.country_name,
    ROUND(ct.country_total / 1000000000, 2)
        AS total_value_usd_billion,
    ROUND(
        ct.country_total / gt.total_value * 100,
        2
    ) AS contribution_percentage,
    CASE
        WHEN ct.country_total / gt.total_value >= 0.05
            THEN 'High Debt'
        WHEN ct.country_total / gt.total_value >= 0.01
            THEN 'Medium Debt'
        ELSE 'Low Debt'
    END AS debt_category
FROM country_totals ct
CROSS JOIN global_total gt
JOIN dim_country c
    ON ct.country_code = c.country_code
ORDER BY ct.country_total DESC;

# Q27. Cumulative debt/value per country using window functions
WITH annual_country_totals AS (
    SELECT
        country_code,
        year,
        SUM(value) AS annual_value
    FROM fact_debt
    WHERE value IS NOT NULL
    GROUP BY
        country_code,
        year
)
SELECT
    c.country_name,
    a.year,
    ROUND(a.annual_value / 1000000000, 2)
        AS annual_value_usd_billion,
    ROUND(
        SUM(a.annual_value) OVER (
            PARTITION BY a.country_code
            ORDER BY a.year
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) / 1000000000,
        2
    ) AS cumulative_value_usd_billion
FROM annual_country_totals a
JOIN dim_country c
    ON a.country_code = c.country_code
ORDER BY
    c.country_name,
    a.year;
    
# Q28. Indicators with average above overall average
SELECT
    i.kpi,
    i.series_name,
    ROUND(AVG(f.value) / 1000000000, 2)
        AS avg_value_usd_billion
FROM fact_debt f
JOIN dim_indicator i
    ON f.series_code = i.series_code
WHERE f.value IS NOT NULL
GROUP BY
    i.series_code,
    i.kpi,
    i.series_name
HAVING AVG(f.value) >
       (
           SELECT AVG(value)
           FROM fact_debt
           WHERE value IS NOT NULL
       )
ORDER BY avg_value_usd_billion DESC;    

# Q29. Countries contributing more than 5%
WITH country_totals AS (
    SELECT
        country_code,
        SUM(value) AS country_total
    FROM fact_debt
    WHERE value IS NOT NULL
    GROUP BY country_code
),
global_total AS (
    SELECT SUM(value) AS total_value
    FROM fact_debt
    WHERE value IS NOT NULL
)
SELECT
    c.country_name,
    ROUND(ct.country_total / 1000000000, 2)
        AS total_value_usd_billion,
    ROUND(
        ct.country_total / gt.total_value * 100,
        2
    ) AS contribution_percentage
FROM country_totals ct
CROSS JOIN global_total gt
JOIN dim_country c
    ON ct.country_code = c.country_code
WHERE ct.country_total / gt.total_value > 0.05
ORDER BY contribution_percentage DESC;

# Q30. Most dominant indicator for each country
WITH country_indicator_totals AS (
    SELECT
        country_code,
        series_code,
        SUM(value) AS total_value
    FROM fact_debt
    WHERE value IS NOT NULL
    GROUP BY
        country_code,
        series_code
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY country_code
            ORDER BY total_value DESC
        ) AS indicator_rank
    FROM country_indicator_totals
)
SELECT
    c.country_name,
    i.kpi AS dominant_indicator,
    i.series_name,
    ROUND(r.total_value / 1000000000, 2)
        AS total_value_usd_billion
FROM ranked r
JOIN dim_country c
    ON r.country_code = c.country_code
JOIN dim_indicator i
    ON r.series_code = i.series_code
WHERE r.indicator_rank = 1
ORDER BY r.total_value DESC;
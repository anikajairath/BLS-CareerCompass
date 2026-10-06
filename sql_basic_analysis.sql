CREATE DATABASE CareerCompass_DB;

USE CareerCompass_DB;

-- Basic count check
SELECT 'BOS' AS dataset, COUNT(*) FROM bos_employment
UNION ALL
SELECT 'Employment Projections', COUNT(*) FROM employment_projections
UNION ALL
SELECT 'MSA', COUNT(*) FROM msa_employment
UNION ALL
SELECT 'National', COUNT(*) FROM national_employment
UNION ALL
SELECT 'Openings', COUNT(*) FROM openings
UNION ALL
SELECT 'State', COUNT(*) FROM state_employment;

-- Top 10 highest annually paid occupations nationally
SELECT OCC_CODE, OCC_TITLE, TOT_EMP, H_MEDIAN, A_MEDIAN FROM national_employment
ORDER BY A_MEDIAN DESC, H_MEDIAN DESC
LIMIT 10;

-- Top 10 lowest annually paid occupations nationally
SELECT OCC_CODE, OCC_TITLE, TOT_EMP, H_MEDIAN, A_MEDIAN FROM national_employment
WHERE A_MEDIAN != 0
ORDER BY A_MEDIAN, H_MEDIAN
LIMIT 10;

-- Top 10 occupations with the highest employee concentration nationally
SELECT OCC_CODE, OCC_TITLE, TOT_EMP, H_MEDIAN, A_MEDIAN FROM national_employment
ORDER BY TOT_EMP DESC
LIMIT 10;

-- Top 10 occupations with the highest annual wages and high employment nationally
SELECT OCC_CODE, OCC_TITLE, TOT_EMP, A_MEDIAN, H_MEDIAN FROM national_employment
WHERE TOT_EMP > (SELECT AVG(TOT_EMP) FROM national_employment) AND 
A_MEDIAN > (SELECT AVG(A_MEDIAN) FROM national_employment)
ORDER BY A_MEDIAN DESC, TOT_EMP DESC
LIMIT 10;

-- Top 10 occupations with annual high wages but low employment
SELECT OCC_CODE, OCC_TITLE, TOT_EMP, A_MEDIAN, H_MEDIAN FROM national_employment
WHERE TOT_EMP < (SELECT AVG(TOT_EMP) FROM national_employment) AND 
A_MEDIAN > (SELECT AVG(A_MEDIAN) FROM national_employment)
ORDER BY A_MEDIAN DESC, TOT_EMP
LIMIT 10;

-- Average annual median wage nationally
SELECT AVG(A_MEDIAN) AS average_median_annual_wage FROM national_employment

-- Percentage of occupations that pay higher than the average wage
SELECT 
	COUNT(CASE WHEN A_MEDIAN > (SELECT AVG(A_MEDIAN) FROM national_employment) THEN 1 END) AS higher_than_avg_wages,
    COUNT(CASE WHEN A_MEDIAN != 0 THEN 1 END) AS total_count_wages,
    ROUND(COUNT(CASE WHEN A_MEDIAN > (SELECT AVG(A_MEDIAN) FROM national_employment) THEN 1 END)/COUNT(A_MEDIAN) * 100, 2) AS percentage_of_occupations_paying_higher_than_avg
FROM national_employment

-- Top 10 occupations with largest employment estimates but relatively low employment uncertainty
SELECT OCC_CODE, OCC_TITLE, TOT_EMP, EMP_PRSE FROM national_employment
WHERE TOT_EMP > 0 AND EMP_PRSE IS NOT NULL
ORDER BY TOT_EMP DESC
LIMIT 10;

-- Top 10 states with the highest employees
SELECT AREA_TITLE AS State, SUM(TOT_EMP) AS Total_employment FROM state_employment
GROUP BY AREA_TITLE
ORDER BY SUM(TOT_EMP) DESC
LIMIT 10;

-- Top 10 states with the highest avg annual wage
SELECT AREA_TITLE AS State, ROUND(AVG(A_MEDIAN), 2) AS Avg_wage FROM state_employment
GROUP BY AREA_TITLE
ORDER BY AVG(A_MEDIAN) DESC
LIMIT 10;

-- Avg annual wage for each state
SELECT AREA_TITLE AS State, ROUND(AVG(A_MEDIAN), 2) AS Avg_wage FROM state_employment GROUP BY AREA_TITLE;

-- Highest paid occupation and it's salary per state
WITH States_Ranked AS (SELECT AREA_TITLE AS State, OCC_TITLE AS Highest_paid_occupation, 
A_MEDIAN AS Wage, RANK() OVER (PARTITION BY AREA_TITLE ORDER BY A_MEDIAN DESC)
AS rn FROM state_employment)
SELECT State, Highest_paid_occupation, Wage FROM States_Ranked WHERE rn = 1;

-- Occupations with the highest employees per state
WITH States_Ranked AS (SELECT AREA_TITLE AS State, OCC_TITLE AS Occupation_with_the_highest_employees, 
TOT_EMP AS Total_employees, RANK() OVER (PARTITION BY AREA_TITLE ORDER BY TOT_EMP DESC)
AS rn FROM state_employment)
SELECT State, Occupation_with_the_highest_employees, Total_employees FROM States_Ranked WHERE rn = 1;

-- Top 10 states with the highest employees and salaries for Operation Analysts
SELECT OCC_CODE, OCC_TITLE AS Occupation, AREA_TITLE AS State, TOT_EMP AS Total_employees,
A_MEDIAN AS Avg_annual_salary
FROM state_employment WHERE OCC_TITLE = 'Operations Research Analysts'
ORDER BY TOT_EMP DESC, A_MEDIAN DESC
LIMIT 10;

-- Top 10 states with the highest average employment concentration
SELECT AREA_TITLE AS State, ROUND(AVG(JOBS_1000), 2) AS Avg_jobs_per_1000
FROM state_employment
WHERE JOBS_1000 != 0 AND AREA_TITLE NOT IN ('Virgin Islands', 'Guam', 'District of Columbia', 'Puerto Rico', 'Hawaii', 'Alaska')
GROUP BY AREA_TITLE
ORDER BY Avg_jobs_per_1000 DESC
LIMIT 10;

-- Top 10 states where Operations Research Analysts are most concentrated
SELECT AREA_TITLE AS State, OCC_TITLE AS Occupation, TOT_EMP AS Total_employment,
JOBS_1000, LOC_QUOTIENT FROM state_employment
WHERE OCC_TITLE = 'Operations Research Analysts' AND LOC_QUOTIENT != 0 AND AREA_TITLE NOT IN ('Virgin Islands', 'Guam', 'District of Columbia', 'Puerto Rico', 'Hawaii', 'Alaska')
ORDER BY LOC_QUOTIENT DESC
LIMIT 10;

-- Most concentrated occupation in each state
WITH Ranked_Occupations AS (SELECT AREA_TITLE AS State, OCC_CODE, OCC_TITLE AS Occupation,
TOT_EMP, JOBS_1000, LOC_QUOTIENT, RANK() OVER (PARTITION BY AREA_TITLE ORDER BY LOC_QUOTIENT DESC) AS rn
FROM state_employment WHERE LOC_QUOTIENT != 0)
SELECT State, OCC_CODE, Occupation, TOT_EMP, JOBS_1000, LOC_QUOTIENT
FROM Ranked_Occupations
WHERE rn = 1;

-- Highly concentrated and well-paid occupations by state
SELECT AREA_TITLE AS State, OCC_TITLE AS Occupation, TOT_EMP, A_MEDIAN, JOBS_1000, LOC_QUOTIENT
FROM state_employment WHERE LOC_QUOTIENT != 0 AND A_MEDIAN > (SELECT AVG(A_MEDIAN) FROM state_employment
WHERE A_MEDIAN != 0)
ORDER BY LOC_QUOTIENT DESC, A_MEDIAN DESC
LIMIT 20;

-- Which states pay more than the national median wage for Operation Research Analysts
SELECT s.AREA_TITLE AS State, s.OCC_TITLE AS Occupation, s.A_MEDIAN, n.A_MEDIAN, 
(s.A_MEDIAN - n.A_MEDIAN) AS Difference
FROM state_employment s 
JOIN national_employment n ON s.OCC_CODE = n.OCC_CODE
WHERE s.A_MEDIAN > n.A_MEDIAN
AND s.A_MEDIAN != 0
AND n.A_MEDIAN != 0
AND s.OCC_TITLE = 'Operations Research Analysts'
ORDER BY (s.A_MEDIAN - n.A_MEDIAN) DESC;

-- Top 10 States with the Most Occupations Paying Above the National Median
WITH States_paying_more_than_national AS (SELECT s.AREA_TITLE AS State, s.OCC_TITLE AS Occupation, 
s.A_MEDIAN AS State_median, n.A_MEDIAN AS national_median, 
(s.A_MEDIAN - n.A_MEDIAN) AS Difference
FROM state_employment s 
JOIN national_employment n ON s.OCC_CODE = n.OCC_CODE
WHERE s.A_MEDIAN > n.A_MEDIAN
AND s.A_MEDIAN != 0
AND n.A_MEDIAN != 0),

Count_of_occupations AS (SELECT State, COUNT(*) AS ROWS_COUNT FROM States_paying_more_than_national GROUP BY State),
Ranked AS (SELECT *, RANK() OVER (ORDER BY ROWS_COUNT DESC) AS rn FROM Count_of_occupations)

SELECT * FROM Ranked WHERE rn < 10;

-- Top 20 highest percentage of national employment for an occupation is in each state
SELECT s.AREA_TITLE AS State, s.OCC_TITLE AS Occupation, s.TOT_EMP AS State_employment, 
n.TOT_EMP AS National_employment,
ROUND(s.TOT_EMP/n.TOT_EMP * 100, 2) AS Percent_of_national_emp
FROM state_employment s 
JOIN national_employment n ON s.OCC_CODE = n.OCC_CODE
WHERE s.TOT_EMP != 0 AND n.TOT_EMP != 0
ORDER BY Percent_of_national_emp DESC
LIMIT 20;

-- Top 20 occupations has both above-national wages and high concentration
SELECT s.AREA_TITLE AS State, s.OCC_TITLE AS Occupation, s.A_MEDIAN AS State_median_wage,
n.A_MEDIAN AS National_median_wage, ROUND(s.A_MEDIAN - n.A_MEDIAN, 2) AS Wage_difference,
s.LOC_QUOTIENT FROM state_employment s 
JOIN national_employment n ON s.OCC_CODE = n.OCC_CODE
WHERE s.A_MEDIAN > n.A_MEDIAN AND s.LOC_QUOTIENT > 1 AND s.A_MEDIAN != 0 AND n.A_MEDIAN != 0
ORDER BY s.A_MEDIAN DESC
LIMIT 20;

-- Top 10 metropolitan areas that have the highest wages for an occupation
SELECT AREA_TITLE AS Metro, PRIM_STATE AS State, OCC_TITLE AS Occupation,
TOT_EMP AS Employment, A_MEDIAN AS Median_annual_wage
FROM msa_employment
WHERE A_MEDIAN != 0
AND TOT_EMP > 0
ORDER BY A_MEDIAN DESC
LIMIT 10;

-- Top 10 metropolitan areas with the highest employment
SELECT AREA_TITLE AS Metro, PRIM_STATE AS State, OCC_TITLE AS Occupation,
TOT_EMP AS Employment, A_MEDIAN AS Median_annual_wage
FROM msa_employment
WHERE TOT_EMP > 0
ORDER BY TOT_EMP DESC
LIMIT 10;

-- Top 10 metropolitan areas with the highest occupational concentration
SELECT AREA_TITLE AS Metro, PRIM_STATE AS State, OCC_TITLE AS Occupation,
TOT_EMP AS Employment, JOBS_1000, LOC_QUOTIENT
FROM msa_employment
WHERE LOC_QUOTIENT != 0
ORDER BY LOC_QUOTIENT DESC
LIMIT 10;

-- Top 10 occupations projected to grow the fastest
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE, `Employment, 2025` AS Employment_2025,
`Employment, 2035` AS Employment_2035, `Employment change, percent, 2025–35` AS Growth_percent
FROM employment_projections
WHERE `Employment change, percent, 2025–35` != 0
ORDER BY `Employment change, percent, 2025–35` DESC
LIMIT 10;

-- Top 10 fastest declining occupations
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE, `Employment, 2025` AS Employment_2025,
`Employment, 2035` AS Employment_2035, `Employment change, percent, 2025–35` AS Growth_percent
FROM employment_projections
WHERE `Employment change, percent, 2025–35` != 0
ORDER BY `Employment change, percent, 2025–35`
LIMIT 10;

-- Top 10 occupations with the largest employment distribution in 2025
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE, `Employment, 2025` AS Employment_2025,
`Employment, 2035` AS Employment_2035, `Employment distribution, percent, 2025` AS Distribution_2025
FROM employment_projections
WHERE `Employment distribution, percent, 2025` != 0
ORDER BY `Employment distribution, percent, 2025` DESC
LIMIT 10;

-- Top 10 occupations with the largest change in employment distribution
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE,
`Employment distribution, percent, 2025` AS Distribution_2025,
`Employment distribution, percent, 2035` AS Distribution_2035,
ROUND(`Employment distribution, percent, 2035` - `Employment distribution, percent, 2025`, 2) 
AS Distribution_change
FROM employment_projections
ORDER BY Distribution_change DESC
LIMIT 10;

-- Top 10 occupations projected to add the most jobs
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE,
`Employment, 2025` AS Employment_2025, `Employment, 2035` AS Employment_2035,
`Employment change, numeric, 2025–35` AS Jobs_change
FROM employment_projections
WHERE `Employment change, numeric, 2025–35` != 0
ORDER BY Jobs_change DESC
LIMIT 10;

-- Top 10 occupations by annual average openings
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE,
`Occupational openings, 2025–35 annual average` AS Annual_openings,
`Median annual wage, dollars, 2025` AS Median_wage
FROM employment_projections
WHERE `Occupational openings, 2025–35 annual average` != 0
ORDER BY Annual_openings DESC
LIMIT 10;

-- Top 10 occupation with the lowest annual openings
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE,
`Occupational openings, 2025–35 annual average` AS Annual_openings,
`Median annual wage, dollars, 2025` AS Median_wage
FROM employment_projections
WHERE `Occupational openings, 2025–35 annual average` != 0
ORDER BY Annual_openings
LIMIT 10;

-- Projected employment growth by typical education level
SELECT `Typical education needed for entry` AS Education_level,
COUNT(*) AS Occupation_count,
ROUND(AVG(`Employment change, percent, 2025–35`), 2) AS Avg_growth_percent,
ROUND(AVG(`Occupational openings, 2025–35 annual average`), 2) AS Avg_annual_openings,
ROUND(AVG(`Median annual wage, dollars, 2025`), 2) AS Avg_median_wage
FROM employment_projections
GROUP BY `Typical education needed for entry`
ORDER BY Avg_growth_percent DESC, Occupation_count DESC;

-- Projected employment growth by work experience
SELECT `Work experience in a related occupation` AS Work_experience,
COUNT(*) AS Occupation_count,
ROUND(AVG(`Employment change, percent, 2025–35`), 2) AS Avg_growth_percent,
ROUND(AVG(`Occupational openings, 2025–35 annual average`), 2) AS Avg_annual_openings,
ROUND(AVG(`Median annual wage, dollars, 2025`), 2) AS Avg_median_wage
FROM employment_projections
WHERE `Work experience in a related occupation` IS NOT NULL
GROUP BY `Work experience in a related occupation`
ORDER BY Avg_growth_percent DESC, Occupation_count DESC;

-- 2025-2035 Total employment projected growth
SELECT ROUND(SUM(`Employment, 2025`), 2) AS Total_employment_2025,
ROUND(SUM(`Employment, 2035`),2) AS Total_employment_2026,
ROUND(SUM(`Employment change, numeric, 2025–35`),2) AS Total_jobs_change,
ROUND(SUM(`Employment change, numeric, 2025–35`)/SUM(`Employment, 2025`) * 100, 2) AS Overall_growth_percent
FROM employment_projections

-- Openings by education level
SELECT `Typical education needed for entry` AS Education_level,
COUNT(*) AS Occupation_count,
ROUND(AVG(`Employment change, percent, 2025–35`), 2) AS Avg_growth_percent,
ROUND(SUM(`Occupational openings, 2025–35 annual average`), 2) AS Total_annual_openings,
ROUND(AVG(`Occupational openings, 2025–35 annual average`), 2) AS Avg_annual_openings,
ROUND(AVG(`Median annual wage, dollars, 2025`), 2) AS Avg_median_wage
FROM employment_projections
WHERE `Typical education needed for entry` IS NOT NULL
GROUP BY `Typical education needed for entry`
ORDER BY Avg_annual_openings DESC;

-- Openings by work experience
SELECT `Work experience in a related occupation` AS Work_experience,
COUNT(*) AS Occupation_count,
ROUND(AVG(`Employment change, percent, 2025–35`), 2) AS Avg_growth_percent,
ROUND(SUM(`Occupational openings, 2025–35 annual average`), 2) AS Total_annual_openings,
ROUND(AVG(`Occupational openings, 2025–35 annual average`), 2) AS Avg_annual_openings,
ROUND(AVG(`Median annual wage, dollars, 2025`), 2) AS Avg_median_wage
FROM employment_projections
WHERE `Work experience in a related occupation` IS NOT NULL
GROUP BY `Work experience in a related occupation`
ORDER BY Avg_annual_openings DESC;

-- Openings by on the job training required
SELECT `ON_JOB_TRAINING` AS Training_required,
COUNT(*) AS Occupation_count,
ROUND(AVG(`Employment change, percent, 2025–35`), 2) AS Avg_growth_percent,
ROUND(SUM(`Occupational openings, 2025–35 annual average`), 2) AS Total_annual_openings,
ROUND(AVG(`Occupational openings, 2025–35 annual average`), 2) AS Avg_annual_openings,
ROUND(AVG(`Median annual wage, dollars, 2025`), 2) AS Avg_median_wage
FROM employment_projections
WHERE `ON_JOB_TRAINING` IS NOT NULL
GROUP BY `ON_JOB_TRAINING`
ORDER BY Avg_annual_openings DESC;

-- Top 10 occupations with the highest projected openings
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE,
`Occupational openings, 2025–35 annual average` AS Annual_openings
FROM openings
ORDER BY Annual_openings DESC
LIMIT 10;

-- Top 10 occupations with the lowest projected openings
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE,
`Occupational openings, 2025–35 annual average` AS Annual_openings
FROM openings
ORDER BY Annual_openings
LIMIT 10;

-- Sources of projected job openings
SELECT ROUND(AVG(`Labor force exits, 2025–35 annual average`), 2) AS Avg_labor_force_exits,
ROUND(AVG(`Occupational transfers, 2025–35 annual average`), 2) AS Avg_occupational_transfers,
ROUND(AVG(`Total occupational separations, 2025–35 annual average`), 2) AS Avg_total_separations,
ROUND(AVG(`Occupational openings, 2025–35 annual average`), 2) AS Avg_total_openings
FROM openings;

-- Top occupations with the highest projected growth and openings
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE,
`Employment change, percent, 2025–35` AS Growth_percent,
`Occupational openings, 2025–35 annual average` AS Annual_openings,
`Median annual wage, dollars, 2025` AS Median_wage
FROM employment_projections
WHERE `Employment change, percent, 2025–35` >
(SELECT AVG(`Employment change, percent, 2025–35`) FROM employment_projections)
AND `Occupational openings, 2025–35 annual average` > 
(SELECT AVG(`Occupational openings, 2025–35 annual average`)
FROM employment_projections
WHERE `Occupational openings, 2025–35 annual average` > 0)
ORDER BY Growth_percent DESC
LIMIT 20;

-- Top occupations with the highest projected wages and openings
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE,
`Median annual wage, dollars, 2025` AS Median_wage,
`Occupational openings, 2025–35 annual average` AS Annual_openings,
`Employment change, percent, 2025–35` AS Growth_percent
FROM employment_projections
WHERE `Median annual wage, dollars, 2025` >
(SELECT AVG(`Median annual wage, dollars, 2025`) FROM employment_projections
WHERE `Median annual wage, dollars, 2025` > 0)
AND `Occupational openings, 2025–35 annual average` >
(SELECT AVG(`Occupational openings, 2025–35 annual average`) FROM employment_projections
WHERE `Occupational openings, 2025–35 annual average` > 0)
ORDER BY Annual_openings DESC
LIMIT 20;

-- Top occupations with the highest projected openings, wages and positive growth
SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE,
`Median annual wage, dollars, 2025` AS Median_wage,
`Occupational openings, 2025–35 annual average` AS Annual_openings,
`Employment change, percent, 2025–35` AS Growth_percent,
`Employment change, numeric, 2025–35` AS Jobs_change
FROM employment_projections
WHERE `Median annual wage, dollars, 2025` >
(SELECT AVG(`Median annual wage, dollars, 2025`)
FROM employment_projections WHERE `Median annual wage, dollars, 2025` > 0)
AND `Occupational openings, 2025–35 annual average` > 
(SELECT AVG(`Occupational openings, 2025–35 annual average`)
FROM employment_projections WHERE `Occupational openings, 2025–35 annual average` > 0)
AND `Employment change, percent, 2025–35` > 0
ORDER BY Growth_percent DESC, Annual_openings DESC
LIMIT 20;

-- States with the highest current employment in occupations with strong projected growth
SELECT s.AREA_TITLE AS State,
SUM(s.TOT_EMP) AS Current_employment,
ROUND(AVG(ep.`Employment change, percent, 2025–35`), 2) AS Avg_projected_growth
FROM state_employment s
JOIN employment_projections ep ON s.OCC_CODE = ep.`2025 National Employment Matrix code`
WHERE ep.`Employment change, percent, 2025–35` > 0
GROUP BY s.AREA_TITLE
ORDER BY Avg_projected_growth DESC;

-- States with the highest current employment in occupations with high projected openings
SELECT s.AREA_TITLE AS State,
ROUND(SUM(s.TOT_EMP), 0) AS Current_employment,
ROUND(SUM(ep.`Occupational openings, 2025–35 annual average`), 2) AS Associated_national_openings
FROM state_employment s
JOIN employment_projections ep
ON s.OCC_CODE = ep.`2025 National Employment Matrix code`
GROUP BY s.AREA_TITLE
ORDER BY Associated_national_openings DESC
LIMIT 10;

-- Top 10 states with the highest wages, projected openings and growth
SELECT s.AREA_TITLE AS State,
ROUND(AVG(s.A_MEDIAN), 2) AS Avg_median_wage,
ROUND(SUM(s.TOT_EMP), 0) AS Current_employment,
ROUND(SUM(ep.`Occupational openings, 2025–35 annual average`), 2) AS Associated_national_openings,
ROUND(AVG(ep.`Employment change, percent, 2025–35`), 2) AS Avg_projected_growth
FROM state_employment s
JOIN employment_projections ep ON s.OCC_CODE = ep.`2025 National Employment Matrix code`
WHERE s.A_MEDIAN > 0 AND s.A_MEDIAN > (SELECT AVG(A_MEDIAN) FROM state_employment WHERE A_MEDIAN > 0)
AND ep.`Occupational openings, 2025–35 annual average` > (SELECT AVG(`Occupational openings, 2025–35 annual average`)
FROM employment_projections WHERE `Occupational openings, 2025–35 annual average` > 0)
AND ep.`Employment change, percent, 2025–35` > 0
GROUP BY s.AREA_TITLE
ORDER BY Avg_median_wage DESC, Associated_national_openings DESC, Avg_projected_growth DESC;

-- Top 5 highest growth projected occupations per state
WITH Ranked_Occupations AS (SELECT s.AREA_TITLE AS State, s.OCC_CODE,
s.OCC_TITLE AS Occupation, s.TOT_EMP AS Current_employment, s.A_MEDIAN AS State_median_wage,
ep.`Employment change, percent, 2025–35` AS Projected_growth,
ep.`Employment change, numeric, 2025–35` AS Projected_jobs_change,
ROW_NUMBER() OVER (PARTITION BY s.AREA_TITLE ORDER BY ep.`Employment change, percent, 2025–35` DESC) AS rn
FROM state_employment s JOIN employment_projections ep ON s.OCC_CODE = ep.`2025 National Employment Matrix code`
WHERE ep.`Employment change, percent, 2025–35` > 0)

SELECT * FROM Ranked_Occupations WHERE rn <= 5

-- Top 10 states for a certain occupation in terms of wage, openings, growth
SELECT s.AREA_TITLE AS State, s.OCC_CODE, s.OCC_TITLE AS Occupation,
s.TOT_EMP AS Current_employment, s.A_MEDIAN AS State_median_wage,
s.LOC_QUOTIENT, ep.`Employment change, percent, 2025–35` AS National_projected_growth,
ep.`Occupational openings, 2025–35 annual average` AS National_annual_openings
FROM state_employment s
JOIN employment_projections ep ON s.OCC_CODE = ep.`2025 National Employment Matrix code`
WHERE s.OCC_TITLE = 'Operations Research Analysts' AND s.LOC_QUOTIENT > 0
ORDER BY s.LOC_QUOTIENT DESC
LIMIT 20;
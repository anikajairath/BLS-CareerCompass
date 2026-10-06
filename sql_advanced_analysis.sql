-- Top 10% occupations for strong wage, growth and openings
WITH Ranked_Occupations AS (SELECT `2025 National Employment Matrix code` AS OCC_CODE,
`2025 National Employment Matrix title` AS OCC_TITLE,
`Employment, 2025` AS Employment_2025,
`Employment, 2035` AS Employment_2035,
`Employment change, percent, 2025–35` AS Growth_Percent,
`Occupational openings, 2025–35 annual average` AS Annual_Openings,
`Median annual wage, dollars, 2025` AS Median_Wage,
NTILE(10) OVER (ORDER BY `Median annual wage, dollars, 2025` DESC) AS Wage_Decile,
NTILE(10) OVER (ORDER BY `Employment change, percent, 2025–35` DESC) AS Growth_Decile,
NTILE(10) OVER (ORDER BY `Occupational openings, 2025–35 annual average` DESC) AS Openings_Decile
FROM employment_projections WHERE `Median annual wage, dollars, 2025` > 0
AND `Employment change, percent, 2025–35` IS NOT NULL 
AND `Occupational openings, 2025–35 annual average` > 0)

SELECT *
FROM Ranked_Occupations
WHERE Wage_Decile = 1 AND Growth_Decile = 1 AND Openings_Decile = 1
ORDER BY Median_Wage DESC, Growth_Percent DESC, Annual_Openings DESC;

-- States that outperform national median wage
WITH National_Benchmark_Wage AS (SELECT OCC_CODE, OCC_TITLE,
A_MEDIAN AS National_Median_Wage FROM national_employment
WHERE A_MEDIAN > 0 AND TOT_EMP > 0)

SELECT s.AREA_TITLE AS State, s.OCC_CODE, s.OCC_TITLE AS Occupation, s.A_MEDIAN AS State_Median_Wage,
n.National_Median_Wage, 
ROUND(((s.A_MEDIAN - n.National_Median_Wage)/n.National_Median_Wage) * 100, 2) AS Wage_Difference_Percent
FROM state_employment s
JOIN National_Benchmark_Wage n ON n.OCC_CODE = s.OCC_CODE
WHERE s.A_MEDIAN > n.National_Median_Wage
ORDER BY Wage_Difference_Percent DESC;

-- Creating a career profile view
CREATE VIEW careercompass_occupation_profile AS
SELECT ep.`2025 National Employment Matrix code` AS OCC_CODE, ep.`2025 National Employment Matrix title` AS OCC_TITLE,
ep.`Employment, 2025` AS Employment_2025, ep.`Employment, 2035` AS Employment_2035,
ep.`Employment change, numeric, 2025–35` AS Jobs_Change,
ep.`Employment change, percent, 2025–35` AS Growth_Percent,
ep.`Occupational openings, 2025–35 annual average` AS Annual_Openings,
ep.`Median annual wage, dollars, 2025` AS National_Median_Wage,
ep.`Typical education needed for entry` AS Education,
ep.`Work experience in a related occupation` AS Experience,
ep.`ON_JOB_TRAINING` AS Training,
n.TOT_EMP AS National_OEWS_Employment,
n.A_MEDIAN AS National_OEWS_Median_Wage
FROM employment_projections ep
LEFT JOIN national_employment n
ON ep.`2025 National Employment Matrix code` = n.OCC_CODE;

-- Creating index on OCC_CODE in national_employment
CREATE INDEX idx_national_occ_code ON national_employment (OCC_CODE);

-- Creating index on OCC_CODE in state_employment
CREATE INDEX idx_state_occ_code ON state_employment (OCC_CODE);

-- Creating index on OCC_CODE in msa_employment
CREATE INDEX idx_msa_occ_code ON msa_employment (OCC_CODE);

-- Creating index on National Employment Matrix code in employment_projections
CREATE INDEX idx_ep_occ_code ON employment_projections (`2025 National Employment Matrix code`);

-- Creating index on National Employment Matrix code in openings
CREATE INDEX idx_openings_occ_code ON openings (`2025 National Employment Matrix code`);

-- Stored procedure to suggest top 10 best states for any occupation
DELIMITER //

CREATE PROCEDURE occupation_best_states(IN occupation_code_input VARCHAR(20))
BEGIN
	SELECT s.AREA_TITLE AS State, s.OCC_TITLE AS Occupation, s.A_MEDIAN AS State_Median_Wage,
	s.TOT_EMP AS State_Employment, s.LOC_QUOTIENT, ep.`Employment change, percent, 2025–35` AS Projected_Growth,
	ep.`Occupational openings, 2025–35 annual average` AS Annual_Openings
    FROM state_employment s
    JOIN employment_projections ep ON s.OCC_CODE = ep.`2025 National Employment Matrix code`
    WHERE s.OCC_CODE = occupation_code_input
    AND s.A_MEDIAN != 0
    AND ep.`Employment change, percent, 2025–35` > 0
    ORDER BY s.A_MEDIAN DESC,
    ep.`Employment change, percent, 2025–35` DESC,
	ep.`Occupational openings, 2025–35 annual average` DESC,
	s.LOC_QUOTIENT DESC
    LIMIT 10;
END//

DELIMITER ;

-- Stored procedure to suggest top 10 display occupations for any state
DELIMITER //

CREATE PROCEDURE state_top_occupations(IN state_input VARCHAR(100))
BEGIN
	SELECT s.AREA_TITLE AS State, s.OCC_CODE, s.OCC_TITLE AS Occupation,
	s.TOT_EMP AS Employment, s.A_MEDIAN AS Median_Wage,
	s.LOC_QUOTIENT, ep.`Employment change, percent, 2025–35` AS Projected_Growth,
	ep.`Occupational openings, 2025–35 annual average` AS Annual_Openings
	FROM state_employment s
    JOIN employment_projections ep ON s.OCC_CODE = ep.`2025 National Employment Matrix code`
    WHERE s.AREA_TITLE = state_input
    AND s.TOT_EMP > 0
	AND s.A_MEDIAN != 0
    ORDER BY s.A_MEDIAN DESC, ep.`Employment change, percent, 2025–35` DESC,
	ep.`Occupational openings, 2025–35 annual average` DESC
    LIMIT 10;
END //

DELIMITER ;

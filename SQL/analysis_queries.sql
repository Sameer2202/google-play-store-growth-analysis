-- =============================================================
-- Google Play Store Analytics Project
-- Analysis Queries — answering the project's Key Questions
-- Database: playstore_analysis | Tables: playstore_clean, reviews_clean
-- =============================================================

USE playstore_analysis;

-- ---------------------------------------------------------------
-- Q1: Which categories drive the most installs?
-- ---------------------------------------------------------------
SELECT Category, SUM(Installs) AS Total_Installs, COUNT(*) AS App_Count
FROM playstore_clean
GROUP BY Category
ORDER BY Total_Installs DESC
LIMIT 10;


-- ---------------------------------------------------------------
-- Q2: Do higher-rated apps actually get more installs?
-- ---------------------------------------------------------------
SELECT
    CASE
        WHEN Rating >= 4.5 THEN '4.5+'
        WHEN Rating >= 4.0 THEN '4.0-4.5'
        WHEN Rating >= 3.5 THEN '3.5-4.0'
        WHEN Rating >= 3.0 THEN '3.0-3.5'
        ELSE 'Below 3.0'
    END AS Rating_Bucket,
    COUNT(*) AS App_Count,
    ROUND(AVG(Installs)) AS Avg_Installs
FROM playstore_clean
WHERE Rating IS NOT NULL
GROUP BY Rating_Bucket
ORDER BY Rating_Bucket DESC;


-- ---------------------------------------------------------------
-- Q3: What's the free vs paid app split?
-- ---------------------------------------------------------------
SELECT `Type`, COUNT(*) AS App_Count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM playstore_clean), 1) AS Pct
FROM playstore_clean
GROUP BY `Type`;


-- ---------------------------------------------------------------
-- Q4: How have installs trended over time (by last-update year)?
-- ---------------------------------------------------------------
SELECT YEAR(Last_Updated) AS Update_Year, SUM(Installs) AS Total_Installs
FROM playstore_clean
WHERE Last_Updated IS NOT NULL
GROUP BY Update_Year
ORDER BY Update_Year;


-- ---------------------------------------------------------------
-- Q5: Which paid apps have the best rating-to-install performance?
-- ---------------------------------------------------------------
SELECT App, Category, Rating, Price, Installs
FROM playstore_clean
WHERE `Type` = 'Paid' AND Rating IS NOT NULL
ORDER BY Rating DESC, Installs DESC
LIMIT 10;


-- ---------------------------------------------------------------
-- Q6: Does app size (MB) impact installs?
-- ---------------------------------------------------------------
SELECT
    CASE
        WHEN Size_MB IS NULL THEN 'Varies with device'
        WHEN Size_MB < 10 THEN 'Under 10MB'
        WHEN Size_MB < 50 THEN '10-50MB'
        WHEN Size_MB < 100 THEN '50-100MB'
        ELSE 'Over 100MB'
    END AS Size_Bucket,
    COUNT(*) AS App_Count,
    ROUND(AVG(Installs)) AS Avg_Installs
FROM playstore_clean
GROUP BY Size_Bucket
ORDER BY Avg_Installs DESC;


-- ---------------------------------------------------------------
-- Q7: What do user reviews reveal about retention, by category?
-- (Joins playstore_clean with reviews_clean)
-- ---------------------------------------------------------------
SELECT p.Category,
       COUNT(r.Sentiment) AS Review_Count,
       ROUND(SUM(CASE WHEN r.Sentiment = 'Positive' THEN 1 ELSE 0 END) * 100.0 / COUNT(r.Sentiment), 1) AS Pct_Positive,
       ROUND(AVG(r.Sentiment_Polarity), 3) AS Avg_Polarity
FROM playstore_clean p
JOIN reviews_clean r ON p.App = r.App
GROUP BY p.Category
HAVING Review_Count > 50
ORDER BY Pct_Positive DESC
LIMIT 10;


-- ---------------------------------------------------------------
-- Q8: Which niche categories show high-potential growth signals?
-- (few competitors, but strong ratings and installs)
-- ---------------------------------------------------------------
SELECT Category,
       COUNT(*) AS App_Count,
       ROUND(AVG(Rating), 2) AS Avg_Rating,
       ROUND(AVG(Installs)) AS Avg_Installs
FROM playstore_clean
WHERE Rating IS NOT NULL
GROUP BY Category
HAVING App_Count < 50
ORDER BY Avg_Rating DESC, Avg_Installs DESC
LIMIT 10;
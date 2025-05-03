-- Exploratory Data Analysis

SELECT * 
FROM layoffs_staging2
;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2
;

SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC
;

# DELETE MORE DUPLICATES
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging2
;

WITH duplicate_cte2 AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging2
)
SELECT *
FROM duplicate_cte2
WHERE row_num > 1
;

CREATE TABLE `layoffs_staging3` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` bigint DEFAULT NULL,
  `percentage_laid_off` text,
  `date` date DEFAULT NULL,
  `stage` text,
  `country` text,
  `funds_raised_millions` text,
  `row_num`INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging3
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging2
;

DELETE 
FROM layoffs_staging3
WHERE row_num > 1
;

SELECT * 
FROM layoffs_staging3
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC
;

# DELETE ROW_NUM

ALTER TABLE layoffs_staging3
DROP COLUMN row_num
;


SELECT * 
FROM layoffs_staging3
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC
;

# Sum of total laid off
SELECT company, SUM(total_laid_off) 
FROM layoffs_staging3
GROUP BY company
ORDER BY 2 DESC
;

# When layoffs occurred
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging3
;

# Industry hit hardest
SELECT industry, SUM(total_laid_off) 
FROM layoffs_staging3
GROUP BY industry
ORDER BY 2 DESC
;

SELECT * 
FROM layoffs_staging3
;

# Country hit hardest
SELECT country, SUM(total_laid_off) 
FROM layoffs_staging3
GROUP BY country
ORDER BY 2 DESC
;

# By year
SELECT YEAR(`date`), SUM(total_laid_off) 
FROM layoffs_staging3
GROUP BY YEAR(`date`)
ORDER BY 1 DESC
;

# By stage
SELECT stage, SUM(total_laid_off) 
FROM layoffs_staging3
GROUP BY stage
ORDER BY 2 DESC
;

SELECT company, SUM(total_laid_off) 
FROM layoffs_staging3
GROUP BY company
ORDER BY 2 DESC
;

# Progression of layoffs (rolling sum)
# based on month

SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off)
FROM layoffs_staging3
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
;

WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging3
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC
)
SELECT `Month`, total_off,
SUM(total_off) OVER(ORDER BY `Month`) AS rolling_total
FROM Rolling_Total
;

# Look at company layoffs per year

SELECT company, SUM(total_laid_off) 
FROM layoffs_staging3
GROUP BY company
ORDER BY 2 DESC
;

SELECT company, YEAR(`date`), SUM(total_laid_off) 
FROM layoffs_staging3
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC
;

# rank top 5 companies laid off employees each year

WITH Company_Year (company, years, total_laid_off)  AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off) 
FROM layoffs_staging3
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(SELECT *, 
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT * 
FROM Company_Year_Rank
WHERE ranking <= 5
;

















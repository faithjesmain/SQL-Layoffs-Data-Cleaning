SELECT * 
FROM layoffs
;

-- Stage Table

CREATE TABLE layoffs_staging
LIKE layoffs
;

INSERT layoffs_staging
SELECT * 
FROM layoffs
;

SELECT * 
FROM layoffs_staging
;

-- REMOVE DUPLICATES

# add unique row number to identify duplicates

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
;

# CTE
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1
;

# Staging 2 database to delete

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` bigint DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2
;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
;

DELETE
FROM layoffs_staging2
WHERE row_num > 1
;

SELECT * 
FROM layoffs_staging2
;

-- STANDARDIZE DATA (issues like white spaces)

# Trim White Space
SELECT company, TRIM(company)
FROM layoffs_staging2
;

UPDATE layoffs_staging2
SET company = TRIM(company)
;

# Fix industry names (crypto, crypto currency)

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1
;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'
;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'
;

# Country

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1
;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'
;

SELECT *
FROM layoffs_staging2
;

# Change date to date column

# Replace invalid strings with NULL
UPDATE layoffs_staging2
SET `date` = NULL 
WHERE `date` IN ('None', '')
;

# Convert valid strings to date
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
WHERE `date` LIKE '%m/%d/%Y'
;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE
;

SELECT `date`
FROM layoffs_staging2
;

-- REMOVE NULLS & BLANKS

# Set blanks to nulls

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''
;

SELECT *
FROM layoffs_staging2
WHERE industry = '' OR industry = 'None'
;

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

# Join data on itself to fill in industry

SELECT * 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL
;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL
;

SELECT *
FROM layoffs_staging2
;

# Set 'None' to NULL 

UPDATE layoffs_staging2
SET percentage_laid_off = NULL 
WHERE percentage_laid_off = 'None'
;

UPDATE layoffs_staging2
SET funds_raised_millions = NULL
WHERE funds_raised_millions = 'None'
;

SELECT percentage_laid_off, funds_raised_millions
FROM layoffs_staging2
;

SELECT *
FROM layoffs_staging2
;

# Drop a column

ALTER TABLE layoffs_staging2
DROP COLUMN row_num
;

SELECT *
FROM layoffs_staging2
;

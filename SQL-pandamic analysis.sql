-- Part 1: explore dataset

-- SELECT columns we need
SELECT continent, location, date, total_cases, new_cases, total_deaths, population  FROM CovidDeaths
ORDER BY location, date

-- Create the temp table
CREATE TABLE #death ( continent NVARCHAR(50), 
location NVARCHAR(50), date DATE, total_cases INT, new_cases INT, total_deaths INT, population numeric(18,0))

-- Insert value to temp table 
INSERT INTO #death 
SELECT continent, location, date, total_cases, new_cases, total_deaths, population  FROM CovidDeaths


-- 1) Look at the total cases vs total death
SELECT *, (CAST(total_deaths AS decimal) / CAST(total_cases AS decimal) * 100) as death_rate FROM #death
WHERE continent IS NOT NULL 
ORDER BY continent, location, date


-- Rank of MAX death rate per country 
WITH death_table AS 
(SELECT *, (CAST(total_deaths AS decimal) / CAST(total_cases AS decimal) * 100) as death_rate FROM #death
WHERE continent IS NOT NULL)
SELECT continent, location, MAX(death_rate) AS max_death_rate FROM death_table
GROUP BY continent, location
ORDER BY continent, max_death_rate DESC


-- 2) look at the total case vs population (infection rate)
SELECT *, (CAST(total_cases AS decimal) / CAST(population AS decimal) * 100) as infection_rate FROM #death
WHERE continent IS NOT NULL 
ORDER BY continent, location, date 

-- Rank of MAX infection rate per country 
WITH death_table AS 
(SELECT *, (CAST(total_cases AS decimal) / CAST(population AS decimal) * 100) as infection_rate FROM #death
WHERE continent IS NOT NULL )
SELECT continent, location, MAX(infection_rate) AS max_infection_rate FROM death_table
GROUP BY continent, location
ORDER BY max_infection_rate DESC


-- 3) Countries with the highest death count per population 
WITH death_table AS 
(SELECT *, (CAST(total_deaths AS decimal) / CAST(population AS decimal) * 100) as death_population_rate FROM #death
WHERE continent IS NOT NULL )
SELECT continent, location, MAX(total_deaths) AS max_total_death, MAX(death_population_rate) AS max_death_population_rate FROM death_table
GROUP BY continent, location
ORDER BY max_total_death DESC

-- 4) Total death per continent 
SELECT continent, MAX(total_deaths) AS total_death FROM #death
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death DESC

-- 5) Global number: Global death, global cases, global death_rate
SELECT date, SUM(total_cases) AS global_case, SUM(total_deaths) global_death, SUM(CAST(total_deaths AS decimal))/ SUM(CAST(total_cases AS decimal)) AS global_death_rate FROM #death
GROUP BY date
order by date



-- Part 2: Look insight from joing table "death" and "vaccination" 

-- 1) Joining tables

SELECT vacc.continent, vacc.location, vacc.date, vacc.new_vaccinations, vacc.total_vaccinations, total_deaths, total_cases, population FROM CovidDeaths as death
INNER JOIN CovidVaccinations as vacc
ON death.date = vacc.date AND death.location = vacc.location AND death.continent = death.continent

-- 2) Create temp table and insert values into
--DROP table #insight

CREATE TABLE #insight
(continent nvarchar(50), 
location nvarchar(50),
date Date,new_vaccinations INT,  total_vaccination INT, total_death INT, total_cases INT, population INT)

INSERT INTO #insight 
SELECT vacc.continent AS continent, vacc.location AS location, vacc.date AS date, vacc.new_vaccinations AS new_vaccinations, vacc.total_vaccinations AS total_vaccinations, total_deaths, total_cases, population FROM CovidDeaths as death
INNER JOIN CovidVaccinations as vacc
ON death.date = vacc.date AND death.location = vacc.location AND death.continent = death.continent

SELECT * FROM #insight


-- 3) TOTAL Population VS new vaccination
SELECT continent, location, date, population, new_vaccinations, SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS rolling_vaccination
FROM #insight
WHERE new_vaccinations IS NOT NULL

-- MAX vaccination people per country 
WITH roll_vac AS
(SELECT continent, location, date, population, new_vaccinations, SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS rolling_vaccination
FROM #insight
WHERE new_vaccinations IS NOT NULL)
SELECT location, MAX(rolling_vaccination) AS max_vaccination_count 
FROM roll_vac
GROUP BY location
ORDER BY MAX(rolling_vaccination) DESC

-- How's about the vaccination rate daily evolution ? 
WITH roll_vac AS
(SELECT continent, location, date, population, new_vaccinations, SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS rolling_vaccination
FROM #insight
WHERE new_vaccinations IS NOT NULL)
SELECT *, (CAST(rolling_vaccination AS decimal)/ CAST(population AS decimal)) * 100 AS daily_vaccination_rate
FROM roll_vac

-- And how's the global max vaccination rate? 
WITH roll_vac AS
(SELECT continent, location, date, population, new_vaccinations, SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS rolling_vaccination
FROM #insight
WHERE new_vaccinations IS NOT NULL)
SELECT DISTINCT location, population,  MAX(rolling_vaccination) OVER(PARTITION BY location) AS max_vaccination_count, 
CAST(MAX(rolling_vaccination) OVER(PARTITION BY location) AS decimal)/ CAST(population AS decimal) AS country_vaccination_rate
FROM roll_vac
ORDER BY max_vaccination_count DESC




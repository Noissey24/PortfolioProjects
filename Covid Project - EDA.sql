# This first part of the project is a Exploratory Data Analysis (EDA), to create views and temp tables in order to use them later on to create visualizations.
#
# The main skills used in this file are the use of SELECT, WHERE, CAST, ALIASING, CTE, TEMP TABLES, AGGREGATE FUNCTIONS, OVER, PARTITION BY, VIEWS
#
USE covid_project;
# 1. Percentage of infected people who died due to covid-19, in other words, the odds of dying of covid-19.
SELECT 	location, reg_date, total_deaths, total_cases,
		(CAST(total_deaths AS UNSIGNED) / CAST(total_cases AS UNSIGNED)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

# 2. Percentage of people that got Covid-19 or the chance of catching Covid-19
SELECT 	location, reg_date, total_cases, population,
		(CAST(total_cases AS UNSIGNED) / CAST(population AS UNSIGNED)) * 100 AS InfectedPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

# 3. Countries with the highest Infected Percentages compared to population
SELECT 	location, MAX(CAST(total_cases AS UNSIGNED)) AS Total_cases, Population,
		MAX(CAST(total_cases AS UNSIGNED) / CAST(population AS UNSIGNED)) * 100 AS InfectedPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY InfectedPercentage DESC;

# 4. Countries with the highest Death Percentages compared to population
SELECT 	location, MAX(CAST(total_deaths AS UNSIGNED)) AS Total_deaths, Population,
		MAX(CAST(total_deaths AS UNSIGNED) / CAST(population AS UNSIGNED)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY DeathPercentage DESC;

# 5. Countries with the highest Death count
SELECT 	location, MAX(CAST(total_deaths AS UNSIGNED)) AS Total_deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY Total_deaths DESC;

# 6. Continents with the highest Infected Percentages compared to population
SELECT 	location, MAX(CAST(total_cases AS UNSIGNED)) AS Total_cases, Population,
		MAX(CAST(total_cases AS UNSIGNED) / CAST(population AS UNSIGNED)) * 100 AS InfectedPercentage
FROM CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income'
GROUP BY Location, population
ORDER BY InfectedPercentage DESC;

# 7. Continents with the highest Death count
SELECT 	location, MAX(CAST(total_deaths AS UNSIGNED)) AS Total_deaths
FROM CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income'
GROUP BY Location
ORDER BY Total_deaths DESC;

# 8. Getting total cases, deaths and a measure for the whole table
SELECT 	SUM(CAST(new_deaths AS UNSIGNED)) AS Total_Deaths, SUM(CAST(new_cases AS UNSIGNED)) AS Total_Cases, 
		SUM(CAST(new_deaths AS UNSIGNED)) / SUM(CAST(new_cases AS UNSIGNED)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1;

#9 Rolling people vaccinated, just an accumulative sum of the people that has been vaccinated
SELECT 	Dts.continent, Dts.location, Dts.reg_date, Dts.population, Vac.new_vaccinations,
		SUM(CAST(Vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY Dts.location ORDER BY Dts.location, Dts.reg_date) AS RollingVaccinated
FROM covidDeaths Dts
JOIN covidVaccinations Vac
	ON Dts.location = Vac.location and Dts.reg_date = Vac.reg_date;

# 10 Percentage of people who has been vaccinated, using a CTE
WITH CTE_RollingPeopleVaccinated (continent, location, reg_date, population, new_vaccinations, RollingVaccinated)
AS (
	SELECT 	Dts.continent, Dts.location, Dts.reg_date, Dts.population, Vac.new_vaccinations,
			SUM(CAST(Vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY Dts.location ORDER BY Dts.location, Dts.reg_date) AS RollingVaccinated
	FROM covidDeaths Dts
	JOIN covidVaccinations Vac
		ON Dts.location = Vac.location and Dts.reg_date = Vac.reg_date
)
SELECT *, RollingVaccinated/population*100 AS VaccinatedPercentage
FROM CTE_RollingPeopleVaccinated;

# 11 Percentage of people who has been vaccinated, using temporary tables

DROP TEMPORARY TABLE IF EXISTS temp_Vaccinated_vs_Population;
CREATE TEMPORARY TABLE temp_Vaccinated_vs_Population(
continent VARCHAR(20),
location VARCHAR(60),
reg_date DATETIME,
population BIGINT,
new_vaccinations BIGINT,
rollingVaccinated BIGINT
);
# I had to use the IGNORE clause to avoid the 1292 warning, that in this case wouldn't let me insert the data
INSERT IGNORE INTO temp_Vaccinated_vs_Population
SELECT 	Dts.continent, Dts.location, Dts.reg_date, CAST(Dts.population AS UNSIGNED) AS Population, CAST(Vac.new_vaccinations AS UNSIGNED) AS new_vaccinations,
		SUM(CAST(Vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY Dts.location ORDER BY Dts.location, Dts.reg_date) AS RollingVaccinated
FROM covidDeaths Dts
JOIN covidVaccinations Vac
	ON Dts.location = Vac.location and Dts.reg_date = Vac.reg_date;
    
SELECT *, RollingVaccinated/Population*100 AS VaccinatedPercentage
FROM temp_Vaccinated_vs_Population;

# 12 Create a view of the Percentage of vaccinated people
CREATE VIEW PercentVaccinated AS
SELECT 	Dts.continent, Dts.location, Dts.reg_date, Dts.population, Vac.new_vaccinations, 
		SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (Partition by Dts.Location Order by Dts.location, Dts.reg_date) as RollingVaccinated
FROM CovidDeaths Dts
JOIN CovidVaccinations Vac
	ON Dts.location = Vac.location AND Dts.reg_date = Vac.reg_date
WHERE Dts.continent IS NOT NULL; 
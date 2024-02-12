/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in country has 'state'

Select location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null and total_deaths is not Null
order by 1,2

-- Use Case statement to show a DeathPercentage is Massive or Minuscule
SELECT  location,  date, total_cases, total_deaths, 
CASE 
WHEN ((CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100)> 2 THEN 'Massive'
ELSE 'Minuscule' 
END AS DeathStatus
FROM PortfolioProject..CovidDeaths
WHERE total_deaths IS NOT NULL
ORDER BY DeathStatus;

-- Having Clause Count total_deaths over 500 people in all locations
SELECT location, total_deaths, Count(Convert(Float,total_Deaths)) As total_Deaths_Over500
FROM PortfolioProject..CovidDeaths WHERE Total_Deaths is not NULL
GROUP BY Location, Total_Deaths
HAVING count(Convert(Float,total_Deaths))  > 500
ORDER BY count(Convert(Float,total_Deaths)) 

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select location, date, total_cases, total_deaths, (cast(total_cases as float)/cast(population as float))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as HighestPercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as HighestDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc


--Show the lowest total death in 2022 in continent
SELECT Continent, date, Min(cast(Total_deaths as int)) as LowestDeathCount 
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL 
AND date >= '2022-01-01' AND date <= '2022-12-31' 
GROUP BY Continent,date
ORDER BY TotalDeathCount DESC

-- Showing the highest death count per population of a continent contain 'state'
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null 
Group by continent
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest infected count per population

Select continent, MAX(cast(Total_cases as int)) as TotalCaseCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent
order by TotalCaseCount desc

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2


Select avg(new_cases) as total_cases, avg(cast(new_deaths as int)) as total_deaths, avg(cast(new_deaths as int))/avg(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not Null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
Select *, (RollingPeopleVaccinated/Population)*100 as PopvsVac
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100 as PopvsVac
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Create View PercentPopulationInfected as
Select location, date, total_cases, total_deaths, (cast(total_cases as float)/cast(population as float))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null 


CREATE VIEW GlobalDeathPercentage as
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null 


CREATE VIEW LowestDeathCountin2022 as
SELECT Continent, date, min(cast(Total_deaths as int)) as LowestDeathCount 
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL 
AND date >= '2022-01-01' AND date <= '2022-12-31' 
GROUP BY Continent,date

Create view highestdeathsbylocation as
SELECT Location, MAX(cast(Total_deaths as int)) as HighestDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by Location

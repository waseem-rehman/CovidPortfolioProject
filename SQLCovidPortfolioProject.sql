SELECT *
FROM [Portfololio-Project]..Coviddeath
Where continent is not null
Order by 3,4

SELECT *
FROM [Portfololio-Project]..CovidVaccination
Where continent is not null
Order by location, date

-- Working with reduced data

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfololio-Project]..Coviddeath
Where continent is not null
Order by 1,2

-- Finding out DeathPercentage which gives us insight into likelihood of dying of covid

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM [Portfololio-Project]..Coviddeath
Where continent is not null AND location like 'Pak%' AND total_cases is not null
Order by 1,2

-- Finding out total cases to population ratio, shows what % of population got covid

SELECT location, date, population, total_cases, (total_deaths/population)*100 as PopulationCovidPercentage
FROM [Portfololio-Project]..Coviddeath
--Where location like 'Pak%'
Order by 1,2


--Looking at countries with highest infection rate compare to population

SELECT location, population, Max(total_cases) as HighestInfectionCount, Max((total_deaths/population))*100 as PopulationCovidPercentage
FROM [Portfololio-Project]..Coviddeath
--Where location like 'Pak%'
Group by location, population
Order by PopulationCovidPercentage desc

-- Showing countries with highest death count per population

SELECT location, Max(cast(total_deaths as bigint)) as TotalDeathCount
FROM [Portfololio-Project]..Coviddeath
--Where location like 'Pak%'
Where continent is not null
Group by location
Order by TotalDeathCount desc


-- Let's break it down by Continent by setting continent is null as then it gives location as continent

SELECT location, Max(cast(total_deaths as bigint)) as TotalDeathCount
FROM [Portfololio-Project]..Coviddeath
--Where location like 'Pak%'
Where continent is null
Group by location
Order by TotalDeathCount desc

-- Let's break it down by Continent by setting continent is not null

SELECT continent, Max(cast(total_deaths as bigint)) as TotalDeathCount
FROM [Portfololio-Project]..Coviddeath
--Where location like 'Pak%'
Where continent is not null
Group by continent
Order by TotalDeathCount desc

-- Global cases and death by date

SELECT date, Sum(new_cases) as TotalCases, Sum(new_deaths) as TotalDeaths, Sum (new_deaths)/Sum(new_cases)*100 as DeathPercentage
FROM [Portfololio-Project]..Coviddeath
Where continent is not null AND new_cases > 0
Group by date
Order by 1,2

--Overall

SELECT Sum(new_cases) as TotalCases, Sum(new_deaths) as TotalDeaths, Sum (new_deaths)/Sum(new_cases)*100 as DeathPercentage
FROM [Portfololio-Project]..Coviddeath
Where continent is not null AND new_cases > 0
--Group by date
Order by 1,2

--Looking at Total Population vs Vaccinations (Note:LOB or Large Object are Column definitions inc. Text, varchar(MAX) Changing the SubArea column type to a more appropriate varchar(30) (Max length submission from the application is 30) resolves the issue. cast(dea.location as varchar) didn't worked. Convert worked!

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, Sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by Convert(varchar(30),dea.Location),dea.date) as RollingPeopleVaccinated --,(RollingPeopleVaccinated/population)*100
FROM [Portfololio-Project]..Coviddeath as dea
Join [Portfololio-Project]..CovidVaccination vac
 On dea.location=vac.location
 and dea.date=vac.date
Where dea.continent is not null --AND dea.location like 'Pak%'
Order by 2,3

-- CTE (Common Table Expression)

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, Sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by Convert(varchar(30),dea.Location),dea.date) as RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM [Portfololio-Project]..Coviddeath dea
Join [Portfololio-Project]..CovidVaccination vac
 On dea.location=vac.location
 and dea.date=vac.date
Where dea.continent is not null --AND dea.location like 'Pak%'
--Order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- TEMP Table (CREATE Table and Insert Into)

DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
 Continent nvarchar(255),
 Location nvarchar(255),
 Date datetime,
 Population numeric,
 New_vaccinations numeric,
 RollingPeopleVaccinated numeric,
)

INSERT into #PercentPopulationVaccinated
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, Sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by Convert(varchar(30),dea.Location),dea.date) as RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM [Portfololio-Project]..Coviddeath dea
Join [Portfololio-Project]..CovidVaccination vac
 On dea.location=vac.location
 and dea.date=vac.date
Where dea.continent is not null --AND dea.location like 'Pak%'
--Order by 2,3

SELECT *
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE View PercentPopulationVaccinatedview as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, Sum(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by Convert(varchar(30),dea.Location),dea.date) as RollingPeopleVaccinated --(RollingPeopleVaccinated/population)*100
FROM [Portfololio-Project]..Coviddeath dea
Join [Portfololio-Project]..CovidVaccination vac
 On dea.location=vac.location
 and dea.date=vac.date
Where dea.continent is not null --AND dea.location like 'Pak%'
--Order by 2,3

SELECT TOP(10) *
FROM PercentPopulationVaccinatedview

--Global Cases View

Create View Globalview as
SELECT Sum(new_cases) as TotalCases, Sum(new_deaths) as TotalDeaths, Sum (new_deaths)/Sum(new_cases)*100 as DeathPercentage
FROM [Portfololio-Project]..Coviddeath
Where continent is not null AND new_cases > 0
--Group by date
--Order by 1,2


-- Continent level Globalview

CREATE View ContinentGlobalView as
SELECT continent, Max(cast(total_deaths as bigint)) as TotalDeathCount
FROM [Portfololio-Project]..Coviddeath
--Where location like 'Pak%'
Where continent is not null
Group by continent
--Order by TotalDeathCount desc
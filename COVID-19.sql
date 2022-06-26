select *
from PortfolioProject..CovidDeaths$
where continent is not null
order by 3,4

--select *
--from PortfolioProject..CovidVaccinations$
--order by 3,4

--Select data that we are going to be using

select location,date,total_cases,new_cases,total_deaths,population
from PortfolioProject..CovidDeaths$
where continent is not null
order by location,date --the same as 1,2

--looking at total cases vs total deaths
--shows lilkelihood of dying if you contract Covid in your country
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage --put percentage
from PortfolioProject..CovidDeaths$
where continent is not null
where location like '%states%'
order by location,date --the same as 1,2

select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage --put percentage
from PortfolioProject..CovidDeaths$
where continent is not null
and location like 'Argentina'
order by location,date desc 


--Looking total cases vs population
--shows what percentage of population got Covid-19
select location,date,total_cases,population,(total_cases/population)*100 as DeathPercentage --put percentage
from PortfolioProject..CovidDeaths$
where continent is not null
--where location like '%states%'
order by location,date desc --the same as 1,2

select location,date,total_cases,population,(total_cases/population)*100 as DeathPercentage --put percentage
from PortfolioProject..CovidDeaths$
where continent is not null
and location like '%states%'
order by location,date desc --the same as 1,2


--Looking at countries with highest infection rate compared to population

select location,population,MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected 
from PortfolioProject..CovidDeaths$
where continent is null
group by location, population
order by PercentPopulationInfected desc

--showing countries with highest death count per population
select location,MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is null
group by location
order by TotalDeathCount desc

--now I want to use continents
--Seen that Mexico is not included in north america
select continent,MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc

--Here I have the correct numbers.
select continent,MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc


--Showing the continent with the highest death count per population

select continent,MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc

--Global numbers
--Here I can see the DeathPercentage per day for the whole planet
Select  date,sum(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, (sum(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
--where location like '%States%'
where continent is not null
group by date
order by 1,2

--If I want to see the global number for the whole Covid-19 time
Select sum(new_cases)as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, (sum(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
--where location like '%States%'
where continent is not null
--group by date
order by 1,2

--Lets join tables
Select *
From PortfolioProject..CovidDeaths$ dea --alias for the join
join PortfolioProject..CovidVaccinations$ vac
	ON dea.location=vac.location
	and dea.date=vac.date

-- Looking at Total population vs Vaccionations
Select dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations,-- instead of cast( ... as '  ') I can use convert(int, ... )
sum(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as RollingPeopleVaccinated-- Using order by I can see cumulative 
--,(RollingPeopleVaccinated/dea.population)*100  I cannot use this function with this name
From PortfolioProject..CovidDeaths$ dea --alias for the join
join PortfolioProject..CovidVaccinations$ vac
	ON dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null
order by 2,3

-- So, now I want to see the cumulative vaccinated in Argentina
Select dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (PARTITION BY dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
	join PortfolioProject..CovidVaccinations$ vac
		ON dea.location=vac.location
		and dea.date=vac.date
where dea.location like 'Argentina'
order by 2,3
-- I can see that the vaccination proccess started on January 21st, 2021 with 17791 vaccinated achieving a number of
-- 7391255 =~ 7.4M vaccinated to the April 30th, 2021


-- Using CTE

With PopvsVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated) -- if the number of columns is different, I get an error.
as 
(
Select dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations,-- instead of cast( ... as '  ') I can use convert(int, ... )
sum(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as RollingPeopleVaccinated-- Using order by I can see cumulative 
--,(RollingPeopleVaccinated/dea.population)*100  I cannot use this function with this name
From PortfolioProject..CovidDeaths$ dea --alias for the join
	join PortfolioProject..CovidVaccinations$ vac
		ON dea.location=vac.location
		and dea.date=vac.date
where dea.continent is not null
--order by 2,3
)
Select *,(RollingPeopleVaccinated/population)*100
from PopvsVac

--Temp Table
DROP TABLE if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations,-- instead of cast( ... as '  ') I can use convert(int, ... )
sum(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as RollingPeopleVaccinated-- Using order by I can see cumulative 
--,(RollingPeopleVaccinated/dea.population)*100  I cannot use this function with this name
From PortfolioProject..CovidDeaths$ dea --alias for the join
	join PortfolioProject..CovidVaccinations$ vac
		ON dea.location=vac.location
		and dea.date=vac.date
where dea.continent is not null
--order by 2,3

Select *,(RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated

--Creating view to store data for later visualizations
DROP VIEW if exists PercentPopulationVaccinated
Create view PercentPopulationVaccinated as 
Select dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths$ dea --alias for the join
	join PortfolioProject..CovidVaccinations$ vac
		ON dea.location=vac.location
		and dea.date=vac.date
where dea.continent is not null
--order by 2,3

Select * 
from PercentPopulationVaccinated
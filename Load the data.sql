# In this file there's the data loading into their respective tables
USE covid_project;
LOAD DATA local INFILE './/Data//CovidDeaths.csv' INTO TABLE coviddeaths
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA local INFILE './/Data//CovidVaccinations.csv' INTO TABLE covidvaccinations
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
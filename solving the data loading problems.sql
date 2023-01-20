# In this file I show some of the solutions or approaches I took to load the dataset correctly into MySQL

# The first thing I did was loading the first row of the dataset to create the table, using the Table Data Import Wizard from MySQL
# I searched for a reason why it wouldn't let me load the rest of the dataset, so I searched on StackOverflow, and then I checked the file direction of the next variable
# After saving the value into a text file, I set this value to and empty string, so it wouldn't pop an error when loading the data.
SHOW VARIABLES LIKE "secure_file_priv";
# I saw it was necessary to set the local_infile variable to 1, in order to let the user load the data
SET GLOBAL local_infile=1;

# After the data loaded completely, I made a mistake and had the first row duplicated so I deleted one instance of this row
DELETE FROM coviddeaths
WHERE iso_code = 'AFG'
ORDER BY reg_date
LIMIT 1;
# I checked if the table was now correct
Select * from coviddeaths;

# Changed the original date column name to reg_date, to avoid some problems
ALTER TABLE coviddeaths RENAME COLUMN date TO reg_date;

# Checking the number of rows
SELECT count(continent)
FROM coviddeaths;
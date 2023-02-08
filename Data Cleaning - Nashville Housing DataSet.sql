# This Project is all about the process of Data Cleaning.
# PROJECT REACH ------------------------------------------------------------------------------
# The main data cleaning techniques demonstrated are:
#	1) Change the datatype of a column to better describe the column, 
#	2) Replacing NULLs with valid values from the same table,
# 	3) Splitting string columns to obtain more useful fields, 
#	4) Removing duplicate rows
#	5) Data standardization
#
# SKILLS DEMONSTRATED -----------------------------------------------------------------------------
# The main skills used in this project are the use of ALTER TABLE, JOIN, String Functions, CTE, CASE, OVER, PARTITION BY, ROW_NUMBER
#
#--------------------------------------------------------------------------------------------------
USE nashville_housing;

# Check the data from the imported file
SELECT * FROM nashville_housing.housing;

#--------------------------------------------------------------------------------------------------
# Standardize the SaleDate field to only show as a Date and not DateTime (since the DateTime stamps are filled with '00:00:00')

SELECT SaleDate, DATE(SaleDate)
FROM housing;

ALTER TABLE housing CHANGE SaleDate SaleDate DATE;

#--------------------------------------------------------------------------------------------------
# Populate the Property Address Data, After checking the table I noticed there were some rows that had null values in the PropertyAddress field
# Second thing I noticed was that some ParcelIDs were repeated in the table and those always had the same PropertyAddresses

# Shows all the rows with null PropertyAddress, then a self JOIN to see if their ParcelID repeated with a different UniqueID and a valid PropertyAddress
SELECT hsg1.ParcelID, hsg1.UniqueID, hsg1.PropertyAddress, hsg2.ParcelID, hsg2.UniqueID, hsg2.PropertyAddress, IFNULL(hsg1.PropertyAddress, hsg2.PropertyAddress)
FROM housing hsg1
JOIN housing hsg2
	ON hsg1.ParcelID = hsg2.ParcelID 
    AND hsg1.UniqueID != hsg2.UniqueID
WHERE hsg1.PropertyAddress IS NULL;

# This update copied the Property addresses to the null values with the same ParcelID
UPDATE housing hsg1
JOIN housing hsg2
	ON hsg1.ParcelID = hsg2.ParcelID 
    AND hsg1.UniqueID != hsg2.UniqueID
SET hsg1.PropertyAddress = IFNULL(hsg1.PropertyAddress, hsg2.PropertyAddress)
WHERE hsg1.PropertyAddress IS NULL;

#--------------------------------------------------------------------------------------------------
# Splitting both PropertyAddress and OwnerAdress fields to different Address, City, State fields
SELECT 	PropertyAddress,
		trim(substring(PropertyAddress, 1, POSITION(',' IN PropertyAddress)-1)) AS Address,
		trim(substring(PropertyAddress, POSITION(',' IN PropertyAddress)+1)) AS City
FROM housing;

ALTER TABLE housing
ADD PtyAddress VARCHAR(100) AFTER PropertyAddress;

UPDATE housing
SET PtyAddress = trim(substring(PropertyAddress, 1, POSITION(',' IN PropertyAddress)-1));

ALTER TABLE housing
ADD PtyCity VARCHAR(100) AFTER PtyAddress;

UPDATE housing
SET PtyCity = trim(substring(PropertyAddress, POSITION(',' IN PropertyAddress)+1));

# Now for the Land Owners

SELECT 	OwnerAddress,
		trim(SUBSTRING_INDEX(OwnerAddress,',', 1)) AS OwrAddress,
		trim(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2), ',', -1)) AS OwnerCity,
        trim(SUBSTRING_INDEX(OwnerAddress,',', -1)) AS OwnerState
FROM housing;

ALTER TABLE housing
ADD OwrAddress VARCHAR(100) AFTER OwnerAddress,
ADD OwnerCity VARCHAR(100) AFTER OwrAddress,
ADD OwnerState VARCHAR(100) AFTER OwnerCity;

UPDATE housing
SET OwrAddress = trim(SUBSTRING_INDEX(OwnerAddress,',', 1)),
	OwnerCity = trim(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2), ',', -1)),
    OwnerState = trim(SUBSTRING_INDEX(OwnerAddress,',', -1));

#--------------------------------------------------------------------------------------------------
# Stardardize the SoldAsVacant field, change the Y and N to Yes and No

# We check that the most popular option is Yes and No, so it's more efficient to change the 'Y's and 'N's
SELECT distinct SoldAsVacant, count(SoldAsVacant)
FROM housing
Group By SoldAsVacant;

UPDATE housing
SET SoldAsVacant = CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END;

#--------------------------------------------------------------------------------------------------    
# Removing the Duplicate rows based on some fields
# If the data from these fields is the same on more than one row then it will be removed

WITH TimesRepeatedCTE AS (
SELECT 	*, ROW_NUMBER() OVER (
		PARTITION BY 	ParcelID,
						LandUse,
                        PropertyAddress,
                        SaleDate,
                        SalePrice,
                        LegalReference
                        ORDER BY
							UniqueID) AS Times_repeated
FROM housing
)
DELETE
FROM housing
USING housing JOIN TimesRepeatedCTE tr
	ON housing.UniqueID = tr.UniqueID
WHERE Times_repeated > 1;

#--------------------------------------------------------------------------------------------------    
# Removing Unused Columns

ALTER TABLE housing
	DROP COLUMN PropertyAddress,
	DROP COLUMN OwnerAddress,
	DROP COLUMN TaxDistrict;

# Renaming some columns so that they make sense
ALTER TABLE housing
	RENAME COLUMN PtyAddress TO PropertyAddress,
    RENAME COLUMN PtyCity TO PropertyCity,
    RENAME COLUMN OwrAddress TO OwnerAddress;
    
SELECT * FROM housing;
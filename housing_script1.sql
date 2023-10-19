/*
Data Cleaning Project Using MySQL
 */

select * from housing_data;

-- ---------------------------------------------- --
-- Standardize SaleDate Column

Alter table housing_data
add SaleDate_fixed Date
after SaleDate;

select STR_TO_DATE(SaleDate, "%M %d, %Y")
from housing_data;

update housing_data
set SaleDate_fixed = STR_TO_DATE(SaleDate, "%M %d, %Y");

select SaleDate, SaleDate_fixed from housing_data
order by SaleDate_fixed;

Alter table housing_data
drop column SaleDate;
Alter table housing_data
Rename column SaleDate_fixed to SaleDate;

-- ---------------------------------------------- --
-- Populate Property Address Data

select *
from housing_data
where PropertyAddress is null;

-- ParcelID is the same for the same propertyAddress
-- For a Null address with the same ParcelID as a non-Null address, set them to be the same
-- Use a Self INNER JOIN WHERE ParcelID is the same, and UniqueID is not

select t1.ParcelID, t1.PropertyAddress,
       t2.ParcelID , t2.PropertyAddress,
       IFNULL(t1.PropertyAddress, t2.PropertyAddress)
from housing_data as t1
inner join housing_data as t2
on t1.ParcelID = t2.ParcelID
and t1.UniqueID != t2.UniqueID
where t1.PropertyAddress is null;


update housing_data t1
inner join housing_data as t2
on t1.ParcelID = t2.ParcelID
and t1.UniqueID != t2.UniqueID
set t1.PropertyAddress= IFNULL(t1.PropertyAddress, t2.PropertyAddress)
where t1.PropertyAddress is null;

-- ---------------------------------------------- --
-- Property Address gets separated into Columns

alter table housing_data
add PropertyAddressStreet varchar(255)
after PropertyAddress;
alter table housing_data
add PropertyAddressCity varchar(255)
after PropertyAddressStreet;


update housing_data
set PropertyAddressStreet = SUBSTRING(PropertyAddress, 1, LOCATE(",", PropertyAddress)-1);
update housing_data
set PropertyAddressCity = SUBSTRING(PropertyAddress, LOCATE(",", PropertyAddress)+1);


-- ---------------------------------------------- --
-- Owner Address gets separated into Columns

alter table housing_data
add OwnerAddressStreet varchar(255)
after OwnerAddress;
alter table housing_data
add OwnerAddressCity varchar(255)
after OwnerAddressStreet;
alter table housing_data
add OwnerAddressState varchar(255)
after OwnerAddressCity;

update housing_data
set OwnerAddressStreet = substring_index(OwnerAddress, ",", 1);
update housing_data
set OwnerAddressCity = substring_index(substring_index(OwnerAddress, ",", -2), ",", 1);
update housing_data
set OwnerAddressState = substring_index(OwnerAddress, ",", -1);

-- ---------------------------------------------- --
-- Standardize "Yes" and "No" in SoldAsVacant Column

select distinct (SoldAsVacant)
from housing_data hd ;

select 
case
	when SoldAsVacant = "N" then "No"
	when SoldAsVacant = "Y" then "Yes"
	else SoldAsVacant
end as sav
from housing_data hd ;

update housing_data 
set SoldAsVacant =
case
	when SoldAsVacant = "N" then "No"
	when SoldAsVacant = "Y" then "Yes"
	else SoldAsVacant
end;

-- ---------------------------------------------- --
-- Removing Duplicates


with duplCTE as (
select *,
     row_number() OVER(
     partition by ParcelID,
                  PropertyAddress,
                  SaleDate,
                  SalePrice,
                  LegalReference
                  order by UniqueID
                  ) as row_num 
from housing_data )
select * from duplCTE
where row_num > 1;


with duplCTE as (
select *,
     row_number() OVER(
     partition by ParcelID,
                  PropertyAddress,
                  SaleDate,
                  SalePrice,
                  LegalReference
                  order by UniqueID
                  ) as row_num 
from housing_data )
DELETE from housing_data
using duplCTE inner join housing_data
on duplCTE.UniqueID = housing_data.UniqueID
where row_num > 1;

-- ---------------------------------------------- --
-- Remove Unused Columns: PropertyAddress, OwnerAddress, TaxDistrict

alter table housing_data
drop column TaxDistrict;

select * from housing_data hd ;
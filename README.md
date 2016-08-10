#dob-permit-geocode

This is a set of scripts to transform the publicly available NYC DOB permits dataset into a spatial dataset by adding a point geometry to each record.

##Methodology

The source dataset is transformed with the following steps:

- Download the source dataset as CSV from [data.cityofnewyork.us](https://nycopendata.socrata.com/api/views/ipu4-2q9a/rows.csv?accessType=DOWNLOAD) (Approximately 546k rows as of 2 June 2016)

- Approximately 19 rows from the source CSV contain strange pipe-delimited values, so sed is used to get rid of rows with pipe characters

- Create a new PostgreSQL table from the CSV

- Assemble a bbl column from the borough, block, and lot columns

- Join with mappluto 16v1 on bbl, append parcel centroids to permits.   

- Join with building footprints on bin, append parcel centroids to permits.  96% of the data are matched using mappluto and buildingfootprints.

- Join with the geosupport lookup table (this table contains the results of running all rows that do not match mappluto or building footprints through the geoclient API.  The results are logged in a table so we can join them without hitting the API every time.) 13k rows are matched using the geosupport lookup table as of 2 June 2016

- Any rows that still do not match are run through the geoclient API, if they return lat/lon, those details are added to the geosupport lookup table

- Join with the geosupport lookup table AGAIN to capture any new matches.

- Drop rows that are still unmatched (~975 as of 2 June 2016) .17% of original.  Not bad.

- TODO: Create an output file of unmatched BBLs so that DOB and DCP can figure out where the discrepancies are.

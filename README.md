#dob-permit-geocode

This is a set of scripts to transform the publicly available NYC DOB permits dataset into a spatial dataset by adding a point geometry to each record.

The script runs every 24 hours and produces 3 output files:

- [dob_permits.shp](http://dob.reallysimpleopendata.com/dob_permits.zip) - A shapefile with all original fields plus point geometries.  (permits that could not be geocoded by any of the methods below are excluded)
- [failed.csv](http://dob.reallysimpleopendata.com/failed.csv) - A csv export of all rows that could not be geocoded.  This should be useful to both DOB and DCP for figuring out why these addresses do not geocode.
- [lastrun.txt](http://dob.reallysimpleopendata.com/lastrun.txt) - A text file with the a timestamp of the last time the script was run, for reference.  (should be midnight GMT-5)

##Methodology

The source dataset is processed through the following steps:

- Download the source dataset as CSV from [data.cityofnewyork.us](https://nycopendata.socrata.com/api/views/ipu4-2q9a/rows.csv?accessType=DOWNLOAD) (Approximately 546k rows as of 2 June 2016)

- Approximately 19 rows from the source CSV contain strange pipe-delimited values, so sed is used to get rid of rows with pipe characters

- Create a new PostgreSQL table from the CSV

- Assemble a bbl column from the borough, block, and lot columns

- Join with mappluto 16v1 on bbl, append parcel centroids to permits.   

- Join with building footprints on bin, append parcel centroids to permits.  96% of the data are matched using mappluto and buildingfootprints.

- Join with the geosupport lookup table (this table contains the results of running all rows that do not match mappluto or building footprints through the geoclient API.  The results are logged in a table so we can join future runs against them without hitting the geoclient API more than we have to) 13k rows are matched using the geosupport lookup table as of 2 June 2016

- Any rows that still do not match are run through the geoclient API, if they return lat/lon, those details are added to the geosupport lookup table

- Join with the geosupport lookup table AGAIN to capture any new matches.

- Drop rows that are still unmatched (~975 as of 2 June 2016) .17% of original.  Not bad.

#TODO:
-Create a nice landing page
-Export a few more "slices" of the dataset, by community district, nta, etc.  Or perhaps just the previous 30-60-90-days.  


#Docker
- The `Dockerfile` creates an image with everything the script needs to run, including node, zip/unzip, psql, gdal tools, etc.  It does not include a database, and we are currently using the [mdillon/postgis](https://hub.docker.com/r/mdillon/postgis/) image to spin up a separate postgis container.


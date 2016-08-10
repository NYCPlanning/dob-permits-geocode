echo Rows in raw data:
wc -l < temp/dob_permits.csv
sed '/|/d' temp/dob_permits.csv > temp/dob_permits_cleaned.csv

echo Rows after removing invalid lines:
wc -l < temp/dob_permits_cleaned.csv

echo Creating table
psql $DATABASE_URL -f create.sql

echo Loading data
psql $DATABASE_URL  -c "\COPY dob_permits FROM 'temp/dob_permits_cleaned.csv' CSV HEADER;"  

echo Assembling bbl column
psql $DATABASE_URL -f makebbl.sql

echo Looking up BBLs in PLUTO and BINs in building footprints
psql $DATABASE_URL -f geocode.sql

echo Looking up addresses in geosupport results table
psql $DATABASE_URL -f gslookup.sql

echo Running anything not yet geocoded through geosupport 
node geocode.js
echo Looking up addresses in geosupport results table again
psql $DATABASE_URL -f gslookup.sql 

echo Exporting csv of failed geocodes
psql $DATABASE_URL -c "\COPY (SELECT * FROM dob_permits WHERE geom IS NULL) To '../output/failed.csv' DELIMITER ',' CSV HEADER;"


echo Dropping null geometries
psql $DATABASE_URL  -f dropnulls.sql

echo Exporting to shapefile
ogr2ogr -f "ESRI Shapefile" ../output/dob_permits.shp PG:"$DATABASE_URL" -sql "SELECT * FROM dob_permits"
echo zipping shapefile
zip -r ../output/dob_permits.zip ../output/dob_permits.*

echo Dropping a timestamp
date '+%m/%d/%y %H:%M:%S' > ../output/lastrun.txt

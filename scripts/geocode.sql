SELECT AddGeometryColumn('dob_permits', 'geom', 4326, 'POINT',2);
UPDATE dob_permits SET geom = null;
UPDATE dob_permits a
SET    geom = ST_Centroid(b.geom)
FROM   dcp_mappluto b
WHERE  a.bbl = b.bbl;

UPDATE dob_permits a
SET    geom = ST_Centroid(b.geom)
FROM   doitt_buildingfootprints b
WHERE  a.binnumber::numeric = b.bin
AND a.geom IS NULL;



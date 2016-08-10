UPDATE dob_permits a
SET    geom = ST_Centroid(b.geom)
FROM   dob_permitsnotfound b
WHERE  (a.binnumber::numeric = b.sourcebin
OR (a.streetname = b.sourcestreetname) AND (a.housenumber = b.sourcehousenumber))
AND a.geom IS NULL;

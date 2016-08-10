var pgp = require('pg-promise')(),
  request = require('request'),
  Mustache = require('mustache');

require('dotenv').config();

var config = process.env.DATABASE_URL;

var db = pgp(config);

var i=0;
var nullGeomResults;
//query the db for null geometries

var nullGeomQuery = 'SELECT DISTINCT bbl, binnumber, borough, housenumber, streetname FROM dob_permits WHERE geom IS NULL';

var geoclientTemplate = 'https://api.cityofnewyork.us/geoclient/v1/address.json?houseNumber={{housenumber}}&street={{{streetname}}}&borough={{borough}}&app_id={{app_id}}&app_key={{app_key}}';

db.any(nullGeomQuery)
  .then(function (data) {
    nullGeomResults = data

    console.log('Found ' + nullGeomResults.length + ' null geometries in dob_permits')
    addressLookup(nullGeomResults[i]);
  });


function addressLookup(row) {
  console.log('Looking up address', row.borough.trim(), row.housenumber.trim(), row.streetname.trim(), row.binnumber)

      var apiCall = Mustache.render(geoclientTemplate, {
        housenumber: row.housenumber.trim(),
        streetname: row.streetname.trim(),
        borough: row.borough.trim(),
        app_id: process.env.GEOCLIENT_APP_ID,
        app_key: process.env.GEOCLIENT_APP_KEY
      })

      console.log(apiCall);

      request(apiCall, function(err, response, body) {
          var data = JSON.parse(body);
          data = data.address;

          appendToNotfound(data, row);
      })
}


function appendToNotfound(data, row) {
  
  var insertTemplate = 'INSERT INTO dob_permitsnotfound (geom, sourcehousenumber, sourcestreetname, sourcebin, sourcebbl, responsebbl) VALUES (ST_SetSRID(ST_GeomFromText(\'POINT({{longitude}} {{latitude}})\'),4326), \'{{sourcehousenumber}}\', \'{{sourcestreetname}}\', {{sourcebin}},{{sourcebbl}},{{responsebbl}})'
 
  if(data.latitude && data.longitude) {
    console.log('Writing to dob_permitsnotfound', data.bbl);

    var insert = Mustache.render(insertTemplate, {
      latitude: data.latitude,
      longitude: data.longitude,
      sourcehousenumber: row.housenumber.trim(),
      sourcestreetname: row.streetname.trim(),
      sourcebin: row.binnumber,
      sourcebbl: row.bbl,
      responsebbl: (data.bbl === undefined) ? 'NULL' : data.bbl
    })

    console.log(insert);

    db.none(insert)
    .then(function(data) {
      i++;
      console.log(i,nullGeomResults.length)
      if (i<nullGeomResults.length) {
         addressLookup(nullGeomResults[i])
      } else {
        console.log('Done!')
      }
      
    })
    .catch(function(err) {
      console.log(err);
    })

  } else {
    console.log('Response did not include a lat/lon, skipping...');
    i++;
        console.log(i,nullGeomResults.length)
        if (i<nullGeomResults.length) {
           addressLookup(nullGeomResults[i])
        }
  }
}







// ! Parameters
var width = window.innerWidth * 0.8 - 20;
var height = width * 0.8;
if (width > 900) {
  var width = 900;
  var height = width * .6;
}
var width_margin = width * 0.15;

$.ajax({
    url: "./outputs/England_pcn_summary_text_1.json",
    dataType: "json",
    async: false,
    success: function(data) {
        England_pcn_summary_text_1 = data;},
    error: function (xhr) {
      alert('England Text not available - pcn' + xhr.statusText);
    },
  });

d3.select("#pcn_summary_text_1").html(function (d) {
    return (
        England_pcn_summary_text_1
    );
  });
  
$.ajax({
   url: "./outputs/Sussex_pcn_summary_text_1.json",
   dataType: "json",
   async: false,
   success: function(data) {
       Sussex_pcn_summary_text_1 = data;},
   error: function (xhr) {
     alert('Sussex PCN Text not available - pcn' + xhr.statusText);
   },
});

d3.select("#pcn_summary_text_2").html(function (d) {
  return (
      Sussex_pcn_summary_text_1
  );
});


$.ajax({
  url: "./outputs/GP_location_data.json",
  dataType: "json",
  async: false,
  success: function(data) {
      GP_location = data;},
  error: function (xhr) {
    alert('Sussex GP location data not available - pcn' + xhr.statusText);
  },
});

// PCN summary

$.ajax({
    url: "./outputs/Sussex_PCN_summary_df.json",
    dataType: "json",
    async: false,
    success: function(data) {
        Sussex_pcn_summary_df = data;},
    error: function (xhr) {
      alert('Sussex PCN summary not available - pcn' + xhr.statusText);
    },
 });
 
 var PCNs = d3
 .map(Sussex_pcn_summary_df, function (d) {
   return d.PCN_Name;
 })
 .keys();


// This will be to highlight a particular line on the figure (and show some key figures)
d3.select("#select_pcn_1_button")
  .selectAll("myOptions")
  .data(PCNs)
  // .data(['Cissbury Integrated Care PCN'])
  .enter()
  .append("option")
  .text(function (d) {
    return d;
  })
  .attr("value", function (d) {
    return d;
  });

var Selected_pcn_area_option = d3
 .select("#select_pcn_1_button")
 .property("value");

// Map

// function reg_pop_style(feature) {
//     return {
//       fillColor: 'purple',
//       color: 'purple',
//       weight: 1,
//       fillOpacity: 0.25
//      }
//    } 
 
var PCN_ReachLSOA11_geojson = $.ajax({
    url: "./outputs/total_pcn_lsoa_level_reach_plus_five.geojson",
    dataType: "json",
    success: console.log("LSOA (2011) boundary data for PCN reach successfully loaded."),
    error: function (xhr) {
      alert(xhr.statusText);
    },
  });


  function getpatient_countColour(d) {
    return d > 2000 ? '#440154' :
           d > 1800  ? '#482173' :
           d > 1600  ? '#433E85' :
           d > 1200  ? '#38598C' :
           d > 1000  ? '#2D708E' :
           d > 800  ? '#25858E' :
           d > 600  ? '#1E9B8A' :
           d > 400  ? '#2BB07F' :
           d > 200  ? '#51C56A' :
           d > 100  ? '#85D54A' :
           d > 50  ? '#C2DF23' :
           d >= 5   ? '#FDE725' :
           '#fcb045' ;
    }
  
  // Create a function to add stylings to the polygons in the leaflet map
  function reg_pop_style(feature) {
    return {
      fillColor: getpatient_countColour(feature.properties.Patients),
      // color: getpatient_countColour(feature.properties.Patients),
      color: 'black',
      weight: 1,
      fillOpacity: 0.85,
    };
  }

// Generic Map parameters

// This tile layer is black and white
var tileUrl = "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png";
// Define an attribution statement to go onto our maps
var attribution =
  '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Contains Ordnance Survey data © Crown copyright and database right 2022';

// ! Load single PCN reach

// Create a leaflet map (L.map) in the element map_1_id
var map_lsoa_pcn_reach = L.map("map_pcn_reach_lsoa");

// add the background and attribution to the map
L.tileLayer(tileUrl, { attribution })
.addTo(map_lsoa_pcn_reach);

// Specify that this code should run once the PCN_geojson data request is complete
$.when(PCN_ReachLSOA11_geojson).done(function () {

pcn_x_summary = Sussex_pcn_summary_df.filter(function (d) {
        return d.PCN_Name == Selected_pcn_area_option;
      });

  var pcn_x_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === Selected_pcn_area_option; }
        , style: reg_pop_style})
       .addTo(map_lsoa_pcn_reach)
       .bindPopup(function (layer) {
          return (
            '2011 LSOA: <Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Number of patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / pcn_x_summary[0].Patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (' + 
            d3.format(',.0f')(pcn_x_summary[0].Patients) +
            ' patients).'
          );
       })
      
        map_lsoa_pcn_reach.fitBounds(pcn_x_boundary.getBounds());
      
// var baseMaps_map_population = {
//   'Show Lower layer super output areas (LSOAs)': lsoa2021_boundary,
//    };

//  L.control
//  .layers(baseMaps_map_population, null, { collapsed: false, position: 'topright'})
//  .addTo(map_lsoa_pcn_reach);

 var legend_map_population = L.control({position: 'bottomright'});
  
 legend_map_population.onAdd = function (map_population) {
     var div = L.DomUtil.create('div', 'info legend'),
        grades = [5, 50, 100, 200, 400, 800, 1000, 1200, 1400, 1600, 1800, 2000],
       labels = ['<b>Patients registered<br>to the PCN</b>'];
    //  loop through our density intervals and generate a label with a colored square for each interval
     for (var i = 0; i < grades.length; i++) {
         div.innerHTML +=
         labels.push(
            '<i style="background:' + getpatient_countColour(grades[i] + 1) + '"></i> ' +
            d3.format(',.0f')(grades[i]) + (grades[i + 1] ? '&ndash;' + d3.format(',.0f')(grades[i + 1]) + '' : '+'));
    }
    div.innerHTML = labels.join('<br>');
    return div;
 };
 
legend_map_population.addTo(map_lsoa_pcn_reach);

  });
  

// Specify that this code should run once the PCN_geojson data request is complete
// $.when(PCN_ReachLSOA11_geojson).done(function () {

  Local_GP_location = GP_location.filter(function (d) {
          return d.PCN_Name == Selected_pcn_area_option;
        });

// TODO fix gp markers
// This loops through the dataframe and plots a marker for every record.

var pane1 = map_lsoa_pcn_reach.createPane('markers1');

for (var i = 0; i < Local_GP_location.length; i++) {
gps = new L.circleMarker([Local_GP_location[i]['latitude'], Local_GP_location[i]['longitude']],
     {
     pane: 'markers1',
     radius: 8,
     weight: .5,
     fillColor: '#c90076',
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + Local_GP_location[i]['ODS_Code'] + ' ' + Local_GP_location[i]['ODS_Name'] + '</Strong><br><br>This practice is part of the ' + Local_GP_location[i]['PCN_Name'] + '. There are <Strong>' + d3.format(',.0f')(Local_GP_location[i]['Patients']) + '</Strong> patients registered to this practice.')
   .addTo(map_lsoa_pcn_reach) 
  }

  // });

d3.select("#select_pcn_1_button").on("change", function (d) {

var Selected_pcn_area_option = d3
 .select("#select_pcn_1_button")
 .property("value");

 console.log('something is happening')

//  TODO I think this might be to do with the layer being out of scope - try adding a generic layer outside of the $when() call and if that works try to get around the $when 

//! this does work!! we need to get the boundary drawing out of the scope of the $when data is ready
 map_lsoa_pcn_reach.removeLayer(gps)

 // Create a leaflet map (L.map) in the element map_1_id
// var map_lsoa_pcn_reach = L.map("map_pcn_reach_lsoa");

// add the background and attribution to the map
L.tileLayer(tileUrl, { attribution })
.addTo(map_lsoa_pcn_reach);
 });
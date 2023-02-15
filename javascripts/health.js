// ! Parameters
var width = window.innerWidth * 0.8 - 20;
var height = width * 0.8;
if (width > 900) {
  var width = 900;
  var height = width * .6;
}
var width_margin = width * 0.15;


// ! Load data
$.ajax({
  url: "./outputs/LSOA_PCN_lookup_data.json",
  dataType: "json",
  async: false,
  success: function(data) {
    lsoa_to_pcn_data = data;
   console.log('LSOA to PCN data successfully loaded.')},
  error: function (xhr) {
    alert('LSOA to PCN data not loaded - ' + xhr.statusText);
  },
});

$.ajax({
  url: "./outputs/LSOA_health_data.json",
  dataType: "json",
  async: false,
  success: function(data) {
    lsoa_health_data = data;
   console.log('LSOA health data successfully loaded.')},
  error: function (xhr) {
    alert('LSOA health not loaded - ' + xhr.statusText);
  },
});

// $.ajax({
//   url: "./outputs/LSOA_health_data_plan_B.json",
//   dataType: "json",
//   async: false,
//   success: function(data) {
//     lsoa_health_data = data;
//    console.log('LSOA health data successfully loaded.')},
//   error: function (xhr) {
//     alert('LSOA health not loaded - ' + xhr.statusText);
//   },
// });

// TODO join LSOA PCN data to the lsoa_health_data object
lsoa_health_data.forEach(function(main_item) {
  var result = lsoa_to_pcn_data.filter(function(lookup_item) {
      return lookup_item.LSOA21CD === main_item.LSOA21CD;
  });
  main_item.PCN_Name = (result[0] !== undefined) ? result[0].PCN_Name : null;
  main_item.LTLA = (result[0] !== undefined) ? result[0].LTLA : null;
});

// Health
var health_df =  lsoa_health_data.filter(function (d) {
  return d.Topic == 'Health';
});

var very_good_good_health_df =  lsoa_health_data.filter(function (d) {
  return d.Topic == 'Health' && d.Category == 'Good or very good health';
});

// TODO create a PCN (and LTLA) version of these datasets

// TODO this might be better transposed (then youd have one row with bad/very bad, fair, good/very good and denominator)

var PCN_health_df = d3.nest()
  .key(function(d){
  return d.PCN_Name})
  .rollup(function(item){
  return {Numerator: d3.sum(item, function(d){
      return d.Numerator    
  }), 
          Denominator : d3.sum(item, function(d){
      return d.Denominator    
  })};
}).entries(very_good_good_health_df)
.map(function(d){
  return { 
    PCN: d.key,
    Numerator: d.value.Numerator,
    Proportion: d.value.Numerator / d.value.Denominator,
    Denominator: d.value.Denominator};
});

// Disability
var disability_df =  lsoa_health_data.filter(function (d) {
  return d.Topic == 'Disability';
});

// console.log(disability_df)

// Provision of unpaid care 
var unpaid_care_df =  lsoa_health_data.filter(function (d) {
  return d.Topic === 'Unpaid care' &&
         d.Category === 'Provides some care';
});

// console.log(unpaid_care_df)

var PCN_unpaid_care_df = d3.nest()
  .key(function(d){
  return d.PCN_Name})
  .rollup(function(item){
  return {Numerator: d3.sum(item, function(d){
      return d.Numerator    
  }), 
          Denominator : d3.sum(item, function(d){
      return d.Denominator    
  })};
}).entries(unpaid_care_df)
.map(function(d){
  return { 
    PCN: d.key,
    Numerator: d.value.Numerator,
    Proportion: d.value.Numerator / d.value.Denominator,
    Denominator: d.value.Denominator};
});

// console.log(unpaid_care_df)
 
// Tables

// ! Render LTLA table on load
window.onload = () => {
  loadTable_health_PCN_summary(PCN_health_df);
  loadTable_unpaid_care_PCN_summary(PCN_unpaid_care_df);
  // loadTable_disability_PCN_summary(ltla_pop_summary_data);
};

function loadTable_health_PCN_summary(PCN_health_df) {
  const tableBody = document.getElementById("table_pcn_health_1_body");
  var dataHTML = "";

  for (let item of PCN_health_df) {
    dataHTML += `<tr><td>${item.PCN}</td><td>${d3.format(",.0f")(item.Numerator)}</td><td>${d3.format('.1%')(item.Numerator/item.Denominator)}</td><td>${d3.format(",.0f")(item.Denominator)}</td></tr>`;
  }
  tableBody.innerHTML = dataHTML;
}

function loadTable_unpaid_care_PCN_summary(PCN_unpaid_care_df) {
  const tableBody = document.getElementById("table_pcn_unpaid_care_1_body");
  var dataHTML = "";

  for (let item of PCN_unpaid_care_df) {
    dataHTML += `<tr><td>${item.PCN}</td><td>${d3.format(",.0f")(item.Numerator)}</td><td>${d3.format('.1%')(item.Numerator/item.Denominator)}</td><td>${d3.format(",.0f")(item.Denominator)}</td></tr>`;
  }
  tableBody.innerHTML = dataHTML;
}

// Maps - 

var LSOA21_geojson_health = $.ajax({
  url: "./outputs/sussex_2021_lsoas_health.geojson",
  dataType: "json",
  success: console.log("LSOA (2021) health geojson data successfully loaded."),
  error: function (xhr) {
    alert(xhr.statusText);
  },
});

var LTLA_geojson = $.ajax({
  url: "./outputs/sussex_ltlas.geojson",
  dataType: "json",
  success: console.log("LTLA boundary data successfully loaded."),
  error: function (xhr) {
    alert(xhr.statusText);
  },
});

// function get_health_proportion_colour(d) {
//   return d > .9 ? '#6f6f93' :
//          d > .85  ? '#8d8d98' :
//          d > .8  ? '#a4a49d' :
//          d > .75 ? '#b9b9a1' :
//          d > .7   ? '#cdcda4' :
//          d > .65   ? '#e0e0a6' :
//          '#f3f3a7' ;
// }

function get_health_proportion_colour(d) {
  return d > .9 ? '#b69fd6' :
         d > .85  ? '#bfb2d6' :
         d > .8  ? '#cedbbb' :
         d > .75 ? '#d7e4bf' :
         d > .7   ? '#cdcda4' :
         d > .65   ? '#e0e0a6' :
         '#f3f3a7' ;
}


function get_health_proportion_legend_colour(d) {
  return d > 90 ? '#b69fd6' :
         d > 85  ? '#bfb2d6' :
         d > 80  ? '#cedbbb' :
         d > 75 ? '#d7e4bf' :
         d > 70   ? '#cdcda4' :
         d > 65   ? '#e0e0a6' :
         '#f3f3a7' ;
}

// function get_health_proportion_colour(d) {
//   return d > .9 ? '#' :
//          d > .85  ? '#fde0dd' :
//          d > .8  ? '#fcc5c0' :
//          d > .75 ? '#f768a1' :
//          d > .7   ? '#dd3497' :
//          d > .65   ? '#ae017e' :
//          d > .6   ? '#7a0177' :
//          d > .55   ? '#49006a' :
//          '#000044' ;
// }

function get_bad_health_proportion_colour(d) {
  return d > .175 ? '#081d58' :
         d > .15  ? '#253494' :
         d > .125  ? '#225ea8' :
         d > .1 ? '#1d91c0' :
         d > .075   ? '#41b6c4' :
         d > .05   ? '#7fcdbb' :
         d > .025   ? '#c7e9b4' :
         '#edf8b1' ;
}

function get_bad_health_proportion_legend_colour(d) {
  return d > 17.5 ? '#081d58' :
         d > 15  ? '#253494' :
         d > 12.5  ? '#225ea8' :
         d > 10 ? '#1d91c0' :
         d > 7.5   ? '#41b6c4' :
         d > 5   ? '#7fcdbb' :
         d > 2.5   ? '#c7e9b4' :
         '#edf8b1' ;
}

function ltla_colours(feature) {
  return {
   //  fillColor: '#000000',
    color: '#000000',
    weight: 2,
    fillOpacity: 0
  }
}

// Generic Map parameters
// Define the background tiles for our maps 
// This tile layer is coloured
// var tileUrl = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";

// Specify that this code should run once the PCN_geojson data request is complete
$.when(LSOA21_geojson_health).done(function () {

// This tile layer is black and white
var tileUrl = "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png";
// Define an attribution statement to go onto our maps
var attribution =
  '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Contains Ordnance Survey data © Crown copyright and database right 2022';

function gvg_style(feature) {
  return {
    fillColor: get_health_proportion_colour(feature.properties.very_good_good_proportion),
    color: get_health_proportion_colour(feature.properties.very_good_good_proportion),
    // fillColor: '#f4365f',
    // color: '#c9c9c9',
    weight: 1,
    fillOpacity: 0.85,
  };
}

function bvb_style(feature) {
  return {
    fillColor: get_bad_health_proportion_colour(feature.properties.very_bad_bad_proportion),
    color: get_bad_health_proportion_colour(feature.properties.very_bad_bad_proportion),
    // fillColor: '#f4365f',
    // color: '#c9c9c9',
    weight: 1,
    fillOpacity: 0.85,
  };
}

  // Create a leaflet map (L.map) in the element map_general_health
  var map_general_health = L.map("map_general_health_id");
  
  // add the background and attribution to the map
  L.tileLayer(tileUrl, { attribution })
  .addTo(map_general_health);
  
  var lsoa2021_good_very_good = L.geoJSON(LSOA21_geojson_health.responseJSON, { style: gvg_style})
   .bindPopup(function (layer) {
      return (
        '2021 LSOA: <Strong>' +
        layer.feature.properties.LSOA21CD +
        " (" +
        layer.feature.properties.LSOA21NM +
        ')</Strong><br>Number of residents reporting good or very good health: <Strong>' +
        d3.format(',.0f')(layer.feature.properties.very_good_good_numerator) +
        '</Strong><br>Proportion of residents reporting good or very good health: <Strong>' +
        d3.format('.1%')(layer.feature.properties.very_good_good_proportion) +
        '</Strong>.'
      );
   })
   .addTo(map_general_health);

   var lsoa2021_bad_very_bad = L.geoJSON(LSOA21_geojson_health.responseJSON, { style: bvb_style})
   .bindPopup(function (layer) {
      return (
        '2021 LSOA: <Strong>' +
        layer.feature.properties.LSOA21CD +
        " (" +
        layer.feature.properties.LSOA21NM +
        ')</Strong><br>Number of residents reporting bad or very bad health: <Strong>' +
        d3.format(',.0f')(layer.feature.properties.very_bad_bad_numerator) +
        '</Strong><br>Proportion of residents reporting bad or very bad health: <Strong>' +
        d3.format('.1%')(layer.feature.properties.very_bad_bad_proportion) +
        '</Strong>.'
      );
   })
  
  var ltla_boundary = L.geoJSON(LTLA_geojson.responseJSON, { style: ltla_colours })
  .bindPopup(function (layer) {
     return (
       "Local authority: <Strong>" +
       layer.feature.properties.LAD22NM //+
     );
  });
  
  map_general_health.fitBounds(lsoa2021_good_very_good.getBounds());
    
  var legend_good_health_map = L.control({position: 'bottomleft'});
    
   legend_good_health_map.onAdd = function (map_general_health) {
        var div = L.DomUtil.create('div', 'info legend'),
           grades = [0, 65, 70, 75, 80, 85, 90],
           labels = ['<b>Proportion of residents<br>self-reporting good<br>or very good health</b>'];
   
       // loop through our density intervals and generate a label with a colored square for each interval
       for (var i = 0; i < grades.length; i++) {
           div.innerHTML +=
           labels.push(
               '<i style="background:' + get_health_proportion_legend_colour(grades[i] + 1) + '"></i> ' +
               d3.format(',.0f')(grades[i]) + (grades[i + 1] ? '&ndash;' + d3.format(',.0f')(grades[i + 1]) + '%' : '%+'));
       }
       div.innerHTML = labels.join('<br>');
       return div;
   };
   
   legend_good_health_map.addTo(map_general_health);

   
  var legend_bad_health_map = L.control({position: 'bottomright'});
    
  legend_bad_health_map.onAdd = function (map_general_health) {
       var div = L.DomUtil.create('div', 'info legend'),
          grades = [0, 2.5, 5, 7.5, 10, 12.5, 15, 17.5],
          labels = ['<b>Proportion of residents<br>self-reporting bad<br>or very bad health</b>'];
  
      // loop through our density intervals and generate a label with a colored square for each interval
      for (var i = 0; i < grades.length; i++) {
          div.innerHTML +=
          labels.push(
              '<i style="background:' + get_bad_health_proportion_legend_colour(grades[i] + 1) + '"></i> ' +
              d3.format(',.1f')(grades[i]) + (grades[i + 1] ? '&ndash;' + d3.format(',.1f')(grades[i + 1]) + '%' : '%+'));
      }
      div.innerHTML = labels.join('<br>');
      return div;
  };
  
  legend_bad_health_map.addTo(map_general_health);

 
   var baseMaps_map_population = {'Show good or very good health (LSOAs)': lsoa2021_good_very_good,
     'Show bad or very bad (LSOAs)': lsoa2021_bad_very_bad
     };
 
   var overlayMaps_map_population = {
     "Show Local Authorities": ltla_boundary
   };
   
    L.control
    .layers(baseMaps_map_population, overlayMaps_map_population, { collapsed: false, position: 'topright'})
    .addTo(map_general_health);
 
  
  });
  
  
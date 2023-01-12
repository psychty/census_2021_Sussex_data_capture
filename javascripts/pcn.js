// ! Parameters
var width = window.innerWidth * 0.8 - 20;
var height = width * 0.8;
if (width > 900) {
  var width = 900;
  var height = width * .6;
}
var width_margin = width * 0.15;
var gp_marker_colour = '#c90076'

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

 var PCN_ids = d3
 .map(Sussex_pcn_summary_df, function (d) {
   return d.PCN_Number;
 })
 .keys();

// We need a function to return our own PCN_ID (the number we've given to the PCN based on its row number in the dataframe in R).
var selected_pcn_id_lookup = d3
  .scaleOrdinal()
  .domain(PCNs)
  .range(PCN_ids);

d3.select("#select_pcn_x_button")
  .selectAll("myOptions")
  .data(PCNs)
  // .data(['Cissbury Integrated Care PCN', 'Haywards Heath Villages PCN'])
  .enter()
  .append("option")
  .text(function (d) {
    return d;
  })
  .attr("value", function (d) {
    return d;
  });

// Map
var PCN_ReachLSOA11_geojson = $.ajax({
    url: "./outputs/total_pcn_lsoa_level_reach_plus_five.geojson",
    dataType: "json",
    success: console.log("LSOA (2011) boundary data for PCN reach successfully loaded."),
    error: function (xhr) {
      alert(xhr.statusText);
    },
  });

$.when(PCN_ReachLSOA11_geojson).done(function () {

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

// ! Load PCN reach base map (this only needs to happen once)

// Create a leaflet map (L.map) in the element map_1_id
var map_lsoa_pcn_reach = L.map("map_pcn_reach_lsoa");

// add the background and attribution to the map
L.tileLayer(tileUrl, { attribution })
.addTo(map_lsoa_pcn_reach);

// // We use the same legend (and it is built independent of data) so add this now too.
var legend_map_population = L.control({position: 'bottomright'});
  
legend_map_population.onAdd = function () {
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

L.control.scale().addTo(map_lsoa_pcn_reach);

// ! filter chosen PCN LSOA data 

// This is what we'll need to update on select change

var Selected_pcn_area_option = d3
 .select("#select_pcn_x_button")
 .property("value");

var selected_pcn_id = 'pcn_' + selected_pcn_id_lookup(Selected_pcn_area_option) + '_group';

d3.select("#pcn_reach_title_1").html(function (d) {
  return (
   Selected_pcn_area_option +
      '; Registered population residential neighbourhoods (LSOAs); LSOAs with five or more registered patients.'
  );
});

pcn_x_summary = Sussex_pcn_summary_df.filter(function (d) {
  return d.PCN_Name == Selected_pcn_area_option;
});

// ! Build the 40 layers (one for each PCN, with lsoa layers and gp practices)


// for (var i = 1; i <= Sussex_pcn_summary_df.length; i++) {

//   this['pcn_' + i + '_group'] = L.layerGroup();
//   this['pcn_' + i] = PCNs[i - 1]
//   this['pcn_' + i + '_boundary'] = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
//            filter: function(feat) { return feat.properties.PCN_Name === this['pcn_' + i]; }
//           , style: reg_pop_style})
//         //  .addTo(pcn_x_boundary)
//          .bindPopup(function (layer) {
//             return (
//               '<Strong>' +
//               layer.feature.properties.LSOA11CD +
//               '</Strong><br><br>Patients registered to ' +
//               layer.feature.properties.PCN_Name +
//               ': <Strong>' +
//               d3.format(',.0f')(layer.feature.properties.Patients) +
//               '</Strong>.<br><br>This is <Strong>' +
//               d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
//               '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
//               d3.format(',.0f')(layer.feature.properties.Total_patients) +
//               '</Strong> patients).'
//             );
//          })
  
//   // Add this to the layerGroup      
//   this['pcn_' + i + '_boundary'].addTo(this['pcn_' + i + '_group'])
  
//   // filter GP markers
//   this['pcn_gp_location_' + i] = GP_location.filter(function (d) {
//     return d.PCN_Name == this['pcn_' + i];
//   });
  
//   // This loops through the Local_GP_location dataframe and plots a marker for every record.
//   for (var k = 0; k < this['pcn_gp_location_' + i].length; i++) {
//   new L.circleMarker([this['pcn_gp_location_' + i][k]['latitude'], this['pcn_gp_location_' + i][k]['longitude']],{
//        radius: 8,
//        weight: .5,
//        fillColor: gp_marker_colour,
//        color: '#000',
//        fillOpacity: 1})
//       .bindPopup('<Strong>' + 
//       this['pcn_gp_location_' + i][k]['ODS_Code'] + 
//       ' ' + 
//       this['pcn_gp_location_' + i][k]['ODS_Name'] + 
//       '</Strong><br><br>This practice is part of the ' + 
//       this['pcn_gp_location_' + i][k]['PCN_Name'] +
//       '. There are <Strong>' + 
//       d3.format(',.0f')(this['pcn_gp_location_' + i][k]['Patients']) + 
//       '</Strong> patients registered to this practice.' )
//      .addTo(this['pcn_' + i + '_group']) // These markers are directly added to the layer group
//     };
  
//   }
// console.log(this.pcn_1_group)

// this.pcn_1_group.addTo(map_lsoa_pcn_reach) // This is our first PCN we want to initialise on the page     


// ! PCN 1
pcn_1_group = L.layerGroup();
pcn_1 = PCNs[1 - 1]
pcn_1_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_1; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })

// Add this to the layerGroup      
pcn_1_boundary.addTo(pcn_1_group)

// filter GP markers
pcn_gp_location_1 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_1;
});

// This loops through the Local_GP_location dataframe and plots a marker for every record.
for (var i = 0; i < pcn_gp_location_1.length; i++) {
new L.circleMarker([pcn_gp_location_1[i]['latitude'], pcn_gp_location_1[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_1[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_1[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_1[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_1[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_1_group) // These markers are directly added to the layer group
  };

pcn_1_group.addTo(map_lsoa_pcn_reach) // This is our first PCN we want to initialise on the page     

// ! PCN 2 from two onwards we do not need to add this to the map
pcn_2_group = L.layerGroup();
pcn_2 = PCNs[2 - 1]
pcn_2_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_2; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_2_boundary.addTo(pcn_2_group)       
pcn_gp_location_2 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_2;
});

// This loops through the Local_GP_location dataframe and plots a marker for every record.
for (var i = 0; i < pcn_gp_location_2.length; i++) {
new L.circleMarker([pcn_gp_location_2[i]['latitude'], pcn_gp_location_2[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_2[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_2[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_2[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_2[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_2_group) // These markers are directly added to the layer group
  };

// ! PCN 3
pcn_3_group = L.layerGroup();
pcn_3 = PCNs[3 - 1]
pcn_3_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_3; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })

pcn_3_boundary.addTo(pcn_3_group)
pcn_gp_location_3 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_3;
});
for (var i = 0; i < pcn_gp_location_3.length; i++) {
new L.circleMarker([pcn_gp_location_3[i]['latitude'], pcn_gp_location_3[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_3[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_3[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_3[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_3[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_3_group) // These markers are directly added to the layer group
  };

// ! PCN 4
pcn_4_group = L.layerGroup();
pcn_4 = PCNs[4 - 1]
pcn_4_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_4; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })

// Add this to the layerGroup      
pcn_4_boundary.addTo(pcn_4_group)

pcn_gp_location_4 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_4;
});

// This loops through the Local_GP_location dataframe and plots a marker for every record.
for (var i = 0; i < pcn_gp_location_4.length; i++) {
new L.circleMarker([pcn_gp_location_4[i]['latitude'], pcn_gp_location_4[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_4[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_4[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_4[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_4[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_4_group) // These markers are directly added to the layer group
  };

  // ! PCN 5
  pcn_5_group = L.layerGroup();
  pcn_5 = PCNs[5 - 1]
  pcn_5_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
           filter: function(feat) { return feat.properties.PCN_Name === pcn_5; }
          , style: reg_pop_style})
        //  .addTo(pcn_x_boundary)
         .bindPopup(function (layer) {
            return (
              '<Strong>' +
              layer.feature.properties.LSOA11CD +
              '</Strong><br><br>Patients registered to ' +
              layer.feature.properties.PCN_Name +
              ': <Strong>' +
              d3.format(',.0f')(layer.feature.properties.Patients) +
              '</Strong>.<br><br>This is <Strong>' +
              d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
              '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
              d3.format(',.0f')(layer.feature.properties.Total_patients) +
              '</Strong> patients).'
            );
         })
  pcn_5_boundary.addTo(pcn_5_group)
  pcn_gp_location_5 = GP_location.filter(function (d) {
    return d.PCN_Name == pcn_5;
  });
  
  for (var i = 0; i < pcn_gp_location_5.length; i++) {
  new L.circleMarker([pcn_gp_location_5[i]['latitude'], pcn_gp_location_5[i]['longitude']],{
       radius: 8,
       weight: .5,
       fillColor: gp_marker_colour,
       color: '#000',
       fillOpacity: 1})
      .bindPopup('<Strong>' + 
      pcn_gp_location_5[i]['ODS_Code'] + 
      ' ' + 
      pcn_gp_location_5[i]['ODS_Name'] + 
      '</Strong><br><br>This practice is part of the ' + 
      pcn_gp_location_5[i]['PCN_Name'] +
      '. There are <Strong>' + 
      d3.format(',.0f')(pcn_gp_location_5[i]['Patients']) + 
      '</Strong> patients registered to this practice.' )
     .addTo(pcn_5_group) // These markers are directly added to the layer group
    };
  
// ! PCN 6
pcn_6_group = L.layerGroup();
pcn_6 = PCNs[6 - 1]
pcn_6_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_6; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_6_boundary.addTo(pcn_6_group)
pcn_gp_location_6 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_6;
});

for (var i = 0; i < pcn_gp_location_6.length; i++) {
new L.circleMarker([pcn_gp_location_6[i]['latitude'], pcn_gp_location_6[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_6[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_6[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_6[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_6[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_6_group) // These markers are directly added to the layer group
  };

// ! PCN 7
pcn_7_group = L.layerGroup();
pcn_7 = PCNs[7 - 1]
pcn_7_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_7; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_7_boundary.addTo(pcn_7_group)
pcn_gp_location_7 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_7;
});

for (var i = 0; i < pcn_gp_location_7.length; i++) {
new L.circleMarker([pcn_gp_location_7[i]['latitude'], pcn_gp_location_7[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_7[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_7[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_7[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_7[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_7_group) // These markers are directly added to the layer group
  };

// ! PCN 8
pcn_8_group = L.layerGroup();
pcn_8 = PCNs[8 - 1]
pcn_8_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_8; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_8_boundary.addTo(pcn_8_group)
pcn_gp_location_8 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_8;
});

for (var i = 0; i < pcn_gp_location_8.length; i++) {
new L.circleMarker([pcn_gp_location_8[i]['latitude'], pcn_gp_location_8[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_8[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_8[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_8[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_8[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_8_group) // These markers are directly added to the layer group
  };

// ! PCN 9
pcn_9_group = L.layerGroup();
pcn_9 = PCNs[9 - 1]
pcn_9_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_9; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_9_boundary.addTo(pcn_9_group)
pcn_gp_location_9 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_9;
});

for (var i = 0; i < pcn_gp_location_9.length; i++) {
new L.circleMarker([pcn_gp_location_9[i]['latitude'], pcn_gp_location_9[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_9[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_9[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_9[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_9[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_9_group) // These markers are directly added to the layer group
  };

// ! PCN 10
pcn_10_group = L.layerGroup();
pcn_10 = PCNs[10 - 1]
pcn_10_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_10; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_10_boundary.addTo(pcn_10_group)
pcn_gp_location_10 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_10;
});

for (var i = 0; i < pcn_gp_location_10.length; i++) {
new L.circleMarker([pcn_gp_location_10[i]['latitude'], pcn_gp_location_10[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_10[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_10[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_10[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_10[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_10_group) // These markers are directly added to the layer group
  };

// ! PCN 11
pcn_11_group = L.layerGroup();
pcn_11 = PCNs[11 - 1]
pcn_11_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_11; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_11_boundary.addTo(pcn_11_group)
pcn_gp_location_11 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_11;
});

for (var i = 0; i < pcn_gp_location_11.length; i++) {
new L.circleMarker([pcn_gp_location_11[i]['latitude'], pcn_gp_location_11[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_11[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_11[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_11[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_11[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_11_group) // These markers are directly added to the layer group
  };

// ! PCN 12
pcn_12_group = L.layerGroup();
pcn_12 = PCNs[12 - 1]
pcn_12_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_12; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_12_boundary.addTo(pcn_12_group)
pcn_gp_location_12 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_12;
});

for (var i = 0; i < pcn_gp_location_12.length; i++) {
new L.circleMarker([pcn_gp_location_12[i]['latitude'], pcn_gp_location_12[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_12[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_12[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_12[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_12[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_12_group) // These markers are directly added to the layer group
  };

// ! PCN 13
pcn_13_group = L.layerGroup();
pcn_13 = PCNs[13 - 1]
pcn_13_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_13; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_13_boundary.addTo(pcn_13_group)
pcn_gp_location_13 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_13;
});

for (var i = 0; i < pcn_gp_location_13.length; i++) {
new L.circleMarker([pcn_gp_location_13[i]['latitude'], pcn_gp_location_13[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_13[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_13[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_13[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_13[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_13_group) // These markers are directly added to the layer group
  };

// ! PCN 14
pcn_14_group = L.layerGroup();
pcn_14 = PCNs[14 - 1]
pcn_14_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_14; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_14_boundary.addTo(pcn_14_group)
pcn_gp_location_14 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_14;
});

for (var i = 0; i < pcn_gp_location_14.length; i++) {
new L.circleMarker([pcn_gp_location_14[i]['latitude'], pcn_gp_location_14[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_14[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_14[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_14[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_14[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_14_group) // These markers are directly added to the layer group
  };

// ! PCN 15
pcn_15_group = L.layerGroup();
pcn_15 = PCNs[15 - 1]
pcn_15_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_15; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_15_boundary.addTo(pcn_15_group)
pcn_gp_location_15 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_15;
});

for (var i = 0; i < pcn_gp_location_15.length; i++) {
new L.circleMarker([pcn_gp_location_15[i]['latitude'], pcn_gp_location_15[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_15[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_15[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_15[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_15[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_15_group) // These markers are directly added to the layer group
  };

// ! PCN 16
pcn_16_group = L.layerGroup();
pcn_16 = PCNs[16 - 1]
pcn_16_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_16; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_16_boundary.addTo(pcn_16_group)
pcn_gp_location_16 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_16;
});

for (var i = 0; i < pcn_gp_location_16.length; i++) {
new L.circleMarker([pcn_gp_location_16[i]['latitude'], pcn_gp_location_16[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_16[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_16[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_16[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_16[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_16_group) // These markers are directly added to the layer group
  };

// ! PCN 17
pcn_17_group = L.layerGroup();
pcn_17 = PCNs[17 - 1]
pcn_17_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_17; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_17_boundary.addTo(pcn_17_group)
pcn_gp_location_17 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_17;
});

for (var i = 0; i < pcn_gp_location_17.length; i++) {
new L.circleMarker([pcn_gp_location_17[i]['latitude'], pcn_gp_location_17[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_17[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_17[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_17[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_17[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_17_group) // These markers are directly added to the layer group
  };

// ! PCN 18
pcn_18_group = L.layerGroup();
pcn_18 = PCNs[18 - 1]
pcn_18_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_18; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_18_boundary.addTo(pcn_18_group)
pcn_gp_location_18 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_18;
});

for (var i = 0; i < pcn_gp_location_18.length; i++) {
new L.circleMarker([pcn_gp_location_18[i]['latitude'], pcn_gp_location_18[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_18[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_18[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_18[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_18[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_18_group) // These markers are directly added to the layer group
  };

// ! PCN 19
pcn_19_group = L.layerGroup();
pcn_19 = PCNs[19 - 1]
pcn_19_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_19; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_19_boundary.addTo(pcn_19_group)
pcn_gp_location_19 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_19;
});

for (var i = 0; i < pcn_gp_location_19.length; i++) {
new L.circleMarker([pcn_gp_location_19[i]['latitude'], pcn_gp_location_19[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_19[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_19[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_19[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_19[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_19_group) // These markers are directly added to the layer group
  };

// ! PCN 20
pcn_20_group = L.layerGroup();
pcn_20 = PCNs[20 - 1]
pcn_20_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_20; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_20_boundary.addTo(pcn_20_group)
pcn_gp_location_20 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_20;
});

for (var i = 0; i < pcn_gp_location_20.length; i++) {
new L.circleMarker([pcn_gp_location_20[i]['latitude'], pcn_gp_location_20[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_20[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_20[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_20[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_20[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_20_group) // These markers are directly added to the layer group
  };

// ! PCN 21
pcn_21_group = L.layerGroup();
pcn_21 = PCNs[21 - 1]
pcn_21_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_21; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_21_boundary.addTo(pcn_21_group)
pcn_gp_location_21 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_21;
});

for (var i = 0; i < pcn_gp_location_21.length; i++) {
new L.circleMarker([pcn_gp_location_21[i]['latitude'], pcn_gp_location_21[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_21[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_21[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_21[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_21[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_21_group) // These markers are directly added to the layer group
  };

// ! PCN 22
pcn_22_group = L.layerGroup();
pcn_22 = PCNs[22 - 1]
pcn_22_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_22; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_22_boundary.addTo(pcn_22_group)
pcn_gp_location_22 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_22;
});

for (var i = 0; i < pcn_gp_location_22.length; i++) {
new L.circleMarker([pcn_gp_location_22[i]['latitude'], pcn_gp_location_22[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_22[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_22[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_22[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_22[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_22_group) // These markers are directly added to the layer group
  };

// ! PCN 23
pcn_23_group = L.layerGroup();
pcn_23 = PCNs[23 - 1]
pcn_23_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_23; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_23_boundary.addTo(pcn_23_group)
pcn_gp_location_23 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_23;
});

for (var i = 0; i < pcn_gp_location_23.length; i++) {
new L.circleMarker([pcn_gp_location_23[i]['latitude'], pcn_gp_location_23[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_23[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_23[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_23[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_23[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_23_group) // These markers are directly added to the layer group
  };

// ! PCN 24
pcn_24_group = L.layerGroup();
pcn_24 = PCNs[24 - 1]
pcn_24_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_24; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_24_boundary.addTo(pcn_24_group)
pcn_gp_location_24 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_24;
});

for (var i = 0; i < pcn_gp_location_24.length; i++) {
new L.circleMarker([pcn_gp_location_24[i]['latitude'], pcn_gp_location_24[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_24[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_24[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_24[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_24[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_24_group) // These markers are directly added to the layer group
  };

// ! PCN 25
pcn_25_group = L.layerGroup();
pcn_25 = PCNs[25 - 1]
pcn_25_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_25; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_25_boundary.addTo(pcn_25_group)
pcn_gp_location_25 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_25;
});

for (var i = 0; i < pcn_gp_location_25.length; i++) {
new L.circleMarker([pcn_gp_location_25[i]['latitude'], pcn_gp_location_25[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_25[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_25[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_25[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_25[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_25_group) // These markers are directly added to the layer group
  };

// ! PCN 26
pcn_26_group = L.layerGroup();
pcn_26 = PCNs[26 - 1]
pcn_26_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_26; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_26_boundary.addTo(pcn_26_group)
pcn_gp_location_26 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_26;
});

for (var i = 0; i < pcn_gp_location_26.length; i++) {
new L.circleMarker([pcn_gp_location_26[i]['latitude'], pcn_gp_location_26[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_26[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_26[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_26[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_26[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_26_group) // These markers are directly added to the layer group
  };

// ! PCN 27
pcn_27_group = L.layerGroup();
pcn_27 = PCNs[27 - 1]
pcn_27_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_27; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_27_boundary.addTo(pcn_27_group)
pcn_gp_location_27 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_27;
});

for (var i = 0; i < pcn_gp_location_27.length; i++) {
new L.circleMarker([pcn_gp_location_27[i]['latitude'], pcn_gp_location_27[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_27[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_27[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_27[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_27[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_27_group) // These markers are directly added to the layer group
  };

// ! PCN 28
pcn_28_group = L.layerGroup();
pcn_28 = PCNs[28 - 1]
pcn_28_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_28; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_28_boundary.addTo(pcn_28_group)
pcn_gp_location_28 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_28;
});

for (var i = 0; i < pcn_gp_location_28.length; i++) {
new L.circleMarker([pcn_gp_location_28[i]['latitude'], pcn_gp_location_28[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_28[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_28[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_28[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_28[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_28_group) // These markers are directly added to the layer group
  };

// ! PCN 29
pcn_29_group = L.layerGroup();
pcn_29 = PCNs[29 - 1]
pcn_29_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_29; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_29_boundary.addTo(pcn_29_group)
pcn_gp_location_29 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_29;
});

for (var i = 0; i < pcn_gp_location_29.length; i++) {
new L.circleMarker([pcn_gp_location_29[i]['latitude'], pcn_gp_location_29[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_29[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_29[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_29[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_29[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_29_group) // These markers are directly added to the layer group
  };

// ! PCN 30
pcn_30_group = L.layerGroup();
pcn_30 = PCNs[30 - 1]
pcn_30_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_30; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_30_boundary.addTo(pcn_30_group)
pcn_gp_location_30 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_30;
});

for (var i = 0; i < pcn_gp_location_30.length; i++) {
new L.circleMarker([pcn_gp_location_30[i]['latitude'], pcn_gp_location_30[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_30[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_30[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_30[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_30[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_30_group) // These markers are directly added to the layer group
  };

// ! PCN 31
pcn_31_group = L.layerGroup();
pcn_31 = PCNs[31 - 1]
pcn_31_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_31; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_31_boundary.addTo(pcn_31_group)
pcn_gp_location_31 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_31;
});

for (var i = 0; i < pcn_gp_location_31.length; i++) {
new L.circleMarker([pcn_gp_location_31[i]['latitude'], pcn_gp_location_31[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_31[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_31[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_31[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_31[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_31_group) // These markers are directly added to the layer group
  };

// ! PCN 32
pcn_32_group = L.layerGroup();
pcn_32 = PCNs[32 - 1]
pcn_32_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_32; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_32_boundary.addTo(pcn_32_group)
pcn_gp_location_32 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_32;
});

for (var i = 0; i < pcn_gp_location_32.length; i++) {
new L.circleMarker([pcn_gp_location_32[i]['latitude'], pcn_gp_location_32[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_32[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_32[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_32[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_32[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_32_group) // These markers are directly added to the layer group
  };

// ! PCN 33
pcn_33_group = L.layerGroup();
pcn_33 = PCNs[33 - 1]
pcn_33_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_33; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_33_boundary.addTo(pcn_33_group)
pcn_gp_location_33 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_33;
});

for (var i = 0; i < pcn_gp_location_33.length; i++) {
new L.circleMarker([pcn_gp_location_33[i]['latitude'], pcn_gp_location_33[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_33[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_33[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_33[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_33[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_33_group) // These markers are directly added to the layer group
  };

// ! PCN 34
pcn_34_group = L.layerGroup();
pcn_34 = PCNs[34 - 1]
pcn_34_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_34; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_34_boundary.addTo(pcn_34_group)
pcn_gp_location_34 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_34;
});

for (var i = 0; i < pcn_gp_location_34.length; i++) {
new L.circleMarker([pcn_gp_location_34[i]['latitude'], pcn_gp_location_34[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_34[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_34[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_34[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_34[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_34_group) // These markers are directly added to the layer group
  };

// ! PCN 35
pcn_35_group = L.layerGroup();
pcn_35 = PCNs[35 - 1]
pcn_35_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_35; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_35_boundary.addTo(pcn_35_group)
pcn_gp_location_35 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_35;
});

for (var i = 0; i < pcn_gp_location_35.length; i++) {
new L.circleMarker([pcn_gp_location_35[i]['latitude'], pcn_gp_location_35[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_35[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_35[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_35[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_35[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_35_group) // These markers are directly added to the layer group
  };

// ! PCN 36
pcn_36_group = L.layerGroup();
pcn_36 = PCNs[36 - 1]
pcn_36_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_36; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_36_boundary.addTo(pcn_36_group)
pcn_gp_location_36 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_36;
});

for (var i = 0; i < pcn_gp_location_36.length; i++) {
new L.circleMarker([pcn_gp_location_36[i]['latitude'], pcn_gp_location_36[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_36[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_36[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_36[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_36[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_36_group) // These markers are directly added to the layer group
  };

// ! PCN 37
pcn_37_group = L.layerGroup();
pcn_37 = PCNs[37 - 1]
pcn_37_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_37; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_37_boundary.addTo(pcn_37_group)
pcn_gp_location_37 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_37;
});

for (var i = 0; i < pcn_gp_location_37.length; i++) {
new L.circleMarker([pcn_gp_location_37[i]['latitude'], pcn_gp_location_37[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_37[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_37[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_37[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_37[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_37_group) // These markers are directly added to the layer group
  };

// ! PCN 38
pcn_38_group = L.layerGroup();
pcn_38 = PCNs[38 - 1]
pcn_38_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_38; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_38_boundary.addTo(pcn_38_group)
pcn_gp_location_38 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_38;
});

for (var i = 0; i < pcn_gp_location_38.length; i++) {
new L.circleMarker([pcn_gp_location_38[i]['latitude'], pcn_gp_location_38[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_38[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_38[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_38[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_38[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_38_group) // These markers are directly added to the layer group
  };

// ! PCN 39
pcn_39_group = L.layerGroup();
pcn_39 = PCNs[39 - 1]
pcn_39_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_39; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_39_boundary.addTo(pcn_39_group)
pcn_gp_location_39 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_39;
});

for (var i = 0; i < pcn_gp_location_39.length; i++) {
new L.circleMarker([pcn_gp_location_39[i]['latitude'], pcn_gp_location_39[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_39[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_39[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_39[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_39[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_39_group) // These markers are directly added to the layer group
  };

// ! PCN 40
pcn_40_group = L.layerGroup();
pcn_40 = PCNs[40 - 1]
pcn_40_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === pcn_40; }
        , style: reg_pop_style})
      //  .addTo(pcn_x_boundary)
       .bindPopup(function (layer) {
          return (
            '<Strong>' +
            layer.feature.properties.LSOA11CD +
            '</Strong><br><br>Patients registered to ' +
            layer.feature.properties.PCN_Name +
            ': <Strong>' +
            d3.format(',.0f')(layer.feature.properties.Patients) +
            '</Strong>.<br><br>This is <Strong>' +
            d3.format('.1%')(layer.feature.properties.Patients / layer.feature.properties.Total_patients) +
            '</Strong> of the total number of patients registered to a practice in this PCN (<Strong>' + 
            d3.format(',.0f')(layer.feature.properties.Total_patients) +
            '</Strong> patients).'
          );
       })
pcn_40_boundary.addTo(pcn_40_group)
pcn_gp_location_40 = GP_location.filter(function (d) {
  return d.PCN_Name == pcn_40;
});

for (var i = 0; i < pcn_gp_location_40.length; i++) {
new L.circleMarker([pcn_gp_location_40[i]['latitude'], pcn_gp_location_40[i]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    pcn_gp_location_40[i]['ODS_Code'] + 
    ' ' + 
    pcn_gp_location_40[i]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    pcn_gp_location_40[i]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(pcn_gp_location_40[i]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(pcn_40_group) // These markers are directly added to the layer group
  };

// This function identifies the selected PCN, hides all areas then adds the appropriate PCN layer 
function showSelectedPCN(){

var Selected_pcn_area_option = d3
  .select("#select_pcn_x_button")
  .property("value");

d3.select("#pcn_reach_title_1").html(function (d) {
  return (
  Selected_pcn_area_option +
  '; Registered population residential neighbourhoods (LSOAs); LSOAs with five or more registered patients.');
});

var selected_pcn_id = 'pcn_' + selected_pcn_id_lookup(Selected_pcn_area_option) + '_group';
console.log(selected_pcn_id)

// We can make sure every layergroup is off, and then turn on only the selected one

// ! use a loop to remove all groups from the leaflet map
for (var i = 1; i < Sussex_pcn_summary_df.length; i++) {
map_lsoa_pcn_reach.removeLayer(this['pcn_' + i + '_group'])
}

// make this programmatic (not manually coding 40 pcns if possible)
var selected_pcn_object = this['pcn_' + selected_pcn_id_lookup(Selected_pcn_area_option) + '_group'];
var selected_pcn_boundary = this['pcn_' + selected_pcn_id_lookup(Selected_pcn_area_option) + '_boundary'];

selected_pcn_object.addTo(map_lsoa_pcn_reach)
map_lsoa_pcn_reach.fitBounds(selected_pcn_boundary.getBounds(), {maxZoom: 13});

}

// initalise the function
showSelectedPCN()


// showSelectedPCN() is fired any time the select changes
d3.select("#select_pcn_x_button").on("change", function (d) {
  showSelectedPCN()
 });

}); // pcn data load scope
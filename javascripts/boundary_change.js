// ! Parameters
var width = window.innerWidth * 0.8 - 20;
var height = width * 0.8;
if (width > 900) {
  var width = 900;
  var height = width * .6;
}
var width_margin = width * 0.15;

// Function to colour our lsoas by change on the map
var lsoa_change_colour_function = d3
  .scaleOrdinal()
  .domain(['Unchanged', 'Merged', 'Split', 'Redefined'])
  .range(['#c9c9c9', '#da20b2', '#20b2da', '#ff1a55']);

// Create a function to add stylings to the polygons in the leaflet map
function lsoa_change_style(feature) {
  return {
    fillColor: lsoa_change_colour_function(feature.properties.Change),
    // color: lsoa_change_colour_function(feature.properties.Change),
    color: 'maroon',
    weight: 1,
    fillOpacity: 0.85,
  };
}

function ltla_colours(feature) {
    return {
     //  fillColor: '#000000',
      color: '#000000',
      weight: 2,
      fillOpacity: 0
    }
  }
 
 function lsoa2011_colours(feature) {
     return {
       fillColor: 'maroon',
       color: 'maroon',
       weight: 1,
       fillOpacity: 0.25
     }
   }
   
 function lsoa2021_colours(feature) {
    return {
      fillColor: 'purple',
      color: 'purple',
      weight: 1,
      fillOpacity: 0.25
     }
   } 
 
// ! Load data
   $.ajax({
    url: "./outputs/lsoa_changes_table.json",
    dataType: "json",
    async: false,
    success: function(data) {
      lsoa_changes_summary_data = data;
     console.log('LSOA change summary data successfully loaded.')},
    error: function (xhr) {
      alert('LSOA change data not loaded - ' + xhr.statusText);
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
  
  var LSOA11_geojson = $.ajax({
    url: "./outputs/sussex_2011_lsoas.geojson",
    dataType: "json",
    success: console.log("LSOA (2011) boundary data successfully loaded."),
    error: function (xhr) {
      alert(xhr.statusText);
    },
  });
  
  var LSOA21_geojson = $.ajax({
    url: "./outputs/sussex_2021_lsoas.geojson",
    dataType: "json",
    success: console.log("LSOA (2021) boundary data successfully loaded."),
    error: function (xhr) {
      alert(xhr.statusText);
    },
  });

  
// ! Render tables on load
window.onload = () => {
    loadTable_lsoa_change_summary(lsoa_changes_summary_data);
  };
  
  // ! Function for adding the table body from a json file
  function loadTable_lsoa_change_summary(lsoa_changes_summary_data) {
    const tableBody = document.getElementById("table_change_1");
    var dataHTML = "";
  
    for (let item of lsoa_changes_summary_data) {
      dataHTML += `<tr><td>${item.LTLA}</td><td>${d3.format(",.0f")(item.LSOAs_in_2011)}</td><td>${d3.format(',.0f')(item.Unchanged)}</td><td>${d3.format(",.0f")(item.Split)}</td><td>${d3.format(",.0f")(item.Merged)}</td><td>${d3.format(",.0f")(item.LSOAs_in_2021)}</td><td>${item.Difference}</td></tr>`;
    }
    tableBody.innerHTML = dataHTML;
  }

  

// Generic Map parameters
// Define the background tiles for our maps 
// This tile layer is coloured
// var tileUrl = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";

// This tile layer is black and white
var tileUrl = "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png";
// Define an attribution statement to go onto our maps
var attribution =
  '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Contains Ordnance Survey data © Crown copyright and database right 2022';

// ! LSOA boundary changes 

// Specify that this code should run once the PCN_geojson data request is complete
$.when(LSOA21_geojson).done(function () {

// Create a leaflet map (L.map) in the element map_slider_change_id
var map_lsoa_change = L.map("map_slider_change_id", { zoomControl: false});

L.control.zoom({
  position: 'bottomleft'
}).addTo(map_lsoa_change);

// Add titles
var title11 = L.control({position: 'topleft'});

title11.onAdd = function () {
      var div = L.DomUtil.create('div');
      // here is Your part:
      div.innerHTML = '<span class="map_title">2011 Census LSOAs</span>';
      return div;
};
title11.addTo(map_lsoa_change);

var title21 = L.control({position: 'topright'});

title21.onAdd = function () {
  var div = L.DomUtil.create('div');
  // here is Your part:
  div.innerHTML = '<span class="map_title">2021 Census LSOAs</span>';
  return div;
};
title21.addTo(map_lsoa_change);

map_lsoa_change.createPane('left');
map_lsoa_change.createPane('right');
 
// add the background and attribution to the map
 L.tileLayer(tileUrl, { attribution })
 .addTo(map_lsoa_change);

var ltla_boundary = L.geoJSON(LTLA_geojson.responseJSON, { style: ltla_colours })
 .addTo(map_lsoa_change)
 .bindPopup(function (layer) {
    return (
      "Local authority: <Strong>" +
      layer.feature.properties.LAD22NM +
      "</Strong>"
    );
 });

map_lsoa_change.fitBounds(ltla_boundary.getBounds());

var baseMaps_map_lsoa_change = {
  "Show Local Authority boundaries": ltla_boundary,
  };

  

  var lsoa2011_boundary = L.geoJSON(LSOA11_geojson.responseJSON, { style: lsoa_change_style, pane: 'left' })
 .bindPopup(function (layer) {
    return (
      '2011 LSOA:<br><Strong>' +
      layer.feature.properties.LSOA11CD +
      "</Strong> (" +
      layer.feature.properties.LSOA11NM +
      ')<br>' +
      'Status from 2011 to 2021:<Strong>' +
      layer.feature.properties.Change +
      '</Strong>'
    );
 })
 .addTo(map_lsoa_change);

var lsoa2021_boundary = L.geoJSON(LSOA21_geojson.responseJSON, { style: lsoa2021_colours, pane: 'right' })
 .bindPopup(function (layer) {
    return (
      '<Strong>2021</Strong> LSOA:<br><Strong>' +
      layer.feature.properties.LSOA21CD +
      "</Strong> (" +
      layer.feature.properties.LSOA21NM +
      ')'
    );
 })
 .addTo(map_lsoa_change);

L.control
 .layers(null, baseMaps_map_lsoa_change, { collapsed: false, position: 'bottomright'})
 .addTo(map_lsoa_change);

// ! This works only because we change the leaflet-side-by-side.js file to have getPane() instead of getContainer()
L.control
 .sideBySide(lsoa2011_boundary, lsoa2021_boundary)
 .addTo(map_lsoa_change);



// ! Postcode search map 1
var marker_chosen = L.marker([0, 0])
.addTo(map_lsoa_change);

//search event
$(document).on("click", "#btnPostcode", function () {
  var input = $("#txtPostcode").val();
  var url = "https://api.postcodes.io/postcodes/" + input;

  post(url).done(function (postcode) {
    var chosen_lsoa = postcode["result"]["lsoa"];
    var chosen_lat = postcode["result"]["latitude"];
    var chosen_long = postcode["result"]["longitude"];

    marker_chosen.setLatLng([chosen_lat, chosen_long]);
    map_lsoa_change.setView([chosen_lat, chosen_long], 12);

    // var msoa_summary_data_chosen = msoa_summary_data.filter(function (d) {
    //   return d.MSOA11NM == chosen_msoa;
    // });

    console.log(chosen_lsoa);

    d3.select("#local_postcode_summary_1")
      // .data(msoa_summary_data_chosen)
      .html(function (d) {
        // return d.MSOA11NM + " (" + d.msoa11hclnm + ")";
        return chosen_lsoa;
      });

    d3.select("#local_postcode_summary_2")
      // .data(msoa_summary_data_chosen)
      .html(function (d) {
        // return d.Change_label;
        return 'This too shall pass... as a placeholder. Eventually this will be linked to more information about the LSOA such as the current usual resident population and whether the LSOA is the same as it was in 2011.'
      });
  });
});

//enter event - search
$("#txtPostcode").keypress(function (e) {
  if (e.which === 13) {
    $("#btnPostcode").click();
  }
});

//ajax call
function post(url) {
  return $.ajax({
    url: url,
    success: function () {
      //woop
    },
    error: function (desc, err) {
      $("#result_text").html("Details: " + desc.responseText);

      d3.select("#local_postcode_summary_1").html(function (d) {
        return "The postcode you entered does not seem to be valid, please check and try again.";
      });
      d3.select("#local_postcode_summary_2").html(function (d) {
        return "This could be because there is a problem with the postcode look up tool we are using.";
      });
    },
  });
}




});

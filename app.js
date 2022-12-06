// ! Parameters
var width = window.innerWidth * 0.8 - 20;
var height = width * 0.8;
if (width > 900) {
  var width = 900;
  var height = width * .6;
}
var width_margin = width * 0.15;

// Create an array of colours for keys
// pcn_colours = ['#a04866', '#d74356', '#c4705e', '#ca572a', '#d49445',  '#526dd6', '#37835c', '#a2b068', '#498a36',  '#a678e4', '#8944b3',  '#57c39b', '#4ab8d2', '#658dce', '#776e29', '#60bf52', '#7e5b9e' ,  '#afb136',  '#ce5cc6','#d58ec6', '#000099', '#000000']

// Create a function which takes the pcn_code as input and outputs the colour
// var setPCNcolour = d3
  // .scaleOrdinal()
  // .domain(pcn_codes)
  // .range(pcn_colours);

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

$.ajax({
  url: "./outputs/ltla_2021_pop_table.json",
  dataType: "json",
  async: false,
  success: function(data) {
    ltla_pop_summary_data = data;
   console.log('LTLA population successfully loaded.')},
  error: function (xhr) {
    alert('LTLA population data not loaded - ' + xhr.statusText);
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

// ! Load area pyramid data
$.ajax({
  url: "./outputs/Census_2021_pyramid_data.json",
  dataType: "json",
  async: false,
  success: function(data) {
    Census_pyramid_data = data;
   console.log('Area pyramid data successfully loaded.')},
  error: function (xhr) {
    alert('Area pyramid data not loaded - ' + xhr.statusText);
  },
});

// Get a list of unique PCN_codes from the data using d3.map
var area_list = d3
  .map(ltla_pop_summary_data, function (d) {
    return d.Area;
  })
  .keys();

// ! Render tables on load
window.onload = () => {
  loadTable_ltla_population_summary(ltla_pop_summary_data);
  loadTable_lsoa_change_summary(lsoa_changes_summary_data);
};

function loadTable_lsoa_change_summary(lsoa_changes_summary_data) {
  const tableBody = document.getElementById("table_change_1");
  var dataHTML = "";

  for (let item of lsoa_changes_summary_data) {
    dataHTML += `<tr><td>${item.LTLA}</td><td>${d3.format(",.0f")(item.LSOAs_in_2011)}</td><td>${d3.format(',.0f')(item.Unchanged)}</td><td>${d3.format(",.0f")(item.Split)}</td><td>${d3.format(",.0f")(item.Merged)}</td><td>${d3.format(",.0f")(item.LSOAs_in_2021)}</td><td>${d3.format(",.0f")(item.Difference)}</td></tr>`;
  }
  tableBody.innerHTML = dataHTML;
}

function loadTable_ltla_population_summary(ltla_2021_pop_table) {
  const tableBody = document.getElementById("table_total_1");
  var dataHTML = "";

  for (let item of ltla_2021_pop_table) {
    dataHTML += `<tr><td>${item.Area}</td><td>${d3.format(",.0f")(item.Persons)}</td><td>${d3.format(',.0f')(item.Female)}</td><td>${d3.format(",.0f")(item.Male)}</td></tr>`;
  }
  tableBody.innerHTML = dataHTML;
}

// ! Population pyramid
var margin_middle = 80,
    pyramid_plot_width = (height/2) - (margin_middle/2),
    male_zero = pyramid_plot_width,
    female_zero = pyramid_plot_width + margin_middle;

// append the svg object to the body of the page
var svg_pyramid = d3.select("#pyramid_census_datavis")
.append("svg")
.attr("width", height + (margin_middle/2))
.attr("height", height + (margin_middle/2))
.append("g")

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_area_pyramid_button")
  .selectAll("myOptions")
  .data(area_list)
  .enter()
  .append("option")
  .text(function (d) {
    return d;
  })
  .attr("value", function (d) {
    return d;
  });

// Retrieve the selected area name
var chosen_pyramid_area = d3
  .select("#select_area_pyramid_button")
  .property("value");

// Use the value from chosen_pcn_pyramid_area to populate a title for the figure. This will be placed as the element 'selected_pcn_pyramid_title' on the webpage
d3.select("#selected_area_pyramid_title").html(function (d) {
  return (
    "Population pyramid; " +
    chosen_pyramid_area +
    "; usual resident population; Census 2021"   
   );
 });

  var age_levels = ["0-4 years", "5-9 years", "10-14 years", "15-19 years", "20-24 years", "25-29 years", "30-34 years", "35-39 years", "40-44 years", "45-49 years", "50-54 years", "55-59 years", "60-64 years", "65-69 years", "70-74 years", "75-79 years", "80-84 years", "85-89 years", '90+ years']

  Census_pyramid_data.sort(function(a,b) {
  return age_levels.indexOf(a.Age_group) > age_levels.indexOf(b.Age_group)});

// Filter to get out chosen dataset
chosen_pyramid_data = Census_pyramid_data.filter(function(d,i){
  return d.Area_name === chosen_pyramid_area })

chosen_pyramid_summary_data = ltla_pop_summary_data.filter(function(d,i){
    return d.Area === chosen_pyramid_area }) 
 
d3.select("#area_age_structure_text_1").html(function (d) {
  return (
    "There are estimated to be <b class = 'extra'>" +
    d3.format(',.0f')(chosen_pyramid_summary_data[0]['Persons']) +
    ' </b>persons recorded as residents in ' +
        chosen_pyramid_area + 
       ' as at Census day 2021. This includes <b>' +
       d3.format(',.0f')(chosen_pyramid_summary_data[0]['Male']) +
       ' males</b> and <b>' + 
       d3.format(',.0f')(chosen_pyramid_summary_data[0]['Female']) +
       ' females</b>.');
});

// d3.select("#pcn_age_structure_text_2").html(function (d) {
//   return (
//   '<b class = "extra">' +
//   d3.format(',.0f')(chosen_pcn_pyramid_summary_data[0]['65+ years']) +
//   ' </b>patients are aged 65+ and over, this is ' +
//   d3.format('.1%')(chosen_pcn_pyramid_summary_data[0]['65+ years'] / chosen_pcn_pyramid_summary_data[0]['Total'])
//   );
// });

// d3.select("#pcn_age_structure_text_3").html(function (d) {
//  return (
//   '<b class = "extra">' +
//   d3.format(',.0f')(chosen_pcn_pyramid_summary_data[0]['0-15 years']) +
//   '</b> are aged 0-15 and <b class = "extra">'+
//   d3.format(',.0f')(chosen_pcn_pyramid_summary_data[0]['16-64 years']) +
//   '</b> are aged 16-64.'
//  );
//  });

// find the maximum data value on either side
 var maxPopulation_static_pyr = Math.max(
  d3.max(chosen_pyramid_data, function(d) { return d['Population']; })
);

if(maxPopulation_static_pyr < 2000) {
  maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 200) * 200
}

if(maxPopulation_static_pyr >= 2000 && maxPopulation_static_pyr < 3000) {
  maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 250) * 250
}

if(maxPopulation_static_pyr >= 3000) {
    maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 500) * 500
}

// the scale goes from 0 to the width of the pyramid plotting region. We will invert this for the left x-axis
var x_static_pyramid_scale_male = d3.scaleLinear()
 .domain([0, maxPopulation_static_pyr])
 .range([male_zero, (0 + margin_middle/4)])
 .nice();

var xAxis_static_pyramid = svg_pyramid
 .append("g")
 .attr("transform", "translate(0," + height + ")")
 .call(d3.axisBottom(x_static_pyramid_scale_male).ticks(6))

 var x_static_pyramid_scale_female = d3.scaleLinear()
 .domain([0, maxPopulation_static_pyr])
 .range([female_zero, (height - margin_middle/4)])
 .nice();

var xAxis_static_pyramid_2 = svg_pyramid
 .append("g")
 .attr("transform", "translate(0," + height + ")")
 .call(d3.axisBottom(x_static_pyramid_scale_female).ticks(6));

 var pyramid_scale_bars = d3.scaleLinear()
 .domain([0, maxPopulation_static_pyr])
 .range([0, (pyramid_plot_width - margin_middle/4)]);

var y_pyramid_scale = d3.scaleBand()
 .domain(age_levels)
 .range([height, 0])
 .padding([0.2]);

 var yaxis_pos = height/2
 
 var yAxis_static_pyramid = svg_pyramid
 .append("g")
 .attr("transform", "translate(0" + yaxis_pos + ",0)")
 .call(d3.axisLeft(y_pyramid_scale).tickSize(0))
 .style('text-anchor', 'middle')
 .select(".domain").remove()
 
svg_pyramid
   .selectAll("myRect")
   .data(chosen_pyramid_data)
   .enter()
   .append("rect")
   .attr("class", "pyramid_1")
   .attr("x", female_zero)
   .attr("y", function(d) { return y_pyramid_scale(d.Age_group); })
   .attr("width", function(d) { return pyramid_scale_bars(d['Population']); })
   .attr("height", y_pyramid_scale.bandwidth())
   .attr("fill", "#0099ff")
 
svg_pyramid
  .selectAll("myRect")
  .data(chosen_pyramid_data)
  .enter()
  .append("rect")
  .attr("class", "pyramid_1")
  .attr("x", function(d) { return male_zero - pyramid_scale_bars(d['Population']); })
  .attr("y", function(d) { return y_pyramid_scale(d.Age_group); })
  .attr("width", function(d) { return pyramid_scale_bars(d['Population']); })
  .attr("height", y_pyramid_scale.bandwidth())
  .attr("fill", "#ff6600")

function render_pyramid(d) {
  var chosen_pyramid_area = d3
    .select("#select_area_pyramid_button")
    .property("value");
   
  d3.select("#selected_area_pyramid_title").html(function (d) {
    return (
       "Population pyramid; " +
       chosen_pyramid_area +
       "; usual resident population; Census 2021"   
      );
    });

chosen_pyramid_data = Census_pyramid_data.filter(function(d,i){
  return d.Area === chosen_pyramid_area })
   
chosen_pyramid_summary_data = ltla_pop_summary_data.filter(function(d,i){
  return d.Area === chosen_pyramid_area }) 
    
d3.select("#area_age_structure_text_1").html(function (d) {
  return (
   "There are estimated to be <b class = 'extra'>" +
    d3.format(',.0f')(chosen_pyramid_summary_data[0]['Persons']) +
    ' </b>persons recorded as residents in ' +
        chosen_pyramid_area + 
       ' as at Census day 2021. This includes <b>' +
       d3.format(',.0f')(chosen_pyramid_summary_data[0]['Male']) +
       ' males</b> and <b>' + 
       d3.format(',.0f')(chosen_pyramid_summary_data[0]['Female']) +
       ' females</b>.');
     });
    
svg_pyramid.selectAll(".pyramid_1").remove();

var maxPopulation_static_pyr = Math.max(
    d3.max(chosen_pyramid_data, function(d) { return d['Population']; })
  );

if(maxPopulation_static_pyr < 2000) {
  maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 200) * 200
}

if(maxPopulation_static_pyr >= 2000 && maxPopulation_static_pyr < 3000) {
  maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 250) * 250
}

if(maxPopulation_static_pyr >= 3000) {
    maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 500) * 500
}

x_static_pyramid_scale_male
  .domain([0, maxPopulation_static_pyr])
  
x_static_pyramid_scale_female 
  .domain([0, maxPopulation_static_pyr])
  
pyramid_scale_bars 
  .domain([0,maxPopulation_static_pyr])

xAxis_static_pyramid 
  .transition()
  .duration(1000)
  .call(d3.axisBottom(x_static_pyramid_scale_male).ticks(6));
 
 xAxis_static_pyramid_2
 .transition()
 .duration(1000)
 .call(d3.axisBottom(x_static_pyramid_scale_female).ticks(6));

svg_pyramid
   .selectAll("myRect")
   .data(chosen_pyramid_data)
   .enter()
   .append("rect")
   .attr("class", "pyramid_1")
   .attr("x", female_zero)
   .attr("y", function(d) { return y_pyramid_scale(d.Age_group); })
   .attr("width", function(d) { return pyramid_scale_bars(d['Population']); })
   .attr("height", y_pyramid_scale.bandwidth())
   .attr("fill", "#0099ff")
 
svg_pyramid
  .selectAll("myRect")
  .data(chosen_pyramid_data)
  .enter()
  .append("rect")
  .attr("class", "pyramid_1")
  .attr("x", function(d) { return male_zero - pyramid_scale_bars(d['Population']); })
  .attr("y", function(d) { return y_pyramid_scale(d.Age_group); })
  .attr("width", function(d) { return pyramid_scale_bars(d['Population']); })
  .attr("height", y_pyramid_scale.bandwidth())
  .attr("fill", "#ff6600")
}

render_pyramid()
     
// The .on('change) part says when the drop down menu (select element) changes then retrieve the new selected area name and then use it to update the selected_pcn_pyramid_title element 
d3.select("#select_area_pyramid_button").on("change", function (d) {
render_pyramid()
});



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

// Create a leaflet map (L.map) in the element map_1_id
var map_1 = L.map("map_1_id", { zoomControl: false});

L.control.zoom({
  position: 'bottomleft'
}).addTo(map_1);

// Add titles
var title11 = L.control({position: 'topleft'});

title11.onAdd = function () {
      var div = L.DomUtil.create('div');
      // here is Your part:
      div.innerHTML = '<span class="map_title">2011 Census LSOAs</span>';
      return div;
};
title11.addTo(map_1);

var title21 = L.control({position: 'topright'});

title21.onAdd = function () {
  var div = L.DomUtil.create('div');
  // here is Your part:
  div.innerHTML = '<span class="map_title">2021 Census LSOAs</span>';
  return div;
};
title21.addTo(map_1);

map_1.createPane('left');
map_1.createPane('right');
 
// add the background and attribution to the map
 L.tileLayer(tileUrl, { attribution })
 .addTo(map_1);

var ltla_boundary = L.geoJSON(LTLA_geojson.responseJSON, { style: ltla_colours })
 .addTo(map_1)
 .bindPopup(function (layer) {
    return (
      "Local authority: <Strong>" +
      layer.feature.properties.LAD22NM +
      "</Strong>"
    );
 });

map_1.fitBounds(ltla_boundary.getBounds());

var baseMaps_map_1 = {
  "Show Local Authority boundaries": ltla_boundary,
  };

  var lsoa2011_boundary = L.geoJSON(LSOA11_geojson.responseJSON, { style: lsoa2011_colours, pane: 'left' })
 .bindPopup(function (layer) {
    return (
      '<Strong>2011</Strong> LSOA:<br><Strong>' +
      layer.feature.properties.LSOA11CD +
      "</Strong> (" +
      layer.feature.properties.LSOA11NM +
      ')'
    );
 })
 .addTo(map_1);

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
 .addTo(map_1);

L.control
 .layers(null, baseMaps_map_1, { collapsed: false, position: 'bottomright'})
 .addTo(map_1);

// ! This works only because we change the leaflet-side-by-side.js file to have getPane() instead of getContainer()
L.control
 .sideBySide(lsoa2011_boundary, lsoa2021_boundary)
 .addTo(map_1);



// ! Postcode search map 1
var marker_chosen = L.marker([0, 0])
.addTo(map_1);

//search event
$(document).on("click", "#btnPostcode", function () {
  var input = $("#txtPostcode").val();
  var url = "https://api.postcodes.io/postcodes/" + input;

  post(url).done(function (postcode) {
    var chosen_lsoa = postcode["result"]["lsoa"];
    var chosen_lat = postcode["result"]["latitude"];
    var chosen_long = postcode["result"]["longitude"];

    marker_chosen.setLatLng([chosen_lat, chosen_long]);
    map_1.setView([chosen_lat, chosen_long], 12);

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

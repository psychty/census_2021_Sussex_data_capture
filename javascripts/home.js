// ! Parameters
var width = window.innerWidth * 0.8 - 20;
var height = width * 0.8;
if (width > 900) {
  var width = 900;
  var height = width * .6;
}
var width_margin = width * 0.15;

function get_density_colour(d) {
  return d > 25000 ? '#7f3b08' :
         d > 20000  ? '#b35806' :
         d > 15000  ? '#e08214' :
         d > 10000  ? '#fdb863' :
         d > 5000   ? '#fee0b6' :
         d > 1000   ? '#f7f7f7' :
         d > 500   ? '#d8daeb' :
         d > 200   ? '#b2abd2' :
         d > 100   ? '#8073ac' :
         d > 50   ? '#542788' :
         '#2d004b' ;
}

// function get_density_colour(d) {
//   return d > 20000 ? '#2d004b' :
//          d > 15000  ? '#542788' :
//          d > 10000  ? '#8073ac' :
//          d > 8000  ? '#b2abd2' :
//          d > 5000   ? '#d8daeb' :
//          d > 1000   ? '#f7f7f7' :
//          d > 500   ? '#fee0b6' :
//          d > 200   ? '#fdb863' :
//          d > 100   ? '#e08214' :
//          d > 50   ? '#b35806' :
//          '#7f3b08' ;
// }

// Create a function to add stylings to the polygons in the leaflet map
function density_style(feature) {
  return {
    fillColor: get_density_colour(feature.properties.Persons_per_square_kilometre),
    color: get_density_colour(feature.properties.Persons_per_square_kilometre),
    // color: '#',
    weight: 1,
    fillOpacity: 0.85,
  };
}

function density_style_ltla(feature) {
  return {
    fillColor: get_density_colour(feature.properties.Persons_per_square_kilometre),
    color: '#000',
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

function lsoa2021_colours(feature) {
  return {
   //  fillColor: '#000000',
    color: '#000000',
    weight: 2,
    fillOpacity: 0
  }
}

function msoa2021_colours(feature) {
  return {
   //  fillColor: '#000000',
    color: '#000000',
    weight: 2,
    fillOpacity: 0
  }
}



// ! Load data

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

$.ajax({
  url: "./outputs/Census_2021_broad_pop.json",
  dataType: "json",
  async: false,
  success: function(data) {
    Census_broad_age_data = data;
   console.log('Area broad age summary data successfully loaded.')},
  error: function (xhr) {
    alert('Area broad age summary data not loaded - ' + xhr.statusText);
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

var LSOA21_geojson = $.ajax({
  url: "./outputs/sussex_2021_lsoas.geojson",
  dataType: "json",
  success: console.log("LSOA (2021) boundary data successfully loaded."),
  error: function (xhr) {
    alert(xhr.statusText);
  },
});

var MSOA21_geojson = $.ajax({
  url: "./outputs/sussex_2021_msoas.geojson",
  dataType: "json",
  success: console.log("MSOA (2021) boundary data successfully loaded."),
  error: function (xhr) {
    alert(xhr.statusText);
  },
});

var area_list = d3
  .map(ltla_pop_summary_data, function (d) {
    return d.Area;
  })
  .keys();

// ! Render LTLA table on load
window.onload = () => {
  loadTable_ltla_population_summary(ltla_pop_summary_data);
  loadTable_ltla_population_change_summary(ltla_pop_summary_data);
};


function loadTable_ltla_population_summary(ltla_2021_pop_table) {
  const tableBody = document.getElementById("table_total_1");
  var dataHTML = "";

  for (let item of ltla_2021_pop_table) {
    dataHTML += `<tr><td>${item.Area}</td><td>${d3.format(",.0f")(item.Persons)}</td><td>${d3.format(',.0f')(item.Female)}</td><td>${d3.format(",.0f")(item.Male)}</td><td>${d3.format(",.0f")(item.Median_age)}</td></tr>`;
  }
  tableBody.innerHTML = dataHTML;
}

function loadTable_ltla_population_change_summary(ltla_2021_pop_table) {
  const tableBody = document.getElementById("table_total_2");
  var dataHTML = "";

  for (let item of ltla_2021_pop_table) {
    dataHTML += `<tr><td>${item.Area}</td><td>${d3.format(",.0f")(item.Population_2011)}</td><td>${d3.format(',.0f')(item.Persons)}</td><td>${'+' + d3.format(",.0f")(item.Population_change)}</td><td>${'+' + d3.format(",.1%")(item.Population_percentage_change)}</td></tr>`;
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
    "Figure - Population pyramid; " +
    chosen_pyramid_area +
    "; usual resident population; Census 2021"   
   );
 });

  var age_levels = ["0-4 years", "5-9 years", "10-14 years", "15-19 years", "20-24 years", "25-29 years", "30-34 years", "35-39 years", "40-44 years", "45-49 years", "50-54 years", "55-59 years", "60-64 years", "65-69 years", "70-74 years", "75-79 years", "80-84 years", "85-89 years", '90+ years']

Census_pyramid_data.sort(function(a,b) {
  return age_levels.indexOf(a.Age_group) > age_levels.indexOf(b.Age_group)});

// Filter to get out chosen dataset
chosen_pyramid_data = Census_pyramid_data.filter(function(d,i){
  return d.Area === chosen_pyramid_area })

chosen_pyramid_summary_data = ltla_pop_summary_data.filter(function(d,i){
    return d.Area === chosen_pyramid_area }) 

chosen_pryamid_broad_data = Census_broad_age_data.filter(function(d,i){
  return d.Area === chosen_pyramid_area  && d.Sex === 'Persons'})
  
 
d3.select("#area_age_structure_text_1").html(function (d) {
  return (
    "According to the 2021 Census, there were an estimated <b class = 'extra'>" +
    d3.format(',.0f')(chosen_pyramid_summary_data[0]['Persons']) +
    ' </b>persons recorded as residents in ' +
        chosen_pyramid_area + 
       ' as at Census day 2021. This includes <b>' +
       d3.format(',.0f')(chosen_pyramid_summary_data[0]['Male']) +
       ' males</b> and <b>' + 
       d3.format(',.0f')(chosen_pyramid_summary_data[0]['Female']) +
       ' females</b>.');
});

   
d3.select("#area_age_structure_text_2").html(function (d) {
  return (
  '<b>' +
  d3.format(',.0f')(chosen_pryamid_broad_data[0]['65+ years']) +
  ' </b>residents were aged 65+ and over, this is ' +
  d3.format('.1%')(chosen_pryamid_broad_data[0]['65+ years'] / chosen_pryamid_broad_data[0]['Total'])
  );
});

d3.select("#area_age_structure_text_3").html(function (d) {
 return (
  '<b>' +
  d3.format(',.0f')(chosen_pryamid_broad_data[0]['0-17 years']) +
  '</b> were aged 0-17 ('  +
  d3.format('.1%')(chosen_pryamid_broad_data[0]['0-17 years'] / chosen_pryamid_broad_data[0]['Total']) +
  ') and <b>'+
  d3.format(',.0f')(chosen_pryamid_broad_data[0]['18-64 years']) +
  '</b> were aged 18-64 ('  +
  d3.format('.1%')(chosen_pryamid_broad_data[0]['18-64 years'] / chosen_pryamid_broad_data[0]['Total']) +
  ').'
 );
 });

// find the maximum data value on either side
 var maxPopulation_static_pyr = Math.max(
  d3.max(chosen_pyramid_data, function(d) { return d.Male; }),
  d3.max(chosen_pyramid_data, function(d) { return d.Female; })
);

if(maxPopulation_static_pyr < 2000) {
  maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 200) * 200
}

if(maxPopulation_static_pyr >= 2000 && maxPopulation_static_pyr < 20000) {
  maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 1000) * 1000
}

if(maxPopulation_static_pyr >= 20000) {
    maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 5000) * 5000
}

// the scale goes from 0 to the width of the pyramid plotting region. We will invert this for the left x-axis
var x_static_pyramid_scale_male = d3.scaleLinear()
 .domain([0, maxPopulation_static_pyr])
 .range([male_zero, (0 + margin_middle/4)])
 .nice();

var xAxis_static_pyramid = svg_pyramid
 .append("g")
 .attr("transform", "translate(0," + height + ")")
 .call(d3.axisBottom(x_static_pyramid_scale_male).ticks(5))

 var x_static_pyramid_scale_female = d3.scaleLinear()
 .domain([0, maxPopulation_static_pyr])
 .range([female_zero, (height - margin_middle/4)])
 .nice()

var xAxis_static_pyramid_2 = svg_pyramid
 .append("g")
 .attr("transform", "translate(0," + height + ")")
 .call(d3.axisBottom(x_static_pyramid_scale_female).ticks(5));

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
   .attr("width", function(d) { return pyramid_scale_bars(d.Female); })
   .attr("height", y_pyramid_scale.bandwidth())
   .attr("fill", "#f1c232")
 
svg_pyramid
  .selectAll("myRect")
  .data(chosen_pyramid_data)
  .enter()
  .append("rect")
  .attr("class", "pyramid_1")
  .attr("x", function(d) { return male_zero - pyramid_scale_bars(d.Male); })
  .attr("y", function(d) { return y_pyramid_scale(d.Age_group); })
  .attr("width", function(d) { return pyramid_scale_bars(d.Male); })
  .attr("height", y_pyramid_scale.bandwidth())
  .attr("fill", "#741b47")

function render_pyramid(d) {
  var chosen_pyramid_area = d3
    .select("#select_area_pyramid_button")
    .property("value");
   
  d3.select("#selected_area_pyramid_title").html(function (d) {
    return (
       "Figure - Population pyramid; " +
       chosen_pyramid_area +
       "; usual resident population; Census 2021"   
      );
    });

chosen_pyramid_data = Census_pyramid_data.filter(function(d,i){
  return d.Area === chosen_pyramid_area })
   
chosen_pyramid_summary_data = ltla_pop_summary_data.filter(function(d,i){
  return d.Area === chosen_pyramid_area }) 

chosen_pryamid_broad_data = Census_broad_age_data.filter(function(d,i){
  return d.Area === chosen_pyramid_area  && d.Sex === 'Persons'})
  
d3.select("#area_age_structure_text_1").html(function (d) {
  return (
    "According to the 2021 Census, there were an estimated <b class = 'extra'>" +
    d3.format(',.0f')(chosen_pyramid_summary_data[0]['Persons']) +
    ' </b>persons recorded as residents in ' +
        chosen_pyramid_area + 
       ' as at Census day 2021. This includes <b>' +
       d3.format(',.0f')(chosen_pyramid_summary_data[0]['Male']) +
       ' males</b> and <b>' + 
       d3.format(',.0f')(chosen_pyramid_summary_data[0]['Female']) +
       ' females</b>.');
     });
   
d3.select("#area_age_structure_text_2").html(function (d) {
  return (
  '<b>' +
  d3.format(',.0f')(chosen_pryamid_broad_data[0]['65+ years']) +
  ' </b>residents were aged 65+ and over, this is ' +
  d3.format('.1%')(chosen_pryamid_broad_data[0]['65+ years'] / chosen_pryamid_broad_data[0]['Total'])
  );
});

d3.select("#area_age_structure_text_3").html(function (d) {
 return (
  '<b>' +
  d3.format(',.0f')(chosen_pryamid_broad_data[0]['0-17 years']) +
  '</b> were aged 0-17 ('  +
  d3.format('.1%')(chosen_pryamid_broad_data[0]['0-17 years'] / chosen_pryamid_broad_data[0]['Total']) +
  ') and <b>'+
  d3.format(',.0f')(chosen_pryamid_broad_data[0]['18-64 years']) +
  '</b> were aged 18-64 ('  +
  d3.format('.1%')(chosen_pryamid_broad_data[0]['18-64 years'] / chosen_pryamid_broad_data[0]['Total']) +
  ').'
 );
 });

// fin
    
svg_pyramid.selectAll(".pyramid_1").remove();

var maxPopulation_static_pyr = Math.max(
    d3.max(chosen_pyramid_data, function(d) { return d['Male']; }),
    d3.max(chosen_pyramid_data, function(d) { return d['Female']; })
  );

if(maxPopulation_static_pyr < 2000) {
  maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 200) * 200
}

if(maxPopulation_static_pyr >= 2000 && maxPopulation_static_pyr < 20000) {
  maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 1000) * 1000
}

if(maxPopulation_static_pyr >= 20000) {
    maxPopulation_static_pyr  = Math.ceil(maxPopulation_static_pyr / 5000) * 5000
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
  .call(d3.axisBottom(x_static_pyramid_scale_male).ticks(5));
 
 xAxis_static_pyramid_2
 .transition()
 .duration(1000)
 .call(d3.axisBottom(x_static_pyramid_scale_female).ticks(5));

svg_pyramid
   .selectAll("myRect")
   .data(chosen_pyramid_data)
   .enter()
   .append("rect")
   .attr("class", "pyramid_1")
   .attr("x", female_zero)
   .attr("y", function(d) { return y_pyramid_scale(d.Age_group); })
   .attr("width", function(d) { return pyramid_scale_bars(d.Female); })
   .attr("height", y_pyramid_scale.bandwidth())
   .attr("fill", "#f1c232")
   
svg_pyramid
  .selectAll("myRect")
  .data(chosen_pyramid_data)
  .enter()
  .append("rect")
  .attr("class", "pyramid_1")
  .attr("x", function(d) { return male_zero - pyramid_scale_bars(d.Male); })
  .attr("y", function(d) { return y_pyramid_scale(d.Age_group); })
  .attr("width", function(d) { return pyramid_scale_bars(d.Male); })
  .attr("height", y_pyramid_scale.bandwidth())
  .attr("fill", "#741b47")

 svg_pyramid
  .append("text")
  .attr("x", function(d) { return male_zero - pyramid_scale_bars(maxPopulation_static_pyr)})
  .attr("y", 30)
  .attr("id", "pyramid_sex_label_male")
  .attr("text-anchor", "start")
  .attr("class", "pyramid_1")
  // .style("fill", "#f1c232")
  .style("font-weight", "bold")
  .style("font-size", "12px")
  .text('Males: ' +  d3.format(',.0f')(chosen_pyramid_summary_data[0]['Male']))
  // .text("First doses so far: " + d3.format(",.0f")(chosen_dose_1_so_far));
 
svg_pyramid
  .append("text")
  .attr("x", function(d) { return female_zero + pyramid_scale_bars(maxPopulation_static_pyr)})
  .attr("y", 30)
  .attr("id", "pyramid_sex_label_female")
  .attr("text-anchor", "end")
  .attr("class", "pyramid_1")
  // .style("fill", "#f1c232")
  .style("font-weight", "bold")
  .style("font-size", "12px")
  .text('Females: ' +  d3.format(',.0f')(chosen_pyramid_summary_data[0]['Female']))
  // .text("First doses so far: " + d3.format(",.0f")(chosen_dose_1_so_far));
 
 
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
  '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Contains Ordnance Survey data ?? Crown copyright and database right 2022';

// ! LSOA boundary changes 

// Specify that this code should run once the PCN_geojson data request is complete
$.when(LSOA21_geojson).done(function () {

// Create a leaflet map (L.map) in the element map_1_id
var map_population = L.map("map_overall_population");

L.control.zoom({
  position: 'bottomleft'
}).addTo(map_population);

// add the background and attribution to the map
L.tileLayer(tileUrl, { attribution })
.addTo(map_population);

var lsoa2021_boundary = L.geoJSON(LSOA21_geojson.responseJSON, { style: density_style})
 .bindPopup(function (layer) {
    return (
      '2021 LSOA: <Strong>' +
      layer.feature.properties.LSOA21CD +
      " (" +
      layer.feature.properties.LSOA21NM +
      ')</Strong><br>Population: <Strong>' +
      d3.format(',.0f')(layer.feature.properties.Population) +
      '</Strong><br>Population per square kilometre: <Strong>' +
      d3.format(',.0f')(layer.feature.properties.Persons_per_square_kilometre) +
      'km<sup>2</sup> </Strong>.'
    );
 })
//  .addTo(map_population);

var msoa2021_boundary = L.geoJSON(MSOA21_geojson.responseJSON, { style: density_style})
 .bindPopup(function (layer) {
    return (
      '2021 LSOA: <Strong>' +
      layer.feature.properties.MSOA21CD +
      ' (' +
      layer.feature.properties.MSOA21NM +
      ')</Strong><br>Population: <Strong>' +
      d3.format(',.0f')(layer.feature.properties.Population) +
      '</Strong><br>Population per square kilometre: <Strong>' +
      d3.format(',.0f')(layer.feature.properties.Persons_per_square_kilometre) +
      'km<sup>2</sup> </Strong>.'
    );
 })
//  .addTo(map_population);

var ltla_boundary = L.geoJSON(LTLA_geojson.responseJSON, { style: density_style_ltla })
.bindPopup(function (layer) {
   return (
     "Local authority: <Strong>" +
     layer.feature.properties.LAD22NM +
     "</Strong><br>Population: <Strong>" +
     d3.format(',.0f')(layer.feature.properties.Population) +
     '</Strong><br>Population per square kilometre: <Strong>' +
     d3.format(',.0f')(layer.feature.properties.Persons_per_square_kilometre) +
     'km<sup>2</sup> </Strong>.'
   );
})
.addTo(map_population);

map_population.fitBounds(ltla_boundary.getBounds());

var baseMaps_map_population = {
  'Show Lower layer super output areas (LSOAs)': lsoa2021_boundary,
  'Show Middle layer super output areas (MSOAs)': msoa2021_boundary,
   "Show Local Authorities": ltla_boundary,
  };

 L.control
 .layers(baseMaps_map_population, null, { collapsed: false, position: 'topright'})
 .addTo(map_population);

 var legend_map_population = L.control({position: 'bottomright'});
  
 legend_map_population.onAdd = function (map_population) {
 
     var div = L.DomUtil.create('div', 'info legend'),
         grades = [0, 50, 100, 200, 500, 1000, 5000, 10000, 15000, 20000, 25000],
         labels = ['<b>Population density<br>(people per km<sup>2</sup>)</b>'];
 
     // loop through our density intervals and generate a label with a colored square for each interval
     for (var i = 0; i < grades.length; i++) {
         div.innerHTML +=
         labels.push(
             '<i style="background:' + get_density_colour(grades[i] + 1) + '"></i> ' +
             d3.format(',.0f')(grades[i]) + (grades[i + 1] ? '&ndash;' + d3.format(',.0f')(grades[i + 1]) + ' per km<sup>2</sup>' : ' per km<sup>2</sup>+'));
     }
     div.innerHTML = labels.join('<br>');
     return div;
 };
 
legend_map_population.addTo(map_population);

// ! Postcode search map population
var marker_chosen = L.marker([0, 0])
.addTo(map_population);

//search event
$(document).on("click", "#btnPostcode", function () {
  var input = $("#txtPostcode").val();
  var url = "https://api.postcodes.io/postcodes/" + input;

  post(url).done(function (postcode) {
    var chosen_lsoa = postcode["result"]["lsoa"];
    var chosen_lat = postcode["result"]["latitude"];
    var chosen_long = postcode["result"]["longitude"];

    marker_chosen.setLatLng([chosen_lat, chosen_long]);
    map_population.setView([chosen_lat, chosen_long], 12);

    var msoa_summary_data_chosen = msoa_summary_data.filter(function (d) {
      return d.MSOA11NM == chosen_msoa;
    });

    // console.log(chosen_lsoa);

    // d3.select("#local_postcode_summary_1")
    //   // .data(msoa_summary_data_chosen)
    //   .html(function (d) {
    //     // return d.MSOA11NM + " (" + d.msoa11hclnm + ")";
    //     return chosen_lsoa;
    //   });

    // d3.select("#local_postcode_summary_2")
    //   // .data(msoa_summary_data_chosen)
    //   .html(function (d) {
    //     // return d.Change_label;
    //     return 'This too shall pass... as a placeholder. Eventually this will be linked to more information about the LSOA such as the current usual resident population and whether the LSOA is the same as it was in 2011.'
    //   });
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


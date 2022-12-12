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

// Get a list of unique PCN_codes from the data using d3.map
var area_list = d3
  .map(ltla_pop_summary_data, function (d) {
    return d.Area;
  })
  .keys();

// ! Render LTLA table on load
window.onload = () => {
  loadTable_ltla_population_summary(ltla_pop_summary_data);
};


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
  return d.Area === chosen_pyramid_area })

chosen_pyramid_summary_data = ltla_pop_summary_data.filter(function(d,i){
    return d.Area === chosen_pyramid_area }) 
 
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


// ! ASR pyramid

$.ajax({
  url: "./outputs/Disability_ASP_data.json",
  dataType: "json",
  async: false,
  success: function(data) {
    Census_asr_pyramid_data = data;
   console.log('Area pyramid data successfully loaded.')},
  error: function (xhr) {
    alert('Area pyramid data not loaded - ' + xhr.statusText);
  },
});

var margin_middle = 80,
    height_asr = window.innerHeight * 0.5 + (margin_middle/2),
    asr_pyramid_plot_width = (height_asr/2) - (margin_middle/2),
    male_zero = asr_pyramid_plot_width,
    female_zero = asr_pyramid_plot_width + margin_middle;

// append the svg object to the body of the page
var svg_asr_pyramid = d3.select("#asr_pyramid_census_datavis")
.append("svg")
.attr("width", height_asr + (margin_middle/2))
.attr("height",  height_asr + (margin_middle/2))
.append("g")

var asr_area_list = d3
  .map(higher_disability_table, function (d) {
    return d.Area_name;
  })
  .keys();

// We need to create a dropdown button for the user to choose which area to be displayed on the figure.
d3.select("#select_area_asr_pyramid_button")
  .selectAll("myOptions")
  .data(asr_area_list)
  .enter()
  .append("option")
  .text(function (d) {
    return d;
  })
  .attr("value", function (d) {
    return d;
  });

// Retrieve the selected area name
var chosen_asr_pyramid_area = d3
  .select("#select_area_asr_pyramid_button")
  .property("value");

// Use the value from chosen_pcn_asr_pyramid_area to populate a title for the figure. This will be placed as the element 'selected_pcn_asr_pyramid_title' on the webpage
d3.select("#selected_area_asr_pyramid_title").html(function (d) {
  return (
    "Figure - Age-specific prevalence of disability; " +
    chosen_asr_pyramid_area +
    " compared to England; usual resident population; Census 2021"   
   );
 });

// var age_levels = ["Under 1",  "1 to 4",   "5 to 9", "10 to 14", "15 to 19" ,"20 to 24", "25 to 29", "30 to 34", "35 to 39", "40 to 44", "45 to 49", "50 to 54", "55 to 59", "60 to 64", "65 to 69", "70 to 74", "75 to 79", "80 to 84", "85 to 89", "90+"]

var age_levels = ["0-9 years", "10-14 years", "15-24 years", "25-34 years", "35-44 years", "45-54 years", "55-64 years", "65-74 years", "75-84 years", "85+ years"]

Census_asr_pyramid_data.sort(function(a,b) {
  return age_levels.indexOf(a.Age) > age_levels.indexOf(b.Age)});

// Filter to get out chosen dataset
chosen_asr_pyramid_data = Census_asr_pyramid_data.filter(function(d,i){
  return d.Area_name === chosen_asr_pyramid_area })

// Filter to get out chosen dataset
comparator_asr_pyramid_data = Census_asr_pyramid_data.filter(function(d,i){
  return d.Area_name === 'England' })

 var maxPopulation_static_pyr = 1;

// the scale goes from 0 to the width of the asr_pyramid plotting region. We will invert this for the left x-axis
var x_static_asr_pyramid_scale_male = d3.scaleLinear()
 .domain([0, maxPopulation_static_pyr])
 .range([male_zero, (0 + margin_middle/4)])
 .nice();

var xAxis_static_asr_pyramid = svg_asr_pyramid
 .append("g")
 .attr("transform", "translate(0," + height_asr + ")")
 .call(d3.axisBottom(x_static_asr_pyramid_scale_male).ticks(5).tickFormat(d3.format(",.1%")))
 
//  xAxis_static_asr_pyramid.tickFormat(d3.format(".2s"));

 var x_static_asr_pyramid_scale_female = d3.scaleLinear()
 .domain([0, maxPopulation_static_pyr])
 .range([female_zero, (height_asr - margin_middle/4)])
 .nice()

var xAxis_static_asr_pyramid_2 = svg_asr_pyramid
 .append("g")
 .attr("transform", "translate(0," + height_asr + ")")
 .call(d3.axisBottom(x_static_asr_pyramid_scale_female).ticks(5));

 var asr_pyramid_scale_bars = d3.scaleLinear()
 .domain([0, maxPopulation_static_pyr])
 .range([0, (asr_pyramid_plot_width - margin_middle/4)]);

var y_asr_pyramid_scale = d3.scaleBand()
 .domain(age_levels)
 .range([height_asr, 0])
 .padding([0.2]);

 var yaxis_pos = height_asr/2
 
 var yAxis_static_asr_pyramid = svg_asr_pyramid
 .append("g")
 .attr("transform", "translate(0" + yaxis_pos + ",0)")
 .call(d3.axisLeft(y_asr_pyramid_scale).tickSize(0))
 .style('text-anchor', 'middle')
 .select(".domain").remove()

svg_asr_pyramid
   .selectAll("myRect")
   .data(chosen_asr_pyramid_data)
   .enter()
   .append("rect")
   .attr("class", "asr_pyramid_1")
   .attr("x", female_zero)
   .attr("y", function(d) { return y_asr_pyramid_scale(d.Age); })
   .attr("width", function(d) { return asr_pyramid_scale_bars(d.Female); })
   .attr("height", y_asr_pyramid_scale.bandwidth())
   .attr("fill", "#f1c232")
 
svg_asr_pyramid
  .selectAll("myRect")
  .data(chosen_asr_pyramid_data)
  .enter()
  .append("rect")
  .attr("class", "asr_pyramid_1")
  .attr("x", function(d) { return male_zero - asr_pyramid_scale_bars(d.Male); })
  .attr("y", function(d) { return y_asr_pyramid_scale(d.Age); })
  .attr("width", function(d) { return asr_pyramid_scale_bars(d.Male); })
  .attr("height", y_asr_pyramid_scale.bandwidth())
  .attr("fill", "#741b47")

svg_asr_pyramid
  .append("text")
  .attr("x", function(d) { return male_zero - asr_pyramid_scale_bars(maxPopulation_static_pyr)})
  .attr("y", 30)
  .attr("id", "pyramid_sex_label_male")
  .attr("text-anchor", "start")
  .attr("class", "pyramid_1")
  .style("font-weight", "bold")
  .style("font-size", "12px")
  .text('Males')
 
svg_asr_pyramid
  .append("text")
  .attr("x", function(d) { return female_zero + asr_pyramid_scale_bars(maxPopulation_static_pyr)})
  .attr("y", 30)
  .attr("id", "pyramid_sex_label_female")
  .attr("text-anchor", "end")
  .attr("class", "pyramid_1")
  .style("font-weight", "bold")
  .style("font-size", "12px")
  .text('Females')
 

function render_asr_pyramid(d) {
  var chosen_asr_pyramid_area = d3
    .select("#select_area_asr_pyramid_button")
    .property("value");
   
    d3.select("#selected_area_asr_pyramid_title").html(function (d) {
      return (
        "Figure - Age-specific prevalence of disability; " +
        chosen_asr_pyramid_area +
        " compared to England; usual resident population; Census 2021"   
       );
     });

chosen_asr_pyramid_data = Census_asr_pyramid_data.filter(function(d,i){
  return d.Area_name === chosen_asr_pyramid_area })
   
// fin
    
svg_asr_pyramid.selectAll(".asr_pyramid_1").remove();

var maxPopulation_static_pyr = 1

x_static_asr_pyramid_scale_male
  .domain([0, maxPopulation_static_pyr])
  
x_static_asr_pyramid_scale_female 
  .domain([0, maxPopulation_static_pyr])
  
asr_pyramid_scale_bars 
  .domain([0,maxPopulation_static_pyr])

xAxis_static_asr_pyramid 
  .transition()
  .duration(1000)
  .call(d3.axisBottom(x_static_asr_pyramid_scale_male).ticks(5).tickFormat(d3.format(",.0%")))
 
 xAxis_static_asr_pyramid_2
 .transition()
 .duration(1000)
 .call(d3.axisBottom(x_static_asr_pyramid_scale_female).ticks(5).tickFormat(d3.format(",.0%")))

svg_asr_pyramid
   .selectAll("myRect")
   .data(chosen_asr_pyramid_data)
   .enter()
   .append("rect")
   .attr("class", "asr_pyramid_1")
   .attr("x", female_zero)
   .attr("y", function(d) { return y_asr_pyramid_scale(d.Age); })
   .attr("width", function(d) { return asr_pyramid_scale_bars(d.Female); })
   .attr("height", y_asr_pyramid_scale.bandwidth())
   .attr("fill", "#f1c232")
   
svg_asr_pyramid
  .selectAll("myRect")
  .data(chosen_asr_pyramid_data)
  .enter()
  .append("rect")
  .attr("class", "asr_pyramid_1")
  .attr("x", function(d) { return male_zero - asr_pyramid_scale_bars(d.Male); })
  .attr("y", function(d) { return y_asr_pyramid_scale(d.Age); })
  .attr("width", function(d) { return asr_pyramid_scale_bars(d.Male); })
  .attr("height", y_asr_pyramid_scale.bandwidth())
  .attr('fill', 'none')
  .attr("fill", "#741b47")
 

// Comparator


svg_asr_pyramid
   .selectAll("myRect")
   .data(comparator_asr_pyramid_data)
   .enter()
   .append("rect")
   .attr("class", "asr_pyramid_1_comp")
   .attr("x", female_zero)
   .attr("y", function(d) { return y_asr_pyramid_scale(d.Age); })
   .attr("width", function(d) { return asr_pyramid_scale_bars(d.Female); })
   .attr("height", y_asr_pyramid_scale.bandwidth())
   .attr('fill', 'none')
   .attr("stroke", "#003366")
   .style("stroke-dasharray", ("3, 3"))
 
svg_asr_pyramid
  .selectAll("myRect")
  .data(comparator_asr_pyramid_data)
  .enter()
  .append("rect")
  .attr("class", "asr_pyramid_1_comp")
  .attr("x", function(d) { return male_zero - asr_pyramid_scale_bars(d.Male); })
  .attr("y", function(d) { return y_asr_pyramid_scale(d.Age); })
  .attr("width", function(d) { return asr_pyramid_scale_bars(d.Male); })
  .attr("height", y_asr_pyramid_scale.bandwidth())
  .attr('fill', 'none')
  .attr("stroke", "#999999")
  .style("stroke-dasharray", ("3, 3"))


}

render_asr_pyramid()
     
// The .on('change) part says when the drop down menu (select element) changes then retrieve the new selected area name and then use it to update the selected_pcn_asr_pyramid_title element 
d3.select("#select_area_asr_pyramid_button").on("change", function (d) {
render_asr_pyramid()
});

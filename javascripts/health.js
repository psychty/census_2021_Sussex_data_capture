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

console.log(unpaid_care_df)

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
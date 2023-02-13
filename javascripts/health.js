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

// TODO join LSOA PCN data to the lsoa_health_data object

// console.log(lsoa_to_pcn_data)
// console.log(lsoa_health_data)

// Health
var health_df =  lsoa_health_data.filter(function (d) {
  return d.Topic == 'Health';
});

// I thought it might be because there were multiple occurences (perhaps multiple indexes of the main key (LSOA)) it did not make a difference
// var health_df =  lsoa_health_data.filter(function (d) {
  // return d.Topic == 'Health' && d.Category == 'Good or very good health';
// });

// TODO create a PCN and LTLA version of these datasets

// console.log(health_df)

// Disability
var disability_df =  lsoa_health_data.filter(function (d) {
  return d.Topic == 'Disability';
});

// console.log(disability_df)

// Provision of unpaid care 
var unpaid_care_df =  lsoa_health_data.filter(function (d) {
  return d.Topic == 'Unpaid care';
});

// console.log(unpaid_care_df)

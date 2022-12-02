var width = window.innerWidth * 0.8 - 20;
var height = width * 0.8;
if (width > 900) {
  var width = 900;
  var height = width * .6;
}
var width_margin = width * 0.15;

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

window.onload = () => {
  loadTable_lsoa_change_summary(lsoa_changes_summary_data);
};

// Change table 
function loadTable_lsoa_change_summary(lsoa_changes_summary_data) {
  const tableBody = document.getElementById("table_change_1");
  var dataHTML = "";

  for (let item of lsoa_changes_summary_data) {
    dataHTML += `<tr><td>${item.LTLA}</td><td>${item.UTLA}</td><td>${d3.format(",.0f")(item.LSOAs_in_2011)}</td><td>${d3.format(',.0f')(item.Unchanged)}</td><td>${d3.format(",.0f")(item.Split)}</td><td>${d3.format(",.0f")(item.Merged)}</td><td>${d3.format(",.0f")(item.LSOAs_in_2021)}</td><td>${d3.format(",.0f")(item.Difference)}</td></tr>`;
  }
  tableBody.innerHTML = dataHTML;
}
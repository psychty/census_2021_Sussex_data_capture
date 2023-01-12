

for (var i = 1; i <= Sussex_pcn_summary_df.length; i++) {

this['pcn_' + i + '_group'] = L.layerGroup();
this['pcn_' + i] = PCNs[i - 1]
this['pcn_' + i + '_boundary'] = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
         filter: function(feat) { return feat.properties.PCN_Name === this['pcn_' + i]; }
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
this['pcn_' + i + '_boundary'].addTo(this['pcn_' + i + '_group'])

// filter GP markers
this['pcn_gp_location_' + i] = GP_location.filter(function (d) {
  return d.PCN_Name == this['pcn_' + i];
});

// This loops through the Local_GP_location dataframe and plots a marker for every record.
for (var k = 0; k < this['pcn_gp_location_' + i].length; i++) {
new L.circleMarker([this['pcn_gp_location_' + i][k]['latitude'], this['pcn_gp_location_' + i][k]['longitude']],{
     radius: 8,
     weight: .5,
     fillColor: gp_marker_colour,
     color: '#000',
     fillOpacity: 1})
    .bindPopup('<Strong>' + 
    this['pcn_gp_location_' + i][k]['ODS_Code'] + 
    ' ' + 
    this['pcn_gp_location_' + i][k]['ODS_Name'] + 
    '</Strong><br><br>This practice is part of the ' + 
    this['pcn_gp_location_' + i][k]['PCN_Name'] +
    '. There are <Strong>' + 
    d3.format(',.0f')(this['pcn_gp_location_' + i][k]['Patients']) + 
    '</Strong> patients registered to this practice.' )
   .addTo(this['pcn_' + i + '_group']) // These markers are directly added to the layer group
  };

}
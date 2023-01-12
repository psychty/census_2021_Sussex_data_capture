// ! PCN 40
pcn_40_group = L.layerGroup();
pcn_40 = PCNs[40 - 1]
var pcn_40_boundary = L.geoJSON(PCN_ReachLSOA11_geojson.responseJSON, {
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

pcn_40_group.addTo(map_lsoa_pcn_reach) // This is our first PCN we want to initialise on the page     

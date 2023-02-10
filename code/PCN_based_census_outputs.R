
# PCN based census outputs

# Loading some packages 
packages <- c('easypackages','readxl', 'tidyr', 'dplyr', 'readr', "rgdal", 'nomisr', 'rgeos', "tmaptools", 'sp', 'sf', 'maptools', 'leaflet', 'leaflet.extras', 'leaflet.extras2', 'spdplyr', 'geojsonio', 'rmapshaper', 'jsonlite', 'httr', 'rvest', 'stringr', 'scales', 'xfun', 'viridis', 'PostcodesioR', 'ggplot2')
install.packages(setdiff(packages, rownames(installed.packages())))
easypackages::libraries(packages)

local_store <- '~/Repositories/census_2021_Sussex_data_capture/raw_data'
output_directory <- '~/Repositories/census_2021_Sussex_data_capture/outputs'

# We need to somehow align 2011 LSOAs to 2021 MSOAs so that we can get roughly the population coverage we need.

# We need to designate it as experimental. 

# How do method two PCN boundaries align with MSOAs?

# PCN boundaries ####
pcn_spdf <- st_read(paste0(output_directory, '/sussex_pcn_footprints_method_2.geojson')) %>% 
  as_Spatial(IDs = PCN_Name)

areas <- c('Brighton and Hove', 'Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden', 'Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing') 

# To do this we can use a 2021 LSOA lookup, built up from an output area lookup 
oa21_lookup <- read_csv('https://www.arcgis.com/sharing/rest/content/items/792f7ab3a99d403ca02cc9ca1cf8af02/data')

# We can also create an LSOA lookup by subsetting this dataframe
Sussex_lsoa21_lookup <- oa21_lookup %>% 
  select(LSOA21CD = lsoa21cd, LSOA21NM = lsoa21nm, MSOA21CD = msoa21cd, MSOA21NM = msoa21nm, LTLA = lad22nm) %>% 
  unique() %>% 
  filter(LTLA %in% areas)

Sussex_msoa21_lookup <-  oa21_lookup %>% 
  select(MSOA21CD = msoa21cd, MSOA21NM = msoa21nm, LTLA = lad22nm) %>% 
  unique() %>% 
  filter(LTLA %in% areas)

# LSOA 2021 boundaries
lsoa_2021_spdf <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA_Dec_2021_Boundaries_Generalised_Clipped_EW_BGC_2022/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  filter(LSOA21CD %in% Sussex_lsoa21_lookup$LSOA21CD) %>% 
  as_Spatial(IDs = LSOA2CD)

oa11_lookup <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/OA11_LSOA11_MSOA11_LAD20_RGN20_EW_LU_a1cf695c9b074c708921b2a7555f808a/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  st_drop_geometry()

# We can also create an LSOA lookup by subsetting this dataframe
lsoa11_lookup <- oa11_lookup %>% 
  select(LSOA11CD, LSOA11NM, MSOA11CD, MSOA11NM, LTLA = LAD20NM) %>% 
  unique() %>% 
  filter(LTLA %in% areas)

# This is extracting a geojson format file from open geography portal. It has geometry information as well as the information we need and is a spatial features object. By adding the st_drop_geometry() function we turn this into a dataframe
lsoa_change_df <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA11_LSOA21_LAD22_EW_LU/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  select(Original_LSOA11CD = F_LSOA11CD, LSOA21CD, LSOA21NM, LTLA = LAD22NM, Change = CHGIND) %>% 
  st_drop_geometry() %>% 
  mutate(Change = factor(ifelse(Change == 'M', 'Merged', ifelse(Change == 'S', 'Split', ifelse(Change == 'X', 'Redefined', ifelse(Change == 'U', 'Unchanged', NA)))), levels = c('Unchanged', 'Merged', 'Split', 'Redefined')))

lsoa_change_df1 <- lsoa_change_df %>% 
  filter(Original_LSOA11CD %in% lsoa11_lookup$LSOA11CD) %>% 
  select(Original_LSOA11CD, Change) %>% 
  unique()

lsoa_2011_spdf <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA_Dec_2011_Boundaries_Generalised_Clipped_BGC_EW_V3_2022/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  filter(LSOA11CD %in% lsoa11_lookup$LSOA11CD) %>% 
  as_Spatial(IDs = LSOA11CD) %>% 
  left_join(lsoa_change_df1, by = c('LSOA11CD' = 'Original_LSOA11CD'))

unique(lsoa_2011_spdf$Change)

change_colours <- c('#c9c9c9', '#da20b2', '#20b2da', '#ff1a55')

change_palette <- colorFactor(change_colours,
                              levels = levels(lsoa_2011_spdf$Change))

leaflet(lsoa_2011_spdf) %>% 
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
           attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a><br>Contains Royal Mail data<br>Reproduced under Open Government Licence<br>&copy Crown copyright<br>Zoom in/out using your mouse wheel<br>Click on an area to find out more.') %>%
  addPolygons(data = lsoa_2011_spdf,
              stroke = TRUE, 
              color = "#000000",
              fillColor = ~change_palette(Change),
              fillOpacity = .8,
              weight = 1,
              popup = paste0('LSOA 2011: ', lsoa_2011_spdf$LSOA11NM, ' (', lsoa_2011_spdf$LSOA11CD, ')'),
              group = 'Show 2011 boundaries') %>% 
  addPolygons(data = lsoa_2021_spdf,
              stroke = TRUE, 
              fill = FALSE,
              color = "purple",
              label = paste0(lsoa_2021_spdf$LSOA21CD, ' (', lsoa_2021_spdf$LSOA21NM, ')'),
              popup = paste0('LSOA 2021: ', lsoa_2021_spdf$LSOA21NM, ' (', lsoa_2021_spdf$LSOA21CD, ')'),
              weight = 1,
              group = 'Show 2021 boundaries') %>%
  addLegend(position = 'topright',
            colors = change_colours,
            labels = levels(lsoa_2011_spdf$Change),
            title = 'LSOA Changes<br>between 2011 and 2021',
            opacity = 1) %>% 
  addLayersControl(overlayGroups = c('Show 2011 boundaries', 'Show 2021 boundaries'),
                   options = layersControlOptions(collapsed = FALSE))

leaf_map <- leaflet(lsoa_2021_spdf,
        options = leafletOptions(zoomControl = TRUE)) %>%
  addControl(paste0("<font size = '1px'><b>Sussex 2011 LSOAs</font>"),
             position='topleft') %>% 
  addControl(paste0("<font size = '1px'><b>Sussex 2021 LSOAs</font>"),
             position='topright') %>% 
  addMapPane("left", zIndex = 0) %>%
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
           attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a><br>Contains Royal Mail data<br>Reproduced under Open Government Licence<br>&copy Crown copyright<br>Zoom in/out using your mouse wheel<br>Click on an area to find out more.',
           layerId = "left_layer",
           options = pathOptions(pane = "left")) %>%
  addPolygons(data = lsoa_2011_spdf,
              stroke = TRUE, 
              color = "#000000",
              fillColor = ~change_palette(Change),
              fillOpacity = .8,
              weight = 1,
              popup = paste0('LSOA 2011: ', lsoa_2011_spdf$LSOA11NM, ' (', lsoa_2011_spdf$LSOA11CD, ')'),
              options = pathOptions(pane = "left"),
              group = 'Show 2011 boundaries') %>% 
  addPolygons(data = lsoa_2021_spdf,
              stroke = TRUE,
              fillColor = 'orange',
              fillOpacity = .3,
              color = "purple",
              popup = paste0('LSOA 2021: ', lsoa_2021_spdf$LSOA21NM, ' (', lsoa_2021_spdf$LSOA21CD, ')'),
              weight = 1,
              group = 'Show 2021 boundaries',
              options = pathOptions(pane = "left")) %>%
  addPolygons(data = pcn_spdf,
              fill = FALSE,
              stroke = TRUE, 
              color = "maroon",
              weight = 4,
              label = paste0(pcn_spdf$PCN_Name),
              options = pathOptions(pane = "left"),
              group = 'Show PCN boundaries') %>% 
  addMapPane("right", zIndex = 0) %>% 
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
           attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a><br>Contains Royal Mail data<br>Reproduced under Open Government Licence<br>&copy Crown copyright<br>Zoom in/out using your mouse wheel<br>Click on an area to find out more.',
           layerId = "right_layer",
           options = pathOptions(pane = "right")) %>%
  addPolygons(data = lsoa_2011_spdf,
              stroke = TRUE, 
              color = "#000000",
              fillColor = ~change_palette(Change),
              fillOpacity = .8,
              weight = 1,
              popup = paste0('LSOA 2011: ', lsoa_2011_spdf$LSOA11NM, ' (', lsoa_2011_spdf$LSOA11CD, ')'),
              options = pathOptions(pane = "right"),
              group = 'Show 2011 boundaries') %>% 
  addPolygons(data = lsoa_2021_spdf,
              stroke = TRUE,
              fillColor = 'orange',
              fillOpacity = .3,
              color = "purple",
              popup = paste0('LSOA 2021: ', lsoa_2021_spdf$LSOA21NM, ' (', lsoa_2021_spdf$LSOA21CD, ')'),
              weight = 1,
              group = 'Show 2021 boundaries',
              options = pathOptions(pane = "right")) %>%
  addSidebyside(layerId = "sidecontrols",
                leftId = "left_layer",
                rightId = "right_layer") %>% 
  addLegend(position = 'topright',
            colors = change_colours,
            labels = levels(lsoa_2011_spdf$Change),
            title = 'LSOA Changes<br>between 2011 and 2021',
            opacity = 1) %>% 
  addLayersControl(overlayGroups = c('Show PCN boundaries', 'Show 2011 boundaries','Show 2021 boundaries'),
                   options = layersControlOptions(collapsed = FALSE))

leaf_map <- leaf_map %>% 
  hideGroup(c('Show 2021 boundaries'))

# Export the map as a html file
htmlwidgets::saveWidget(leaf_map,
                        paste0(output_directory, '/lsoa_2011_changes_map.html'),
                        selfcontained = TRUE)

pcn_sf <- st_read(paste0(output_directory, '/sussex_pcn_footprints_method_2.geojson')) 

lsoa_2021_sf <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA_Dec_2021_Boundaries_Generalised_Clipped_EW_BGC_2022/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  filter(LSOA21CD %in% Sussex_lsoa21_lookup$LSOA21CD)

# Does not work
# geo_join <- st_join(pcn_sf, lsoa_2021_sf, left = FALSE, largest = TRUE)

lsoa_centroids <- st_point_on_surface(lsoa_2021_sf) %>% 
  as_Spatial()

LSOA_PCN_lookup <- cbind(lsoa_centroids, over(lsoa_centroids, pcn_spdf))
                         
lsoa_2021_spdf <- cbind(lsoa_2021_spdf, over(lsoa_2021_spdf, pcn_spdf))


LSOA_PCN_lookup

leaflet(lsoa_2021_spdf) %>% 
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
           attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a><br>Contains Royal Mail data<br>Reproduced under Open Government Licence<br>&copy Crown copyright<br>Zoom in/out using your mouse wheel<br>Click on an area to find out more.') %>%
  addPolygons(data = pcn_spdf,
              fill = FALSE,
              stroke = TRUE, 
              color = "maroon",
              weight = 4,
              label = paste0(pcn_spdf$PCN_Name),
              group = 'Show PCN boundaries from 2011 LSOAs') %>% 
  addPolygons(data = lsoa_2021_spdf,
              stroke = TRUE,
              fillColor = 'orange',
              fillOpacity = .3,
              color = "purple",
              popup = paste0('LSOA 2021: ', lsoa_2021_spdf$LSOA21NM, ' (', lsoa_2021_spdf$LSOA21CD, ')'),
              weight = 1,
              group = 'Show 2021 boundaries') %>%
  addCircleMarkers(LSOA_PCN_lookup)
  addLayersControl(overlayGroups = c('Show PCN boundaries from 2011 LSOAs', 'Show 2021 boundaries'),
                   options = layersControlOptions(collapsed = FALSE))


# method_3 ####

# We need to create a single geojson file that has our PCN boundaries.
for(i in 1:length(unique(LSOA_PCN_lookup@data$PCN_Name))){
  pcn_x <- unique(LSOA_PCN_lookup@data$PCN_Name)[i]
  
  pcn_footprint_x_df <- LSOA_PCN_lookup@data %>% 
    filter(PCN_Name == pcn_x) %>% 
    select(PCN_Name) %>% 
    unique()
  
  pcn_x_footprint <-  LSOA_PCN_lookup %>% 
    filter(PCN_Name %in% pcn_x) %>% 
    gUnaryUnion()
  
  assign(paste0('pcn_footprint_', i),  SpatialPolygonsDataFrame(pcn_x_footprint, pcn_footprint_x_df))
  
}

method_3_footprint <- rbind(pcn_footprint_1, pcn_footprint_2, pcn_footprint_3,  pcn_footprint_4, pcn_footprint_5, pcn_footprint_6, pcn_footprint_7,  pcn_footprint_8, pcn_footprint_9, pcn_footprint_10, pcn_footprint_11,  pcn_footprint_12, pcn_footprint_13, pcn_footprint_14, pcn_footprint_15,  pcn_footprint_16, pcn_footprint_17, pcn_footprint_18, pcn_footprint_19,  pcn_footprint_20, pcn_footprint_21, pcn_footprint_22, pcn_footprint_23,  pcn_footprint_24, pcn_footprint_25, pcn_footprint_26, pcn_footprint_27,  pcn_footprint_28, pcn_footprint_29, pcn_footprint_30, pcn_footprint_31,  pcn_footprint_32, pcn_footprint_33, pcn_footprint_34, pcn_footprint_35,  pcn_footprint_36, pcn_footprint_37, pcn_footprint_38) 



leaflet(lsoa_2021_spdf,
        options = leafletOptions(zoomControl = TRUE)) %>%
  addControl(paste0("<font size = '1px'><b>Sussex 2011 LSOAs</font>"),
             position='topleft') %>% 
  addControl(paste0("<font size = '1px'><b>Sussex 2021 LSOAs</font>"),
             position='topright') %>% 
  addMapPane("left", zIndex = 0) %>%
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
           attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a><br>Contains Royal Mail data<br>Reproduced under Open Government Licence<br>&copy Crown copyright<br>Zoom in/out using your mouse wheel<br>Click on an area to find out more.',
           layerId = "left_layer",
           options = pathOptions(pane = "left")) %>%
  addPolygons(data = pcn_spdf,
              fill = FALSE,
              stroke = TRUE, 
              color = "maroon",
              weight = 4,
              label = paste0(pcn_spdf$PCN_Name),
              options = pathOptions(pane = "left"),
              group = 'Show PCN boundaries from 2011 LSOAs') %>% 
  addMapPane("right", zIndex = 0) %>% 
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
           attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a><br>Contains Royal Mail data<br>Reproduced under Open Government Licence<br>&copy Crown copyright<br>Zoom in/out using your mouse wheel<br>Click on an area to find out more.',
           layerId = "right_layer",
           options = pathOptions(pane = "right")) %>%
  addPolygons(data = method_3_footprint,
              fill = FALSE,
              stroke = TRUE, 
              color = "purple",
              weight = 4,
              label = paste0(method_3_footprint$PCN_Name),
              options = pathOptions(pane = "right"),
              group = 'Show PCN boundaries from 2021 LSOAs') %>% 
  addSidebyside(layerId = "sidecontrols",
                leftId = "left_layer",
                rightId = "right_layer") %>% 
  addLayersControl(overlayGroups = c('Show PCN boundaries from 2011 LSOAs', 'Show PCN boundaries from 2021 LSOAs'),
                   options = layersControlOptions(collapsed = FALSE))



# Census data ####

# I have created a lookup for the area types that nomisr uses for Census 21, these are different to other datasets so bear this in mind
nomis_area_types <- data.frame(Level = c('OA','LSOA','MSOA','LTLA', 'UTLA', 'Region'), Area_type_code = c('150','151','152','154', '155','480'))

# We will want to filter the datasets for just Sussex areas, it is not practical to do this within the nomis call (to specify 1,029 areas to the api call), so whilst it takes a while to extract all LSOAs in england, you can filter afterwards.

# This is a really useful function from the nomisr package to help identify the table id you want.
nomis_tables <- nomis_data_info() %>% 
  select(id, components.dimension, name.value) # We really only need three fields from this table


# Health ####

# *At the moment there are only topic summaries available from nomis so it might be possible to use that information to retrieve a table of just census 21 files.

census_nomis_tables <- nomis_tables %>% 
  filter(str_detect(name.value, '^TS'))

census_nomis_tables %>% 
  View()

# Lets say we want to use the lsoa level disability
table_x <- nomis_tables %>% 
  filter(id == 'NM_2056_1')

table_x$components.dimension

names(census_LSOA_disability_raw_df)


census_LSOA_disability_raw_df <- nomis_get_data(id = table_x$id,
                                                measure = '20100',
                                                geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, LSOA21NM = GEOGRAPHY_NAME, Disability = C2021_DISABILITY_5_NAME, Population = OBS_VALUE) %>% 
  filter(LSOA21CD %in% Sussex_lsoa21_lookup$LSOA21CD)

unique(census_LSOA_disability_raw_df$Disability)

census_LSOA_disability_df <- census_LSOA_disability_raw_df %>% 
  group_by(Disability) %>% 
  summarise(Population = sum(Population))
  
  


  
   
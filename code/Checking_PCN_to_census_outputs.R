
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

PCN_Meta <- fromJSON(paste0(output_directory, '/Sussex_PCN_summary_df.json'))

# This is missing the unallocated Brighton PCN, and we need to make a factor of this field (PCN Name)
Method_2_LSOA_based_PCN_df <- read_csv(paste0(output_directory, '/Method_2_LSOA_based_PCN_df.csv')) %>% 
  mutate(PCN_Name = factor(PCN_Name, levels = PCN_Meta$PCN_Name))

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
# htmlwidgets::saveWidget(leaf_map,
#                         paste0(output_directory, '/lsoa_2011_changes_map.html'),
#                         selfcontained = TRUE)

pcn_sf <- st_read(paste0(output_directory, '/sussex_pcn_footprints_method_2.geojson')) 

lsoa_2021_sf <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA_Dec_2021_Boundaries_Generalised_Clipped_EW_BGC_2022/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  filter(LSOA21CD %in% Sussex_lsoa21_lookup$LSOA21CD)

# Can we repeat PCN boundaries with Census 2021 LSOAs?

PCN_lsoa_change_df <- lsoa_change_df %>% 
  filter(Original_LSOA11CD %in% Method_2_LSOA_based_PCN_df$LSOA11CD) %>% 
  left_join(Method_2_LSOA_based_PCN_df, by = c('Original_LSOA11CD' =  'LSOA11CD')) %>% 
  mutate(PCN_Name = factor(PCN_Name)) %>% 
  select(!c(Original_LSOA11CD, Patients, LSOA21NM, Proportion_residents_to_PCN)) %>% 
  unique()

Method_3_LSOA_based_PCN_footprint <- lsoa_2021_spdf %>% 
  filter(LSOA21CD %in% PCN_lsoa_change_df$LSOA21CD) %>%
  left_join(PCN_lsoa_change_df, by = 'LSOA21CD')

# PCN_object <- Method_3_LSOA_based_PCN_footprint %>% 
#   group_by(PCN_Name) %>% 
#   summarise()

PCN_palette <- colorFactor(c("#92a0d6","#74cf3d","#4577ff","#449e00","#e84fcd","#02de71","#f68bff","#63df6b","#8f227f","#508000","#4646a9","#deab00","#0295e8","#c44e00","#02caf9","#ff355c","#01c2a0","#a50c35","#019461","#ff7390","#00afa6","#ff8753","#0063a5","#c5cd5d","#0a5494","#897400","#b2afff","#395c0a","#f7afed","#90d78a","#9b2344","#00796b","#ff836f","#81b6ff","#843f22","#524b85","#dfc47c","#853a4a","#f8b892","#ff91b9"),
                              levels = levels(Method_3_LSOA_based_PCN_footprint$PCN_Name))
leaflet(lsoa_2011_spdf) %>% 
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
           attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a><br>Contains Royal Mail data<br>Reproduced under Open Government Licence<br>&copy Crown copyright<br>Zoom in/out using your mouse wheel<br>Click on an area to find out more.') %>%
  addPolygons(data = Method_3_LSOA_based_PCN_footprint,
              stroke = TRUE, 
              color = "#000000",
              fillColor = ~PCN_palette(PCN_Name),
              fillOpacity = .8,
              weight = 1,
              popup = paste0(Method_3_LSOA_based_PCN_footprint$PCN_Name),
              group = 'Show PCN boundaries from 2021 LSOAs') %>% 
  addPolygons(data = pcn_spdf,
              fill = FALSE,
              stroke = TRUE, 
              color = "maroon",
              weight = 4,
              label = paste0(pcn_spdf$PCN_Name),
              group = 'Show PCN boundaries from 2011 LSOAs') %>% 
  addLayersControl(overlayGroups = c('Show PCN boundaries from 2011 LSOAs', 'Show PCN boundaries from 2021 LSOAs'),
                   options = layersControlOptions(collapsed = FALSE))


# Checking by PCN ####

i = 40
pcn_x <- levels(Method_3_LSOA_based_PCN_footprint$PCN_Name)[i]

pcn_x_lsoas <- Method_3_LSOA_based_PCN_footprint %>%
  filter(PCN_Name == pcn_x)

pcn_foot <- pcn_spdf %>% 
  filter(PCN_Name == pcn_x)

leaflet() %>% 
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
           attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a><br>Contains Royal Mail data<br>Reproduced under Open Government Licence<br>&copy Crown copyright<br>Zoom in/out using your mouse wheel<br>Click on an area to find out more.') %>%
  addPolygons(data = pcn_x_lsoas,
              stroke = TRUE, 
              color = "#000000",
              fillColor = 'pink',
              fillOpacity = .8,
              weight = 1,
              popup = paste0(pcn_x_lsoas$LSOA21CD),
              group = 'Show PCN boundaries from 2021 LSOAs') %>% 
  addPolygons(data = pcn_foot,
              fill = FALSE,
              stroke = TRUE, 
              color = "purple",
              weight = 4,
              label = paste0(pcn_spdf$PCN_Name),
              group = 'Show PCN boundaries from 2011 LSOAs') %>% 
  addLayersControl(overlayGroups = c('Show PCN boundaries from 2011 LSOAs', 'Show PCN boundaries from 2021 LSOAs'),
                   options = layersControlOptions(collapsed = FALSE))

# Good enough for me, lets start bulding PCN census profile

final_lsoa_pcn_lookup <- PCN_lsoa_change_df %>% 
  select(!Change)

final_lsoa_pcn_lookup %>% 
  write.csv(paste0(output_directory, '/lsoa_2021_lookup_to_Sussex_PCNs.csv'),
            row.names = FALSE)

  
   
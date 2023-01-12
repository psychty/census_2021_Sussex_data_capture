# Loading some packages 
packages <- c('easypackages','readxl', 'tidyr', 'dplyr', 'readr', "rgdal", 'nomisr', 'rgeos', "tmaptools", 'sp', 'sf', 'maptools', 'leaflet', 'leaflet.extras', 'spdplyr', 'geojsonio', 'rmapshaper', 'jsonlite', 'httr', 'rvest', 'stringr', 'scales', 'xfun', 'viridis', 'PostcodesioR', 'ggplot2')
install.packages(setdiff(packages, rownames(installed.packages())))
easypackages::libraries(packages)

local_store <- '~/Repositories/census_2021_Sussex_data_capture/raw_data'
output_directory <- '~/Repositories/census_2021_Sussex_data_capture/outputs'

areas <- c('Brighton and Hove', 'Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden', 'Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing') 

options(scipen = 999)

# We will need this a bit later 

# This is extracting a geojson format file from open geography portal. It has geometry information as well as the information we need and is a spatial features object. By adding the st_drop_geometry() function we turn this into a dataframe
lsoa_change_df <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA11_LSOA21_LAD22_EW_LU/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  select(LSOA11CD = F_LSOA11CD, LSOA11NM, LSOA21CD, LSOA21NM, LTLA = LAD22NM, Change = CHGIND) %>% 
  st_drop_geometry() %>% 
  mutate(Change = ifelse(Change == 'M', 'Merged', ifelse(Change == 'S', 'Split', ifelse(Change == 'X', 'Redefined', ifelse(Change == 'U', 'Unchanged', NA)))))

# GP Practice registered populations ####

# October 2022 is the most recent release with an LSOA file. These are usually released once per quarter. We may find that on the January release (due on 12th Jan) this can be updated.
time_period <- 'january-2023' 

# We need the latest release that has the LSOA level numbers we need. As such, we need to specify the January 2022 release.
calls_patient_numbers_webpage <- read_html(paste0('https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/', time_period)) %>%
  html_nodes("a") %>%
  html_attr("href")

gp_mapping <- read_csv(unique(grep('gp-reg-pat-prac-map.csv', calls_patient_numbers_webpage, value = T))) %>%
  mutate(PRACTICE_NAME = gsub('Woodlands&Clerklands', 'Woodlands & Clerklands', gsub('\\(Aic\\)', '\\(AIC\\)', gsub('\\(Acf\\)', '\\(ACF\\)', gsub('Pcn', 'PCN', gsub('And', 'and',  gsub(' Of ', ' of ',  str_to_title(PRACTICE_NAME)))))))) %>%  
  mutate(PCN_NAME = gsub('\\(Aic\\)', '\\(AIC\\)', gsub('\\(Acf\\)', '\\(ACF\\)', gsub('Pcn', 'PCN', gsub('And', 'and',  gsub(' Of ', ' of ',  str_to_title(PCN_NAME))))))) %>%
  mutate(EXTRACT_DATE = paste0(ordinal(as.numeric(substr(EXTRACT_DATE,1,2))), ' ', substr(EXTRACT_DATE, 3,5), ' 20', substr(EXTRACT_DATE, 8,9))) %>% 
  select(Extract_date = EXTRACT_DATE, ODS_Code = PRACTICE_CODE, ODS_Name = PRACTICE_NAME, ICB_Name = SUB_ICB_LOCATION_NAME, Practice_postcode = PRACTICE_POSTCODE, PCN_Code = PCN_CODE, PCN_Name = PCN_NAME, Commissioning_region = COMM_REGION_NAME) %>% 
  mutate(PCN_Name = ifelse(PCN_Name == 'Unallocated', paste0(PCN_Name, ' - ', ODS_Name), PCN_Name)) # Primary care organisations are still part of the ICB even if they are not allocated to a PCN (as with Brighton Station Health Centre). So we need to search based on ICB rather than PCN.

Extract_date = unique(gp_mapping$Extract_date)

# Geolocating practices ####

gp_mapping_sussex <- gp_mapping %>% 
  filter(str_detect(ICB_Name, '^NHS Sussex'))

for(i in 1:length(unique(gp_mapping_sussex$Practice_postcode))){
  
  if(i == 1){lookup_result <- data.frame(postcode = character(), longitude = double(), latitude = double())
  }
  
  lookup_result_x <- postcode_lookup(unique(gp_mapping_sussex$Practice_postcode)[i]) %>% 
    select(postcode, longitude, latitude)
  
  lookup_result <- lookup_result_x %>% 
    bind_rows(lookup_result) 
  
}

gp_locations <- gp_mapping_sussex %>%
  rename(postcode = Practice_postcode) %>% 
  left_join(lookup_result, by = 'postcode')  

# leaflet() %>% 
#   addControl(paste0("<font size = '2px'><b>Primary Care organisations; Sussex; as at ", Extract_date, "</b><br>Based on main GP practice details on registered address;</font>"),
#              position='topright') %>% 
#   addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',attribution = paste0('&copy; <a href=https://www.openstreetmap.org/copyright>OpenStreetMap</a> contributors &copy; <a href=https://carto.com/attributions>CARTO</a><br>Contains OS data ? Crown copyright and database right 2021<br>Zoom in/out using your mouse wheel or the plus (+) and minus (-) buttons and click on an area/circle to find out more.')) %>%
#   addCircleMarkers(lng = gp_locations$longitude,
#                    lat = gp_locations$latitude,
#                    radius = 4,
#                    color = '#000000',
#                    fillColor = 'purple',
#                    stroke = TRUE,
#                    weight = .75,
#                    fillOpacity = 1,
#                    popup = gp_locations$ODS_Name,
#                    group = 'Show GP practice') %>%
#   addScaleBar(position = "bottomleft") %>%
#   addMeasure(position = 'bottomleft',
#              primaryAreaUnit = 'sqmiles',
#              primaryLengthUnit = 'miles')



# Now we know that the file we want contains the string 'gp-reg-pat-prac-quin-age.csv' we can use that in the read_csv call.
# I have also tidied it a little bit by renaming the Sex field and giving R some meta data about the order in which the age groups should be
latest_gp_total_pop <- read_csv(unique(grep('gp-reg-pat-prac-all.csv', calls_patient_numbers_webpage, value = T))) %>%
  select(EXTRACT_DATE, ODS_Code = CODE, Patients = NUMBER_OF_PATIENTS) %>%
  mutate(EXTRACT_DATE = paste0(ordinal(as.numeric(substr(EXTRACT_DATE,1,2))), ' ', substr(EXTRACT_DATE, 3,5), ' ', substr(EXTRACT_DATE, 6,10))) %>% 
  filter(ODS_Code %in% gp_mapping$ODS_Code) %>% 
  left_join(gp_mapping, by = 'ODS_Code') 

gp_locations %>% 
  select(ODS_Code, ODS_Name, PCN_Name, longitude, latitude) %>% 
  left_join(latest_gp_total_pop[c('ODS_Code', 'Patients')], by = 'ODS_Code') %>% 
  toJSON() %>%
  write_lines(paste0(output_directory, '/GP_location_data.json'))

latest_PCN_total_pop <- latest_gp_total_pop %>% 
  group_by(PCN_Code, PCN_Name) %>% 
  summarise(Patients = sum(Patients, na.rm = TRUE))
  
paste0('As at, ', Extract_date, ' there were ', format(nrow(latest_PCN_total_pop), big.mark = ','), ' distinct primary care networks in England (including ', numbers_to_words(nrow(subset(latest_PCN_total_pop, PCN_Code == 'U'))), ' practices which are not currently allocated to a PCN).') %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory,'/England_pcn_summary_text_1.json'))

sussex_gp_total_pop <- latest_gp_total_pop %>% 
  filter(str_detect(ICB_Name, '^NHS Sussex ICB'))

sussex_PCN_total_pop <- latest_PCN_total_pop %>% 
  filter(PCN_Name %in% sussex_gp_total_pop$PCN_Name)

sussex_PCN_total_pop %>% 
  ungroup() %>% 
  mutate(PCN_Number = row_number()) %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory,'/Sussex_PCN_summary_df.json'))

paste0('In the NHS Sussex ICB footprint, there are ', format(nrow(sussex_PCN_total_pop), big.mark = ','), ' distinct primary care networks in England (including ', numbers_to_words(nrow(subset(sussex_PCN_total_pop, PCN_Code == 'U'))), ' practices which are not currently allocated to a PCN).') %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory,'/Sussex_pcn_summary_text_1.json'))

# Combine population data with the PCN_data table ####

practices_by_pcn <- latest_gp_total_pop %>% 
  select(ODS_Code, ODS_Name, PCN_Code, PCN_Name) %>% 
  unique() %>% 
  group_by(PCN_Code, PCN_Name) %>% 
  summarise(Practices = n()) #%>% 
  # mutate(Practices = str_to_title(numbers_to_words(Practices)))

# Residential area information
download.file(unique(grep('gp-reg-pat-prac-lsoa-male-female', calls_patient_numbers_webpage, value = T)),
              paste0(local_store, '/lsoa_zip.zip'), 
              mode = 'wb')
unzip(paste0(local_store, '/lsoa_zip.zip'), 
      exdir = local_store)

lsoa_all_df <- read_csv(paste0(local_store, '/gp-reg-pat-prac-lsoa-all.csv')) %>% 
  mutate(EXTRACT_DATE = paste0(ordinal(as.numeric(substr(EXTRACT_DATE,1,2))), ' ', substr(EXTRACT_DATE, 3,5), ' ', substr(EXTRACT_DATE, 6,10))) %>% 
  select(EXTRACT_DATE, ODS_Code = PRACTICE_CODE, LSOA11CD = LSOA_CODE, Patients = NUMBER_OF_PATIENTS) 

lsoa_gp_df <- lsoa_all_df %>% 
  filter(ODS_Code %in% gp_mapping$ODS_Code) %>% 
  left_join(gp_mapping, by = 'ODS_Code') 

lsoa_pcn_df <- lsoa_gp_df %>% 
  group_by(LSOA11CD, PCN_Code, PCN_Name) %>% 
  summarise(Patients = sum(Patients, na.rm = TRUE))

# lsoa_x <- lsoa_gp_df %>% 
  # filter(LSOA11CD == 'E01031611') 

# lsoa_x_b <- lsoa_pcn_df %>% 
  # filter(LSOA11CD == 'E01031611')

#sum(lsoa_x$Patients)
#sum(lsoa_x_b$Patients)

# 13254
  
 # "#440154", "#482173", "#433E85", "#38598C", "#2D708E", "#25858E", "#1E9B8A", "#2BB07F",
 # "#51C56A", "#85D54A", "#C2DF23", "#FDE725"
# count the unknown addresses - NO2011
  
# We cannot map to 2021 LSOAs because we for LSOAs which split do not know which new LSOA they went to  
# For the time being this is likely to be 2011 LSOA.

# LSOA boundaries ####
lsoa_2011_sf <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA_Dec_2011_Boundaries_Generalised_Clipped_BGC_EW_V3_2022/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') 

# Convert it to a spatial polygon data frame
lsoa_2011_boundaries_spdf <-  as_Spatial(lsoa_2011_sf, IDs = lsoa_2011_sf$LSOA11CD)

# PCN view - showing all LSOAs linked to each network check - 
sussex_pcn_reach <- lsoa_pcn_df %>% 
  filter(PCN_Name %in% sussex_PCN_total_pop$PCN_Name)

# most lsoa counts are less than 2,000 (there are 93 LSOAs with 2,000 or more residents assigned to a PCN)
# sussex_pcn_reach %>% 
#   filter(Patients >= 5 & Patients <= 2000) %>% 
#   ggplot() +
#   geom_histogram(aes(x = Patients))


# We need to create a single geojson file that holds one row per LSOA per PCN which has at least five registered patients in. You would expect the same LSOA to appear multiple times if it has at least five patients assigned to a PCN.

for(i in 1:length(unique(sussex_pcn_reach$PCN_Name))){
pcn_x <- unique(sussex_pcn_reach$PCN_Name)[i]

pcn_reach_x_df <- sussex_pcn_reach %>% 
  filter(PCN_Name == pcn_x)

assign(paste0('pcn_reach_', i), lsoa_2011_boundaries_spdf %>% 
  filter(LSOA11CD %in% pcn_reach_x_df$LSOA11CD) %>% 
  left_join(pcn_reach_x_df, by = 'LSOA11CD') %>% 
  filter(Patients >= 5))

assign(paste0('pcn_reach_single', i), lsoa_2011_boundaries_spdf %>% 
         filter(LSOA11CD %in% pcn_reach_x_df$LSOA11CD) %>% 
         left_join(pcn_reach_x_df, by = 'LSOA11CD') %>% 
         filter(Patients >= 5) %>% 
         gUnaryUnion(id = 'PCN_Name'))

}

sussex_PCN_total_pop <- sussex_PCN_total_pop %>% 
  rename(Total_patients = Patients)

total_pcn_reach <- rbind(pcn_reach_1, pcn_reach_2, pcn_reach_3,  pcn_reach_4, pcn_reach_5, pcn_reach_6, pcn_reach_7,  pcn_reach_8, pcn_reach_9, pcn_reach_10, pcn_reach_11,  pcn_reach_12, pcn_reach_13, pcn_reach_14, pcn_reach_15,  pcn_reach_16, pcn_reach_17, pcn_reach_18, pcn_reach_19,  pcn_reach_20, pcn_reach_21, pcn_reach_22, pcn_reach_23,  pcn_reach_24, pcn_reach_25, pcn_reach_26, pcn_reach_27,  pcn_reach_28, pcn_reach_29, pcn_reach_30, pcn_reach_31,  pcn_reach_32, pcn_reach_33, pcn_reach_34, pcn_reach_35,  pcn_reach_36, pcn_reach_37, pcn_reach_38, pcn_reach_39,  pcn_reach_40) %>% 
  select(-c(PCN_Code, LSOA11NM)) %>% 
  left_join(sussex_PCN_total_pop[c('PCN_Name', 'Total_patients')], by = 'PCN_Name')

# total_pcn_reach@data %>% 
#   filter(str_detect(PCN_Name, 'Sidley')) %>% 
#   View()

df <- data.frame(ID = character())

# Get the IDs of spatial polygon
for (i in total_pcn_reach@polygons ) { df <- rbind(df, data.frame(ID = i@ID, stringsAsFactors = FALSE))  }

# and set rowname = ID
row.names(total_pcn_reach) <- df$ID

# Then use df as the second argument to the spatial dataframe conversion function:
total_pcn_reach_json <- SpatialPolygonsDataFrame(total_pcn_reach, total_pcn_reach@data)  

geojson_write(ms_simplify(geojson_json(total_pcn_reach_json), keep = 0.5), file = paste0(output_directory, '/total_pcn_lsoa_level_reach_plus_five.geojson'))

# gp_locations_x <- gp_locations %>%
#   filter(PCN_Name == 'Unallocated - Sidley Medical Practice')
# 
# pcn_reach_x <- sussex_pcn_reach %>% 
#   filter(PCN_Name == 'Unallocated - Sidley Medical Practice')
# 
# pcn_reach_boundary <- lsoa_2011_boundaries_spdf %>% 
#   filter(LSOA11CD %in% pcn_reach_x$LSOA11CD) %>% 
#   left_join(pcn_reach_x, by = 'LSOA11CD') %>% 
#   filter(Patients >= 5)
# 
# quantile_pal <- colorQuantile(plasma(10, direction = 1), pcn_reach_boundary$Patients, n = 10)
# 
# leaflet() %>%
#   addControl(paste0("<font size = '2px'><b>Primary Care organisations; Sussex; as at ", Extract_date, "</b><br>Based on main GP practice details on registered address;</font>"),
#              position='topright') %>%
#   addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',attribution = paste0('&copy; <a href=https://www.openstreetmap.org/copyright>OpenStreetMap</a> contributors &copy; <a href=https://carto.com/attributions>CARTO</a><br>Contains OS data ? Crown copyright and database right 2021<br>Zoom in/out using your mouse wheel or the plus (+) and minus (-) buttons and click on an area/circle to find out more.')) %>%
# 
# addPolygons(data = pcn_reach_boundary,
#             stroke = FALSE,
#             smoothFactor = 0.2,
#             fillOpacity = 1,
#             color = ~quantile_pal(Patients)) %>%
#   addCircleMarkers(lng = gp_locations_x$longitude,
#                    lat = gp_locations_x$latitude,
#                    radius = 4,
#                    color = '#000000',
#                    fillColor = 'purple',
#                    stroke = TRUE,
#                    weight = .75,
#                    fillOpacity = 1,
#                    popup = gp_locations_x$ODS_Name,
#                    group = 'Show GP practice') %>%
#   addLegend(pal = quantile_pal,
#             values = pcn_reach_x$Patients,
#             opacity = 1) %>%
#   addScaleBar(position = "bottomleft") %>%
#   addMeasure(position = 'bottomleft',
#              primaryAreaUnit = 'sqmiles',
#              primaryLengthUnit = 'miles')

# How big is an lsoa level geojson file
# sussex_pcn_reach_five_plus <- lsoa_2011_boundaries_spdf %>% 
#   left_join(pcn_reach_x_df, by = 'LSOA11CD') %>% 
#   filter(Patients >= 5)


# LSOA view - which PCN should a single LSOA be assigned to based on its residents (mutually exclusive boundaries)
# This could also be the basis for the census data


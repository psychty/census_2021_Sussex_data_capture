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
time_period <- 'october-2022' 

# We need the latest release that has the LSOA level numbers we need. As such, we need to specify the January 2022 release.
calls_patient_numbers_webpage <- read_html(paste0('https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/', time_period)) %>%
  html_nodes("a") %>%
  html_attr("href")

gp_mapping <- read_csv(unique(grep('gp-reg-pat-prac-map.csv', calls_patient_numbers_webpage, value = T))) %>%
  mutate(PRACTICE_NAME = gsub('Woodlands&Clerklands', 'Woodlands & Clerklands', gsub('\\(Aic\\)', '\\(AIC\\)', gsub('\\(Acf\\)', '\\(ACF\\)', gsub('Pcn', 'PCN', gsub('And', 'and',  gsub(' Of ', ' of ',  str_to_title(PRACTICE_NAME)))))))) %>%  
  mutate(PCN_NAME = gsub('\\(Aic\\)', '\\(AIC\\)', gsub('\\(Acf\\)', '\\(ACF\\)', gsub('Pcn', 'PCN', gsub('And', 'and',  gsub(' Of ', ' of ',  str_to_title(PCN_NAME))))))) %>%
  mutate(EXTRACT_DATE = paste0(ordinal(as.numeric(substr(EXTRACT_DATE,1,2))), ' ', substr(EXTRACT_DATE, 4,6), ' 20', substr(EXTRACT_DATE, 8,9))) %>% 
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
  mutate(PCN_number = row_number()) %>% 
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
sussex_pcn_reach %>% 
  filter(Patients >= 5 & Patients <= 2000) %>% 
  ggplot() +
  geom_histogram(aes(x = Patients))


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
         gUnaryUnion(id = PCN_Name))

}


total_pcn_reach <- rbind(pcn_reach_1, pcn_reach_2, pcn_reach_3,  pcn_reach_4, pcn_reach_5, pcn_reach_6, pcn_reach_7,  pcn_reach_8, pcn_reach_9, pcn_reach_10, pcn_reach_11,  pcn_reach_12, pcn_reach_13, pcn_reach_14, pcn_reach_15,  pcn_reach_16, pcn_reach_17, pcn_reach_18, pcn_reach_19,  pcn_reach_20, pcn_reach_21, pcn_reach_22, pcn_reach_23,  pcn_reach_24, pcn_reach_25, pcn_reach_26, pcn_reach_27,  pcn_reach_28, pcn_reach_29, pcn_reach_30, pcn_reach_31,  pcn_reach_32, pcn_reach_33, pcn_reach_34, pcn_reach_35,  pcn_reach_36, pcn_reach_37, pcn_reach_38, pcn_reach_39,  pcn_reach_40) %>% 
  select(-c(PCN_Code, LSOA11NM)) 


df <- data.frame(ID = character())

# Get the IDs of spatial polygon
for (i in total_pcn_reach@polygons ) { df <- rbind(df, data.frame(ID = i@ID, stringsAsFactors = FALSE))  }

# and set rowname = ID
row.names(total_pcn_reach) <- df$ID

# Then use df as the second argument to the spatial dataframe conversion function:
total_pcn_reach_json <- SpatialPolygonsDataFrame(total_pcn_reach, total_pcn_reach@data)  


geojson_write(ms_simplify(geojson_json(total_pcn_reach_json), keep = 0.5), file = paste0(output_directory, '/total_pcn_lsoa_level_reach_plus_five.geojson'))





gp_locations_x <- gp_locations %>%
  filter(PCN_Name == pcn_x)

quantile_pal <- colorQuantile(plasma(10, direction = 1), pcn_reach_x$Patients, n = 10)

leaflet() %>% 
  addControl(paste0("<font size = '2px'><b>Primary Care organisations; Sussex; as at ", Extract_date, "</b><br>Based on main GP practice details on registered address;</font>"),
             position='topright') %>% 
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',attribution = paste0('&copy; <a href=https://www.openstreetmap.org/copyright>OpenStreetMap</a> contributors &copy; <a href=https://carto.com/attributions>CARTO</a><br>Contains OS data ? Crown copyright and database right 2021<br>Zoom in/out using your mouse wheel or the plus (+) and minus (-) buttons and click on an area/circle to find out more.')) %>%
  
addPolygons(data = pcn_reach_x,
            label = paste0(pcn_reach_x$LSOA11CD, ' ', pcn_reach_x$LSOA11NM),
            popup = paste0(pcn_reach_x$LSOA11CD, ' ', pcn_reach_x$LSOA11NM, ' ', pcn_reach_x$Patients),
            stroke = FALSE,
            smoothFactor = 0.2, 
            fillOpacity = 1,
            color = ~quantile_pal(Patients)) %>% 
  addCircleMarkers(lng = gp_locations_x$longitude,
                   lat = gp_locations_x$latitude,
                   radius = 4,
                   color = '#000000',
                   fillColor = 'purple',
                   stroke = TRUE,
                   weight = .75,
                   fillOpacity = 1,
                   popup = gp_locations_x$ODS_Name,
                   group = 'Show GP practice') %>%
  addLegend(pal = quantile_pal, 
            values = pcn_reach_x$Patients,
            opacity = 1) %>% 
  addScaleBar(position = "bottomleft") %>%
  addMeasure(position = 'bottomleft',
             primaryAreaUnit = 'sqmiles',
             primaryLengthUnit = 'miles')







# How big is an lsoa level geojson file

sussex_pcn_reach_five_plus <- lsoa_2011_boundaries_spdf %>% 
  left_join(pcn_reach_x_df, by = 'LSOA11CD') %>% 
  filter(Patients >= 5)


# LSOA view - which PCN should a single LSOA be assigned to based on its residents (mutually exclusive boundaries)

# This could also be the basis for the census data

# PCN organisation data ####
download.file('https://nhs-prod.global.ssl.fastly.net/binaries/content/assets/website-assets/services/ods/data-downloads-other-nhs-organisations/epcn.zip', paste0(local_store, '/epcn.zip'), mode = 'wb')
unzip(paste0(local_store, '/epcn.zip'), exdir = local_store)

PCN_data <- read_excel(paste0(local_store, "/ePCN.xlsx"),
                       sheet = 'PCNDetails') %>% 
  rename(PCN_Code = 'PCN Code',
         PCN_Name = 'PCN Name',
         Open_date = 'Open Date',
         Close_date = 'Close Date') %>% 
  mutate(Open_date = paste(substr(Open_date, 1,4), substr(Open_date, 5,6), substr(Open_date, 7,8), sep = '-')) %>% 
  mutate(Open_date = as.Date(Open_date)) %>% 
  mutate(Address_label = gsub(', NA','', paste(str_to_title(`Address Line 1`), str_to_title(`Address Line 2`),str_to_title(`Address Line 3`),str_to_title(`Address Line 4`), Postcode, sep = ', '))) %>% 
  mutate(PCN_Name = gsub('\\(Aic\\)', '\\(AIC\\)', gsub('\\(Acf\\)', '\\(ACF\\)', gsub('Pcn', 'PCN', gsub('And', 'and',  gsub(' Of ', ' of ',  str_to_title(PCN_Name))))))) %>% 
  select(PCN_Code, PCN_Name, Postcode, Address_label)
                       
Practice_to_PCN_lookup <- read_excel(paste0(local_store, "/ePCN.xlsx"), 
           sheet = "PCN Core Partner Details") %>%
  mutate(`Partner\r\nName` = gsub('\\(Aic\\)', '\\(AIC\\)', gsub('\\(Acf\\)', '\\(ACF\\)', gsub('Pcn', 'PCN', gsub('And', 'and',  gsub(' Of ', ' of ',  str_to_title(`Partner\r\nName`))))))) %>% 
  mutate(`Practice\r\nParent\r\nSub ICB Loc Name` = gsub('97r', '97R', gsub('09d', '09D', gsub('70f', '70F', gsub('\\Nhs', '\\NHS', gsub('\\Icb', '\\ICB', gsub('Pcn', 'PCN', gsub('And', 'and',  gsub(' Of ', ' of ',  str_to_title(`Practice\r\nParent\r\nSub ICB Loc Name`)))))))))) %>% 
  mutate(`PCN Name` = gsub('\\(Aic\\)', '\\(AIC\\)', gsub('\\(Acf\\)', '\\(ACF\\)', gsub('Pcn', 'PCN', gsub('And', 'and',  gsub(' Of ', ' of ',  str_to_title(`PCN Name`))))))) %>% 
  filter(str_detect(`Practice\r\nParent\r\nSub ICB Loc Name`, '^NHS Sussex ICB')) %>%
  filter(is.na(`Practice to PCN\r\nRelationship\r\nEnd Date`) | `Partner\r\nOrganisation\r\nCode` == 'G81041') %>%
  select(ODS_Code = 'Partner\r\nOrganisation\r\nCode', ODS_Name = 'Partner\r\nName', ICB_Name = 'Practice\r\nParent\r\nSub ICB Loc Name', PCN_Code = 'PCN Code', PCN_Name = 'PCN Name') 

practice_total_list_size_public <- latest_gp_practice_numbers %>% 
  group_by(PCN_Code, Sex) %>% 
  summarise(Patients = sum(Patients, na.rm = TRUE)) %>% 
  ungroup() %>% 
  pivot_wider(names_from = 'Sex',
              values_from = 'Patients') %>% 
  mutate(Total = Male + Female)

latest_age_pcn_numbers <- read_csv(unique(grep('gp-reg-pat-prac-sing-age-regions.csv', calls_patient_numbers_webpage, value = T))) %>%
  filter(ORG_CODE %in% PCN_data$PCN_Code) %>% 
  filter(AGE != 'ALL') %>% 
  rename(PCN_Code = ORG_CODE,
         Patients = NUMBER_OF_PATIENTS,
         Sex = SEX,
         Age = AGE) %>%
  mutate(Sex = factor(ifelse(Sex == 'FEMALE', 'Female', ifelse(Sex == 'MALE', 'Male', NA)), levels = c('Female', 'Male'))) %>%
  mutate(Age = as.numeric(gsub('95\\+', '95', Age))) %>% 
  mutate(Age_group = factor(ifelse(Age < 16, '0-15 years', ifelse(Age < 65, '16-64 years', '65+ years')), levels = c('0-15 years', '16-64 years', '65+ years'))) %>% 
  select(PCN_Code, Sex, Age_group, Patients) %>%
  group_by(PCN_Code, Age_group) %>%
  summarise(Patients = sum(Patients, na.rm = TRUE)) %>% 
  pivot_wider(names_from = 'Age_group',
              values_from = 'Patients')

PCN_data %>% 
  left_join(practice_total_list_size_public, by = 'PCN_Code') %>% 
  left_join(latest_age_pcn_numbers, by = 'PCN_Code') %>% 
  left_join(n_practice_in_pcn, by = 'PCN_Code') %>%
  toJSON() %>%
  write_lines(paste0(output_directory, '/PCN_data.json'))

# PCN boundaries ####

lsoa_pcn_lookup <- read_csv(paste0(source_directory, '/lsoa_pcn_lookup_Feb_22.csv')) %>% 
  arrange(PCN_Code)

lsoa_clipped_spdf <- geojson_read('https://opendata.arcgis.com/datasets/e9d10c36ebed4ff3865c4389c2c98827_0.geojson',  what = "sp") %>%
  filter(LSOA11CD %in% lsoa_pcn_lookup$LSOA11CD) %>% 
  arrange(LSOA11CD) %>% 
  left_join(lsoa_pcn_lookup, by = c('LSOA11CD', 'LSOA11NM')) %>% 
  arrange(PCN_Code)

PCN_data <- PCN_data %>% 
  arrange(PCN_Code)

PCN_boundary <- gUnaryUnion(lsoa_clipped_spdf, id = lsoa_clipped_spdf@data$PCN_Code)

df <- data.frame(ID = character())

# Get the IDs of spatial polygon
for (i in PCN_boundary@polygons ) { df <- rbind(df, data.frame(ID = i@ID, stringsAsFactors = FALSE))  }

# and set rowname = ID
row.names(PCN_data) <- df$ID

# Then use df as the second argument to the spatial dataframe conversion function:
pcn_spdf <- SpatialPolygonsDataFrame(PCN_boundary, PCN_data)  

geojson_write(geojson_json(pcn_spdf), file = paste0(output_directory, '/pcn_boundary_simple.geojson'))




# Deprivation lsoa ####
IMD_2019_national <- read_csv('https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/845345/File_7_-_All_IoD2019_Scores__Ranks__Deciles_and_Population_Denominators_3.csv') %>% 
  select("LSOA code (2011)",  "Local Authority District name (2019)", "Index of Multiple Deprivation (IMD) Score", "Index of Multiple Deprivation (IMD) Rank (where 1 is most deprived)", "Index of Multiple Deprivation (IMD) Decile (where 1 is most deprived 10% of LSOAs)") %>% 
  rename(lsoa_code = 'LSOA code (2011)',
         LTLA = 'Local Authority District name (2019)',
         IMD_2019_score = 'Index of Multiple Deprivation (IMD) Score',
         IMD_2019_rank = "Index of Multiple Deprivation (IMD) Rank (where 1 is most deprived)", 
         IMD_2019_decile = "Index of Multiple Deprivation (IMD) Decile (where 1 is most deprived 10% of LSOAs)") %>% 
  mutate(IMD_2019_decile = factor(ifelse(IMD_2019_decile == 1, '10% most deprived',  ifelse(IMD_2019_decile == 2, 'Decile 2',  ifelse(IMD_2019_decile == 3, 'Decile 3',  ifelse(IMD_2019_decile == 4, 'Decile 4',  ifelse(IMD_2019_decile == 5, 'Decile 5',  ifelse(IMD_2019_decile == 6, 'Decile 6',  ifelse(IMD_2019_decile == 7, 'Decile 7',  ifelse(IMD_2019_decile == 8, 'Decile 8',  ifelse(IMD_2019_decile == 9, 'Decile 9',  ifelse(IMD_2019_decile == 10, '10% least deprived', NA)))))))))), levels = c('10% most deprived', 'Decile 2', 'Decile 3', 'Decile 4', 'Decile 5', 'Decile 6', 'Decile 7', 'Decile 8', 'Decile 9', '10% least deprived'))) %>% 
  rename(LSOA11CD = lsoa_code)
 
IMD_2019 <- IMD_2019_national %>% 
  filter(LTLA %in% c('Brighton and Hove', 'Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing', 'Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden')) %>% 
  arrange(desc(IMD_2019_score)) %>% 
  mutate(Rank_in_Sussex = rank(desc(IMD_2019_score))) %>% 
  mutate(Decile_in_Sussex = abs(ntile(IMD_2019_score, 10) - 11)) %>% 
  mutate(Decile_in_Sussex = factor(ifelse(Decile_in_Sussex == 1, '10% most deprived',  ifelse(Decile_in_Sussex == 2, 'Decile 2',  ifelse(Decile_in_Sussex == 3, 'Decile 3',  ifelse(Decile_in_Sussex == 4, 'Decile 4',  ifelse(Decile_in_Sussex == 5, 'Decile 5',  ifelse(Decile_in_Sussex == 6, 'Decile 6',  ifelse(Decile_in_Sussex == 7, 'Decile 7',  ifelse(Decile_in_Sussex == 8, 'Decile 8',  ifelse(Decile_in_Sussex == 9, 'Decile 9',  ifelse(Decile_in_Sussex == 10, '10% least deprived', NA)))))))))), levels = c('10% most deprived', 'Decile 2', 'Decile 3', 'Decile 4', 'Decile 5', 'Decile 6', 'Decile 7', 'Decile 8', 'Decile 9', '10% least deprived'))) %>% 
  mutate(UTLA = ifelse(LTLA %in% c('Brighton and Hove'),'Brighton and Hove', ifelse(LTLA %in% c('Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing'), 'West Sussex', ifelse(LTLA %in% c('Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden'), 'East Sussex', NA)))) %>% 
  group_by(UTLA) %>% 
  arrange(UTLA, desc(IMD_2019_score)) %>% 
  mutate(Rank_in_UTLA = rank(desc(IMD_2019_score))) %>% 
  mutate(Decile_in_UTLA = abs(ntile(IMD_2019_score, 10) - 11)) %>% 
  mutate(Decile_in_UTLA = factor(ifelse(Decile_in_UTLA == 1, '10% most deprived',  ifelse(Decile_in_UTLA == 2, 'Decile 2',  ifelse(Decile_in_UTLA == 3, 'Decile 3',  ifelse(Decile_in_UTLA == 4, 'Decile 4',  ifelse(Decile_in_UTLA == 5, 'Decile 5',  ifelse(Decile_in_UTLA == 6, 'Decile 6',  ifelse(Decile_in_UTLA == 7, 'Decile 7',  ifelse(Decile_in_UTLA == 8, 'Decile 8',  ifelse(Decile_in_UTLA == 9, 'Decile 9',  ifelse(Decile_in_UTLA == 10, '10% least deprived', NA)))))))))), levels = c('10% most deprived', 'Decile 2', 'Decile 3', 'Decile 4', 'Decile 5', 'Decile 6', 'Decile 7', 'Decile 8', 'Decile 9', '10% least deprived'))) %>% 
  mutate(UTLA = ifelse(LTLA %in% c('Brighton and Hove'),'Brighton and Hove', ifelse(LTLA %in% c('Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing'), 'West Sussex', ifelse(LTLA %in% c('Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden'), 'East Sussex', NA)))) %>% 
  arrange(LSOA11CD) %>% 
  filter(LSOA11CD %in% lsoa_pcn_lookup$LSOA11CD) %>% 
  select(LSOA11CD, LTLA, IMD_2019_decile, IMD_2019_rank) %>% 
  left_join(lsoa_pcn_lookup[c('LSOA11CD', 'LSOA11NM', 'PCN_Name')], by = 'LSOA11CD')
  
# Fuel poverty data

download.file('https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1072034/fuel-poverty-sub-regional-2022-tables.xlsx', paste0(source_directory, '/fuel_poverty_2020_data.xlsx'), mode = 'wb')

lsoa_fp <- read_excel("GitHub/pcn_hi_2022_des/data/fuel_poverty_2020_data.xlsx", 
                      sheet = "Table 3", skip = 2) %>% 
  rename(Fuel_poor_hh = 'Number of households in fuel poverty',
         Proportion_fuel_poor_hh = 'Proportion of households fuel poor (%)',
         LSOA11CD = 'LSOA Code') %>% 
  select(LSOA11CD, Fuel_poor_hh, Proportion_fuel_poor_hh)

IMD_2019 <- IMD_2019 %>% 
  left_join(lsoa_fp, by = 'LSOA11CD')

if(file.exists(paste0(output_directory, '/lsoa_pcn_des_west_sussex.geojson')) == FALSE){
  
  # Read in the lsoa geojson boundaries for our lsoas (actually this downloads all 30,000+ and then we filter)
  lsoa_spdf <- geojson_read('https://opendata.arcgis.com/datasets/8bbadffa6ddc493a94078c195a1e293b_0.geojson',  what = "sp") %>%
    filter(LSOA11CD %in% IMD_2019$LSOA11CD) %>% 
    arrange(LSOA11CD)
  
  df <- data.frame(ID = character())
  
  # Get the IDs of spatial polygon
  for (i in lsoa_spdf@polygons ) { df <- rbind(df, data.frame(ID = i@ID, stringsAsFactors = FALSE))  }
  
  # and set rowname = ID
  row.names(IMD_2019) <- df$ID
  
  # Then use df as the second argument to the spatial dataframe conversion function:
  lsoa_spdf_json <- SpatialPolygonsDataFrame(lsoa_spdf, IMD_2019)  
  
  geojson_write(geojson_json(lsoa_spdf_json), file = paste0(output_directory, '/lsoa_pcn_des_west_sussex.geojson'))
  
}

# GP locations
library(PostcodesioR)

lookup_result <- data.frame(postcode = character(), longitude = double(), latitude = double())
  
  for(i in 1:nrow(gp_numbers_mapping_wsx)){
    lookup_result_x <- postcode_lookup(gp_numbers_mapping_wsx$Practice_postcode[i]) %>% 
      select(postcode, longitude, latitude)
    
    lookup_result <- lookup_result_x %>% 
      bind_rows(lookup_result)
    
  }
  
gp_locations <- gp_numbers_mapping_wsx %>%
  rename(postcode = Practice_postcode) %>% 
  left_join(lookup_result, by = 'postcode')  

# Number of patients in each quintile ####
download.file(unique(grep('gp-reg-pat-prac-lsoa-male-female', calls_patient_numbers_webpage, value = T)), paste0(source_directory, '/gp_reg_lsoa.zip'), mode = 'wb')
unzip(paste0(source_directory, '/gp_reg_lsoa.zip'), exdir = source_directory)

file.remove(paste0(source_directory, '/gp-reg-pat-prac-lsoa-female.csv'))
file.remove(paste0(source_directory, '/gp-reg-pat-prac-lsoa-male.csv'))

gp_lsoa_df <- read_csv(paste0(source_directory, '/gp-reg-pat-prac-lsoa-all.csv')) %>% 
  rename(ODS_Code = PRACTICE_CODE,
         LSOA11CD = LSOA_CODE) %>% 
  filter(ODS_Code %in% gp_numbers_mapping_wsx$ODS_Code) %>% 
  left_join(IMD_2019_national, by = 'LSOA11CD')

gp_dep_df <- gp_lsoa_df %>%
  mutate(Quintile = factor(ifelse(is.na(IMD_2019_decile), 'Unknown', ifelse(IMD_2019_decile %in% c('10% most deprived', 'Decile 2'), '20% most deprived', ifelse(IMD_2019_decile %in% c('Decile 3', 'Decile 4'), 'Quintile 2', ifelse(IMD_2019_decile %in% c('Decile 5', 'Decile 6'), 'Quintile 3', ifelse(IMD_2019_decile %in% c('Decile 7', 'Decile 8'), 'Quintile 4', ifelse(IMD_2019_decile %in% c('Decile 9', '10% least deprived'), '20% least deprived', NA)))))), levels = c('20% most deprived', 'Quintile 2', 'Quintile 3', 'Quintile 4', '20% least deprived', 'Unknown'))) %>% 
  group_by(ODS_Code, Quintile) %>% 
  summarise(Patients = sum(NUMBER_OF_PATIENTS, na.rm = TRUE)) %>% 
  group_by(ODS_Code) %>% 
  mutate(Proportion = Patients / sum(Patients)) %>% 
  left_join(gp_locations, by = 'ODS_Code') %>% 
  mutate(Type = 'GP') %>% 
  rename(Area_Code = ODS_Code,
         Area_Name = ODS_Name)

pcn_dep_df <- gp_dep_df %>% 
  group_by(PCN_Code, PCN_Name, Quintile) %>% 
  summarise(Patients = sum(Patients, na.rm = TRUE)) %>% 
  group_by(PCN_Code, PCN_Name) %>% 
  mutate(Proportion = Patients / sum(Patients)) %>% 
  mutate(Type = 'PCN') %>% 
  rename(Area_Code = PCN_Code,
         Area_Name = PCN_Name)

dep_df <- gp_dep_df %>% 
  select(-c(PCN_Code, PCN_Name)) %>% 
  bind_rows(pcn_dep_df) %>% 
  select(Area_Code, Area_Name, Type, Quintile, Patients) %>% 
  arrange(Quintile) %>% 
  pivot_wider(names_from = 'Quintile',
              values_from = 'Patients') %>% 
  mutate(`20% most deprived` = replace_na(`20% most deprived`, 0),
         `Quintile 2` = replace_na(`Quintile 2`, 0),
         `Quintile 3` = replace_na(`Quintile 3`, 0),
         `Quintile 4` = replace_na(`Quintile 4`, 0),
         `20% least deprived` = replace_na(`20% least deprived`, 0),
         Unknown = replace_na(Unknown, 0)) %>% 
  mutate(Total = `20% most deprived` + `Quintile 2` + `Quintile 3` + `Quintile 4` + `20% least deprived` + Unknown) %>% 
  left_join(gp_locations, by = c('Area_Code' = 'ODS_Code')) %>% 
  mutate(PCN_Name = ifelse(is.na(PCN_Name), Area_Name, PCN_Name)) %>% 
  select(Area_Code, Area_Name, Type, `20% most deprived`, `Quintile 2`, `Quintile 3`, `Quintile 4`, `20% least deprived`, Unknown, Total, longitude, latitude, PCN_Code, PCN_Name) 

dep_df %>% 
  rename(lat = latitude,
         long = longitude) %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/PCN_deprivation_data.json'))

# MSOA inequalities ####

# Local Health data from fingertips

local_health_metadata <- read_csv('https://fingertips.phe.org.uk/api/indicator_metadata/csv/by_profile_id?profile_id=143') %>%
  rename(ID = 'Indicator ID',
         Source = 'Data source') %>% 
  select(ID, Definition, Rationale, Methodology, Source)

msoa_local_health_data <- read_csv('https://fingertips.phe.org.uk/api/all_data/csv/by_profile_id?child_area_type_id=3&parent_area_type_id=402&profile_id=143&parent_area_code=E10000032') %>% 
  filter(is.na(Category)) %>% 
  select(!c('Parent Code', 'Parent Name', 'Category Type', 'Category', 'Lower CI 99.8 limit', 'Upper CI 99.8 limit', 'Recent Trend', 'New data', 'Compared to goal')) %>% 
  rename(ID = 'Indicator ID',
         Indicator_Name = 'Indicator Name',
         Area_Code = 'Area Code',
         Area_Name = 'Area Name',
         Type = 'Area Type',
         Period = 'Time period',
         Lower_CI = 'Lower CI 95.0 limit',
         Upper_CI = 'Upper CI 95.0 limit',
         Numerator = 'Count',
         Compared_to_eng = 'Compared to England value or percentiles',
         Compared_to_wsx = 'Compared to Counties & UAs (from Apr 2021) value or percentiles',
         Note = 'Value note') %>% 
  mutate(Indicator = trimws(paste(ifelse(Indicator_Name == 'Life expectancy at birth, (upper age band 90+)', Sex, ''), Indicator_Name, Age, Period, sep = ' '), which = 'left')) %>% 
  select(ID, Indicator, Area_Code, Area_Name, Value, Lower_CI, Upper_CI, Numerator, Denominator, Note, Compared_to_wsx, Compared_to_eng)

England_local_health_data <- msoa_local_health_data %>% 
  filter(Area_Name == 'England')

WSx_local_health_Data <- msoa_local_health_data %>% 
  filter(Area_Name == 'West Sussex')

msoa_local_health_data <- msoa_local_health_data %>% 
  filter(Area_Name != 'England') %>% 
  filter(Area_Name != 'West Sussex') %>% 
  left_join(local_health_metadata, by = 'ID')

indicators_from_local_health <- msoa_local_health_data %>% 
  select(ID, Indicator) %>% 
  unique()

indicators_from_local_health %>% 
  view()

inequalities_data <- msoa_local_health_data %>% 
  filter(ID %in% c('93283', '93097', '93098', '93280', '93227', '93229', '93231', '93232', '93233', '93250', '93252', '93253', '93254', '93255', '93256', '93257', '93259', '93260', '93267', '93087'))

msoa_names <- read_csv('https://houseofcommonslibrary.github.io/msoanames/MSOA-Names-Latest.csv') %>%
  select(msoa11cd, msoa11hclnm) %>%
  rename(Area_Code = msoa11cd)

inequalities_data_summary <- inequalities_data %>% 
  select(Indicator, Area_Code, Value) %>% 
  pivot_wider(names_from = 'Indicator',
              values_from = 'Value') %>% 
  rename(Unemployment = 'Unemployment (% of the working age population claiming out of work benefit) 16-64 yrs 2019/20',
         Long_term_unemployment = 'Long-Term Unemployment- rate per 1,000 working age population 16-64 yrs 2019/20',
         HH_in_fuel_poverty = 'Estimated percentage of households that experience fuel poverty, 2018 Not applicable 2018',
         Male_LE_at_birth = 'Male Life expectancy at birth, (upper age band 90+) All ages 2015 - 19',
         Female_LE_at_birth = 'Female Life expectancy at birth, (upper age band 90+) All ages 2015 - 19',
         Hosp_all_cause = 'Emergency hospital admissions for all causes, all ages, standardised admission ratio All ages 2015/16 - 19/20',
         BME_population_census = 'Black and Minority Ethnic (BME) Population All ages 2011',
         Proportion_non_white_uk_census = "Percentage of population whose ethnicity is not 'White UK' All ages 2011",
         Deaths_all_cause_smr = 'Deaths from all causes, all ages, standardised mortality ratio All ages 2015 - 19',
         Deaths_U75_all_cause_smr = 'Deaths from all causes, under 75 years, standardised mortality ratio <75 yrs 2015 - 19') %>% 
  arrange(Area_Code) %>% 
  left_join(msoa_names, by = 'Area_Code') %>% 
  select(Area_Code, msoa11hclnm, Unemployment, Long_term_unemployment, Male_LE_at_birth, Female_LE_at_birth, Hosp_all_cause, Deaths_all_cause_smr, Deaths_U75_all_cause_smr, BME_population_census, Proportion_non_white_uk_census) 

summary(inequalities_data_summary$BME_population_census)

# MSOA geographies ####
# lsoa_to_msoa <- read_csv('https://opendata.arcgis.com/datasets/a46c859088a94898a7c462eeffa0f31a_0.csv') %>% 
#   select(LSOA11CD, MSOA11CD, MSOA11NM) %>% 
#   unique() %>% 
#   left_join(lsoa_pcn_lookup, by = 'LSOA11CD') %>% 
#   filter(!is.na(PCN_Name))
# 
# lsoa_to_msoa %>% 
#   write.csv(., paste0(source_directory, '/lsoa_to_msoa.csv'), row.names = FALSE)

lsoa_to_msoa <- read_csv(paste0(source_directory, '/lsoa_to_msoa.csv'))

msoa_boundaries_json <- geojson_read(paste0(source_directory, '/failsafe_msoa_boundary.geojson'),  what = "sp") %>% 
  filter(MSOA11CD %in% inequalities_data_summary$Area_Code) %>%
  arrange(MSOA11CD)

df <- data.frame(ID = character())

# Get the IDs of spatial polygon
for (i in msoa_boundaries_json@polygons ) { df <- rbind(df, data.frame(ID = i@ID, stringsAsFactors = FALSE))  }

# and set rowname = ID
row.names(inequalities_data_summary) <- df$ID

# Then use df as the second argument to the spatial dataframe conversion function:
msoa_boundaries_json <- SpatialPolygonsDataFrame(msoa_boundaries_json, inequalities_data_summary)  

geojson_write(geojson_json(msoa_boundaries_json), file = paste0(output_directory, '/msoa_inequalities.geojson'))

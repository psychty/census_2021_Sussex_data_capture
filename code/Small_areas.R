
# Small areas 


# Small areas across England and Wales can be segmented based on consistent population sizes. Output Areas (OAs) are a geography used by many population and health services to detail small area characteristics, activity, and outcomes, because of their consistent population size and stable boundaries (which only change as a result of new Census outputs every 10 years). 

# Whilst Output Areas (OAs) are the smallest statistical geography from the Census, the numbers of people in each area (usually a maximum of 250 households or 650 people) are often too small when looking at specific population characteristics like age and sex or ethnicity to meaningfully compare areas.

# Lower layer Super Output Areas (LSOAs) are made up of groups of OAs and comprise between 400 and 1,200 households and have a usually resident population between 1,000 and 3,000 persons. Area information such as neighbourhood deprivation is based on the LSOA geography and population estimates for calculating rates are published at LSOA level. We sometimes use Middle layer Super Output Areas (MSOAs) if the numbers of people are still too small (for example over 50s with a certain health condition). MSOAs comprise between 2,000 and 6,000 households and a usual resident population between 5,000 and 15,000 persons. 

# The three levels of Output Areas have conterminous boundaries and an OA can only be part of one LSOA and MSOA. OAs are defined by codes rather than meaningful names, although the House of Commons library has created a meaningful naming convention for MSOAs which is contributed to by local areas. 

# Nonetheless, stakeholders may not be as familiar with OAs (or an aggregate level) as they are wit Wards and Parliamentary constituencies. 

# Census outputs will also be available for 2022 ward boundaries and where possible we will also present area level analyses at this level. However, ward boundaries are not coterminous (aligning) with OA geographies, have greater variation in population coverage, and are frequently amended.

# Changes have been made to the 2011 LSOAs as a result of population and household changes found in the 2021 Census. New 2021 LSOAs were created by merging or splitting 2011 LSOAs to ensure that population and household thresholds were met. Whilst health statistics may continue to be published on the 2011 LSOA boundaries for the foreseable future, they will eventually switch to the 2021 boundaries and so a lookup and explanation of what has changed may be useful.

# Wards and LSOA boundaries do not neatly align and a ward can contain just a few LSOAs or several. Importantly, LSOAs can also span across more than one ward. The Office for National Statistics provides a ‘best-fit’ lookup which assigns LSOAs to the ward in which most of the population lies (based on the population weighted centroid of the area). This means that some residents can be assigned to a different ward if the majority of their neighbourhood falls into an adjacent ward.

# For more information see https://www.ons.gov.uk/methodology/geography/ukgeographies/censusgeographies/census2021geographies

# This short report shows the changes in geographies between the 2011 and 2021

packages <- c('easypackages', 'tidyr', 'ggplot2', 'dplyr', 'scales', 'readxl', 'readr', 'purrr', 'stringr', 'rgdal', 'spdplyr', 'geojsonio', 'rmapshaper', 'jsonlite', 'rgeos', 'sp', 'sf', 'maptools', 'leaflet', 'leaflet.extras', 'leaflet.extras2', 'nomisr')
install.packages(setdiff(packages, rownames(installed.packages())))
easypackages::libraries(packages)

local_store <- '~/Repositories/census_2021_Sussex_data_capture/raw_data'
output_directory <- '~/Repositories/census_2021_Sussex_data_capture/outputs'

areas <- c('Brighton and Hove', 'Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden', 'Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing') 

#LTLA boundaries

# This will read in the boundaries (in a geojson format) from Open Geography Portal - we dont really want all the rivers included but if we use full extent boundaries for the whole county then the area around chichester harbour might look strane to how people expect it to look.

# As such, we can take the clipped boudnary for chichester and the full extent boundaries for the rest of the county and then stitch it together.
lad_boundaries_clipped_sf <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Local_Authority_Districts_May_2022_UK_BFC_V3_2022/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  filter(LAD22NM %in% c('Chichester', 'Brighton and Hove')) 

lad_boundaries_full_extent_sf <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/Local_Authority_Districts_May_2022_UK_BFE_V3_2022/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  filter(LAD22NM %in% areas & LAD22NM != 'Chichester' & LAD22NM != 'Brighton and Hove')

lad_boundaries_sf <- rbind(lad_boundaries_clipped_sf, lad_boundaries_full_extent_sf)
lad_boundaries_spdf <- as_Spatial(lad_boundaries_sf, IDs = lad_boundaries_sf$LAD22NM)

# 2021 lookup
# This is an output area lookup 
oa21_lookup <- read_csv('https://www.arcgis.com/sharing/rest/content/items/792f7ab3a99d403ca02cc9ca1cf8af02/data')

# We can also create an LSOA lookup by subsetting this dataframe
lsoa21_lookup <- oa21_lookup %>% 
  select(LSOA21CD = lsoa21cd, LSOA21NM = lsoa21nm, MSOA21CD = msoa21cd, MSOA21NM = msoa21nm, LTLA = lad22nm) %>% 
  unique() %>% 
  filter(LTLA %in% areas)

msoas <- lsoa21_lookup %>% 
  select(MSOA21CD, MSOA21NM, LTLA) %>% 
  unique()

# this will download all lsoas and then filter just those in Sussex
lsoa_2021_sf <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA_Dec_2021_Boundaries_Generalised_Clipped_EW_BGC_2022/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  filter(LSOA21CD %in% lsoa21_lookup$LSOA21CD) 

# Convert it to a spatial polygon data frame
lsoa_2021_boundaries_spdf <- as_Spatial(lsoa_2021_sf, IDs = lsoa_2021_sf$LSOA2CD)

census_LSOA_raw_df <- nomis_get_data(id = 'NM_2028_1',
                                     time = 'latest', 
                                     c_sex = '0', # '1,2' would return males and females
                                     measures = '20100',
                                     geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, LSOA21NM = GEOGRAPHY_NAME, Sex = C_SEX_NAME, Population = OBS_VALUE) %>% 
  mutate(Sex = gsub('All persons', 'Persons', Sex)) %>% 
  filter(LSOA21CD %in% lsoa21_lookup$LSOA21CD)

census_LSOA_density_raw_df <- nomis_get_data(id = 'NM_2026_1',
                                     time = 'latest', 
                                     measures = '20100',
                                     geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, Persons_per_square_kilometre = OBS_VALUE) %>% 
  filter(LSOA21CD %in% lsoa21_lookup$LSOA21CD)

census_LSOA_df <- census_LSOA_density_raw_df %>% 
  left_join(census_LSOA_raw_df, by = 'LSOA21CD') %>% 
  select(!Sex)

census_MSOA_density_raw_df <- nomis_get_data(id = 'NM_2026_1',
                                          time = 'latest', 
                                          measures = '20100',
                                          geography = 'TYPE152') %>% 
  select(MSOA21CD = GEOGRAPHY_CODE, Persons_per_square_kilometre = OBS_VALUE) %>% 
  filter(MSOA21CD %in% msoas$MSOA21CD)

census_LAD_density_raw_df <- nomis_get_data(id = 'NM_2026_1',
                                             time = 'latest', 
                                             measures = '20100',
                                             geography = 'TYPE154,TYPE155') %>% 
  select(Area = GEOGRAPHY_NAME, Persons_per_square_kilometre = OBS_VALUE) %>% 
  filter(Area %in% c(areas, 'East Sussex', 'West Sussex')) %>% 
  unique()

# The 2011 data would be nice to plot alongside but it is calculated as a per hectare rate
# census_2011_density <- nomis_get_data(id = 'NM_160_1',
#                                        time = 'latest', 
#                                        measures = '20100',
#                                        geography = 'TYPE298') #%>% 
#   select(LSOA21CD = GEOGRAPHY_CODE, Persons_per_square_kilometre = OBS_VALUE) %>% 
#   filter(LSOA21CD %in% lsoa21_lookup$LSOA21CD)

# This is extracting a geojson format file from open geography portal. It has geometry information as well as the information we need and is a spatial features object. By adding the st_drop_geometry() function we turn this into a dataframe
lsoa_change_df <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA11_LSOA21_LAD22_EW_LU/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  select(LSOA11CD = F_LSOA11CD, LSOA11NM, LSOA21CD, LSOA21NM, LTLA = LAD22NM, Change = CHGIND) %>% 
  st_drop_geometry() %>% 
  mutate(Change = ifelse(Change == 'M', 'Merged', ifelse(Change == 'S', 'Split', ifelse(Change == 'X', 'Redefined', ifelse(Change == 'U', 'Unchanged', NA)))))

# I want to summarise how many LSOAs there were in 2011 and 2021 for each LTLA, I'm also going to add UTLA information and order thetable ready for exporting as a json file that I can use on the website.
lsoa_changes <- lsoa_change_df %>% 
  group_by(LTLA) %>% 
  summarise(LSOAs_in_2011 = n_distinct(LSOA11CD),
            LSOAs_in_2021 = n_distinct(LSOA21CD)) %>% 
  mutate(Difference = LSOAs_in_2021 - LSOAs_in_2011) %>% 
  mutate(Difference = ifelse(Difference > 0, paste0('+', Difference), Difference)) %>% 
  filter(LTLA %in% areas)

lsoa_change_detail <- lsoa_change_df %>% 
  group_by(LTLA, Change) %>% 
  summarise(Areas = n()) %>% 
  filter(LTLA %in% areas) %>% 
  pivot_wider(names_from = 'Change',
              values_from = 'Areas') %>% 
  mutate(Merged = replace_na(Merged, 0),
         Split = replace_na(Split, 0))

ltla_summary_df <- lsoa_changes %>% 
  left_join(lsoa_change_detail, by = 'LTLA') %>% 
  select(LTLA, LSOAs_in_2011, Unchanged, Split, Merged, LSOAs_in_2021, Difference) 

esx_changes <- ltla_summary_df %>% 
  filter(LTLA %in% c('Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden')) %>% 
  summarise(LSOAs_in_2011 = sum(LSOAs_in_2011, na.rm = TRUE),
         Unchanged = sum(Unchanged, na.rm = TRUE),
         Merged = sum(Merged, na.rm = TRUE),
         Split = sum(Split, na.rm = TRUE),
         LSOAs_in_2021 = sum(LSOAs_in_2021),
         LTLA = 'East Sussex') %>% 
  mutate(Difference = LSOAs_in_2021 - LSOAs_in_2011) %>% 
  mutate(Difference = ifelse(Difference > 0, paste0('+', Difference), Difference))

wsx_changes <- ltla_summary_df %>% 
  filter(LTLA %in% c('Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing')) %>% 
  summarise(LSOAs_in_2011 = sum(LSOAs_in_2011, na.rm = TRUE),
          Unchanged = sum(Unchanged, na.rm = TRUE),
          Merged = sum(Merged, na.rm = TRUE),
          Split = sum(Split, na.rm = TRUE),
          LSOAs_in_2021 = sum(LSOAs_in_2021),
          LTLA = 'West Sussex') %>% 
  mutate(Difference = LSOAs_in_2021 - LSOAs_in_2011) %>% 
  mutate(Difference = ifelse(Difference > 0, paste0('+', Difference), Difference))

ltla_summary_df %>% 
  bind_rows(esx_changes) %>% 
  bind_rows(wsx_changes) %>% 
  mutate(LTLA = factor(LTLA, levels = c('Brighton and Hove', 'East Sussex', 'Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden', 'West Sussex', 'Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing'))) %>% 
  arrange(LTLA) %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/lsoa_changes_table.json'))

#   There are four designated categories to describe the changes, and these are as follows:
#   U - No Change from 2011 to 2021. This means that direct comparisons can be made between these 2011 and 2021 LSOA.
# S - Split. This means that the 2011 LSOA has been split into two or more 2021 LSOA. There will be one record for each of the 2021 LSOA that the 2011 LSOA has been split into. This means direct comparisons can be made between estimates for the single 2011 LSOA and the estimates from the aggregated 2021 LSOA.
# M - Merged. 2011 LSOA have been merged with another one or more 2011 LSOA to form a single 2021 LSOA. This means direct comparisons can be made between the aggregated 2011 LSOAs’ estimates and the single 2021 LSOA’s estimates. 
# X - The relationship between 2011 and 2021 LSOA is irregular and fragmented. This has occurred where 2011 LSOA have been redesigned because of local authority district boundary changes, or to improve their social homogeneity. These can’t be easily mapped to equivalent 2021 LSOA like the regular splits (S) and merges (M), and therefore like for like comparisons of estimates for 2011 LSOA and 2021 LSOA are not possible.  

# You could also export as a csv or to clipboard as follows

# lsoa_changes %>% 
#   write.csv(paste0(output_directory, '/lsoa_changes_table.csv'),
#             row.names = FALSE)

# lsoa_changes %>% 
#   write.table(.,
#               'clipboard',
#               sep = '\t',
#               row.names = FALSE)

oa11_lookup <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/OA11_LSOA11_MSOA11_LAD20_RGN20_EW_LU_a1cf695c9b074c708921b2a7555f808a/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  st_drop_geometry()

# We can also create an LSOA lookup by subsetting this dataframe
lsoa11_lookup <- oa11_lookup %>% 
    select(LSOA11CD, LSOA11NM, MSOA11CD, MSOA11NM, LTLA = LAD20NM) %>% 
    unique() %>% 
    filter(LTLA %in% areas)

lsoa_2011_sf <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/LSOA_Dec_2011_Boundaries_Generalised_Clipped_BGC_EW_V3_2022/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>% 
  filter(LSOA11CD %in% lsoa11_lookup$LSOA11CD) 
  
# Convert it to a spatial polygon data frame
lsoa_2011_boundaries_spdf <-  as_Spatial(lsoa_2011_sf, IDs = lsoa_2011_sf$LSOA11CD)

lsoa_2021_boundaries_spdf <- lsoa_2021_boundaries_spdf %>% 
  left_join(census_LSOA_df, by = c('LSOA21CD', 'LSOA21NM')) 

lsoa_2011_boundaries_spdf <- lsoa_2011_boundaries_spdf %>% 
  select(!LSOA11NMW)

lsoa_2021_leaflet_map <- leaflet(lsoa_2021_boundaries_spdf,
        options = leafletOptions(zoomControl = FALSE)) %>%
  addControl(paste0("<font size = '1px'><b>Sussex 2011 LSOAs</font>"),
             position='topleft') %>% 
  addControl(paste0("<font size = '1px'><b>Sussex 2021 LSOAs</font>"),
             position='topright') %>% 
  addMapPane("left", zIndex = 0) %>%
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
           attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a><br>Contains Royal Mail data<br>Reproduced under Open Government Licence<br>&copy Crown copyright<br>Zoom in/out using your mouse wheel<br>Click on an area to find out more.',
           layerId = "left_layer",
           options = pathOptions(pane = "left")) %>%
  addPolygons(data = lsoa_2011_boundaries_spdf,
              stroke = TRUE, 
              color = "maroon",
              weight = 1,
              popup = paste0('LSOA 2011: ', lsoa_2011_boundaries_spdf$LSOA11NM, ' (', lsoa_2011_boundaries_spdf$LSOA11CD, ')'),
              options = pathOptions(pane = "left")) %>% 
  addPolygons(data = lad_boundaries_spdf,
              fill = FALSE,
              stroke = TRUE, 
              color = "#000000",
              weight = 2,
              group = 'lad',
              label = paste0(lad_boundaries_spdf$LAD22NM),
              options = pathOptions(pane = "left")) %>% 
  addMapPane("right", zIndex = 0) %>% 
  addTiles(urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
           attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a><br>Contains Royal Mail data<br>Reproduced under Open Government Licence<br>&copy Crown copyright<br>Zoom in/out using your mouse wheel<br>Click on an area to find out more.',
           layerId = "right_layer",
           options = pathOptions(pane = "right")) %>%
  addPolygons(data = lsoa_2021_boundaries_spdf,
              stroke = TRUE, 
              color = "purple",
              label = paste0(lsoa_2021_boundaries_spdf$LSOA21CD, ' (', lsoa_2021_boundaries_spdf$LSOA21NM, ')'),
              popup = paste0('LSOA 2021: ', lsoa_2021_boundaries_spdf$LSOA21NM, ' (', lsoa_2021_boundaries_spdf$LSOA21CD, ')'),
    weight = 1,
    group = 'Show 2021 boundaries',
    options = pathOptions(pane = "right")) %>%
  addPolygons(data = lad_boundaries_spdf,
              fill = FALSE,
              stroke = TRUE, 
              color = "#000000",
              weight = 2,
              group = 'lad',
              label = paste0(lad_boundaries_spdf$LAD22NM),
              options = pathOptions(pane = "right")) %>% 
  addSidebyside(layerId = "sidecontrols",
                leftId = "left_layer",
                rightId = "right_layer") %>% 
  addSearchFeatures(targetGroups = 'Show 2021 boundaries',
                    options = searchFeaturesOptions(zoom = 13,
                                                    openPopup = TRUE,
                                                    moveToLocation = TRUE,
                                                    autoType = TRUE,
                                                    textPlaceholder = 'Search for a 2021 LSOA Code (e.g. E01034817)',
                                                    collapsed = FALSE))

# Export the map as a html file
htmlwidgets::saveWidget(lsoa_2021_leaflet_map,
                        paste0(output_directory, '/lsoa_2021_leaflet_map.html'),
                        selfcontained = TRUE)


# geojson_write(ms_simplify(geojson_json(utla_ua_boundaries_rate_geo), keep = 0.2), file = paste0(output_directory_x, '/utla_covid_rate_latest.geojson'))

geojson_write(ms_simplify(geojson_json(lsoa_2021_boundaries_spdf), keep = 0.85), file = paste0(output_directory, '/sussex_2021_lsoas.geojson'))

geojson_write(ms_simplify(geojson_json(lsoa_2011_boundaries_spdf), keep = 1), file = paste0(output_directory, '/sussex_2011_lsoas.geojson'))


# Add population

census_LTLA_df <- nomis_get_data(id = 'NM_2029_1',
                                     time = 'latest', # latest = 2020
                                     c_sex = '0', # '1,2' would return males and females
                                     measures = '20100',
                                     c2021_age_92 = '0') %>% 
  select(Area = GEOGRAPHY_NAME, Year = DATE, Sex = C_SEX_NAME, Age = C2021_AGE_92_NAME, Population = OBS_VALUE) %>% 
  mutate(Sex = gsub('All persons', 'Persons', Sex)) %>% 
  unique() %>% 
  filter(Area %in% c(areas, 'East Sussex', 'West Sussex'))

lad_boundaries_spdf <- lad_boundaries_spdf %>% 
  left_join(census_LTLA_df[c('Area', 'Population')], by = c('LAD22NM' = 'Area')) %>% 
  left_join(census_LAD_density_raw_df, by = c('LAD22NM' = 'Area'))

lad_boundaries_spdf@data %>% View()

geojson_write(ms_simplify(geojson_json(lad_boundaries_spdf), keep = .6), file = paste0(output_directory, '/sussex_ltlas.geojson'))

# small area population maps ####



# We already have LSOA

# Middle super output areas ####


# https://www.nomisweb.co.uk/api/v01/dataset/NM_2027_1.data.csv?date=latest&geography=637540494&c2021_age_102=0...101&measures=20100

# this will download all lsoas and then filter just those in Sussex
msoa_2021_clipped_sf <- st_read('https://services1.arcgis.com/ESMARspQHYMw9BZ9/arcgis/rest/services/MSOA_Dec_2021_Boundaries_Generalised_Clipped_EW_BGC_2022/FeatureServer/0/query?outFields=*&where=1%3D1&f=geojson') %>%
  filter(MSOA21CD %in% msoas$MSOA21CD) 

# Convert it to a spatial polygon data frame
msoa_2021_boundaries_spdf <- as_Spatial(msoa_2021_clipped_sf, IDs = msoa_2021_clipped_sf$MSOA21CD)

census_MSOA_df <- nomis_get_data(id = 'NM_2027_1',
                                 time = 'latest', 
                                 c2021_age_102 = '0...101',
                                 measures = '20100',
                                 geography = 'TYPE152') %>% 
  select(MSOA21CD = GEOGRAPHY_CODE, MSOA21NM = GEOGRAPHY_NAME, Age = C2021_AGE_102_NAME, Population = OBS_VALUE) %>% 
  unique() %>% 
  filter(MSOA21CD %in% msoas$MSOA21CD)

msoa_total <- census_MSOA_df %>% 
  filter(Age == 'Total: All usual residents')

msoa_broad_age <- census_MSOA_df %>% 
  filter(Age != 'Total: All usual residents') %>%
  mutate(Age = as.numeric(ifelse(Age == 'Aged under 1 year', 0, ifelse(Age == 'Aged 100 years and over', 100, gsub(' year','', gsub(' years', '', gsub('Aged ', '', Age))))))) %>% 
  mutate(Age_group = factor(ifelse(Age <= 17, "0-17 years", ifelse(Age <= 64, "18-64 years", "65+ years")), levels = c('0-17 years', '18-64 years','65+ years'))) %>% 
  group_by(MSOA21CD, MSOA21NM, Age_group) %>% 
  summarise(Population = sum(Population, na.rm = TRUE)) %>% 
  ungroup() %>% 
  pivot_wider(names_from = 'Age_group',
              values_from = 'Population')

msoa_2021_spdf <- msoa_2021_boundaries_spdf %>% 
  left_join(msoa_total[c('Area_Code', 'Population')], by = c('MSOA21CD' = 'Area_Code')) %>% 
  left_join(census_MSOA_density_raw_df, by = 'MSOA21CD') %>% 
  left_join(msoa_broad_age, by = c('MSOA21CD', 'MSOA21NM'))
  
geojson_write(ms_simplify(geojson_json(msoa_2021_spdf), keep = 1), file = paste0(output_directory, '/sussex_2021_msoas.geojson'))


summary(lad_boundaries_spdf@data$Persons_per_square_kilometre)
summary(msoa_2021_spdf$Persons_per_square_kilometre)
summary(lsoa_2021_boundaries_spdf$Persons_per_square_kilometre)


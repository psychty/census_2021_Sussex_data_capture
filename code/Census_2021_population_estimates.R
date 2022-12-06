
packages <- c('easypackages', 'tidyr', 'ggplot2', 'dplyr', 'scales', 'readxl', 'readr', 'purrr', 'stringr', 'rgdal', 'spdplyr', 'geojsonio', 'rmapshaper', 'jsonlite', 'rgeos', 'sp', 'sf', 'maptools', 'leaflet', 'leaflet.extras', 'leaflet.extras2')
install.packages(setdiff(packages, rownames(installed.packages())))
easypackages::libraries(packages)

# https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationandhouseholdestimatesenglandandwalescensus2021/census2021/census2021firstresultsenglandwales1.xlsx

local_store <- '~/Repositories/census_2021_Sussex_data_capture/raw_data'
output_directory <- '~/Repositories/census_2021_Sussex_data_capture/outputs'

areas <- c('Brighton and Hove', 'Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden', 'Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing') 

nomis_area_types <- data.frame(Level = c('OA','LSOA','MSOA','LTLA', 'UTLA', 'Region'), Area_type_code = c('150','151','152','154', '155','480'))

# This will take a minute as it is retreiving single year of age for all UTLAs for the last nine available years - 
# This is from table TS009 - sex by single year of age
census_LTLA_raw_df <- nomis_get_data(id = 'NM_2029_1',
                             time = 'latest', # latest = 2020
                             c_sex = '0,1,2', # '1,2' would return males and females
                             measures = '20100',
                             c2021_age_92 = '0...91',
                             geography = 'TYPE154') %>% 
  select(Area_code = GEOGRAPHY_CODE, Area = GEOGRAPHY_NAME, Year = DATE, Sex = C_SEX_NAME, Age = C2021_AGE_92_NAME, Population = OBS_VALUE) %>% 
 mutate(Sex = gsub('All persons', 'Persons', Sex))

 Total_population <- census_LTLA_raw_df %>% 
  filter(Age == 'Total: All usual residents') %>% 
  pivot_wider(names_from = 'Sex',
              values_from = 'Population') %>% 
  filter(Area %in% areas) %>% 
  select(!c(Area_code, Age)) 

 Total_population %>% 
   toJSON() %>% 
   write_lines(paste0(output_directory, '/ltla_2021_pop_table.json'))
 
# When we clean the age field we use nested gsub() functions to remove the year part of Aged 1 year, the as well as the 'aged' and 'years' parts of the rest of the values. This does not work for the Aged under 1 year and Aged 90 years and over so ahead of this we do a conditional ifelse statement to tell R how to deal with those values.
census_LTLA_raw_df <- census_LTLA_raw_df %>% 
  filter(Age != 'Total: All usual residents') %>% 
  mutate(Age = as.numeric(ifelse(Age == 'Aged under 1 year', 0, ifelse(Age == 'Aged 90 years and over', 90, gsub(' year','', gsub(' years', '', gsub('Aged ', '', Age))))))) 

census_LTLA_five_year <- census_LTLA_raw_df %>%  
  mutate(Age_group = factor(ifelse(Age <= 4, "0-4 years", ifelse(Age <= 9, "5-9 years", ifelse(Age <= 14, "10-14 years", ifelse(Age <= 19, "15-19 years", ifelse(Age <= 24, "20-24 years", ifelse(Age <= 29, "25-29 years",ifelse(Age <= 34, "30-34 years", ifelse(Age <= 39, "35-39 years",ifelse(Age <= 44, "40-44 years", ifelse(Age <= 49, "45-49 years",ifelse(Age <= 54, "50-54 years", ifelse(Age <= 59, "55-59 years",ifelse(Age <= 64, "60-64 years", ifelse(Age <= 69, "65-69 years",ifelse(Age <= 74, "70-74 years", ifelse(Age <= 79, "75-79 years",ifelse(Age <= 84, "80-84 years",ifelse(Age <= 89, "85-89 years", "90+ years")))))))))))))))))), levels = c('0-4 years', '5-9 years','10-14 years','15-19 years','20-24 years','25-29 years','30-34 years','35-39 years','40-44 years','45-49 years','50-54 years','55-59 years','60-64 years','65-69 years','70-74 years','75-79 years','80-84 years','85-89 years', '90+ years')))  %>% 
  group_by(Area_code, Area, Year, Sex, Age_group) %>% 
  summarise(Population = sum(Population, na.rm = TRUE)) %>% 
  ungroup()

# Small areas
# TODO get nomis figures for LSOA population

nomis_data_info() %>% View()



# Population pyramid data ####

sussex_ltla_pyramid_df <- census_LTLA_five_year %>% 
  filter(Sex != 'Persons') %>% 
  filter(Area %in% areas)

  
wsx_pyramid_df <- sussex_ltla_pyramid_df %>% 
  filter(Area %in% c('Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing')) %>% 
  group_by(Year, Sex, Age_group) %>% 
  summarise(Population = sum(Population, na.rm = TRUE),
            Area = 'West Sussex')

esx_pyramid_df <- sussex_ltla_pyramid_df %>% 
  filter(Area %in% c('Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden')) %>% 
  group_by(Year, Sex, Age_group) %>% 
  summarise(Population = sum(Population, na.rm = TRUE),
            Area = 'East Sussex')

sussex_ltla_pyramid_df %>% 
  select(!Area_code) %>% 
  bind_rows(wsx_pyramid_df) %>% 
  bind_rows(esx_pyramid_df) %>% 
  select(!Year) %>%
  toJSON() %>% 
  write_lines(paste0(output_directory, '/Census_2021_pyramid_data.json'))

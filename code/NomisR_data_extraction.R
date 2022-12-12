# Loading some packages 
packages <- c('easypackages', 'tidyr', 'dplyr', 'nomisr', 'readr')
install.packages(setdiff(packages, rownames(installed.packages())))
easypackages::libraries(packages)

# There are *at least* two ways to access data from the ONS nomis platform.

# I have created a lookup for the area types that nomisr uses for Census 21, these are different to other datasets so bear this in mind
nomis_area_types <- data.frame(Level = c('OA','LSOA','MSOA','LTLA', 'UTLA', 'Region'), Area_type_code = c('150','151','152','154', '155','480'))

# We will want to filter the datasets for just Sussex areas, it is not practical to do this within the nomis call (to specify 1,029 areas to the api call), so whilst it takes a while to extract all LSOAs in england, you can filter afterwards.

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

# This is a really useful function from the nomisr package to help identify the table id you want.
nomis_tables <- nomis_data_info() %>% 
  select(id, components.dimension, name.value) # We really only need three fields from this table

# This is a table containing lists
nomis_tables %>% 
  names()

# A warning - this  contains much more than just Census 2021 data, it is all the tables in nomis, and there isn't really a way to distinguish the data sources*.

# As such, my advice would be to look on nomis for the table name
# https://www.nomisweb.co.uk/query/select/getdatasetbytheme.asp?opt=3&theme=&subgrp=

# Topic summaries have codes starting with TSXXX followed by three digit numbers. However, the nomis API has a different ID 

# *At the moment there are only topic summaries available from nomis so it might be possible to use that information to retrieve a table of just census 21 files.

library(stringr)

census_nomis_tables <- nomis_tables %>% 
  filter(str_detect(name.value, '^TS'))

census_nomis_tables %>% 
  View()

# Lets say we want to use the lsoa population by sex.
table_x <- nomis_tables %>% 
  filter(id == 'NM_2028_1')


table_x$components.dimension

# Also the field names differ from dataset to dataset so I often revert to going to the nomis website if I'm experimenting or trying to access a new data file.

# LSOA Population by sex
census_LSOA_raw_df <- nomis_get_data(id = 'NM_2028_1',
                                     time = 'latest', 
                                     c_sex = '0', # '1,2' would return males and females
                                     measures = '20100',
                                     geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, LSOA21NM = GEOGRAPHY_NAME, Sex = C_SEX_NAME, Population = OBS_VALUE) %>% 
  mutate(Sex = gsub('All persons', 'Persons', Sex)) %>% 
  filter(LSOA21CD %in% Sussex_lsoa21_lookup$LSOA21CD)

# MSOA Population by age and sex
census_LSOA_raw_df <- nomis_get_data(id = 'NM_2028_1',
                                     time = 'latest', 
                                     c_sex = '0', # '1,2' would return males and females
                                     measures = '20100',
                                     geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, LSOA21NM = GEOGRAPHY_NAME, Sex = C_SEX_NAME, Population = OBS_VALUE) %>% 
  mutate(Sex = gsub('All persons', 'Persons', Sex)) %>% 
  filter(LSOA21CD %in% lsoa21_lookup$LSOA21CD)
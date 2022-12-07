# Loading some packages 
packages <- c('easypackages', 'tidyr', 'dplyr', 'nomisr')
install.packages(setdiff(packages, rownames(installed.packages())))
easypackages::libraries(packages)

# There are *at least* two ways to access data from the ONS nomis platform.



# I have created a lookup for the area types that nomisr uses for Census 21, these are different to other datasets so bear this in mind
nomis_area_types <- data.frame(Level = c('OA','LSOA','MSOA','LTLA', 'UTLA', 'Region'), Area_type_code = c('150','151','152','154', '155','480'))

# This is a really useful function from the nomisr package to help identify the table id you want.
# nomis_data_info() %>% View()

# Also the field names differ from dataset to dataset so I often revert to going to the nomis website if I'm experimenting or trying to access a new data file.


census_LSOA_raw_df <- nomis_get_data(id = 'NM_2028_1',
                                     time = 'latest', 
                                     c_sex = '0', # '1,2' would return males and females
                                     measures = '20100',
                                     geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, LSOA21NM = GEOGRAPHY_NAME, Sex = C_SEX_NAME, Population = OBS_VALUE) %>% 
  mutate(Sex = gsub('All persons', 'Persons', Sex)) %>% 
  filter(LSOA21CD %in% lsoa21_lookup$LSOA21CD)
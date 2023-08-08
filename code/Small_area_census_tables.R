
# Loading some packages 
packages <- c('easypackages','readxl', 'tidyr', 'dplyr', 'readr', "rgdal", 'nomisr', 'rgeos', "tmaptools", 'sp', 'sf', 'maptools', 'leaflet', 'leaflet.extras', 'leaflet.extras2', 'spdplyr', 'geojsonio', 'rmapshaper', 'jsonlite', 'httr', 'rvest', 'stringr', 'scales', 'xfun', 'viridis', 'PostcodesioR', 'ggplot2')
install.packages(setdiff(packages, rownames(installed.packages())))
easypackages::libraries(packages)

local_store <- '~/Repositories/census_2021_Sussex_data_capture/raw_data'
output_directory <- '~/Repositories/census_2021_Sussex_data_capture/outputs'

# We need to somehow align 2011 LSOAs to 2021 MSOAs so that we can get roughly the population coverage we need.
# We need to designate it as experimental. 

# PCN boundaries ####
pcn_spdf <- st_read(paste0(output_directory, '/sussex_pcn_footprints_method_2.geojson')) %>% 
  as_Spatial(IDs = PCN_Name)

areas <- c('Brighton and Hove', 'Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden', 'Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing') 

PCN_Meta <- fromJSON(paste0(output_directory, '/Sussex_PCN_summary_df.json'))

# This is missing the unallocated Brighton PCN, and we need to make a factor of this field (PCN Name)
Method_2_LSOA_based_PCN_df <- read_csv(paste0(output_directory, '/Method_2_LSOA_based_PCN_df.csv')) %>% 
  mutate(PCN_Name = factor(PCN_Name, levels = PCN_Meta$PCN_Name))

final_lsoa_pcn_lookup  <- read_csv(paste0(output_directory, '/lsoa_2021_lookup_to_Sussex_PCNs.csv')) %>% 
  arrange(LSOA21CD) %>% 
  mutate(id = row_number())

# Census data ####

# I have created a lookup for the area types that nomisr uses for Census 21, these are different to other datasets so bear this in mind
nomis_area_types <- data.frame(Level = c('OA','LSOA','MSOA','LTLA', 'UTLA', 'Region'), Area_type_code = c('150','151','152','154', '155','480'))

# We will want to filter the datasets for just Sussex areas, it is not practical to do this within the nomis call (to specify 1,029 areas to the api call), so whilst it takes a while to extract all LSOAs in england, you can filter afterwards.

# This is a really useful function from the nomisr package to help identify the table id you want.
nomis_tables <- nomis_data_info() %>% 
  select(id, components.dimension, name.value) # We really only need three fields from this table

# *At the moment there are only topic summaries available from nomis so it might be possible to use that information to retrieve a table of just census 21 files.

census_nomis_tables <- nomis_tables %>% 
  filter(str_detect(name.value, '^TS'))

# Age
census_LSOA_age_raw_df <- nomis_get_data(id = 'NM_2020_1',
                                                measure = '20100',
                                                geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, Age_group = C2021_AGE_19_NAME, Population = OBS_VALUE) %>% 
  filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 

census_LSOA_age_df <- census_LSOA_age_raw_df %>% 
  filter(Age_group != 'Total') %>% 
  mutate(Age_group = ifelse(Age_group == 'Aged 85 years and over', '85+ years', ifelse(Age_group == 'Aged 4 years and under', '0-4 years', gsub(' to ', '-', gsub('Aged ', '', Age_group))))) 

unique(census_LSOA_age_df$Age_group)

census_LSOA_65_plus <- census_LSOA_age_df %>% 
  mutate(Age_65 = ifelse(Age_group %in% c('65-69 years','70-74 years','75-79 years','80-84 years','85+ years'), '65+ years', ifelse(Age_group %in% c('0-4 years','5-9 years','10-14 years','15-19 years','20-24 years','25-29 years','30-34 years','35-39 years','40-44 years','45-49 years','50-54 years','55-59 years','60-64 years'), 'Under 65 years', NA))) %>% 
  group_by(LSOA21CD, Age_65) %>% 
  summarise(Population = sum(Population)) %>% 
  group_by(LSOA21CD) %>% 
  mutate(Denominator = sum(Population)) %>% 
  mutate(Proportion = Population / Denominator) %>% 
  filter(Age_65 == '65+ years') %>% 
  mutate(Topic = 'Age') %>% 
  select(LSOA21CD, Topic, Category = Age_65, Numerator = Population, Proportion, Denominator)

census_LSOA_75_plus <- census_LSOA_age_df %>% 
  mutate(Age_75 = ifelse(Age_group %in% c('75-79 years','80-84 years','85+ years'), '75+ years', ifelse(Age_group %in% c('0-4 years','5-9 years','10-14 years','15-19 years','20-24 years','25-29 years','30-34 years','35-39 years','40-44 years','45-49 years','50-54 years','55-59 years','60-64 years', '65-69 years','70-74 years'), 'Under 75 years', NA))) %>% 
  group_by(LSOA21CD, Age_75) %>% 
  summarise(Population = sum(Population)) %>% 
  group_by(LSOA21CD) %>% 
  mutate(Denominator = sum(Population)) %>% 
  mutate(Proportion = Population / Denominator) %>% 
  filter(Age_75 == '75+ years') %>% 
  mutate(Topic = 'Age') %>% 
  select(LSOA21CD, Topic, Category = Age_75, Numerator = Population, Proportion, Denominator)


# Health ####

census_LSOA_health_raw_df <- nomis_get_data(id = 'NM_2055_1',
                                                measure = '20100',
                                                geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, LSOA21NM = GEOGRAPHY_NAME, Health = C2021_HEALTH_6_NAME, Population = OBS_VALUE) %>% 
  filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 

census_LSOA_health_table <- census_LSOA_health_raw_df %>% 
  filter(Health != 'Total: All usual residents') %>% 
  mutate(Health = ifelse(Health %in% c('Very good health', 'Good health'), 'Good or very good health', ifelse(Health %in% c('Bad health', 'Very bad health'), 'Bad or very bad health', Health))) %>% 
  group_by(LSOA21CD, Health) %>% 
  summarise(Population = sum(Population)) %>% 
  group_by(LSOA21CD) %>% 
  mutate(Proportion = Population / sum(Population)) %>% 
  mutate(Denominator = sum(Population)) %>% 
  mutate(Topic = 'Health') %>% 
  select(LSOA21CD, Topic, Category = Health, Numerator = Population, Proportion, Denominator)

census_LSOA_health_raw_df %>% 
  filter(Health != 'Total: All usual residents') %>% 
  left_join(final_lsoa_pcn_lookup, by = 'LSOA21CD') %>% 
  mutate(Health = ifelse(Health %in% c('Very good health', 'Good health'), 'Good or very good health', ifelse(Health %in% c('Bad health', 'Very bad health'), 'Bad or very bad health', Health))) %>% 
  group_by(PCN_Name, Health) %>% 
  summarise(Population = sum(Population)) %>% 
  group_by(PCN_Name) %>% 
  mutate(Denominator = sum(Population)) %>% 
  pivot_wider(names_from = 'Health',
              values_from = 'Population') 

# census_LSOA_health_table <- census_LSOA_health_raw_df %>% 
#   filter(Health != 'Total: All usual residents') %>% 
#   group_by(LSOA21CD) %>% 
#   mutate(Proportion = Population / sum(Population)) %>% 
#   mutate(Denominator = sum(Population)) %>% 
#   mutate(Topic = 'Health') %>% 
#   select(LSOA21CD, Topic, Category = Health, Numerator = Population, Proportion, Denominator)


# Disability ####

census_LSOA_disability_raw_df <- nomis_get_data(id = 'NM_2056_1',
                                                measure = '20100',
                                                geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, Disability = C2021_DISABILITY_5_NAME, Population = OBS_VALUE) %>% 
  filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 

census_LSOA_denominator <- census_LSOA_disability_raw_df %>% 
  filter(Disability == 'Total: All usual residents')

census_LSOA_disability_df <- census_LSOA_disability_raw_df %>% 
  filter(Disability %in% c('Disabled under the Equality Act', 'Not disabled under the Equality Act')) %>% 
  group_by(LSOA21CD) %>% 
  mutate(Proportion = Population / sum(Population)) %>% 
  mutate(Denominator = sum(Population))

census_LSOA_disability_detailed_df <- census_LSOA_disability_raw_df %>% 
  filter(Disability %in% c('Not disabled under the Equality Act: No long term physical or mental health conditions', 'Not disabled under the Equality Act: Has long term physical or mental health condition but day-to-day activities are not limited', 'Disabled under the Equality Act: Day-to-day activities limited a little', 'Disabled under the Equality Act: Day-to-day activities limited a lot')) %>% 
  group_by(LSOA21CD) %>% 
  mutate(Proportion = Population / sum(Population)) %>% 
  mutate(Denominator = sum(Population))

census_LSOA_disability_table <- census_LSOA_disability_df %>% 
  filter(Disability == 'Disabled under the Equality Act') %>% 
  mutate(Topic = 'Disability') %>% 
  select(LSOA21CD, Topic, Category = Disability, Numerator = Population, Proportion, Denominator)

census_LSOA_unpaid_care_raw_df <- nomis_get_data(id = 'NM_2057_1',
                                                measure = '20100',
                                                geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, Care_provided = C2021_CARER_7_NAME, Population = OBS_VALUE) %>% 
  filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 

census_LSOA_unpaid_care_yes_no <-  census_LSOA_unpaid_care_raw_df %>% 
  filter(Care_provided != 'Total: All usual residents aged 5 and over') %>% 
  filter(Care_provided != 'Provides 19 hours or less unpaid care a week') %>% 
  filter(Care_provided != 'Provides 20 to 49 hours unpaid care a week') %>% 
  mutate(Care_provided = ifelse(Care_provided %in% c("Provides 9 hours or less unpaid care a week",  "Provides 10 to 19 hours unpaid care a week", "Provides 20 to 34 hours unpaid care a week", "Provides 35 to 49 hours unpaid care a week",   "Provides 50 or more hours unpaid care a week"), 'Provides some care', Care_provided)) %>% 
  group_by(LSOA21CD, Care_provided) %>% 
  summarise(Population = sum(Population)) %>% 
  group_by(LSOA21CD) %>% 
  mutate(Proportion = Population / sum(Population)) %>% 
  mutate(Denominator = sum(Population)) 
  
census_LSOA_unpaid_care_35_plus <- census_LSOA_unpaid_care_raw_df %>% 
  filter(Care_provided != 'Total: All usual residents aged 5 and over') %>% 
  filter(Care_provided != 'Provides 19 hours or less unpaid care a week') %>% 
  filter(Care_provided != 'Provides 20 to 49 hours unpaid care a week') %>% 
  mutate(Care_provided = ifelse(Care_provided %in% c("Provides 9 hours or less unpaid care a week",  "Provides 10 to 19 hours unpaid care a week", "Provides 20 to 34 hours unpaid care a week"), 'Up to 34 hours', ifelse(Care_provided %in% c("Provides 35 to 49 hours unpaid care a week",   "Provides 50 or more hours unpaid care a week"), 'Provides 35 or more hours', Care_provided))) %>% 
  group_by(LSOA21CD, Care_provided) %>% 
  summarise(Population = sum(Population)) %>% 
  group_by(LSOA21CD) %>% 
  mutate(Proportion = Population / sum(Population)) %>% 
  mutate(Denominator = sum(Population)) %>% 
  filter(Care_provided != 'Provides no unpaid care')
  
census_LSOA_unpaid_care_table <- census_LSOA_unpaid_care_yes_no %>% 
  bind_rows(census_LSOA_unpaid_care_35_plus) %>% 
  mutate(Topic = 'Unpaid care') %>% 
  select(LSOA21CD, Topic, Category = Care_provided, Numerator = Population, Proportion, Denominator)

census_number_disabled_in_household_raw_df <-  nomis_get_data(id = 'NM_2058_1',
                                                              measure = '20100',
                                                              geography = 'TYPE151') %>% 
  select(LSOA21CD = GEOGRAPHY_CODE, LSOA21NM = GEOGRAPHY_NAME, Number_of_people = C2021_HHDISABLED_4_NAME, Population = OBS_VALUE) %>% 
  filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 

census_number_disabled_in_household_table <- census_number_disabled_in_household_raw_df %>%  
  filter(Number_of_people != 'Total: All households') %>% 
  mutate(Number_of_people = ifelse(Number_of_people %in% c('1 person disabled under the Equality Act in household', '2 or more people disabled under the Equality Act in household'), 'One or more in household', ifelse(Number_of_people == 'No people disabled under the Equality Act in household', 'None', NA))) %>% 
  group_by(LSOA21CD, Number_of_people) %>% 
  summarise(Population = sum(Population)) %>% 
  group_by(LSOA21CD) %>% 
  mutate(Proportion = Population / sum(Population)) %>% 
  mutate(Denominator = sum(Population)) %>% 
  mutate(Topic = 'HH disabled') %>% 
  select(LSOA21CD, Topic, Category = Number_of_people, Numerator = Population, Proportion, Denominator)


# wider determinants ####

# Ethnicity 
# 
# census_LSOA_ethnicity_raw_df <- nomis_get_data(id = 'NM_2020_1',
#                                                measure = '20100',
#                                                geography = 'TYPE151') #%>% 
# select(LSOA21CD = GEOGRAPHY_CODE, Ethnicity = C2021_AGE_19_NAME, Population = OBS_VALUE) %>% 
#   filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 
# 
# # TODO Country of birth ###
# 
# census_LSOA_country_of_birth_raw_df <- nomis_get_data(id = 'NM_2024_1',
#                                                       measure = '20100',
#                                                       geography = 'TYPE151')# %>% 
# select(LSOA21CD = GEOGRAPHY_CODE, Country_of_birth = C2021_AGE_19_NAME, Population = OBS_VALUE) %>% 
#   filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 
# 
# # unique(census_LSOA_country_of_birth_raw_df$)
# 
# # TODO Household experiencing deprivation ###
# 
# census_LSOA_hh_deprivation_raw_df <- nomis_get_data(id = 'NM_2031_1',
#                                                     measure = '20100',
#                                                     geography = 'TYPE151') %>% 
#   select(LSOA21CD = GEOGRAPHY_CODE, Household_deprivation_dimension = C2021_DEP_6_NAME, Population = OBS_VALUE) %>% 
#   filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 
# 
# 
# # Definition: The dimensions of deprivation used to classify households are indicators based on four selected household characteristics.
# # 
# # Education: A household is classified as deprived in the education dimension if no one has at least level 2 education and no one aged 16 to 18 years is a full-time student.
# # 
# # Employment: A household is classified as deprived in the employment dimension if any member, not a full-time student, is either unemployed or economically inactive due to long-term sickness or disability.
# # 
# # Health: A household is classified as deprived in the health dimension if any person in the household has general health that is bad or very bad or is identified as disabled. People who have assessed their day-to-day activities as limited by long-term physical or mental health conditions or illnesses are considered disabled. This definition of a disabled person meets the harmonised standard for measuring disability and is in line with the Equality Act (2010).
# # 
# # Housing: A household is classified as deprived in the housing dimension if the household's accommodation is either overcrowded, in a shared dwelling, or has no central heating.
# 
# # TODO Household language
# census_LSOA_household_language_raw_df <- nomis_get_data(id = 'NM_2044_1',
#                                                         measure = '20100',
#                                                         geography = 'TYPE151') %>% 
#   select(LSOA21CD = GEOGRAPHY_CODE, Household_language = C2021_HHLANG_5_NAME, Population = OBS_VALUE) %>% 
#   filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 
# 
# # TODO Household size
# census_LSOA_household_size_raw_df <- nomis_get_data(id = 'NM_2037_1',
#                                                     measure = '20100',
#                                                     geography = 'TYPE151') %>% 
#   select(LSOA21CD = GEOGRAPHY_CODE, Household_size = C2021_HHSIZE_10_NAME, Population = OBS_VALUE) %>% 
#   filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 
# 
# # Household composition 
# 
# census_LSOA_household_comp_raw_df <- nomis_get_data(id = 'NM_2023_1',
#                                                     measure = '20100',
#                                                     geography = 'TYPE151') %>% 
#   select(LSOA21CD = GEOGRAPHY_CODE, Household_composition = C2021_HHCOMP_15_NAME, Population = OBS_VALUE) %>% 
#   filter(LSOA21CD %in% final_lsoa_pcn_lookup$LSOA21CD) 
# 
# census_LSOA_household_comp_df_broad <- census_LSOA_household_comp_raw_df %>% 
#   filter(Household_composition %in% c('One-person household', 'Single family household', 'Other household types')) %>% 
#   group_by(LSOA21CD) %>% 
#   mutate(Proportion = Population / sum(Population),
#          Denominator = sum(Population),
#          Topic = 'Household composition')
# 
# census_LSOA_household_comp_single_person_over_66 <- census_LSOA_household_comp_raw_df %>% 
#   filter(Household_composition %in% c('Total: All households', 'One-person household: Aged 66 years and over')) %>% 
#   pivot_wider(names_from = 'Household_composition',
#               values_from = 'Population') %>% 
#   rename(Numerator = 'One-person household: Aged 66 years and over',
#          Denominator = 'Total: All households') %>% 
#   mutate(Proportion = Numerator/Denominator,
#          Topic = 'Household composition',
#          Category = 'One-person household: Aged 66 years and over')
# 
# census_LSOA_household_comp_lone_parent_dependent_children <- census_LSOA_household_comp_raw_df %>%   filter(Household_composition %in% c('Total: All households', 'Single family household: Lone parent family: With dependent children')) %>% 
#   pivot_wider(names_from = 'Household_composition',
#               values_from = 'Population') %>% 
#   rename(Numerator = 'Single family household: Lone parent family: With dependent children',
#          Denominator = 'Total: All households') %>% 
#   mutate(Proportion = Numerator/Denominator,
#          Topic = 'Household composition',
#          Category = 'Lone parent family: With dependent children')
# 
# census_LSOA_household_comp_any_with_dependent_children <- census_LSOA_household_comp_raw_df %>%   filter(Household_composition %in% c('Total: All households', 'Single family household: Married or civil partnership couple: Dependent children', 'Single family household: Cohabiting couple family: With dependent children', 'Single family household: Lone parent family: With dependent children', 'Other household types: With dependent children')) %>%
#   mutate(Household_composition = ifelse(Household_composition %in% c('Single family household: Married or civil partnership couple: Dependent children', 'Single family household: Cohabiting couple family: With dependent children', 'Single family household: Lone parent family: With dependent children', 'Other household types: With dependent children'), 'Any with dependent children', ifelse(Household_composition == 'Total: All households', 'Total: All households', NA))) %>% 
#   group_by(LSOA21CD, Household_composition) %>%
#   summarise(Population = sum(Population)) %>% 
#   group_by(LSOA21CD) %>% 
#   pivot_wider(names_from = 'Household_composition',
#               values_from = 'Population') %>% 
#   rename(Numerator = 'Any with dependent children',
#          Denominator = 'Total: All households') %>% 
#   mutate(Proportion = Numerator/Denominator,
#          Topic = 'Household composition',
#          Category = 'Any with dependent children')

# building LSOA table ####

# %>% 
  # left_join(final_lsoa_pcn_lookup, by = 'LSOA21CD')

LSOA_table <- census_LSOA_disability_table %>% 
  bind_rows(census_LSOA_health_table) %>% 
  bind_rows(census_LSOA_unpaid_care_table) %>% 
  bind_rows(census_number_disabled_in_household_table) %>% 
  left_join(final_lsoa_pcn_lookup, by = 'LSOA21CD') %>% 
  select(LSOA21CD, PCN_Name, LTLA, Topic, Category, Numerator, Proportion, Denominator)

LSOA_table %>%
  select(!c('PCN_Name', 'LTLA')) %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/LSOA_health_data.json'))

LSOA_table %>% 
  filter(Category == 'Good or very good health') %>% 
  group_by(PCN_Name) %>% 
  summarise(Numerator = sum(Numerator, na.rm = TRUE))

# LSOA_table %>%
#   toJSON() %>% 
#   write_lines(paste0(output_directory, '/LSOA_health_data_plan_B.json'))

LSOA_table %>%
  select(c('LSOA21CD', 'PCN_Name', 'LTLA')) %>%
  # select(c('id', 'LSOA21CD', 'PCN_Name', 'LTLA')) %>%
  unique() %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/LSOA_PCN_lookup_data.json'))

# Plan B geojson file containing the data for these maps
# 
# very_good_good_proportion
# very_bad_bad_proportion
# provides_some_unpaid_care_proportion
# disabled_proportion
# households_with_disabled_proportion
# 
# unique(LSOA_table$Category)

prop_health <- LSOA_table %>% 
  filter(Category %in% c("Disabled under the Equality Act", "Bad or very bad health", "Good or very good health", "Provides some care", "One or more in household")) %>% 
  select(LSOA21CD, Category, Numerator) %>% 
  mutate(Category = paste0(ifelse(Category == 'Disabled under the Equality Act', 'disabled_', ifelse(Category == 'Bad or very bad health', 'very_bad_bad_', ifelse(Category == 'Good or very good health', 'very_good_good_', ifelse(Category == 'Provides some care', 'provides_some_unpaid_care_proportion', ifelse(Category == 'One or more in household', 'households_with_disabled_', NA))))), 'numerator')) %>% 
  pivot_wider(names_from = 'Category',
              values_from = 'Numerator')

num_health <- LSOA_table %>% 
  filter(Category %in% c("Disabled under the Equality Act", "Bad or very bad health", "Good or very good health", "Provides some care", "One or more in household")) %>% 
  select(LSOA21CD, Category, Proportion) %>% 
  mutate(Category = paste0(ifelse(Category == 'Disabled under the Equality Act', 'disabled_', ifelse(Category == 'Bad or very bad health', 'very_bad_bad_', ifelse(Category == 'Good or very good health', 'very_good_good_', ifelse(Category == 'Provides some care', 'provides_some_unpaid_care_proportion', ifelse(Category == 'One or more in household', 'households_with_disabled_', NA))))), 'proportion')) %>% 
  pivot_wider(names_from = 'Category',
              values_from = 'Proportion')

LSOA_table %>% 
  group_by(Category) %>% 
  summarise(min_prop = min(Proportion),
            max_prop = max(Proportion))

lsoa_df_to_add <- num_health %>% 
  left_join(prop_health, by = 'LSOA21CD')

lsoa_21_health <- st_read(paste0(output_directory, '/sussex_2021_lsoas.geojson')) %>% 
  as_Spatial(IDs = 'LSOA21CD') %>% 
  left_join(lsoa_df_to_add, by = 'LSOA21CD') %>% 
  left_join(final_lsoa_pcn_lookup[c('LSOA21CD', 'PCN_Name')], by = 'LSOA21CD') %>% 
  select(!c(Population, Persons_per_square_kilometre))

geojson_write(lsoa_21_health, file = paste0(output_directory, '/sussex_2021_lsoas_health.geojson'))
packages <- c('easypackages', 'tidyr', 'ggplot2', 'dplyr', 'scales', 'readxl', 'readr', 'stringr')
install.packages(setdiff(packages, rownames(installed.packages())))
easypackages::libraries(packages)

# https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationandhouseholdestimatesenglandandwalescensus2021/census2021/census2021firstresultsenglandwales1.xlsx

local_store <- '//chi_nas_prod2.corporate.westsussex.gov.uk/groups2.bu/Public Health Directorate/PH Research Unit/Census 2021'

if(file.exists('//chi_nas_prod2.corporate.westsussex.gov.uk/groups2.bu/Public Health Directorate/PH Research Unit/Census 2021/First_results_EW_28_June_22.xlsx') != TRUE){
  download.file('https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationandhouseholdestimatesenglandandwalescensus2021/census2021/census2021firstresultsenglandwales1.xlsx', paste0(local_store, '/First_results_EW_28_June_22.xlsx'), mode = 'wb')
}

# This is rounded to nearest 100
First_results_EW_raw_df_1 <- read_excel(paste0(local_store, '/First_results_EW_28_June_22.xlsx'), 
                                        sheet = "P03", skip = 7) %>% 
  pivot_longer(cols = `All persons`:`Males:\r\nAged 90 years and over\r\n[note 12]`,
               names_to = 'Age',
               values_to = 'Population') %>% 
  filter(Age != 'All persons') %>% 
  mutate(Sex = ifelse(substr(Age, 1,1) == 'F', 'Females', ifelse(substr(Age, 1,1) == 'M', 'Males', ifelse(substr(Age, 1,1) == 'A', 'Persons', NA)))) %>% 
  mutate(Age_group = ifelse(str_detect(Age, '4 years and under'), '0-4 years', ifelse(str_detect(Age, '5 to 9 years'), '5-9 years', ifelse(str_detect(Age, '10 to 14'), '10-14 years', ifelse(str_detect(Age, '15 to 19 years'), '15-19 years', ifelse(str_detect(Age, '20 to 24'), '20-24 years', ifelse(str_detect(Age, '25 to 29 years'), '25-29 years', ifelse(str_detect(Age, '30 to 34'), '30-34 years', ifelse(str_detect(Age, '35 to 39 years'), '35-39 years', ifelse(str_detect(Age, '40 to 44'), '40-44 years', ifelse(str_detect(Age, '45 to 49 years'), '45-49 years', ifelse(str_detect(Age, '50 to 54'), '50-54 years', ifelse(str_detect(Age, '55 to 59 years'), '55-59 years', ifelse(str_detect(Age, '60 to 64'), '60-64 years',  ifelse(str_detect(Age, '65 to 69 years'), '65-69 years', ifelse(str_detect(Age, '70 to 74'), '70-74 years', ifelse(str_detect(Age, '75 to 79 years'), '75-79 years', ifelse(str_detect(Age, '80 to 84'), '80-84 years', ifelse(str_detect(Age, '85 to 89 years'), '85-89 years', ifelse(str_detect(Age, '90 years and over'), '90+ years', NA)))))))))))))))))))) %>% 
  mutate(Age_group = factor(ifelse(Age_group %in% c('80-84 years', '85-89 years', '90+ years'), '80+ years', Age_group), levels = c('0-4 years', '5-9 years', '10-14 years', '15-19 years', '20-24 years', '25-29 years', '30-34 years', '35-39 years', '40-44 years', '45-49 years', '50-54 years', '55-59 years', '60-64 years', '65-69 years', '70-74 years', '75-79 years', '80+ years'))) %>% 
  select(Area = 'Area name', Sex, Age_group, Population) %>% 
  group_by(Area, Sex, Age_group) %>% 
  summarise(Population = sum(Population, na.rm = TRUE)) %>% 
  ungroup() %>% 
  filter(Area %in% c('Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing', 'West Sussex')) %>% 
  mutate(Data_source = 'Census 2021')

First_results_EW_raw_df_2 <- read_excel(paste0(local_store, '/First_results_EW_28_June_22.xlsx'), 
                                        sheet = "P02", skip = 7) %>% 
  pivot_longer(cols = `All persons`:`Aged 90 years and over\r\n[note 12]`,
               names_to = 'Age',
               values_to = 'Population') %>% 
  filter(Age != 'All persons') %>% 
  mutate(Sex = 'Persons') %>% 
  mutate(Age_group = ifelse(str_detect(Age, '4 years and under'), '0-4 years', ifelse(str_detect(Age, '5 to 9 years'), '5-9 years', ifelse(str_detect(Age, '10 to 14'), '10-14 years', ifelse(str_detect(Age, '15 to 19 years'), '15-19 years', ifelse(str_detect(Age, '20 to 24'), '20-24 years', ifelse(str_detect(Age, '25 to 29 years'), '25-29 years', ifelse(str_detect(Age, '30 to 34'), '30-34 years', ifelse(str_detect(Age, '35 to 39 years'), '35-39 years', ifelse(str_detect(Age, '40 to 44'), '40-44 years', ifelse(str_detect(Age, '45 to 49 years'), '45-49 years', ifelse(str_detect(Age, '50 to 54'), '50-54 years', ifelse(str_detect(Age, '55 to 59 years'), '55-59 years', ifelse(str_detect(Age, '60 to 64'), '60-64 years',  ifelse(str_detect(Age, '65 to 69 years'), '65-69 years', ifelse(str_detect(Age, '70 to 74'), '70-74 years', ifelse(str_detect(Age, '75 to 79 years'), '75-79 years', ifelse(str_detect(Age, '80 to 84'), '80-84 years', ifelse(str_detect(Age, '85 to 89 years'), '85-89 years', ifelse(str_detect(Age, '90 years and over'), '90+ years', NA)))))))))))))))))))) %>% 
  mutate(Age_group = factor(ifelse(Age_group %in% c('80-84 years', '85-89 years', '90+ years'), '80+ years', Age_group), levels = c('0-4 years', '5-9 years', '10-14 years', '15-19 years', '20-24 years', '25-29 years', '30-34 years', '35-39 years', '40-44 years', '45-49 years', '50-54 years', '55-59 years', '60-64 years', '65-69 years', '70-74 years', '75-79 years', '80+ years'))) %>% 
  select(Area = 'Area name', Sex, Age_group, Population) %>% 
  group_by(Area, Sex, Age_group) %>% 
  summarise(Population = sum(Population, na.rm = TRUE)) %>% 
  ungroup() %>% 
  filter(Area %in% c('Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing', 'West Sussex')) %>% 
  mutate(Data_source = 'Census 2021')

First_results_EW_raw_df <- First_results_EW_raw_df_1 %>% 
  bind_rows(First_results_EW_raw_df_2) %>% 
  mutate(Sex = factor(Sex, levels = c('Females', 'Males', 'Persons')))


First_results_EW_raw_df %>% 
  View()

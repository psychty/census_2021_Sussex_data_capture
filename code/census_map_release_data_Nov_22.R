

# Census MSOA population estimates

# Loading some packages 
packages <- c('easypackages', 'tidyr', 'ggplot2', 'plyr', 'dplyr', 'scales', 'readxl', 'readr', 'purrr', 'stringr', 'PHEindicatormethods', 'rgdal', 'spdplyr', 'geojsonio', 'rmapshaper', 'jsonlite', 'rgeos', 'sp', 'sf', 'maptools', 'ggpol', 'magick', 'officer', 'leaflet', 'leaflet.extras', 'zoo', 'fingertipsR', 'nomisr', 'showtext', 'waffle', 'lemon', 'ggstream')
install.packages(setdiff(packages, rownames(installed.packages())))
easypackages::libraries(packages)

base_directory <- 'C:/Users/asus/OneDrive/Documents/Repositories/census_2021_sussex_data_capture'

output_directory <- paste0(base_directory, '/outputs')

data_directory <- paste0(base_directory, '/raw_data')

if(dir.exists(data_directory) != TRUE){
  dir.create(data_directory)
}

if(dir.exists(output_directory) != TRUE){
  dir.create(output_directory)
}

# Custom fonts ####

# https://cran.rstudio.com/web/packages/showtext/vignettes/introduction.html
library(showtext)
## Loading Google fonts (https://fonts.google.com/)
font_add_google('Poppins', 'poppins')

font_add(family = "poppins", regular = "C:/Users/asus/AppData/Local/Microsoft/Windows/Fonts/Poppins-Regular.ttf")
font_add(family = "poppinsb", regular = "C:/Users/asus/AppData/Local/Microsoft/Windows/Fonts/Poppins-Bold.ttf")

showtext_auto(TRUE)

ph_theme = function(){
  theme(
    plot.title = element_text(colour = "#000000", face = "bold", size = 12, family = 'poppinsb'),
    plot.subtitle = element_text(colour = "#000000", size = 12),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.background = element_rect(fill = "#FFFFFF"),
    panel.grid.major.y = element_line(colour = "#E7E7E7", size = .3),
    panel.grid.minor.y = element_blank(),
    strip.text = element_text(colour = "#000000", size = 11),
    strip.background = element_blank(),
    axis.ticks = element_line(colour = "#dbdbdb"),
    legend.title = element_text(colour = "#000000", size = 11, face = "bold"),
    legend.background = element_rect(fill = "#ffffff"),
    legend.key = element_rect(fill = "#ffffff", colour = "#ffffff"),
    legend.key.size = unit(.5,"line"),
    legend.text = element_text(colour = "#000000", size = 11),
    axis.text = element_text(colour = "#000000", size = 11),
    axis.title =  element_text(colour = "#000000", size = 11, face = "bold"),
    axis.line = element_line(colour = "#dbdbdb"),
    legend.position = 'none',
    # plot.margin = margin(t = 1, r = 1.5, b = 0.2,l = 0, unit = 'cm'),
    text = element_text(family = 'poppins'))}



# Key info ####
# Sometimes we need to make changes to data if it is possible to identify individuals. This is known as statistical disclosure control.

# In Census 2021, we swapped records (targeted record swapping), for example, if a household was likely to be identified in datasets because it has unusual characteristics, we swapped the record with a similar one from a nearby small area (very unusual households could be swapped with one in a nearby local authority)

# We also added small changes to some counts (cell key perturbation), for example, we might change a count of four to a three or a five -- this might make small differences between tables depending on how the data are broken down when we applied perturbation

# Age MSOAs

if(file.exists( paste0(data_directory, '/TS007_resident_age_msoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS007_resident_age_101a/UR-msoa%2Bresident_age_101a.xlsx',
                paste0(data_directory, '/TS007_resident_age_msoa.xlsx'),
                mode = 'wb')
}

TS007_resident_age_msoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS007_resident_age_msoa.xlsx", 
                                      sheet = "Table")
              


# Number of households ####

# Output area

if(file.exists( paste0(data_directory, '/TS041_number_households_oa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS041_households/atc-ts-demmig-hh-ct-oa-oa.xlsx',
                paste0(data_directory, '/TS041_number_households_oa.xlsx'),
                mode = 'wb')
}

TS041_number_households_oa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS041_number_households_oa.xlsx", 
                                      sheet = "Table")

# LSOA

if(file.exists( paste0(data_directory, '/TS041_number_households_lsoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS041_households/atc-ts-demmig-hh-ct-oa-lsoa.xlsx',
                paste0(data_directory, '/TS041_number_households_lsoa.xlsx'),
                mode = 'wb')
}

TS041_number_households_lsoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS041_number_households_lsoa.xlsx", 
                                         sheet = "Table")


# Population density ####


# Output area

if(file.exists( paste0(data_directory, '/TS006_pop_density_oa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS006_population_density/atc-ts-demmig-ur-pd-oa-oa.xlsx',
                paste0(data_directory, '/TS006_pop_density_oa.xlsx'),
                mode = 'wb')
}

TS006_pop_density_oa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS006_pop_density_oa.xlsx", 
                                         sheet = "Table")

# LSOA

if(file.exists( paste0(data_directory, '/TS006_pop_density_lsoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS006_population_density/atc-ts-demmig-ur-pd-oa-oa.xlsx',
                paste0(data_directory, '/TS006_pop_density_lsoa.xlsx'),
                mode = 'wb')
}

TS006_pop_density_lsoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS041_number_households_lsoa.xlsx", 
                                           sheet = "Table")


#  Age by sex = LTLA

if(file.exists( paste0(data_directory, '/TS009_age_sex_ltla.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS009_sex_resident_age_91a/UR-ltla%2Bsex%2Bresident_age_91a.xlsx',
                paste0(data_directory, '/TS009_age_sex_ltla.xlsx'),
                mode = 'wb')
}

TS009_age_sex_ltla <- read_excel("census_2021_Sussex_data_capture/raw_data/TS009_age_sex_ltla.xlsx", 
                                     sheet = "Table")


# Household composition ####
if(file.exists( paste0(data_directory, '/TS003_household_composition_lsoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS003_hh_family_composition_15a/HH-lsoa%2Bhh_family_composition_15a.xlsx',
                paste0(data_directory, '/TS003_household_composition_lsoa.xlsx'),
                mode = 'wb')
}

TS003_household_composition_lsoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS003_household_composition_lsoa.xlsx", 
                                 sheet = "Table")

unique(TS003_household_composition_lsoa$`Household composition (15 categories) Label`)


# household size #### 

if(file.exists( paste0(data_directory, '/TS017_household_size_lsoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS017_hh_size_9a/HH-lsoa%2Bhh_size_9a.xlsx',
                paste0(data_directory, '/TS017_household_size_lsoa.xlsx'),
                mode = 'wb')
}

TS017_household_size_lsoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS017_household_size_lsoa.xlsx", 
                                               sheet = "Table")

unique(TS017_household_size_lsoa$`Household size (9 categories) Label`)


# household deprivation ####

if(file.exists( paste0(data_directory, '/TS011_household_deprivation_lsoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS011_hh_deprivation/HH-lsoa%2Bhh_deprivation.xlsx',
                paste0(data_directory, '/TS011_household_deprivation_lsoa.xlsx'),
                mode = 'wb')
}

TS011_household_deprivation_lsoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS011_household_deprivation_lsoa.xlsx", 
                                        sheet = "Table")

unique(TS011_household_deprivation_lsoa$`Household deprivation (6 categories) Label`)


# legal partnerships ####

if(file.exists( paste0(data_directory, '/TS002_legal_partnerships_lsoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS002_legal_partnership_status/UR-lsoa%2Blegal_partnership_status.xlsx',
                paste0(data_directory, '/TS002_legal_partnerships_lsoa.xlsx'),
                mode = 'wb')
}

TS002_legal_partnerships_lsoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS002_legal_partnerships_lsoa.xlsx", 
                                               sheet = "Table")

unique(TS002_legal_partnerships_lsoa$`Marital and civil partnership status (12 categories) Label`)


# Living arrangements - MSOA only ####

if(file.exists( paste0(data_directory, '/TS010_Living_arrangements_msoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS010_living_arrangements_11a/UR_HH-msoa%2Bliving_arrangements_11a.xlsx',
                paste0(data_directory, '/TS010_Living_arrangements_msoa.xlsx'),
                mode = 'wb')
}

TS010_Living_arrangements_msoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS010_Living_arrangements_msoa.xlsx", 
                                            sheet = "Table")

unique(TS010_Living_arrangements_msoa$`Living arrangements (11 categories) Label`)

# residence type 


if(file.exists( paste0(data_directory, '/TS001_residence_type_lsoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS001_residence_type/atc-ts-demmig-ur-ct-oa-lsoa%2Bresidence_type.xlsx',
                paste0(data_directory, '/TS001_residence_type_lsoa.xlsx'),
                mode = 'wb')
}

TS001_residence_type_lsoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS001_residence_type_lsoa.xlsx", 
                                             sheet = "Table")

unique(TS001_residence_type_lsoa$`Residence type (2 categories) Label`)

# age of arrival to UK ####

if(file.exists( paste0(data_directory, '/TS018_age_of_arrival_lsoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS018_age_arrival_uk_18a/atc-ts-demmig-ur-ct-oa-lsoa%2Bage_arrival_uk_18a.xlsx',
                paste0(data_directory, '/TS018_age_of_arrival_lsoa.xlsx'),
                mode = 'wb')
}

TS018_age_of_arrival_lsoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS018_age_of_arrival_lsoa.xlsx", 
                                        sheet = "Table")

TS018_age_of_arrival_lsoa %>%  View()

# Country of birth overview ####

if(file.exists( paste0(data_directory, '/TS004_country_of_birth_lsoa.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS004_country_of_birth_12a/atc-ts-demmig-ur-ct-oa-lsoa%2Bcountry_of_birth_12a.xlsx',
                paste0(data_directory, '/TS004_country_of_birth_lsoa.xlsx'),
                mode = 'wb')
}

TS004_country_of_birth_lsoa <- read_excel("census_2021_Sussex_data_capture/raw_data/TS004_country_of_birth_lsoa.xlsx", 
                                        sheet = "Table")

unique(TS004_country_of_birth_lsoa$`Country of birth (12 categories) Label`)

# Country of birth detailed - LTLA only ####

if(file.exists( paste0(data_directory, '/TS012_country_of_birth_detailed_ltla.xlsx')) != TRUE){
  download.file('https://ons-dp-prod-census-publication.s3.eu-west-2.amazonaws.com/TS012_country_of_birth_60a/UR-ltla%2Bcountry_of_birth_60a.xlsx',
                paste0(data_directory, '/TS012_country_of_birth_detailed_ltla.xlsx'),
                mode = 'wb')
}

TS012_country_of_birth_detailed_ltla <- read_excel("census_2021_Sussex_data_capture/raw_data/TS012_country_of_birth_detailed_ltla.xlsx", 
                                     sheet = "Table")

unique(TS012_country_of_birth_detailed_ltla$`Country of birth (60 categories) Label`)

#
### Local authority disability data by age and sex. 
### Source: Census 2021, ONS.
### February 2023.


# STEP 1: Set working directory ####

setwd("C:/Users/cwix1380/OneDrive - West Sussex County Council/PUBLIC HEALTH/PHSRU/Census 2021/Disability - age, sex, deprivation/DisabilityR")

# STEP 2: Load Packages ####
library(tidyverse)
library(RColorBrewer)

# STEP 3: Import data ####

# Import age and sex disability data - Census 2021

disability <- read_csv("disabilitycensus2021_R.csv", skip = 3) %>%
  mutate(age_factor = factor(age, levels = c("Under 1", "1 to 4", "5 to 9", "10 to 14", "15 to 19", "20 to 24", "25 to 29", "30 to 34", "35 to 39", "40 to 44", "45 to 49", "50 to 54", "55 to 59", "60 to 64", "65 to 69", "70 to 74", "75 to 79", "80 to 84", "85 to 89", "90+"))) %>%
  mutate(disability_status_factor = factor(disability_status, levels = c("Non-disabled", "Disabled", "Disabled; limited a little", "Disabled; limited a lot")))

# Import count and % data inlcuding WSx (but not split by age or sex!)
disability_wsx <- read_csv("disability_wsx.csv", skip = 4) 



# Import IMD disability data - Census 2021

disability_imd_2021 <- read_csv("disabilitycensus2021_IMD.csv", skip = 3) %>%
  mutate(disability_status_factor = factor(disability_status, levels = c("Non-disabled", "Disabled", "Disabled; limited a little", "Disabled; limited a lot")))



# Import age and sex disability data - Census 2011

disability_2011 <- read_csv("disabilitycensus2011_R.csv", skip = 3) %>%
  mutate(age_factor = factor(age, levels = c("Under 1", "1 to 4", "5 to 9", "10 to 14", "15 to 19", "20 to 24", "25 to 29", "30 to 34", "35 to 39", "40 to 44", "45 to 49", "50 to 54", "55 to 59", "60 to 64", "65 to 69", "70 to 74", "75 to 79", "80 to 84", "85 to 89", "90+"))) %>%
  mutate(disability_status_factor = factor(disability_status, levels = c("Non-disabled", "Disabled", "Disabled; limited a little", "Disabled; limited a lot")))


# Create new table with only WSx D&Bs and the SE and England 
wsx_ltla_disability_2011 <- disability_2011 %>%
  filter(area %in% c("Adur", "Arun", "Chichester", "Crawley", "Horsham", "Mid Sussex", "Worthing", "South East", "England"))


# Combine the 2011 and 2021 census data (age and sex data)
combined2011_2021 <- bind_rows(wsx_ltla_disability_2011, disability) %>%
  mutate(row_ID = row_number())





# STEP 4: Make graphs of LTLA, SE and Eng percentages split by age and sex ####

# Three category disability - disability by age and sex in D&Bs
# Made 3 plots to join together in ppoint

adur_crawley_worthing <-
ggplot(data = filter(disability, category=="Three category",  sex %in% c("Female", "Male"), area %in% c("Adur", "Crawley", "Worthing")), mapping = aes(x=age_specific_percentage , y=age_factor)) +
  geom_col(mapping = aes(fill = disability_status_factor)) +
  facet_grid(area ~ sex) +
  labs(x = "Age specific percentage (%)", y = "Age band") +
  scale_fill_manual(values=c("#313695",  "#fdae61", "#a50026"), breaks = c("Non-disabled", "Disabled; limited a little", "Disabled; limited a lot"), name = "") +
  theme_light() +
  theme(strip.text.y = element_blank(), legend.position = "bottom", axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10)))

#save plot  
ggsave(plot = adur_crawley_worthing, filename = "adur_crawley_worthing.png", type = "cairo", dpi= 200, width = 8, height = 30, unit = "cm")


arun_horsham <-
ggplot(data = filter(disability, category=="Three category",  sex %in% c("Female", "Male"), area %in% c("Arun", "Horsham")), mapping = aes(x=age_specific_percentage , y=age_factor)) +
  geom_col(mapping = aes(fill = disability_status_factor)) +
  facet_grid(area ~ sex) +
  labs(x = "Age specific percentage (%)", y = "Age band") +
  scale_fill_manual(values=c("#313695",  "#fdae61", "#a50026"), breaks = c("Non-disabled", "Disabled; limited a little", "Disabled; limited a lot"), name = "") +
  theme_light() +
  theme(strip.text.y = element_blank(), legend.position = "bottom", axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10)))

#save plot  
ggsave(plot = arun_horsham, filename = "arun_horsham.png", type = "cairo", dpi= 200, width = 8, height = 20, unit = "cm")


chichester_midsussex <-
ggplot(data = filter(disability, category=="Three category",  sex %in% c("Female", "Male"), area %in% c("Chichester", "Mid Sussex")), mapping = aes(x=age_specific_percentage , y=age_factor)) +
  geom_col(mapping = aes(fill = disability_status_factor)) +
  facet_grid(area ~ sex) +
  labs(x = "Age specific percentage (%)", y = "Age band") +
  scale_fill_manual(values=c("#313695",  "#fdae61", "#a50026"), breaks = c("Non-disabled", "Disabled; limited a little", "Disabled; limited a lot"), name = "") +
  theme_light() +
  theme(strip.text.y = element_blank(), legend.position = "bottom", axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10)))

#save plot  
ggsave(plot = chichester_midsussex, filename = "chichester_midsussex.png", type = "cairo", dpi= 200, width = 8, height = 20, unit = "cm")


# STEP 5: Get WSx numbers from adding up LTLAs; make age-specific percentages from these ####


# Make new table of summed LTLA count and population to give WSx total numbers; mutate new column to give age-specific percentages 
wsx_population <-
  combined2011_2021 %>% filter(category %in% c("Two category","Three category"), area %in% c("Adur", "Arun", "Chichester", "Crawley", "Horsham", "Mid Sussex", "Worthing")) %>% 
  select(year, area, category, disability_status_factor, sex, age_factor, count, Population) %>% 
  group_by(year, category, disability_status_factor, sex, age_factor) %>% 
  summarise(sum_population = sum(Population, na.rm = TRUE), sum_count = sum(count, na.rm = TRUE)) %>%
  mutate(age_specific_percent = (sum_count / sum_population)*100)


# To export to csv to make a table of the data
write.csv(wsx_population,"C:/Users/cwix1380/OneDrive - West Sussex County Council/PUBLIC HEALTH/PHSRU/Census 2021/Disability - age, sex, deprivation/DisabilityR//wsx_population.csv", row.names = FALSE)


# WSx plot - disability by age and sex
wsx_percentage_graph <-
  ggplot(data = filter(wsx_population, year=="2021", category=="Three category", sex %in% c("Female", "Male")), mapping = aes(x=age_specific_percent , y=age_factor)) +
  geom_col(mapping = aes(fill = disability_status_factor)) +
  labs(x = "Age specific percentage (%)", y = "Age band") +
  scale_fill_manual(values=c("#313695",  "#fdae61", "#a50026"), breaks = c("Non-disabled", "Disabled; limited a little", "Disabled; limited a lot"), name = "") +
  facet_wrap(~ sex) +
  theme_light() +
  theme(legend.position = "bottom", axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10)))

#save plot  
ggsave(plot = wsx_percentage_graph, filename = "wsx_percentage_graph.png", type = "cairo", dpi= 200, width = 8, height = 10, unit = "cm")



# ENG plot - disability by age and sex
ENG_percentage_graph <-
ggplot(data = filter(disability, category=="Three category", sex %in% c("Female", "Male"), area %in% c("England")), mapping = aes(x=age_specific_percentage , y=age_factor)) +
  geom_col(mapping = aes(fill = disability_status_factor)) +
  labs(x = "Age specific percentage (%)", y = "Age band") +
  scale_fill_manual(values=c("#313695",  "#fdae61", "#a50026"), breaks = c("Non-disabled", "Disabled; limited a little", "Disabled; limited a lot"), name = "") +
  facet_wrap(~ sex) +
  theme_light() +
  theme(legend.position = "bottom", axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10)))

#save plot  
ggsave(plot = ENG_percentage_graph, filename = "ENG_percentage_graph.png", type = "cairo", dpi= 200, width = 8, height = 10, unit = "cm")


# South East plot - disability by age and sex
SE_percentage_graph <-
  ggplot(data = filter(disability, category=="Three category", sex %in% c("Female", "Male"), area %in% c("South East")), mapping = aes(x=age_specific_percentage , y=age_factor)) +
  geom_col(mapping = aes(fill = disability_status_factor)) +
  labs(x = "Age specific percentage (%)", y = "Age band") +
  scale_fill_manual(values=c("#313695",  "#fdae61", "#a50026"), breaks = c("Non-disabled", "Disabled; limited a little", "Disabled; limited a lot"), name = "") +
  facet_wrap(~ sex) +
  theme_light() +
  theme(legend.position = "bottom", axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10)))

#save plot  
ggsave(plot = SE_percentage_graph, filename = "SE_percentage_graph.png", type = "cairo", dpi= 200, width = 8, height = 10, unit = "cm")


# STEP XX - Graph of IMD data vs. disability ####

# Make graph of IMD decile against age-specific percentage of disability (all ages, two category), split by sex (Census 2021 data)
imd_graph <-
ggplot(data = filter(disability_imd_2021, category=="Two category", disability_status=="Disabled", sex %in% c("Female", "Male")), mapping = aes(x=imd_decile, y=age_specific_percentage)) +
  geom_col(mapping = aes(fill = sex), position = "dodge") +
  scale_x_continuous(expand = c(0,NA), breaks = seq(1:10)) + 
  labs(x = "IMD decile", y = "Age-standardised percentage (%)") +
  scale_y_continuous(expand = c(0,0),breaks=seq(0, 30, 5), limits = c(0,30)) +
  scale_fill_manual(values=c("#313695", "#fdae61"), breaks = c("Male", "Female"), name = "") +
  theme_light() +
  theme(panel.grid.major.x = element_blank(),legend.position = "bottom", panel.grid.minor = element_blank(), plot.margin = margin(0.5,0.5,0,0, unit = "cm"), axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10, l = 10))) 

#save plot  
ggsave(plot = imd_graph, filename = "imd_graph.png", type = "cairo", dpi= 200, width = 16, height = 9, unit = "cm")


# Graph of IMD decile against age-specific percentage of disability (all ages), split by disability status (Census 2021 data)
imd_status_graph <-
ggplot(data = filter(disability_imd_2021, category=="Three category", disability_status_factor %in% c("Disabled; limited a lot", "Disabled; limited a little"), sex %in% c("Persons")), mapping = aes(x=imd_decile, y=age_specific_percentage)) +
  geom_col(mapping = aes(fill = disability_status), position = "dodge") +
  scale_x_continuous(expand = c(0,NA), breaks = seq(1:10)) + 
  labs(x = "IMD decile", y = "Age-standardised percentage (%)") +
  scale_y_continuous(expand = c(0,0),breaks=seq(0, 14, 2), limits = c(0,14)) +
  scale_fill_manual(values=c("#313695", "#fdae61"), breaks = c("Disabled; limited a lot", "Disabled; limited a little"), name = "") +
  theme_light() +
  theme(panel.grid.major.x = element_blank(),legend.position = "bottom", panel.grid.minor = element_blank(), plot.margin = margin(0.5,0.5,0,0, unit = "cm"), axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10, l = 10))) 

#save plot  
ggsave(plot = imd_status_graph, filename = "imd_status_graph.png", type = "cairo", dpi= 200, width = 16, height = 9, unit = "cm")



## STEP XX - Make graphs of disability over time (2011 and 2021)

# Disability prevalence by age and by Census year (2011 and 2021), England.

ENG_disability_time_graph <-
ggplot(data = filter(combined2011_2021, category=="Two category", sex %in% c("Persons"), area %in% c("England"), disability_status_factor=="Disabled")) +
  geom_col(mapping = aes(x=age_specific_percentage , y=age_factor, fill = factor(year)), position = "dodge") +
  labs(x = "Age-specific percentage (%)", y = "Age band (years)") +
  scale_x_continuous(expand = c(0,NA), breaks = seq(0,100, 10), limits = c(0,100)) + 
  scale_fill_manual(values=c("#fdae61", "#313695"), breaks = c("2011", "2021"), name = "") +
  theme_light() +
  theme(legend.position = "bottom", panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(), axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10)), plot.margin = margin(0.5,0.5,0,0.5, unit = "cm"))

#save plot  
ggsave(plot = ENG_disability_time_graph, filename = "ENG_disability_time_graph.png", type = "cairo", dpi= 200, width = 10, height = 12, unit = "cm")


# WSx-specifc graphs - 2011 vs. 2021 by age ####


## GRAPH - total disability age-specific percentage by age (all persons, WSx), split by Census year
wsx_disability_time_graph <-
ggplot(data = filter(wsx_population, category=="Two category", sex %in% c("Persons"), disability_status_factor=="Disabled")) +
  geom_col(mapping = aes(x=age_specific_percent , y=age_factor, fill = factor(year)), position = "dodge") +
  labs(x = "Age-specific percentage (%)", y = "Age band (years)") +
  scale_x_continuous(expand = c(0,NA), breaks = seq(0,100, 10), limits = c(0,100)) + 
  scale_fill_manual(values=c("#fdae61", "#313695"), breaks = c("2011", "2021"), name = "") +
  theme_light() +
  theme(legend.position = "bottom", panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(), axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10)), plot.margin = margin(0.5,0.5,0,0.5, unit = "cm"))

#save plot  
ggsave(plot = wsx_disability_time_graph, filename = "wsx_disability_time_graph.png", type = "cairo", dpi= 200, width = 10, height = 12, unit = "cm")



# GRAPH - Limited a lot disability age-specific percentage by age (all persons, WSx), split by Census year
wsx_limited_lot_time_graph <-
ggplot(data = filter(wsx_population, category=="Three category", sex %in% c("Persons"), disability_status_factor=="Disabled; limited a lot")) +
  geom_col(mapping = aes(x=age_specific_percent, y=age_factor, fill = factor(year)), position = "dodge") +
  labs(x = "Age-specific percentage (%)", y = "Age band (years)") +
  scale_x_continuous(expand = c(0,NA), breaks = seq(0,70, 10), limits = c(0,70)) + 
  scale_fill_manual(values=c("#fdae61", "#313695"), breaks = c("2011", "2021"), name = "") +
  theme_light() +
  theme(legend.position = "bottom", panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(), axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10)), plot.margin = margin(0.5,0.5,0,0.5, unit = "cm"))

#save plot  
ggsave(plot = wsx_limited_lot_time_graph, filename = "wsx_limited_lot_time_graph.png", type = "cairo", dpi= 200, width = 10, height = 12, unit = "cm")


# GRAPH - Limited a little disability age-specific percentage by age (all persons, WSx), split by Census year
wsx_limited_little_time_graph <-
  ggplot(data = filter(wsx_population, category=="Three category", sex %in% c("Persons"), disability_status_factor=="Disabled; limited a little")) +
  geom_col(mapping = aes(x=age_specific_percent, y=age_factor, fill = factor(year)), position = "dodge") +
  labs(x = "Age-specific percentage (%)", y = "Age band (years)") +
  scale_x_continuous(expand = c(0,NA), breaks = seq(0,40, 10), limits = c(0,40)) + 
  scale_fill_manual(values=c("#fdae61", "#313695"), breaks = c("2011", "2021"), name = "") +
  theme_light() +
  theme(legend.position = "bottom", panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(), axis.title.x = element_text(margin = margin(t = 10)),  axis.title.y = element_text(margin = margin(r = 10)), plot.margin = margin(0.5,0.5,0,0.5, unit = "cm"))

#save plot  
ggsave(plot = wsx_limited_little_time_graph, filename = "wsx_limited_little_time_graph.png", type = "cairo", dpi= 200, width = 10, height = 12, unit = "cm")





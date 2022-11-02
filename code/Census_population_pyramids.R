# vaccine population ltla difference sussex

# Styles for our pyramid plots
pyramid_theme <- function(){
  theme(plot.background = element_rect(fill = "white", colour = "#ffffff"),
        panel.background = element_rect(fill = "white"),
        axis.text = element_text(colour = "#000000", size = 7),
        plot.title = element_text(colour = "#000000", face = "bold", size = 9, vjust = 1),
        plot.subtitle = element_text(colour = "#000000", size = 8, vjust = 1),
        axis.title = element_text(colour = "#000000", face = "bold", size = 8),
        panel.grid.major.x = element_line(colour = "#E2E2E3", linetype = "solid", size = 0.1),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_blank(),
        strip.text = element_text(colour = "#000000", size = 8),
        strip.background = element_rect(fill = "#ffffff"),
        axis.ticks = element_line(colour = "#E2E2E3"),
        legend.key.size = unit(.5, 'cm'),
        legend.title = element_text(size= 8), #change legend title font size
        legend.text = element_text(size=8),
        legend.position = 'none')}

# We use ggplot to create population pyramids by creating two facets (one for male and one for female) and control the direction of bars by making the female values negative and male values positive. So we need to create a function that creates an absolute (removes the sign) value and adds a comma separator.
abs_comma <- function (x, ...) {
  format(abs(x), ..., big.mark = ",", scientific = FALSE, trim = TRUE)}

# Load some packages ####
easypackages::libraries(c("readxl", "readr", 'plyr', "dplyr", 'readODS', "tidyverse", "scales",  'jsonlite', 'httr', 'rvest', 'stringr', 'ggpol', 'patchwork', 'grid', 'gridExtra')) # These packages allow you to read in data, manipulate it, and create visualisations

# Border style for flextable
bord_style <- fp_border(color = "black", style = "solid", width = .3)

# https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationandhouseholdestimatesenglandandwalescensus2021/census2021/census2021firstresultsenglandwales1.xlsx

if(file.exists('//chi_nas_prod2.corporate.westsussex.gov.uk/groups2.bu/Public Health Directorate/PH Research Unit/Census 2021/First_results_EW_28_June_22.xlsx') != TRUE){
download.file('https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationandhouseholdestimatesenglandandwalescensus2021/census2021/census2021firstresultsenglandwales1.xlsx', '//chi_nas_prod2.corporate.westsussex.gov.uk/groups2.bu/Public Health Directorate/PH Research Unit/Census 2021/First_results_EW_28_June_22.xlsx', mode = 'wb')
}

# This is rounded to nearest 100
First_results_EW_raw_df_1 <- read_excel("//chi_nas_prod2.corporate.westsussex.gov.uk/groups2.bu/Public Health Directorate/PH Research Unit/Census 2021/First_results_EW_28_June_22.xlsx", 
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

First_results_EW_raw_df_2 <- read_excel("//chi_nas_prod2.corporate.westsussex.gov.uk/groups2.bu/Public Health Directorate/PH Research Unit/Census 2021/First_results_EW_28_June_22.xlsx", 
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

Areas <- c('Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing', 'West Sussex')

compare_df <- First_results_EW_raw_df

for(i in 1:length(Areas)){
  
Area_x <- Areas[i]

pyramid_x_df <- compare_df %>% 
  filter(Area == Area_x)

compare_table_x <- compare_table_combined %>% 
  filter(Area == Area_x)

pyramid_x_df_limit <- pyramid_x_df %>% 
  filter(Sex != 'Persons') %>% 
  mutate(Population = abs(Population)) %>% 
  select(Population) %>% 
  unique() %>% 
  max()

pyramid_x_df_limit <- ifelse(pyramid_x_df_limit <= 1000, round_any(pyramid_x_df_limit, 500, ceiling), ifelse(pyramid_x_df_limit <= 5000, round_any(pyramid_x_df_limit, 1000, ceiling), ifelse(pyramid_x_df_limit <= 10000, round_any(pyramid_x_df_limit, 2000, ceiling), round_any(pyramid_x_df_limit, 5000, ceiling))))

pyramid_x_breaks <- ifelse(pyramid_x_df_limit <= 1000, 100,  ifelse(pyramid_x_df_limit <= 5000, 1000,  ifelse(pyramid_x_df_limit <= 10000, 2000, ifelse(pyramid_x_df_limit <= 20000, 5000, 10000))))

area_x_dummy <- pyramid_x_df %>% 
  mutate(Denominator_dummy = ifelse(Sex == 'Females', 0 - pyramid_x_df_limit, pyramid_x_df_limit)) %>% 
  filter(Sex != 'Persons')

pyramid_plot_a <- pyramid_x_df %>%
  filter(Sex != 'Persons') %>% 
  ggplot() +
  geom_bar(data = area_x_dummy, aes(x = New_age,
                                    y = Denominator_dummy /2),
           stat = "identity",
           fill = NA) +
  geom_bar(aes(x = New_age, 
               y = Population,
               fill = Data_source), 
           colour = '#c9c9c9',
           stat = "identity",
           position = position_dodge()) +
  scale_fill_manual(values =  c("#841f27", "#354e71"),
                    name = 'Data source') +
  labs(x = '',
       y = '',
       title = paste0('Population pyramid; ', Area_x, ';\ndifferences between Census 2021 and NIMS denominators;')) +
  facet_share(~Sex,
              dir = "h",
              scales = "free",
              switch = 'both',
              reverse_num = FALSE) +
  scale_y_continuous(labels = abs_comma,
                     breaks = seq(-pyramid_x_df_limit, pyramid_x_df_limit, pyramid_x_breaks)) +
  coord_flip() +
  pyramid_theme() +
  theme(legend.position = 'top')

area_x_dummy_b <- pyramid_x_df %>% 
  mutate(Denominator_dummy = ifelse(Sex == 'Females', 0 - pyramid_x_df_limit, pyramid_x_df_limit)) %>% 
  filter(Sex == 'Persons')


persons_x_df_limit <- pyramid_x_df %>% 
  filter(Sex == 'Persons') %>% 
  select(Population) %>% 
  unique() %>% 
  max()

persons_x_df_limit <- ifelse(persons_x_df_limit <= 1000, round_any(persons_x_df_limit, 500, ceiling), ifelse(persons_x_df_limit <= 5000, round_any(persons_x_df_limit, 1000, ceiling), ifelse(persons_x_df_limit <= 10000, round_any(persons_x_df_limit, 2000, ceiling), round_any(persons_x_df_limit, 5000, ceiling))))

persons_x_breaks <- ifelse(persons_x_df_limit <= 1000, 100,  ifelse(persons_x_df_limit <= 5000, 1000,  ifelse(persons_x_df_limit <= 10000, 2000, ifelse(persons_x_df_limit <= 20000, 5000, 10000))))

pyramid_plot_b <- pyramid_x_df %>%
  filter(Sex == 'Persons') %>% 
  ggplot() +
  geom_bar(aes(x = New_age, 
               y = Population,
               fill = Data_source), 
           colour = '#c9c9c9',
           width = 1,
           stat = "identity",
           position = position_dodge()) +
  scale_fill_manual(values =  c("#841f27", "#354e71")) +
  labs(x = '',
       y = '',
       title = paste0(Area_x, '; Persons;'),
       caption = 'Note: the scale is different on the total population figure') +
  scale_y_continuous(labels = abs_comma,
                     breaks = seq(-persons_x_df_limit, persons_x_df_limit, persons_x_breaks)) +
  coord_flip() +
  pyramid_theme() +
  theme(legend.position = 'none',
        plot.margin = margin(t = 0, r = 1, b = 0.2,l = 0, unit = 'cm'),
        plot.title = element_text(size = 14))

compare_df_x <- compare_df %>% 
  filter(Area == Area_x) %>% 
  filter(Sex == 'Persons') %>% 
  select(!Age_group) %>% 
  pivot_wider(names_from = 'Data_source',
              values_from = 'Population') %>% 
  mutate(Difference_on_rounded_figures = NIMS - `Census 2021`,
         Higher_estimate = ifelse(NIMS > `Census 2021`, 'NIMS higher', ifelse(`Census 2021` > NIMS, 'Census higher', 'Same rounded population'))) %>% 
  rename(Age_group = New_age)

compare_table_x <- compare_table_combined %>% 
  ungroup() %>% 
  filter(Area == Area_x) %>% 
  filter(Sex == 'Persons') %>%
  bind_rows(compare_df_x) %>% 
  mutate(`Census 2021` = format(`Census 2021`, big.mark = ',', trim = TRUE)) %>% 
  mutate(NIMS = format(NIMS, big.mark = ',', trim = TRUE)) %>% 
  mutate(Difference_on_rounded_figures = format(Difference_on_rounded_figures, big.mark = ',', trim = TRUE)) %>% 
  select(Age = 'Age_group', 'Census 2021\nestimate\n(rounded)' = 'Census 2021', 'NIMS estimate\n(rounded)' = NIMS, 'Difference\n(based on rounded\nestimates)' = Difference_on_rounded_figures) %>% 
  mutate(Age = factor(Age, levels = c('All ages', '5+ years', '5-14 years*', '15-64 years*', '65+ years', '0-4 years','5-9 years', '10-14 years**', '15-19 years**', '20-24 years', '25-29 years', '30-34 years', '35-39 years', '40-44 years', '45-49 years', '50-54 years', '55-59 years', '60-64 years', '65-69 years', '70-74 years', '75-79 years', '80+ years*'))) %>% 
  arrange(Age) 

compare_table_x_short <- compare_table_x %>% 
  filter(Age %in% c('All ages', '5+ years', '5-14 years*', '15-64 years*', '65+ years'))

TSpecial <- ttheme_minimal(
  core=list(bg_params = list(fill = c('#c9c9c9', '#ffffff','#c9c9c9', '#ffffff', '#c9c9c9'), 
                             col = NA),
            fg_params = list(fontsize = 10)),
  colhead=list(fg_params = list(col="#000000",
                                fontsize = 10,
                                fontface= 'bold'),
               padding = unit(c(1, 1), "mm")))

Ttitle <- textGrob(paste0(Area_x, ' population estimates; persons;'),
                   gp = gpar(fontsize = 12,
                             fontface = 'bold',
                             align = 'left'))

TCaption <- paste0('Note: values are rounded at the five year age band level *before* being aggregated which can result in differences to aggregated outputs published elsewhere.\n*To align with NIMS denominators for older groups (which cover 80+ years) we have summed the rounded values for 80-84, 85-89 and 90+ years in the census table.\n**NIMS population age groups do not align with census age groups for those aged 10-19, as NIMS uses a 10-11, 12-15, 16-17, and 18-19 banding\nand census uses 10-14 and 15-19 years.')

png(paste0("//chi_nas_prod2.corporate.westsussex.gov.uk/groups2.bu/Public Health Directorate/PH Research Unit/Census 2021/Census_vs_NIMS_infographic_", gsub(' ', '_', Area_x), '.png'),
    width = 1480,
    height = 980,
    res = 145)
print(pyramid_plot_a + (pyramid_plot_b / tableGrob(compare_table_x_short, rows = NULL, theme = TSpecial)) +
  inset_element(Ttitle, left = 0, right = 1, top = 0.45, bottom = 0.4) +
  plot_annotation(caption = TCaption))
dev.off()

}

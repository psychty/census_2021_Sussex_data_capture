
packages <- c('easypackages', 'tidyr', 'ggplot2', 'dplyr', 'scales', 'readxl', 'readr', 'purrr', 'stringr', 'jsonlite', 'nomisr', 'ggpol')
install.packages(setdiff(packages, rownames(installed.packages())))
easypackages::libraries(packages)

local_store <- '~/Repositories/census_2021_Sussex_data_capture/raw_data'
output_directory <- '~/Repositories/census_2021_Sussex_data_capture/outputs'

areas <- c('Brighton and Hove', 'Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden', 'Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing') 

nomis_area_types <- data.frame(Level = c('OA','LSOA','MSOA','LTLA', 'UTLA', 'Region'), Area_type_code = c('150','151','152','154', '155','480'))

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

# Extracting data ####

# NOTE # This code is also available in the Census_2021_population_estimates.R file

# This will take a minute as it is retrieving single year of age for all UTLAs for the last nine available years - 
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

esx_population <- census_LTLA_raw_df %>% 
  filter(Area %in% c('Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden')) %>% 
  filter(Age == 'Total: All usual residents') %>% 
  group_by(Sex) %>% 
  summarise(Population = sum(Population, na.rm = TRUE),
            Area = 'East Sussex',
            Year = 2021) %>% 
  pivot_wider(names_from = 'Sex',
              values_from = 'Population')

wsx_population <- census_LTLA_raw_df %>% 
  filter(Area %in% c('Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing')) %>% 
  filter(Age == 'Total: All usual residents') %>% 
  group_by(Sex) %>% 
  summarise(Population = sum(Population, na.rm = TRUE),
            Area = 'West Sussex',
            Year = 2021) %>% 
  pivot_wider(names_from = 'Sex',
              values_from = 'Population')

Total_population <- Total_population %>% 
  bind_rows(esx_population) %>% 
  bind_rows(wsx_population) %>% 
  mutate(Area = factor(Area, levels = c('Brighton and Hove', 'East Sussex', 'Eastbourne', 'Hastings', 'Lewes', 'Rother', 'Wealden', 'West Sussex', 'Adur', 'Arun', 'Chichester', 'Crawley', 'Horsham', 'Mid Sussex', 'Worthing'))) %>% 
  arrange(Area) 

rm(esx_population, wsx_population)

# A total df which might be useful for labels
Total_population

# When we clean the age field we use nested gsub() functions to remove the year part of Aged 1 year, the as well as the 'aged' and 'years' parts of the rest of the values. This does not work for the Aged under 1 year and Aged 90 years and over so ahead of this we do a conditional ifelse statement to tell R how to deal with those values.
census_LTLA_raw_df <- census_LTLA_raw_df %>% 
  filter(Age != 'Total: All usual residents') %>% 
  mutate(Age = as.numeric(ifelse(Age == 'Aged under 1 year', 0, ifelse(Age == 'Aged 90 years and over', 90, gsub(' year','', gsub(' years', '', gsub('Aged ', '', Age))))))) 

census_LTLA_five_year <- census_LTLA_raw_df %>%  
  mutate(Age_group = factor(ifelse(Age <= 4, "0-4 years", ifelse(Age <= 9, "5-9 years", ifelse(Age <= 14, "10-14 years", ifelse(Age <= 19, "15-19 years", ifelse(Age <= 24, "20-24 years", ifelse(Age <= 29, "25-29 years",ifelse(Age <= 34, "30-34 years", ifelse(Age <= 39, "35-39 years",ifelse(Age <= 44, "40-44 years", ifelse(Age <= 49, "45-49 years",ifelse(Age <= 54, "50-54 years", ifelse(Age <= 59, "55-59 years",ifelse(Age <= 64, "60-64 years", ifelse(Age <= 69, "65-69 years",ifelse(Age <= 74, "70-74 years", ifelse(Age <= 79, "75-79 years",ifelse(Age <= 84, "80-84 years",ifelse(Age <= 89, "85-89 years", "90+ years")))))))))))))))))), levels = c('0-4 years', '5-9 years','10-14 years','15-19 years','20-24 years','25-29 years','30-34 years','35-39 years','40-44 years','45-49 years','50-54 years','55-59 years','60-64 years','65-69 years','70-74 years','75-79 years','80-84 years','85-89 years', '90+ years')))  %>% 
  group_by(Area_code, Area, Year, Sex, Age_group) %>% 
  summarise(Population = sum(Population, na.rm = TRUE)) %>% 
  ungroup()

# The above is for every LTLA in England

# Population pyramid data preparation

# Get Sussex data only
sussex_ltla_pyramid_df <- census_LTLA_five_year %>% 
  filter(Sex != 'Persons') %>% 
  mutate(Sex = factor(Sex, levels = c('Male', 'Female'))) %>%  # coerce the Sex field to a factor and specify the order (levels) of that factor
  filter(Area %in% areas)

# As it is only for LTLAs we need to make a version for WSx and ESx
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

# We now have a dataframe suitable for use in ggplot to make population pyramids.
# This has one row per area, age, and sex combination 
pyramid_df <- sussex_ltla_pyramid_df %>% 
  select(!Area_code) %>% 
  bind_rows(wsx_pyramid_df) %>% 
  bind_rows(esx_pyramid_df)

# This is all we need to do if we are plotting a single population pyramid. However, if you want to compare areas, side by side, or with lines overlaid on top, we need to standardise the structure in some way because comparing West Sussex (with around 30,000 in some age bands) with Lewes (with a maximum of 4,000 in an age group) Lewes would be hard to spot. As such, we can convert the structure into percentages (so to say 5% of males are in 0-4 in West Sussex compared to 7% of males in 0-4 in Lewes (this is a fictional estimate)).

pyramid_df <- pyramid_df %>% 
  group_by(Area) %>% 
  mutate(Proportion = Population / sum(Population)) %>% 
  ungroup()

# exporting for web ####
# For plotting on a webpage using the d3 javascript library we need to put males and females in separate columns.
pyramid_df %>% 
  select(!c('Proportion', 'Year')) %>%
  pivot_wider(names_from = 'Sex',
              values_from = 'Population')  %>% 
  toJSON() %>% 
  write_lines(paste0(output_directory, '/Census_2021_pyramid_data.json'))

# TODO We also may want to have some broader summaries of the data (e.g. what is the proportion of over 65s, 18-64 year olds', under 18s etc) and maybe median age?

# Back to plotting in ggplot and R ####
# An example with West Sussex

Area_x <- 'West Sussex'

pyramid_x_df <- pyramid_df %>% 
  filter(Area == Area_x)

# To plot the pyramid we need to stitch a few layers together (this is essentially two bar charts turned sideways with one going in the opposite direction (negative numbers). We clean up the labels so they both look as they should to the reader. 

# We want to control the x axes so that they are symmetrical for both sexes (otherwise one might be longer than the other).

# We need a maximum value to make our pyramid 
pyramid_x_df_limit <- pyramid_x_df %>% 
  select(Population) %>% 
  unique() %>% 
  max()

# If we used this, and specified some automated break points we might end up with very strange ticks on the x axes (not neat rounded values)

# As such, we will use a nested ifelse statement (other method available) to transform the raw value to a rounded one. We cannot just use a round() function because rounding to the nearest 10 might work for one area but for West Sussex or other larger areas that wouldn't help us much. Equally if we rounded everything to the nearest 1,000, it would not look very good for smaller areas.

# I'd like to use the round_any() function from the plyr package, but the package is quite old and conflicts with dplyr package.
# The function is very straight forward though, and allows you to specify the value you'd like to round to (e.g. nearest 500, or 700)  
round_any = function(x, accuracy, f = round){f(x / accuracy) * accuracy}

# This is saying if the limit is up to and including 1,000, then round the number up (because we said ceiling rather than floor) to the nearest 200, if not then check to see if the limit is up to and including 5,000, if it is then round the number up to the nearest 1,000, if not then check if it is up to and including 10,000, then round up to the nearest 2,000, if not then check if the value is up to 30,000, if it is then round up to the nearest 5,000 and if none of those conditions are met (e.g. if the number is greater than 30,000, then round the limit up to the nearest 10,000)

pyramid_x_df_limit <- ifelse(pyramid_x_df_limit <= 1000, round_any(pyramid_x_df_limit, 200, ceiling),ifelse(pyramid_x_df_limit <= 5000, round_any(pyramid_x_df_limit, 1000, ceiling), ifelse(pyramid_x_df_limit <= 10000, round_any(pyramid_x_df_limit, 2000, ceiling), ifelse(pyramid_x_df_limit <= 30000, round_any(pyramid_x_df_limit, 5000, ceiling), round_any(pyramid_x_df_limit, 10000, ceiling)))))

# Then once we have the limit value, we can specify some sensible break points for the axes.
pyramid_x_breaks <- ifelse(pyramid_x_df_limit <= 1000, 100, 
                           ifelse(pyramid_x_df_limit <= 5000, 1000, 
                                  ifelse(pyramid_x_df_limit <= 10000, 2000,
                                         ifelse(pyramid_x_df_limit <= 40000, 5000, 
                                                10000))))

# Now we need to make a dummy population pyramid dataframe that fills the space on both sides (e.g. for West Sussex we want a dummy pyramid df that has bars of 35,000 on each side). We will use these on the ggplot but they will be blank (or white) so that the reader won't see them.

area_x_dummy <- pyramid_x_df %>% 
  mutate(Denominator_dummy = pyramid_x_df_limit) # We also need to give the population field a different name in order for ggplot to treat it differently.

pyramid_example_1 <- pyramid_x_df %>% # Use the pyramid_x_df with ggplot
  ggplot() +
  geom_bar(data = area_x_dummy, aes(x = Age_group,
                                    y = ifelse(Sex == 'Male', 0 - Denominator_dummy /2, Denominator_dummy / 2)), # Add a bar graph using the dummy dataframe (to get symmetrical male and female plots). Here we have change the sign from positive to negative for males 
           stat = "identity",
           fill = NA) + # fill is blank
  geom_bar(aes(x = Age_group, # Plot the actual values
               y = ifelse(Sex == 'Male', 0 - Population, Population), # Again, reversing the sign from positive to negative for males
               fill = Sex), # fill the bars by sex
           colour = '#c9c9c9', # add a border
           stat = "identity",
           position = position_dodge()) + # put the bars next to each other
  # give the values for each sex colour
  scale_fill_manual(values =  c("#741b47", "#f1c232"), 
                    name = 'Sex') +
  # Remove the x and y axes labels and add a title
  labs(x = '',
       y = '',
       title = paste0('Population pyramid; ', Area_x, ';'),
       subtitle = paste0('Census 2021;')) + 
  # Plot the males and females on separate figures
  facet_share(~Sex, 
              dir = "h",
              scales = "free",
              switch = 'both',
              reverse_num = FALSE) +
  # use the pyramid limits to set the breaks and change the values from negative numbers to positive
  scale_y_continuous(labels = abs_comma,
                     breaks = seq(-pyramid_x_df_limit, pyramid_x_df_limit, pyramid_x_breaks)) +
  # flip the plot on its side
  coord_flip() +
  # add some formatting
  pyramid_theme() 

pyramid_example_1

# You can save this as a png (raster image format) or svg (scalable vector format) file as follows

png(paste0(output_directory,'/West Sussex Census 2021 Population structure.png'),
    width = 1080,
    height = 1280,
    res = 160)
print(pyramid_example_1)
dev.off()

svg(paste0(output_directory, '/West Sussex Census 2021 Population structure.svg'),
    width = 6,
    height = 8,
    pointsize = 8)
print(pyramid_example_1)
dev.off()

# Looping ####

# TODO looping

for(i in 1:length(Areas)){
  
Area_x <- Areas[i]

pyramid_x_df <- compare_df %>% 
  filter(Area == Area_x)

compare_table_x <- compare_table_combined %>% 
  filter(Area == Area_x)


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

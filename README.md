# Census 2021 Sussex data capture

This repo is for sharing tools, mostly in R, to help collate, analyse, and visualise Census 2021 data as it becomes available.

I want this to be an inclusive, collaborative repo with contributors across our teams.

To start this, we have added a few scripts for creating maps and population pyramids.

# Data

The data used in this report come from the [Census 2021](https://census.gov.uk/) data store from the Office for National Statistics © Crown Copyright.

The data is reproduced under Open Government Licence.

# Scripts

There are some R scripts available in the '[code](./code/)' folder.

| Script name                      | Description                                                                                                                                                              |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Local_data_extraction.R          | downloading all available data for an area type to a local directory                                                                                                     |
| NomisR_data_extraction.R         | using the nomisr package to read data as you need it for the area you need it for                                                                                        |
| Small_areas.R                    | Explore differences in small area boundaries between 2011 and 2021 Censuses. This also creates and exports leaflet maps. Shows population estimates at small areas.      |
| Population_by_age_sex_pyramids.R | Extract population estimates for sex by single year of age for LTLAs and transform to five year and broad age groups for population pyramids and other summary analyses. |

#TODO We may need to work on making file paths relative to everyones work set up.

# Outputs

There is a [folder containing outputs including images and datasets](./outputs/). This will get bigger and bigger and may be reorganised into categories (images/data/lookups) later.

# Accompanying website

I have also created a website (which is written using the index.html, styles.css, and app.js files also on this repository).

This is hosted on netlify at the following address;
[https://census-2021-sussex-ph-overview.netlify.app](https://census-2021-sussex-ph-overview.netlify.app)

[![Netlify Status](https://api.netlify.com/api/v1/badges/ebcd429c-b829-4a06-89d9-c68fffa78dec/deploy-status)](https://app.netlify.com/sites/census-2021-sussex-ph-overview/deploys)

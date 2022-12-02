# Census 2021 Sussex data capture

This repo is for sharing tools, mostly in R, to help collate, analyse, and visualise Census 2021 data as it becomes available.

I want this to be an inclusive, collaborative repo with contributors across our teams.

To start this, we have added a few scripts for creating maps and population pyramids.

# Data

The data used in this report come from the [Census 2021](https://census.gov.uk/) data store from the Office for National Statistics © Crown Copyright.

The data is reproduced under Open Government Licence.

# Scripts

There are some R scripts available in the 'code' folder.

| Script name              | Description                                                                                                              |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| Local_data_extraction.R  | downloading all available data for an area type to a local directory                                                     |
| NomisR_data_extraction.R | using the nomisr package to read data as you need it for the area you need it for                                        |
| Output_area_changes.R    | Explore differences in small area boundaries between 2011 and 2021 Censuses. This also creates and exports leaflet maps. |

#TODO We may need to work on making file paths relative to everyones work set up.

# Outputs

# Accompanying website

I have also created a website (which is written using the index.html, styles.css, and app.js files also on this repository).

This is hosted on netlify at the following address.

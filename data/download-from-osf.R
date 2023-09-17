readRenviron("~/.Renviron")
library(osfr)
here::i_am("data/download-from-osf.R")
conflict_answer <- "overwrite"

osfcode <- "e6c5p"
osf_project <- osf_retrieve_node(sprintf("https://osf.io/%s", osfcode))
osf_all_files <- osf_ls_files(osf_project)


osfcode <- "vaund" 
osf_project <- osf_retrieve_node(sprintf("https://osf.io/%s", osfcode))
osf_all_files <- osf_ls_files(osf_project)

osf_download(osf_all_files,
             path = here::here("data"),
             conflicts = conflict_answer)

untar(here::here("data","rf-pred-current-CHELSA-testing.tar.bz2"),
      exdir = here::here("data","rf-pred-current-CHELSA"))

untar(here::here("data","rf-pred-current-CHELSA-region.tar.bz2"),
      exdir = here::here("data","rf-pred-current-CHELSA"))
untar(here::here("data","rf-spatial-pred-CHELSA.tar.bz2"),
      exdir = here::here("data","rf-spatial-pred-CHELSA"))

readRenviron("~/.Renviron")
library(osfr)
conflict_answer <- "overwrite"
osfcode <- "e6c5p"
osf_project <- osf_retrieve_node(sprintf("https://osf.io/%s", osfcode))
osf_all_files <- osf_ls_files(osf_project)
osf_download(osf_all_files,
             path = sprintf("%s/rf-input/", work.dir),
             conflicts = conflict_answer)
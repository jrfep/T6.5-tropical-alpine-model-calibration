
library(RefManageR)
library(dplyr)
library(stringr)
mountain_references <- read_csv("tables/refs_for_biblio_creator.csv", show_col_types = FALSE)
ref_list <- filter(mountain_references, grepl("https://doi.org/",url)) %>%
  pull(url) %>%
  str_replace("https://doi.org/","")
for (x in ref_list) {
  bib <- ReadCrossRef(filter = list(doi = x), min.relevance = 0)
  cat((toBiblatex(bib)),file="temp_ref.bib",append = TRUE)
  cat("\n\n",file="temp_ref.bib",append=TRUE)
}



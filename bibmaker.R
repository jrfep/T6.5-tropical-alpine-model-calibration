

library(RefManageR)
bib <- ReadCrossRef(filter = list(doi = "10.1016/j.yqres.2009.02.005"), min.relevance = 0)
toBiblatex(bib)

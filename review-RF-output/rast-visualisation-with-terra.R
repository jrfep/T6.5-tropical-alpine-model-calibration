# remotes::install_github("dieghernan/tidyterra")
library(tidyterra)
library(terra)
spatial_pred <- rast(here::here("data","rf-spatial-pred-CHELSA","GMBA_V2_L03-Eastern-Arc-Mountains.tif"))

GMBA <- vect(here::here("data","GMBA_inventory_valid.gpkg")) %>%
  filter(MapUnit %in% "Basic") %>%
  filter(Level_03 %in% "Eastern Arc Mountains")
         
# Facet all layers
library(ggplot2)

slc <- GMBA %>% filter(MapName %in% "Nguru Mountains")
slc <- GMBA %>% filter(MapName %in% "South Pare")

rst <- crop(spatial_pred,slc) %>% select("T6.4")
ggplot(slc) +
  geom_spatraster(data = rst ) +
  geom_spatvector(fill=NA) +
  facet_wrap(~lyr) +
  scale_fill_whitebox_c(
    palette = "viridi",
    n.breaks = 12,
    direction = -1,
    guide = guide_legend(reverse = TRUE)
  ) +
  theme_minimal() +
  labs(
    fill = "",
    title = "Probability of class",
    subtitle = "Ecosystem Functional Groups"
  )

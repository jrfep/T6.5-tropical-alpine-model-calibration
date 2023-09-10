#
# This is a Shiny dashboard. You can run the application by clicking
# the 'Run App' button above.
#

library(shiny)
library(shinydashboard)
library(shinythemes)

here::i_am("Africa-dashboard/app.R")

require(dplyr)
library(tidyr)
library(ggplot2)
require(sf)
library(mapview)
library(leaflet)
library(stringr)
library(DT)
library(readr)

records_file <- here::here("data","EFG-records-GMBA.rds")
EFG_records <- readRDS(file=records_file) 
GMBA <- read_sf(here::here("data","GMBA_inventory_valid.gpkg")) %>%
  filter(MapUnit %in% "Basic") %>%
  filter(Level_01 %in% "Africa",Level_03 %in% EFG_records$GMBA_group) 
clrs <- c("other" = "aliceblue",
          "T1.3" = "palegreen",
          "T2.1" = "darkgreen",
          "T3.1" = "maroon",
          "T6.1" = "cyan",
          "T6.4" = "wheat4",
          "T6.5" = "wheat")

clrs <- wesanderson::wes_palette("Moonrise3",n=7, type = "continuous")
names(clrs) <- c("T6.1", "other",  "T3.1", "T1.3", "T2.1", "T6.4", "T6.5")
clrs["other"] <- "whitesmoke"
clrs <- clrs[sort(names(clrs))]

ui <- dashboardPage(
  skin = "purple",
  header = dashboardHeader(title = "Basic dashboard"),
  sidebar = dashboardSidebar(
    sidebarMenu(
      {
        regs <- c("Southern Rift Mountains", "Atlantic Plateau (Brazil)", "Hawaian Islands")
        regs <- GMBA %>% st_drop_geometry() %>% distinct(Level_03) %>% pull
        selectInput('xreg', 'Select the region of interest', regs)},
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Widgets", tabName = "widgets", icon = icon("th"))
    )
  ),
  body = dashboardBody(
    tabItems(
      # First tab content
      tabItem(tabName = "dashboard",
              fluidRow(
                leafletOutput("mapPlot")
              ),
              fluidRow(
                box(plotOutput("histPlot")),
                box(dataTableOutput("filteredTable"))
              )
      ),
      
      # Second tab content
      tabItem(tabName = "widgets",
              h2("Widgets tab content")
      )
    )
  )
)

server <- function(input, output) { 
  
  selectedPred <- reactive({
    pred_file <- here::here("data", "rf-pred-current-CHELSA",
                            sprintf("GMBA_V2_L03-%s-region.csv", 
                                    str_replace_all(input$xreg, 
                                                    "[ \\(\\)*\\/]+", "-")))
    prds <- read_csv(pred_file, col_types = "ddddddd") 
    if (nrow(prds)>100)
      prds <- prds %>% slice_sample(n=100)
    prds <- prds %>% 
      arrange(T6.5, T1.3, T3.1) %>%
      mutate(id=row_number()) %>%
      pivot_longer(cols = 1:7, names_to = "pred_EFG", values_to = "prob") %>%
      filter(prob > 0)

    return(prds)
  })
  selectedMapView <- reactive({
    EFG_slc <- filter(EFG_records, GMBA_group %in% input$xreg)
    GMBA_slc <- filter(GMBA, Level_03 %in% input$xreg) %>% 
      dplyr::select(MapName, Elev_High)
    slc_clrs <- clrs[match(unique(EFG_slc$EFG),names(clrs)) ]
    
    m <- mapview(EFG_slc, zcol = "EFG", col.regions = slc_clrs) +
      mapview(GMBA_slc, zcol = "MapName")
  })
  
  selectedTable <- reactive({
    GMBA %>% 
      st_drop_geometry() %>% 
      filter(Level_03 %in% input$xreg) %>% 
      transmute(Level_01, Level_02, Level_03, 
                Name = if_else(!is.na(WikiDataUR),
                               sprintf("<a href='%s' target='out'>%s</a>", 
                                       WikiDataUR, MapName),
                               MapName),
                Elev_High) %>%
      arrange(Level_01, Level_02, Level_03)
  })
  
  ## outputs 
  output$mapPlot <- renderLeaflet({
    selectedMapView()@map
  })
  
  output$filteredTable <- renderDataTable({
    DT::datatable(selectedTable(), rownames = FALSE, escape = FALSE)
  })
  
  output$histPlot <- renderPlot({
      ggplot(selectedPred()) + 
      geom_bar(aes(y=prob, x=id, fill=pred_EFG), stat = "identity") +
      scale_fill_manual(values = rev(clrs)) +
      theme_linedraw()
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

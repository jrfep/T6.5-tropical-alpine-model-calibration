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
    prds <- prds[,colSums(prds == 0) < nrow(prds)] 
    valid_cols <- c("T1.3","T2.1", "T3.1","T6.1", "T6.4", "T6.5")
    prds %>% 
      pivot_longer(cols = any_of(valid_cols), names_to = "EFG") %>%
      filter(value>0)
  })
  selectedMapView <- reactive({
    EFG_slc <- filter(EFG_records, GMBA_group %in% input$xreg)
    GMBA_slc <- filter(GMBA, Level_03 %in% input$xreg) %>% 
      dplyr::select(MapName, Elev_High)
    m <- mapview(EFG_slc, zcol = "EFG") +
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
    
    ggplot(data = selectedPred(), 
           aes(x=value,fill=EFG)) + 
      geom_histogram(bins=25) + 
      facet_wrap(~EFG, scales="free") +
      theme_dark()
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

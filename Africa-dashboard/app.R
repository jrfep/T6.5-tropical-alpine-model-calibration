#
# This is a Shiny dashboard. You can run the application by clicking
# the 'Run App' button above.
#

library(shiny)
library(shinydashboard)
library(shinythemes)
library(pins)
require(dplyr)
library(tidyr)
library(ggplot2)
require(sf)
library(mapview)
library(leaflet)
library(stringr)
library(DT)
library(readr)
library(tidyterra)
library(terra)

board <- board_connect()


EFG_records <- board %>% pin_read("jferrer/EFG_records")

GMBA_file <- pin_download(board, "jferrer/GMBA-valid-data")
GMBA <- read_sf(GMBA_file) %>%
  filter(MapUnit %in% "Basic") %>%
  filter(Level_01 %in% "Africa",Level_03 %in% EFG_records$GMBA_group) 

pred_files <- pin_download(board, "jferrer/rf-pred-current-CHELSA/")
map_files <- pin_download(board, "jferrer/rf-spatial-pred-CHELSA/")

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
  header = dashboardHeader(title = "Tropical Alpine / Africa"),
  sidebar = dashboardSidebar(
    sidebarMenu(
      {
        regs <- c("Southern Rift Mountains", "Atlantic Plateau (Brazil)", "Hawaian Islands")
        regs <- GMBA %>% st_drop_geometry() %>% distinct(Level_03) %>% pull
        selectInput('xreg', 'Select the region of interest', regs)},
      menuItem("Overview", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Spatial prediction", tabName = "widgets", icon = icon("th"))
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
                box(dataTableOutput("filteredTable")),
                box(plotOutput("histPlot"))
              )
      ),
      
      # Second tab content
      tabItem(tabName = "widgets",
              h2("Spatial prediction"),
                plotOutput("terraPlot")
      )
    )
  )
)

server <- function(input, output) { 
  
  selectedPred <- reactive({
    pred_file <- grep(sprintf("GMBA_V2_L03-%s-region.csv",
                              str_replace_all(input$xreg,
                                            "[ \\(\\)*\\/]+", "-")),
                      pred_files, 
                      value = TRUE)
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
  
  selectedMapPred <- reactive({
  
    idx <- input$filteredTable_rows_selected

    if (length(idx)>0) {
      map_file <- grep(sprintf("GMBA_V2_L03-%s.tif",
                               str_replace_all(input$xreg,
                                               "[ \\(\\)*\\/]+", "-")),
                       map_files, 
                       value = TRUE)
      spatial_pred <- rast(map_file)
      
      GMBA_slc <- filter(GMBA, Level_03 %in% input$xreg) %>% 
        dplyr::select(MapName, Elev_High) 
      
      mnts_nms <- selectedTable() %>% slice(idx) %>% pull(MapName)
      GMBA_slc <- GMBA_slc %>% filter(MapName %in% mnts_nms)
      rst <- crop(spatial_pred,GMBA_slc) %>% select(-1)
    return(rst)
    }
  })
  
  selectedTable <- reactive({
    GMBA %>% 
      st_drop_geometry() %>% 
      filter(Level_03 %in% input$xreg) %>% 
      transmute(Level_01, Level_02, Level_03, 
                MapName,
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
    DT::datatable(selectedTable() %>% select(-MapName), 
                  rownames = FALSE, 
                  selection = "single",
                  escape = FALSE)
  })
  output$mountainName <- renderText({
    
    idx <- input$filteredTable_rows_selected
    if (length(idx)>0) {
      selectedTable() %>% slice(idx) %>% pull(MapName)
    }
    })
  output$histPlot <- renderPlot({
      ggplot(selectedPred()) + 
      geom_bar(aes(y=prob, x=id, fill=pred_EFG), stat = "identity") +
      scale_fill_manual(values = rev(clrs)) +
      theme_linedraw()
  })
  
  output$terraPlot <- renderPlot({
    idx <- input$filteredTable_rows_selected
    
    if (length(idx)>0) {
      mnt_nms <- selectedTable() %>% slice(idx) %>% pull(MapName)
      
      
      ggplot() +
        geom_spatraster(data = selectedMapPred() ) +
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
          subtitle = paste0(mnt_nms)
        )
      
    }
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

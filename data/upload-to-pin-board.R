library(pins)
here::i_am("data/download-from-osf.R")
board <- board_connect()

pin_upload(board = board, 
           paths = here::here("data","rf-spatial-pred-CHELSA"),
           name = "rf-spatial-pred-CHELSA")

pin_upload(board = board, 
           paths = here::here("data","rf-pred-current-CHELSA"),
           name = "rf-pred-current-CHELSA")

pin_upload(board = board, 
           paths = here::here("data","GMBA_inventory_valid.gpkg"),
           name = "GMBA-valid-data")

EFG_records <- readRDS(here::here("data","EFG-records-GMBA.rds"))
pin_write(board = board,
          x = EFG_records)

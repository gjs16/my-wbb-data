# update_data.R

# 1. Load Required Packages
library(wehoop)
library(dplyr)
library(readr)
library(purrr)
library(stringr)
# Packages for Google Sheets integration
library(googlesheets4)
library(googledrive)

# 2. Configuration
# We still fetch all seasons locally, but only upload 2026 daily
seasons <- c(2024, 2025, 2026) 
current_season <- 2026
data_path <- "./data/"
google_sheet_id <- Sys.getenv("GOOGLE_SHEET_ID") # This is the ID for the CURRENT sheet

# Ensure the output directory exists
if (!dir.exists(data_path)) {
  dir.create(data_path, recursive = TRUE)
}

# --- FUNCTION TO UPLOAD ALL LOCAL CSV/TXT FILES TO A SINGLE GOOGLE SHEET ---
upload_to_sheets <- function(sheet_id, local_path) {
  message("--- Starting Google Sheets Upload ---")
  
  if (file.exists("gcs_auth.json")) {
    gs4_auth(path = "gcs_auth.json")
    message("Google Sheets authenticated via Service Account.")
  } else {
    message("ERROR: gcs_auth.json not found. Sheets upload skipped.")
    return(NULL)
  }

  # List all uncompressed files created in the data_path
  all_files <- list.files(
    path = local_path, 
    pattern = "\\.csv$|\\.txt$", 
    full.names = TRUE
  )
  
  # CRITICAL FILTER: Only upload 2026 data and the schema on daily runs.
  files_to_upload <- all_files %>% 
    str_subset(paste0("_", current_season, "\\.csv$|llm_data_schema\\.txt$"))

  message(paste("Filtered files for daily upload (current season/schema only):", length(files_to_upload)))

  # Check if the target Google Sheet exists and has permissions
  tryCatch({
    drive_get(id = sheet_id)
  }, error = function(e) {
    message(paste("ERROR: Cannot access Google Sheet ID:", sheet_id))
    message("Ensure the Service Account has 'Editor' access to the sheet.")
    return(NULL)
  })

  # Loop through filtered files and upload/overwrite each one to its own tab
  walk(files_to_upload, ~{
    file_name <- basename(.x)
    sheet_name <- str_replace_all(file_name, "\\.csv$|\\.txt$", "") 
    
    message(paste("Uploading/Overwriting Tab:", sheet_name))
    
    if (grepl("\\.txt$", file_name)) {
      data_to_upload <- readLines(.x) %>% as_tibble() %>% rename(Schema_Content = value)
      Sys.sleep(1) # Small pause for the small schema file
    } else {
      # Use read_csv and ensure consistent column names (not strictly needed but good practice)
      data_to_upload <- read_csv(.x, show_col_types = FALSE)
      # FIX: Apply a simpler column name conversion if necessary, though wehoop is usually fine.
      
      # FIX FOR 503 ERROR: Pause before writing large files to prevent API rate limiting
      message("Pausing for 7 seconds to respect Google Sheets API limits...")
      Sys.sleep(7) 
    }
    
    # Overwrite the corresponding tab
    tryCatch({
      sheet_write(data_to_upload, ss = sheet_id, sheet = sheet_name)
      message(paste("SUCCESS: Wrote", file_name, "to tab", sheet_name))
    }, error = function(e) {
      message(paste("ERROR writing to sheet:", sheet_name, e))
    })
  })
}
# --- END UPLOAD FUNCTION ---


# 3. Define the Fetch & Write Function (Uncompressed files for all seasons)
fetch_and_write_data <- function(season, path) {
  message(paste("---

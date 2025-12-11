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
seasons <- c(2024, 2025, 2026)
current_season <- 2026
data_path <- "./data/"
# Reads the Sheet ID securely from the GitHub Actions environment
google_sheet_id <- Sys.getenv("GOOGLE_SHEET_ID") 


# Ensure the output directory exists
if (!dir.exists(data_path)) {
  dir.create(data_path, recursive = TRUE)
}

# --- FUNCTION TO UPLOAD ALL LOCAL CSV/TXT FILES TO A SINGLE GOOGLE SHEET ---
upload_to_sheets <- function(sheet_id, local_path) {
  message("--- Starting Google Sheets Upload ---")
  
  # Authenticate using the service account token provided by GitHub Actions secret
  if (file.exists("gcs_auth.json")) {
    gs4_auth(path = "gcs_auth.json")
    message("Google Sheets authenticated via Service Account.")
  } else {
    message("ERROR: gcs_auth.json not found. Sheets upload skipped.")
    return(NULL)
  }

  # List all uncompressed files created in the data_path
  files_to_upload <- list.files(
    path = local_path, 
    pattern = "\\.csv$|\\.txt$", 
    full.names = TRUE
  )

  # Check if the target Google Sheet exists and has permissions
  tryCatch({
    drive_get(id = sheet_id)
  }, error = function(e) {
    message(paste("ERROR: Cannot access Google Sheet ID:", sheet_id))
    message("Ensure the Service Account has 'Editor' access to the sheet.")
    return(NULL)
  })

  # Loop through files and upload/overwrite each one to its own tab
  walk(files_to_upload, ~{
    file_name <- basename(.x)
    sheet_name <- str_replace_all(file_name, "\\.csv$|\\.txt$", "") 
    
    message(paste("Uploading/Overwriting Tab:", sheet_name))
    
    # Read the data from the local file
    if (grepl("\\.txt$", file_name)) {
      # For the schema file, read line by line and convert to a one-column tibble
      data_to_upload <- readLines(.x) %>% 
        as_tibble() %>% 
        rename(Schema_Content = value)
    } else {
      # For CSVs, read as standard dataframe
      data_to_upload <- read_csv(.x, show_col_types = FALSE)
      
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
fetch_and

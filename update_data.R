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
historic_seasons <- c(2024, 2025)
data_path <- "./data/"

# IDs for the two Google Sheets (Read from GitHub Actions Environment)
google_sheet_id_current <- Sys.getenv("GOOGLE_SHEET_ID_CURRENT") # For 2026 and schema
google_sheet_id_historic <- Sys.getenv("GOOGLE_SHEET_ID_HISTORIC") # For 2024, 2025

# Ensure the output directory exists
if (!dir.exists(data_path)) {
  dir.create(data_path, recursive = TRUE)
}

# --- AUTHENTICATION CHECK ---
auth_sheets <- function() {
  if (file.exists("gcs_auth.json")) {
    gs4_auth(path = "gcs_auth.json")
    message("Google Sheets authenticated via Service Account.")
    return(TRUE)
  } else {
    message("ERROR: gcs_auth.json not found. Sheets upload skipped.")
    return(FALSE)
  }
}

# --- FUNCTION TO UPLOAD DAILY DATA (CURRENT SEASON + SCHEMA) ---
upload_current_data <- function(sheet_id, local_path) {
  message(paste("--- Starting Daily Upload to CURRENT Sheet ID:", sheet_id, "---"))
  
  if (!auth_sheets()) return(NULL)
  
  # List all files, keeping only current season data AND the schema file
  all_files <- list.files(
    path = local_path, 
    pattern = "\\.csv$|\\.txt$", 
    full.names = TRUE
  )
  
  # Filter for the current season files and the schema file
  files_to_upload <- all_files %>% 
    str_subset(paste0("_", current_season, "\\.csv$|llm_data_schema\\.txt$"))

  message(paste("Filtered files for daily upload:", length(files_to_upload)))

  # Loop through filtered files and upload/overwrite each one to its own tab
  walk(files_to_upload, ~{
    file_name <- basename(.x)
    sheet_name <- str_replace_all(file_name, "\\.csv$|\\.txt$", "")
    
    message(paste("Uploading/Overwriting Tab:", sheet_name))
    
    if (grepl("\\.txt$", file_name)) {
      data_to_upload <- readLines(.x) %>% as_tibble() %>% rename(Schema_Content = value)
      Sys.sleep(1) 
    } else {
      data_to_upload <- read_csv(.x, show_col_types = FALSE)
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
# --- END CURRENT UPLOAD FUNCTION ---

# --- FUNCTION TO UPLOAD HISTORIC DATA (MANUAL/INFREQUENT USE ONLY) ---
upload_historic_data <- function(sheet_id, local_path, seasons_list) {
  message(paste("--- Starting HISTORIC Upload to HISTORIC Sheet ID:", sheet_id, "---"))
  
  if (!auth_sheets()) return(NULL)
  
  # Filter to ONLY historic data (2024, 2025)
  historic_files <- list.files(
    path = local_path,
    pattern = paste0("(", paste(seasons_list, collapse = "|"), ")", "\\.csv$"),
    full.names = TRUE
  )
  
  message(paste("Files for HISTORIC upload:", length(historic_files)))
  
  # Loop through files and upload to the historic sheet
  walk(historic_files, ~{
    file_name <- basename(.x)
    sheet_name <- str_replace_all(file_name, "\\.csv$", "")
    message(paste("Uploading/Overwriting Historic Tab:", sheet_name))
    
    data_to_upload <- read_csv(.x, show_col_types = FALSE)
    Sys.sleep(7) # Respect API limits
    
    tryCatch({
      sheet_write(data_to_upload, ss = sheet_id, sheet = sheet_name)
      message(paste("SUCCESS: Wrote", file_name, "to historic tab", sheet_name))
    }, error = function(e) {
      message(paste("ERROR writing to sheet:", sheet_name, e))
    })
  })
}
# --- END HISTORIC UPLOAD FUNCTION ---


# 3. Define the Fetch & Write Function (Uncompressed files for all seasons)
fetch_and_write_data <- function(season, path) {
  message(paste("--- Fetching data for season:", season, "---"))
  
  # FIX: Corrected function name from espn_wbb_schedule to load_wbb_schedule
  wbb_pbp <- wehoop::load_wbb_pbp(season = season)
  wbb_schedule <- wehoop::load_wbb_schedule(season = season) 
  wbb_team_box <- wehoop::espn_wbb_team_box_score(season = season)
  wbb_player_box <- wehoop::espn_wbb_player_box_score(season = season)
  
  # Define list of data frames to save
  data_list <- list(
    wbb_pbp

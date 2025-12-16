# update_data.R (Temporary Script to Upload Historic Data - Final Fix)

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
  
  all_files <- list.files(
    path = local_path, 
    pattern = "\\.csv$|\\.txt$", 
    full.names = TRUE
  )
  
  files_to_upload <- all_files %>% 
    str_subset(paste0("_", current_season, "\\.csv$|llm_data_schema\\.txt$"))

  message(paste("Filtered files for daily upload:", length(files_to_upload)))

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
    
    tryCatch({
      sheet_write(data_to_upload, ss = sheet_id, sheet = sheet_name)
      message(paste("SUCCESS: Wrote", file_name, "to tab", sheet_name))
    }, error = function(e) {
      message(paste("ERROR writing to current sheet:", sheet_name, e))
    })
  })
}
# --- END CURRENT UPLOAD FUNCTION ---

# --- FUNCTION TO UPLOAD HISTORIC DATA (MANUAL/INFREQUENT USE ONLY) ---
upload_historic_data <- function(sheet_id, local_path, seasons_list) {
  message(paste("--- Starting HISTORIC Upload to HISTORIC Sheet ID:", sheet_id, "---"))
  
  if (!auth_sheets()) return(NULL)
  
  historic_files <- list.files(
    path = local_path,
    pattern = paste0("(", paste(seasons_list, collapse = "|"), ")", "\\.csv$"),
    full.names = TRUE
  )
  
  message(paste("Files for HISTORIC upload:", length(historic_files)))
  
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
      message(paste("ERROR writing to historic sheet:", sheet_name, e))
    })
  })
}
# --- END HISTORIC UPLOAD FUNCTION ---


# 3. Define the Fetch & Write Function (Uncompressed files for all seasons)
fetch_and_write_data <- function(season, path) {
  message(paste("--- Fetching data for season:", season, "---"))
  
  # API Robustness Fix: Increased timeout
  wbb_pbp <- wehoop::load_wbb_pbp(season = season, timeout = 600)
  wbb_schedule <- wehoop::load_wbb_schedule(season = season) 
  
  # FIX: Corrected function names for team and player box scores
  wbb_team_box <- wehoop::load_wbb_team_box(season = season) 
  wbb_player_box <- wehoop::load_wbb_player_box(season = season)
  
  data_list <- list(
    wbb_pbp = wbb_pbp,
    wbb_schedule = wbb_schedule,
    wbb_team_box = wbb_team_box,
    wbb_player_box = wbb_player_box
  )
  
  if (nrow(wbb_schedule) == 0 && season >= current_season) {
    stop("CRITICAL FAILURE: Schedule data missing for current season. Halting process.")
  }

  walk(names(data_list), function(name) {
    df <- data_list[[name]]
    file_name <- paste0(path, name, "_", season, ".csv")
    
    if (nrow(df) > 0) {
      message(paste("Writing", name, "to:", file_name))
      write_csv(df, file_name)
    } else {
      message(paste("Skipping write for", name, "in season", season, ": Data frame is empty."))
    }
  })
}

# 4. Main Execution

# A. Fetch all required data locally
walk(seasons, ~fetch_and_write_data(season = .x, path = data_path))

# B. Create and save the data schema file (CRITICAL CONTEXT FOR LLM)
schema_file <- paste0(data_path, "llm_data_schema.txt")
schema_content <- c(
  "Data Schema Definitions:",
  "wbb_pbp: Play-by-play data, includes detailed events for every game.",
  "wbb_schedule: Game-level schedule information (teams, scores, links).",
  "wbb_team_box: Team-level box scores (stats summaries by team per game).",
  "wbb_player_box: Player-level box scores (stats summaries by player per game).",
  "",
  "LLM ACCESS NOTE:",
  "1. ALWAYS check the 'NCAA WBB Current Stats' sheet for 2026 data and the schema.",
  "2. ALWAYS check the 'NCAA WBB Historic Stats' sheet for 2024 and 2025 data."
)
writeLines(schema_content, schema_file)
message(paste("Wrote schema to:", schema_file))

# C. Upload the filtered data (current season and schema) to the CURRENT Google Sheet
if (!is.null(google_sheet_id_current) && google_sheet_id_current != "") {
  upload_current_data(google_sheet_id_current, data_path)
} else {
  message("WARNING: GOOGLE_SHEET_ID_CURRENT environment variable is not set. Current Sheets upload skipped.")
}

# D. OPTIONAL/MANUAL: Upload the HISTORIC data to the HISTORIC Google Sheet.
#    ***THIS BLOCK IS UNCOMMENTED FOR THIS SINGLE RUN ONLY***
if (!is.null(google_sheet_id_historic) && google_sheet_id_historic != "") {
  upload_historic_data(google_sheet_id_historic, data_path, historic_seasons)
} else {
  message("WARNING: GOOGLE_SHEET_ID_HISTORIC environment variable is not set. Historic Sheets upload skipped.")
}

message("--- Data update process completed successfully ---")

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
  message(paste("--- Fetching data for season:", season, "---"))
  
  # Fetch data using wehoop functions
  wbb_pbp <- wehoop::load_wbb_pbp(season = season)
  wbb_schedule <- wehoop::espn_wbb_schedule(season = season)
  wbb_team_box <- wehoop::espn_wbb_team_box_score(season = season)
  wbb_player_box <- wehoop::espn_wbb_player_box_score(season = season)
  
  # Define list of data frames to save
  data_list <- list(
    wbb_pbp = wbb_pbp,
    wbb_schedule = wbb_schedule,
    wbb_team_box = wbb_team_box,
    wbb_player_box = wbb_player_box
  )
  
  # Loop through and write each data frame to a CSV
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
} # <--- **MISSING CLOSING BRACE WAS HERE**

# 4. Main Execution

# A. Fetch all required data locally
walk(seasons, ~fetch_and_write_data(season = .x, path = data_path))

# B. Create and save the data schema file (only needs to be done once, but harmless to run daily)
schema_file <- paste0(data_path, "llm_data_schema.txt")
schema_content <- c(
  "Data Schema Definitions:",
  "wbb_pbp: Play-by-play data, includes detailed events for every game.",
  "wbb_schedule: Game-level schedule information (teams, scores, links).",
  "wbb_team_box: Team-level box scores (stats summaries by team per game).",
  "wbb_player_box: Player-level box scores (stats summaries by player per game)."
)
writeLines(schema_content, schema_file)
message(paste("Wrote schema to:", schema_file))

# C. Upload the filtered data (current season and schema) to Google Sheets
if (!is.null(google_sheet_id) && google_sheet_id != "") {
  upload_to_sheets(google_sheet_id, data_path)
} else {
  message("WARNING: GOOGLE_SHEET_ID environment variable is not set. Sheets upload skipped.")
}

message("--- Data update process completed successfully ---")

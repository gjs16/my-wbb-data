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
  # The token file is expected to be saved by the GitHub Action steps
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
    # The tab name is the filename without the extension (e.g., 'national_wbb_schedule_2026')
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


# 3. Define the Fetch & Write Function (UPDATED: NO .gz, NO current_season filter)
fetch_and_write_data <- function(season, path) {
  message(paste("--- Processing Season:", season, "---"))
  
  # --- A. SCHEDULE & RESULTS ---
  tryCatch({
    message("Fetching Schedule...")
    df_schedule <- load_wbb_schedule(season = season)
    if (!is.null(df_schedule) && nrow(df_schedule) > 0) {
      # SAVE UNCOMPRESSED FOR ALL SEASONS
      write_csv(df_schedule, file = paste0(path, "national_wbb_schedule_", season, ".csv"))
    }
  }, error = function(e) { message(paste("Error fetching schedule:", e)) })

  # --- B. TEAM BOX SCORES ---
  tryCatch({
    message("Fetching Team Box Scores...")
    df_team <- load_wbb_team_box(season = season)
    if (!is.null(df_team) && nrow(df_team) > 0) {
      # SAVE UNCOMPRESSED FOR ALL SEASONS
      write_csv(df_team, file = paste0(path, "national_wbb_team_box_", season, ".csv"))
    }
  }, error = function(e) { message(paste("Error fetching team box:", e)) })

  # --- C. PLAYER BOX SCORES ---
  tryCatch({
    message("Fetching Player Box Scores...")
    df_player <- load_wbb_player_box(season = season)
    if (!is.null(df_player) && nrow(df_player) > 0) {
      # SAVE UNCOMPRESSED FOR ALL SEASONS
      write_csv(df_player, file = paste0(path, "national_wbb_player_box_", season, ".csv"))
    }
  }, error = function(e) { message(paste("Error fetching player box:", e)) })
  
  gc()
}

# 4. Execute the Loop
walk(seasons, fetch_and_write_data, path = data_path)

# 5. SPECIAL: Create Arkansas-Specific Files
message("--- Creating Arkansas Specific Files ---")
ark_national_file <- paste0(data_path, "national_wbb_player_box_", current_season, ".csv")

tryCatch({
  if (file.exists(ark_national_file)) {
    # Read the full file we just downloaded (now uncompressed)
    full_data <- read_csv(ark_national_file, show_col_types = FALSE)
    
    # Filter for Arkansas
    ark_data <- full_data %>% 
      filter(team_short_display_name == "Arkansas" | team_name == "Arkansas")
    
    # Save Uncompressed 
    write_csv(ark_data, file = paste0(data_path, "arkansas_wbb_player_box_", current_season, ".csv"))
    message("Successfully saved Arkansas player data.")
  }
}, error = function(e) { message(paste("Error creating Arkansas subset:", e)) })

# 6. CRUCIAL: Generate Schema/Context File
message("--- Generating LLM Schema Anchor ---")

schema_text <- c(
  "# DATA SCHEMA AND CONTEXT FOR WBB BOX SCORES",
  paste("Updated on:", Sys.Date()),
  "",
  "## General Context",
  "* **Seasons Included:** 2024, 2025, 2026",
  "* **Primary Team:** Arkansas Razorbacks",
  "* **Data Source:** wehoop (NCAA functionality)",
  "* **Google Sheet ID:** 1QNTkUqUm-gXwhqLKoOtj3x8fdw-aV06InXtP4VoGaTI",
  "* **Google Sheet Tab Name:** llm_data_schema",
  "",
  "## Key Columns Dictionary",
  "* **team_display_name / team_name:** The school name.",
  "* **athlete_display_name:** The player's name.",
  "* **minutes:** Minutes played.",
  "* **points:** Total points scored.",
  "* **rebounds:** Total rebounds.",
  "* **assists:** Total assists.",
  "* **field_goal_pct:** FG% (0.0 to 1.0).",
  "* **three_point_field_goal_pct:** 3PT% (0.0 to 1.0).",
  "",
  "## File/Tab Guide",
  "* **national_wbb_player_box_2026:** Best for current national player analysis.",
  "* **arkansas_wbb_player_box_2026:** Best for current Arkansas player analysis.",
  "* **national_wbb_team_box_2026:** Best for schedule results and team comparisons.",
  "* **Note:** Historic 2024 and 2025 files are available on their own tabs for trending."
)

writeLines(schema_text, paste0(data_path, "llm_data_schema.txt"))

message("--- Local Data Refresh Complete ---")

# 7. CRUCIAL: UPLOAD TO GOOGLE SHEETS
upload_to_sheets(google_sheet_id, data_path)

message("--- Daily Update Process Complete ---")

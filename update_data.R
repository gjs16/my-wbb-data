# update_data.R (Final Permanent Script - Single Sheet, Cell Limit Proof)

# 1. Load Required Packages
library(wehoop)
library(dplyr)
library(readr)
library(purrr)
library(stringr)
library(lubridate) # Needed for data type conversion fix
# Packages for Google Sheets integration
library(googlesheets4)
library(googledrive)

# 2. Configuration
seasons <- c(2024, 2025, 2026)
current_season <- 2026
data_path <- "./data/"

# CRITICAL: Use only ONE Sheet ID for the consolidated analysis hub
google_sheet_id <- Sys.getenv("GOOGLE_SHEET_ID") 

# CRITICAL EXCLUSION LIST: Files too large for Google Sheets (10M cell limit)
EXCLUDE_PREFIXES <- c("wbb_pbp") 

# Ensure the output directory exists
if (!dir.exists(data_path)) {
  dir.create(data_path, recursive = TRUE)
}

# --- DATA CLEANUP AND CONVERSION FUNCTION (FIXING hms/difftime ERROR) ---
clean_data_for_sheets <- function(df) {
  df <- df %>%
    # FIX: Convert hms/difftime columns (common in schedule/pbp) to characters
    mutate(across(where(inherits, what = "hms"), as.character)) %>%
    mutate(across(where(inherits, what = "difftime"), as.character)) 
  return(df)
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

# --- FUNCTION TO UPLOAD ALL FILTERED DATA TO ONE SHEET ---
upload_to_sheets <- function(sheet_id, local_path, current_season_only = FALSE) {
  message(paste("--- Starting Google Sheets Upload to Sheet ID:", sheet_id, "---"))
  
  if (!auth_sheets()) return(NULL)
  
  all_files <- list.files(
    path = local_path, 
    pattern = "\\.csv$|\\.txt$", 
    full.names = TRUE
  )
  
  files_to_upload <- all_files %>% 
    # 1. Filter out the massive, excluded files (like wbb_pbp)
    str_subset(paste0("(", paste(EXCLUDE_PREFIXES, collapse = "|"), ")"), negate = TRUE) %>%
    # 2. Keep only current season data if running daily, otherwise keep all seasons
    {if (current_season_only) str_subset(., paste0("_", current_season, "\\.csv$|llm_data_schema\\.txt$|llm_grounding\\.txt$")) else .}

  message(paste("Filtered files for upload:", length(files_to_upload)))

  walk(files_to_upload, ~{
    file_name <- basename(.x)
    
    # RENAME TABS for LLM simplicity: remove 'wbb_' prefix if it exists
    sheet_name <- str_replace_all(file_name, "wbb_", "") %>%
                  str_replace_all(., "\\.csv$|\\.txt$", "")
    
    message(paste("Uploading/Overwriting Tab:", sheet_name))
    
    if (grepl("\\.txt$", file_name)) {
      data_to_upload <- readLines(.x) %>% as_tibble() %>% rename(Schema_Content = value)
      Sys.sleep(1) 
    } else {
      # Read CSV and clean data types before upload
      data_to_upload <- read_csv(.x, show_col_types = FALSE) %>% clean_data_for_sheets()
      message("Pausing for 7 seconds to respect Google Sheets API limits...")
      Sys.sleep(7) 
    }
    
    tryCatch({
      sheet_write(data_to_upload, ss = sheet_id, sheet = sheet_name)
      message(paste("SUCCESS: Wrote", file_name, "to tab", sheet_name))
    }, error = function(e) {
      message(paste("FATAL ERROR writing to sheet:", sheet_name, e))
    })
  })
}
# --- END UPLOAD FUNCTION ---


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
  
  # Fail-safe check
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

# B. Create and save the data schema and grounding files
schema_file <- paste0(data_path, "llm_data_schema.txt")
schema_content <- c(
  "Data Schema Definitions:",
  "schedule_YYYY: Game-level schedule information (teams, scores, links).",
  "team_box_YYYY: Team-level box scores (stats summaries by team per game).",
  "player_box_YYYY: Player-level box scores (stats summaries by player per game).",
  "NOTE: Play-by-play (wbb_pbp) data is TOO large for Sheets; check the GitHub repository for raw CSV files.",
  "",
  "LLM ACCESS NOTE: ALL core analysis data for 2024, 2025, and 2026 is consolidated in this ONE sheet (NCAA WBB Stats).",
  "Review the 'llm_grounding' tab first for strategic advice."
)
writeLines(schema_content, schema_file)
message(paste("Wrote schema to:", schema_file))


# --- New LLM Grounding File ---
grounding_file <- paste0(data_path, "llm_grounding.txt")
grounding_content <- c(
  "# LLM PROJECT GOAL AND ANALYSIS GUIDE",
  "## Project Goal",
  "To enable fast, cross-seasonal analysis of NCAA Women's Basketball statistics to identify trends, performance shifts, and opportunities for arbitrage in betting markets (where permitted) or advanced scouting.",
  "",
  "## Data Layer Strategy (Read Before Analyzing)",
  "1. **Primary Layer (Google Sheet):** Contains all tables needed for 95% of queries (YoY comparison, calculating team averages, finding top players). All tabs are named clearly (e.g., 'player_box_2026').",
  "2. **Deep Dive Layer (GitHub/Drive):** Contains the highly granular, massive Play-by-Play files ('wbb_pbp_YYYY.csv'). These files are intentionally EXCLUDED from this Google Sheet to avoid the 10 million cell limit.",
  "",
  "## Query Handling Rules",
  "* **A. Cross-Analysis:** Queries involving multiple seasons (e.g., '2024 vs 2026') MUST reference the appropriate tabs (e.g., 'player_box_2024' and 'player_box_2026') within this SINGLE sheet.",
  "* **B. Quick Queries (In-Sheet):** Use standard sheet analysis for calculating averages, totals, and finding leaders in the 'player_box' and 'team_box' tables.",
  "* **C. Deep Dive Queries (External CSV):** If the query asks for **quarter/minute specific data** or **event-level granularity** (e.g., 'shots taken under 5 seconds', 'turnovers in the 3rd quarter'), the LLM MUST request access to the external 'wbb_pbp_YYYY.csv' files from the linked GitHub repository/Drive and process them separately. Do not attempt PBP analysis on the sheet data."
)
writeLines(grounding_content, grounding_file)
message(paste("Wrote LLM Grounding document to:", grounding_file))
# -----------------------------


# C. Upload the ALL filtered data (All seasons + schema + grounding) to the SINGLE Google Sheet
if (!is.null(google_sheet_id) && google_sheet_id != "") {
  # Perform a full initial sync (current_season_only = FALSE)
  upload_to_sheets(google_sheet_id, data_path, current_season_only = FALSE) 
} else {
  message("WARNING: GOOGLE_SHEET_ID environment variable is not set. Sheets upload skipped.")
}

message("--- Data update process completed successfully ---")

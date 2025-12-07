# update_data.R

# 1. Load Required Packages
library(wehoop)
library(dplyr)
library(readr)
library(purrr)
library(stringr)

# 2. Configuration
seasons <- c(2024, 2025, 2026) 
current_season <- 2026
data_path <- "./data/" 

# Ensure the output directory exists
if (!dir.exists(data_path)) {
  dir.create(data_path, recursive = TRUE)
}

# 3. Define the Fetch & Write Function
fetch_and_write_data <- function(season, path) {
  message(paste("--- Processing Season:", season, "---"))
  
  # --- A. SCHEDULE & RESULTS ---
  tryCatch({
    message("Fetching Schedule...")
    df_schedule <- load_wbb_schedule(season = season)
    
    if (!is.null(df_schedule) && nrow(df_schedule) > 0) {
      # Save Compressed
      write_csv(df_schedule, file = paste0(path, "national_wbb_schedule_", season, ".csv.gz"))
      
      # Save Uncompressed (Current Season Only)
      if (season == current_season) {
        write_csv(df_schedule, file = paste0(path, "national_wbb_schedule_", season, ".csv"))
      }
    }
  }, error = function(e) { message(paste("Error fetching schedule:", e)) })

  # --- B. TEAM BOX SCORES ---
  tryCatch({
    message("Fetching Team Box Scores...")
    df_team <- load_wbb_team_box(season = season)
    
    if (!is.null(df_team) && nrow(df_team) > 0) {
      write_csv(df_team, file = paste0(path, "national_wbb_team_box_", season, ".csv.gz"))
      
      if (season == current_season) {
        write_csv(df_team, file = paste0(path, "national_wbb_team_box_", season, ".csv"))
      }
    }
  }, error = function(e) { message(paste("Error fetching team box:", e)) })

  # --- C. PLAYER BOX SCORES ---
  tryCatch({
    message("Fetching Player Box Scores...")
    df_player <- load_wbb_player_box(season = season)
    
    if (!is.null(df_player) && nrow(df_player) > 0) {
      write_csv(df_player, file = paste0(path, "national_wbb_player_box_", season, ".csv.gz"))
      
      if (season == current_season) {
        write_csv(df_player, file = paste0(path, "national_wbb_player_box_", season, ".csv"))
      }
    }
  }, error = function(e) { message(paste("Error fetching player box:", e)) })
  
  # Clean up memory
  gc()
} # <--- End of fetch_and_write_data function

# 4. Execute the Loop
walk(seasons, fetch_and_write_data, path = data_path)

# 5. SPECIAL: Create Arkansas-Specific Files
message("--- Creating Arkansas Specific Files ---")
tryCatch({
  ark_file_path <- paste0(data_path, "national_wbb_player_box_", current_season, ".csv.gz")
  
  if (file.exists(ark_file_path)) {
    # Read the full file we just downloaded
    full_data <- read_csv(ark_file_path, show_col_types = FALSE)
    
    # Filter for Arkansas
    ark_data <- full_data %>% 
      filter(team_short_display_name == "Arkansas" | team_name == "Arkansas")
    
    # Save Uncompressed for LLM
    write_csv(ark_data, file = paste0(data_path, "arkansas_wbb_player_box_", current_season, ".csv"))
    message("Successfully saved Arkansas player data.")
  }
}, error = function(e) { message(paste("Error creating Arkansas subset:", e)) })

# 6. CRUCIAL: Generate Schema/Context File
message("--- Generating LLM Schema Anchor ---")

schema_text <- c(
  "# DATA SCHEMA AND CONTEXT FOR 2026 WBB BOX SCORES",
  paste("Updated on:", Sys.Date()),
  "",
  "## General Context",
  "* **Season:** 2025-2026 (labeled '2026')",
  "* **Primary Team:** Arkansas Razorbacks",
  "* **Data Source:** wehoop (NCAA functionality)",
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
  "## File Guide",
  "* **arkansas_wbb_player_box_2026.csv:** Use for detailed player stats for Arkansas.",
  "* **national_wbb_team_box_2026.csv:** Use for schedule results, win/loss records, and opponent comparison."
)

writeLines(schema_text, paste0(data_path, "llm_data_schema.txt"))

message("--- Daily Update Complete ---")

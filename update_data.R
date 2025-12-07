# update_data.R: Optimized for LLM Accessibility and Stability

# 1. Load Required Packages
library(wehoop)
library(dplyr)
library(readr)
library(purrr)
library(stringr)

# 2. Configuration
# Seasons to fetch (2024 and 2025 for context, 2026 for current season)
seasons <- c(2024, 2025, 2026) 
current_season <- 2026
# Define the output path relative to the script location
data_path <- "./data/" 

# --- Ensure the 'data' directory exists ---
if (!dir.exists(data_path)) {
  dir.create(data_path)
}

# 3. Define Core Data Fetching Function (Modified for LLM Access)
fetch_and_write_data <- function(season, data_path) {
    message(paste("Starting data fetch for season:", season))
    
    # -----------------------------------------------------------------------
    # 3.1 Fetch and Write NATIONAL SCHEDULE/RESULTS
    # -----------------------------------------------------------------------
    message(paste("Fetching schedule for", season))
    schedule_data <- load_wbb_schedule(season = season)
    
    # Save Compressed (.csv.gz) - Efficient storage
    write_csv(
        schedule_data, 
        file = paste0(data_path, "national_wbb_schedule_", season, ".csv.gz")
    )
    
    # Save Uncompressed (.csv) ONLY for the current season (LLM Access)
    if (season == current_season) {
        write_csv(
            schedule_data, 
            file = paste0(data_path, "national_wbb_schedule_", season, ".csv")
        )
    }

    # -----------------------------------------------------------------------
    # 3.2 Fetch and Write NATIONAL TEAM BOX SCORES
    # -----------------------------------------------------------------------
    message(paste("Fetching team box scores for", season))
    team_box_data <- load_wbb_team_box(season = season)
    
    # Save Compressed (.csv.gz)
    write_csv(
        team_box_data, 
        file = paste0(data_path, "national_wbb_team_box_", season, ".csv.gz")
    )
    
    # Save Uncompressed (.csv) ONLY for the current season (LLM Access)
    if (season == current_season) {
        write_csv(
            team_box_data, 
            file = paste0(data_path, "national_wbb_team_box_", season, ".csv")
        )
    }

    # -----------------------------------------------------------------------
    # 3.3 Fetch and Write NATIONAL PLAYER BOX SCORES
    # -----------------------------------------------------------------------
    message(paste("Fetching player box scores for", season))
    player_box_data <- load_wbb_player_box(season = season)
    
    # Save Compressed (.csv.gz)
    write_csv(
        player_box_data, 
        file = paste0(data_path, "national_wbb_player_box_", season, ".csv.gz")
    )
    
    # Save Uncompressed (.csv) ONLY for the current season (LLM Access)
    if (season == current_season) {
        write_csv(
            player_box_data, 
            file = paste0(data_path, "national_wbb_player_box_", season, ".csv")
        )
    }
    
    # Optional: Clean up memory after large fetches
    rm(schedule_data, team_box_data, player_box_data)
    gc()
    message(paste("Finished data fetch for season:", season))
}

# 4. Execute the update for all seasons
walk(seasons, fetch_and_write_data, data_path = data_path)

# 5. BONUS: Create Optimized Arkansas Files for 2026
# This creates specific, smaller files for focused analysis.

# Fetch 2026 player box for filtering
ark_pbox <- load_wbb_player_box(season = current_season) %>% 
    filter(team_name == "Arkansas")
    
# Save Compressed Arkansas Player Box
write_csv(
    ark_pbox, 
    file = paste0(data_path, "arkansas_wbb_player_box_", current_season, ".csv.gz")
)

# Save Uncompressed Arkansas Player Box (OPTIMIZED LLM CRUNCHING)
write_csv(
    ark_pbox, 
    file = paste0(data_path, "arkansas_wbb_player_box_", current_season, ".csv")
)

# 6. CRUCIAL: Generate LLM Stability & Schema Anchor File
# This file provides a reliable column dictionary to prevent LLM hallucinations.

schema_content <- c(
  "# DATA SCHEMA AND CONTEXT FOR 2025-2026 WBB BOX SCORES",
  "This schema is a stable reference for the 'national_wbb_team_box_2026.csv' and 'arkansas_wbb_player_box_2026.csv' files.",
  "",
  "## General Context",
  "* **Season Reference:** The data refers to the 2025-2026 season, labeled '2026'.",
  "* **Team Identifier:** The team you are focused on is 'Arkansas'.",
  "* **Unique Game ID:** The primary key for all joining is the 'game_id' column.",
  "",
  "## Key Columns Dictionary (Team Box Scores)",
  "Use these exact column names when calculating team stats:",
  "* **team_name:** Name of the team.",
  "* **opponent_name:** Name of the opponent team.",
  "* **total_points:** Final score of the team (for W/L check).",
  "* **opponent_total_points:** Final score of the opponent.",
  "* **fg_pct:** Field Goal Percentage (as a decimal).",
  "* **trb:** Total Rebounds (The column is typically 'trb', not 'total_rebounds').",
  "* **tov:** Turnovers committed.",
  "",
  "## Key Columns Dictionary (Player Box Scores)",
  "Use these exact column names when analyzing individual player stats:",
  "* **player_name:** Name of the individual player.",
  "* **min:** Minutes played.",
  "* **pts:** Points scored.",
  "* **trb:** Total Rebounds.",
  "* **ast:** Assists.",
  "* **fg_pct:** Field Goal Percentage (as a decimal, for the player)."
)

writeLines(
    schema_content, 
    con = paste0(data_path, current_season, "_wbb_data_schema.txt")
)

message(paste("Successfully generated all data files and the LLM Schema Anchor for", current_season))

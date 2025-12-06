# update_data.R (Recommended Replacement)

# 1. Load Required Packages
library(wehoop)
library(dplyr)
library(readr)
library(purrr)

# 2. Configuration
# Seasons to fetch (2024 and 2025 for context, 2026 for current season)
seasons <- c(2024, 2025, 2026) 
# Define the output path relative to the script location
data_path <- "./data/" 

# 3. Define Core Data Fetching Function
# This function handles all three data types for a given season
fetch_and_write_data <- function(season, data_path) {
    message(paste("Starting data fetch for season:", season))

    # --- Fetch and Write NATIONAL SCHEDULE/RESULTS ---
    message(paste("Fetching schedule for", season))
    schedule_data <- load_wbb_schedule(season = season)
    write_csv(
        schedule_data, 
        file = paste0(data_path, "national_wbb_schedule_", season, ".csv.gz")
    )

    # --- Fetch and Write NATIONAL TEAM BOX SCORES ---
    # This is the PRIMARY source for W/L record and team metrics (PPG, FG%, etc.)
    message(paste("Fetching team box scores for", season))
    team_box_data <- load_wbb_team_box(season = season)
    write_csv(
        team_box_data, 
        file = paste0(data_path, "national_wbb_team_box_", season, ".csv.gz")
    )

    # --- Fetch and Write NATIONAL PLAYER BOX SCORES ---
    # This is the PRIMARY source for player stats (scoring leaders, minutes)
    message(paste("Fetching player box scores for", season))
    player_box_data <- load_wbb_player_box(season = season)
    write_csv(
        player_box_data, 
        file = paste0(data_path, "national_wbb_player_box_", season, ".csv.gz")
    )
    
    # Optional: Clean up memory after large fetches
    rm(schedule_data, team_box_data, player_box_data)
    gc()
    message(paste("Finished data fetch for season:", season))
}

# 4. Execute the update for all seasons
walk(seasons, fetch_and_write_data, data_path = data_path)

# 5. BONUS: Add Arkansas-Specific File for Faster Querying
# While not strictly necessary, having one small file for Arkansas's current season can speed up analysis.
ark_pbox <- load_wbb_player_box(season = 2026) %>% 
    filter(team_name == "Arkansas")
write_csv(ark_pbox, file = paste0(data_path, "arkansas_wbb_player_box_2026.csv.gz"))

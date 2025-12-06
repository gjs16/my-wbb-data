# Load necessary libraries (must be installed in your GitHub Action workflow)
library(wehoop)
library(dplyr)
library(readr)
library(stringr)

# --- Configuration ---
TEAM_NAME_FILTER <- "Arkansas" 
PBP_SEASONS <- c(2025, 2026) # PBP for current/prior season
AGGREGATE_SEASONS <- c(2024, 2025, 2026) # Aggregated stats for past three seasons
# WNBA_SEASONS <- c(2025) # REMOVED: WNBA PBP removed to comply with 100MB limit


# --- WNBA Data Refresh (PBP) ---
# This section is now skipped to keep the repository small for Gemini integration.
# cat("Refreshing WNBA PBP data...\n")
# for (season in WNBA_SEASONS) {
#   wnba_pbp <- load_wnba_pbp(season)
#   filename <- sprintf("data/wnba_pbp_%d.csv.gz", season)
#   write_csv(wnba_pbp, filename) 
#   cat(sprintf("Saved WNBA PBP data for %d to %s\n", season, filename))
# }


# --- NCAA WBB DATA PULLS ---

# 1. PBP Data Filtering (Arkansas-Specific PBP)
for (season in PBP_SEASONS) {
  cat(sprintf("\nProcessing NCAA WBB PBP data for season: %d\n", season))

  # Fetch the full PBP data from wehoop (Required for filtering)
  full_pbp_data <- load_wbb_pbp(season)

  # 3. Filter for Arkansas games
  # FINAL FIX: Using 'home_team_name' and 'away_team_name' with str_detect for robust filtering.
  arkansas_game_ids <- full_pbp_data %>%
    filter(str_detect(home_team_name, TEAM_NAME_FILTER) | str_detect(away_team_name, TEAM_NAME_FILTER)) %>%
    pull(game_id) %>%
    unique()

  # Filter the PBP data to include only those games
  arkansas_pbp_data <- full_pbp_data %>%
    filter(game_id %in% arkansas_game_ids)

  # 4. Save the Arkansas-specific PBP data (small file)
  arkansas_output_filename <- sprintf("data/arkansas_wbb_pbp_%d.csv.gz", season)
  cat(sprintf("Saving filtered Arkansas PBP data (%d rows) to: %s\n", 
              nrow(arkansas_pbp_data), arkansas_output_filename))
  write_csv(arkansas_pbp_data, arkansas_output_filename) 
}

# 2. National Aggregate Data (NEW REQUEST - Small Files)
for (season in AGGREGATE_SEASONS) {
  cat(sprintf("\nRefreshing National Aggregate Stats for season: %d\n", season))
  
  # Pull 2a: Team Statistics (Aggregated Box Scores)
  team_box <- load_wbb_team_box(season)
  team_filename <- sprintf("data/national_wbb_team_box_%d.csv.gz", season)
  write_csv(team_box, team_filename)
  cat(sprintf("Saved National Team Box Score (%d rows) to: %s\n", nrow(team_box), team_filename))
  
  # Pull 2b: Player Statistics (Aggregated Box Scores)
  player_box <- load_wbb_player_box(season)
  player_filename <- sprintf("data/national_wbb_player_box_%d.csv.gz", season)
  write_csv(player_box, player_filename)
  cat(sprintf("Saved National Player Box Score (%d rows) to: %s\n", nrow(player_box), player_filename))
  
  # Pull 2c: Game Schedules/Results (Individual Game Summary)
  schedule_data <- load_wbb_schedule(season)
  schedule_filename <- sprintf("data/national_wbb_schedule_%d.csv.gz", season)
  write_csv(schedule_data, schedule_filename)
  cat(sprintf("Saved National Schedule/Results (%d rows) to: %s\n", nrow(schedule_data), schedule_filename))
}

cat("\nAll data processing and filtering complete. All files are ready for Gemini integration.\n")

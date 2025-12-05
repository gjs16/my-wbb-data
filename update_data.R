# Load necessary libraries (must be installed in your GitHub Action workflow)
library(wehoop)
library(dplyr)
library(readr)
library(stringr)

# --- Configuration ---
TEAM_NAME <- "Arkansas"
NCAA_SEASONS <- c(2025, 2026)
WNBA_SEASONS <- c(2025)

# --- WNBA Data Refresh ---
cat("Refreshing WNBA PBP data...\n")
for (season in WNBA_SEASONS) {
  wnba_pbp <- load_wnba_pbp(season)
  filename <- sprintf("data/wnba_pbp_%d.csv.gz", season)
  write_csv(wnba_pbp, filename) 
  cat(sprintf("Saved WNBA PBP data for %d to %s\n", season, filename))
}


# --- NCAA WBB Data Refresh and Filtering ---
for (season in NCAA_SEASONS) {
  cat(sprintf("\nProcessing NCAA WBB data for season: %d\n", season))

  # 1. Fetch the full PBP data from wehoop
  full_pbp_data <- load_wbb_pbp(season)

  # 2. Save the full PBP file (to keep the master file)
  full_output_filename <- sprintf("data/ncaa_wbb_pbp_%d.csv.gz", season)
  cat(sprintf("Saving full PBP data (%d rows) to: %s\n", nrow(full_pbp_data), full_output_filename))
  write_csv(full_pbp_data, full_output_filename) 

  # 3. Filter for Arkansas games
  # FIX: The columns 'team_name' and 'opponent_name' were causing errors.
  # Using the more robust 'home_team' and 'away_team' columns to identify the games instead.
  arkansas_game_ids <- full_pbp_data %>%
    filter(home_team == TEAM_NAME | away_team == TEAM_NAME) %>%
    pull(game_id) %>%
    unique()

  # Filter the PBP data to include only those games
  arkansas_pbp_data <- full_pbp_data %>%
    filter(game_id %in% arkansas_game_ids)

  # 4. Save the Arkansas-specific data to a new compressed file
  arkansas_output_filename <- sprintf("data/arkansas_wbb_%d.csv.gz", season)
  cat(sprintf("Saving filtered Arkansas data (%d rows) to: %s\n", 
              nrow(arkansas_pbp_data), arkansas_output_filename))
  write_csv(arkansas_pbp_data, arkansas_output_filename) 
}

cat("\nAll data processing and filtering complete. Arkansas-specific files are ready.\n")

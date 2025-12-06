# Load necessary libraries (must be installed in your GitHub Action workflow)
library(wehoop)
library(dplyr)
library(readr)
library(stringr)

# --- Configuration ---
# Only keeping Aggregate seasons for consistent small file pulls.
AGGREGATE_SEASONS <- c(2024, 2025, 2026) 

# ------------------------------------
# --- NCAA WBB DATA PULLS ---
# ------------------------------------

# Note: Section 3 (Team and Player Season Aggregate Stats) has been
# removed because the espn_* functions require a specific 'team_id'.
# The necessary national aggregate data can be derived from the box 
# score files being loaded below.

# 3. Game Box Scores and Schedule/Results
for (season in AGGREGATE_SEASONS) {
  cat(sprintf("\nRefreshing National Game Stats for season: %d\n", season))
  
  # Pull 3a: Team Box Scores (by-game stats)
  team_box <- load_wbb_team_box(season)
  team_filename <- sprintf("data/national_wbb_team_box_%d.csv.gz", season)
  write_csv(team_box, team_filename)
  cat(sprintf("Saved National Team Box Score (%d rows) to: %s\n", nrow(team_box), team_filename))
  
  # Pull 3b: Player Box Scores (by-game stats)
  player_box <- load_wbb_player_box(season)
  player_filename <- sprintf("data/national_wbb_player_box_%d.csv.gz", season)
  write_csv(player_box, player_filename)
  cat(sprintf("Saved National Player Box Score (%d rows) to: %s\n", nrow(player_box), player_filename))
  
  # Pull 3c: Game Schedules/Results (Individual Game Summary)
  schedule_data <- load_wbb_schedule(season)
  schedule_filename <- sprintf("data/national_wbb_schedule_%d.csv.gz", season)
  write_csv(schedule_data, schedule_filename)
  cat(sprintf("Saved National Schedule/Results (%d rows) to: %s\n", nrow(schedule_data), schedule_filename))
}

cat("\nAll data processing and filtering complete. All files are ready for Gemini integration.\n")

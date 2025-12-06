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

# Note: NET Rankings (1) and AP/Coaches Poll Rankings (2) have been removed 
# as they pull current data, which conflicts with the historical/aggregate 
# nature of the remaining data pulls.

# 3. New: Team and Player Season Aggregate Stats
for (season in AGGREGATE_SEASONS) {
  cat(sprintf("\nRefreshing National Season Aggregate Stats for season: %d\n", season))
  
  # Pull 3a: Team Aggregate Stats (Season Averages/Totals)
  team_stats <- espn_wbb_team_stats(season)
  team_stats_filename <- sprintf("data/national_wbb_team_stats_%d.csv.gz", season)
  write_csv(team_stats, team_stats_filename)
  cat(sprintf("Saved National Team Stats (%d rows) to: %s\n", nrow(team_stats), team_stats_filename))

  # Pull 3b: Player Aggregate Stats (Season Averages/Totals)
  player_stats <- espn_wbb_player_stats(season)
  player_stats_filename <- sprintf("data/national_wbb_player_stats_%d.csv.gz", season)
  write_csv(player_stats, player_stats_filename)
  cat(sprintf("Saved National Player Stats (%d rows) to: %s\n", nrow(player_stats), player_stats_filename))

  # Pull 3c: Game Rosters (Static Roster Information)
  rosters <- espn_wbb_game_rosters(season)
  rosters_filename <- sprintf("data/national_wbb_rosters_%d.csv.gz", season)
  write_csv(rosters, rosters_filename)
  cat(sprintf("Saved National Roster Data (%d rows) to: %s\n", nrow(rosters), rosters_filename))
}

# 4. Existing: Game Box Scores and Schedule/Results (Renumbered from old script)
for (season in AGGREGATE_SEASONS) {
  cat(sprintf("\nRefreshing National Game Stats for season: %d\n", season))
  
  # Pull 4a: Team Box Scores (by-game stats)
  team_box <- load_wbb_team_box(season)
  team_filename <- sprintf("data/national_wbb_team_box_%d.csv.gz", season)
  write_csv(team_box, team_filename)
  cat(sprintf("Saved National Team Box Score (%d rows) to: %s\n", nrow(team_box), team_filename))
  
  # Pull 4b: Player Box Scores (by-game stats)
  player_box <- load_wbb_player_box(season)
  player_filename <- sprintf("data/national_wbb_player_box_%d.csv.gz", season)
  write_csv(player_box, player_filename)
  cat(sprintf("Saved National Player Box Score (%d rows) to: %s\n", nrow(player_box), player_filename))
  
  # Pull 4c: Game Schedules/Results (Individual Game Summary)
  schedule_data <- load_wbb_schedule(season)
  schedule_filename <- sprintf("data/national_wbb_schedule_%d.csv.gz", season)
  write_csv(schedule_data, schedule_filename)
  cat(sprintf("Saved National Schedule/Results (%d rows) to: %s\n", nrow(schedule_data), schedule_filename))
}

cat("\nAll data processing and filtering complete. All files are ready for Gemini integration.\n")

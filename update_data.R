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

# 1. New: NET Rankings (Current-season/date rankings)
cat(sprintf("\nRefreshing National NET Rankings (current date)...\n"))
net_rankings <- ncaa_wbb_NET_rankings()
net_filename <- "data/national_wbb_net_rankings_current.csv.gz"
write_csv(net_rankings, net_filename)
cat(sprintf("Saved National NET Rankings (%d rows) to: %s\n", nrow(net_rankings), net_filename))


# 2. New: AP and Coaches Poll Rankings (Season-by-season polls)
for (season in AGGREGATE_SEASONS) {
  cat(sprintf("\nRefreshing National AP/Coaches Poll Rankings for season: %d\n", season))
  rankings <- espn_wbb_rankings(season)
  rankings_filename <- sprintf("data/national_wbb_rankings_%d.csv.gz", season)
  write_csv(rankings, rankings_filename)
  cat(sprintf("Saved National Poll Rankings (%d rows) to: %s\n", nrow(rankings), rankings_filename))
}


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

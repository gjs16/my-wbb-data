# update_data.R
# Purpose: Fetch daily NCAA WBB data, save efficiently for history, 
# and create uncompressed snapshots for LLM accessibility.

# 1. Load Required Packages
library(wehoop)
library(dplyr)
library(readr)
library(purrr)
library(stringr)

# 2. Configuration
# We fetch 2024-2025 for historical context, and 2026 for the active season.
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
      # 1. Save Compressed (Archive)
      write_csv(df_schedule, file = paste0(path, "national_wbb_schedule_", season, ".csv.gz"))
      
      # 2. Save Uncompressed (ONLY for Current Season for LLM)
      if (season == current_season) {
        write_csv(df_schedule, file = paste0(path, "national_wbb_schedule_", season, ".csv"))
      }
    }
  }, error = function(e) { message(paste("Error fetching schedule:", e)) })

  # --- B. TEAM BOX SCORES ---
  tryCatch({
    message("Fetching Team Box Scores...")
    df_team <- load_wbb_team_box(season = season)
    
    if (!is.null(df_team) && nrow(df_team) >

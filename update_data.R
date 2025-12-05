library(wehoop)
library(dplyr)
library(readr)
library(purrr)

# Create data directory if it doesn't exist
if (!dir.exists("data")) {
  dir.create("data")
}

# --- CONFIGURATION ---
wnba_season <- 2025
ncaa_seasons <- c(2025, 2026) # 2025 is the 2024-25 season, 2026 is the 2025-26 season

# --- FUNCTION TO SAFE LOAD ---
# Wrapper to handle potential timeout/connection issues gracefully
safe_load_wnba <- function(y) {
  tryCatch(
    {
      message(paste("Loading WNBA PBP for season:", y))
      load_wnba_pbp(seasons = y)
    },
    error = function(e) {
      message(paste("Error loading WNBA:", e))
      return(NULL)
    }
  )
}

safe_load_ncaa <- function(y) {
  tryCatch(
    {
      message(paste("Loading NCAA PBP for season:", y))
      load_wbb_pbp(seasons = y)
    },
    error = function(e) {
      message(paste("Error loading NCAA:", e))
      return(NULL)
    }
  )
}

# --- FETCH WNBA DATA ---
# WNBA data is smaller, so we can save it as a standard CSV if desired,
# but we will use .csv.gz for consistency and speed.
wnba_data <- safe_load_wnba(wnba_season)

if (!is.null(wnba_data) && nrow(wnba_data) > 0) {
  file_name <- paste0("data/wnba_pbp_", wnba_season, ".csv.gz")
  message(paste("Writing WNBA data to", file_name, "Rows:", nrow(wnba_data)))
  write_csv(wnba_data, file_name)
} else {
  message("No WNBA data found or error occurred.")
}

# --- FETCH NCAA DATA ---
# NCAA data is HUGE. We must iterate and save separately to avoid memory crash
# and to keep file sizes manageable for GitHub (<100MB).
for (season in ncaa_seasons) {
  ncaa_data <- safe_load_ncaa(season)
  
  if (!is.null(ncaa_data) && nrow(ncaa_data) > 0) {
    file_name <- paste0("data/ncaa_wbb_pbp_", season, ".csv.gz")
    message(paste("Writing NCAA data to", file_name, "Rows:", nrow(ncaa_data)))
    
    # Selecting columns to reduce size slightly if needed, but keeping all for now.
    # We write to a compressed CSV to stay under GitHub's 100MB limit.
    write_csv(ncaa_data, file_name)
    
    # Garbage collection to free up memory before next load
    rm(ncaa_data)
    gc()
  } else {
    message(paste("No NCAA data found for season", season))
  }
}

message("Data update complete.")

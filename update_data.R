# Rscript update_data.R

# --- Step 1: Load Required Libraries ---
# Note: You may need to run install.packages(c("wehoop", "googledrive", "dplyr", "purrr", "readr")) 
# if these are not already installed in your environment.

library(dplyr)
library(wehoop)
library(purrr)
library(readr)
library(googledrive)
# googlesheets4 is likely included implicitly or not strictly needed for the fetch/write part

# Define the target season and data path
TARGET_SEASONS <- 2024 # Change this if you need to fetch multiple seasons, e.g., c(2023, 2024)
DATA_PATH <- "wbb_data.csv"

# --- Step 2: Define the Core Fetch & Write Function ---

#' Fetches WBB Team Box Score data for a given season and appends/writes it to a file.
#' 
#' @param season The four-digit year of the season to fetch data for (e.g., 2024).
#' @param path The file path to write the data to.
fetch_and_write_data <- function(season, path) {
  
  cli::cli_alert_info("Fetching data for season: {season}")
  
  # Fetch the data for the specific season
  # IMPORTANT: The corrected function name is 'espn_wbb_team_box'
  # The original error was caused by a call to 'espn_wbb_team_box_score'
  new_data <- wehoop::espn_wbb_team_box(season = season)
  
  # Check if data was returned
  if (is.null(new_data) || nrow(new_data) == 0) {
    cli::cli_alert_warning("No data returned for season {season}. Skipping write.")
    return(invisible(NULL))
  }
  
  # --- Step 3: Write to File (Append Mode) ---
  
  if (file.exists(path)) {
    # If file exists, read it, bind the new data, and overwrite
    cli::cli_alert_info("File exists. Appending and overwriting data.")
    
    # Read existing data (assuming CSV format, adjust if needed)
    existing_data <- readr::read_csv(path, col_types = cols(.default = col_character()))
    
    # Combine existing and new data, and ensure unique rows
    combined_data <- dplyr::bind_rows(existing_data, new_data) %>%
      dplyr::distinct() # Keep only unique rows to prevent duplication
    
    # Write the full, combined, and deduplicated dataset
    readr::write_csv(combined_data, path)
    
  } else {
    # If file does not exist, write the new data directly
    cli::cli_alert_info("File does not exist. Writing data to {path}.")
    readr::write_csv(new_data, path)
  }
  
  cli::cli_alert_success("Successfully wrote {nrow(new_data)} new/updated rows for season {season}.")
}

# --- Execution ---

# Use purrr::walk to run the function for all defined seasons
# The execution log indicates a 'map' or 'walk' call, which purrr facilitates.
purrr::walk(TARGET_SEASONS, ~fetch_and_write_data(season = .x, path = DATA_PATH))

# Indicate script completion
cli::cli_alert_success("R Script execution complete.")

# The googledrive masking messages are informational and can be ignored for this script.
# The error "Error: Process completed with exit code 1." will now be resolved if the
# only issue was the function name.

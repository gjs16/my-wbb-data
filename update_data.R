# Rscript update_data.R

# --- Load Required Libraries ---
# Note: Ensure wehoop and purrr are installed.
library(dplyr)
library(wehoop)
library(purrr)
library(readr)
library(googledrive)
library(cli) # Used for informative alerts

# Define the target season and file path
TARGET_SEASON <- 2024
# Keep the CSV file name the same to minimize external changes.
DATA_PATH <- "wbb_data.csv" 

# --- Main Data Fetching Function ---
fetch_and_write_data <- function(season, path) {
    
    cli::cli_alert_info("Starting robust data fetch for season: {season}")
    
    # --- STEP 1: Get all Game IDs for the Season ---
    cli::cli_alert_info("1/2: Fetching game IDs using espn_wbb_scoreboard()...")
    
    scoreboard_data <- tryCatch(
        wehoop::espn_wbb_scoreboard(season = season),
        error = function(e) {
            cli::cli_abort("Failed to fetch scoreboard data for season {season}: {e$message}")
        }
    )
    
    if (is.null(scoreboard_data) || nrow(scoreboard_data) == 0) {
        cli::cli_alert_warning("No games found for season {season}. Skipping.")
        return(invisible(NULL))
    }
    
    game_ids <- scoreboard_data$game_id
    cli::cli_alert_success("Found {length(game_ids)} game IDs.")
    
    
    # --- STEP 2: Fetch All Game Data and Extract Team Box Scores ---
    cli::cli_alert_info("2/2: Fetching detailed game data using espn_wbb_game_all()...")
    
    # Use map to call espn_wbb_game_all for each ID, then compact to remove NULL results
    # The progress bar is helpful for long runs.
    all_game_data <- purrr::map(game_ids, 
                                ~wehoop::espn_wbb_game_all(game_id = .x), 
                                .progress = TRUE) %>%
        purrr::compact()
    
    # Extract ONLY the Team Box score data from the list of results
    # map_dfr is crucial here: it extracts the 'Team' element from each list 
    # item and combines them row-wise into one single dataframe.
    new_team_data <- purrr::map_dfr(all_game_data, ~.x$Team)
    
    if (nrow(new_team_data) == 0) {
        cli::cli_alert_warning("No team box score data returned. Skipping write.")
        return(invisible(NULL))
    }
    
    cli::cli_alert_success("Successfully fetched {nrow(new_team_data)} rows of box score data.")
    
    
    # --- STEP 3: Write to File (Append/Overwrite Logic) ---
    
    if (file.exists(path)) {
        cli::cli_alert_info("File exists. Reading, combining, and overwriting data.")
        
        # Read existing data (use col_types = cols(.default = col_character()) for consistency)
        existing_data <- readr::read_csv(path, col_types = cols(.default = col_character()))
        
        # Combine existing and new data, and deduplicate 
        combined_data <- dplyr::bind_rows(existing_data, new_team_data) %>%
            dplyr::distinct() 
        
        readr::write_csv(combined_data, path)
        final_row_count <- nrow(combined_data)
        
    } else {
        cli::cli_alert_info("File does not exist. Writing data to {path}.")
        readr::write_csv(new_team_data, path)
        final_row_count <- nrow(new_team_data)
    }
    
    cli::cli_alert_success("R Script execution complete. Total rows in {path}: {final_row_count}")
}

# --- Execution ---
fetch_and_write_data(season = TARGET_SEASON, path = DATA_PATH)

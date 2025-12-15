# 🏀 Automated Women's College Basketball (WBB) Data Fetcher

This repository provides an automated pipeline for recurringly fetching, updating, and storing detailed team box score data for NCAA Women's College Basketball (WBB) seasons.

The process leverages the power of R for data scraping and analysis, and GitHub Actions for daily automation, ensuring the local dataset remains current.

---

## ✨ Project Goal

The primary goal is to maintain an up-to-date, comprehensive dataset of WBB team box scores (stored in `wbb_data.csv`) by automating the entire data retrieval process, making the data readily available for analysis, visualization, or modeling.

## 💾 Data Source & Pipeline

### Source

The data is sourced from ESPN using the **`wehoop`** R package, part of the fantastic [SportsDataverse](https://sportsdataverse.org/) project.

### Data Flow & Logic

The R script (`update_data.R`) executes a robust two-step process to ensure complete and efficient data retrieval:

1.  **Schedule Retrieval:** The script first uses `wehoop::espn_wbb_scoreboard(season)` to fetch the `game_id` for every game played in the target season (e.g., 2024).
2.  **Detailed Data Fetch:** It then iterates through all collected `game_id`s, using the comprehensive **`wehoop::espn_wbb_game_all(game_id)`** function to retrieve all play-by-play, player, and team data for that specific game.
3.  **Extraction and Storage:** The script specifically extracts the **Team Box Score** data, combines it with existing data in `wbb_data.csv`, and uses a `dplyr::distinct()` operation to prevent duplicate entries before overwriting the file.

### Output File

* **`wbb_data.csv`**: A single, continuously updated CSV file containing all WBB team box score data fetched since the project's inception.

---

## 🛠️ Setup and Installation

### 1. R Environment

You must have R installed. The project relies on the following R packages:

| Package | Purpose |
| :--- | :--- |
| `wehoop` | Data retrieval from ESPN WBB |
| `dplyr` | Data manipulation and binding |
| `purrr` | Iterating and mapping over lists (for `game_all`) |
| `readr` | Reading and writing CSV files |
| `googledrive` | (Optional) Interacting with Google Drive/Sheets (as required) |
| `cli` | Command Line Interface status messages |

You can install these packages in your R environment with:

```R
install.packages(c("wehoop", "dplyr", "purrr", "readr", "googledrive", "cli"))

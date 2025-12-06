# Automated WeHoop Data Repository 🏀

This repository automatically fetches and updates **Women's Basketball** play-by-play data and various seasonal statistics daily using GitHub Actions and the **wehoop R package**.

The updated `update_data.R` script now automatically filters the NCAA data and saves Arkansas-specific files for easier analysis.

---

## 💾 Data Sources and File Listing

The data is stored in the `data/` directory in **Compressed CSV format (`.csv.gz`)**.

### 1. Play-by-Play (PBP) Data
These files contain detailed, game-by-game event logs.

| League | Team | Season | File Path |
| :--- | :--- | :--- | :--- |
| WNBA | N/A | 2025 | `data/wnba_pbp_2025.csv.gz` |
| NCAA WBB | All Teams | 2024-25 | `data/ncaa_wbb_pbp_2025.csv.gz` |
| NCAA WBB | All Teams | 2025-26 | `data/ncaa_wbb_pbp_2026.csv.gz` |
| NCAA WBB | **Arkansas** | 2024-25 | `data/arkansas_wbb_2025.csv.gz` |
| NCAA WBB | **Arkansas** | 2025-26 | `data/arkansas_wbb_2026.csv.gz` |

### 2. Seasonal Aggregate & Box Score Data
These files provide summarized team/player stats, rosters, and game results.
*(The `season` variable refers to the year the championship is played, e.g., **2026** is the **2025-26** season.)*

| Type | League | Scope | Season | File Path Pattern |
| :--- | :--- | :--- | :--- | :--- |
| **Team Aggregate Stats** | NCAA WBB | National | 2024, 2025, 2026 | `data/national_wbb_team_stats_{season}.csv.gz` |
| **Player Aggregate Stats** | NCAA WBB | National | 2024, 2025, 2026 | `data/national_wbb_player_stats_{season}.csv.gz` |
| **Game Rosters** | NCAA WBB | National | 2024, 2025, 2026 | `data/national_wbb_rosters_{season}.csv.gz` |
| **Team Box Scores (by-game)** | NCAA WBB | National | 2024, 2025, 2026 | `data/national_wbb_team_box_{season}.csv.gz` |
| **Player Box Scores (by-game)** | NCAA WBB | National | 2024, 2025, 2026 | `data/national_wbb_player_box_{season}.csv.gz` |
| **Schedule/Results** | NCAA WBB | National | 2024, 2025, 2026 | `data/national_wbb_schedule_{season}.csv.gz` |

---

## 🤖 How to use with LLMs

To analyze this data in an LLM, you need the **Raw Link** for the specific file.

1.  Navigate to the `data/` folder in this repository.
2.  Click on the file you want (e.g., `arkansas_wbb_2026.csv.gz`).
3.  Look for the **"Raw"** button (or "Download" if viewing in a browser).
4.  Right-click the **"Raw"** button and select **"Copy Link Address"**.
5.  Paste that link into your analysis tool with the prompt below.

### Example Prompt for Analysis: "I am providing a link to a compressed CSV file containing only Arkansas WBB play-by-play data. Please load this dataset directly and perform the following analysis..." PASTEYOURRAWLINKHERE

---

## ⚙️ Setup Instructions

1.  **Fork** this repository to your own GitHub account.
2.  Go to the **Actions** tab.
3.  Click **"I understand my workflows, go ahead and enable them"**.
4.  Select the **Daily Data Refresh** workflow on the left.
5.  Click **Run workflow** to trigger the first data pull immediately.

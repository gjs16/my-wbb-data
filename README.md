# Automated WeHoop Data Repository 🏀

This repository automatically fetches and updates **Women's Basketball** statistics daily using GitHub Actions and the **wehoop R package**. This strategy focuses on reliable game-level box scores and schedules for streamlined LLM analysis.

---

## 💾 Data Sources and File Listing

The data is stored in the `data/` directory in **Compressed CSV format (`.csv.gz`)**.

### 1. Seasonal Statistics (Box Scores & Schedule)
These files provide summarized team/player stats, and game results for all NCAA Division I WBB teams.
*(The `season` variable refers to the year the championship is played, e.g., **2026** is the **2025-26** season.)*

| Type | League | Scope | Season | File Path Pattern |
| :--- | :--- | :--- | :--- | :--- |
| **Schedule/Results** | NCAA WBB | National | 2024, 2025, 2026 | `data/national_wbb_schedule_{season}.csv.gz` |
| **Team Box Scores (by-game)** | NCAA WBB | National | 2024, 2025, 2026 | `data/national_wbb_team_box_{season}.csv.gz` |
| **Player Box Scores (by-game)** | NCAA WBB | National | 2024, 2025, 2026 | `data/national_wbb_player_box_{season}.csv.gz` |

---

## 🤖 How to use with LLMs

To analyze this data in an LLM, you need the **Raw Link** for the specific file.

1.  Navigate to the `data/` folder in this repository.
2.  Click on the file you want (e.g., `national_wbb_team_box_2026.csv.gz`).
3.  Look for the **"Raw"** button or "Download" link.
4.  Right-click the **"Raw"** button and select **"Copy Link Address"**.
5.  Paste that link into your analysis tool with a prompt, using the file type for context.

### Example Prompt for Analysis
"I am providing a link to a compressed CSV file containing national NCAA WBB team box score data for the 2026 season. Please load this dataset directly and calculate the current win-loss record for the Arkansas Razorbacks." **PASTEYOURRAWLINKHERE**

---

## ⚙️ Setup Instructions
... (The rest of the Setup Instructions section remains the same)

# 🏀 Automated WBB Data Repository: LLM-Optimized (Two-Sheet System)

This repository automates the daily fetching and preparation of **Women's College Basketball** statistics from the `wehoop` R package. The entire pipeline is engineered for **streamlined and stable LLM (Large Language Model) analysis** by leveraging Google Sheets.

---

## 💡 LLM Quick-Start Context: Project Goal & Workflow

This section provides the essential information an LLM needs for immediate analysis without detailed file examination.

### Project Goal
To provide a reliable, daily-updated, multi-season database of NCAA Women's Basketball statistics to enable detailed trend analysis, player performance tracking, and year-over-year (YoY) benchmarking.

### Data Architecture Overview (The "Two-Sheet" Strategy)
The data is split into two separate Google Sheets to handle large file sizes and manage daily updates efficiently. LLMs must reference **both** sheet names for full analysis. 

| Sheet Name | Sheet ID | Tabs Contained | Data Purpose |
| :--- | :--- | :--- | :--- |
| **NCAA WBB Current Stats** | `1QNTkUqUm-gXwhqLKoOtj3x8fdw-aV06InXtP4VoGaTI` | `llm_data_schema`, All `*2026` tabs | **Current Season Live Data** (Daily Updates) |
| **NCAA WBB Historic Stats** | `1ul53_2X0TlE_Nb_iaZ1WTFqn7j9ETDdxYQGbE2N7y6Q` | All `*2024`, `*2025` tabs | **Historical Benchmarking Data** (Static) |

### Daily Workflow Summary (The Process)
1.  **Fetch:** The R script pulls **all three seasons** (2024, 2025, 2026) daily.
2.  **Filter & Sync:** Only the current season (`*2026`) files and the `llm_data_schema` are synced to the **NCAA WBB Current Stats** sheet.
3.  **LLM Access:** The LLM accesses the most up-to-date 2026 data and schema instantly via the current sheet.

---

## 💾 Tab Inventory and Schema Context

The R script generates the following types of tabs (one for each season per dataset):

| Tab Name Pattern | Content Description | Key Columns for Analysis |
| :--- | :--- | :--- |
| `llm_data_schema` | **CRITICAL:** Text file containing the names and definitions of all available datasets. | N/A (Context Only) |
| `wbb_player_box_YYYY` | Player-level stats (points, rebounds, FG%, minutes). **BEST for individual performance analysis.** | `player_name`, `team_name`, `pts`, `reb`, `ast`, `min`, `fg_pct` |
| `wbb_team_box_YYYY` | Team-level stats (FG%, turnovers, totals). **BEST for team efficiency analysis.** | `team_name`, `fg_pct`, `fg3_pct`, `turnovers`, `rebounds` |
| `wbb_schedule_YYYY` | Game-level results (scores, opponents, game IDs). **BEST for identifying wins/losses/dates.** | `game_id`, `date`, `home_team`, `away_team`, `home_score`, `away_score` |
| `wbb_pbp_YYYY` | Play-by-play data (most granular, very large). | `play_id`, `score`, `shooting_player`, `type_text` |

---

## 🚀 Cross-Analysis Prompting Guide (How to Use Both Sheets)

To spot trends and propose analysis, LLMs must be instructed to use the data separation.

| Goal | Tabs/Sheets to Reference | Sample Prompt Structure (For LLM Use) |
| :--- | :--- | :--- |
| **YoY Player Trend** | `Historic` (`*2024`) and `Current` (`*2026`) sheets, `wbb_player_box` tabs. | "Using the **NCAA WBB Current Stats** and **NCAA WBB Historic Stats** sheets, compare the average points per game for the top 5 players on the Arkansas team in 2024 vs. 2026. Suggest a reason for any large change." |
| **Propose Analysis** | `Current` sheet, all tabs. | "Using the **NCAA WBB Current Stats** sheet, analyze the relationship between team free-throw percentage (`ft_pct` from `wbb_team_box_2026`) and winning percentage (`w` from `wbb_schedule_2026`). Propose three teams that are underperforming based on their shooting efficiency." |
| **Workflow Step** | `llm_data_schema` tab. | "Explain the data flow of this project using the `llm_data_schema` and the 'LLM Quick-Start Context' section. Which tab is the largest and why?" |

# 🏀 Automated WBB Data Repository: LLM-Optimized

This repository automatically fetches and updates **Women's Basketball** statistics daily using GitHub Actions and the **wehoop R package**. This strategy is engineered for **streamlined and stable LLM (Large Language Model) analysis** by piping all data into a single Google Sheet.

---

## 💾 Data Sources and File Listing

The repository now exclusively uses **uncompressed (.csv)** files for all three seasons (2024, 2025, 2026) to ensure compatibility with the Google Sheets bridge. All files are located in the local `data/` directory and are synced to a single Google Sheet daily.

### 1. File Inventory (Uncompressed for Analysis)

| Tab Name | Scope | Season | Use Case |
| :--- | :--- | :--- | :--- |
| **llm_data_schema** | Metadata | N/A | **CRUCIAL:** Provides column names and context. |
| **national_wbb_schedule_2026** | National | 2026 | Current Schedule and game results. |
| **national_wbb_team_box_2026** | National | 2026 | Current Team-level metrics (FG%, TOs, Rebounds). |
| **national_wbb_player_box_2026** | National | 2026 | Current Individual stats (Points, Minutes, Player FG%). |
| **arkansas_wbb_player_box_2026** | Arkansas | 2026 | Quickest access for Arkansas player analysis. |
| **national_wbb_schedule_2025** | Historic | 2025 | Historic data for trending and comparisons. |
| **national_wbb_player_box_2025** | Historic | 2025 | Historic data for trending and comparisons. |
| **national_wbb_team_box_2025** | Historic | 2025 | Historic data for trending and comparisons. |
| **national_wbb_schedule_2024** | Historic | 2024 | Historic data for trending and comparisons. |
| **national_wbb_player_box_2024** | Historic | 2024 | Historic data for trending and comparisons. |
| **national_wbb_team_box_2024** | Historic | 2024 | Historic data for trending and comparisons. |

---

## 🚀 Optimized LLM Workflow (Via Google Sheets)

The most stable and fastest way to analyze this data is through your consolidated Google Sheet, which is updated daily by the GitHub Action.

* **Google Sheet ID:** `1QNTkUqUm-gXwhqLKoOtj3x8fdw-aV06InXtP4VoGaTI`
* **Google Sheet Name:** `NCAA WBB Stats`

### Querying the Data in Gemini

You will use the **Google Drive Tool** capability available in the LLM chat. Always provide the sheet name first.

| Goal | Tab to Reference | Sample Prompt Structure |
| :--- | :--- | :--- |
| **Team-Level Performance** | `national_wbb_team_box_2026` | "Using the **NCAA WBB Stats** sheet, filter the `national_wbb_team_box_2026` tab for Arkansas. Calculate the average `fg_pct` in the three most recent wins." |
| **Historic Comparison** | Multiple Tabs | "Using the **NCAA WBB Stats** sheet, compare the `national_wbb_player_box_2024` and `national_wbb_player_box_2026` tabs to find the average `points` scored by the top 5 players on the roster in each season." |

# 🏀 Automated WBB Data Repository: LLM-Optimized

This repository automatically fetches and updates **Women's Basketball** statistics daily using GitHub Actions and the **wehoop R package**. This strategy focuses on reliable game-level box scores and schedules, engineered for **streamlined and stable LLM (Large Language Model) analysis**.

---

## 💾 Data Sources and File Listing

The repository contains three types of files, optimized for different consumption methods. All files are located in the `data/` directory.

### 1. Core Data (Storage & Historical Analysis)

These files are the original, comprehensive dataset. They are large and compressed for efficient storage and programmatic analysis (e.g., using R/Python scripts).

| Type | Scope | Season | File Path Pattern | Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Schedule/Results** | National | 2024, 2025, 2026 | `data/national_wbb_schedule_{season}.csv.gz` | Complete schedule, game metadata. |
| **Team Box Scores** | National | 2024, 2025, 2026 | `data/national_wbb_team_box_{season}.csv.gz` | **Team-level metrics** (FG%, TOs, Rebounds). |
| **Player Box Scores** | National | 2024, 2025, 2026 | `data/national_wbb_player_box_{season}.csv.gz` | **Individual stats** (Points, Minutes, Player FG%). |

### 2. LLM-Optimized Files (Current Season: 2026) 🚀

These **uncompressed (.csv)** and team-specific files are generated specifically for the current season to ensure LLMs can access the data instantly without compression errors.

| Type | Scope | File Path Pattern | Analysis Focus (Pull for Speed) |
| :--- | :--- | :--- | :--- | :--- |
| **LLM Schema Anchor** | Metadata | `data/2026_wbb_data_schema.txt` | **CRUCIAL:** Provides column names and context. **Must be copied into your prompt.** |
| **National Team Box** | Uncompressed | `data/national_wbb_team_box_2026.csv` | Full team-by-team statistical crunching. |
| **Arkansas Player Box** | Uncompressed | `data/arkansas_wbb_player_box_2026.csv` | **Quickest access** for Arkansas player analysis (Points leaders, Minutes, etc.). |

---

## 💡 How to use with LLMs: Stability & Speed

Using this data with an LLM requires a specific two-step prompting strategy to ensure **stability** (preventing statistical hallucination) and **speed**.

### Understanding Data Access

* **For LLM Users:** Always use the **uncompressed** `.csv` files for the current season (e.g., `national_wbb_team_box_2026.csv`). The compressed `.gz` files will fail to load with most general-purpose LLM tools.
* **Quickest Pull:** For Arkansas-only questions, use the smaller, pre-filtered **`arkansas_wbb_player_box_2026.csv`** file for the fastest LLM response.
* **Comprehensive Pull:** For SEC or national projections, use the full **`national_wbb_team_box_2026.csv`**.

### The Optimized Two-Step Query Process

To guarantee correct column names and context, you must first provide the schema, then the data link.

#### Step 1: Anchor the LLM (Copy the Schema)

1.  Navigate to the `data/` folder.
2.  Click on **`2026_wbb_data_schema.txt`**.
3.  Click **"Raw"** and copy **all the text content**.
4.  Paste this schema directly into your LLM prompt.

#### Step 2: Provide the Data (Copy the Raw Link)

1.  Navigate back to the `data/` folder.
2.  Click on the desired **uncompressed** `.csv` file (e.g., `national_wbb_team_box_2026.csv`).
3.  Click **"Raw"**.
4.  Copy the **full URL** from your browser (this is the Raw Link).
5.  Paste this Raw Link into your LLM prompt immediately after the schema text.

### 📝 Sample Optimized Queries (For Arkansas Analysis)

Here are examples showing the best file to use and the ideal prompt structure:

| Goal | Best File to Use | Sample Prompt Structure |
| :--- | :--- | :--- |
| **Team-Level Performance Trend** | `national_wbb_team_box_2026.csv` | **[PASTE SCHEMA]** "Load the dataset from the link. Filter for Arkansas and calculate the average `fg_pct` in the three most recent wins. How does their average `tov` in those games compare to the season average?" **[PASTE RAW LINK]** |
| **Quick Player Leaderboard** | `arkansas_wbb_player_box_2026.csv` | **[PASTE SCHEMA]** "Load the Arkansas Player Box dataset. Which players lead the team in total `pts` and average `min` per game for the season? Display the top 3." **[PASTE RAW LINK]** |
| **Modeling/Projection** | `national_wbb_team_box_2026.csv` | **[PASTE SCHEMA]** "Load the dataset. Filter for all SEC teams. Build a simple linear regression model where `total_points` is the dependent variable and `fg_pct` and `trb` are independent variables. Interpret the coefficients." **[PASTE RAW LINK]** |

---

## ⚙️ Setup and Maintenance

The setup process involves initializing the R environment and scheduling the `update_data.R` script.

... (The rest of the Setup Instructions section remains the same)

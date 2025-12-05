Automated WeHoop Data Repository

This repository automatically fetches and updates Women's Basketball play-by-play data daily using GitHub Actions and the wehoop R package.

The updated update_data.R script now automatically filters the NCAA data and saves Arkansas-specific files for easier analysis.

Data Sources

The data is stored in the data/ directory in Compressed CSV format (.csv.gz).

| League | Team | Season | File Path |
| WNBA | N/A | 2025 | data/wnba_pbp_2025.csv.gz |
| NCAA WBB | All Teams | 2024-25 | data/ncaa_wbb_pbp_2025.csv.gz |
| NCAA WBB | All Teams | 2025-26 | data/ncaa_wbb_pbp_2026.csv.gz |
| NCAA WBB | Arkansas | 2024-25 | data/arkansas_wbb_2025.csv.gz |
| NCAA WBB | Arkansas | 2025-26 | data/arkansas_wbb_2026.csv.gz |

(Note: In wehoop, the "season" year refers to the year the championship is played. So 2026 is the 2025-26 season.)

How to use with LLMs

To analyze this data in an LLM, you need the Raw Link.

Navigate to the data/ folder in this repository.

Click on the file you want (e.g., arkansas_wbb_2026.csv.gz).

Look for the "Download" button or the "Raw" button.

Right-click that button and select "Copy Link Address".

Paste that link into your analysis tool with the prompt below.

Example Prompt for Analysis

"I am providing a link to a compressed CSV file containing only Arkansas WBB play-by-play data. Please load this dataset directly and perform the following analysis..."

$$PASTE YOUR RAW LINK HERE$$

Setup Instructions

Fork this repository to your own GitHub account.

Go to the Actions tab.

Click "I understand my workflows, go ahead and enable them".

Select the Daily Data Refresh workflow on the left.

Click Run workflow to trigger the first data pull immediately.

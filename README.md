# CB Progress Tracker

A web-based dashboard to track contributor (CB) performance, promotion pipeline, and incentives.

## How to Use

1. **Open** `index.html` in any modern browser (Chrome, Firefox, Safari, Edge)
2. **Upload** your CSV data using the "Upload CSV" button, or click "load sample data" to explore
3. **Navigate** between Dashboard, Contributors, Pipeline, and Strikes & Incentives tabs

## CSV Format

Your CSV file should have these columns:

| Column | Description | Example |
|--------|-------------|---------|
| `name` | Contributor name | Maria Garcia |
| `cb_id` | Unique CB identifier | CB-001 |
| `level` | Current level: L0, L10, or L12 | L10 |
| `status` | Active, Inactive, On Track, In 1:1, Removed, Promoted | On Track |
| `qc_score` | QC score (0-5) | 4.5 |
| `tasks_submitted` | Total tasks submitted | 12 |
| `tasks_passed` | Tasks that passed QC | 11 |
| `carrots` | Carrots earned | 8 |
| `strikes` | Strike count (0-2) | 0 |
| `mission_quality` | Standard, High, or Premium | High |
| `last_active` | Last active date | 2026-03-20 |
| `notes` | Optional notes | Excellent performance |

A sample CSV file (`sample_cb_data.csv`) is included for reference.

## Features

- **Dashboard**: Summary metrics, level distribution, QC performance, promotion-ready and at-risk lists
- **Contributors**: Searchable, filterable, sortable table of all contributors with detail views
- **Pipeline**: Visual promotion pipeline (L0 → L10 → L12) with decision flow
- **Strikes & Incentives**: Two-strike system tracking, carrot leaderboard, mission quality stats
- **CSV Export**: Export current data back to CSV

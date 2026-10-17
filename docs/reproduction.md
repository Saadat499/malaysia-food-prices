# Reproducing the saved analysis

Run commands from the repository root. The sequence below is for PowerShell and a fresh PostgreSQL database. It has been checked against the source files, but the complete pipeline was not rerun for this README update.

## Environment

Install Python and PostgreSQL (including `psql` and `createdb`, available on PATH). Versions are not pinned in the existing project. Power BI Desktop on Windows is needed only for the dashboard.

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Create a local `.env` with PGHOST, PGPORT, PGDATABASE, PGUSER and PGPASSWORD. Use `food_prices` for PGDATABASE; the loaders validate this database name. Supply your own local credentials and never commit this file.

Example non-secret settings:

```dotenv
PGHOST=localhost
PGPORT=5432
PGDATABASE=food_prices
PGUSER=postgres
```

Add PGPASSWORD locally. The Python loaders read `.env`; `psql` does not. For the commands below, supply matching host/user values and enter the password at the prompt. Create a new empty database once:

```powershell
createdb -h localhost -U postgres food_prices
.\.venv\Scripts\python.exe src/check_env.py
```

## Download inputs

Keep the original downloads unchanged. From PowerShell:

```powershell
New-Item -ItemType Directory -Force data/raw
$rawBase = 'https://storage.data.gov.my/pricecatcher'
foreach ($lookup in @('lookup_item','lookup_premise')) {
    Invoke-WebRequest "$rawBase/$lookup.parquet" -OutFile "data/raw/$lookup.parquet"
}
$analysisMonths = @('2022-12') + @(2023..2025 | ForEach-Object {
    $yearValue = $_
    1..12 | ForEach-Object { '{0}-{1:00}' -f $yearValue, $_ }
})
$downloadMonths = $analysisMonths + @('2026-08','2026-09')
foreach ($monthValue in $downloadMonths) {
    Invoke-WebRequest "$rawBase/pricecatcher_$monthValue.parquet" -OutFile "data/raw/pricecatcher_$monthValue.parquet"
}
```

The extra 2026 files are used by the exploratory inspection notebook, not the main 2023–2025 analysis. The upstream files and lookups can change; a fresh download may not reproduce the original snapshot exactly. Preserve your downloaded snapshot if exact repeatability matters.

## Prepare observations

```powershell
.\.venv\Scripts\python.exe -m jupyterlab
```

Run each notebook from top to bottom in this order:

1. `notebooks/01_data_inspection.ipynb`
2. `notebooks/02_coverage_checks.ipynb`
3. `notebooks/03_data_preparation.ipynb`

Before running notebook 03, replace its first-cell hard-coded `project_root` with the absolute path to your checkout. Notebooks 01 and 02 search parent folders, with an original-machine fallback; launch Jupyter from this repository root.

Notebook 03 creates staged, deduplicated, flagged and processed files. The expected processed snapshot is 37 monthly files and 6,945,328 observations. Check its audit outputs before loading. Notebook execution rewrites generated audit CSVs; use a separate checkout if preserving the published outputs.

## Load PostgreSQL and run analyses

```powershell
psql -h localhost -U postgres -d food_prices -v ON_ERROR_STOP=1 -f sql/01_create_tables.sql
.\.venv\Scripts\python.exe src/load_lookups.py
.\.venv\Scripts\python.exe src/load_prices.py
psql -h localhost -U postgres -d food_prices -v ON_ERROR_STOP=1 -f sql/02_verify_load.sql
.\.venv\Scripts\python.exe src/load_festival_windows.py
```

The schema script is for a fresh database. Do not rerun it against populated tables. The lookup and price loaders refuse to append to existing records. Expected dimensions: 15 items and 2,632 premises, including the unknown-lookup premise.

Run queries 03–11 in numerical order. The first two queries in this example illustrate CSV export; use the mapping below for the remaining result filenames:

```powershell
psql -h localhost -U postgres -d food_prices -v ON_ERROR_STOP=1 --csv -f sql/03_monthly_price_trends.sql -o docs/monthly_price_summary_2023_2025.csv
psql -h localhost -U postgres -d food_prices -v ON_ERROR_STOP=1 --csv -f sql/04_monthly_price_changes.sql -o docs/monthly_price_changes_2023_2025.csv
```

| SQL file | Output CSV under docs/ |
|---|---|
| 05_tomato_matched_premises.sql | tomato_matched_premises_2024_05_06.csv |
| 06_tomato_coverage_sensitivity.sql | tomato_coverage_sensitivity_2024_05_06.csv |
| 07_tomato_state_comparison.sql | tomato_state_comparison_2024_05_06.csv |
| 08_state_price_comparison.sql | Two result sets; see instructions below |
| 09_retailer_price_comparison.sql | monthly_retailer_price_comparison_2023_2025.csv |
| 10_festival_price_comparison.sql | festival_price_comparison_2023_2025.csv |
| 11_festival_price_sensitivity.sql | festival_price_comparison_unflagged_2023_2025.csv |

Query 08 contains two SELECT statements. Run it in a SQL editor such as pgAdmin and export the first result as `monthly_state_price_summary_2023_2025.csv` and the second as `monthly_state_price_ranks_2023_2025.csv`. Do not combine both outputs into a single CSV.

After exporting query 10, generate the three-year summaries, then create the reporting views:

```powershell
.\.venv\Scripts\python.exe src/summarise_festival_patterns.py
psql -h localhost -U postgres -d food_prices -v ON_ERROR_STOP=1 -f sql/12_reporting_views.sql
```

The views are `v_monthly_price_trends`, `v_monthly_state_prices`, `v_monthly_retailer_prices` and `v_festival_price_comparison`. Open `dashboard/price_catcher_visual.pbix`, inspect its data-source settings and update local paths or database connections before refresh. Dashboard refresh was not validated during documentation preparation.

## Scale and checks

The inspected raw folder was 119,839,489 bytes and processed Parquet files 49,443,039 bytes. These folder measurements are not total disk or RAM requirements; allow extra room for intermediate files, PostgreSQL and indexes. Runtime has not been measured.

Notebook assertions, loader count checks and SQL verification exist; they are not a dedicated automated test suite. Fresh upstream data or changed dependency versions can change outputs or fail the snapshot checks. Do not suppress such failures without investigating them.

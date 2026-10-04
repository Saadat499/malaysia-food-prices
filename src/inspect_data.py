from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_ROOT / "data" / "raw"
DOCS_DIR = PROJECT_ROOT / "docs"

# Inspection month only; the final analysis period is undecided.
MONTH = "2026-09"

FILES = {
    "prices": f"pricecatcher_{MONTH}.parquet",
    "items": "lookup_item.parquet",
    "premises": "lookup_premise.parquet",
}


def load_tables():
    """Load the three local Parquet files."""
    tables = {}

    for name, filename in FILES.items():
        path = RAW_DIR / filename

        if not path.is_file():
            raise FileNotFoundError(f"Required file not found: {path}")

        tables[name] = pd.read_parquet(path)

    return tables


def profile_tables(tables):
    """Print column profiles and five sample rows."""
    for name, df in tables.items():
        print(f"\n--- {name}: {len(df):,} rows ---")
        print("Source file:", FILES[name])

        profile = pd.DataFrame({
            "dtype": df.dtypes.astype(str),
            "null_count": df.isna().sum(),
            "distinct_non_null": df.nunique(dropna=True),
        })

        print(profile.to_string())
        print("\nFirst five rows:")
        print(df.head(5).to_string(index=False))


def check_lookups(tables):
    """Check lookup keys and matching price records."""
    prices = tables["prices"]

    for name, key in [
        ("items", "item_code"),
        ("premises", "premise_code"),
    ]:
        lookup = tables[name]
        matched = prices[key].isin(lookup[key])

        print(f"\n--- {name}: lookup checks ---")
        print("Missing lookup keys:", lookup[key].isna().sum())
        print("Repeated keys beyond first:", lookup[key].duplicated().sum())
        print("Price records using -1:", prices[key].eq(-1).sum())
        print("Matched records:", f"{matched.sum():,}")
        print("Unmatched records:", f"{(~matched).sum():,}")
        print("Matched percentage:", f"{matched.mean():.2%}")

        unmatched_codes = (
            prices.loc[~matched, key]
            .drop_duplicates()
            .sort_values()
            .tolist()
        )
        print("Unmatched codes:", unmatched_codes)


def check_dates(prices):
    """Compare observed dates with the inspection month's calendar."""
    dates = pd.to_datetime(prices["date"], errors="raise")
    normalized = dates.dt.normalize()

    month_start = pd.Timestamp(f"{MONTH}-01")
    month_end = month_start + pd.offsets.MonthEnd(0)
    expected_dates = pd.date_range(month_start, month_end)

    observed_dates = pd.DatetimeIndex(normalized.dropna().unique())
    missing_dates = expected_dates.difference(observed_dates)
    outside_dates = observed_dates.difference(expected_dates)

    print("\n--- Date coverage ---")
    print("Earliest date:", dates.min())
    print("Latest date:", dates.max())
    print("Missing date values:", dates.isna().sum())
    print("Distinct observed dates:", len(observed_dates))
    print(
        "Expected dates without records:",
        missing_dates.strftime("%Y-%m-%d").tolist(),
    )
    print(
        "Dates outside inspection month:",
        outside_dates.strftime("%Y-%m-%d").tolist(),
    )

    daily_counts = (
        normalized.value_counts()
        .sort_index()
        .reindex(expected_dates, fill_value=0)
    )

    print("\nRecords per date:")
    print(daily_counts.to_string())
    print("Total records within inspection month:", daily_counts.sum())


def check_prices(prices):
    """Summarise prices and count potential duplicate records."""
    print("\n--- Price and duplicate checks ---")

    summary = prices["price"].quantile([0, 0.01, 0.50, 0.99, 1])
    summary.index = ["min", "p1", "median", "p99", "max"]
    print(summary.to_string())

    print("Zero prices:", prices["price"].eq(0).sum())
    print("Negative prices:", prices["price"].lt(0).sum())
    print("Exact duplicate rows beyond first:", prices.duplicated().sum())

    candidate_key = ["date", "premise_code", "item_code"]
    print(
        "Repeated date-premise-item combinations beyond first:",
        prices.duplicated(subset=candidate_key).sum(),
    )


def main():
    tables = load_tables()

    # Collect printed results in memory, then save and display them.
    buffer = StringIO()

    with redirect_stdout(buffer):
        print(f"PriceCatcher inspection: {MONTH}")
        print("Local-file inspection; no cleaning applied.")
        profile_tables(tables)
        check_lookups(tables)
        check_dates(tables["prices"])
        check_prices(tables["prices"])

    report = buffer.getvalue()

    DOCS_DIR.mkdir(parents=True, exist_ok=True)
    report_path = DOCS_DIR / "inspect_output.txt"
    report_path.write_text(report, encoding="utf-8")

    print(report, end="")
    print(f"\nReport saved: {report_path}")


if __name__ == "__main__":
    main()
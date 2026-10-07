from pathlib import Path
import os
from decimal import Decimal

import pandas as pd
import psycopg
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parent.parent
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"

load_dotenv(PROJECT_ROOT / ".env")

EXPECTED_RECORDS = 6_945_328

COLUMNS = [
    "date",
    "premise_code",
    "item_code",
    "price",
    "source_month",
    "is_supporting_period",
    "item_month_median",
    "price_to_median",
    "flag_low_price",
    "flag_high_price",
    "flag_extreme_price",
    "item_lookup_missing",
    "premise_lookup_missing",
]

COPY_SQL = """
COPY public.price_observations (
    date,
    premise_code,
    item_code,
    price,
    source_month,
    is_supporting_period,
    item_month_median,
    price_to_median,
    flag_low_price,
    flag_high_price,
    flag_extreme_price,
    item_lookup_missing,
    premise_lookup_missing
)
FROM STDIN
"""


def main():
    months = pd.period_range("2022-12", "2025-12", freq="M")
    files = [
        (str(month), PROCESSED_DIR / f"basket_{month}.parquet")
        for month in months
    ]

    missing = [str(path) for _, path in files if not path.is_file()]
    if missing:
        raise FileNotFoundError(
            "Missing prepared files:\n" + "\n".join(missing)
        )

    with psycopg.connect(
        dbname=os.getenv("PGDATABASE", "food_prices")
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_database()")
            if cursor.fetchone()[0] != "food_prices":
                raise ValueError("Connected to the wrong database")

            cursor.execute("SELECT COUNT(*) FROM public.items")
            if cursor.fetchone()[0] != 15:
                raise ValueError("Expected 15 loaded items")

            cursor.execute("SELECT COUNT(*) FROM public.premises")
            if cursor.fetchone()[0] != 2632:
                raise ValueError("Expected 2,632 loaded premises")

            cursor.execute(
                "SELECT COUNT(*) FROM public.price_observations"
            )
            if cursor.fetchone()[0] != 0:
                raise ValueError(
                    "Price table is not empty. No records were loaded."
                )

            total_loaded = 0
            expected_flags = 0
            expected_supporting = 0
            expected_unmatched = 0

            for month, path in files:
                print(f"{month}: loading...", flush=True)
                data = pd.read_parquet(path, columns=COLUMNS)

                if data[COLUMNS].isna().any().any():
                    raise ValueError(f"{month}: missing required values")

                if not data["source_month"].eq(month).all():
                    raise ValueError(f"{month}: source_month mismatch")

                data["date"] = pd.to_datetime(
                    data["date"], errors="raise"
                ).dt.date

                # Decimal preserves the displayed decimal value when
                # writing prices into PostgreSQL NUMERIC columns.
                for column in ["price", "item_month_median"]:
                    data[column] = data[column].map(
                        lambda value: Decimal(str(value))
                    )

                with cursor.copy(COPY_SQL) as copier:
                    for row in data.itertuples(index=False, name=None):
                        copier.write_row(row)

                cursor.execute(
                    """
                    SELECT COUNT(*)
                    FROM public.price_observations
                    WHERE source_month = %s
                    """,
                    (month,),
                )
                saved_count = cursor.fetchone()[0]

                if saved_count != len(data):
                    raise ValueError(f"{month}: row count mismatch")

                total_loaded += len(data)
                expected_flags += int(data["flag_extreme_price"].sum())
                expected_supporting += int(
                    data["is_supporting_period"].sum()
                )
                expected_unmatched += int(
                    data["premise_lookup_missing"].sum()
                )

                print(
                    f"{month}: loaded and counted {saved_count:,} rows",
                    flush=True,
                )

            if total_loaded != EXPECTED_RECORDS:
                raise ValueError(
                    f"Expected {EXPECTED_RECORDS:,} records; "
                    f"found {total_loaded:,}"
                )

            cursor.execute("""
                SELECT
                    COUNT(*),
                    COUNT(*) FILTER (WHERE flag_extreme_price),
                    COUNT(*) FILTER (WHERE is_supporting_period),
                    COUNT(*) FILTER (WHERE premise_lookup_missing)
                FROM public.price_observations
            """)
            actual = cursor.fetchone()
            expected = (
                total_loaded,
                expected_flags,
                expected_supporting,
                expected_unmatched,
            )

            if actual != expected:
                raise ValueError(
                    f"Database totals {actual} differ from files {expected}"
                )

        # Commit only after all files and totals pass.

    print("\nPrice load committed successfully.")
    print("Monthly files loaded:", len(files))
    print(f"Total records: {total_loaded:,}")
    print(f"Supporting records: {expected_supporting:,}")
    print(f"Flagged prices: {expected_flags:,}")
    print(f"Records missing premise details: {expected_unmatched:,}")


if __name__ == "__main__":
    main()
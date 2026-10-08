import csv
import os
from datetime import date
from pathlib import Path

import psycopg
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = PROJECT_ROOT / "docs" / "festival_windows_candidate.csv"


def parse_bool(value):
    value = value.strip().lower()
    if value not in {"true", "false"}:
        raise ValueError(f"Invalid boolean value: {value!r}")
    return value == "true"


def main():
    load_dotenv(PROJECT_ROOT / ".env")

    required_env = [
        "PGHOST", "PGPORT", "PGDATABASE", "PGUSER", "PGPASSWORD"
    ]
    missing = [name for name in required_env if not os.getenv(name)]
    if missing:
        raise ValueError(f"Missing environment variables: {missing}")

    rows = []

    with CSV_PATH.open(encoding="utf-8-sig", newline="") as file:
        for row in csv.DictReader(file):
            start = date.fromisoformat(row["start_date"])
            end = date.fromisoformat(row["end_date"])
            days = int(row["calendar_days"])

            if days != 14 or (end - start).days + 1 != days:
                raise ValueError(f"Invalid window dates: {row}")

            rows.append((
                int(row["year"]),
                row["festival"],
                row["window"],
                start,
                end,
                days,
                parse_bool(row["outside_analysis_period"]),
            ))

    keys = [row[:3] for row in rows]

    if len(rows) != 30:
        raise ValueError(f"Expected 30 windows; found {len(rows)}.")

    if len(set(keys)) != len(keys):
        raise ValueError("Duplicate year–festival–window combinations.")

    with psycopg.connect(
        host=os.environ["PGHOST"],
        port=os.environ["PGPORT"],
        dbname=os.environ["PGDATABASE"],
        user=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_database()")
            database = cursor.fetchone()[0]

            if database != "food_prices":
                raise ValueError(f"Wrong database: {database}")

            print("Database:", database)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS public.festival_windows (
                    year INTEGER NOT NULL,
                    festival TEXT NOT NULL,
                    window_name TEXT NOT NULL,
                    start_date DATE NOT NULL,
                    end_date DATE NOT NULL,
                    calendar_days INTEGER NOT NULL,
                    outside_analysis_period BOOLEAN NOT NULL,
                    PRIMARY KEY (year, festival, window_name),
                    CHECK (end_date >= start_date),
                    CHECK (calendar_days = end_date - start_date + 1),
                    CHECK (calendar_days = 14)
                )
            """)

            cursor.executemany("""
                INSERT INTO public.festival_windows (
                    year, festival, window_name,
                    start_date, end_date, calendar_days,
                    outside_analysis_period
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (year, festival, window_name)
                DO UPDATE SET
                    start_date = EXCLUDED.start_date,
                    end_date = EXCLUDED.end_date,
                    calendar_days = EXCLUDED.calendar_days,
                    outside_analysis_period =
                        EXCLUDED.outside_analysis_period
            """, rows)

            cursor.execute("""
                SELECT year, festival, window_name,
                       start_date, end_date, calendar_days,
                       outside_analysis_period
                FROM public.festival_windows
                ORDER BY year, festival, window_name
            """)
            saved = cursor.fetchall()

            if saved != sorted(rows):
                raise ValueError(
                    "Database windows do not match the CSV. "
                    "Changes will be rolled back."
                )

    # Printed only after the transaction commits successfully.
    print("Windows loaded and verified:", len(saved))
    print("Years:", sorted({row[0] for row in saved}))
    print("All windows contain 14 days: True")
    print("Festival window load committed successfully.")


if __name__ == "__main__":
    main()
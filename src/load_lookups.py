from pathlib import Path
import os

import pandas as pd
import psycopg
from psycopg import sql
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parent.parent
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"

load_dotenv(PROJECT_ROOT / ".env")

ITEM_COLUMNS = [
    "item_code", "item", "unit", "item_group", "item_category"
]

PREMISE_COLUMNS = [
    "premise_code", "premise", "state", "district",
    "premise_type", "premise_type_clean", "premise_lookup_missing"
]

BASKET_CODES = {
    1, 1111, 904, 918, 1589, 917, 129, 1564,
    1131, 94, 114, 103, 1431, 1555, 193,
}


def collect_lookups():
    item_parts = []
    premise_parts = []

    for month in pd.period_range("2022-12", "2025-12", freq="M"):
        path = PROCESSED_DIR / f"basket_{month}.parquet"

        data = pd.read_parquet(
            path,
            columns=ITEM_COLUMNS + PREMISE_COLUMNS,
        )

        item_parts.append(data[ITEM_COLUMNS].drop_duplicates())
        premise_parts.append(data[PREMISE_COLUMNS].drop_duplicates())

    items = pd.concat(item_parts, ignore_index=True).drop_duplicates()
    premises = pd.concat(
        premise_parts, ignore_index=True
    ).drop_duplicates()

    # A code must have one consistent set of lookup descriptions.
    for name, frame, key in [
        ("items", items, "item_code"),
        ("premises", premises, "premise_code"),
    ]:
        if frame[key].isna().any():
            raise ValueError(f"{name}: missing lookup codes")

        if frame[key].duplicated().any():
            raise ValueError(f"{name}: conflicting descriptions for a code")

    if set(items["item_code"]) != BASKET_CODES:
        raise ValueError("Item codes do not match the selected basket")

    if items[["item", "unit"]].isna().any().any():
        raise ValueError("An item is missing its name or unit")

    if premises["premise_lookup_missing"].isna().any():
        raise ValueError("A premise is missing its lookup status")

    premises = premises.rename(
        columns={"premise_lookup_missing": "lookup_missing"}
    )

    return (
        items.sort_values("item_code").reset_index(drop=True),
        premises.sort_values("premise_code").reset_index(drop=True),
    )


def copy_table(cursor, table_name, frame):
    statement = sql.SQL("COPY {} ({}) FROM STDIN").format(
        sql.Identifier("public", table_name),
        sql.SQL(", ").join(
            sql.Identifier(column) for column in frame.columns
        ),
    )

    # Convert pandas missing values to SQL NULL.
    records = frame.astype(object).where(frame.notna(), None)

    with cursor.copy(statement) as copier:
        for row in records.itertuples(index=False, name=None):
            copier.write_row(row)

    cursor.execute(
        sql.SQL("SELECT COUNT(*) FROM {}").format(
            sql.Identifier("public", table_name)
        )
    )
    count = cursor.fetchone()[0]

    if count != len(frame):
        raise ValueError(f"{table_name}: saved row count does not match")

    return count


def main():
    items, premises = collect_lookups()

    # psycopg also reads PGHOST, PGPORT, PGUSER and PGPASSWORD
    # from the environment loaded above.
    with psycopg.connect(
        dbname=os.getenv("PGDATABASE", "food_prices")
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_database()")
            database = cursor.fetchone()[0]

            if database != "food_prices":
                raise ValueError(f"Wrong database: {database}")

            # Refuse to append to tables that already contain records.
            for table in ["items", "premises", "price_observations"]:
                cursor.execute(
                    sql.SQL("SELECT COUNT(*) FROM {}").format(
                        sql.Identifier("public", table)
                    )
                )
                if cursor.fetchone()[0] != 0:
                    raise ValueError(
                        f"{table} is not empty. No records were loaded."
                    )

            item_count = copy_table(cursor, "items", items)
            premise_count = copy_table(cursor, "premises", premises)

        # Both tables commit together when this context exits successfully.

    print("Database:", database)
    print("Items loaded:", item_count)
    print("Premises loaded:", premise_count)
    print("Premises missing lookup details:",
          int(premises["lookup_missing"].sum()))
    print("Lookup load committed successfully.")


if __name__ == "__main__":
    main()
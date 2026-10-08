from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DOCS_DIR = PROJECT_ROOT / "docs"


def main():
    source = DOCS_DIR / "festival_price_comparison_2023_2025.csv"
    results = pd.read_csv(source)

    group_keys = ["festival", "target_window", "item_code", "state"]
    comparison_keys = ["year"] + group_keys

    if results[comparison_keys].isna().any().any():
        raise ValueError("Missing comparison identifiers.")

    if results.duplicated(comparison_keys).any():
        raise ValueError("Duplicate comparison rows.")

    if set(results["year"]) != {2023, 2024, 2025}:
        raise ValueError("Expected results for 2023, 2024 and 2025.")

    measure = "median_shop_change_pct"

    if results[measure].isna().any():
        raise ValueError("Missing price-change estimates.")

    # Put each year's result in a separate column.
    changes = results.pivot(
        index=group_keys,
        columns="year",
        values=measure,
    ).reindex(columns=[2023, 2024, 2025])

    # Retain only comparisons that qualify in all three years.
    complete = changes.dropna().copy()

    complete["pattern"] = "mixed"
    complete.loc[
        complete[[2023, 2024, 2025]].gt(0).all(axis=1),
        "pattern",
    ] = "increase_all_three"

    complete.loc[
        complete[[2023, 2024, 2025]].lt(0).all(axis=1),
        "pattern",
    ] = "decrease_all_three"

    complete.loc[
        complete[[2023, 2024, 2025]].eq(0).all(axis=1),
        "pattern",
    ] = "zero_all_three"

    complete = complete.rename(columns={
        2023: "change_pct_2023",
        2024: "change_pct_2024",
        2025: "change_pct_2025",
    }).reset_index()

    complete.columns.name = None

    item_details = results[
        ["item_code", "item", "unit"]
    ].drop_duplicates()

    if item_details["item_code"].duplicated().any():
        raise ValueError("Inconsistent item names or units.")

    complete = complete.merge(
        item_details,
        on="item_code",
        how="left",
        validate="many_to_one",
    )

    # Count locations in each pattern, separately for each item/window.
    summary_keys = ["festival", "target_window", "item_code"]

    summary = (
        complete.groupby(summary_keys + ["pattern"])
        .size()
        .unstack("pattern", fill_value=0)
        .reindex(
            columns=[
                "increase_all_three",
                "decrease_all_three",
                "zero_all_three",
                "mixed",
            ],
            fill_value=0,
        )
    )

    summary["eligible_locations"] = summary.sum(axis=1)
    summary = summary.reset_index()
    summary.columns.name = None

    summary = summary.merge(
        item_details,
        on="item_code",
        how="left",
        validate="many_to_one",
    )

    detail_path = DOCS_DIR / "festival_three_year_patterns.csv"
    summary_path = DOCS_DIR / "festival_three_year_summary.csv"

    complete.to_csv(detail_path, index=False)
    summary.to_csv(summary_path, index=False)

    print("Input comparisons:", len(results))
    print("Comparisons qualifying in all three years:", len(complete))

    print("\nPatterns across qualifying comparisons:")
    print(complete["pattern"].value_counts().to_string())

    print("\nTomato summary:")
    columns = [
        "festival",
        "target_window",
        "eligible_locations",
        "increase_all_three",
        "decrease_all_three",
        "zero_all_three",
        "mixed",
    ]
    print(
        summary.loc[summary["item_code"].eq(114), columns]
        .to_string(index=False)
    )

    print("\nSaved:", detail_path)
    print("Saved:", summary_path)


if __name__ == "__main__":
    main()
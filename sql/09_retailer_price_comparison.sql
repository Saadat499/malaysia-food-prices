-- Retailer comparisons within the same item, state and month.
-- Compare the five main retail categories.
-- Retain flagged prices; include an unflagged sensitivity median.

WITH retailer_month AS (
    SELECT
        DATE_TRUNC('month', o.date)::date AS month,
        o.item_code,
        p.state,
        p.premise_type_clean AS retailer_type,
        COUNT(*) AS observations,
        COUNT(DISTINCT o.date) AS recorded_days,
        COUNT(DISTINCT o.premise_code) AS premises,

        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY o.price::double precision
            )
        )::numeric AS median_price,

        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY o.price::double precision
            ) FILTER (
                WHERE NOT o.flag_extreme_price
            )
        )::numeric AS median_price_unflagged,

        COUNT(*) FILTER (
            WHERE o.flag_extreme_price
        ) AS flagged_records

    FROM public.price_observations AS o
    JOIN public.premises AS p
        ON o.premise_code = p.premise_code

    WHERE o.date >= DATE '2023-01-01'
      AND o.date < DATE '2026-01-01'
      AND NOT o.is_supporting_period
      AND p.state IS NOT NULL
      AND p.premise_type_clean IN (
          'Hypermarket',
          'Kedai Runcit',
          'Pasar Basah',
          'Pasar Mini',
          'Pasar Raya / Supermarket'
      )

    GROUP BY
        DATE_TRUNC('month', o.date)::date,
        o.item_code,
        p.state,
        p.premise_type_clean
),
eligible AS (
    SELECT *
    FROM retailer_month
    WHERE premises >= 5
      AND recorded_days >= 4
),
ranked AS (
    SELECT
        *,
        COUNT(*) OVER (
            PARTITION BY item_code, state, month
        ) AS retailer_types_compared,

        DENSE_RANK() OVER (
            PARTITION BY item_code, state, month
            ORDER BY median_price
        ) AS price_rank,

        MIN(median_price) OVER (
            PARTITION BY item_code, state, month
        ) AS lowest_retailer_median
    FROM eligible
)
SELECT
    r.month,
    r.item_code,
    i.item,
    i.unit,
    r.state,
    r.retailer_type,
    r.observations,
    r.recorded_days,
    r.premises,
    r.retailer_types_compared,
    ROUND(r.median_price, 2) AS median_price,
    ROUND(r.median_price_unflagged, 2) AS median_price_unflagged,
    r.flagged_records,
    ROUND(
        100.0 * (r.median_price_unflagged - r.median_price)
        / NULLIF(r.median_price, 0),
        2
    ) AS median_sensitivity_pct,
    r.price_rank,
    ROUND(
        100.0 * (r.median_price - r.lowest_retailer_median)
        / NULLIF(r.lowest_retailer_median, 0),
        2
    ) AS pct_above_lowest
FROM ranked AS r
JOIN public.items AS i
    ON r.item_code = i.item_code
WHERE r.retailer_types_compared >= 2
ORDER BY
    r.item_code,
    r.state,
    r.month,
    r.price_rank,
    r.retailer_type;
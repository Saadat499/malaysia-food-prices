-- Monthly state summaries, 2023–2025.
-- Primary median retains flagged prices.
-- The unflagged median is a sensitivity check.

WITH state_month AS (
    SELECT
        DATE_TRUNC('month', o.date)::date AS month,
        o.item_code,
        COALESCE(p.state, 'Unknown') AS state,
        COUNT(*) AS observations,
        COUNT(DISTINCT o.date) AS recorded_days,
        COUNT(DISTINCT o.premise_code) AS premises,

        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY o.price::double precision
        ) AS median_price,

        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY o.price::double precision
        ) FILTER (
            WHERE NOT o.flag_extreme_price
        ) AS median_price_unflagged,

        COUNT(*) FILTER (
            WHERE o.flag_extreme_price
        ) AS flagged_records

    FROM public.price_observations AS o
    LEFT JOIN public.premises AS p
        ON o.premise_code = p.premise_code

    WHERE o.date >= DATE '2023-01-01'
      AND o.date < DATE '2026-01-01'
      AND NOT o.is_supporting_period

    GROUP BY
        DATE_TRUNC('month', o.date)::date,
        o.item_code,
        COALESCE(p.state, 'Unknown')
)
SELECT
    s.month,
    s.item_code,
    i.item,
    i.unit,
    s.state,
    s.observations,
    s.recorded_days,
    s.premises,
    ROUND(s.median_price::numeric, 2) AS median_price,
    ROUND(
        s.median_price_unflagged::numeric, 2
    ) AS median_price_unflagged,
    s.flagged_records,
    ROUND(
        (
            100.0 * (s.median_price_unflagged - s.median_price)
            / NULLIF(s.median_price, 0)
        )::numeric,
        2
    ) AS median_sensitivity_pct
FROM state_month AS s
JOIN public.items AS i
    ON s.item_code = i.item_code
ORDER BY s.item_code, s.state, s.month;

-- Rank eligible states for each item and month.
-- Retain flagged prices in the main comparison.

WITH state_month AS (
    SELECT
        DATE_TRUNC('month', o.date)::date AS month,
        o.item_code,
        p.state,
        COUNT(*) AS observations,
        COUNT(DISTINCT o.date) AS recorded_days,
        COUNT(DISTINCT o.premise_code) AS premises,
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY o.price::double precision
            )
        )::numeric AS median_price
    FROM public.price_observations AS o
    JOIN public.premises AS p
        ON o.premise_code = p.premise_code
    WHERE o.date >= DATE '2023-01-01'
      AND o.date < DATE '2026-01-01'
      AND NOT o.is_supporting_period
      AND p.state IS NOT NULL
    GROUP BY
        DATE_TRUNC('month', o.date)::date,
        o.item_code,
        p.state
),
eligible AS (
    SELECT *
    FROM state_month
    WHERE premises >= 5
      AND recorded_days >= 4
),
ranked AS (
    SELECT
        *,
        COUNT(*) OVER (
            PARTITION BY item_code, month
        ) AS states_compared,
        DENSE_RANK() OVER (
            PARTITION BY item_code, month
            ORDER BY median_price
        ) AS price_rank,
        MIN(median_price) OVER (
            PARTITION BY item_code, month
        ) AS lowest_state_median
    FROM eligible
)
SELECT
    r.month,
    r.item_code,
    i.item,
    i.unit,
    r.state,
    r.observations,
    r.recorded_days,
    r.premises,
    r.states_compared,
    ROUND(r.median_price, 2) AS median_price,
    r.price_rank,
    ROUND(r.lowest_state_median, 2) AS lowest_state_median,
    ROUND(
        100.0 * (r.median_price - r.lowest_state_median)
        / NULLIF(r.lowest_state_median, 0),
        2
    ) AS pct_above_lowest
FROM ranked AS r
JOIN public.items AS i
    ON r.item_code = i.item_code
WHERE r.states_compared >= 2
ORDER BY r.item_code, r.month, r.price_rank, r.state;
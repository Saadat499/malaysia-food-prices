-- Monthly summaries for the main analysis period: 2023–2025.

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', date)::date AS month,
        item_code,
        COUNT(*) AS observations,
        COUNT(DISTINCT date) AS recorded_days,
        COUNT(DISTINCT premise_code) AS premises,
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY price::double precision
        ) AS median_price,
        AVG(price) AS mean_price,
        COUNT(*) FILTER (
            WHERE flag_extreme_price
        ) AS flagged_records
    FROM public.price_observations
    WHERE date >= DATE '2023-01-01'
      AND date < DATE '2026-01-01'
      AND NOT is_supporting_period
    GROUP BY
        DATE_TRUNC('month', date)::date,
        item_code
)
SELECT
    m.month,
    m.item_code,
    i.item,
    i.unit,
    m.observations,
    m.recorded_days,
    m.premises,
    ROUND(m.median_price::numeric, 2) AS median_price,
    ROUND(m.mean_price, 2) AS mean_price,
    m.flagged_records
FROM monthly AS m
JOIN public.items AS i
    ON m.item_code = i.item_code
ORDER BY m.item_code, m.month;
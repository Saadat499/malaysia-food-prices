-- Monthly median price changes for 2023–2025.
-- Retain flagged prices and round only the final results.

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', date)::date AS month,
        item_code,
        COUNT(*) AS observations,
        COUNT(DISTINCT date) AS recorded_days,
        COUNT(DISTINCT premise_code) AS premises,
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY price::double precision
            )
        )::numeric AS median_price
    FROM public.price_observations
    WHERE date >= DATE '2023-01-01'
      AND date < DATE '2026-01-01'
      AND NOT is_supporting_period
    GROUP BY
        DATE_TRUNC('month', date)::date,
        item_code
),
previous_month AS (
    SELECT
        *,
        LAG(month) OVER (
            PARTITION BY item_code ORDER BY month
        ) AS previous_month_date,
        LAG(median_price) OVER (
            PARTITION BY item_code ORDER BY month
        ) AS previous_median_price
    FROM monthly
)
SELECT
    p.month,
    p.item_code,
    i.item,
    i.unit,
    p.observations,
    p.recorded_days,
    p.premises,
    ROUND(p.median_price, 2) AS median_price,
    ROUND(p.previous_median_price, 2) AS previous_median_price,
    CASE
        WHEN p.previous_month_date =
             (p.month - INTERVAL '1 month')::date
        THEN ROUND(
            100.0 * (p.median_price - p.previous_median_price)
            / NULLIF(p.previous_median_price, 0),
            2
        )
    END AS monthly_change_pct
FROM previous_month AS p
JOIN public.items AS i
    ON p.item_code = i.item_code
ORDER BY p.item_code, p.month;
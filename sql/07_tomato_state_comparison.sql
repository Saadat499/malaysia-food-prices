-- Tomato case study: May–June 2024.
-- Compare all matched shops with the four-day sensitivity subset.
-- Flagged prices remain included.

WITH shop_month AS (
    SELECT
        premise_code,
        DATE_TRUNC('month', date)::date AS month,
        COUNT(DISTINCT date) AS recorded_days,
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY price::double precision
        ) AS median_price
    FROM public.price_observations
    WHERE item_code = 114
      AND date >= DATE '2024-05-01'
      AND date < DATE '2024-07-01'
    GROUP BY
        premise_code,
        DATE_TRUNC('month', date)::date
),
matched AS (
    SELECT
        may.premise_code,
        may.recorded_days AS may_days,
        june.recorded_days AS june_days,
        may.median_price AS may_price,
        june.median_price AS june_price,
        100.0 * (june.median_price - may.median_price)
            / NULLIF(may.median_price, 0) AS change_pct
    FROM shop_month AS may
    JOIN shop_month AS june
        ON may.premise_code = june.premise_code
    WHERE may.month = DATE '2024-05-01'
      AND june.month = DATE '2024-06-01'
),
samples AS (
    SELECT
        *,
        'all_matched' AS sample
    FROM matched

    UNION ALL

    SELECT
        *,
        'at_least_4_days' AS sample
    FROM matched
    WHERE may_days >= 4
      AND june_days >= 4
)
SELECT
    COALESCE(p.state, 'Unknown') AS state,
    s.sample,
    COUNT(*) AS matched_premises,
    COUNT(*) FILTER (
        WHERE s.june_price > s.may_price
    ) AS premises_with_increases,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE s.june_price > s.may_price
        ) / COUNT(*),
        1
    ) AS percent_with_increases,
    ROUND(
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY s.change_pct
            )
        )::numeric,
        2
    ) AS median_shop_change_pct
FROM samples AS s
LEFT JOIN public.premises AS p
    ON s.premise_code = p.premise_code
GROUP BY
    COALESCE(p.state, 'Unknown'),
    s.sample
ORDER BY state, s.sample;
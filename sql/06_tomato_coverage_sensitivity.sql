-- Explore the largest observed monthly increase:
-- tomatoes (114), May to June 2024.
-- Include shops with observations in both months.
-- Retain flagged prices.

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
)
SELECT
    COUNT(*) AS matched_premises,
    COUNT(*) FILTER (
        WHERE june_price > may_price
    ) AS premises_with_increases,
    COUNT(*) FILTER (
        WHERE june_price < may_price
    ) AS premises_with_decreases,
    COUNT(*) FILTER (
        WHERE june_price = may_price
    ) AS premises_unchanged,
    ROUND(
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY may_price
            )
        )::numeric, 2
    ) AS median_shop_price_may,
    ROUND(
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY june_price
            )
        )::numeric, 2
    ) AS median_shop_price_june,
    ROUND(
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY change_pct
            )
        )::numeric, 2
    ) AS median_shop_change_pct,
    MIN(may_days) AS minimum_may_days,
    MIN(june_days) AS minimum_june_days,
    COUNT(*) FILTER (
        WHERE may_days < 4 OR june_days < 4
    ) AS premises_with_fewer_than_4_days

FROM matched
WHERE may_days >= 4
  AND june_days >= 4;
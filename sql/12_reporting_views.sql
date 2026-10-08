-- Monthly median price changes for 2023–2025.
-- Retain flagged prices and round only the final results.

CREATE OR REPLACE VIEW public.v_monthly_price_trends AS
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

CREATE OR REPLACE VIEW public.v_monthly_state_prices AS
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

SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT item_code) AS items,
    COUNT(DISTINCT month) AS months,
    SUM(observations) AS total_observations,
    SUM(flagged_records) AS flagged_records
FROM public.v_monthly_state_prices;

-- Monthly retailer comparisons within each state.
CREATE OR REPLACE VIEW public.v_monthly_retailer_prices AS
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

-- Verify the retailer view.
SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT item_code) AS items,
    COUNT(DISTINCT month) AS months,
    COUNT(DISTINCT retailer_type) AS retailer_types,
    COUNT(*) FILTER (
        WHERE premises < 5
           OR recorded_days < 4
           OR retailer_types_compared < 2
    ) AS coverage_failures
FROM public.v_monthly_retailer_prices;

-- Festival comparisons using premises observed in both windows.
-- Supporting December 2022 observations are included where needed.

CREATE OR REPLACE VIEW public.v_festival_price_comparison AS
WITH window_observations AS (
    SELECT
        w.year,
        w.festival,
        w.window_name,
        o.item_code,
        p.state,
        o.premise_code,
        o.date,
        o.price
    FROM public.festival_windows AS w
    JOIN public.price_observations AS o
        ON o.date BETWEEN w.start_date AND w.end_date
    JOIN public.premises AS p
        ON o.premise_code = p.premise_code
    WHERE p.state IS NOT NULL
),
shop_prices AS (
    SELECT
        year,
        festival,
        window_name,
        item_code,
        state,
        premise_code,
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY price::double precision
            )
        )::numeric AS median_price,
        ARRAY_AGG(DISTINCT date) AS observed_dates
    FROM window_observations
    GROUP BY
        year, festival, window_name,
        item_code, state, premise_code
),
matched AS (
    SELECT
        t.year,
        t.festival,
        t.window_name AS target_window,
        t.item_code,
        t.state,
        t.premise_code,
        r.median_price AS reference_price,
        t.median_price AS target_price,
        r.observed_dates AS reference_dates,
        t.observed_dates AS target_dates,
        100.0 * (t.median_price - r.median_price)
            / NULLIF(r.median_price, 0) AS shop_change_pct
    FROM shop_prices AS t
    JOIN shop_prices AS r
        ON t.year = r.year
       AND t.festival = r.festival
       AND t.item_code = r.item_code
       AND t.state = r.state
       AND t.premise_code = r.premise_code
       AND r.window_name = 'reference'
    WHERE t.window_name <> 'reference'
),
matched_dates AS (
    SELECT
        year, festival, target_window, item_code, state,
        'reference' AS period,
        UNNEST(reference_dates) AS observed_date
    FROM matched

    UNION ALL

    SELECT
        year, festival, target_window, item_code, state,
        'target' AS period,
        UNNEST(target_dates) AS observed_date
    FROM matched
),
date_coverage AS (
    SELECT
        year,
        festival,
        target_window,
        item_code,
        state,
        COUNT(DISTINCT observed_date) FILTER (
            WHERE period = 'reference'
        ) AS matched_reference_days,
        COUNT(DISTINCT observed_date) FILTER (
            WHERE period = 'target'
        ) AS matched_target_days
    FROM matched_dates
    GROUP BY
        year, festival, target_window, item_code, state
),
price_summary AS (
    SELECT
        year,
        festival,
        target_window,
        item_code,
        state,
        COUNT(*) AS matched_premises,
        COUNT(*) FILTER (
            WHERE target_price > reference_price
        ) AS premises_with_increases,
        COUNT(*) FILTER (
            WHERE target_price < reference_price
        ) AS premises_with_decreases,
        COUNT(*) FILTER (
            WHERE target_price = reference_price
        ) AS premises_unchanged,
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY reference_price::double precision
            )
        )::numeric AS median_shop_reference_price,
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY target_price::double precision
            )
        )::numeric AS median_shop_target_price,
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY shop_change_pct::double precision
            )
        )::numeric AS median_shop_change_pct
    FROM matched
    GROUP BY
        year, festival, target_window, item_code, state
)
SELECT
    s.year,
    s.festival,
    s.target_window,
    s.item_code,
    i.item,
    i.unit,
    s.state,
    s.matched_premises,
    d.matched_reference_days,
    d.matched_target_days,
    s.premises_with_increases,
    s.premises_with_decreases,
    s.premises_unchanged,
    ROUND(
        100.0 * s.premises_with_increases
        / NULLIF(s.matched_premises, 0),
        2
    ) AS pct_premises_with_increases,
    ROUND(
        s.median_shop_reference_price, 2
    ) AS median_shop_reference_price,
    ROUND(
        s.median_shop_target_price, 2
    ) AS median_shop_target_price,
    ROUND(
        s.median_shop_change_pct, 2
    ) AS median_shop_change_pct
FROM price_summary AS s
JOIN date_coverage AS d
    USING (year, festival, target_window, item_code, state)
JOIN public.items AS i
    ON s.item_code = i.item_code
WHERE s.matched_premises >= 5
  AND d.matched_reference_days >= 4
  AND d.matched_target_days >= 4
ORDER BY
    s.year, s.festival, s.target_window, s.item_code, s.state;

-- Verify the festival view.
SELECT
    COUNT(*) AS comparisons,
    COUNT(DISTINCT year) AS years,
    COUNT(DISTINCT festival) AS festival_groups,
    COUNT(*) FILTER (
        WHERE matched_premises < 5
           OR matched_reference_days < 4
           OR matched_target_days < 4
    ) AS coverage_failures,
    COUNT(*) FILTER (
        WHERE premises_with_increases
            + premises_with_decreases
            + premises_unchanged <> matched_premises
    ) AS count_mismatches
FROM public.v_festival_price_comparison;

-- Compare each shop's median price in the reference and target windows.
-- Keep flagged prices in this main analysis.
-- Include December 2022 supporting records where the windows require them.

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
    FROM public.festival_windows w
    JOIN public.price_observations o
        ON o.date BETWEEN w.start_date AND w.end_date
    JOIN public.premises p
        ON o.premise_code = p.premise_code
    WHERE p.state IS NOT NULL
),

-- One row per shop, item and window.
shop_prices AS (
    SELECT
        year,
        festival,
        window_name,
        item_code,
        state,
        premise_code,
        (
            PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY price::double precision)
        )::numeric AS median_price,
        ARRAY_AGG(DISTINCT date) AS observed_dates
    FROM window_observations
    GROUP BY
        year, festival, window_name,
        item_code, state, premise_code
),

-- Keep shops observed in both windows for the same item.
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
    FROM shop_prices t
    JOIN shop_prices r
        ON t.year = r.year
        AND t.festival = r.festival
        AND t.item_code = r.item_code
        AND t.state = r.state
        AND t.premise_code = r.premise_code
        AND r.window_name = 'reference'
    WHERE t.window_name <> 'reference'
),

-- Count distinct dates across the matched shops collectively.
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
        COUNT(DISTINCT observed_date)
            FILTER (WHERE period = 'reference')
            AS matched_reference_days,
        COUNT(DISTINCT observed_date)
            FILTER (WHERE period = 'target')
            AS matched_target_days
    FROM matched_dates
    GROUP BY year, festival, target_window, item_code, state
),

-- Each matched shop contributes equally to these summaries.
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
            PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY reference_price::double precision)
        )::numeric AS median_shop_reference_price,
        (
            PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY target_price::double precision)
        )::numeric AS median_shop_target_price,
        (
            PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY shop_change_pct::double precision)
        )::numeric AS median_shop_change_pct
    FROM matched
    GROUP BY year, festival, target_window, item_code, state
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
        100.0 * s.premises_with_increases / s.matched_premises,
        2
    ) AS pct_premises_with_increases,
    ROUND(s.median_shop_reference_price, 2)
        AS median_shop_reference_price,
    ROUND(s.median_shop_target_price, 2)
        AS median_shop_target_price,
    ROUND(s.median_shop_change_pct, 2)
        AS median_shop_change_pct
FROM price_summary s
JOIN date_coverage d
    USING (year, festival, target_window, item_code, state)
JOIN public.items i
    ON s.item_code = i.item_code
WHERE s.matched_premises >= 5
    AND d.matched_reference_days >= 4
    AND d.matched_target_days >= 4
ORDER BY
    s.year, s.festival, s.target_window, s.item_code, s.state;
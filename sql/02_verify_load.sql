SELECT 'items' AS table_name, COUNT(*) AS row_count
FROM public.items

UNION ALL

SELECT 'premises', COUNT(*)
FROM public.premises

UNION ALL

SELECT 'price_observations', COUNT(*)
FROM public.price_observations;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE NOT is_supporting_period
    ) AS main_period_records,
    COUNT(*) FILTER (
        WHERE is_supporting_period
    ) AS supporting_records,
    COUNT(DISTINCT source_month) AS months,
    COUNT(DISTINCT item_code) AS items,
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date,
    COUNT(*) FILTER (
        WHERE flag_extreme_price
    ) AS flagged_prices,
    COUNT(*) FILTER (
        WHERE premise_lookup_missing
    ) AS missing_premise_details
FROM public.price_observations;
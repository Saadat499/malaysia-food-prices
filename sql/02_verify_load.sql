SELECT 'items' AS table_name, COUNT(*) AS row_count
FROM public.items

UNION ALL

SELECT 'premises', COUNT(*)
FROM public.premises

UNION ALL

SELECT 'price_observations', COUNT(*)
FROM public.price_observations;
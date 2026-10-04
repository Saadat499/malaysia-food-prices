\# Initial Data Inspection — September 2026



\## Date coverage

The downloaded snapshot contains 1,390,113 price records across

23 distinct dates, from 1 to 24 September 2026. There are no

observations for 16 September or 25–30 September.



This snapshot does not cover the full calendar month. I don't know 

why those dates are missing. Missing observations do

not mean prices were zero.



\## Collection volume

Record counts are much higher on 7, 14, and 21 September than

on surrounding dates. This shows variation in collection volume,

not necessarily changes in prices.



I need to investigate whether different items or premises were

recorded on those dates, because changing coverage could affect

price comparisons.



\## Lookup coverage

The item lookup matches 98.59% of price records. The remaining

19,580 records, or approximately 1.41%, contain 14 item codes

absent from the lookup. Their item descriptions cannot currently

be identified through this lookup.



All premise codes match the premise lookup. An outdated item

lookup is a possible explanation for the unmatched codes, but

the cause has not been confirmed.



\## Keys and duplicates

Both lookup tables have unique, non-missing code columns. This

means duplicate lookup keys will not multiply rows during joins.



The price data contains no exact duplicate rows or repeated

date–premise–item combinations in this snapshot.



\## Price validity

There are no missing, zero, or negative prices. However, positive

prices are not automatically valid.



Same-item comparisons revealed suspicious extremes. For example,

BOH tea has a median price of 14.30 and a maximum of 1,430.00.

Decimal-entry errors are possible, but I have not verified the

intended values and have not corrected them.



\## Current limitations and next steps

These findings apply only to the downloaded September snapshot.

They do not establish data quality or coverage for other months.



No records have been removed or prices changed. The final food

basket, analysis period, and cleaning rules remain undecided.

Next, I will assess item choices and historical coverage before

finalising the analysis scope.


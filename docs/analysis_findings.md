\# Analysis findings



\## Scope and interpretation



The analysis covers 15 selected food items during 2023–2025.

December 2022 records support the Chinese New Year 2023 reference window.



Prices refer to each item's specified product and unit.

The dataset represents monitored premises, not a consumption-weighted

national price index. No combined basket cost or forecast is calculated.



\## Monthly price movements



Tomato's pooled observation median rose from RM3.90 in May 2024

to RM6.99 in June 2024, an increase of 79.23%.



Among 1,189 shops observed in both months, the median individual

shop percentage change was 79.03%.



Requiring at least four observed dates in each month retained

907 shops. Their median individual percentage change was 96.99%,

and 790 shops recorded increases.



The direction persisted under this coverage check, but the magnitude

was sensitive to which shops qualified. This was an exploratory

case study selected after inspecting the monthly changes.



\## State and retailer comparisons



State rankings compare the same item and month.

Retailer rankings compare the same item, state and month.



Eligible groups require at least five premises and four observed

dates collectively. Rankings require at least two eligible groups

and allow ties.



For standard chicken in Johor in December 2025, median prices were:



\- Hypermarket: RM7.95/kg.

\- Supermarket: RM8.09/kg.

\- Mini market: RM8.60/kg.

\- Grocery shop: RM9.20/kg.

\- Wet market: RM9.60/kg.



This example does not establish that one retailer type is always

cheapest. Shop composition, districts and observation frequency differ.



The retailer comparison contains 14 items. Beef, code 1431,

had no qualifying comparison between two retailer types within

the same state and month under these rules.



\## Festive comparisons



Each shop's median price in a target window is compared with its

median in the corresponding reference window. Shop percentage

changes are then summarised using their median.



Comparisons require at least five shops observed in both windows

and at least four distinct dates in each window collectively

among those matched shops.



There were 3,259 qualifying annual comparisons.

Of these, 957 item–location–festival–window combinations qualified

in all three years:



\- Zero reported median change in every year: 531.

\- Mixed patterns: 383.

\- Decrease in every year: 36.

\- Increase in every year: 7.



Classification uses percentage changes exported to two decimal places.

A zero median change does not mean every shop's price was unchanged.

The matched shops can differ between years.



Tomatoes showed decreases during the Raya lead-up in all three

years in 13 of 15 eligible locations. After Raya, decreases occurred

in all three years in 14 of 15 eligible locations.



Both comparisons use the pre-Ramadan reference window.



Prawns showed increases after Chinese New Year in all three years

in 5 of 15 eligible locations.



\## Sensitivity to flagged prices



Flagged observations remain in the main analysis because an unusual

price is not automatically an error.



Excluding flagged prices retained all 3,259 festive comparisons.

Matched-shop counts changed in one comparison.



Two reported median shop percentage changes changed:



\- Garlic, Kedah, after Raya 2025: -5.67% to -4.78%.

\- Grade C eggs, Negeri Sembilan, after Deepavali 2025:

&#x20; -5.45% to -5.16%.



The largest difference was 0.89 percentage points.

No reported direction changed between increase, decrease and zero.



\## Limitations and practical implications



Coverage varies by item, location, retailer type and period.

Missing dates are not treated as zero prices.



The current premise lookup may not reflect every historical change

in retailer classification or location.



Matching shops reduces changes in shop composition within each

festive comparison, but does not control for seasonal supply,

promotions, policy changes or other influences.



These are descriptive associations, not causal festival effects.

Three years provide limited evidence of recurring patterns.



Consumers can use item-specific local comparisons as a starting

point, but should check current prices and account for travel costs.

The results do not justify a blanket recommendation to buy before

every festival or always choose a particular retailer type.



\## Reproducibility



SQL files contain the monthly, state, retailer and festive analyses.

The unflagged festive query provides the sensitivity comparison.



src/summarise\_festival\_patterns.py generates the three-year

pattern detail and summary from the main festive comparison CSV.



Supporting results are saved in docs/.


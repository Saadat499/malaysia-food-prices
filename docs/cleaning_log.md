\# Cleaning Log



\## 001 — Premise-type whitespace



Date: 2026-10-06



Issue:

The premise lookup contains both "Pasar Basah" and "Pasar Basah ",

which differ by a trailing space.



Action:

Removed leading and trailing whitespace using .str.strip() in a

new working column named premise\_type\_clean.



Verification:

\- 338 labels changed.

\- Distinct non-null categories decreased from 13 to 12.

\- The combined Pasar Basah category contains 360 premises.

\- One missing premise type remains missing.

\- No rows were removed.



Preservation:

The original premise\_type column and downloaded Parquet file remain

unchanged. This transformation currently exists in the notebook's

working DataFrame and must be included in the cleaning pipeline.



No other category names were combined.

## Review of recurring low-price flags



Reviewed 270 flagged observations covering onions in May 2024

and potatoes in November 2025.



Of these, 269 observations occurred at MYDIN branches:

\- 108 onion observations at 0.99 across 15 branches.

\- 161 potato observations at 0.49 across 17 branches.



The prices occurred during similar dates across branches.

This is consistent with coordinated promotional pricing,

but no promotion has been independently confirmed.



One potato observation at 0.30 at BATARAS remains unresolved.



Decision: retain all 270 observations with their screening flags.

Do not correct or exclude prices solely because they fall outside

the item-month median screening thresholds.



Records removed by this review: 0.

Price values changed: 0.



\## Duplicate removal and price review



Removed 31 exact duplicate rows from the December 2022 supporting

data. No repeated date–premise–item keys remained.



Remaining records: 6,945,328.

Original raw files were preserved.



Flagged 587 observations priced below 0.2 times or above 5 times

their item-month median. This is a review rule, not proof of error.



Five observations were separately documented as suspected recording

errors after comparison with nearby dates at the same premise.

Their correct replacement prices have not been established.



Working policy:

\- Preserve recorded prices and retain screening flags.

\- Retain unresolved low-price clusters; promotions are unconfirmed.

\- Do not automatically correct decimals, cap prices or delete flags.

\- Use medians as the primary descriptive price summary.

\- Compare results with and without flagged observations.



Excluding all 587 flags changed none of the 555 item-month medians.

The largest absolute monthly mean change was 3.119%.



These checks do not establish accuracy or national representativeness.

State, retailer and festive comparisons require separate checks.


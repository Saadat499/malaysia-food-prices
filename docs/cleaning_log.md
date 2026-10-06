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


\# Analysis Decisions



\## Provisional basket



Status: 15 items selected, pending historical coverage checks.



This basket covers selected household food ingredients and packaged

essentials. It is not intended to represent Malaysia's 15 most-consumed

foods. Items will be analysed separately using their item codes and

listed units.



| Code | Item | Unit | Reason for inclusion |

|---|---|---|---|

| 1 | AYAM BERSIH - STANDARD | 1kg | Chicken protein staple |

| 1111 | TELUR AYAM GRED C | 30 biji | Eggs with a defined grade and pack size |

| 904 | BERAS SUPER CAP RAMBUTAN 5% (IMPORT) | 10 kg | Rice product observed in all 36 candidate months |

| 1589 | GULA PUTIH BERTAPIS KASAR (PELBAGAI JENAMA) | 1kg | Sugar for household cooking |

| 917 | TEPUNG GANDUM NGP (BERBUNGKUS, CAP SAUH) | 1kg | Wheat flour with stronger historical coverage |

| 94 | CILI MERAH - MINYAK | 1kg | Chilli cooking ingredient |

| 114 | TOMATO | 1kg | Fresh vegetable |

| 103 | SANTAN KELAPA SEGAR (BIASA) | 1kg | Coconut milk for cooking |

| 1431 | DAGING LEMBU TEMPATAN (BAHAGIAN 1 DAGING PAHA (KECUALI BATANG PINANG - TENDERLOIN) | 1kg | Specified local beef cut with broader historical coverage |

| 1555 | UDANG PUTIH/VANNAMEI (TERNAK) (ANTARA 41 HINGGA 60 EKOR SEKILOGRAM) | 1kg | Seafood with a specified size range |

| 193 | SARDIN CAP KING CUP (SOS TOMATO) | 425 g | Packaged fish product |



\## Provisional basket revision



Replaced rice 992 with 904, flour 1593 with 917, and beef 1370

with 1431 after checking historical coverage for January 2023

through December 2025.



All three replacements have observations in all 36 months.

Selections were based on coverage, not observed festive price effects.

These are distinct products; their price histories will not be spliced

together with those of the original selections.



The basket and analysis period remain provisional pending geographic

and festive-window coverage checks.



\## Selection principles



\- Fifteen items is a manageable project scope, not a statistical standard.

\- Different grades, brands, pack sizes, and varieties will not be

&#x20; combined without justification.

\- Observation counts indicate monitoring coverage, not consumption.

\- Items may be replaced if coverage is insufficient. Replacements will

&#x20; not be chosen because they show stronger festive price effects.

\- No combined basket cost will be calculated unless quantities and a

&#x20; calculation method are defined.



\## Unmatched historical premise



Among the selected basket records for 2023–2025, 21 records

reference premise\_code 20927, which is absent from the saved

premise lookup.



The records occur on 5, 13, and 19 February 2024.

Details are saved in historical\_unmatched\_premise\_records.csv.



Preserve these records and flag their geographic and premise-type

information as unknown. Exclude them from comparisons requiring

those attributes unless a verified lookup resolves the code.

Do not infer a location or delete the raw records.



This is a planned handling rule; no cleaning has been applied.





\## Still to decide



\- Final basket after coverage checks.

\- Analysis period.

\- Official festive calendar.

\- Comparison windows and coverage requirements.

\- Statistical methods and forecast evaluation plan.



\## Candidate festive comparison design



Status: proposed for coverage assessment, before price-effect analysis.



All windows use each year's verified Malaysian festival dates.

Window boundaries are inclusive.



Chinese New Year and Deepavali:

\- Reference: days -28 to -15.

\- Lead-up: days -14 to -1.

\- After: days +2 to +15.

\- Days 0 and +1 are excluded consistently.

\- The reference window is not assumed to be free of festive influence.



Ramadan and Aidilfitri:

\- Reference: 14 days before the first fasting day.

\- Early Ramadan: first 14 fasting days.

\- Raya lead-up: 14 days before Aidilfitri.

\- After Raya: days +2 to +15 after Aidilfitri.

\- Late Ramadan is not treated as a non-festive Raya baseline.



Candidate eligibility rules for each pair of windows:

\- At least 4 distinct observed dates per window.

\- At least 5 distinct premises per window.

\- At least 5 premises observed in both windows.

\- State information must be known.

\- Missing or insufficient coverage produces an unavailable comparison,

&#x20; not a zero price or an automatically imputed price.



These are project screening rules, not statistical guarantees.

Flag overlaps with other festival windows and incomplete source coverage.

Reassess eligibility after cleaning.



\## Retailer comparison scope



Main candidate retailer types:

\- Hypermarket

\- Kedai Runcit

\- Pasar Basah

\- Pasar Mini

\- Pasar Raya / Supermarket



Compare the same item and listed unit within the same state and

period. National retailer counts do not establish local coverage.



Chicken has observations in all five categories across all 36 months.

Retain these categories as candidates pending local coverage checks.



Local beef (1431) is predominantly observed in wet markets.

Supermarket coverage is much smaller, and other retailer categories

are sparse. Do not present an unrestricted five-category beef

comparison. Assess wet-market versus supermarket comparisons only

where both have sufficient local support.



Exclude records with unknown retailer type from retailer comparisons.

Keep wholesale observations separate from the main retail comparison.

Categories without selected-item observations receive no price estimate.



These decisions concern coverage, not price differences.

Reassess eligibility after cleaning.


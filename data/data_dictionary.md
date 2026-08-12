# Data Dictionary — Xóm Air Review Dataset

Source: [Xóm Data — Skytrax](https://dataset.xomdata.com/datasets/schema/skytrax)

---

## Document Scope

This document describes the **data structure** and the **processing decisions** applied.

|||
|---|---|
|**Raw Data**|The raw `airline_reviews` is over **150 MB** — not included in the repo due to size|
|**Data in Repo**|`data/processed/airline_reviews_PBI_Master_Optimized_V4.csv` (30.5 MB) — the cleaned version, used for all analysis and dashboard|
|**The other four tables**|Raw versions, fully included in the repo|

> ⚠️ Because the main table in the repo is the **processed version**, any statistics on missing values in text columns reflect the results of the cleaning process, not the source data. Therefore, this document focuses on the **schema and processing rationale**, rather than listing post-processing statistics.

---

## Schema Diagram

```
airlines (595)  ──┬── airline_reviews  (154,126)   ← main analysis table
                  ├── lounge_reviews   (5,087)
                  └── seat_reviews     (3,766)

airports (1,004) ──── airport_reviews  (49,505)
```

**The four review tables are independent** — there is no linking key for a passenger across multiple tables. The only join keys are `airline_id` and `airport_id`.

⚠️ `lounge_reviews.airport` is **free text**, not matching the `airports` dimension table. Cannot be joined.

|Table|Rows|In Repo|
|---|---|---|
|`airline_reviews`|154,126|Processed version (V4)|
|`airport_reviews`|49,505|Raw|
|`lounge_reviews`|5,087|Raw|
|`seat_reviews`|3,766|Raw|
|`airlines`|595|Raw|
|`airports`|1,004|Raw|

---

## General Conventions

|Convention|Meaning|
|---|---|
|Rating columns|Scale **1–5**, higher is better|
|**Null in rating columns**|**"Passenger did not rate this criterion" — NOT a score of 0.** Reviewers only rate what they care about|
|`verify`|`1` = verified flight evidence · `0` = unverified|
|`recommended`|`1` = will recommend · `0` = won't. **Target variable** of the ML model|
|`date_submitted`|Date review was submitted — **primary time axis**|
|`date_visit` / `date_flown`|Actual experience date — highly missing, not used as time axis|
|`updated_at`|Data extraction timestamp, no analytical meaning|
|`customer_name`|Anonymized with pseudonyms|
|`"Unknown"`|**Missing value filled during the cleaning step — not a category.** Only appears in `airline_reviews`|

---

## `airlines` — Dimension

**Grain**: 1 row = 1 airline · 595 rows

|Column|Type|Description|
|---|---|---|
|`airline_id`|INT|Primary Key|
|`airline_name`|STRING|Airline name|

> `airline_id = 419` is named **`"Read more"`** — a data scraping error, see defect **D1**. Only **577 / 595** airlines have reviews; the remaining 18 do not appear in any table.

---

## `airports` — Dimension

**Grain**: 1 row = 1 airport · 1,004 rows

|Column|Type|Description|
|---|---|---|
|`airport_id`|INT|Primary Key|
|`airport_name`|STRING|Airport name|

---

## `airline_reviews` — Main Fact

**Grain**: 1 row = 1 flight review · 154,126 rows × 26 columns **Timeframe**: 2009 → 2026 · **577 airlines** · 100% foreign key integrity

### Identification and Time

|Column|Type|Description|
|---|---|---|
|`review_id`|INT|Primary Key|
|`airline_id`|INT|FK → `airlines`|
|`verify`|INT|1 = verified flight evidence|
|`date_submitted`|DATE|Review submission date|
|`recommended`|INT|**Target variable**|

### Demographics and Journey

|Column|Type|Description|
|---|---|---|
|`nationality`|STRING|Nationality, **free-text field**|
|`type_of_traveller`|STRING|Solo Leisure · Couple Leisure · Family Leisure · Business|
|`seat_type`|STRING|Economy · Premium Economy · Business · First|
|`aircraft`|STRING|Aircraft type|
|`origin_city` · `origin_airport`|STRING|Origin|
|`destination_city` · `destination_airport`|STRING|Destination|
|`transit_city` · `transit_airport`|STRING|Transit point · `"Direct Flight"` if non-stop|

### Seven Service Rating Columns — 1–5 scale

|Column|Description|
|---|---|
|`value_for_money`|Value for money — **an overall verdict, not a service attribute**. See note below|
|`ground_service`|Ground procedures: check-in, boarding, baggage|
|`seat_comfort`|Seat comfort|
|`cabin_staff_service`|Flight attendant service|
|`food_and_beverages`|Food and beverages|
|`inflight_entertainment`|Inflight entertainment|
|`wifi_and_connectivity`|Wifi and connectivity|

**Unrated rate** — this is real data, not filled during the cleaning step, and itself is a finding:

|Column|Overall|Verified Reviews Only|
|---|---|---|
|`value_for_money`|0.2%|**0.0%**|
|`ground_service`|26.8%|**4.1%**|
|`seat_comfort`|9.1%|7.9%|
|`cabin_staff_service`|9.3%|8.5%|
|`food_and_beverages`|27.4%|31.8%|
|`inflight_entertainment`|41.0%|46.0%|
|**`wifi_and_connectivity`**|**73.3%**|**62.7%**|

> **Why this table matters**: Passengers only rate what they care about. `value_for_money` is rated by almost everyone; `wifi_and_connectivity` is left blank by nearly two-thirds. This disparity is the foundation of Finding 1 in the README — wifi is the least rated, has the lowest average score, and is the least influential on the recommendation decision.

> **Note on `value_for_money`**: The other six columns describe _what the airline provides_; this column describes _what the passenger concludes after considering everything_. Therefore, it is excluded from the main ML model. Full reasoning in `P2-GIAI-THICH-VALUE-FOR-MONEY.md`.

### Four Derived Fields — created during cleaning

|Column|Type|Description|
|---|---|---|
|`sentiment_label`|STRING|Positive · Negative · Neutral — from VADER|
|`sentiment_score`|FLOAT|VADER compound score, range −1 → +1|
|`data_era`|STRING|Historical (Pre-2015) · Modern (2015–Present)|
|`data_era_covid`|STRING|Pre Covid · Covid · After Covid|

---

## `airport_reviews` — Fact (raw)

**Grain**: 1 row = 1 airport review · 49,505 rows × 20 columns · 2002 → 2026

|Group|Columns|
|---|---|
|Identification|`review_id` · `airport_id` · `verify` · `recommended`|
|Time|`date_submitted` · `date_visit`|
|Demographics|`customer_name` · `nationality` · `type_of_traveller` · `experience_at_airport` _(Arrival · Departure · Arrival and Departure · Transit)_|
|1–5 Ratings|`queuing_times` · `terminal_cleanliness` · `terminal_seating` · `terminal_signs` · `food_beverages` · `airport_shopping` · `airport_staff` · `wifi_connectivity`|
|Other|`review` _(text)_ · `updated_at`|

> Same pattern as `airline_reviews`: criteria that are **mandatory to experience** (queuing, terminal cleanliness) are rated the most; wifi is left blank the most.

---

## `lounge_reviews` — Fact (raw)

**Grain**: 1 row = 1 lounge review · 5,087 rows × 21 columns · 2006 → 2026

|Group|Columns|
|---|---|
|Identification|`review_id` · `airline_id` · `verify` · `recommended`|
|Time|`date_submitted` · `date_visit`|
|Lounge Desc|`lounge_name` · `airport` ⚠️ · `type_of_lounge`|
|Demographics|`nationality` · `type_of_traveller` ⚠️|
|1–5 Ratings|`comfort` · `cleanliness` · `bar_and_beverages` · `catering` · `washrooms` · `wifi_connectivity` · `staff_service`|
|Other|`review`|

> Rating columns in this table are almost fully populated — a lounge is a short and complete experience, easier to evaluate holistically than a flight.

---

## `seat_reviews` — Fact (raw)

**Grain**: 1 row = 1 seat review · 3,766 rows × 26 columns

|Group|Columns|
|---|---|
|Identification|`review_id` · `airline_id` · `verify` · `recommended`|
|Time|`date_submitted` ⚠️ · `date_flown`|
|Seat Desc|`seat_type` · `aircraft_type` · `seat_layout` _(e.g. `3x3`)_ · `type_of_traveller`|
|Ratings — all classes|`seat_legroom` · `seat_recline` · `seat_width` · `aisle_space` · `seat_storage` · `power_supply` · `viewing_tv_screen`|
|Ratings — **lie-flat seats only**|`sleep_comfort` · `sitting_comfort` · `seat_bed_width` · `seat_bed_length` · `seat_privacy`|

> **The last five columns are blank in most rows, and this is not an error.** They only apply to lie-flat seats in Business/First class. Any analysis using them must pre-filter by `seat_type`.

---

## Data Processing Decisions

Applied to `airline_reviews` when creating V4.

### X1. Drop `review` column after extraction

|||
|---|---|
|**Action**|Run VADER for sentiment and LDA for topics, then **completely delete the text column**|
|**Why**|Review content takes up almost the entire file size. After extraction, useful information is stored in `sentiment_label` and `sentiment_score`|
|**Result**|**>150 MB → 30.5 MB**, light enough to host on GitHub and for Power BI to process smoothly|
|**Trade-off**|Cannot read the original text from the V4 file. Must go back to raw data for new text analysis|

### X2. Drop pre-2009 data

|||
|---|---|
|**Action**|Only keep reviews from 2009 onwards|
|**Why**|Before 2009 there were only a few dozen reviews per year — too sparse to draw trendlines, yet they stretch the time axis on all charts|
|**Trade-off**|Lost early history. Doesn't affect any conclusions as the sample size is too small|

### X3. Fill missing values in **text columns** with `"Unknown"`

|||
|---|---|
|**Action**|`nationality` · `type_of_traveller` · `aircraft` · `origin_city` · `origin_airport` · `destination_city` · `destination_airport` · `seat_type` → replace nulls with `"Unknown"`; `transit_city` · `transit_airport` → replace with `"Direct Flight"`|
|**Why**|Power BI handles slicers and relationships more stably when there are no nulls in text columns|
|**⚠️ Warning**|**`"Unknown"` is a missing value, not a category.** Must be filtered out before grouping — otherwise, "Unknown" will appear as a nationality or aircraft type on charts|

### X4. **Keep** missing values in rating columns

|||
|---|---|
|**Action**|The seven service rating columns are **not** filled — null remains null|
|**Why**|Null means "passenger did not rate this criterion", not "rated 0". Filling with 0 would make wifi look like an industry disaster instead of something nobody cares about; filling with the mean would erase the very discovery of Finding 1|
|**Trade-off**|The ML model must use `.dropna()`, losing two-thirds of the sample. See section below|

### X5. Add four derived fields

|Field|Creation Method|Used Where|
|---|---|---|
|`sentiment_label` · `sentiment_score`|VADER on `review` column before dropping|Negative topic analysis|
|`data_era`|Split at 2015|Era comparison|
|`data_era_covid`|Split around Covid timeline|Industry recovery charts|

Pre-calculated in Python instead of writing DAX — keeps the Power BI model light and responsive at 154k rows scale.

---

## Identified Data Errors

|ID|Error|Table|Scale|Treatment|
|---|---|---|---|---|
|**D1**|**`airline_id = 419` is named `"Read more"`** — button text was recorded as airline name during scraping|`airlines` · `airline_reviews`|**6,700 rows (4.3%)**, ranked 54/72 at threshold 200|**Excluded from all airline-level analysis.** Sits mid-table so it doesn't appear in top/bottom 10|
|**D2**|**Bias by review completeness** — reviews listing `aircraft` recommend **55.6%**, those without only **15.0%**|`airline_reviews`|gap of **+40.6 points**|Not an insight about fleets but about **review writing behavior**: satisfied people write in more detail. All charts by `aircraft` must use a reference line specific to the group that listed it|
|**D3**|`nationality` is free-text, contains noisy values _(e.g., `flt. 93`)_|All review tables|~|Only analyze common groups|
|**D4**|`type_of_traveller` only has **one unique value** (`Business`)|`lounge_reviews`|5,087|Useless column — do not use for grouping|
|**D5**|`airport` is free-text, does not match `airports` dimension|`lounge_reviews`|5,087|Cannot join|
|**D6**|`date_submitted` = `1970-01-01` — Unix epoch sentinel value, not a real date|`seat_reviews`|~|Exclude or set to null|
|**D7**|`updated_at` only has a single unique value|3 raw tables|100%|Exclude from analysis|
|**D8**|18/595 airlines have no reviews|`airlines`|18 rows|Normal, no action needed|

---

## ML Model Dataset

|Filtering Step|Remaining Rows|
|---|---|
|Total|154,126|
|`verify == 1` only|61,965|
|`.dropna()` on seven ratings|**20,644**|

**20,644 / 61,965 = 33.3%.** Two-thirds of verified reviews are excluded because they didn't rate all seven criteria — mainly due to `wifi_and_connectivity` and `inflight_entertainment`.

This is a limitation that must be stated in the README: the group that bothers to rate all seven criteria might be **biased** — pickier reviewers, or more extreme experiences than average.

---

## Derived Fields used in Power BI

|Field|Source|Purpose|
|---|---|---|
|`% Recommended`|`SUM(recommended) / COUNT(*)`|Metric close to NPS|
|`Inflight Experience Score`|Average of inflight ratings|X-axis of CX matrix|
|`Lounge Score`|Average of lounge ratings|Y-axis of CX matrix|
|`Airlines Qualified Flag`|`[Total Reviews] >= [Review Threshold]`|Exclude airlines with too few reviews from rankings|
|Minimum Review Threshold|User-selected parameter|Default 200 → 72 airlines, covering 77.6% of reviews|

Full documentation for 91 measures: [`powerbi/dax_measures.md`](https://claude.ai/powerbi/dax_measures.md)

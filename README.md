# Airline Customer Experience Intelligence | Power BI, Python, SQL

![Dashboard Overview](images/dashboard/01_industry_command_center.png)

**Author:** Lương Thế Kiện
**Date:** August 2026
**Tools Used:** Power BI · Python (scikit-learn, NLTK) · SQL (BigQuery)

## 📑 Table of Contents

1. [📌 Background & Overview](#-background--overview)
2. [📂 Dataset Description & Data Structure](#-dataset-description--data-structure)
3. [🧠 Design Thinking Process](#-design-thinking-process)
4. [📊 Key Insights & Visualizations](#-key-insights--visualizations)
5. [🔎 Final Conclusion & Recommendations](#-final-conclusion--recommendations)

---

## 📌 Background & Overview

### 📖 What is this project about?

**Xóm Air** is a customer-experience consultancy for the aviation industry. Its clients are airlines, airport groups and alliances who want to know what passengers actually think — not what satisfaction surveys tell them. To answer that, Xóm Air maintains a repository of passenger-written reviews scraped from independent review platforms.

The commercial problem is that everyone in the industry reacts to whatever passengers shout about loudest. Wifi complaints are visible, quotable and easy to put on a slide, so wifi gets budget. Nobody had tested whether the loudest complaint is the one that changes behaviour. Meanwhile, client airlines were benchmarking themselves against public review scores without knowing that roughly 60% of those scores come from reviews with no proof the flight ever happened.

This analysis covers the flight leg — **154,126 airline reviews across 493 carriers, 2009 to 2026**.

### 👤 Who is this project for?

- **VP Customer Experience (client airline)** — to see which service attributes actually move loyalty, and where the gap between current performance and business impact is widest.
- **Chief Insights Officer (Xóm Air)** — to establish a benchmark clients can trust, rather than one inflated by unverified reviews.
- **Head of Product, Cabin** — to prioritise hardware and service investment against what passengers weigh most heavily.
- **Marketing Director (client airline)** — to understand how business and leisure travellers differ, and which segment carries the remaining headroom.

### ❓ Business Questions

- Which service attributes are genuinely associated with a passenger's decision to recommend — and which only *appear* to matter?
- What do passengers complain about most, and does that overlap with what drives loyalty?
- Which airlines lead and which lag, on which specific criteria?
- How far apart are verified and unverified reviews — and what does that say about the reliability of public rankings?
- Do business and leisure travellers behave differently, and does that pattern hold for every carrier?

### 🎯 Project Outcome

- Identified **ground service** as the leading actionable driver of recommendation (23.08%), against **wifi** at 0.52% — despite wifi and entertainment dominating the complaint narrative.
- Quantified a **16.3-point inflation** in the industry's most-cited public benchmark, and rebuilt every figure on verified reviews only.
- Measured a **halo effect** in which ground service ratings shift how passengers score every other part of the journey by up to 2.2 points on a 5-point scale.
- Delivered a two-page dashboard that lets any client airline benchmark itself against the market on every attribute, filtered by review verification status and minimum sample size.

---

## 📂 Dataset Description & Data Structure

### 📌 Data Source

| Attribute | Detail |
|---|---|
| **Source** | Public dataset — [Xóm Data / Skytrax](https://dataset.xomdata.com/datasets/schema/skytrax) |
| **Period** | January 2009 – April 2026 |
| **Size** | 154,126 airline reviews · 493 carriers · 577 with review data |
| **Verified** | 61,965 (40.2%) |
| **Format** | CSV, cleaned and enriched in Python |

Field definitions, processing decisions and known defects: [`data/data_dictionary.md`](data/data_dictionary.md)

### 📊 Tables Used

**`airline_reviews`** — fact table, one row per flight review

| Column | Description |
|---|---|
| `review_id` · `airline_id` | Primary key and foreign key to the airline dimension |
| `verify` | 1 if the review carries flight evidence |
| `date_submitted` | Review date — the primary time axis |
| `nationality` · `type_of_traveller` · `seat_type` · `aircraft` | Passenger and journey attributes |
| `seat_comfort` · `cabin_staff_service` · `food_and_beverages` · `inflight_entertainment` · `ground_service` · `wifi_and_connectivity` · `value_for_money` | Service ratings, 1–5 scale. **A blank means "not rated", not zero** |
| `recommended` | Target variable — would the passenger recommend this airline |
| `sentiment_label` · `sentiment_score` | Derived in Python via VADER on the original review text |
| `data_era` · `data_era_covid` | Derived period flags for trend analysis |

**`airlines`** — dimension, 595 carriers with `airline_id` and `airline_name`.

Three further review tables (`airport_reviews`, `lounge_reviews`, `seat_reviews`) were cleaned and profiled but sit outside the scope of this analysis.

### 🔗 Data Relationships

![Data Model](powerbi/data_model.png)

| From Table | To Table | Join Key | Relationship |
|---|---|---|---|
| `airline_reviews` | `airlines` | `airline_id` | Many-to-One |
| `airline_reviews` | `Master_Calendar` | `date_submitted` | Many-to-One |

A star schema with a single fact table. Sentiment scores and period flags were materialised in Python rather than computed in DAX, keeping the model responsive at 154k rows.

---

## 🧠 Design Thinking Process

### 1️⃣ Empathize

| Stakeholder | What they do today | Where it breaks down |
|---|---|---|
| **VP Customer Experience** | Reads monthly review summaries and complaint themes | Knows what passengers complain about, not what changes their behaviour. Budget follows noise |
| **Chief Insights Officer** | Benchmarks clients against public review averages | Has no way to tell whether that baseline is trustworthy |
| **Head of Product, Cabin** | Prioritises hardware upgrades by internal roadmap | Cannot connect a seat or entertainment investment to a loyalty outcome |
| **Marketing Director** | Segments campaigns by cabin class | Assumes premium passengers are the most satisfied, never tested |

### 2️⃣ Define Point of View

> The CX team needs to know which service attributes drive a passenger's decision to recommend, so they can allocate a fixed improvement budget — **but complaint volume and actual impact have never been measured against each other**, and the benchmark they measure themselves against has never been validated.

Two problems, not one. The first is a prioritisation problem. The second is a measurement problem — and solving the second is a precondition for trusting any answer to the first.

### 3️⃣ Ideate

| Question to answer | Metric required | Where it lives |
|---|---|---|
| What actually drives recommendation? | Feature importance from a classifier trained on service ratings | Page 1 |
| Is that the same as what people complain about? | Complaint theme frequency from review text | Page 1 |
| Does one attribute contaminate the others? | Cross-tabulated ratings by ground service band | Page 1 |
| Can the public benchmark be trusted? | Verified vs unverified recommendation rate | Page 1 |
| How does a single airline compare? | Delta against industry on every attribute | Page 2 |
| Which segment holds the headroom? | Recommendation rate split by traveller type | Page 1 & 2 |

### 4️⃣ Prototype & Review

- **Two pages, not one.** The industry benchmark and the single-airline view serve different people in different meetings. Merging them would force both audiences to filter past content they don't need.
- **Page 2 shows deltas, not raw scores.** A CX lead cannot act on "2.98" but can act on "+0.72 against market". Every KPI on the deep-dive page is expressed relative to the industry.
- **The verified-review toggle stays visible** rather than being buried in a methodology footnote, because the gap it exposes is itself one of the findings.
- **A minimum-review threshold is a user parameter, not a hard-coded rule.** Without it a carrier with nine enthusiastic reviews outranks Singapore Airlines; fixing it at one value would embed a judgement the reader cannot test.
- **Complaint themes and loyalty drivers sit side by side on Page 1**, because the mismatch between them is the point of the entire analysis.

---

## 📊 Key Insights & Visualizations

### 📋 I. Industry Command Center

![Industry Command Center](images/dashboard/01_industry_command_center.png)

#### 📌 Key Findings

##### 1. What passengers complain about and what decides their loyalty are two different lists

- The top complaint themes are **Delay & Mishandling (29.28%)**, **Refund & Support (21.03%)** and **In-flight Service Drop (18.83%)** — none of which is wifi or entertainment.
- Yet the loyalty model ranks **wifi last at 0.52%** and **inflight entertainment second-last at 2.47%**.
- Ground service, the attribute closest to the leading complaint themes, accounts for **23.08%** — forty-four times more than wifi.

→ **Complaint volume and commercial impact are not the same signal. A complaint can be loud, frequent and genuine while still being irrelevant to whether a passenger comes back — and budget that follows complaint volume is being spent in the wrong place.**

> The model runs on the 20,644 verified reviews that rate all seven attributes — 33.3% of the verified pool. Passengers who rate everything may be more thorough, or more extreme, than those who rate selectively.

##### 2. The ranking holds regardless of how the model is specified

- Value for money leads the importance ranking at **39.59%**, but it is a summary verdict passengers reach after weighing everything else — not a service an airline delivers.
- Excluding it and re-running the model leaves the rank order of the six service attributes unchanged: ground service **36.63%**, seat comfort **24.81%**, cabin staff **18.42%**, food **14.17%**, entertainment **4.88%**, wifi **1.07%**.

→ **Ground service is the top actionable driver under either specification. The conclusion does not depend on a modelling choice.**

##### 3. Ground service colours every score that follows it

- Passengers who rated ground service **4–5★** gave seat comfort **4.0** and inflight entertainment **3.77**.
- Passengers who rated it **1–2★** gave the identical seats **1.8** and the identical entertainment system **1.73**.

→ **A 2.2-point swing on a 5-point scale, on hardware that did not change. The ground experience sets the frame for everything a passenger evaluates afterwards, which means investment there pays out across the whole journey rather than in one line item.**

##### 4. The public ranking is inflated by 16 points

- Verified reviews — those carrying flight evidence — recommend at **28.1%**.
- Unverified reviews recommend at **44.4%**.
- Unverified reviews make up **59.8%** of the industry's most-cited dataset.

→ **Any ranking built on the full review pool sits roughly sixteen points above what verified passengers actually report. Airlines are benchmarking against a baseline that is partly an artefact of unverified enthusiasm.**

##### 5. Business travellers are harder to please than leisure travellers

- Industry-wide, business travellers recommend at **26.86%** against **28.34%** for leisure — a gap of **−1.5 points**.
- Business travellers make up only **15.56%** of reviews; solo leisure alone accounts for **38.37%**.

→ **Expectation rises with price. The same cabin scores lower when someone paid more to sit in it — which makes any carrier that inverts this pattern worth examining closely.**

---

### 📈 II. Airline Deep-Dive — Vietnam Airlines

![Airline Deep-Dive](images/dashboard/02_airline_deep_dive.png)

#### 📌 Key Findings

##### 1. Vietnam Airlines outperforms the market on every service attribute

- Recommendation rate **51.7%** against an industry **28.1%** — **+23.6 points**.
- Value for money **3.11** (+0.85), ground service **2.98** (+0.72).
- The service gap chart shows a positive delta on all seven attributes, with no exception.

→ **This is not a carrier with isolated strengths. It clears the industry benchmark across the board, and at the dashboard's 200-review threshold it ranks seventh among all qualifying airlines.**

##### 2. Its largest advantages sit where impact is highest

- Widest gaps against benchmark: **value for money (+85.43%)**, **seat comfort (+74.86%)**, **cabin staff service (+74.66%)**, **ground service (+72.00%)**.
- Narrowest gaps: **wifi (+14.68%)** and **inflight entertainment (+10.77%)**.

→ **The airline is strongest precisely on the attributes the model identifies as decisive, and weakest on the two that barely register. If a competitor were designing a response, attacking on wifi would be the least effective move available.**

##### 3. Business travellers invert the industry pattern here

- Business travellers recommend at **57.69%**, leisure at **50.24%** — a gap of **+7.5 points**.
- The industry gap runs the other way at **−1.5 points**, making this a **nine-point divergence** from the market pattern.

→ **The premium cabin is not merely satisfying high-expectation passengers, it is satisfying them more than the leisure cabin does. That is a defensible competitive asset — and it locates the remaining headroom in the leisure segment, which is the larger group.**

##### 4. The promoter–detractor split confirms the loyalty model independently

- Ranking attributes by the gap between promoters and detractors: **ground service (2.4)** and **value for money (2.4)** lead; **wifi (1.5)** and **inflight entertainment (1.2)** trail.
- This ordering was produced from raw score differences, with no model involved.

→ **Two independent methods — a random forest on the full industry and a simple promoter–detractor comparison on a single carrier — return the same top two and the same bottom two. The prioritisation holds without relying on the model.**

> Vietnam Airlines has **65.1% verified reviews** against an industry 40.2%, so its data is more reliable than the benchmark it is measured against. The true gap between this carrier and the market may be narrower than the headline figures suggest.

---

## 🔎 Final Conclusion & Recommendations

| **Aspect** | **Insight** | **Recommendation** |
|---|---|---|
| **Investment prioritisation** | Wifi explains 0.52% of the recommendation decision against ground service at 23.08%, yet absorbs disproportionate attention in complaint reviews | Move wifi budget to ground operations. Wifi is worth fixing when broken, but does not belong in a loyalty budget. **Owner:** VP Customer Experience with Ground Operations |
| **Compounding returns** | Ground service ratings shift how passengers score every other attribute by up to 2.2 points on a 5-point scale | Treat ground service as a multiplier rather than a line item — the same spend returns improvements across seat, food and entertainment scores. **Owner:** Head of Ground Operations |
| **Benchmark reliability** | Unverified reviews recommend 16.3 points higher than verified ones and make up 59.8% of the public dataset | Rebuild internal CX targets on verified reviews only, and publish the verified baseline alongside the public number. **Owner:** Chief Insights Officer |
| **Segment strategy** | Industry business travellers recommend 1.5 points below leisure; at Vietnam Airlines they recommend 7.5 points above | Protect the premium-cabin advantage as a differentiator, and direct improvement effort at the leisure segment where the headroom sits. **Owner:** VP Customer Experience with Marketing |
| **Competitive positioning** | Vietnam Airlines' widest advantages fall on the highest-impact attributes; its narrowest fall on wifi and entertainment | Lead commercial messaging on value for money and service quality rather than cabin technology. **Owner:** Marketing Director |

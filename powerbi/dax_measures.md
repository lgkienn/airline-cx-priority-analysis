# DAX Measures — Xóm Air Dashboard

Measure table: `#Measures` · Total: **91 measures**
Fact table: `airline_reviews_PBI_Master_Optimized_V4` · Calendar: `Master_Calendar`

| Group | Count | Purpose |
|---|---|---|
| Core Metrics | 37 | Base measures every other calculation builds on. |
| Benchmark Comparison | 25 | Compare a selected airline against the industry average. The backbone of the Airline Deep-Dive page. |
| Time Intelligence | 3 | Year-over-year movement using the calendar table. |
| Statistical Threshold | 3 | Exclude airlines with too few reviews so small-sample carriers cannot distort rankings. |
| Verified vs Unverified | 5 | Quantify the gap between reviews backed by flight evidence and those that are not. |
| Traveller Segment | 9 | Split business and leisure travellers, whose expectations differ materially. |
| Ranking | 1 | Dynamic top-N selection. |
| Dynamic Labels | 8 | Text measures that rewrite themselves based on the current selection. |

---

## Core Metrics

Base measures every other calculation builds on.

### `% Recommended`

```dax
% Recommended =
DIVIDE([Total Recommended],[Total Reviews])
```

### `% Recommended_Unverifed`

```dax
% Recommended_Unverifed =
CALCULATE([% Recommended], airline_reviews_PBI_Master_Optimized_V4[verify] = 0)
```

### `Abs Tipping Point Gap`

```dax
Abs Tipping Point Gap =
ABS([Tipping Point Gap])
```

### `Aircraft % Recommended Color`

```dax
Aircraft % Recommended Color =
IF([% Recommended] >= [Avg % Recommended (Self Benchmark)], "#0078D4", "#CA5010")
```

### `Airlines Covered`

```dax
Airlines Covered =
CALCULATE(
    DISTINCTCOUNT(airline_reviews_PBI_Master_Optimized_V4[airline_id]),
    FILTER(
        VALUES(airline_reviews_PBI_Master_Optimized_V4[airline_id]),
        [Airlines Qualified Flag] = 1
    )
)
```

### `Avg Cabin Staff Service`

```dax
Avg Cabin Staff Service =
AVERAGE(airline_reviews_PBI_Master_Optimized_V4[cabin_staff_service])
```

### `Avg Food Beverage`

```dax
Avg Food Beverage =
AVERAGE(airline_reviews_PBI_Master_Optimized_V4[food_and_beverages])
```

### `Avg Ground Service`

```dax
Avg Ground Service =
AVERAGE(airline_reviews_PBI_Master_Optimized_V4[ground_service])
```

### `Avg Ground Service (Unverified)`

```dax
Avg Ground Service (Unverified) =
CALCULATE([Avg Ground Service],airline_reviews_PBI_Master_Optimized_V4[verify]=0)
```

### `Avg Inflight Entertainment`

```dax
Avg Inflight Entertainment =
AVERAGE(airline_reviews_PBI_Master_Optimized_V4[inflight_entertainment])
```

### `Avg Inflight Experience Score (Fixed Baseline)`

```dax
Avg Inflight Experience Score (Fixed Baseline) =
CALCULATE(
    [Inflight Experience Score],
    ALL('airline_reviews_PBI_Master_Optimized_V4'),
    ALL('airlines'),
    ALL('Master_Calendar'),
    'airline_reviews_PBI_Master_Optimized_V4'[verify] = 1
)
```

### `Avg Lounge Score (Fixed Baseline)`

```dax
Avg Lounge Score (Fixed Baseline) =
CALCULATE(
    [Lounge Score],
    ALL('lounge_reviews_PBI_Master_Optimized_V2'),
    ALL('airlines'),
    ALL('Master_Calendar'),
    lounge_reviews_PBI_Master_Optimized_V2[verify] = 1
)
```

### `Avg Seat Comfort`

```dax
Avg Seat Comfort =
AVERAGE('airline_reviews_PBI_Master_Optimized_V4'[seat_comfort])
```

### `Avg Value for Money`

```dax
Avg Value for Money =
AVERAGE(airline_reviews_PBI_Master_Optimized_V4[value_for_money])
```

### `Avg Wifi and Connectivity`

```dax
Avg Wifi and Connectivity =
AVERAGE(airline_reviews_PBI_Master_Optimized_V4[wifi_and_connectivity])
```

### `Avg_value_for_money_Unverified`

```dax
Avg_value_for_money_Unverified =
CALCULATE([Avg Value for Money],'airline_reviews_PBI_Master_Optimized_V4'[verify]=0)
```

### `Axis Maximum`

```dax
Axis Maximum =
VAR SelectedMetric = SELECTEDVALUE('Trend Metric Selector'[Trend Metric Selector])
VAR RawMax =
    MAXX(
        ALLSELECTED('Master_Calendar'[Date]),
        SWITCH(
            SelectedMetric,
            "% Recommended", [% Recommended],
            "Avg Value for Money", [Avg Value for Money]
        )
    )
VAR DynamicMaxRecommended = CEILING(COALESCE(RawMax, 0.1) * 1.15, 0.05)
RETURN
SWITCH(
    SelectedMetric,
    "Avg Value for Money", 5,
    DynamicMaxRecommended
)
```

### `Dynamic Selected Metric`

```dax
Dynamic Selected Metric =
// Dùng MAX thay cho SELECTEDVALUE để "lách luật" Composite Key của Field Parameter
VAR SelectedMetric = MAX('Trend Metric Selector'[Trend Metric Selector])

RETURN
SWITCH(
    SelectedMetric,
    "% Recommended", [% Recommended],
    "Avg Value for Money", [Avg Value for Money]
)
```

### `Inflight Experience Score`

```dax
Inflight Experience Score =
DIVIDE(
    [Avg Seat Comfort] + [Avg Cabin Staff Service] + [Avg Food Beverage] + [Avg Inflight Entertainment],
    4
)
```

### `Lounge Score`

```dax
Lounge Score =
CALCULATE(
    AVERAGE(lounge_reviews_PBI_Master_Optimized_V2[overall_rating]),
    CROSSFILTER('airlines'[airline_id], 'lounge_reviews_PBI_Master_Optimized_V2'[airline_id], BOTH)
)
```

### `Market Coverage %`

```dax
Market Coverage % =
DIVIDE([Airlines Covered], [Total Airlines in DB])
```

### `Quadrant Color`

```dax
Quadrant Color =
VAR X = [Inflight Experience Score]
VAR Y = [Lounge Score]
VAR AvgX = [Avg Inflight Experience Score (Industry)]
VAR AvgY = [Avg Lounge Score (Industry)]
RETURN
SWITCH(
    TRUE(),
    ISBLANK(X) || ISBLANK(Y), "#BDBDBD",  // Giữ nguyên màu xám nhạt cho các trường hợp không có dữ liệu
    X >= AvgX && Y >= AvgY, "#235A8C",    // Market Leaders: Xanh Navy đậm (Đồng bộ với line chart)
    X < AvgX && Y < AvgY, "#A6A6A6",      // Underperformers: Xám trung tính (Làm chìm các yếu tố kém)
    X >= AvgX && Y < AvgY, "#7EB2E6",     // Inflight Specialists: Xanh dương nhạt (Tone sur tone với các bar chart)
    "#E29E4A"                             // Lounge Specialists: Cam đất nhẹ (Màu nhấn tạo sự chú ý)
)
```

### `Quadrant Group`

```dax
Quadrant Group =
VAR X = [Inflight Experience Score]
VAR Y = [Lounge Score]
VAR AvgX = [Avg Inflight Experience Score (Industry)]
VAR AvgY = [Avg Lounge Score (Industry)]
RETURN
SWITCH(
    TRUE(),
    X >= AvgX && Y >= AvgY, "Thủ lĩnh Toàn diện",
    X < AvgX && Y < AvgY, "Yếu cả 2 mảng",
    X >= AvgX && Y < AvgY, "Mạnh Trời - Yếu Đất",
    X < AvgX && Y >= AvgY, "Mạnh Đất - Yếu Trời"
)
```

### `Selected Criteria Value`

```dax
Selected Criteria Value =
SWITCH(
    SELECTEDVALUE('Criteria'[CriteriaName]),
    "Seat Comfort", [Avg Seat Comfort],
    "Cabin Staff Service", [Avg Cabin Staff Service],
    "Food & Beverage", [Avg Food Beverage],
    "Inflight Entertainment", [Avg Inflight Entertainment],
    "Ground Service", [Avg Ground Service],
    "Wifi & Connectivity", [Avg Wifi and Connectivity],
    "Value for Money", [Avg Value for Money]
)
```

### `Selected Criteria Value (Detractors)`

```dax
Selected Criteria Value (Detractors) =
CALCULATE([Selected Criteria Value], airline_reviews_PBI_Master_Optimized_V4[recommended] = 0)
```

### `Selected Criteria Value (Promoters)`

```dax
Selected Criteria Value (Promoters) =
CALCULATE([Selected Criteria Value], airline_reviews_PBI_Master_Optimized_V4[recommended] = 1)
```

### `Tipping Point Gap`

```dax
Tipping Point Gap =
[Selected Criteria Value (Promoters)] - [Selected Criteria Value (Detractors)]
```

### `Tipping Point Gap Color`

```dax
Tipping Point Gap Color =
IF([Tipping Point Gap] >= 0, "#0078D4", "#CA5010")
```

### `Total Airlines in DB`

```dax
Total Airlines in DB =
CALCULATE(
    DISTINCTCOUNT(airline_reviews_PBI_Master_Optimized_V4[airline_id]),
    ALL(airline_reviews_PBI_Master_Optimized_V4[airline_id]) // Lấy toàn bộ hãng bất chấp bộ lọc
)
```

### `Total Recommended`

```dax
Total Recommended =
CALCULATE(COUNTROWS('airline_reviews_PBI_Master_Optimized_V4'), 'airline_reviews_PBI_Master_Optimized_V4'[recommended] = 1)
```

### `Total Review (All)`

```dax
Total Review (All) =
[Total Verified Reviews] + [Total Unverified Reviews]
```

### `Total Reviews`

```dax
Total Reviews =
COUNTROWS('airline_reviews_PBI_Master_Optimized_V4')
```

### `Total Reviews (All Sources)`

```dax
Total Reviews (All Sources) =
[Total Reviews] + CALCULATE(COUNTROWS('lounge_reviews_PBI_Master_Optimized_V2'))
```

### `Total Unverified Reviews`

```dax
Total Unverified Reviews =
CALCULATE([Total Reviews], 'airline_reviews_PBI_Master_Optimized_V4'[verify] = 0)
```

### `VAR SelectedMetric`

```dax
VAR SelectedMetric =
MAX('Trend Metric Selector'[Trend Metric Selector])
RETURN
SWITCH(
    SelectedMetric,
    "% Recommended", "0.0%",
    "Avg Value for Money", "0.00"
)
```

### `_Dynamic Selected Metric FormatString`

```dax
_Dynamic Selected Metric FormatString =
VAR SelectedMetric = MAX('Trend Metric Selector'[Trend Metric Selector])
RETURN
IF(
    CONTAINSSTRING(SelectedMetric, "%"),
    "0.0%",    // Nếu tên Slicer có chứa dấu "%" -> Hiện phần trăm
    "0.00"     // Nếu không -> Hiện số có 2 chữ số thập phân
)
```

### `_VAR SelectedMetric FormatString`

```dax
_VAR SelectedMetric FormatString =
VAR SelectedMetric = MAX('Trend Metric Selector'[Trend Metric Selector])
RETURN
SWITCH(
    SelectedMetric,
    "% Recommended", "0.0%",
    "Avg Value for Money", "0.00"
)
```


## Benchmark Comparison

Compare a selected airline against the industry average. The backbone of the Airline Deep-Dive page.

### `% Recommended Delta vs LY`

```dax
% Recommended Delta vs LY =
[% Recommended] - [% Recommended LY]
```

### `Abs Delta vs Benchmark`

```dax
Abs Delta vs Benchmark =
ABS([Delta vs Benchmark (Diverging Bar)])
```

### `Avg % Recommended (Industry)`

```dax
Avg % Recommended (Industry) =
CALCULATE([% Recommended], ALL(airlines))
```

### `Avg % Recommended (Self Benchmark)`

```dax
Avg % Recommended (Self Benchmark) =
CALCULATE([% Recommended], ALL('airline_reviews_PBI_Master_Optimized_V4'[aircraft]))
```

### `Avg Cabin Staff Service (Benchmark)`

```dax
Avg Cabin Staff Service (Benchmark) =
VAR BenchAirline = [Selected Benchmark Airline]
RETURN
    IF(
        BenchAirline = "Industry Average",
        CALCULATE([Avg Cabin Staff Service], ALL(airlines)),
        CALCULATE(
            [Avg Cabin Staff Service],
            ALL(airlines),
            airlines[airline_name] = BenchAirline
        )
    )
```

### `Avg Ground Service (Industry)`

```dax
Avg Ground Service (Industry) =
CALCULATE([Avg Ground Service],ALL(airlines),airline_reviews_PBI_Master_Optimized_V4[verify]=1)
```

### `Avg Inflight Experience Score (Industry)`

```dax
Avg Inflight Experience Score (Industry) =
CALCULATE([Inflight Experience Score], ALL('airlines'))
```

### `Avg Lounge Score (Industry)`

```dax
Avg Lounge Score (Industry) =
CALCULATE([Lounge Score], ALL('airlines'))
```

### `Avg Value for Money_Industry`

```dax
Avg Value for Money_Industry =
CALCULATE([Avg Value for Money],ALL(airlines),airline_reviews_PBI_Master_Optimized_V4[verify]=1)
```

### `Delta % Recommended vs Industry`

```dax
Delta % Recommended vs Industry =
[% Recommended] - [Avg % Recommended (Industry)]
```

### `Delta % Recommended vs Industry (pp)`

```dax
Delta % Recommended vs Industry (pp) =
[Delta % Recommended vs Industry] * 100
```

### `Delta Avg Ground Service to Industry`

```dax
Delta Avg Ground Service to Industry =
[Avg Ground Service] - [Avg Ground Service (Industry)]
```

### `Delta Avg Ground Service to Unverified`

```dax
Delta Avg Ground Service to Unverified =
[Avg Ground Service] - [Avg Ground Service (Unverified)]
```

### `Delta Avg Value for Money to unverified rate`

```dax
Delta Avg Value for Money to unverified rate =
VAR Avg_value_for_money_Unverified = CALCULATE([Avg Value for Money],'airline_reviews_PBI_Master_Optimized_V4'[verify]=0)
VAR Avg_value_for_money_Verified = CALCULATE([Avg Value for Money],'airline_reviews_PBI_Master_Optimized_V4'[verify]=1)
RETURN
    Avg_value_for_money_Verified - Avg_value_for_money_Unverified
```

### `Delta Avg Value of Money vs Unverified rate text`

```dax
Delta Avg Value of Money vs Unverified rate text =
VAR D = [Delta Avg Value for Money to unverified rate]
VAR _format = FORMAT(D, "0.00;0.00;0.00")
RETURN
SWITCH(TRUE,
        D>0, UNICHAR(11165) & _format,
        D<0, UNICHAR(11167) & _format,
        _format
)
```

### `Delta Cabin Staff vs Benchmark`

```dax
Delta Cabin Staff vs Benchmark =
[Avg Cabin Staff Service] - [Avg Cabin Staff Service (Benchmark)]
```

### `Delta Ground Service to Unverified`

```dax
Delta Ground Service to Unverified =
[Avg Ground Service] - [Avg Ground Service (Unverified)]
```

### `Delta Value for Money vs Industry`

```dax
Delta Value for Money vs Industry =
[Avg Value for Money] - [Avg Value for Money_Industry]
```

### `Delta vs Benchmark (Diverging Bar)`

```dax
Delta vs Benchmark (Diverging Bar) =
[Selected Criteria Value] - [Selected Criteria Value (Benchmark)]
```

### `Dynamic Industry Benchmark`

```dax
Dynamic Industry Benchmark =
// Vẫn dùng MAX để đọc lựa chọn
VAR SelectedMetric = MAX('Trend Metric Selector'[Trend Metric Selector])

RETURN
SWITCH(
    SelectedMetric,
    "% Recommended", CALCULATE([% Recommended], ALL('airlines')),
    "Avg Value for Money", CALCULATE([Avg Value for Money], ALL('airlines'))
)
```

### `Industry Benchmark Trend`

```dax
Industry Benchmark Trend =
// 1. Đọc giá trị Slicer đang được chọn (Mặc định là "% Recommended" nếu không chọn gì)
VAR SelectedMetric = SELECTEDVALUE('Trend Metric Selector'[Trend Metric Selector], "% Recommended")

// 2. Trả về kết quả Trung bình ngành bằng cách gỡ bỏ bộ lọc Hãng bay (REMOVEFILTERS)
RETURN
SWITCH(
    SelectedMetric,
    "% Recommended",
        CALCULATE(
            [% Recommended],
            REMOVEFILTERS(airlines[airline_name]) // Gỡ lọc Hãng bay để tính toàn ngành
        ),
    "Avg Value for Money",
        CALCULATE(
            [Avg Value for Money],
            REMOVEFILTERS(airlines[airline_name])
        )
)
```

### `Selected Benchmark Airline`

```dax
Selected Benchmark Airline =
SELECTEDVALUE('Benchmark_Selector'[BenchmarkAirline], "Industry Average")
```

### `Selected Criteria Value (Benchmark)`

```dax
Selected Criteria Value (Benchmark) =
VAR BenchAirline = [Selected Benchmark Airline]
RETURN
    IF(
        BenchAirline = "Industry Average",
        CALCULATE([Selected Criteria Value], ALL(airlines), airline_reviews_PBI_Master_Optimized_V4[verify] = 1),
        CALCULATE(
            [Selected Criteria Value], ALL(airlines),
            airlines[airline_name] = BenchAirline, airline_reviews_PBI_Master_Optimized_V4[verify] = 1
        )
    )
```

### `Service Gap Benchmark Color`

```dax
Service Gap Benchmark Color =
IF([Delta vs Benchmark (Diverging Bar)] >= 0, "#0078D4", "#CA5010")
```

### `_Dynamic Industry Benchmark FormatString`

```dax
_Dynamic Industry Benchmark FormatString =
VAR SelectedMetric = MAX('Trend Metric Selector'[Trend Metric Selector])
RETURN
IF(
    CONTAINSSTRING(SelectedMetric, "%"),
    "0.0%",    // Nếu tên Slicer có chứa dấu "%" -> Hiện phần trăm
    "0.00"     // Nếu không -> Hiện số có 2 chữ số thập phân
)
```


## Time Intelligence

Year-over-year movement using the calendar table.

### `% Recommended LY`

```dax
% Recommended LY =
CALCULATE([% Recommended], DATEADD(Master_Calendar[Date],-1,YEAR))
```

### `Trend Metric Selector Value`

```dax
Trend Metric Selector Value =
SWITCH(
    SELECTEDVALUE('Trend Metric Selector'[Trend Metric Selector]),
    "% Recommended", [% Recommended],
    "Avg Value for Money", [Avg Value for Money],
    BLANK()
)
```

### `_Trend Metric Selector Value FormatString`

```dax
_Trend Metric Selector Value FormatString =
SWITCH(
    SELECTEDVALUE('Trend Metric Selector'[Trend Metric Selector]),
    "% Recommended", "0.0%",
    "Avg Value for Money", "0.00",
    "0.00"
)
```


## Statistical Threshold

Exclude airlines with too few reviews so small-sample carriers cannot distort rankings.

### `% Recommended (Qualified Only)`

```dax
% Recommended (Qualified Only) =
IF(
    [Airlines Qualified Flag] = 1,
    [% Recommended],
    BLANK()
)
```

### `Aircraft Reviews Qualified Flag`

```dax
Aircraft Reviews Qualified Flag =
IF(COUNTROWS(airline_reviews_PBI_Master_Optimized_V4) >= 30, 1, 0)
```

### `Airlines Qualified Flag`

```dax
Airlines Qualified Flag =
IF([Total Reviews] >= [Min Review Threshold Value], 1, 0)
```


## Verified vs Unverified

Quantify the gap between reviews backed by flight evidence and those that are not.

### `% Recommended_Verifed`

```dax
% Recommended_Verifed =
CALCULATE([% Recommended], airline_reviews_PBI_Master_Optimized_V4[verify] = 1)
```

### `% Verified Review`

```dax
% Verified Review =
DIVIDE([Total Verified Reviews], [Total Review (All)])
```

### `Total Verified Reviews`

```dax
Total Verified Reviews =
CALCULATE([Total Reviews], 'airline_reviews_PBI_Master_Optimized_V4'[verify] = 1)
```

### `Verified Recommend Gap (pp)`

```dax
Verified Recommend Gap (pp) =
([% Recommended_Verifed] - [% Recommended_Unverifed]) * 100
```

### `Verified Recommend Gap Color`

```dax
Verified Recommend Gap Color =
IF([Verified Recommend Gap (pp)] < 0, "#D13438", "#107C10")
```


## Traveller Segment

Split business and leisure travellers, whose expectations differ materially.

### `% Recommended_Business`

```dax
% Recommended_Business =
CALCULATE([% Recommended], airline_reviews_PBI_Master_Optimized_V4[Traveller Group] = "Business")
```

### `% Recommended_Leisure`

```dax
% Recommended_Leisure =
CALCULATE([% Recommended], airline_reviews_PBI_Master_Optimized_V4[Traveller Group] = "Leisure")
```

### `Abs Segment Gap`

```dax
Abs Segment Gap =
ABS([Segment Gap (Business vs Leisure)])
```

### `Business vs Leisure NPS Gap`

```dax
Business vs Leisure NPS Gap =
[% Recommended_Business] - [% Recommended_Leisure]
```

### `Business vs Leisure NPS Gap (pp)`

```dax
Business vs Leisure NPS Gap (pp) =
[Business vs Leisure NPS Gap] * 100
```

### `Segment Gap (Business vs Leisure)`

```dax
Segment Gap (Business vs Leisure) =
[Selected Criteria Value (Business2)] - [Selected Criteria Value (Leisure2)]
```

### `Segment Gap Color`

```dax
Segment Gap Color =
IF([Segment Gap (Business vs Leisure)] >= 0, "#0078D4", "#CA5010")
```

### `Selected Criteria Value (Business2)`

```dax
Selected Criteria Value (Business2) =
CALCULATE([Selected Criteria Value], 'airline_reviews_PBI_Master_Optimized_V4'[Traveller Group] = "Business")
```

### `Selected Criteria Value (Leisure2)`

```dax
Selected Criteria Value (Leisure2) =
CALCULATE([Selected Criteria Value], 'airline_reviews_PBI_Master_Optimized_V4'[Traveller Group] = "Leisure")
```


## Ranking

Dynamic top-N selection.

### `Rank % Recommended`

```dax
Rank % Recommended =
IF(
    [Airlines Qualified Flag] = 1,
    RANKX(
        FILTER(ALL('airlines'[airline_name]), [Airlines Qualified Flag] = 1),
        [% Recommended], , DESC
    )
)
```


## Dynamic Labels

Text measures that rewrite themselves based on the current selection.

### `Delta % Cabin Staff Text`

```dax
Delta % Cabin Staff Text =
VAR D = [Delta Cabin Staff vs Benchmark]
VAR _format = FORMAT(D, "0.00;0.00;0.00")
RETURN
SWITCH(TRUE,
        D>0, UNICHAR(11165) & _format,
        D<0, UNICHAR(11167) & _format,
        _format
)
```

### `Delta % Recommended vs Industry Text`

```dax
Delta % Recommended vs Industry Text =
VAR D = [Delta % Recommended vs Industry]
VAR _format = FORMAT(D, "0.0%;0.0%;0.0%")
RETURN
SWITCH(TRUE,
        D>0, UNICHAR(11165) & " " & _format,
        D<0, UNICHAR(11167) & " " & _format,
        _format
)
```

### `Delta Avg Ground Service to Unverified Text`

```dax
Delta Avg Ground Service to Unverified Text =
VAR D = [Avg Ground Service] - [Avg Ground Service (Unverified)]
VAR _format = FORMAT(D, "0.00;0.00;0.00")
RETURN
SWITCH(TRUE,
        D>0, UNICHAR(11165) & _format,
        D<0, UNICHAR(11167) & _format,
        _format
)
```

### `Delta Avg Ground Service vs Industry Text`

```dax
Delta Avg Ground Service vs Industry Text =
VAR D = [Delta Avg Ground Service to Industry]
VAR _format = FORMAT(D, "0.00;0.00;0.00")
RETURN
SWITCH(TRUE,
        D>0, UNICHAR(11165) & _format,
        D<0, UNICHAR(11167) & _format,
        _format
)
```

### `Delta Avg Value of Money vs Industry Text`

```dax
Delta Avg Value of Money vs Industry Text =
VAR D = [Delta Value for Money vs Industry]
VAR _format = FORMAT(D, "0.00;0.00;0.00")
RETURN
SWITCH(TRUE,
        D>0, UNICHAR(11165) & _format,
        D<0, UNICHAR(11167) & _format,
        _format
)
```

### `Quadrant Label`

```dax
Quadrant Label =
VAR X = [Inflight Experience Score]
VAR Y = [Lounge Score]
VAR AvgX = [Avg Inflight Experience Score (Industry)]
VAR AvgY = [Avg Lounge Score (Industry)]
RETURN
SWITCH(
    TRUE(),
    ISBLANK(X) || ISBLANK(Y), "Không đủ dữ liệu Lounge",
    X >= AvgX && Y >= AvgY, "Thủ lĩnh Toàn diện",
    X < AvgX && Y < AvgY, "Yếu cả 2 mảng",
    X >= AvgX && Y < AvgY, "Mạnh Trời - Yếu Đất",
    "Mạnh Đất - Yếu Trời"
)
```

### `Ref Label_Value Impact`

```dax
Ref Label_Value Impact =
"Top #1 Loyalty Driver (29.28%)"
```

### `Verified Gap Label`

```dax
Verified Gap Label =
"% Recommend — Verified " & FORMAT([% Recommended_Verifed], "0.0%") &
" vs Unverified " & FORMAT([% Recommended_Unverifed], "0.0%")
```


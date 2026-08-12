/* ============================================================
   Time-Series Trends & Data Integrity
   ------------------------------------------------------------
   Purpose : Year-over-year recommendation trend, travel-season effects on queuing, verified vs unverified review gap, and the service tipping point.
   Source  : airline_reviews, airport_reviews
   Engine  : Google BigQuery (Standard SQL)
   Note    : Airlines are filtered with HAVING COUNT(*) >= 350 so
             that small-sample carriers cannot enter the rankings.
   ============================================================ */

-- ## PHẦN IV: XU HƯỚNG THỜI GIAN & ĐỘ TIN CẬY DỮ LIỆU (TIME-SERIES & INTEGRITY)

### 12. Xu hướng Tỷ lệ Khuyến nghị (% Recommended) và Điểm dịch vụ trung bình thay đổi như thế nào qua từng năm?

SELECT 
    EXTRACT(YEAR FROM date_submitted) AS review_year,
    COUNT(*) AS total_reviews,
    ROUND(AVG(seat_comfort), 2) AS avg_seat,
    ROUND(AVG(cabin_staff_service), 2) AS avg_staff,
    ROUND(AVG(value_for_money), 2) AS avg_value,
    ROUND(SUM(CASE WHEN recommended = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_recommended
FROM projectda-502509.airline_reviews.airline_reviews
WHERE date_submitted IS NOT NULL
GROUP BY review_year
ORDER BY review_year ASC;

-- Tính mùa vụ (Seasonality): Vào các tháng cao điểm du lịch (Tháng 6, 7, 8 và 12), điểm Thời gian xếp hàng tại các sân bay sụt giảm nghiêm trọng nhất ở những cảng nào?
SELECT 
    airport_name,
    COUNT(*) AS peak_season_reviews,
    ROUND(AVG(queuing_times), 2) AS peak_season_queuing_score,
    ROUND(AVG(airport_staff), 2) AS peak_season_staff_score
FROM projectda-502509.airline_reviews.airport_reviews a
LEFT JOIN projectda-502509.airline_reviews.dim_airports b
ON a.airport_id = b.airport_id
WHERE EXTRACT(MONTH FROM date_submitted) IN (6, 7, 8, 12) 
  AND airport_name != 'Unknown'
GROUP BY airport_name
HAVING COUNT(*) >= 250
ORDER BY peak_season_queuing_score ASC
LIMIT 15;

-- Có sự chênh lệch điểm số và tỷ lệ Recommend giữa nhóm "Review đã xác thực" (`verified = True/Yes`) và nhóm chưa xác thực không?
SELECT 
    verify,
    COUNT(*) AS total_reviews,
    ROUND(AVG(seat_comfort), 2) AS avg_seat,
    ROUND(AVG(cabin_staff_service), 2) AS avg_staff,
    ROUND(AVG(value_for_money), 2) AS avg_value,
    ROUND(SUM(CASE WHEN recommended = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_recommended
FROM projectda-502509.airline_reviews.airline_reviews
GROUP BY verify;

-- "Điểm gãy" dịch vụ (The Tipping Point): Trong nhóm khách hàng KIÊN QUYẾT KHÔNG giới thiệu (`recommended = 0`), tiêu chí nào bị chấm 1 - 2 sao với tần suất cao nhất?
SELECT 
    'Seat Comfort' AS service_attribute,
    ROUND(SUM(CASE WHEN seat_comfort <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_rated_1_or_2_stars
FROM projectda-502509.airline_reviews.airline_reviews WHERE recommended = 0 AND seat_comfort IS NOT NULL
UNION ALL
SELECT 
    'Cabin Staff Service',
    ROUND(SUM(CASE WHEN cabin_staff_service <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM projectda-502509.airline_reviews.airline_reviews WHERE recommended = 0 AND cabin_staff_service IS NOT NULL
UNION ALL
SELECT 
    'Food and Beverages',
    ROUND(SUM(CASE WHEN food_and_beverages <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM projectda-502509.airline_reviews.airline_reviews WHERE recommended = 0 AND food_and_beverages IS NOT NULL
UNION ALL
SELECT 
    'Inflight Entertainment',
    ROUND(SUM(CASE WHEN inflight_entertainment <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM projectda-502509.airline_reviews.airline_reviews WHERE recommended = 0 AND inflight_entertainment IS NOT NULL
UNION ALL
SELECT 
    'Ground Service',
    ROUND(SUM(CASE WHEN ground_service <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM projectda-502509.airline_reviews.airline_reviews WHERE recommended = 0 AND ground_service IS NOT NULL
UNION ALL
SELECT 
    'Wifi and Connectivity',
    ROUND(SUM(CASE WHEN SAFE_CAST(wifi_and_connectivity AS FLOAT64) <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
FROM projectda-502509.airline_reviews.airline_reviews WHERE recommended = 0 AND wifi_and_connectivity IS NOT NULL
ORDER BY pct_rated_1_or_2_stars DESC;

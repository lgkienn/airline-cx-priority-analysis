/* ============================================================
   Competitive Benchmarking
   ------------------------------------------------------------
   Purpose : Rank airlines by service criteria, recommendation rate and value for money; identify all-round leaders across flight and lounge experience.
   Source  : airline_reviews, airlines, lounge_reviews
   Engine  : Google BigQuery (Standard SQL)
   Note    : Airlines are filtered with HAVING COUNT(*) >= 350 so
             that small-sample carriers cannot enter the rankings.
   ============================================================ */


-- Ví dụ cho tiêu chí Thái độ tiếp viên (cabin_staff_service)
-- Top 10 Hãng xuất sắc nhất
SELECT 
    b.airline_name,
    COUNT(*) AS total_reviews,
    ROUND(AVG(cabin_staff_service), 2) AS avg_staff_service
FROM projectda-502509.airline_reviews.airline_reviews a
LEFT JOIN projectda-502509.airline_reviews.dim_airlines b
ON a.airline_id = b.airline_id
WHERE cabin_staff_service IS NOT NULL
GROUP BY b.airline_name
HAVING COUNT(*) >= 350 -- Bộ lọc lọc bỏ các hãng có quá ít review gây sai lệch
ORDER BY avg_staff_service DESC
LIMIT 10;

-- Top 10 Hãng tệ nhất (Thay DESC thành ASC)
SELECT 
    b.airline_name,
    COUNT(*) AS total_reviews,
    ROUND(AVG(cabin_staff_service), 2) AS avg_staff_service
FROM projectda-502509.airline_reviews.airline_reviews a
LEFT JOIN projectda-502509.airline_reviews.dim_airlines b
ON a.airline_id = b.airline_id
WHERE cabin_staff_service IS NOT NULL
GROUP BY b.airline_name
HAVING COUNT(*) >= 350
ORDER BY avg_staff_service ASC
LIMIT 10;

-- Xem min max để lựa chọn ra bộ lọc bao nhiêu reviews là đẹp
WITH count_totalreview AS (
SELECT 
    b.airline_name,
    COUNT(*) AS total_reviews,
FROM projectda-502509.airline_reviews.airline_reviews a
LEFT JOIN projectda-502509.airline_reviews.dim_airlines b
ON a.airline_id = b.airline_id
WHERE cabin_staff_service IS NOT NULL
GROUP BY b.airline_name
--HAVING COUNT(*) >= 20
ORDER BY total_reviews DESC)

SELECT 
    DISTINCT PERCENTILE_CONT(count_totalreview.total_reviews, 0.5) OVER() AS median_value,
    --MAX(total_reviews) as max_reviews,
    --AVG(count_totalreview.total_reviews) as avg_review
FROM count_totalreview

;

-- Hãng bay nào có chỉ số khuyến nghị cao
SELECT 
    b.airline_name,
    COUNT(*) AS total_reviews,
    SUM(CASE WHEN recommended = 1 THEN 1 ELSE 0 END) AS total_promoters,
    ROUND(SUM(CASE WHEN recommended = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_recommended
FROM projectda-502509.airline_reviews.airline_reviews a
LEFT JOIN projectda-502509.airline_reviews.dim_airlines b
ON a.airline_id = b.airline_id
GROUP BY b.airline_name
HAVING COUNT(*) >= 250
ORDER BY pct_recommended DESC
LIMIT 15;

-- Hãng bay nào được đánh giá đáng tiền nhất theo từng hạng ghế
SELECT 
    airline_name,
    seat_type,
    COUNT(*) AS total_reviews,
    ROUND(AVG(value_for_money), 2) AS avg_value_for_money,
    ROUND(SUM(CASE WHEN recommended = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_recommended
FROM projectda-502509.airline_reviews.airline_reviews a
LEFT JOIN projectda-502509.airline_reviews.dim_airlines b
ON a.airline_id = b.airline_id
WHERE value_for_money IS NOT NULL AND seat_type != 'Unknown'
GROUP BY airline_name, seat_type
HAVING COUNT(*) >= 250
ORDER BY seat_type, avg_value_for_money DESC;

-- Hãng bay nào là "Thủ lĩnh toàn diện" (Mạnh cả Trải nghiệm Chuyến bay lẫn Phòng chờ VIP)?

WITH airline_scores AS (
    SELECT 
        airline_name,
        COUNT(*) AS flight_reviews,
        ROUND(AVG(value_for_money), 2) AS flight_avg_rating,
        ROUND(SUM(CASE WHEN recommended = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS flight_nps
    FROM projectda-502509.airline_reviews.airline_reviews a
    LEFT JOIN projectda-502509.airline_reviews.dim_airlines b
    ON a.airline_id = b.airline_id
    GROUP BY airline_name
    HAVING COUNT(*) >= 50
),
lounge_scores AS (
    SELECT 
        airline_name,
        COUNT(*) AS lounge_reviews,
        ROUND(AVG(comfort), 2) AS lounge_avg_rating,
        ROUND(SUM(CASE WHEN recommended = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS lounge_nps
    FROM projectda-502509.airline_reviews.lounge_reviews a
    LEFT JOIN projectda-502509.airline_reviews.dim_airlines b
    ON a.airline_id = b.airline_id
    GROUP BY airline_name
    HAVING COUNT(*) >= 20
)
SELECT 
    a.airline_name,
    a.flight_reviews,
    a.flight_avg_rating,
    a.flight_nps,
    l.lounge_reviews,
    l.lounge_avg_rating,
    l.lounge_nps,
    ROUND((a.flight_nps + l.lounge_nps) / 2, 2) AS combined_nps_score
FROM airline_scores a
JOIN lounge_scores l ON a.airline_name = l.airline_name
ORDER BY combined_nps_score DESC
LIMIT 10;

/* ============================================================
   Ground Infrastructure & Aircraft Hardware
   ------------------------------------------------------------
   Purpose : Airport queuing and staff pain points, lounge priorities, promoter-detractor score gaps, Boeing vs Airbus, and seat layout impact.
   Source  : airline_reviews, airport_reviews, lounge_reviews, seat_reviews, airports
   Engine  : Google BigQuery (Standard SQL)
   Note    : Airlines are filtered with HAVING COUNT(*) >= 350 so
             that small-sample carriers cannot enter the rankings.
   ============================================================ */

## PHẦN III: HẠ TẦNG MẶT ĐẤT & PHẦN CỨNG MÁY BAY (GROUND & HARDWARE ANALYTICS)
-- Top 10 Sân bay bị phàn nàn nhiều nhất về Thời gian xếp hàng và Thái độ nhân viên?

SELECT 
    airport_name,
    COUNT(*) AS total_reviews,
    ROUND(AVG(queuing_times), 2) AS avg_queuing_time,
    ROUND(AVG(airport_staff), 2) AS avg_staff_service,
    ROUND((AVG(queuing_times) + AVG(airport_staff)) / 2, 2) AS combined_pain_score
FROM projectda-502509.airline_reviews.airport_reviews a
LEFT JOIN projectda-502509.airline_reviews.dim_airports b
ON a.airport_id = b.airport_id
WHERE airport_name != 'Unknown'
GROUP BY airport_name
HAVING COUNT(*) >= 250
ORDER BY combined_pain_score ASC -- Điểm càng thấp càng tệ
LIMIT 10;

-- Ở Phòng chờ (Lounge), yếu tố Đồ ăn (Catering) hay Không gian nghỉ ngơi (Comfort) quan trọng hơn?

SELECT 
    recommended,
    COUNT(*) AS total_reviews,
    ROUND(AVG(catering), 2) AS avg_catering,
    ROUND(AVG(bar_and_beverages), 2) AS avg_bar,
    ROUND(AVG(comfort), 2) AS avg_comfort,
    ROUND(AVG(cleanliness), 2) AS avg_cleanliness,
    ROUND(AVG(wifi_connectivity), 2) AS avg_wifi
FROM projectda-502509.airline_reviews.lounge_reviews
GROUP BY recommended;
-- Nhìn vào khoảng cách chênh lệch điểm số (Gap) giữa nhóm recommended = 1 và 0 
-- Tiêu chí nào có mức sụt giảm mạnh nhất khi recommended = 0, tiêu chí đó có sức nặng quyết định lớn nhất.

--- Dòng máy bay nào (Boeing vs. Airbus) mang lại trải nghiệm tốt cho khách hàng hơn?

SELECT 
    CASE 
        WHEN UPPER(aircraft) LIKE '%BOEING%' OR aircraft LIKE '%B7%' THEN 'Boeing Fleet'
        WHEN UPPER(aircraft) LIKE '%AIRBUS%' OR aircraft LIKE '%A3%' THEN 'Airbus Fleet'
        ELSE 'Other/Mixed' 
    END AS manufacturer,
    COUNT(*) AS total_reviews,
    ROUND(AVG(seat_comfort), 2) AS avg_seat_comfort,
    ROUND(AVG(inflight_entertainment), 2) AS avg_ife,
    ROUND(AVG(value_for_money), 2) AS avg_value,
    ROUND(SUM(CASE WHEN recommended = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_recommended
FROM projectda-502509.airline_reviews.airline_reviews
WHERE aircraft != 'Unknown'
GROUP BY manufacturer
HAVING COUNT(*) >= 1000
ORDER BY pct_recommended DESC;

-- Sơ đồ bố trí ghế (Seat Layout) ảnh hưởng thế nào đến điểm đánh giá Chỗ để chân và Độ rộng?
SELECT 
    seat_type,
    seat_layout,
    COUNT(*) AS total_reviews,
    ROUND(AVG(seat_width), 2) AS avg_seat_width,
    ROUND(AVG(seat_legroom), 2) AS avg_legroom,
    ROUND(AVG(sitting_comfort), 2) AS avg_sitting_comfort,
    ROUND(AVG(sleep_comfort), 2) AS avg_sleep_comfort
FROM projectda-502509.airline_reviews.seat_reviews
WHERE seat_layout != 'Unknown' AND seat_type != 'Unknown'
GROUP BY seat_type, seat_layout
HAVING COUNT(*) >= 50
ORDER BY seat_type, avg_seat_width DESC;

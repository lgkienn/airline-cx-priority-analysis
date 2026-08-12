/* ============================================================
   Passenger Behaviour & Expectations
   ------------------------------------------------------------
   Purpose : Compare satisfaction across transit vs direct flights, business vs leisure travellers, and reviewer nationalities.
   Source  : airline_reviews, airlines
   Engine  : Google BigQuery (Standard SQL)
   Note    : Airlines are filtered with HAVING COUNT(*) >= 350 so
             that small-sample carriers cannot enter the rankings.
   ============================================================ */

-- ## PHẦN II: THẤU HIỂU HÀNH VI & KỲ VỌNG HÀNH KHÁCH (PASSENGER INSIGHTS)
-- Khách hàng bay Nối chuyến (Transit) có độ hài lòng thấp hơn Khách bay thẳng (Direct Flight) không?
SELECT 
    CASE 
        WHEN transit_airport = 'Direct Flight' THEN 'Direct Flight' 
        ELSE 'Transit Flight' 
    END AS flight_type,
    COUNT(*) AS total_reviews,
    ROUND(AVG(SAFE_CAST(seat_comfort AS FLOAT64)), 2) AS avg_seat_comfort,
    ROUND(AVG(SAFE_CAST(cabin_staff_service AS FLOAT64)), 2) AS avg_staff_service,
    ROUND(AVG(SAFE_CAST(value_for_money AS FLOAT64)), 2) AS avg_value_for_money,
    ROUND(SUM(CASE WHEN SAFE_CAST(recommended AS INT64) = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_recommended
FROM projectda-502509.airline_reviews.airline_reviews
GROUP BY flight_type;

-- Sự khác biệt về độ hài lòng và kỳ vọng giữa Khách Công vụ (Business) và Khách Du lịch (Leisure)?
SELECT 
    type_of_traveller,
    COUNT(*) AS total_reviews,
    ROUND(AVG(SAFE_CAST(wifi_and_connectivity AS FLOAT64)), 2) AS avg_wifi,
    ROUND(AVG(SAFE_CAST(food_and_beverages AS FLOAT64)), 2) AS avg_fnb,
    ROUND(AVG(SAFE_CAST(cabin_staff_service AS FLOAT64)), 2) AS avg_staff,
    ROUND(AVG(SAFE_CAST(value_for_money AS FLOAT64)), 2) AS avg_value,
    ROUND(SUM(CASE WHEN SAFE_CAST(recommended AS INT64) = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_recommended
FROM projectda-502509.airline_reviews.airline_reviews
WHERE type_of_traveller != 'Unknown'
GROUP BY type_of_traveller
ORDER BY pct_recommended DESC;

-- Top 10 Quốc tịch để lại nhiều review nhất và họ khắt khe với tiêu chí nào nhất?
WITH top_nationalities AS (
    SELECT nationality
    FROM projectda-502509.airline_reviews.airline_reviews
    WHERE nationality != 'Unknown'
    GROUP BY nationality
    ORDER BY COUNT(*) DESC
    LIMIT 10
)
SELECT 
    a.nationality,
    COUNT(*) AS total_reviews,
    ROUND(AVG(a.seat_comfort), 2) AS avg_seat,
    ROUND(AVG(a.cabin_staff_service), 2) AS avg_staff,
    ROUND(AVG(a.food_and_beverages), 2) AS avg_fnb,
    ROUND(AVG(a.inflight_entertainment), 2) AS avg_ife,
    ROUND(AVG(SAFE_CAST(wifi_and_connectivity AS FLOAT64)), 2) AS avg_wifi,
    ROUND(AVG(a.value_for_money), 2) AS avg_value
FROM projectda-502509.airline_reviews.airline_reviews a
JOIN top_nationalities t ON a.nationality = t.nationality
GROUP BY a.nationality
ORDER BY total_reviews DESC;

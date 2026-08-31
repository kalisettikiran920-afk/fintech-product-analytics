/*
Assumptions:
1. PostgreSQL syntax is assumed.
2. Users may trigger the same event multiple times, so COUNT(DISTINCT user_id) is used.
3. The first occurrence of app_open and first_unit_credited is used for completion time analysis.
*/


/*
==========================================================================================================
1. A step-by-step funnel for the investment onboarding journey: users reaching each stage, and step-over-step conversion
==========================================================================================================
*/

-- Create a funnel with unique users at each stage
WITH funnel AS (
    SELECT
        CASE event_name
            WHEN 'app_open' THEN 1
            WHEN 'mobile_verified' THEN 2
            WHEN 'pan_verified' THEN 3
            WHEN 'sip_amount_selected' THEN 4
            WHEN 'bank_verified' THEN 5
            WHEN 'mandate_completed' THEN 6
            WHEN 'additional_details_saved' THEN 7
            WHEN 'investment_consent_verified' THEN 8
            WHEN 'sip_created' THEN 9
            WHEN 'first_unit_credited' THEN 10
        END AS stage_order,
        event_name,
        COUNT(DISTINCT user_id) AS users
    FROM events
    WHERE event_name IN (
        'app_open',
        'mobile_verified',
        'pan_verified',
        'sip_amount_selected',
        'bank_verified',
        'mandate_completed',
        'additional_details_saved',
        'investment_consent_verified',
        'sip_created',
        'first_unit_credited'
    )
    GROUP BY event_name
),
-- Calculate previous stage users for conversion analysis
funnel_conversion AS (
    SELECT
        *,
        LAG(users) OVER (ORDER BY stage_order) AS previous_stage_users
    FROM funnel
)
SELECT
    stage_order,
    event_name,
    users,
    previous_stage_users,
    CASE
        WHEN previous_stage_users IS NULL THEN 100.00
        ELSE ROUND(users * 100.0 / previous_stage_users, 2)
    END AS conversion_percentage
FROM funnel_conversion
ORDER BY stage_order;


/*
==========================================================================================================
2. Median time between the first and last stage, for users who completed.
==========================================================================================================
*/
WITH user_journey AS (
    SELECT
        user_id,
        MIN(CASE
            WHEN event_name = 'app_open'
            THEN event_ts
        END) AS app_open_time,
        MIN(CASE
            WHEN event_name = 'first_unit_credited'
            THEN event_ts
        END) AS first_unit_credited_time
    FROM events
    GROUP BY user_id
)
SELECT
    PERCENTILE_CONT(0.5)
    WITHIN GROUP (
        ORDER BY first_unit_credited_time - app_open_time
    ) AS median_completion_time
FROM user_journey
WHERE first_unit_credited_time IS NOT NULL;



/*
==================================================================================
3. The single largest drop-off, named.
==================================================================================
*/
WITH funnel AS (
    SELECT
        CASE event_name
            WHEN 'app_open' THEN 1
            WHEN 'mobile_verified' THEN 2
            WHEN 'pan_verified' THEN 3
            WHEN 'sip_amount_selected' THEN 4
            WHEN 'bank_verified' THEN 5
            WHEN 'mandate_completed' THEN 6
            WHEN 'additional_details_saved' THEN 7
            WHEN 'investment_consent_verified' THEN 8
            WHEN 'sip_created' THEN 9
            WHEN 'first_unit_credited' THEN 10
        END AS stage_order,
        event_name,
        COUNT(DISTINCT user_id) AS users
    FROM events
    WHERE event_name IN (
        'app_open',
        'mobile_verified',
        'pan_verified',
        'sip_amount_selected',
        'bank_verified',
        'mandate_completed',
        'additional_details_saved',
        'investment_consent_verified',
        'sip_created',
        'first_unit_credited'
    )
    GROUP BY event_name
),
drop_offs AS (
    SELECT
        *,
        LAG(event_name) OVER (ORDER BY stage_order) AS previous_stage,
        LAG(users) OVER (ORDER BY stage_order) AS previous_stage_users,
        LAG(users) OVER (ORDER BY stage_order) - users AS drop_off
    FROM funnel
)
SELECT
    previous_stage,
    event_name AS current_stage,
    drop_off
FROM drop_offs
WHERE previous_stage IS NOT NULL
ORDER BY drop_off DESC
LIMIT 1;
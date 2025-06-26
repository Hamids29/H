WITH patient_metrics AS (
    SELECT
        p.patient_id,
        p.provider_id,
        MAX(CASE 
            WHEN c.successful_call_flag = 'Y' 
                 AND call_outcome = 'Erleada - Welcome Call Completed' 
            THEN 1 ELSE 0 END) AS enrolled_engaged_program_patient
    FROM
        patiente2e_new_vw.vw_events_patient_aggregate_erleada p
    LEFT JOIN
        patiente2e_new_vw.vw_syneos_case c ON p.patient_id = c.patient_id
    WHERE 
        (
            p.spp_first_ship_date BETWEEN '2023-01-01' AND '2023-12-31'
            OR
            p.claims_first_ship_date BETWEEN '2023-01-01' AND '2023-12-31'
        )
    GROUP BY
        p.patient_id,
        p.provider_id
),
patient_with_status AS (
    SELECT
        patient_id,
        provider_id,
        CASE
            WHEN enrolled_engaged_program_patient > 0 THEN 'Program Patient' 
            ELSE 'Not A Program Patient'
        END AS engagement_status
    FROM
        patient_metrics
)
SELECT
    provider_id,
    COUNT(patient_id) FILTER (WHERE engagement_status = 'Program Patient') AS program_patient_count,
    COUNT(patient_id) FILTER (WHERE engagement_status = 'Not A Program Patient') AS non_program_patient_count,
    COUNT(patient_id) AS total_patient_count
FROM
    patient_with_status
GROUP BY
    provider_id
ORDER BY
    provider_id;

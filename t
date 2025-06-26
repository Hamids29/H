WITH patient_metrics AS (
    SELECT
        p.patient_id,
        p.provider_id,
        p.persistence_days,
        p.spp_first_ship_date,
        p.spp_last_ship_date,
        COUNT(DISTINCT c.call_completion_date) AS total_calls,
        COUNT(DISTINCT t.training_completed_date) AS completed_trainings,
        SUM(CASE WHEN c.successful_call_flag = 'Y' THEN 1 ELSE 0 END) AS successful_calls,
        COUNT(e.program_consent_received_date) AS has_program_consent,
        MAX(CASE WHEN c.successful_call_flag = 'Y' AND call_outcome = 'Erleada - Welcome Call Completed' THEN 1 ELSE 0 END) AS enrolled_engaged_program_patient
    FROM
        patiente2e_new_vw.vw_events_patient_aggregate_erleada p
    LEFT JOIN
        patiente2e_new_vw.vw_syneos_case c ON p.patient_id = c.patient_id
    LEFT JOIN
        patiente2e_new_vw.vw_syneos_training t ON p.patient_id = t.patient_id
    LEFT JOIN
        patiente2e_new_vw.vw_syneos_enrollment e ON p.patient_id = e.patient_id
    LEFT JOIN
        patiente2e_new_vw.vw_syneos_therapy th ON p.patient_id = th.patient_id
    LEFT JOIN 
        patiente2e_new_vw.vw_syneos_lead_contact l ON p.patient_id = l.patient_id
    WHERE 
        (
            p.spp_first_ship_date BETWEEN '2023-01-01' AND '2023-12-31'
            OR
            p.claims_first_ship_date BETWEEN '2023-01-01' AND '2023-12-31'
        )
    GROUP BY
        p.patient_id,
        p.provider_id,
        p.persistence_days,
        p.spp_first_ship_date,
        p.spp_last_ship_date
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
    engagement_status,
    COUNT(patient_id) AS patient_count
FROM
    patient_with_status
GROUP BY
    provider_id,
    engagement_status
ORDER BY
    provider_id,
    engagement_status;


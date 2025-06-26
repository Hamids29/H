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
        MAX(CASE WHEN c.successful_call_flag = 'Y' AND call_outcome = 'Erleada - Welcome Call Completed' THEN 1 ELSE 0 END) AS enrolled_engaged_program_patient,
        COUNT(DISTINCT CASE WHEN spp_last_ship_date >= '2024-12-31'::date - INTERVAL '90 days' THEN p.patient_id END) AS active_spp_patient_count
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
       p.spp_first_ship_date >= '2023-01-01' OR p.claims_first_ship_date  >= '2023-01-01'--or p claims fsd
        AND p.spp_first_ship_date <= '2023-12-31' OR p.claims_first_ship_date <= '2023-12-31'
    GROUP BY
        p.patient_id,
        p.provider_id,
        p.persistence_days,
        p.spp_first_ship_date,
        p.spp_last_ship_date
) 
SELECT
    patient_id,
    CASE
        WHEN enrolled_engaged_program_patient > 0 THEN 'Program Patient' 
        ELSE 'Not A Program Patient'
    END AS engagement_status,
    provider_id
FROM
    patient_metrics
ORDER BY 
    persistence_days DESC;

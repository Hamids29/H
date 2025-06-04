SELECT
    -- Patient Demographics
    j.patient_id,
    j.persistence_days,
    CASE WHEN j.persistence_days > 180 THEN 1 ELSE 0 END AS persistent_over_180_days,
    j.payment_type,
    
    -- SDOH data
    s.ice_ethnic_code_broad_desc AS ethnicity,
    s.ap_estimated_income_dollar_value_desc AS estimated_income,
    s.ice_education_level_code_desc AS education_level,
    s.ice_marital_status_code_code AS marital_status,
    
    -- Therapy information
    j.spp_ship_count,
    DATEDIFF(day, j.spp_first_ship_date, COALESCE(j.spp_last_ship_date, CURRENT_DATE)) AS therapy_duration,
    
    -- Active patient status
    CASE 
        WHEN j.spp_last_ship_date >= CURRENT_DATE - INTERVAL '90 days' THEN 1
        ELSE 0
    END AS is_active_spp_patient,
    
    -- Companion program information (if available)
    CASE WHEN j.companion_enrollment_date IS NOT NULL THEN 1 ELSE 0 END AS has_companion_program,
    
    -- Date fields
    j.spp_first_ship_date,
    j.spp_last_ship_date,
    j.companion_enrollment_date,
    
    -- Additional fields that might be useful for prediction
    j.product,
    
    -- Set program enrollment to 0 since no Syneos data
    0 AS enrolled_in_program,
    0 AS total_calls,
    0 AS successful_calls
FROM
    pe2eprddb.patiente2e_new.jbi_hubpretriage j
LEFT JOIN
    patiente2e_new_vw.vw_acxiom_sdoh s ON j.patient_id = s.patient_id
WHERE
    j.product = 'SPRAVATO'
    AND j.spp_first_ship_date IS NOT NULL
    AND j.spp_first_ship_date >= '2023-01-01'
    AND j.spp_first_ship_date <= '2023-12-31'
ORDER BY
    j.patient_id;
